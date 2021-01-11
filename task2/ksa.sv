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