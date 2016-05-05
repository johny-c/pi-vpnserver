#!/bin/bash
## This script guides the user through the overall procedure
## Raspberry-Pi-OVPN-Server
tutorial_URL="readwrite.com/2014/04/10/raspberry-pi-vpn-tutorial-server-secure-web-browsing/"
printf "This program follows the instructions from: %s.\n\n" "$tutorial_URL"

## First change your password
printf "It is highly recommended to change your pi's default password before doing anything else.\n"
ans='a'
while [ $ans != 'y' -a $ans != 'n' ]; do
    printf "Do you wish to change your password (y/n)?\n"
    read ans
done
if [ $ans == 'y' ]; then
    sudo passwd
fi

## Set the main working directory for our VPN setup
export DDIR=$( dirname "$(readlink -f "$0")" )
export ERDIR="$DDIR/test" #"/etc/openvpn/easy-rsa"
export CFG_FILE="$DDIR/vpn_config.yaml"
export CFG_FILE_DEFAULT="$DDIR/vpn_config.default.yaml"

## Create vpn_config.yaml if it does not exist and change permissions
printf "Initializing configuration file.\n"
if [ ! -e $CFG_FILE ]; then
    cp $CFG_FILE_DEFAULT $CFG_FILE
fi
chmod 600 $CFG_FILE_DEFAULT
chmod 600 $CFG_FILE
chmod 700 $DDIR/*.sh

## Install software to run this program
printf "\nFirst we need to install some software to make things easier.\n"
sudo apt-get install python3-pip python3-yaml
sudo apt-get install python-netifaces python3-netifaces
sudo apt-get install openvpn easy-rsa curl
sudo pip3 install netifaces --upgrade
sudo pip3 install requests --upgrade

## Setup configuration variables
printf "\nOk. Now we have to setup your configuration.\n"
python3 setupConfig.py

printf "Your configuration is set. Now setting up the vpn server...\n"
./setupVPNserver.sh

printf "Your VPN server is set. Now setting up the clients...\n"
python3 setupVPNclients.py

printf "Clients should be set up. You are done! Now rebooting...\n"
printf "After the reboot, copy the [client].ovpn files to the client devices!\n"
sleep 5
reboot
