import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/app_events.dart';
import '../utils/format.dart';
import '../widgets/state_views.dart';

class _Row {
  int? bahanId; // simpan ID (bukan objek) agar Dropdown tetap valid setelah data dimuat ulang
  final TextEditingController qty = TextEditingController();
}

class KeluarFormScreen extends StatefulWidget {
  const KeluarFormScreen({super.key});
  @override
  State<KeluarFormScreen> createState() => _KeluarFormScreenState();
}

class _KeluarFormScreenState extends State<KeluarFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _penerima = TextEditingController();
  final _ket = TextEditingController();
  DateTime _tgl = DateTime.now();
  List<BahanBaku> _bahan = [];
  List<_Row> _rows = [_Row()];
  int _gen = 0; // dinaikkan untuk mereset seluruh form setelah sukses
  bool _loading = true, _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBahan();
    dataVersion.addListener(_loadBahan);
  }

  @override
  void dispose() {
    dataVersion.removeListener(_loadBahan);
    _penerima.dispose();
    _ket.dispose();
    for (final r in _rows) {
      r.qty.dispose();
    }
    super.dispose();
  }

  BahanBaku? _byId(int? id) {
    for (final b in _bahan) {
      if (b.id == id) return b;
    }
    return null;
  }

  Future<void> _loadBahan() async {
    try {
      final data = await ApiService.getStok();
      if (!mounted) return;
      setState(() {
        _bahan = data;
        _error = null;
        _loading = false;
        for (final r in _rows) {
          if (_byId(r.bahanId) == null) r.bahanId = null; // bahan sudah dihapus
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _resetForm() {
    final old = _rows;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final r in old) {
        r.qty.dispose();
      }
    });
    setState(() {
      _rows = [_Row()];
      _penerima.clear();
      _ket.clear();
      _tgl = DateTime.now();
      _gen++;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ApiService.createKeluar({
        'tanggal': fmtDate(_tgl),
        'penerima': _penerima.text.trim(),
        'keterangan': _ket.text.trim().isEmpty ? null : _ket.text.trim(),
        'items': _rows
            .map((r) => {'bahan_id': r.bahanId, 'qty': double.parse(r.qty.text.trim().replaceAll(',', '.'))})
            .toList(),
      });
      if (!mounted) return;
      showSuccess(context, 'Barang keluar berhasil dicatat');
      _resetForm();
      notifyDataChanged(); // stok, retur, dan riwayat ikut diperbarui
    } on ApiException catch (e) {
      if (!mounted) return;
      showError(context, e.fullMessage);
      _loadBahan(); // stok mungkin sudah berubah oleh transaksi lain
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _itemRow(int i, _Row r) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        flex: 3,
        child: DropdownButtonFormField<int>(
          isExpanded: true,
          value: r.bahanId,
          decoration: const InputDecoration(labelText: 'Bahan', border: OutlineInputBorder()),
          items: _bahan
              .map((b) => DropdownMenuItem<int>(
            value: b.id,
            child: Text('${b.nama} (${fmtQty(b.stok)} ${b.satuan})', overflow: TextOverflow.ellipsis),
          ))
              .toList(),
          onChanged: (v) => setState(() => r.bahanId = v),
          validator: (v) {
            if (v == null) return 'Pilih bahan';
            if (_rows.where((x) => x.bahanId == v).length > 1) return 'Bahan duplikat';
            return null;
          },
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        flex: 2,
        child: TextFormField(
          controller: r.qty,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: 'Qty', suffixText: _byId(r.bahanId)?.satuan, border: const OutlineInputBorder()),
          validator: (v) {
            final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
            if (n == null || n <= 0) return 'Qty harus > 0';
            final b = _byId(r.bahanId);
            if (b != null && n > b.stok) return 'Maks ${fmtQty(b.stok)}';
            return null;
          },
        ),
      ),
      if (_rows.length > 1)
        IconButton(
          tooltip: 'Hapus item',
          icon: const Icon(Icons.delete_outline),
          onPressed: () {
            final removed = _rows[i];
            setState(() => _rows.removeAt(i));
            WidgetsBinding.instance.addPostFrameCallback((_) => removed.qty.dispose());
          },
        ),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const LoadingView();
    } else if (_error != null) {
      body = ErrorView(message: _error!, onRetry: () {
        setState(() => _loading = true);
        _loadBahan();
      });
    } else if (_bahan.isEmpty) {
      body = const EmptyView(message: 'Belum ada bahan baku.\nTambahkan di tab Stok.');
    } else {
      body = Form(
        key: _formKey,
        child: KeyedSubtree(
          key: ValueKey(_gen),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            TextFormField(
              controller: _penerima,
              decoration: const InputDecoration(labelText: 'Penerima / bagian', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Penerima wajib diisi' : null,
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Tanggal: ${fmtDate(_tgl)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: _tgl, firstDate: DateTime(2020), lastDate: DateTime(2100));
                if (d != null) setState(() => _tgl = d);
              },
            ),
            const Divider(),
            const Text('Item bahan baku', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (var i = 0; i < _rows.length; i++) _itemRow(i, _rows[i]),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _rows.add(_Row())),
                icon: const Icon(Icons.add),
                label: const Text('Tambah item'),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _ket,
              decoration: const InputDecoration(labelText: 'Keterangan (opsional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Simpan'),
            ),
          ]),
        ),
      );
    }
    return Scaffold(appBar: AppBar(title: const Text('Barang Keluar')), body: body);
  }
}
