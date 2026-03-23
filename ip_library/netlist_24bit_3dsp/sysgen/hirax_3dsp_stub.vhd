-- Generated from Simulink block 
library IEEE;
use IEEE.std_logic_1164.all;
library xil_defaultlib;
entity hirax_3dsp_stub is
  port (
    gateway_in5 : in std_logic_vector( 11-1 downto 0 );
    pol_in1 : in std_logic_vector( 8-1 downto 0 );
    pol_in2 : in std_logic_vector( 8-1 downto 0 );
    pol_in3 : in std_logic_vector( 8-1 downto 0 );
    pol_in4 : in std_logic_vector( 8-1 downto 0 );
    sync_in : in std_logic_vector( 1-1 downto 0 );
    clk : in std_logic;
    out_00 : out std_logic_vector( 48-1 downto 0 );
    out_01 : out std_logic_vector( 48-1 downto 0 );
    overflow : out std_logic_vector( 1-1 downto 0 );
    sync_out : out std_logic_vector( 1-1 downto 0 )
  );
end hirax_3dsp_stub;
architecture structural of hirax_3dsp_stub is 
begin
  sysgen_dut : entity xil_defaultlib.hirax_3dsp 
  port map (
    gateway_in5 => gateway_in5,
    pol_in1 => pol_in1,
    pol_in2 => pol_in2,
    pol_in3 => pol_in3,
    pol_in4 => pol_in4,
    sync_in => sync_in,
    clk => clk,
    out_00 => out_00,
    out_01 => out_01,
    overflow => overflow,
    sync_out => sync_out
  );
end structural;
