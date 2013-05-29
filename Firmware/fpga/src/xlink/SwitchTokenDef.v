/*
 * The copyrights, all other intellectual and industrial
 * property rights are retained by XMOS and/or its licensors.
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2008
 */
 
 /*
  * SwitchTokenDef - token definitions
  *
  */

 // Number of bits in Token
`define NUM_BITS_IN_TOKEN              9

// Identify whether its Control or Data Token, status of MSB
`define CTL_TOKEN                      1'b1
`define DATA_TOKEN                     1'b0

// Pre-define Tokens.
`define EOP_DATA_VALUE                      8'h02  // EOP is the same as PAUSE to do quick fix in hw
`define EOM_DATA_VALUE                      8'h01
`define EOD_DATA_VALUE                      8'h82
`define ACK_DATA_VALUE                      8'h03
`define NACK_DATA_VALUE                     8'h04
`define PAUSE_DATA_VALUE                    8'h02
`define PSCTL_DATA_VALUE                    8'hc2
`define SSCTL_DATA_VALUE                    8'hc3
`define WRITEC_DATA_VALUE                   8'hc0
`define READC_DATA_VALUE                    8'hc1


`define EOP_TOKEN                      {`CTL_TOKEN, `EOP_DATA_VALUE}  // EOP is the same as PAUSE to do quick fix in hw
`define EOM_TOKEN                      {`CTL_TOKEN, `EOM_DATA_VALUE}
`define EOD_TOKEN                      {`CTL_TOKEN, `EOD_DATA_VALUE}
`define ACK_TOKEN                      {`CTL_TOKEN, `ACK_DATA_VALUE}
`define NACK_TOKEN                     {`CTL_TOKEN, `NACK_DATA_VALUE}
`define PAUSE_TOKEN                    {`CTL_TOKEN, `PAUSE_DATA_VALUE}
`define PSCTRL_TOKEN                   {`CTL_TOKEN, `PSCTL_DATA_VALUE}
`define SSCTRL_TOKEN                   {`CTL_TOKEN, `SSCTL_DATA_VALUE}
`define WRITEC_TOKEN                   {`CTL_TOKEN, `WRITEC_DATA_VALUE}
`define READC_TOKEN                    {`CTL_TOKEN, `READC_DATA_VALUE}




`define CREDIT8_TOKEN                  {`CTL_TOKEN, 8'he0}
`define CREDIT64_TOKEN                 {`CTL_TOKEN, 8'he1}
`define CREDIT16_TOKEN                 {`CTL_TOKEN, 8'he4}
`define HELLO_TOKEN                    {`CTL_TOKEN, 8'he6}



// UNUSED G1 TOKENS
//`define LRESET_TOKEN                   {`CTL_TOKEN, 8'he2}
//`define CREDIT_RESET_TOKEN             {`CTL_TOKEN, 8'he3}

//`endif
