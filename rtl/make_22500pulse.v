`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    06:15:56 08/25/2022 
// Design Name: 
// Module Name:    make_22500pulse 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module make_22500pulse(
	 input sys_clk,
	 input sys_rst,
	 input locked,
	 output reg clk_2_5Mhz = 1'b0
    );
	 
	 reg [5:0] cnt_make_2_5Mhz = 6'd0;
	 always @ (posedge sys_clk)
	 begin
		if (locked)
		begin
			if (cnt_make_2_5Mhz == 6'd9)
			begin
				cnt_make_2_5Mhz <= 6'd0;
				clk_2_5Mhz <= ~clk_2_5Mhz;
			end
			else begin
				cnt_make_2_5Mhz <= cnt_make_2_5Mhz + 6'd1;
			end
		end
	 end

endmodule
