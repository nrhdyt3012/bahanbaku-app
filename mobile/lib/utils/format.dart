/// 10.0 -> "10", 2.5 -> "2.5", 2.05 -> "2.05"
String fmtQty(num v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  var s = v.toStringAsFixed(2);
  s = s.replaceFirst(RegExp(r'0+$'), '');
  return s.replaceFirst(RegExp(r'\.$'), '');
}

String fmtDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// "2026-10-24 15:30:45" -> "24 Okt 2026, 15:30"
String fmtDateTime(String s) {
  const bln = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  final d = DateTime.tryParse(s.replaceFirst(' ', 'T'));
  if (d == null) return s;
  return '${d.day} ${bln[d.month - 1]} ${d.year}, '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
