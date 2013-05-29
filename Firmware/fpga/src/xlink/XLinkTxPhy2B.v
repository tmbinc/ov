/*
 * The copyrights, all other intellectual and industrial
 * property rights are retained by XMOS and/or its licensors.
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2008
 */
 
 /*
  * XLinkTxPhy2B - Xlink Transmit 2-bit phy. 
  *
  */
`include "SwitchCommonDef.v"
`include "XLinkDefines.v"
 

module XLinkTxPhy2B (

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


// transmit data register.
reg [9 : 0]                tx_data_t, tx_data_r;

// transmit state machine.
reg [1 : 0]                tx_fsm_t, tx_fsm_r;

// transmit wait counter.
reg [3 : 0]                wait_counter_t, wait_counter_r;

// transmiter bit count.
reg [3 : 0]                tx_bit_count_t, tx_bit_count_r;

// indicates a bit is transmitted.
wire                        bit_tx_t, last_bit_tx_t;

// 0-wire & 1-wire pair.
reg                        tx_0_t, tx_0_r, tx_1_t, tx_1_r;

// for debugging purposes
//wire [8:0] tx_token_w;
//assign tx_token_w = {1'b1, 8'he2}; // reset

// output port mapping
assign tx_roomForToken = (tx_fsm_r == `TX_IDEAL) ? 1'b1 : 1'b0;


assign bit_tx_t      = (tx_fsm_r == `TX_BIT_TX)    ? 1'b1 : 1'b0;
assign last_bit_tx_t = (tx_bit_count_r == 4'b1001) ? 1'b1 : 1'b0;

// this generate zero and one wire pair
always @ (*)
begin
   // initial assignment
   tx_0_t = tx_0_r;
   tx_1_t = tx_1_r;
   // maintain the transmition
   if (tx_fsm_r == `TX_BIT_TX)
   begin
      if (tx_data_r[9] == 1'b0)
      begin
         tx_0_t = ~ tx_0_r;
         tx_1_t = tx_1_r;
      end
      else
      begin
         tx_0_t = tx_0_r;
         tx_1_t = ~ tx_1_r;      
      end
   end   
end

// count the number bits transmitted for this token.
always @ (*)
begin
   tx_bit_count_t = tx_bit_count_r;
   // simple counter.
   if (tx_fsm_r == `TX_IDEAL)
   begin
      tx_bit_count_t = 4'b0;
   end
   else if (tx_fsm_r == `TX_BIT_TX)
   begin
      tx_bit_count_t = tx_bit_count_r + 4'b1;
   end   
end

// time out counter
always @ (*)
begin
   // initial assignment
   wait_counter_t = wait_counter_r;   
   // time out generation.
   case (tx_fsm_r)
      `TX_BIT_TX:
         if (last_bit_tx_t == 1'b1)
         begin
            if (inter_token_delay > 4'b0)
               wait_counter_t = inter_token_delay - 4'b1;            
            else
               wait_counter_t = inter_token_delay;
         end
         else
         begin
            if (intra_token_delay > 4'b0)
               wait_counter_t = intra_token_delay - 4'b1;            
            else
               wait_counter_t = intra_token_delay;
         end
      `TX_BIT_WAIT, `TX_TOKEN_WAIT:
         if (wait_counter_r > 4'b0)
         begin
            wait_counter_t = wait_counter_r - 4'b1;
         end
      default:
         wait_counter_t = wait_counter_r;   
   endcase
end

// transmit state machine.
always @ (*)
begin
   tx_fsm_t = tx_fsm_r;
   // transmitter state machine.
   case (tx_fsm_r)
      `TX_IDEAL:
         if (tx_token_valid == 1'b1)
         begin
            tx_fsm_t = `TX_BIT_TX;         
         end
      `TX_BIT_TX:
         if (last_bit_tx_t == 1'b1)
         begin
            tx_fsm_t = `TX_TOKEN_WAIT;
         end
         else
         begin
            if (intra_token_delay != 0)
            begin
               tx_fsm_t = `TX_BIT_WAIT;
            end
         end
      `TX_BIT_WAIT:
         if (wait_counter_r == 4'b0)
         begin
            tx_fsm_t = `TX_BIT_TX;         
         end
      `TX_TOKEN_WAIT:
         if (wait_counter_r == 4'b0)
         begin
            tx_fsm_t = `TX_IDEAL;         
         end
      default:
         tx_fsm_t = tx_fsm_r;
   endcase
end

// Transmit data management
always @ (*)
begin
   tx_data_t = tx_data_r;
   // load new token to be transmitted
   if (tx_token_valid == 1'b1 & tx_fsm_r == `TX_IDEAL)
   begin
      // store the 8bits data
      tx_data_t[9 : 2] = tx_token[7 : 0];
      // this generate the addtion transitions
      if ((^ tx_token[7 : 0]) == 1'b1) // odd 1's to trasnmit
      //if ((^ tx_token_w[7 : 0]) == 1'b1)
      begin          
         if (tx_token[8] == 1'b1)   // CTL token
            tx_data_t[1 : 0] = 2'b10;
         else  // DATA token
            tx_data_t[1 : 0] = 2'b01;
      end
      else
      begin // even 1's to transmit
         if (tx_token[8] == 1'b1)   // CTL token
            tx_data_t[1 : 0] = 2'b11;
         else  // DATA token
            tx_data_t[1 : 0] = 2'b00;      
      end      
   end
   else if (bit_tx_t == 1'b1)
   begin // shift register for transmitting.
      tx_data_t[9 : 1] = tx_data_r[8 : 0];
      tx_data_t[0] = 1'b0;
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
      tx_data_r      <= 0;
      tx_fsm_r       <= `TX_IDEAL;
      wait_counter_r <= 4'b0;
      tx_bit_count_r <= 4'b0;
      tx_0_r         <= 1'b0;
      tx_1_r         <= 1'b0;
   end      
   else
   begin
      tx_data_r      <= tx_data_t;
      tx_fsm_r       <= tx_fsm_t;
      wait_counter_r <= wait_counter_t;
      tx_bit_count_r <= tx_bit_count_t;
      tx_0_r         <= tx_0_t;
      tx_1_r         <= tx_1_t;   
   end
end


// 2B tx bits.
assign tx_0 = tx_0_r;
assign tx_1 = tx_1_r;


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

  
