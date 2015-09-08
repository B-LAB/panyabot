#!/bin/bash
echo "Trying to mount peripheral devices"
mount -t devtmpfs none /dev
udevd &
udevadm trigger
hciconfig hci0 up
echo "Testing working directory and starting run.py"
flask/bin/python tests.py
flask/bin/python run.py