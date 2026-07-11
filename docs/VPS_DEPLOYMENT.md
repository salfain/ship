# Deploy Backend ke VPS dengan Nginx dan PM2

Contoh asumsi:

- Domain: `api.domain-anda.com`
- Folder app: `/var/www/ship-monitoring`
- Backend listen internal: `127.0.0.1:3131`
- OS VPS: Ubuntu/Debian

## 1. Upload Project

Di laptop:

```bash
scp -r backend user@IP_VPS:/var/www/ship-monitoring/
```

Atau gunakan Git bila project sudah ada repository.

## 2. Install Dependency Backend

Di VPS:

```bash
cd /var/www/ship-monitoring/backend
npm install --omit=dev
cp .env.example .env
nano .env
```

Isi `.env` production:

```env
PORT=3131
API_PREFIX=/api
TOKEN_SECRET=ganti_dengan_secret_panjang
DATA_DIR=./data
UPLOAD_DIR=./uploads
PUBLIC_BASE_URL=https://api.domain-anda.com
```

## 3. Jalankan dengan PM2

```bash
npm install -g pm2
cd /var/www/ship-monitoring/backend
pm2 start ecosystem.config.cjs
pm2 save
pm2 startup
```

Ikuti perintah yang ditampilkan `pm2 startup`, biasanya perlu dijalankan sekali dengan `sudo`.

Cek status:

```bash
pm2 status
pm2 logs ship-monitoring-api
```

Test lokal di VPS:

```bash
curl http://127.0.0.1:3131/api/health
```

## 4. Konfigurasi Nginx

Buat file:

```bash
sudo nano /etc/nginx/sites-available/ship-monitoring-api
```

Isi:

```nginx
server {
    listen 80;
    server_name api.domain-anda.com;

    client_max_body_size 10M;

    location / {
        proxy_pass http://127.0.0.1:3131;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

Aktifkan site:

```bash
sudo ln -s /etc/nginx/sites-available/ship-monitoring-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## 5. Buka Firewall

```bash
sudo ufw allow 'Nginx Full'
sudo ufw allow OpenSSH
sudo ufw status
```

Port `3131` tidak perlu dibuka publik jika Nginx berada di VPS yang sama.

## 6. Pasang HTTPS

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d api.domain-anda.com
```

Test publik:

```bash
curl https://api.domain-anda.com/api/health
```

## 7. Arahkan Flutter ke Backend Publik

Di `.env` Flutter:

```env
API_BASE_URL=https://api.domain-anda.com/api
MANAGER_DECISION_ENABLED=true
```

Lalu build ulang APK:

```bash
flutter build apk --release
```

## 8. Update Backend Setelah Perubahan

```bash
cd /var/www/ship-monitoring/backend
npm install --omit=dev
pm2 restart ship-monitoring-api
pm2 logs ship-monitoring-api
```

## Catatan Production

- Backend saat ini memakai JSON file untuk development/testing. Untuk production ramai, pindahkan data ke PostgreSQL/MySQL.
- Pastikan `TOKEN_SECRET` panjang dan tidak sama dengan contoh.
- Folder `data/` dan `uploads/` perlu backup rutin.
- Gunakan HTTPS untuk aplikasi mobile production.
