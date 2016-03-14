#!/bin/bash
echo "Trying to mount peripheral devices"
mount -t devtmpfs none /dev
udevd &
udevadm trigger
service dbus restart
service bluetooth restart

echo "Validating for database instantiation"
if [ ! -f "../data/app.db" ]; then
	echo "Instatiating app database"
	flask/bin/python db_start.py
	echo "Running first database tests"
	flask/bin/python tests.py
else
	echo "App database already instatiated"
	echo "Validating for first database test"
	if [ ! -f "../data/test.db" ]; then
		echo "Running first database tests"
		flask/bin/python tests.py
	else
		echo "First database test already run"
	fi
fi

echo "Checking for firmware updates"
./firmwareman.sh
echo "Priming one HCI device on host"
./app/hostcon.sh -P
echo "Starting app"
flask/bin/python run.py