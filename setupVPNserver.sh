#!/bin/sh
# Raspberry-Pi-OVPN-Server
echo Setting up Raspberry Pi as an openVPN server!

## Update the Server
sudo -s
apt-get update
apt-get upgrade

## Install the software
apt-get install openvpn easy-rsa curl
mkdir /etc/openvpn/easy-rsa
cp /usr/share/easy-rsa /etc/openvpn/easy-rsa

## Edit the vars file
#- change line export EASY_RSA to
#*export EASY_RSA="/etc/openvpn/easy-rsa"*
$fnew=$ERDIR/vars
$forig=/usr/share/easy-rsa/vars 
$lineold=$(cat $forig | grep "export EASY_RSA")
$linenew="export EASY_RSA=$ERDIR"
sed -i -- 's/lineold/linenew/g' $fnew

## Continue with regular procedure
source ./vars
./clean-all
./build-ca

## Build key for your server, name your server here
#- when prompted common name must equal [server name]
#- challenge password must be left blank
./build-key-server $SERVER_NAME


## Build the key for your server, enter a vpn username
#- challenge password must be left blank
./build-key-pass $CLIENT_NAME
cd $ERDIR/keys
openssl rss -in ($CLIENT_NAME).key -des3 -out ($CLIENT_NAME).3des.key
cd $ERDIR
echo "Now you have to wait for a while (about 1 hour on a Raspberry Pi 1 Model B)..."
echo Running Diffie-Hellman algorithm
./build-dh
echo DH algorithm finished!

# Generate static key for TLS auth
echo Generating static key to avoid DDoS attacks...
openvpn --genkey --secret keys/ta.key
echo Done.

## Get the server.conf file and update it to your local settings
#cd /etc/openvpn
echo Copying server.conf to /etc/openvpn
cp $DDIR/server.conf /etc/openvpn/

## Enable ipv4 forwarding 
#- uncomment the line
#*net.ipv4.ip_forward=1*
echo Uncommenting line to enable packet forwarding in /etc/sysctl.conf
$newline="net.ipv4.ip_forward=1"
$oldline="#$newline"
sed -i -- 's/$oldline/$newline/g' /etc/sysctl.conf
#nano /etc/sysctl.conf
sysctl -p

## Get firewall rules file
#- update file to your local settings and IPs etc
#cd /etc
#wget https://github.com/bicklp/pi-vpnserver/blob/master/firewall-openvpn-rules.sh
echo Copying firewall-openvpn-rules to /etc
cp $DDIR/firewall-openvpn-rules.sh /etc/


## Update your interface file
#- add line to interfaces file with a tab at the beginning
echo Updating /etc/network/interfaces with firewall-openvpn-rules
$oldline=$(cat /etc/network/interfaces | grep "iface $IFACE_TYPE inet ")
$newline="$oldline\tpre-up /etc/firewall-openvpn-rules.sh"
sed -i -- 's/$oldline/$newline/g' /etc/networks/interfaces

## Reboot the server
echo Server should be set up now! 
echo "You still have to set up the client(s)"
echo Now rebooting...
echo ""
reboot
