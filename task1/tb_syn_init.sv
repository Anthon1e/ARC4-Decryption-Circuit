`timescale 1ps / 1ps

module tb_syn_init();

	reg clk, rst_n, en; 
	wire rdy;
	wire [7:0] addr, wrdata;
	wire wren; 
	reg err; 
	
	init dut(.*);
	
	initial begin
		// Set up for the rise of clock every 10 seconds
		clk = 1'b0;
		#1;
		forever begin
			clk = 1'b1;
			#1;
			clk = 1'b0;
			#1;
		end
	end
	
	initial begin 
		err = 0; 
		#10; 
		 
		rst_n = 0; 
		#10; 
		
		rst_n = 1;
		#2600;
		
		#10000; // 10ps per cycle. Time needed = (256 + 256*6) cycles = 17920ps 
			
		if (~err) $display("INTERFACE OK");
		$stop;
	end
endmodule: tb_syn_init
