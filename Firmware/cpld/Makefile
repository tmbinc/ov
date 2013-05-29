# Project name
PROJECT=ov1_cpld
# Part number
PART=XC9572XL-5-TQ100
# Output configuration file
OUTPUT=$(PROJECT).svf
# Verilog sources
SOURCES=ov1_cpld.v
# Constraints file
UCF=$(PROJECT).ucf

# Path to Xilinx tools, blank if in $PATH, must end in /
XILINX=

WD=work
PB=$(WD)/$(PROJECT)

XSTFLAGS=-opt_mode Speed -opt_level 1 -verilog2001 YES
CPLDFITFLAGS=-slew fast -power std -terminate keeper -unused float -optimize speed -init low

.PHONY: all clean

all: $(PB).tim $(OUTPUT)

$(WD):
	mkdir $(WD)/

$(PB).ngc: $(SOURCES)
	@[ ! -e $(WD) ] && mkdir $(WD) || true
	@echo "Generating $(PB).prj..."
	@rm -f $(PB).prj
	@for i in $(SOURCES); do \
		echo "verilog $(PROJECT) $$i" >> $(PB).prj; \
	done
	@echo "DEFAULT_SEARCH_ORDER" > $(PB).lso
	@echo "set -tmpdir $(WD) -xsthdpdir $(WD)" > $(PB).xst
	@echo "run -ifn $(PB).prj -ifmt mixed -top $(PROJECT) -ofn $@ -ofmt NGC -p $(PART) $(XSTFLAGS) -lso $(PB).lso" >> $(PB).xst
	$(XILINX)xst -ifn $(PB).xst -ofn $(PB)_xst.log

$(PB).ngd: $(PB).ngc $(UCF)
	cd $(WD) ; $(XILINX)ngdbuild -p $(PART) -uc ../$(UCF) ../$< ../$@

$(PB).vm6: $(PB).ngd
	cd $(WD) ; $(XILINX)cpldfit -p $(PART) ../$<

$(PB).tim: $(PB).vm6
	cd $(WD) ; $(XILINX)taengine -l ../$@ -detail -f $(PROJECT) ../$<

$(PB).jed: $(PB).vm6
	cd $(WD) ; $(XILINX)hprep6 -i ../$<
	@cp $(PB).jed $(OUTPUT)

$(PB).svf: $(PB).jed
	@echo "Generating $(PB).cmd..."
	@echo "setmode -bscan" > $(PB).cmd
	@echo "setcable -p svf -file ../$@" >> $(PB).cmd
	@echo "addDevice -p 1 -file ../$<" >> $(PB).cmd
	@echo "erase -p 1 -o" >> $(PB).cmd
	@echo "program -p 1" >> $(PB).cmd
	@echo "quit" >> $(PB).cmd
	cd $(WD) ; $(XILINX)impact -batch $(PROJECT).cmd

%: $(WD)/%
	@sed -e 's/FREQUENCY .* HZ/FREQUENCY 5E5 HZ/' $< >$@
	@echo "Output $@ is ready"

clean:
	rm -rf $(WD) $(OUTPUT)
