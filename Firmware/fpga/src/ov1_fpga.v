`timescale 1ns / 1ps

module ov1_fpga(
		input [5:0] BANK0IP,
		input [7:0] BANK1IP,
		input [6:0] BANK3IP,
		input [19:0] BANK0IO,
		input [31:0] PONY_IO,
		input [2:0] M,
		inout [7:0] D,
		input BUSY_DOUT,
		output MOSI_CSI_B,
		inout X1_AUXCLK,
		output [2:0] FLED,
		output CCLK,
		input OSC_13MHZ_R,
		inout [4:0] XLBIN,
		inout [4:0] XLBOUT,
		inout [4:0] XLAIN,
		inout [4:0] XLAOUT,
		inout [3:0] ULPI_D,
		input ULPI_DIR,
		input ULPI_CLK,
		output ULPI_STP,
		input ULPI_NXT,
		output CLOCK_192,
		output TARGETPHY_RST,
		input TARGETD_P,
		input TARGETD_N,

		output [12:0] SD_A,
		inout [15:0] SD_DQ,
		output SD_WE,
		output SD_CLK,
		output SD_CAS,
		output [1:0] SD_DQM,
		output SD_RAS,
		output SD_CS,
		output [1:0] SD_BA
	);

	//
	// Clocking
	//
	wire clk13;     // 13 MHz clock (buffered from input clock)
	wire clk_sdram; // 91 MHz SDRAM clock
	wire clk26;     // 26 MHz clock (2x input clock)
	wire rst;

	//
	// Generate ulpi_clk and ulpi_clkn by taking the external
	// clock input. Inversion of ULPI_CLK (for ulpi_clkn) is okay
	// because it's used in IDDR2s and ODDR2s which can use 
	// an inverted clock.
	//

	wire ulpi_clk, ulpi_clkn;
	assign ulpi_clk = ULPI_CLK;
	assign ulpi_clkn = ~ULPI_CLK;
	
	//
	// Generate 19.2 MHz and SDRAM clock using DCMs.
	//

	clkgen clkgen_inst (
		 .CLOCK_13(OSC_13MHZ_R), 
		 .CLOCK_26(clk26), 
		 .CLOCK_192(CLOCK_192), 
		 .CLOCK_13_BUF(clk13), 
		 .CLOCK_SDRAM(clk_sdram),
		 .RST(rst), 
		 .LOCKED(LOCKED)
		 );


	//
	// Implicit reset for the first 2^24 cycles.
	//

	reg [25:0] reset_counter = 0;

	always @(posedge clk13)
	begin
		if (!reset_counter[3])
			reset_counter <= reset_counter + 1;
	end

	assign rst = ~reset_counter[3]; // start with a reset

	// ---------------------------------------
	// chipscope debug
	//
	//wire [35:0] cs_control0, cs_control1;
	//
	//wire [63:0] debug;
	//wire [63:0] debug2;
	//
	//cs_icon icon (
	//    .CONTROL0(cs_control0),
	//    .CONTROL1(cs_control1)
	//);
	//
	//cs_ila ila (
	//    .CONTROL(cs_control0),
	//	 .CLK(clk),
	//    .TRIG0(debug2) 
	//);

	wire rxcmd, valid;
	wire [7:0] data;

	//cs_ila9 ila9 (
	//    .CONTROL(cs_control1),
	//    .CLK(ulpi_clk),
	//    .DATA({rxcmd, data}),
	//    .TRIG0({valid, rxcmd, data})
	//);

	//
	// XMOS communication
	//

	wire xmos_ready;
	wire xmos_valid;

	wire [7:0] xmos_d;
	wire [7:0] ulpi_data;
	wire ulpi_rxcmd;
	wire ulpi_valid;

	wire xmos_full;

	//assign debug2 = {xmos_ready, xmos_valid, xmos_d, xmos_state, ulpi_data, ulpi_rxcmd, ulpi_valid, xmos_ready && xmos_state, ulpi_data};

	wire reg_write_req, reg_read_req;
	wire reg_write_ack, reg_read_ack;
	wire [7:0] reg_data_write;
	wire [7:0] reg_data_read;
	wire  [5:0] reg_address;

	ulpi ulpi_inst (
		 .ULPI_RST(TARGETPHY_RST), 
		 .ULPI_NXT(ULPI_NXT), 
		 .ULPI_CLK(ulpi_clk), 
		 .ULPI_CLKN(ulpi_clkn), 
		 .ULPI_DIR(ULPI_DIR), 
		 .ULPI_STP(ULPI_STP), 
		 .ULPI_D(ULPI_D), 
		 .DEBUG(),
		 .DATA_CLK(clk_sdram), 
		 .RST(rst), 
		 .REG_ADDR(reg_address), 
		 .REG_DATA_WRITE(reg_data_write), 
		 .REG_DATA_READ(reg_data_read), 
		 .REG_WRITE_REQ(reg_write_req), 
		 .REG_WRITE_ACK(reg_write_ack), 
		 .REG_READ_REQ(reg_read_req), 
		 .REG_READ_ACK(reg_read_ack), 
		 .RXCMD(ulpi_rxcmd), 
		 .DATA(ulpi_data), 
		 .VALID(ulpi_valid),
		 .READY(1'b1) // !xmos_full)
		 );

	ulpi_ctrl ulpi_ctrl_inst (
		.CLK(CLK_SDRAM), 
		.REG_ADDR(reg_address), 
		.REG_DATA_WRITE(reg_data_write), 
		.REG_DATA_READ(reg_data_read), 
		.REG_WRITE_REQ(reg_write_req), 
		.REG_WRITE_ACK(reg_write_ack), 
		.REG_READ_REQ(reg_read_req), 
		.REG_READ_ACK(reg_read_ack), 
		.RST(rst)
		);

	//
	// XMOS communication over 8-bit parallel link.
	//

	wire xmos_clk = clk26;

	assign CCLK = ~xmos_clk;
	assign MOSI_CSI_B = xmos_valid;
	assign D = xmos_d;

	assign xmos_ready = BUSY_DOUT;

	wire xmos_valid_new;
	reg xmos_prev_hold;

	assign xmos_valid = xmos_valid_new || xmos_prev_hold;

	reg [7:0] cnt_overflow;
	wire overflow;

	reg [7:0] xmos_cnt;

	always @(posedge xmos_clk)
	begin
		xmos_prev_hold <= xmos_valid && !xmos_ready;
	end

	always @(posedge ulpi_clk)
	begin
		if (overflow)
			cnt_overflow <= cnt_overflow + 1;
		if (ulpi_valid)
			xmos_cnt <= xmos_cnt + 1;
	end

	xmos_fifo fifo_xmos (
	  .rst(rst),
	  .wr_clk(clk_sdram),
	  .rd_clk(xmos_clk),
	  .din({cnt_overflow[6:0], ulpi_rxcmd, ulpi_data}),
	  .wr_en(ulpi_valid),
	  .rd_en(xmos_ready),
	  .dout(xmos_d),
	  .full(/*xmos_full*/),
	  .almost_full(xmos_full),
	  .overflow(overflow),
	  .empty(),
	  .valid(xmos_valid_new)
	);
	
	//
	// sdram test
	//
	
	ODDR2 buf_vclk1 (
		.Q(SD_CLK),
		.C0(clk_sdram),
		.C1(~clk_sdram),
		.CE(1'b1),
		.D0(1'b0),
		.D1(1'b1),
		.R(1'b0),
		.S(1'b0)
	);
	
	// memory interface - write request
	wire user_wreq;
	wire user_wstart;
	wire user_wdone;
	wire [23:0] user_waddr;
	wire [9:0] user_wsize;
	wire user_wen;
	wire [15:0] user_wdata;

	// memory interface - read request
	wire user_rreq;
	wire user_rstart;
	wire user_rdone;
	wire [23:0] user_raddr;
	wire [9:0] user_rsize;
	wire user_rvalid;
	wire [15:0] user_rdata;

	// reset
	wire status;
	wire err_strobe;
	wire err_latch;

	mt_extram_sdrctrl mt_extram_sdrctrl_inst (
		.clk(clk_sdram), 
		.rst(rst), 
		.user_wreq(user_wreq), 
		.user_wstart(user_wstart), 
		.user_wdone(user_wdone), 
		.user_waddr(user_waddr), 
		.user_wsize(user_wsize), 
		.user_wen(user_wen), 
		.user_wdata(user_wdata), 
		.user_rreq(user_rreq), 
		.user_rstart(user_rstart), 
		.user_rdone(user_rdone), 
		.user_raddr(user_raddr), 
		.user_rsize(user_rsize), 
		.user_rvalid(user_rvalid), 
		.user_rdata(user_rdata), 
		.SD_CKE(), 
		.SD_CS(SD_CS), 
		.SD_WE(SD_WE), 
		.SD_CAS(SD_CAS), 
		.SD_RAS(SD_RAS), 
		.SD_DQM(SD_DQM), 
		.SD_BA(SD_BA), 
		.SD_A(SD_A), 
		.SD_DQ(SD_DQ)
	);

	mt_extram_test mt_extram_test_inst (
		.clk(clk_sdram), 
		.rst(rst), 
		.user_wreq(user_wreq), 
		.user_wstart(user_wstart), 
		.user_wdone(user_wdone), 
		.user_waddr(user_waddr), 
		.user_wsize(user_wsize), 
		.user_wen(user_wen), 
		.user_wdata(user_wdata), 
		.user_rreq(user_rreq), 
		.user_rstart(user_rstart), 
		.user_rdone(user_rdone), 
		.user_raddr(user_raddr), 
		.user_rsize(user_rsize), 
		.user_rvalid(user_rvalid), 
		.user_rdata(user_rdata), 
		.status(status), 
		.err_strobe(err_strobe), 
		.err_latch(err_latch)
	);

	/* INITIAL INSERTION OF XLINK CORE */
    wire mm_reset, mm_clk;

    midimux_clklogic inst_clkgen (
        .clk_in_13(clk13),
        .clk_50(mm_clk),
        .rst_50(mm_reset)
        );

    /* Standard data bus decl */
    wire [30:0] addr_bus;
    wire [31:0] data_bus_wr;
    wire [31:0] data_bus_rd;
    wire wr_strobe;
    wire rd_strobe;

    XLinkToAddrBus xl2ab (
        mm_clk,
        mm_reset,
        XLAIN[0],
        XLAIN[1],
        XLAOUT[0],
        XLAOUT[1],

        addr_bus,
        data_bus_wr,
        data_bus_rd,
        wr_strobe,
        rd_strobe
        );

    wire [31:0] leds_module_dout;


    led_module leds (
        .clk(mm_clk),
        .reset(mm_reset),
        .addr_bus(addr_bus),
        .data_bus_wr(data_bus_wr),
        .data_bus_rd(leds_module_dout),
        .wr_strobe(wr_strobe),
        .rd_strobe(rd_strobe),

        .leds(FLED)
        );



    wire [31:0] memtest_dbus_rd;
    reg [1:0] memtest_stat_dbus_r;
    reg [1:0] memtest_stat_dbus_n;
    assign memtest_dbus_rd = {30'h0, memtest_stat_dbus_r};

    always @(*) begin
        memtest_stat_dbus_n = 0;

        if (rd_strobe && addr_bus == 31'h02000000)
            memtest_stat_dbus_n = {status, err_latch};
    end
    
    always @(posedge mm_clk)
    begin
        if (mm_reset)
            memtest_stat_dbus_r <= 0;
        else
            memtest_stat_dbus_r <= memtest_stat_dbus_n;
    end


    assign data_bus_rd = leds_module_dout | memtest_dbus_rd;
endmodule
