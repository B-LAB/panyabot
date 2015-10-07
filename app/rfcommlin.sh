#!/bin/bash
args=("$@")
# $@ is a special array used to store bash command line arguments
# you can access these args using this format: ${arg[x]} with zero indexing
hcino=$(grep -o "hci." <<< $(hciconfig))
hciconfig $hcino up
currdev=$(echo "dev_"${args[0]} | tr : _)
bdevpath="/org/bluez/283/"$hcino"/"$currdev

if [ -z "${args[2]}" ]; then
	echo "Setting up RFCOMM bind for" ${args[0]} "on *NIX host"
	# check if submitted uid-attached host is up
	if l2ping ${args[0]} -c 1; then
		# devfind checks if submitted UID is already registered on rfcomm
		devfind=$(grep -o ${args[0]} <<< $(rfcomm))
		if [ -z "$devfind" ]; then
			echo 1234 | bluez-simple-agent $hcino ${args[0]}
			rfcomm release ${args[1]}
			rfcomm bind ${args[1]} ${args[0]} 1
			echo "rfport:" ${args[1]}
		else
			# rfport searches for the attached /dev/rfcomm{x} device
			echo $(hcitool name ${args[0]}) "already bound"
			rfport=$(grep -o 'rfcomm.' <<< $(rfcomm))
			echo "rfport: /dev/"$rfport
		fi
		rfcomm
	else
		rfport="NULL"
		echo "rfport:" $rfport
		echo ${args[0]} "not found"
	fi
else
	echo "Setting up RFCOMM release for" ${args[0]} "on *NIX host"
	rfcomm release ${args[1]}
	bluez-simple-agent $hcino ${args[0]} remove
	echo "Rfcomm port" ${args[1]} ",rfcomm output:" $(rfcomm)
fi