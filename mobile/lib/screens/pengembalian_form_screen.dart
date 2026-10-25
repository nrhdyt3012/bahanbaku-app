import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/app_events.dart';
import '../utils/format.dart';
import '../widgets/state_views.dart';

class PengembalianFormScreen extends StatefulWidget {
  const PengembalianFormScreen({super.key});
  @override
  State<PengembalianFormScreen> createState() => _PengembalianFormScreenState();
}

class _PengembalianFormScreenState extends State<PengembalianFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ket = TextEditingController();
  DateTime _tgl = DateTime.now();
  List<KeluarSummary> _list = [];
  int? _keluarId;
  KeluarDetail? _detail;
  Map<int, TextEditingController> _ctrls = {}; // key: detail_keluar_id
  int _gen = 0;
  bool _loadingList = true, _loadingDetail = false, _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadList();
    dataVersion.addListener(_loadList);
  }

  @override
  void dispose() {
    dataVersion.removeListener(_loadList);
    _ket.dispose();
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadList() async {
    try {
      final data = await ApiService.getKeluar();
      if (!mounted) return;
      setState(() {
        _list = data;
        _error = null;
        _loadingList = false;
        if (_keluarId != null && !_list.any((t) => t.id == _keluarId)) {
          _keluarId = null;
          _detail = null;
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loadingList = false;
      });
    }
  }

  void _disposeCtrlsLater() {
    final old = _ctrls.values.toList();
    _ctrls = {};
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final c in old) {
        c.dispose();
      }
    });
  }

  Future<void> _selectKeluar(int id) async {
    setState(() {
      _keluarId = id;
      _detail = null;
      _loadingDetail = true;
      _disposeCtrlsLater();
    });
    try {
      final d = await ApiService.getKeluarDetail(id);
      if (!mounted || _keluarId != id) return;
      setState(() {
        _detail = d;
        _ctrls = {for (final it in d.items) it.detailKeluarId: TextEditingController()};
        _loadingDetail = false;
        _gen++;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadingDetail = false);
      showError(context, e.fullMessage);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final items = <Map<String, dynamic>>[];
    for (final it in _detail!.items) {
      final n = double.tryParse(_ctrls[it.detailKeluarId]!.text.trim().replaceAll(',', '.'));
      if (n != null && n > 0) items.add({'detail_keluar_id': it.detailKeluarId, 'qty': n});
    }
    if (items.isEmpty) {
      showError(context, 'Isi qty retur minimal pada satu item');
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService.createPengembalian({
        'keluar_id': _keluarId,
        'tanggal': fmtDate(_tgl),
        'keterangan': _ket.text.trim().isEmpty ? null : _ket.text.trim(),
        'items': items,
      });
      if (!mounted) return;
      showSuccess(context, 'Pengembalian berhasil dicatat');
      _ket.clear();
      notifyDataChanged();
      await _selectKeluar(_keluarId!); // muat ulang sisa yang bisa dikembalikan
    } on ApiException catch (e) {
      if (!mounted) return;
      showError(context, e.fullMessage);
      _selectKeluar(_keluarId!); // sisa mungkin berubah
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _itemField(KeluarItem it) {
    final habis = it.sisa <= 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(it.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('Keluar ${fmtQty(it.qty)} ${it.satuan} | sudah kembali ${fmtQty(it.sudahKembali)} | sisa ${fmtQty(it.sisa)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _ctrls[it.detailKeluarId],
            enabled: !habis,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: habis ? 'Sudah dikembalikan semua' : 'Qty dikembalikan',
              suffixText: it.satuan,
              border: const OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null; // kosong = tidak diretur
              final n = double.tryParse(v.trim().replaceAll(',', '.'));
              if (n == null || n < 0) return 'Qty tidak valid';
              if (n > it.sisa) return 'Maks ${fmtQty(it.sisa)}';
              return null;
            },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loadingList) {
      body = const LoadingView();
    } else if (_error != null) {
      body = ErrorView(message: _error!, onRetry: () {
        setState(() => _loadingList = true);
        _loadList();
      });
    } else if (_list.isEmpty) {
      body = const EmptyView(message: 'Belum ada transaksi barang keluar');
    } else {
      body = Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          DropdownButtonFormField<int>(
            isExpanded: true,
            value: _keluarId,
            decoration: const InputDecoration(labelText: 'Transaksi barang keluar', border: OutlineInputBorder()),
            items: _list
                .map((t) => DropdownMenuItem<int>(
              value: t.id,
              child: Text('${t.noTransaksi} - ${t.penerima}', overflow: TextOverflow.ellipsis),
            ))
                .toList(),
            onChanged: (v) {
              if (v != null) _selectKeluar(v);
            },
            validator: (v) => v == null ? 'Pilih transaksi barang keluar' : null,
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Tanggal retur: ${fmtDate(_tgl)}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _tgl, firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (d != null) setState(() => _tgl = d);
            },
          ),
          if (_loadingDetail) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
          if (_detail != null)
            KeyedSubtree(
              key: ValueKey(_gen),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tanggal keluar: ${_detail!.tanggal}', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                for (final it in _detail!.items) _itemField(it),
                TextFormField(
                  controller: _ket,
                  decoration: const InputDecoration(labelText: 'Keterangan (opsional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Simpan pengembalian'),
                ),
              ]),
            ),
        ]),
      );
    }
    return Scaffold(appBar: AppBar(title: const Text('Pengembalian Barang')), body: body);
  }
}
