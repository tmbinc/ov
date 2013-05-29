/*
 * The copyrights, all other intellectual and industrial
 * property rights are retained by XMOS and/or its licensors.
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2008
 */
 
 /*
  * XLinkDefines
  *
  */

 
`define RX_TIME_OUT        8'hFF

// Tx statmachine.
`define TX_IDEAL           2'b00
`define TX_BIT_TX          2'b01
`define TX_BIT_WAIT        2'b10
`define TX_TOKEN_WAIT      2'b11


 
// 5bits XLink Value codeing.
`define NUM_BITS_5B_CODE   3     // Number of bits in 5B coding

`define V0_5B_CODE         3'b100
`define V1_5B_CODE         3'b101
`define V2_5B_CODE         3'b110
`define V3_5B_CODE         3'b111

`define E0_5B_CODE         3'b011

`define INVALID_5B_CODE    3'b000

// INVALID token.
`define INVALID_5B_TOKEN   9'h1FF

// Double escape EOM/PAUSE token.
`define DOUBLE_ESP_EOM_TOKEN     `V0_5B_CODE
`define DOUBLE_ESP_PAUSE_TOKEN   `V1_5B_CODE
`define DOUBLE_ESP_RTZ_TOKEN     `V2_5B_CODE

// expectional data coding
`define CREDIT8_DATA_CODING         2'b00
`define CREDIT64_DATA_CODING        2'b01
`define LRESET_DATA_CODING          2'b10
`define CREDIT_RESET_DATA_CODING    2'b11

