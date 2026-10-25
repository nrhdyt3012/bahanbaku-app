const router = require('express').Router();
const { asyncHandler: a } = require('../middleware/errorHandler');
const c = require('../controllers/pengembalianController');
router.get('/', a(c.list));
router.get('/:id', a(c.detail));
router.post('/', a(c.create));
module.exports = router;