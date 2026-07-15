# Pundi

Pundi adalah aplikasi pencatat keuangan Flutter yang sepenuhnya offline. Pengguna dapat menambahkan pemasukan/pengeluaran secara manual atau memindai struk. Google ML Kit menjalankan OCR di perangkat, parser heuristik mengambil nominal, merchant, dan tanggal, lalu pengguna selalu memeriksa hasil sebelum menyimpan.

## Fitur

- Dashboard saldo, pemasukan/pengeluaran bulan berjalan, dan transaksi terbaru.
- Multi-dompet dengan saldo awal, transfer antar-dompet, serta saldo gabungan.
- Utang/piutang dengan jatuh tempo, progres pembayaran, dan pencatatan arus kas otomatis.
- CRUD transaksi lokal dengan halaman detail, catatan, tanggal/jam, edit, hapus, serta filter periode dan kategori.
- Kamera/galeri → crop/putar/perjelas gambar → OCR on-device → parser struk → konfirmasi yang dapat diedit.
- Saran kategori berbasis kata kunci merchant dan teks struk.
- Smart merchant memory: koreksi kategori merchant dipakai kembali secara lokal.
- Transaksi mingguan/bulanan berulang dengan konfirmasi, lewati, edit, dan pengingat lokal.
- Kategori khusus dengan pilihan ikon, warna, dan tipe transaksi.
- OCR line-item dan split receipt ke beberapa kategori dengan validasi jumlah terhadap total.
- Lampiran foto struk lokal yang dapat diperbesar atau dilepas.
- Pencarian riwayat berdasarkan merchant, catatan, kategori, atau nominal.
- Anggaran per kategori dengan peringatan eksplisit saat batas bulanan terlewati.
- Prediksi anggaran berbasis bulan berjalan dan rata-rata 3 bulan terakhir.
- Target tabungan yang terhubung ke dompet tujuan dan transfer setoran.
- Sampah transaksi 30 hari, pemulihan, hapus permanen, serta Undo.
- Donut chart kategori dan arus kas dengan rentang 7 hari, bulan berjalan, atau tanggal kustom.
- Deteksi transaksi ganda pada input dan impor CSV.
- Ekspor/impor CSV serta backup AES-256-GCM berpassword; restore JSON lama tetap didukung.
- Catat cepat dari tombol tambah dan widget layar utama Android.
- Pengingat backup berdasarkan usia/jumlah transaksi baru dan pengunci aplikasi sekali per sesi boot perangkat, sehingga kamera atau perpindahan aplikasi tidak memicu autentikasi ulang.
- Deep-link notifikasi, onboarding, data demo opsional, dan database SQLCipher terenkripsi.
- Material 3, tema terang/gelap, tanpa backend, akun, atau network call.

## Arsitektur

```text
UI screens/widgets
      ↓
Provider state (TransactionProvider, DashboardProvider, AppFeaturesProvider)
      ↓
Services (OCR, parser, notification, device security, export/backup)
      ↓
DatabaseHelper → SQLite on-device
```

`DatabaseHelper` menggunakan migrasi versi sejak awal. Instalasi lama dimigrasikan satu kali dari SQLite biasa ke SQLCipher dengan kunci acak di secure storage. Restore JSON berjalan di dalam transaksi database agar kegagalan validasi tidak meninggalkan data setengah terpulihkan.

## Dokumentasi pengembang

- [Changelog](CHANGELOG.md)
- [Panduan kontribusi](CONTRIBUTING.md)
- [Panduan pengujian](docs/testing.md)
- [Catatan privasi](docs/privacy.md)
- [Checklist rilis](docs/release-checklist.md)

## Menjalankan

Prasyarat: Flutter stable dengan Dart 3.8+, Android SDK, dan perangkat/emulator Android SDK 24+.

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Rilis Android:

```bash
flutter build apk --release
```

> Mengapa minSdk 24? Rilis terkini `image_picker` dan `path_provider` telah menaikkan dukungan minimum Android ke SDK 24.

## Privasi dan keterbatasan

Semua transaksi dan hasil OCR disimpan hanya di perangkat. Pundi tidak memiliki sinkronisasi cloud, sehingga uninstall dapat menghapus data. Gunakan menu **Pengaturan → Cadangkan terenkripsi** secara berkala, simpan berkas `.pundi` di lokasi aman, dan jangan lupakan password karena Pundi tidak menyimpannya.

OCR dipengaruhi cahaya, fokus kamera, dan tata letak struk. Pundi tidak pernah menyimpan hasil scan secara otomatis: nominal, merchant, tanggal, dan kategori selalu ditampilkan pada layar konfirmasi terlebih dahulu.

## Struktur utama

```text
lib/
├── database/   # schema, migrations, CRUD, aggregate queries
├── models/     # transaction, category, parsed receipt, recurrence, split
├── providers/  # application state
├── screens/    # home, add, history, scan, statistics, settings
├── services/   # OCR, parser, categorization, CSV/JSON
├── utils/      # categories and Indonesian formatting
└── widgets/    # reusable presentation components
```
