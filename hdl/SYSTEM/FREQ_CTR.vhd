----------------------------------------------------------------------------------
--! @file
-- Company:
-- Engineer:
--
-- Create Date:    10:43:45 06/01/2011
-- Design Name:
-- Module Name:    FREQ_CTR - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description: Multiport frequency counter. Measures the frequency of one of 'NUMBER_OF_PORTS' clock signal in addition to that of the CLK200 and CTRL_CLK clocks.
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
--  110601 JFC: Created
--  110922 JFC: Eliminated internal generation of CLK200_DIV2 and CTRL_CLK_DIV2 signals. Those are now provided externally.
--  120406 JFC: Cleanup. Changed for new AXI4S control interface.
--  121105 JFC: Switch to synchronous reset. Removed RST since START_FREQ_CR is pulsed anyway for each read. Added intermediary GATE_TIME registers and end-of-count signals to facilitate timing.
--  121119 JFC: Put the source clock counter process back to async reset to better handle when the source clock is absent
--  130209 JFC: Added an explicit BUFR on SRC_SEL
-- Additional Comments:
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;
use work.chFPGA_Package.all; -- Get all component definitions

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

--! @brief Implements a frequency counter
--! This module measures the frequency of a signal relative to the ob-board 200 MHz clock.
--! The signal to be measured is a logic line (not a clock line) toggling at half the clock frequency. This signal can be generated easily with a flip-flop and does not require any clocking routing ressources.
--! The gate time is specified by the user to control the resolution of the counter.
--! The accuracy is determined by the accuracy of the reference clock.
entity FREQ_CTR is
	generic (
		FPGA_SERIES: integer;
		NUMBER_OF_CLK_IN_PORTS: INTEGER:=8
			);
    port (
		-- Control interface
		CTRL_CMD_IN_DAT: in AXIS8_DAT_STRUCT; -- Command stream input, signals from master (Data, Valid, Last)
		CTRL_CMD_IN_RDY: out AXIS8_RDY_STRUCT; -- Command stream input, signals to master (Ready)
		CTRL_RPLY_OUT_DAT: out AXIS8_DAT_STRUCT; -- Reply stream output, signals to slave (Data, Valid, Last)
		CTRL_RPLY_OUT_RDY: in AXIS8_RDY_STRUCT; -- Reply stream output,  signals from slave (Ready)
		CTRL_CLK: in  STD_LOGIC;
		CTRL_RST: in std_logic;

		CLK200: in STD_LOGIC; -- Reference clock
		CLK_IN_DIV2: in STD_LOGIC_VECTOR(0 to NUMBER_OF_CLK_IN_PORTS-1);

		-- System-level signals
		RST: in STD_LOGIC -- synchronous to CLK200
	);
end FREQ_CTR;

architecture Behavioral of FREQ_CTR is

--- Define Control word and its signals
signal CONTROL_BYTES: slv8_array(0 to 4); -- default value set in the CMD_SLAVE
signal STATUS_BYTES: slv8_array(0 to 4); -- default value set in the CMD_SLAVE



signal GATE_CTR: UNSIGNED(31 downto 0):=(others=>'0');
signal FREQ_CTR: UNSIGNED(31 downto 0):=(others=>'0');
signal FREQ_CTR_RDY: STD_LOGIC;
signal FREQ_CTR_START: STD_LOGIC:='0';
signal GATE_EN: STD_LOGIC:='0';
signal FREQ_CTR_SRC_SEL: UNSIGNED(6 downto 0):=(others=>'0');
signal SRC_CLK: STD_LOGIC;
signal SRC_CLK_FABRIC: STD_LOGIC;

signal GATE_PERIOD: unsigned(31 downto 0); -- GATE_PERIOD=40E6 Corresponds to a GATE_PERIOD/CLK200_FREQ= 0.2s second gate time. Since inputs are divided by 2, real frequency is 100*count.
signal GATE_PERIOD_MINUS_2: unsigned(31 downto 0);
signal IS_LAST_GATE_VALUE: STD_LOGIC;

begin

-- CONTROL Byte 0-3
GATE_PERIOD(31 downto 0)    <= to_unsigned(CONTROL_BYTES(0 to 3)); -- to_unsigned() accepting Byte Arrays is defined in the project package

-- CONTROL Byte 4

FREQ_CTR_START              <= CONTROL_BYTES(4)(7);
FREQ_CTR_SRC_SEL            <= unsigned(CONTROL_BYTES(4)(6 downto 0));

-- STATUS bytes 0-3
STATUS_BYTES(0 to 3)        <= to_slv8_array(FREQ_CTR);
-- STATUS_BYTES(1)             <= std_logic_vector(FREQ_CTR(23 downto 16));
-- STATUS_BYTES(2)             <= std_logic_vector(FREQ_CTR(15 downto 8));
-- STATUS_BYTES(3)             <= std_logic_vector(FREQ_CTR(7 downto 0));

-- STATUS bytes 4

STATUS_BYTES(4)(7 downto 1) <= (others=>'0');
STATUS_BYTES(4)(0)          <= FREQ_CTR_RDY;

-- Convert clock inputs into a divided by two logic signal


CTRL_SLAVE0: entity work.CTRL_SLAVE
	GENERIC MAP (
		NUMBER_OF_CONTROL_BYTES=>CONTROL_BYTES'Length(1), -- Length of array in the first dimension: number of bytes
		NUMBER_OF_STATUS_BYTES=>STATUS_BYTES'Length(1),
		DEFAULT_CONTROL_BYTES=> X"02625A00_00"
 	)

	PORT MAP(
		-- Control interface (command and reply stream buses)
		CTRL_CMD_IN_DAT => CTRL_CMD_IN_DAT,
		CTRL_CMD_IN_RDY => CTRL_CMD_IN_RDY,
		CTRL_RPLY_OUT_DAT => CTRL_RPLY_OUT_DAT,
		CTRL_RPLY_OUT_RDY => CTRL_RPLY_OUT_RDY,
		CTRL_CLK => CTRL_CLK,
		CTRL_RST => CTRL_RST,

		CONTROL_BYTES => CONTROL_BYTES,
		STATUS_BYTES => STATUS_BYTES,
		CLK => CLK200,
		RST => RST
	);

-- Select clock to measure
SRC_CLK_FABRIC<= CLK_IN_DIV2(to_integer(FREQ_CTR_SRC_SEL));

--! Pass the selected signal through a clock buffer to facilitate timing and remove tool complaints
--! A regional clock BUFR will suffice as the frequency counter is very localized
K7: if FPGA_SERIES=7 generate
	-- SRCCLK0 : BUFR
	-- 		generic map (
	-- 			BUFR_DIVIDE => "BYPASS", --  ("BYPASS", "1", "2", "3", "4", "5", "6", "7", "8")
	-- 			SIM_DEVICE => "7SERIES" -- Specify target device, "VIRTEX4", "VIRTEX5", "VIRTEX6"
	-- 		)
	-- 		port map (
	-- 			I => SRC_CLK_FABRIC, -- Clock buffer input
	-- 			O => SRC_CLK, -- Clock buffer output
	-- 			CE => '1', -- Clock enable input
	-- 			CLR => '0'-- Clock buffer reset input
	-- 		);
	SRCCLK0 : BUFH
		port map (
			I => SRC_CLK_FABRIC,
			O => SRC_CLK
		);

end generate;

V6: if FPGA_SERIES=FPGA_VIRTEX6 or FPGA_SERIES=FPGA_ULTRASCALEPLUS generate
	SRCCLK0 : BUFG
		port map (
			O => SRC_CLK, -- 1-bit output: Clock buffer output
			I => SRC_CLK_FABRIC -- 1-bit input: Clock buffer input
		);
end generate;

-- Source clock counter process
src_ctr_proc: process(SRC_CLK, FREQ_CTR_START)
	begin
		if FREQ_CTR_START='0' then -- We need an asynchronous reset to clear the counter even in the absence of the source clock
				FREQ_CTR<=(others=>'0');
		elsif rising_edge(SRC_CLK) then
			if GATE_EN='1' then
					FREQ_CTR<=FREQ_CTR+1;
			end if;
		end if; -- CLK
	end process;

-- Reference clock counter
ref_ctr_proc: process(CLK200)
	begin
		if rising_edge(CLK200) then
			GATE_PERIOD_MINUS_2<=GATE_PERIOD-2; -- register the gate period to isolate the timing from the SLAVE. We substract 2 to have an accurate count given the pipelinning delays.

			-- Create a signal that indicates if we reached the total gate time. This is to simplify the logic and facilitate timing closure.

			if FREQ_CTR_START='0' then
					GATE_CTR<=(others=>'0');
					GATE_EN<='1';
					FREQ_CTR_RDY<='0';
					IS_LAST_GATE_VALUE<='0';
			else
				if GATE_CTR=GATE_PERIOD_MINUS_2 then
					IS_LAST_GATE_VALUE<='1';
				else
					IS_LAST_GATE_VALUE<='0';
				end if;

				if GATE_EN='1' then
					if IS_LAST_GATE_VALUE='1' then
						GATE_EN<='0';
						FREQ_CTR_RDY<='1';
					else
						GATE_CTR<=GATE_CTR+1;
					end if;
				end if;
			end if; -- FREQ_CTR_START
		end if; -- CLK
	end process;


end Behavioral;

