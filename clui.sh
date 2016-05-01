#!/bin/bash

## This script guides the user through the overall procedure

# Raspberry-Pi-OVPN-Server
tutorial_URL="readwrite.com/2014/04/10/raspberry-pi-vpn-tutorial-server-secure-web-browsing/"
printf "This program follows the instructions from: %s.\n\n" "$tutorial_URL"

# First change your password
printf "It is highly recommended to change your pi's default password before doing anything else.\n"
ans='a'
while [ $ans != 'y' -a $ans != 'n' ]; do
    printf "Do you wish to change your password (y/n)?\n"
    read ans
    printf "You typed %s\n" $ans
done
if [ $ans == 'y' ]; then
    sudo passwd
fi

## Setup variables
ans='y'
while [ $ans == 'y' ]; do
    ./setupVars.sh

    ## Print setup
    printf "This is your configuration:\n\n"
    printf "Network interface: %s" $IFACE_TYPE
    printf "Local IP:          %s" $SERVER_LOCAL_IP
    printf "Public IP:         %s" $SERVER_PUBLIC_IP
    printf "Gateway IP:        %s" $GATEWAY_IP
    printf "Local subnet IP:   %s" $LAN_IP
    printf "VPN port:          %s" $VPN_PORT
    printf "Key size:          %s" $KEY_SIZE
    printf "Server name:       %s" $SERVER_NAME
    printf "Client names:      %s" $CLIENT_NAMES
    ans='a'
    while [ $ans != 'y' && $ans != 'n' ]; do
        printf "Do you wish to change your configuration? (y/n)\n"
        read ans
        printf "You typed %s\n" $ans
    done
done

printf "Your configuration is set. Now setting up the vpn server...\n"
./setupVPNserver.sh

printf "Your VPN server is set. Now setting up the clients...\n"
./setupVPNclient.sh

printf "You are done! Just copy the [client].ovpn files to the actual clients!\n"
