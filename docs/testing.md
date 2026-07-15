# Panduan Pengujian

Dokumen ini merangkum pemeriksaan minimum sebelum perubahan Pundi digabungkan.

## Pemeriksaan lokal

```bash
flutter pub get
flutter analyze
flutter test
```

Gunakan emulator atau perangkat Android untuk memeriksa alur yang bergantung pada plugin native, seperti kamera, pemilih gambar, autentikasi biometrik, notifikasi lokal, widget layar utama, dan penyimpanan aman.

## Area yang perlu diuji manual

- Input transaksi pemasukan dan pengeluaran dari tombol tambah cepat.
- Pemindaian struk dari kamera dan galeri, termasuk crop, rotasi, koreksi merchant, dan koreksi kategori.
- Transfer antar-dompet serta dampaknya pada saldo gabungan.
- Backup terenkripsi, restore backup baru, dan restore JSON lama.
- Pengingat transaksi berulang, pengingat backup, dan deep-link notifikasi.
- Pengunci aplikasi setelah boot perangkat baru dan saat kembali dari kamera atau aplikasi lain.

## Data uji

Gunakan data sintetis untuk merchant, nominal, catatan, dan lampiran. Jangan menambahkan foto struk nyata atau informasi finansial pribadi ke repository.
