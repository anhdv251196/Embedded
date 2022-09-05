///////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022 Xilinx, Inc.
// All Rights Reserved
///////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor     : Xilinx
// \   \   \/     Version    : 14.7
//  \   \         Application: Xilinx CORE Generator
//  /   /         Filename   : chipscope.v
// /___/   /\     Timestamp  : Tue Aug 23 02:53:50 UTC 2022
// \   \  /  \
//  \___\/\___\
//
// Design Name: Verilog Synthesis Wrapper
///////////////////////////////////////////////////////////////////////////////
// This wrapper is used to integrate with Project Navigator and PlanAhead

`timescale 1ns/1ps

module chipscope(
    CONTROL,
    CLK,
    TRIG0,
    TRIG1,
    TRIG2,
    TRIG3) /* synthesis syn_black_box syn_noprune=1 */;


inout [35 : 0] CONTROL;
input CLK;
input [0 : 0] TRIG0;
input [0 : 0] TRIG1;
input [0 : 0] TRIG2;
input [0 : 0] TRIG3;

endmodule
