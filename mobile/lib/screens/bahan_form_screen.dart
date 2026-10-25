import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/app_events.dart';
import '../utils/format.dart';
import '../widgets/state_views.dart';

class BahanFormScreen extends StatefulWidget {
  final BahanBaku? bahan; // null = tambah baru
  const BahanFormScreen({super.key, this.bahan});
  @override
  State<BahanFormScreen> createState() => _BahanFormScreenState();
}

class _BahanFormScreenState extends State<BahanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kode = TextEditingController(text: widget.bahan?.kode);
  late final TextEditingController _nama = TextEditingController(text: widget.bahan?.nama);
  late final TextEditingController _satuan = TextEditingController(text: widget.bahan?.satuan);
  final _stok = TextEditingController();
  Map<String, String> _serverErr = {}; // pesan validasi dari backend per field
  bool _saving = false;

  bool get _isEdit => widget.bahan != null;

  @override
  void dispose() {
    _kode.dispose();
    _nama.dispose();
    _satuan.dispose();
    _stok.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _serverErr = {};
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final body = {
      'kode': _kode.text.trim(),
      'nama': _nama.text.trim(),
      'satuan': _satuan.text.trim(),
      if (!_isEdit && _stok.text.trim().isNotEmpty) 'stok': double.parse(_stok.text.trim().replaceAll(',', '.')),
    };
    try {
      if (_isEdit) {
        await ApiService.updateBahan(widget.bahan!.id, body);
      } else {
        await ApiService.createBahan(body);
      }
      notifyDataChanged();
      if (!mounted) return;
      showSuccess(context, _isEdit ? 'Bahan baku diubah' : 'Bahan baku ditambahkan');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      _serverErr = (e.errors ?? {}).map((k, v) => MapEntry(k, v.toString()));
      setState(() {});
      _formKey.currentState!.validate(); // tampilkan pesan backend di bawah field
      showError(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_isEdit ? 'Edit Bahan Baku' : 'Tambah Bahan Baku')),
    body: Form(
      key: _formKey,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        TextFormField(
          controller: _kode,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Kode', border: OutlineInputBorder()),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Kode wajib diisi' : _serverErr['kode'],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nama,
          decoration: const InputDecoration(labelText: 'Nama', border: OutlineInputBorder()),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : _serverErr['nama'],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _satuan,
          decoration: const InputDecoration(labelText: 'Satuan (kg, liter, pcs ...)', border: OutlineInputBorder()),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Satuan wajib diisi' : _serverErr['satuan'],
        ),
        const SizedBox(height: 12),
        if (_isEdit)
          Text('Stok saat ini: ${fmtQty(widget.bahan!.stok)} ${widget.bahan!.satuan}\n'
              'Stok hanya berubah lewat transaksi barang keluar / pengembalian.',
              style: const TextStyle(color: Colors.grey))
        else
          TextFormField(
            controller: _stok,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Stok awal (opsional)', border: OutlineInputBorder()),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return _serverErr['stok'];
              final n = double.tryParse(v.trim().replaceAll(',', '.'));
              if (n == null || n < 0) return 'Stok awal harus angka >= 0';
              return _serverErr['stok'];
            },
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
