module task3(input logic CLOCK_50, input logic [3:0] KEY, input logic [9:0] SW,
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
	assign key = 'h000018;
	
	wire [7:0] ct_addr, ct_wrdata, ct_rddata;
	wire [7:0] pt_addr, pt_wrdata, pt_rddata;
	wire ct_wren, pt_wren, rdy; 
	reg [3:0] cs, ns;
	reg en; 

    ct_mem ct(ct_addr, clk, ct_wrdata, ct_wren, ct_rddata);
    pt_mem pt(pt_addr, clk, pt_wrdata, pt_wren, pt_rddata);
    arc4   a4(clk, reset, en, rdy, key, ct_addr, ct_rddata,
              pt_addr, pt_rddata, pt_wrdata, pt_wren);

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
					ns = `STATE1; end 
				default: begin 
					ns = 4'bxxxx; 
					en = 1'bx; end 
			endcase 
			cs <= ns; 
		end	
	end  
endmodule: task3
