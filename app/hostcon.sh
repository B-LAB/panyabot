#!/bin/bash
# Major revision of host-slave connection on *nix/x86 platforms
# Based on positional parameters (http://linuxcommand.org/wss0130.php)

interactive=
testhci=
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
		-r | --reinstall )		reinstall=1
								;;
		-f | --flush )			flush=1
								;;
		-i | --interactive )	interactive=1
								;;
		-T | --testhci )		testhci=1
								;;
		-S | --switch  )		switch=1
								;;
		-A | --allup )			allup=1
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

	echo -n "Would you like to reinstall $uid firmware? (y/n) >"
	read response
	if [ "$response" = "y" ]; then
		reinstall=1
		echo -n "Will upload default firmware to $uid."
		echo ""
	fi

	echo -n "Would you like to flush device? (y/n) >"
	read response
	if [ "$response" = "y" ]; then
		flush=1
		echo -n "Will flush $uid from $devassgn."
		echo ""
	fi

	echo -n "Would you like to test host bluetooth device(s)? (y/n) >"
	read response
	if [ "$response" = "y" ]; then
		testhci=1
		echo -n "Will test all attached host bluetooth devices."
		echo ""
	fi

	echo -n "Would you like to test current HCI device? (y/n) >"
	read response
	if [ "$response" = "y" ]; then
		testhci=1
		echo -n "Will test current HCI device."
		echo ""
	fi

	echo -n "Would you like to switch out current HCI device? (y/n) >"
	read response
	if [ "$response" = "y" ]; then
		switch=1
		echo -n "Will switch out current HCI device."
		echo ""
	fi

	echo "DEBUG-only feature!"
	echo -n "Would you like to pull up ALL HCI devices? (y/n) >"
	read response
	if [ "$response" = "y" ]; then
		allup=1
		echo -n "Will pull up all HCI devices."
		echo ""
	fi
fi

echo "host=$host:uid=$uid"
echo "flush=$flush:dev=$devassgn"
echo "reinstall=$reinstall:skpath=$skpath"
echo "interactive=$interactive"
echo "testhci=$testhci:switch=$switch:allup=$allup"

function optexecute {
	echo "starting prompted execution scripts"
	if [ "$host" = "linux" ]; then
		if [ ! -z "$flush" ]; then
			linuxflush
			errorcatch
		elif [ ! -z "$reinstall" ]; then
			linuxreinstall
			errorcatch
		else
			linuxpandb
			errorcatch
		fi
	elif [ "$host" = "darwin" ]; then
		darwin
	else
		windows
	fi
}

function errorcatch {
	for e in ${error[@]}; do
		if [ "${#error[@]}" -gt 1 ]; then
			if [ "$e" -eq 1 ]; then
				exit 1
			fi
		elif [ "$e" = 0 ]; then
			# No error occured during function executions
			exit 0
		fi
	done
}

function hciallup {
	# pull all available interfaces up.

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
							error+=(0)
						else
							# hciconfig reset failed
							echo "error while resetting ${hci[$n]}"
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
				error+=(0)
			else
				# hciconfig reset failed
				echo "error while resetting ${hci[$n]}"
				error+=(2)
			fi
		done
	fi
	if [ "$cn" -ne 0 ]; then
		if [ "$tl" -eq "$cn" ]; then
			echo "all interfaces are already up"
		fi
	else
		echo "there are no HCI devices connected"
		error+=(3)
	fi

	# if [ "$error" = 1 ]; then exit 1; fi
}

function hciswitch {
	# iteratively switch to any alternative HCI interface on each call.

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
		# ensure there's only one HCI interface up. Otherwise run hciprimer.
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
							error+=(0)
						else
							# Hciconfig reset failed
							echo "error while switching from hci$currpathnum to hci$posspathnum"
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
							error+=(0)
						else
							# hciconfig reset failed
							echo "error while switching from hci$currpathnum to hci$posspathnum"
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
							error+=(0)
						else
							# hciconfig reset failed
							echo "error while switching from hci$currpathnum to hci$posspathnum"
							error+=(6)
						fi
					fi
				fi
			done
		else
			# many interfaces are up, will fix to only one running interface.
			hciprimer
		fi
	elif [ "$cn" = 1 ]; then
		# only one host bluetooth device found
		error+=(7)
	else
		# no host bluetooth device found
		error+=(8)
	fi
}

function hciprimer {
	# this function ensures that only one HCI device is used per session.

	hcicnfvar=($(hciconfig | grep -o "hci."))
	hcitlvar=$(hcitool dev | while read line; do echo "${line#Devices:}"; done)
	hcitllist=($(echo "${hcitlvar#$'\n'}"))
	# http://bash.cyberciti.biz/guide/Perform_arithmetic_operations
	hcitltotal=$((${#hcitllist[@]}/2))

	# these variables shouldn't be required. initially done because integer and 
	# string comparisons are different in bash.
	tl=$(echo "$hcitltotal")
	cn=$(echo "${#hcicnfvar[@]}")

	echo "${hcitltotal} HCI interfaces are up"
	# if only 1 HCI device is up, then print it and set to no error state (0).
	if [ "$tl" -eq 1 ]; then
		# we have to do this loop to separate hci values from their BD Addresses
		# in the hcitllist list variable.
		for (( i=0; i<"$tl"; i++ )); do 
			if [ "$(($i%2))" = 0 ]; then
				hcitldev=$(echo "${hcitllist[$i]}")
				hcitluid=$(echo "${hcitllist[$(($i+1))]}")
				echo "$hcitldev=$hcitluid"
				error+=(0)
			fi
		done
	else
		# pull down ALL available interfaces.
		for (( h=0; h<"$tl"; h++ )); do
			if [ "$(($h%2))" = 0 ]; then
				hciconfig -a "${hcitllist[$h]}" down
				exstat=$?
				if [ "$exstat" = "0" ]; then 
					echo "${hcicnfvar[$n]} reset on host"
					hcitlvar=$(hcitool dev | while read line; do echo "${line#Devices:}"; done)
					hcitllist=($(echo "${hcitlvar#$'\n'}"))
					hcitltotal=$((${#hcitllist[@]}/2))
					error+=(0)
				else
					# hciconfig shutoff failed
					echo "error while shutting ${hcicnfvar[$c]}"
					error+=(9)
				fi
			fi
		done
		# pull up hci0 after pulling down all available interfaces.
		posspathnum=0
		hciconfig -a "hci$posspathnum" reset
		exstat=$?
		if [ "$exstat" = "0" ]; then 
			echo "hci$posspathnum reset on host"
			hcitlvar=$(hcitool dev | while read line; do echo "${line#Devices:}"; done)
			hcitllist=($(echo "${hcitlvar#$'\n'}"))
			hcitltotal=$((${#hcitllist[@]}/2))
			error+=(0)
		else
			# hciconfig shutoff failed
			echo "error while pulling up hci$posspathnum"
			error+=(10)
		fi
	fi
}

function linuxflush {
	# begin flushing process
	echo "FLUSHING"
	echo "Starting release process:"
	# We first determine if the passed device dev assignment
	# exists in the rfcomm table.
	devfind=$(rfcomm | grep -o "$devassgn")
	# We then check if the passed uid exists in the same
	# rfcomm table to determine if it's already bound to either the
	# assigned device path or another one.
	uidfind=$(rfcomm | grep "$uid")
	# matchuid is used to match the passed uid to the assigned device path
	# but only if the latter hasn't already been assigned.
	matchuid=$(echo "$uidfind" | grep -o "rfcomm.")

	if [ -z "$devfind" ]; then
		echo "$devassgn not previously attached"
	else
		if [ "$devfind" = "$matchuid" ]; then
			rfcomm release "/dev/$devassgn"
			exstat=$?
			if [ "$exstat" = "0" ]; then 
				echo "$uid unbound from $host host"
			else
				# Rfcomm release failed. return exit code to shell or subprocess call
				# exit 5
				error+=(11)
			fi
		else
			# Rfcomm device path found ($matchuid) doesn't match the app assigned value ($devfind)
			# exit 11
			error+=(12)
		fi
	fi

	# determine macid of host bluetooth device to unpair client
	hciuid=$(hciconfig | grep -o ..:..:..:..:..:..)
	if [ -z "$hciuid" ]; then
		# no host bluetooth mac address found
		# exit 2
		error+=(13)
	else
		# pair to the passed macid variable.
		if [ -f /var/lib/bluetooth/$hciuid/linkkeys ]; then
			keychck=$(cat /var/lib/bluetooth/$hciuid/linkkeys | grep -o $uid)
			if [ -z "$keychck" ]; then
				echo $uid "not previously paired to"
				# exit 7
				error+=(14)
			else
				bluez-test-device remove $uid
				exstat=$?
				# http://stackoverflow.com/questions/748445/shell-status-codes-in-make
				if [ "$exstat" = "0" ]; then 
					echo "Unpairing" $uid "successful"
				else
					echo "Unpairing" $uid "not successful"
					# exit 8
					error+=(15)
				fi
			fi
			# exit 0
			error+=(0)
		fi
	fi
}

function linuxreinstall {
	echo "Reinstalling"
	export ARDUINO_DIR=/usr/share/arduino
	export BOARD=uno
	# determine if device dev paths have been assigned to any USB serial devices
	# devs contains the device dev paths that matched
	# devnos contains the number of devices that matched
	devpaths=($(find /sys -name "ttyACM*" | grep devices))
	devnum=${#devpaths[@]}
	# if USB device devs have been found proceed to reinstall i.e. devnum>0
	if [ "$devnum" != 0 ]; then
		for dev in ${devpaths[@]}; do
			# use udevadm tool to determine if dev paths have Arduino in their metadata
			ardcheck=$(udevadm info -a -p ${dev#./sys} | grep Arduino)
			# if there are arduino associated dev paths attempt to upload the sketch
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
					# Sketch upload was successful
					error+=(16)
				else
					# Sketch upload was unsuccessful
					error+=(17)
				fi
			fi
		done
	fi
}

function linuxpandb {
	echo "Pairing and Binding"
	# begin pairing and binding process
	# restart systemd dbus and bluetooth services as a fail safe check
	# NOTE: restarting the dbus will break a Linux Guest OS running on a VM.
	# Turn on only if you're sure you won't be running your fork on a VM.
	# service dbus restart
	service bluetooth restart
	echo "Checking connection status of" $uid "to" $host "host"
	# bluetooth ping(ONCE) the bluetooth client to confirm it's up
	if l2ping "$uid" -c 1; then
		echo "Pinging" $uid "to ensure device is up"
		# devfind conditional checks if submitted UID is already registered on rfcomm,
		# if not it pairs to and binds the passed macid variable
		devfind=$(rfcomm | grep $uid)
		if [ -z "$devfind" ]; then
			echo "Starting pairing process:"
			# pair to the passed macid variable.
			if [ -f /var/lib/bluetooth/$hciuid/linkkeys ]; then
				keychck=$(cat /var/lib/bluetooth/$hciuid/linkkeys | grep -o $uid)
				if [ -z "$keychck" ]; then
					echo 1234 | bluez-simple-agent $hcinum $uid
					exstat=$?
					# http://stackoverflow.com/questions/748445/shell-status-codes-in-make
					if [ "$exstat" = "0" ]; then 
						echo $uid "paired"
					else
						error+=(18)
					fi
				else
					echo $uid "previously paired"
				fi
			fi
			# rfchck conditional checks if the passed dev device has already been
			# bound. It releases and binds the passed macid if it has.
			rfchck=$(rfcomm | grep $devassgn)
			if [ -z "$rfchck" ]; then
				echo "Starting binding process:"
				# bind the passed macid to the assigned rfcomm port on channel 1
				rfcomm bind "/dev/"$devassgn $uid 1
				exstat=$?
				# http://stackoverflow.com/questions/748445/shell-status-codes-in-make
				if [ "$exstat" = "0" ]; then 
					echo $uid "bound to /dev/"devassgn
				else
					error+=(19)
				fi
			else
				prebound=$(echo $rfchck | grep -o "..:..:..:..:..:..")
				echo "/dev/"$devassgn "already bound to" $prebound
				error+=(20)
			fi
		else
			# client has already been bound to
			# devassgnchck determines if the passed devassgn value
			devassgnchck=$(echo $devfind | grep -o "rfcomm.")
			if [ "$devassgnchck" = "$devassgn" ]; then
				echo $(hcitool name $uid) "already bound to /dev/"$devassgn
				echo "Performing pairing status validation"
				if [ -f /var/lib/bluetooth/$hciuid/linkkeys ]; then
					keychck=$(cat /var/lib/bluetooth/$hciuid/linkkeys | grep -o $uid)
					if [ -z "$keychck" ]; then
						echo 1234 | bluez-simple-agent $hcinum $uid
						exstat=$?
						# http://stackoverflow.com/questions/748445/shell-status-codes-in-make
						if [ "$exstat" = "0" ]; then 
							echo $uid "paired"
						else
							error+=(21)
						fi
					else
						echo $uid "previously paired"
					fi
				fi
			else
				echo $uid "already assigned to" $devassgnchck
				echo "Not able to reassign to" $devassgn
				error+=(22)
			fi
		fi
		# Pairing and Binding process went through flawlessly
		rfcomm
		error+=(0)
	else
		# bluetooth ping failed to find passed macid. return exit code to shell or subprocess call.
		error+=(23)
	fi
}

function windows {
	echo "Setting up host-client connection for $uid on $uid host"
	echo ""
	sleep 3
}

function darwin {
	echo "Setting up host-client connection for $uid on $uid host"
	echo ""
	sleep 3
}

optexecute