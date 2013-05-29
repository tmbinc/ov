/*
 * The copyrights, all other intellectual and industrial
 * property rights are retained by XMOS and/or its licensors.
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2008
 */
 
 /*
  * XLinkTxPhy - Xlink Transmit phy. This is a wrapper for the 2-bit Xlink Tx phy.
  *
  */

`include "SwitchCommonDef.v"
`include "XLinkDefines.v"
 

module XLinkTxPhy (

   // system clock and reset.
   clk,
   async_reset_n,
   
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



// System Clock & reset.
input                      clk;
input                      async_reset_n;

input                      xlink_mode;

// static config.
input [3 : 0]              inter_token_delay;      // 4bits inter token delay counter
input [3 : 0]              intra_token_delay;      // 4bits intra token (i.e. between bits), delay counter

// transmit token interface
output                     tx_roomForToken;        // indicates PHY can accept another token
input  [8 : 0]             tx_token;               // input token to be transmitted.
input                      tx_token_valid;         // input token valid

// Physical link pair
output                     tx_0;    
output                     tx_1;       



// 
// Internal signals
//

// 2bits PHY
wire                       tx_roomForToken_2b;
wire [1 : 0]               tx_2b;

// output stage register.
reg  [1 : 0]               tx_line_r;


// room for Token mux.
assign tx_roomForToken = tx_roomForToken_2b;

assign tx_0 = tx_line_r[0];
assign tx_1 = tx_line_r[1];


// 2bits Tx Phy
XLinkTxPhy2B XLinkTxPhy2B_inst 
(
   // system clock and reset.
   .clk                    (clk),
   .async_reset_n                  (async_reset_n),
   
   .xlink_mode             (xlink_mode),
   
   // static config.
   .inter_token_delay      (inter_token_delay),      // 4bits inter token delay counter
   .intra_token_delay      (intra_token_delay),      // 4bits intra token (i.e. between bits), delay counter
   
   // transmit token interface
   .tx_roomForToken        (tx_roomForToken_2b),        // indicates PHY can accept another token
   .tx_token               (tx_token),               // input token to be transmitted.
   .tx_token_valid         (tx_token_valid & (~ xlink_mode)),   // input token valid
   
   // Physical link pair
   .tx_0                   (tx_2b[0]),  
   .tx_1                   (tx_2b[1])
);

//*******************************
// Sequential.
//*******************************

// sequential path
always @ (posedge clk or negedge async_reset_n)
begin
   if (async_reset_n == `SSWITCH_RESET_LEVEL)
   begin
      tx_line_r <= 0;
   end      
   else
   begin
      tx_line_r <= {tx_2b};  
   end
end


//*****************
// Assertions.
//*****************

// cover_off
// synthesis translate_off
`ifdef ASSERTIONS_ON
`ifdef SSWITCH_ASSERTIONS_ON

   
      
`endif
`endif
// synthesis translate_on
// cover_on

endmodule

  
