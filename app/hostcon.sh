#!/bin/bash
# Major revision of host-slave connection on *nix/x86 platforms
# Based on positional parameters (http://linuxcommand.org/wss0130.php)

interactive=
flash=
reset=
host="linux"

while [ "$1" != "" ]; do
	case $1 in
		-H | --host )			shift
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
		-r | --reset )			reset=1
								;;
		-f | --flush )			flush=1
								;;
		-i | --interactive )	interactive=1
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

	echo -n "Would you like to reset $uid firmware? (y/n) >"
	read response
	if [ "$response" = "y" ]; then
		reset=1
		echo -n "Will upload default firmware to $uid."
		echo ""
	fi

	echo -n "Would you like to flush device? (y/n) >"
	read response
	if [ "$response" = "y" ]; then
		reset=1
		echo -n "Will flush $uid from $devassgn."
		echo ""
	fi
fi

echo -n "host=$host:uid=$uid:dev=$devassgn:skpath=$skpath:reset=$reset:flush=$flush:interactive=$interactive"
echo ""

if [ "$host" = "linux" ] || [ "$host" = "darwin" ]; then
	# conditional to determine if the current subprocess call is to reset or connect/release
	# a robot
	if [ "$reset" = "1"  ]; then
		if [ "$host" = "darwin" ]; then
			# export ARDUINO_DIR=/Applications/Arduino.app/Contents/Java
			export ARDUINO_DIR=/Applications/Arduino.app/Contents/MacOS/
			export ARDMK_DIR=$(pwd)/Makefile
			export AVR_TOOLS_DIR=/usr
			export MONITOR_PORT=/dev/ttyACM0
			export BOARD_TAG=uno
		else
			export ARDUINO_DIR=/usr/share/arduino
			export BOARD=uno
			# determine if device dev paths have been assigned to any USB serial devices
			# devs contains the device dev paths that matched
			# devnos contains the number of devices that matched
			devpaths=($(find /sys -name "ttyACM*" | grep devices))
			devnum=${#devpaths[@]}
			echo "Number of Dev paths found: "$denvum
			if [ "$devnum" != 0 ]; then
				for dev in ${devpaths[@]}; do
					echo "Checking: $dev"
					ardcheck=$(udevadm info -a -p ${dev#./sys} | grep Arduino)
					if [ ! -z "$ardcheck" ]; then
						echo "Arduino found"
						target=/dev/$(echo $dev | grep -o ttyACM.)
						echo $target " will be reset now"
						export SERIALDEV=$target
						export ARDUINO_PORT=$target
						echo "Will attempt to make upload $skpath to $target"
						make -C $skpath upload
						exstat=$?
						# http://stackoverflow.com/questions/748445/shell-status-codes-in-make
						if [ "$exstat" = "0" ]; then 
							echo "Sketch upload successful"
							exit 0
						else
							echo "A problem occured while uploading sketch"
							exit 1
						fi
					fi
				done
			fi
		fi
	else
		# determine the hci number
		hcinum=$(hciconfig | grep -o hci.)
		# conditional to check that the hci device is not down
		# NOTE: -z is an empty/unset variable check that returns true if variable isn't set
		# alternatively, -n checks if a variable is non-empty/set and returns True if it is
		if [ ! -z "$hcinum" ];then
			echo "Found $hcinum"
			echo "Will now reset $hcinum"
			echo "$(hciconfig)"
			hciconfig -a $hcinum reset
			echo "$(hciconfig)"
		else
			echo "No HCI device found"
			exit 2
		fi
		# conditional to determine if the reset flag has been set. if true, passed macid
		# is flushed; if false, passed macid is paired to and bound to given rfcomm port.
		if [ "$flush" = "" ]; then
			# begin pairing and binding process
			# restart systemd dbus and bluetooth services as a fail safe check
			service dbus restart
			service bluetooth restart
			# double check the hci device, probably could do with less checks, but just to
			# ensure reliable operation
			if [ -z "$hcist"]; then
				hciconfig $hcinum up
			fi
			echo "Setting up RFCOMM bind for $uid on *NIX host"
			# bluetooth ping(ONCE) the passed macid variable to confirm it's up
			if l2ping "$uid" -c 1; then
				# devfind conditional checks if submitted UID is already registered on rfcomm,
				# if not it pairs to and binds the passed macid variable
				devfind=$(rfcomm | grep -o $uid)
				if [ -z "$devfind" ]; then
					# pair to the passed macid variable.
					# NOTE: Perhaps I should check linkkeys if device has already been
					# paired to?
					echo 1234 | bluez-simple-agent $hcinum $uid
					exstat=$?
					# http://stackoverflow.com/questions/748445/shell-status-codes-in-make
					if [ "$exstat" = "0" ]; then 
						echo "Pairing successful"
					else
						echo "Pairing was not successful"
						exit 3
					fi
					# rfchck conditional checks if the passed dev device has already been
					# bound. It releases and binds the passed macid if it has.
					rfchck=$(rfcomm | grep -o $devassgn)
					if [ -z "$rfchck" ]; then
						# bind the passed macid to the assigned rfcomm port on channel 1
						rfcomm bind "/dev/"$devassgn $uid 1
						exstat=$?
						# http://stackoverflow.com/questions/748445/shell-status-codes-in-make
						if [ "$exstat" = "0" ]; then 
							echo "Rfcomm binding successful"
						else
							echo "Rfcomm binding was not successful"
							exit 4
						fi
					else
						rfcomm release "/dev/"$devassgn
						exstat=$?
						# http://stackoverflow.com/questions/748445/shell-status-codes-in-make
						if [ "$exstat" = "0" ]; then 
							echo "Rfcomm release successful"
						else
							echo "Rfcomm release was not successful"
							exit 5
						fi
						rfcomm bind "/dev/"$devassgn $uid 1
						exstat=$?
						# http://stackoverflow.com/questions/748445/shell-status-codes-in-make
						if [ "$exstat" = "0" ]; then 
							echo "Rfcomm binding successful"
						else
							echo "Rfcomm binding was not successful"
							exit 4
						fi
					fi
					echo "Dev device assigned:/dev/" $devassgn
				else
					# rfport searches for the bound rfcomm port number e.g. /dev/rfcomm(?)
					echo $(hcitool name $uid) "already bound"
					rfport=$(rfcomm | grep -o rfcomm.)
					echo "Dev device assigned: /dev/"$rfport
				fi
				rfcomm
				exit 0
			else
				# bluetooth ping failed to find passed macid
				rfport="NULL"
				echo "$uid not found"
				echo -n "Ensure device is on and within range"
				exit 6
			fi
		else
			# begin flushing process
			# conditionals that ensure robust flushing if errors are found
			echo "Setting up RFCOMM release for $uid on *NIX host"
			rfchck=$(rfcomm | grep -o $devassgn)
			if [ -z "$rfchck" ]; then
				echo "Dev device $devassgn not previously attached"
			else
				rfcomm release "/dev/$devassgn"
				exstat=$?
				# http://stackoverflow.com/questions/748445/shell-status-codes-in-make
				if [ "$exstat" = "0" ]; then 
					echo "Dev device $devassgn released, rfcomm output:" $(rfcomm)
				else
					echo "Rfcomm release was not successful"
					exit 5
				fi
			fi
			hciuid=$(hciconfig | grep -o ..:..:..:..:..:..)
			if [ -z "$hciuid" ]; then
				echo "no host bluetooth hci found"
				exit 7
			else
				keychck=$(cat /var/lib/bluetooth/$hciuid/linkkeys | grep -o $uid)
				if [ -z "$keychck" ]; then
					echo "$uid not previously paired"
				else
					bluez-test-device remove $uid
					exstat=$?
					# http://stackoverflow.com/questions/748445/shell-status-codes-in-make
					if [ "$exstat" = "0" ]; then 
						echo "$uid successfully unpaired"
					else
						echo "unpairing $uid failed"
						exit 8
					fi
				fi
				exit 0
			fi
		fi
	fi
else
	# $@ is a special array used to store bash command line arguments
	# you can access these args using this format: ${arg[x]} with zero indexing
	# Currently this must always run from a CLI interface with bash scripting capabilities e.g. Git, Cygwin
	echo "Setting up RFCOMM bind for $uid on x86 host"
	echo -n "host=$host:uid=$uid:dev=$devassgn:skpath=$skpath:reset=$reset:flush=$flush:interactive=$interactive"
	echo ""
	sleep 3
fi