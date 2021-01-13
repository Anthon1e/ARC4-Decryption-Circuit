`timescale 1ps / 1ps

module tb_syn_crack();

	reg clk, rst_n, en, key_crack;
	reg [7:0] ct_rddata, msg_length, pt_addr_db;
	wire rdy, key_valid, ct_wren;
	wire [23:0] key; 
	wire [7:0] ct_addr, ct_wrdata, pt_rddata;
	reg err; 
	
	ct_mem ct(ct_addr, clk, ct_wrdata, ct_wren, ct_rddata);
	
	crack dut(clk, rst_n, en, rdy, key, key_valid, ct_addr, ct_rddata, msg_length, key_crack, pt_addr_db, pt_rddata);
	
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
		$readmemh("test2.memh", ct.altsyncram_component.m_default.altsyncram_inst.mem_data);
		err = 0; 
		key_crack = 0;
		msg_length = 'h35;
		#10; 
		
		rst_n = 0; 
		en = 1;
		#10; 
		
		rst_n = 1;
		#50; 
		en = 0; 
		#2600;
		
		#300000; // 10ps per cycle. Time needed = (256 + 256*6) cycles = 17920ps 
			
		if (~err) $display("INTERFACE OK");
		$stop;
	end
endmodule: tb_syn_crack
