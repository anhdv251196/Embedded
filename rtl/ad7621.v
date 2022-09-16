`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/15/2022 09:38:34 PM
// Design Name: 
// Module Name: ad7621
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


module ad7621(
    /* System Interface */
    input sys_clk,
    input sys_rst,
    
    /* FPGA parameters */
    input [15:0] FPGA_OFFSETVALUE,
    input [15:0] FPGA_MAXSATVALUE,

    /* AD7621 interface */
    input ad7621_restart,
    input ad7621_start,
    input ad7621_busy,
    input [15:0] ad7621_di,
    output reg ad7621_convst,
    output wire [15:0] ad7621_fifo_do,
    output wire ad7621_flag_fifo_do
    
    /* ILA interface */
    //output [15:0] cnt_rd_pixel_ila
    );
    
	 /* Detect falling edge of ad7621 busy */ 
    wire flag_falling_edge_busy;
    detect_falling_edge falling_edge_fifo_instant 
    (.sys_clk(sys_clk),
     .d_i(ad7621_busy),
     .d_o(flag_falling_edge_busy)
     );
    
    /**/
    reg [15:0] cnt_rd_pixel = 16'd0;
    always @ (posedge sys_clk)
    begin
        if (sys_rst || ad7621_restart)
        begin
            cnt_rd_pixel <= 16'd0;
        end
        else begin
            if (ad7621_start) cnt_rd_pixel <= cnt_rd_pixel + 16'd1;
        end
    end
	 
	/* Latch data in falling edge of busy signal */ 
	reg [15:0] r_dat_temp = 16'd0;
	reg r_dat_valid_temp = 1'b0;
    always @ (posedge sys_clk)
    begin
        if (sys_rst || ad7621_restart)
        begin
            r_dat_temp <= 16'd0;
            r_dat_valid_temp <= 1'b0;
        end
        else begin
            if (flag_falling_edge_busy)
            begin
                if ( (cnt_rd_pixel >= 16'd34) && (cnt_rd_pixel <= 16'd2081) )
                begin
                    r_dat_temp <= ad7621_di - FPGA_OFFSETVALUE;
                    r_dat_valid_temp <= 1'b1;
                end
            end 
            else begin
                r_dat_valid_temp <= 1'b0;
            end
        end
    end
	
	divider #(.WIDTH(10), .FBITS(4)) div_instance 
	(
		.clk(sys_clk),
		.start(r_dat_valid_temp),
		.x(10'h3FF),
		.y(FPGA_MAXSATVALUE[15:6]),
		.w_data_i(r_dat_temp),
		.r_data_o(ad7621_fifo_do),
		.r_data_valid(ad7621_flag_fifo_do)
	);

		reg ad7621_start_ff1 = 1'b0;
		reg ad7621_start_ff2 = 1'b0; 
		always @ (posedge sys_clk)
		begin
			ad7621_start_ff1 <= ad7621_start;
			ad7621_start_ff2 <= ad7621_start_ff1;
		end
    
    /* Strobe a convst signal */
    always @ (posedge sys_clk)
    begin
        if (sys_rst || ad7621_restart)
        begin
            ad7621_convst <= 1'b1;
        end
        else begin
            if (ad7621_start) ad7621_convst <= 1'b0;
            if (ad7621_start_ff2) ad7621_convst <= 1'b1;
        end
    end
    
    //assign cnt_rd_pixel_ila = cnt_rd_pixel;
    
endmodule
