-- Generated from Simulink block 
library IEEE;
use IEEE.std_logic_1164.all;
library xil_defaultlib;
entity hirax_bit_growth_stub is
  port (
    pol_in1 : in std_logic_vector( 8-1 downto 0 );
    pol_in2 : in std_logic_vector( 8-1 downto 0 );
    pol_in3 : in std_logic_vector( 8-1 downto 0 );
    pol_in4 : in std_logic_vector( 8-1 downto 0 );
    shift : in std_logic_vector( 11-1 downto 0 );
    sync_in : in std_logic_vector( 1-1 downto 0 );
    clk : in std_logic;
    out00 : out std_logic_vector( 58-1 downto 0 );
    out01 : out std_logic_vector( 58-1 downto 0 );
    overflow : out std_logic_vector( 1-1 downto 0 );
    sync_out : out std_logic_vector( 1-1 downto 0 );
    gateway_out1 : out std_logic_vector( 26-1 downto 0 );
    gateway_out11 : out std_logic_vector( 8-1 downto 0 );
    gateway_out2 : out std_logic_vector( 26-1 downto 0 );
    gateway_out3 : out std_logic_vector( 26-1 downto 0 );
    gateway_out4 : out std_logic_vector( 26-1 downto 0 );
    gateway_out1_x0 : out std_logic_vector( 26-1 downto 0 );
    gateway_out2_x0 : out std_logic_vector( 26-1 downto 0 );
    gateway_out3_x0 : out std_logic_vector( 26-1 downto 0 );
    gateway_out1_x1 : out std_logic_vector( 8-1 downto 0 );
    gateway_out11_x0 : out std_logic_vector( 18-1 downto 0 )
  );
end hirax_bit_growth_stub;
architecture structural of hirax_bit_growth_stub is 
begin
  sysgen_dut : entity xil_defaultlib.hirax_bit_growth 
  port map (
    pol_in1 => pol_in1,
    pol_in2 => pol_in2,
    pol_in3 => pol_in3,
    pol_in4 => pol_in4,
    shift => shift,
    sync_in => sync_in,
    clk => clk,
    out00 => out00,
    out01 => out01,
    overflow => overflow,
    sync_out => sync_out,
    gateway_out1 => gateway_out1,
    gateway_out11 => gateway_out11,
    gateway_out2 => gateway_out2,
    gateway_out3 => gateway_out3,
    gateway_out4 => gateway_out4,
    gateway_out1_x0 => gateway_out1_x0,
    gateway_out2_x0 => gateway_out2_x0,
    gateway_out3_x0 => gateway_out3_x0,
    gateway_out1_x1 => gateway_out1_x1,
    gateway_out11_x0 => gateway_out11_x0
  );
end structural;
