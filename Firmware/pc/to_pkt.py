import sys

a = open(sys.argv[1], "rb")

if a.read(1) not in ("\0", "\1"):
	a.seek(0)

data = []
ts = 0
prx = 0
while True:
	d = ord(a.read(1))
	t = ord(a.read(1))
	
	ts += 1
	
	if not t:
		data.append((ts, d))
	else:
		if prx & 0x10 and not d & 0x10:
			if len(data):
				print "RawPacket data<%s> speed<HS> time<0.000 %03d %03d>" % (' '.join("%02X" % x[1] for x in data), data[0][0] / 1000, data[0][0] % 1000)
			data = []
		prx = d
