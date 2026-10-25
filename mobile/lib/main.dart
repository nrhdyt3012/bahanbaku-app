import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() => runApp(const BahanBakuApp());

class BahanBakuApp extends StatelessWidget {
  const BahanBakuApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Bahan Baku',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
    home: const HomeScreen(),
  );
}
