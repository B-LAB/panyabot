#!/bin/bash
echo "Trying to mount peripheral devices"
mount -t devtmpfs none /dev
udevd &
udevadm trigger
service dbus restart
service bluetooth restart

if [ ! -f "../data/test.db" ]; then
	echo "Testing working directory and starting run.py"
	flask/bin/python tests.py
fi

if [ ! -f ../data/sketches ]; then
	echo "Copying makefiles and compiling firmware"
	# http://askubuntu.com/questions/300744/copy-the-content-file-to-all-subdirectory-in-a-directory-using-terminal
	mkdir -p ../data/sketches
	cp -r sketches /data/
		for oldfwdir in ../data/sketches/*; do
			export BOARD=uno
			export ARDUINO_DIR=/usr/share/arduino
			cp /usr/share/arduino/Arduino.mk "$oldfwdir"Makefile
			make -C $oldfwdir
		done
	rm -r sketches
else
	echo "Checking for firmware updates"
	for newfwdir in sketches/*; do
		nfwbasename=$(basename $newfwdir)
		echo "checking $nfwbasename firmware"
		for newfw in $newfwdir/*; do
			nfirmware=$(basename $newfw)
			nfwmatch=$(echo $nfirmware | grep -i -o $nfwbasename)
			if [ ! -z "$nfwmatch" ]; then
				echo "$nfirmware"
				for oldfwdir in ../data/sketches/*; do
					ofwbasename=$(basename $oldfwdir)
					for oldfw in $oldfwdir/*; do
						ofirmware=$(basename $oldfw)
						ofwmatch=$(echo $ofirmware | grep -i -o $ofwbasename)
						if [ ! -z "$ofwmatch" ]; then
							if [ ! -z "$ofwmatch" ]; then
	                            onfwmatch=$(echo $ofirmware | grep -i -o $nfwbasename)
	                            if [ ! -z "$onfwmatch" ]; then
	                                    echo "comparing $ofirmware to $nfirmware"
	                                    if [ "$ofirmware" != "$nfirmware" ]; then
	                                            echo "updating $ofirmware to $nfirmware"
	                                            onum=$(echo ${ofirmware//[A-Z]/})
	                                            nnum=$(echo ${nfirmware//[A-Z]/})
	                                            # if [ "$onum" -lt "$nnum" ]
	                                            # 	echo $newfwdir/$newfw/$nfirmware
	                                            # fi
	                                    else
	                                            echo "no update required for $ofwbasename"
	                                    fi
	                            fi
	                        fi
						fi
					done
				done
			fi
		done
	done

	rm -r sketches

fi

flask/bin/python db_start.py
flask/bin/python run.py

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
fi