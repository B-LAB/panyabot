################################################
# Dockerfile to build panyabot container images
# Based on raspbian
################################################
#Set the base image to raspbian
FROM resin/raspberrypi-systemd:jessie

# File Author / Maintainer
MAINTAINER Wachira Ndaiga

# Update the repository sources list and install dependancies
RUN sudo apt-get update && apt-get install -y \
    python \
    python-dev \
    python-pip \
    usbutils \
    bluez \
    python-bluez

# Set application directory tree
COPY . /panyabot
WORKDIR /panyabot
RUN cd /panyabot

# Create running environment
RUN pip install virtualenv
RUN virtualenv flask --system-site-packages
RUN flask/bin/pip install -r requirements.txt
RUN chmod 755 run.sh

# Expose ports
EXPOSE 5000

# Create environment variables
ENV INITSYSTEM on
ENV XDG_RUNTIME_DIR /run/user/%I

# Start web app
 CMD ["/bin/bash", "run.sh"]