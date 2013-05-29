module SimpleLinkDataProcessor (
    clk,
    reset,

    rx_buf_dout,
    rx_buf_en,
    rx_buf_empty,


    tx_token_out,
    tx_token_valid,
    tx_token_taken,

    addr,
    
    data_bus_wr,
    data_bus_rd,

    wr_strobe,
    rd_strobe
    );

    input clk, reset;

    
    /* Internal bus */
    output wr_strobe;
    reg wr_strobe;

    output rd_strobe;
    reg rd_strobe;

    output [30:0] addr;
    output [31:0] data_bus_wr;
    input [31:0] data_bus_rd;

    /* XLINK Fifos */
    input [8:0] rx_buf_dout;
    input rx_buf_empty;
    output rx_buf_en;
    reg rx_buf_en;

    output [8:0] tx_token_out;
    reg [8:0] tx_token_out;
    output tx_token_valid;
    reg tx_token_valid;
    input tx_token_taken;


    /* Statemachine */
    reg store_sm; // Next cycle store

    reg [3:0] s;
    reg [3:0] s_n;

    `define IDLE        0
    
    `define RX_ADDR_0   1
    `define RX_ADDR_1   2
    `define RX_ADDR_2   3
    `define RX_ADDR_3   4

    `define RX_VALUE_0  5
    `define RX_VALUE_1  6
    `define RX_VALUE_2  7
    `define RX_VALUE_3  8

    `define DO_READ     9
    `define CAPTURE_D   10

    `define DO_WRITE    11

    `define TX_VALUE_0  12
    `define TX_VALUE_1  13
    `define TX_VALUE_2  14
    `define TX_VALUE_3  15


    reg [31:0] addr_in;
    reg [31:0] addr_in_n;
    assign addr = addr_in[30:0];
    wire nW_R = addr_in[31];

    reg [31:0] value;
    assign data_bus_wr = value;
    
    reg [31:0] value_n;


    always @(posedge clk)
    begin
        if  (reset)
        begin
            s <= `IDLE;
            addr_in <= 0;
            value <= 0;
            store_sm <= 0;
        end
        else
        begin
            s <= s_n;
            addr_in <= addr_in_n;
            value <= value_n;
            store_sm <= rx_buf_en;
        end
    end


    always @(*)
    begin
        addr_in_n = addr_in;
        value_n = value;

        /* FIFO signals */
        rx_buf_en = 0;
        tx_token_out = 0;
        tx_token_valid = 0;

        /* Address bus signals */
        rd_strobe = 0;
        wr_strobe = 0;

        s_n = s;

        case (s)
            `IDLE: begin
                if (!rx_buf_empty) begin
                    s_n = `RX_ADDR_0;
                    rx_buf_en = 1;
                end
            end

            /************** Address Reception ***************/
            `RX_ADDR_0: begin
                if (store_sm)
                    addr_in_n[31:24] = rx_buf_dout;
                
                if (!rx_buf_empty) begin
                    s_n = `RX_ADDR_1;
                    rx_buf_en = 1;
                end
            end


            `RX_ADDR_1: begin
                if (store_sm)
                    addr_in_n[23:16] = rx_buf_dout;
                
                if (!rx_buf_empty) begin
                    s_n = `RX_ADDR_2;
                    rx_buf_en = 1;
                end
            end

            `RX_ADDR_2: begin
                if (store_sm)
                    addr_in_n[15:8] = rx_buf_dout;
                
                if (!rx_buf_empty) begin
                    s_n = `RX_ADDR_3;
                    rx_buf_en = 1;
                end
            end
             
            `RX_ADDR_3: begin
                // If we setup the address do the write
                if (store_sm) begin
                    addr_in_n[7:0] = rx_buf_dout;

                    if (nW_R)
                        s_n = `DO_READ;
                end


                if (!rx_buf_empty && !nW_R) begin
                    s_n = `RX_VALUE_0;
                    rx_buf_en = 1;
                end
            end

            /***************************** VALUE [if needed] RECEPTION ******/
            `RX_VALUE_0: begin
                if (store_sm)
                    value_n[31:24] = rx_buf_dout;
                
                if (!rx_buf_empty) begin
                    s_n = `RX_VALUE_1;
                    rx_buf_en = 1;
                end
            end


            `RX_VALUE_1: begin
                if (store_sm)
                    value_n[23:16] = rx_buf_dout;
                
                if (!rx_buf_empty) begin
                    s_n = `RX_VALUE_2;
                    rx_buf_en = 1;
                end
            end

            `RX_VALUE_2: begin
                if (store_sm)
                    value_n[15:8] = rx_buf_dout;
                
                if (!rx_buf_empty) begin
                    s_n = `RX_VALUE_3;
                    rx_buf_en = 1;
                end
            end
             
            `RX_VALUE_3: begin
                if (store_sm) begin
                    value_n[7:0] = rx_buf_dout;
                    s_n = `DO_WRITE;
                end
            end

            /****** WRITE LOGIC *************/
            `DO_WRITE: begin
                wr_strobe = 1;
                s_n = `IDLE;
            end

            /****** READ LOGIC **************/

            `DO_READ: begin
                rd_strobe = 1;
                s_n = `CAPTURE_D;
            end

            `CAPTURE_D: begin
                value_n = data_bus_rd;
                s_n = `TX_VALUE_0;
            end

            `TX_VALUE_0: begin
                tx_token_valid = 1;
                tx_token_out = value[31:24];

                if (tx_token_taken) begin
                    tx_token_valid = 0;
                    s_n = `TX_VALUE_1;
                end
            end

            `TX_VALUE_1: begin
                tx_token_valid = 1;
                tx_token_out = value[23:16];

                if (tx_token_taken) begin
                    tx_token_valid = 0;
                    s_n = `TX_VALUE_2;
                end
            end

            `TX_VALUE_2: begin
                tx_token_valid = 1;
                tx_token_out = value[15:8];

                if (tx_token_taken) begin
                    tx_token_valid = 0;
                    s_n = `TX_VALUE_3;
                end
            end

            `TX_VALUE_3: begin
                tx_token_valid = 1;
                tx_token_out = value[7:0];

                if (tx_token_taken) begin
                    tx_token_valid = 0;
                    s_n = `IDLE;
                end
            end


                
        endcase

    end

endmodule
