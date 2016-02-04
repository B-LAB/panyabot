#!/bin/bash
# Major revision of host-slave connection on *nix/x86 platforms
# Based on positional parameters (http://linuxcommand.org/wss0130.php)

interactive=
hciter=0
testhci=
flash=
reinstall=
host="linux"

while [ "$1" != "" ]; do
	case $1 in
		-H | --host )			shift
								host=$1
								;;
		-h | -- hciter )		shift
								hciter=$1
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
		-t | --testhci )		testhci=1
								;;
	esac
	shift
done

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
fi

echo "host=$host:uid=$uid:dev=$devassgn:skpath=$skpath:reinstall=$reinstall:flush=$flush:interactive=$interactive"

function hciallup {
	# put all available interfaces up.

	hcicnfvar=($(hciconfig | grep -o "hci."))
	hcitlvar=$(hcitool dev | while read line; do echo "${line#Devices:}"; done)
	hcitllist=($(echo "${hcitlvar#$'\n'}"))
	# http://bash.cyberciti.biz/guide/Perform_arithmetic_operations
	hcitltotal=$((${#hcitllist[@]}/2))

	tl=$(echo "$hcitltotal")
	cn=$(echo "${#hcicnfvar[@]}")

	if [ "$tl" -lt "$cn" ]; then
		hcinumdiff=$((${#hcicnfvar[@]}-$hcitltotal))
		echo "$hcinumdiff local host device(s) is/are down"
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
							error=0
						else
							# Hciconfig reset failed
							echo "error while resetting ${hci[$n]}"
							error=1
						fi
					fi
				done
			fi
		done
	fi

	if [ "$error" = 1 ]; then exit 1; fi
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
			currpathnum=$(echo "${hcitllist[0]}" | grep -o '[0-9]$')
			# start a loop over each available HCI interface to count over for
			# the possible values that can be assigned as current HCI interface.
			for (( c=0; c<"$cn"; c++ )); do
				# posspathnum stores the digit value of the in-loop HCI interface.
				posspathnum=$(echo "${hcicnfvar[$c]}" | grep -o '[0-9]$')
				# hcimax is the max index value of the available HCI interfaces.
				hcimax=$(($(echo "${#hcicnfvar[@]}")-1))
				# e.g. ppn=cpn then just assign to next available interface.
				if [ "$posspathnum" -eq "$currpathnum" ]; then
					if [ "$posspathnum" -lt "${#hcicnfvar[@]}" ]; then
						posspathnum+=1
						hciconfig -a "hci$currpathnum" down
						prexstat=$?
						hciconfig -a "hci$posspathnum" reset
						exstat=$?
						if [ "$exstat" = "0" ] && [ "$prexstat" = 0 ]; then 
							echo "switched from hci$currpathnum to hci$posspathnum"
							hcitlvar=$(hcitool dev | while read line; do echo "${line#Devices:}"; done)
							hcitllist=($(echo "${hcitlvar#$'\n'}"))
							hcitltotal=$((${#hcitllist[@]}/2))
							error=0
						else
							# Hciconfig reset failed
							echo "error while switching from hci$currpathnum to hci$posspathnum"
							error=2
						fi
					fi
				fi
				# e.g. ppn<cpn we need to check if cpn isn't the highest value
				# interface, if not increment to a value higher. If it is higher
				# then force a interface assignment to hci0, the next loop will 
				# then start from ppn=cpn.
				if [ "$posspathnum" -lt "$currpathnum" ]; then
					if [ "$currpathnum" -ne "$hcimax" ]; then
						while [ "$posspathnum" -le "$currpathnum" ]; do
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
							error=0
						else
							# Hciconfig reset failed
							echo "error while switching from hci$currpathnum to hci$posspathnum"
							error=3
						fi
					else
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
							error=0
						else
							# Hciconfig reset failed
							echo "error while switching from hci$currpathnum to hci$posspathnum"
							error=4
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
		error=5
	else
		# no host bluetooth device found
		error=6
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

	echo "${hcitltotal} local host device(s) found"
	if [ "$tl" -eq 1 ]; then
		for (( i=0; i<="$tl"; i++ )); do 
			if [ "$(($i%2))" = 0 ]; then
				hcitldev=$(echo "${hcitllist[$i]}")
				hcitluid=$(echo "${hcitllist[$(($i+1))]}")
				echo "$hcitldev=$hcitluid"
			fi
		done
	else
		for (( h=0; h<"$tl"; h++ )); do
			if [ "$(($h%2))" = 0 ]; then
				hciconfig -a "${hcitllist[$h]}" down
				exstat=$?
				if [ "$exstat" = "0" ]; then 
					echo "${hcicnfvar[$n]} reset on host"
					hcitlvar=$(hcitool dev | while read line; do echo "${line#Devices:}"; done)
					hcitllist=($(echo "${hcitlvar#$'\n'}"))
					hcitltotal=$((${#hcitllist[@]}/2))
					error=0
				else
					# Hciconfig shutoff failed
					echo "error while shutting ${hcicnfvar[$c]}"
					error=7
				fi
			fi
			for (( c=0; c<"$cn"; c++ )); do
				hciconfig -a "${hcicnfvar[$c]}" reset
				exstat=$?
				if [ "$exstat" = "0" ]; then 
					echo "${hcicnfvar[$n]} reset on host"
					hcitlvar=$(hcitool dev | while read line; do echo "${line#Devices:}"; done)
					hcitllist=($(echo "${hcitlvar#$'\n'}"))
					hcitltotal=$((${#hcitllist[@]}/2))
					error=0
				else
					# Hciconfig reset failed
					echo "error while resetting ${hcicnfvar[$c]}"
					error=8
				fi
			done
		done

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
				exit 5
			fi
		else
			# Rfcomm device path found ($matchuid) doesn't match the app assigned value ($devfind)
			exit 11
	fi

	# determine macid of host bluetooth device to unpair client
	hciuid=$(hciconfig | grep -o ..:..:..:..:..:..)
	if [ -z "$hciuid" ]; then
		# no host bluetooth mac address found
		exit 2
	else
		# pair to the passed macid variable.
		if [ -f /var/lib/bluetooth/$hciuid/linkkeys ]; then
			keychck=$(cat /var/lib/bluetooth/$hciuid/linkkeys | grep -o $uid)
			if [ -z "$keychck" ]; then
				echo $uid "not previously paired to"
				exit 7
			else
				bluez-test-device remove $uid
				exstat=$?
				# http://stackoverflow.com/questions/748445/shell-status-codes-in-make
				if [ "$exstat" = "0" ]; then 
					echo "Unpairing" $uid "successful"
				else
					echo "Unpairing" $uid "not successful"
					exit 8
				fi
			fi
			exit 0
		fi
	fi
}

function linuxreinstall {
	echo "Reinstalling"
}

function linuxupload {
	echo "Uploading"
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