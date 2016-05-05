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
printf '\nEditing the "vars" file - export EASY_RSA="/etc/openvpn/easy-rsa"...\n'
fnew=$ERDIR/vars
forig="$ORIGERDIR/vars"
lineold=$(cat $forig | grep "export EASY_RSA")
linenew="export EASY_RSA=$ERDIR"
sed -i -- "s@$lineold@$linenew@g" $fnew

## Build certificate authority
printf "\nNext is building a certificate authority!\n\n"
read -p "Press any key to start building the CA\n\n"
. $CWD/utils.sh
cd $ERDIR
. ./vars
./clean-all
./build-ca

## Build key for your server, name your server here
SERVER_NAME=$(read_from_yaml $CFG_FILE "SERVER_NAME")
printf "\nNow building the key server\n\n
        Common name must be the same as the server name (%s)\n
        Leave the challenge password blank.\n\n" $SERVER_NAME
read -p "Press any key to start building the Key Server\n\n"
./build-key-server $SERVER_NAME

# ## Build the client keys for your server, enter a vpn username
# CLIENT_NAMES=$(read_from_yaml $CFG_FILE "CLIENT_NAMES")
# printf "Now building the client keys. Leave the challenge password blank."
# for CLIENT_NAME in "${CLIENT_NAMES[@]}"; do
#     ./build-key-pass $CLIENT_NAME
#     openssl rsa -in keys/$CLIENT_NAME.key -des3 -out keys/$CLIENT_NAME.3des.key
# done

printf "\nNow you have to wait for a while (about 1 hour on a Raspberry Pi 1 Model B)...\n"
printf "Running Diffie-Hellman algorithm . . .\n"
./build-dh
printf "\nDH algorithm finished!\n\n"

## Generate static key for TLS auth
printf "\nGenerating static key to avoid DDoS attacks...\n\n"
openvpn --genkey --secret keys/ta.key
printf "Done.\n\n"

## Get the server.conf file and update it to your local settings
printf "\nCopying 'server.conf' \nfrom %s \nto '%s/openvpn'\n\n" "$CWD" "$ETCDIR"
cp $CWD/server.conf $ETCDIR/openvpn
fpath=$ETCDIR/openvpn/server.conf
for key in SERVER_LOCAL_IP VPN_PORT SERVER_NAME KEY_SIZE LAN_IP GATEWAY_IP; do
    old="[$key]"
    new=$(read_from_yaml $CFG_FILE $key)
    printf "\nNow replacing %s \nwith %s \nin %s\n" "$old" "$new" $fpath
    sed -i -- "s/$old/$new/g" $fpath
done

## Enable ipv4 forwarding
printf "\nUncommenting line to enable packet forwarding in /etc/sysctl.conf .\n"
fpath=/etc/sysctl.conf
new="net.ipv4.ip_forward=1"
old="#$new"
printf "\nNow replacing %s \nwith %s \nin %s\n" "$old" "$new" $fpath
sed -i -- "s/$old/$new/g" $fpath
sudo sysctl -p

## Update firewall rules file to your local settings and IPs etc
printf "\nCopying %s \nfrom %s \nto %s .\n\n" "$fwrules" "$CWD" "$ETCDIR"
sudo cp $CWD/$fwrules $ETCDIR/$fwrules
sudo chown $USER:$USER $ETCDIR/$fwrules
fpath=$ETCDIR/$fwrules
for key in SERVER_LOCAL_IP IFACE_TYPE; do
    old="[$key]"
    new=$(read_from_yaml $CFG_FILE $key)
    printf "\nNow replacing %s \nwith %s \nin %s\n" "$old" "$new" $fpath
    sed -i -- "s/$old/$new/g" $fpath
done

## Update your interface file
#- add line to interfaces file with a tab at the beginning
sudo mkdir -p $ETCDIR/network
if [ ! -e $ETCDIR/network/interfaces ]; then
    printf "\nNow Copying /etc/network/interfaces \nto %s/etc/network/interfaces\n" "$ETCDIR"
    sudo cp /etc/network/interfaces $ETCDIR/network/interfaces
    sudo chown $USER:$USER $ETCDIR/network/interfaces
fi
printf "\nUpdating %s \nwith %s\n\n" "$ETCDIR/network/interfaces" "$ETCDIR/$fwrules"
IFACE_TYPE=$(read_from_yaml $CFG_FILE "IFACE_TYPE")
old=$(cat "$ETCDIR/network/interfaces" | grep "iface $IFACE_TYPE inet ")
new="$old\tpre-up $ETCDIR/$fwrules"
printf "\nNow replacing %s \nwith %s \nin %s\n" "$old" "$new" $fpath
sudo sed -i -- "s@$old@$new@g" "$ETCDIR/network/interfaces"


## Setup also the client files
## Download the default file and update settings
printf "\nCopying 'Default.txt' \nfrom %s \nto %s .\n\n" "$CWD" "$ERDIR/keys"
sudo cp $CWD/Default.txt $ERDIR/keys

fpath=$ERDIR/keys/Default.txt
printf "You may want to reset your DDNS name or public IP in %s\n\n" "$fpath"
for key in SERVER_PUBLIC_IP VPN_PORT; do
    old="[$key]"
    new=$(read_from_yaml $CFG_FILE $key)
    sed -i -- "s@$old@$new@g" $fpath
done

## Get the script to generate the client files
printf "\nCopying 'makeOVPN.sh' \nfrom %s \nto %s .\n\n" "$CWD" "$ERDIR/keys"
sudo cp $CWD/makeOVPN.sh $ERDIR/keys

## Set permissions for the file
printf "\nChanging permissions for '%s/makeOVPN.sh'\n\n" "$ERDIR/keys"
cd $ERDIR/keys
sudo chmod 700 makeOVPN.sh

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
    print "Building key for client: %s\n\n" $client
    . /vars
    ./build-key-pass $client
    openssl rsa -in "$client.key" -des3 -out "$client.3des.key"
    ./keys/makeOVPN $client
done

printf "\nClients should be ready! You just have to reboot\n"
printf "After the rebooting, copy the [client].ovpn files to your client devices!\n"
