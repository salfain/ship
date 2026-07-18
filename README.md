# Ship Monitoring Flutter

Migrasi awal aplikasi Ship Monitoring dari Android Kotlin/Jetpack Compose ke Flutter.

## Status Phase

- Phase 0: review PRD dan repo acuan selesai.
- Phase 1: project Flutter, theme Material 3, komponen reusable, environment, dan routing dasar selesai.
- Phase 2: fondasi auth, secure storage session, Dio interceptor, dan role navigation tersedia.
- Phase 3: modul Nakhoda inti tersedia: data kapal saya, dashboard dinamis, riwayat pengajuan, detail pengajuan, form pengajuan 4 PDF, dan kirim lokasi GPS.
- Phase 4: modul Admin inti tersedia: dashboard dinamis, daftar pengajuan, detail verifikasi, approve/reject dengan catatan, data kapal, history kapal, lokasi kapal, checklist cek kedatangan tanpa upload dokumen, serta pembuatan akun pengguna dan penambahan kapal dari Profil Admin.
- Phase 5: modul Manager/Kepala KSOP inti tersedia: dashboard dinamis, antrian keputusan, detail & approve/reject akhir, data kapal, history kapal, lokasi kapal, dan laporan ringkas.
- Phase 6: Maps, lokasi, dan monitoring tersedia: permission GPS, kirim koordinat Nakhoda, komponen marker kapal reusable, refresh lokasi, dan fallback preview saat API key Maps belum diisi.
- Phase 7: file, dokumen, dan validasi tersedia: validasi PDF berdasarkan ekstensi, MIME, ukuran, file kosong, preview nama/ukuran file, upload multipart, dan pesan error saat dokumen URL tidak bisa dibuka.
- Phase 8: UI polish dan hardening berjalan: tombol header menjadi logout, summary card responsif, format tanggal tahan error locale, dan placeholder modul lama sudah tidak ada di source aplikasi.
- Phase 9: release preparation tersedia: package Android `id.ksop.shipmonitoring`, konfigurasi release/testing, dokumentasi instalasi, dan build APK release.

## Catatan Implementasi

- Endpoint auth mengikuti repo acuan: `POST /auth/login` dengan base URL dari `.env`.
- Role routing mendukung `NAHKODA`, `ADMIN`, dan `MANAGER`.
- Kontrak pengajuan repo lama memakai empat dokumen PDF wajib: `sailingPermit`, `callSignCertificate`, `safetyCertificate`, dan `radioStationPermit`.
- Pemilihan file disiapkan memakai `file_selector`; `file_picker` tidak dipakai karena gagal build pada kombinasi Flutter 3.44.4 dan Android Gradle Plugin terbaru di mesin ini.
- Base URL default mengikuti repo acuan: `https://ship-monitoring-be.vercel.app/api`. Backend lokal baru tersedia di folder `backend/`; ganti `API_BASE_URL` di `.env` bila ingin memakai backend lokal/VPS sendiri.
- Kirim lokasi Nakhoda memakai `geolocator`; uji final perlu device fisik dengan izin lokasi aktif.
- Peta marker kapal memakai `google_maps_flutter`; saat `GOOGLE_MAPS_API_KEY` kosong, aplikasi menampilkan preview peta agar layar tetap aman dibuka. API key asli harus dibuat dari akun Google Cloud milik project.
- Cek kedatangan Admin sudah menyimpan item checklist dan catatan; upload dokumen inspeksi dapat ditambahkan setelah kebutuhan file backend final.
- Keputusan Manager memakai endpoint baru `PUT /api/submissions/{id}/manager-validation`.
- Dokumen pengajuan dibatasi 4 MB per file; signed URL yang expired perlu di-refresh dari detail pengajuan atau backend.
- Dokumentasi instalasi tersedia di `docs/INSTALLATION.md`; dokumentasi backend tersedia di `backend/README.md`; panduan deploy VPS tersedia di `docs/VPS_DEPLOYMENT.md`.
- APK release lokal masih memakai signing debug untuk testing internal; gunakan keystore resmi sebelum distribusi production.

## Konfigurasi

Salin `.env.example` ke `.env`, lalu sesuaikan:

```env
API_BASE_URL=https://alamat-backend-vps-anda.com/api
GOOGLE_MAPS_API_KEY=isi_api_key_maps
GOOGLE_MAPS_ANDROID_DEBUG_KEY=isi_api_key_maps_debug
GOOGLE_MAPS_ANDROID_RELEASE_KEY=isi_api_key_maps_release
GOOGLE_MAPS_WEB_KEY=isi_api_key_maps_web
GOOGLE_MAPS_MAP_ID=isi_map_id_untuk_advanced_marker
MANAGER_DECISION_ENABLED=true
```

Untuk Android Maps native, isi `GOOGLE_MAPS_API_KEY` di `.env` atau Gradle property `MAPS_API_KEY`; Gradle akan memasukkan key ke Android Manifest.
Untuk Flutter Web, loader di `web/index.html` mengambil `GOOGLE_MAPS_WEB_KEY` dari `.env`. Key Web harus memakai restriction **Websites** dan mengizinkan origin tempat aplikasi dijalankan. Untuk development, tambahkan `http://localhost:8080/*` di **Google Cloud Console > APIs & Services > Credentials > API key > Website restrictions**, lalu jalankan dengan port tetap:

```bash
flutter run -d chrome --web-port=8080
```

Pastikan **Maps JavaScript API** aktif pada project Google Cloud yang sama. `GOOGLE_MAPS_MAP_ID` diperlukan oleh Advanced Marker; saat debug Web dan nilai ini kosong, aplikasi memakai `DEMO_MAP_ID` resmi untuk testing. Gunakan Map ID milik project untuk production.

## Perintah

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

APK debug hasil verifikasi lokal berada di `build/app/outputs/flutter-apk/app-debug.apk` setelah menjalankan `flutter build apk --debug`.
APK release hasil verifikasi lokal berada di `build/app/outputs/flutter-apk/app-release.apk` setelah menjalankan `flutter build apk --release`.
