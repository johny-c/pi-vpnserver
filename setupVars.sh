#!/bin/bash
## Configuration variables to automate the VPN setup

## Variables associative array
declare -A MY_VARS
MY_VARS=( [SERVER_LOCAL_IP]="192.168.1.2" [SERVER_PUBLIC_IP]="123.111.123.111"
          [LAN_IP]="192.168.1.0" [GATEWAY_IP]="192.168.1.1" [KEY_SIZE]=2048
          [VPN_PORT]=1194 [IFACE_TYPE]="eth0" [SERVER_NAME]="vpn_server")

## Load default values
. $DDIR/utils.sh
for key in ${!MY_VARS[@]}; do
    MY_VARS[$key]=$(read_from_yaml $CFG_FILE $key)
done


## Setup network variables
printf "Trying to figure out your network configuration . . .\n"
printf "Press enter to keep the default choice.\n"

# Set network interface
MY_VARS[IFACE_TYPE]=$( read_input "Use eth0 or wlan0 network interface" ${MY_VARS[IFACE_TYPE]} )

# Set server local ip
SERVER_LOCAL_IP=$(ip addr show $IFACE_TYPE | grep "inet" | grep -v "inet6" | awk '{print $2}' | cut -d '/' -f 1)
MY_VARS[SERVER_LOCAL_IP]=$( read_input "Local ip address" $SERVER_LOCAL_IP )

# Set server public ip
SERVER_PUBLIC_IP=$(curl -s https://api.ipify.org)
MY_VARS[SERVER_PUBLIC_IP]=$( read_input "Public ip address" $SERVER_PUBLIC_IP )

# Set gateway ip
GATEWAY_IP=$( netstat -nr | head -3 | tail -1 | awk '{print $2}' )
MY_VARS[GATEWAY_IP]=$( read_input "Gateway(router) ip address" $GATEWAY_IP )

# Set LAN ip
LAN_IP=$( netstat -nr | tail -1 | awk '{print $1}' )
MY_VARS[LAN_IP]=$( read_input "Local subnet ip address" $LAN_IP )

## Setup user variables
printf "\nA few more to go . . .\n"
printf "Press enter to keep the default choice.\n"

MY_VARS[VPN_PORT]=$( read_input "Pick a port allowing VPN connections on your server" ${MY_VARS[VPN_PORT]} )
MY_VARS[KEY_SIZE]=$( read_input "Choose authentication key size" ${MY_VARS[KEY_SIZE]} )
MY_VARS[SERVER_NAME]=$( read_input "Pick a name for your server" ${MY_VARS[SERVER_NAME]} )

## Read clients
STR=$(read_from_yaml $CFG_FILE "CLIENT_NAMES")
STR=$(trim $STR)         # Remove leading and trailing whitespace
STR="${STR:1:${#STR}-2}" # Remove first and last character
CLIENT_NAMES=(`echo $STR | sed -e 's/,/\n/g'`)
printf "\nThese are your clients:\n\n"
for c in "${CLIENT_NAMES[@]}"; do printf "%s  " $c; done
printf "\n\n"

new_client=1
i=0
while [ $new_client -gt 0 ]; do
    printf "Pick a name for a new client or leave blank to stop adding clients.\n" $(expr $i + 1)
    read CLIENT_NAME

    if [ -n "$CLIENT_NAME" ]; then
        CLIENT_NAMES+=("$CLIENT_NAME")
	    i=$(expr $i + 1)
        printf "Added client %s\n" $CLIENT_NAME
    else
        new_client=0
    fi
done

printf "\nThese are your clients:\n\n"
for c in "${CLIENT_NAMES[@]}"; do printf "%s  " $c; done
printf "\n\n"

## Save new Configuration to yaml file
for key in "${!MY_VARS[@]}"; do
    write_to_yaml $CFG_FILE $key ${MY_VARS[$key]}
done

cr=$( IFS=, ; echo "${CLIENT_NAMES[*]}" )
write_to_yaml $CFG_FILE "CLIENT_NAMES" $cr
