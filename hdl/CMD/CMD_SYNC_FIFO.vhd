----------------------------------------------------------------------------------
--! @file
-- Company: McGill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    2012-10-17
-- Design Name:
-- Module Name:    CMD_SYNC_FIFO - Behavioral
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


-- Implements a shallow bidirectional FIFO for the byte-serial control bus from A to B
--
-- This FIFO is use to add a pipeline level to the command and reply channels
-- of the bus. It is used to break TREADY combinatorial paths and make timing
-- easier to be met.
entity CMD_SYNC_FIFO is
	GENERIC (
		SIM: boolean :=FALSE
		);
     PORT (
		-- Command streams from single slave input to multiple master outputs
		CMD_A_DAT: in AXIS8_DAT_STRUCT;
		CMD_A_RDY: out AXIS8_RDY_STRUCT;
		RPLY_A_DAT: out AXIS8_DAT_STRUCT;
		RPLY_A_RDY: in AXIS8_RDY_STRUCT;

		CMD_B_DAT: out AXIS8_DAT_STRUCT;
		CMD_B_RDY: in AXIS8_RDY_STRUCT;
		RPLY_B_DAT: in AXIS8_DAT_STRUCT;
		RPLY_B_RDY: out AXIS8_RDY_STRUCT;

		-- System interface
		CLK: in STD_LOGIC;
		RST : in  STD_LOGIC
		);
end CMD_SYNC_FIFO;


architecture Behavioral of CMD_SYNC_FIFO is

signal RST_N: std_logic;

begin

RST_N <= not RST;

-- Implement a register slice for both the command and reply channels.
--
-- We use a AXI4S register slice, which is very compact (uses about 25 registers / 4 SLICEs, which is close to optimal)
--
-- This implements a 1-byte-deep FIFO andn a 1-byte output register (plus TUSER bits), which is necessary because popelining
-- the TREADY signal implies that the source will be notified one clock later
-- that the destination is not ready. It the source was sending a byte while TREADY was propagating,  the incoming byte needs to be stored
-- until the destination is ready to receive it.
FIFOGEN_SYNC: if SIM=FALSE generate
	CMD_FIFO0 : entity work.AXI4S_REG_SLICE
	  PORT MAP (
		 ACLK => CLK,
		 ARESETN => RST_N,
		 S00_AXIS_ACLK => CLK,
		 S00_AXIS_ARESETN => RST_N,
		 S00_AXIS_TVALID => CMD_A_DAT.TVALID,
		 S00_AXIS_TREADY => CMD_A_RDY.TREADY,
		 S00_AXIS_TDATA => CMD_A_DAT.TDATA,
		 S00_AXIS_TLAST => CMD_A_DAT.TLAST,
		 M00_AXIS_ACLK => CLK,
		 M00_AXIS_ARESETN => RST_N,
		 M00_AXIS_TVALID => CMD_B_DAT.TVALID,
		 M00_AXIS_TREADY => CMD_B_RDY.TREADY,
		 M00_AXIS_TDATA => CMD_B_DAT.TDATA,
		 M00_AXIS_TLAST => CMD_B_DAT.TLAST
	  );

	RPLY_FIFO0 : entity work.AXI4S_REG_SLICE
	  PORT MAP (
		 ACLK => CLK,
		 ARESETN => RST_N,
		 S00_AXIS_ACLK => CLK,
		 S00_AXIS_ARESETN => RST_N,
		 S00_AXIS_TVALID => RPLY_B_DAT.TVALID,
		 S00_AXIS_TREADY => RPLY_B_RDY.TREADY,
		 S00_AXIS_TDATA => RPLY_B_DAT.TDATA,
		 S00_AXIS_TLAST => RPLY_B_DAT.TLAST,
		 M00_AXIS_ACLK => CLK,
		 M00_AXIS_ARESETN => RST_N,
		 M00_AXIS_TVALID => RPLY_A_DAT.TVALID,
		 M00_AXIS_TREADY => RPLY_A_RDY.TREADY,
		 M00_AXIS_TDATA => RPLY_A_DAT.TDATA,
		 M00_AXIS_TLAST => RPLY_A_DAT.TLAST
	  );
end generate;

FIFOGEN0_SIM: if SIM=TRUE generate
	CMD_B_DAT<=CMD_A_DAT;
	CMD_A_RDY<=CMD_B_RDY;
	RPLY_A_DAT<=RPLY_B_DAT;
	RPLY_B_RDY<=RPLY_A_RDY;
end generate;


end Behavioral;

