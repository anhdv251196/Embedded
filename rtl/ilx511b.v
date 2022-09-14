`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/16/2022 03:01:40 AM
// Design Name: 
// Module Name: ilx511b
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

`include "/home/ise/Machine_VB/embed/include/define.h" 

module ilx511b(
    /* System Interface */
    input sys_clk,
    input sys_rst,
    
    /* FPGA interfaces */
    input [15:0] FPGA_INTCLOCK,
    
    /* Pheripheral interfaces */
    input aqui_src,
    
    /* CCDs sensor interfaces */
    output reg ilx511b_clk,
    output reg ilx511b_rog,
    
    /* ADC interface */
    output flag_adc_start,
    output flag_adc_restart,
	 
	 /**/
	 output reg flag_sel_clok = 1'b0
    
    /*ILA interface*/
//    output ilx511b_rog_ila,
//    output rising_fifo_rest_ila,
//    output [15:0] cnt_1khz_ila,
//    output [15:0] cnt_intclk_ila,
//    output integ_done_ila,
//    output ilx511b_clk_ila,
//    output flag_en_smp_data_ila,
//    output flag_smp_data_ila
    );
    
    /* Detect rising edge of aquisition source */
    wire rising_edge_fifo_rest;
    detect_rising_edge rising_edge_fifo_instant 
    (.sys_clk(sys_clk),
     .d_i(aqui_src),
     .d_o(rising_edge_fifo_rest)
     );
     
    assign flag_adc_restart = rising_edge_fifo_rest;
     
    /* Detect falling edge of aquisition source */ 
    wire falling_edge_fifo_rest;
    detect_falling_edge falling_edge_fifo_instant 
    (.sys_clk(sys_clk),
     .d_i(aqui_src),
     .d_o(falling_edge_fifo_rest)
     );
    
    /* make clk 1KHz - T = 1ms, run integration time*/
    reg [15:0] cnt_1khz = 15'd0;
    reg [15:0] cnt_intclk = 15'd0;
    reg en_intclk = 1'b0;
    reg integ_done = 1'b0;
    reg flag_start_rog_low1 = 1'b0;          // Flag indicate that change ROG to low
    reg flag_end_rog_low1 = 1'b0;            // Flag indicate that change ROG to high
    reg flag_start_rog_low2 = 1'b0;          // Flag indicate that change ROG to low
    reg flag_end_rog_low2 = 1'b0;            // Flag indicate that change ROG to high
    reg [15:0] cnt_rog_low = 16'd0;
    always @ (posedge sys_clk)
    begin
        if (sys_rst || integ_done)
        begin
            cnt_1khz <= 15'd0;
            cnt_intclk <= 15'd0;
            en_intclk <= 1'b0;
            integ_done <= 1'b0;
        end 
        else begin
            if (flag_end_rog_low1) en_intclk <= 1'b1;
            if (en_intclk) begin
                if (cnt_1khz == `TIME_MAKE_1KHZ)
                begin
                    cnt_1khz <= 15'd0;
                    cnt_intclk <= cnt_intclk + 15'd1;
                    if (cnt_intclk == FPGA_INTCLOCK) integ_done <= 1'b1;
                end
                else begin
                    cnt_1khz <= cnt_1khz + 15'd1;
                end
            end
            else begin
                cnt_1khz <= 15'd0;
                cnt_intclk <= 15'd0;
            end
        end
    end
	
	/* Make delay ROG to low after rising edge of fifo_rst */
	reg en_delay_rog_to_low = 1'b0;
	reg en_rog_from_end_rog_low1 = 1'b0;
	reg [7:0] cnt_delay_rog_to_low = 8'd0;
	reg flag_start_ctr_rog = 1'b0;
	reg flag_start_clok_from_end_rog_low1 = 1'b0;
	always @ (posedge sys_clk)
	begin
		if (sys_rst | flag_start_ctr_rog | flag_start_clok_from_end_rog_low1)
		begin
			en_delay_rog_to_low <= 1'b0;
			cnt_delay_rog_to_low <= 8'd0;
			flag_start_ctr_rog <= 1'b0;
			en_rog_from_end_rog_low1 <= 1'b0;
			flag_start_clok_from_end_rog_low1 <= 1'b0;
		end else begin
			if (rising_edge_fifo_rest) en_delay_rog_to_low <= 1'b1;
			if (flag_end_rog_low1) en_rog_from_end_rog_low1 <= 1'b1;
			if (en_delay_rog_to_low)
			begin
				if (cnt_delay_rog_to_low == 8'd149)
				begin
					cnt_delay_rog_to_low <= 8'd0;
					flag_start_ctr_rog <= 1'b1;
				end else begin
					cnt_delay_rog_to_low <= cnt_delay_rog_to_low + 8'd1;
				end
			end else if (en_rog_from_end_rog_low1)
			begin
				if (cnt_delay_rog_to_low == 8'd149)
				begin
					cnt_delay_rog_to_low <= 8'd0;
					flag_start_clok_from_end_rog_low1 <= 1'b1;
				end else begin
					cnt_delay_rog_to_low <= cnt_delay_rog_to_low + 8'd1;
				end
			end else begin
				cnt_delay_rog_to_low <= 8'd0;
			end
		end
	end
    
    /* Make ROG pulse to low */
    always @ (posedge sys_clk)
    begin
        if (sys_rst | flag_end_rog_low1 | flag_end_rog_low2)
        begin
            flag_start_rog_low1 <= 1'b0;
            flag_end_rog_low1 <= 1'b0;
            flag_start_rog_low2 <= 1'b0;
            flag_end_rog_low2 <= 1'b0;
            cnt_rog_low <= 16'd0;
        end 
        else begin
            if (flag_start_ctr_rog) flag_start_rog_low1 <= 1'b1;
            if (integ_done) flag_start_rog_low2 <= 1'b1;
            if (flag_start_rog_low1)
            begin
                if (cnt_rog_low == 16'd149)
                begin
                    cnt_rog_low <= 16'd0;
                    flag_end_rog_low1 <= 1'b1;
                end
                else begin
                    cnt_rog_low <= cnt_rog_low + 16'd1;
                end
            end
            else if (flag_start_rog_low2)
            begin
                if (cnt_rog_low == 16'd149)
                begin
                    cnt_rog_low <= 16'd0;
                    flag_end_rog_low2 <= 1'b1;
                end
                else begin
                    cnt_rog_low <= cnt_rog_low + 16'd1;
                end
            end
            else begin
                cnt_rog_low <= 16'd0;
            end
        end
    end
    
    /* Control ROG signal that indicate integration time */
    always @ (posedge sys_clk)
    begin
        if (sys_rst)
        begin
            ilx511b_rog <= 1'b1;
        end
        else begin
            if (flag_start_ctr_rog | integ_done) ilx511b_rog <= 1'b0;
            if (flag_end_rog_low1 | flag_end_rog_low2) ilx511b_rog <= 1'b1;
        end
    end
    
    /* Falling edge of CLK after rising edge of ROG */
    reg [15:0] cnt_clk_delay_after_rise_rog = 16'd0;
    reg en_delay_clk = 1'b0;
    reg flag_en_smp_data = 1'b0;
    always @ (posedge sys_clk)
    begin
        if (sys_rst || flag_en_smp_data)
        begin
            cnt_clk_delay_after_rise_rog <= 16'd0;
            en_delay_clk <= 1'b0;
            flag_en_smp_data <= 1'b0;
        end
        else begin
            if (flag_end_rog_low2) en_delay_clk <= 1'b1;
            if (en_delay_clk)
            begin
                if (cnt_clk_delay_after_rise_rog == `TIME_DELAY_CLK)
                begin
                    flag_en_smp_data <= 1'b1;
                    cnt_clk_delay_after_rise_rog <= 16'd0;
                end
                else begin
                    cnt_clk_delay_after_rise_rog <= cnt_clk_delay_after_rise_rog + 16'd1;
                end
            end
            else begin
                cnt_clk_delay_after_rise_rog <= 16'd0;
            end
        end
    end
    
    /* Clock sampling data */
    reg flag_smp_data = 1'b0;
    reg [15:0] cnt_smp = 16'd0;
    reg [15:0] cnt_make_smp_clk = 16'd0;
    always @ (posedge sys_clk)
    begin
        if (sys_rst)
        begin
            ilx511b_clk <= 1'b1;
            cnt_smp <= 16'd0;
        end
        else begin
            if (flag_en_smp_data) flag_smp_data <= 1'b1;
            if (cnt_smp == `SAMPLE_CLOCK) flag_smp_data <= 1'b0;
            if (flag_smp_data)
            begin
                if (cnt_make_smp_clk == `SMP_MK_CLK - 1)
                begin
                    cnt_make_smp_clk <= 16'd0;
                    
                    if (cnt_smp == `SAMPLE_CLOCK)
                    begin
                        cnt_smp <= 1'b0;
                    end
                    else begin
                        cnt_smp <= cnt_smp + 1'b1;
                        ilx511b_clk <= ~ilx511b_clk;
                    end
                end
                else begin
                    cnt_make_smp_clk <= cnt_make_smp_clk + 16'd1;
                end
            end
            else begin
                cnt_smp <= 1'b0;
                cnt_make_smp_clk <= 16'd0;
            end
        end
    end
    
    /* Flag adc start */
    detect_rising_edge adc_start_instant 
    (.sys_clk(sys_clk),
     .d_i((cnt_make_smp_clk == `START_RD_ADC) & (ilx511b_clk == 1'b0)),
     .d_o(flag_adc_start)
     );
	  
	 always @ (posedge sys_clk)
	 begin
		if (sys_rst)
		begin
			flag_sel_clok <= 1'b0;
		end else begin
			if (rising_edge_fifo_rest || ((cnt_intclk == FPGA_INTCLOCK)&&(cnt_1khz == `TIME_MAKE_1KHZ - 149))) flag_sel_clok <= 1'b1;
			if ((cnt_smp == `SAMPLE_CLOCK) || flag_start_clok_from_end_rog_low1) flag_sel_clok <= 1'b0;
		end
	 end
    
//    assign ilx511b_rog_ila = ilx511b_rog;
//    assign rising_fifo_rest_ila = rising_edge_fifo_rest;
//    assign cnt_1khz_ila = cnt_1khz;
//    assign cnt_intclk_ila = cnt_intclk;
//    assign integ_done_ila = integ_done;
//    assign ilx511b_clk_ila = ilx511b_clk;
//    assign flag_en_smp_data_ila = flag_en_smp_data;
//    assign flag_smp_data_ila = flag_smp_data;
    
endmodule
