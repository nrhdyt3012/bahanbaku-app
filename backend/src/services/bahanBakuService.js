const pool = require('../config/db');
const AppError = require('../utils/AppError');
const { isValidQty, throwIfErrors } = require('../utils/helpers');

function validate(body, { isCreate }) {
  const errors = {};
  const kode = (body.kode ?? '').toString().trim();
  const nama = (body.nama ?? '').toString().trim();
  const satuan = (body.satuan ?? '').toString().trim();

  if (!kode) errors.kode = 'Kode wajib diisi';
  else if (kode.length > 30) errors.kode = 'Kode maksimal 30 karakter';
  else if (!/^[A-Za-z0-9._-]+$/.test(kode)) errors.kode = 'Kode hanya boleh huruf, angka, titik, strip, dan underscore';

  if (!nama) errors.nama = 'Nama wajib diisi';
  else if (nama.length > 100) errors.nama = 'Nama maksimal 100 karakter';

  if (!satuan) errors.satuan = 'Satuan wajib diisi';
  else if (satuan.length > 20) errors.satuan = 'Satuan maksimal 20 karakter';

  let stok = 0;
  if (isCreate && body.stok !== undefined && body.stok !== null && body.stok !== '') {
    if (Number(body.stok) === 0) stok = 0;
    else if (!isValidQty(body.stok)) errors.stok = 'Stok awal harus angka >= 0 (maks. 2 desimal)';
    else stok = Number(body.stok);
  }
  throwIfErrors(errors);
  return { kode, nama, satuan, stok };
}

exports.list = async (q) => {
  const like = `%${(q || '').trim()}%`;
  const [rows] = await pool.query(
    'SELECT id, kode, nama, satuan, stok, created_at, updated_at FROM bahan_baku WHERE kode LIKE ? OR nama LIKE ? ORDER BY nama ASC',
    [like, like]
  );
  return rows;
};

exports.get = async (id) => {
  const [rows] = await pool.query('SELECT id, kode, nama, satuan, stok, created_at, updated_at FROM bahan_baku WHERE id = ?', [id]);
  if (!rows.length) throw new AppError(404, 'Bahan baku tidak ditemukan');
  return rows[0];
};

exports.create = async (body) => {
  const { kode, nama, satuan, stok } = validate(body, { isCreate: true });
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const [r] = await conn.query('INSERT INTO bahan_baku (kode, nama, satuan, stok) VALUES (?,?,?,?)', [kode, nama, satuan, stok]);
    if (stok > 0) {
      await conn.query(
        `INSERT INTO riwayat_stok (bahan_id, tipe, qty, stok_sebelum, stok_sesudah, ref_no)
         VALUES (?, 'STOK_AWAL', ?, 0, ?, ?)`,
        [r.insertId, stok, stok, kode]
      );
    }
    await conn.commit();
    return { id: r.insertId, kode, nama, satuan, stok };
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
};

// Stok TIDAK bisa diubah lewat update master; hanya lewat transaksi (keluar/kembali)
exports.update = async (id, body) => {
  const { kode, nama, satuan } = validate(body, { isCreate: false });
  const [r] = await pool.query('UPDATE bahan_baku SET kode=?, nama=?, satuan=? WHERE id=?', [kode, nama, satuan, id]);
  if (r.affectedRows === 0) throw new AppError(404, 'Bahan baku tidak ditemukan');
  return exports.get(id);
};

exports.remove = async (id) => {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const [rows] = await conn.query('SELECT id FROM bahan_baku WHERE id=? FOR UPDATE', [id]);
    if (!rows.length) throw new AppError(404, 'Bahan baku tidak ditemukan');
    const [[{ pakai }]] = await conn.query('SELECT COUNT(*) AS pakai FROM detail_keluar WHERE bahan_id=?', [id]);
    if (pakai > 0) throw new AppError(409, 'Bahan baku sudah dipakai di transaksi, tidak bisa dihapus');
    await conn.query('DELETE FROM riwayat_stok WHERE bahan_id=?', [id]);
    await conn.query('DELETE FROM bahan_baku WHERE id=?', [id]);
    await conn.commit();
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
};
