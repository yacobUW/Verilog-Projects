

module FP_Divider_TB();


reg [15:0] a, b;
reg [4:0] cycles;
reg rst;
reg clk;
wire [15:0] sum;

FP_Divider DUT(clk, rst, a, cycles, b, sum);

initial begin
clk = 0;
rst = 0;

forever #100 clk = ~clk;

end 

initial begin

// My code is currently configured to take in a 8 Bit A value and 4 bit B value. I could make B change to other N values but parameters need to be manually changed.

a = 133;          // if you want to test new values replace these do not add new ones to the end of the rst
b = 2;
// cycles = 1;
cycles = 4;


#25 rst = 1; 

#25 rst = 0;


end

endmodule
