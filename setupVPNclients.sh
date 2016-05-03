#!/bin/bash
## VPN Client(s) Setup

sudo -s
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

. $DDIR/utils.sh
CLIENT_NAMES=$(read_from_yaml $CFG_FILE "CLIENT_NAMES")
## Run the file and enter your server / client details
for CLIENT_NAME in ${CLIENT_NAMES[@]}; do
    ./makeOVPN.sh ${CLIENT_NAME}
done
