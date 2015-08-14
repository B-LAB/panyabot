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

RUN git clone https://github.com/waschguy/panyabot

# Create running environment
RUN pip install virtualenv
RUN virtualenv flask
RUN pip install -r /panyabot/requirements.txt

# Expose ports
EXPOSE 5000

# Set the default directory where CMD will execute
WORKDIR /panyabot

CMD flask/bin/python db_create.py
CMD flask/bin/python db_migrate.py
CMD flask/bin/python tests.py
CMD flask/bin/python run.py