module task2(input logic CLOCK_50, input logic [3:0] KEY, input logic [9:0] SW,
             output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
             output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
             output logic [9:0] LEDR);

    wire reset = KEY[3];
	wire clk = CLOCK_50; 
	wire [23:0] key; 
	assign key[23:10] = 14'b00000000000000; 
	assign key[9:0] = SW[9:0]; 
	
	reg [7:0] addr, addr_init, addr_ksa, wrdata, wrdata_init, wrdata_ksa, q;
	reg wren, wren_init, wren_ksa;
	
	wire rdy_init, rdy_ksa;
	reg en_init, en_ksa, mode; 
	
	s_mem s( addr, clk, wrdata, wren, q );
	
	init i(clk, reset, en_init, rdy_init, addr_init, wrdata_init, wren_init);
	
	ksa k(clk, reset, en_ksa, rdy_ksa, key, addr_ksa, q, wrdata_ksa, wren_ksa); 
	
	always_ff @(posedge clk or negedge reset) begin 
		if (~reset) begin 
			en_init <= 1;
			en_ksa <= 0;
			mode <= 0; end
		else if ((rdy_ksa == 1) && (q == 8'b11111111)) begin 
			en_init <= 0; 
			en_ksa <= 1; 
			mode <= 1; end
		else if (en_ksa)
			en_ksa <= 0;
		else begin 
			en_init <= 0; 
			en_ksa <= en_ksa; 
			mode <= mode; end
	end	
	
	always_comb begin 
		if (~mode) begin 
			wren = wren_init; 
			addr = addr_init; 
			wrdata = wrdata_init; end
		else begin
			wren = wren_ksa;
			addr = addr_ksa; 
			wrdata = wrdata_ksa; end
	end
endmodule: task2

module init(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            output logic [7:0] addr, output logic [7:0] wrdata, output logic wren);

	`define STATE0 4'b0000 // Restart state 
	`define STATE1 4'b0001 
	`define STATE2 4'b0010 
	`define STATE3 4'b0011 
	`define STATE4 4'b0100 
	`define STATE5 4'b0101 
	`define STATE6 4'b0110 
	`define STATE7 4'b0111 
	`define STATE8 4'b1000
	`define STATE9 4'b1001 
	
	reg [3:0] cs, ns;
	
	always_ff @(posedge clk or negedge rst_n) begin 
		if (~rst_n) begin
			cs <= `STATE4;
			wren = 0;
			rdy <= 1'b1; end
		else if (en) begin 
			rdy = 1'b0; 
			cs = `STATE0; end 
		else begin 
			case (cs) 
			`STATE0: begin 
				addr = 8'b00000000;
				wrdata = 8'b00000000;
				wren = 1; 
				ns = `STATE1; end 
			`STATE1: begin
				addr = addr + 1;
				wrdata = wrdata + 1;
				wren = 1;
				if (addr == 8'b11111111)
					ns = `STATE2; 
				else
					ns = `STATE1; end 
			`STATE2: begin 
				ns = `STATE3; 
				rdy = 1'b1;  
				addr = 8'bzzzzzzzz;
				wrdata = 8'bzzzzzzzz;
				wren = 1'bz; end
			`STATE3: begin 
				ns = `STATE3; 
				rdy = 1'b1; end
			`STATE4: begin 
				ns = `STATE4; end 
			default: begin 
				rdy = 1'bx; 
				addr = 8'bxxxxxxxx;
				wrdata = 8'bxxxxxxxx;
				wren = 1'bx; 
				ns = 4'bxxxx; end
			endcase 
			cs <= ns; 
		end	
	end 
endmodule: init