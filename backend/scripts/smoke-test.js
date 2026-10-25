// Uji alur bisnis utama. Jalankan API dulu (npm run dev), lalu: npm run test:smoke
// Catatan: skrip ini membuat data uji baru di database yang sedang dipakai.
const BASE = process.env.API_URL || 'http://localhost:3000/api';
let pass = 0, fail = 0;

async function call(method, path, body) {
  const res = await fetch(BASE + path, {
    method,
    headers: { 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
  });
  return { status: res.status, json: await res.json() };
}
function check(name, cond, extra = '') {
  if (cond) { pass++; console.log(`  OK    ${name}`); }
  else { fail++; console.log(`  GAGAL ${name} ${extra}`); }
}

(async () => {
  const today = new Date().toISOString().slice(0, 10);
  const kode = 'T' + Date.now().toString().slice(-8);

  console.log('1. Master bahan baku');
  let r = await call('POST', '/bahan-baku', { kode, nama: 'Bahan Uji', satuan: 'kg', stok: 10 });
  check('tambah bahan -> 201', r.status === 201, JSON.stringify(r.json));
  const bid = r.json.data?.id;
  r = await call('POST', '/bahan-baku', { kode, nama: 'Duplikat', satuan: 'kg' });
  check('kode duplikat -> 409', r.status === 409);
  r = await call('POST', '/bahan-baku', { kode: '', nama: '', satuan: '' });
  check('field kosong -> 422', r.status === 422 && r.json.errors?.kode);

  console.log('2. Barang keluar');
  r = await call('POST', '/keluar', { tanggal: today, penerima: 'Produksi', items: [{ bahan_id: bid, qty: 4 }] });
  check('keluar 4 dari 10 -> 201', r.status === 201, JSON.stringify(r.json));
  const keluarId = r.json.data?.id;
  r = await call('GET', `/bahan-baku/${bid}`);
  check('stok jadi 6', r.json.data?.stok === 6, `stok=${r.json.data?.stok}`);

  r = await call('POST', '/keluar', { tanggal: today, penerima: 'Produksi', items: [{ bahan_id: bid, qty: 7 }] });
  check('keluar melebihi stok -> 422', r.status === 422, r.json.message);
  r = await call('GET', `/bahan-baku/${bid}`);
  check('stok tetap 6 (rollback)', r.json.data?.stok === 6);
  const list = await call('GET', '/keluar');
  check('transaksi gagal tidak tersimpan', list.json.data.filter((t) => t.penerima === 'Produksi' && t.id > keluarId).length === 0);

  r = await call('POST', '/keluar', { tanggal: today, penerima: 'X', items: [{ bahan_id: bid, qty: -1 }] });
  check('qty negatif -> 422', r.status === 422);
  r = await call('POST', '/keluar', { tanggal: today, penerima: 'X', items: [] });
  check('tanpa item -> 422', r.status === 422);
  r = await call('POST', '/keluar', { tanggal: '24-10-2026', penerima: 'X', items: [{ bahan_id: bid, qty: 1 }] });
  check('format tanggal salah -> 422', r.status === 422);
  r = await call('POST', '/keluar', { tanggal: today, penerima: 'X', items: [{ bahan_id: bid, qty: 1 }, { bahan_id: bid, qty: 1 }] });
  check('bahan duplikat -> 422', r.status === 422);

  console.log('3. Pengembalian');
  r = await call('GET', `/keluar/${keluarId}`);
  const item = r.json.data?.items?.[0];
  check('detail menampilkan sisa 4', item?.sisa === 4, JSON.stringify(item));
  r = await call('POST', '/pengembalian', { keluar_id: keluarId, tanggal: today, items: [{ detail_keluar_id: item.detail_keluar_id, qty: 5 }] });
  check('retur 5 > sisa 4 -> 422', r.status === 422, r.json.message);
  r = await call('POST', '/pengembalian', { keluar_id: keluarId, tanggal: today, items: [{ detail_keluar_id: item.detail_keluar_id, qty: 3 }] });
  check('retur 3 -> 201', r.status === 201, JSON.stringify(r.json));
  r = await call('GET', `/bahan-baku/${bid}`);
  check('stok jadi 9', r.json.data?.stok === 9, `stok=${r.json.data?.stok}`);
  r = await call('POST', '/pengembalian', { keluar_id: keluarId, tanggal: today, items: [{ detail_keluar_id: item.detail_keluar_id, qty: 2 }] });
  check('retur 2 > sisa 1 -> 422', r.status === 422, r.json.message);
  r = await call('POST', '/pengembalian', { keluar_id: keluarId, tanggal: today, items: [{ detail_keluar_id: item.detail_keluar_id, qty: 1 }] });
  check('retur sisa 1 -> 201', r.status === 201);
  r = await call('GET', `/bahan-baku/${bid}`);
  check('stok kembali 10', r.json.data?.stok === 10);

  console.log('4. Konkurensi (10 request keluar bersamaan, stok 10, masing-masing 3)');
  const results = await Promise.all(
    Array.from({ length: 10 }, () => call('POST', '/keluar', { tanggal: today, penerima: 'Paralel', items: [{ bahan_id: bid, qty: 3 }] }))
  );
  const ok = results.filter((x) => x.status === 201).length;
  r = await call('GET', `/bahan-baku/${bid}`);
  check(`hanya 3 yang sukses (dapat ${ok}) dan stok akhir 1`, ok === 3 && r.json.data?.stok === 1, `stok=${r.json.data?.stok}`);

  console.log('5. Riwayat & stok');
  r = await call('GET', `/riwayat?bahan_id=${bid}`);
  const tipe = r.json.data.map((x) => x.tipe);
  check('riwayat berisi STOK_AWAL, KELUAR, KEMBALI', ['STOK_AWAL', 'KELUAR', 'KEMBALI'].every((t) => tipe.includes(t)));
  const konsisten = r.json.data.every((x) => (x.tipe === 'KELUAR' ? x.stok_sebelum - x.qty === x.stok_sesudah : x.tipe === 'KEMBALI' ? x.stok_sebelum + x.qty === x.stok_sesudah : true));
  check('stok_sebelum/sesudah konsisten dengan qty', konsisten);
  r = await call('GET', '/riwayat?tipe=SALAH');
  check('filter tipe tidak valid -> 400', r.status === 400);
  r = await call('GET', '/stok?q=Bahan Uji');
  check('pencarian stok', r.status === 200 && r.json.data.length >= 1);

  console.log('6. Hapus master');
  r = await call('DELETE', `/bahan-baku/${bid}`);
  check('hapus bahan yang sudah dipakai -> 409', r.status === 409);
  const k2 = 'D' + Date.now().toString().slice(-8);
  r = await call('POST', '/bahan-baku', { kode: k2, nama: 'Sementara', satuan: 'pcs', stok: 5 });
  r = await call('DELETE', `/bahan-baku/${r.json.data.id}`);
  check('hapus bahan belum dipakai -> 200', r.status === 200);

  console.log(`\nHasil: ${pass} lulus, ${fail} gagal`);
  process.exit(fail ? 1 : 0);
})().catch((e) => { console.error('Tidak bisa menghubungi API:', e.message); process.exit(1); });
