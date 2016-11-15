module test_bench;
	reg [31:0] a,b;
	reg clk,rst;
	wire [31:0] z;
	wire ofw;

	FloatAdder adder(clk,rst,a,b,z,ofw);

	initial
	begin
		a = 32'b01111111100000000000000000000001;
		b = 32'b01111111100000000000000000000011;
		rst<=0;
		clk <=1'b0;
		while(1)
		begin
			#5 clk <= ~clk;
		end
	end	

	initial $monitor($time, "a=%h, b=%h,result=%b,ofw=%b",a,b,z,ofw);
	initial #5000 $stop;
endmodule
