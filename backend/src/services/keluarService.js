const pool = require('../config/db');
const AppError = require('../utils/AppError');
const { round2, genNo, isValidDate, isValidQty, throwIfErrors } = require('../utils/helpers');

function validate({ tanggal, penerima, items }) {
  const errors = {};
  if (!isValidDate(tanggal)) errors.tanggal = 'Tanggal wajib diisi dengan format YYYY-MM-DD';
  if (typeof penerima !== 'string' || !penerima.trim()) errors.penerima = 'Penerima wajib diisi';
  else if (penerima.trim().length > 100) errors.penerima = 'Penerima maksimal 100 karakter';

  if (!Array.isArray(items) || items.length === 0) {
    errors.items = 'Minimal 1 item bahan baku';
  } else {
    const seen = new Set();
    items.forEach((it, i) => {
      if (!Number.isInteger(it?.bahan_id)) errors[`items[${i}].bahan_id`] = 'Bahan baku tidak valid';
      else if (seen.has(it.bahan_id)) errors[`items[${i}].bahan_id`] = 'Bahan baku duplikat dalam satu transaksi';
      else seen.add(it.bahan_id);
      if (!isValidQty(it?.qty)) errors[`items[${i}].qty`] = 'Qty harus angka > 0 (maks. 2 desimal)';
    });
  }
  throwIfErrors(errors);
}

exports.create = async (body) => {
  validate(body);
  const { tanggal, penerima, keterangan, items } = body;
  // Urutkan agar urutan penguncian baris konsisten (mencegah deadlock antar transaksi)
  const sorted = [...items].sort((a, b) => a.bahan_id - b.bahan_id);

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const noTrx = genNo('OUT');
    const [h] = await conn.query(
      'INSERT INTO transaksi_keluar (no_transaksi, tanggal, penerima, keterangan) VALUES (?,?,?,?)',
      [noTrx, tanggal, penerima.trim(), keterangan ? String(keterangan).trim() : null]
    );

    for (const it of sorted) {
      const qty = Number(it.qty);
      // FOR UPDATE: kunci baris bahan agar stok tidak berubah oleh transaksi lain
      const [rows] = await conn.query('SELECT id, kode, nama, satuan, stok FROM bahan_baku WHERE id=? FOR UPDATE', [it.bahan_id]);
      if (!rows.length) throw new AppError(404, `Bahan baku dengan id ${it.bahan_id} tidak ditemukan`);
      const b = rows[0];
      if (b.stok < qty) {
        throw new AppError(422, `Stok ${b.nama} tidak cukup (tersedia ${b.stok} ${b.satuan}, diminta ${qty} ${b.satuan})`);
      }
      const sesudah = round2(b.stok - qty);
      await conn.query('INSERT INTO detail_keluar (keluar_id, bahan_id, qty) VALUES (?,?,?)', [h.insertId, b.id, qty]);
      await conn.query('UPDATE bahan_baku SET stok=? WHERE id=?', [sesudah, b.id]);
      await conn.query(
        `INSERT INTO riwayat_stok (bahan_id, tipe, qty, stok_sebelum, stok_sesudah, ref_no)
         VALUES (?, 'KELUAR', ?, ?, ?, ?)`,
        [b.id, qty, b.stok, sesudah, noTrx]
      );
    }
    await conn.commit();
    return { id: h.insertId, no_transaksi: noTrx };
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
};

exports.list = async () => {
  const [rows] = await pool.query(
    `SELECT t.id, t.no_transaksi, t.tanggal, t.penerima, t.keterangan, t.created_at,
            COUNT(d.id) AS jumlah_item
       FROM transaksi_keluar t
       LEFT JOIN detail_keluar d ON d.keluar_id = t.id
      GROUP BY t.id
      ORDER BY t.id DESC`
  );
  return rows;
};

// Detail transaksi + sisa qty yang masih boleh dikembalikan per item
exports.detail = async (id) => {
  const [heads] = await pool.query('SELECT id, no_transaksi, tanggal, penerima, keterangan, created_at FROM transaksi_keluar WHERE id=?', [id]);
  if (!heads.length) throw new AppError(404, 'Transaksi barang keluar tidak ditemukan');
  const [items] = await pool.query(
    `SELECT d.id AS detail_keluar_id, d.bahan_id, b.kode, b.nama, b.satuan, d.qty,
            COALESCE(SUM(p.qty), 0) AS sudah_kembali,
            d.qty - COALESCE(SUM(p.qty), 0) AS sisa
       FROM detail_keluar d
       JOIN bahan_baku b ON b.id = d.bahan_id
       LEFT JOIN detail_pengembalian p ON p.detail_keluar_id = d.id
      WHERE d.keluar_id = ?
      GROUP BY d.id, d.bahan_id, b.kode, b.nama, b.satuan, d.qty
      ORDER BY d.id`,
    [id]
  );
  return { ...heads[0], items };
};
