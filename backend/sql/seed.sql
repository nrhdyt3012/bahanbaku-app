USE bahan_baku_db;
INSERT INTO bahan_baku (kode, nama, satuan, stok) VALUES
  ('BB-001', 'Tepung Terigu', 'kg', 100),
  ('BB-002', 'Gula Pasir', 'kg', 50),
  ('BB-003', 'Minyak Goreng', 'liter', 40),
  ('BB-004', 'Telur Ayam', 'butir', 300);
INSERT INTO riwayat_stok (bahan_id, tipe, qty, stok_sebelum, stok_sesudah, ref_no)
SELECT id, 'STOK_AWAL', stok, 0, stok, 'SEED' FROM bahan_baku;