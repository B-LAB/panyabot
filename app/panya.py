#!flask/bin/python
import collections

commands = []

class Panya(object):
	def __init__(self):
		pass

	def PanyaMove(self, longdir=None):
		self.long = longdir
		storecomms("LONG",self.long)
		# return self.long

	def PanyaTurn(self, latdir=None):
		self.lat = latdir
		storecomms("LAT",self.lat)
		# return self.lat

	def PanyaStop(self):
		storecomms("H","Stop")
		# return self.instruct

	def PanyaSetSpeed(self, speed=None):
		self.speed = speed
		storecomms("S",self.speed)
		# return self.speed

	def PanyaDelay(self, duration=None):
		self.duration = duration
		storecomms("D",self.duration)
		# return self.duration

	def PanyaPin(self, pin=None, state=None):
		self.pin = pin
		self.state = state
		storecomms("P/S",self.pin+","+self.state)
		# return self.pin + ":" + self.state

def storecomms(arg1=None, arg2=None):
	commands.append(arg1+"="+arg2)

def main():
	pass

if __name__ == '__main__':
	main()