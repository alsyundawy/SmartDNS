#!/usr/bin/env bash
#
# CHANGELOG:
# - Standardized variable expansion by consistently using ${VAR} across all shell
#   scripts to improve readability, consistency, and safety.
# - Fixed ShellCheck warnings.
# - Corrected Markdown formatting errors.
# - Added appropriate ShellCheck directives and disabled SC2312/SC2153/SC2034 where safe.
# - Removed unused color variables and IPV6_INTERFACE assignments.
# - Improved shebang declarations.
# - Expanded OS support to Ubuntu 22.04, 24.04, 26.04 and Debian 11, 12, 13.
# - Optimized package installation sequence to resolve port 53 bind conflicts.
# - Corrected dynamic IPv6 frontend and backend rendering in dnsdist templates.
# - Sourced LC_ALL=C locale execution for consistent English command output parsing.
# - Improved telemetry UUID generation with stable kernel-based /proc/sys/kernel/random/uuid fallback.
# - Pointed cron updater scheduler to permanent /opt/blocklist/update-blocklist.sh script.
# - Added @reboot cron entry to ensure 127.0.1.1 SmartDNS is present in /etc/hosts on every boot.
#   (Merged from ichandkusuma/SmartDNS)
#

####################################
# Install Scheduler
####################################

install_scheduler() {

	info "Installing Scheduler..."

	# Pastikan cron aktif
	systemctl enable --now cron >/dev/null 2>&1 || true

	# Random schedule (sekali saat install)
	HOUR=$((RANDOM % 6))    # 00-05
	MINUTE=$((RANDOM % 60)) # 00-59

	cat >/etc/cron.d/smartdns <<EOF
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# SmartDNS Auto Update
${MINUTE} ${HOUR} * * * root /opt/blocklist/update-blocklist.sh >>/var/log/smartdns-blocklist.log 2>&1

# SmartDNS Hosts
@reboot root /bin/bash -c 'grep -qxF "127.0.1.1 SmartDNS" /etc/hosts || echo "127.0.1.1 SmartDNS" >> /etc/hosts'
EOF

	chmod 644 /etc/cron.d/smartdns

	# Reload cron
	systemctl reload cron >/dev/null 2>&1 ||
		systemctl restart cron >/dev/null 2>&1

	success "Scheduler installed."
	info "Daily update scheduled at $(printf "%02d:%02d" "${HOUR}" "${MINUTE}")."

}

####################################
# Heartbeat Scheduler
####################################

install_heartbeat_scheduler() {

	info "Installing Heartbeat Scheduler..."

	install -Dm755 \
		"${BASE_DIR}/scripts/smartdns-heartbeat" \
		/usr/local/bin/smartdns-heartbeat

	install -Dm644 \
		"${BASE_DIR}/templates/smartdns-heartbeat.cron" \
		/etc/cron.d/smartdns-heartbeat

	chmod 644 /etc/cron.d/smartdns-heartbeat

	# Reload cron
	systemctl reload cron >/dev/null 2>&1 ||
		systemctl restart cron >/dev/null 2>&1

	success "Heartbeat scheduler installed."

}
