`timescale 1ps / 1ps

module tb_rtl_task5();

	reg CLOCK_50;
	reg [3:0] KEY;
	reg [9:0] SW;
	wire [9:0] LEDR; 
	wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5; 
	reg err; 
	
	task5 dut(CLOCK_50, KEY, SW, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR); 
	
	initial begin
		// Set up for the rise of clock every 10 seconds
		CLOCK_50 = 1'b0;
		#1;
		forever begin
			CLOCK_50 = 1'b1;
			#1;
			CLOCK_50 = 1'b0;
			#1;
		end
	end
	
	initial begin 
		$readmemh("test2.memh", dut.ct.altsyncram_component.m_default.altsyncram_inst.mem_data);
		err = 0; 
		#10; 
		 
		KEY[3] = 0; 
		#10; 
		
		KEY[3] = 1;
		#2600;
		//$stop;
		
		#900000; // 10ps per cycle. Time needed = (256 + 256*6) cycles = 17920ps 
		if (dut.rdy !== 1) begin 
			err = 1; 
			$display("Error: Rdy should be 1 by now"); end 
			
		if (~err) $display("INTERFACE OK");
		$stop;
	end
endmodule: tb_rtl_task5
