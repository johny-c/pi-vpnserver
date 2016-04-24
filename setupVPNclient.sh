#!/bin/sh
## VPN Client(s) Setup

## Download the default file and update settings
#- Set the Public IP or DDNS name in the Default.txt file
cp $DDIR/Default.txt $ERDIR/keys 

## Get the script to generate the client files
cp $DDIR/makeOVPN.sh $ERDIR/keys 

## Set permissions for the file
chmod 700 $ERDIR/makeOVPN.sh

##run the file and enter your server / client details
#- enter [vpn_username] when prompted
#- export the [vpn_username].ovpn file to clients

./makeOVPN.sh





