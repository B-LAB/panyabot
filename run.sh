#!/bin/bash
echo "Trying to mount peripheral devices"
mount -t devtmpfs none /dev
udevd &
udevadm trigger
service dbus restart
service bluetooth restart

echo "Testing working directory and starting run.py"
flask/bin/python tests.py

flask/bin/python db_start.py
flask/bin/python run.py
hcino=$(grep -o "hci." <<< $(hciconfig))
hcist=$(grep -o "down" <<< $(hciconfig))

echo "Copying makefiles to sketch directories"
# http://askubuntu.com/questions/300744/copy-the-content-file-to-all-subdirectory-in-a-directory-using-terminal
for d in /panyabot/sketches/*/; do
	cp /usr/share/arduino/Arduino.mk "$d"Makefile
done 

if [ -z "$hcist"]; then
	hciconfig $hcino up
fi