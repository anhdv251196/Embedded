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
`include "/home/ise/Machine_VB/embed/include/define.h" 
module make_22500pulse(
	 input sys_clk,
	 input sys_rst,
	 input locked,
	 output reg sel_ccd_clk = 1'b0,
	 output reg clk_2_5Mhz = 1'b0
    );
	 
	 reg [17:0] cnt_pulse = 16'd0;
	 reg [5:0] cnt_make_2_5Mhz = 6'd0;
	 always @ (posedge sys_clk)
	 begin
		if (locked)
		begin
			if (cnt_make_2_5Mhz == 6'd4)
			begin
				cnt_make_2_5Mhz <= 6'd0;
				cnt_pulse <= cnt_pulse + 17'd1;
				clk_2_5Mhz <= ~clk_2_5Mhz;
			end
			else begin
				cnt_make_2_5Mhz <= cnt_make_2_5Mhz + 6'd1;
			end
			if (cnt_pulse == `CCD_CLK_PULSE) sel_ccd_clk <= 1'b1;
		end
	 end

endmodule
