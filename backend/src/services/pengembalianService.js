const pool = require('../config/db');
const AppError = require('../utils/AppError');
const { round2, genNo, isValidDate, isValidQty, throwIfErrors } = require('../utils/helpers');

function validate({ keluar_id, tanggal, items }) {
  const errors = {};
  if (!Number.isInteger(keluar_id)) errors.keluar_id = 'Transaksi barang keluar wajib dipilih';
  if (!isValidDate(tanggal)) errors.tanggal = 'Tanggal wajib diisi dengan format YYYY-MM-DD';
  if (!Array.isArray(items) || items.length === 0) {
    errors.items = 'Minimal 1 item yang dikembalikan';
  } else {
    const seen = new Set();
    items.forEach((it, i) => {
      if (!Number.isInteger(it?.detail_keluar_id)) errors[`items[${i}].detail_keluar_id`] = 'Item tidak valid';
      else if (seen.has(it.detail_keluar_id)) errors[`items[${i}].detail_keluar_id`] = 'Item duplikat';
      else seen.add(it.detail_keluar_id);
      if (!isValidQty(it?.qty)) errors[`items[${i}].qty`] = 'Qty harus angka > 0 (maks. 2 desimal)';
    });
  }
  throwIfErrors(errors);
}

exports.create = async (body) => {
  validate(body);
  const { keluar_id, tanggal, keterangan, items } = body;
  const sorted = [...items].sort((a, b) => a.detail_keluar_id - b.detail_keluar_id);

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const [heads] = await conn.query('SELECT id FROM transaksi_keluar WHERE id=?', [keluar_id]);
    if (!heads.length) throw new AppError(404, 'Transaksi barang keluar tidak ditemukan');

    const noTrx = genNo('RET');
    const [h] = await conn.query(
      'INSERT INTO transaksi_pengembalian (no_transaksi, keluar_id, tanggal, keterangan) VALUES (?,?,?,?)',
      [noTrx, keluar_id, tanggal, keterangan ? String(keterangan).trim() : null]
    );

    for (const it of sorted) {
      const qty = Number(it.qty);
      // Kunci baris detail_keluar: dua retur bersamaan untuk item yang sama jadi antre
      const [dk] = await conn.query(
        'SELECT id, bahan_id, qty FROM detail_keluar WHERE id=? AND keluar_id=? FOR UPDATE',
        [it.detail_keluar_id, keluar_id]
      );
      if (!dk.length) throw new AppError(404, `Item ${it.detail_keluar_id} bukan bagian dari transaksi keluar ini`);

      const [[{ kembali }]] = await conn.query(
        'SELECT COALESCE(SUM(qty), 0) AS kembali FROM detail_pengembalian WHERE detail_keluar_id=?',
        [dk[0].id]
      );
      const sisa = round2(dk[0].qty - kembali);
      if (qty > sisa) {
        throw new AppError(422, `Qty retur melebihi sisa yang bisa dikembalikan (keluar ${dk[0].qty}, sudah kembali ${kembali}, sisa ${sisa})`);
      }

      const [[b]] = await conn.query('SELECT id, stok FROM bahan_baku WHERE id=? FOR UPDATE', [dk[0].bahan_id]);
      const sesudah = round2(b.stok + qty);
      await conn.query(
        'INSERT INTO detail_pengembalian (pengembalian_id, detail_keluar_id, bahan_id, qty) VALUES (?,?,?,?)',
        [h.insertId, dk[0].id, b.id, qty]
      );
      await conn.query('UPDATE bahan_baku SET stok=? WHERE id=?', [sesudah, b.id]);
      await conn.query(
        `INSERT INTO riwayat_stok (bahan_id, tipe, qty, stok_sebelum, stok_sesudah, ref_no)
         VALUES (?, 'KEMBALI', ?, ?, ?, ?)`,
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
    `SELECT p.id, p.no_transaksi, p.tanggal, p.keterangan, p.created_at,
            p.keluar_id, k.no_transaksi AS no_keluar, k.penerima,
            COUNT(d.id) AS jumlah_item
       FROM transaksi_pengembalian p
       JOIN transaksi_keluar k ON k.id = p.keluar_id
       LEFT JOIN detail_pengembalian d ON d.pengembalian_id = p.id
      GROUP BY p.id, k.no_transaksi, k.penerima
      ORDER BY p.id DESC`
  );
  return rows;
};

exports.detail = async (id) => {
  const [heads] = await pool.query(
    `SELECT p.id, p.no_transaksi, p.tanggal, p.keterangan, p.created_at, p.keluar_id, k.no_transaksi AS no_keluar
       FROM transaksi_pengembalian p JOIN transaksi_keluar k ON k.id = p.keluar_id WHERE p.id=?`,
    [id]
  );
  if (!heads.length) throw new AppError(404, 'Transaksi pengembalian tidak ditemukan');
  const [items] = await pool.query(
    `SELECT d.id, d.detail_keluar_id, d.bahan_id, b.kode, b.nama, b.satuan, d.qty
       FROM detail_pengembalian d JOIN bahan_baku b ON b.id = d.bahan_id
      WHERE d.pengembalian_id=? ORDER BY d.id`,
    [id]
  );
  return { ...heads[0], items };
};
