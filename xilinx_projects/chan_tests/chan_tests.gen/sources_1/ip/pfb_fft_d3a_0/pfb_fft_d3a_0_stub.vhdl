-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
-- Date        : Thu Aug 31 18:01:40 2023
-- Host        : twiddlebug running 64-bit Ubuntu 22.04.2 LTS
-- Command     : write_vhdl -force -mode synth_stub
--               /home/ih/chfpgalite/xilinx_projects/chan_tests/chan_tests.gen/sources_1/ip/pfb_fft_d3a_0/pfb_fft_d3a_0_stub.vhdl
-- Design      : pfb_fft_d3a_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xczu47dr-ffvg1517-1-i
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity pfb_fft_d3a_0 is
  Port ( 
    in0 : in STD_LOGIC_VECTOR ( 13 downto 0 );
    in1 : in STD_LOGIC_VECTOR ( 13 downto 0 );
    in2 : in STD_LOGIC_VECTOR ( 13 downto 0 );
    in3 : in STD_LOGIC_VECTOR ( 13 downto 0 );
    in4 : in STD_LOGIC_VECTOR ( 13 downto 0 );
    in5 : in STD_LOGIC_VECTOR ( 13 downto 0 );
    in6 : in STD_LOGIC_VECTOR ( 13 downto 0 );
    in7 : in STD_LOGIC_VECTOR ( 13 downto 0 );
    shift : in STD_LOGIC_VECTOR ( 13 downto 0 );
    sync_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    clk : in STD_LOGIC;
    of_x0 : out STD_LOGIC_VECTOR ( 1 downto 0 );
    out0 : out STD_LOGIC_VECTOR ( 35 downto 0 );
    out1 : out STD_LOGIC_VECTOR ( 35 downto 0 );
    out2 : out STD_LOGIC_VECTOR ( 35 downto 0 );
    out3 : out STD_LOGIC_VECTOR ( 35 downto 0 );
    sync_out : out STD_LOGIC_VECTOR ( 0 to 0 )
  );

end pfb_fft_d3a_0;

architecture stub of pfb_fft_d3a_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "in0[13:0],in1[13:0],in2[13:0],in3[13:0],in4[13:0],in5[13:0],in6[13:0],in7[13:0],shift[13:0],sync_in[0:0],clk,of_x0[1:0],out0[35:0],out1[35:0],out2[35:0],out3[35:0],sync_out[0:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "fft_pfb,Vivado 2022.2";
begin
end;
