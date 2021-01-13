module crack(input logic clk, input logic rst_n,
             input logic en, output logic rdy,
             output logic [23:0] key, output logic key_valid,
             output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
			 input logic [7:0] msg_length, input logic key_crack, input [7:0] pt_addr_db, output [7:0] pt_rddata);

    // For Task 5, you may modify the crack port list above,
    // but ONLY by adding new ports. All predefined ports must be identical.

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
	
	reg [7:0] pt_addr, pt_wrdata;
	reg pt_wren;

	reg [7:0] pt_addr_crack, pt_wrdata_crack, ct_addr_crack;
	reg pt_wren_crack;
	
	reg [7:0] pt_addr_a4, pt_wrdata_a4, ct_addr_a4;
	reg pt_wren_a4, rdy_arc4, en_arc4;
	
	reg [3:0] cs, ns;
	reg [1:0] mode; 
	reg [7:0] k; 

    // this memory must have the length-prefixed plaintext if key_valid
    pt_mem pt(pt_addr, clk, pt_wrdata, pt_wren, pt_rddata);
    arc4 a4(clk, rst_n, en_arc4, rdy_arc4, key, ct_addr_a4, ct_rddata,
			pt_addr_a4, pt_rddata, pt_wrdata_a4, pt_wren_a4);

    always_ff @(posedge clk or negedge rst_n) begin 
		if (~rst_n) begin 
			key_valid = 0; 
			en_arc4 = 0; 
			k = 8'b00000001;
			mode = 2'b00;
			rdy = 1; end 
		else if (en) begin 	
			en_arc4 = 1;
			rdy = 0; 
			cs = `STATEX; end 
		else begin 
			case (cs)
				`STATEX: begin 
					en_arc4 = 0;
					if (key_crack == 0)
						key = 'h000000;
					else 
						key = 'h000001; 
					ns = `STATE0; end
				`STATE0: begin
					if (rdy_arc4 == 1) begin
						mode = 2'b01; 
						pt_addr_crack = k; 
						pt_wren_crack = 0; 
						ns = `STATE1; end
					else begin 
						ns = `STATE0; end end 
				`STATE1: begin 
					ns = `STATE2; end 
				`STATE2: begin 
					if ((k !== msg_length) && (k !== msg_length+1)) begin 
						if ((pt_rddata >= 'h20) && (pt_rddata <= 'h7E)) begin 
							k = k+1;
							pt_addr_crack = k; 
							ns = `STATE1; end 
						else begin 
							en_arc4 = 1;
							ns = `STATE3; end end 
					else begin 
						rdy = 1;
						if ((pt_rddata >= 'h20) && (pt_rddata <= 'h7E)) begin 
							key_valid = 1; 
							key = key; 
							ns = `STATE5; end
						else begin 
							key_valid = 0; 
							ns = `STATE4; end end end
				`STATE3: begin 
					mode = 2'b00; 
					en_arc4 = 0;
					k = 8'b00000001; 
					key = key+2; 
					ns = `STATE0; end 
				`STATE4: begin 	
					ns = `STATE4; end 
				`STATE5: begin 
					mode = 2'b10; 
					ns = `STATE5; end
			endcase 
			cs <= ns;
		end 
	end	
	
	always_comb begin 
		case (mode) 
		2'b00: begin 
			pt_addr = pt_addr_a4;
			pt_wrdata = pt_wrdata_a4; 
			pt_wren = pt_wren_a4; 
			ct_addr = ct_addr_a4; end 
		2'b01: begin 
			pt_addr = pt_addr_crack;
			pt_wrdata = pt_wrdata_crack; 
			pt_wren = pt_wren_crack; 
			ct_addr = ct_addr_crack; end 
		2'b10: begin 
			pt_addr = pt_addr_db;
			pt_wrdata = pt_wrdata_crack;
			pt_wren = 0; 
			ct_addr = ct_addr_crack; end
		default: begin 
			pt_addr = 8'bxxxxxxxx;
			pt_wrdata = 8'bxxxxxxxx; 
			pt_wren = 1'bx; 
			ct_addr = 8'bxxxxxxxx; end
		endcase
	end
endmodule: crack

module arc4(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            input logic [23:0] key,
            output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
            output logic [7:0] pt_addr, input logic [7:0] pt_rddata, output logic [7:0] pt_wrdata, output logic pt_wren);
	
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

module prga(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            input logic [23:0] key,
            output logic [7:0] s_addr, input logic [7:0] s_rddata, output logic [7:0] s_wrdata, output logic s_wren,
            output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
            output logic [7:0] pt_addr, input logic [7:0] pt_rddata, output logic [7:0] pt_wrdata, output logic pt_wren);
			
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
					ct_addr = 8'b00000000;
					rdy = 1;
					ns = `STATE8; end
			endcase 
			cs <= ns; 
		end	
	end 
endmodule: prga
