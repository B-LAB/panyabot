#!/bin/bash

function compilefw {
	for oldfwdir in ../data/sketches/*; do
		export BOARD=uno
		export ARDUINO_DIR=/usr/share/arduino
		cp /usr/share/arduino/Arduino.mk "$oldfwdir"Makefile
		make -C $oldfwdir
		exstat=$?
		if [ "$exstat" = "0" ]; then 
			echo "compile successful"
			exit 0
		else
			echo "compile not successful"
			exit 3
		fi
	done
}

function firmwarecheck {
	if [ ! -d ../data/sketches ]; then
		echo "Copying makefiles and compiling firmware"
		# http://askubuntu.com/questions/300744/copy-the-content-file-to-all-subdirectory-in-a-directory-using-terminal
		mkdir -p ../data/sketches
		cp -r sketches ../data/
		compilefw
		rm -r sketches
		exit 0
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
											onum=$(echo ${ofirmware//[A-Za-z^.]./})
											nnum=$(echo ${nfirmware//[A-Za-z^.]./})
											if [ ! -z "$onum" ]; then
												echo "updating $ofirmware to $nfirmware"
												if [ ! -z "$nnum"]; then
													if [ "$onum" -lt "$nnum" ]; then
														echo "saving $newfw over $oldfw"
														cp -r sketches/nfirmware $(dirname $oldfw)
														rm -r $oldfw
														compilefw
													else
														# Downgrading firmware is not supported
														echo "ERROR: legacy firmware found in update repository"
														exit 2
													fi
												else
													echo "ERROR: firmware in update repository lacks version info"
													echo "INFO: saving $newfw over $oldfw"
													cp -r sketches/nfirmware $(dirname $oldfw)
													rm -r $oldfw
													compilefw
												fi
											else
												echo "ERROR: legacy firmware lacks version info"
												if [ ! -z "$nnum"]; then
													echo "INFO: saving $newfw over $oldfw"
													cp -r $newfw $(dirname $oldfw)
													rm -r $oldfw
													compilefw
												else
													echo "ERROR: firmware update lacks version info"
													echo "ERROR: firmware can't be updated"
													exit 1
												fi
											fi
										else
										echo "no update required for $ofwbasename"
										exit 0
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
}

firmwarecheck