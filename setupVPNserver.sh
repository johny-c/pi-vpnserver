#!/bin/bash
# Raspberry-Pi-OVPN-Server
printf "Setting up Raspberry Pi as an openVPN server!\n"

## Update the Server
sudo -s
apt-get update
apt-get upgrade
## Install the software to build and run the VPN server
apt-get install openvpn easy-rsa curl python3-yaml

## Set the main working directory for our VPN setup
export DDIR=$( dirname "$(readlink -f "$0")" )
export ERDIR="$DDIR/test" #"/etc/openvpn/easy-rsa"
export CFG_FILE="$DDIR/vpn_config.yaml"
export CFG_FILE_DEFAULT="$DDIR/vpn_config.default.yaml"

netif="/etc/network/interfaces"
fwrul="/etc/firewall-openvpn-rules.sh"
mkdir $ERDIR
cp /usr/share/easy-rsa $ERDIR

## Edit the vars file
printf 'Editing the "vars" file - export EASY_RSA="/etc/openvpn/easy-rsa"...\n'
fnew=$ERDIR/vars
forig="/usr/share/easy-rsa/vars"
lineold=$(cat $forig | grep "export EASY_RSA")
linenew="export EASY_RSA=$ERDIR"
sed -i -- "s/$lineold/$linenew/g" $fnew

## Build certificate authority
cd $ERDIR
source ./vars
./clean-all
./build-ca

## Build key for your server, name your server here
SERVER_NAME=$(read_from_yaml $CFG_FILE "SERVER_NAME")
printf "Now building the key.server\n
        Common name must be the same as the server name (%s)\n
        Leave the challenge password blank.\n" $SERVER_NAME
./build-key-server $SERVER_NAME

# ## Build the client keys for your server, enter a vpn username
# CLIENT_NAMES=$(read_from_yaml $CFG_FILE "CLIENT_NAMES")
# printf "Now building the client keys. Leave the challenge password blank."
# for CLIENT_NAME in "${CLIENT_NAMES[@]}"; do
#     ./build-key-pass $CLIENT_NAME
#     openssl rsa -in keys/$CLIENT_NAME.key -des3 -out keys/$CLIENT_NAME.3des.key
# done

printf "Now you have to wait for a while (about 1 hour on a Raspberry Pi 1 Model B)...\n"
printf "Running Diffie-Hellman algorithm . . .\n"
./build-dh
printf "\nDH algorithm finished!\n"

## Generate static key for TLS auth
printf "Generating static key to avoid DDoS attacks...\n"
openvpn --genkey --secret keys/ta.key
printf "Done.\n"

## Get the server.conf file and update it to your local settings
printf "Copying server.conf to /etc/openvpn\n"
cp $DDIR/server.conf /etc/openvpn/
fpath=/etc/openvpn/server.conf
for key in SERVER_LOCAL_IP VPN_PORT SERVER_NAME KEY_SIZE LAN_IP GATEWAY_IP; do
    val=$(read_from_yaml $CFG_FILE $key)
    sed -i -- "s/[$key]/$val/g" $fpath
done

## Enable ipv4 forwarding
printf "Uncommenting line to enable packet forwarding in /etc/sysctl.conf .\n"
newline="net.ipv4.ip_forward=1"
oldline="#$newline"
sed -i -- "s/$oldline/$newline/g" /etc/sysctl.conf
sysctl -p

## Update firewall rules file to your local settings and IPs etc
printf "Copying firewall-openvpn-rules to /etc .\n"
cp $DDIR/firewall-openvpn-rules.sh $fwrul
for key in SERVER_LOCAL_IP IFACE_TYPE; do
    val=$(read_from_yaml $CFG_FILE $key)
    sed -i -- "s/[$key]/$val/g" $fwrul
done

## Update your interface file
#- add line to interfaces file with a tab at the beginning
printf "Updating $netif with firewall-openvpn-rules"
IFACE_TYPE=$(read_from_yaml $CFG_FILE "IFACE_TYPE")
oldline=$(cat $netif | grep "iface $IFACE_TYPE inet ")
newline="$oldline\tpre-up $fwrul"
sed -i -- "s/$oldline/$newline/g" $netif


## Setup also the client files
## Download the default file and update settings
printf "Copying Default.txt to %s.\n
        You may want to set your DDNS name or public IP" "$ERDIR/keys"
cp $DDIR/Default.txt $ERDIR/keys
fpath=$ERDIR/keys/Default.txt
for key in SERVER_PUBLIC_IP VPN_PORT; do
    val=$(read_from_yaml $CFG_FILE $key)
    sed -i -- "s/[$key]/$val/g" $fpath
done

## Get the script to generate the client files
cp $DDIR/makeOVPN.sh $ERDIR/keys

## Set permissions for the file
cd $ERDIR/keys
chmod 700 makeOVPN.sh

## Reboot the server
printf "Server should be good to go now!\n"
