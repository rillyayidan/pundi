# Catatan Privasi

Pundi dirancang sebagai aplikasi pencatat keuangan offline. Catatan ini membantu pengembang menjaga batasan privasi saat menambah fitur.

## Data lokal

- Transaksi, kategori, dompet, target tabungan, utang/piutang, dan lampiran struk disimpan di perangkat.
- OCR berjalan on-device melalui Google ML Kit; hasil scan tidak dikirim ke server aplikasi.
- Backup terenkripsi menggunakan password pengguna dan harus tetap dapat disimpan di lokasi pilihan pengguna.

## Hal yang harus dihindari

- Jangan menambahkan analytics, crash reporting, sinkronisasi cloud, atau endpoint jaringan tanpa keputusan produk eksplisit.
- Jangan mencatat isi struk, password backup, kunci database, atau data transaksi ke log debug permanen.
- Jangan menambahkan fixture yang berisi data finansial pribadi.

## Saat menambah fitur

Pastikan layar baru menjelaskan konsekuensi penyimpanan data bila fitur tersebut membuat salinan lampiran, backup, atau ekspor. Bila fitur membutuhkan izin Android baru, dokumentasikan alasan izin tersebut di pull request.
