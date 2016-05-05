#!/usr/bin/env python3
import subprocess
import yaml
import sys
import os

## Execute commands in the shell
def shell(cmd):
    proc = subprocess.call(cmd)
    #outs, errs = proc.communicate()

## Specify client names to make keys for
def set_names(clients):
    ## Read clients
    if len(clients) > 0:
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

    answer = ''
    while answer != 'y' and answer != 'n':
        answer = input("Do you want to add some client names now (y/n)? ")
    if answer == 'n':
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


## YAML configuration file path
CWD = os.getcwd()
CFG_FILE = os.path.join(CWD, 'vpn_config.yaml')

## Load saved configuration
with open(CFG_FILE, 'r') as f:
    cfg = yaml.load(f)

print("Here is your current configuration:\n")
for k in cfg:
    print("%s : %s" % (k,cfg[k]) )

clients = cfg['CLIENT_NAMES']
if len(clients) == 0:
    print("No client names given. Now exiting.")
    sys.exit(0)

## Enter into the right directory
print("Currently working directory is %s\n" % CWD)
EASY_RSA_DIR = os.path.join(CWD, 'test', 'etc', 'openvpn', 'easy-rsa')
KEYS_DIR = os.path.join(EASY_RSA_DIR, 'keys')
shell(['mkdir', '-p', KEYS_DIR])
os.chdir(EASY_RSA_DIR)

## Build the client keys for your server, enter a vpn username
print("Now building the client keys. Leave the challenge password blank.\n")
for CLIENT_NAME in cfg['CLIENT_NAMES']:
    shell(['./build-key-pass', str(CLIENT_NAME)])
    keypath = os.path.join(KEYS_DIR, str(CLIENT_NAME))
    shell(['openssl', 'rsa', '-in', keypath + '.key', '-des3', '-out', keypath + '.3des.key'])

## Enter into the right directory
os.chdir(KEYS_DIR)

## Run the file and enter your server / client details
print("Now creating the client ovpn files...\n")
for CLIENT_NAME in cfg['CLIENT_NAMES']:
    shell(['./makeOVPN.sh', str(CLIENT_NAME)])
    #./makeOVPN.sh CLIENT_NAME
