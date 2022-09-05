`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/16/2022 04:02:29 AM
// Design Name: 
// Module Name: detect_falling_edge
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module detect_falling_edge(
    input sys_clk,
    input d_i,
    output d_o
    );
    
    reg d_i_ff1;
	 reg d_i_ff2;
	 reg d_i_ff3;
    always @ (posedge sys_clk)
    begin
        d_i_ff1 <= d_i;
		  d_i_ff2 <= d_i_ff1;
		  d_i_ff3 <= d_i_ff2;
    end
    
    assign d_o = d_i_ff3 & (d_i_ff3 ^ d_i_ff2);
    
endmodule
