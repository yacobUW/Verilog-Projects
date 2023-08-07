

module FP_Divider(input clk, input rst, input [7:0] a, input [4:0] accuracy_cycles, input [7:0] b, output [15:0] sum); 

parameter n = 8; // supporting 8 bit division

// wire [n-1:0] fixed_point; 

wire [7:0] fracb, eb;
wire [7:0] fraca, ea;


reg [4:0] count;

wire [4:0] t_cy;
assign t_cy = accuracy_cycles;

wire [n-1:0] normalize_b;

reg stop;



normalize normb(b, eb);
normalize norma(a, ea);


twoscomp invb(b, eb, normalize_b); 

reg [16:0] reciprocal;

reg [7:0] Qout;
reg [7:0] QoutC;


wire [8:0] RB;

reg addcy1; 
reg mulcy1;

wire [8:0] taylorsum;
wire [8:0] reciprocal_sum;


always @(posedge clk or posedge rst) begin

if (rst) begin

count <= 0;
stop <= 0;


end else if(count == t_cy) begin 

stop <= 1;
count <= count;
end else if(~stop) begin 

count <= count + 1;

end

end


multiplier multi(normalize_b, stop, clk, rst, taylorsum); //  have a stop value called when the t is finished. Then check for the stop value next so that we know if we should do the reciprocal calculations. if not then we can just allways do them.   but we want the accumulator to stop once T is reached


accumilator add(taylorsum, normalize_b, stop, rst, clk, reciprocal_sum);   // fracb is same as b or fixed_b

assign RB[8] = 1;  // This is how I am adding 1 to the left most bit
assign RB[7:0] = reciprocal_sum; 

wire [4:0] s;

reg [7:0] trun_reciprocal;
reg [7:0] Qout_shifted;

reg [7:0] whole_number = 1;

LUT Svalue(t_cy, n, s);


always @(*) begin 


	if (stop) begin

	reciprocal = RB[8:0] * a; 
	
	trun_reciprocal = reciprocal[16:9];

	// Qout =  reciprocal << (ea - eb); 
	{whole_number, Qout} =  trun_reciprocal << ((ea - eb) + 1);   // whole number is 8 bits
	// Qout =  trun_reciprocal << (ea - eb); 
	Qout_shifted = (Qout >> s);

	QoutC = Qout + Qout_shifted;

	end 
end 

assign sum = {whole_number,QoutC};


endmodule


//////////////////////////////////////////////

module normalize(input[7:0] variable, output reg [7:0] ex);

always @(*) begin

	casex(variable)

	8'b1xxxxxxx: ex = 8;
	8'b01xxxxxx: ex = 7;
	8'b001xxxxx: ex = 6;
	8'b0001xxxx: ex = 5;
	8'b00001xxx: ex = 4;
	8'b000001xx: ex = 3;
	8'b0000001x: ex = 2;
	8'b00000001: ex = 1;
	default: ex = 0; 
	endcase
end  
 
endmodule

//////////////////////////////////////////////

module twoscomp(input [7:0] frac, input [7:0] sizing, output wire [8:0] result);

reg [7:0] invert;
reg [7:0] match = 0;
parameter WIDTH = 8; // Define a constant parameter for the input size
integer i;


reg start = 1;
reg copy = 0;

always @* begin
 
    invert = ~frac;
	

	for(i = WIDTH-1; i >= 0; i = i-1) begin
	
		if(start & (~invert[i])) begin

			// match[i:0] = invert[i:0];
			start = 0;
			copy = 1;
			match[i] = invert[i];
		end else if(copy) begin
		
		match[i] = invert[i];
		end
	end
end

assign result = match + 1; 

endmodule


///////////////////////////////////////////////////
 
module multiplier(input [7:0] multiplier, input pause, input clk, input rst, output [8:0] result);     // try to combine this and the accumilator module


parameter N_b = 4;

wire [7:0] multiplier_trun;

reg first = 1;

assign multiplier_trun = multiplier << (8 - N_b);
// assign multiplier_trun = multiplier << (8 - N_b);


reg [15:0] repeated = 0;

    always @(posedge clk or posedge rst) begin     // 
        if (rst) begin
            // repeated <= multiplier * multiplier; //  * multiplier;
			repeated <= multiplier_trun * multiplier_trun;
            // result <= 0;
        end else if (~pause) begin
            // repeated <= repeated * multiplier;
	
            // repeated <= first ? repeated[7:0] * multiplier_trun : repeated[15:8] * multiplier_trun; // this only needed for 4 bit n
			repeated <= repeated[15:8] * multiplier_trun;

			first = 0;
			
        end
    end
	
	assign result = repeated[15:8];

endmodule



///////////////////////////////////////////////


module accumilator (input [7:0] a, input [7:0] starting, input stopping, input rst, input clk, output [7:0] accum_sum); // dont forget to define the done in this code
 
reg overflow;
reg carry;
 
reg [7:0] reg1;
wire [7:0] sum1;
wire cout;
reg [7:0] reg2;


assign {cout,sum1} = accum_sum + reg1;


parameter N_b = 4;

wire [7:0] starting_trun;

assign starting_trun = starting << (8 - N_b);


always@(posedge clk or posedge rst) begin


if(rst) begin 
	reg1 <= 0; // starting * starting;
	reg2 <= starting_trun;     // this needs to be trunucated
	carry <= 0;
	overflow <= 0;
	
end else if(~stopping) begin
	reg1 <= a;
	reg2 <= sum1;
	carry <= cout;

	if (sum1[7] == 1) 
		begin 
			overflow <= 1'b1;
		end
	else 
		begin
		overflow <= 1'b0;
		end
end 

end

//assign LEDR[8] = carry;
//assign LEDR[9] = overflow;

assign accum_sum = reg2;

endmodule 

///////////////////////////////////////////////////

module LUT(input [4:0] t, input [4:0] n, output reg [4:0] s);

always @* begin

	if(n == 4) begin
		case(t)
		1: s = 3;
		2: s = 3;
		default: s = 0;
		endcase
	end
	
	if(n == 8) begin
		case(t)
		1: s = 4;
		2: s = 6;
		3: s = 6;
		4: s = 6;
		5: s = 7;
		6: s = 7;
		7: s = 7;
		default: s = 0;
		endcase
	end
	
end 

endmodule

