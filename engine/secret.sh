#!/usr/bin/env bash

####################################
# Generate Secret
####################################

generate_secret(){

    DNSDIST_KEY=$(openssl rand -base64 32)

    DNSDIST_API_KEY=$(openssl rand -hex 32)

	if [[ -z "${DNSDIST_WEB_PASSWORD:-}" ]]; then

		DNSDIST_WEB_PASSWORD=$(openssl rand -base64 18)

	fi

}
