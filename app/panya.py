#!flask/bin/python

class PanyaMove(longdir):
	def __init__(self, longdir=None):
		self.direction = longdir

	def instruct(self):
		return self.direction

class PanyaTurn(latdir):
	def __init__(self, latdir=None):
		self.direction = latdir

	def instruct(self):
		return self.direction

class PanyaStop():
	def __init__(self):
		pass

	def instruct(self):
		return "S"

class PanyaSetSpeed(speed):
	def __init__(self, speed=None):
		self.speed = speed

	def instruct(self):
		return self.speed

class PanyaPin(pin,state):
	def __init__(self, pin=None, state=None):
		self.pin = pin
		self.state = state

	def instruct(self):
		return self.pin + self.state