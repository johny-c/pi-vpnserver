#!/bin/sh

# e.g. iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j SNAT --to-source 192.168.1.20
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $IFACE_TYPE -j SNAT --to-source $SERVER_LOCAL_IP #[Local IP of VPN Server]

