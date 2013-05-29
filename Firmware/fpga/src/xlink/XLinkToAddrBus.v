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

module XLinkToAddrBus(
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


// Standard
input clk;
input reset;
wire reset, clk;

// XLINK TX
output tx_0;
output tx_1;
wire tx_0;
wire tx_1;

// XLINK RX
input rx_0;
input rx_1;

// address bus
output wr_strobe, rd_strobe;
output [31:0] data_bus_wr;
input [31:0] data_bus_rd;
output [30:0] addr_bus;


// Some XMOS code needs inverted reset
wire reset_n;
assign reset_n = ~reset; 


reg xlink_mode;

// rx wires
wire [8:0] rx_token;
wire rx_token_valid;
wire rx_error;

// rx phy
XLinkRxPhy xlink_rx_phy(

   // system clock and reset.
   clk,
   reset_n,
   
   // 2bits or 5bits
   xlink_mode,
         
   // receive token interface
   rx_token,               // received token
   rx_token_valid,         // received token valid
   rx_error,               // detect error
   
   // Physical link pair
   rx_0,                   // receive 0-wire
   rx_1         
);

// TX iface
wire tx_roomForToken;
wire [8:0] tx_token;
wire tx_token_valid;

reg [3:0] inter_token_delay;
reg [3:0] intra_token_delay;

// tx phy
XLinkTxPhy xlink_tx_phy(

   // system clock and reset.
   clk,
   reset_n,
   
   // 2bits or 5bits
   xlink_mode,
   
   // static config.
   inter_token_delay,      // 4bits inter token delay counter
   intra_token_delay,      // 4bits intra token (i.e. between bits), delay counter
   
   // transmit token interface
   tx_roomForToken,        // indicates PHY can accept another token
   tx_token,               // input token to be transmitted.
   tx_token_valid,         // input token valid
      
   // Physical link pair
   tx_0,                   // transmit 0-wire
   tx_1                    // transmit 1-wire

);

// tx buffer interface
wire tx_buf_wen;
wire [8:0] tx_data_in; 

wire tx_buf_ren, tx_empty;
wire [8:0] tx_data_out;

// xlink tx buffer - 9bits wide data, 4 bit wide address

XTokenFifo xl_tx_fifo (
    .clk(clk),
    .reset(reset),
    .din(tx_data_in), // Bus [8 : 0] 
    .rd_en(tx_buf_ren),
    .wr_en(tx_buf_wen),
    .dout(tx_data_out), // Bus [8 : 0] 
    .empty(tx_empty),
    .full());


// rx buffer interface
wire [8:0] rx_token_buf_in; 
wire rx_buf_wen;

wire [8:0] rx_data_out;
wire rx_buf_ren;

// rx data buffer
XTokenFifo xl_rx_fifo (
    .clk(clk),
    .reset(reset),
    .din(rx_token_buf_in), // Bus [7 : 0] 
    .rd_en(rx_buf_ren),
    .wr_en(rx_buf_wen),
    .dout(rx_data_out), // Bus [7 : 0] 
    .empty(rx_empty),
    .full());
    


// interface between tx buffer and tx phy
XLinkTxCntrl xl_tx_ctl( 

   clk, reset,             // system services 

   tx_roomForToken,        // indicates PHY can accept another token
   tx_token,               // input token to be transmitted.
   tx_token_valid,         // indicate that the data on the bus is valid
   
   tx_data_out,        // buffer interface
   tx_buf_ren,   
   tx_empty
   
   );   

wire [8:0] tx_d_token;

wire link_has_credits;
wire link_issued_credits;

wire link_reset_state_machine;
assign link_reset_state_machine = 0;

reg link_issue_hello;

// xlink controller
XLinkCntrl xl_ctl(
   clk, 
   reset, 
   
   rx_token, 
   rx_token_valid, 
   rx_error, 
   
   tx_data_in,  
   tx_buf_wen,
   
   rx_token_buf_in,  
   rx_buf_wen,
   
   tx_d_token,
   tx_d_token_valid,
   tx_d_token_taken,

   link_reset_state_machine,
   link_issue_hello,
   link_has_credits,
   link_issued_credits
   );

// xlink data processor
wire [31:0] switch_reg_db;

SimpleLinkDataProcessor xl_d_proc( 
   clk, reset, 
   
   rx_data_out,  
   rx_buf_ren,
   rx_empty, 
   
   tx_d_token,
   tx_d_token_valid,
   tx_d_token_taken,

   addr_bus,

   data_bus_wr,
   data_bus_rd | switch_reg_db,
   wr_strobe,
   rd_strobe
   
   );

`define SWITCH_REG 32'h7F000080
/* Switch Register Format
 * 10..0 clock cycle IPG [unimplemented]
 * 21.11 symbol gap [unimplemented]
 *
 * 23 - reset state machine [unimplemented]
 * 24 - WO issue hello
 * 25 - RO link has credits and can transmit
 * 26 - RO Link has issued credits and can receive
 * 27 - RO Link Protocol Error
 * 30 - Signal Wires [fixed 0]
 * 31 - Enable Link [fixed 1]
 */

reg [31:0] switch_reg_rd_r;
assign switch_reg_db = switch_reg_rd_r;
reg [31:0] switch_reg_rd_n;

always @(*) begin
    switch_reg_rd_n = 0;

    if (rd_strobe && addr_bus == `SWITCH_REG) begin
        switch_reg_rd_n[31] = 1;
        switch_reg_rd_n[26] = link_issued_credits;
        switch_reg_rd_n[25] = link_has_credits;
        switch_reg_rd_n[21:11] = inter_token_delay;
        switch_reg_rd_n[10:0] = intra_token_delay;
    end
end

always @(posedge clk)
begin
    if (reset)
    begin
        switch_reg_rd_r <= 0;
        inter_token_delay <= 2;
        intra_token_delay <= 2;
        link_issue_hello <= 0;
    end
    else if (wr_strobe && addr_bus == `SWITCH_REG) begin
        link_issue_hello <= data_bus_wr[24];

        inter_token_delay <= data_bus_wr[21:11];
        intra_token_delay <= data_bus_wr[10:0];
    end
    else begin
        switch_reg_rd_r <= switch_reg_rd_n;
        link_issue_hello <= 0;
    end
end

reg rx_token_valid_stretch;
reg rx_token_is_ctrl;
   
always @(posedge clk)
begin
   xlink_mode = 0;
end


endmodule

