`timescale 1ps / 1ps

module tb_syn_ksa();

	reg clk, rst_n, en; 
	reg [7:0] rddata;
	reg [23:0] key;
	wire rdy;
	wire [7:0] addr, wrdata, q;
	wire wren; 
	reg err;

	ksa dut(.*);
	
	s_mem s( addr, clk, wrdata, wren, rddata );
	
	initial begin
		// Set up for the rise of clock every 10 seconds
		clk = 1'b0;
		#5;
		forever begin
			clk = 1'b1;
			#5;
			clk = 1'b0;
			#5;
		end
	end
	
	initial begin
		$readmemh("test1.memh", s.altsyncram_component.m_default.altsyncram_inst.mem_data);
		err = 0; 
		#10; 
		
		key = 24'b000000000000001100111100;  
		rst_n = 0; 
		en = 1;
		#10; 
		
		rst_n = 1;
		#10; 
		en = 0;
		#2600;
		//$stop;
		
		#17000; // 10ps per cycle. Time needed = (256 + 256*6) cycles = 17920ps 
		if (rdy !== 1) begin 
			err = 1; 
			$display("Error: Rdy should be 1 by now"); end 	
			
		if (~err) $display("INTERFACE OK");
		$stop;
	end


endmodule: tb_syn_ksa
