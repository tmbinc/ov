// vim: ts=4:sw=4:et

/* OpenVizsla LED BLOCK
 * LED Module is at 
 *  0100XXXX
 *
 *  1 reg
 *  LED_CTRL
 *
 *  31-24   23-16   15-8    7 6 5 4 3 2     1       0
 *  PWM3    PWM2    PWM1    0 0 0 0 0 LED3  LED2    LED1
 */

`define LED_BASE        15'h0100
`define LED_REG_DIRECT  16'h0000;
module led_module (
    clk,
    reset,
    addr_bus,
    data_bus_wr,
    data_bus_rd,
    wr_strobe,
    rd_strobe,

    leds
    );

    /* 50 MHZ Clock Input */
    input clk;
    
    /* Synchronous reset */
    input reset;


    /* standard address bus stuff */
    input [30:0] addr_bus;
    input [31:0] data_bus_wr;
    output [31:0] data_bus_rd;

    input wr_strobe;
    input rd_strobe;


    output [2:0] leds;

    /* Actual LED Value */
    reg [2:0] leds_r;
    reg [2:0] leds_n;

    /* LEDS are 0-on on PCB */
    assign leds = ~leds_r;

    /* Address bus regs */
    reg [2:0] data_bus_rd_r;
    reg [2:0] data_bus_rd_n;

    /* Addr bus logic */
    wire sel_led_module;
    assign sel_led_module = addr_bus[30:16] == `LED_BASE;

    
    assign data_bus_rd = {29'b0, data_bus_rd_r};

    always @(*) begin
        data_bus_rd_n = 0;
        leds_n = leds_r;

        if (sel_led_module && rd_strobe)
            data_bus_rd_n = leds_r;
        if (sel_led_module && wr_strobe)
            leds_n = data_bus_wr;

    end

    always @(posedge clk)
    begin
        if (reset)
        begin
            leds_r <= 0;
            data_bus_rd_r <= 0;
        end
        else
        begin
            leds_r <= leds_n;
            data_bus_rd_r <= data_bus_rd_n;
        end

    end
endmodule

