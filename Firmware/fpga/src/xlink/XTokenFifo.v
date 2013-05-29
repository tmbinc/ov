/*
 * The copyrights, all other intellectual and industrial
 * property rights are retained by XMOS and/or its licensors.
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2008
 */
 
 /*
  * Fifo - token fifo.  Stores 9 bit tokens.
  *
  */
  
`include "SwitchCommonDef.v"

module XTokenFifo(
	input clk,
	input reset,
	input [8:0] din,
	input rd_en,
	input wr_en,
	output  [8:0] dout,
	output  empty,
	output  full
);

  parameter FIFO_SIZE = 8;
  parameter FIFO_ADDR_WIDTH = 2;
  
  reg [8:0] fifo_r[FIFO_SIZE-1:0];
  reg [8:0] fifo_t[FIFO_SIZE-1:0];
  reg [FIFO_ADDR_WIDTH:0] fifoHead_r;
  reg [FIFO_ADDR_WIDTH:0] fifoTail_r;
  reg [FIFO_ADDR_WIDTH:0] fifoHead_t;
  reg [FIFO_ADDR_WIDTH:0] fifoTail_t;
  
  
 reg empty_t;
 reg full_t;
 
assign empty = empty_t;
assign full = full_t; 
assign dout = fifo_r[fifoTail_r]; 


always @(*) begin
  // check full/empty
  empty_t = (fifoHead_r == ((fifoTail_r+1) & 'h7)) ? 1'b 1 : 1'b 0;
  full_t = (fifoTail_r == fifoHead_r) ? 1'b 1 : 1'b 0;
  
end

always @(*) begin 
  fifoTail_t = fifoTail_r;
  
  if (empty==0) begin
    if (rd_en) begin
	  fifoTail_t = fifoTail_r + 1;
	end
  end
  
end

  
always @(fifo_r[0], fifo_r[1], fifo_r[2], fifo_r[3], fifo_r[4], fifo_r[5], fifo_r[6], fifo_r[7], 
         fifoHead_r, fifoTail_r, fifoHead_t, fifoTail_t, empty, full,
		 rd_en, wr_en, din) begin   // workaround for xilink error #1468.

  fifo_t[0] = fifo_r[0];
  fifo_t[1] = fifo_r[1];
  fifo_t[2] = fifo_r[2];
  fifo_t[3] = fifo_r[3];
  fifo_t[4] = fifo_r[4];
  fifo_t[5] = fifo_r[5];
  fifo_t[6] = fifo_r[6];
  fifo_t[7] = fifo_r[7];
	
  fifoHead_t = fifoHead_r;
  
  if (full==0) begin
    if (wr_en) begin
	  fifoHead_t = fifoHead_r + 1;
	  fifo_t[fifoHead_r] = din;
	end
  end
end

always @(posedge clk or posedge reset)
begin
  if (reset)
  begin
    fifo_r[0] <= 0;
    fifo_r[1] <= 0;
    fifo_r[2] <= 0;
    fifo_r[3] <= 0;
    fifo_r[4] <= 0;
    fifo_r[5] <= 0;
    fifo_r[6] <= 0;
    fifo_r[7] <= 0;
    fifoHead_r <= 0;
    fifoTail_r <= (FIFO_SIZE-1);
	 
	 //empty_r <= 1;
	 //full_r <= 1;
  end
  else begin
    fifo_r[0] <= fifo_t[0];
    fifo_r[1] <= fifo_t[1];
    fifo_r[2] <= fifo_t[2];
    fifo_r[3] <= fifo_t[3];
    fifo_r[4] <= fifo_t[4];
    fifo_r[5] <= fifo_t[5];
    fifo_r[6] <= fifo_t[6];
    fifo_r[7] <= fifo_t[7];
    fifoHead_r <= fifoHead_t;
    fifoTail_r <= fifoTail_t;
	 
	 //empty_r <= empty_t;
	 //full_r <= full_t;
  end
end

endmodule
