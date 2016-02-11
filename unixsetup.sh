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

echo "Running firmware manager"
flask/bin/sh firmwareman.sh

echo "Starting app"
flask/bin/python run.py