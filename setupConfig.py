#!/usr/bin/python3
import yaml
import netifaces as nif
from requests import get
import sys
import setupVPNclients.py

## Get answer from user
def read_input(question="", default=""):
    answer = input(question + " (" + default + ") ? ")
    if answer == '':
        answer = default
    return answer


## YAML configuration file
CFG_FILE = 'vpn_config.yaml'

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
    print("Press enter to keep the default choice.\n")

    # Set network interface
    netifs = nif.interfaces()
    netif = ''
    while netif not in netifs:
        print("Available network interfaces: %s" % netifs )
        print("Saved network interface: %s" % cfg['IFACE_TYPE'] )
        netif = input("Choose your network interface: ")
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

    MY_VARS['VPN_PORT']= read_input( "Pick a port allowing VPN connections on your server", str(cfg['VPN_PORT']) )
    MY_VARS['KEY_SIZE']= read_input( "Choose authentication key size", str(cfg['KEY_SIZE']) )
    MY_VARS['SERVER_NAME']= read_input( "Pick a name for your server", cfg['SERVER_NAME'] )
    MY_VARS['CLIENT_NAMES'] = setup_clients(cfg['CLIENT_NAMES'])

    ## Save new Configuration to yaml file
    with open(CFG_FILE, 'w') as outfile:
        outfile.write( yaml.dump(MY_VARS, default_flow_style=False) )
