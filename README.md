# GitHub Actions Worker — Telegram Flutter Builder

Repository ini sudah disiapkan untuk kontrak worker yang dipakai bot:

- Flutter ZIP → `.github/workflows/build-flutter.yml`
- Web2APK → `.github/workflows/build-android.yml`
- Dispatch inputs: `jobId`, `userId`, `payload`
- Artifact wajib: `apk-<jobId>`
- Runner: `ubuntu-22.04`
- Flutter project lama dideteksi dari constraint Dart di `pubspec.yaml`
- Flutter modern memakai channel `stable` bila constraint-nya lebih baru dari mapping yang tersedia
- Java dipilih otomatis dari Gradle/AGP project

## Upload ke GitHub

1. Upload seluruh isi repo ke GitHub.
2. Pastikan folder `.github/workflows/` ikut ter-upload.
3. Di bot, tambahkan repo worker dengan command worker yang sudah tersedia di bot, misalnya `/addworkergithub`.
4. Gunakan workflow:
   - Flutter: `build-flutter.yml`
   - Android/Web2APK: `build-android.yml`
5. Token GitHub harus punya akses Actions + Contents untuk repo worker dan akses yang dibutuhkan bot untuk release/artifact.

## Secret bot

Jangan commit token Telegram/GitHub/Vercel ke source. Gunakan environment/secret. File `config.js` pada paket ini sudah diubah agar token dibaca dari environment.

Contoh nama environment tersedia di `.env.example`.

## Catatan kompatibilitas

Tidak ada sistem yang bisa menjamin 100% semua aplikasi Flutter di dunia berhasil build: project dapat memakai dependency yang sudah mati, SDK native yang hilang, kode Dart yang rusak, atau konfigurasi Android/iOS yang tidak kompatibel. Worker ini dibuat agar toolchain dipilih otomatis dan error build tetap berasal dari project yang sedang dibangun, bukan karena workflow dasar yang hilang.

## Kontrak artifact

Bot mencari artifact setelah run selesai. Workflow selalu menghasilkan satu file APK dan mengunggahnya dengan nama:

`apk-${jobId}`

Isi artifact adalah `${jobId}.apk`.

