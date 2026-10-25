const svc = require('../services/pengembalianService');

exports.list = async (req, res) => res.json({ success: true, data: await svc.list() });
exports.detail = async (req, res) => res.json({ success: true, data: await svc.detail(req.params.id) });
exports.create = async (req, res) =>
  res.status(201).json({ success: true, message: 'Pengembalian barang berhasil dicatat', data: await svc.create(req.body || {}) });
