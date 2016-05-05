#!/usr/bin/env python3
import subprocess
import yaml
import sys
import os

## Specify client names to make keys for
def setup_clients(clients):
    ## Read clients
    if len(currentClients) > 0:
        print("\nThese are your clients:")
        for client in clients:
            print("%s  " % client)

        answer = ''
        while answer != 'y' and answer != 'n':
            answer = input("\nDo you want to delete these clients (y/n)? ")
        if answer == 'y':
            clients = set()
    else:
        print("\nYou currently have no clients.")

    while a != 'y' and a != 'n':
        a = input("Do you want to add some client names now (y/n)? ")
    if a == 'n':
        return clients

    inputState = True
    while inputState:
        client = input("Pick a name for a new client or leave blank to stop adding clients.\n")
        if client == '':
            inputState = False
        else:
            clients.add(client)
            print("Added client %s\n" % client )

    return clients

## Execute commands in the shell
def shell(cmd):
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE)
    for line in proc.stdout.readlines():
        print line.rstrip()

## YAML configuration file path
CWD = os.getcwd()
CFG_FILE = os.path.join(CWD, 'vpn_config.yaml')

## Load saved configuration
with open(CFG_FILE, 'r') as f:
    cfg = yaml.load(f)

print("Here is your current configuration:\n")
for k in cfg:
    print("%s : %s" % (k,cfg[k]) )

clients = setup_clients(cfg['CLIENT_NAMES'])
if clients != cfg['CLIENT_NAMES']:
    cfg['CLIENT_NAMES'] = clients
    ## Save new Configuration to yaml file
    with open(CFG_FILE, 'w') as outfile:
        outfile.write( yaml.dump(cfg, default_flow_style=False) )

if len(clients) == 0:
    print("No client names given. Now exiting.")
    sys.exit(0)

## Enter into the right directory
print("Currently working directory is %s" % CWD)
EASY_RSA_DIR = CWD + 'test/etc/openvpn/easy-rsa'
shell(['mkdir', '-p', EASY_RSA_DIR])
shell(['cd', EASY_RSA_DIR])

## Build the client keys for your server, enter a vpn username
print("Now building the client keys. Leave the challenge password blank.")
for CLIENT_NAME in cfg['CLIENT_NAMES']:
    shell(['./build-key-pass', str(CLIENT_NAME)])
    shell(['openssl', 'rsa', '-in', 'keys/' + str(CLIENT_NAME) + '.key', '-des3', '-out', 'keys/' + str(CLIENT_NAME) + '.3des.key'])
    #./build-key-pass CLIENT_NAME
    #openssl rsa -in keys/CLIENT_NAME.key -des3 -out keys/CLIENT_NAME.3des.key

## Enter into the right directory
shell(['cd', EASY_RSA_DIR + '/keys'])

## Run the file and enter your server / client details
print("Now creating the client ovpn files...")
for CLIENT_NAME in cfg['CLIENT_NAMES']:
    shell(['./makeOVPN.sh', str(CLIENT_NAME)])
    #./makeOVPN.sh CLIENT_NAME
