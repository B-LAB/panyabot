#!/bin/bash
# Major revision of host-slave connection on *nix/x86 platforms
# Based on positional parameters (http://linuxcommand.org/wss0130.php)

interactive=
flash=
reinstall=
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
		-r | --reinstall )		reinstall=1
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
fi

echo "host=$host:uid=$uid:dev=$devassgn:skpath=$skpath:reinstall=$reinstall:flush=$flush:interactive=$interactive"

if [ "$host" = "linux" ] || [ "$host" = "darwin" ]; then
	# conditional to determine if the current subprocess call is to reistall or connect/release a robot
	if [ "$reinstall" = "1"  ]; then
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
						make -C $skpath upload
						exstat=$?
						# $? is a shell status code that returns the previous commands exit code
						if [ "$exstat" = "0" ]; then 
							# Sketch upload was successful
							exit 0
						else
							# Sketch upload was unsuccessful
							exit 1
						fi
					fi
				done
			fi
		fi
	else
		# determine the host bluetooth device number
		hcinum=$(hciconfig | grep -o hci.)
		# conditional to check that the hci device is not down
		# NOTE: -z is an empty/unset variable check that returns true if variable isn't set
		# alternatively, -n checks if a variable is non-empty/set and returns True if it is
		if [ ! -z "$hcinum" ];then
			# host bluetooth device found & will be reset
			echo "$(hciconfig)"
			hciconfig -a $hcinum reset
			echo "$(hciconfig)"
		else
			# no host bluetooth device found. return exit code to shell or subprocess call.
			exit 2
		fi
		# conditional to determine if the flush flag has been set. if true, passed macid
		# is flushed; if false, passed macid is paired to and bound to given rfcomm port.
		if [ "$flush" = "" ]; then
			# begin pairing and binding process
			# restart systemd dbus and bluetooth services as a fail safe check
			service dbus restart
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
								exit 3
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
							exit 4
						fi
					else
						prebound=$(echo $rfchck | grep -o "..:..:..:..:..:..")
						echo "/dev/"$devassgn "already bound to" $prebound
						exit 11
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
									exit 9
								fi
							else
								echo $uid "previously paired"
							fi
						fi
					else
						echo $uid "already assigned to" $devassgnchck
						echo "Not able to reassign to" $devassgn
						exit 10
					fi
				fi
				# Pairing and Binding process went through flawlessly
				rfcomm
				exit 0
			else
				# bluetooth ping failed to find passed macid. return exit code to shell or subprocess call.
				exit 6
			fi
		else
			# begin flushing process
			# determine rfcomm path to release it from client
			echo "Starting unbinding process:"
			devfind=$(rfcomm | grep $uid)
			rfchck=$(rfcomm | grep $devassgn)
			devfound=$($devfind | grep -o "rfcomm.")
			rfcfound=$($rfchck | grep -o "rfcomm.")

			if [ -z "$rfchck" ]; then
				echo $devassgn "not previously attached"
			else
				if [ "$devfound" = "$rfcfound" ]; then
					rfcomm release "/dev/"$devassgn
					exstat=$?
					if [ "$exstat" = "0" ]; then 
						echo $uid "unbound from"
					else
						# Rfcomm release failed. return exit code to shell or subprocess call
						exit 5
					fi
				else
					echo "Device dev path found doesn't match the one passed in"
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
		fi
	fi
else
	# $@ is a special array used to store bash command line arguments
	# you can access these args using this format: ${arg[x]} with zero indexing
	# Currently this must always run from a CLI interface with bash scripting capabilities e.g. Git, Cygwin
	echo "Setting up RFCOMM bind for $uid on x86 host"
	echo -n "host=$host:uid=$uid:dev=$devassgn:skpath=$skpath:reistall=$reinstall:flush=$flush:interactive=$interactive"
	echo ""
	sleep 3
fi