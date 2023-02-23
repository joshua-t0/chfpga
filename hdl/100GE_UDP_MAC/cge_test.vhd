
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_misc.ALL; -- for reduce functions

library UNISIM;
use UNISIM.VComponents.all;

library work;
use work.chFPGA_Package.all;

entity cge_test is
	port (
		tx_p: out std_logic_vector(0 to 3);
		tx_n: out std_logic_vector(0 to 3);
		gt_ref_clk_p : in std_logic; --156.250 reference clock input
		gt_ref_clk_n : in std_logic
	);
end entity;


architecture impl of cge_test is
	signal refclk: std_logic;
	signal rst: std_logic := '1';
begin

		cge0: entity work.cge
		 generic map (
			IMPLEMENT_PACKET_GENERATOR => TRUE
		 	)
		port map (
			tx_p => tx_p,
			tx_n => tx_n,
			refclk_p => gt_ref_clk_p,
			refclk_n => gt_ref_clk_n,

			refclk_out => refclk,
			rst => rst,
			ctrl_clk => refclk, -- used as init_clk
			ctrl_rst => rst
		 );

		rst_proc: process(refclk)
		begin
			if rising_edge(refclk) then
				rst <= '0';
			end if;
		end process;


end architecture impl;



