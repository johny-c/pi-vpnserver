#!/usr/bin/env bash

function read_input {
    question="$1"
    default="$2"
    q="$1 ($2)? "
    read -p "$q" ans

    if [ -n "$ans" ]; then
        printf '%s' "$ans"
    else
        printf '%s' "$default"
    fi
}

function print_config {
    ## Print setup
    printf "Done! This is your configuration:\n\n"
    printf "Network interface: %s\n" "$IFACE_TYPE"
    printf "Local IP:          %s\n" "$SERVER_LOCAL_IP"
    printf "Public IP:         %s\n" "$SERVER_PUBLIC_IP"
    printf "Gateway IP:        %s\n" "$GATEWAY_IP"
    printf "Local subnet IP:   %s\n" "$LAN_IP"
    printf "VPN port:          %s\n" "$VPN_PORT"
    printf "Key size:          %s\n" "$KEY_SIZE"
    printf "Server name:       %s\n" "$SERVER_NAME"
    printf "Client names:      "
    for i in "${CLIENT_NAMES[@]}"; do
        printf "%s  " "$i"
    done
    printf "\n\n"
}
