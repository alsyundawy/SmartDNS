#!/usr/bin/env bash

#########################################
# SmartDNS Feature Updater
#########################################

update_features() {

    info "Updating SmartDNS features..."

    #####################################
    # Telemetry Heartbeat
    #####################################

    if [[ -f "$BASE_DIR/scripts/smartdns-heartbeat" ]]; then

        install -m 755 \
            "$BASE_DIR/scripts/smartdns-heartbeat" \
            /usr/local/bin/smartdns-heartbeat

        success "Telemetry heartbeat updated."

    else

        warn "Telemetry heartbeat script not found."

    fi

    #####################################
    # Blocklist
    #####################################

    if [[ -f "$BASE_DIR/engine/blocklist.sh" ]]; then

        info "Updating DNS Blocklist..."

        install_blocklist || {
            error "Blocklist update failed."
            return 1
        }

    fi

    #####################################
    # Scheduler
    #####################################

    info "Updating Scheduler..."

    install_scheduler || {
        error "Scheduler update failed."
        return 1
    }

    install_heartbeat_scheduler || {
        error "Heartbeat scheduler update failed."
        return 1
    }

    #####################################
    # Automatic Update Scheduler
    #####################################

    if [[ -r "$BASE_DIR/cache/wizard.env" ]]; then
        source "$BASE_DIR/cache/wizard.env"
    fi

    ENABLE_AUTO_UPDATE="${ENABLE_AUTO_UPDATE:-yes}"

    automatic_update_scheduler || {
        error "Automatic update scheduler failed."
        return 1
    }

    #####################################
    # Restart Services
    #####################################

    info "Restarting Services..."

    restart_services || {
        error "Service restart failed."
        return 1
    }

    success "SmartDNS features updated."

}
