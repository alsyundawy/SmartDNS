# SmartDNS Installer

High Performance Recursive DNS Resolver built with **Unbound** and **dnsdist** for ISP, Enterprise, VPS and Self-Hosted environments.

SmartDNS Installer automatically detects your server hardware and generates an optimized DNS configuration with minimal user interaction.

---

# Features

* One Command Installation
* Automatic Hardware Detection
* Smart CPU & RAM Tuning
* Recursive DNS Resolver (Unbound)
* High Performance DNS Load Balancer (dnsdist)
* DNSSEC Validation
* DNS Packet Cache
* IPv4 & IPv6 Support
* DNS Blocklist (TrustPositif)
* Domain Whitelist
* Domain Insecure Support
* DNSDist Web Management
* Automatic Blocklist Update
* Automatic Root Hints Update
* Automatic Backup
* Automatic Health Check
* Automatic Timezone Configuration
* Automatic Hostname Configuration
* Smart Scheduler (Cron)
* Interactive Installation Wizard

---

# Minimum Requirements

| Component   | Minimum     |
| ----------- | ----------- |
| CPU         | 2 Core      |
| RAM         | 2 GB        |
| Storage     | 10 GB       |
| Network     | Public IPv4 |
| Root Access | Required    |

---

# Recommended Requirements

| Component | Recommended      |
| --------- | ---------------- |
| CPU       | 4 Core or Higher |
| RAM       | 4 GB or Higher   |
| Storage   | 15GB SSD         |
| Network   | IPv4 + IPv6      |
| OS        | Ubuntu 22.04 LTS |

---

# Supported Operating System

* Ubuntu 22.04 LTS (Recommended)

Future Support

* Ubuntu 24.04 LTS
* Debian 12

---

# Installation

Clone repository

```bash
git clone https://github.com/ichandkusuma/SmartDNS.git
```

Enter project directory

```bash
cd SmartDNS
```

Grant execute permission

```bash
chmod +x install.sh
```

Run installer

```bash
./install.sh
```

---

# Installation Wizard

The installer will automatically configure:

* Hostname
* Timezone
* CPU Threads
* Cache Size
* DNSSEC
* IPv6
* Packet Cache
* DNSDist Web Password
* DNSDist API Key
* Recursive Port
* Frontend Port
* Spoof IPv4
* Spoof IPv6
* Resolver ACL

---

# Default Service Ports

| Service            | Port |
| ------------------ | ---: |
| DNS Resolver       |   53 |
| Recursive Resolver | 5300 |
| DNSDist Web UI     | 8083 |

---

# DNS Features

## DNSSEC

Validate DNS responses using DNSSEC.

---

## Recursive Resolver

Uses Unbound as a full recursive DNS resolver.

---

## DNS Cache

Optimized packet cache and recursive cache.

---

## IPv4 & IPv6

Supports both IPv4 and IPv6.

---

## DNS Blocklist

Automatically blocks malicious and restricted domains.

Current source:

* TrustPositif Indonesia

Automatic update every day at **03:00 WIB**.

---

## Domain Whitelist

Domains can bypass blocklist.

Example:

* bri.co.id
* bca.co.id
* bankmandiri.co.id

---

## Domain Insecure

Support for domains that have DNSSEC validation issues.

---

## DNSDist Web UI

Manage DNSDist using a web browser.

Default URL

```
http://SERVER_IP:8083
```

---

# Automatic Scheduler

| Task              | Schedule    |
| ----------------- | ----------- |
| Blocklist Update  | Daily 03:00 |
| Root Hints Update |      -      |

---

# Generated Automatically

During installation SmartDNS automatically generates:

* DNSDist Secret Key
* DNSDist API Key
* DNSDist Web Password
* Optimized Cache Size
* Optimized Thread Count
* Optimized Performance Configuration
* Resolver ACL

---

# Project Structure

```
SmartDNS/
├── cache/
├── data/
├── engine/
├── output/
├── templates/
├── install.sh
├── uninstall.sh
└── README.md
```

---

# Useful Commands

## Restart DNS

```bash
systemctl restart unbound
systemctl restart dnsdist
```

---

## Service Status

```bash
systemctl status unbound
systemctl status dnsdist
```

---

## Test DNS

```bash
dig @127.0.0.1 google.com
```

IPv6

```bash
dig @::1 google.com
```

---

## Check Configuration

Unbound

```bash
unbound-checkconf
```

DNSDist

```bash
dnsdist --check-config
```

---

## Check Listening Port

```bash
ss -lntup | grep 53
```

---

## Manual Blocklist Update

```bash
bash data/update-blocklist.sh
```

---

## View DNSDist Web Password

```bash
cat cache/secret.env
```

---

## Cron Schedule

```bash
cat /etc/cron.d/smartdns
```

---

# License

MIT License
Presented by <a href="https://mynoc.id/" target=_blank>MyNOC.ID</a>

---

# Disclaimer

This project is intended for educational, laboratory, enterprise, ISP and self-hosted DNS environments.

Please test configurations in your own environment before deploying to production.
