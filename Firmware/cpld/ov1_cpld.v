/*
 * DIP0: CPLD Enable (GTS2)
 * DIP1: FPGA Power
 * DIP2: FPGA Boot mode (off: JTAG, on: slave serial)
 * DIP3: XBOOTMODE
 * DIP4: JTAG Enable
 * DIP5: JTAG Select
 * DIP6: Serial Select
 * DIP7: CPLD TMS
 */

module ov1_cpld (
	/*input clk13m,*/
	input [6:0] dipsw,
	/*input [2:0] button,*/
	/* CRITICAL: don't touch the following line. Making some inputs outputs will brick the board */
	input ftdi_tdi, output ftdi_tdo, input ftdi_tms, input ftdi_tck, input ftdi_trst,
	/* -- */
	output fpga_tdi, input fpga_tdo, output fpga_tms, output fpga_tck,
	output xcore_tdi, input xcore_tdo, output xcore_tms, output xcore_tck, inout xcore_trst,
	output old_xcore_trst,
	input ftdi_tx, output ftdi_rx,
	input xcore0_tx, output xcore0_rx,
	input xcore1_tx, output xcore1_rx,
	input xsys_tx, output xsys_rx,
	input ftdi_reset,
	output xcore_reset,
	output [2:0] fpga_m,
	output fpga_ven,
	output xbootmode
	/*input [1:0] x0_aux,*/
	/*input [2:0] x1_aux,*/
	/*inout current_sda, output current_scl,*/
	/*input spi_clk, input spi_cs, input spi_mosi, output spi_miso,*/
	/*output lcd_clk, output lcd_cs, output lcd_din, output lcd_cd, output lcd_rst,*/
	/*output [10:0] lcd_led,*/
	/*input [3:0] extra,*/
);

/* Global tristate */
wire tris;

function zz;
	input v;
	begin
		if (tris)
			zz = 1'bz;
		else
			zz = v;
	end
endfunction

/* NOTE: don't pass z values around to zz(). Use zzz() if you need a tristate driver. */
/* The Xilinx tools are broken and can't handle it... */
function zzz;
	input drive,v;
	begin
		if (tris || !drive)
			zzz = 1'bz;
		else
			zzz = v;
	end
endfunction

/* Invert buttons, DIPs */
wire [6:0] dipsw_t = ~dipsw;
/*wire ]2:0] button_t = ~button;*/

/* If DIP 0 is OFF, disable outputs */
assign tris = !dipsw_t[0];

/* CRITICAL: ftdi_tdo must be zz'ed, or you brick the board */
wire ftdi_tdo_safe;
assign ftdi_tdo = zz(ftdi_tdo_safe);

/* FPGA power */
/* NOTE: don't tristate this, it doesn't have a pull-down. Pull low when CPLD disabled. */
assign fpga_ven = !tris && dipsw_t[1];

/* FPGA mode */
assign fpga_m[0] = zzz(fpga_ven, 1'b1);
assign fpga_m[1] = zzz(fpga_ven, dipsw_t[2]);
assign fpga_m[2] = zzz(fpga_ven, 1'b1);

/* XMOS bootmode */
assign xbootmode = dipsw_t[3] && xcore_trst;

/* JTAG switch */
wire jtagen = dipsw_t[4];
wire jtagsel = dipsw_t[5];
wire jtag_fpga = jtagen && jtagsel;
wire jtag_xcore = jtagen && !jtagsel;

assign fpga_tdi = zzz((jtag_fpga && fpga_ven), ftdi_tdi);
assign fpga_tms = zzz((jtag_fpga && fpga_ven), ftdi_tms);
assign fpga_tck = zzz((jtag_fpga && fpga_ven), ftdi_tck);

assign xcore_tdi = zzz(jtag_xcore, ftdi_tdi);
assign xcore_tms = zzz(jtag_xcore, ftdi_tms);
assign xcore_tck = zzz(jtag_xcore, ftdi_tck);

/* used to be XSYS input only, but no longer */
assign xcore_trst = zzz((jtag_xcore && !ftdi_trst), 1'b0);
/* legacy for old board revs, disconnected in newer ones */
assign old_xcore_trst = zzz(jtag_xcore ? !ftdi_trst : !xcore_trst, 1'b0);

assign ftdi_tdo_safe = jtag_fpga ? fpga_tdo : (jtag_xcore : xcore_tdo : 1'b0);

assign xcore_reset = zzz((jtag_xcore && !ftdi_reset), 1'b0);

/* Serial switch */
wire serialsel = dipsw_t[6];

assign ftdi_rx = zz(serialsel ? xcore1_tx : xcore0_tx);
assign xsys_rx = zz(serialsel ? xcore0_tx : xcore1_tx);
assign xcore0_rx = zz(serialsel ? xsys_tx : ftdi_tx);
assign xcore1_rx = zz(serialsel ? ftdi_tx : xsys_tx);

endmodule
