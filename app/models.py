from app import app
from app import db

class User(db.Model):
	__tablename__ = 'user'

	id=db.Column(db.Integer, primary_key=True)
	firstname=db.Column(db.String(100))
	lastname=db.Column(db.String(100))
	nickname=db.Column(db.String(64), index=True, unique=True)
	password=db.Column(db.String)

	authenticated = db.Column(db.Boolean, default=False)
	robots=db.relationship('Robot', backref='owner', lazy='dynamic')

	def is_active(self):
		"""True, as all users are active."""
		return True
	
	def is_authenticated(self):
		"""Return True if the user is authenticated."""
		return self.authenticated
	
	def is_anonymous(self):
		"""False, as anonymous users aren't supported."""
		return False

	def get_id(self):
		"""Return id of user"""		
		try:
			return unicode(self.id) # python 2
		except NameError:
			return str(self.id) # python 3


	def __repr__(self):
		return '<User %r>' % (self.nickname)

class Robot(db.Model):
	__tablename__ = 'robot'

	id=db.Column(db.Integer, primary_key=True)
	alias=db.Column(db.String(64), index=True, unique=True)
	macid=db.Column(db.String(48), index=True, unique=True)
	status=db.Column(db.String(14), index=True, unique=True)
	totaltime=db.Column(db.Integer, index=True)
	lastuse=db.Column(db.DateTime)
	user_id=db.Column(db.Integer, db.ForeignKey('user.id'))
	sessions=db.relationship('Session', backref='robot', lazy='dynamic')

	def __repr__(self):
		return '<Robot %r>' % (self.alias)

class Session(db.Model):
	__tablename__ = 'session'

	id=db.Column(db.Integer, primary_key=True)
	timestamp=db.Column(db.DateTime, index=True, unique=True)
	progression=db.Column(db.String, index=True, unique=True)
	duration=db.Column(db.Integer, index=True)
	robot_id=db.Column(db.Integer, db.ForeignKey('robot.id'))

	def __repr__(self):
		return '<Session %r>' % (self.timestamp)