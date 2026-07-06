#!/usr/bin/env bash

####################################
# Runtime Configuration
####################################

merge_runtime(){

    mkdir -p cache

    cat > cache/runtime.env <<EOF
####################################
# System
####################################

HOSTNAME=$HOSTNAME
OS=$OS
VERSION=$VERSION
KERNEL=$KERNEL
CPU_ARCH=$CPU_ARCH
CPU_MODEL=$CPU_MODEL
CPU_THREADS=$CPU_THREADS
RAM_MB=$RAM_MB

####################################
# Network
####################################

DEFAULT_IF=$DEFAULT_IF
SERVER_IPV4=$SERVER_IPV4
SERVER_IPV6=${SERVER_IPV6:-}
ONLINE=${ONLINE:-Unknown}

####################################
# Wizard
####################################

ENABLE_IPV6=$ENABLE_IPV6
ENABLE_DNSSEC=$ENABLE_DNSSEC
ENABLE_RATELIMIT=$ENABLE_RATELIMIT
ENABLE_QUERYLOG=$ENABLE_QUERYLOG

RECURSIVE_PORT=$RECURSIVE_PORT
FRONTEND_PORT=$FRONTEND_PORT

####################################
# Tuning
####################################

UNBOUND_THREADS=$UNBOUND_THREADS
RRSET_CACHE=$RRSET_CACHE
MSG_CACHE=$MSG_CACHE
SLABS=$SLABS
OUTGOING_RANGE=$OUTGOING_RANGE
NUM_QUERIES=$NUM_QUERIES
INFRA_CACHE=$INFRA_CACHE

DNSDIST_CACHE=$DNSDIST_CACHE
TCP_THREADS=$TCP_THREADS
TCP_QUEUE=$TCP_QUEUE
UDP_OUTSTANDING=$UDP_OUTSTANDING

IPV6_AVAILABLE=$IPV6_AVAILABLE

EOF

    success "Runtime cache generated."

}

