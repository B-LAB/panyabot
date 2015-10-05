import bluetooth
from flask import json, g
from sys import platform as _platform
import os
from datetime import datetime
from app import app

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

def rfcommreg(arg1):
	import subprocess
	subprocess.check_call(['%s %s' % (rfpath, str(arg1))], shell = True)

def datasend(arg1,arg2,arg3,commands):
	import os
	print os.environ["rfport"]
	print 'Sending %s\'s commands to %s, alias:%s' % (arg3,arg1, arg2)
	for i in range(0,len(commands)):
		print commands[i]

def portsetup(commands):
	from app import db
	from app.models import User, Robot
	user = User.query.filter_by(nickname=g.user.nickname).first()
	robot = Robot.query.filter_by(user_id=user.id).first()
	# sdpbrowse(robot.macid) # HC06 and HC05 bluetooth modules don't advertise an SDP interface. Uncomment if
	# using a module that does. Bug number will be attached to this issue.
	rfcommreg(robot.macid)
	datasend(robot.macid,robot.alias,user.nickname,commands)

def parseblocks(code):
	import panya
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
