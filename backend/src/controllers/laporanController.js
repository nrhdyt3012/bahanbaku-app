const svc = require('../services/laporanService');
exports.stok = async (req, res) => res.json({ success: true, data: await svc.stok(req.query.q) });
exports.riwayat = async (req, res) => res.json({ success: true, data: await svc.riwayat(req.query) });