#!/bin/bash
# Raspberry-Pi-OVPN-Server
printf "Setting up Raspberry Pi as an openVPN server!\n"

## Update the Server
sudo apt-get update
sudo apt-get upgrade

## Install the software needed to build and run the VPN server
sudo apt-get install openvpn easy-rsa

## Set the main working directory for our VPN setup
export CWD=$( dirname "$(readlink -f "$0")" )
export CFG_FILE="$CWD/vpn_config.yaml"
export CFG_FILE_DEFAULT="$CWD/vpn_config.default.yaml"

## Setup test directories structure
## Change next line to TESTDIR="" in the master branch
export TESTDIR=$CWD/test #"/etc/openvpn/easy-rsa"
export ETCDIR=$TESTDIR/etc
export ERDIR=$ETCDIR/openvpn/easy-rsa
export ORIGERDIR=/usr/share/easy-rsa

## Define files used
fwrules="firewall-openvpn-rules.sh"

## Create local copy of easy-rsa
mkdir -p $ERDIR/keys
sudo cp -r $ORIGERDIR $ETCDIR/openvpn
sudo chown -R $USER:$USER $ERDIR

## Edit the vars file - Use '@' as sed delimiter because we use / already
printf 'Editing the "vars" file - export EASY_RSA="/etc/openvpn/easy-rsa"...\n'
fnew=$ERDIR/vars
forig="$ORIGERDIR/vars"
lineold=$(cat $forig | grep "export EASY_RSA")
linenew="export EASY_RSA=$ERDIR"
sed -i -- "s@$lineold@$linenew@g" $fnew

## Build certificate authority
. $CWD/utils.sh
cd $ERDIR
. ./vars
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
printf "\nCopying server.conf to %s/openvpn\n" "$ETCDIR"
cp $CWD/server.conf $ETCDIR/openvpn
fpath=$ETCDIR/openvpn/server.conf
for key in SERVER_LOCAL_IP VPN_PORT SERVER_NAME KEY_SIZE LAN_IP GATEWAY_IP; do
    old="[$key]"
    new=$(read_from_yaml $CFG_FILE $key)
    sed -i -- "s/$old/$new/g" $fpath
done

## Enable ipv4 forwarding
printf "Uncommenting line to enable packet forwarding in /etc/sysctl.conf .\n"
newline="net.ipv4.ip_forward=1"
oldline="#$newline"
sed -i -- "s/$oldline/$newline/g" /etc/sysctl.conf
sysctl -p

## Update firewall rules file to your local settings and IPs etc
printf "Copying %s to %s .\n" "$fwrules" "$ETCDIR"
sudo cp $CWD/$fwrules $ETCDIR/$fwrules
for key in SERVER_LOCAL_IP IFACE_TYPE; do
    old="[$key]"
    new=$(read_from_yaml $CFG_FILE $key)
    sed -i -- "s/$old/$new/g" $ETCDIR/$fwrules
done

## Update your interface file
#- add line to interfaces file with a tab at the beginning
printf "Updating %s with %s\n" "$ETCDIR/network/interfaces" "$ETCDIR/$fwrules"
IFACE_TYPE=$(read_from_yaml $CFG_FILE "IFACE_TYPE")
oldline=$(cat "$ETCDIR/network/interfaces" | grep "iface $IFACE_TYPE inet ")
newline="$oldline\tpre-up $ETCDIR/$fwrules"
sudo sed -i -- "s@$oldline@$newline@g" "$ETCDIR/network/interfaces"


## Setup also the client files
## Download the default file and update settings
printf "Copying Default.txt to %s.\n
        You may want to set your DDNS name or public IP" "$ERDIR/keys"
cp $CWD/Default.txt $ERDIR/keys
fpath=$ERDIR/keys/Default.txt
for key in SERVER_PUBLIC_IP VPN_PORT; do
    old="[$key]"
    new=$(read_from_yaml $CFG_FILE $key)
    sed -i -- "s@$old@$new@g" $fpath
done

## Get the script to generate the client files
cp $CWD/makeOVPN.sh $ERDIR/keys

## Set permissions for the file
cd $ERDIR/keys
chmod 700 makeOVPN.sh

## Reboot the server
printf "\nVPN Server should be good to go now!\n"
