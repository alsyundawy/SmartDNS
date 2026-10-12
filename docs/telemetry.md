# 📡 SmartDNS Telemetry Architecture & Security Guide

Panduan teknis dan spesifikasi arsitektur telemetri mandiri (_self-hosted telemetry_) untuk ekosistem **SmartDNS** di bawah domain [alsyundawy.com](https://alsyundawy.com).

> [!NOTE]
> Panduan ini dan seluruh dokumentasi operasional, instalasi, Web UI, serta arsitektur SmartDNS telah dikonsolidasikan dalam satu berkas terpadu di [docs/GUIDE.md](file:///Users/alsyundawy/Downloads/GitHub/SmartDNS/docs/GUIDE.md).

---

## 🔒 Analisis Keamanan & Privasi

1. **Enkripsi In-Transit**: Seluruh transmisi payload telemetri diwajibkan menggunakan HTTPS/TLS.
2. **Tidak Ada Data DNS / Riwayat Klien**: Telemetri **tidak pernah** mengumpulkan kueri DNS, log penjelajahan pengguna, data lalu lintas, atau cache resolver.
3. **Kendali Penuh (Full Data Sovereignty)**: Dengan mengarahkan endpoint ke `alsyundawy.com` atau server sendiri, data IP publik dan spesifikasi node tidak lagi diekspos ke pihak luar manapun.
4. **Proteksi Akses Lokal**: Berkas UUID di `/var/lib/smartdns/uuid` dan `/var/lib/smartdns/install.json` di-set izin `chmod 600` (hanya dapat diakses oleh akun root).
5. **Fail-Safe & Non-Blocking**: Skrip klien `smartdns-heartbeat` dilengkapi batas waktu timeout ketat (`--connect-timeout 10`, `--max-time 30`) sehingga kegagalan jaringan atau server penerima tidak akan memengaruhi kinerja resolusi DNS.

---

## 📋 Spesifikasi API Telemetri

### Endpoint

- **Metode**: `POST`
- **URL**: `https://telemetry.alsyundawy.com/api/v1/heartbeat.php`
- **Header**:
  - `Content-Type: application/json`
  - `User-Agent: SmartDNS/<versi>`

### Contoh Permintaan (JSON Payload)

```json
{
  "uuid": "4f8a1234-abcd-4def-9876-123456789abc",
  "product": "SmartDNS",
  "version": "1.0.3-shellcheck-optimizer",
  "system": {
    "hostname": "dns01.alsyundawy.com",
    "os": "Ubuntu",
    "version": "24.04",
    "kernel": "6.8.0-45-generic",
    "uptime": "15 days, 2 hours",
    "arch": "x86_64",
    "cpu_model": "AMD EPYC 7763",
    "cpu_threads": 4,
    "memory_mb": 4096,
    "virtualization": "KVM"
  },
  "network": {
    "ipv4": "103.151.222.227",
    "ipv6": "",
    "ipv6_available": "no"
  },
  "features": {
    "ipv6": false,
    "dnssec": true,
    "ratelimit": true,
    "querylog": false
  },
  "spoof": {
    "ipv4_default": true,
    "ipv6_default": true
  },
  "tuning": {
    "threads": 4,
    "rrset_cache": "64m",
    "msg_cache": "32m",
    "slabs": 4,
    "outgoing_range": 4096,
    "num_queries": 2048,
    "infra_cache": 10000,
    "dnsdist_cache": 100000,
    "tcp_threads": 4,
    "tcp_queue": 100,
    "udp_outstanding": 65535
  }
}
```

### Format Respons Sukses

```json
{
  "status": "ok",
  "message": "Heartbeat acknowledged",
  "uuid": "4f8a1234-abcd-4def-9876-123456789abc",
  "timestamp": 1791807600
}
```

---

## 🛠️ Konfigurasi Klien (SmartDNS Node)

### 1. Mengubah Endpoint Target

Tambahkan variabel `SMARTDNS_TELEMETRY_URL` pada `/var/lib/smartdns/install.env`:

```bash
SMARTDNS_TELEMETRY_URL="https://telemetry.alsyundawy.com/api/v1/heartbeat.php"
```

### 2. Menonaktifkan Pengiriman Telemetri

Jika node berada di jaringan terisolasi atau Anda memilih untuk tidak mengirim data status:

```bash
SMARTDNS_TELEMETRY_URL="disable"
# atau
TELEMETRY_DISABLE=true
```

---

## 🖥️ Server Penerima (Self-Hosted Backend)

Paket server backend penerima telah disertakan di folder [`tools/telemetry-server/`](file:///Users/alsyundawy/Downloads/GitHub/SmartDNS/tools/telemetry-server).
Paket ini berisi:

- **`api/v1/heartbeat.php`**: Skrip penerima API dengan validasi format UUID anti-traversal dan ekstraksi IP Cloudflare/proxy.
- **`index.php`**: Dashboard web interaktif untuk memonitor seluruh armada node Anda secara real-time.
- **`data/.htaccess`**: Proteksi file JSON data node.
