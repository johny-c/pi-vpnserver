#!/bin/bash

# Network variables
export SERVER_LOCAL_IP="192.168.1.5"
export SERVER_PUBLIC_IP="123.456.789.123"
export LAN_IP="192.168.1.0"
export GATEWAY_IP="192.168.1.1"

# User variables
export KEY_SIZE=2048
export VPN_PORT=1194
export IFACE_TYPE="eth0" # set to wlan0 for wireless server
export SERVER_NAME="my_vpn_server"
export CLIENT_NAMES=("vpn_client1" "vpn_client2")
