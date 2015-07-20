#!flask/bin/python
import os
import unittest
import datetime

from config import basedir
from app import app, db, bcrypt
from app.models import User, Robot

class TestCase(unittest.TestCase):
	def setUp(self):
		print 'Setting up database testing environment',
		app.config['TESTING'] = True
		app.config['WTF_CSRF_ENABLED'] = False
		app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + os.path.join(basedir, 'test.db')
		self.app = app.test_client()
		db.create_all()

		u = User(firstname='John', lastname='Doe', nickname='Jay', password=bcrypt.generate_password_hash('JD'))
		r = Robot(alias='Ninja', macid='10:14:06:30:19:86', owner=User.query.filter_by(nickname=u.nickname).first())
		db.session.add(u)
		db.session.add(r)
		db.session.commit()
		print '- Done!'

	def tearDown(self):
		print 'Tearing down database testing environment',
		db.session.remove()
		db.drop_all()
		print '- Done!'

	def login(self, nickname, password):
		return self.app.post('/login', data=dict(nickname=nickname, password=password),
							follow_redirects=True)

	def logout(self):
		return self.app.get('/logout', follow_redirects=True)

	def register(self, firstname, lastname, nickname, mac, roname, pwd, confirm):
		return self.app.post('register', data=dict(firstname=firstname,
							lastname=lastname, nickname=nickname, robot_mac=mac,
							robot_name=roname, password=pwd, confirm=confirm),
							follow_redirects=True)

	def test_registration(self):
		result = self.register('John', 'Doe', 'Jay', '10:14:06:30:19:90',
								'Geisha', 'JD', 'JD')
		assert 'This nickname is already in use' in result.data
		result = self.register('John', 'Doe', 'Johnny', '10:14:06:30:19:86',
								'Geisha', 'JD', 'JD')
		assert 'This robot already has an owner' in result.data
		result = self.register('John', 'Doe', 'Johnny', '10:14:06:30:19:90',
								'Ninja', 'JD', 'JD')
		assert 'This robot name is already in use' in result.data
		result = self.register('admin', 'admin', 'admin', '10:14:06:30:19:90',
								'robot', 'default', 'default')
		assert 'account has been created' in result.data

	def test_login_logout(self):
		result = self.login('Jay','JD')
		assert 'Welcome' in result.data
		result = self.logout()
		assert 'You have been logged out' in result.data
		result = self.login('admin', 'default')
		assert 'Invalid login' in result.data

if __name__ == '__main__':
	unittest.main()
