const router = require('express').Router();
const { asyncHandler: a } = require('../middleware/errorHandler');
const c = require('../controllers/bahanBakuController');
router.get('/', a(c.list));
router.get('/:id', a(c.get));
router.post('/', a(c.create));
router.put('/:id', a(c.update));
router.delete('/:id', a(c.remove));
module.exports = router;