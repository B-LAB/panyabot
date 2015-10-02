#!/bin/bash
args=("$@")
# $@ is a special array used to store bash command line arguments
# you can access these args using this format: ${arg[x]} with zero indexing
echo "Setting up RFCOMM bind for" ${args[0]} "on *NIX host"
hcitool name ${args[0]}
rfcomm release ${args[0]}
echo 1234 | bluez-simple-agent hci0 ${args[0]}
rfcomm bind /dev/rfcomm0 ${args[0]} 1
rfcomm