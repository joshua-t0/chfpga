-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
-- Date        : Fri Feb 20 13:23:33 2026
-- Host        : twiddlebug running 64-bit Ubuntu 22.04.5 LTS
-- Command     : write_vhdl -force -mode synth_stub /home/vbidula/chfpgalite/_Cores/KC705/FFT2/FFT2_stub.vhdl
-- Design      : FFT2
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7k420tffg901-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FFT2 is
  Port ( 
    ce_1 : in STD_LOGIC;
    clk_1 : in STD_LOGIC;
    in0 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    in1 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    in2 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    in3 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    shift : in STD_LOGIC_VECTOR ( 10 downto 0 );
    sync_in : in STD_LOGIC;
    out1 : out STD_LOGIC_VECTOR ( 35 downto 0 );
    out2 : out STD_LOGIC_VECTOR ( 35 downto 0 );
    overflow : out STD_LOGIC;
    sync_out : out STD_LOGIC
  );

end FFT2;

architecture stub of FFT2 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "ce_1,clk_1,in0[7:0],in1[7:0],in2[7:0],in3[7:0],shift[10:0],sync_in,out1[35:0],out2[35:0],overflow,sync_out";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "simple_pfb_v2,Vivado 2022.2";
begin
end;
