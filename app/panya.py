#!flask/bin/python

class Panya(object):
	def __init__(self):
		pass

	def PanyaMove(self, longdir):
		self.direction = longdir
		print self.direction
		return longdir

	def PanyaTurn(self, latdir):
		self.direction = latdir
		print self.direction
		return latdir

	def PanyaStop(self):
		pass

	def PanyaSetSpeed(self, speed):
		self.speed = speed
		print self.speed
		return speed

	def PanyaDelay(self, duration):
		self.duration = duration
		print self.duration
		return duration

	def PanyaPin(self, pin, state):
		self.pin = pin
		self.state = state
		print self.pin + ":" + self.state
		return self.pin + ":" + self.state