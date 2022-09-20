`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    02:42:47 08/19/2022 
// Design Name: 
// Module Name:    top_embed 
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
module top_embed(
	input sys_clk,
	input xreset,
	
	/* MCU interface */
	input fifo_rset,
	input trigger,
	output reg pixel_ready = 1'b0,
	output single_strobe,
	output cont_strobe,
	
	input spi_clk,
	input spi_mosi,
	inout spi_miso,
	
	input fpga_cs,
	input fifo_cs,
	input e2_cs,
	input adt_cs,
	
	/* ADT interface */
	output adt7301_clk,
	output adt7301_cs,
	//input adt7301_miso,
	
	/* EEPROM interface */
	output eeprom_clk,
	output eeprom_cs,
	
	/* CCD sensor inteface */
	output ilx511b_clk,
	output ilx511b_rog,
	output ilx511b_shsw,
	
	/* ADC interface */
	input ad7621_busy,
	input [15:0] ad7621_di,
	output ad7621_convst
	
    );
	 
	 /* Make x2 clock = 24MHz */
	 wire sys_2xclk;
	 wire sys_4xclk;
	 wire LOCKED_OUT;
	 clock_wizard clk_wizard_instance (
    .CLKIN_IN(sys_clk), 
	 .CLKFX_OUT(sys_4xclk), 	 
    .CLK2X_OUT(sys_2xclk),
	 .LOCKED_OUT(LOCKED_OUT)
    );
	 
	 wire fpga_mosi;
	 wire fpga_miso;
	 wire fifo_mosi;
	 wire fifo_miso;
	 mux_data_spi mux_spi_instance (
	 .spi_mosi(spi_mosi),
	 .spi_miso(spi_miso),
	 
	 .fpga_cs(fpga_cs),
	 .fpga_mosi(fpga_mosi),
	 .fpga_miso(fpga_miso),
	 
	 .fifo_cs(fifo_cs),
	 .fifo_mosi(fifo_mosi),
	 .fifo_miso(fifo_miso),
	 
	 .e2_clk(spi_clk),
	 .e2_cs(e2_cs),
	 .eeprom_clk(eeprom_clk),
	 .eeprom_cs(eeprom_cs),
	 
	 .adt_cs(adt_cs),
	 .adt7301_clk(adt7301_clk),
	 .adt7301_cs(adt7301_cs)
	 //.adt7301_miso(adt7301_miso)
	 );
	 
	 wire [15:0] FPGA_COUNTBASE;
	 wire [15:0] FPGA_STRBCOUNT;
	 wire [15:0] FPGA_INTCLOCK;
	 wire [15:0] FPGA_SSLOWDELAY;
	 wire [15:0] FPGA_SSHIGHDELAY;
	 wire [15:0] FPGA_LAMPENABLE;
	 wire [15:0] FPGA_OFFSETVALUE;
	 wire [15:0] FPGA_MAXSATVALUE;
	 fpga_spi fpga_spi_instance (
	 .sys_clk(sys_4xclk),
	 .sys_rst(xreset),
	 .FPGA_COUNTBASE(FPGA_COUNTBASE),
	 .FPGA_STRBCOUNT(FPGA_STRBCOUNT),
	 .FPGA_INTCLOCK(FPGA_INTCLOCK),
	 .FPGA_SSLOWDELAY(FPGA_SSLOWDELAY),
	 .FPGA_SSHIGHDELAY(FPGA_SSHIGHDELAY),
	 .FPGA_LAMPENABLE(FPGA_LAMPENABLE),
	 .FPGA_OFFSETVALUE(FPGA_OFFSETVALUE),
	 .FPGA_MAXSATVALUE(FPGA_MAXSATVALUE),
	 .fpga_clk(spi_clk),
	 .fpga_cs(fpga_cs),
	 .fpga_mosi(fpga_mosi),
	 .fpga_miso(fpga_miso)
	 );
	 
	 wire flag_adc_start;
	 wire flag_adc_restart;
	 wire ilx511b_clk_ff;
	 wire ilx511b_rog_ff;
	 wire flag_sel_clok;
	 wire flag_en_single_strobe;
	 ilx511b ilx_instance (
	 .sys_clk(sys_4xclk),
	 .sys_rst(xreset),
	 .FPGA_INTCLOCK(FPGA_INTCLOCK),
	 .aqui_src(fifo_rset | trigger),
	 .ilx511b_clk(ilx511b_clk_ff),
	 .ilx511b_rog(ilx511b_rog_ff),
	 .flag_adc_start(flag_adc_start),
	 .flag_adc_restart(flag_adc_restart),
	 .flag_sel_clok(flag_sel_clok),
	 .flag_en_single_strobe(flag_en_single_strobe)
	 );
	 
	 /* Make strobe */
	 make_strobe mk_strobe_instance
	 (
	 .sys_clk(sys_4xclk),
	 .sys_rst(sys_rst),
	 .flag_en_single_strobe(flag_en_single_strobe),
	 .FPGA_COUNTBASE(FPGA_COUNTBASE),
	 .FPGA_STRBCOUNT(FPGA_STRBCOUNT),
	 .FPGA_SSLOWDELAY(FPGA_SSLOWDELAY),
	 .FPGA_SSHIGHDELAY(FPGA_SSHIGHDELAY),
	 .FPGA_LAMPENABLE(FPGA_LAMPENABLE),
	 .single_strobe(single_strobe),
	 .cont_strobe(cont_strobe)
	 );
	 
	 
	 /* Make 2.5Mhz for CCD clock */
	 wire clk_2_5Mhz;
	 make_22500pulse make_pulse_instance (
	 .sys_clk(sys_4xclk),
	 .sys_rst(xreset),
	 .locked(LOCKED_OUT),
	 .clk_2_5Mhz(clk_2_5Mhz)
	 );
	 
	 assign ilx511b_clk = (flag_sel_clok == 1'b1) ? ~ilx511b_clk_ff : ~clk_2_5Mhz;
	 assign ilx511b_rog = ~ilx511b_rog_ff;
	 assign ilx511b_shsw = 1'b0;
	 
	 wire [15:0] ad7621_fifo_do;
	 wire ad7621_flag_fifo_do;
	 ad7621 ad7621_instance (
	 .sys_clk(sys_4xclk),
	 .sys_rst(xreset),
	 .FPGA_OFFSETVALUE(FPGA_OFFSETVALUE),
	 .FPGA_MAXSATVALUE(FPGA_MAXSATVALUE),
	 .ad7621_restart(flag_adc_restart),
	 .ad7621_start(flag_adc_start),
	 .ad7621_busy(ad7621_busy),
	 .ad7621_di(ad7621_di),
	 .ad7621_convst(ad7621_convst),
	 .ad7621_fifo_do(ad7621_fifo_do),
	 .ad7621_flag_fifo_do(ad7621_flag_fifo_do)
	 );
	 
	 /* Detect falling edge of fifo cs */ 
    wire rise_edge_acqui_src;
    detect_rising_edge rise_edge_acqui_src_instant 
    (.sys_clk(sys_4xclk),
     .d_i(fifo_rset | trigger),
     .d_o(rise_edge_acqui_src)
    );
	 
	 wire fifo_empty;
	 wire fifo_full;
	 wire [15:0] fifo_dout;
	 wire flag_rd_fifo;
	 wire [10:0] data_count;
	 wire [10:0] cnt_ff;
	 fifo_ccd fifo_ccd_instance (
	 .clk(sys_4xclk), // input clk
	 .rst(xreset | rise_edge_acqui_src), // input rst
	 .din(ad7621_fifo_do), // input [15 : 0] din
	 .wr_en(ad7621_flag_fifo_do & ~fifo_full), // input wr_en
	 .rd_en(flag_rd_fifo & ~fifo_empty), // input rd_en
	 .dout(fifo_dout), // output [15 : 0] dout
	 .full(fifo_full), // output full
	 .empty(fifo_empty), // output empty
	 .data_count(data_count)
	 );
	 
	 always @ (posedge sys_4xclk)
	 begin
		if (data_count >= 1)
		begin
			pixel_ready <= 1'b1;
		end else begin
			pixel_ready <= 1'b0;
		end
	 end
//	 assign pixel_ready = (data_count >= 1);
	 
	 fifo_spi fifo_spi_instance (
	 .sys_clk(sys_4xclk),
	 .sys_rst(xreset),
	 .fifo_data(fifo_dout),
	 .flag_fifo_data(flag_rd_fifo | ~fifo_empty),
	 .flag_rd_fifo(flag_rd_fifo),
	 .fifo_clk(spi_clk),
	 .fifo_cs(fifo_cs),
	 .fifo_mosi(fifo_mosi),
	 .fifo_miso(fifo_miso)
	 );

endmodule
