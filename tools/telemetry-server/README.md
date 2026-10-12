# 📡 SmartDNS Telemetry Receiver Server

Modul backend server telemetri mandiri (_self-hosted_) untuk menerima dan memonitor status kesehatan (_heartbeat_) seluruh node server **SmartDNS** di bawah domain [alsyundawy.com](https://alsyundawy.com).

---

## 📁 Struktur Berkas

```text
tools/telemetry-server/
├── api/
│   └── v1/
│       └── heartbeat.php    # Endpoint HTTP POST API penerima heartbeat
├── data/
│   └── .htaccess            # Proteksi akses publik ke direktori data
│   └── nodes/               # Tempat penyimpanan JSON telemetry per UUID
├── index.php                # Dashboard Web Fleet Monitor interaktif
└── README.md                # Panduan instalasi dan deployment
```

---

## 🚀 Panduan Deployment ke Web Server (alsyundawy.com)

### 1. Upload ke Hosting / VPS

Salin seluruh isi folder `tools/telemetry-server/` ke direktori web server domain Anda:

- **Subdomain Dedicated** (Disarankan): `https://telemetry.alsyundawy.com/`
- **Subfolder**: `https://alsyundawy.com/telemetry/`

Contoh struktur di server Linux/Nginx/Apache:

```bash
/var/www/telemetry.alsyundawy.com/
├── api/v1/heartbeat.php
├── data/nodes/
├── index.php
```

### 2. Atur Hak Akses (_Permissions_)

Pastikan web server (misal: `www-data`, `nginx`, atau user cPanel) memiliki izin tulis (_write permission_) ke folder `data/`:

```bash
chmod 750 /var/www/telemetry.alsyundawy.com/data
chmod 750 /var/www/telemetry.alsyundawy.com/data/nodes
chown -R www-data:www-data /var/www/telemetry.alsyundawy.com/data
```

### 3. Konfigurasi Nginx (Jika menggunakan VPS Nginx)

Tambahkan blok server berikut pada konfigurasi Nginx Anda:

```nginx
server {
    server_name telemetry.alsyundawy.com;
    root /var/www/telemetry.alsyundawy.com;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    # Blokir akses langsung ke folder data JSON
    location ^~ /data/ {
        deny all;
        return 403;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
    }
}
```

### 4. Mengakses Dashboard Fleet Monitor

Buka di browser:

```text
https://telemetry.alsyundawy.com/?key=alsyundawy2026
```

> [!TIP]
> Anda dapat mengganti kunci akses `?key=alsyundawy2026` di berkas [`index.php`](file:///Users/alsyundawy/Downloads/GitHub/SmartDNS/tools/telemetry-server/index.php) atau melalui _environment variable_ `SMARTDNS_DASHBOARD_SECRET`.

---

## ⚙️ Konfigurasi di Node SmartDNS

### 1. Menggunakan Endpoint Default (alsyundawy.com)

Secara otomatis, skrip instalasi dan pembaruan SmartDNS kini telah diarahkan ke:

```text
https://telemetry.alsyundawy.com/api/v1/heartbeat.php
```

### 2. Mengubah Endpoint Kustom

Jika Anda ingin mengarahkan node ke URL lain, setel di berkas `/var/lib/smartdns/install.env`:

```bash
SMARTDNS_TELEMETRY_URL="https://telemetry.alsyundawy.com/api/v1/heartbeat.php"
```

### 3. Menonaktifkan Telemetri Sepenuhnya

Jika Anda ingin menjalankan server tanpa mengirimkan telemetri apapun:

```bash
SMARTDNS_TELEMETRY_URL="disable"
# atau
TELEMETRY_DISABLE=true
```
