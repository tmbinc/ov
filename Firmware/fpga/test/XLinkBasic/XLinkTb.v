/*
 * The copyrights, all other intellectual and industrial
 * property rights are retained by XMOS and/or its licensors.
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2008
 */
 
 /*
  * XlinkTb - testbench. Instantiates xlink_top and sends reset and messages to it.
  *
  */
  
    `timescale 1ns/100ps

module XLinkTb;
    
    // the external stimuli
    reg clk;
    reg reset;
    
    reg rx_0;
    reg rx_1;
    
    wire tx_0, tx_1;
    
    wire led0;
    wire led1;
    wire led2;
    
    //glbl glbl();
   
    XLinkTestTop DUT( 
         .clk(clk), 
         .reset(reset), 
      
         .tx_0(tx_0), 
         .tx_1(tx_1), 
      
         .rx_0(rx_0), 
         .rx_1(rx_1), 
      
         .led0(), 
         .led1(), 
         .led2()
         );
   
    integer i; 


    always
       #10 clk = ~clk;
    

    ///// Send token to device
    task tx_token;
    input [8:0] token;
    integer i;
    begin
        for (i=7; i>=0; i = i - 1) begin
            #40;
            if (token[i])
                rx_1 = !rx_1;
            else
                rx_0 = !rx_0;
        end
        #40;
        
        // cmd/data
        if (token[8])
            rx_1 = !rx_1;
        else
            rx_0 = !rx_0;

        #40;
        // Parity
        if (rx_1)
            rx_1 = !rx_1;
        else
            rx_0 = !rx_0;

        // IPG
        #80;
    end
    endtask

    task parse_token_rx;
        output cmd;
        output [7:0] value;

        integer i;

        reg [1:0] last;
        reg [9:0] rx;
        reg [1:0] _edge;
    begin
        last = {rx_1, rx_0};

        
        for (i=9; i>=0; i = i - 1) begin
            @(rx_1, rx_0);
            _edge = last ^ {rx_1, rx_0};


            if (_edge[1])
                rx[i] = 1;
            else
                rx[i] = 0;

            last = {rx_1, rx_0};
        end
        
        value = rx[9:2];
        cmd = rx[1];
    end
    endtask

    task parse_token_tx;
        output cmd;
        output [7:0] value;

        integer i;

        reg [1:0] last;
        reg [9:0] rx;
        reg [1:0] _edge;
    begin
        last = {tx_1, tx_0};

        
        for (i=9; i>=0; i = i - 1) begin
            @(tx_1, tx_0);
            _edge = last ^ {tx_1, tx_0};


            if (_edge[1])
                rx[i] = 1;
            else
                rx[i] = 0;

            last = {tx_1, tx_0};
        end
        
        value = rx[9:2];
        cmd = rx[1];

    end
    endtask




    /* Parsed data visualizers */
    reg [7:0] fpga_tx_token_data;
    reg fpga_tx_token_type;
    initial begin
        #100;
        while (1)
            parse_token_tx(fpga_tx_token_type, fpga_tx_token_data);
    end

    reg [7:0] sim_tx_token_data;
    reg sim_tx_token_type;
    initial begin
        #100;
        while (1)
            parse_token_rx(sim_tx_token_type, sim_tx_token_data);
    end


    task tx_data_32;
        input [31:0] val;
    begin
        tx_token({1'b1, val[31:24]});
        tx_token({1'b1, val[23:16]});
        tx_token({1'b1, val[15:8]});
        tx_token({1'b1, val[7:0]});
    end
    endtask

    initial
    begin
        $dumpfile("XLinkTb.lxt2");
        $dumpvars(0, DUT);
        $dumpvars(0, fpga_tx_token_type, fpga_tx_token_data, sim_tx_token_type, sim_tx_token_data);

        clk = 0;
        rx_1 = 0;
        rx_0 = 0; 
        reset = 1;
        i = 0;
   
        #100;
        reset = 0;

        #33;

        // SEND HELLO
        tx_token({1'b1, 8'hE6});

        #6000;
	
        /* Write link to initialize */
	tx_data_32(32'h7F000080);        
	tx_data_32(32'h01001002);        

	// Simulate acceptance of the HELLO
	#1000;
	tx_token({1'b1, 8'hE4});
	tx_token({1'b1, 8'hE4});
	tx_token({1'b1, 8'hE4});

	#6000;
        tx_data_32(32'h01000000);        
        tx_data_32(32'h00000007);        
	
	#200;

        tx_data_32(32'hFF000080);        


	#6000;
        tx_data_32(32'h01000000);        
        tx_data_32(32'h00000001);        
        #500;
        tx_data_32(32'h01000000);        
        tx_data_32(32'h00000002);        

        #500;
        tx_data_32(32'h01000000);        
        tx_data_32(32'h00000003);        
       
        
        #500;
        tx_data_32(32'h01000000);        
        tx_data_32(32'h00000004);        
       
        #500;
        tx_data_32(32'h01000000);        
        tx_data_32(32'h00000005);        
       
        #500;
        tx_data_32(32'h81000000);        

        #10000;
    
        $finish;
    end

       
endmodule
