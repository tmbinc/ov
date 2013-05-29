/*
 * The copyrights, all other intellectual and industrial
 * property rights are retained by XMOS and/or its licensors.
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2008
 */
 
 /*
  * SwitchCommonDef - switch definitions
  *
  */

// Generic Token definations.
`include "SwitchTokenDef.v"




`define RESET_VALUE 1'b 0

`define NODE_ID_BITS                   8     // Number of bits in Node ID,
`define PROC_ID_BITS                   8     // Max processor ID bits.
`define LLINK_ID_BITS                  8     // Max channelEnds (aka LLinks)

`define NUM_NETWORKS                   4
`define NUM_NETWORKS_BITS              2     // number of bits required for networks.

// This is also define int definations.v
`ifdef _SWITCH_STAND_ALONE_SIMULATION_
`define NUM_THREADS                    8     // number of threads per processor.
`endif

// This ifdef is required.
`ifdef _SWITCH_STAND_ALONE_SIMULATION_
// Sync. Reset level. 
`define SSWITCH_RESET_LEVEL            1'b0
`else
// Sync. Reset level. 
`define SSWITCH_RESET_LEVEL            `RESET_VALUE		// defined in definations.v
`endif

`define CLK_DIVIDER_UPDATE_KEY         8'hEA

//*****************
// Assertions.
//*****************
 
`define ASSERT_INFO(x)     else begin $info(x);    end
`define ASSERT_WARNING(x)  else begin $warning(x); end
`define ASSERT_ERROR(x)    else begin $error(x);   end
`define ASSERT_FATAL(x)    else begin $fatal(x);   end
