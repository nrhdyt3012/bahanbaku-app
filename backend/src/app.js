require('dotenv').config();
const express = require('express');
const cors = require('cors');
const pool = require('./config/db');
const { notFound, errorHandler, asyncHandler } = require('./middleware/errorHandler');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/api/health', asyncHandler(async (req, res) => {
  await pool.query('SELECT 1');
  res.json({ success: true, message: 'API dan database berjalan' });
}));
app.use('/api/bahan-baku', require('./routes/bahanBaku'));
app.use('/api/keluar', require('./routes/keluar'));
app.use('/api/pengembalian', require('./routes/pengembalian'));
app.use('/api/stok', require('./routes/stok'));
app.use('/api/riwayat', require('./routes/riwayat'));

app.use(notFound);
app.use(errorHandler);

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => console.log(`API berjalan di http://localhost:${PORT}`));
