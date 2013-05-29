/*
 * The copyrights, all other intellectual and industrial
 * property rights are retained by XMOS and/or its licensors.
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2008
 */
 
 /*
  * XLinkTxCntrl - manages the tx fifo, reading data from it and sending to the txPhy
  *
  */
  
  
  `include "SwitchTokenDef.v"

module XLinkTxCntrl( 

   clk, reset,             // system services 

   tx_roomForToken,        // indicates PHY can accept another token
   tx_token,               // input token to be transmitted.
   tx_token_valid,         // indicate that the data on the bus is valid
   
   tx_buf_data_out,        // buffer interface
   tx_rd_en,
   tx_buf_empty
   
   );
   
input clk;
input reset;

input tx_roomForToken;
output [8:0] tx_token;
//reg [8:0] tx_token;
output tx_token_valid;
reg tx_token_valid;
reg tx_token_valid_t;

input [8:0] tx_buf_data_out;
output tx_rd_en;
reg tx_rd_en;
reg tx_rd_en_t;
input tx_buf_empty;

reg [3:0] s, s1;

`define START 0
`define SEND_TOKEN 1
`define SEND_TOKEN_DONE 2

always @(posedge clk or posedge reset) 
begin
   if (reset) begin
      s <= `START;
      tx_rd_en <= 0;
      tx_token_valid <= 0;
   end
   else begin
      s <= s1;
      tx_rd_en <= tx_rd_en_t;
      tx_token_valid <= tx_token_valid_t;
   end
end

assign tx_token = tx_buf_data_out;

always @(*)
begin
    
s1 = `START;
tx_token_valid_t = 0;
tx_rd_en_t = 0;
case (s)
`START:   
   // send data to trasmitter if the transmitter has room
   // and there is data in the fifo
   if (tx_roomForToken & !tx_buf_empty)
   begin
      tx_rd_en_t = 1;
      s1 = `SEND_TOKEN;
   end
   else
   begin
      tx_token_valid_t = 0;
      tx_rd_en_t = 0;
      s1 = `START;
   end
//1:
`SEND_TOKEN:
begin
   tx_token_valid_t = 1;
   tx_rd_en_t = 0;
   s1 = `SEND_TOKEN_DONE;
end
//2:
`SEND_TOKEN_DONE:
begin
   tx_token_valid_t = 0;
   tx_rd_en_t = 0;
   s1 = `START;
end
default: 
  s1 = `START;
endcase
end // end always

endmodule
