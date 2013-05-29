import sys

a = open(sys.argv[1], "r")

hdr = a.readline()[:-2].split('\t')
print hdr

t = False

from Link import Link

s = Link()

data = []

for l in a.readlines():
	l = l[:-2].split('\t')
	C = int(l[hdr.index('rxcmd')])
	DATA = int(l[hdr.index('DataPort')], 0x10)
	
	if t and not C:
#		if len(data) and (len(data) != 1 or data[0][1]):
		s.handle_packet(data)
		data = []
	ts = int(l[0])
	
	if C:
		data.append((ts, DATA))
	else:
		print "+%d [%02x] alt_int=%d ID=%d RxEvent=%d Vbus=%d LineState=%d%d" % (ts, DATA, (DATA>>7)&1, (DATA>>6)&1, (DATA>>4)&3, (DATA>>2)&3, (DATA>>1)&1, (DATA>>0)&1)

	t = C

if len(data):
	print "dropping partial last packet"
