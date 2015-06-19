from app import app, db

class User(db.Model):
	id=db.Column(db.Integer, primary_key=True)
	nickname=db.Column(db.String(64), index=True, unique=True)
	robots=db.relationship('Robot', backref='owner', lazy='dynamic')

	def __repr__(self):
		return '<User %r>' % (self.nickname)

class Robot(db.Model):
	id=db.Column(db.Integer, primary_key=True)
	alias=db.Column(db.String(64), index=True, unique=True)
	macid=db.Column(db.String(48), index=True, unique=True)
	totaltime=db.Column(db.Integer, index=True)
	lastuse=db.Column(db.DateTime)
	user_id=db.Column(db.Integer, db.ForeignKey('user.id'))
	sessions=db.relationship('Session', backref='robot', lazy='dynamic')

	def __repr__(self):
		return '<Robot %r>' % (self.alias)

class Session(db.Model):
	id=db.Column(db.Integer, primary_key=True)
	timestamp=db.Column(db.DateTime, index=True, unique=True)
	progression=db.Column(db.String, index=True, unique=True)
	duration=db.Column(db.Integer, index=True)
	robot_id=db.Column(db.Integer, db.ForeignKey('robot.id'))

	def __repr__(self):
		return '<Session %r>' % (self.timestamp)