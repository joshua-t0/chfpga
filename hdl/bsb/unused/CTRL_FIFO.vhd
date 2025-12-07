----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    2012-10-17
-- Design Name:
-- Module Name:    CTRL_FIFO - Behavioral
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



-- Implements a shallow FIFO for the command system from A to B
entity CTRL_FIFO is
	GENERIC (
		USE_ASYNC_FIFO: boolean;
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
end CTRL_FIFO;


architecture Behavioral of CTRL_FIFO is

signal RST_N: std_logic;
signal CMD_A_RDY_TREADY: std_logic;
signal CMD_B_RDY_TREADY: std_logic;
signal RPLY_A_RDY_TREADY: std_logic;
signal RPLY_B_RDY_TREADY: std_logic;

begin

RST_N <= not RST;

CMD_A_RDY.TREADY<=CMD_A_RDY_TREADY; -- debug sim
CMD_B_RDY_TREADY<= CMD_B_RDY.TREADY; -- debug sim

RPLY_B_RDY.TREADY<=RPLY_B_RDY_TREADY; -- debug sim
RPLY_A_RDY_TREADY<= RPLY_A_RDY.TREADY; -- debug sim

FIFOGEN_SYNC: if USE_ASYNC_FIFO=FALSE and SIM=FALSE generate
	CMD_FIFO0 : entity work.AXI4S_REG_SLICE
	  PORT MAP (
		 ACLK => A_CLK,
		 ARESETN => RST_N,
		 S00_AXIS_ACLK => A_CLK,
		 S00_AXIS_ARESETN => RST_N,
		 S00_AXIS_TVALID => CMD_A_DAT.TVALID,
		 S00_AXIS_TREADY => CMD_A_RDY_TREADY,
--		 S00_AXIS_TREADY => CMD_A_RDY.TREADY,
		 S00_AXIS_TDATA => CMD_A_DAT.TDATA,
		 S00_AXIS_TLAST => CMD_A_DAT.TLAST,
		 M00_AXIS_ACLK => B_CLK,
		 M00_AXIS_ARESETN => RST_N,
		 M00_AXIS_TVALID => CMD_B_DAT.TVALID,
		 M00_AXIS_TREADY => CMD_B_RDY_TREADY,
--		 M00_AXIS_TREADY => CMD_B_RDY.TREADY,
		 M00_AXIS_TDATA => CMD_B_DAT.TDATA,
		 M00_AXIS_TLAST => CMD_B_DAT.TLAST
	  );

	RPLY_FIFO0 : entity work.AXI4S_REG_SLICE
	  PORT MAP (
		 ACLK => A_CLK,
		 ARESETN => RST_N,
		 S00_AXIS_ACLK => B_CLK,
		 S00_AXIS_ARESETN => RST_N,
		 S00_AXIS_TVALID => RPLY_B_DAT.TVALID,
--		 S00_AXIS_TREADY => RPLY_B_RDY.TREADY,
		 S00_AXIS_TREADY => RPLY_B_RDY_TREADY,
		 S00_AXIS_TDATA => RPLY_B_DAT.TDATA,
		 S00_AXIS_TLAST => RPLY_B_DAT.TLAST,
		 M00_AXIS_ACLK => A_CLK,
		 M00_AXIS_ARESETN => RST_N,
		 M00_AXIS_TVALID => RPLY_A_DAT.TVALID,
--		 M00_AXIS_TREADY => RPLY_A_RDY.TREADY,
		 M00_AXIS_TREADY => RPLY_A_RDY_TREADY,
		 M00_AXIS_TDATA => RPLY_A_DAT.TDATA,
		 M00_AXIS_TLAST => RPLY_A_DAT.TLAST
	  );
end generate;
FIFOGEN0_SIM: if USE_ASYNC_FIFO=FALSE and SIM=TRUE generate
	CMD_B_DAT<=CMD_A_DAT;
	CMD_A_RDY<=CMD_B_RDY;
	RPLY_A_DAT<=RPLY_B_DAT;
	RPLY_B_RDY<=RPLY_A_RDY;
end generate;

FIFOGEN_ASYNC: if USE_ASYNC_FIFO=TRUE generate
--	CMD_FIFO : AXI4S_ASYNC_FIFO
--	  PORT MAP (
--		 ACLK => A_CLK,
--		 ARESETN => RST_N,
--		 S00_AXIS_ACLK => A_CLK,
--		 S00_AXIS_ARESETN => RST_N,
--		 S00_AXIS_TVALID => CMD_A_DAT.TVALID,
--		 S00_AXIS_TREADY => CMD_A_RDY.TREADY,
--		 S00_AXIS_TDATA => CMD_A_DAT.TDATA,
--		 S00_AXIS_TLAST => CMD_A_DAT.TLAST,
--		 M00_AXIS_ACLK => B_CLK,
--		 M00_AXIS_ARESETN => RST_N,
--		 M00_AXIS_TVALID => CMD_B_DAT.TVALID,
--		 M00_AXIS_TREADY => CMD_B_RDY.TREADY,
--		 M00_AXIS_TDATA => CMD_B_DAT.TDATA,
--		 M00_AXIS_TLAST => CMD_B_DAT.TLAST
--	  );
--
--	RPLY_FIFO : AXI4S_ASYNC_FIFO -- We use a second one because XST has a bug and can't handle the TIGs inserted by the core with the same name in both instances
--	  PORT MAP (
--		 ACLK => A_CLK,
--		 ARESETN =>RST_N,
--		 S00_AXIS_ACLK => B_CLK,
--		 S00_AXIS_ARESETN => RST_N,
--		 S00_AXIS_TVALID => RPLY_B_DAT.TVALID,
--		 S00_AXIS_TREADY => RPLY_B_RDY.TREADY,
--		 S00_AXIS_TDATA => RPLY_B_DAT.TDATA,
--		 S00_AXIS_TLAST => RPLY_B_DAT.TLAST,
--		 M00_AXIS_ACLK => A_CLK,
--		 M00_AXIS_ARESETN => RST_N,
--		 M00_AXIS_TVALID => RPLY_A_DAT.TVALID,
--		 M00_AXIS_TREADY => RPLY_A_RDY.TREADY,
--		 M00_AXIS_TDATA => RPLY_A_DAT.TDATA,
--		 M00_AXIS_TLAST => RPLY_A_DAT.TLAST
--	  );

	CMD_FIFO0: entity work.CMD_FIFO
	  PORT MAP (
		 m_aclk => B_CLK,
		 s_aclk => A_CLK,
		 s_aresetn => RST_N,
		 s_axis_tvalid => CMD_A_DAT.TVALID,
--		 s_axis_tready => CMD_A_RDY.TREADY,
		 s_axis_tready => CMD_A_RDY_TREADY,
		 s_axis_tdata => CMD_A_DAT.TDATA,
		 s_axis_tlast => CMD_A_DAT.TLAST,
		 m_axis_tvalid => CMD_B_DAT.TVALID,
--		 m_axis_tready => CMD_B_RDY.TREADY,
		 m_axis_tready => CMD_B_RDY_TREADY,
		 m_axis_tdata => CMD_B_DAT.TDATA,
		 m_axis_tlast => CMD_B_DAT.TLAST
	  );

	RPLY_FIFO0 : entity work.CMD_FIFO
	  PORT MAP (
		 m_aclk => A_CLK,
		 s_aclk => B_CLK,
		 s_aresetn => RST_N,
		 s_axis_tvalid => RPLY_B_DAT.TVALID,
		 s_axis_tready => RPLY_B_RDY_TREADY,
--		 s_axis_tready => RPLY_B_RDY.TREADY,
		 s_axis_tdata => RPLY_B_DAT.TDATA,
		 s_axis_tlast => RPLY_B_DAT.TLAST,
		 m_axis_tvalid => RPLY_A_DAT.TVALID,
		 m_axis_tready => RPLY_A_RDY_TREADY,
--		 m_axis_tready => RPLY_A_RDY.TREADY,
		 m_axis_tdata => RPLY_A_DAT.TDATA,
		 m_axis_tlast => RPLY_A_DAT.TLAST
	  );

end generate;

end Behavioral;

