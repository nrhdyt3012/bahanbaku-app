require('dotenv').config();
const mysql = require('mysql2/promise');

// decimalNumbers: kolom DECIMAL dikembalikan sebagai number (bukan string)
// dateStrings: kolom DATE/TIMESTAMP dikembalikan sebagai string (tanpa konversi timezone)
module.exports = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'bahan_baku_db',
  waitForConnections: true,
  connectionLimit: 10,
  decimalNumbers: true,
  dateStrings: true,
});
