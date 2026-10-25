CREATE TABLE bahan_baku (
  id INT AUTO_INCREMENT PRIMARY KEY,
  kode VARCHAR(30) NOT NULL UNIQUE,
  nama VARCHAR(100) NOT NULL,
  satuan VARCHAR(20) NOT NULL,
  stok DECIMAL(12,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT chk_bahan_stok CHECK (stok >= 0)
) ENGINE=InnoDB;
CREATE TABLE transaksi_keluar (
  id INT AUTO_INCREMENT PRIMARY KEY,
  no_transaksi VARCHAR(40) NOT NULL UNIQUE,
  tanggal DATE NOT NULL,
  penerima VARCHAR(100) NOT NULL,
  keterangan TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
CREATE TABLE detail_keluar (
  id INT AUTO_INCREMENT PRIMARY KEY,
  keluar_id INT NOT NULL,
  bahan_id INT NOT NULL,
  qty DECIMAL(12,2) NOT NULL,
   CONSTRAINT chk_dk_qty CHECK (qty > 0),
  CONSTRAINT uq_dk UNIQUE (keluar_id, bahan_id),
  CONSTRAINT fk_dk_keluar FOREIGN KEY (keluar_id) REFERENCES transaksi_keluar(id) ON DELETE CASCADE,
  CONSTRAINT fk_dk_bahan FOREIGN KEY (bahan_id) REFERENCES bahan_baku(id)
) ENGINE=InnoDB;
CREATE TABLE transaksi_pengembalian (
  id INT AUTO_INCREMENT PRIMARY KEY,
  no_transaksi VARCHAR(40) NOT NULL UNIQUE,
  keluar_id INT NOT NULL,
  tanggal DATE NOT NULL,
  keterangan TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_tp_keluar FOREIGN KEY (keluar_id) REFERENCES transaksi_keluar(id)
) ENGINE=InnoDB;
CREATE TABLE detail_pengembalian (
  id INT AUTO_INCREMENT PRIMARY KEY,
  pengembalian_id INT NOT NULL,
  detail_keluar_id INT NOT NULL,
  bahan_id INT NOT NULL,
  qty DECIMAL(12,2) NOT NULL,
  CONSTRAINT chk_dp_qty CHECK (qty > 0),
  CONSTRAINT fk_dp_pengembalian FOREIGN KEY (pengembalian_id) REFERENCES transaksi_pengembalian(id) ON DELETE 
      CASCADE,
  CONSTRAINT fk_dp_detail_keluar FOREIGN KEY (detail_keluar_id) REFERENCES detail_keluar(id),
  CONSTRAINT fk_dp_bahan FOREIGN KEY (bahan_id) REFERENCES bahan_baku(id)
) ENGINE=InnoDB;
CREATE TABLE riwayat_stok (
  id INT AUTO_INCREMENT PRIMARY KEY,
  bahan_id INT NOT NULL,
  tipe ENUM('STOK_AWAL','KELUAR','KEMBALI') NOT NULL,
  qty DECIMAL(12,2) NOT NULL,
  stok_sebelum DECIMAL(12,2) NOT NULL,
  stok_sesudah DECIMAL(12,2) NOT NULL,
  ref_no VARCHAR(40) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_riwayat_bahan (bahan_id),
  INDEX idx_riwayat_tipe (tipe),
  CONSTRAINT fk_rs_bahan FOREIGN KEY (bahan_id) REFERENCES bahan_baku(id)
) ENGINE=InnoDB;