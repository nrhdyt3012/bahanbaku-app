import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/app_events.dart';
import '../utils/format.dart';
import '../widgets/state_views.dart';
import 'bahan_form_screen.dart';

class StokScreen extends StatefulWidget {
  const StokScreen({super.key});
  @override
  State<StokScreen> createState() => _StokScreenState();
}

class _StokScreenState extends State<StokScreen> {
  List<BahanBaku> _items = [];
  bool _loading = true;
  String? _error;
  String _q = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
    dataVersion.addListener(_load);
  }

  @override
  void dispose() {
    dataVersion.removeListener(_load);
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getStok(q: _q);
      if (!mounted) return;
      setState(() {
        _items = data;
        _error = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _q = v;
      _load();
    });
  }

  Future<void> _openForm([BahanBaku? b]) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => BahanFormScreen(bahan: b)));
  }

  Future<void> _delete(BahanBaku b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus bahan baku?'),
        content: Text('${b.nama} (${b.kode}) akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.deleteBahan(b.id);
      if (!mounted) return;
      showSuccess(context, 'Bahan baku dihapus');
      notifyDataChanged();
    } on ApiException catch (e) {
      if (!mounted) return;
      showError(context, e.fullMessage);
    }
  }

  Widget _body() {
    if (_loading) return const LoadingView();
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: () {
        setState(() => _loading = true);
        _load();
      });
    }
    if (_items.isEmpty) return const EmptyView(message: 'Belum ada data bahan baku');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final b = _items[i];
          return ListTile(
            title: Text(b.nama),
            subtitle: Text(b.kode),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(fmtQty(b.stok), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: b.stok <= 0 ? Colors.red : null)),
                Text(b.satuan, style: const TextStyle(color: Colors.grey)),
              ]),
              PopupMenuButton<String>(
                onSelected: (v) => v == 'edit' ? _openForm(b) : _delete(b),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                ],
              ),
            ]),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Stok Bahan Baku')),
    floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: TextField(
          onChanged: _onSearch,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari kode atau nama', border: OutlineInputBorder()),
        ),
      ),
      Expanded(child: _body()),
    ]),
  );
}
