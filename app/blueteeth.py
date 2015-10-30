import bluetooth
import os
import time
import serial
import subprocess
import panya
import re
from app import db
from app.models import User, Robot
from datetime import datetime
from app import app
from flask import json, g
from sys import platform as _platform

# Uncomment the following lines to enable BLE search
# if _platform == "linux" or _platform == "linux2":
# 	from bluetooth.ble import DiscoveryService
# 	blescan = True
# else:
# 	blescan = False

bdir = app.config["BASE"]
sdir = app.config["DATA"]
resp = []
reset=""

if _platform == "linux" or _platform == "linux2":
	rfpath = os.path.join(bdir,"app","rfcommlin.sh")
	host="lin"
else:
	rfpath = os.path.join(bdir,"app","rfcommwin.sh")
	host="win"

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

def rfcommbind(rfcset,macid,alias=None,unick=None,commands=None,uid=None,rst=None):
	global reset
	if rst is None:
		try:
			if (host=="win"):
				output=subprocess.check_output([rfpath,macid,rfcset], shell=True)
				print '********************************************************************'
				print output
				print '********************************************************************'
			else:
				output=subprocess.check_output(['%s %s %s' %(rfpath,macid,rfcset)], shell=True)
				print '********************************************************************'
				print output
				print '********************************************************************'
			datasend(macid,alias,unick,commands,rfcset,uid)
		except Exception,e:
			robot = Robot.query.filter_by(user_id=uid).first()
			robot.status="inactive"
			db.session.commit()
			print "Error Binding RFCOMM Device"
			reset = "y"
			if (host=="win"):
				output=subprocess.check_output([rfpath,macid,rfcset,reset], shell=True)
			else:
				output=subprocess.check_output(['%s %s %s %s' %(rfpath,macid,rfcset,reset)], shell=True)
			reset = ""
			print str(e)
	else:
		reset=rst
		try:
			if (host=="win"):
				output=subprocess.check_output([rfpath,macid,rfcset,reset], shell=True)
				print '********************************************************************'
				print output
				print '********************************************************************'
			else:
				output=subprocess.check_output(['%s %s %s %s' %(rfpath,macid,rfcset,reset)], shell=True)
				print '********************************************************************'
				print output
				print '********************************************************************'
			reset = ""
			robot = Robot.query.filter_by(user_id=uid).first()
			robots = Robot.query.all()
			robot.status="inactive"
			db.session.commit()
			for rob in robots:
				print "%s:%s" %(robot.alias,robot.status)
		except Exception,e:
			print "Error Releasing RFCOMM device!"
			robot = Robot.query.filter_by(user_id=uid).first()
			robot.status="inactive"
			db.session.commit()
			print str(e)

def datasend(macid,alias,unick,commands,rfcset,uid):
	global reset
	devport = "/dev/"
	devport+=str(rfcset)
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
	for i in range(0,len(commands)):
		print commands[i]
	rfcommbind(rfcset,macid,None,None,None,uid,reset)

def rfcommset(robots):
	prstlist={}
	prstflag=False
	for robot in robots:
		if (robot.status!="inactive"):
			prstcomm=re.search("rfcomm.",robot.status)
			if prstcomm:
				print 'Found %s registered to %s' %(prstcomm.group(),robot.alias)
				devno=prstcomm.group().strip("rfcomm")
				prstlist['robot.alias']=devno
				prstflag=True
			else:
				print 'Possible error with status setting for %s' %(robot.alias)
				print 'Resetting status value to inactive.'
				robot.status="inactive"
				db.session.commit()
				prstflag=False
	if prstflag:
		for key, value in prstlist.iteritems():
			maxval=value
			if value>maxval:
				maxval=value
		setval=maxval+1
	else:
		setval=0
	setcomm="rfcomm"+str(setval)
	return setcomm

def portsetup(commands):
	Qflag = False
	user = User.query.filter_by(nickname=g.user.nickname).first()
	robot = Robot.query.filter_by(user_id=user.id).first()
	robots = Robot.query.all()
	for rob in robots:
		print "%s:%s" %(robot.alias,robot.status)
		if (rob.status!="inactive"):
			print "Queuing bluetooth upload"
			Qflag = True
			rfcset = "NULL"
			# a procedure to manage concurrent bluetooth requests
			# should come here
			Qflag = False
	if not Qflag:
		# rfcset = "rfcomm0"
		# robot.status="active"
		rfcset=rfcommset(robots)
		robot.status=rfcset
		db.session.commit()
		rfcommbind(rfcset,robot.macid,robot.alias,user.nickname,commands,user.id)
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
