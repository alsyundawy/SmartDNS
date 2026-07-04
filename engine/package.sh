#!/usr/bin/env bash

#########################################
# Package List
#########################################

PACKAGES=(
    unbound
    dnsdist
    dnsutils
    curl
    wget
    unzip
    jq
    ca-certificates
    freecdb
)

#########################################
# Check Package
#########################################

is_installed(){

    dpkg -s "$1" >/dev/null 2>&1

}

#########################################
# Repair Install Package
#########################################


repair_package_manager() {

    info "Checking package manager..."

    dpkg --configure -a >/dev/null 2>&1 || true

    apt-get -f install -y >/dev/null 2>&1 || true

    if ! apt-get update; then
        error "Package manager could not be repaired."
        return 1
    fi

    success "Package manager OK."

}

#########################################
# Wait Package Manager
#########################################

wait_package_manager(){

    info "Waiting for package manager..."

    local TIMEOUT=180
    local ELAPSED=0

    while fuser /var/lib/dpkg/lock >/dev/null 2>&1 \
       || fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 \
       || fuser /var/lib/apt/lists/lock >/dev/null 2>&1
    do

        sleep 2

        ELAPSED=$((ELAPSED+2))

        if (( ELAPSED >= TIMEOUT )); then

            error "Package manager is busy."

            return 1

        fi

    done

    success "Package manager ready."

}

#########################################
# Install Missing Package
#########################################

install_packages(){

    local MISSING_PACKAGES=()

    for PKG in "${PACKAGES[@]}"
    do

        if is_installed "$PKG"; then

            success "$PKG already installed"

        else

            warn "$PKG missing"

            MISSING_PACKAGES+=("$PKG")

        fi

    done

    if (( ${#MISSING_PACKAGES[@]} > 0 )); then

        info "Updating package repository..."

        apt-get update || return 1

		if ! apt-get -f install -y; then
			error "Package manager is not healthy."
			exit 1
		fi

        info "Installing missing packages..."

        apt-get install -y "${MISSING_PACKAGES[@]}" || return 1

        command -v unbound >/dev/null || {
            error "Unbound installation failed"
            return 1
        }

        command -v dnsdist >/dev/null || {
            error "dnsdist installation failed"
            return 1
        }

        success "All required packages installed."

    else

        success "All required packages already installed."

    fi

}

####################################
# Verify Packages
####################################

verify_packages() {

    info "Verifying installed packages..."

    local FAILED=0

    command -v unbound >/dev/null 2>&1 || {
        warn "unbound missing"
        FAILED=1
    }

    command -v dnsdist >/dev/null 2>&1 || {
        warn "dnsdist missing"
        FAILED=1
    }

    command -v dig >/dev/null 2>&1 || {
        warn "dnsutils missing"
        FAILED=1
    }

    command -v curl >/dev/null 2>&1 || {
        warn "curl missing"
        FAILED=1
    }

    command -v wget >/dev/null 2>&1 || {
        warn "wget missing"
        FAILED=1
    }

    command -v unzip >/dev/null 2>&1 || {
        warn "unzip missing"
        FAILED=1
    }

    command -v jq >/dev/null 2>&1 || {
        warn "jq missing"
        FAILED=1
    }

    command -v cdb >/dev/null 2>&1 || {
        warn "freecdb missing"
        FAILED=1
    }

    if (( FAILED )); then
        error "Required packages are missing."
        return 1
    fi

    success "All required packages installed."

}
