# PanyaBot
This is PanyaBot's Flask-based Programming Platform and has been a labour of love project for the past 2 years. This repo is home to the software that underpins all the functioning of our friendly robot, PanyaBot. 

The programming platform will allow for users to control PanyaBot through a block-based programming language as well as allowing for general gameplay. 

Current plans include making sure that the Platform is fully developed to be as close to final/marketready. 

# PanyaBot History
The first instance of this web IDE can be found [here](https://github.com/Muuo/PanyaFace). Developed by Muuo Wambua, Elizabeth Ondula, Kimani Kinyajui, Brian Bosire, Wachira Ndaiga and Jessica Colaco of the iHub, the first iteration of PanyaBot was in every way of the word, a prototype, that went on to garner quite a bit of recognition. 

The team won a number of awards and honours through the [Africa RObotics Network Design Challenge of 2014](http://robotics-africa.org/2014-design-challenge).

Our latest iteration is intended to be as close to market ready, both in terms of hardware and software. 

## Quickstart
To run the instance, clone this repository to your Raspberry Pi, Intel Edison or any Unix-based OS (Untested) and execute `run.sh`. 

This will check if all required dependancies are available and install them if not. You will then be prompted to point your browser to a self-hosted URL where you will find the Programming Platform running. Sign up for a local account and you're ready to go!

# Getting started on Linux and Ubuntu
1. Install [virtualenv](http://virtualenv.readthedocs.org/en/latest/installation.html) and [virtualenvwrapper](http://virtualenvwrapper.readthedocs.org/en/latest/install.html)(makes it easier to work with virtualenv)
2. For bluetooth support we'll need to install the `libbluetooth-dev` library. For ubuntu guys use: `sudo apt-get install libbluetooth-dev` 
3. Clone this repository and navigate into the panyabot folder `cd panyabot`
4. Create a virtualenv called panyabot using `mkvirtualenv panyabot`
5. Install the requirements using pip: `pip install -r requirements.txt -U`
6. Execute run.sh using `sh run.sh` and you should see the server running on http://0.0.0.0:5000