#!/bin/bash
# Raspberry-Pi-OVPN-Server
printf "Setting up Raspberry Pi as an openVPN server!\n"

netif="/etc/network/interfaces"
fwrul="/etc/firewall-openvpn-rules.sh"


## Update the Server
sudo -s
apt-get update
apt-get upgrade

## Install the software
apt-get install openvpn easy-rsa curl
mkdir $ERDIR
cp /usr/share/easy-rsa $ERDIR

## Edit the vars file
#- change line export EASY_RSA to
#*export EASY_RSA="/etc/openvpn/easy-rsa"*
fnew=$ERDIR/vars
forig=/usr/share/easy-rsa/vars
lineold=$(cat $forig | grep "export EASY_RSA")
linenew="export EASY_RSA=$ERDIR"
sed -i -- 's/lineold/linenew/g' $fnew

## Continue with regular procedure
cd $ERDIR
source ./vars
./clean-all
./build-ca

## Build key for your server, name your server here
#- when prompted common name must equal [server name]
#- challenge password must be left blank
./build-key-server $SERVER_NAME


## Build the key for your server, enter a vpn username
#- challenge password must be left blank
for CLIENT_NAME in "${CLIENT_NAMES[@]}"; do
    cd $ERDIR
    ./build-key-pass $CLIENT_NAME
    cd $ERDIR/keys
    openssl rsa -in $CLIENT_NAME.key -des3 -out $CLIENT_NAME.3des.key
done

cd $ERDIR
printf "Now you have to wait for a while (about 1 hour on a Raspberry Pi 1 Model B)..."
printf "Running Diffie-Hellman algorithm . . ."
./build-dh
printf "DH algorithm finished!\n"

# Generate static key for TLS auth
printf "Generating static key to avoid DDoS attacks..."
openvpn --genkey --secret keys/ta.key
printf "Done.\n"

## Get the server.conf file and update it to your local settings
#cd /etc/openvpn
printf "Copying server.conf to /etc/openvpn"
cp $DDIR/server.conf /etc/openvpn/

## Enable ipv4 forwarding
#- uncomment the line
#*net.ipv4.ip_forward=1*
printf "Uncommenting line to enable packet forwarding in /etc/sysctl.conf"
newline="net.ipv4.ip_forward=1"
oldline="#$newline"
sed -i -- 's/$oldline/$newline/g' /etc/sysctl.conf
#nano /etc/sysctl.conf
sysctl -p

## Get firewall rules file
#- update file to your local settings and IPs etc
#cd /etc
#wget https://github.com/bicklp/pi-vpnserver/blob/master/firewall-openvpn-rules.sh
printf "Copying firewall-openvpn-rules to /etc"
cp $DDIR/firewall-openvpn-rules.sh /etc/


## Update your interface file
#- add line to interfaces file with a tab at the beginning
printf "Updating $netif with firewall-openvpn-rules"
oldline=$(cat $netif | grep "iface $IFACE_TYPE inet ")
newline="$oldline\tpre-up $fwrul"
sed -i -- 's/$oldline/$newline/g' $netif

## Reboot the server
printf "Server should be set up now!"
printf "You still have to set up the client(s)"
printf "Now rebooting...\n"
reboot
