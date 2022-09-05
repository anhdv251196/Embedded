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
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 sys_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 100000000" *)
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
    output reg [15:0] ad7621_fifo_do,
    output reg ad7621_flag_fifo_do
    
    /* ILA interface */
    //output [15:0] cnt_rd_pixel_ila
    );
    
    reg ad7621_busy_ff;
    always @ (posedge sys_clk)
    begin
        ad7621_busy_ff <= ad7621_busy;
    end
    
    /* Falling edge of ad7621 busy */
    wire flag_falling_edge_busy;
    assign flag_falling_edge_busy = ad7621_busy_ff & (ad7621_busy_ff ^ ad7621_busy);
    
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
    reg [31:0] ad7621_do_ff1;
	 wire [31:0] ad7621_do_ff2;
    always @ (posedge sys_clk)
    begin
        if (sys_rst || ad7621_restart)
        begin
            ad7621_fifo_do <= 16'd0;
            ad7621_flag_fifo_do <= 1'b0;
            ad7621_do_ff1 <= 32'd0;
        end
        else begin
            if (flag_falling_edge_busy)
            begin
                if ( (cnt_rd_pixel >= 16'd34) && (cnt_rd_pixel <= 16'd2081) )
                begin
//                    ad7621_do_ff1 <= (ad7621_di - FPGA_OFFSETVALUE) * 65535;
						  ad7621_do_ff1 <= ad7621_di - FPGA_OFFSETVALUE;
                    ad7621_fifo_do <= ad7621_do_ff1[15:0];
                    ad7621_flag_fifo_do <= 1'b1;
                end
            end 
            else begin
                ad7621_flag_fifo_do <= 1'b0;
            end
        end
    end
	 

		reg ad7621_start_ff;
		always @ (posedge sys_clk)
		begin
			ad7621_start_ff <= ad7621_start;
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
            if (ad7621_start_ff) ad7621_convst <= 1'b1;
        end
    end
    
    //assign cnt_rd_pixel_ila = cnt_rd_pixel;
    
endmodule
