from flask import Flask
from flask.ext.bcrypt import Bcrypt
from flask.ext.sqlalchemy import SQLAlchemy
from flask.ext.login import LoginManager

app=Flask(__name__,instance_path='/home/root/Envs/PanyaBot/instance/',instance_relative_config=True)
bcrypt=Bcrypt(app)

app.config.from_object('config')
app.config.from_pyfile('config.py')
db=SQLAlchemy(app)

login_manager=LoginManager()
login_manager.init_app(app)
login_manager.login_view='login'

from app import views, models