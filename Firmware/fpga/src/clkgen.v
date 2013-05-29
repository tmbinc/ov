`timescale 1ns / 1ps
module clkgen(
		input CLOCK_13,
		output CLOCK_192,
		output CLOCK_13_BUF,
		output CLOCK_26,
		output CLOCK_SDRAM,
		input RST,
		output LOCKED
	);

	//
	// First DCM: 13 MHz * 4 / 5 = 10.4 MHz
	//

	wire u1_clkin_buf;
	wire u1_clk2x, u1_clk2x_buf;
	wire u1_clkfx, u1_clkfx_buf;
	wire u1_locked;

	DCM_SP #( 
		.CLK_FEEDBACK("2X"),
		.CLKFX_DIVIDE(5),
		.CLKFX_MULTIPLY(4),
		.CLKIN_PERIOD(75.758),
		.STARTUP_WAIT("FALSE") 
	) 
	U1 (
		.CLKFB(u1_clk2x_buf),
		.CLKIN(u1_clkin_buf),
		.DSSEN(1'b0),
		.PSCLK(1'b0),
		.PSEN(1'b0),
		.PSINCDEC(1'b0),
		.RST(RST),
		.CLKDV(),
		.CLKFX(u1_clkfx),
		.CLKFX180(),
		.CLK0(),
		.CLK2X(u1_clk2x),
		.CLK2X180(),
		.CLK90(),
		.CLK180(),
		.CLK270(),
		.LOCKED(u1_locked),
		.PSDONE(),
		.STATUS()
	);

	IBUFG u1_clkin_ibuf (.I(CLOCK_13), .O(u1_clkin_buf));
	BUFG  u1_clk2x_bufg (.I(u1_clk2x), .O(u1_clk2x_buf));
	BUFG  u1_clkfx_bufg (.I(u1_clkfx), .O(u1_clkfx_buf));

	assign CLOCK_13_BUF = u1_clkin_buf;
	assign CLOCK_26 = u1_clk2x_buf;

	//
	// Second DCM: 10.4 MHz * 24 / 13 = 19.2 MHz
	//

	wire u2_clkin;
	wire u2_clk0, u2_clk0_buf;
	wire u2_clkfx;
	wire u2_locked;
	wire u2_rst_in;

	DCM_SP #( 
		.CLK_FEEDBACK("1X"),
		.CLKFX_DIVIDE(13),
		.CLKFX_MULTIPLY(24),
		.CLKIN_PERIOD(37.879),
		.STARTUP_WAIT("FALSE")
	)
	U2 (
		.CLKFB(u2_clk0_buf),
		.CLKIN(u2_clkin),
		.DSSEN(1'b0),
		.PSCLK(1'b0),
		.PSEN(1'b0),
		.PSINCDEC(1'b0),
		.RST(u2_rst_in),
		.CLKDV(),
		.CLKFX(u2_clkfx),
		.CLKFX180(),
		.CLK0(u2_clk0),
		.CLK2X(),
		.CLK2X180(),
		.CLK90(),
		.CLK180(),
		.CLK270(),
		.LOCKED(u2_locked),
		.PSDONE(),
		.STATUS()
	);

	BUFG  u2_clkfx_bufg (.I(u2_clkfx), .O(CLOCK_192));
	BUFG  u2_clk0_bufg  (.I(u2_clk0),  .O(u2_clk0_buf));

	//
	// U2 rst generation (TODO: is that really required?)
	//
	
	wire u2_fds_q_out;
	reg u2_fd1_q_out;
	reg u2_fd2_q_out;
	reg u2_fd3_q_out;

	FDS  U2_FDS_INST (.C(u2_clkin), 
						  .D(1'b0), 
						  .S(1'b0), 
						  .Q(u2_fds_q_out));

	always @(posedge u2_clkin)
	begin
		u2_fd1_q_out <= u2_fds_q_out;
		u2_fd2_q_out <= u2_fd1_q_out;
		u2_fd3_q_out <= u2_fd2_q_out;
	end
	
	assign u2_rst_in = ~u1_locked | (u2_fd3_q_out | u2_fd2_q_out | u2_fd1_q_out);
	
	//
	// Third DCM: Generate SDRAM clock 13 MHz * 7 = 91 MHz
	//
	
	wire u3_clk0, u3_clk0_buf;
	wire u3_clkfx;
	wire u3_locked;

	DCM_SP #( 
		.CLK_FEEDBACK("1X"),
		.CLKFX_DIVIDE(1),
		.CLKFX_MULTIPLY(7),
		.CLKIN_PERIOD(75.758),
		.STARTUP_WAIT("FALSE") 
	) 
	U3 (
		.CLKFB(u3_clk0_buf),
		.CLKIN(u1_clkin_buf),
		.DSSEN(1'b0),
		.PSCLK(1'b0),
		.PSEN(1'b0),
		.PSINCDEC(1'b0),
		.RST(RST),
		.CLKDV(),
		.CLKFX(u3_clkfx),
		.CLKFX180(),
		.CLK0(u3_clk0),
		.CLK2X(),
		.CLK2X180(),
		.CLK90(),
		.CLK180(),
		.CLK270(),
		.LOCKED(u3_locked),
		.PSDONE(),
		.STATUS()
	);

	BUFG  u3_clk0_bufg  (.I(u3_clk0),  .O(u3_clk0_buf));
	BUFG  u3_clkfx_bufg (.I(u3_clkfx), .O(CLOCK_SDRAM));
	
	//
	// Master "locked"
	//

	assign LOCKED = u1_locked & u2_locked & u3_locked;
endmodule
