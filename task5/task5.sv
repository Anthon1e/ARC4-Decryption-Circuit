module task5(input logic CLOCK_50, input logic [3:0] KEY, input logic [9:0] SW,
             output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
             output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
             output logic [9:0] LEDR);

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
	
    wire reset = KEY[3];
	wire clk = CLOCK_50; 
	wire [23:0] key; 
	wire key_valid; 
	reg [24:0] correct_key;
	
	wire [7:0] ct_addr, ct_wrdata, ct_rddata;
	wire ct_wren, rdy; 
	reg [3:0] cs, ns;
	reg en; 

    ct_mem ct(ct_addr, clk, ct_wrdata, ct_wren, ct_rddata);
    doublecrack dc(clk, reset, en, rdy, key, key_valid, ct_addr, ct_rddata);

    always_ff @(posedge clk or negedge reset) begin 
		if (~reset) begin 
			en <= 1; 
			cs = `STATE0; end 
		else begin 
			case(cs) 
				`STATE0: begin 
					en = 0; 
					if (rdy) 
						ns = `STATE1; 
					else 
						ns = `STATE0; end
				`STATE1: begin 
					en = 0;
					ns = `STATE0; end 
				default: begin 
					ns = 4'bxxxx; 
					en = 1'bx; end 
			endcase 
			cs <= ns; 
		end	
	end  
	
	always_comb begin 
		if (~rdy) begin 
			correct_key = 25'b1000100010001000100010001; end 
		else if (key_valid && rdy) begin 
			correct_key[23:0] = key; 
			correct_key[24] = 0; end
		else begin 
			correct_key[23:0] = 24'b000000000000000000000000;
			correct_key[24] = 1; end
	end 
				
	sseg H0({correct_key[24],correct_key[3:0]},		HEX0);   
	sseg H1({correct_key[24],correct_key[7:4]}, 	HEX1);
	sseg H2({correct_key[24],correct_key[11:8]}, 	HEX2);
	sseg H3({correct_key[24],correct_key[15:12]}, 	HEX3);
	sseg H4({correct_key[24],correct_key[19:16]}, 	HEX4);
	sseg H5({correct_key[24],correct_key[23:20]}, 	HEX5);
endmodule: task5

module sseg(in,segs);
	input [4:0] in;
	output [6:0] segs;
	reg [6:0] segs;

	always_comb begin
		case(in) 
			5'b00000: segs = 7'b1000000;
			5'b00001: segs = 7'b1111001;
			5'b00010: segs = 7'b0100100;
			5'b00011: segs = 7'b0110000;
			5'b00100: segs = 7'b0011001;
			5'b00101: segs = 7'b0010010;
			5'b00110: segs = 7'b0000010;
			5'b00111: segs = 7'b1111000;
			5'b01000: segs = 7'b0000000;
			5'b01001: segs = 7'b0010000;
			5'b01010: segs = 7'b0001000;
			5'b01011: segs = 7'b0000011;
			5'b01100: segs = 7'b1000110;
			5'b01101: segs = 7'b0100001;
			5'b01110: segs = 7'b0000110;
			5'b01111: segs = 7'b0001110;
			5'b10000: segs = 7'b0111111;
			5'b10001: segs = 7'b1111111; 
			default: segs = 7'b1111111;
		endcase
	end
endmodule
