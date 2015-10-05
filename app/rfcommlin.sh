#!/bin/bash
args=("$@")
# $@ is a special array used to store bash command line arguments
# you can access these args using this format: ${arg[x]} with zero indexing
echo "Setting up RFCOMM bind for" ${args[0]} "on *NIX host"
hciconfig hci0 up

devfind=$(grep -q $args[0]} <<< $(rfcomm))
if l2ping ${args[0]} -c 1; then
	rfport=$(grep -o 'rfcomm.' <<< $(rfcomm))
	if $devfind; then
		echo "Found device at" $rfport
		rfcomm release /dev/$rfport
		rfcomm bind /dev/$rfport ${args[0]} 1
		echo $(hcitool name ${args[0]}) "already bound!"
	else
		echo 1234 | bluez-simple-agent hci0 ${args[0]}
		rfcomm bind /dev/$rfport ${args[0]} 1
	fi
	rfcomm
else
	rfport="NULL"
	echo ${args[0]} "not found!"
fi
export rfport