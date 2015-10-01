#!/bin/bash
args=("$@")
# $@ is a special array used to store bash command line arguments
# you can access these args using this format: ${arg[x]} with zero indexing
echo "Setting up RFCOMM bind for" ${args[0]} "on *NIX host"
bluetoothctl << EOF
power on
discoverable on
agent on
default-agent
pairable on
scan on
pair ${args[0]}
scan off
quit
EOF