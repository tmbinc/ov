/*
 * The copyrights, all other intellectual and industrial
 * property rights are retained by XMOS and/or its licensors.
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2008
 */
 
 /*
  * XLinkDataProc - data processor. This is user code and should be replaced with 
  *                                 user specific functionality.
  *                                 This example receives messages containing one
  *                                 byte of data. It increments the data and sends
  *                                 it back to the originating channel end.
  */
  
  
`include "SwitchTokenDef.v"
module XLinkDataProc( 
   clk, reset, 
   
   rx_buf_dout,  
   rx_buf_en,
   rx_buf_empty, 
   
   tx_token_out,
   tx_token_valid,
   tx_token_taken
   
   );

input clk, reset;

// interface with receive buffer
input [8:0] rx_buf_dout;
input rx_buf_empty;
output rx_buf_en;
reg rx_buf_en;

// tx interface
output [8:0] tx_token_out;
reg [8:0] tx_token_out;
output tx_token_valid;
reg tx_token_valid;
input tx_token_taken;

// FSM
reg [3:0] s, s1;

// internals

reg [0:2] d_num;
reg [0:2] d_num_t;

// 4 data tokens
reg [8:0] data_4, data_3, data_2, data_1, data_0;  // workaround for xilink error #1468.
reg [8:0] data_t [4:0]; 

// states
`define START 0
`define READ  1
`define STORE 2
`define SEND_PACKET 3
`define OUTPUT_TOKEN  4
`define OUTPUT_TOKEN_DONE 5

always @(posedge clk or posedge reset)
begin
    if (reset) begin
       s <= `START;
       data_0 <= 0;
       data_1 <= 0;
       data_2 <= 0;
       data_3 <= 0;
       data_4 <= 0;
       d_num <= 0;
    end
    else begin
       s <= s1;
       data_0 <= data_t[0];
       data_1 <= data_t[1];
       data_2 <= data_t[2];
       data_3 <= data_t[3];
       data_4 <= data_t[4];
       d_num <= d_num_t;
    end
end   


always @(*)
begin
    
   
   data_t[0] = data_0;
   data_t[1] = data_1;
   data_t[2] = data_2;
   data_t[3] = data_3;
   data_t[4] = data_4;
   rx_buf_en = 0;
   tx_token_out = 0;
   tx_token_valid = 0;
   s1 = s;
   d_num_t = d_num;


begin
case (s)
    
    // new packet - reset counters
    //0:
	`START:
    begin
       tx_token_valid = 0;
       rx_buf_en = 0;
       if (!rx_buf_empty)
       begin
          d_num_t = 0;
          s1 = `READ;
       end
       else 
       begin
          rx_buf_en = 0;
          s1 = `START;
       end 
    end
    
    // read data from fifo
    //1: 
	`READ:
    begin
       if (!rx_buf_empty)
       begin
           rx_buf_en = 1;
           s1 = `STORE;
       end
    end
    // store data into buffer
    //2:
	`STORE:
    begin   
       data_t[d_num] = rx_buf_dout;
       rx_buf_en = 0;
       d_num_t = d_num + 1;
       
       s1 = `READ;   
       
       if (d_num_t == 5)
       begin
           s1 = `SEND_PACKET;
       end
    end

    //6: 
	`SEND_PACKET:
    begin
      // in this state we have the full data packet, 
      // so we are going to send it back incremented
      // first change the node id to 0:
      data_t[0] = 0;
      // increment the data
      data_t[3] = (data_3 + 1) & 'hFF;  // 8 bits only
      // set the loop counter
      d_num_t = 5;
      // clear the buffer control lines
      rx_buf_en = 0;
      s1 = `OUTPUT_TOKEN;
    end
    
    // output a token to the tx fifo
    //7:
	`OUTPUT_TOKEN:
    begin
      if (d_num == 0)
      begin
         tx_token_valid = 0;
         s1 = `START;
      end
      else
      begin
         case (d_num)
             5: tx_token_out = data_0;   // dest node
             4: tx_token_out = data_1;   // dest proc
             3: tx_token_out = 8'h02;    // dest chan
             2: tx_token_out = data_3;   // data
             1: tx_token_out = `EOM_TOKEN;  // End control token
         endcase 
         tx_token_valid = 1;
         s1 = `OUTPUT_TOKEN_DONE;
      end 
    end
    
    // when token is taken, decrement count
    //8:
	`OUTPUT_TOKEN_DONE:
    begin
        if (tx_token_taken)
        begin
           tx_token_valid = 0;
           d_num_t = d_num - 1;
           if (d_num_t == 0) 
           begin         
             s1 = 0;
           end
           else 
           begin
             s1 = `OUTPUT_TOKEN;
           end
        end
        else begin
           tx_token_valid = 1;
           s1 = `OUTPUT_TOKEN_DONE;
        end
    end
endcase 
end // end reset if

end // end always
    
endmodule
