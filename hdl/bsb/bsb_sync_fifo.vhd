----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    2012-10-17
-- Design Name:
-- Module Name:    cmd_sync_fifo - impl
-- Project Name: chFPGA
-- Target Devices: Virtex 6, Kintex 7, Ultrascale+
-- Tool versions: Vivado 2022.2
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
entity bsb_sync_fifo is
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
end bsb_sync_fifo;


-- Implementation:
--
-- Implement a register slice for both the command and reply channels.
--
-- We use a AXI4S register slice, which is very compact (uses about 25 registers / 4 SLICEs, which is close to optimal)
--
-- This implements a 1-byte-deep FIFO andn a 1-byte output register (plus TUSER bits), which is necessary because pipelining
-- the TREADY signal implies that the source will be notified one clock later
-- that the destination is not ready. It the source was sending a byte while TREADY was propagating,  the incoming byte needs to be stored
-- until the destination is ready to receive it.
architecture impl of bsb_sync_fifo is

begin

	cmd_fifo0 : entity work.axis_sync_fifo
	  port map (
		 clk => clk,
		 rst => rst,

		 s_axis_tvalid => cmd_a_dat.tvalid,
		 s_axis_tready => cmd_a_rdy.tready,
		 s_axis_tdata => cmd_a_dat.tdata,
		 s_axis_tlast => cmd_a_dat.tlast,

		 m_axis_tvalid => cmd_b_dat.tvalid,
		 m_axis_tready => cmd_b_rdy.tready,
		 m_axis_tdata => cmd_b_dat.tdata,
		 m_axis_tlast => cmd_b_dat.tlast
	  );

	rply_fifo0 : entity work.axis_sync_fifo
	  port map (
		 clk => clk,
		 rst => rst,

		 s_axis_tvalid => rply_b_dat.tvalid,
		 s_axis_tready => rply_b_rdy.tready,
		 s_axis_tdata => rply_b_dat.tdata,
		 s_axis_tlast => rply_b_dat.tlast,

		 m_axis_tvalid => rply_a_dat.tvalid,
		 m_axis_tready => rply_a_rdy.tready,
		 m_axis_tdata => rply_a_dat.tdata,
		 m_axis_tlast => rply_a_dat.tlast
	  );

end impl;

