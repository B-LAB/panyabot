from flask.ext.wtf import Form
from wtforms import StringField, BooleanField, PasswordField
from wtforms.validators import DataRequired, EqualTo, MacAddress

class LoginForm(Form):
	nickname=StringField('nickname', validators=[DataRequired()])
	password=PasswordField('password', validators=[DataRequired()])
	remember_me=BooleanField('remember_me', default=False)

class RegistrationForm(Form):
	firstname=StringField('firstname', validators=[DataRequired()])
	lastname=StringField('lastname', validators=[DataRequired()])
	nickname=StringField('nickname', validators=[DataRequired()])
	robot_mac=StringField('robot_mac', validators=[DataRequired(),MacAddress()])
	robot_name=StringField('robot_name', validators=[DataRequired()])
	password=PasswordField('new_password', validators=[DataRequired(),EqualTo('confirm', message='Password must match')])
	confirm=PasswordField('repeat_password')