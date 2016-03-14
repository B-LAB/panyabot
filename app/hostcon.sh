#!/bin/bash
# Major revision of host-slave connection on *nix/x86 platforms
# Based on positional parameters (http://linuxcommand.org/wss0130.php)

interactive=
primehci=
flash=
reinstall=
host="linux"
error=()

# all command options in CAPS deal with hci devices and shouldn't need to be
# passed except in hci error cases.
while [ "$1" != "" ]; do
	case $1 in
		-h | --host )			shift
								host=$1
								;;
		-u | --uid )			shift
								uid=$1
								;;
		-d | --dev )			shift
								devassgn=$1
								;;
		-s | --sketchpath )		shift
								skpath=$1
								;;
		-c | --currentuser )	shift
								cuser=$1
								;;
		-e | --errorkey )		shift
								errorkey=$1
								;;
		-r | --reinstall )		reinstall="reinstall"
								;;
		-f | --flush )			flush="flush"
								;;
		-i | --interactive )	interactive="interactive"
								;;
		-p | --pairbind )		pairbind="pairbind"
								;;
		-P | --primehci )		primehci="primehci"
								;;
		-S | --switch  )		switch="switch"
								;;
		-A | --allup )			allup="allup"
								;;

	esac
	shift
done

# the following conditionals are specific to the interactive
# hostcon prompt call
if [ "$interactive" = "1" ]; then
	echo -n "Enter host platform [$host] > "
	read response
	if [ -n "$response" ]; then
		host=$response
	fi

	echo -n "Enter robot uid > "
	read response
	if [ -n "$response" ]; then
		uid=$response
	fi

	echo -n "Enter dev device assignment > "
	read response
	if [ -n "$response" ]; then
		devassgn=$response
	fi

	echo -n "Enter sketch filepath > "
	read response
	if [ -n "$response" ]; then
		skpath=$response
	fi

	echo -n "Would you like to pair and bind host to client? (y/n) >"
	read response
	if [ "$response" = "y" ]; then
		pairbind="pairbind"
		echo -n "Will pair and bind $host to $uid at $devassgn."
		echo ""
	fi

	echo -n "Would you like to reinstall $uid firmware? (y/n) >"
	read response
	if [ "$response" = "y" ]; then
		reinstall="reinstall"
		echo -n "Will upload default firmware to $uid."
		echo ""
	fi

	echo -n "Would you like to flush device? (y/n) >"
	read response
	if [ "$response" = "y" ]; then
		flush="flush"
		echo -n "Will flush $uid from $devassgn."
		echo ""
	fi

	echo -n "Would you like to prime a HCI device? (y/n) >"
	read response
	if [ "$response" = "y" ]; then
		primehci="primehci"
		echo -n "Will prime a HCI device."
		echo ""
	fi

	echo -n "Would you like to switch out current HCI device? (y/n) >"
	read response
	if [ "$response" = "y" ]; then
		switch="switch"
		echo -n "Will switch out current HCI device."
		echo ""
	fi

	echo "DEBUG-only feature!"
	echo -n "Would you like to pull up ALL HCI devices? (y/n) >"
	read response
	if [ "$response" = "y" ]; then
		allup="allup"
		echo -n "Will pull up all HCI devices."
		echo ""
	fi
fi

echo "host=$host:uid=$uid"
echo "flush=$flush:dev=$devassgn"
echo "reinstall=$reinstall:skpath=$skpath"
echo "interactive=$interactive"
echo "primehci=$primehci:switch=$switch:allup=$allup"

function optexecute {
	echo "starting prompted execution scripts"
	while [ "$1" != "" ]; do
		case $1 in
			"linux" ) linuxscripts $reinstall $flush $primehci $pairbind $switch $allup;;
			"windows" ) windowsscripts $reinstall $flush $primehci $pairbind $switch $allup;;
			"darwin" ) darwinscripts $reinstall $flush $primehci $pairbind $switch $allup;;
		esac
		shift
	done
	echo "checking for any runtime errors"
	errorcatch
}

function linuxhciallup {
	# pull all available interfaces up.

	echo "pulling up all HCI devices"
	hcicnfvar=($(hciconfig | grep -o "hci."))
	hcitlvar=$(hcitool dev | while read line; do echo "${line#Devices:}"; done)
	hcitllist=($(echo "${hcitlvar#$'\n'}"))
	# http://bash.cyberciti.biz/guide/Perform_arithmetic_operations
	hcitltotal=$((${#hcitllist[@]}/2))

	tl=$(echo "$hcitltotal")
	cn=$(echo "${#hcicnfvar[@]}")

	# first check if the number of UP HCIs are less than available HCIs.
	if [ "$tl" -lt "$cn" ] && [ "$tl" -ne 0 ] && [ "$cn" -ne 0 ]; then
		# determine the number of available HCIs that aren't up.
		hcinumdiff=$((${#hcicnfvar[@]}-$hcitltotal))
		echo "$hcinumdiff local host device(s) is/are down"
		# for each HCI device that's up compare it to the list of HCI devices
		# that are available, if an available HCI device doesn't match then
		# pull it up.
		for (( h=0; h<"$tl"; h++ )); do
			if [ "$(($h%2))" = 0 ]; then
				for (( n=0; n<"$cn"; n++ )); do
					if [ "${hcitllist[$h]}" != "${hcicnfvar[$n]}" ]; then
						hciconfig -a "${hcicnfvar[$n]}" reset
						exstat=$?
						if [ "$exstat" = "0" ]; then 
							echo "${hcicnfvar[$n]} reset on host"
							hcitlvar=$(hcitool dev | while read line; do echo "${line#Devices:}"; done)
							hcitllist=($(echo "${hcitlvar#$'\n'}"))
							hcitltotal=$((${#hcitllist[@]}/2))
							# global error variable used to determine internal
							# states of bash functions. It is looped over when
							# the bash subprocess call is complete.
						else
							# hciconfig reset failed
							error+=(1)
						fi
					fi
				done
			fi
		done
	elif [ "$tl" -eq 0 ] && [ "$cn" -gt 0 ]; then
		for (( n=0; n<"$cn"; n++)); do
			hciconfig -a "${hcicnfvar[$n]}" reset
			exstat=$?
			if [ "$exstat" = "0" ]; then 
				echo "${hcicnfvar[$n]} reset on host"
				hcitlvar=$(hcitool dev | while read line; do echo "${line#Devices:}"; done)
				hcitllist=($(echo "${hcitlvar#$'\n'}"))
				hcitltotal=$((${#hcitllist[@]}/2))
				# global error variable used to determine internal
				# states of bash functions. It is looped over when
				# the bash subprocess call is complete.
			else
				# hciconfig reset failed
				error+=(2)
			fi
		done
	else
		# no HCI interfaces available
		error+=(29)
	fi
	if [ "$cn" -ne 0 ]; then
		if [ "$tl" -eq "$cn" ]; then
			echo "all interfaces are already up"
		fi
	else
		# no host HCI interfaces available, no critical error
		error+=(3)
	fi

	# if [ "$error" = 1 ]; then exit 1; fi
}

function linuxhciswitch {
	# iteratively switch to any alternative HCI interface on each call.

	echo "Switching over host HCI devices"
	hcicnfvar=($(hciconfig | grep -o "hci."))
	hcitlvar=$(hcitool dev | while read line; do echo "${line#Devices:}"; done)
	hcitllist=($(echo "${hcitlvar#$'\n'}"))
	hcitltotal=$((${#hcitllist[@]}/2))

	# these variables shouldn't be required. initially done because integer and 
	# string comparisons are different in bash.
	tl=$(echo "$hcitltotal")
	cn=$(echo "${#hcicnfvar[@]}")

	# check if there are multiple HCI interfaces to switch over. Otherwise exit.
	if [ "$cn" -gt 1 ]; then
		# ensure there's only one HCI interface up. Otherwise run linuxhciprimer.
		if [ "$tl" -eq 1 ]; then
			hcinumdiff=$(($cn-$tl))
			echo "current bluetooth host set to ${hcitllist[1]}"
			echo "$hcinumdiff local host device(s) can be switched over"
			# currpathnum stores the digit value of the running HCI interface.
			currpathnum=$(echo "${hcitllist[0]}" | grep -o '[0-9]$') #cpn
			# start a loop over each available HCI interface to count over for
			# the possible values that can be assigned as current HCI interface.
			posspathnum=0
			for (( c=0; c<"$cn"; c++ )); do
				# posspathnum stores the digit value of the in-loop HCI interface.
				posspathnum=$(echo "${hcicnfvar[$c]}" | grep -o '[0-9]$') #ppn
				# hcimax is the max index value of the available HCI interfaces.
				hcimax=$(($(echo "${#hcicnfvar[@]}")-1))
				# ppn=cpn; then just assign to next available interface.
				if [ "$posspathnum" -eq "$currpathnum" ]; then
					# ensure that ppn is always less than hcimax
					if [ "$posspathnum" -lt "$hcimax" ]; then
						posspathnum=$(($posspathnum+1))
						hciconfig -a "hci$currpathnum" down
						# additional $? variable, prexstat variable used to
						# ensure this tiered process completes as expected.
						prexstat=$?
						hciconfig -a "hci$posspathnum" reset
						exstat=$?
						if [ "$exstat" = "0" ] && [ "$prexstat" = 0 ]; then 
							echo "switched from hci$currpathnum to hci$posspathnum"
							hcitlvar=$(hcitool dev | while read line; do echo "${line#Devices:}"; done)
							hcitllist=($(echo "${hcitlvar#$'\n'}"))
							hcitltotal=$((${#hcitllist[@]}/2))
						else
							# HCI switch failed
							error+=(4)
						fi
					fi
				fi
				# ppn<cpn (hcimax<cpn>hcimax); we need to ensure that cpn isn't
				# he highest HCI value, if not increment to a value higher. If
				# higher, force an interface assignment to hci0, the next loop
				# will then start from ppn=cpn.
				if [ "$posspathnum" -lt "$currpathnum" ]; then
					if [ "$currpathnum" -ne "$hcimax" ]; then
						while [ "$posspathnum" -le "$currpathnum" ]; do
							# increment ppn until one value higher than cpn.
							posspathnum+=1
						done
						hciconfig -a "hci$currpathnum" down
						prexstat=$?
						hciconfig -a "hci$posspathnum" reset
						exstat=$?
						if [ "$exstat" = "0" ] && [ "$prexstat" = 0 ]; then 
							echo "switched from hci$currpathnum to hci$posspathnum"
							hcitlvar=$(hcitool dev | while read line; do echo "${line#Devices:}"; done)
							hcitllist=($(echo "${hcitlvar#$'\n'}"))
							hcitltotal=$((${#hcitllist[@]}/2))
						else
							# HCI switch failed
							error+=(5)
						fi
					else
						# forcing interface assignment to hci0
						posspathnum=0
						hciconfig -a "hci$currpathnum" down
						prexstat=$?
						hciconfig -a "hci$posspathnum" reset
						exstat=$?
						if [ "$exstat" = "0" ] && [ "$prexstat" = 0 ]; then 
							echo "switched from hci$currpathnum to hci$posspathnum"
							hcitlvar=$(hcitool dev | while read line; do echo "${line#Devices:}"; done)
							hcitllist=($(echo "${hcitlvar#$'\n'}"))
							hcitltotal=$((${#hcitllist[@]}/2))
						else
							# HCI switch failed
							error+=(6)
						fi
					fi
				fi
			done
		else
			# many interfaces are up, will fix to only one running interface.
			linuxhciprimer
		fi
	elif [ "$cn" = 1 ]; then
		# only one host HCI interface found
		error+=(7)
	else
		# no host HCI interfaces found, non-critical
		error+=(8)
	fi
}

function linuxhciprimer {
	# this function ensures that only one HCI device is used per session.
	# hcicnfvar gives the total number of available HCI devices (hciconfig)
	# hcitlvar parses and outputs a string with all HCI devices that are up (hcitool dev)
	# hcitllist takes hcitlvar, removes the newline and stores the result in a list
	# hcitltotal calculates the number of HCI devices that are up for counter operations
	lnxhciflag=0

	echo "Priming HCI device on host"
	hcicnfvar=($(hciconfig | grep -o "hci."))
	hcitlvar=$(hcitool dev | while read line; do echo "${line#Devices:}"; done)
	hcitllist=($(echo "${hcitlvar#$'\n'}"))
	hcitltotal=$((${#hcitllist[@]}/2))
	tl=$(echo "$hcitltotal")
	cn=$(echo "${#hcicnfvar[@]}")
	echo "${hcitltotal} HCI interfaces are up"

	# if only 1 HCI device is up, echo it and proceed to next function.
	if [ "$tl" -eq 1 ]; then
		# for loop parses out the hci dev number and hci uid of the
		# one HCI device that is up.
		for (( i=0; i<"$tl"; i++ )); do 
			if [ "$(($i%2))" = 0 ]; then
				hcitldev=$(echo "${hcitllist[$i]}")
				hcitluid=$(echo "${hcitllist[$(($i+1))]}")
				echo "$hcitldev=$hcitluid"
			fi
		done
	# if no HCI devices are available and none are available append
	# error code 23 and 24 to be caught by errorcatch function.
	elif [ "$tl" -eq 0 ] && [ "$cn" -eq 0 ]; then
		error+=(23)
		error+=(24)
	# if the number of HCI devices that are available is greater than 0
	elif [ "$cn" -gt 0 ]; then		
		# pull down ALL available interfaces first (i.e. hcitool dev = none).
		for (( h=0; h<"$tl"; h++ )); do
			if [ "$(($h%2))" = 0 ]; then
				hciconfig -a "${hcitllist[$h]}" down
				exstat=$?
				if [ "$exstat" = "0" ]; then 
					echo "${hcicnfvar[$n]} reset on host"
					hcitlvar=$(hcitool dev | while read line; do echo "${line#Devices:}"; done)
					hcitllist=($(echo "${hcitlvar#$'\n'}"))
					hcitltotal=$((${#hcitllist[@]}/2))
					tl=$(echo "$hcitltotal")
				else
					# HCI interface pull down failed
					error+=(9)
				fi
			fi
		done
		# pull up hci0 after pulling down all available interfaces.
		hciconfig -a hci0 reset
		exstat=$?
		if [ "$exstat" = "0" ]; then 
			echo "hci0 reset on host"
			echo "$(hciconfig)"
			hcitlvar=$(hcitool dev | while read line; do echo "${line#Devices:}"; done)
			hcitllist=($(echo "${hcitlvar#$'\n'}"))
			hcitltotal=$((${#hcitllist[@]}/2))
			tl=$(echo "$hcitltotal")
			lnxhciflag=1
		else
			# HCI interface pull up failed
			# Might occur due to an rfkill command on host.
			# Error received with state that the operation
			# is not permissible.
			error+=(10)
		fi
	fi
}

function linuxhcicheck {
	# precondition test function that's run before pairing/binding or flushing and
	# ensures HCI device is properly set up.
	echo "Searching for HCI device"

	# hcitlvar parses and outputs a string with all HCI devices that are up (hcitool dev)
	# hcitllist takes hcitlvar, removes the newline and stores the result in a list
	# hcitltotal calculates the number of HCI devices that are up for counter operations
	hcitlvar=$(hcitool dev | while read line; do echo "${line#Devices:}"; done)
	hcitllist=($(echo "${hcitlvar#$'\n'}"))
	hcitltotal=$((${#hcitllist[@]}/2))
	tl=$(echo "$hcitltotal")

	if [ "$tl" -eq 1 ]; then
		echo "$tl HCI interface is up"
		lnxhciflag=1
	elif [ "$tl" -eq 0 ]; then
		echo "$tl HCI interfaces are up"
		echo "Will try to set to hci0"
		linuxhciprimer
	else
		echo "$tl HCI interfaces are up"
		echo "Will pull down extra interfaces and set to hci0"
		linuxhciprimer
	fi
}

function linuxflush {
	# this function flushes bluetooth device from host (unpairs and unbinds)

	linuxhcicheck
	echo "Number of HCI setup errors = ${#error[@]}"
	echo "error code(s): ${error[@]}"

	# if atleast one HCI device is up, flushing will be run
	if [ "$lnxhciflag" -eq 0 ]; then
		echo "flushing will not be attempted"
		failflag=1
	elif [ "$lnxhciflag" -eq 1 ] && [ "${#error[@]}" -eq 0 ]; then
		echo "flushing process will be run"
		failflag=0
		lnxhciflag=0
	elif [ "$lnxhciflag" -eq 1 ] && [ "${#error[@]}" -gt 0 ]; then
		echo "flushing will be attempted despite error state"
		failflag=0
		lnxhciflag=0
	fi

	if [ "$failflag" -eq 0 ]; then
		# begin flushing process
		echo "Starting flush on linux host"
		echo "Starting release process:"
		# check if the passed device dev assignment exists in the rfcomm table.
		devfind=$(rfcomm | grep -o "$devassgn")
		# check if the passed uid exists in the rfcomm table.
		uidfind=$(rfcomm | grep "$uid")
		# matchuid stores the rfcomm dev number entry attached to passed uid.
		matchuid=$(echo "$uidfind" | grep -o "rfcomm.")

		# if passed device dev assignment doesn't exist in the rfcomm table
		if [ -z "$devfind" ]; then
			echo "$devassgn not previously attached"
		# else ensure that passed device dev assignment is the same as what's
		# stored for the passed uid in the rfcomm table.
		else
			if [ "$devfind" = "$matchuid" ]; then
				rfcomm release "/dev/$devassgn"
				exstat=$?
				if [ "$exstat" = "0" ]; then 
					echo "$uid unbound from $host host"
				else
					# Rfcomm release failed
					error+=(11)
				fi
			# Device dev path found attached to passed uid ($matchuid) 
			# doesn't match the device dev path assigned value ($devfind)
			else
				error+=(12)
			fi
		fi

		# begin unpairing process
		echo "Starting unpair process:"
		# hciuid stores the macid of host HCI device
		hciuid=$(hciconfig | grep -o ..:..:..:..:..:..)

		# if there's no uid found for the host HCI device, append error 13
		# unpair from the passed macid variable if otherwise
		if [ -z "$hciuid" ]; then
			# no host HCI interface found
			error+=(13)
		else
			# all paired device details are stored in /var/lib/bluetooth/$hciuid/linkkeys
			# we run a match on the passed uid to check if registered as paired on host.
			if [ -f /var/lib/bluetooth/$hciuid/linkkeys ]; then
				keychck=$(cat /var/lib/bluetooth/$hciuid/linkkeys | grep -o $uid)
				if [ -z "$keychck" ]; then
					# HCI device lacks linkkey file
					error+=(14)
				else
					bluez-test-device remove $uid
					exstat=$?
					if [ "$exstat" = "0" ]; then 
						echo "Unpairing" $uid "successful"
					else
						# unpairing was successful
						error+=(15)
					fi
				fi
			fi
		fi
	else
		echo "CRITICAL: flush preconditions failed"
		error+=(30)
	fi
}

function linuxreinstall {
	# this function installs the passed firmware (skpath) to
	# all attached USB Arduino devices

	echo "Starting firmware install"
	export ARDUINO_DIR=/usr/share/arduino
	export BOARD=uno
	
	# devpaths is a list that stores all ttyACM* device path details
	# devnum stores the number of items in the devpaths list
	devpaths=($(find /sys -name "ttyACM*" | grep devices))
	devnum=$(echo ${#devpaths[@]})

	# if USB device devs have been found proceed to reinstall i.e. devnum>0
	if [ "$devnum" -gt 0 ]; then
		for dev in "${devpaths[@]}"; do
			# use udevadm piped to grep to match and output all devices with the tag Arduino
			ardcheck=$(udevadm info -a -p ${dev#./sys} | grep Arduino)
			# if there are arduinos associated dev paths attempt to upload the firmware
			if [ ! -z "$ardcheck" ]; then
				target=/dev/$(echo $dev | grep -o ttyACM.)
				echo "Dev path:"$dev" Dev num:"$devnum" Target:"$target
				export SERIALDEV=$target
				export ARDUINO_PORT=$target
				export ARDUINO_LIBS="Servo Wire Firmata"
				make -C $skpath upload
				exstat=$?
				# $? is a shell status code that returns the previous commands exit code
				if [ "$exstat" = "0" ]; then 
					# firmware upload was successful
					echo "firmware was successfully uploaded"
				else
					# firmware upload was unsuccessful
					echo "firmware upload was unsuccessful"
					error+=(16)
				fi
			else
				# no Arduinos found attached to USB ports
				error+=(28)
			fi
		done
	else
		# no USB devices attached to host
		error+=(27)
	fi
}

function linuxpandb {
	# this function pairs and binds to the passed uid (uid)

	linuxhcicheck
	echo "Number of HCI setup errors = ${#error[@]}"
	echo "error code(s): ${error[@]}"

	# if atleast one HCI device is up, flushing will be run
	if [ "$lnxhciflag" -eq 0 ]; then
		echo "flushing will not be attempted"
		failflag=1
	elif [ "$lnxhciflag" -eq 1 ]; then
		if [ "${#error[@]}" -eq 0 ]; then
			echo "flushing process will be run"
			failflag=0
			lnxhciflag=0
		else
			echo "flushing will be attempted despite error state"
			failflag=0
			lnxhciflag=0
		fi
	fi
	if [ "$failflag" -eq 0 ]; then
		echo "Pairing and Binding"
		# begin pairing and binding process
		# restart systemd dbus and bluetooth services as a fail safe check
		# NOTE: restarting the dbus on a Linux VM will break it.
		# service dbus restart
		service bluetooth restart
		echo "Checking connection status of" $uid "to" $host "host"
		# bluetooth ping(ONCE) the bluetooth client to confirm it's up
		hciuid=$(hciconfig | grep -o ..:..:..:..:..:..)
		if l2ping "$uid" -c 1; then
			echo "Pinging" $uid "to ensure device is up"
			# devfind conditional checks if submitted UID is already registered on rfcomm,
			# if not it pairs to and binds the passed macid variable
			devfind=$(rfcomm | grep $uid)
			if [ -z "$devfind" ]; then
				echo "Starting pairing process:"
				# pair to the passed macid variable.
				if [ ! -z $hciuid ]; then
					echo "Checking if $uid previously paired to $hciuid"
					if [ -f /var/lib/bluetooth/$hciuid/linkkeys ]; then
						keychck=$(cat /var/lib/bluetooth/$hciuid/linkkeys | grep -o $uid)
						if [ -z "$keychck" ]; then
							echo 1234 | bluez-simple-agent $hciuid $uid
							exstat=$?
							# http://stackoverflow.com/questions/748445/shell-status-codes-in-make
							if [ "$exstat" = "0" ]; then 
								echo $uid "paired"
							else
								# pairing to $uid failed
								error+=(17)
							fi
						else
							echo $uid "previously paired"
						fi
					fi
				else
					# no host HCI interfaces available
					error+=(25)
				fi
				# rfchck conditional checks if the passed dev device has already been
				# bound. It releases and binds the passed macid if it has.
				rfchck=$(rfcomm | grep $devassgn)
				if [ -z "$rfchck" ]; then
					echo "Starting binding process:"
					# bind the passed macid to the assigned rfcomm port on channel 1
					rfcomm bind "/dev/"$devassgn $uid 1
					exstat=$?
					if [ "$exstat" = "0" ]; then 
						echo "$uid bound to /dev/$devassgn"
					else
						# binding to $uid to /dev/$devassgn failed
						error+=(18)
					fi
				else
					# /dev/$devassgn already bound to host
					echo "$uid already bound to /dev/$devassgn"
				fi
			else
				# client has already been bound to
				# devassgnchck determines if the passed devassgn value
				devassgnchck=$(echo $devfind | grep -o "rfcomm.")
				if [ "$devassgnchck" = "$devassgn" ]; then
					echo "$uid already bound to /dev/$devassgn"
					echo "Performing pairing status validation"
					if [ ! -z $hciuid ]; then
						if [ -f /var/lib/bluetooth/$hciuid/linkkeys ]; then
							keychck=$(cat /var/lib/bluetooth/$hciuid/linkkeys | grep -o $uid)
							if [ -z "$keychck" ]; then
								echo 1234 | bluez-simple-agent $hcinum $uid
								exstat=$?
								# http://stackoverflow.com/questions/748445/shell-status-codes-in-make
								if [ "$exstat" = "0" ]; then 
									echo "$uid paired"
								else
									# bluetooth pairing to $uid failed
									error+=(20)
								fi
							else
								echo "$uid previously paired"
							fi
						fi
					else
						# no host HCI interfaces available
						error+=(26)
					fi
				else
					# $uid already assigned to $devassgnchck, won't force assignment to $devassgn
					error+=(21)
				fi
			fi
			# Print rfcomm table data
			rfcomm
		else
			# bluetooth ping failed to find passed macid.
			error+=(22)
		fi
	else
		echo "CRITICAL: Pair and binding preconditions failed"
		error+=(30)
	fi
}

function errorcatch {
	errorcount=0
	if [ "$host" = "linux" ]; then
		for e in ${error[@]}; do
			case $e in
				"1" ) echo "error 1: error while resetting ${hci[$n]}";;
				"2" ) echo "error 2: error while resetting ${hci[$n]}";;
				"3" ) echo "error 3: no host HCI interfaces available";;
				"4" ) echo "error 4: error while switching from hci$currpathnum to hci$posspathnum";;
				"5" ) echo "error 5: error while switching from hci$currpathnum to hci$posspathnum";;
				"6" ) echo "error 6: error while switching from hci$currpathnum to hci$posspathnum";;
				"7" ) echo "error 7: one HCI interface available, HCI switch cannot be done";;
				"8" ) echo "error 8: no host HCI interfaces available";;
				"9" ) echo "error 9: error pulling down ${hcicnfvar[$c]} interface";;
				"10" ) echo "error 10: error while pulling up hci$posspathnum";;
				"11" ) echo "error 11: rfcomm release of /dev/$devassgn failed";;
				"12" ) echo "error 12: Device path assigned to $matchuid match the app assigned value $devfind";;
				"13" ) echo "error 13: no HCI interfaces available, forced script exit";;
				"14" ) echo "error 14: $uid not previously paired to";;
				"15" ) echo "error 15: unpairing $uid not successful";;
				"16" ) echo "error 16: $(basename $skpath) firmware upload was unsuccessful";;
				"17" ) echo "error 17: bluetooth pairing to $uid failed";;
				"18" ) echo "error 18: binding to $uid to /dev/$devassgn failed";;
				"19" ) echo "error 19: /dev/$devassgn already bound to $prebound";; # invalid error, need to remove it
				"20" ) echo "error 20: bluetooth pairing to $uid failed";;
				"21" ) echo "error 21: $uid already assigned to $devassgnchck";;
				"22" ) echo "error 22: bluetooth pinging $uid failed ";;
				"23" ) echo "error 23: no HCI interfaces are up";;
				"24" ) echo "error 24: no host HCI interfaces available, forced script exit";;
				"25" ) echo "error 25: no host HCI interfaces available";;
				"26" ) echo "error 26: no host HCI interfaces available";;
				"27" ) echo "error 27: no USB devices attached to host";;
				"28" ) echo "error 28: no Arduinos attached to host";;
				"29" ) echo "error 29: no host HCI interfaces available";;
				"30" ) echo "error 30: preconditions test failed";;
			esac
			if [ "$e" != 0 ]; then
				errorcount=$(($errorcount+1))
			else
				errorcount="$errorcount"
			fi
		done
		homedir=$(dirname $(pwd))
		if [ "$errorcount" -gt 0 ]; then
			retcode="$errorcount"
			echo "$errorcount errors occured"
			if ([ ! -f $homedir/data/$cuser/error.log ] && [ "$flush" = "" ]) || [ "$cuser" = "admin" ]; then
				if [ "$cuser" = "admin" ]; then
					echo "setting up admin error logging"
					if [ ! -d $homedir/data/$cuser ]; then
						echo "creating admin data directory"
						mkdir -p $homedir/data/$cuser
					fi
					if [ -f $homedir/data/$cuser/error.log ]; then
						rm $homedir/data/$cuser/error.log
					fi
				fi
				echo "starting non-flush error logging cycle"
				touch $homedir/data/$cuser/error.log
				echo -e "[{\"key\":\""$errorkey"\", \"code\": [" >> $homedir/data/$cuser/error.log
				while [ "$errorcount" -ge 1 ]; do
					errorcount=$(($errorcount-1))
					if [ "$errorcount" -eq 0 ]; then
						err="${error[$errorcount]}"
						echo -e "\""$err"\"]}]" >> $homedir/data/$cuser/error.log
					else
						err="${error[$errorcount]}"
						echo -e "\""$err"\"," >> $homedir/data/$cuser/error.log
					fi
				done
				exit $retcode
			elif [ -f $homedir/data/$cuser/error.log ] && [ "$flush" != "" ]; then
				echo "starting flush error logging cycle"
				# http://www.theunixschool.com/2014/08/sed-examples-remove-delete-chars-from-line-file.html
				sed 's/]}]$/,/g' $homedir/data/$cuser/error.log
				while [ "$errorcount" -ge 1 ]; do
					errorcount=$(($errorcount-1))
					if [ "$errorcount" -eq 0 ]; then
						err="${error[$errorcount]}"
						echo -e "\""$err"\"]}]" >> $homedir/data/$cuser/error.log
					else
						err="${error[$errorcount]}"
						echo -e "\""$err"\"," >> $homedir/data/$cuser/error.log
					fi
				done
				exit $retcode
			fi
		else
			echo "no errors occured"
			if [ -f $homedir/data/$cuser/error.log ]; then
				rm $homedir/data/$cuser/error.log
			fi
			exit 0
		fi
	fi
}

function windowsscripts {
	echo "Setting up host-client connection for $uid on $uid host"
	echo ""
	sleep 3
}

function darwinscripts {
	echo "Setting up host-client connection for $uid on $uid host"
	echo ""
	sleep 3
}

function linuxscripts {
	echo "starting linux script execution"
	while [ "$1" != "" ]; do
		case $1 in
			"reinstall" ) linuxreinstall;;
			"flush" )  linuxflush;;
			"pairbind" ) linuxpandb;;
			"allup" ) linuxhciallup;;
			"primehci" ) linuxhciprimer;;
			"switch" ) linuxhciswitch;;
		esac
		shift
	done
}

optexecute $host