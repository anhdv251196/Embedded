`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    02:29:51 09/16/2022 
// Design Name: 
// Module Name:    make_strobe 
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
module make_strobe(
	 /* System interface */
	 input sys_clk,
	 input sys_rst,
	 
	 /**/
	 input flag_en_single_strobe,
	 
	 input [15:0] FPGA_COUNTBASE,
	 input [15:0] FPGA_STRBCOUNT,
	 input [15:0] FPGA_SSLOWDELAY,
	 input [15:0] FPGA_SSHIGHDELAY,
	 input [15:0] FPGA_LAMPENABLE,
	 
	 /**/
	 output reg single_strobe = 1'b1,
	 output reg cont_strobe = 1'b0
    );
	 
	 reg flag_start_single_strobe = 1'b0;
	 reg flag_end_single_strobe = 1'b0;
	 reg [15:0] cnt_mk_strobe = 16'd0;
	 reg [5:0] cnt_mk_2MHz = 6'd0;
	 always @ (posedge sys_clk)
	 begin
		if (sys_rst | (FPGA_LAMPENABLE[0] == 1'b0) | flag_end_single_strobe)
		begin
			single_strobe <= 1'b1;
			cnt_mk_2MHz <= 6'd0;
			cnt_mk_strobe <= 16'd0;
			flag_start_single_strobe <= 1'b0;
			flag_end_single_strobe <= 1'b0;
		end
		else begin
			if (cnt_mk_strobe == FPGA_SSHIGHDELAY) single_strobe <= 1'b0;
			if (cnt_mk_strobe == FPGA_SSLOWDELAY) 
			begin
				single_strobe <= 1'b1;
				flag_end_single_strobe <= 1'b1;
			end
			if (flag_en_single_strobe) flag_start_single_strobe <= 1'b1;
			if (flag_start_single_strobe)
			begin
				if (cnt_mk_2MHz == 6'd23)
				begin
					cnt_mk_strobe <= cnt_mk_strobe + 1'b1;
					cnt_mk_2MHz <= 6'd0;
				end else begin
					cnt_mk_2MHz <= cnt_mk_2MHz + 6'd1;
				end
			end else begin
				cnt_mk_2MHz <= 6'd0;
				cnt_mk_strobe <= 16'd0;
			end
		end
	 end
	 
	 reg [15:0] prev_countbase = 16'd0;
	 reg [15:0] prev_strbcount = 16'd0;
	 wire flag_change_params;
	 /* Make */
	 always @ (posedge sys_clk)
	 begin
		prev_countbase <= FPGA_COUNTBASE;
		prev_strbcount <= FPGA_STRBCOUNT;
	 end
	 
	 assign flag_change_params = (prev_countbase != FPGA_COUNTBASE) | (prev_strbcount != FPGA_STRBCOUNT);
	 
	 /* Make contionous strobe signal */
	 reg [27:0] r_cnt_cont_strobe = 28'd0;
	 always @ (posedge sys_clk)
	 begin
		if (sys_rst | (FPGA_LAMPENABLE[0] == 1'b0) | flag_change_params)
		begin
			r_cnt_cont_strobe <= 28'd0;
			cont_strobe <= 1'b1;
		end else begin
			if ( r_cnt_cont_strobe == ( (FPGA_COUNTBASE[15:1] * (FPGA_STRBCOUNT + 1)) - 1) )
			begin
				r_cnt_cont_strobe <= 28'd0;
				cont_strobe <= ~cont_strobe;
			end else begin
				r_cnt_cont_strobe <= r_cnt_cont_strobe + 28'd1;
			end
		end
	 end

endmodule
