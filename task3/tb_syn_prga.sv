`timescale 1ps / 1ps

module tb_syn_prga();

	reg clk, rst_n, en; 
	reg [7:0] ct_rddata, pt_rddata, s_rddata;
	reg [23:0] key;
	wire rdy;
	wire [7:0] ct_addr, pt_addr, pt_wrdata, ct_wrdata, s_addr, s_wrdata;
	wire pt_wren, ct_wren, s_wren;
	reg err;
	
	prga dut(clk, rst_n, en, rdy, key, s_addr, s_rddata, s_wrdata, s_wren, ct_addr, ct_rddata, pt_addr, pt_rddata, pt_wrdata, pt_wren);
	
	s_mem s(s_addr, clk, s_wrdata, s_wren, s_rddata);
	
	ct_mem ct(ct_addr, clk, ct_wrdata, ct_wren, ct_rddata);
	
    pt_mem pt(pt_addr, clk, pt_wrdata, pt_wren, pt_rddata);
	
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
		$readmemh("test2.memh", s.altsyncram_component.m_default.altsyncram_inst.mem_data);
		$readmemh("test2.memh", ct.altsyncram_component.m_default.altsyncram_inst.mem_data);
		key = 'h000018;
		err = 0; 
		#10; 
		
		rst_n = 0; 
		en = 1;
		#10; 
		
		rst_n = 1;
		#50; 
		en = 0; 
		#2600;
		//$stop;
		
		#30000; // 10ps per cycle. Time needed = (256 + 256*6) cycles = 17920ps 
			
		if (~err) $display("INTERFACE OK");
		$stop;
	end

endmodule: tb_syn_prga
