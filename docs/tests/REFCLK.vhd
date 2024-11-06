----------------------------------------------------------------------------------
--! @file
-- Company: Mc Gill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    2011-08-24

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chFPGA_Package.all; -- Get all component definitions

library UNISIM;
use UNISIM.VComponents.all;

--- ENTITY DECLARATIONS -------------------------------------------------------------------------------
--! \brief
--! Handles the FMC Reference Clock generation, SYNC event detection and generation, and ADC SYNC signal generation
entity REFCLK is
	 GENERIC (
	 	PLATFORM_ID: integer;
	 	NUMBER_OF_MEZZANINES: integer;
	 	IMPLEMENT_CLOCK_ENCODED_SYNC: boolean := FALSE;
		SIM: BOOLEAN := FALSE
		);

	port (
		-- Control interface
		CTRL_CMD_IN_DAT: in AXIS8_DAT_STRUCT; --! Command stream input, signals from master (Data, Valid, Last)
		CTRL_CMD_IN_RDY: out AXIS8_RDY_STRUCT; --! Command stream input, signals to master (Ready)
		CTRL_RPLY_OUT_DAT: out AXIS8_DAT_STRUCT; --! Reply stream output, signals to slave (Data, Valid, Last)
		CTRL_RPLY_OUT_RDY: in AXIS8_RDY_STRUCT; --! Reply stream output,  signals from slave (Ready)
		CTRL_CLK: in  std_logic;
		CTRL_RST: in std_logic;

		------------------------------------------------------------------------
		-- SYNC sequencing signals
		------------------------------------------------------------------------

		clk10: in std_logic; -- Buffered 10 MHz reference clock (with well defined phase relationship with all other boards in the system)

		sync_in: in std_logic_vector(0 to 5); -- External sync request signals (from backplane or IRIG-B comparator)

		adcdaq_reset: out std_logic; --! When a SYNC event is detected, is activated to initiate reset of the ADC data acquisition and processing pipeline

		------------------------------------------------------------------------
		-- Mezzanine signals
		--------------------------------------------------------------------------

		-- Reference clocks from mezzanines (LVDS)
		fmc_refclk_p: in std_logic_vector(0 to NUMBER_OF_MEZZANINES-1); --! Reference Clock LVDS input from the FMC. The Input pad is instantiated in this module.
		fmc_refclk_n: in std_logic_vector(0 to NUMBER_OF_MEZZANINES-1);


		-- System-level signals
		rst: in std_logic -- synchronous to clk200
	);

end REFCLK;

