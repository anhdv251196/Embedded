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


module divider(
    input sys_clk,
    input [15:0] Q,
    input [15:0] M,
    output reg [15:0] Quo = 0,
    output reg [15:0] Rem = 0,
    
    input start
    );
    
    reg [15:0] a1, b1;
    reg [15:0] p1;
    
    reg [4:0] index = 5'd0;
    
    parameter IDLE = 8'd0;
    parameter S0 = 8'd1;
    parameter S1 = 8'd2;
    parameter S2 = 8'd3;
    parameter S3 = 8'd4;
    parameter S4 = 8'd5;
    reg [7:0] cur_state;
    reg [7:0] next_state = IDLE;
    
    always @ (posedge sys_clk)
    begin
        case (cur_state)
            IDLE: 
                begin
                    a1 <= Q;
                    b1 <= M;
                    p1 <= 0;
                    index <= 5'd0;
                    if(start) next_state <= S0;
                end
            S0: 
                begin
                    p1 <= {p1[14:0], a1[15]};
                    a1[15:1] <= a1[14:0];
                    next_state <= S1;
                end
            S1:
                begin
                    p1 <= p1 - b1;
                    next_state <= S2;
                end
            S2:
                begin
                    if (p1[15] == 1) begin
                        a1[0] <= 0;
                        p1 <= p1 + b1;
                    end else
                        a1[0] <= 1;
                    index <= index + 5'd1;
                    if (index == 5'd15) next_state <= IDLE;
                    else next_state <= S0;
                end
            default: next_state <= IDLE;
        endcase
    end
    
    always @ (*)
    begin
        cur_state <= next_state;
    end
    
    always @ (posedge sys_clk)
    begin
//        if (start)
//        begin
//            a1 <= Q;
//            b1 <= M;
//            p1 <= 0;
//            flag <= 1'd1;
//        end
        
////        if (a1[15] == 1) a1 <= 0 - a1;
////        if (b1[15] == 1) b1 <= 0 - b1;
////        if ((b1[15] == 1) && (a1[15] == 1)) begin
////            b1 <= 0 - b1;
////            a1 <= 0 - a1;
////        end
        
//        if ((index < 16) && (flag == 1)) begin
//            p1 <= {p1[14:0], a1[15]};
//            a1[15:1] <= a1[14:0];
//            p1 <= p1 - b1;
//            if (p1[15] == 1) begin
//                a1[0] <= 0;
//                p1 <= p1 + b1;
//            end else
//                a1[0] <= 1;
//            index <= index + 5'd1;
//        end
        
        if ((Q[15] == 1) && (M[15] == 0))
        begin
            Quo <= 0 - a1;
            Rem <= 0 - p1;
        end
        
        else if ((Q[15] == 0) && (M[15] == 1))
        begin
            Quo <= 0 - a1;
            Rem <= p1;
        end
        
        else if ((Q[15] == 1) && (M[15] == 1))
        begin
            Quo <= a1;
            Rem <= 0 - p1;
        end
        
        else begin
            Quo <= a1;
            Rem <= p1;
        end
    end
    
endmodule
