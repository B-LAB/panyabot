################################################
# Dockerfile to build panyabot container images
# Based on yocto
################################################
#Set the base image to raspbian
FROM resin/rpi-raspbian

# File Author / Maintainer
MAINTAINER Wachira Ndaiga

# Update the repository sources list
RUN sudo apt-get update
RUN sudo apt-get upgrade

# Install python and python-dev
RUN sudo apt-get install -y python python-dev python-pip

# Create running environment
RUN pip install virtualenv
RUN virtualenv flask
RUN yes w | pip install -r requirements.txt
RUN flask/bin/python db_create.py
RUN flask/bin/python db_migrate.py
RUN flask/bin/python tests..py
RUN flask/bin/python run.py
