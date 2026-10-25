import 'package:dio/dio.dart';
import '../config.dart';
import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  final Map<String, dynamic>? errors;
  ApiException(this.message, [this.errors]);

  /// Pesan + detail per field (kalau ada), untuk ditampilkan di snackbar.
  String get fullMessage {
    if (errors == null || errors!.isEmpty) return message;
    return '$message:\n${errors!.values.map((e) => '• $e').join('\n')}';
  }

  @override
  String toString() => message;
}

class ApiService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  /// Semua request lewat sini: ambil field `data`, dan ubah error jadi ApiException.
  static Future<dynamic> _call(Future<Response> Function() fn) async {
    try {
      final r = await fn();
      final body = r.data;
      return body is Map ? body['data'] : null;
    } on DioException catch (e) {
      final d = e.response?.data;
      if (d is Map && d['message'] != null) {
        throw ApiException(d['message'].toString(), (d['errors'] as Map?)?.cast<String, dynamic>());
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw ApiException('Tidak dapat terhubung ke server. Periksa koneksi dan alamat API ($baseUrl).');
      }
      throw ApiException('Terjadi kesalahan tak terduga');
    }
  }

  static Map<String, dynamic> _q(Map<String, dynamic> m) =>
      Map.fromEntries(m.entries.where((e) => e.value != null && e.value.toString().isNotEmpty));

  // ---- Master & stok ----
  static Future<List<BahanBaku>> getStok({String? q}) async {
    final d = await _call(() => _dio.get('/stok', queryParameters: _q({'q': q})));
    return (d as List).map((e) => BahanBaku.fromJson(e)).toList();
  }

  static Future<void> createBahan(Map<String, dynamic> body) => _call(() => _dio.post('/bahan-baku', data: body));
  static Future<void> updateBahan(int id, Map<String, dynamic> body) => _call(() => _dio.put('/bahan-baku/$id', data: body));
  static Future<void> deleteBahan(int id) => _call(() => _dio.delete('/bahan-baku/$id'));

  // ---- Barang keluar ----
  static Future<void> createKeluar(Map<String, dynamic> body) => _call(() => _dio.post('/keluar', data: body));

  static Future<List<KeluarSummary>> getKeluar() async {
    final d = await _call(() => _dio.get('/keluar'));
    return (d as List).map((e) => KeluarSummary.fromJson(e)).toList();
  }

  static Future<KeluarDetail> getKeluarDetail(int id) async {
    final d = await _call(() => _dio.get('/keluar/$id'));
    return KeluarDetail.fromJson(d as Map<String, dynamic>);
  }

  // ---- Pengembalian ----
  static Future<void> createPengembalian(Map<String, dynamic> body) => _call(() => _dio.post('/pengembalian', data: body));

  // ---- Riwayat ----
  static Future<List<RiwayatItem>> getRiwayat({String? tipe}) async {
    final d = await _call(() => _dio.get('/riwayat', queryParameters: _q({'tipe': tipe})));
    return (d as List).map((e) => RiwayatItem.fromJson(e)).toList();
  }
}
