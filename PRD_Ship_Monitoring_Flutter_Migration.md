# PRD.md — Migrasi Aplikasi Ship Monitoring ke Flutter

**Nama Produk:** Ship Monitoring  
**Versi Dokumen:** 1.0  
**Tanggal:** 03 Juli 2026  
**Target Platform:** Android terlebih dahulu, siap dikembangkan ke iOS  
**Backend:** Backend sudah tersedia di VPS. Base URL akan dimasukkan pada konfigurasi environment Flutter.  
**Repository Acuan:** `https://github.com/Jamaludin21/ship-monitoring.git`

---

## 1. Ringkasan Produk

Ship Monitoring adalah aplikasi monitoring kapal dan pengajuan berlabuh yang digunakan oleh tiga role utama, yaitu **Nakhoda**, **Admin/Tata Usaha KSOP**, dan **Manager/Kepala KSOP**. Aplikasi existing dibuat menggunakan Android native berbasis Kotlin dan Jetpack Compose. Pada pengembangan baru, aplikasi akan dimigrasikan ke **Flutter** dengan desain antarmuka yang dirombak agar lebih modern, rapi, dan nyaman digunakan, tetapi fitur utama tetap dipertahankan.

Aplikasi ini berfungsi untuk membantu proses pengajuan dokumen kapal, pengiriman lokasi kapal, verifikasi pengajuan, persetujuan atau penolakan pengajuan, pemeriksaan kedatangan kapal, riwayat pengajuan, serta pemantauan lokasi kapal melalui peta.

---

## 2. Tujuan Migrasi

Tujuan migrasi aplikasi ke Flutter adalah:

1. Membuat aplikasi lebih mudah dikembangkan untuk Android dan iOS.
2. Merombak desain antarmuka agar lebih modern, konsisten, dan mudah digunakan.
3. Mempertahankan fitur utama yang sudah ada pada aplikasi sebelumnya.
4. Mengintegrasikan aplikasi Flutter dengan backend yang sudah tersedia di VPS.
5. Membuat struktur proyek yang lebih rapi, modular, dan mudah dirawat.
6. Menyediakan proses pengembangan bertahap berdasarkan phase agar pengerjaan lebih terarah.

---

## 3. Ruang Lingkup Produk

### 3.1. In Scope

Fitur yang termasuk dalam pengembangan:

- Login berbasis role.
- Penyimpanan token/session pengguna.
- Dashboard untuk masing-masing role.
- Fitur Nakhoda:
  - melihat data kapal sendiri,
  - mengirim lokasi kapal,
  - membuat pengajuan berlabuh,
  - upload dokumen PDF,
  - melihat riwayat pengajuan,
  - melihat detail pengajuan.
- Fitur Admin/Tata Usaha KSOP:
  - melihat semua pengajuan,
  - melihat detail pengajuan,
  - memverifikasi pengajuan,
  - approve/reject pengajuan,
  - melihat semua kapal,
  - melihat history kapal,
  - melihat lokasi kapal,
  - mengelola hasil cek kedatangan kapal.
- Fitur Manager/Kepala KSOP:
  - melihat pengajuan yang menunggu keputusan,
  - melihat detail pengajuan,
  - approve/reject keputusan akhir,
  - melihat semua kapal,
  - melihat history kapal,
  - melihat lokasi kapal,
  - melihat laporan ringkas.
- Integrasi Google Maps.
- Integrasi GPS/location update.
- Validasi file PDF.
- Handling error dan loading state.
- Build APK release.

### 3.2. Out of Scope

Fitur yang tidak termasuk pada tahap awal:

- Integrasi dengan sistem nasional pelabuhan.
- Notifikasi push FCM.
- Chat atau komunikasi real-time.
- Web admin baru.
- Offline mode penuh.
- Payment atau biaya administrasi.
- WebSocket live tracking.
- Multi-language selain Bahasa Indonesia.

---

## 4. Role Pengguna

### 4.1. Nakhoda

Nakhoda adalah pengguna yang bertugas mengirim data pengajuan berlabuh dan mengirim lokasi kapal ke sistem.

Hak akses utama:

- Login.
- Melihat informasi kapal sendiri.
- Mengirim lokasi kapal.
- Membuat pengajuan berlabuh.
- Mengunggah dokumen persyaratan.
- Melihat riwayat pengajuan.
- Melihat detail pengajuan.
- Melihat profil.

### 4.2. Admin/Tata Usaha KSOP

Admin/Tata Usaha KSOP adalah pengguna yang bertugas memeriksa data dan dokumen pengajuan dari Nakhoda.

Hak akses utama:

- Login.
- Melihat daftar pengajuan masuk.
- Melihat detail pengajuan.
- Memverifikasi pengajuan.
- Menyetujui atau menolak pengajuan.
- Melihat data kapal.
- Melihat history kapal.
- Melihat lokasi kapal.
- Mengelola hasil cek kedatangan kapal.
- Melihat profil.

### 4.3. Manager/Kepala KSOP

Manager/Kepala KSOP adalah pengguna yang bertugas memantau pengajuan dan memberikan keputusan akhir terhadap pengajuan kapal.

Hak akses utama:

- Login.
- Melihat pengajuan menunggu keputusan.
- Melihat detail pengajuan.
- Memberikan approve/reject keputusan akhir.
- Melihat semua kapal.
- Melihat lokasi kapal.
- Melihat history kapal.
- Melihat laporan ringkas.
- Melihat profil.

> Catatan: Pada repo existing, Manager digunakan sebagai role pemantau. Pada target migrasi ini, Manager/Kepala KSOP disesuaikan menjadi role yang dapat memberikan keputusan akhir approve/reject sesuai kebutuhan sistem terbaru.

---

## 5. Target Desain UI/UX

Desain baru mengikuti konsep yang sudah direkomendasikan sebelumnya:

### 5.1. Karakter Desain

- Modern, bersih, dan mudah dibaca.
- Tema maritim dengan warna utama biru laut dan toska.
- Banyak menggunakan card dengan sudut membulat.
- Bottom navigation untuk akses cepat.
- Icon yang jelas untuk setiap menu.
- Status data menggunakan warna:
  - Biru: informasi,
  - Kuning/oranye: pending/menunggu,
  - Hijau: disetujui/aktif,
  - Merah: ditolak/error.
- Layout mobile-first.

### 5.2. Komponen UI Utama

- AppBar dengan nama role dan tombol notifikasi/logout.
- Dashboard cards.
- Summary cards.
- Search bar.
- Filter chip.
- List card untuk pengajuan.
- Detail card untuk informasi pengajuan.
- File upload card.
- Primary button.
- Secondary button.
- Alert dialog untuk approve/reject.
- Bottom navigation.
- Map preview card.

---

## 6. Struktur Navigasi Aplikasi

### 6.1. Navigasi Nakhoda

- Login
- Dashboard Nakhoda
- Pengajuan
- Buat Pengajuan
- Riwayat Pengajuan
- Detail Pengajuan
- Lokasi/Kirim Lokasi
- Profil

### 6.2. Navigasi Admin/Tata Usaha KSOP

- Login
- Dashboard Admin
- Daftar Pengajuan
- Detail Pengajuan
- Verifikasi Pengajuan
- Cek Kedatangan Kapal
- Data Kapal
- History Kapal
- Lokasi Kapal
- Profil

### 6.3. Navigasi Manager/Kepala KSOP

- Login
- Dashboard Manager
- Pengajuan Menunggu Keputusan
- Detail & Keputusan
- Data Kapal
- History Kapal
- Lokasi Kapal
- Laporan Ringkas
- Profil

---

## 7. Kebutuhan Fungsional

### 7.1. Autentikasi

| Kode | Kebutuhan |
|---|---|
| AUTH-01 | Sistem menyediakan halaman login menggunakan username dan password. |
| AUTH-02 | Sistem memvalidasi akun ke backend. |
| AUTH-03 | Sistem menyimpan token login secara aman. |
| AUTH-04 | Sistem mengarahkan pengguna ke dashboard sesuai role. |
| AUTH-05 | Sistem menghapus session saat logout. |
| AUTH-06 | Jika token expired atau request mendapat 401, sistem mengarahkan pengguna ke login. |

### 7.2. Dashboard Nakhoda

| Kode | Kebutuhan |
|---|---|
| NKD-01 | Sistem menampilkan nama Nakhoda dan informasi kapal. |
| NKD-02 | Sistem menampilkan status lokasi kapal aktif/tidak aktif. |
| NKD-03 | Sistem menampilkan ringkasan pengajuan: total, pending, disetujui, ditolak. |
| NKD-04 | Sistem menampilkan pengajuan terbaru. |
| NKD-05 | Sistem menyediakan tombol aksi cepat: buat pengajuan, kirim lokasi, lihat history. |

### 7.3. Pengajuan Berlabuh Nakhoda

| Kode | Kebutuhan |
|---|---|
| SUB-01 | Nakhoda dapat membuka form pengajuan berlabuh. |
| SUB-02 | Sistem menampilkan nomor kapal dan nama kapal. |
| SUB-03 | Nakhoda mengisi nama nakhoda, jumlah pegawai, muatan, dan jumlah muatan. |
| SUB-04 | Nakhoda mengunggah dokumen PDF persyaratan. |
| SUB-05 | Sistem memvalidasi dokumen harus PDF. |
| SUB-06 | Sistem membatasi ukuran file maksimal sesuai ketentuan backend, disarankan 4–5 MB. |
| SUB-07 | Nakhoda dapat mengirim pengajuan ke backend. |
| SUB-08 | Sistem menampilkan status berhasil/gagal. |

### 7.4. Riwayat dan Detail Pengajuan

| Kode | Kebutuhan |
|---|---|
| HIS-01 | Nakhoda dapat melihat riwayat pengajuan miliknya. |
| HIS-02 | Admin dan Manager dapat melihat riwayat pengajuan kapal. |
| HIS-03 | Pengguna dapat melihat detail pengajuan. |
| HIS-04 | Detail pengajuan menampilkan data kapal, data muatan, status, dokumen, catatan, dan waktu pengajuan. |
| HIS-05 | Sistem dapat membuka dokumen melalui signed URL dari backend. |

### 7.5. Lokasi Kapal

| Kode | Kebutuhan |
|---|---|
| LOC-01 | Nakhoda dapat mengaktifkan pengiriman lokasi kapal. |
| LOC-02 | Sistem mengambil koordinat dari GPS perangkat. |
| LOC-03 | Sistem mengirim latitude dan longitude ke backend secara berkala. |
| LOC-04 | Admin dan Manager dapat melihat daftar lokasi kapal. |
| LOC-05 | Admin dan Manager dapat melihat lokasi kapal pada peta. |
| LOC-06 | Sistem menampilkan status kapal aktif/tidak aktif berdasarkan data lokasi terakhir. |

### 7.6. Admin/Tata Usaha KSOP

| Kode | Kebutuhan |
|---|---|
| ADM-01 | Admin dapat melihat semua pengajuan. |
| ADM-02 | Admin dapat melihat detail pengajuan. |
| ADM-03 | Admin dapat approve pengajuan. |
| ADM-04 | Admin dapat reject pengajuan dengan catatan penolakan. |
| ADM-05 | Admin dapat mencari history kapal berdasarkan nomor kapal. |
| ADM-06 | Admin dapat melihat semua data kapal. |
| ADM-07 | Admin dapat melihat lokasi kapal pada peta. |
| ADM-08 | Admin dapat mengelola hasil cek kedatangan kapal. |

### 7.7. Cek Kedatangan Kapal

| Kode | Kebutuhan |
|---|---|
| INS-01 | Admin dapat membuka checklist pemeriksaan kedatangan kapal. |
| INS-02 | Admin dapat memilih kondisi YA/TIDAK pada setiap item checklist. |
| INS-03 | Admin dapat menambahkan catatan pemeriksaan. |
| INS-04 | Admin dapat mengunggah dokumen hasil pemeriksaan jika diperlukan. |
| INS-05 | Admin dapat menyimpan hasil pemeriksaan ke backend. |

### 7.8. Manager/Kepala KSOP

| Kode | Kebutuhan |
|---|---|
| MGR-01 | Manager dapat melihat pengajuan yang menunggu keputusan. |
| MGR-02 | Manager dapat melihat detail pengajuan. |
| MGR-03 | Manager dapat approve pengajuan sebagai keputusan akhir. |
| MGR-04 | Manager dapat reject pengajuan dengan catatan keputusan. |
| MGR-05 | Manager dapat melihat semua kapal. |
| MGR-06 | Manager dapat melihat history kapal. |
| MGR-07 | Manager dapat melihat lokasi kapal. |
| MGR-08 | Manager dapat melihat laporan ringkas pengajuan. |

---

## 8. Kebutuhan Non-Fungsional

| Kategori | Kebutuhan |
|---|---|
| Performance | Halaman utama harus dimuat kurang dari 3 detik pada koneksi stabil. |
| Security | Token disimpan menggunakan secure storage. |
| Usability | UI harus mudah digunakan oleh pengguna non-teknis. |
| Reliability | Error API harus ditampilkan dengan pesan yang mudah dipahami. |
| Maintainability | Struktur kode menggunakan clean architecture sederhana. |
| Compatibility | Minimal Android 8.0 atau menyesuaikan kebutuhan perangkat target. |
| Scalability | Struktur service harus mudah ditambah untuk fitur baru. |
| Accessibility | Ukuran teks dan tombol harus nyaman disentuh di perangkat Android. |

---

## 9. Integrasi Backend

Backend sudah tersedia di VPS. Aplikasi Flutter cukup memasukkan base URL backend pada environment.

### 9.1. Konfigurasi Environment

Contoh file:

```env
API_BASE_URL=https://alamat-backend-vps-anda.com/api
GOOGLE_MAPS_API_KEY=isi_api_key_maps
```

Atau dengan Flutter flavor:

- `.env.dev`
- `.env.prod`

### 9.2. Endpoint Backend yang Digunakan

Endpoint mengacu pada aplikasi existing:

| Fitur | Method | Endpoint |
|---|---|---|
| Login | POST | `/api/auth/login` |
| Health Check | GET | `/api/health` |
| Semua Kapal | GET | `/api/ships` |
| Kapal Saya | GET | `/api/ships/my` |
| Update Lokasi | POST | `/api/location/update` |
| Semua Lokasi Kapal | GET | `/api/location/ships` |
| Buat Pengajuan | POST | `/api/submissions` |
| Semua Pengajuan | GET | `/api/submissions` |
| History Saya | GET | `/api/submissions/my-history` |
| Detail Pengajuan | GET | `/api/submissions/{id}` |
| History Kapal | GET | `/api/submissions/ship/{shipNumber}/history` |
| Approve Pengajuan | PATCH | `/api/submissions/{id}/approve` |
| Reject Pengajuan | PATCH | `/api/submissions/{id}/reject` |
| Checklist Inspeksi | GET | `/api/submissions/arrival-inspection/checklist` |
| Detail Inspeksi | GET | `/api/submissions/{id}/arrival-inspection` |
| Simpan Inspeksi | PUT | `/api/submissions/{id}/arrival-inspection` |

### 9.3. Catatan Integrasi

- Semua endpoint protected wajib menggunakan header `Authorization: Bearer <token>`.
- Upload dokumen menggunakan `multipart/form-data`.
- File dokumen wajib PDF.
- Signed URL dokumen perlu di-refresh dari detail pengajuan ketika URL expired.
- Lokasi kapal dikirim berkala dari aplikasi Nakhoda.
- Peta ditampilkan pada role Admin dan Manager.

---

## 10. Rekomendasi Tech Stack Flutter

| Area | Rekomendasi |
|---|---|
| Framework | Flutter stable |
| Bahasa | Dart |
| State Management | Riverpod atau BLoC |
| Routing | GoRouter |
| HTTP Client | Dio |
| Environment | flutter_dotenv atau dart-define |
| Secure Storage | flutter_secure_storage |
| Local Cache | shared_preferences / hive |
| Maps | google_maps_flutter |
| Location | geolocator + permission_handler |
| File Picker | file_picker |
| PDF Handling | url_launcher / open_filex |
| Form Validation | Form + TextFormField validator |
| UI | Material 3 custom theme |
| Testing | flutter_test, integration_test |

Rekomendasi utama: gunakan **Riverpod + GoRouter + Dio**, karena kombinasi ini cukup ringan, rapi, dan cocok untuk aplikasi dengan role-based navigation.

---

## 11. Desain Layar Utama

### 11.1. Login

Isi layar:

- Logo aplikasi.
- Judul Ship Monitoring.
- Input username.
- Input password.
- Tombol masuk.
- Pesan error jika login gagal.

### 11.2. Dashboard Nakhoda

Isi layar:

- Salam pengguna.
- Card radar/lokasi aktif.
- Informasi kapal.
- Ringkasan pengajuan.
- Pengajuan terbaru.
- Aksi cepat:
  - Buat Pengajuan,
  - Kirim Lokasi,
  - Lihat History.
- Bottom navigation:
  - Beranda,
  - Pengajuan,
  - Lokasi,
  - Profil.

### 11.3. Buat Pengajuan

Isi layar:

- Stepper: Data → Dokumen → Review.
- Data kapal otomatis.
- Form data pengajuan.
- Upload dokumen PDF.
- Tombol kirim pengajuan.

### 11.4. Riwayat Pengajuan

Isi layar:

- Search bar.
- Filter status: semua, pending, disetujui, ditolak.
- List pengajuan.
- Badge status.
- Tombol detail.

### 11.5. Detail Pengajuan

Isi layar:

- Status pengajuan.
- Informasi pengajuan.
- Informasi kapal.
- Dokumen persyaratan.
- Catatan verifikasi/penolakan.
- Riwayat proses.
- Tombol aksi sesuai role.

### 11.6. Dashboard Admin

Isi layar:

- Ringkasan pengajuan.
- Pengajuan perlu dicek.
- Data kapal.
- Lokasi kapal aktif.
- Cek kedatangan kapal.
- Riwayat kapal terbaru.
- Menu cepat.

### 11.7. Verifikasi Pengajuan Admin

Isi layar:

- Detail data pengajuan.
- Tab: detail, dokumen, riwayat.
- Preview daftar dokumen.
- Tombol setujui.
- Tombol tolak.
- Dialog catatan penolakan.

### 11.8. Cek Kedatangan Kapal

Isi layar:

- Informasi pengajuan.
- Checklist alat navigasi dan komunikasi.
- Pilihan YA/TIDAK.
- Catatan pemeriksaan.
- Upload dokumen hasil cek.
- Tombol simpan hasil cek.

### 11.9. Dashboard Manager

Isi layar:

- Ringkasan persetujuan.
- Pengajuan menunggu keputusan.
- Data kapal.
- Lokasi kapal aktif.
- Riwayat pengajuan terbaru.
- Tombol laporan ringkas.

### 11.10. Detail & Keputusan Manager

Isi layar:

- Informasi pengajuan.
- Dokumen.
- Hasil verifikasi admin.
- Hasil inspeksi jika ada.
- Tombol setujui.
- Tombol tolak.
- Dialog catatan keputusan.

### 11.11. Lokasi Kapal

Isi layar:

- Filter kapal.
- Peta lokasi kapal.
- Marker kapal.
- List kapal aktif/tidak aktif.
- Detail lokasi kapal.

---

## 12. Fase Pengembangan

## Phase 0 — Persiapan dan Analisis

### Tujuan
Menyiapkan dasar migrasi dari Android Kotlin ke Flutter.

### Scope
- Review fitur aplikasi lama.
- Review endpoint backend.
- Menentukan style UI baru.
- Menyiapkan struktur folder Flutter.
- Menentukan base URL VPS.
- Menyiapkan API key Maps.

### Output
- Dokumen PRD final.
- Daftar endpoint final.
- Flow role final.
- Desain wireframe final.
- Project Flutter kosong.

### Acceptance Criteria
- Base URL backend VPS sudah diketahui.
- Role dan fitur sudah disepakati.
- Struktur folder awal sudah dibuat.

---

## Phase 1 — Setup Project Flutter dan Design System

### Tujuan
Membangun fondasi aplikasi Flutter.

### Scope
- Membuat project Flutter.
- Setup package utama.
- Setup theme Material 3.
- Setup color palette.
- Setup typography.
- Setup reusable components.
- Setup environment.
- Setup routing dasar.

### Output
- Project Flutter berjalan.
- Komponen UI dasar:
  - AppButton,
  - AppTextField,
  - AppCard,
  - StatusBadge,
  - EmptyState,
  - LoadingState,
  - ErrorState.
- Theme maritim sesuai desain baru.

### Acceptance Criteria
- Aplikasi bisa run di emulator/device.
- Theme dan komponen dasar bisa digunakan di beberapa halaman.
- Struktur folder sudah rapi.

### Estimasi
2–3 hari.

---

## Phase 2 — Auth, Session, dan Role Navigation

### Tujuan
Membangun login dan pembagian dashboard sesuai role.

### Scope
- Halaman login.
- Integrasi endpoint login.
- Simpan token.
- Auth interceptor.
- Auto logout saat token tidak valid.
- Redirect berdasarkan role:
  - NAHKODA,
  - ADMIN,
  - MANAGER.
- Logout.

### Output
- Login berfungsi.
- Role-based navigation berfungsi.
- Session tersimpan aman.

### Acceptance Criteria
- User valid masuk ke dashboard sesuai role.
- User invalid mendapat pesan error.
- Token tersimpan di secure storage.
- Logout menghapus session.

### Estimasi
3–4 hari.

---

## Phase 3 — Modul Nakhoda

### Tujuan
Membangun seluruh fitur utama Nakhoda.

### Scope
- Dashboard Nakhoda.
- Ambil data kapal sendiri.
- Form pengajuan berlabuh.
- Upload dokumen PDF.
- Kirim pengajuan.
- Riwayat pengajuan.
- Detail pengajuan.
- Profil sederhana.
- Kirim lokasi kapal.

### Output
- Modul Nakhoda lengkap.

### Acceptance Criteria
- Nakhoda dapat melihat kapal sendiri.
- Nakhoda dapat membuat pengajuan.
- Sistem menolak file non-PDF.
- Sistem menampilkan history pengajuan.
- Sistem dapat mengirim koordinat lokasi ke backend.

### Estimasi
6–8 hari.

---

## Phase 4 — Modul Admin/Tata Usaha KSOP

### Tujuan
Membangun fitur verifikasi dan monitoring untuk Admin.

### Scope
- Dashboard Admin.
- Daftar pengajuan.
- Detail pengajuan.
- Approve pengajuan.
- Reject pengajuan dengan catatan.
- Data kapal.
- History kapal.
- Lokasi kapal.
- Cek kedatangan kapal.
- Upload dokumen inspeksi jika diperlukan.

### Output
- Modul Admin lengkap.

### Acceptance Criteria
- Admin dapat melihat semua pengajuan.
- Admin dapat approve/reject pengajuan.
- Admin dapat melihat detail dokumen.
- Admin dapat menyimpan hasil cek kedatangan.
- Admin dapat melihat lokasi kapal.

### Estimasi
7–10 hari.

---

## Phase 5 — Modul Manager/Kepala KSOP

### Tujuan
Membangun fitur pengambilan keputusan akhir dan pemantauan untuk Manager.

### Scope
- Dashboard Manager.
- Daftar pengajuan menunggu keputusan.
- Detail pengajuan.
- Melihat hasil verifikasi Admin.
- Approve keputusan akhir.
- Reject keputusan akhir dengan catatan.
- Data kapal.
- History kapal.
- Lokasi kapal.
- Laporan ringkas.

### Output
- Modul Manager lengkap.

### Acceptance Criteria
- Manager dapat melihat pengajuan menunggu keputusan.
- Manager dapat approve/reject.
- Manager dapat melihat lokasi kapal.
- Manager dapat melihat laporan ringkas.

### Estimasi
5–7 hari.

---

## Phase 6 — Maps, Location, dan Monitoring

### Tujuan
Memperkuat fitur lokasi kapal dan monitoring pada peta.

### Scope
- Permission GPS.
- Ambil koordinat perangkat.
- Kirim lokasi berkala dari Nakhoda.
- Tampilkan marker kapal di peta.
- Detail lokasi kapal.
- Status aktif/tidak aktif.
- Refresh lokasi manual dan otomatis.

### Output
- Modul lokasi stabil.

### Acceptance Criteria
- Aplikasi meminta izin lokasi dengan benar.
- Koordinat berhasil dikirim ke backend.
- Admin/Manager dapat melihat marker kapal.
- Data lokasi dapat di-refresh.

### Estimasi
4–6 hari.

---

## Phase 7 — File, Dokumen, dan Validasi

### Tujuan
Menyempurnakan upload dan akses dokumen.

### Scope
- File picker PDF.
- Validasi ukuran file.
- Validasi ekstensi/MIME.
- Upload multipart.
- Preview nama file.
- Buka dokumen melalui URL.
- Handling signed URL expired.
- Pesan error dokumen.

### Output
- Upload dokumen stabil dan aman.

### Acceptance Criteria
- File non-PDF ditolak.
- File terlalu besar ditolak.
- File berhasil dikirim ke backend.
- Dokumen dapat dibuka dari detail pengajuan.

### Estimasi
3–4 hari.

---

## Phase 8 — UI Polish, Testing, dan Hardening

### Tujuan
Merapikan desain dan memastikan aplikasi siap digunakan.

### Scope
- Perbaikan spacing.
- Perbaikan responsif layar.
- Skeleton/loading state.
- Empty state.
- Error state.
- Disable button saat loading.
- Guard anti double submit.
- Manual testing semua role.
- Black box testing.
- Bug fixing.

### Output
- Aplikasi stabil dan rapi.

### Acceptance Criteria
- Tidak ada crash pada alur utama.
- Semua role berhasil menjalankan fitur utama.
- UI konsisten.
- Error API tampil jelas.
- Tombol tidak bisa double submit.

### Estimasi
5–7 hari.

---

## Phase 9 — Build Release dan Deployment

### Tujuan
Menyiapkan aplikasi untuk dibagikan atau diuji di perangkat nyata.

### Scope
- Setup app icon.
- Setup app name.
- Setup package name.
- Setup release config.
- Setup API base URL production VPS.
- Build APK release.
- Testing pada device fisik.
- Dokumentasi instalasi.

### Output
- APK release.
- File konfigurasi production.
- Dokumentasi singkat penggunaan.

### Acceptance Criteria
- APK berhasil diinstall.
- Aplikasi terhubung ke backend VPS.
- Login dan fitur utama berjalan pada device fisik.
- Tidak ada debug URL yang tertinggal.

### Estimasi
2–3 hari.

---

## 13. Struktur Folder Flutter yang Disarankan

```text
lib/
  main.dart
  app.dart

  core/
    config/
      env.dart
      app_config.dart
    constants/
      app_colors.dart
      app_text_styles.dart
      app_sizes.dart
    network/
      dio_client.dart
      auth_interceptor.dart
      api_exception.dart
    storage/
      secure_storage_service.dart
    utils/
      file_validator.dart
      date_formatter.dart
      location_helper.dart
    widgets/
      app_button.dart
      app_text_field.dart
      app_card.dart
      status_badge.dart
      loading_view.dart
      error_view.dart
      empty_view.dart

  features/
    auth/
      data/
      domain/
      presentation/
    dashboard/
      presentation/
    nahkoda/
      data/
      domain/
      presentation/
    admin/
      data/
      domain/
      presentation/
    manager/
      data/
      domain/
      presentation/
    submissions/
      data/
      domain/
      presentation/
    ships/
      data/
      domain/
      presentation/
    location/
      data/
      domain/
      presentation/
    inspection/
      data/
      domain/
      presentation/

  routes/
    app_router.dart

  theme/
    app_theme.dart
```

---

## 14. Data Model Utama di Flutter

### 14.1. User

```dart
class User {
  final String id;
  final String username;
  final String name;
  final String role;
}
```

### 14.2. Ship

```dart
class Ship {
  final String id;
  final String shipNumber;
  final String name;
  final String captainId;
}
```

### 14.3. Submission

```dart
class Submission {
  final String id;
  final String shipId;
  final String captainName;
  final int employeeCount;
  final String cargo;
  final String cargoAmount;
  final String status;
  final String? reviewNote;
  final DateTime submittedAt;
}
```

### 14.4. Location

```dart
class ShipLocation {
  final String shipId;
  final String shipName;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
}
```

---

## 15. Status Pengajuan

Status yang digunakan pada UI:

| Status Backend | Label UI | Warna |
|---|---|---|
| PENDING | Menunggu Verifikasi | Kuning |
| WAITING_MANAGER_VALIDATION | Menunggu Keputusan | Ungu/Biru |
| APPROVED | Disetujui | Hijau |
| REJECTED | Ditolak | Merah |

Jika backend belum memiliki status `WAITING_MANAGER_VALIDATION`, maka status tersebut perlu ditambahkan atau disimulasikan berdasarkan proses setelah Admin approve.

---

## 16. User Stories

### Nakhoda

1. Sebagai Nakhoda, saya ingin login agar dapat mengakses data kapal saya.
2. Sebagai Nakhoda, saya ingin mengirim lokasi kapal agar pihak KSOP dapat memantau posisi kapal.
3. Sebagai Nakhoda, saya ingin mengajukan dokumen berlabuh agar proses perizinan dapat dilakukan secara digital.
4. Sebagai Nakhoda, saya ingin melihat status pengajuan agar mengetahui apakah pengajuan saya diterima atau ditolak.

### Admin/Tata Usaha KSOP

1. Sebagai Admin, saya ingin melihat daftar pengajuan agar dapat memeriksa dokumen yang masuk.
2. Sebagai Admin, saya ingin melihat detail dokumen agar dapat melakukan verifikasi.
3. Sebagai Admin, saya ingin menyetujui atau menolak pengajuan agar pengajuan dapat diproses ke tahap berikutnya.
4. Sebagai Admin, saya ingin mengisi hasil cek kedatangan kapal agar data pemeriksaan terdokumentasi.

### Manager/Kepala KSOP

1. Sebagai Manager, saya ingin melihat pengajuan yang menunggu keputusan agar dapat memberikan persetujuan akhir.
2. Sebagai Manager, saya ingin approve/reject pengajuan agar keputusan akhir tercatat di sistem.
3. Sebagai Manager, saya ingin melihat lokasi kapal agar dapat memantau kondisi kapal.
4. Sebagai Manager, saya ingin melihat laporan ringkas agar dapat memantau jumlah pengajuan.

---

## 17. Acceptance Criteria Global

Aplikasi dianggap selesai jika:

1. Semua role dapat login.
2. Setiap role diarahkan ke dashboard masing-masing.
3. Nakhoda dapat membuat pengajuan dan upload dokumen PDF.
4. Nakhoda dapat mengirim lokasi kapal.
5. Admin dapat melihat, approve, reject, dan memeriksa pengajuan.
6. Admin dapat mengelola hasil cek kedatangan kapal.
7. Manager dapat melihat detail dan memberikan keputusan akhir.
8. Admin dan Manager dapat melihat lokasi kapal pada peta.
9. Token tersimpan aman dan logout berjalan.
10. Aplikasi terhubung ke backend VPS production.
11. APK release dapat diinstall di perangkat Android.
12. Desain aplikasi sesuai konsep UI baru.

---

## 18. Risiko dan Mitigasi

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Endpoint backend berubah | Integrasi gagal | Buat daftar endpoint final sebelum coding |
| Signed URL dokumen expired | Dokumen gagal dibuka | Refresh detail pengajuan sebelum buka dokumen |
| Permission lokasi ditolak | Lokasi tidak terkirim | Berikan pesan dan tombol buka pengaturan |
| File PDF terlalu besar | Upload gagal | Validasi ukuran sebelum upload |
| Token expired | User stuck di halaman | Auto logout dan redirect ke login |
| Desain terlalu kompleks | Development lama | Gunakan komponen reusable dan design system |
| Manager approval belum tersedia di backend | Fitur tidak bisa berjalan | Tambahkan endpoint manager validation atau gunakan endpoint approve/reject sesuai backend final |

---

## 19. Prioritas Fitur

### Must Have

- Login
- Role navigation
- Dashboard per role
- Pengajuan dokumen
- Upload PDF
- History pengajuan
- Detail pengajuan
- Approve/reject
- Kirim lokasi
- Peta lokasi kapal
- Session/token

### Should Have

- Checklist cek kedatangan
- Laporan ringkas Manager
- Search dan filter
- Refresh lokasi otomatis
- Empty state dan error state

### Could Have

- Push notification
- Export laporan PDF
- Offline draft pengajuan
- Chat admin-nakhoda

### Won't Have Saat Ini

- WebSocket realtime
- Payment
- Integrasi sistem nasional
- Multi-language

---

## 20. Rencana Timeline Singkat

| Phase | Durasi |
|---|---|
| Phase 0 — Persiapan dan Analisis | 1–2 hari |
| Phase 1 — Setup Project dan Design System | 2–3 hari |
| Phase 2 — Auth dan Role Navigation | 3–4 hari |
| Phase 3 — Modul Nakhoda | 6–8 hari |
| Phase 4 — Modul Admin | 7–10 hari |
| Phase 5 — Modul Manager | 5–7 hari |
| Phase 6 — Maps dan Location | 4–6 hari |
| Phase 7 — File dan Dokumen | 3–4 hari |
| Phase 8 — Testing dan Hardening | 5–7 hari |
| Phase 9 — Release | 2–3 hari |

Total estimasi: **38–54 hari kerja**, tergantung kesiapan backend, desain final, dan revisi selama pengembangan.

---

## 21. Definition of Done

Setiap phase dianggap selesai jika:

1. Fitur sesuai scope phase selesai.
2. Tidak ada error utama.
3. UI sudah mengikuti design system.
4. API sudah terhubung ke backend.
5. Error handling tersedia.
6. Loading state tersedia.
7. Testing manual sudah dilakukan.
8. Kode sudah rapi dan bisa dilanjutkan ke phase berikutnya.

---

## 22. Catatan untuk Developer

1. Jangan langsung membuat semua fitur sekaligus.
2. Mulai dari auth dan struktur role.
3. Buat komponen UI reusable dari awal.
4. Pisahkan logic API, state management, dan UI.
5. Gunakan `.env` atau `dart-define` untuk base URL VPS.
6. Pastikan upload dokumen diuji menggunakan file PDF asli.
7. Pastikan fitur lokasi diuji di perangkat fisik, bukan hanya emulator.
8. Manager approval perlu dipastikan endpoint backend-nya sebelum Phase 5.
9. Desain dashboard dibuat sederhana: ringkasan, list terbaru, dan tombol aksi cepat.
10. Jangan menambahkan fitur baru sebelum fitur utama selesai.

---

## 23. Placeholder Konfigurasi Backend VPS

Isi bagian ini setelah alamat backend dari VPS tersedia:

```text
Production API Base URL:
https://________________________________/api

Google Maps API Key:
______________________________________

Package Name:
com.__________________.shipmonitoring

App Name:
Ship Monitoring
```

---

## 24. Lampiran Ringkas Alur Sistem

### Alur Nakhoda

1. Login.
2. Sistem menampilkan dashboard Nakhoda.
3. Nakhoda melihat data kapal sendiri.
4. Nakhoda mengaktifkan lokasi.
5. Nakhoda membuat pengajuan berlabuh.
6. Nakhoda upload dokumen PDF.
7. Sistem menyimpan pengajuan.
8. Nakhoda melihat status di riwayat.

### Alur Admin

1. Login.
2. Sistem menampilkan dashboard Admin.
3. Admin melihat pengajuan masuk.
4. Admin membuka detail pengajuan.
5. Admin memeriksa dokumen.
6. Admin approve atau reject.
7. Admin mengisi hasil cek kedatangan jika diperlukan.
8. Sistem menyimpan hasil verifikasi.

### Alur Manager

1. Login.
2. Sistem menampilkan dashboard Manager.
3. Manager melihat pengajuan menunggu keputusan.
4. Manager membuka detail pengajuan.
5. Manager memeriksa hasil verifikasi Admin.
6. Manager approve atau reject.
7. Sistem menyimpan keputusan akhir.
8. Manager dapat melihat lokasi kapal dan laporan ringkas.

---

## 25. Kesimpulan

Migrasi aplikasi Ship Monitoring ke Flutter dilakukan untuk membuat aplikasi lebih modern, mudah dikembangkan, dan siap digunakan pada banyak platform. Fitur utama tetap mengikuti aplikasi existing, yaitu autentikasi role, pengajuan berlabuh, upload dokumen PDF, verifikasi, approval, cek kedatangan kapal, history, dan monitoring lokasi kapal.

Pengembangan dilakukan secara bertahap per phase agar proses pengerjaan lebih terarah. Backend sudah tersedia di VPS, sehingga fokus utama pengembangan adalah pembuatan frontend Flutter, integrasi API, perombakan desain, pengujian, dan build release.
