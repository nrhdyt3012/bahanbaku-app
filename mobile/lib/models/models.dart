double _d(dynamic v) => v is num ? v.toDouble() : double.parse(v.toString());
int _i(dynamic v) => v is int ? v : int.parse(v.toString());

class BahanBaku {
  final int id;
  final String kode, nama, satuan;
  final double stok;
  BahanBaku({required this.id, required this.kode, required this.nama, required this.satuan, required this.stok});

  factory BahanBaku.fromJson(Map<String, dynamic> j) => BahanBaku(
    id: _i(j['id']),
    kode: j['kode'],
    nama: j['nama'],
    satuan: j['satuan'],
    stok: _d(j['stok']),
  );
}

class KeluarSummary {
  final int id, jumlahItem;
  final String noTransaksi, tanggal, penerima;
  KeluarSummary({required this.id, required this.jumlahItem, required this.noTransaksi, required this.tanggal, required this.penerima});

  factory KeluarSummary.fromJson(Map<String, dynamic> j) => KeluarSummary(
    id: _i(j['id']),
    jumlahItem: _i(j['jumlah_item']),
    noTransaksi: j['no_transaksi'],
    tanggal: j['tanggal'],
    penerima: j['penerima'],
  );
}

class KeluarItem {
  final int detailKeluarId, bahanId;
  final String kode, nama, satuan;
  final double qty, sudahKembali, sisa;
  KeluarItem({
    required this.detailKeluarId, required this.bahanId, required this.kode, required this.nama,
    required this.satuan, required this.qty, required this.sudahKembali, required this.sisa,
  });

  factory KeluarItem.fromJson(Map<String, dynamic> j) => KeluarItem(
    detailKeluarId: _i(j['detail_keluar_id']),
    bahanId: _i(j['bahan_id']),
    kode: j['kode'],
    nama: j['nama'],
    satuan: j['satuan'],
    qty: _d(j['qty']),
    sudahKembali: _d(j['sudah_kembali']),
    sisa: _d(j['sisa']),
  );
}

class KeluarDetail {
  final int id;
  final String noTransaksi, tanggal, penerima;
  final List<KeluarItem> items;
  KeluarDetail({required this.id, required this.noTransaksi, required this.tanggal, required this.penerima, required this.items});

  factory KeluarDetail.fromJson(Map<String, dynamic> j) => KeluarDetail(
    id: _i(j['id']),
    noTransaksi: j['no_transaksi'],
    tanggal: j['tanggal'],
    penerima: j['penerima'],
    items: (j['items'] as List).map((e) => KeluarItem.fromJson(e)).toList(),
  );
}

class RiwayatItem {
  final int id;
  final String tipe, kode, nama, satuan, createdAt;
  final String? refNo;
  final double qty, stokSebelum, stokSesudah;
  RiwayatItem({
    required this.id, required this.tipe, required this.kode, required this.nama, required this.satuan,
    required this.createdAt, required this.refNo, required this.qty, required this.stokSebelum, required this.stokSesudah,
  });

  factory RiwayatItem.fromJson(Map<String, dynamic> j) => RiwayatItem(
    id: _i(j['id']),
    tipe: j['tipe'],
    kode: j['kode'],
    nama: j['nama'],
    satuan: j['satuan'],
    createdAt: j['created_at'],
    refNo: j['ref_no'],
    qty: _d(j['qty']),
    stokSebelum: _d(j['stok_sebelum']),
    stokSesudah: _d(j['stok_sesudah']),
  );
}
