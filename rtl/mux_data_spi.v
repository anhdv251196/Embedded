`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/17/2022 08:37:40 PM
// Design Name: 
// Module Name: mux_data_spi
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


module mux_data_spi(
    /* SPI interface */
    input spi_mosi,
    inout spi_miso,

    /* FPGA spi */
    input fpga_cs,
    output fpga_mosi,
    input fpga_miso,
    
    /* FIFO spi */
    input fifo_cs,
    output fifo_mosi,
    input fifo_miso,
	 
	 /* EEPROM */
	 input e2_clk,
	 input e2_cs,
	 output eeprom_clk,
	 output eeprom_cs,
	 
	 /*ADT*/
	 input adt_cs,
	 output adt7301_clk,
	 output adt7301_cs
	 //input adt7301_miso
    );
	 
	 wire m0_scl_o;
	 wire m0_scl_i;
	  IOBUF scl_iobuf_0
	 (.O(m0_scl_i),
	  .IO(spi_miso),
	  .I(m0_scl_o),
	  .T(~e2_cs | ~adt_cs)
	  );
    
    //assign m0_scl_o = (fifo_cs == 1'b0) ? fifo_miso : (fpga_cs == 1'b0) ? fpga_miso : (adt_cs == 1'b0) ? m0_scl_i :1'b0;
	 assign m0_scl_o = ((fifo_cs == 1'b0) && (fpga_cs == 1'b0)) ? fifo_miso : (fpga_cs == 1'b0) ? fpga_miso : 1'b0;
//	 wire [2:0] spi_mux;
//	 assign spi_mux = {fifo_cs, fpga_cs, adt_cs};
//	 always @ (*)
//	 begin
//		case (spi_mux)
//			3'b011: m0_scl_o = fifo_miso;
//			3'b101: m0_scl_o = fpga_miso;
//			3'b110: m0_scl_o = adt7301_miso;
//			default: m0_scl_o = 1'b0;
//		endcase
//	 end
    assign fpga_mosi = (fpga_cs == 1'b0) ? spi_mosi : 1'b0;
    assign fifo_mosi = (fifo_cs == 1'b0) ? spi_mosi : 1'b0;
	 assign eeprom_clk = e2_clk;
	 assign eeprom_cs = e2_cs;
	 assign adt7301_clk = e2_clk;
	 assign adt7301_cs = adt_cs;
    
endmodule
