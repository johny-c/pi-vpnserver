#!/bin/bash
## Configuration variables to automate the VPN setup

# Set the main working directory for our VPN setup
export DDIR=$( dirname "$(readlink -f "$0")" )
export ERDIR="/etc/openvpn/easy-rsa"

## Set some default values

# Network variables
SERVER_LOCAL_IP="192.168.1.5"
SERVER_PUBLIC_IP="123.456.789.123"
LAN_IP="192.168.1.0"
GATEWAY_IP="192.168.1.1"

# User variables
KEY_SIZE=2048
VPN_PORT=1194
IFACE_TYPE="eth0" # set to wlan0 for wireless server
SERVER_NAME="my_vpn_server"
CLIENT_NAMES=("vpn_client1" "vpn_client2")

# Utility function
read_input(){
    question="$1"
    default="$2"
    q="$1 ($2)? "
    read -rp "$q" ans
    if [ -n "$ans" ]; then
        printf "%s" "$ans"
    else
        printf "%s" "$default"
    fi
}


## Setup network variables
printf "Trying to figure out your network configuration . . ."
printf "Press enter to keep the default choice.\n"

# Set network interface
IFACE_TYPE=$( read_input "Use eth0 or wlan0 network interface" $IFACE_TYPE )

# Set server local ip
SERVER_LOCAL_IP=$(ip addr show $IFACE_TYPE | grep "inet" | grep -v "inet6" | awk '{print
$2}' | cut -d '/' -f 1)
SERVER_LOCAL_IP=$( read_input "Local ip address" $SERVER_LOCAL_IP )

# Set server public ip
SERVER_PUBLIC_IP=$(curl -s https://api.ipify.org)
SERVER_PUBLIC_IP=$( read_input "Public ip address" $SERVER_PUBLIC_IP )

# Set gateway ip
GATEWAY_IP=$( netstat -nr | head -3 | tail -1 | awk '{print $2}' )
GATEWAY_IP=$( read_input "Gateway(router) ip address" $GATEWAY_IP )

# Set LAN ip
LAN_IP=$( netstat -nr | tail -1 | awk '{print $1}' )
LAN_IP=$( read_input "Local subnet ip address" $LAN_IP )

## Setup user variables
printf "\nA few more to go . . ."
printf "Press enter to keep the default choice.\n"

VPN_PORT=$( read_input "Pick a port allowing VPN connections on your server" $VPN_PORT )
KEY_SIZE=$( read_input "Choose authentication key size" $KEY_SIZE )
SERVER_NAME=$( read_input "Pick a name for your server" $SERVER_NAME )

new_client=1
i=0
while [ test $new_client -gt 0 ]; do
    printf "Pick a name for your client no %d or leave blank to stop adding clients." $i+1
    read CLIENT_NAME

    if [ -n $CLIENT_NAME ]; then
        CLIENT_NAMES+=("$CLIENT_NAME")
    else
        new_client=0
    fi
done


## Make variables available to subprocesses
export IFACE_TYPE=$IFACE_TYPE
export SERVER_LOCAL_IP=$SERVER_LOCAL_IP
export SERVER_PUBLIC_IP=$SERVER_PUBLIC_IP
export GATEWAY_IP=$GATEWAY_IP
export LAN_IP=$LAN_IP
export VPN_PORT=$VPN_PORT
export KEY_SIZE=$KEY_SIZE
export SERVER_NAME=$SERVER_NAME
export CLIENT_NAMES=$CLIENT_NAMES

## Print setup
printf "Done!"
