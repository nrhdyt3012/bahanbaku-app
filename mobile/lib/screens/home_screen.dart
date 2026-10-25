import 'package:flutter/material.dart';
import 'keluar_form_screen.dart';
import 'pengembalian_form_screen.dart';
import 'riwayat_screen.dart';
import 'stok_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  // IndexedStack menjaga state tiap tab; sinkronisasi data lewat dataVersion
  final _pages = const [StokScreen(), KeluarFormScreen(), PengembalianFormScreen(), RiwayatScreen()];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _index, children: _pages),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Stok'),
        NavigationDestination(icon: Icon(Icons.output_outlined), selectedIcon: Icon(Icons.output), label: 'Keluar'),
        NavigationDestination(icon: Icon(Icons.assignment_return_outlined), selectedIcon: Icon(Icons.assignment_return), label: 'Retur'),
        NavigationDestination(icon: Icon(Icons.history), label: 'Riwayat'),
      ],
    ),
  );
}
