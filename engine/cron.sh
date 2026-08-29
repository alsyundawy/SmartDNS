#!/usr/bin/env bash

####################################
# Ensure Cron
####################################

ensure_cron() {

    if ! systemctl enable --now cron >/dev/null 2>&1; then
        error "Failed to enable/start cron service."
        return 1
    fi

    if ! systemctl is-active --quiet cron; then
        error "cron service is not running."
        return 1
    fi

    return 0
}

####################################
# Reload Cron
####################################

reload_cron() {

    if systemctl reload cron >/dev/null 2>&1; then
        return 0
    fi

    if systemctl restart cron >/dev/null 2>&1; then
        if systemctl is-active --quiet cron; then
            return 0
        fi
    fi

    error "Failed to reload/restart cron service."
    return 1
}

####################################
# Install Scheduler
####################################

install_scheduler() {

    info "Installing Scheduler..."

    ensure_cron || return 1

    # Random schedule (once during installation)
    HOUR=$(( RANDOM % 6 ))
    MINUTE=$(( RANDOM % 60 ))

    cat >/etc/cron.d/smartdns <<EOF2
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# SmartDNS Blocklist Auto Update
${MINUTE} ${HOUR} * * * root ${BASE_DIR}/data/update-blocklist.sh >>/var/log/smartdns-blocklist.log 2>&1

# SmartDNS Hosts
@reboot root /bin/bash -c 'grep -qxF "127.0.1.1 SmartDNS" /etc/hosts || echo "127.0.1.1 SmartDNS" >> /etc/hosts
EOF2

    chmod 644 /etc/cron.d/smartdns

    reload_cron || return 1

    success "Scheduler installed."
    info "Daily update scheduled at $(printf "%02d:%02d" "$HOUR" "$MINUTE")."

}

####################################
# Heartbeat Scheduler
####################################

install_heartbeat_scheduler() {

    ensure_cron || return 1

    install -Dm755 \
        "$BASE_DIR/scripts/smartdns-heartbeat" \
        /usr/local/bin/smartdns-heartbeat

    install -Dm644 \
        "$BASE_DIR/templates/smartdns-heartbeat.cron" \
        /etc/cron.d/smartdns-heartbeat

    chmod 644 /etc/cron.d/smartdns-heartbeat

    reload_cron || return 1

    success "Heartbeat scheduler installed."

}

#########################################
# Automatic Update Scheduler
#########################################

automatic_update_scheduler() {

    if [[ "$ENABLE_AUTO_UPDATE" == "yes" ]]; then

        info "Installing Automatic Update Scheduler..."

        ensure_cron || return 1

        # Random schedule (once during installation)
        HOUR=$(( RANDOM % 6 ))
        MINUTE=$(( RANDOM % 60 ))

        cat >/etc/cron.d/smartdns-update <<EOF2
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# SmartDNS patch Auto Update
${MINUTE} ${HOUR} * * * root ${BASE_DIR}/update.sh --patch >> /var/log/smartdns-update.log 2>&1
EOF2

        chmod 644 /etc/cron.d/smartdns-update

        reload_cron || return 1

        success "Automatic Update scheduler installed."
        info "Automatic Update at $(printf "%02d:%02d" "$HOUR" "$MINUTE")."

    else

        rm -f /etc/cron.d/smartdns-update

        info "Automatic Update disabled."

    fi

}
