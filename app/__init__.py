import os
import re
from flask import Flask
from flask.ext.bcrypt import Bcrypt
from flask.ext.sqlalchemy import SQLAlchemy
from flask.ext.login import LoginManager

basedir = os.path.dirname(__file__)
basedir = re.sub('\/\/app', '', basedir)

if os.path.exists(basedir+'/instance'):
	app = Flask(__name__,instance_path=basedir+'/instance',instance_relative_config=True)
	app.config.from_pyfile('config.py')
else:
	app = Flask(__name__)

# instantiate the salted hash
bcrypt = Bcrypt(app)

# load configuration values and connect to app.db
app.config.from_object('config')
db = SQLAlchemy(app)

# set up Flask-Login
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

from app import views, models