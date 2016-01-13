from flask import render_template, url_for, request, g, flash, redirect, jsonify
from flask.ext.login import login_user, logout_user, current_user, login_required
from app import app, db, login_manager, bcrypt
from .serialcon import leginquire, parseblocks, sketchupl
from .forms import LoginForm, RegistrationForm
from .models import User, Robot

@app.before_request
def before_request():
	g.user = current_user

@app.errorhandler(404)
def not_found_error(error):
	return render_template('404.html'), 404

@app.errorhandler(500)
def internal_error(error):
	db.session.rollback()
	return render_template('500.html'), 500

@login_manager.user_loader
def user_loader(user_id):
	return User.query.get(int(user_id))

@app.route('/bluetooth', methods=['POST','GET'])
def bluetooth():
	if request.method == 'POST':
		parseblocks(request.json['panya'])
		return jsonify({'status':'OK'})
	if request.method == 'GET':
		return jsonify({
		'devices': leginquire()
		})

@app.route('/reset')
def reset():
	user = g.user
	robot = Robot.query.filter_by(user_id=user.id).first()
	if sketchupl('sketches/Blink/Blink.ino'):
		flash(str(robot.alias)+' has been reset!')
	else:
		flash(str(robot.alias)+' reset failed!')
	return render_template('home.html', title='Home', user=user, robot=robot)

@app.route('/register', methods=['GET','POST'])
def register():
	form = RegistrationForm()
	if form.validate_on_submit():
		print "Registering user to " + str(db)
		pwd_hash=bcrypt.generate_password_hash(form.password.data)
		user = User(firstname=form.firstname.data, lastname=form.lastname.data, nickname=form.nickname.data, password=pwd_hash)
		db.session.add(user)
		robot = Robot(alias=form.robot_name.data, macid=form.robot_mac.data, owner=User.query.filter_by(nickname=(form.nickname.data)).first(), status="inactive")
		db.session.add(robot)
		db.session.commit()
		flash('You\'re account has been created. Please log in')
		return redirect(url_for('login'))
	return render_template('register.html', title='Sign Up', form=form)

@app.route('/login', methods=['GET','POST'])
def login():
	if g.user is not None and g.user.is_authenticated():
		return redirect(url_for('home'))	
	form = LoginForm()
	if form.validate_on_submit():
		print 'Logging in to ' + str(db)
		user = User.query.filter_by(nickname=form.nickname.data).first()
		if user:
			if bcrypt.check_password_hash(user.password, form.password.data):
				user.authenticated = True
				db.session.add(user)
				db.session.commit()
				login_user(user, remember=form.remember_me.data)
				flash('Welcome %s' % (g.user.nickname))
				return redirect(request.args.get('next') or url_for('home'))
			else:
				flash('Invalid login. Please try again')	
		else:
			flash('Invalid login. Please try again')
			return redirect(url_for('login'))
	return render_template('login.html', title='Sign In', form=form)

@app.route('/logout')
def logout():
	"""Logout the current user"""
	print 'Logging out of ' + str(db)
	user = current_user
	user.authenticated = False
	db.session.add(user)
	db.session.commit()
	logout_user()
	flash('You have been logged out')
	return redirect(url_for('login'))

@app.route('/')
@app.route('/home')
@login_required
def home():
	user = g.user
	robot = Robot.query.filter_by(user_id=user.id).first()
	return render_template('home.html', title='Home', user=user, robot=robot)

@app.route('/blockly')
@login_required
def blockly():
	user = g.user
	robot = Robot.query.filter_by(user_id=user.id).first()
	return render_template('blockly.html', title='Blockly', user=user, robot=robot)
