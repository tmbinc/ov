# Script to do compilation in Actel's tools then PAR.
# Need windows Libero for bitgen
# 
# Is easy to target to other versions of ORSoC dev board:
#	for old A3P1000, 25MHz board: 
#$ make FPGA_FAMILY=ProASIC3 FPGA_PART=A3P1000 all
#
#
# Can also set following environment variables to have the correspondingly 
# affect the placer:
# PLACE_INCREMENTAL=on 
# ROUTE_INCREMENTAL=on 
# PLACER_HIGH_EFFORT=on
#
# So command above would look like:
#$ make FPGA_FAMILY=ProASIC3 FPGA_PART=A3P1000 all PLACE_INCREMENTAL=on ROUTE_INCREMENTAL=on PLACER_HIGH_EFFORT=on
#

# Name of the directory we're currently in
CUR_DIR=$(shell pwd)
DESIGN_NAME=ov2
DESIGN_TOP_NAME=ov2
BOARD_SYN_DIR=.
# The root path of the whole project
#BOARD_ROOT ?=$(CUR_DIR)/../../..
#include $(BOARD_ROOT)/Makefile.inc

VENDOR_TCL_SHELL=acttclsh

DESIGN_TOP_NAME=$(DESIGN_NAME)_top
PROJ_ADB_FILE_NAME=$(DESIGN_NAME).adb
PROJ_ADB_FILE=$(PROJ_ADB_FILE_NAME)

# Required EDIF file names
EDIF_NAME=$(DESIGN_TOP_NAME).edn
PROJ_EDF_FILE=$(BOARD_SYN_DIR)/out/$(EDIF_NAME)

# TCL script names
TCL_SCRIPT_START=start.tcl
TCL_SCRIPT_COMPILE=compile.tcl
TCL_SCRIPT_PAR=par.tcl
TCL_SCRIPT_CREATE_COMPILE_PAR=create-compile-par.tcl
TCL_SCRIPT_CREATE_COMPILE_PAR_BITGEN=create-compile-par-bitgen.tcl
TCL_SCRIPT_REPORT=report.tcl
TCL_SCRIPT_BITGEN=bitgen.tcl
# Generate these every time
.PHONY: $(TCL_SCRIPT_START) $(TCL_SCRIPT_COMPILE) $(TCL_SCRIPT_PAR) $(TCL_SCRIPT_BITGEN)


# TCL script generation parameters
# Potentially we want more here!
# All are assigned with ?= allowing them to be redfined on the command line

FPGA_FAMILY ?=Igloo
FPGA_PART ?=AGL125V5
FPGA_PACKAGE ?=\"132 QFN\"
FPGA_VOLTAGE ?=1.5
#FPGA_SPEED_GRADE ?=-2
FPGA_SPEED_GRADE ?=STD
FPGA_TEMP_RANGE=COM # either COM or IND
FPGA_VOLT_RANGE=COM # either COM or IND
COMP_DIR ?=parcomp

# Tool effort settings
# Set to 'on' to enable them
PLACE_INCREMENTAL ?= off
ROUTE_INCREMENTAL ?= off
PLACER_HIGH_EFFORT ?= off

PDC_FILE ?=$(DESIGN_NAME).pdc
SDC_FILE ?=$(DESIGN_NAME).sdc


#DEFINES_FILE_CUTOFF=$(shell grep -n "end of included module defines" $(PROJECT_VERILOG_DEFINES) | cut -d ':' -f 1)
#DESIGN_DEFINES=$(shell cat $(PROJECT_VERILOG_DEFINES) | sed s://.*::g | sed s:\`:\#:g | sed 's:^[ ]*::' | awk '{print};/^\#define/{printf "_%s=%s\n",$$2,$$2}' | grep -v PERIOD | cpp -P | sed s:^_::g | sed s:=$$::g )
# Rule to look at what defines are being extracted from main file
#print-defines:
#	@echo; echo "\t### Design defines ###"; echo
#	@echo "\tParsing "$(PROJECT_VERILOG_DEFINES)" and exporting:"
#	@echo $(DESIGN_DEFINES)

# Rule to print out current config of current session
print-config:
	@echo; echo "\t### PAR make configuration ###"; echo
	@echo "\tFPGA_FAMILY="$(FPGA_FAMILY)
	@echo "\tFPGA_PART="$(FPGA_PART)
	@echo "\tFPGA_PACKAGE="$(FPGA_PACKAGE)
	@echo "\tFPGA_VOLTAGE="$(FPGA_VOLTAGE)
	@echo "\tFPGA_SPEED_GRADE="$(FPGA_SPEED_GRADE)
	@echo "\tFPGA_TEMP_RANGE="$(FPGA_TEMP_RANGE)
	@echo "\tFPGA_VOLT_RANGE="$(FPGA_VOLT_RANGE)
	@echo "\tPLACE_INCREMENTAL="$(PLACE_INCREMENTAL)
	@echo "\tROUTE_INCREMENTAL="$(ROUTE_INCREMENTAL)
	@echo "\tPLACER_HIGH_EFFORT="$(PLACER_HIGH_EFFORT)
	@echo
	@echo "\tBackend pinout script:"
	@echo "\tBOARD_CONFIG="$(BOARD_CONFIG)

TIME_CMD=time -p

print-defines:
	@echo defines go here?

# Rule for everything from, potentially, synthesis up to PAR
all: print-config print-defines create-compile-par-bitgen

# Not possible to do programming file generation under Linux
# not with the free  tools
bitgen: $(TCL_SCRIPT_BITGEN)
	$(TIME_CMD) $(VENDOR_TCL_SHELL) $<

# Leave this with no pre-reqs so we can call it seperately
create-compile-par: sdc-file pdc-file $(PROJ_EDF_FILE) $(TCL_SCRIPT_CREATE_COMPILE_PAR)
	$(TIME_CMD) $(VENDOR_TCL_SHELL) $(TCL_SCRIPT_CREATE_COMPILE_PAR)

create-compile-par-bitgen: sdc-file pdc-file $(PROJ_EDF_FILE) $(TCL_SCRIPT_CREATE_COMPILE_PAR_BITGEN)
	$(TIME_CMD) $(VENDOR_TCL_SHELL) $(TCL_SCRIPT_CREATE_COMPILE_PAR_BITGEN)

par: $(TCL_SCRIPT_PAR)
	$(TIME_CMD) $(VENDOR_TCL_SHELL) $<

compile: $(TCL_SCRIPT_COMPILE)
	$(TIME_CMD) $(VENDOR_TCL_SHELL) $<

create: print-config print-defines sdc-file pdc-file $(PROJ_ADB_FILE)

report: $(TCL_SCRIPT_REPORT)
	$(TIME_CMD) $(VENDOR_TCL_SHELL) $<

$(PROJ_ADB_FILE): $(PROJ_EDF_FILE) $(TCL_SCRIPT_START)
	$(TIME_CMD) $(VENDOR_TCL_SHELL) $(TCL_SCRIPT_START) 

$(PROJ_EDF_FILE):
#	$(MAKE) -C $(BOARD_SYN_DIR)/run all

create-compile: create compile

clean:
	rm -rf *.rpt *.log *~ *.tcl *.lok *.tmp *.dtf $(SDC_FILE) $(PDC_FILE) *.adb

clean-syn:
	$(MAKE) -C $(BOARD_SYN_DIR)/run distclean

clean-sw:
	$(Q) echo; echo "\t### Cleaning simulation sw directories ###"; echo;
	$(MAKE) -C $(adb)/lib distclean


distclean: clean-sw clean-syn clean

STEP_NAME=$(shell echo $(TCL_FILE) | cut -d '.' -f 1)

# Rule to create the different steps of compilation with the Actel Designer 
# tool.
# We need to create dollar signs ($) to dereference variables in the TCL 
# scripts, but we also don't want make or bash thinking the variables we write
# with $s on the front are for them.. so we separate them from the actual
# variable name with ending and beginning the strings again, eg: $$""varname ..


# Just create the project
$(TCL_SCRIPT_START):
	TCL_FILE=$@ $(MAKE) tcl-common
	$(Q)echo "run_designer \"Starting new project\" \"" >> $@
	TCL_FILE=$@ $(MAKE) dump-actel-create-project-tcl
	$(Q)echo "\"">> $@
	$(Q)echo >> $@

# Open and compile the project's netlist
$(TCL_SCRIPT_COMPILE):
	TCL_FILE=$@ $(MAKE) tcl-common
	$(Q)echo "run_designer \"Compiling\" \" " >> $@
	$(Q)echo "  open_design $$""proj_name.adb " >> $@
	TCL_FILE=$@ $(MAKE) dump-actel-compile-project-tcl
	$(Q)echo "\"">> $@

# Import SDC and do place and route
$(TCL_SCRIPT_PAR):
	TCL_FILE=$@ $(MAKE) tcl-common
	$(Q)echo "run_designer \"PAR\" \" " >> $@
	$(Q)echo "  open_design $$""proj_name.adb " >> $@
	TCL_FILE=$@ $(MAKE) dump-actel-par-project-tcl
	$(Q)echo "\"">> $@

# Generate programming file
$(TCL_SCRIPT_BITGEN):
	TCL_FILE=$@ $(MAKE) tcl-common
	$(Q)echo "run_designer \"exporting PDB file\" \" " >> $@
	$(Q)echo "  open_design $$""proj_name.adb " >> $@
	TCL_FILE=$@ $(MAKE) dump-actel-bitgen-project-tcl
	$(Q)echo "\"">> $@

# Generate reports
$(TCL_SCRIPT_REPORT):
	TCL_FILE=$@ $(MAKE) tcl-common
	$(Q)echo "run_designer \"Generating timing reports\" \" " >> $@
	$(Q)echo "  open_design $$""proj_name.adb " >> $@
	TCL_FILE=$@ $(MAKE) dump-actel-report-project-tcl
	$(Q)echo "\"">> $@

# Do project creation, compile and PAR in one single run of the tool
$(TCL_SCRIPT_CREATE_COMPILE_PAR):
	TCL_FILE=$@ $(MAKE) tcl-common
	$(Q)echo "run_designer \"Create compile and PAR design project\" \" " >> $@
	TCL_FILE=$@ $(MAKE) dump-actel-create-project-tcl
	TCL_FILE=$@ $(MAKE) dump-actel-compile-project-tcl
	TCL_FILE=$@ $(MAKE) dump-actel-par-project-tcl
	$(Q)echo "\"">> $@
	$(Q)echo >> $@

# Do project creation, compile and PAR in one single run of the tool
$(TCL_SCRIPT_CREATE_COMPILE_PAR_BITGEN):
	TCL_FILE=$@ $(MAKE) tcl-common
	$(Q)echo "run_designer \"Create compile and PAR and generate programming file\" \" " >> $@
	TCL_FILE=$@ $(MAKE) dump-actel-create-project-tcl
	TCL_FILE=$@ $(MAKE) dump-actel-compile-project-tcl
	TCL_FILE=$@ $(MAKE) dump-actel-par-project-tcl
	TCL_FILE=$@ $(MAKE) dump-actel-bitgen-project-tcl
	$(Q)echo "\"">> $@
	$(Q)echo >> $@

# The different texts that we dump out for the different sets of command files

# This is the common header, setting variables in the TCL file
tcl-common:
	$(Q)rm -f $(TCL_FILE);
	$(Q)echo; echo "\tGenerating "$(TCL_FILE); echo
	$(Q)echo "set compile_directory     "$(COMP_DIR) >> $(TCL_FILE)
	$(Q)echo "set proj_name             "$(DESIGN_NAME) >> $(TCL_FILE)
	$(Q)echo "set top_name              "$(DESIGN_TOP_NAME) >> $(TCL_FILE)
	$(Q)echo "set family                "$(FPGA_FAMILY) >> $(TCL_FILE)
	$(Q)echo "set part                  "$(FPGA_PART) >> $(TCL_FILE)
	$(Q)echo "set package               "$(FPGA_PACKAGE) >> $(TCL_FILE)
	$(Q)echo "set pdc_filename          "$(PDC_FILE) >> $(TCL_FILE)
	$(Q)echo "set sdc_filename          "$(SDC_FILE) >> $(TCL_FILE)
	$(Q)echo >> $(TCL_FILE)
	$(Q)echo "  proc run_designer {message script} {" >> $(TCL_FILE)
	$(Q)echo "    puts \"Designer: $$""message\"" >> $(TCL_FILE)
	$(Q)echo "    set f [open designer.tcl w]" >> $(TCL_FILE)
	$(Q)echo "    puts $$""f $$""script" >> $(TCL_FILE)
	$(Q)echo "    close $$""f " >> $(TCL_FILE)
	$(Q)echo "    puts [exec designer SCRIPT:designer.tcl LOGFILE:"$(STEP_NAME)".log]" >> $(TCL_FILE)
	$(Q)echo "}" >> $(TCL_FILE)
	$(Q)echo >> $(TCL_FILE)

# TCL commands to create and setup a new project in Designer
dump-actel-create-project-tcl:
	$(Q)echo "  new_design " \\ >> $(TCL_FILE)
	$(Q)echo "    -name $$""proj_name " \\ >> $(TCL_FILE)
	$(Q)echo "    -family $$""family " \\ >> $(TCL_FILE)
	$(Q)echo "    -path ." >> $(TCL_FILE)
	$(Q)echo "  set_device " \\ >> $(TCL_FILE)
	$(Q)echo "    -die $$""part " \\ >> $(TCL_FILE)
	$(Q)echo "    -package \\\"$$""package\\\" " \\ >> $(TCL_FILE)
	$(Q)echo "    -speed "$(FPGA_SPEED_GRADE)" " \\ >> $(TCL_FILE)
	$(Q)echo "    -voltage "$(FPGA_VOLTAGE)" " \\ >> $(TCL_FILE)
	$(Q)echo "    -iostd LVTTL " \\ >> $(TCL_FILE)
	$(Q)echo "    -jtag yes " \\ >> $(TCL_FILE)
	$(Q)echo "    -probe yes " \\ >> $(TCL_FILE)
	$(Q)echo "    -trst yes " \\ >> $(TCL_FILE)
	$(Q)echo "    -temprange "$(FPGA_TEMP_RANGE)" "  \\ >> $(TCL_FILE)
	$(Q)echo "    -voltrange "$(FPGA_VOLT_RANGE)" "  >> $(TCL_FILE)
#	$(Q)echo "  import_source " \\ >> $(TCL_FILE)
#	$(Q)echo "    -format edif " \\ >> $(TCL_FILE)
#	$(Q)echo "    -edif_flavor GENERIC "$(PROJ_EDF_FILE)" "\\ >> $(TCL_FILE)
#	$(Q)echo "    -format pdc " \\ >> $(TCL_FILE)
#	$(Q)echo "    -abort_on_error yes $$""pdc_filename " \\ >> $(TCL_FILE)
#	$(Q)echo "    -merge_physical yes " \\ >> $(TCL_FILE)
#	$(Q)echo "    -merge_timing yes " >> $(TCL_FILE)
	$(Q)echo "  import_source " \\ >> $(TCL_FILE)
	$(Q)echo "    -format verilog top.v " >> $(TCL_FILE)
#	$(Q)echo "    -top-entity top.v "\\ >> $(TCL_FILE)
#	$(Q)echo "    -format pdc " \\ >> $(TCL_FILE)
#	$(Q)echo "    -abort_on_error yes $$""pdc_filename " \\ >> $(TCL_FILE)
#	$(Q)echo "    -merge_physical yes " \\ >> $(TCL_FILE)
#	$(Q)echo "    -merge_timing yes " >> $(TCL_FILE)
	$(Q)echo "  save_design $$""proj_name.adb " >> $(TCL_FILE)

# TCL commands to compile a project in Designer
dump-actel-compile-project-tcl:
	$(Q)echo "  compile " \\ >> $(TCL_FILE)
	$(Q)echo "    -pdc_abort_on_error on " \\ >> $(TCL_FILE)
	$(Q)echo "    -pdc_eco_display_unmatched_objects off " \\ >> $(TCL_FILE)
	$(Q)echo "    -pdc_eco_max_warnings 10000 " \\ >> $(TCL_FILE)
	$(Q)echo "    -demote_globals off " \\ >> $(TCL_FILE)
	$(Q)echo "    -demote_globals_max_fanout 12 " \\ >> $(TCL_FILE)
	$(Q)echo "    -promote_globals off " \\ >> $(TCL_FILE)
	$(Q)echo "    -promote_globals_min_fanout 200 " \\ >> $(TCL_FILE)
	$(Q)echo "    -promote_globals_max_limit 0 " \\ >> $(TCL_FILE)
	$(Q)echo "    -localclock_max_shared_instances 12 " \\ >> $(TCL_FILE)
	$(Q)echo "    -localclock_buffer_tree_max_fanout 12 " \\ >> $(TCL_FILE)
	$(Q)echo "    -combine_register off " \\ >> $(TCL_FILE)
	$(Q)echo "    -delete_buffer_tree off " \\ >> $(TCL_FILE)
	$(Q)echo "    -delete_buffer_tree_max_fanout 12 " \\ >> $(TCL_FILE)
	$(Q)echo "    -report_high_fanout_nets_limit 10 " >> $(TCL_FILE)
	$(Q)echo "  save_design $$""proj_name.adb " >> $(TCL_FILE)

# TCL commands to ipmort SDC and do PAR on project
dump-actel-par-project-tcl:
	$(Q)echo "  import_aux " \\ >> $(TCL_FILE)
	$(Q)echo "    -format sdc $$""sdc_filename     " >> $(TCL_FILE)
	$(Q)echo "  layout " \\ >> $(TCL_FILE)
	$(Q)echo "    -timing_driven " \\ >> $(TCL_FILE)
	$(Q)echo "    -run_placer on " \\ >> $(TCL_FILE)
	$(Q)echo "    -place_incremental "$(PLACE_INCREMENTAL) \\ >> $(TCL_FILE)
	$(Q)echo "    -run_router on " \\ >> $(TCL_FILE)
	$(Q)echo "    -route_incremental "$(ROUTE_INCREMENTAL) \\ >> $(TCL_FILE)
	$(Q)echo "    -placer_high_effort "$(PLACER_HIGH_EFFORT) >> $(TCL_FILE)
	$(Q)echo "  save_design $$""proj_name.adb " >> $(TCL_FILE)

# TCL commands to generate programming file (PDB) from project
dump-actel-bitgen-project-tcl:
	$(Q)echo "  export " \\ >> $(TCL_FILE)
	$(Q)echo "    -format pdb " \\ >> $(TCL_FILE)
	$(Q)echo "    -feature prog_fpga " \\ >> $(TCL_FILE)
	$(Q)echo "    $$""proj_name.pdb " >> $(TCL_FILE)
	$(Q)echo "  save_design $$""proj_name.adb " >> $(TCL_FILE)

# TCL commands to generate timing reports of project
dump-actel-report-project-tcl:
	$(Q)echo "  report " \\ >> $(TCL_FILE)
	$(Q)echo "  -type timer " \\ >> $(TCL_FILE)
	$(Q)echo "  -analysis max " \\ >> $(TCL_FILE)
	$(Q)echo "  -print_summary yes " \\ >> $(TCL_FILE)
	$(Q)echo "  -use_slack_threshold no " \\ >> $(TCL_FILE)
	$(Q)echo "  -print_paths yes " \\ >> $(TCL_FILE)
	$(Q)echo "  -max_paths 5 " \\ >> $(TCL_FILE)
	$(Q)echo "  -max_expanded_paths 1 " \\ >> $(TCL_FILE)
	$(Q)echo "  -include_user_sets no " \\ >> $(TCL_FILE)
	$(Q)echo "  -include_pin_to_pin yes " \\ >> $(TCL_FILE)
	$(Q)echo "  -select_clock_domains no " \\ >> $(TCL_FILE)
	$(Q)echo "   "$(DESIGN_NAME)"-timing.rpt " >> $(TCL_FILE)
	$(Q)echo "  report " \\ >> $(TCL_FILE)
	$(Q)echo "  -type timing_violations " \\ >> $(TCL_FILE)
	$(Q)echo "  -analysis max " \\ >> $(TCL_FILE)
	$(Q)echo "  -use_slack_threshold no " \\ >> $(TCL_FILE)
	$(Q)echo "  -limit_max_paths yes " \\ >> $(TCL_FILE)
	$(Q)echo "  -max_paths 100 " \\ >> $(TCL_FILE)
	$(Q)echo "  -max_expanded_paths 0 " \\ >> $(TCL_FILE)
	$(Q)echo "   "$(DESIGN_NAME)"-timviol.rpt " >> $(TCL_FILE)
	$(Q)echo "  report " \\ >> $(TCL_FILE)
	$(Q)echo "  -type timing_violations " \\ >> $(TCL_FILE)
	$(Q)echo "  -analysis min " \\ >> $(TCL_FILE)
	$(Q)echo "  -use_slack_threshold no " \\ >> $(TCL_FILE)
	$(Q)echo "  -limit_max_paths yes " \\ >> $(TCL_FILE)
	$(Q)echo "  -max_paths 100 " \\ >> $(TCL_FILE)
	$(Q)echo "  -max_expanded_paths 0 " \\ >> $(TCL_FILE)
	$(Q)echo "  "$(DESIGN_NAME)"-timmindly.rpt " >> $(TCL_FILE)



sdc-file:
	$(Q)for define in $(DESIGN_DEFINES); do export $$define=1; done; \
	$(MAKE) $(SDC_FILE)


#
# Constraint script generation
#

ETH_CLK_PERIOD_NS ?= 8.0000 # 125 MHz
ETH_CLK_PERIOD_HALF_NS ?= 4.0000 # 125 MHz
SDRAM_OUT_DELAY ?=1.5
SDRAM_IN_DELAY ?=0.8
# Whittle away at the defines until we have only the Wishbone frequency (MHz) integer
WB_FREQ_MHZ ?=$(shell echo $(DESIGN_DEFINES) | tr " " "\n" | grep BOARD | grep _WB | tr "_" "\n" | grep WB | cut -d 'B' -f 2)
XTAL_FREQ_MHZ ?=$(shell echo $(DESIGN_DEFINES) | tr " " "\n" | grep BOARD | grep _XTAL | tr "_" "\n" | grep XTAL | cut -d 'L' -f 2)

ifeq ($(XTAL_FREQ_MHZ), 64)
SYS_CLK_PERIOD_NS ?= 15.625 # 64 MHz
# These are for board clock with 64 MHz XTAL
ifeq ($(WB_FREQ_MHZ), 16)
WB_SDC_GENCLK_DIVIDE_BY ?=144
WB_SDC_GENCLK_MULTIPLY_BY ?=36
endif
ifeq ($(WB_FREQ_MHZ), 18)
WB_SDC_GENCLK_DIVIDE_BY ?=128
WB_SDC_GENCLK_MULTIPLY_BY ?=36
endif
ifeq ($(WB_FREQ_MHZ), 20)
WB_SDC_GENCLK_DIVIDE_BY ?=144
WB_SDC_GENCLK_MULTIPLY_BY ?=45
endif
endif # ifeq ($(XTAL_FREQ_MHZ), 64)

ifeq ($(XTAL_FREQ_MHZ), 25)
SYS_CLK_PERIOD_NS ?= 40.00 # 25 MHz
# These are for board with 25 MHz XTAL
ifeq ($(WB_FREQ_MHZ), 20)
WB_SDC_GENCLK_DIVIDE_BY ?=125
WB_SDC_GENCLK_MULTIPLY_BY ?=100
endif
ifeq ($(WB_FREQ_MHZ), 24)
WB_SDC_GENCLK_DIVIDE_BY ?=125
WB_SDC_GENCLK_MULTIPLY_BY ?=120
endif
endif # ifeq ($(XTAL_FREQ_MHZ), 25)

print-freq:
	$(Q)echo "XTAL Freq: "$(XTAL_FREQ_MHZ)"MHz"
	$(Q)echo "sys_clk_pad_i period: "$(SYS_CLK_PERIOD_NS)"ns"
	$(Q)echo "Multiply XTAL by "$(WB_SDC_GENCLK_MULTIPLY_BY)" and divide by "$(WB_SDC_GENCLK_DIVIDE_BY)" to get WB frequency"
	$(Q)echo "WB Freq: "$(WB_FREQ_MHZ)"MHz"


#
# Timing (SDC)
#
$(SDC_FILE):
	$(Q)echo; echo "\t### Generating SDC file ###"; echo
	$(Q)rm -f $@
	$(Q) echo "set sdc_version 1.7" >> $@
	$(Q) echo "########  Clock Constraints  ########" >> $@
	$(Q) echo "create_clock  -name { sys_clk_pad_i } -period "$(SYS_CLK_PERIOD_NS)"  { sys_clk_pad_i  } " >> $@
	$(Q)if [ ! -z $$JTAG_DEBUG ]; then \
		echo "create_clock  -name { tck_pad_i } -period 50.000  { tck_pad_i  } " >> $@; \
	fi
	$(Q)if [ ! -z $$ETH_CLK ]; then \
		echo "create_clock  -name { eth_clk_pad_i } -period "$(ETH_CLK_PERIOD_NS)" { eth_clk_pad_i  } " >> $@; \
	fi
	$(Q)if [ ! -z $$SMII0 ]; then \
		echo "create_clock  -name { smii0/smii_if0/mtx_clk_gen:Q } -period 40.000   { smii0/smii_if0/mtx_clk_gen:Q  } " >> $@; \
		echo "create_clock  -name { smii0/smii_if0/mrx_clk_gen:Q } -period 40.000  { smii0/smii_if0/mrx_clk_gen:Q  } " >> $@; \
		echo "set_output_delay  -max 3.000 -clock { eth_clk_pad_i }  [get_ports { eth0_smii_sync_pad_o eth0_smii_tx_pad_o }] " >> $@; \
		echo "set_output_delay  -min -1.500 -clock { eth_clk_pad_i }  [get_ports { eth0_smii_sync_pad_o eth0_smii_tx_pad_o }] " >> $@; \
	fi
	$(Q) echo "########  Specify Asynchronous paths between domains  ########" >> $@
	$(Q) echo "set_false_path -from [ get_clocks { clkgen0/pll0/Core:GLA }] -to [ get_clocks { clkgen0/pll0/Core:GLB }]" >> $@
	$(Q) echo "set_false_path -from [ get_clocks { clkgen0/pll0/Core:GLB }] -to [ get_clocks { clkgen0/pll0/Core:GLA }]" >> $@
	$(Q) echo "########  Input Delay Constraints  ########" >> $@
	$(Q) echo "set_input_delay  -max "$(SDRAM_IN_DELAY)" -clock { clkgen0/pll0/Core:GLA } { sdram_dq_pad_io[*] }" >> $@
	$(Q) echo "########  Output Delay Constraints  ########" >> $@
	$(Q) echo "set_output_delay  -max  "$(SDRAM_OUT_DELAY)"  -clock { clkgen0/pll0/Core:GLA } { sdram_dq_pad_io[*] }" >> $@
	$(Q) echo "set_output_delay  -max  "$(SDRAM_OUT_DELAY)"  -clock { clkgen0/pll0/Core:GLA } { sdram_ras_pad_o }" >> $@
	$(Q) echo "set_output_delay  -max  "$(SDRAM_OUT_DELAY)"  -clock { clkgen0/pll0/Core:GLA } { sdram_cas_pad_o }" >> $@
	$(Q) echo "set_output_delay  -max  "$(SDRAM_OUT_DELAY)"  -clock { clkgen0/pll0/Core:GLA } { sdram_we_pad_o }" >> $@
	$(Q) echo "set_output_delay  -max  "$(SDRAM_OUT_DELAY)"  -clock { clkgen0/pll0/Core:GLA } { sdram_a_pad_o[*] }" >> $@
	$(Q) echo "set_output_delay  -max  "$(SDRAM_OUT_DELAY)"  -clock { clkgen0/pll0/Core:GLA } { sdram_ba_pad_o[*] }" >> $@
	$(Q) echo "set_output_delay  -max  "$(SDRAM_OUT_DELAY)"  -clock { clkgen0/pll0/Core:GLA } { sdram_cke_pad_o }" >> $@
	$(Q) echo "set_output_delay  -max  "$(SDRAM_OUT_DELAY)"  -clock { clkgen0/pll0/Core:GLA } { sdram_dqm_pad_o[*] }" >> $@
	$(Q)echo >> $@

#	$(Q) echo "########  Generated Clock Constraints  ########" >> $@
#	$(Q) echo "create_generated_clock  -name { clkgen0/pll0/Core:GLA } -divide_by 36  -multiply_by 36  -source { clkgen0/pll0/Core:CLKA } { clkgen0/pll0/Core:GLA  } " >> $@
#	$(Q) echo "create_generated_clock  -name { clkgen0/pll0/Core:GLB } -divide_by "$(WB_SDC_GENCLK_DIVIDE_BY)"  -multiply_by "$(WB_SDC_GENCLK_MULTIPLY_BY)"  -source { clkgen0/pll0/Core:CLKA } { clkgen0/pll0/Core:GLB  } " >> $@

#
# Physical design constraints
#

# Pin settings, based on CPU board
PDC_MKPINS_PATH ?=.
PDC_MKPINASSIGNS_PATH ?=.

# Default board config
BOARD_CONFIG ?= ov2.mkpinassigns

include $(PDC_MKPINASSIGNS_PATH)/$(BOARD_CONFIG)

# PDC file generation - depending on Verilog defines file, we generate right PDC

pdc-file:
	$(Q)for define in $(DESIGN_DEFINES); do export $$define=1; done; \
	$(MAKE) $(PDC_FILE)

# To do - somehow figure out the top-level signals in the design, and then 
# auto-generate this rule....?!
$(PDC_FILE): $(PROJECT_VERILOG_DEFINES)
	$(Q)echo; echo "\t### Generating PDC file ###"; echo
	$(Q)touch $@
	$(Q)echo "#" >> $@
	$(Q)echo "# IO banks setting" >> $@
	$(Q)echo "#" >> $@
	$(Q)echo "" >> $@
	$(Q)echo "set_iobank Bank1 -vcci 3.30 -fixed no" >> $@
	$(Q)echo "set_iobank Bank0 -vcci 3.30 -fixed no" >> $@
	$(Q)echo "" >> $@
	$(Q)echo "#" >> $@
	$(Q)echo "# I/O constraints" >> $@
	$(Q)echo "#" >> $@
	$(Q)echo "" >> $@
#	$(Q)echo "set_io rst_n_pad_i "$(RST_BUS_SETTING) " -pinname "$(RST_PIN) >> $@
#	$(Q)echo "set_io sys_clk_pad_i "$(CLK_BUS_SETTING) " -pinname "$(CLK_PIN) >> $@
	$(Q)echo "set_io targetULPI_D\\[0\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(targetULPI_D0) >> $@
	$(Q)echo "set_io targetULPI_D\\[1\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(targetULPI_D1) >> $@
	$(Q)echo "set_io targetULPI_D\\[2\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(targetULPI_D2) >> $@
	$(Q)echo "set_io targetULPI_D\\[3\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(targetULPI_D3) >> $@
	$(Q)echo "set_io targetULPI_D\\[4\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(targetULPI_D4) >> $@
	$(Q)echo "set_io targetULPI_D\\[5\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(targetULPI_D5) >> $@
	$(Q)echo "set_io targetULPI_D\\[6\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(targetULPI_D6) >> $@
	$(Q)echo "set_io targetULPI_D\\[7\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(targetULPI_D7) >> $@

	$(Q)echo "set_io targetULPI_NXT " $(GPIO_BUS_SETTINGS) "  -pinname "$(targetULPI_NXT) >> $@
	$(Q)echo "set_io targetULPI_DIR " $(GPIO_BUS_SETTINGS) "  -pinname "$(targetULPI_DIR) >> $@
	$(Q)echo "set_io targetULPI_STP " $(GPIO_BUS_SETTINGS) "  -pinname "$(targetULPI_STP) >> $@
	$(Q)echo "set_io targetULPI_CLK " $(GPIO_BUS_SETTINGS) "  -pinname "$(targetULPI_CLK) >> $@

	$(Q)echo "set_io ram_ba0 "$(SDRAM_CTRL_BUS_SETTINGS)" -pinname "$(RAM_BA0) >> $@
	$(Q)echo "set_io ram_ba1 "$(SDRAM_CTRL_BUS_SETTINGS)" -pinname "$(RAM_BA1) >> $@
	$(Q)echo "set_io ram_cas "$(SDRAM_CTRL_BUS_SETTINGS)" -pinname "$(RAM_CAS) >> $@
	$(Q)echo "set_io ram_clk "$(SDRAM_CTRL_BUS_SETTINGS)" -pinname "$(RAM_CLK) >> $@
	$(Q)echo "set_io ram_cs0 "$(SDRAM_CTRL_BUS_SETTINGS)" -pinname "$(RAM_CS0) >> $@
	$(Q)echo "set_io ram_dqmh "$(SDRAM_CTRL_BUS_SETTINGS)" -pinname "$(RAM_DQMH) >> $@
	$(Q)echo "set_io ram_dqml "$(SDRAM_CTRL_BUS_SETTINGS)" -pinname "$(RAM_DQML) >> $@
	$(Q)echo "set_io ram_ras "$(SDRAM_CTRL_BUS_SETTINGS)" -pinname "$(RAM_RAS) >> $@
	$(Q)echo "set_io ram_we "$(SDRAM_CTRL_BUS_SETTINGS)" -pinname "$(RAM_WE) >> $@

	$(Q)echo "set_io ram_d\[0\\] " $(SDRAM_DATA_BUS_SETTINGS)" -pinname "$(RAM_D0) >> $@
	$(Q)echo "set_io ram_d\[1\\] " $(SDRAM_DATA_BUS_SETTINGS)" -pinname "$(RAM_D1) >> $@
	$(Q)echo "set_io ram_d\[2\\] " $(SDRAM_DATA_BUS_SETTINGS)" -pinname "$(RAM_D2) >> $@
	$(Q)echo "set_io ram_d\[3\\] " $(SDRAM_DATA_BUS_SETTINGS)" -pinname "$(RAM_D3) >> $@
	$(Q)echo "set_io ram_d\[4\\] " $(SDRAM_DATA_BUS_SETTINGS)" -pinname "$(RAM_D4) >> $@
	$(Q)echo "set_io ram_d\[5\\] " $(SDRAM_DATA_BUS_SETTINGS)" -pinname "$(RAM_D5) >> $@
	$(Q)echo "set_io ram_d\[6\\] " $(SDRAM_DATA_BUS_SETTINGS)" -pinname "$(RAM_D6) >> $@
	$(Q)echo "set_io ram_d\[7\\] " $(SDRAM_DATA_BUS_SETTINGS)" -pinname "$(RAM_D7) >> $@
	$(Q)echo "set_io ram_d\[8\\] " $(SDRAM_DATA_BUS_SETTINGS)" -pinname "$(RAM_D8) >> $@
	$(Q)echo "set_io ram_d\[9\\] " $(SDRAM_DATA_BUS_SETTINGS)" -pinname "$(RAM_D9) >> $@
	$(Q)echo "set_io ram_d\[10\\] " $(SDRAM_DATA_BUS_SETTINGS)" -pinname "$(RAM_D10) >> $@
	$(Q)echo "set_io ram_d\[11\\] " $(SDRAM_DATA_BUS_SETTINGS)" -pinname "$(RAM_D11) >> $@
	$(Q)echo "set_io ram_d\[12\\] " $(SDRAM_DATA_BUS_SETTINGS)" -pinname "$(RAM_D12) >> $@
	$(Q)echo "set_io ram_d\[13\\] " $(SDRAM_DATA_BUS_SETTINGS)" -pinname "$(RAM_D13) >> $@
	$(Q)echo "set_io ram_d\[14\\] " $(SDRAM_DATA_BUS_SETTINGS)" -pinname "$(RAM_D14) >> $@
	$(Q)echo "set_io ram_d\[15\\] " $(SDRAM_DATA_BUS_SETTINGS)" -pinname "$(RAM_D15) >> $@

	$(Q)echo "set_io ram_a\\[0\\] "$(SDRAM_CTRL_BUS_SETTINGS)" -pinname "$(RAM_A0) >> $@
	$(Q)echo "set_io ram_a\\[1\\] "$(SDRAM_CTRL_BUS_SETTINGS)" -pinname "$(RAM_A1) >> $@
	$(Q)echo "set_io ram_a\\[2\\] "$(SDRAM_CTRL_BUS_SETTINGS)" -pinname "$(RAM_A2) >> $@
	$(Q)echo "set_io ram_a\\[3\\] "$(SDRAM_CTRL_BUS_SETTINGS)" -pinname "$(RAM_A3) >> $@
	$(Q)echo "set_io ram_a\\[4\\] "$(SDRAM_CTRL_BUS_SETTINGS)" -pinname "$(RAM_A4) >> $@
	$(Q)echo "set_io ram_a\\[5\\] "$(SDRAM_CTRL_BUS_SETTINGS)" -pinname "$(RAM_A5) >> $@
	$(Q)echo "set_io ram_a\\[6\\] "$(SDRAM_CTRL_BUS_SETTINGS)" -pinname "$(RAM_A6) >> $@
	$(Q)echo "set_io ram_a\\[7\\] "$(SDRAM_CTRL_BUS_SETTINGS)" -pinname "$(RAM_A7) >> $@
	$(Q)echo "set_io ram_a\\[8\\] "$(SDRAM_CTRL_BUS_SETTINGS)" -pinname "$(RAM_A8) >> $@
	$(Q)echo "set_io ram_a\\[9\\] "$(SDRAM_CTRL_BUS_SETTINGS)" -pinname "$(RAM_A9) >> $@
	$(Q)echo "set_io ram_a\\[10\\] "$(SDRAM_CTRL_BUS_SETTINGS)" -pinname "$(RAM_A10) >> $@
	$(Q)echo "set_io ram_a\\[11\\] "$(SDRAM_CTRL_BUS_SETTINGS)" -pinname "$(RAM_A11) >> $@

	$(Q)echo "set_io F1 " $(GPIO_BUS_SETTINGS) "  -pinname "$(F1) >> $@
	$(Q)echo "set_io F2 " $(GPIO_BUS_SETTINGS) "  -pinname "$(F2) >> $@
	$(Q)echo "set_io F3 " $(GPIO_BUS_SETTINGS) "  -pinname "$(F3) >> $@
	$(Q)echo "set_io F4 " $(GPIO_BUS_SETTINGS) "  -pinname "$(F4) >> $@
	$(Q)echo "set_io F5 " $(GPIO_BUS_SETTINGS) "  -pinname "$(F5) >> $@
	$(Q)echo "set_io F6 " $(GPIO_BUS_SETTINGS) "  -pinname "$(F6) >> $@
	$(Q)echo "set_io F7 " $(GPIO_BUS_SETTINGS) "  -pinname "$(F7) >> $@
	$(Q)echo "set_io F8 " $(GPIO_BUS_SETTINGS) "  -pinname "$(F8) >> $@
	$(Q)echo "set_io F9 " $(GPIO_BUS_SETTINGS) "  -pinname "$(F9) >> $@
	$(Q)echo "set_io F10 " $(GPIO_BUS_SETTINGS) "  -pinname "$(F10) >> $@

	$(Q)echo "set_io FPGA1 " $(GPIO_BUS_SETTINGS) "  -pinname "$(FPGA1) >> $@
	$(Q)echo "set_io FINT " $(GPIO_BUS_SETTINGS) "  -pinname "$(FINT) >> $@

	$(Q)echo "set_io P\\[0\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(P0) >> $@
	$(Q)echo "set_io P\\[1\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(P1) >> $@
	$(Q)echo "set_io P\\[2\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(P2) >> $@
	$(Q)echo "set_io P\\[3\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(P3) >> $@
	$(Q)echo "set_io P\\[4\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(P4) >> $@
	$(Q)echo "set_io P\\[5\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(P5) >> $@
	$(Q)echo "set_io P\\[6\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(P6) >> $@
	$(Q)echo "set_io P\\[7\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(P7) >> $@

	$(Q)echo "set_io XLAout\\[0\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(XLAout0) >> $@
	$(Q)echo "set_io XLAout\\[1\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(XLAout1) >> $@
	$(Q)echo "set_io XLAout\\[2\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(XLAout2) >> $@
	$(Q)echo "set_io XLAout\\[3\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(XLAout3) >> $@
	$(Q)echo "set_io XLAout\\[4\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(XLAout4) >> $@
	$(Q)echo "set_io XLAin\\[0\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(XLAin0) >> $@
	$(Q)echo "set_io XLAin\\[1\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(XLAin1) >> $@
	$(Q)echo "set_io XLAin\\[2\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(XLAin2) >> $@
	$(Q)echo "set_io XLAin\\[3\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(XLAin3) >> $@
	$(Q)echo "set_io XLAin\\[4\\] " $(GPIO_BUS_SETTINGS) "  -pinname "$(XLAin4) >> $@

	$(Q)echo "" >> $@
