module task1(input logic CLOCK_50, input logic [3:0] KEY, input logic [9:0] SW,
             output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
             output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
             output logic [9:0] LEDR);

	wire reset = KEY[3];
	wire clk = CLOCK_50; 
	wire [7:0] addr, wrdata;
	wire wren;
	reg en; 
	
    s_mem s( addr, clk, wrdata, wren, q );
	
	init I(clk, reset, en, rdy, addr, wrdata, wren);
			
    always_ff @(posedge clk or negedge reset) begin 
		if (~reset) 
			en <= 1'b1; 
		else
			en <= 1'b0; 
	end	

endmodule: task1
