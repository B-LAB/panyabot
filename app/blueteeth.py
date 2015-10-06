import bluetooth
from flask import json, g
from sys import platform as _platform
import os
from datetime import datetime
from app import app
import time
from app import db
from app.models import User, Robot
import serial
import subprocess
import panya

# Uncomment the following lines to enable BLE search
# if _platform == "linux" or _platform == "linux2":
# 	from bluetooth.ble import DiscoveryService
# 	blescan = True
# else:
# 	blescan = False

bdir = app.config["BASE"]
sdir = app.config["DATA"]
resp = []

if _platform == "linux" or _platform == "linux2":
	rfpath = os.path.join(bdir,"app","rfcommlin.sh")
else:
	rfpath = os.path.join(bdir,"app","rfcommwin.sh")

def leginquire():
	global resp
	global i
	resp = []
	nearby_devices = bluetooth.discover_devices(duration=8, lookup_names=True, flush_cache=True)
	for addr, name in nearby_devices:
		try:
			resp.append({'mac':str(addr),'name':str(name)})
		except UnicodeEncodeError:
			resp.append({'mac':str(addr),'name':str(name.encode('utf-8', 'replace'))})
	# if ((resp == []) & (blescan)):
		# bleinquire()
	response = json.dumps(resp)
	return response

def sdpbrowse(uid=None):
	target = uid
	print target
	if target == "all": target = None

	services = bluetooth.find_service(address=target)

	if len(services) > 0:
	    print("found %d services on %s" % (len(services), target))
	    print()
	else:
	    print("no services found")

	for svc in services:
	    print("Service Name: %s"    % svc["name"])
	    print("    Host:        %s" % svc["host"])
	    print("    Description: %s" % svc["description"])
	    print("    Provided By: %s" % svc["provider"])
	    print("    Protocol:    %s" % svc["protocol"])
	    print("    channel/PSM: %s" % svc["port"])
	    print("    svc classes: %s "% svc["service-classes"])
	    print("    profiles:    %s "% svc["profiles"])
	    print("    service id:  %s "% svc["service-id"])
	    print()

def rfcommreg(rfcset,macid,alias,unick,commands,uid):
	try:
		output=subprocess.check_output(['%s %s %s' % (rfpath, str(macid), str(rfcset))], shell=True)
		print '********************************************************************'
		print output
		print '********************************************************************'
		datasend(macid,alias,unick,commands,rfcset,uid)
	except:
		robot = Robot.query.filter_by(user_id=uid).first()
		robot.status="inactive"
		db.session.commit()
		print "Error Binding RFCOMM Device"

def datasend(macid,alias,unick,commands,rfcset,uid):
	devport = rfcset
	print devport
	ser = serial.Serial(devport)
	print ser
	print 'Sending %s\'s commands to %s, alias:%s' % (unick,macid,alias)
	ser.write('1')
	time.sleep(1)
	ser.write('2')
	time.sleep(1)
	ser.write('?')
	time.sleep(2)
	ser.write('1')
	ser.close()
	reset = "y"
	try:
		output=subprocess.check_output(['%s %s %s %s' % (rfpath, str(macid), str(rfcset), str(reset))], shell=True)
		print '********************************************************************'
		print output
		print '********************************************************************'
		robot = Robot.query.filter_by(user_id=uid).first()
		robot.status="inactive"
		reset = ""
		db.session.commit()
		for rob in robots:
			print "%s:%s" %(robot.alias,robot.status)
	except:
		print "Error Releasing RFCOMM device!"
		robot = Robot.query.filter_by(user_id=uid).first()
		robot.status="inactive"
		reset = ""
		db.session.commit()
	for i in range(0,len(commands)):
		print commands[i]

def portsetup(commands):
	Qflag = False
	user = User.query.filter_by(nickname=g.user.nickname).first()
	robot = Robot.query.filter_by(user_id=user.id).first()
	robots = Robot.query.all()
	for rob in robots:
		print "%s:%s" %(robot.alias,robot.status)
		if (rob.status=="active"):
			print "Queuing bluetooth upload"
			Qflag = True
			rfcset = "NULL"
	if not Qflag:
		rfcset = "/dev/rfcomm0"
		robot.status="active"
		db.session.commit()
		rfcommreg(rfcset,robot.macid,robot.alias,user.nickname,commands,user.id)
	# sdpbrowse(robot.macid) # HC06 and HC05 bluetooth modules don't advertise an SDP interface. Uncomment if
	# using a module that does. Bug number will be attached to this issue.

def parseblocks(code):
	response = json.dumps(code)
	t = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
	savedir = os.path.join(sdir, g.user.nickname)
	if not os.path.exists(savedir):
		os.mkdir(savedir)
	filename = os.path.join(savedir, t+'.py')
	print filename
	target = open(filename,'w')
	target.write(code)
	target.close()
	execfile(filename,globals(),locals())
	# panya.commands.append("COUNT="+str(locals()['count']+1))
	portsetup(panya.commands)
	panya.commands = []
	return response

# Uncomment the following lines to enable BLE search
# def bleinquire():
# 	global resp
# 	global i
# 	service = DiscoveryService()
# 	devices = service.discover(2)
# 	for addr, name in devices.items():
# 		resp.append({'mac*':str(addr),'name*':str(name)})

if __name__ == '__main__':
	# print "OS: %s" % (str(_platform))
	print leginquire()
