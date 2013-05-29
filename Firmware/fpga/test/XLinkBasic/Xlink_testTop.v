/*
 * The copyrights, all other intellectual and industrial
 * property rights are retained by XMOS and/or its licensors.
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2008
 */
 
 /*
  * XLinkTop - Top level module of Xlink
  *
  */
  
`include "SwitchCommonDef.v"

module XLinkTestTop( clk, reset, tx_0, tx_1, rx_0, rx_1, led0, led1, led2);//, led3, led4 );


input clk;
input reset;

output tx_0;
output tx_1;

wire tx_0;
wire tx_1;

input rx_0;
input rx_1;


wire reset, clk;

output led0;
output led1;
output led2;


/* Standard data bus decl */
wire [30:0] addr_bus;
wire [31:0] data_bus_wr;
wire [31:0] data_bus_rd;
wire wr_strobe;
wire rd_strobe;

XLinkToAddrBus xl2ab (
	clk,
	reset,
	tx_0,
	tx_1,
	rx_0,
	rx_1,

	addr_bus,
	data_bus_wr,
	data_bus_rd,
	wr_strobe,
	rd_strobe
	);

wire [31:0] leds_module_dout;


led_module leds (
	.clk(clk),
	.reset(reset),
	.addr_bus(addr_bus),
	.data_bus_wr(data_bus_wr),
	.data_bus_rd(leds_module_dout),
	.wr_strobe(wr_strobe),
	.rd_strobe(rd_strobe),

	.leds({led2, led1, led0})
	);

assign data_bus_rd = leds_module_dout;
endmodule

