#!/usr/bin/env bash
#
# CHANGELOG:
# - Standardized variable expansion by consistently using ${VAR} across all shell
#   scripts to improve readability, consistency, and safety.
# - Fixed ShellCheck warnings and added appropriate directives.
# - Integrated SmartDNS Management UI update caller with fallback and error handling.
#

# shellcheck disable=SC1091

#########################################
# SmartDNS Feature Updater
#########################################

update_features() {

	info "Updating SmartDNS features..."

	#####################################
	# Telemetry Heartbeat
	#####################################

	if [[ -f "${BASE_DIR}/scripts/smartdns-heartbeat" ]]; then

		install -m 755 \
			"${BASE_DIR}/scripts/smartdns-heartbeat" \
			/usr/local/bin/smartdns-heartbeat

		success "Telemetry heartbeat updated."

	else

		warning "Telemetry heartbeat script not found."

	fi

	#####################################
	# Telemetry UUID Migration
	#####################################

	if [[ -f "${BASE_DIR}/lib/telemetry.sh" ]]; then

		info "Migrating Telemetry UUID..."
		# shellcheck source=lib/telemetry.sh
		source "${BASE_DIR}/lib/telemetry.sh"

		if generate_uuid && update_install_uuid; then
			success "Telemetry UUID synchronized."
		else
			warning "Telemetry UUID migration skipped."
		fi

	fi

	#####################################
	# Blocklist
	#####################################

	if [[ -f "${BASE_DIR}/engine/blocklist.sh" ]]; then

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

	if [[ -r "${BASE_DIR}/cache/wizard.env" ]]; then
		# shellcheck source=/dev/null
		source "${BASE_DIR}/cache/wizard.env"
	fi

	ENABLE_AUTO_UPDATE="${ENABLE_AUTO_UPDATE:-yes}"

	automatic_update_scheduler || {
		error "Automatic update scheduler failed."
		return 1
	}

	#####################################
	# SmartDNS Management UI
	#####################################

	local ui_installer="${BASE_DIR}/ui/install-local.sh"

	if [[ -f "${ui_installer}" ]]; then

		info "Installing/updating SmartDNS Management UI..."

		if bash "${ui_installer}"; then
			success "SmartDNS Management UI updated."
		else
			warning "SmartDNS UI update failed; continuing core update."
		fi

	else

		warning "SmartDNS UI installer not found; skipping."

	fi

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
