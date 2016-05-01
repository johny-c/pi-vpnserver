#!/bin/bash
## VPN Client(s) Setup

## Download the default file and update settings
#- Set the Public IP or DDNS name in the Default.txt file
cp $DDIR/Default.txt $ERDIR/keys

## Get the script to generate the client files
cp $DDIR/makeOVPN.sh $ERDIR/keys

## Set permissions for the file
cd $ERDIR/keys
chmod 700 makeOVPN.sh

##run the file and enter your server / client details
for i in ${CLIENT_NAMES[@]}; do
    ./makeOVPN.sh ${i}
done
