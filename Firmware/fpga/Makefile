# Project name
PROJECT=ov1_fpga
# Part number
PART=XC3S500E
PART_PACKAGE=PQ208
PART_SPEEDGRADE=4
PART_FAMILY=spartan3e
# Output configuration file
OUTPUT=$(PROJECT).svf
WD=work
# Verilog sources

SOURCES=src/ov1_fpga.v 			\
	src/ulpi.v			\
	src/clkgen.v			\
	src/ulpi_ctrl.v			\
	src/xlink/SwitchTokenDef.v 	\
	src/xlink/XLinkDataProc.v 	\
	src/xlink/XLinkRxPhy.v 		\
	src/xlink/XLinkTxPhy.v 		\
	src/xlink/XLinkController.v 	\
	src/xlink/XLinkRxPhy2B.v \
	src/xlink/XLinkTxCntrl.v \
	src/xlink/XLinkTxPhy2B.v \
	src/xlink/XLinkToAddrBus.v \
	src/xlink/XTokenFifo.v\
	src/xlink/SimpleLinkDataProcessor.v \
	src/led_module.v

# VHDL Sources

VHDSOURCES=src/openvizsla_clklogic.vhd \
	   src/mt_toolbox/mt_clktools.vhd  \
	   src/mt_toolbox/mt_lfsr.vhd  \
	   src/mt_toolbox/mt_toolbox.vhd \
	   src/mt_toolbox/mt_extram_sdrctrl.vhd	\
	   src/mt_toolbox/mt_extram_test.vhd

UCF=xilsrc/ov1_fpga.ucf

# Generated Cores
CORES=fifo xmos_fifo

# Path to Xilinx tools, blank if in $PATH, must end in /
XILINX=

CORES_FILES=$(patsubst %,$(WD)/%.v,$(CORES))
SOURCES+=$(CORES_FILES)

PB=$(WD)/$(PROJECT)
PART_FULL=$(PART)-$(PART_PACKAGE)-$(PART_SPEEDGRADE)

XSTFLAGS=-opt_mode Speed -opt_level 1 -verilog2001 YES
CPLDFITFLAGS=-slew fast -power std -terminate keeper -unused float -optimize speed -init low
BITGENFLAGS=-g UnusedPin:PullDown -g UserID:0xFFFFFFFF -g DonePin:PullUp

.PHONY: all clean

all: $(PB).twr $(OUTPUT)

$(WD):
	mkdir $(WD)/


$(PB).ngc: $(SOURCES) $(VHDSOURCES)
	@[ ! -e $(WD) ] && mkdir $(WD) || true
	@echo "Generating $(PB).prj..."
	@rm -f $(PB).prj
	@for i in $(SOURCES); do \
		echo "verilog $(PROJECT) $$i" >> $(PB).prj; \
	done
	@for i in $(VHDSOURCES); do \
		echo "vhdl $(PROJECT) $$i" >> $(PB).prj; \
	done	
	@echo "DEFAULT_SEARCH_ORDER" > $(PB).lso
	@echo "set -tmpdir $(WD) -xsthdpdir $(WD)" > $(PB).xst
	@echo "run -ifn $(PB).prj -ifmt mixed -top $(PROJECT) -ofn $@ -ofmt NGC -p $(PART_FULL) $(XSTFLAGS) -lso $(PB).lso" >> $(PB).xst
	$(XILINX)xst -ifn $(PB).xst -ofn $(PB)_xst.log

$(PB).ngd: $(PB).ngc $(UCF)
	cd $(WD) ; $(XILINX)ngdbuild -p $(PART_FULL) -uc ../$(UCF) ../$< ../$@

$(PB)_map.ncd: $(PB).ngd
	cd $(WD) ; $(XILINX)map -p $(PART_FULL) -o $(PROJECT)_map.ncd $(PROJECT).ngd $(PROJECT).pcf

$(PB).ncd: $(PB)_map.ncd
	cd $(WD) ; $(XILINX)par -w -ol high -t 1 $(PROJECT)_map.ncd $(PROJECT).ncd $(PROJECT).pcf

$(PB).twr: $(PB).ncd
	cd $(WD) ; $(XILINX)trce -e 3 -s 4 -n 3 -xml $(PROJECT).twx $(PROJECT).ncd -o $(PROJECT).twr $(PROJECT).pcf -ucf $(PROJECT).ucf

$(PB).bit: $(PB).twr
	cd $(WD) ; $(XILINX)bitgen -w $(BITGENFLAGS) $(PROJECT).ncd $(PROJECT).bit

$(PB).vm6: $(PB).ngd
	cd $(WD) ; $(XILINX)cpldfit -p $(PART_FULL) ../$<

$(PB).tim: $(PB).vm6
	cd $(WD) ; $(XILINX)taengine -l ../$@ -detail -f $(PROJECT) ../$<

$(PB).jed: $(PB).vm6
	cd $(WD) ; $(XILINX)hprep6 -i ../$<
	@cp $(PB).jed $(OUTPUT)

# Don't set WD as explicit dependency
# Causes coregen.cgp to be recreated every time resulting
# in slow coregen rebuild
$(WD)/coregen.cgp:
	mkdir -p $(WD)
	@echo "SET busformat = BusFormatAngleBracketNotRipped" > $@
	@echo "SET designentry = Verilog" >> $@
	@echo "SET device = $(PART)" >> $@
	@echo "SET devicefamily = $(PART_FAMILY)" >> $@
	@echo "SET flowvendor = Other" >> $@
	@echo "SET package = $(PART_PACKAGE)" >> $@
	@echo "SET speedgrade = -$(PART_SPEEDGRADE)" >> $@
	@echo "SET verilogsim = true" >> $@
	@echo "SET vhdlsim = false" >> $@
	@echo "SET asysymbol = false" >> $@

# HACK. Coregen rewrites its input file
# and doesn't update its output file timestamp
# and, in one case, sets the output file timestamp to weird things.
# do the rm-copy-touch tango.
$(CORES_FILES): $(WD)/%.v: xilsrc/%.xco $(WD)/coregen.cgp
	rm -f $@
	mkdir -p $(WD)/xilsrc
	cp $< $(WD)/$<
	cd $(WD) ; $(XILINX)coregen -b $< -p .
	touch $(WD)/$<

$(PROJECT).svf: $(PB).bit
	@echo "Generating $(PB).cmd..."
	@echo "setmode -bscan" > $(PB).cmd
	@echo "setcable -p svf -file ../$@" >> $(PB).cmd
	@echo "addDevice -p 1 -file ../$<" >> $(PB).cmd
	@echo "erase -p 1 -o" >> $(PB).cmd
	@echo "program -p 1" >> $(PB).cmd
	@echo "quit" >> $(PB).cmd
	cd $(WD) ; $(XILINX)impact -batch $(PROJECT).cmd

#%: $(WD)/%
#	#@sed -e 's/FREQUENCY .* HZ/FREQUENCY 5E5 HZ/' $< >$@
#	@echo "Output $@ is ready"

clean:
	rm -rf $(WD) _xmsgs $(OUTPUT)
