#!/usr/bin/env bash
#
# CHANGELOG:
# - Released v1.0.1-shellcheck-optimizer with full ShellCheck compliance and strict bash standards.
# - Created update.sh for automated repository patching and blocklist/service updates.
# - Added git commit change detection and self-re-execution logic upon git pull updates.
# - Standardized variable expansion and added ShellCheck directives.
#

# shellcheck disable=SC1091
set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

####################################
# Libraries
####################################

# shellcheck source=lib/colors.sh
source "${BASE_DIR}/lib/colors.sh"
# shellcheck source=lib/logger.sh
source "${BASE_DIR}/lib/logger.sh"
# shellcheck source=lib/system.sh
source "${BASE_DIR}/lib/system.sh"
# shellcheck source=lib/validate.sh
source "${BASE_DIR}/lib/validate.sh"
# shellcheck source=lib/detect.sh
source "${BASE_DIR}/lib/detect.sh"
# shellcheck source=lib/version.sh
source "${BASE_DIR}/lib/version.sh"
# shellcheck source=lib/telemetry.sh
source "${BASE_DIR}/lib/telemetry.sh"

####################################
# Engine
####################################

# shellcheck source=engine/tuning.sh
source "${BASE_DIR}/engine/tuning.sh"
# shellcheck source=engine/template.sh
source "${BASE_DIR}/engine/template.sh"
# shellcheck source=engine/runtime.sh
source "${BASE_DIR}/engine/runtime.sh"
# shellcheck source=engine/render.sh
source "${BASE_DIR}/engine/render.sh"
# shellcheck source=engine/package.sh
source "${BASE_DIR}/engine/package.sh"
# shellcheck source=engine/service.sh
source "${BASE_DIR}/engine/service.sh"
# shellcheck source=engine/wizard.sh
source "${BASE_DIR}/engine/wizard.sh"
# shellcheck source=engine/acl.sh
source "${BASE_DIR}/engine/acl.sh"
# shellcheck source=engine/security.sh
source "${BASE_DIR}/engine/security.sh"
# shellcheck source=engine/state.sh
source "${BASE_DIR}/engine/state.sh"
# shellcheck source=engine/blocklist.sh
source "${BASE_DIR}/engine/blocklist.sh"
# shellcheck source=engine/secret.sh
source "${BASE_DIR}/engine/secret.sh"
# shellcheck source=engine/cron.sh
source "${BASE_DIR}/engine/cron.sh"
# shellcheck source=engine/swap.sh
source "${BASE_DIR}/engine/swap.sh"
# shellcheck source=engine/sysctl.sh
source "${BASE_DIR}/engine/sysctl.sh"

####################################
# Menu Options
####################################

usage() {
	cat <<EOF
Usage:
    $0 --patch
    $0 --help

Options:
    --patch    Update patch
EOF
}

case "${1:-}" in
	--patch)
		banner

		info "Update Repositories..."

		SCRIPT_PATH="${BASE_DIR}/update.sh"

		OLD_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "initial")

		git pull || exit 1

		NEW_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "initial")

		if [[ "${OLD_COMMIT}" != "${NEW_COMMIT}" ]]; then
			info "Repository updated. Restarting updater..."
			exec "${SCRIPT_PATH}" --patch
		fi

		install_blocklist || exit 1

		if [[ -r cache/wizard.env ]]; then
			# shellcheck disable=SC1091
			source cache/wizard.env
		fi

		ENABLE_AUTO_UPDATE="${ENABLE_AUTO_UPDATE:-yes}"

		info "Check Automatic Update..."
		automatic_update_scheduler || exit 1

		mkdir -p cache
		if grep -q '^ENABLE_AUTO_UPDATE=' cache/wizard.env 2>/dev/null; then
			sed -i "s/^ENABLE_AUTO_UPDATE=.*/ENABLE_AUTO_UPDATE=${ENABLE_AUTO_UPDATE}/" cache/wizard.env
		else
			echo "ENABLE_AUTO_UPDATE=${ENABLE_AUTO_UPDATE}" >> cache/wizard.env
		fi

		restart_services || exit 1
		save_state SERVICE
		;;
	--help)
		usage
		;;
	*)
		usage
		exit 1
		;;
esac
