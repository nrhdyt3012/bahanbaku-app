const AppError = require('./AppError');
const round2 = (n) => Math.round(n * 100) / 100;
// Nomor transaksi: OUT-20261024-153045-123
function genNo(prefix) {
  const d = new Date();
  const p = (n, l = 2) => String(n).padStart(l, '0');
  const stamp = `${d.getFullYear()}${p(d.getMonth() + 
      1)}${p(d.getDate())}-${p(d.getHours())}${p(d.getMinutes())}${p(d.getSeconds())}`;
  return `${prefix}-${stamp}-${p(Math.floor(Math.random() * 1000), 3)}`;
}
function isValidDate(s) {
  if (typeof s !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(s)) return false;
  const d = new Date(`${s}T00:00:00Z`);
  return !Number.isNaN(d.getTime()) && d.toISOString().slice(0, 10) === s;
}
// Angka > 0, maksimal 2 desimal (sesuai DECIMAL(12,2)), batas atas wajar
function isValidQty(v) {
  const n = Number(v);
  if (v === null || v === '' || typeof v === 'boolean' || !Number.isFinite(n)) return false;
  if (n <= 0 || n > 1e9) return false;
  return Math.abs(n * 100 - Math.round(n * 100)) < 1e-6;
}
function throwIfErrors(errors) {
  if (Object.keys(errors).length) throw new AppError(422, 'Validasi gagal', errors);
}
module.exports = { round2, genNo, isValidDate, isValidQty, throwIfErrors };