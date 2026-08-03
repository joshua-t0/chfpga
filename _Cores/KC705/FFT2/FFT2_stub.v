// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
// Date        : Fri Feb 20 13:23:33 2026
// Host        : twiddlebug running 64-bit Ubuntu 22.04.5 LTS
// Command     : write_verilog -force -mode synth_stub /home/vbidula/chfpgalite/_Cores/KC705/FFT2/FFT2_stub.v
// Design      : FFT2
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k420tffg901-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "simple_pfb_v2,Vivado 2022.2" *)
module FFT2(ce_1, clk_1, in0, in1, in2, in3, shift, sync_in, out1, 
  out2, overflow, sync_out)
/* synthesis syn_black_box black_box_pad_pin="ce_1,clk_1,in0[7:0],in1[7:0],in2[7:0],in3[7:0],shift[10:0],sync_in,out1[35:0],out2[35:0],overflow,sync_out" */;
  input ce_1;
  input clk_1;
  input [7:0]in0;
  input [7:0]in1;
  input [7:0]in2;
  input [7:0]in3;
  input [10:0]shift;
  input sync_in;
  output [35:0]out1;
  output [35:0]out2;
  output overflow;
  output sync_out;
endmodule
