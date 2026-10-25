const router = require('express').Router();
const { asyncHandler: a } = require('../middleware/errorHandler');
const c = require('../controllers/laporanController');
router.get('/', a(c.stok));
module.exports = router;