`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    01:53:32 08/19/2022 
// Design Name: 
// Module Name:    embed_top 
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
module embed_top(
	input sys_clk,
	output pulse_signal
    );
	 
	 wire sys_2xclk;
	 clk_gen clk_instance (
    .CLKIN_IN(sys_clk), 
    .CLKIN_IBUFG_OUT(),
    .CLK2X_OUT(sys_2xclk)
    );
	 
	 pulse_signal u1 (
	 .sys_clk(sys_2xclk),
	 .pulse_signal(pulse_signal)
	 );


endmodule
