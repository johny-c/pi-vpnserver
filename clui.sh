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
done
if [ $ans == 'y' ]; then
    sudo passwd
fi

# Set the main working directory for our VPN setup
export DDIR=$( dirname "$(readlink -f "$0")" )
export ERDIR="$DDIR/test" #"/etc/openvpn/easy-rsa"

## Source utility functions
source $DDIR/utils.sh

## Setup variables
ans='y'
while [ $ans == 'y' ]; do
    print_config

    ans='a'
    while [ $ans != 'y' -a $ans != 'n' ]; do
        printf "Do you wish to change your configuration? (y/n)\n"
        read ans
        printf "You typed %s\n" $ans
    done
done

print_config

printf "Your configuration is set. Now setting up the vpn server...\n"
./setupVPNserver.sh

printf "Your VPN server is set. Now setting up the clients...\n"
./setupVPNclients.sh

printf "You are done! Just copy the [client].ovpn files to the actual client devices!\n"
