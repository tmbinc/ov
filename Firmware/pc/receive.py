import usb.core
import usb.util
import time

# find our device
dev = usb.core.find(idVendor=0x20b1, idProduct=0x0101)

assert dev
dev.set_configuration()

out = open("out", "wb")

while True:
	print "data!"
	out.write(dev.read(0x81, 0x200, 0, -1).tostring())

