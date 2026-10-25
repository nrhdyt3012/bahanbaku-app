const pool = require('../config/db');
const AppError = require('../utils/AppError');

const TIPE = ['STOK_AWAL', 'KELUAR', 'KEMBALI'];

// Daftar stok terkini
exports.stok = async (q) => {
  const like = `%${(q || '').trim()}%`;
  const [rows] = await pool.query(
    'SELECT id, kode, nama, satuan, stok, updated_at FROM bahan_baku WHERE kode LIKE ? OR nama LIKE ? ORDER BY nama ASC',
    [like, like]
  );
  return rows;
};

// Riwayat pergerakan stok (ledger), terbaru di atas
exports.riwayat = async ({ bahan_id, tipe, limit }) => {
  const where = [];
  const params = [];
  if (bahan_id !== undefined && bahan_id !== '') {
    if (!Number.isInteger(Number(bahan_id))) throw new AppError(400, 'bahan_id tidak valid');
    where.push('r.bahan_id = ?');
    params.push(Number(bahan_id));
  }
  if (tipe) {
    if (!TIPE.includes(tipe)) throw new AppError(400, `tipe harus salah satu dari: ${TIPE.join(', ')}`);
    where.push('r.tipe = ?');
    params.push(tipe);
  }
  const lim = Math.min(Math.max(parseInt(limit, 10) || 200, 1), 500);
  params.push(lim);
  const [rows] = await pool.query(
    `SELECT r.id, r.tipe, r.qty, r.stok_sebelum, r.stok_sesudah, r.ref_no, r.created_at,
            b.id AS bahan_id, b.kode, b.nama, b.satuan
       FROM riwayat_stok r JOIN bahan_baku b ON b.id = r.bahan_id
       ${where.length ? 'WHERE ' + where.join(' AND ') : ''}
      ORDER BY r.id DESC LIMIT ?`,
    params
  );
  return rows;
};
