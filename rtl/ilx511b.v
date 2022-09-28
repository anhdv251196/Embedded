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
    /*
    00: Normal mode
    01: Software Trigger
    02: External Hardware Level Trigger
    03: External Synchronzation
    04: External Hardware Edge
    */
    input [15:0] FPGA_TRIGGERMODE,
    input [15:0] FPGA_TRIGGERDELAY,
    
    /* Pheripheral interfaces */
    input aqui_src,
    
    /* CCDs sensor interfaces */
    output reg ilx511b_clk,
    output reg ilx511b_rog,
    
    /* ADC interface */
    output flag_adc_start,
    output flag_adc_restart,
	 
	 /**/
	 output reg flag_sel_clok = 1'b0,
	 output flag_en_single_strobe
    
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
    
    /**********************************NEW CODE*********************************/
    
    /* Detect rising edge of aquisition source */
    wire rising_edge_fifo_rest;
    detect_rising_edge rising_edge_fifo_instant 
    (.sys_clk(sys_clk),
     .d_i(aqui_src),
     .d_o(rising_edge_fifo_rest)
     );

    
    localparam [3:0] IDLE = 4'd0,             /* Idle stage */
                     WAIT_CLK_TO_ROG1 = 4'd1,
                     TRIGGER_DELAY = 4'd2,
                     RESET_CCD = 4'd3,        /*  */
                     WAIT_ROG_TO_CLK1 = 4'd4,
                     INTEGRATION = 4'd5,      /*  */
                     LATCH_DATA = 4'd6,
                     WAIT_ROG_TO_CLK2 = 4'd7,
                     READ_SPECTRUM = 4'd8;
                     
    reg [3:0] current_state = 4'b0000;
    reg [3:0] next_state = 4'b000;
    
    always @ (posedge sys_clk)
    begin
        if (sys_rst)
        begin
            current_state <= 4'b0000;
        end else begin
            current_state <= next_state;
        end
    end
    
    reg en_delay_clok_high_to_rog_low = 1'b0;
    reg en_delay_rog_high_to_clok_low = 1'b0;
    reg en_keep_rog_to_low1 = 1'b0;
    reg en_keep_rog_to_low2 = 1'b0;
    reg flag_start_ctr_rog1 = 1'b0;
    reg flag_start_ctr_rog2 = 1'b0;
    reg en_latch_data = 1'b0;
    reg en_integration = 1'b0;                      /* Enable integration */
    reg start_integration  = 1'b0;                  /* Flag running integrartion time */
    reg integ_done = 1'b0;                          /* Flag indicates that integration time is done */
    reg flag_en_smp_data = 1'b0;
    reg flag_smp_data = 1'b0;
    reg flag_en_frame = 1'b0;
    reg [15:0] cnt_smp = 16'd0;
    reg [15:0] cnt_make_smp_clk = 16'd0;
    reg [15:0] cnt_1khz = 15'd0;                     /* counter that make 1ms integration time unit */
    reg [15:0] cnt_intclk = 15'd0;                   /* counter that count integration time */
    reg en_trigger_delay = 1'b0;
    reg flag_end_trigger_delay = 1'b0;
    always @ (posedge sys_clk)
    begin
        if (sys_rst)
        begin
            next_state <= IDLE;
            flag_sel_clok <= 1'b0;
            en_delay_clok_high_to_rog_low <= 1'b0;
            en_delay_rog_high_to_clok_low <= 1'b0;
            en_keep_rog_to_low1 <= 1'b0;
            en_keep_rog_to_low2 <= 1'b0;
            start_integration  <= 1'b0;
            flag_smp_data <= 1'b0;
            flag_en_frame <= 1'b0;
            en_trigger_delay <= 1'b0;
        end else begin
            case (current_state)
            IDLE:
            begin
                flag_sel_clok <= 1'b0;
                flag_en_frame <= 1'b0;
                if (rising_edge_fifo_rest) 
                begin
                    next_state <= TRIGGER_DELAY;
                    en_trigger_delay <= 1'b1;
                end
            end
            
            TRIGGER_DELAY:
            begin
                if (flag_end_trigger_delay)
                begin
                    next_state <= WAIT_CLK_TO_ROG1;
                    en_trigger_delay <= 1'b0;
                    en_delay_clok_high_to_rog_low <= 1'b1;
                end
            end
            
            WAIT_CLK_TO_ROG1:
            begin
                flag_sel_clok <= 1'b1;
                if (flag_start_ctr_rog1)
                begin
                    next_state <= RESET_CCD;
                    en_keep_rog_to_low1 <= 1'b1;
                    en_delay_clok_high_to_rog_low <= 1'b0;
                end
            end
            
            RESET_CCD:
            begin
                if (en_integration) 
                begin
                    if (FPGA_TRIGGERMODE == 16'd3)
                    begin
                        next_state <= READ_SPECTRUM;
                        flag_smp_data <= 1'b1;
                    end else begin
                        next_state <= INTEGRATION;
                        start_integration  <= 1'b1;
                    end
                    en_keep_rog_to_low1 <= 1'b0;
                end
            end
            
            INTEGRATION:
            begin
                if ((cnt_intclk == FPGA_INTCLOCK-1)&&(cnt_1khz == `TIME_MAKE_1KHZ - 299)) flag_sel_clok <= 1'b1;
                if ((cnt_intclk == 0)&&(cnt_1khz == 299)) flag_sel_clok <= 1'b0;
                if (integ_done)
                begin
                    next_state <= LATCH_DATA;
                    start_integration <= 1'b0;
                    en_keep_rog_to_low2 <= 1'b1;
                end
            end
            
            LATCH_DATA:
            begin
                if (en_latch_data)
                begin
                    next_state <= WAIT_ROG_TO_CLK2;
                    en_keep_rog_to_low2 <= 1'b0;
                    en_delay_rog_high_to_clok_low <= 1'b1;
                end
            end
            
            WAIT_ROG_TO_CLK2:
            begin
                if (flag_en_smp_data)
                begin
                    next_state <= READ_SPECTRUM;
                    en_delay_rog_high_to_clok_low <= 1'b0;
                    flag_smp_data <= 1'b1;
                end
            end
            
            READ_SPECTRUM:
            begin
                if (cnt_smp == `SAMPLE_CLOCK)
                begin
                    next_state <= IDLE;
                    flag_smp_data <= 1'b0;
                    flag_en_frame <= 1'b1;
                end
            end
            
            default: next_state <= IDLE;
            endcase
        end
    end
    
    /* Control ROG pin of CCD sensor */
    always @ (posedge sys_clk)
    begin
        if (sys_rst | flag_en_frame)
        begin
            ilx511b_rog <= 1'b1;
        end else begin
            if (flag_start_ctr_rog1 | integ_done) ilx511b_rog <= 1'b0;
            if (en_integration | en_latch_data) ilx511b_rog <= 1'b1;
        end
    end
    
    /**/
    reg [15:0] cnt_trigger_delay = 16'd0;
    reg [9:0] cnt_make_2MHz = 10'd0;
    always @ (posedge sys_clk)
    begin
        if (sys_rst | flag_end_trigger_delay)
        begin
            cnt_trigger_delay <= 16'd0;
            flag_end_trigger_delay <= 1'b0;
            cnt_make_2MHz <= 10'd0;
        end else begin
            if (en_trigger_delay)
            begin
                if (cnt_trigger_delay == FPGA_TRIGGERDELAY) flag_end_trigger_delay <= 1'b1;
                if (cnt_make_2MHz == 10'd23)
                begin
                    cnt_make_2MHz <= 10'd0;
                    cnt_trigger_delay <= cnt_trigger_delay + 16'd1;
                end else begin
                    cnt_make_2MHz <= cnt_make_2MHz + 10'd1;
                end
            end
        end
    end
    
    always @ (posedge sys_clk)
    begin
        if (sys_rst | flag_en_frame)
        begin
            ilx511b_clk <= 1'b1;
        end else begin
        end
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
    
    /**/
    reg [9:0] cnt_delay_rog_high_to_clok_low = 10'd0;
    always @ (posedge sys_clk)
    begin
        if (sys_rst | flag_en_smp_data)
        begin
            cnt_delay_rog_high_to_clok_low <= 10'd0;
            flag_en_smp_data <= 1'b0;
        end else begin
            if (en_delay_rog_high_to_clok_low)
            begin
                if (cnt_delay_rog_high_to_clok_low == 10'd299)
                begin
                    cnt_delay_rog_high_to_clok_low <= 10'd0;
                    flag_en_smp_data <= 1'b1;
                end else begin
                    cnt_delay_rog_high_to_clok_low <= cnt_delay_rog_high_to_clok_low + 10'd1;
                end
            end else begin
                cnt_delay_rog_high_to_clok_low <= 10'd0;
            end
        end
    end
    
    /*************************/
    /* Make integration time */
    /*************************/
    always @ (posedge sys_clk)
    begin
        if (sys_rst | integ_done)
        begin
            integ_done <= 1'b0;
            cnt_1khz <= 15'd0;
            cnt_intclk <= 15'd0;
        end else begin
            if (start_integration) begin
                if (cnt_intclk == FPGA_INTCLOCK) integ_done <= 1'b1;
                if (cnt_1khz == `TIME_MAKE_1KHZ)
                begin
                    cnt_1khz <= 15'd0;
                    cnt_intclk <= cnt_intclk + 15'd1;
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
    
    /* Keep ROG low 300 cycle clock for the first time */
    reg [9:0] cnt_keep_rog_low1 = 10'd0;
    always @ (posedge sys_clk)
    begin
        if (sys_rst | en_integration)
        begin
            cnt_keep_rog_low1 <= 10'd0;
            en_integration <= 1'b0;
        end else begin
            if (en_keep_rog_to_low1)
            begin
                if (cnt_keep_rog_low1 == 10'd299)
                begin
                    cnt_keep_rog_low1 <= 10'd0;
                    en_integration <= 1'b1;
                end else begin
                    cnt_keep_rog_low1 <= cnt_keep_rog_low1 + 10'd1;
                end
            end else begin
                cnt_keep_rog_low1 <= 10'd0;
            end
        end
    end
    
    /* Keep ROG low 300 cycle clock for the first time */
    reg [9:0] cnt_keep_rog_low2 = 10'd0;
    always @ (posedge sys_clk)
    begin
        if (sys_rst | en_latch_data)
        begin
            cnt_keep_rog_low2 <= 10'd0;
            en_latch_data <= 1'b0;
        end else begin
            if (en_keep_rog_to_low2)
            begin
                if (cnt_keep_rog_low2 == 10'd299)
                begin
                    cnt_keep_rog_low2 <= 10'd0;
                    en_latch_data <= 1'b1;
                end else begin
                    cnt_keep_rog_low2 <= cnt_keep_rog_low2 + 10'd1;
                end
            end else begin
                cnt_keep_rog_low2 <= 10'd0;
            end
        end
    end
    
    /**/
    reg [9:0] cnt_delay_clok_high_to_rog_low = 10'd0;
    always @ (posedge sys_clk)
    begin
        if (sys_rst | flag_start_ctr_rog1)
        begin
            cnt_delay_clok_high_to_rog_low <= 10'd0;
            flag_start_ctr_rog1 <= 1'b0;
        end else begin
            if (en_delay_clok_high_to_rog_low)
            begin
                if (cnt_delay_clok_high_to_rog_low == 10'd299)
                begin
                    cnt_delay_clok_high_to_rog_low <= 10'd0;
                    flag_start_ctr_rog1 <= 1'b1;
                end else begin
                    cnt_delay_clok_high_to_rog_low <= cnt_delay_clok_high_to_rog_low + 10'd1;
                end
            end else begin
                cnt_delay_clok_high_to_rog_low <= 10'd0;
            end
        end
    end
    
    /* Flag adc start */
    detect_rising_edge adc_start_instant 
    (.sys_clk(sys_clk),
     .d_i((cnt_make_smp_clk == `START_RD_ADC) & (ilx511b_clk == 1'b0)),
     .d_o(flag_adc_start)
     );
     
     assign flag_adc_restart = flag_start_ctr_rog1;
     assign flag_en_single_strobe = en_latch_data;
    
endmodule
