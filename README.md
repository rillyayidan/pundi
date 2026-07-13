# Pundi

Pundi adalah aplikasi pencatat keuangan Flutter yang sepenuhnya offline. Pengguna dapat menambahkan pemasukan/pengeluaran secara manual atau memindai struk. Google ML Kit menjalankan OCR di perangkat, parser heuristik mengambil nominal, merchant, dan tanggal, lalu pengguna selalu memeriksa hasil sebelum menyimpan.

## Fitur

- Dashboard saldo, pemasukan/pengeluaran bulan berjalan, dan transaksi terbaru.
- CRUD transaksi lokal dengan halaman detail, catatan, tanggal/jam, edit, hapus, serta filter periode dan kategori.
- Kamera/galeri → OCR on-device → parser struk → konfirmasi yang dapat diedit.
- Saran kategori berbasis kata kunci merchant dan teks struk.
- Anggaran per kategori dengan peringatan eksplisit saat batas bulanan terlewati.
- Donut chart kategori dan arus kas dengan rentang 7 hari, bulan berjalan, atau tanggal kustom.
- Ekspor transaksi CSV serta backup/restore penuh dalam JSON.
- Material 3, tema terang/gelap, tanpa backend, akun, atau network call.

## Arsitektur

```text
UI screens/widgets
      ↓
Provider state (TransactionProvider, DashboardProvider)
      ↓
Services (OCR, parser, category suggestion, export/backup)
      ↓
DatabaseHelper → SQLite on-device
```

`DatabaseHelper` menggunakan migrasi versi sejak awal. Restore JSON berjalan di dalam transaksi SQLite agar kegagalan validasi tidak meninggalkan database setengah terpulihkan.

## Menjalankan

Prasyarat: Flutter stable dengan Dart 3.8+, Android SDK, dan perangkat/emulator Android SDK 24+.

```bash
flutter pub get
flutter test
flutter run
```

Rilis Android:

```bash
flutter build apk --release
```

> Mengapa minSdk 24? Rilis terkini `image_picker` dan `path_provider` telah menaikkan dukungan minimum Android ke SDK 24.

## Privasi dan keterbatasan

Semua transaksi dan hasil OCR disimpan hanya di perangkat. Pundi tidak memiliki sinkronisasi cloud, sehingga uninstall dapat menghapus data. Gunakan menu **Pengaturan → Cadangkan ke JSON** secara berkala dan simpan berkas di lokasi aman.

OCR dipengaruhi cahaya, fokus kamera, dan tata letak struk. Pundi tidak pernah menyimpan hasil scan secara otomatis: nominal, merchant, tanggal, dan kategori selalu ditampilkan pada layar konfirmasi terlebih dahulu.

## Struktur utama

```text
lib/
├── database/   # schema, migrations, CRUD, aggregate queries
├── models/     # transaction, category, parsed receipt
├── providers/  # application state
├── screens/    # home, add, history, scan, statistics, settings
├── services/   # OCR, parser, categorization, CSV/JSON
├── utils/      # categories and Indonesian formatting
└── widgets/    # reusable presentation components
```
