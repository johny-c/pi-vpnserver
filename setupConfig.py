#!/usr/bin/python3
import sys
import os
import yaml
import netifaces as nif
from requests import get

## Get answer from user
def read_input(question="", default=""):
    answer = input(question + " (" + default + ") ? ")
    if answer == '':
        answer = default
    return answer

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

if __name__ == '__main__':
    ## YAML configuration file
    CWD = os.getcwd()
    CFG_FILE = os.path.join(CWD, 'vpn_config.yaml')

    editState = True
    while editState:
        ## Load saved values
        with open(CFG_FILE, 'r') as f:
            cfg = yaml.load(f)

        print("Here is your current configuration:\n")
        for k in cfg:
            print("%s : %s" % (k,cfg[k]) )

        answer = ''
        while answer != 'y' and answer != 'n':
            answer = input("\nDo you want to change your configuration (y/n)? ")

        if answer == 'n':
            print("Configuration did not change. Now exiting.")
            sys.exit(0)

        ## Variables dictionary
        MY_VARS = {}

        ## Setup network variables
        print("Press enter to keep the default choice (in parentheses).\n")

        # Set network interface
        netifs = nif.interfaces()
        netif = ''
        while netif not in netifs:
            print("Available network interfaces: %s" % netifs )
            netif = read_input("Choose your network interface",  cfg['IFACE_TYPE'] )
        MY_VARS['IFACE_TYPE'] = netif

        # Set server local ip
        #SERVER_LOCAL_IP=$(ip addr show $IFACE_TYPE | grep "inet" | grep -v "inet6" | awk '{print $2}' | cut -d '/' -f 1)
        SERVER_LOCAL_IP = nif.ifaddresses(MY_VARS['IFACE_TYPE'])[nif.AF_INET][0]['addr']
        MY_VARS['SERVER_LOCAL_IP']=read_input("Local ip address", SERVER_LOCAL_IP )

        # Set server public ip
        #SERVER_PUBLIC_IP=$(curl -s https://api.ipify.org)
        SERVER_PUBLIC_IP = get('https://api.ipify.org').text
        MY_VARS['SERVER_PUBLIC_IP'] = read_input("Public ip address", SERVER_PUBLIC_IP )

        # Set gateway ip
        #GATEWAY_IP=$( netstat -nr | head -3 | tail -1 | awk '{print $2}' )
        GATEWAY_IP = nif.gateways()['default'][nif.AF_INET][0]
        MY_VARS['GATEWAY_IP'] = read_input("Gateway(router) ip address", GATEWAY_IP )

        # Set LAN ip
        #LAN_IP=$( netstat -nr | tail -1 | awk '{print $1}' )
        LAN_IP = MY_VARS['GATEWAY_IP']
        LAN_IP_PARTS = LAN_IP.split('.')
        LAN_IP_PARTS[-1] = '0'
        LAN_IP = '.'.join(LAN_IP_PARTS)
        MY_VARS['LAN_IP'] = read_input("Local subnet ip address" , LAN_IP )

        ## Setup user variables
        print("\nA few more to go . . .")
        print("Press enter to keep the default choice.\n")

        MY_VARS['VPN_PORT']= int( read_input( "Pick a port allowing VPN connections on your server", str(cfg['VPN_PORT']) ) )
        MY_VARS['KEY_SIZE']= int( read_input( "Choose authentication key size", str(cfg['KEY_SIZE']) ) )
        MY_VARS['SERVER_NAME']= read_input( "Pick a name for your server", cfg['SERVER_NAME'] )
        MY_VARS['CLIENT_NAMES'] = set_names(cfg['CLIENT_NAMES'])

        ## Save new Configuration to yaml file
        with open(CFG_FILE, 'w') as outfile:
            outfile.write( yaml.dump(MY_VARS, default_flow_style=False) )
