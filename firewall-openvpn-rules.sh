#!/bin/sh

# e.g. iptables -t nat - UNG -s 10.8.0.0/24 -o eth0 -j N --to-source 192.168.1.20
 # Replace with interface type and local IP address of the VPN Server
iptables -t nat - UNG -s 10.8.0.0/24 -o [IFACE_TYPE] -j SNAT --to-source [SERVER_LOCAL_IP]
