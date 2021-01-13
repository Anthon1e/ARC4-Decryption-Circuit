module arc4(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            input logic [23:0] key,
            output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
            output logic [7:0] pt_addr, input logic [7:0] pt_rddata, output logic [7:0] pt_wrdata, output logic pt_wren);

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
	
	reg [7:0] addr, addr_init, addr_ksa, wrdata, wrdata_init, wrdata_ksa;
	reg [7:0] q; 
	reg wren, wren_init, wren_ksa;
	
	wire [7:0] s_addr, s_wrdata;
	wire s_wren; 
	wire rdy_init, rdy_ksa, rdy_prga;
	reg en_init, en_ksa, en_prga;
	reg [1:0] mode; 
	reg [3:0] cs, ns;

    s_mem s(addr, clk, wrdata, wren, q);
	
	init i(clk, rst_n, en_init, rdy_init, addr_init, wrdata_init, wren_init);
	
	ksa k(clk, rst_n, en_ksa, rdy_ksa, key, addr_ksa, q, wrdata_ksa, wren_ksa); 
	
    prga p (clk, rst_n, en_prga, rdy_prga, key, 
			s_addr, q, s_wrdata, s_wren,
            ct_addr, ct_rddata,
            pt_addr, pt_rddata, pt_wrdata, pt_wren);
			
	always_ff @(posedge clk or negedge rst_n) begin 
		if (~rst_n) begin
			en_init = 0; 
			en_ksa = 0;
			en_prga = 0; 
			rdy = 1; 
			cs = `STATE7; end 
		else if (en) begin 
			en_init = 1; 
			rdy = 0; 
			cs = `STATE0; end
		else begin 
			case (cs)
			`STATE0: begin  			// Init State 
				en_init = 0; 
				mode = 2'b00; 
				ns = `STATE1; end 
			`STATE1: begin  
				if (rdy_init) begin 
					ns = `STATE2; 
					en_ksa = 1; end 
				else 
					ns = `STATE1; end
			`STATE2: begin 				// Ksa State 
				en_ksa = 0;
				mode = 2'b01;
				ns = `STATE3; end
			`STATE3: begin  
				if (rdy_ksa) begin 
					ns = `STATE4; 
					en_prga = 1; end
				else 
					ns = `STATE3; end
			`STATE4: begin 				// Prga State
				en_prga = 0;	
				mode = 2'b10; 
				ns = `STATE5; end 
			`STATE5: begin 
				if (rdy_prga)
					ns = `STATE6;
				else 
					ns = `STATE5; end
			`STATE6: begin 
				rdy = 1; 
				ns = `STATE6; end
			`STATE7: begin 
				rdy = 0; 
				ns = `STATE7; end	
			default: begin 
				rdy = 1'bx; 
				ns = 4'bxxxx;
				mode = 2'bxx; 
				en_init = 1'bx; 
				en_ksa = 1'bx;
				en_prga = 1'bx; end
			endcase
			cs <= ns; 
		end	
	end 
	
	always_comb begin 
		case (mode) 
		2'b00: begin 
			wren = wren_init; 
			addr = addr_init; 
			wrdata = wrdata_init; end 
		2'b01: begin 
			wren = wren_ksa;
			addr = addr_ksa; 
			wrdata = wrdata_ksa; end 
		2'b10: begin 
			wren = s_wren; 
			addr = s_addr; 
			wrdata = s_wrdata; end 
		default: begin 
			wren = 1'bx; 
			addr = 8'bxxxxxxxx; 
			wrdata = 8'bxxxxxxxx; end
		endcase
	end
endmodule: arc4

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

module ksa(input logic clk, input logic rst_n,
           input logic en, output logic rdy,
           input logic [23:0] key,
           output logic [7:0] addr, input logic [7:0] rddata, output logic [7:0] wrdata, output logic wren);

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
	reg [7:0] i, j; 
	reg [7:0] s_i, s_j; 
	
	wire [7:0] s_key [2:0];
	assign s_key[2] = key[7:0];
	assign s_key[1] = key[15:8];
	assign s_key[0] = key[23:16]; 
	
	always_ff @(posedge clk or negedge rst_n) begin 
		if (~rst_n) begin
			wren = 0;
			rdy = 1'b1; 
			cs = `STATE6; end
		else if (en) begin
			wren = 0;
			i = 8'b00000000; 
			j = 8'b00000000; 
			addr = i; 
			cs = `STATE0; 
			rdy = 1'b0; end
		else begin 	
			case (cs) 
			`STATE0: begin 			// Read value in i 		
				addr = i; 
				ns = `STATE1; end 
			`STATE1: begin 			// Calculate j 
				s_i = rddata; 
				j = (j + s_i + s_key[i%3]) % 256; 
				addr = j;
				ns = `STATE9; end 
			`STATE9: begin 
				ns = `STATE2; end 
			`STATE2: begin 			// Read value in j AND Write i to j 
				s_j = rddata; 
				wren = 1; 
				wrdata = s_i; 
				addr = j; 
				ns = `STATE3; end 
			`STATE3: begin 			// Write j to i AND Continue loop 
				wren = 1; 
				wrdata = s_j;
				addr = i; 
				if (i == 8'b11111111)
					ns = `STATE5; 
				else 
					ns = `STATE4; end  
			`STATE4: begin 			// Redo loop 
				wren = 0; 
				i = i+1; 
				addr = i; 
				ns = `STATE0; end
			`STATE5: begin 
				wren = 0; 
				ns = `STATE5; 
				rdy = 1'b1; end 
			`STATE6: begin 
				ns = `STATE6; end 
			default: begin 
				rdy = 1'bx; 
				addr = 8'bxxxxxxxx;
				wrdata = 8'bxxxxxxxx;
				wren = 1'bx; 
				ns = 4'bxxxx; 
				i = 8'bxxxxxxxx;
				j = 8'bxxxxxxxx; 
				s_i = 8'bxxxxxxxx; 
				s_j = 8'bxxxxxxxx; end	
			endcase 
			cs <= ns; 
		end	
	end 
endmodule: ksa

