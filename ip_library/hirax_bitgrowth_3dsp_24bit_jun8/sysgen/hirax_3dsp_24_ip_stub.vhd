-- Generated from Simulink block 
library IEEE;
use IEEE.std_logic_1164.all;
library xil_defaultlib;
entity hirax_3dsp_24_ip_stub is
  port (
    bitshift : in std_logic_vector( 11-1 downto 0 );
    pol_in_1 : in std_logic_vector( 8-1 downto 0 );
    pol_in_2 : in std_logic_vector( 8-1 downto 0 );
    pol_in_3 : in std_logic_vector( 8-1 downto 0 );
    pol_in_4 : in std_logic_vector( 8-1 downto 0 );
    sync_in : in std_logic_vector( 1-1 downto 0 );
    clk : in std_logic;
    out00 : out std_logic_vector( 48-1 downto 0 );
    out01 : out std_logic_vector( 48-1 downto 0 );
    overflow : out std_logic_vector( 1-1 downto 0 );
    sync_out : out std_logic_vector( 1-1 downto 0 )
  );
end hirax_3dsp_24_ip_stub;
architecture structural of hirax_3dsp_24_ip_stub is 
begin
  sysgen_dut : entity xil_defaultlib.hirax_3dsp_24_ip 
  port map (
    bitshift => bitshift,
    pol_in_1 => pol_in_1,
    pol_in_2 => pol_in_2,
    pol_in_3 => pol_in_3,
    pol_in_4 => pol_in_4,
    sync_in => sync_in,
    clk => clk,
    out00 => out00,
    out01 => out01,
    overflow => overflow,
    sync_out => sync_out
  );
end structural;
