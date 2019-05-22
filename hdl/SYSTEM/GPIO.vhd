----------------------------------------------------------------------------------
-- @file
-- Company: Mc Gill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    2011-08-24
-- Design Name:    chFPGA
-- Module Name:    GPIO - Behavioral
-- Project Name:
-- Target Devices: Virtex 6 or 7 series
-- Tool versions: ISE 13.1 - 14.2
--
-- Dependencies:
--
-- Revision:
--  2011-08-29 JFC: Added USER_ACCESS to obtain the bitstream date (or other user info inserted at bitstream-generation time)
--  2011-09-14 JFC: Added global reset signal
--  2012-09-18 JFC: Cleanup. Added comments. Removed version Generics
--  2012-09-23 JFC: Moved fan readout (debouncing) circuitry in here.
--  2012-11-05 JFC: Removed RST from the fan tachymeter measurment logic to slightly reduce logic.
--  2013-01-30 JFC: Added PLATFORM_ID field to allow the Python software to instantiate the appropriate handlers for the specific platform
----------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all; -- for or_reduce()


use work.chFPGA_Package.all; -- Get all component definitions

use work.icecore_package.slv32_array;
use work.icecore_package.irigb;

library UNISIM;
use UNISIM.VComponents.all;

--! @brief Implements general I/O common to all the devices
--!
--! Includes
--!   - Global data capture/injection trigger
--!   - Global antenna reset
--!   - Global correlator reset
--!   - LCD Interface bits
--!   - Buck switching supply SYNC signal generation
--!   - FMC ADC Reset line
--!   - Fan speed readout
--!   - IP Port offsets for the data capture and correlator outputs
entity GPIO is
	generic (
		PLATFORM_ID: INTEGER; --! identifies the type of platform on which the firmware is running
		COOKIE : integer := 16#42#;
		PROTOCOL_VERSION: INTEGER; --! Protocol version used to determins compatibility with the python support software
		NUMBER_OF_ADCS: INTEGER; --! Number of antenna processing blocks that are implemented
		NUMBER_OF_CHANNELIZERS: INTEGER; --! Number of antenna processing blocks that are implemented
		CHANNELIZERS_CLOCK_SOURCE: INTEGER; --! ADC channel from which the channelizers clocks are derived
		NUMBER_OF_CHANNELIZERS_WITH_FFT: INTEGER; --! Number of antenna processing blocks with an FFT module
		NUMBER_OF_CROSSBAR_INPUTS: integer;
		NUMBER_OF_CROSSBAR_OUTPUTS: integer;
		NUMBER_OF_BP_SHUFFLE_LINKS: integer;
		NUMBER_OF_GPU_LINKS: integer;
		NUMBER_OF_CORRELATORS: INTEGER; --! Number of correlator blocks (CH_DIST+CORR+ACC) that are implemented if IMPLEMENT_CORR=TRUE
		NUMBER_OF_CHANNELIZERS_TO_CORRELATE: INTEGER; --! Number of antennas to be correlated for each frequency channel. This is hard coded for now. Determines how many antenna streams are fed to the CORR_BLOCK modules, and how many multipliers to implement in parallel in the CORR module.
		NUMBER_OF_ADC_BOARDS: integer := 1;
		NUMBER_OF_BUCK_SYNC_LINES: integer :=16;
		BUCK_CLK_DIVIDE_FACTOR: INTEGER :=12; -- Buck frequency is 200MHz/BUCK_CLK_DIVIDE_FACTOR/16
		MAC_ADDRESS_OUI_CODE: std_logic_vector(23 downto 0) := X"000A35"; -- Xilinx OUI code used to identify the first 3 bytes of the MAC address
		NUMBER_OF_USER_SMA_SIGNALS: integer := 8;
		SIM: boolean := FALSE
		);
	port (
		-- Control interface

		ctrl_cmd_in_dat: in AXIS8_DAT_STRUCT; -- Command stream input, signals from master (Data, Valid, Last)
		ctrl_cmd_in_rdy: out AXIS8_RDY_STRUCT; -- Command stream input, signals to master (Ready)
		ctrl_rply_out_dat: out AXIS8_DAT_STRUCT; -- Reply stream output, signals to slave (Data, Valid, Last)
		ctrl_rply_out_rdy: in AXIS8_RDY_STRUCT; -- Reply stream output,  signals from slave (Ready)
		ctrl_clk: in  std_logic;
		ctrl_rst: in std_logic;

		-- IP Port setting

		CTRL_RPLY_IP_PORT_OFFSET: out PortOffset;
		DATA_IP_PORT_OFFSET: out PortOffset;
		CORR_IP_PORT_OFFSET: out PortOffset;
		HOST_FRAME_READ_RATE: out std_logic_vector(4 downto 0);
		local_mac_addr: out std_logic_vector(47 downto 0);
		local_base_ip_addr: out std_logic_vector(31 downto 0);
		local_base_ip_port: out std_logic_vector(15 downto 0);
		local_subarray: out std_logic_vector(1 downto 0);
		remote_ip_port0: out std_logic_vector(15 downto 0);
		remote_mac_addr1: out std_logic_vector(47 downto 0);
		remote_ip_addr1: out std_logic_vector(31 downto 0);
		remote_ip_port1: out std_logic_vector(15 downto 0);

		-- Buck control signals

		buck_sync: out std_logic_vector(0 to NUMBER_OF_BUCK_SYNC_LINES-1);

		-- ARM SPI interface

		arm_spi_sck: in std_logic;
		arm_spi_miso: out std_logic;
		arm_spi_mosi: in std_logic;
		arm_spi_cs_n: in std_logic;

		-- Various unused signals, defined for testing

		arm_irq_in: in std_logic;
		arm_irq_out: out std_logic;
		arm_irq_oe: out std_logic;

		flash_cs_in: in std_logic;
		flash_cs_out: out std_logic;
		flash_cs_oe: out std_logic;

		gpio_irq_in: in std_logic;
		gpio_irq_out: out std_logic;
		gpio_irq_oe: out std_logic;  -- Active-high: enables GPIO reset output driver.

		gpio_rst_in: in std_logic;
		gpio_rst_out: out std_logic;
		gpio_rst_oe: out std_logic;  -- Active-high: enables GPIO reset output driver.

		uart_rx_in: in std_logic;
		uart_rx_out: out std_logic;
		uart_rx_oe: out std_logic;

		uart_tx_in: in std_logic;
		uart_tx_out: out std_logic;
		uart_tx_oe: out std_logic;

		-- FAN control signals (for on-board fan found on some evaluation boards)

		FAN_PWM: out std_logic; --! PWM control of the fan
		FAN_TACH: in std_logic; --! Tachymeter input from the fan (two pulses per revolution). A debouncer cleans this signal before measuring the fan frequency.
		FAN_TACH_DIV2: out std_logic; --! logic signal pulsing at half the fan rotation speed

		-- ADC mezzanine control signals

		ADC_RST: out std_logic_vector(0 to NUMBER_OF_ADC_BOARDS-1);
		adc_pll_lock: in std_logic_vector(0 to NUMBER_OF_ADC_BOARDS-1); --! Lock signal for the ADC PLL on each mezzanine

		-- LCD (on some evaluation boards)

		LCD_DB: out  std_logic_vector(7 downto 4);
		LCD_E : out  std_logic;
		LCD_RS : out  std_logic;
		LCD_RW : out  std_logic;

		-- Backplane signals

		-- Slot sensing system (measures capacitance on the sense line to identify the slot number)

		slot_probe: in std_logic_vector(1 downto 0); --! Signal used to probe the capacitance of the backplane slot-sense line
		slot_sense: in std_logic_vector( 1 downto 0); --! Returns the logic level change in response to the probe edge, which is used to determine the board capacitance.

		-- Backplane buck regulator synchronization signal

		bp_buck_sync: inout std_logic;
		bp_buck_sync_mon: out std_logic;

		-- Backplane global interrupt line

		bp_gpio_int_out: out std_logic;
		bp_gpio_int_in: in std_logic;
		bp_gpio_int_oe: out std_logic;

		-- UDP Communication link monitoring

		udp_tx_frame : in std_logic;
		udp_rx_frame : in std_logic;
		udp_tx_overflow : in std_logic;
		udp_rx_overflow : in std_logic;
		sfp_status_vector: in std_logic_vector(15 downto 0);

		cmd_packet_counter: in std_logic_vector(7 downto 0);
		rply_packet_counter: in std_logic_vector(7 downto 0);
		udp_stack_reset: out std_logic;
		ctrl_master_reset: out std_logic;

		-- General signals

		TRIG_ASYNC: out std_logic;

		-- Clocks

		clk200: in std_logic; --! 200 MHz clock, used for many things
		clk200_reset: in std_logic; --!
		clk10: in std_logic; --! 10 MHZ reference clock, in phase for every board in the system
		dna_clk: in std_logic; --! DNA port clock (max 97 MHz)

		-- PWM signal

		pwm_clk: in std_logic;
		pwm_ctr_en: in std_logic; -- Active when the pwm counter is to be enabled.
		pwm_reset: in std_logic;
		pwm_out: out std_logic;

		-- Event (Frame) counter

		event_ctr_clk: in std_logic;
		event_ctr_en: in std_logic;
		event_ctr_inc: in std_logic;
		event_ctr_reset: in std_logic;

		-- User output selection

		user_mux_in: in std_logic_vector(0 to NUMBER_OF_USER_SMA_SIGNALS-1); -- User selectable signals (typically PWM, 1PPS, SYNC, ?)
		user_mux_out: out std_logic_vector(0 to 3); -- User selected signal
		user_mux_oe: out std_logic_vector(0 to 3);
		user_bit: out std_logic_vector(1 downto 0);

		-- IRIG-B time

		irigb_mux_in: in std_logic_vector(0 to 7); -- IRIG-B time signals
		irigb_before_target: out std_logic;
		irigb_pps: out std_logic;
		irigb_out: out std_logic;
		irigb_delay: out std_logic_vector(4 downto 0); -- Delay to apply to the IRIG-B signals on the IOB
		irigb_delay_reset: out std_logic;

		-- Channelizer clock source selection

		CHAN_CLK_SOURCE: out std_logic;

		-- User-controlled global resets

		USER_RESET: out std_logic;
		ADCDAQ_RESET_ASYNC: out std_logic;
		CHAN_CLK_RESET_ASYNC: out std_logic;
		CHAN_RESET_ASYNC: out std_logic;
		CORR_RESET_ASYNC: out std_logic;
		BLINKER_RESET: out std_logic
	);
end GPIO;

architecture Behavioral of GPIO is

attribute async_reg : string;

--signal CLK: std_logic;
signal CLK_CTR: UNSIGNED(7 downto 0):=(others=>'0'); -- Divides the ADC clock by up to 255
signal CE: std_logic:='0';

signal firmware_timestamp: std_logic_vector(31 downto 0);
signal USER_DATA_VALID: std_logic;

--- Define Control word and its signals
signal CONTROL_BYTES: slv8_array(0 to 50); -- default value set in the CMD_SLAVE
signal STATUS_BYTES: slv8_array(0 to 37); -- default value set in the CMD_SLAVE

--signal CTRL_FLAG_ADC_RESET: std_logic;
signal CTRL_FLAG_BUCK_SYNC_ENABLE: std_logic;
signal CTRL_FLAG_ADCDAQ_RESET: std_logic;
signal CTRL_FLAG_GLOBAL_TRIG: std_logic;
signal CTRL_FLAG_BUCK_CLK_DIV: UNSIGNED(7 downto 0);
signal buck_sync_int: std_logic:='0';
signal buck_phase: std_logic_vector(NUMBER_OF_BUCK_SYNC_LINES*4-1 downto 0);
signal buck_phase_ctr: unsigned(3 downto 0):=(others=>'0'); -- Counts the 16 possible phasess. Initialized to avoid metata on '=' for simulations.

--signal CTRL_FLAG_TEST: std_logic_vector(3 downto 0);
--signal CHAN_RESET_ASYNC: std_logic;
--signal CORR_RESET_ASYNC: std_logic;

-- ARM-SPI interface
	signal spi_addr, spi_rdat, spi_wdat: std_logic_vector(31 downto 0) := (others => '0');
	signal spi_rreq, spi_rack, spi_wreq, spi_wack: std_logic := '0';

	constant NUMBER_OF_CORE_REGISTERS: integer := 23;
	signal core_reg_wr_value : work.icecore_package.slv32_array(0 to NUMBER_OF_CORE_REGISTERS-1);
	signal core_reg_rd_value : work.icecore_package.slv32_array(0 to NUMBER_OF_CORE_REGISTERS-1);
	constant core_reg_default_values : work.icecore_package.slv32_array(0 to NUMBER_OF_CORE_REGISTERS-1) := (
		7 => X"00000000", -- MAC
		8 => X"0000_0000", -- MAC, Port
		9 => X"00000000", -- IP
		others => X"00000000" );

-- -- ARM memory map process
-- 	-- Define module addresses
-- 	constant BASE_ADDR: integer := 0; -- Core Control register
-- 	constant NUMBER_OF_MODULES: integer := 1;

-- 	signal addr: unsigned(18 downto 0) := (others => '0');
-- 	signal addr_dly: unsigned(18 downto 0) := (others => '0');
-- 	signal din_dly: std_logic_vector(31 downto 0) := (others => '0');
-- 	-- Bus control signals for each module, packed into arrays
-- 	signal rreq, rack, wreq, wack: std_logic_vector(0 to NUMBER_OF_MODULES-1) := (others => '0');
-- 	signal dout: icecore_package.slv32_array(0 to NUMBER_OF_MODULES-1) := (others=> (others=>'0'));


-- Fan related signals
signal FAN_TACH_CTR: UNSIGNED(16 downto 0); --! the length of this counter sets the number of clk200 cycles  the debouncing waits before deciding that the state is stable
signal FAN_TACH_TARGET: std_logic :='0'; --!
signal FAN_TACH_DIV2_INT: std_logic :='0';

signal slot_probe_dly: std_logic_vector(1 downto 0);
signal slot_sense_ctr: slv8_array( 1 downto 0);

signal dna_dout: std_logic;
signal dna_read: std_logic :='1'; -- First clock is a read
signal dna_shift: std_logic := '1'; -- Will start shifting as soon as read is disabled
signal dna_ctr: unsigned(5 downto 0) := to_unsigned(57-1, 6); -- Will shift 57 times

signal firmware_crc32: std_logic_vector(31 downto 0);

signal fpga_serial_number: std_logic_vector(56 downto 0) := (others=>'0'); -- Need to initialize because we do not shift all the 64 bits
signal target_fpga_serial_number: std_logic_vector(56 downto 0);

signal target_local_subarray: std_logic_vector(1 downto 0);
signal target_load_trigger: std_logic;
signal target_load_trigger_dly: std_logic := '0';
signal target_local_mac_addr: std_logic_vector(47 downto 0);
signal target_network_config_source: std_logic_vector(1 downto 0);
signal target_local_base_ip_addr: std_logic_vector(31 downto 0);
signal target_local_base_ip_port: std_logic_vector(15 downto 0);

-- Network parameters from SPI registers
signal spi_fpga_ip_address: std_logic_vector(31 downto 0) := X"0A0A0A0B";
signal spi_fpga_ip_port: std_logic_vector(15 downto 0) := X"A028"; -- 41000
signal spi_fpga_mac_address: std_logic_vector(47 downto 0) := X"123456789ABC";
--signal udp_stack_reset: std_logic;
--signal ctrl_master_reset: std_logic;

signal local_mac_addr_int: std_logic_vector(47 downto 0);

-- Default Network settings -- Valid until new targets are loaded (requires the matching FPGA serial number in the TARGET_FPGA_SERIAN_NUMBER)
signal local_base_ip_addr_reg: std_logic_vector(31 downto 0) := X"0A0A0A0B";
signal local_base_ip_port_reg: std_logic_vector(15 downto 0) := X"A028"; -- 41000
signal local_network_config_source_reg: std_logic_vector(1 downto 0) := sel(SIM, "11", "00"); -- Normally Use SPI-based networking parameters, but use default local parameters if this is simulated
signal local_mac_addr_reg: std_logic_vector(47 downto 0) := X"123456789ABC";
signal local_subarray_reg: std_logic_vector(1 downto 0) := "00";

-- signal udp_tx_frame_ctr: unsigned(7 downto 0) := (others=>'0');
-- signal udp_rx_frame_ctr: unsigned(7 downto 0) := (others=>'0');

-- Mux signals
signal user_mux_source: slv4_array(0 to 3);

-- IRIG-B receiver

signal irig_source: std_logic_vector(2 downto 0) := "000";
-- signal irigb_out_int: std_logic;
-- signal irig_vect : std_logic_vector(0 to 3);
signal ts: irigb; -- Current time as obtained by the IRIG-B decoder
signal pps_ctr: unsigned(5 downto 0);
signal pps_int: std_logic;
signal pps_int_dly: std_logic;

signal ts_sample: irigb; -- Sampled time
signal event_ts_sample_trig: std_logic; -- Automatically generated by the event counter trigger (on the event_ctr_clk). Toggled on every trigger event.
signal event_ts_sample_trig_reg: std_logic; -- registers the trigger for the IRIGB time, from other clock domain. First stage of a synchronizer. Needs ASYNC_REG attribute.
signal event_ts_sample_trig_reg2: std_logic; -- second stage of the IRIG-B sampling trigger synchronizer. Needs ASYNC_REG attribute.
attribute ASYNC_REG of event_ts_sample_trig_reg: signal is "true";
attribute ASYNC_REG of event_ts_sample_trig_reg2: signal is "true";
signal event_ts_sample_trig_reg3: std_logic; -- Equals event_ts_sample_trig when the trigger has been processed.

signal refclk_ts_sample_trig: std_logic; -- Automatically generated by the event counter trigger (on the event_ctr_clk). Toggled on every trigger event.
signal refclk_ts_sample_trig_reg: std_logic; -- registers the trigger for the IRIGB time, from other clock domain. First stage of a synchronizer. Needs ASYNC_REG attribute.
signal refclk_ts_sample_trig_reg2: std_logic; -- second stage of the IRIG-B sampling trigger synchronizer. Needs ASYNC_REG attribute.
attribute ASYNC_REG of refclk_ts_sample_trig_reg: signal is "true";
attribute ASYNC_REG of refclk_ts_sample_trig_reg2: signal is "true";
signal refclk_ts_sample_trig_reg3: std_logic; -- Equals event_ts_sample_trig when the trigger has been processed.

signal ts_target: irigb; -- Target time used with the time comparator
signal ts_compare_enable: std_logic;
signal ts_force: std_logic;
signal ts_before_target: std_logic;

signal refclk_ctr: unsigned(63 downto 0);
signal refclk_sample: unsigned(63 downto 0);
signal target_refclk_count: unsigned(63 downto 0);
-- PWM signals
signal pwm_period: unsigned(31 downto 0);
signal pwm_high_time: unsigned(31 downto 0);
signal pwm_offset: unsigned(31 downto 0);
signal pwm_ctr: unsigned(31 downto 0);
signal pwm_active: std_logic;
signal pwm_out_int: std_logic;
signal pwm_soft_reset: std_logic;


-- Event counter and capture
signal event_ctr: unsigned(47 downto 0);
signal event_sample: unsigned(47 downto 0); -- Captured value
signal event_ctr_soft_reset: std_logic;

signal manual_event_sample_trig: std_logic;
signal manual_event_sample_trig_dly: std_logic; -- async
attribute async_reg of manual_event_sample_trig_dly: signal is "true";

signal event_sample_en: std_logic;
signal event_sample_arm: std_logic;
signal event_sample_done_int: std_logic;
signal event_sample_done: std_logic;
attribute async_reg of event_sample_done: signal is "true";

-- Reference clock counter capture logic
signal manual_refclk_sample_trig: std_logic; -- indicates when to capture the reference counter
signal manual_refclk_sample_trig_reg: std_logic; -- 1st stage of the synchronizer
attribute ASYNC_REG of manual_refclk_sample_trig_reg: signal is "true";
signal manual_refclk_sample_trig_reg2: std_logic; -- delayed version used to detect the rising edge and do clock synchronization (needs ASYNC_REG)
attribute ASYNC_REG of manual_refclk_sample_trig_reg2: signal is "true";
signal manual_refclk_sample_trig_reg3: std_logic;
signal refclk_sample_done: std_logic;
attribute async_reg of refclk_sample_done: signal is "true";
signal ts_sample_trig10: std_logic :='0';
signal ts_sample_trig10_ack: std_logic;
signal ts_sample_done: std_logic;

signal bp_buck_sync_wr_dat: std_logic_vector(31 downto 0);
signal bp_buck_sync_rd_dat: std_logic_vector(31 downto 0);
signal bp_buck_sync_rd_dat_valid: std_logic;

--signal release_ctr_mon: std_logic_vector(7 downto 0);
--signal sync_ctr_mon: std_logic_vector(7 downto 0);
begin

-----------------------------------------------------------------------------------
-- CONTROL and STATUS Bytes
-----------------------------------------------------------------------------------
--! \addtogroup memory_map
--! GPIO Module
--! =============
--!  -------------------------------------------------------------------
--! |  Page   | Addr|Bit(s)|     Name                    | Description |
--! |---------|-----|------|-----------------------------|-------------|
--! | CONTROL |  0  |  7   | CTRL_FLAG_GLOBAL_TRIG       | |
--! |         |     |  6   | CTRL_FLAG_BUCK_SYNC_ENABLE  | Enables the generation of the Buck switcher synchronization signals. If '0', all sync lines are held low to let the switcher free-run.|
--! |         |     |  5   | CHAN_CLK_RESET              | Resets the MMCM that generates the channelizer clocks |
--! |         |     |  4   | CHAN_CLK_SOURCE             | Selects the source of the channelizer clocks: 0: ADC clock, 1: 200 MHz system clock. CHAN_CLK_RESET or ADCDAQ_RESET must be asserted when doing the change to allow the MMCM to lock properly to the new clock.|
--! |         |     |  3   | ADCDAQ_RESET                | Resets all ADCDAQ modules. This also resets the channelizer clock MMCM, the channelizers and the correlators.|
--! |         |     |  2   | (unused)                    | |
--! |         |     | 1:0  | ADC_RESET                   | ADC RESET line (active High) for each FMC ADC boards (bit 0 is for ADC board 0, etc) |
--! |         |  1  | 7:0  | CTRL_FLAG_BUCK_CLK_DIV      | System clock frequency divider ratio used to set the buck sync frequency|
--! |         |  2  |  7   | LCD_E                       | LCD Enable |
--! |         |     |  6   | LCD_RS                      | LCD Command/Data flag|
--! |         |     |  5   | LCD_RW                      | LCD Read/Write flag|
--! |         |     |  4   | (unused)                    | |
--! |         |     | 3:0  | LCD_DB                      | LCD data bus ( 4 bits) |
--! |         |  3  |  7   | BLINKER_RESET               | |
--! |         |     |  6   | CHAN_RESET_ASYNC            | Resets all channelizers |
--! |         |     |  5   | CORR_RESET_ASYNC            | Resets all correlators |
--! |         |     |  4   | (unused)                    | |
--! |         |     | 3:2  | CORR_IP_PORT_OFFSET         | Sets the IP port number offset of the returned captured data relative to the base port |
--! |         |     | 1:0  | DATA_IP_PORT_OFFSET         | Sets the IP port number offset of the returned correlator data relative to the base port |
--! |         |  4  | 7:6  | CTRL_RPLY_IP_PORT_OFFSET    | Sets the IP port number offset of the command replies relative to the base port |
--! |         |     |  5   | (unused)                    | |
--! |         |     | 4:0  | HOST_FRAME_READ_RATE        | Indicates how often the host reads its UDP buffers in order to throttle the Ethernet output data rate. The read period is 2*(2^HOST_FRAME_READ_RATE)*(1/ctrl_clk) where CTRL lk is 125 MHz|
--! |         |5-12 | 63:0 | BUCK_PHASE                  | Phase of each of the 16 Buck sync lines. There are 16 possible phase values for each line. Bits 3:0 is for phase 0, bits 7:4 for phase 1 etc.|
--! |         |13-18| 47:0 | TARGET_LOCAL_MAC_ADDR       | MAC address to be used by the board if target_network_config_SOURCE="11" |
--! |         |19-22| 31:0 | TARGET_local_BASE_IP_ADDR   | Target IP address to be loaded if the target serial number matches the FPGA serial number and the trigger goes from 0 to 1  |
--! |         |23-24| 15:0 | TARGET_BASE_PORT            | Target base UDP port to be loaded when the target serial matches the FPGA serial and the trigger bit rises to 1. All commands,replies and data streams are relative to this port.  |
--! |         |25-32| 63:57| (unused)                    | |
--! |         |     | 56:0 | TARGET_FPGA_DNA             | Target FPGA serial number: the specified IP address and port will be loaded only if the target serial matches the actual serial number. |
--! |         |  33 | 7    | TARGET_load_TRIGGER         | When going from 0 to 1, loads the target IP ADDRESS/ IP PORT/ MAC_ADDRESS ans subarray *IF* the TARGET_FPGA_SERIAL match the actual FPGA serial|
--! |         |     | 6:4  | (unused)                    | |
--! |         |     | 3:2  | target_TARGET_local_MAC_ADDR_SOURCE   | Determines when and what IP address and port is loaded. '11' Always loads the programmed values. '10' Sets the address and port based on the FPGA DNA. '00' loads the programmed values only if the  FPGA serial number match the target value specified in the lower bits of this register |
--! |         |     | 1:0  | TARGET_local_SUBARRAY       | Subarray number. The value is latched when the target FPGA DNA serial number matches the actual FPGA DNA number.|
--! |         |34-37| 31:0 | pwm_offset                  | Number of events (frames) to delay before starting to generate the first High of the PWM output|
--! |         |38-41| 31:0 | pwm_high_time               | Number of events (frames) to keep the PWM output at High|
--! |         |42-45| 31:0 | pwm_pwriod                  | Number of events (frames) between PWM High (i.e PWM period)|
--! |         |  33 | 7    | pwm_soft_reset              | Software reset of the PWM module. Active high. |
--! |         |     | 7:3  | (unused)                    | |
--! |         |     | 2:0  | user_mux_source             | Selects which user source to send to the user output. |
--! | STATUS  |  0  |  7   | USER_DATA_VALID             | |
--! |         |     | 6:0  | COOKIE                      | |
--! |         |  1  | 7:0  | LOG2_FRAME_LENGTH           | |
--! |         |  2  | 7:0  | NUMBER_OF_CHANNELIZERS      | Number of antennas processing pipelines implemented in the firmware |
--! |         |  3  | 7:0  | NUMBER_OF_CORRELATORS       | Number of correlators implemented in the firmware |
--! |         |  4  | 7:0  | NUMBER_OF_CHANNELIZERS_TO_CORRELATE | Number of antennas connected to the correlators. Only antennas 0 to N-1 will be connected. This sets the numbe rof parallel multipliers and accumulators in the correlator. |
--! |         |  5  | 7:0  | NUMBER_OF_CHANNELIZERS_WITH_FFT   | Indicates how many channelizers have a FFT module. Those will be channeizers 0 to N-1|
--! |         |  6  | 7:0  | NUMBER_OF_GPU_LINKS         | Indicates how GPU Links are implemented. If zero, the GPU module is not present at all (not even the common registers)|
--! |         | 7-10| 31:0 | firmware_timestamp                   | 32-bit word containing the timestamp of the firmware inserted during the bitgen process |
--! |         | 11  | 7:0  | PLATFORM_ID                 | Type of platform on which the firmware is running. 0=ML605, 1=KC705 |
--! |         |12-19| 63:57| (unused)                    |   |
--! |         |     | 56:0 | FPGA_DNA                    | FPGA unique serial number |
--! |         | 20  | 7:0  | NUMBER_OF_CROSSBAR_INPUTS   | Indicates how many channelizers are connected to the crossbar inputs. Those will be channeizers 0 to N-1|
--! |         | 21  | 7:0  | NUMBER_OF_CROSSBAR_OUTPUTS  | Indicates the number of crossbar outputs. Those outputs feed the GPU links and the FPGA correlators (if implemented).
--! |         |22-23| 15:0 | PROTOCOL_VERSION            | 16-bit value indicating the protocol version. A change in the version means that some change is needed on host control software. |
--! |         | 24  | 7:0  | CHANNELIZERS_CLOCK_SOURCE   | ADC channel from which the channelizer clocks are derived. Useful to know if we should expect the clock to be missing and use alternate internal clock.
--!  ------------------------------------------------------------------------------
--!
-- CONTROL Byte 0
CTRL_FLAG_GLOBAL_TRIG      <= CONTROL_BYTES(0)(7);
CTRL_FLAG_BUCK_SYNC_ENABLE <= CONTROL_BYTES(0)(6);
CHAN_CLK_RESET_ASYNC       <= CONTROL_BYTES(0)(5);
CHAN_CLK_SOURCE            <= CONTROL_BYTES(0)(4);
ADCDAQ_RESET_ASYNC         <= CONTROL_BYTES(0)(3);
ADC_RST                    <= reverse_bits_and_dir(CONTROL_BYTES(0)(NUMBER_OF_ADC_BOARDS-1 downto 0));


-- CONTROL Byte 1
CTRL_FLAG_BUCK_CLK_DIV <= UNSIGNED(CONTROL_BYTES(1));

-- CONTROL Byte 2
LCD_E  <= CONTROL_BYTES(2)(7);
LCD_RS <= CONTROL_BYTES(2)(6);
LCD_RW <= CONTROL_BYTES(2)(5);
LCD_DB <= CONTROL_BYTES(2)(3 downto 0);

-- CONTROL Byte 3
USER_RESET <='0';
BLINKER_RESET       <= CONTROL_BYTES(3)(7);
CHAN_RESET_ASYNC     <= CONTROL_BYTES(3)(6);
CORR_RESET_ASYNC    <= CONTROL_BYTES(3)(5);
-- unused bit 4
CORR_IP_PORT_OFFSET <= CONTROL_BYTES(3)(3 downto 2);
DATA_IP_PORT_OFFSET <= CONTROL_BYTES(3)(1 downto 0);

-- CONTROL Byte 4
CTRL_RPLY_IP_PORT_OFFSET<= CONTROL_BYTES(4)(7 downto 6);
HOST_FRAME_READ_RATE    <= CONTROL_BYTES(4)(4 downto 0);

-- CONTROL bytes 5-12
BUCK_PHASE <= to_slv(CONTROL_BYTES(5 to 12));


-- CONTROL bytes 13-18
target_local_mac_addr <= to_slv(CONTROL_BYTES(13 to 18));

-- CONTROL bytes 19-22
target_local_base_ip_addr <= to_slv(CONTROL_BYTES(19 to 22));

-- CONTROL bytes 23-24
target_local_base_ip_port <= to_slv(CONTROL_BYTES(23 to 24));

-- CONTROL bytes 25-32
target_fpga_serial_number(56) <= CONTROL_BYTES(25)(0);
target_fpga_serial_number(55 downto 0) <= to_slv(CONTROL_BYTES(26 to 32));

-- CONTROL byte 33
target_load_trigger          <= CONTROL_BYTES(33)(7);
target_network_config_source <= CONTROL_BYTES(33)(3 downto 2);
target_local_subarray        <= CONTROL_BYTES(33)(1 downto 0);

-- CONTROL byte 34-37, 38-41, 42-45
pwm_offset <= to_unsigned(CONTROL_BYTES(34 to 37));
pwm_high_time <= to_unsigned(CONTROL_BYTES(38 to 41));
pwm_period <= to_unsigned(CONTROL_BYTES(42 to 45));

-- CONTROL byte 46
pwm_soft_reset <= CONTROL_BYTES(46)(7);
bp_gpio_int_oe <= CONTROL_BYTES(46)(4);
user_mux_source(0) <= CONTROL_BYTES(46)(3 downto 0);

-- CONTROL byte 47

uart_tx_oe   <= CONTROL_BYTES(47)(7);
uart_tx_out  <= CONTROL_BYTES(47)(6);
uart_rx_oe   <= CONTROL_BYTES(47)(5);
uart_rx_out  <= CONTROL_BYTES(47)(4);
gpio_rst_oe  <= CONTROL_BYTES(47)(3);
arm_irq_out  <= CONTROL_BYTES(47)(0);
gpio_rst_out <= CONTROL_BYTES(47)(2);
arm_irq_oe   <= CONTROL_BYTES(47)(1);

-- CONTROL byte 48
user_mux_source(3) <= CONTROL_BYTES(48)(7 downto 4);
gpio_irq_oe        <= CONTROL_BYTES(48)(3);
gpio_irq_out       <= CONTROL_BYTES(48)(2);
flash_cs_oe        <= CONTROL_BYTES(48)(1);
flash_cs_out       <= CONTROL_BYTES(48)(0);


-- CONTROL byte 49
user_mux_source(2) <= CONTROL_BYTES(49)(7 downto 4);
user_mux_source(1) <= CONTROL_BYTES(49)(3 downto 0);

-- CONTROL byte 50
user_bit(1)       <= CONTROL_BYTES(50)(7);
user_bit(0)       <= CONTROL_BYTES(50)(6);
irigb_delay_reset <= CONTROL_BYTES(50)(5);
irigb_delay       <= CONTROL_BYTES(50)(4 downto 0);

-- STATUS Byte 0
STATUS_BYTES(0)(7)          <= USER_DATA_VALID;
STATUS_BYTES(0)(6 downto 0) <= to_slv(COOKIE, 7);

-- STATUS Byte 1
STATUS_BYTES(1) <= to_slv(LOG2_FRAME_LENGTH,8);

-- STATUS Byte 2
STATUS_BYTES(2) <= to_slv(NUMBER_OF_CHANNELIZERS, 8);

-- STATUS Byte 3
STATUS_BYTES(3) <= to_slv(NUMBER_OF_CORRELATORS,8);

--STATUS_BYTES(3)(7 downto 4) <= (others=>'0');

--STATUS Byte 4
STATUS_BYTES(4) <= to_slv(NUMBER_OF_CHANNELIZERS_TO_CORRELATE, 8);
STATUS_BYTES(5) <= to_slv(NUMBER_OF_CHANNELIZERS_WITH_FFT,8);
STATUS_BYTES(6) <= to_slv(NUMBER_OF_GPU_LINKS,8);

-- bitgen: for i in 0 to 7 generate
-- -- 	STATUS_BYTES(4)(i)<='1' when IMPLEMENT_ANT(i)=TRUE else '0';
-- 	STATUS_BYTES(5)(i)<='1' when IMPLEMENT_FFT(i+8)=TRUE else '0';
-- 	STATUS_BYTES(6)(i)<='1' when IMPLEMENT_FFT(i)=TRUE else '0';
-- end generate;

-- STATUS Bytes 7-10
STATUS_BYTES(7 to 10) <= to_slv8_array(firmware_timestamp);

-- STATUS Bytes 11
STATUS_BYTES(11)<=to_slv(PLATFORM_ID,8);

-- STATUS Bytes 12-15
STATUS_BYTES(12)(7 downto 1) <= (others=>'0');
STATUS_BYTES(12)(0) <= fpga_serial_number(56);
STATUS_BYTES(13 to 19) <= to_slv8_array(fpga_serial_number(55 downto 0));

STATUS_BYTES(20) <= to_slv(NUMBER_OF_CROSSBAR_INPUTS, 8);
STATUS_BYTES(21) <= to_slv(NUMBER_OF_CROSSBAR_OUTPUTS, 8);

STATUS_BYTES(22 to 23) <= to_slv8_array(to_slv(PROTOCOL_VERSION, 16));
STATUS_BYTES(24) <= to_slv(CHANNELIZERS_CLOCK_SOURCE, 8);
-- Connect signals to module ports

-- STATUS Bytes 25-30
STATUS_BYTES(25 to 30) <= to_slv8_array(local_mac_addr_int);

-- STATUS Bytes 31-32
STATUS_BYTES(31) <= slot_sense_ctr(0);
STATUS_BYTES(32) <= slot_sense_ctr(1);

-- STATUS Bytes 33-35
STATUS_BYTES(33)(7 downto 8-NUMBER_OF_ADC_BOARDS) <= reverse_bits_and_dir(adc_pll_lock);
STATUS_BYTES(33)(5 downto 2) <= (others=>'0');
STATUS_BYTES(33)(1) <= udp_tx_overflow;
STATUS_BYTES(33)(0) <= udp_rx_overflow;

STATUS_BYTES(34) <= cmd_packet_counter;
STATUS_BYTES(35) <= rply_packet_counter;

STATUS_BYTES(36) <= to_slv(NUMBER_OF_BP_SHUFFLE_LINKS, 8);
-- STATUS_BYTES(36)(1) <= bp_shuffle_lock(1);

--ADC_RST<=CTRL_FLAG_ADC_RESET;

--CLK<=ADC_CLK; -- select clock to use for Buck SYNC generation

STATUS_BYTES(37)(0) <= arm_irq_in;
STATUS_BYTES(37)(1) <= gpio_rst_in;
STATUS_BYTES(37)(2) <= uart_rx_in;
STATUS_BYTES(37)(3) <= uart_tx_in;
STATUS_BYTES(37)(4) <= flash_cs_in;
STATUS_BYTES(37)(5) <= gpio_irq_in;
STATUS_BYTES(37)(6) <= bp_gpio_int_in;


-----------------------------------------------------------------------------------
-- Memory-Mapped interface
-----------------------------------------------------------------------------------
--! Instantiates a memory-mapped interface to the control and status bytes
CTRL_SLAVE0: entity work.CTRL_SLAVE
	GENERIC MAP (
		NUMBER_OF_CONTROL_BYTES=>CONTROL_BYTES'Length(1), -- Length of array in the first dimension: number of bytes
		NUMBER_OF_STATUS_BYTES=>STATUS_BYTES'Length(1),
		DEFAULT_CONTROL_BYTES=> (X"50" & to_slv(BUCK_CLK_DIVIDE_FACTOR,8) & X"00_65_14_FEDCBA9876543210_000000000000_00000000_A028_0000000000000000_00_00000000_0002faf0_0005f5e1_00_00_00_89_00")
	)
	PORT MAP(
		-- Control interface (command and reply stream buses)
		ctrl_cmd_in_dat => ctrl_cmd_in_dat,
		ctrl_cmd_in_rdy => ctrl_cmd_in_rdy,
		ctrl_rply_out_dat => ctrl_rply_out_dat,
		ctrl_rply_out_rdy => ctrl_rply_out_rdy,
		ctrl_clk => ctrl_clk,
		ctrl_rst => ctrl_rst,

		CONTROL_BYTES => CONTROL_BYTES,
		STATUS_BYTES => STATUS_BYTES,
		CLK => ctrl_clk, -- 110909 JFC: Was CLK (ADC_CLK), but did not work because SYNC stops the ADC CLK...
		RST => ctrl_rst
	);


	arm_spi0: entity work.arm_spi port map (
		-- SPI interface
		sck => arm_spi_sck,
		miso => arm_spi_miso,
		mosi => arm_spi_mosi,
		cs_n => arm_spi_cs_n,

		-- Master bus interface
		m_addr => spi_addr,
		m_rdat => spi_rdat,
		m_wdat => spi_wdat,
		m_rreq => spi_rreq,
		m_rack => spi_rack,
		m_wreq => spi_wreq,
		m_wack => spi_wack,

		clk => ctrl_clk,
		reset => '0' -- redundant; cs_n does the same thing

	);


-------------------------
-- Core Register assignments
-------------------------
-- Register write values

-- Register Read values
-- Registers 0-2
core_reg_rd_value(0) <= x"beefface"; -- (Read only) Core firmware cookie
core_reg_rd_value(1) <= to_slv(COOKIE, 32); -- (Read only) Application firmware cookie
core_reg_rd_value(2) <= X"00000000"; -- (Read only) Application Flags: Kintex 7

-- Register 3
core_reg_rd_value(3) <= firmware_crc32; -- (Read/Write with readback) Firmware CRC32, computed by the host application and stored here for future reference
firmware_crc32       <= core_reg_wr_value(3);

-- Registers 4-6
core_reg_rd_value(4) <= firmware_timestamp; -- (Read only) Firmware timestamp, taken from the USER_ACCESS data filled in when the bitstream file was generated
core_reg_rd_value(5) <= fpga_serial_number(31 downto 0); -- (Read only)
core_reg_rd_value(6) <= "0000000" & fpga_serial_number(56 downto 32); -- (Read only)

-------------------------
-- Application-specific registers
-------------------------

-- Networking configuration
-------------------------
-- Register 7
core_reg_rd_value(7)               <= spi_fpga_mac_address(31 downto 0); -- (Read/Write with readback)
spi_fpga_mac_address(31 downto 0)  <= core_reg_wr_value(7);
-- Register 8
core_reg_rd_value(8)               <= spi_fpga_mac_address(47 downto 32) & spi_fpga_ip_port; -- (Read/Write with readback)
spi_fpga_mac_address(47 downto 32) <= core_reg_wr_value(8)(31 downto 16);
spi_fpga_ip_port                   <= core_reg_wr_value(8)(15 downto 0);
-- Register 9
core_reg_rd_value(9)               <= spi_fpga_ip_address; -- (Read/Write with readback)
spi_fpga_ip_address                <= core_reg_wr_value(9);

-- IRIG-B timestamp registers
-------------------------
-- Register 10 (_IRIGB_SAMPLE0_ADDR)
core_reg_rd_value(10)(31 downto 26) <= to_slv(pps_ctr); -- (Read only)
core_reg_rd_value(10)(25 downto 8)  <= ts_sample.sbs; -- (Read only)
core_reg_rd_value(10)(7 downto 0)   <= to_slv(ts_sample.y); -- (Read only)
-- Register 11 (_IRIGB_SAMPLE1_ADDR)
core_reg_rd_value(11)(31 downto 30) <= to_slv(ts_sample.source(1 downto 0)); -- (Read only)
core_reg_rd_value(11)(29)           <= ts_sample.recent; -- (Read only)
core_reg_rd_value(11)(28 downto 20) <= to_slv(ts_sample.d); -- (Read only)
core_reg_rd_value(11)(19 downto 14) <= to_slv(ts_sample.h); -- (Read only)
core_reg_rd_value(11)(13 downto 7)  <= to_slv(ts_sample.m); -- (Read only)
core_reg_rd_value(11)(6 downto 0)   <= to_slv(ts_sample.s); -- (Read only)
-- Register 12 (_IRIGB_SAMPLE2_ADDR)
core_reg_rd_value(12)(31 downto 30) <= irig_source(1 downto 0); -- (Read/Write with readback)
core_reg_rd_value(12)(29)           <= manual_refclk_sample_trig; -- (Read/Write with readback)
core_reg_rd_value(12)(28)           <= manual_event_sample_trig; -- (Read/Write with readback)
core_reg_rd_value(12)(27 downto 0)  <= to_slv(ts_sample.ss); -- (Read only)
irig_source(1 downto 0)             <= core_reg_wr_value(12)(31 downto 30);
manual_refclk_sample_trig           <= core_reg_wr_value(12)(29);
manual_event_sample_trig            <= core_reg_wr_value(12)(28);
-- Register 13 (_IRIGB_TARGET0_ADDR)
core_reg_rd_value(13)(31)          <= irig_source(2); -- (Read/Write with readback)
core_reg_rd_value(13)(7 downto 0)  <= core_reg_wr_value(13)(7 downto 0); -- (Readback)
ts_target.y                        <= unsigned(core_reg_wr_value(13)(7 downto 0));
irig_source(2)                     <= core_reg_wr_value(13)(31);
-- Register 14 (_IRIGB_TARGET1_ADDR)
core_reg_rd_value(14)(31)          <= ts_before_target; -- (Read-only)
core_reg_rd_value(14)(30)          <= event_sample_done; -- (Read only)
core_reg_rd_value(14)(29)          <= refclk_sample_done; -- (Read-only)
core_reg_rd_value(14)(28 downto 0) <= core_reg_wr_value(14)(28 downto 0); -- (Readback)
ts_target.d                        <= unsigned(core_reg_wr_value(14)(28 downto 20));
ts_target.h                        <= unsigned(core_reg_wr_value(14)(19 downto 14));
ts_target.m                        <= unsigned(core_reg_wr_value(14)(13 downto 7));
ts_target.s                        <= unsigned(core_reg_wr_value(14)(6 downto 0));
-- Register 15 (_IRIGB_TARGET2_ADDR)
core_reg_rd_value(15)(31)          <= ts_compare_enable; -- (Readback)
core_reg_rd_value(15)(30)          <= ts_force; -- (Readback)
core_reg_rd_value(15)(27 downto 0) <= core_reg_wr_value(15)(27 downto 0); -- (Readback)
ts_target.ss                       <= unsigned(core_reg_wr_value(15)(27 downto 0));
ts_compare_enable                  <= core_reg_wr_value(15)(31);
ts_force                           <= core_reg_wr_value(15)(30);
-- Register 16 (_IRIGB_EVENT_CTR_ADDR)
core_reg_rd_value(16) <= std_logic_vector(event_sample(31 downto 0)); -- (Read-only)

-- Registers 17 (_IRIGB_EVENT_CTR_ADDR2)
core_reg_rd_value(17)(15 downto 0) <= std_logic_vector(event_sample(47 downto 32)); -- (read-only)
core_reg_rd_value(17)(31 downto 16) <= (others=>'0'); -- (read-only)

--core_reg_rd_value(17)(31 downto 16) <= bp_buck_sync_wr_dat(31 downto 16); -- readback
--core_reg_rd_value(17)(15 downto 8)  <= release_ctr_mon; --unused
--core_reg_rd_value(17)(7 downto 0)   <= sync_ctr_mon; --unused

-- Registers 18 (_BP_BUCK_SYNC_ADDR2)

bp_buck_sync_wr_dat                 <= core_reg_wr_value(18); -- write-only
core_reg_rd_value(18)(31)           <= bp_buck_sync_rd_dat_valid; -- (Read-only)
core_reg_rd_value(18)(30 downto 0)  <= bp_buck_sync_rd_dat(30 downto 0); -- (Read-only)

-- Register 19 (_SFP_STATUS_ADDR)
core_reg_rd_value(19)(31 downto 18) <= core_reg_wr_value(19)(31 downto 18); -- (readback)
core_reg_rd_value(19)(17)           <= udp_tx_overflow; -- (Read only)
core_reg_rd_value(19)(16)           <= udp_rx_overflow; -- (Read only)
core_reg_rd_value(19)(15 downto 0)  <= sfp_status_vector; -- (Read-only)
udp_stack_reset                     <= core_reg_wr_value(19)(31);
ctrl_master_reset                   <= core_reg_wr_value(19)(30);

-- Register 20 (_REMOTE_IP_PORT_ADDR)
remote_ip_port0                 <= core_reg_wr_value(20)(15 downto 0);
remote_ip_port1                 <= core_reg_wr_value(20)(31 downto 16);
core_reg_rd_value(20)           <= core_reg_wr_value(20); -- (Readback)

-- Register 21 (_IRIGB_REFCLK_SAMPLE)
core_reg_rd_value(21)           <= std_logic_vector(refclk_sample(31 downto 0)); -- read
target_refclk_count(31 downto 0) <= unsigned(core_reg_wr_value(21));
-- Register 22 (_IRIGB_REFCLK_SAMPLE2)
core_reg_rd_value(22)           <= std_logic_vector(refclk_sample(63 downto 32)); -- read
target_refclk_count(63 downto 32) <= unsigned(core_reg_wr_value(21));

core_regs0: entity work.register_array
	generic map(
		ADDRESS_MASK => X"000000" & "------XX",
		NUMBER_OF_REGISTERS => NUMBER_OF_CORE_REGISTERS,
		DEFAULT_REGISTER_VALUES => core_reg_default_values,
		ADDRESS_WIDTH => 32,
		SIM => False --! Indicates this is running as a simulation. Used to accelerate simulations
	)
	port map (
		-- Control interface (*** JFC: to be replaced by an AXI4-Lite bus)
		s_addr => spi_addr,
		s_wdat => spi_wdat,
		s_rdat => spi_rdat,
		s_wreq => spi_wreq,
		s_wack => spi_wack,
		s_rreq => spi_rreq,
		s_rack => spi_rack,

		-- Register interface
		reg_wr_value  => core_reg_wr_value,
		reg_rd_value  => core_reg_rd_value,

		clk => ctrl_clk -- Clocks both control and register interface
	);

-----------------------
-- IRIG-B decoder
-----------------------
-- irig_vect <=  sync_in & time_in & '0' & '0'; -- Combine all irig signal source in a single vector

irigb_decoder0 : entity work.irigb_decoder
	port map (
		clk_200mhz => clk200,
		irig       => irigb_mux_in,
		source     => unsigned(irig_source),
		pps        => pps_int,
		ts         => ts
	);

irigb_before_target <= ts_before_target;
irigb_comparator0: entity work.irigb_comparator
	port map (
		current_ts    => ts,
		target_ts     => ts_target,
		compare_en    => ts_compare_enable,
		force         => ts_force,
		before_target => ts_before_target, -- Is '1' when current time is before the target time, and '0' when it is equal of after. There is 7 clocks latency compared to current time input.
		clk_200mhz    => clk200
	);

irigb_encoder0: entity work.irigb_encoder
	port map (
		clk_200mhz => clk200,
		ts_out => irigb_out
	);


irigb_pps <= pps_int;
-----------------------
-- IRIG-B Time capture
-----------------------
--
-- This process is used to capture the IRIG-B time and count the PPS pulses.
-- IRIG-B capture is triggered either by capturing the reference clock counter
-- or by capturing the event/frame event.
--
-- `event_ts_sample_trig` is handled by the event/frame capture logic, which operates
-- on on the event_ctr_clk (chan_clk(0), 200 MHz derived from the ADC or
-- multi-phase PLL).
--
--
-- ts_sample_trig10 is handled by the refclk counter capture logic, which is
-- clocked on clk10.
--
-- This process operates in the clk200 clock domain. Ultimately all the
-- trigger clocks are derived from clk10, but they have an unknown phase. So
-- he have to deal with clock domain crossing on the trigger.
--
-- Triggering is done by inverting the state of `event_ts_sample_trig` or
-- `ts_sample_trig10`. The capture is done when  the signal differ from the
-- correspnding acknowledge bit. The acknowledge bit is then set to the
-- trigger signal to indicate that the caapture is done.
--
-- Note that the acknowledge signals are on clk200, not on the clock of their
-- corresponding trigger.
--
irigb_ctr_proc: process(clk200)
	begin
		if rising_edge(clk200) then

			-- Count the pps pulses on the rising edge of the PPS signal. This
			-- is used mainly for debugging. This counter is never resetted.
			pps_int_dly <= pps_int;
			if pps_int='1' and pps_int_dly='0' then
				pps_ctr <= pps_ctr + 1;
			end if;

			-- Resynchronize the capture trigger signal before using it to
			-- enable capture the timestamp -- otherwise we randomly miss
			-- bits. We use a two-stage synchronizer to ensure we deal with
			-- metastable conditions. These registers are marked with the
			-- ASYNC_REG attribute.
			--event_ts_sample_trig_reg <= to_std_logic(event_ts_sample_trig /= ts_sample_trig_ack or
			--                ts_sample_trig10 /= ts_sample_trig10_ack);

			-- Synchronize trigger from the chan_clk domain
			event_ts_sample_trig_reg <= event_ts_sample_trig; -- first synchronizer register
			event_ts_sample_trig_reg2 <= event_ts_sample_trig_reg; -- second synchronizer register
			event_ts_sample_trig_reg3 <= event_ts_sample_trig_reg2; -- reg3 equals reg2 when sampling is done

			-- Synchronize trigger from the clk10 domain
			refclk_ts_sample_trig_reg <= refclk_ts_sample_trig; -- first synchronizer register
			refclk_ts_sample_trig_reg2 <= refclk_ts_sample_trig_reg; -- second synchronizer register
			refclk_ts_sample_trig_reg3 <= refclk_ts_sample_trig_reg2;

			if event_ts_sample_trig_reg2 /= event_ts_sample_trig_reg3 or
			   refclk_ts_sample_trig_reg2 /= refclk_ts_sample_trig_reg3 then
				ts_sample <= ts; -- register the current IRIG-B time
			end if;

		end if;  -- if clk200
	end process;

--------------------------------
-- Event (frame) counter capture
--------------------------------
--! On the rising edge of manual_event_sample_trig, we arm the trigger. When the end
--! of frame is detected, we enable the sampling to capture the frame counter
--! and the timestamp on the first sample of the nest frame. The capture is
--! also enabled after reset so we capture the time of the first word of the
--! first frame after reset.
--!
--! Typically:
--!    event_ctr_en <= axis_adc_tvalid(0);
--!    event_ctr_inc <= axis_adc_tlast(0);
--
event_proc: process(event_ctr_clk)
	begin
		if rising_edge(event_ctr_clk) then

			-- Capture the event info
			if event_ctr_en='1' then -- when tvalid=1
				-- Count events
				if event_ctr_inc='1' then
					event_ctr <= event_ctr + 1;
				end if;
				-- Sample event
				event_sample_en <= '0'; -- Single clock pulse. Overriden below.
				if event_sample_en='1' then
					event_sample <= event_ctr;
					event_sample_done_int <= '1';
					event_ts_sample_trig <= not event_ts_sample_trig; -- cause a transition to indicate that the timestamp should be sampled now
				end if;
			end if;


			if manual_event_sample_trig='0' then
				event_sample_done_int <= '0';
			end if;

			event_sample_done <= to_std_logic(event_sample_done_int='1' and event_ts_sample_trig_reg2 = event_ts_sample_trig_reg3);

			-- Arm the sampling at the rising edge of manual_event_sample_trig
			manual_event_sample_trig_dly <= manual_event_sample_trig;
			if manual_event_sample_trig='1' and manual_event_sample_trig_dly='0' then
				event_sample_arm <= '1';
			elsif event_sample_arm = '1' and event_ctr_en = '1' and event_ctr_inc='1' then
				event_sample_arm <= '0';
				event_sample_en <= '1';
			end if;

			if event_ctr_reset='1' or event_ctr_soft_reset='1' then
				event_ctr <= (others=>'0');
				event_sample_arm <= '0';
				event_sample_en <= '1'; -- sample the first incoming frame after reset
			end if;
		end if; --CLK
	end process;

--------------------------------------
-- 10 MHz reference clock time capture
--------------------------------------
-- Count the reference clock cycles and capture the current count on the
-- rising edge of `manual_refclk_sample_trig`. A reference counter capture also
-- automaatically triggers the IRIB-time capture.
--
-- The 10 MHz clock cycles in a free-running counter. This is our
-- internal time reference, independent from the data frames, and is not
-- affected by sync. The 10 MHz clock might come from a maser, and is not
-- necessarily perfectly aligned to the IRIG-B time that is sent by the GPS.
--
-- The process also capture the current reference clock counter and IRIG-B
-- when a rising edge is seen on `manual_refclk_sample_trig`. `refclk_sample_done`
-- will go high (on the clk10 clock) when the IRIG-B has finished sampling
-- both the counter AND the IRIG-B (sampling the counter is instantaneous so
-- we don`t have to worry about synchronizing this one). Note that this does
-- not guarantee that the IRIG-B is valid, just that the timestamp was
-- registered properly and is stable and ready for reading. You have to check
-- the timestamp flags to check if the time was updated lately.
--
-- To be clear: the capture is done at any time - it is not synchronized to a frame/event.
--
-- The IRIG-B sampling happens a few clocks after the counte capture due to the synchronization regitering.
-- This can be used to obtain a correspondance between the maser time (as
-- represented by the reference counter) and the GPS time (as obtained by the
-- IRIG-B capture)
--
refclk_capture_proc: process(clk10)
	begin
		if rising_edge(clk10) then
			-- Count the 10 MHz clocks continuously
			refclk_ctr <= refclk_ctr + 1;

			-- detect the target condition
			-- refclk_sync_trig <= to_std_logic(refclk_ctr = target_refclk_count);

			-- Capture the counter value on the rising edge of `manual_refclk_sample_trig`.
			-- Manual trigger (edge sensitive, as it is driven by a slow process)
			-- This automatically triggers capture of the IRIG-B time (about 2xclk200 later)`
			manual_refclk_sample_trig_reg <= manual_refclk_sample_trig; -- two stage synchronizer
			manual_refclk_sample_trig_reg2 <= manual_refclk_sample_trig_reg;
			manual_refclk_sample_trig_reg3 <= manual_refclk_sample_trig_reg2;
			if manual_refclk_sample_trig_reg2='1' and manual_refclk_sample_trig_reg3='0' then
				refclk_sample <= refclk_ctr; -- register the current counter
				refclk_ts_sample_trig <= not refclk_ts_sample_trig; -- triggers the sampling of the IRIG-B time
				refclk_sample_done <= '0';
			else
				refclk_sample_done <= to_std_logic(refclk_ts_sample_trig_reg3 = refclk_ts_sample_trig); -- reg3 is not synchronous to clk10, but that's just for a flag
			end if;
			-- Event-based trigger (sync or start of frame) (level-sensitive)
			--event_refclk_sample_trig_reg <= event_refclk_sample_trig; -- two stage synchronizer
			--event_refclk_sample_trig_reg2 <= event_refclk_sample_trig_reg;
			--event_refclk_sample_trig_ack <= event_refclk_sample_trig_reg2; --
			--if event_refclk_sample_trig_reg2 /= event_refclk_sample_trig_ack then
			--	refclk_sample <= refclk_ctr; -- register the current counter
			--end if;
		end if; --CLK
	end process;


--! User muxed output selection
user_gen: for i in 0 to 3 generate
	user_mux_out(i) <= user_mux_in(to_integer(unsigned(user_mux_source(i))));
	user_mux_oe(i) <= '0' when signed(user_mux_source(i)) = -1 else '1';
end generate;

--! Implement USR_ACCESS for VIRTEX6-based platforms
USRACCESS_V6: if FPGA_SERIES_LIST(PLATFORM_ID)=6 generate
	USR_ACCESS0: USR_ACCESS_VIRTEX6
		port map(
			CFGCLK    => open,--1-bit Configuration Clock output
			DATA      => firmware_timestamp,--32-bit Configuration Data output
			DATAVALID => USER_DATA_VALID--1-bit Active high data validoutput
			);
end generate;

--! Implement USR_ACCESS for 7-series platforms
USRACCESS_7: if FPGA_SERIES_LIST(PLATFORM_ID)=7 generate
	USR_ACCESS0: USR_ACCESSE2
		port map(
			CFGCLK    => open, --1-bit Configuration Clock output
			DATA      => firmware_timestamp, --32-bit Configuration Data output
			DATAVALID => USER_DATA_VALID --1-bit Active high data validoutput
			);
end generate;

dna0 : DNA_PORT
	generic map (
		SIM_DNA_VALUE => X"000000000000000" -- Specifies a sample 57-bit DNA value for simulation
	)
	port map (
		DOUT => dna_dout, -- 1-bit output: DNA output data.
		CLK => dna_clk, -- 1-bit input: Clock input.
		DIN => '0', -- 1-bit input: User data input pin.
		READ => dna_read, -- 1-bit input: Active high load DNA, active low read input.
		SHIFT => dna_shift -- 1-bit input: Active high shift enable input.
	);

-- Read the 57-bit DNA
dna_proc: process(dna_clk)
	begin
		if rising_edge(dna_clk) then
			dna_read <='0';
			if dna_read='0' and dna_shift='1' then -- when data is ready and we have not finished shifting
				fpga_serial_number <= std_logic_vector(shift_left(unsigned(fpga_serial_number), 1));
				fpga_serial_number(0) <= dna_dout;
				dna_ctr <= dna_ctr - 1;
				if dna_ctr = 0 then
					dna_shift <= '0';
				end if;
			end if;
		end if;
	end process;


-- comm_mon_proc: process(ctrl_clk)
-- 	begin
-- 		if rising_edge(ctrl_clk) then
-- 			if udp_rx_frame='1' then
-- 				udp_rx_frame_ctr <= udp_rx_frame_ctr + 1;
-- 			end if;
-- 			if udp_tx_frame='1' then
-- 				udp_tx_frame_ctr <= udp_tx_frame_ctr + 1;
-- 			end if;
-- 		end if;
-- 	end process;

network_setup_proc: process(ctrl_clk)
	begin
		if rising_edge(ctrl_clk) then

			-- Load broadcasted networking parameters if the previously received FPGA serial number match our own
			target_load_trigger_dly <= target_load_trigger;
			if target_load_trigger='1' and target_load_trigger_dly='0' and fpga_serial_number = target_fpga_serial_number then
				local_network_config_source_reg <= target_network_config_source;
				local_base_ip_addr_reg          <= target_local_base_ip_addr;
				local_base_ip_port_reg          <= target_local_base_ip_port;
				local_mac_addr_reg              <= target_local_mac_addr;
				local_subarray_reg              <= target_local_subarray;
			end if;


			-- Select which networking parameters to use
			case local_network_config_source_reg is
				when "00" => -- Network configuration comes from the ARM SPI registers
					-- This is the default configuration unless there is a rising edge on
					-- target_load_trigger is '1' with matching target FPGA serial number
					--
					-- In this configuration, UDP channel 0 (control networking) is set through the
					-- SPI interface, and the UDP channel 1 (usually raw data and correlator data,
					-- but configurable) is set through the IP/PORT/MAC target registers that are
					-- also used for matched-FPGA-serial set-up.
					local_mac_addr     <= spi_fpga_mac_address;
					local_base_ip_addr <= spi_fpga_ip_address;
					local_base_ip_port <= spi_fpga_ip_port;
					local_subarray     <= (others=>'0');
					remote_ip_addr1     <= target_local_base_ip_addr;
					remote_mac_addr1    <= target_local_mac_addr;
				when "01" => -- Network config is from broadcast, MAC is MSB of FPGA serial number
					local_mac_addr     <= (MAC_ADDRESS_OUI_CODE & fpga_serial_number(47 downto 24)); -- Use bytes 3-5 of FPGA serial to set the local MAC address
					local_base_ip_addr <= local_base_ip_addr_reg;
					local_base_ip_port <= local_base_ip_port_reg;
					local_subarray     <= local_subarray_reg;
					remote_mac_addr1     <= (others=>'0'); -- auto-detect
					remote_ip_addr1     <= (others=>'0'); -- auto-detect

				when "10" =>-- Network config is from broadcast, MAC is a mix of MSB and LSB of FPGA serial number
					local_mac_addr     <= (MAC_ADDRESS_OUI_CODE & (fpga_serial_number(23 downto 0) xor fpga_serial_number(47 downto 24))); -- Use a mix of FPGA serial number bits to set the local MAC address
					local_base_ip_addr <= local_base_ip_addr_reg;
					local_base_ip_port <= local_base_ip_port_reg;
					local_subarray     <= local_subarray_reg;
					remote_mac_addr1     <= (others=>'0'); -- auto-detect
					remote_ip_addr1     <= (others=>'0'); -- auto-detect

				when others => -- Network config is from broadcast, MAC is fully user-defined
					local_mac_addr     <= local_mac_addr_reg ; -- Use a completely user-defined MAC address
					local_base_ip_addr <= local_base_ip_addr_reg;
					local_base_ip_port <= local_base_ip_port_reg;
					local_subarray     <= local_subarray_reg;
					remote_mac_addr1     <= (others=>'0'); -- auto-detect
					remote_ip_addr1     <= (others=>'0'); -- auto-detect
			end case;

		end if;
	end process;

TRIG_ASYNC<=CTRL_FLAG_GLOBAL_TRIG;


--! Generates the buck switching regulator synchronization signal
buckproc: process(clk200)
	begin
		if rising_edge(clk200) then
			if ctrl_flag_buck_sync_enable='0' then
					clk_ctr <= (0=>'1', others=>'0');
					buck_phase_ctr <= (others=>'0');
					buck_sync <= (others=>'0'); -- Make sure both phases are not driving the Bucks after reset and until we enable the buck sync
			else
				if (clk_ctr = CTRL_FLAG_BUCK_CLK_DIV) then
					clk_ctr <= (0=>'1', others=>'0');
					buck_phase_ctr <= buck_phase_ctr + 1;
				else
					clk_ctr <= clk_ctr + 1;
				end if;

				for i in 0 to NUMBER_OF_BUCK_SYNC_LINES-1 loop
					if unsigned(BUCK_PHASE(4*i+3 downto 4*i)) = buck_phase_ctr then
						buck_sync(i) <='1';
					elsif unsigned(BUCK_PHASE(4*i+3 downto 4*i)) = buck_phase_ctr + 8 then -- wraps around
						buck_sync(i) <='0';
					end if;
				end loop;
			end if; -- RST
		end if; -- CLK

	end process;

------ Fan process  ------------------
--! Debounce the fan tachometer signal
--! Implements the ML605 Tachometer readout with debouncing and provides a logic signal toggling at half the fan rotation frequency.
--! The tachometer signal pulses twices a revolution, but each pulse is very noisy.
--! This process implements some basic debouncing so we can read the rotation speed correctly using the general frequency counter
--!
--! There is no RST clause since this is reset as soon as the first chang eof tachymeter value is encountered, which is needed anyways for an accurate frequency count.
fanproc: process(clk200)
	begin
		if rising_edge(clk200) then
			if FAN_TACH/=FAN_TACH_TARGET then
				FAN_TACH_CTR<=(others=>'0');
			elsif SIGNED(FAN_TACH_CTR)=-1 then -- if we reach the end of the counter without encountering a change in the signal state
				FAN_TACH_TARGET<= not FAN_TACH_TARGET; -- toggle the target bit. The loop will now look for that target to be stable
				FAN_TACH_CTR<=(others=>'0');
				if FAN_TACH_TARGET='1' then -- generate a divide by 2 frequency signal to be used by the frequency counter
					FAN_TACH_DIV2_INT<=not FAN_TACH_DIV2_INT;
				end if;
			else
				FAN_TACH_CTR<=FAN_TACH_CTR+1;
			end if;
		end if; --CLK
	end process;

FAN_TACH_DIV2<=FAN_TACH_DIV2_INT;
FAN_PWM <='1'; -- Fan is always operating at 100% speed


slotproc: process(ctrl_clk)
	begin
		if rising_edge(ctrl_clk) then
			slot_probe_dly <= slot_probe;
			for i in 0 to 1 loop
				if slot_probe_dly(i)='0' and slot_probe(i)='1' then
					slot_sense_ctr(i) <= (others=>'0');
				elsif slot_probe(i)='1' and slot_sense(i)='0' and signed(slot_sense_ctr(i))/=-1 then
					slot_sense_ctr(i) <= std_logic_vector(unsigned(slot_sense_ctr(i)) + 1);
				end if;
			end loop;
		end if; --CLK
	end process;

FAN_TACH_DIV2<=FAN_TACH_DIV2_INT;
FAN_PWM <='1'; -- Fan is always operating at 100% speed

------ PWM generator process  ------------------
pwm_out <= pwm_out_int;
pwm_proc: process(pwm_clk)
	begin
		if rising_edge(pwm_clk) then
			if pwm_ctr_en='1' then
				pwm_ctr <= pwm_ctr + 1;
				if pwm_active='0' then
					if pwm_ctr = pwm_offset then
						pwm_active <= '1';
						pwm_ctr <= (others => '0');
						pwm_out_int <= '1';
					end if;
				else
					if pwm_ctr = pwm_high_time then
						pwm_out_int <= '0';
					elsif pwm_ctr = pwm_period then
						pwm_ctr <= (others => '0');
						pwm_out_int <= '1';
					end if;
				end if;
			end if; -- if ctr_en
			-- Synchronous Reset
			if pwm_reset='1' or pwm_soft_reset='1'then
				pwm_active <= '0';
				pwm_ctr <= (others=>'0');
				pwm_out_int <= '0';
			end if;
		end if; --CLK
	end process;

----------------------------------------------------------------
-- Backplane BUCK SYNC generator and backplane access arbitrator
----------------------------------------------------------------
bp_buck_sync0: entity work.bp_buck_sync
	port map (
		sync => bp_buck_sync,
		sync_mon => bp_buck_sync_mon,

		-- Data interface
		--release_ctr_mon => release_ctr_mon,
		--sync_ctr_mon => sync_ctr_mon,
		wr_dat => bp_buck_sync_wr_dat,
		rd_dat => bp_buck_sync_rd_dat,
		rd_dat_valid => bp_buck_sync_rd_dat_valid,
		clk10 => clk10,
		rst => bp_buck_sync_wr_dat(31)
	);

end Behavioral;

