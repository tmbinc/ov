/*
 * The copyrights, all other intellectual and industrial
 * property rights are retained by XMOS and/or its licensors.
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2008
 */

/*
 * XLinkCntrl - controls sending and receiving of reset and credit tokens.
 *              Passes received tokens onto data processor, and receives tokens to be transmitted.
 *
 */

`include "SwitchCommonDef.v"

module XLinkCntrl(
    clk, 
    reset, 

    rx_token, 
    rx_token_valid, 
    rx_error, 

    tx_token_buf_in,  
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

input clk;
input reset;

// rx interface
input [8:0]rx_token;
input rx_token_valid;
input rx_error;

// tx buffer interface
output [8:0] tx_token_buf_in;
reg [8:0] tx_token_buf_in;
output tx_buf_wen;
reg tx_buf_wen;

//rx buffer interface
output [8:0] rx_token_buf_in;
reg [8:0] rx_token_buf_in; 
output rx_buf_wen;
reg rx_buf_wen;

//tx interface for data handling module
input [8:0] tx_d_token;
input tx_d_token_valid;
output tx_d_token_taken;
reg tx_d_token_taken;


/* Inputs to support link status/configuration register */
input link_reset_state_machine;
input link_issue_hello;

output link_has_credits;
output link_issued_credits;


// internals
reg link_reset;
reg should_send_hello, should_send_hello_n;

// credit counters
reg [7:0] credit_cnt;
reg [7:0] remote_credit_cnt;

assign link_has_credits = |credit_cnt;
assign link_issued_credits = |remote_credit_cnt;

// state machine
reg [4:0] s, s1;




// states 
`define START                5'h0
`define SEND_DATA            5'h8
`define RECEIVE_DATA         5'h9

`define RST_RESET_RECEIVED   5'h1
`define RST_SEND_CREDIT1     5'h2
`define RST_DONE             5'h7

`define SEND_HELLO_1         5'h3


// state transitions
always @(*)
begin
    s1 = `START;

    should_send_hello_n = should_send_hello || link_issue_hello;

    case (s)

        `START:
        begin
            if (rx_token_valid & (rx_token[8] == 1))
            begin
                case (rx_token)
                    `HELLO_TOKEN:   s1 = `RST_RESET_RECEIVED; // next state sends credit
                    `CREDIT64_TOKEN: s1 = `START;
                    `CREDIT8_TOKEN:  s1 = `START;
                    `CREDIT16_TOKEN: s1 = `START;
                    default:
                    begin
                        // forward control token to user. 
                        s1 = `SEND_DATA;
                    end
                endcase
            end // end control token handling
            else if (rx_token_valid & (rx_token[8] == 0)) // data token
                s1 = `SEND_DATA;
            else if (tx_d_token_valid & (credit_cnt > 0)) // data processing is giving us something to tx
                s1 = `RECEIVE_DATA;
            else if ((remote_credit_cnt <= 8) & link_reset)
                s1 = `START;
            else if (should_send_hello_n)
            begin
                s1 = `SEND_HELLO_1;
                should_send_hello_n = 0;
            end
            else 
                s1 = `START;
        end



        `SEND_DATA: 
            s1 = `START;
        `RECEIVE_DATA: 
            s1 = `START;


        `RST_RESET_RECEIVED:
            s1 = `RST_SEND_CREDIT1;

        `RST_SEND_CREDIT1:
            s1 = `RST_DONE; 

        `RST_DONE: 
            s1 = `START;

        `SEND_HELLO_1:
            s1 = `START;

        default: 
            s1 = `START;

    endcase

end // end always


    // actions for states
always @(posedge clk)
begin
    if (reset) begin
        credit_cnt <= 0;
        remote_credit_cnt <= 0;
        tx_token_buf_in <= 0;
        tx_buf_wen <= 0;
        rx_token_buf_in <= 0; 
        rx_buf_wen <= 0;
        tx_d_token_taken <= 0;
        link_reset <= 0;
        should_send_hello <= 0;
    end
    else
    begin
        should_send_hello <= should_send_hello_n;

    case (s)
        `START:
        begin
            rx_token_buf_in <= 0; 
            rx_buf_wen <= 0;
            tx_token_buf_in <= 0;
            tx_buf_wen <= 0;
            tx_d_token_taken <= 0;

            /* If received control token */
            if (rx_token_valid & (rx_token[8] == 1))
            begin
            case (rx_token)
                `HELLO_TOKEN:   
                begin
                    credit_cnt <= 0;
                    remote_credit_cnt <= 0;
                end  

                `CREDIT64_TOKEN: 
                begin 
                    if (link_reset) 
                        credit_cnt <= credit_cnt + 64;
                end  
                
                `CREDIT8_TOKEN:  
                begin
                    if (link_reset) 
                        credit_cnt <= credit_cnt + 8;
                end
                
                `CREDIT16_TOKEN:
                begin
                    if (link_reset)
                        credit_cnt <= credit_cnt + 16;
                end

                default: begin
                    remote_credit_cnt <= remote_credit_cnt - 1;
                    rx_token_buf_in <= rx_token[8:0];
                  rx_buf_wen <= 1;
                end
            endcase
            end
            // ELIF Received Data Token
            else if (rx_token_valid & (rx_token[8] == 0)) 
            begin
                remote_credit_cnt <= remote_credit_cnt - 1;
                rx_token_buf_in <= rx_token[7:0];
                rx_buf_wen <= 1;
            end
            // ELIF TX Token ready and we have credits
            else if (tx_d_token_valid & (credit_cnt > 0)) 
            begin
                // data processing module has given us a tx value
                credit_cnt <= credit_cnt - 1;
                //tx_d_token_r = tx_d_token;
                tx_token_buf_in <= tx_d_token;
                tx_buf_wen <= 1;
            end 
            // ELIF the remote link is short on credits
            else if ((remote_credit_cnt <= 8) & link_reset) 
            begin
                tx_token_buf_in <= `CREDIT64_TOKEN;
                remote_credit_cnt <= remote_credit_cnt + 64;
                tx_buf_wen <= 1'b1;
            end // end of giving remote unit credit
            else if (should_send_hello | link_issue_hello)
            begin
                tx_token_buf_in <= `HELLO_TOKEN;
                tx_buf_wen <= 1'b1;
                credit_cnt <= 0;
                link_reset <= 1;
            end
            else 
            begin
                tx_token_buf_in <= 0; 
                tx_buf_wen <= 0;
            end
        end



        `SEND_DATA:
        begin
            rx_token_buf_in <= 0; 
            rx_buf_wen <= 0;
        end

        
        `RECEIVE_DATA:
        begin
            tx_token_buf_in <= 0;
            tx_buf_wen <= 0;
            tx_d_token_taken <= 1;
        end


        `RST_RESET_RECEIVED:  // reset received. Reset rx and tx credit counters
        begin
            tx_token_buf_in <= `CREDIT64_TOKEN;
            remote_credit_cnt <= 64;
            credit_cnt <= 0;
            tx_buf_wen <= 1'b1;
        end
        
        `RST_SEND_CREDIT1:
        begin
            tx_buf_wen <= 1'b0;
        end   

        `SEND_HELLO_1:
            tx_buf_wen <= 1'b0;

        `RST_DONE: 
        begin
            tx_buf_wen <= 1'b0;
        end
    endcase
    end 
end

    // update state
always @(posedge clk)
begin
    if (reset)
    begin
        s <= 0;
    end 
    else
    begin
        s <= s1;
    end
end

endmodule
