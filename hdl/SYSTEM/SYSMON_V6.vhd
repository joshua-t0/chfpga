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
-- 2012-10-18 JFC: Added FIFO on control bus to operate SYSMON at sysmon_clk
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
		ctrl_cmd_in_dat: in AXIS8_DAT_STRUCT; --! Command stream input, signals from master (Data, Valid, Last)
		ctrl_cmd_in_rdy: out AXIS8_RDY_STRUCT; --! Command stream input, signals to master (Ready)
		ctrl_rply_out_dat: out AXIS8_DAT_STRUCT; --! Reply stream output, signals to slave (Data, Valid, Last)
		ctrl_rply_out_rdy: in AXIS8_RDY_STRUCT; --! Reply stream output,  signals from slave (Ready)
		ctrl_clk: in  STD_LOGIC;
		ctrl_rst: in std_logic;

		--  Current and voltage monitors
		VAUX_CURR_N : in  STD_LOGIC;
		VAUX_CURR_P : in  STD_LOGIC; --! External current monitor on the 12V supply line
		VAUX_VOLT_N : in  STD_LOGIC;
		VAUX_VOLT_P : in  STD_LOGIC;--! External voltage monitor on the 12V supply line
		VP : in  STD_LOGIC;
		VN : in  STD_LOGIC;


		-- FPGA FAN signals
		FAN_PWM: out STD_LOGIC; --! Fan control pin. Can be pulse modulated to produce variable speed (not implemented)
		FAN_TACH: in STD_LOGIC := '0'; --! Fan speed monitor pin. Pulses twice per rotation. Is very glitchy and needs serious debouncing.

		--debug_out: out slv32;
		-- System-level signals
		sysmon_clk: in  STD_LOGIC; --! System monitor clock. Clocks the SYSMON hardware block.
		sysmon_rst: in STD_LOGIC -- synchronous to sysmon_clk
	);

end SYSMON_XADC;

architecture Behavioral of SYSMON_XADC is


constant FPGA_SERIES: integer := PLATFORM_INFO(PLATFORM_ID).FPGA_SERIES;

--- Define Control word and its signals
signal bsb_rst: std_logic;

signal CONTROL_BYTES: slv8_array(0 to 0); --
signal STATUS_BYTES: slv8_array(0 to 1);

signal CONTROL_BYTES_BANK_SEL: STD_LOGIC_VECTOR(0 downto 0);
signal CONTROL_BYTES_FAN_EN: STD_LOGIC;

signal ctrl_cmd_in_rdy_int: AXIS8_RDY_STRUCT;
signal ctrl_rply_out_dat_int: AXIS8_DAT_STRUCT;
	

-- SYSMON signals
signal SYSMON_DOUT: STD_LOGIC_VECTOR(15 downto 0);
signal SYSMON_DIN: STD_LOGIC_VECTOR(15 downto 0);
--signal SYSMON_DADDR: STD_LOGIC_VECTOR(6 downto 0);
signal SYSMON_DRDY: STD_LOGIC;
signal SYSMON_DEN: STD_LOGIC;
signal SYSMON_WR_EN: STD_LOGIC;
signal SYSMON_ALM: STD_LOGIC_VECTOR(15 downto 0);
signal SYSMON_BUSY: STD_LOGIC;
signal SYSMON_OVERTEMP: STD_LOGIC;
signal SYSMON_CHANNEL: STD_LOGIC_VECTOR(5 downto 0);
signal SYSMON_EOC: STD_LOGIC;
signal SYSMON_EOS: STD_LOGIC;

signal VAUXN_VECT: STD_LOGIC_VECTOR(15 downto 0);
signal VAUXP_VECT: STD_LOGIC_VECTOR(15 downto 0);


-- CTRL_SLAVE memory mapped interface
signal SYSMON_ADDR: STD_LOGIC_VECTOR(7 downto 0);


signal fifo_cmd_in_dat:  AXIS8_DAT_STRUCT;
signal fifo_cmd_in_rdy:  AXIS8_RDY_STRUCT;
signal fifo_rply_out_dat:  AXIS8_DAT_STRUCT;
signal fifo_rply_out_rdy: AXIS8_RDY_STRUCT;


begin
-- Assign signals to CONTROL and STATUS WORDS
CONTROL_BYTES_BANK_SEL(0) <=	CONTROL_BYTES(0)(0);
CONTROL_BYTES_FAN_EN <=	CONTROL_BYTES(0)(1);

STATUS_BYTES(0)(7 downto 2) <= SYSMON_ALM(5 downto 0);
STATUS_BYTES(0)(1) <= SYSMON_OVERTEMP;
STATUS_BYTES(0)(0) <= SYSMON_BUSY;

STATUS_BYTES(1)(7) <= SYSMON_BUSY;
STATUS_BYTES(1)(6) <= SYSMON_EOS;
STATUS_BYTES(1)(5) <= SYSMON_EOC;
STATUS_BYTES(1)(4 downto 0) <= SYSMON_CHANNEL(4 downto 0);


FAN_PWM <= CONTROL_BYTES_FAN_EN or SYSMON_OVERTEMP or '1';

ctrl_cmd_in_rdy <= ctrl_cmd_in_rdy_int;
ctrl_rply_out_dat <= ctrl_rply_out_dat_int;

--Implement an an asynchronous FIFO to bridge the BSB bus from the ctrl_clk
--to the sysmon_clk domains to allow the DRP signals will be synchronous to
--that clock
FIFO0 : entity work.CMD_ASYNC_FIFO
  PORT MAP (
		cmd_a_dat  => ctrl_cmd_in_dat,
		cmd_a_rdy  => ctrl_cmd_in_rdy_int,
		rply_a_dat => ctrl_rply_out_dat_int,
		rply_a_rdy => ctrl_rply_out_rdy,
		a_clk      => ctrl_clk,

		cmd_b_dat  => fifo_cmd_in_dat,
		cmd_b_rdy  => fifo_cmd_in_rdy,
		rply_b_dat => fifo_rply_out_dat,
		rply_b_rdy => fifo_rply_out_rdy,
		b_clk      => sysmon_clk,
		b_rst_out  => bsb_rst,

		rst => ctrl_rst -- Asynchronous. The module internally extends the pulse for a number of A_CLK and B_CLK when they come. 
		);

--debug_out(0) <=  ctrl_cmd_in_dat.TVALID;
--debug_out(1) <=  ctrl_cmd_in_dat.TLAST;
--debug_out(2) <=  ctrl_cmd_in_rdy_int.TREADY;
--debug_out(3) <=  ctrl_rply_out_dat_int.TVALID;
--debug_out(4) <=  ctrl_rply_out_dat_int.TLAST;
--debug_out(5) <= ctrl_rply_out_rdy.TREADY;
--debug_out(6) <=  fifo_cmd_in_dat.TVALID;
--debug_out(7) <=  fifo_cmd_in_dat.TLAST;
--debug_out(8) <=  fifo_cmd_in_rdy.TREADY;
--debug_out(9) <=  fifo_rply_out_dat.TVALID;
--debug_out(10) <=  fifo_rply_out_dat.TLAST;
--debug_out(11) <=  fifo_rply_out_rdy.TREADY;
--debug_out(12) <=  sysmon_rst;
--debug_out(13) <= ctrl_rst;
--debug_out(14) <= bsb_rst;
--debug_out(15) <= sysmon_clk;

---- Make sure we capture the ctrl_rst reset of the CTRL_SLAVE
---- even if the sysmon_clk is not yet active and generate a proper reset when the clock
---- comes on.
--bsb_reset_inst : xpm_cdc_async_rst
--	generic map (
--	   RST_ACTIVE_HIGH => 1  -- DECIMAL; 0=active low reset, 1=active high reset
--	)
--	port map (
--	   src_arst => ctrl_rst or sysmon_rst,   -- Source asynchronous reset signal.
--	   dest_arst => bsb_rst, -- 1-bit output: src_arst asynchronous reset signal synchronized to destination
--	                           -- clock domain. This output is registered. NOTE: Signal asserts asynchronously
--	                           -- but deasserts synchronously to dest_clk. Width of the reset signal is at least
--	                           -- (DEST_SYNC_FF*dest_clk) period.

--	   dest_clk => sysmon_clk   -- 1-bit input: Destination clock.
--	);

CTRL_SLAVE0: entity work.CTRL_SLAVE
	GENERIC MAP (
		USE_RAM_DOUT_RDY =>        TRUE, -- need to wait for the RDY signal on RAM read accesses
		RAM_DATA_WIDTH =>          16,
		RAM_ADDR_WIDTH =>          8, -- SYSMON DRP Address bus width is 8 bits for SYSMONE1, 7 bits for the other primitives
		NUMBER_OF_CONTROL_BYTES => CONTROL_BYTES'Length(1), -- Number of bits in the control word
		NUMBER_OF_STATUS_BYTES =>  STATUS_BYTES'Length(1) -- Number of bits in the status word.
		)

	PORT MAP(

		-- Control interface (command and reply stream buses)
		CTRL_CMD_IN_DAT => fifo_cmd_in_dat,
		CTRL_CMD_IN_RDY => fifo_cmd_in_rdy,
		CTRL_RPLY_OUT_DAT => fifo_rply_out_dat,
		CTRL_RPLY_OUT_RDY => fifo_rply_out_rdy,
		CTRL_CLK => sysmon_clk,
		CTRL_RST => bsb_rst,

		CONTROL_BYTES => CONTROL_BYTES,
		STATUS_BYTES => STATUS_BYTES,

		RAM_DIN => SYSMON_DIN,
		RAM_DOUT => SYSMON_DOUT,
		RAM_DOUT_RDY => SYSMON_DRDY,
		RAM_WR_EN => SYSMON_WR_EN,
		RAM_EN => SYSMON_DEN,
		RAM_ADDR => SYSMON_ADDR
		);

VAUXN_VECT<=(13=>VAUX_CURR_N, 12=> VAUX_VOLT_N, others=>'0'); -- 16-bit input N-side auxiliary analog input
VAUXP_VECT<=(13=>VAUX_CURR_P, 12=> VAUX_VOLT_P, others=>'0'); -- 16-bit input P-side auxiliary analog input

SYSMON6_GEN: if FPGA_SERIES = FPGA_VIRTEX6 generate
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
		DADDR => SYSMON_ADDR(6 downto 0), -- 7-bit input address bus for dynamic reconfig
		DCLK => sysmon_clk, -- 1-bit input clock for dynamic reconfig
		DEN => SYSMON_DEN, -- 1-bit input enable for dynamic reconfig
		DI => SYSMON_DIN, -- 16-bit input data bus for dynamic reconfig
		DWE => SYSMON_WR_EN, -- 1-bit input write enable for dynamic reconfig

		JTAGBUSY => open, -- 1-bit output JTAG DRP busy
		JTAGLOCKED => open, -- 1-bit output DRP port lock
		JTAGMODIFIED => open, -- 1-bit output JTAG write to DRP

		ALM => SYSMON_ALM(2 downto 0), -- 3-bit output alarm for temp, Vccint and Vccaux
		BUSY => SYSMON_BUSY, -- 1-bit output ADC busy signal
		OT => SYSMON_OVERTEMP, -- 1-bit output over temperature alarm

		CHANNEL => SYSMON_CHANNEL(4 downto 0), -- 5-bit output channel selection
		EOC => SYSMON_EOC, -- 1-bit output end of conversion
		EOS => SYSMON_EOS, -- 1-bit output end of sequence
		CONVST => '0', -- 1-bit input convert start
		CONVSTCLK => '0', -- 1-bit input convert start clock
		VAUXN => VAUXN_VECT, -- 16-bit input N-side auxiliary analog input
		VAUXP => VAUXP_VECT, -- 16-bit input P-side auxiliary analog input
		VN => VN, -- 1-bit input N-side analog input
		VP => VP, -- 1-bit input P-side analog input


		RESET => sysmon_rst -- 1-bit input active high reset
	);
end generate;


SYSMON7_GEN: if FPGA_SERIES = FPGA_KINTEX7  generate
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
		DADDR => SYSMON_ADDR(6 downto 0), -- 7-bit input address bus for dynamic reconfig
		DCLK => sysmon_clk, -- 1-bit input clock for dynamic reconfig
		DEN => SYSMON_DEN, -- 1-bit input enable for dynamic reconfig
		DI => SYSMON_DIN, -- 16-bit input data bus for dynamic reconfig
		DWE => SYSMON_WR_EN, -- 1-bit input write enable for dynamic reconfig

		JTAGBUSY => open, -- 1-bit output JTAG DRP busy
		JTAGLOCKED => open, -- 1-bit output DRP port lock
		JTAGMODIFIED => open, -- 1-bit output JTAG write to DRP

		ALM => SYSMON_ALM(7 downto 0), -- 7-bit output alarm for temp, Vccint and Vccaux etc.
		BUSY => SYSMON_BUSY, -- 1-bit output ADC busy signal
		OT => SYSMON_OVERTEMP, -- 1-bit output over temperature alarm

		CHANNEL => SYSMON_CHANNEL(4 downto 0), -- 5-bit output channel selection
		EOC => SYSMON_EOC, -- 1-bit output end of conversion
		EOS => SYSMON_EOS, -- 1-bit output end of sequence
		CONVST => '0', -- 1-bit input convert start
		CONVSTCLK => '0', -- 1-bit input convert start clock
		VAUXN => VAUXN_VECT, -- 16-bit input N-side auxiliary analog input
		VAUXP => VAUXP_VECT, -- 16-bit input P-side auxiliary analog input
		VN => VN, -- 1-bit input N-side analog input
		VP => VP, -- 1-bit input P-side analog input


		RESET => sysmon_rst -- 1-bit input active high reset
	);
end generate;


SYSMON_ZUP_GEN: if FPGA_SERIES = FPGA_ULTRASCALEPLUS generate  --Might need more specificity to set the SIM_DEVICE correctly on non-ZYNQ Ultrascale+

   SYSMONE4_inst : SYSMONE4  -- Tried to use SYSMONE1 but cannot set SIM_DEVICE: fails at bitgen DRC
	generic map (
        COMMON_N_SOURCE => X"FFFF", --Source for Common N Channels
        INIT_40 => X"0000", -- config reg 0
        INIT_41 => X"2190", -- config reg 1
        INIT_42 => X"1400", -- config reg 2
        INIT_43 => X"200F", -- config reg 3
        INIT_44 => X"0000", -- config reg 4
        INIT_45 => X"E200", -- Analog Bus Register
        INIT_46 => X"0000", -- Sequencer Channel selection (Vuser0-3)
        INIT_47 => X"0000", -- Sequencer Average selection (Vuser0-3)
        INIT_48 => X"4F01", -- Sequencer channel selection
        INIT_49 => X"0000", -- Sequencer channel selection
        INIT_4A => X"0000", -- Sequencer Average selection
        INIT_4B => X"0000", -- Sequencer Average selection
        INIT_4C => X"0000", -- Sequencer Bipolar selection
        INIT_4D => X"0000", -- Sequencer Bipolar selection
        INIT_4E => X"0000", -- Sequencer Acq time selection
        INIT_4F => X"0000", -- Sequencer Acq time selection
        INIT_50 => X"B794", -- Temp alarm trigger
        INIT_51 => X"4E81", -- Vccint upper alarm limit
        INIT_52 => X"A147", -- Vccaux upper alarm limit
        INIT_53 => X"CBA3", -- Temp alarm OT upper
        INIT_54 => X"AB02", -- Temp alarm reset
        INIT_55 => X"4963", -- Vccint lower alarm limit
        INIT_56 => X"9555", -- Vccaux lower alarm limit
        INIT_57 => X"B00A", -- Temp alarm OT reset
        INIT_58 => X"4E81", -- Vccbram upper alarm limit
        INIT_5C => X"4963", -- Vbccram lower alarm limit
        INIT_59 => X"4963", -- vccpsintlp upper alarm limit
        INIT_5D => X"451E", -- vccpsintlp lower alarm limit
        INIT_5A => X"4963", -- vccpsintfp upper alarm limit
        INIT_5E => X"451E", -- vccpsintfp lower alarm limit
        INIT_5B => X"9A74", -- vccpsaux upper alarm limit
        INIT_5F => X"91EB", -- vccpsaux lower alarm limit
        INIT_60 => X"4D39", -- Vuser0 upper alarm limit
        INIT_61 => X"4DA7", -- Vuser1 upper alarm limit
        INIT_62 => X"9A74", -- Vuser2 upper alarm limit
        INIT_63 => X"9A74", -- Vuser3 upper alarm limit
        INIT_68 => X"4C5E", -- Vuser0 lower alarm limit
        INIT_69 => X"4BF2", -- Vuser1 lower alarm limit
        INIT_6A => X"98BF", -- Vuser2 lower alarm limit
        INIT_6B => X"98BF", -- Vuser3 lower alarm limit
        INIT_7A => X"0000", -- DUAL0 Register
        INIT_7B => X"0000", -- DUAL1 Register
        INIT_7C => X"0000", -- DUAL2 Register
        INIT_7D => X"0000", -- DUAL3 Register
        SIM_DEVICE => "ZYNQ_ULTRASCALE"
--		SIM_MONITOR_FILE => "design.txt" -- Simulation analog entry file
	)
	port map (

		-- DRP port
		DO => SYSMON_DOUT, -- 16-bit output data bus for dynamic reconfig
		DRDY => SYSMON_DRDY, -- 1-bit output data ready for dynamic reconfig
		DADDR => SYSMON_ADDR, -- 8-bit input address bus for dynamic reconfig
		DCLK => sysmon_clk, -- 1-bit input clock for dynamic reconfig
		DEN => SYSMON_DEN, -- 1-bit input enable for dynamic reconfig
		DI => SYSMON_DIN, -- 16-bit input data bus for dynamic reconfig
		DWE => SYSMON_WR_EN, -- 1-bit input write enable for dynamic reconfig

		ALM => SYSMON_ALM(15 downto 0), -- 16-bit output alarm for temp, Vccint and Vccaux
		BUSY => SYSMON_BUSY, -- 1-bit output ADC busy signal
		OT => SYSMON_OVERTEMP, -- 1-bit output over temperature alarm

        ADC_DATA            => open,
		CHANNEL => SYSMON_CHANNEL(5 downto 0), -- 5-bit output channel selection
		EOC => SYSMON_EOC, -- 1-bit output end of conversion
		EOS => SYSMON_EOS, -- 1-bit output end of sequence
		CONVST => '0', -- 1-bit input convert start
		CONVSTCLK => '0', -- 1-bit input convert start clock

		VAUXN => VAUXN_VECT, -- 16-bit input N-side auxiliary analog input
		VAUXP => VAUXP_VECT, -- 16-bit input P-side auxiliary analog input
		VN => VN, -- 1-bit input N-side analog input
		VP => VP, -- 1-bit input P-side analog input

		-- I2C Interface inputs: Ports used with the I2C DRP interface
		I2C_SCLK => '0',         -- 1-bit input: I2C_SCLK input port
		I2C_SDA => '0',            -- 1-bit input: I2C_SDA input port

		RESET => sysmon_rst -- 1-bit input active high reset
	);
end generate;


end Behavioral;

