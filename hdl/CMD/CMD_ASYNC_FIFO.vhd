----------------------------------------------------------------------------------
--! @file
-- Company: McGill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    2012-10-17
-- Design Name:
-- Module Name:    CMD_ASYNC_FIFO - Behavioral
-- Project Name: CHIME PoC
-- Target Devices: Virtex 6 or 7 series
-- Tool versions: ISE 14.2
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 	2012-10-17 JFC: Created

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

library work;
use work.chFPGA_Package.all; -- Get all component definitions



--! Implements a bidirectional asynchronous FIFO for the Byte-Serial command bus from A to B
entity CMD_ASYNC_FIFO is
	GENERIC (
		SIM: boolean :=FALSE
		);
     PORT (
		-- Command streams from single slave input to multiple master outputs
		cmd_a_dat: in AXIS8_DAT_STRUCT;
		cmd_a_rdy: out AXIS8_RDY_STRUCT;
		rply_a_dat: out AXIS8_DAT_STRUCT;
		rply_a_rdy: in AXIS8_RDY_STRUCT;
		a_clk: in STD_LOGIC;

		cmd_b_dat: out AXIS8_DAT_STRUCT;
		cmd_b_rdy: in AXIS8_RDY_STRUCT;
		rply_b_dat: in AXIS8_DAT_STRUCT;
		rply_b_rdy: out AXIS8_RDY_STRUCT;
		b_clk: in std_logic;

		-- System interface
		rst: in std_logic;
		a_rst_out: out std_logic; -- extended reset pulse synchronous to a_clk
		b_rst_out: out std_logic -- extended reset pulse synchronous to b_clk
		);

end CMD_ASYNC_FIFO;


architecture Behavioral of CMD_ASYNC_FIFO is

signal rst_n: std_logic;
signal a_rst, b_rst: std_logic;
signal a_rst_ctr, b_rst_ctr: unsigned(2 downto 0); -- reset will be at least 8 clk long

begin

-- CMD_FIFO generated with the FIFO generator
-- Type AXI Stream, Independent clock, 1 TDATA BYTE, no other flags except TLAST, Distributed RAM, Depth=16 (minimum)
-- Latency is 4WR + 1 RD clk. 
CMD_FIFO0: entity work.CMD_FIFO
  PORT MAP (
	 s_axis_tvalid => cmd_a_dat.TVALID,
	 s_axis_tready => cmd_a_rdy.TREADY,
	 s_axis_tdata => cmd_a_dat.TDATA,
	 s_axis_tlast => cmd_a_dat.TLAST,
	 s_aclk => a_clk,

	 s_aresetn => rst_n,

	 m_axis_tvalid => cmd_b_dat.TVALID,
	 m_axis_tready => cmd_b_rdy.TREADY,
	 m_axis_tdata => cmd_b_dat.TDATA,
	 m_axis_tlast => cmd_b_dat.TLAST,
	 m_aclk => B_CLK
  );

RPLY_FIFO0 : entity work.CMD_FIFO
  PORT MAP (
	 s_axis_tvalid => rply_b_dat.TVALID,
	 s_axis_tready => rply_b_rdy.TREADY,
	 s_axis_tdata => rply_b_dat.TDATA,
	 s_axis_tlast => rply_b_dat.TLAST,
	 s_aclk => B_CLK,

	 s_aresetn => rst_n,

	 m_axis_tvalid => rply_a_dat.TVALID,
	 m_axis_tready => rply_a_rdy.TREADY,
	 m_axis_tdata => rply_a_dat.TDATA,
	 m_axis_tlast => rply_a_dat.TLAST,
	 m_aclk => a_clk
  );

-- we have to make sure that the RST signal stays active until there has been a few clocks on both a_clk and B_CLK to make sure the FIFO is reset properly. 
arst_proc: process(a_clk, rst)
begin
	if RST = '1' then 
		a_rst_ctr <= (others => '0');
		a_rst <= '1';
	elsif rising_edge(a_clk) then
		if signed(a_rst_ctr) = -1 then
			a_rst <= '0';
		else
			a_rst_ctr <= a_rst_ctr + 1;
		end if;
	end if;
end process;

brst_proc: process(b_clk, rst)
begin
	if rst = '1' then 
		b_rst_ctr <= (others => '0');
		b_rst <= '1';
	elsif rising_edge(b_clk) then
		if signed(b_rst_ctr) = -1 then
			b_rst <= '0';
		else
			b_rst_ctr <= b_rst_ctr + 1;
		end if;
	end if;
end process;

a_rst_out <= a_rst;
b_rst_out <= b_rst;
rst_n <= not (a_rst or b_rst); -- rst_n is asynchronous, we don't have to worry about resyncing


end Behavioral;

