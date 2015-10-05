#!/bin/bash
args=("$@")
# $@ is a special array used to store bash command line arguments
# you can access these args using this format: ${arg[x]} with zero indexing
echo "Setting up RFCOMM bind for" ${args[0]} "on *NIX host"
hciconfig hci0 up

# check if submitted uid-attached host is up
if l2ping ${args[0]} -c 1; then
	# devfind checks if submitted UID is already registered on rfcomm
	devfind=$(grep -q ${args[0]} <<< $(rfcomm))
	if ($devfind); then
		# rfport searches for the attached /dev/rfcomm{x} device
		rfport=$(grep -o 'rfcomm.' <<< $(rfcomm))
		echo "rfport:" $rfport
		echo $(hcitool name ${args[0]}) "already bound"
	else
		echo 1234 | bluez-simple-agent hci0 ${args[0]}
		rfcomm bind /dev/rfcomm0 ${args[0]} 1
	fi
	rfcomm
else
	rfport="NULL"
	echo "rfport:"rfport
	echo ${args[0]} "not found"
fi