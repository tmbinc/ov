// top.v

module LEDglow(clk, LED, out);
input clk;
output LED, out;

reg [23:0] cnt;
always @(posedge clk) cnt<=cnt+1;

wire [3:0] PWM_input = cnt[23] ? cnt[22:19] : ~cnt[22:19];
reg [4:0] PWM;
always @(posedge clk) PWM <= PWM[3:0]+PWM_input;

assign LED = PWM[4];
assign out = clk;
endmodule