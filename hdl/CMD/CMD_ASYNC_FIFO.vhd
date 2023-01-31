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
		CMD_A_DAT: in AXIS8_DAT_STRUCT;
		CMD_A_RDY: out AXIS8_RDY_STRUCT;
		RPLY_A_DAT: out AXIS8_DAT_STRUCT;
		RPLY_A_RDY: in AXIS8_RDY_STRUCT;
		A_CLK: in STD_LOGIC;

		CMD_B_DAT: out AXIS8_DAT_STRUCT;
		CMD_B_RDY: in AXIS8_RDY_STRUCT;
		RPLY_B_DAT: in AXIS8_DAT_STRUCT;
		RPLY_B_RDY: out AXIS8_RDY_STRUCT;
		B_CLK: in STD_LOGIC;

		-- System interface
		RST : in  STD_LOGIC
		);
end CMD_ASYNC_FIFO;


architecture Behavioral of CMD_ASYNC_FIFO is

signal RST_N: std_logic;

begin

RST_N <= not RST;

CMD_FIFO0: entity work.CMD_FIFO
  PORT MAP (
	 s_axis_tvalid => CMD_A_DAT.TVALID,
	 s_axis_tready => CMD_A_RDY.TREADY,
	 s_axis_tdata => CMD_A_DAT.TDATA,
	 s_axis_tlast => CMD_A_DAT.TLAST,
	 s_aclk => A_CLK,

	 s_aresetn => RST_N,

	 m_axis_tvalid => CMD_B_DAT.TVALID,
	 m_axis_tready => CMD_B_RDY.TREADY,
	 m_axis_tdata => CMD_B_DAT.TDATA,
	 m_axis_tlast => CMD_B_DAT.TLAST,
	 m_aclk => B_CLK
  );

RPLY_FIFO0 : entity work.CMD_FIFO
  PORT MAP (
	 s_axis_tvalid => RPLY_B_DAT.TVALID,
	 s_axis_tready => RPLY_B_RDY.TREADY,
	 s_axis_tdata => RPLY_B_DAT.TDATA,
	 s_axis_tlast => RPLY_B_DAT.TLAST,
	 s_aclk => B_CLK,

	 s_aresetn => RST_N,

	 m_axis_tvalid => RPLY_A_DAT.TVALID,
	 m_axis_tready => RPLY_A_RDY.TREADY,
	 m_axis_tdata => RPLY_A_DAT.TDATA,
	 m_axis_tlast => RPLY_A_DAT.TLAST,
	 m_aclk => A_CLK
  );

end Behavioral;

