<!-- markdownlint-disable MD033 MD041 MD051 -->

# 📖 SmartDNS — Panduan Lengkap & Dokumentasi Terpadu (All-in-One Manual)

Dokumentasi resmi dan komprehensif untuk instalasi, konfigurasi, operasional, arsitektur, pemeliharaan, dan pemecahan masalah **SmartDNS** (v1.0.3-shellcheck-optimizer).

---

## 📑 Daftar Isi

1. [Arsitektur & Konsep Utama](#1-arsitektur--konsep-utama)
2. [Persyaratan Sistem & Topologi Port](#2-persyaratan-sistem--topologi-port)
3. [Panduan Instalasi (Installation Guide)](#3-panduan-instalasi-installation-guide)
   - [Metode 1: Otomatis 1-Line cURL Installer (Direkomendasikan)](#metode-1-otomatis-1-line-curl-installer-direkomendasikan)
   - [Metode 2: Manual via Git Clone](#metode-2-manual-via-git-clone)
   - [Metode 3: Non-Interaktif / Otomasi CI/CD](#metode-3-non-interaktif--otomasi-cicd)
4. [Panduan Operasional & How-To](#4-panduan-operasional--how-to)
   - [Kontrol Layanan systemd](#kontrol-layanan-systemd)
   - [Akses & Login SmartDNS Web UI](#akses--login-smartdns-web-ui)
   - [Pengaturan IP Spoofing (IPv4 & IPv6)](#pengaturan-ip-spoofing-ipv4--ipv6)
   - [Manajemen Whitelist Domain & Whitelist Client (ACL)](#manajemen-whitelist-domain--whitelist-client-acl)
   - [SafeSearch Enforcement](#safesearch-enforcement)
   - [Rate Limiting (Proteksi DDoS/Flooding)](#rate-limiting-proteksi-ddosflooding)
   - [Custom DNS Overrides](#custom-dns-overrides)
   - [Upstream DNS Resolvers](#upstream-dns-resolvers)
5. [Alat Diagnostik & Pengujian DNS Terintegrasi](#5-alat-diagnostik--pengujian-dns-terintegrasi)
6. [Manajemen Pembaruan Blocklist Otomatis](#6-manajemen-pembaruan-blocklist-otomatis)
7. [Arsitektur & Server Telemetri Mandiri (Self-Hosted)](#7-arsitektur--server-telemetri-mandiri-self-hosted)
8. [Pembaruan Sistem (Update & Upgrade Engine)](#8-pembaruan-sistem-update--upgrade-engine)
9. [Pemecahan Masalah (Troubleshooting & FAQ)](#9-pemecahan-masalah-troubleshooting--faq)
10. [Struktur Berkas & Direktori Sistem](#10-struktur-berkas--direktori-sistem)

---

## 🏛️ 1. Arsitektur & Konsep Utama

SmartDNS menggabungkan dua mesin DNS kelas dunia dalam arsitektur berlapis (two-tier architecture) berkinerja tinggi:

```text
                     +---------------------------------------+
                     |         Klien / Jaringan Lokal        |
                     +---------------------------------------+
                                         |
                                         | Kueri DNS (Port 53 UDP/TCP)
                                         v
                     +---------------------------------------+
                     |         PowerDNS dnsdist (Tier 1)     |
                     |  - High-Speed Load Balancer & Filter  |
                     |  - Evaluasi SuffixMatchNode Whitelist |
                     |  - IP Spoofing (Block A & Block AAAA) |
                     |  - Dynamic Rate Limiting & ACLs       |
                     |  - Packet Cache (Hit ~0.1ms)          |
                     +---------------------------------------+
                            /                         \
            (Domain Terblokir)              (Domain Legal / Whitelist)
                    /                                   \
                   v                                     v
         [Spoof Response IP]                   [Forward Port 5300]
         (IPv4 / IPv6 Spoof)                             |
                                                         v
                                     +---------------------------------------+
                                     |            Unbound (Tier 2)           |
                                     |  - Validating Recursive Resolver      |
                                     |  - DNSSEC Cryptographic Validation   |
                                     |  - Smart Threading & Memory Tuning    |
                                     |  - Upstream DoT / Quad9 / Cloudflare  |
                                     +---------------------------------------+
```

1. **Frontend (Port 53) — dnsdist**:
   - Menerima semua kueri DNS dari klien pada port `53`.
   - Melakukan evaluasi secepat kilat: domain yang terdaftar dalam jutaan entri blocklist langsung di-spoof ke alamat IP lokal/server pemblokir.
   - Domain yang aman atau masuk dalam whitelist diteruskan ke resolver lokal Unbound pada port `5300`.
   - Dilengkapi caching cerdas, packet inspection, dan proteksi DoS via Rate Limiter.
2. **Backend Resolver (Port 5300) — Unbound**:
   - Resolver rekursif murni yang memproses kueri legal dengan validasi kriptografi DNSSEC.
   - Konfigurasi disesuaikan secara dinamis sesuai jumlah core CPU dan RAM server (_Smart Tuning_).
3. **SmartDNS Web UI (Port 5000)**:
   - Panel manajemen berbasis Python web server mandiri (ringan, tanpa dependensi framework berat).
   - Menyediakan dashboard metrik live, editor konfigurasi berbasis formulir maupun raw text, alat uji `dig` terintegrasi, pemantauan status service, dan audit sistem.
4. **PowerDNS Web Console (Port 8083)**:
   - Konsol bawaan dnsdist untuk melihat query throughput, latency distribution, dan load balancing pool.

---

## 🌐 2. Persyaratan Sistem & Topologi Port

### Persyaratan Sistem Operasi

- **Ubuntu**: 20.04 LTS, 22.04 LTS, 24.04 LTS (x86_64, arm64/aarch64)
- **Debian**: 11 (Bullseye), 12 (Bookworm)
- **RAM**: Minimal 1 GB (Direkomendasikan 2 GB+ untuk blocklist > 500.000 domain)
- **CPU**: Minimal 1 Core (Direkomendasikan 2 Core+)
- **Disk**: Minimal 5 GB ruang kosong

### Alokasi Port Jaringan

| Layanan                 | Port   | Protokol   | Akses            | Keterangan                                          |
| :---------------------- | :----- | :--------- | :--------------- | :-------------------------------------------------- |
| **dnsdist Frontend**    | `53`   | UDP & TCP  | Publik / LAN     | Layanan DNS utama untuk seluruh klien jaringan      |
| **Unbound Backend**     | `5300` | UDP & TCP  | `127.0.0.1`      | Resolver internal (hanya diakses oleh dnsdist)      |
| **SmartDNS Web UI**     | `5000` | TCP (HTTP) | Terbatas (Admin) | Panel manajemen web SmartDNS terpadu                |
| **dnsdist Web Console** | `8083` | TCP (HTTP) | Terbatas (Admin) | Konsol metrik dan statistik bawaan PowerDNS dnsdist |

---

## 🚀 3. Panduan Instalasi (Installation Guide)

### Metode 1: Otomatis 1-Line cURL Installer (Direkomendasikan)

Jalankan perintah berikut di terminal server (sebagai `root` atau pengguna dengan hak akses `sudo`):

```bash
curl -sSL https://raw.githubusercontent.com/alsyundawy/SmartDNS/main/install.sh | bash
```

Installer akan otomatis:

1. Memeriksa kecocokan distribusi sistem operasi dan arsitektur CPU.
2. Mematikan `systemd-resolved` yang biasanya mengunci port 53 di Ubuntu.
3. Memasang paket dependensi: `dnsdist`, `unbound`, `bind9-dnsutils`, `curl`, `jq`, `openssl`, `python3`.
4. Menghitung tuning performa memori dan CPU secara optimal (_smart tuning engine_).
5. Mengunduh dan menggabungkan sumber blocklist domain.
6. Membangun konfigurasi `/etc/dnsdist/dnsdist.conf` dan `/etc/unbound/unbound.conf`.
7. Memasang dan mengaktifkan service `smartdns-ui.service` pada port `5000`.
8. Menampilkan kredensial login admin lengkap di akhir instalasi.

---

### Metode 2: Manual via Git Clone

Jika Anda ingin meninjau atau memodifikasi kode sebelum instalasi:

```bash
# 1. Clone repositori
git clone https://github.com/alsyundawy/SmartDNS.git
cd SmartDNS

# 2. Berikan izin eksekusi
chmod +x install.sh update.sh engine/*.sh

# 3. Jalankan wizard instalasi
sudo ./install.sh
```

---

### Metode 3: Non-Interaktif / Otomasi CI/CD

Untuk deployment otomatis (misal: Cloud-Init, Ansible, Terraform), Anda dapat menyuplai variabel lingkungan di depan perintah:

```bash
sudo NON_INTERACTIVE=true \
     IPV4_ADDRESS="103.151.222.227" \
     DNSDIST_WEB_PASSWORD="PasswordKuatAdmin2026!" \
     DNSSEC="yes" \
     RATE_LIMIT="yes" \
     AUTO_UPDATE="yes" \
     ./install.sh
```

Variabel yang didukung:

- `IPV4_ADDRESS`: Alamat IP Publik / Alamat IP Spoofing IPv4 utama.
- `IPV6_ADDRESS`: Alamat IP IPv6 (opsional).
- `DNSDIST_WEB_PASSWORD`: Kata sandi untuk login Web UI dan dnsdist console.
- `DNSSEC`: Aktifkan validasi DNSSEC (`yes` atau `no`).
- `RATE_LIMIT`: Aktifkan batas kecepatan kueri per IP (`yes` atau `no`).
- `AUTO_UPDATE`: Jadwalkan cron pembaruan blocklist harian (`yes` atau `no`).

---

## 🛠️ 4. Panduan Operasional & How-To

### Kontrol Layanan systemd

Seluruh komponen SmartDNS dikelola melalui `systemctl`:

```bash
# Memeriksa status semua layanan
systemctl status dnsdist
systemctl status unbound
systemctl status smartdns-ui

# Me-restart layanan
sudo systemctl restart dnsdist
sudo systemctl restart unbound
sudo systemctl restart smartdns-ui

# Menghentikan layanan
sudo systemctl stop dnsdist unbound smartdns-ui

# Melihat log langsung (realtime journal)
sudo journalctl -u smartdns-ui -f
sudo journalctl -u dnsdist -f
sudo journalctl -u unbound -f
```

---

### Akses & Login SmartDNS Web UI

1. Buka browser web dan arahkan ke alamat IP server:

   ```text
   http://<IP-SERVER-ANDA>:5000
   ```

2. Masukkan kredensial login:
   - **Username**: `admin`
   - **Password**: Password yang ditampilkan saat instalasi selesai (disimpan dalam `/etc/dnsdist/dnsdist.conf`).
3. Sesi login dilindungi token terenkripsi `HttpOnly; SameSite=Lax` dengan masa berlaku 24 jam.

---

### Pengaturan IP Spoofing (IPv4 & IPv6)

Untuk mengubah IP target ke mana domain terblokir dialihkan:

1. Buka tab **Pengaturan** di SmartDNS Web UI.
2. Pada bagian **IP Spoofing**:
   - Masukkan IP spoofing IPv4 (misal IP web landing page pemblokiran).
   - Masukkan IP spoofing IPv6 (jika menggunakan jaringan IPv6).
3. Klik tombol **Simpan Pengaturan**. Sistem akan otomatis memvalidasi sintaks konfigurasi dan me-restart `dnsdist`.

---

### Manajemen Whitelist Domain & Whitelist Client (ACL)

- **Whitelist Domain**:
  Domain yang didaftarkan di sini tidak akan pernah diblokir, meskipun terdapat dalam ribuan daftar blocklist. Kueri akan langsung diteruskan ke Unbound.
  _Contoh_: `google.com`, `bankmandiri.co.id`, `bca.co.id`.
- **Access Control List (ACL) Client IP**:
  Rentang subnet IP yang diizinkan untuk mengajukan kueri ke server DNS ini. Secara bawaan subnet `127.0.0.0/8` dan `::1/128` selalu diizinkan.
  _Contoh menambahkan subnet kantor_: `192.168.1.0/24`, `10.10.0.0/16`.

---

### SafeSearch Enforcement

SmartDNS memiliki fitur bawaan untuk memaksa pencarian aman (_SafeSearch_) pada mesin pencari populer tanpa memerlukan instalasi aplikasi pada perangkat klien:

- **Google**: Mengarahkan kueri domain Google ke IP `forcesafesearch.google.com` (`216.239.38.120`).
- **Bing**: Mengarahkan ke `strict.bing.com` (`204.79.197.220`).
- **YouTube**: Memaksa mode restricted YouTube.
- **DuckDuckGo**: Mengarahkan ke `safe.duckduckgo.com` (`52.142.124.215`).

Anda dapat mengaktifkan atau menonaktifkan masing-masing SafeSearch melalui centang tombol sakelar di tab **Pengaturan**.

---

### Rate Limiting (Proteksi DDoS/Flooding)

Untuk melindungi resolver dari serangan amplifikasi DNS atau banjir kueri (_DNS flood attacks_):

1. Buka tab **Pengaturan** > **Rate Limiting**.
2. Aktifkan sakelar Rate Limit.
3. Atur **Maksimal QPS per IP** (misal `100` QPS).
4. Pilih aksi pemblokiran:
   - `DropAction`: Membuang paket kueri tanpa balasan (hemat bandwidth, direkomendasikan).
   - `DelayAction`: Memperlambat respons kueri selama 50ms.
   - `TruncateAction`: Memaksa klien beralih ke TCP.

---

### Custom DNS Overrides

Anda dapat menambahkan pemetaan kustom domain ke IP lokal secara langsung (mirip berkas `/etc/hosts` terpusat):

- _Domain_: `server.kantor.lan` ➔ _IP_: `192.168.1.250`
- _Domain_: `app.internal.local` ➔ _IP_: `10.0.0.15`

Entri ini akan disuntikkan langsung ke dnsdist menggunakan aturan `SpoofAction` tercepat.

---

### Upstream DNS Resolvers

Secara bawaan Unbound melakukan resolusi rekursif penuh ke Root DNS Servers. Jika Anda ingin mengarahkan kueri ke upstream resolver tertentu:

- Cloudflare: `1.1.1.1`, `1.0.0.1`
- Google Public DNS: `8.8.8.8`, `8.8.4.4`
- Quad9: `9.9.9.9`, `149.112.112.112`
- AdGuard DNS: `94.140.14.14`

Pengaturan ini dapat disesuaikan pada konfigurasi upstream di Web UI atau melalui berkas `/etc/dnsdist/dnsdist.conf`.

---

## 🔍 5. Alat Diagnostik & Pengujian DNS Terintegrasi

Tab **Alat DNS** di Web UI menyediakan instrumen diagnostik tanpa harus membuka terminal SSH:

1. **Uji Resolusi DNS (`dig`)**:
   - Masukkan nama domain yang ingin diuji (misal: `detik.com`, `example.com`).
   - Pilih target uji:
     - `Frontend IPv4 (127.0.0.1)`: Menguji respon filter dnsdist port 53.
     - `Frontend IPv6 (::1)`: Menguji respon dnsdist IPv6.
     - `Recursive Unbound (127.0.0.1:5300)`: Menguji resolusi murni Unbound.
     - `Semua Target Sekaligus`: Menjalankan ketiga pengujian secara simultan.
   - Pilih tipe record: `A`, `AAAA`, `CNAME`, `MX`, `TXT`, `NS`, `PTR`, `SOA`, `ANY`.
   - Opsi `+short` untuk melihat hasil IP ringkas.
2. **Validasi Sintaks Konfigurasi**:
   - `unbound-checkconf`: Memeriksa integritas berkas konfigurasi `/etc/unbound/unbound.conf`.
   - `dnsdist --check-config`: Memeriksa sintaks skrip Lua `/etc/dnsdist/dnsdist.conf`.
3. **Pemeriksaan & Restart Service**:
   - Memeriksa uptime, memori, status aktif service `unbound` dan `dnsdist`.
   - Melakukan restart service secara aman hanya dengan 1 klik.

---

## 🔄 6. Manajemen Pembaruan Blocklist Otomatis

SmartDNS menggunakan skrip pembaruan blocklist mandiri di `/usr/local/bin/smartdns-update`:

### Struktur Sumber Blocklist

Daftar URL sumber blocklist disimpan di:

```text
/etc/smartdns/sources.txt
```

Anda dapat menambahkan URL blocklist baru (format hosts file atau plain domain list per baris) ke dalam berkas tersebut.

### Menjalankan Pembaruan Manual

```bash
sudo smartdns-update
```

Alur kerja skrip pembaruan:

1. Mengunduh daftar domain terbaru dari setiap URL di `sources.txt` menggunakan `curl` dengan timeout aman dan header ETag/Last-Modified.
2. Membersihkan karakter non-ASCII, komentar `#`, dan melakukan deduplikasi domain secara instan.
3. Menyimpan hasil olahan ke `/etc/smartdns/domains.txt`.
4. Memvalidasi berkas baru sebelum menimpa berkas lama (fail-safe protection).
5. Me-reload service `dnsdist` tanpa _downtime_ (zero query loss).

### Pengaturan Cron Terjadwal

Pembaruan blocklist dijadwalkan secara otomatis melalui cron di `/etc/cron.d/smartdns-update`:

```bash
# Menjalankan pembaruan setiap hari pada pukul 03.30 pagi
30 3 * * * root /usr/local/bin/smartdns-update > /var/log/smartdns-update.log 2>&1
```

---

## 📡 7. Arsitektur & Server Telemetri Mandiri (Self-Hosted)

SmartDNS dilengkapi sistem pelaporan telemetri kesehatan node terenkripsi yang dapat diarahkan ke server sendiri di bawah ekosistem domain [alsyundawy.com](https://alsyundawy.com).

### Komitmen Privasi & Keamanan

- **Zero DNS Data**: Telemetri **tidak pernah** merekam atau mengirimkan riwayat penjelajahan, log kueri DNS, data klien, atau isi cache.
- **Kedaulatan Data**: Data hanya dikirimkan ke server Anda sendiri tanpa pihak ketiga.
- **Transmisi Aman**: Komunikasi wajib menggunakan enkripsi HTTPS TLS dengan format JSON terstruktur.
- **UUID Unik**: Setiap instalasi diidentifikasi menggunakan UUID acak yang dibuat saat instalasi di `/var/lib/smartdns/uuid`.

### Spesifikasi Payload Telemetri

Data yang dilaporkan mencakup:

- Versi SmartDNS yang terpasang.
- Spesifikasi perangkat keras: model CPU, jumlah thread, kapasitas RAM, dan virtualisasi.
- Alamat IP publik node dan ketersediaan IPv6.
- Fitur aktif: status DNSSEC, status Rate Limiter, parameter smart tuning cache.
- Waktu uptime node dan status kesehatan service.

### Konfigurasi Endpoint Klien

Untuk mengubah alamat tujuan telemetri, ubah berkas `/var/lib/smartdns/install.env`:

```bash
SMARTDNS_TELEMETRY_URL="https://telemetry.alsyundawy.com/api/v1/heartbeat.php"
```

Untuk menonaktifkan telemetri sepenuhnya:

```bash
# Set variabel ke string kosong
SMARTDNS_TELEMETRY_URL=""
```

### Deployment Server Telemetri Mandiri (PHP Receiver)

Repositori ini telah menyediakan kode server telemetri siap pakai di folder [`tools/telemetry-server/`](file:///Users/alsyundawy/Downloads/GitHub/SmartDNS/tools/telemetry-server/):

1. Salin isi folder `tools/telemetry-server/` ke webroot server PHP Anda (misal Nginx + PHP 8.1+):

   ```bash
   cp -r tools/telemetry-server/* /var/www/telemetry/
   chown -R www-data:www-data /var/www/telemetry/
   chmod 750 /var/www/telemetry/data
   ```

2. Endpoint penerima heartbeat: `https://telemetry.domainanda.com/api/v1/heartbeat.php`.
3. Dashboard monitoring armada (_Fleet Monitor_): `https://telemetry.domainanda.com/?key=alsyundawy2026`.

---

## 🆙 8. Pembaruan Sistem (Update & Upgrade Engine)

Untuk memperbarui instalasi SmartDNS ke rilis terbaru dari repositori GitHub:

```bash
cd /opt/smartdns  # atau direktori repositori SmartDNS Anda
git pull origin main
sudo ./update.sh
```

Fitur skrip pembaruan `update.sh`:

- Memeriksa nomor versi di `VERSION`.
- Membuat cadangan otomatis konfigurasi aktif sebelum pembaruan.
- Memperbarui skrip engine, template, dan Web UI tanpa menghapus whitelist atau custom DNS kustom Anda.
- Melakukan verifikasi linting dan restart layanan secara mulus.

---

## ❓ 9. Pemecahan Masalah (Troubleshooting & FAQ)

### Masalah 1: Port 53 Bentrok / Gagal Bind Port 53

**Penyebab**: `systemd-resolved` bawaan Ubuntu mendengarkan di `127.0.0.53:53`.

**Solusi**:

```bash
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo rm -f /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
sudo systemctl restart dnsdist
```

---

### Masalah 2: Web UI (Port 5000) Tidak Dapat Diakses dari Luar

**Penyebab**: Firewall sistem (UFW/iptables) atau Security Group penyedia Cloud memblokir port 5000.

**Solusi**:

```bash
# Buka port di firewall UFW
sudo ufw allow 5000/tcp
sudo ufw allow 53/udp
sudo ufw allow 53/tcp

# Pastikan service smartdns-ui sedang berjalan
sudo systemctl status smartdns-ui
```

---

### Masalah 3: Lupa Password Login Web UI

**Solusi**:
Kata sandi Web UI terikat langsung dengan konfigurasi `dnsdist.conf`. Anda dapat melihat atau mengubahnya langsung:

```bash
# Melihat password saat ini:
grep -A 4 "setWebserverConfig" /etc/dnsdist/dnsdist.conf

# Mengubah password:
# Edit nilai password="..." di /etc/dnsdist/dnsdist.conf
sudo nano /etc/dnsdist/dnsdist.conf
sudo systemctl restart dnsdist smartdns-ui
```

---

### Masalah 4: Klien Tidak Mendapatkan Internet Setelah Mengarahkan DNS

**Penyebab**: Subnet IP klien belum didaftarkan di ACL Unbound/dnsdist.

**Solusi**:
Buka Web UI > **Pengaturan** > **Access Control List (ACL)**, tambahkan subnet IP jaringan lokal Anda (misal `192.168.0.0/16` atau `10.0.0.0/8`), lalu simpan pengaturan.

---

## 📁 10. Struktur Berkas & Direktori Sistem

| Path Berkas / Direktori          | Fungsi & Keterangan                                              |
| :------------------------------- | :--------------------------------------------------------------- |
| `/etc/dnsdist/dnsdist.conf`      | Berkas konfigurasi utama frontend load balancer & filter dnsdist |
| `/etc/unbound/unbound.conf`      | Berkas konfigurasi resolver rekursif Unbound                     |
| `/etc/smartdns/sources.txt`      | Daftar URL sumber blocklist eksternal                            |
| `/etc/smartdns/domains.txt`      | Basis data domain terfilter aktif (jutaan domain)                |
| `/opt/smartdns-ui/server.py`     | Aplikasi backend SmartDNS Management Web UI (Python 3)           |
| `/opt/smartdns-ui/sessions.json` | Basis data sesi login admin terenkripsi (`chmod 600`)            |
| `/var/lib/smartdns/uuid`         | Identitas unik instans node SmartDNS (`chmod 600`)               |
| `/var/lib/smartdns/install.env`  | Konfigurasi lingkungan instalasi & endpoint telemetri            |
| `/usr/local/bin/smartdns-update` | Skrip pembaru blocklist otomatis                                 |
| `/etc/cron.d/smartdns-update`    | Penjadwal pembaruan blocklist harian                             |
| `/var/log/dnsdist.log`           | Berkas log operasional dnsdist                                   |
| `/var/log/unbound.log`           | Berkas log resolusi dan error Unbound                            |
| `/var/log/smartdns-ui.log`       | Berkas log aktivitas panel SmartDNS Web UI                       |
| `/var/log/smartdns-update.log`   | Berkas log unduhan & pembaruan blocklist harian                  |

---

<div align="center">

**SmartDNS** dikembangkan dan dioptimalkan dengan standar keamanan tertinggi oleh [ALSYUNDAWY IT SOLUTION](https://alsyundawy.com) bersama komunitas open-source.

</div>
