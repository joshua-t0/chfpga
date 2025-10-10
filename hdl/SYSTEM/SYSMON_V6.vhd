----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    20:14:22 05/20/2011
-- Design Name:  chFPGA PoC
-- Module Name:    SYSMON_V6 - impl
-- Project Name: CHIME
-- Target Devices: Virtex 6, Kintex 7, Ultrascale+
-- Tool versions: ISE 14.2 - Vivado 2022.2
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
--    2011-07-08 JFC: Added monitoring of SYSMON's CHANNEL, EOC, EOS. Connected VP/VN and a couple of VAUX
--    2011-07-25 JFC: Modified to use the new 16-bit mode of the CMD_SLAVE
--    2012-10-18 JFC: Added FIFO on control bus to operate SYSMON at sysmon_clk
--    See GIT for more history tracking
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chFPGA_Package.ALL; -- Get all component definitions

library UNISIM;
use UNISIM.VComponents.ALL;

-- Implements the FPGA's internal SYSTEM MONITOR (Virtex 6, Ultrascale+) or XADC (7 series) block to monitor
-- internal and external voltages and temperatures
entity SYSMON_XADC is
	generic (
		PLATFORM_ID: integer
	);
	port (
		-- Control interface
		ctrl_cmd_in_dat: in AXIS8_DAT_STRUCT; -- Command stream input, signals from master (Data, Valid, Last)
		ctrl_cmd_in_rdy: out AXIS8_RDY_STRUCT; -- Command stream input, signals to master (Ready)
		ctrl_rply_out_dat: out AXIS8_DAT_STRUCT; -- Reply stream output, signals to slave (Data, Valid, Last)
		ctrl_rply_out_rdy: in AXIS8_RDY_STRUCT; -- Reply stream output,  signals from slave (Ready)
		ctrl_clk: in  std_logic;
		ctrl_rst: in std_logic;

		--  Current and voltage monitors
		vaux_curr_n: in  std_logic;
		vaux_curr_p: in  std_logic; -- External current monitor on the 12V supply line
		vaux_volt_n: in  std_logic;
		vaux_volt_p: in  std_logic; -- External voltage monitor on the 12V supply line
		vp: in  std_logic;
		vn: in  std_logic;


		-- FPGA FAN signals
		fan_pwm: out std_logic; -- Fan control pin. Can be pulse modulated to produce variable speed (not implemented)
		fan_tach: in std_logic := '0'; -- Fan speed monitor pin. Pulses twice per rotation. Is very glitchy and needs serious debouncing.

		-- debug_out: out slv32;
		-- System-level signals
		sysmon_clk: in  std_logic; -- System monitor clock. Clocks the SYSMON hardware block.
		sysmon_rst: in std_logic -- synchronous to sysmon_clk
	);
end entity SYSMON_XADC;

architecture impl of SYSMON_XADC is


	constant FPGA_SERIES: integer := PLATFORM_INFO(PLATFORM_ID).FPGA_SERIES;

	--- Define Control word and its signals
	signal bsb_rst: std_logic;

	signal control_bytes: slv8_array(0 to 0); --
	signal status_bytes: slv8_array(0 to 1);

	signal control_bytes_fan_en: std_logic;

	signal ctrl_cmd_in_rdy_int: AXIS8_RDY_STRUCT;
	signal ctrl_rply_out_dat_int: AXIS8_DAT_STRUCT;


	-- SYSMON signals
	signal sysmon_dout: std_logic_vector(15 downto 0);
	signal sysmon_din: std_logic_vector(15 downto 0);
	-- signal SYSMON_DADDR: std_logic_vector(6 downto 0);
	signal sysmon_drdy: std_logic;
	signal sysmon_den: std_logic;
	signal sysmon_wr_en: std_logic;
	signal sysmon_alm: std_logic_vector(15 downto 0);
	signal sysmon_busy: std_logic;
	signal sysmon_overtemp: std_logic;
	signal sysmon_channel: std_logic_vector(5 downto 0);
	signal sysmon_eoc: std_logic;
	signal sysmon_eos: std_logic;

	signal vauxn_vect: std_logic_vector(15 downto 0);
	signal vauxp_vect: std_logic_vector(15 downto 0);


	signal sysmon_addr: std_logic_vector(7 downto 0);


	signal fifo_cmd_in_dat: AXIS8_DAT_STRUCT;
	signal fifo_cmd_in_rdy: AXIS8_RDY_STRUCT;
	signal fifo_rply_out_dat: AXIS8_DAT_STRUCT;
	signal fifo_rply_out_rdy: AXIS8_RDY_STRUCT;


begin

	-----------------------------------------------------------------------------------
	-- CONTROL and STATUS Bytes
	-----------------------------------------------------------------------------------
	-- Memory map
	-- ----------------------------------------------------------------------------------------
	-- | Page    | Addr|Bit(s)|     Name               | Description                           |
	-- |---------|-----|-----|-------------------------|---------------------------------------|
	-- | CONTROL |  0  | 7:2 | (unused)                |  |
	-- |         |     |  1  | fan_en                  |  Force HIGH on the fan PWM signal |
	-- |         |     | 0   | (unused)                |  |
	-- | STATUS  |  0  | 7:2 | sysmon_alm              | SYSMON alarm signals |
	-- |         |     |  1  | sysmon_overtemp         | SYSMON overtemperature alarm|
	-- |         |     |  0  | sysmon_busy             | SYSMON data conversion busy |
	-- |         |  1  |  7  | sysmon_busy             | SYSMON data conversion busy |
	-- |         |     |  6  | sysmon_eos              | SYSMON EOS (end of scan) output signal |
	-- |         |     |  5  | sysmon_eoc              | SYSMON EOC (end of conversion) output signal |
	-- |         |     | 4:0 | sysmon_channel          | SYSMON current monitoring channel|
	-- ------------------------------------------------------------------------------

	-- Assign signals to CONTROL and STATUS WORDS
	control_bytes_fan_en <= control_bytes(0)(1);

	status_bytes(0)(7 downto 2) <= sysmon_alm(5 downto 0);
	status_bytes(0)(1)          <= sysmon_overtemp;
	status_bytes(0)(0)          <= sysmon_busy;

	status_bytes(1)(7)          <= sysmon_busy;
	status_bytes(1)(6)          <= sysmon_eos;
	status_bytes(1)(5)          <= sysmon_eoc;
	status_bytes(1)(4 downto 0) <= sysmon_channel(4 downto 0);


	fan_pwm <= control_bytes_fan_en or sysmon_overtemp or '1';

	ctrl_cmd_in_rdy   <= ctrl_cmd_in_rdy_int;
	ctrl_rply_out_dat <= ctrl_rply_out_dat_int;

	-- Implement an an asynchronous FIFO to bridge the BSB bus from the ctrl_clk
	-- to the sysmon_clk domains to allow the DRP signals will be synchronous to
	-- that clock
	fifo0: entity work.CMD_ASYNC_FIFO
		port map (
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

	ctrl_slave0: entity work.CTRL_SLAVE
		generic map (
			USE_RAM_DOUT_RDY        => TRUE, -- need to wait for the RDY signal on RAM read accesses
			RAM_DATA_WIDTH          => 16,
			RAM_ADDR_WIDTH          => 8, -- SYSMON DRP Address bus width is 8 bits for SYSMONE1, 7 bits for the other primitives
			NUMBER_OF_CONTROL_BYTES => control_bytes'Length(1), -- Number of bits in the control word
			NUMBER_OF_STATUS_BYTES  => status_bytes'Length(1) -- Number of bits in the status word.
		)

		port map (
			-- Control interface (command and reply stream buses)
			ctrl_cmd_in_dat   => fifo_cmd_in_dat,
			ctrl_cmd_in_rdy   => fifo_cmd_in_rdy,
			ctrl_rply_out_dat => fifo_rply_out_dat,
			ctrl_rply_out_rdy => fifo_rply_out_rdy,
			ctrl_clk          => sysmon_clk,
			ctrl_rst          => bsb_rst,

			control_bytes => control_bytes,
			status_bytes  => status_bytes,

			ram_din      => sysmon_din,
			ram_dout     => sysmon_dout,
			ram_dout_rdy => sysmon_drdy,
			ram_wr_en    => sysmon_wr_en,
			ram_en       => sysmon_den,
			ram_addr     => sysmon_addr
		);

	vauxn_vect <= (13=> vaux_curr_n, 12=> vaux_volt_n, others => '0'); -- 16-bit input N-side auxiliary analog input
	vauxp_vect <= (13=> vaux_curr_p, 12=> vaux_volt_p, others => '0'); -- 16-bit input P-side auxiliary analog input

	sysmon6_gen: if FPGA_SERIES = FPGA_VIRTEX6 generate

		sysmon0: SYSMON
			generic map (
				INIT_40    => X"0400", -- Configuration register 0
				INIT_41    => X"2000", -- Configuration register 1
				INIT_42    => X"0800", -- Configuration register 2
				INIT_43    => X"0000", -- Test register 0
				INIT_44    => X"0000", -- Test register 1
				INIT_45    => X"0000", -- Test register 2
				INIT_46    => X"0000", -- Test register 3
				INIT_47    => X"0000", -- Test register 4
				INIT_48    => X"0000", -- Sequence register 0
				INIT_49    => X"0000", -- Sequence register 1
				INIT_4A    => X"0000", -- Sequence register 2
				INIT_4B    => X"0000", -- Sequence register 3
				INIT_4C    => X"0000", -- Sequence register 4
				INIT_4D    => X"0000", -- Sequence register 5
				INIT_4E    => X"0000", -- Sequence register 6
				INIT_4F    => X"0000", -- Sequence register 7
				INIT_50    => X"0000", -- Alarm limit register 0
				INIT_51    => X"0000", -- Alarm limit register 1
				INIT_52    => X"0000", -- Alarm limit register 2
				INIT_53    => X"0000", -- Alarm limit register 3
				INIT_54    => X"0000", -- Alarm limit register 4
				INIT_55    => X"0000", -- Alarm limit register 5
				INIT_56    => X"0000", -- Alarm limit register 6
				INIT_57    => X"0000", -- Alarm limit register 7
				SIM_DEVICE => "VIRTEX6" -- Device family selection
			-- SIM_MONITOR_FILE => "design.txt" -- Simulation analog entry file
			)
			port map (
				-- Control Interface
				do    => sysmon_dout, -- 16-bit output data bus for dynamic reconfig
				drdy  => sysmon_drdy, -- 1-bit output data ready for dynamic reconfig
				daddr => sysmon_addr(6 downto 0), -- 7-bit input address bus for dynamic reconfig
				dclk  => sysmon_clk, -- 1-bit input clock for dynamic reconfig
				den   => sysmon_den, -- 1-bit input enable for dynamic reconfig
				di    => sysmon_din, -- 16-bit input data bus for dynamic reconfig
				dwe   => sysmon_wr_en, -- 1-bit input write enable for dynamic reconfig

				jtagbusy     => open, -- 1-bit output JTAG DRP busy
				jtaglocked   => open, -- 1-bit output DRP port lock
				jtagmodified => open, -- 1-bit output JTAG write to DRP

				alm  => sysmon_alm(2 downto 0), -- 3-bit output alarm for temp, Vccint and Vccaux
				busy => sysmon_busy, -- 1-bit output ADC busy signal
				ot   => sysmon_overtemp, -- 1-bit output over temperature alarm

				channel   => sysmon_channel(4 downto 0), -- 5-bit output channel selection
				eoc       => sysmon_eoc, -- 1-bit output end of conversion
				eos       => sysmon_eos, -- 1-bit output end of sequence
				convst    => '0', -- 1-bit input convert start
				convstclk => '0', -- 1-bit input convert start clock
				vauxn     => vauxn_vect, -- 16-bit input N-side auxiliary analog input
				vauxp     => vauxp_vect, -- 16-bit input P-side auxiliary analog input
				vn        => vn, -- 1-bit input N-side analog input
				vp        => vp, -- 1-bit input P-side analog input


				reset => sysmon_rst -- 1-bit input active high reset
			);
	end generate sysmon6_gen;


	sysmon7_gen: if FPGA_SERIES = FPGA_KINTEX7 generate

		xadc0: XADC
			generic map (
				INIT_40    => X"0400", -- Configuration register 0
				INIT_41    => X"2000", -- Configuration register 1
				INIT_42    => X"0800", -- Configuration register 2
				INIT_43    => X"0000", -- Test register 0
				INIT_44    => X"0000", -- Test register 1
				INIT_45    => X"0000", -- Test register 2
				INIT_46    => X"0000", -- Test register 3
				INIT_47    => X"0000", -- Test register 4
				INIT_48    => X"0000", -- Sequence register 0
				INIT_49    => X"0000", -- Sequence register 1
				INIT_4A    => X"0000", -- Sequence register 2
				INIT_4B    => X"0000", -- Sequence register 3
				INIT_4C    => X"0000", -- Sequence register 4
				INIT_4D    => X"0000", -- Sequence register 5
				INIT_4E    => X"0000", -- Sequence register 6
				INIT_4F    => X"0000", -- Sequence register 7
				INIT_50    => X"0000", -- Alarm limit register 0
				INIT_51    => X"0000", -- Alarm limit register 1
				INIT_52    => X"0000", -- Alarm limit register 2
				INIT_53    => X"0000", -- Alarm limit register 3
				INIT_54    => X"0000", -- Alarm limit register 4
				INIT_55    => X"0000", -- Alarm limit register 5
				INIT_56    => X"0000", -- Alarm limit register 6
				INIT_57    => X"0000", -- Alarm limit register 7
				SIM_DEVICE => "7SERIES" -- Device family selection
			)
			port map (
				-- Control Interface
				do    => sysmon_dout, -- 16-bit output data bus for dynamic reconfig
				drdy  => sysmon_drdy, -- 1-bit output data ready for dynamic reconfig
				daddr => sysmon_addr(6 downto 0), -- 7-bit input address bus for dynamic reconfig
				dclk  => sysmon_clk, -- 1-bit input clock for dynamic reconfig
				den   => sysmon_den, -- 1-bit input enable for dynamic reconfig
				di    => sysmon_din, -- 16-bit input data bus for dynamic reconfig
				dwe   => sysmon_wr_en, -- 1-bit input write enable for dynamic reconfig

				jtagbusy     => open, -- 1-bit output JTAG DRP busy
				jtaglocked   => open, -- 1-bit output DRP port lock
				jtagmodified => open, -- 1-bit output JTAG write to DRP

				alm  => sysmon_alm(7 downto 0), -- 7-bit output alarm for temp, Vccint and Vccaux etc.
				busy => sysmon_busy, -- 1-bit output ADC busy signal
				ot   => sysmon_overtemp, -- 1-bit output over temperature alarm

				channel   => sysmon_channel(4 downto 0), -- 5-bit output channel selection
				eoc       => sysmon_eoc, -- 1-bit output end of conversion
				eos       => sysmon_eos, -- 1-bit output end of sequence
				convst    => '0', -- 1-bit input convert start
				convstclk => '0', -- 1-bit input convert start clock
				vauxn     => vauxn_vect, -- 16-bit input N-side auxiliary analog input
				vauxp     => vauxp_vect, -- 16-bit input P-side auxiliary analog input
				vn        => vn, -- 1-bit input N-side analog input
				vp        => vp, -- 1-bit input P-side analog input


				reset => sysmon_rst -- 1-bit input active high reset
			);
	end generate sysmon7_gen;


	sysmon_zup_gen: if FPGA_SERIES = FPGA_ULTRASCALEPLUS generate  -- Might need more specificity to set the SIM_DEVICE correctly on non-ZYNQ Ultrascale+

		sysmone4_inst: SYSMONE4  -- Tried to use SYSMONE1 but cannot set SIM_DEVICE: fails at bitgen DRC
			generic map (
				COMMON_N_SOURCE => X"FFFF", -- Source for Common N Channels
				INIT_40         => X"0000", -- config reg 0
				INIT_41         => X"2190", -- config reg 1
				INIT_42         => X"1400", -- config reg 2
				INIT_43         => X"200F", -- config reg 3
				INIT_44         => X"0000", -- config reg 4
				INIT_45         => X"E200", -- Analog Bus Register
				INIT_46         => X"0000", -- Sequencer Channel selection (Vuser0-3)
				INIT_47         => X"0000", -- Sequencer Average selection (Vuser0-3)
				INIT_48         => X"4F01", -- Sequencer channel selection
				INIT_49         => X"0000", -- Sequencer channel selection
				INIT_4A         => X"0000", -- Sequencer Average selection
				INIT_4B         => X"0000", -- Sequencer Average selection
				INIT_4C         => X"0000", -- Sequencer Bipolar selection
				INIT_4D         => X"0000", -- Sequencer Bipolar selection
				INIT_4E         => X"0000", -- Sequencer Acq time selection
				INIT_4F         => X"0000", -- Sequencer Acq time selection
				INIT_50         => X"B794", -- Temp alarm trigger
				INIT_51         => X"4E81", -- Vccint upper alarm limit
				INIT_52         => X"A147", -- Vccaux upper alarm limit
				INIT_53         => X"CBA3", -- Temp alarm OT upper
				INIT_54         => X"AB02", -- Temp alarm reset
				INIT_55         => X"4963", -- Vccint lower alarm limit
				INIT_56         => X"9555", -- Vccaux lower alarm limit
				INIT_57         => X"B00A", -- Temp alarm OT reset
				INIT_58         => X"4E81", -- Vccbram upper alarm limit
				INIT_5C         => X"4963", -- Vbccram lower alarm limit
				INIT_59         => X"4963", -- vccpsintlp upper alarm limit
				INIT_5D         => X"451E", -- vccpsintlp lower alarm limit
				INIT_5A         => X"4963", -- vccpsintfp upper alarm limit
				INIT_5E         => X"451E", -- vccpsintfp lower alarm limit
				INIT_5B         => X"9A74", -- vccpsaux upper alarm limit
				INIT_5F         => X"91EB", -- vccpsaux lower alarm limit
				INIT_60         => X"4D39", -- Vuser0 upper alarm limit
				INIT_61         => X"4DA7", -- Vuser1 upper alarm limit
				INIT_62         => X"9A74", -- Vuser2 upper alarm limit
				INIT_63         => X"9A74", -- Vuser3 upper alarm limit
				INIT_68         => X"4C5E", -- Vuser0 lower alarm limit
				INIT_69         => X"4BF2", -- Vuser1 lower alarm limit
				INIT_6A         => X"98BF", -- Vuser2 lower alarm limit
				INIT_6B         => X"98BF", -- Vuser3 lower alarm limit
				INIT_7A         => X"0000", -- DUAL0 Register
				INIT_7B         => X"0000", -- DUAL1 Register
				INIT_7C         => X"0000", -- DUAL2 Register
				INIT_7D         => X"0000", -- DUAL3 Register
				SIM_DEVICE      => "ZYNQ_ULTRASCALE",
				SIM_MONITOR_FILE => "/home/jfcliche/chfpga/xilinx_projects/testbenches/sysmon_testbench/sysmon_sim_data.txt"
			)
			port map (
				-- DRP port
				do    => sysmon_dout, -- 16-bit output data bus for dynamic reconfig
				drdy  => sysmon_drdy, -- 1-bit output data ready for dynamic reconfig
				daddr => sysmon_addr, -- 8-bit input address bus for dynamic reconfig
				dclk  => sysmon_clk, -- 1-bit input clock for dynamic reconfig
				den   => sysmon_den, -- 1-bit input enable for dynamic reconfig
				di    => sysmon_din, -- 16-bit input data bus for dynamic reconfig
				dwe   => sysmon_wr_en, -- 1-bit input write enable for dynamic reconfig

				alm  => sysmon_alm(15 downto 0), -- 16-bit output alarm for temp, Vccint and Vccaux
				busy => sysmon_busy, -- 1-bit output ADC busy signal
				ot   => sysmon_overtemp, -- 1-bit output over temperature alarm

				adc_data  => open,
				channel   => sysmon_channel(5 downto 0), -- 5-bit output channel selection
				eoc       => sysmon_eoc, -- 1-bit output end of conversion
				eos       => sysmon_eos, -- 1-bit output end of sequence
				convst    => '0', -- 1-bit input convert start
				convstclk => '0', -- 1-bit input convert start clock

				vauxn => vauxn_vect, -- 16-bit input N-side auxiliary analog input
				vauxp => vauxp_vect, -- 16-bit input P-side auxiliary analog input
				vn    => vn, -- 1-bit input N-side analog input
				vp    => vp, -- 1-bit input P-side analog input

				-- I2C Interface inputs: Ports used with the I2C DRP interface
				i2c_sclk => '0',         -- 1-bit input: I2C_SCLK input port
				i2c_sda  => '0',            -- 1-bit input: I2C_SDA input port

				reset => sysmon_rst -- 1-bit input active high reset
			);
	end generate sysmon_zup_gen;


end architecture impl;

