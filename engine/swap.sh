#!/usr/bin/env bash

install_swap(){

    if swapon --show | grep -q "/swapfile"; then
        success "Swap already enabled."
        return
    fi

    info "Configuring Swap..."

    MEM_GB=$(awk '/MemTotal/ {printf "%.0f",$2/1024/1024}' /proc/meminfo)

    if (( MEM_GB <= 2 )); then
        SWAP_SIZE=2G
    elif (( MEM_GB <= 4 )); then
        SWAP_SIZE=4G
    elif (( MEM_GB <= 8 )); then
        SWAP_SIZE=4G
    elif (( MEM_GB <= 16 )); then
        SWAP_SIZE=8G
    else
        SWAP_SIZE=8G
    fi

    fallocate -l "$SWAP_SIZE" /swapfile 2>/dev/null || \
    dd if=/dev/zero of=/swapfile bs=1M count=$(( ${SWAP_SIZE%G} * 1024 ))

    chmod 600 /swapfile
    mkswap /swapfile >/dev/null
    swapon /swapfile

    grep -q "/swapfile" /etc/fstab || \
    echo "/swapfile none swap sw 0 0" >> /etc/fstab

    sysctl -w vm.swappiness=10 >/dev/null
    grep -q "vm.swappiness" /etc/sysctl.conf || \
    echo "vm.swappiness=10" >> /etc/sysctl.conf

    success "Swap ${SWAP_SIZE} enabled."

}

