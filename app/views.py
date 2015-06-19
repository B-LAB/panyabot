from flask import render_template, url_for, request, g, flash, redirect
from flask.ext.login import login_user, logout_user, current_user, login_required
from app import app, db, login_manager, bcrypt
from .forms import LoginForm
from .models import User

@app.before_request
def before_request():
	g.user = current_user

@login_manager.user_loader
def user_loader(user_id):
	return User.query.get(int(user_id))

@app.route('/login', methods=['GET','POST'])
def login():
	if g.user is not None and g.user.is_authenticated():
		return redirect(url_for('home'))	
	print db
	form = LoginForm()
	if form.validate_on_submit():
		user = User.query.filter_by(nickname=form.nameid.data).first()
		print user
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
	user=current_user
	user.authenticated=False
	db.session.add(user)
	db.session.commit()
	logout_user()
	return redirect(url_for('login'))

@app.route('/')
@app.route('/home')
@login_required
def home():
	user = g.user
	return render_template('home.html', title='Home', user=user)