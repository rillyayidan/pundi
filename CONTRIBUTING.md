# Panduan Kontribusi

Terima kasih sudah membantu pengembangan Pundi. Ikuti panduan singkat ini agar perubahan mudah ditinjau dan aman untuk aplikasi offline.

## Alur kerja

1. Buat branch kecil untuk satu topik perubahan.
2. Jalankan `flutter pub get` setelah mengubah dependency.
3. Jalankan `flutter analyze` dan `flutter test` sebelum membuka pull request.
4. Jelaskan dampak perubahan terhadap data lokal, migrasi database, atau izin perangkat bila relevan.

## Prinsip produk

- Pundi harus tetap offline-first dan tidak menambahkan network call tanpa alasan yang jelas.
- Data transaksi, OCR, backup, dan kunci enkripsi harus tetap berada di perangkat pengguna.
- Setiap hasil OCR atau parser yang berpotensi salah harus dapat dikoreksi pengguna sebelum disimpan.

## Gaya perubahan

- Prioritaskan perubahan kecil yang mudah direview.
- Tambahkan atau perbarui test untuk model, service, parser, dan migrasi database.
- Hindari menyimpan fixture yang berisi data pribadi atau foto struk nyata.
