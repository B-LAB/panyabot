import bluetooth
from flask import json
from sys import platform as _platform

if _platform == "linux" or _platform == "linux2":
	from bluetooth.ble import DiscoveryService
	blescan = True
else:
	blescan = False

resp = []

def leginquire():
	global resp
	global i
	resp = []
	nearby_devices = bluetooth.discover_devices(duration=8, lookup_names=True, flush_cache=True, lookup_class=False)
	# resp.append({'number':str(len(nearby_devices))})
	for addr, name in nearby_devices:
		try:
			resp.append({'mac':str(addr),'name':str(name)})
		except UnicodeEncodeError:
			resp.append({'mac':str(addr),'name':str(name.encode('utf-8', 'replace'))})
	if ((resp == []) & (blescan)):
		bleinquire()
	response = json.dumps(resp)
	return response

def bleinquire():
	global resp
	global i
	service = DiscoveryService()
	devices = service.discover(2)
	for addr, name in devices.items():
		resp.append({'mac*':str(addr),'name*':str(name)})

if __name__ == '__main__':
	print "OS: %s" % (str(_platform))
	print leginquire()