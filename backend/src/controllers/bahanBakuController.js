const svc = require('../services/bahanBakuService');

exports.list = async (req, res) => res.json({ success: true, data: await svc.list(req.query.q) });
exports.get = async (req, res) => res.json({ success: true, data: await svc.get(req.params.id) });
exports.create = async (req, res) =>
  res.status(201).json({ success: true, message: 'Bahan baku berhasil ditambahkan', data: await svc.create(req.body || {}) });
exports.update = async (req, res) =>
  res.json({ success: true, message: 'Bahan baku berhasil diubah', data: await svc.update(req.params.id, req.body || {}) });
exports.remove = async (req, res) => {
  await svc.remove(req.params.id);
  res.json({ success: true, message: 'Bahan baku berhasil dihapus', data: null });
};
