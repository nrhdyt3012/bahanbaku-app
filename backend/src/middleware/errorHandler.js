const AppError = require('../utils/AppError');

// Bungkus handler async agar error otomatis diteruskan ke errorHandler (Express 4)
exports.asyncHandler = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

exports.notFound = (req, res) =>
  res.status(404).json({ success: false, message: 'Endpoint tidak ditemukan' });

// eslint-disable-next-line no-unused-vars
exports.errorHandler = (err, req, res, next) => {
  if (err instanceof AppError) {
    return res.status(err.status).json({ success: false, message: err.message, errors: err.errors });
  }
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ success: false, message: 'Format JSON tidak valid' });
  }
  if (err.code === 'ER_DUP_ENTRY') {
    return res.status(409).json({ success: false, message: 'Data duplikat (misalnya kode sudah dipakai)' });
  }
  if (err.code === 'ER_ROW_IS_REFERENCED_2' || err.code === 'ER_ROW_IS_REFERENCED') {
    return res.status(409).json({ success: false, message: 'Data sudah dipakai transaksi, tidak bisa dihapus' });
  }
  if (err.code === 'ECONNREFUSED' || err.code === 'ER_ACCESS_DENIED_ERROR' || err.code === 'ER_BAD_DB_ERROR') {
    console.error('[DB]', err.code, err.message);
    return res.status(503).json({ success: false, message: 'Database tidak dapat diakses' });
  }
  console.error(err);
  return res.status(500).json({ success: false, message: 'Terjadi kesalahan pada server' });
};
