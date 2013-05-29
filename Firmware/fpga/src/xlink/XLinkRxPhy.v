/*
 * The copyrights, all other intellectual and industrial
 * property rights are retained by XMOS and/or its licensors.
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2008
 */
 
 /*
  * XLinkRxPhy - Xlink Receive phy. This is a wrapper for the 2-bit Xlink Rx phy.
  *
  */

`include "SwitchCommonDef.v"
`include "XLinkDefines.v"

module XLinkRxPhy (

   // system clock and reset.
   clk,
   async_reset_n,
   
   // 2bits or 5bits
   xlink_mode,
         
   // receive token interface
   rx_token,               // received token
   rx_token_valid,         // received token valid
   rx_error,               // detect error
   
   // Physical link pair
   rx_0,                   // receive 0-wire
   rx_1                    // receive 1-wire

);


// System Clock & reset.
input                      clk;
input                      async_reset_n;

input                      xlink_mode;

output  [8 : 0]            rx_token;               // received token      
output                     rx_token_valid;         // received token valid
output                     rx_error;

// Physical link pair
input                      rx_0;                   
input                      rx_1;                                    



// 
// Internal signals
//

// receive bit interface.
reg   [1 : 0]              rx_in_buf_r [1 : 0];
wire  [1 : 0]              rx_in_edge;

// 2bits receive interface.
wire  [8 : 0]              rx_token_2b;               // received token      
wire                       rx_token_valid_2b;         // received token valid
wire                       rx_error_2b;

// final register value.
reg  [8 : 0]               rx_token_r;               // received token      
reg                        rx_token_valid_r;         // received token valid
reg                        rx_error_r;

// time out counter.
reg   [7 : 0]              rx_time_out_cnt_t, rx_time_out_cnt_r;
wire                       rx_time_out;
wire                       rx_rtn_zero;


// output path mux
assign rx_token       = rx_token_r;
assign rx_token_valid = rx_token_valid_r;
assign rx_error       = rx_error_r;

// detect the edge of rx lines
assign rx_in_edge = rx_in_buf_r[0] ^ rx_in_buf_r[1];

// detect return to zero of all rx wires.
assign rx_rtn_zero = ~ ((|rx_in_buf_r[0]) | (|rx_in_buf_r[1]));


// 2Bits XLink Rx Phy
XLinkRxPhy2B XLinkRxPhy2B_inst 
(
   // system clock and reset.
   .clk              (clk),
   .async_reset_n            (async_reset_n),
   
   // 2bits or 5bits
   .xlink_mode       (xlink_mode),
         
   // receive token interface
   .rx_token         (rx_token_2b),               // received token
   .rx_token_valid   (rx_token_valid_2b),         // received token valid
   .rx_error         (rx_error_2b),               // detect error
   
   .rx_time_out      (rx_time_out),
   
   // Physical link pair
   .rx_0_edge        (rx_in_edge[0]),                   // receive 0-wire
   .rx_1_edge        (rx_in_edge[1])                    // receive 1-wire
);


//------------------------------------------------
// generate rx timed out signal from counter.
//------------------------------------------------
assign rx_time_out = (rx_time_out_cnt_r == 0) ? ~ (|rx_in_edge) : 1'b0;

// this maintain rx time out counter.
always @ (*)
begin
   // initial assignment.
   rx_time_out_cnt_t = rx_time_out_cnt_r;
   // detect non active cycles.
   if ( (xlink_mode == 1'b0 && |rx_in_edge[1 : 0]) || (xlink_mode == 1'b1 && |rx_in_edge) )
   begin
      rx_time_out_cnt_t = `RX_TIME_OUT;
   end
   else
   begin
      if (rx_time_out_cnt_r > 0)
      begin
         rx_time_out_cnt_t = rx_time_out_cnt_r - 1'b1;
      end
   end
end


//*******************************
// Sequential.
//*******************************

// sequential path
always @ (posedge clk or negedge async_reset_n)
begin
   if (async_reset_n == `SSWITCH_RESET_LEVEL)
   begin
      rx_token_r       <= 0;
      rx_token_valid_r <= 1'b0;
      rx_error_r       <= 1'b0;
      rx_time_out_cnt_r<= `RX_TIME_OUT;
   end      
   else
   begin
      rx_time_out_cnt_r<= rx_time_out_cnt_t;
      // Mux the return data base on mode.
      if (xlink_mode == 1'b0)
      begin
         rx_token_r       <= rx_token_2b;
         rx_token_valid_r <= rx_token_valid_2b;
         rx_error_r       <= rx_error_2b;
      end
      else
      begin
         rx_token_r       <= 0;
         rx_token_valid_r <= 0;
         rx_error_r       <= 0;
      end
   end
end

// sequential path, dual sync/edge detect flops 
always @ (posedge clk)
begin
//   rx_in_buf_r[0] <= {rx_4, rx_3, rx_2, rx_1, rx_0};
   rx_in_buf_r[0] <= {rx_1, rx_0};
   rx_in_buf_r[1] <= rx_in_buf_r[0];   
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

  
