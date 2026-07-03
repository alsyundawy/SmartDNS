#!/usr/bin/env bash

####################################
# Install Scheduler
####################################

install_scheduler(){

    info "Installing Scheduler..."

    # Pastikan cron terinstall & aktif
    systemctl enable --now cron >/dev/null 2>&1 || true

    cat >/etc/cron.d/smartdns <<EOF
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# SmartDNS Auto Update

0 3 * * * root ${BASE_DIR}/data/update-blocklist.sh >/var/log/smartdns-blocklist.log 2>&1

EOF

    chmod 644 /etc/cron.d/smartdns

    # Reload cron
    systemctl reload cron >/dev/null 2>&1 || \
    systemctl restart cron >/dev/null 2>&1

    success "Scheduler installed."

}
