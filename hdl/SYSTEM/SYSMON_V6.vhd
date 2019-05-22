----------------------------------------------------------------------------------
-- @file
-- Company:
-- Engineer:
--
-- Create Date:    20:14:22 05/20/2011
-- Design Name:  chFPGA PoC
-- Module Name:    SYSMON_V6 - Behavioral
-- Project Name: CHIME
-- Target Devices: Virtex 6
-- Tool versions: ISE 14.2
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
--  110708 JFC: Added monitoring of SYSMON's CHANNEL, EOC, EOS. Connected VP/VN and a couple of VAUX
--  110725 JFC: Modified to use the new 16-bit mode of the CMD_SLAVE
-- 2012-10-18 JFC: Added FIFO on control bus to operate SYSMON at SYSMON_CLK
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
--! @brief Implements the FPGA's internal SYSTEM MONITOR (Virtex 6) or XADC (7 series) block to monitor internal and external voltages and temperatures
entity SYSMON_XADC is
	generic (
		PLATFORM_ID: INTEGER
			);
    port (
		-- Control interface
		CTRL_CMD_IN_DAT: in AXIS8_DAT_STRUCT; --! Command stream input, signals from master (Data, Valid, Last)
		CTRL_CMD_IN_RDY: out AXIS8_RDY_STRUCT; --! Command stream input, signals to master (Ready)
		CTRL_RPLY_OUT_DAT: out AXIS8_DAT_STRUCT; --! Reply stream output, signals to slave (Data, Valid, Last)
		CTRL_RPLY_OUT_RDY: in AXIS8_RDY_STRUCT; --! Reply stream output,  signals from slave (Ready)
		CTRL_CLK: in  STD_LOGIC;
		CTRL_RST: in std_logic;

		--  Current and voltage monitors
		VAUX_CURR_N : in  STD_LOGIC;
		VAUX_CURR_P : in  STD_LOGIC; --! External current monitor on the 12V supply line
		VAUX_VOLT_N : in  STD_LOGIC;
		VAUX_VOLT_P : in  STD_LOGIC;--! External voltage monitor on the 12V supply line
		VP : in  STD_LOGIC;
		VN : in  STD_LOGIC;


		-- FPGA FAN signals
		FAN_PWM: out STD_LOGIC; --! Fan control pin. Can be pulse modulated to produce variable speed (not implemented)
		FAN_TACH: in STD_LOGIC; --! Fan speed monitor pin. Pulses twice per rotation. Is very glitchy and needs serious debouncing.

		-- System-level signals
		SYSMON_CLK: in  STD_LOGIC; --! System monitor clock. Clocks the SYSMON hardware block.
		SYSMON_RST: in STD_LOGIC -- synchronous to SYSMON_CLK
	);

end SYSMON_XADC;

architecture Behavioral of SYSMON_XADC is

--- Define Control word and its signals
signal CONTROL_BYTES: slv8_array(0 to 0); --
signal STATUS_BYTES: slv8_array(0 to 1);

signal CONTROL_BYTES_BANK_SEL: STD_LOGIC_VECTOR(0 downto 0);
signal CONTROL_BYTES_FAN_EN: STD_LOGIC;





-- SYSMON signals
signal SYSMON_DOUT: STD_LOGIC_VECTOR(15 downto 0);
signal SYSMON_DIN: STD_LOGIC_VECTOR(15 downto 0);
--signal SYSMON_DADDR: STD_LOGIC_VECTOR(6 downto 0);
signal SYSMON_DRDY: STD_LOGIC;
signal SYSMON_DEN: STD_LOGIC;
signal SYSMON_WR_EN: STD_LOGIC;
signal SYSMON_ALM: STD_LOGIC_VECTOR(7 downto 0);
signal SYSMON_BUSY: STD_LOGIC;
signal SYSMON_OVERTEMP: STD_LOGIC;
signal SYSMON_CHANNEL: STD_LOGIC_VECTOR(4 downto 0);
signal SYSMON_EOC: STD_LOGIC;
signal SYSMON_EOS: STD_LOGIC;

signal VAUXN_VECT: STD_LOGIC_VECTOR(15 downto 0);
signal VAUXP_VECT: STD_LOGIC_VECTOR(15 downto 0);


-- CTRL_SLAVE memory mapped interface
signal SYSMON_ADDR: STD_LOGIC_VECTOR(6 downto 0);


signal CMD_IN_DAT_FIFO:  AXIS8_DAT_STRUCT;
signal CMD_IN_RDY_FIFO:  AXIS8_RDY_STRUCT;
signal RPLY_OUT_DAT_FIFO:  AXIS8_DAT_STRUCT;
signal RPLY_OUT_RDY_FIFO: AXIS8_RDY_STRUCT;

begin
-- Assign signals to CONTROL and STATUS WORDS
CONTROL_BYTES_BANK_SEL(0)<=		CONTROL_BYTES(0)(0);
CONTROL_BYTES_FAN_EN<=			CONTROL_BYTES(0)(1);

STATUS_BYTES(0)(7 downto 5)<=(others=>'0');
STATUS_BYTES(0)(4 downto 2)<=SYSMON_ALM(2 downto 0);
STATUS_BYTES(0)(1)<=SYSMON_OVERTEMP;
STATUS_BYTES(0)(0)<=SYSMON_BUSY;

STATUS_BYTES(1)(7)<=SYSMON_BUSY;
STATUS_BYTES(1)(6)<=SYSMON_EOS;
STATUS_BYTES(1)(5)<=SYSMON_EOC;
STATUS_BYTES(1)(4 downto 0)<=SYSMON_CHANNEL;


FAN_PWM<=CONTROL_BYTES_FAN_EN or SYSMON_OVERTEMP or '1';


CTRL_SLAVE0: entity work.CTRL_SLAVE
	GENERIC MAP (
		USE_RAM_DOUT_RDY=>TRUE, -- need to wait for the RDY signal on RAM read accesses
		RAM_DATA_WIDTH=>16,
		RAM_ADDR_WIDTH=>7, -- SYSMON DRP Address bus width is 7 bits
		NUMBER_OF_CONTROL_BYTES=>CONTROL_BYTES'Length(1), -- Number of bits in the control word
		NUMBER_OF_STATUS_BYTES=>STATUS_BYTES'Length(1), -- Number of bits in the status word.
		USE_FIFO => TRUE,
		USE_ASYNC_FIFO => TRUE -- Use a asynchonous FIFO to we can run the SYSCLK interface at a different clock speed
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

		RAM_DIN => SYSMON_DIN,
		RAM_DOUT => SYSMON_DOUT,
		RAM_DOUT_RDY => SYSMON_DRDY,
		RAM_WR_EN => SYSMON_WR_EN,
		RAM_EN => SYSMON_DEN,
		RAM_ADDR => SYSMON_ADDR,

		CLK => SYSMON_CLK,
		RST => SYSMON_RST
	);

VAUXN_VECT<=(13=>VAUX_CURR_N, 12=> VAUX_VOLT_N, others=>'0'); -- 16-bit input N-side auxiliary analog input
VAUXP_VECT<=(13=>VAUX_CURR_P, 12=> VAUX_VOLT_P, others=>'0'); -- 16-bit input P-side auxiliary analog input

SYSMON6_GEN: if FPGA_SERIES_LIST(PLATFORM_ID)=6 generate
SYSMON0 : SYSMON
	generic map (
		INIT_40 => X"0400", -- Configuration register 0
		INIT_41 => X"2000", -- Configuration register 1
		INIT_42 => X"0800", -- Configuration register 2
		INIT_43 => X"0000", -- Test register 0
		INIT_44 => X"0000", -- Test register 1
		INIT_45 => X"0000", -- Test register 2
		INIT_46 => X"0000", -- Test register 3
		INIT_47 => X"0000", -- Test register 4
		INIT_48 => X"0000", -- Sequence register 0
		INIT_49 => X"0000", -- Sequence register 1
		INIT_4A => X"0000", -- Sequence register 2
		INIT_4B => X"0000", -- Sequence register 3
		INIT_4C => X"0000", -- Sequence register 4
		INIT_4D => X"0000", -- Sequence register 5
		INIT_4E => X"0000", -- Sequence register 6
		INIT_4F => X"0000", -- Sequence register 7
		INIT_50 => X"0000", -- Alarm limit register 0
		INIT_51 => X"0000", -- Alarm limit register 1
		INIT_52 => X"0000", -- Alarm limit register 2
		INIT_53 => X"0000", -- Alarm limit register 3
		INIT_54 => X"0000", -- Alarm limit register 4
		INIT_55 => X"0000", -- Alarm limit register 5
		INIT_56 => X"0000", -- Alarm limit register 6
		INIT_57 => X"0000", -- Alarm limit register 7
		SIM_DEVICE => "VIRTEX6" -- Device family selection
--		SIM_MONITOR_FILE => "design.txt" -- Simulation analog entry file
	)
	port map (

		-- Control Interface
		DO => SYSMON_DOUT, -- 16-bit output data bus for dynamic reconfig
		DRDY => SYSMON_DRDY, -- 1-bit output data ready for dynamic reconfig
		DADDR => SYSMON_ADDR, -- 7-bit input address bus for dynamic reconfig
		DCLK => SYSMON_CLK, -- 1-bit input clock for dynamic reconfig
		DEN => SYSMON_DEN, -- 1-bit input enable for dynamic reconfig
		DI => SYSMON_DIN, -- 16-bit input data bus for dynamic reconfig
		DWE => SYSMON_WR_EN, -- 1-bit input write enable for dynamic reconfig

		JTAGBUSY => open, -- 1-bit output JTAG DRP busy
		JTAGLOCKED => open, -- 1-bit output DRP port lock
		JTAGMODIFIED => open, -- 1-bit output JTAG write to DRP

		ALM => SYSMON_ALM(2 downto 0), -- 3-bit output alarm for temp, Vccint and Vccaux
		BUSY => SYSMON_BUSY, -- 1-bit output ADC busy signal
		OT => SYSMON_OVERTEMP, -- 1-bit output over temperature alarm

		CHANNEL => SYSMON_CHANNEL, -- 5-bit output channel selection
		EOC => SYSMON_EOC, -- 1-bit output end of conversion
		EOS => SYSMON_EOS, -- 1-bit output end of sequence
		CONVST => '0', -- 1-bit input convert start
		CONVSTCLK => '0', -- 1-bit input convert start clock
		VAUXN => VAUXN_VECT, -- 16-bit input N-side auxiliary analog input
		VAUXP => VAUXP_VECT, -- 16-bit input P-side auxiliary analog input
		VN => VN, -- 1-bit input N-side analog input
		VP => VP, -- 1-bit input P-side analog input


		RESET => SYSMON_RST -- 1-bit input active high reset
	);
end generate;


SYSMON7_GEN: if FPGA_SERIES_LIST(PLATFORM_ID)=7 generate
XADC0 : XADC
	generic map (
		INIT_40 => X"0400", -- Configuration register 0
		INIT_41 => X"2000", -- Configuration register 1
		INIT_42 => X"0800", -- Configuration register 2
		INIT_43 => X"0000", -- Test register 0
		INIT_44 => X"0000", -- Test register 1
		INIT_45 => X"0000", -- Test register 2
		INIT_46 => X"0000", -- Test register 3
		INIT_47 => X"0000", -- Test register 4
		INIT_48 => X"0000", -- Sequence register 0
		INIT_49 => X"0000", -- Sequence register 1
		INIT_4A => X"0000", -- Sequence register 2
		INIT_4B => X"0000", -- Sequence register 3
		INIT_4C => X"0000", -- Sequence register 4
		INIT_4D => X"0000", -- Sequence register 5
		INIT_4E => X"0000", -- Sequence register 6
		INIT_4F => X"0000", -- Sequence register 7
		INIT_50 => X"0000", -- Alarm limit register 0
		INIT_51 => X"0000", -- Alarm limit register 1
		INIT_52 => X"0000", -- Alarm limit register 2
		INIT_53 => X"0000", -- Alarm limit register 3
		INIT_54 => X"0000", -- Alarm limit register 4
		INIT_55 => X"0000", -- Alarm limit register 5
		INIT_56 => X"0000", -- Alarm limit register 6
		INIT_57 => X"0000", -- Alarm limit register 7
		SIM_DEVICE => "7SERIES" -- Device family selection
--		SIM_MONITOR_FILE => "design.txt" -- Simulation analog entry file
	)
	port map (

		-- Control Interface
		DO => SYSMON_DOUT, -- 16-bit output data bus for dynamic reconfig
		DRDY => SYSMON_DRDY, -- 1-bit output data ready for dynamic reconfig
		DADDR => SYSMON_ADDR, -- 7-bit input address bus for dynamic reconfig
		DCLK => SYSMON_CLK, -- 1-bit input clock for dynamic reconfig
		DEN => SYSMON_DEN, -- 1-bit input enable for dynamic reconfig
		DI => SYSMON_DIN, -- 16-bit input data bus for dynamic reconfig
		DWE => SYSMON_WR_EN, -- 1-bit input write enable for dynamic reconfig

		JTAGBUSY => open, -- 1-bit output JTAG DRP busy
		JTAGLOCKED => open, -- 1-bit output DRP port lock
		JTAGMODIFIED => open, -- 1-bit output JTAG write to DRP

		ALM => SYSMON_ALM, -- 7-bit output alarm for temp, Vccint and Vccaux etc.
		BUSY => SYSMON_BUSY, -- 1-bit output ADC busy signal
		OT => SYSMON_OVERTEMP, -- 1-bit output over temperature alarm

		CHANNEL => SYSMON_CHANNEL, -- 5-bit output channel selection
		EOC => SYSMON_EOC, -- 1-bit output end of conversion
		EOS => SYSMON_EOS, -- 1-bit output end of sequence
		CONVST => '0', -- 1-bit input convert start
		CONVSTCLK => '0', -- 1-bit input convert start clock
		VAUXN => VAUXN_VECT, -- 16-bit input N-side auxiliary analog input
		VAUXP => VAUXP_VECT, -- 16-bit input P-side auxiliary analog input
		VN => VN, -- 1-bit input N-side analog input
		VP => VP, -- 1-bit input P-side analog input


		RESET => SYSMON_RST -- 1-bit input active high reset
	);
end generate;


end Behavioral;

