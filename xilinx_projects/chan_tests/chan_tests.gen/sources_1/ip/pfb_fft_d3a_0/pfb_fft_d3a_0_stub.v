// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
// Date        : Thu Aug 31 18:01:40 2023
// Host        : twiddlebug running 64-bit Ubuntu 22.04.2 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/ih/chfpgalite/xilinx_projects/chan_tests/chan_tests.gen/sources_1/ip/pfb_fft_d3a_0/pfb_fft_d3a_0_stub.v
// Design      : pfb_fft_d3a_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xczu47dr-ffvg1517-1-i
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fft_pfb,Vivado 2022.2" *)
module pfb_fft_d3a_0(in0, in1, in2, in3, in4, in5, in6, in7, shift, sync_in, clk, 
  of_x0, out0, out1, out2, out3, sync_out)
/* synthesis syn_black_box black_box_pad_pin="in0[13:0],in1[13:0],in2[13:0],in3[13:0],in4[13:0],in5[13:0],in6[13:0],in7[13:0],shift[13:0],sync_in[0:0],clk,of_x0[1:0],out0[35:0],out1[35:0],out2[35:0],out3[35:0],sync_out[0:0]" */;
  input [13:0]in0;
  input [13:0]in1;
  input [13:0]in2;
  input [13:0]in3;
  input [13:0]in4;
  input [13:0]in5;
  input [13:0]in6;
  input [13:0]in7;
  input [13:0]shift;
  input [0:0]sync_in;
  input clk;
  output [1:0]of_x0;
  output [35:0]out0;
  output [35:0]out1;
  output [35:0]out2;
  output [35:0]out3;
  output [0:0]sync_out;
endmodule
