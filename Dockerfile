################################################
# Dockerfile to build panyabot container images
# Based on raspbian
################################################
#Set the base image to raspbian
FROM resin/rpi-raspbian:jessie

# File Author / Maintainer
MAINTAINER Wachira Ndaiga

# Update the repository sources list
RUN sudo apt-get update

# Install python, python-dev and usbutils
RUN sudo apt-get install -y python python-dev python-pip usbutils

# Set application directory tree
COPY . /panyabot
WORKDIR /panyabot
RUN cd /panyabot
RUN mkdir data

# Create running environment
RUN pip install virtualenv
RUN virtualenv flask
RUN flask/bin/pip install -r requirements.txt
RUN flask/bin/python db_create.py
RUN flask/bin/python db_migrate.py
RUN flask/bin/python tests.py

# Expose ports
EXPOSE 5000

# Start web app
CMD flask/bin/python run.py