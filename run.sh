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
if [ -z "$hcist"]; then
	hciconfig $hcino up