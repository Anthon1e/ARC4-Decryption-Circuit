module doublecrack(input logic clk, input logic rst_n,
             input logic en, output logic rdy,
             output logic [23:0] key, output logic key_valid,
             output logic [7:0] ct_addr, input logic [7:0] ct_rddata);

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
	
	reg [7:0] pt_addr, pt_wrdata, pt_rddata, msg_length, ct_addr_dc;
	reg pt_wren; 
    
	reg en_c1, en_c2, rdy_c1, rdy_c2, key_valid_c1, key_valid_c2; 
	reg [7:0] ct_addr_c1, ct_addr_c2, pt_rddata_c1, pt_rddata_c2;
	reg [23:0] key_c1, key_c2;
	
	reg [3:0] cs, ns;
	reg [1:0] mode; 
	reg [7:0] k; 
	
    // this memory must have the length-prefixed plaintext if key_valid
    pt_mem pt(pt_addr, clk, pt_wrdata, pt_wren, pt_rddata);

    // for this task only, you may ADD ports to crack
    crack c1(clk, rst_n, en_c1, rdy_c1, key_c1, key_valid_c1, ct_addr_c1, ct_rddata, msg_length, 1'b0, pt_addr, pt_rddata_c1);
    crack c2(clk, rst_n, en_c2, rdy_c2, key_c2, key_valid_c2, ct_addr_c2, ct_rddata, msg_length, 1'b1, pt_addr, pt_rddata_c2);
    
	always_ff @(posedge clk or negedge rst_n) begin 
		if (~rst_n) begin 
			ct_addr_dc = 8'b00000000; 
			k = 8'b00000001;
			mode = 2'b00; 
			rdy = 1; end 
		else if (en) begin
			rdy = 0; 
			cs = `STATEX; end 
		else begin 
			case (cs)
				`STATEX: begin 
					en_c1 = 1;
					msg_length = ct_rddata; 
					pt_addr = 8'b00000000; 
					pt_wrdata = msg_length; 
					pt_wren = 1;
					mode = 2'b01; 
					ns = `STATE0; end
				`STATE0: begin 
					en_c1 = 0;
					en_c2 = 1;
					mode = 2'b10;
					ns = `STATE1; end 
				`STATE1: begin 
					en_c2 = 0; 
					mode = 2'b01; 
					ns = `STATE2; end
				`STATE2: begin 
					mode = 2'b10;
					ns = `STATE8; end
				`STATE8: begin 
					mode = 2'b01; 
					if (rdy_c1 || rdy_c2)
						ns = `STATE3;
					else 
						ns = `STATE9; end 
				`STATE9: begin 
					mode = 2'b10; 
					if (rdy_c1)
						ns = `STATE3;
					else 
						ns = `STATE8; end 
				`STATE3: begin 
					pt_addr = k;
					if (k > msg_length) begin 
						pt_wren = 0;
						ns = `STATE6; end
					else 
						ns = `STATE4; end
				`STATE4: begin 
					ns = `STATE5; end 
				`STATE5: begin 
					if (key_valid_c1) begin 
						pt_wrdata = pt_rddata_c1;
						pt_wren = 1; 
						ns = `STATE3; end 
					else if (key_valid_c2) begin 
						pt_wrdata = pt_rddata_c2;
						pt_wren = 1; 
						ns = `STATE3; end
					else begin 
						ns = `STATE6;
						pt_wren = 0; end
					k = k+1; end
				`STATE6: begin 
					if (key_valid_c1) begin 
						key_valid = 1;
						key = key_c1; end
					else if (key_valid_c2) begin 
						key_valid = 1;
						key = key_c2; end
					else begin  
						key_valid = 0; end
					rdy = 1;
					ns = `STATE7; end
				`STATE7: begin
					ct_addr_dc = 8'b00000000; 
					ns = `STATE7; end 
			endcase 
			cs <= ns;
		end
	end 	
	
	always_comb begin 
		case (mode) 
		2'b00: begin 
			ct_addr = ct_addr_dc; end 
		2'b01: begin 
			ct_addr = ct_addr_c1; end 
		2'b10: begin 
			ct_addr = ct_addr_c2; end 
		default: begin 
			ct_addr = 8'bxxxxxxxx; end
		endcase
	end
endmodule: doublecrack
