`timescale 1ps / 1ps

module tb_syn_task4();

	reg CLOCK_50;
	reg [3:0] KEY;
	reg [9:0] SW;
	wire [9:0] LEDR; 
	wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5; 
	wire altera_reserved_tck, altera_reserved_tdi, altera_reserved_tdo, altera_reserved_tms;
	reg err; 
	
	task4 dut(.*, .altera_reserved_tms(altera_reserved_tms), .altera_reserved_tck(altera_reserved_tck), .altera_reserved_tdi(altera_reserved_tdi), .altera_reserved_tdo(altera_reserved_tdo));
	
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
		$readmemh("test2.memh", dut.\ct|altsyncram_component|auto_generated|altsyncram1|ram_block3a0 .ram_core0.ram_core0.mem);
		err = 0; 
		#10; 
		
		KEY[3] = 0; 
		#10; 
		
		KEY[3] = 1;
		#2600;
		//$stop;
		
		#900000; // 10ps per cycle. Time needed = (256 + 256*6) cycles = 17920ps 
			
		if (~err) $display("INTERFACE OK");
		$stop;
	end

endmodule: tb_syn_task4
