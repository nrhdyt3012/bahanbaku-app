import 'package:flutter/foundation.dart';

/// Naik setiap kali ada data berubah (transaksi/master). Layar yang mendengarkan
/// akan memuat ulang datanya, karena IndexedStack menjaga semua tab tetap hidup.
final ValueNotifier<int> dataVersion = ValueNotifier<int>(0);

void notifyDataChanged() => dataVersion.value++;
