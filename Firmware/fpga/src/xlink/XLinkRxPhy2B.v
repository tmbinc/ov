/*
 * The copyrights, all other intellectual and industrial
 * property rights are retained by XMOS and/or its licensors.
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2008
 */
 
 /*
  * XLinkRxPhy2B - Xlink Receive 2-bit phy. 
  *
  */

`include "SwitchCommonDef.v"
`include "XLinkDefines.v"

module XLinkRxPhy2B (

   // system clock and reset.
   clk,
   async_reset_n,
   
   // 2bits or 5bits
   xlink_mode,
         
   // receive token interface
   rx_token,               // received token
   rx_token_valid,         // received token valid
   rx_error,               // detect error
   
   rx_time_out,            // external time out detector.
   
   // edge detected active high pulse
   rx_0_edge,                   // receive 0-wire
   rx_1_edge                    // receive 1-wire

);



// System Clock & reset.
input                      clk;
input                      async_reset_n;

input                      xlink_mode;

output  [8 : 0]            rx_token;               // received token      
output                     rx_token_valid;         // received token valid
output                     rx_error;

input                      rx_time_out;

// Physical link pair
input                      rx_0_edge;                   
input                      rx_1_edge;


// 
// Internal signals
//


// receive bit counter
reg [3 : 0]                rx_bit_cnt_t, rx_bit_cnt_r;

// 10bits serial receive data 
reg [9 : 0]                rx_data_t, rx_data_r;

// indicates complete 10bits of data is receive.
wire                       rx_10bits_t;
reg                        rx_10bits_r;

// zero or one receive data.
wire                       zero_rx_t, one_rx_t;

// receive decoded token.
reg [8 : 0]                rx_token_t; 
reg                        rx_token_valid_t;
reg                        rx_error_t;


// output port assignment.
assign rx_token = rx_token_t;
assign rx_token_valid = rx_token_valid_t;
assign rx_error = rx_error_t;


// detect transition on incoming dual sync.
assign zero_rx_t = rx_0_edge;
assign one_rx_t  = rx_1_edge;
assign rx_10bits_t = (rx_bit_cnt_r == 4'b1001) ? (zero_rx_t | one_rx_t) : 1'b0;


// this maintain the internal data structures.
always @ (*)
begin
   // initial assignment
   rx_bit_cnt_t = rx_bit_cnt_r;
   rx_data_t    = rx_data_r;
   rx_token_t    = 9'b0;
   rx_error_t    = 1'b0;
   rx_token_valid_t = rx_10bits_r;      
   // this decode the 10bits received data into 9bits token
   if (rx_10bits_r == 1'b1)
   begin
      rx_token_t[7 : 0] = rx_data_r[9 : 2];
      rx_error_t = 1'b0;
      // this decode the ctl/data token.
      case ( {^ rx_data_r[9 : 2], rx_data_r[1 : 0]} )
         3'b101:  // odd bits, data token
            rx_token_t[8] = 1'b0;
         3'b110:  // odd bits, ctl token
            rx_token_t[8] = 1'b1;
         3'b000:  // even bits, data token
            rx_token_t[8] = 1'b0;         
         3'b011:  // even bits, ctl toekn
            rx_token_t[8] = 1'b1;         
         default: // ERROR, mark as data.
         begin
            rx_token_t[8] = 1'b0;         
            rx_error_t = 1'b1;
         end
      endcase       
   end
   
   // every time a bit is received increment the count.
   if (rx_10bits_r == 1'b1)
   begin
      if (zero_rx_t == 1'b1 || one_rx_t == 1'b1)
         rx_bit_cnt_t = 4'b1;      
      else
         rx_bit_cnt_t = 4'b0;
   end
   else if (zero_rx_t == 1'b1 || one_rx_t == 1'b1)
   begin
      rx_bit_cnt_t = rx_bit_cnt_r + 4'b1;
   end      
   else if (rx_time_out == 1'b1)   
   begin // reset for next token.
      rx_bit_cnt_t = 4'b0;
   end
   
   
   // shift in the data as required.
   if (zero_rx_t == 1'b1)
   begin
      rx_data_t[9 : 1] = rx_data_r[8 : 0];
      rx_data_t[0] = 1'b0;
   end
   else if (one_rx_t == 1'b1)
   begin
      rx_data_t[9 : 1] = rx_data_r[8 : 0];
      rx_data_t[0] = 1'b1;   
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
      rx_bit_cnt_r     <= 0;      
      rx_data_r        <= 0;
      rx_10bits_r      <= 1'b0;
   end      
   else
   begin
      if (xlink_mode == 1'b1)
      begin
         rx_bit_cnt_r     <= 0;      
         rx_data_r        <= 0;
         rx_10bits_r      <= 1'b0;      
      end
      else
      begin
         rx_bit_cnt_r     <= rx_bit_cnt_t;      
         rx_data_r        <= rx_data_t;
         rx_10bits_r      <= rx_10bits_t;
      end
   end
end


endmodule

  
