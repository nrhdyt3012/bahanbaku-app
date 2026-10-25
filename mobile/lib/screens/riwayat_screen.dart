import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/app_events.dart';
import '../utils/format.dart';
import '../widgets/state_views.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});
  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  static const _filters = <String?, String>{
    null: 'Semua',
    'KELUAR': 'Keluar',
    'KEMBALI': 'Kembali',
    'STOK_AWAL': 'Stok awal',
  };

  List<RiwayatItem> _items = [];
  String? _tipe;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    dataVersion.addListener(_load);
  }

  @override
  void dispose() {
    dataVersion.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getRiwayat(tipe: _tipe);
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

  (IconData, Color, String) _style(RiwayatItem r) {
    switch (r.tipe) {
      case 'KELUAR':
        return (Icons.arrow_upward, Colors.red.shade700, '-${fmtQty(r.qty)}');
      case 'KEMBALI':
        return (Icons.arrow_downward, Colors.green.shade700, '+${fmtQty(r.qty)}');
      default:
        return (Icons.inventory, Colors.blueGrey, '+${fmtQty(r.qty)}');
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
    if (_items.isEmpty) return const EmptyView(message: 'Belum ada riwayat', icon: Icons.history);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final r = _items[i];
          final (icon, color, label) = _style(r);
          return ListTile(
            leading: CircleAvatar(backgroundColor: color.withOpacity(0.12), child: Icon(icon, color: color)),
            title: Text(r.nama),
            subtitle: Text('${r.refNo ?? '-'}\n${fmtDateTime(r.createdAt)}   Stok ${fmtQty(r.stokSebelum)} → ${fmtQty(r.stokSesudah)}'),
            isThreeLine: true,
            trailing: Text('$label ${r.satuan}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Riwayat Transaksi')),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Wrap(spacing: 8, children: [
          for (final e in _filters.entries)
            ChoiceChip(
              label: Text(e.value),
              selected: _tipe == e.key,
              onSelected: (_) {
                setState(() {
                  _tipe = e.key;
                  _loading = true;
                });
                _load();
              },
            ),
        ]),
      ),
      Expanded(child: _body()),
    ]),
  );
}
