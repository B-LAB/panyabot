#!/bin/bash
args=("$@")
# $@ is a special array used to store bash command line arguments
# you can access these args using this format: ${arg[x]} with zero indexing
service dbus restart
service bluetooth restart
hcino=$(grep -o "hci." <<< $(hciconfig))
hcist=$(grep -o "down" <<< $(hciconfig))
if [ -z "$hcist"]; then
	hciconfig $hcino up
fi
rfchck=$(grep -o ${args[1]} <<< $(rfcomm))

if [ -z "${args[2]}" ]; then
	echo "Setting up RFCOMM bind for" ${args[0]} "on *NIX host"
	# check if submitted uid-attached host is up
	if l2ping ${args[0]} -c 1; then
		# devfind checks if submitted UID is already registered on rfcomm
		devfind=$(grep -o ${args[0]} <<< $(rfcomm))
		if [ -z "$devfind" ]; then
			echo 1234 | bluez-simple-agent $hcino ${args[0]}
			if [ -z "$rfchck" ]; then
				rfcomm bind "/dev/"${args[1]} ${args[0]} 1
			else
				rfcomm release "/dev/"${args[1]}
				rfcomm bind "/dev/"${args[1]} ${args[0]} 1
			fi
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
	if [ -z "$rfchck" ]; then
		echo "Rfcomm port" ${args[1]} "not previously attached"
	else
		echo "Rfcomm port" ${args[1]} "released, rfcomm output:" $(rfcomm)
		rfcomm release "/dev/"${args[1]}
	fi
	bluez-test-device remove ${args[0]}
	
fi