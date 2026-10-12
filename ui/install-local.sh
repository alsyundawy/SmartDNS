#!/usr/bin/env bash
#
# CHANGELOG:
# - Standardized variable expansion by consistently using ${VAR} across all shell
#   scripts to improve readability, consistency, and safety.
# - Fixed ShellCheck warnings (SC2086 array packaging for missing dependencies).
# - Added robust command path checks and strict error handling.
#

# ==============================================================================
# SmartDNS UI - Local Server Installer & Setup Script
# Dijalankan langsung di server Linux target (sebagai root)
# Penggunaan: bash install-local.sh
# ==============================================================================
set -e

# Pastikan dijalankan sebagai root
if [[ ${EUID} -ne 0 ]]; then
	echo -e "\033[1;31m[ERROR] Skrip ini harus dijalankan sebagai root (gunakan sudo atau root shell).\033[0m"
	exit 1
fi

TARGET_DIR="/opt/smartdns-ui"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo -e "\033[1;36m===========================================================\033[0m"
echo -e "\033[1;36m  SmartDNS UI Local Installation & Setup\033[0m"
echo -e "\033[1;36m===========================================================\033[0m"

# 1. Cek & Install Dependensi Sistem
echo -e "\033[1;33m>>> [1/7] Memeriksa paket dependensi sistem...\033[0m"
MISSING_PKGS=()
for pkg in python3 dig ss; do
	if ! command -v "${pkg}" >/dev/null 2>&1; then
		case "${pkg}" in
		python3) MISSING_PKGS+=("python3") ;;
		dig) MISSING_PKGS+=("bind9-dnsutils") ;;
		ss) MISSING_PKGS+=("iproute2") ;;
		*) : ;;
		esac
	fi
done

if [[ ${#MISSING_PKGS[@]} -gt 0 ]]; then
	echo -e "\033[1;33mMenginstal paket yang belum tersedia: ${MISSING_PKGS[*]}...\033[0m"
	apt-get update -qq && apt-get install -y -qq "${MISSING_PKGS[@]}"
else
	echo -e "\033[1;32m✓ Semua dependensi utama (python3, bind9-dnsutils, iproute2) sudah terpasang.\033[0m"
fi

# 2. Siapkan direktori kerja
echo -e "\033[1;33m>>> [2/7] Menyiapkan struktur direktori...\033[0m"
mkdir -p "${TARGET_DIR}/static"
mkdir -p /etc/unbound/unbound.conf.d

# 3. Salin file aplikasi ke /opt/smartdns-ui jika dijalankan dari direktori lain
if [[ ${SCRIPT_DIR} != "${TARGET_DIR}" ]]; then
	echo -e "\033[1;33m>>> [3/7] Menyalin file aplikasi ke ${TARGET_DIR}...\033[0m"
	if [[ -f "${SCRIPT_DIR}/server.py" ]]; then
		cp -f "${SCRIPT_DIR}/server.py" "${TARGET_DIR}/"
	fi
	if [[ -d "${SCRIPT_DIR}/static" ]]; then
		cp -rf "${SCRIPT_DIR}/static/." "${TARGET_DIR}/static/"
	fi
fi

# 4. Pasang / Perbarui systemd service unit
echo -e "\033[1;33m>>> [4/7] Mengonfigurasi systemd service...\033[0m"
if [[ -f "${SCRIPT_DIR}/smartdns-ui.service" ]]; then
	cp -f "${SCRIPT_DIR}/smartdns-ui.service" /etc/systemd/system/smartdns-ui.service
elif [[ ! -f /etc/systemd/system/smartdns-ui.service ]]; then
	cat <<EOF >/etc/systemd/system/smartdns-ui.service
[Unit]
Description=SmartDNS Control Center & Management Web UI
After=network.target dnsdist.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/smartdns-ui
ExecStart=/usr/bin/python3 /opt/smartdns-ui/server.py
Restart=always
RestartSec=3
Environment=PYTHONUNBUFFERED=1
Environment="SMARTDNS_DIR=${BASE_DIR}"

[Install]
WantedBy=multi-user.target
EOF
fi

# Pastikan service selalu memakai root repository SmartDNS.
SERVICE_FILE="/etc/systemd/system/smartdns-ui.service"

if grep -q '^Environment="SMARTDNS_DIR=' "${SERVICE_FILE}"; then
	sed -i "s|^Environment=\"SMARTDNS_DIR=.*|Environment=\"SMARTDNS_DIR=${BASE_DIR}\"|" "${SERVICE_FILE}"
else
	sed -i "/^Environment=PYTHONUNBUFFERED=1$/a Environment=\\\"SMARTDNS_DIR=${BASE_DIR}\\\"" "${SERVICE_FILE}"
fi

# 5. Atur hak akses permission
echo -e "\033[1;33m>>> [5/7] Mengatur hak akses (permissions)...\033[0m"
chmod +x "${TARGET_DIR}/server.py" 2>/dev/null || true
chmod 644 /etc/systemd/system/smartdns-ui.service

# 6. Buka Firewall UFW jika aktif
if command -v ufw >/dev/null 2>&1; then
	UFW_STATUS=$(ufw status 2>/dev/null || true)
	if echo "${UFW_STATUS}" | grep -q "Status: active"; then
		echo -e "\033[1;33m>>> [6/7] Terdeteksi firewall UFW aktif, mengizinkan port 5000/tcp...\033[0m"
		ufw allow 5000/tcp comment "SmartDNS Web UI" >/dev/null 2>&1 || true
	else
		echo -e "\033[1;32m✓ [6/7] Firewall UFW tidak aktif atau port sudah terbuka.\033[0m"
	fi
else
	echo -e "\033[1;32m✓ [6/7] Firewall UFW tidak terpasang.\033[0m"
fi

# 7. Reload & restart service
echo -e "\033[1;33m>>> [7/7] Mengaktifkan & merestart service smartdns-ui...\033[0m"
systemctl daemon-reload
systemctl enable smartdns-ui.service
systemctl restart smartdns-ui.service

# Verifikasi status
sleep 1
if systemctl is-active --quiet smartdns-ui.service; then
	STATUS_TXT="\033[1;32mACTIVE (RUNNING)\033[0m"
else
	STATUS_TXT="\033[1;31mFAILED TO START\033[0m"
fi

RAW_IPS=$(hostname -I 2>/dev/null || true)
SERVER_IP=$(awk '{print $1}' <<<"${RAW_IPS}")
if [[ -z ${SERVER_IP} ]]; then
	SERVER_IP="<IP-SERVER-ANDA>"
fi

echo -e "\n\033[1;32m===========================================================\033[0m"
echo -e "  ✓ SmartDNS UI Selesai Dipasang!"
echo -e "===========================================================\033[0m"
echo -e "Status Service:   ${STATUS_TXT}"
echo -e "Dashboard Web UI: \033[1;36mhttp://${SERVER_IP}:5000\033[0m"
echo -e "Login Username:   \033[1;33madmin\033[0m"
echo -e "Login Password:   mengikuti password DNSDist Web UI (:8083)\n"
