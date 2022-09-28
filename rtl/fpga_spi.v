`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Intins
// Engineer: anhdv
// 
// Create Date: 08/14/2022 08:50:33 PM
// Design Name: 
// Module Name: fpga_spi
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


module fpga_spi(
    /* System interface */
    input sys_clk,      /* system clock */
    input sys_rst,
    
    /* FPGA parameters */
    output reg [15:0] FPGA_VERION      = 16'h0001,         /*The current FPGA configuration version. - 0x04*/
    output reg [15:0] FPGA_COUNTBASE   = 16'h0001,         /*A base freq counter for the Continous strobe function. - 0x08*/
    output reg [15:0] FPGA_STRBCOUNT   = 16'h0001,         /*0x0C*/
    output reg [15:0] FPGA_INTCLOCK    = 16'h0006,         /*The detecter integration time in ms [1:65.535]. 0x18*/
    output reg [15:0] FPGA_TRIGGERDELAY    = 16'h0006,
	output reg [15:0] FPGA_TRIGGERMODE    = 16'h0006,
	output reg [15:0] FPGA_SSLOWDELAY  = 16'h0005,         /*The time delay that the SingleStrobe signal goes low after the start of an integration time - 0x38*/
    output reg [15:0] FPGA_SSHIGHDELAY = 16'h0001,         /*The time delay that the SingleStrobe signal goes high after the start of an integration time - 0x3C*/
    output reg [15:0] FPGA_LAMPENABLE  = 16'h0000,         /*Global enable for both the ContinousStrobe and SingleStrobe functions - 0x40*/
    output reg [15:0] FPGA_OFFSETVALUE = 16'h0000,         /*Consistent dectector baseline, We can get this value from detector's optical blank pixel - 0x5C*/
    output reg [15:0] FPGA_MAXSATVALUE = 16'h0001,         /*Scaling 16bit - 0x68*/
    
    /* SPI interface */
    input fpga_clk,         /* fpga spi clk*/
    input fpga_cs,          /* fpga spi cs*/
    input fpga_mosi,        /* fpga spi mosi*/
    output reg fpga_miso,    /* fpga spi miso*/
    
    /* Data interface */
	 input flag_rise_fifo_rset,
	 input trigger
//    output [23:0] receive_data_ila,
//    output [4:0] cnt_spi_ila,
//    output wr_or_rd_ila,
//    output Rx_Done_ila,
//    output [16:0] transmit_data_ila,
//    output [4:0] cnt_shift_data_ila,
//    output [7:0] fpga_addr_ila
//    output fpga_clk_rise,
//    output fpga_cs_rise
    );
    
    localparam version = 2022;
    
    reg [4:0] cnt_spi = 5'd0;
    reg wr_or_rd = 1'b0;
    reg Rx_Done = 1'b0;
    reg [7:0] fpga_addr = 8'h04; 
    
    
//    /* FPGA parameters */
//    reg [15:0] FPGA_VERION      = 16'h0001;         /*The current FPGA configuration version. - 0x04*/
//    reg [15:0] FPGA_COUNTBASE   = 16'h0001;         /*A base freq counter for the Continous strobe function. - 0x08*/
//    reg [15:0] FPGA_STRBCOUNT   = 16'h0001;         /*0x0C*/
//    reg [15:0] FPGA_INTCLOCK    = 16'h0001;         /*The detecter integration time in ms [1:65.535]. 0x18*/
//    reg [15:0] FPGA_SSLOWDELAY  = 16'h0001;         /*The time delay that the SingleStrobe signal goes low after the start of an integration time - 0x38*/
//    reg [15:0] FPGA_SSHIGHDELAY = 16'h0001;         /*The time delay that the SingleStrobe signal goes high after the start of an integration time - 0x3C*/
//    reg [15:0] FPGA_LAMPENABLE  = 16'h0001;         /*Global enable for both the ContinousStrobe and SingleStrobe functions - 0x40*/
//    reg [15:0] FPGA_OFFSETVALUE = 16'h0000;         /*Consistent dectector baseline, We can get this value from detector's optical blank pixel - 0x5C*/
//    reg [15:0] FPGA_MAXSATVALUE = 16'h0001;         /*Scaling 16bit - 0x68*/

    wire fpga_clk_rise_edge;
    detect_rising_edge fpga_clk_rise_edge_instance 
    (.sys_clk(sys_clk),
     .d_i(fpga_clk),
     .d_o(fpga_clk_rise_edge)
     );
	  
	 wire fpga_clk_fall_edge;
    detect_falling_edge fpga_clk_fall_edge_instance 
    (.sys_clk(sys_clk),
     .d_i(fpga_clk),
     .d_o(fpga_clk_fall_edge)
     );
     
    wire fpga_cs_rise_edge;
    detect_rising_edge fpga_cs_rise_edge_instance 
    (.sys_clk(sys_clk),
     .d_i(fpga_cs),
     .d_o(fpga_cs_rise_edge)
     );
	  
	 reg [15:0] FPGA_TRIGGERSTATUS = 16'd0;
	 always @ (posedge sys_clk)
	 begin
		if (sys_rst | flag_rise_fifo_rset)
		begin
			FPGA_TRIGGERSTATUS <= 16'd0;
		end else begin
			if (trigger) FPGA_TRIGGERSTATUS <= 16'd1;
		end
	 end
    
    reg [23:0] receive_data;
    /* Sample data on rising edge of clock */
    always @ (posedge sys_clk)
    begin
        if (fpga_cs_rise_edge || sys_rst)
        begin
            cnt_spi <= 5'd0;
            //wr_or_rd <= 1'b0;
            Rx_Done <= 1'b0;
        end
        else if (fpga_clk_rise_edge && ~fpga_cs) begin
            cnt_spi <= cnt_spi + 5'd1;
            receive_data <= {receive_data[22:0], fpga_mosi};
/*             if (cnt_spi == 5'd8) begin
                wr_or_rd <= receive_data[0];
                fpga_addr <= {receive_data[7:2], 2'b0};
            end */
            if (cnt_spi == 5'd23) Rx_Done <= 1'b1;
        end
    end
    
    reg [16:0] transmit_data = 17'd0;
    always @ (posedge sys_clk)
    begin
        if (cnt_spi == 5'd8)
        begin
            case (fpga_addr)
					 8'h01: transmit_data <= {FPGA_TRIGGERSTATUS, 1'b0};
                8'h04: transmit_data <= {FPGA_VERION, 1'b0};
                8'h08: transmit_data <= {FPGA_COUNTBASE, 1'b0};
                8'h0C: transmit_data <= {FPGA_STRBCOUNT, 1'b0};
                8'h18: transmit_data <= {FPGA_INTCLOCK, 1'b0};
				8'h28: transmit_data <= {FPGA_TRIGGERDELAY, 1'b0};
				8'h2C: transmit_data <= {FPGA_TRIGGERMODE, 1'b0};
                8'h38: transmit_data <= {FPGA_SSLOWDELAY, 1'b0};
                8'h3C: transmit_data <= {FPGA_SSHIGHDELAY, 1'b0};
                8'h40: transmit_data <= {FPGA_LAMPENABLE, 1'b0};
				8'h5C: transmit_data <= {FPGA_OFFSETVALUE, 1'b0};
				8'h68: transmit_data <= {FPGA_MAXSATVALUE, 1'b0};
                default: transmit_data <= {FPGA_VERION, 1'b0};
            endcase
        end
    end
    
    reg [4:0] cnt_shift_data = 5'd16;
    /* Shifted out on the falling edge of clock */
    always @ (posedge sys_clk)
    begin
		if (fpga_cs_rise_edge || sys_rst)
        begin
            wr_or_rd <= 1'b0;
			fpga_addr <= 8'd0;
        end 
		else begin
			if (fpga_clk_fall_edge)
			begin
				if (cnt_spi == 5'd8) begin
					wr_or_rd <= receive_data[0];
					fpga_addr <= {receive_data[7:2], 2'b0};
				end
				if (cnt_spi >= 5'd8 && cnt_spi <= 5'd23)
				begin
					cnt_shift_data <= cnt_shift_data - 5'd1;
					fpga_miso <= transmit_data[cnt_shift_data];
				end
				else begin
					fpga_miso <= 1'b0;
					cnt_shift_data <= 5'd16;
				end
			end
		end
    end
    
    always @ (posedge sys_clk)
    begin
        if (sys_rst) begin
            FPGA_VERION <= version;
            FPGA_COUNTBASE <= 16'd48000;
            FPGA_STRBCOUNT <= 16'd4800;
            FPGA_INTCLOCK <= 16'd6;
			FPGA_TRIGGERDELAY <= 16'd0;
			FPGA_TRIGGERMODE <= 16'd0;
            FPGA_SSLOWDELAY <= 16'h0005;
            FPGA_SSHIGHDELAY <= 16'h0001;
            FPGA_LAMPENABLE <= 16'h0000;
            FPGA_OFFSETVALUE <= 16'h0000;
            FPGA_MAXSATVALUE <= 16'h55F0;
        end
        else begin
            if (Rx_Done & wr_or_rd) begin
                case ({receive_data[23:18],2'b0})
                    8'h08: FPGA_COUNTBASE <= receive_data[15:0];
                    8'h0C: FPGA_STRBCOUNT <= receive_data[15:0];
                    8'h18: FPGA_INTCLOCK <= receive_data[15:0];
					8'h28: FPGA_TRIGGERDELAY <= receive_data[15:0];
					8'h2C: FPGA_TRIGGERMODE <= receive_data[15:0];
                    8'h38: FPGA_SSLOWDELAY <= receive_data[15:0];
                    8'h3C: FPGA_SSHIGHDELAY <= receive_data[15:0];
                    8'h40: FPGA_LAMPENABLE <= receive_data[15:0];
					8'h5C: FPGA_OFFSETVALUE <= receive_data[15:0];
					8'h68: FPGA_MAXSATVALUE <= receive_data[15:0];
                    default: FPGA_VERION <= version;
                endcase
            end 
        end
    end
    
//    assign receive_data_ila = receive_data;
//    assign cnt_spi_ila = cnt_spi;
//    assign wr_or_rd_ila = wr_or_rd;
//    assign Rx_Done_ila = Rx_Done;
//    assign transmit_data_ila = transmit_data;
//    assign cnt_shift_data_ila = cnt_shift_data;
//    assign fpga_addr_ila = fpga_addr;
//    assign fpga_clk_rise = fpga_clk_rise_edge;
//    assign fpga_cs_rise = fpga_cs_rise_edge;
    
endmodule
