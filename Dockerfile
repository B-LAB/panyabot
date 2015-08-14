################################################
# Dockerfile to build panyabot container images
# Based on yocto
################################################
# File Author / Maintainer
MAINTAINER Wachira Ndaiga

# Update the repository sources list
RUN opkg update

# Install python and python-dev
RUN opkg install -y python python-dev python-pip

# Create running environment
RUN pip install virtualenv
RUN virtualenv flask
RUN source flask/bin/activate
RUN yes w | pip install -r requirements.txt
RUN python db_create.py
RUN python db_migrate.py
RUN python tests..py
RUN python run.py
