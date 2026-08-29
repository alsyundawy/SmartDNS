#!/usr/bin/env bash

set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

#########################################
# Libraries
#########################################

source "$BASE_DIR/lib/colors.sh"
source "$BASE_DIR/lib/logger.sh"
source "$BASE_DIR/lib/system.sh"
source "$BASE_DIR/lib/version.sh"
source "$BASE_DIR/lib/telemetry.sh"

#########################################
# Engine
#########################################

source "$BASE_DIR/engine/service.sh"
source "$BASE_DIR/engine/blocklist.sh"
source "$BASE_DIR/engine/cron.sh"
source "$BASE_DIR/engine/state.sh"

#########################################
# Usage
#########################################

usage() {

    cat <<EOF2
Usage:
    $0 --patch
    $0 --help

Options:
    --patch    Update SmartDNS
EOF2

}

#########################################
# Check Git
#########################################

check_git() {

    if ! command -v git >/dev/null 2>&1; then
        error "Git is not installed."
        return 1
    fi

    if ! git -C "$BASE_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        error "SmartDNS directory is not a Git repository."
        return 1
    fi

}

#########################################
# Check Repository Update
#########################################

check_repository_update() {

    info "Checking Repository..."

    git -C "$BASE_DIR" fetch origin || {
        error "Failed to fetch repository."
        return 1
    }

    local CURRENT_COMMIT
    local REMOTE_COMMIT

    CURRENT_COMMIT=$(git -C "$BASE_DIR" rev-parse HEAD)
    REMOTE_COMMIT=$(git -C "$BASE_DIR" rev-parse origin/main)

    if [[ "$CURRENT_COMMIT" == "$REMOTE_COMMIT" ]]; then

        success "Repository already up to date."
        return 1

    fi

    info "Repository update available."
    info "Current : ${CURRENT_COMMIT}"
    info "Remote  : ${REMOTE_COMMIT}"

    return 0

}

#########################################
# Update Repository
#########################################

update_repository() {

    info "Updating Repository..."

    git -C "$BASE_DIR" reset --hard origin/main || {
        error "Failed to update repository."
        return 1
    }

    success "Repository updated."

}

#########################################
# Main
#########################################

case "${1:-}" in

    --patch)

        banner

        info "Checking root..."

        if [[ "$EUID" -ne 0 ]]; then
            error "This command must be run as root."
            exit 1
        fi

        check_git || exit 1

        #####################################
        # Check for repository changes
        #####################################

        if ! check_repository_update; then
            exit 0
        fi

        #####################################
        # Repository changed
        #####################################

        update_repository || exit 1

        #####################################
        # Reload functions from updated tree
        #####################################

        source "$BASE_DIR/engine/update.sh"
        source "$BASE_DIR/engine/service.sh"
        source "$BASE_DIR/engine/blocklist.sh"
        source "$BASE_DIR/engine/cron.sh"
        source "$BASE_DIR/engine/state.sh"

        #####################################
        # Update all features
        #####################################

        update_features || exit 1

        #####################################
        # Save State
        #####################################

        save_state SERVICE

        success "SmartDNS update completed."

        ;;

    --help)

        usage
        ;;

    *)

        usage
        exit 1
        ;;

esac
