import os
import re
from flask import Flask
from flask.ext.bcrypt import Bcrypt
from flask.ext.sqlalchemy import SQLAlchemy
from flask.ext.login import LoginManager
from config import ADMINS, MAIL_SERVER, MAIL_PORT, MAIL_USERNAME, MAIL_PASSWORD

basedir = os.path.dirname(__file__)
basedir = re.sub('\/\/app', '', basedir)

if os.path.exists(basedir+'/instance'):
	app=Flask(__name__,instance_path='/home/root/Envs/PanyaBot/instance/',instance_relative_config=True)
	app.config.from_pyfile('config.py')
else:
	app=Flask(__name__)

bcrypt=Bcrypt(app)

# load configuration values and connect to app.db
app.config.from_object('config')
db=SQLAlchemy(app)

# set up Flask-Login
login_manager=LoginManager()
login_manager.init_app(app)
login_manager.login_view='login'

# if not app.debug:
# 	import logging
# 	from logging.handlers import SMTPHandler, RotatingFileHandler
	
# 	# set up error notification over email
# 	crendentials = None
# 	if MAIL_USERNAME or MAIL_PASSWORD:
# 		crendentials = (MAIL_USERNAME, MAIL_PASSWORD)
# 	mail_handler = SMTPHandler((MAIL_SERVER, MAIL_PORT), 'no-reply@' + MAIL_SERVER, ADMINS, 'panyabot failure', credentials)
# 	mail_handler.setLevel(logging.ERROR)
# 	app.logger.addHandler(mail_handler)

# 	# set up logging to a file
# 	file_handler = RotatingFileHandler('tmp/panyabot.log', 'a', 1*1024*1024, 10)
# 	file_handler.setFormatter(logging.Formatter('%(asctime)s %(levelname)s: %(message)s [in %(pathname)s:%(lineno)d]'))
# 	app.logger.setLevel(logging.INFO)
# 	file_handler.setLevel(logging.INFO)
# 	app.logger.addHandler(file_handler)
# 	app.logger.info('panyabot startup')

from app import views, models