<div align="center">

# SmartDNS

### Automated DNS Resolver Platform for ISP & Enterprise Networks

Developed and maintained by **MyNOC.ID**

<img src="docs/images/banner.png" width="100%">

<br>

![Version](https://img.shields.io/badge/version-v1.0.0-0078D7)
![Build](https://img.shields.io/badge/build-stable-success)
![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04+-E95420)
![Debian](https://img.shields.io/badge/Debian-12-A81D33)
![License](https://img.shields.io/github/license/ichandkusuma/SmartDNS)
![Status](https://img.shields.io/badge/status-production_ready-brightgreen)

</div>

---

# About

SmartDNS is an open-source DNS Resolver Platform developed by **MyNOC.ID**.

Designed specifically for **Internet Service Providers (ISP)**, **Enterprise Networks**, **Network Operators**, and **Data Centers**, SmartDNS automates deployment, optimization, security hardening, monitoring, and lifecycle management of recursive DNS servers using **Unbound** and **dnsdist**.

Starting from **v1.0.0**, SmartDNS also includes a built-in telemetry platform and centralized monitoring dashboard for managing SmartDNS deployments.

---

# Features

## Smart Installation

- Automatic Hardware Detection
- Automatic Operating System Detection
- Automatic CPU Detection
- Automatic Memory Detection
- Automatic Network Detection
- Automatic Internet Detection
- Automatic Hostname Detection
- Automatic Kernel Detection
- Automatic Virtualization Detection
- Automatic Uptime Detection

---

## Smart Configuration

- Automatic Unbound Configuration
- Automatic dnsdist Configuration
- Automatic Runtime Builder
- Automatic ACL Generator
- Automatic Security Hardening
- Automatic Swap Optimization
- Automatic Sysctl Optimization

---

## DNS Features

- DNSSEC
- IPv6 Support
- DNS Blocklist
- Rate Limiting
- Query Logging
- dnsdist Web API

---

## Monitoring

- Automatic Heartbeat
- Built-in Telemetry
- Dashboard
- Node Inventory
- Node Detail
- Statistics Dashboard
- Version Distribution
- Online / Offline Monitoring

---

# Supported Operating Systems

| Distribution | Status |
|--------------|--------|
| Ubuntu 22.04 LTS | ✅ Supported |
| Debian 12 | ✅ Supported |
| Ubuntu 24.04 LTS | ⚠ Experimental |

---

# Minimum Requirements

| Component | Minimum |
|-----------|---------:|
| CPU | 2 Core |
| RAM | 2 GB |
| Storage | 20 GB |
| Internet | Required |

---

# Installation

```bash
git clone https://github.com/ichandkusuma/SmartDNS.git

cd SmartDNS

bash install.sh
```

---

# Updating SmartDNS

Updating SmartDNS uses the same installer.

```bash
cd SmartDNS

git pull

bash install.sh
```

The installer will automatically:

- Detect existing installation
- Preserve UUID
- Preserve telemetry information
- Update SmartDNS components
- Update templates
- Update scheduler
- Restart required services

No manual migration is required.

---

# Installation Modes

## Fresh Installation

If SmartDNS has never been installed, the installer performs a full installation.

## Upgrade

If an existing SmartDNS installation is detected, the installer automatically performs an upgrade while preserving:

- UUID
- Telemetry
- Existing configuration
- Scheduler
- Runtime information

---

# Smart Installation Workflow

```
Hardware Detection

        │

        ▼

Smart Auto Tuning

        │

        ▼

Installation Wizard

        │

        ▼

ACL Generator

        │

        ▼

Security Hardening

        │

        ▼

Blocklist Installation

        │

        ▼

Runtime Builder

        │

        ▼

Configuration Deployment

        │

        ▼

Health Check

        │

        ▼

Heartbeat Registration

        │

        ▼

Monitoring Dashboard
```

---

# Smart Auto Tuning

SmartDNS automatically calculates the optimal configuration based on detected hardware.

## Unbound

- Threads
- RRSET Cache
- Message Cache
- Slabs
- Outgoing Range
- Number of Queries
- Infra Cache

## dnsdist

- Packet Cache
- TCP Threads
- TCP Queue
- UDP Outstanding

No manual tuning is required.

---

# Monitoring Platform

SmartDNS Monitoring includes:

- Dashboard
- Nodes
- Node Detail
- Statistics
- Version Distribution
- Operating System Distribution
- Virtualization Distribution
- IPv6 Statistics
- DNSSEC Statistics
- Online / Offline Status

---

# Built-in Telemetry

Every SmartDNS installation automatically sends a heartbeat every **5 minutes**.

Collected information:

- SmartDNS Version
- UUID
- Operating System
- Kernel
- CPU Model
- CPU Threads
- Memory
- Virtualization
- IPv4
- IPv6
- DNSSEC Status
- Query Log Status
- Rate Limit Status
- Smart Tuning Configuration
- First Seen
- Last Seen

---

# Privacy

SmartDNS **does NOT collect**:

- DNS Queries
- Customer Traffic
- Resolver Cache
- Domain Names
- Client IP Addresses
- Personal Information

Telemetry is used only for:

- Version Statistics
- Compatibility
- Installation Monitoring
- Deployment Statistics

---

# Architecture

```
             SmartDNS Node

                    │

      Heartbeat (Every 5 Minutes)

                    │

                    ▼

         SmartDNS Telemetry API

                    │

                    ▼

             JSON Storage

                    │

                    ▼

      SmartDNS Monitoring Dashboard
```

---

# Project Structure

```
SmartDNS/

├── cache/
├── data/
├── docs/
├── engine/
├── lib/
├── output/
├── scripts/
├── templates/
├── VERSION
├── install.sh
└── README.md
```

---

# Runtime Files

SmartDNS stores runtime information under:

```
/var/lib/smartdns/

├── uuid
├── install.json
└── install.env
```

These files are automatically created during installation and preserved during upgrades.

---

# Screenshots

## Dashboard

![Dashboard](docs/images/dashboard.png)

---

## Nodes

![Nodes](docs/images/nodes.png)

---

## Node Detail

![Node Detail](docs/images/node-detail.png)

---

## Statistics

![Statistics](docs/images/statistics.png)

---

# Roadmap

## Version 1.0.0

- [x] Smart Installer
- [x] Hardware Detection
- [x] Smart Auto Tuning
- [x] Runtime Builder
- [x] ACL Generator
- [x] Security Hardening
- [x] Blocklist
- [x] Scheduler
- [x] Heartbeat
- [x] Telemetry
- [x] Dashboard
- [x] Node Inventory
- [x] Node Detail
- [x] Statistics

---

## Planned

- [ ] SmartDNS CLI
- [ ] Update Checker
- [ ] SmartDNS Update Command
- [ ] Automatic Update
- [ ] Release Channel

---

# Changelog

See [CHANGELOG.md](CHANGELOG.md)

---

# License

This project is licensed under the MIT License.

---

# Developed By

## MyNOC.ID

**Network • Automation • Monitoring**

Founder & Lead Developer

**iChand Kusuma**

GitHub

https://github.com/ichandkusuma

Website

https://mynoc.id

Email

admin@mynoc.id

---

<div align="center">

### ⭐ If SmartDNS helps your infrastructure, please consider giving this repository a Star.

Made with ❤️ by **MyNOC.ID**

</div>
