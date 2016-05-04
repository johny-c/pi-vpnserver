#!/usr/bin/env python3
import subprocess
import yaml

## YAML configuration file
VARS_FILE = 'vpn_config.yaml'

## Load saved values
with open(VARS_FILE, 'r') as f:
    cfg = yaml.load(f)

print("Here is your current configuration:\n")
for k in cfg:
    print("%s : %s" % (k,cfg[k]) )

proc = subprocess.Popen(['tail', '-500', 'mylogfile.log'], stdout=subprocess.PIPE)

for line in proc.stdout.readlines():
    print line.rstrip()
