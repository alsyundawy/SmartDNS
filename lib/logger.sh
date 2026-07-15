#!/usr/bin/env bash

LOGFILE=/var/log/smartdns-installer.log

# shellcheck disable=SC2312
log(){

    echo "$(date '+%F %T') $1" >> "${LOGFILE}"

}

