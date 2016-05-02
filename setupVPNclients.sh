#!/bin/bash
## VPN Client(s) Setup

sudo -s
## Download the default file and update settings
#- Set the Public IP or DDNS name in the Default.txt file
cp $DDIR/Default.txt $ERDIR/keys
fpath=$ERDIR/keys/Default.txt
SERVER_PUBLIC_IP=$(read_from_yaml $CFG_FILE "SERVER_PUBLIC_IP")
VPN_PORT=$(read_from_yaml $CFG_FILE "VPN_PORT")
sed -i -- "s/[SERVER_PUBLIC_IP]/$SERVER_PUBLIC_IP/g" $fpath
sed -i -- "s/[VPN_PORT]/$VPN_PORT/g" $fpath


## Get the script to generate the client files
cp $DDIR/makeOVPN.sh $ERDIR/keys

## Set permissions for the file
cd $ERDIR/keys
chmod 700 makeOVPN.sh

. $DDIR/utils.sh
CLIENT_NAMES=$(read_from_yaml $CFG_FILE "CLIENT_NAMES")
## Run the file and enter your server / client details
for CLIENT_NAME in ${CLIENT_NAMES[@]}; do
    ./makeOVPN.sh ${CLIENT_NAME}
done
