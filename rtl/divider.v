`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/06/2022 02:59:12 AM
// Design Name: 
// Module Name: divider
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


module divider #(
    parameter WIDTH=10,  // width of numbers in bits
    parameter FBITS=4   // fractional bits (for fixed point)
    ) (
    input wire clk,
    input wire start,          // start signal
    output reg busy,           // calculation in progress
    output reg valid,          // quotient and remainder are valid
    output reg dbz,            // divide by zero flag
    output reg ovf,            // overflow flag (fixed-point)
    input wire [WIDTH-1:0] x,  // dividend
    input wire [WIDTH-1:0] y,  // divisor
    output reg [WIDTH+16-1:0] q,  // quotient
    output reg [WIDTH-1:0] r,   // remainder
    input wire [15:0] w_data_i,
    output wire [15:0] r_data_o,
    output wire r_data_valid
    );

    // avoid negative vector width when fractional bits are not used
    localparam FBITSW = (FBITS) ? FBITS : 1;

    reg [WIDTH-1:0] y1;           // copy of divisor
    reg [WIDTH-1:0] q1, q1_next;  // intermediate quotient
    reg [WIDTH:0] ac, ac_next;    // accumulator (1 bit wider)

    localparam ITER = WIDTH+FBITS;  // iterations are dividend width + fractional bits
    reg [8:0] i;     // iteration counter

    always @ (*)
    begin
        if (ac >= {1'b0,y1}) begin
            ac_next = ac - y1;
            {ac_next, q1_next} = {ac_next[WIDTH-1:0], q1, 1'b1};
        end else begin
            {ac_next, q1_next} = {ac, q1} << 1;
        end
    end

    always @(posedge clk) 
    begin
        if (start) begin
            valid <= 0;
            ovf <= 0;
            i <= 0;
            if (y == 0) begin  // catch divide by zero
                busy <= 0;
                dbz <= 1;
            end else begin
                busy <= 1;
                dbz <= 0;
                y1 <= y;
                {ac, q1} <= {{WIDTH{1'b0}}, x, 1'b0};
            end
        end else if (busy) begin
            if (i == ITER-1) begin  // done
                busy <= 0;
                valid <= 1;
                q <= q1_next * w_data_i;
                r <= ac_next[WIDTH:1];  // undo final shift
            end else if (i == WIDTH-1 && q1_next[WIDTH-1:WIDTH-FBITSW]) begin // overflow?
                busy <= 0;
                ovf <= 1;
                q <= 0;
                r <= 0;
            end else begin  // next iteration
                i <= i + 1;
                ac <= ac_next;
                q1 <= q1_next;
            end
        end
    end
    
    reg valid_ff = 1'b0;
    always @ (posedge clk)
    begin
        valid_ff <= valid;
    end
    
    assign r_data_valid = valid & (valid ^ valid_ff);
    assign r_data_o = (q > 20'd1048575) ? 16'hFFFF : q[19:4];
    
endmodule
