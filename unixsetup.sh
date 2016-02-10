#!/bin/bash
sudo apt-get update && apt-get install -y \
    python \
    python-dev \
    python-pip \
    usbutils \
    bluez \
    python-gobject \
    python-bluez \
    nano \
    picocom \
    arduino-mk \
    wget \
    ca-certificates \
    make

echo "Setting up runtime environment"
pip install virtualenv
virtualenv flask --system-site-packages
flask/bin/pip install -r requirements.txt
chmod 755 db_start.py
chmod 755 tests.py
chmod 755 run.py
chmod 755 run.sh
chmod 755 app/hostcon.sh

echo "Creating and testing SQLAlchemy database"
flask/bin/python db_start.py
flask/bin/python tests.py

echo "Copying makefiles and compiling sketches"
# http://askubuntu.com/questions/300744/copy-the-content-file-to-all-subdirectory-in-a-directory-using-terminal
mkdir -p ../data/sketches
cp -r sketches ../data/
for d in ../data/sketches/*/; do
	export BOARD=uno
	export ARDUINO_DIR=/usr/share/arduino
	cp /usr/share/arduino/Arduino.mk "$d"Makefile
	make -C $d
done
rm -r sketches


flask/bin/python run.py