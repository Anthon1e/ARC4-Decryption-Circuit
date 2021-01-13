module prga(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            input logic [23:0] key,
            output logic [7:0] s_addr, input logic [7:0] s_rddata, output logic [7:0] s_wrdata, output logic s_wren,
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
	`define STATEX 4'b1010
	
	reg [3:0] cs, ns;
	reg [7:0] i, j, k; 
	reg [7:0] s_i, s_j, pad_k, c_k; 
	reg [7:0] msg_length; 
	
	always_ff @(posedge clk or negedge rst_n) begin 
		if (~rst_n) begin
			s_wren = 0;
			i = 8'b00000000; 
			j = 8'b00000000; 
			k = 8'b00000001;
			ct_addr = 8'b00000000; 
			rdy = 1'b1; 
			cs = `STATE8; end
		else if (en) begin
			s_wren = 0; 
			s_addr = i; 
			i = 8'b00000000; 
			j = 8'b00000000; 
			k = 8'b00000001;
			cs = `STATEX; 
			rdy = 1'b0; end
		else begin 	
			case (cs) 
				`STATEX: begin
					msg_length = ct_rddata;
					pt_addr = 8'b00000000; 
					pt_wrdata = msg_length; 
					pt_wren = 1;
					ns = `STATE0; end
				`STATE0: begin 		
					i = (i+1) % 256; 
					s_addr = i;
					s_wren = 0;
					ns = `STATE9; end 
				`STATE9: begin 
					ns = `STATE1; end
				`STATE1: begin  		// Read value in i 
					s_i = s_rddata; 
					j = (j + s_i) % 256; 
					s_addr = j; 
					ns = `STATE2; end 
				`STATE2: begin 
					ns = `STATE3; end 
				`STATE3: begin 			// Read value in j AND Write j to i 
					s_j = s_rddata; 
					s_wrdata = s_j; 
					s_addr = i; 
					s_wren = 1; 
					ns = `STATE4; end 
				`STATE4: begin 			// Write i to j
					s_wrdata = s_i; 
					s_addr = j; 
					s_wren = 1; 
					ns = `STATE5; end
				`STATE5: begin 
					s_addr = (s_i + s_j) % 256; 
					s_wren = 0; 
					ct_addr = k; 
					ns = `STATE6; end
				`STATE6: begin 
					ns = `STATE7; end 
				`STATE7: begin 
					pad_k = s_rddata;
					c_k = ct_rddata; 
					pt_addr = k; 
					pt_wrdata = pad_k ^ c_k; 
					pt_wren = 1;
					if (k == msg_length)
						ns = `STATE8; 
					else begin 
						k <= k+1;
						ns = `STATE0; end end 
				`STATE8: begin 
					rdy = 1;
					ns = `STATE8; end
			endcase 
			cs <= ns; 
		end	
	end 
endmodule: prga
