# Instalasi Ship Monitoring

## Konfigurasi

Isi file `.env` sebelum build:

```env
API_BASE_URL=https://alamat-backend-vps-anda.com/api
GOOGLE_MAPS_API_KEY=api_key_google_maps_android
MANAGER_DECISION_ENABLED=true
```

Catatan:

- `GOOGLE_MAPS_API_KEY` harus dibuat dari Google Cloud Console dengan Maps SDK for Android aktif.
- `MANAGER_DECISION_ENABLED=true` memakai endpoint baru `PUT /api/submissions/:id/manager-validation`.
- Package Android aplikasi: `id.ksop.shipmonitoring`.
- Backend lokal tersedia di `backend/`.

## Build

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Output APK release:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Instalasi Android

1. Pindahkan APK ke perangkat Android.
2. Aktifkan izin install aplikasi dari sumber tepercaya.
3. Install APK.
4. Login memakai akun sesuai role dari backend.
5. Untuk fitur lokasi, izinkan akses lokasi perangkat.

## Backend Lokal

```bash
cd backend
copy .env.example .env
npm install
npm run dev
```

Untuk Android emulator:

```env
API_BASE_URL=http://10.0.2.2:3131/api
```

Untuk HP fisik, gunakan IP laptop/VPS sebagai host API.
