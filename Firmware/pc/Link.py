
def bitreverse(a):
	r = 0
	for i in range(8):
		r <<= 1
		if a & 1:
			r |= 1
		a >>= 1
	return r

class Link:
	STATE_SYNC, STATE_DATA, STATE_EOP = range(3)

	PID_RESERVED = 0
	PID_SPLIT = 1
	PID_PING = 2
	PID_ERR = 3
	PID_PRE = 3
	PID_ACK = 4
	PID_NAK = 5
	PID_NYET = 6
	PID_STALL = 7
	PID_OUT = 8
	PID_IN = 9
	PID_SOF = 10
	PID_SETUP = 11
	PID_DATA0 = 12
	PID_DATA1 = 13
	PID_DATA2 = 14
	PID_MDATA = 15

	PIDS = {
		PID_RESERVED: "RESERVED", 
		PID_SPLIT: "SPLIT", 
		PID_PING: "PING",
		PID_ERR: "ERR",
		PID_ACK: "ACK",
		PID_NAK: "NAK",
		PID_NYET: "NYET",
		PID_STALL: "STALL",
		PID_OUT: "OUT",
		PID_IN: "IN",
		PID_SOF: "SOF",
		PID_SETUP: "SETUP",
		PID_DATA0: "DATA0",
		PID_DATA1: "DATA1",
		PID_DATA2: "DATA2",
		PID_MDATA: "MDATA"
	}

	def __init__(self):
		self.state = self.STATE_EOP
		self.data = []

	# ... this is PHY
	def handle_sync(self):
		self.handle_eop()
		self.state = self.STATE_SYNC
		self.bits = 0
		self.cnt = 0
		self.stuff = 0
		self.data = []

	# ... this is PHY
	def handle_bit(self, start, b):
		if self.state == self.STATE_SYNC:
			if b:
				self.state = self.STATE_DATA
				self.stuff = 1 
		elif self.state != self.STATE_EOP:
			if b == 1:
				self.stuff += 1
			else:
				if self.stuff == 6:
					self.stuff = 0
					return
				self.stuff = 0
					
			if self.cnt == 0:
				self.data_ts = start

			self.bits |= b << self.cnt
			self.cnt += 1
			if self.cnt == 8:
				self.data.append((self.data_ts, self.bits))
				self.bits = 0
				self.cnt = 0

	def handle_eop(self):
		if self.state == self.STATE_DATA:
			self.handle_packet(self.data)

	def handle_packet(self, data):
#		print "-----------"

		PSTATE_PID, PSTATE_SOF0, PSTATE_SOF1, PSTATE_TOKEN0, PSTATE_TOKEN1, PSTATE_DUMP = range(6)

		pstate = PSTATE_PID

		for ts, d in data:
			desc = ""

			if pstate == PSTATE_PID:
				d = bitreverse(d)
				if (((d >> 4) ^ d) & 0xF) != 0xF:
					desc = "<invalid>"
					pstate = PSTATE_DUMP
				else:
					pid = d >> 4
					desc = "PID " + self.PIDS[pid]
					if pid == self.PID_SOF:
						pstate = PSTATE_SOF0
					elif pid in [self.PID_OUT, self.PID_IN, self.PID_SETUP]:
						pstate = PSTATE_TOKEN0
					else:
						pstate = PSTATE_DUMP
			elif pstate == PSTATE_SOF0:
				sof = d
				pstate = PSTATE_SOF1
			elif pstate == PSTATE_SOF1:
				sof = (d << 8) | sof
				desc = "FrameNumber=%d, CRC5=%02x" % (sof & 0x07FF, (sof >> 11) & 0x1F)
				pstate = PSTATE_DUMP
			elif pstate == PSTATE_TOKEN0:
				token = d
				pstate = PSTATE_TOKEN1
			elif pstate == PSTATE_TOKEN1:
				token = (d << 8) | token
				desc = "Address=%02x, EP=%02x, CRC5=%02x" % (token & 0x007F, (token >> 7) & 0xF, (token >> 11) & 0x1F)
				pstate = PSTATE_DUMP
			else:
				desc = ""

			print "+%d  %02x %s" % (ts, d, desc)

