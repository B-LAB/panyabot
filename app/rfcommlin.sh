#!/bin/bash
args=("$@")
# $@ is a special array used to store bash command line arguments
# you can access these args using this format: ${arg[x]} with zero indexing
hcino=$(grep -o "hci." <<< $(hciconfig))
hcist=$(grep -o "down" <<< $(hciconfig))

# conditional to check that the hci device is not down
# -z is a bash empty variable check.
if [ -z "$hcist"]; then
	hciconfig $hcino up
fi

# conditional to determine if the reset flag has been set. if true, passed macid
# is flushed; if false, passed macid is paired to and bound to given rfcomm port.
if [ -z "${args[2]}" ]; then
	# restart systemd dbus and bluetooth services as a fail safe check
	service dbus restart
	service bluetooth restart
	# double check the hci device, probably could do with less checks, but just to
	# ensure reliable operation
	if [ -z "$hcist"]; then
		hciconfig $hcino up
	fi
	echo "Setting up RFCOMM bind for" ${args[0]} "on *NIX host"
	
	# bluetooth ping(ONCE) the passed macid variable to confirm it's up
	if l2ping ${args[0]} -c 1; then
		# devfind conditional checks if submitted UID is already registered on rfcomm,
		# if not it pairs to and binds the passed macid variable
		devfind=$(grep -o ${args[0]} <<< $(rfcomm))
		if [ -z "$devfind" ]; then
			# pair to the passed macid variable.
			# NOTE: Perhaps I should check linkkeys if device has already been
			# paired to?
			echo 1234 | bluez-simple-agent $hcino ${args[0]}
			# rfchck conditional checks if the passed macid variable has already been
			# bound. It releases and binds the passed macid if it has.
			rfchck=$(grep -o ${args[1]} <<< $(rfcomm))
			if [ -z "$rfchck" ]; then
				# bind the passed macid to the assigned rfcomm port on channel 1
				rfcomm bind "/dev/"${args[1]} ${args[0]} 1
			else
				rfcomm release "/dev/"${args[1]}
				rfcomm bind "/dev/"${args[1]} ${args[0]} 1
			fi
			echo "rfport:" ${args[1]}
		else
			# rfport searches for the bound rfcomm port number e.g. /dev/rfcomm(?)
			echo $(hcitool name ${args[0]}) "already bound"
			rfport=$(grep -o 'rfcomm.' <<< $(rfcomm))
			echo "rfport: /dev/"$rfport
		fi
		rfcomm
	else
		# bluetooth ping failed to find passed macid
		rfport="NULL"
		echo "rfport:" $rfport
		echo ${args[0]} "not found"
	fi
else
	# conditionals that ensure robust flushing if errors are found
	echo "Setting up RFCOMM release for" ${args[0]} "on *NIX host"
	rfchck=$(grep -o ${args[1]} <<< $(rfcomm))
	if [ -z "$rfchck" ]; then
		echo "Rfcomm port" ${args[1]} "not previously attached"
	else
		rfcomm release "/dev/"${args[1]}
		echo "Rfcomm port" ${args[1]} "released, rfcomm output:" $(rfcomm)
	fi
	hciuid=$(grep -o "..:..:..:..:..:.." <<< $(hciconfig))
	if [ -z "$hciuid" ]; then
		echo "no host bluetooth device found"
	else
		keychck=$(grep -o ${args[0]} <<< $(cat /var/lib/bluetooth/$hciuid/linkkeys))
		if [ -z "$keychck" ]; then
			echo ${args[0]} "not previously paired"
		else
			bluez-test-device remove ${args[0]}
			echo ${args[0]} "unpaired"
		fi
	fi
fi