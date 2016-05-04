#!/usr/bin/env python3
import subprocess
import yaml

## Execute commands in the shell
def shell(cmdlist):
    proc = subprocess.Popen(cmdlist, stdout=subprocess.PIPE)
    for line in proc.stdout.readlines():
        print line.rstrip()

## YAML configuration file path
VARS_FILE = 'vpn_config.yaml'

## Load saved configuration
with open(VARS_FILE, 'r') as f:
    cfg = yaml.load(f)

print("Here is your current configuration:\n")
for k in cfg:
    print("%s : %s" % (k,cfg[k]) )

## Build the client keys for your server, enter a vpn username
print("Now building the client keys. Leave the challenge password blank.")
for CLIENT_NAME in cfg['CLIENT_NAMES']:
    shell(['./build-key-pass', str(CLIENT_NAME)])
    shell(['openssl', 'rsa', '-in', 'keys/' + str(CLIENT_NAME) + '.key', '-des3', '-out', 'keys/' + str(CLIENT_NAME) + '.3des.key'])
    #./build-key-pass CLIENT_NAME
    #openssl rsa -in keys/CLIENT_NAME.key -des3 -out keys/CLIENT_NAME.3des.key

## Run the file and enter your server / client details
print("Now creating the client ovpn files...")
for CLIENT_NAME in cfg['CLIENT_NAMES']:
    shell(['./makeOVPN.sh', str(CLIENT_NAME)])
    #./makeOVPN.sh CLIENT_NAME
