`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/17/2022 08:51:12 PM
// Design Name: 
// Module Name: fifo_spi
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


module fifo_spi(
    /* System interface */
    input sys_clk,      /* system clock */
    input sys_rst,

    /* Data interface */
    input [15:0] fifo_data,
    input flag_fifo_data,
    
    /* FIFO data interface */
    output flag_rd_fifo,

    /* FIFO spi interface */
    input fifo_clk,
    input fifo_cs,
    input fifo_mosi,
    output reg fifo_miso = 1'b0
    );
    
    /* Detect falling edge of fifo cs */ 
    wire fall_edge_fifo_cs;
    detect_falling_edge fall_edge_fifo_instant 
    (.sys_clk(sys_clk),
     .d_i(fifo_cs),
     .d_o(fall_edge_fifo_cs)
    );
    
    assign flag_rd_fifo = fall_edge_fifo_cs;
    
    reg flag_fifo_data_ff;
    always @ (posedge sys_clk)
    begin
        flag_fifo_data_ff <=  flag_rd_fifo;
    end
    
    /* Detect falling edge of fifo cs */ 
    wire rise_edge_fifo_clk;
    detect_rising_edge rise_edge_fifo_clk_instant 
    (.sys_clk(sys_clk),
     .d_i(fifo_clk),
     .d_o(rise_edge_fifo_clk)
    );
    
    reg [15:0] data_tranfer = 16'd0;
    always @ (posedge sys_clk)
    begin
        if (flag_fifo_data_ff) data_tranfer <= fifo_data;
        if (rise_edge_fifo_clk)
		  begin
			data_tranfer <= (data_tranfer << 1'b1);
			fifo_miso <= data_tranfer[15];
		  end
    end
	 
//    assign fifo_miso = data_tranfer[15];
      
endmodule
