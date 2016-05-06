#!/bin/bash
# Raspberry-Pi-OVPN-Server
printf "Setting up Raspberry Pi as an openVPN server!\n\n"
U=$1
## Update the Server
apt-get update
apt-get upgrade

## Install the software needed to build and run the VPN server
apt-get install openvpn easy-rsa

## Set the main working directory for our VPN setup
CWD=$( dirname "$(readlink -f "$0")" )
CFG_FILE="$CWD/vpn_config.yaml"
CFG_FILE_DEFAULT="$CWD/vpn_config.default.yaml"

## Setup test directories structure
## Change next line to TESTDIR="" in the master branch
TESTDIR=$CWD/test
ETCDIR=$TESTDIR/etc
ERDIR=$ETCDIR/openvpn/easy-rsa
KEYS_DIR=$ERDIR/keys
ORIGERDIR=/usr/share/easy-rsa

## Define files used
fwrules="firewall-openvpn-rules.sh"

## Create local copy of easy-rsa
cp -r $ORIGERDIR $ETCDIR/openvpn
mkdir -p $KEYS_DIR # Make keys directory first
chown -R $U:$U $ERDIR # Then give user rights

## Edit the vars file - Use '@' as sed delimiter because we use / already
printf '\nEditing "vars" file...\n'
fpath=$ERDIR/vars
forig="$ORIGERDIR/vars"
old=$(cat $forig | grep "export EASY_RSA")
new=$(printf 'export EASY_RSA="%s"' "$ERDIR")
printf "\nNow replacing %s \nwith %s \nin %s\n" "$old" "$new" $fpath
sed -i -- "s@$old@$new@g" $fpath

## Source files
. $CWD/utils.sh
cd $ERDIR
. ./vars

## Build certificate authority
printf "\nNext is building a certificate authority!\n\n"
read -p "Press any key to start building the CA"
./clean-all
./build-ca

## Build key for your server, name your server here
SERVER_NAME=$(read_from_yaml $CFG_FILE "SERVER_NAME")
printf "\nNow building the key server\n\n
        Common name must be the same as the server name (%s)\n
        Leave the challenge password blank.\n\n" $SERVER_NAME
read -p "Press any key to start building the Key Server"
./build-key-server $SERVER_NAME

## Security
printf "\nNow you have to wait for a while (about 1 hour on a Raspberry Pi 1 Model B)...\n"
read -p "Press any key to start running the Diffie-Hellman algorithm"
printf "Running Diffie-Hellman algorithm . . .\n"
./build-dh
printf "\nDH algorithm finished!\n\n"

## Generate static key for TLS auth
printf "\nGenerating static key to avoid DDoS attacks...\n\n"
read -p "Press any key to Generate static key to avoid DDoS attacks"
openvpn --genkey --secret $KEYS_DIR/ta.key
printf "Done.\n\n"

## Get the server.conf file and update it to your local settings
printf "\nCopying 'server.conf' \nfrom %s \nto '%s/openvpn'\n\n" "$CWD" "$ETCDIR"
read -p "Press any key to copy"
cp $CWD/server.conf $ETCDIR/openvpn
fpath=$ETCDIR/openvpn/server.conf
for key in SERVER_LOCAL_IP VPN_PORT SERVER_NAME KEY_SIZE LAN_IP GATEWAY_IP; do
    old="<$key>"
    new=$(read_from_yaml $CFG_FILE $key)
    printf "\nNow replacing %s \nwith %s \nin %s\n" "$old" "$new" $fpath
    read -p "Press any key to replace"
    sed -i -- "s/$old/$new/g" $fpath
done

## Enable ipv4 forwarding
printf "\nUncommenting line to enable packet forwarding in /etc/sysctl.conf .\n"
read -p "Press any key..."
fpath=/etc/sysctl.conf
new="net.ipv4.ip_forward=1"
old="#$new"
printf "\nNow replacing %s \nwith %s \nin %s\n" "$old" "$new" $fpath
sed -i -- "s/$old/$new/g" $fpath

printf "\nNow configuring kernel parameters according to %s\n" $fpath
sysctl -p

## Update firewall rules file to your local settings and IPs etc
printf "\nCopying %s \nfrom %s \nto %s .\n\n" "$fwrules" "$CWD" "$ETCDIR"
read -p "Press any key..."

cp $CWD/$fwrules $ETCDIR/$fwrules
#chown $U:$U $ETCDIR/$fwrules
fpath=$ETCDIR/$fwrules
for key in SERVER_LOCAL_IP IFACE_TYPE; do
    old="<$key>"
    new=$(read_from_yaml $CFG_FILE $key)
    printf "\nNow replacing %s \nwith %s \nin %s\n" "$old" "$new" $fpath
    read -p "Press any key..."
    sed -i -- "s/$old/$new/g" $fpath
done

## Update your interface file
#- add line to interfaces file with a tab at the beginning
mkdir -p $ETCDIR/network
fpath="$ETCDIR/network/interfaces"
if [ ! -e "$fpath" ]; then
    printf "\nNow Copying /etc/network/interfaces \nto %s/etc/network/interfaces\n" "$ETCDIR"
    read -p "Press any key..."
    cp /etc/network/interfaces $fpath
    #chown $U:$U $fpath
fi

IFACE_TYPE=$(read_from_yaml $CFG_FILE "IFACE_TYPE")
old=$(cat "$fpath" | grep "iface $IFACE_TYPE inet ")

if [ -z "$old" ]; then
    printf "iface $IFACE_TYPE inet... does not exist!\n\n"
    new=$(printf "iface %s inet dhcp\n\tpre-up %s/%s" "$IFACE_TYPE" "$ETCDIR" "$fwrules")
    printf "Appending: \n%s \nto %s\n\n" "$new" "$fpath"
    read -p "Press any key..."
    echo "$new" >> $fpath
else
    new=$(printf "%s\n\tpre-up %s/%s" "$old" "$ETCDIR" "$fwrules")
    printf "\nNow replacing %s \nwith %s \nin %s\n" "$old" "$new" "$fpath"
    read -p "Press any key..."
    sed -i -- "s@$old@$new@g" "$fpath"
fi


## Setup also the client files
## Download the default file and update settings
printf "\nCopying 'Default.txt' \nfrom %s \nto %s .\n\n" "$CWD" "$KEYS_DIR"
read -p "Press any key..."

cp $CWD/Default.txt $KEYS_DIR

fpath=$KEYS_DIR/Default.txt
printf "You may want to reset your DDNS name or public IP in %s\n\n" "$fpath"
for key in SERVER_PUBLIC_IP VPN_PORT; do
    old="<$key>"
    new=$(read_from_yaml $CFG_FILE $key)
    printf "\nNow replacing %s \nwith %s \nin %s\n" "$old" "$new" "$fpath"
    read -p "Press any key..."
    sed -i -- "s@$old@$new@g" $fpath
done

## Get the script to generate the client files
printf "\nCopying 'makeOVPN.sh' \nfrom %s \nto %s .\n\n" "$CWD" "$KEYS_DIR"
read -p "Press any key..."

cp $CWD/makeOVPN.sh $KEYS_DIR

## Set permissions for the file
printf "\nChanging permissions for '%s/makeOVPN.sh'\n\n" "$KEYS_DIR"
cd $KEYS_DIR

chmod 700 makeOVPN.sh

## Reboot the server
printf "\nVPN Server should be good to go now!\n\n"
printf "###################################################################\n\n"
printf "\nNow setting up the clients.\n\n"

## Enter into the right directory
cd $ERDIR
CLIENT_NAMES=( $(pcregrep -M '^  .*\n' $CFG_FILE | cut -d : -f 1 ) )

## Build the client keys for your server, enter a vpn username
printf "Now building the client keys. Leave the challenge passwords blank.\n\n"
for client in ${CLIENT_NAMES[@]}; do
    printf "\nBuilding key for client: %s\n\n" "$client"
    read -p "Press any key..."
    cd $ERDIR
    . ./vars
    ./build-key-pass $client
    cd $KEYS_DIR
    openssl rsa -in "$client.key" -des3 -out "$client.3des.key"
    ./makeOVPN.sh $client
done

printf "\nClients should be ready! You just have to reboot\n"
printf "After the rebooting, copy the [client].ovpn from %s files to your client devices!\n" "$KEYS_DIR"
