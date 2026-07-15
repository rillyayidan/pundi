# Checklist Rilis

Gunakan checklist ini sebelum membuat build rilis Android Pundi.

## Sebelum build

- Pastikan `pubspec.yaml` memiliki nomor versi dan build number yang sesuai.
- Jalankan `flutter pub get`, `flutter analyze`, dan `flutter test`.
- Uji migrasi database dari instalasi lama bila ada perubahan schema.
- Uji backup terenkripsi dan restore pada perangkat atau emulator bersih.
- Verifikasi ikon, nama aplikasi, tema terang/gelap, dan izin Android.

## Build

```bash
flutter build apk --release
```

## Setelah build

- Instal APK rilis pada perangkat uji.
- Uji alur tambah transaksi, scan struk, transfer dompet, backup, restore, dan pengunci aplikasi.
- Catat perubahan penting di `CHANGELOG.md` sebelum tag rilis dibuat.
