----------------------------------------------------------------------------------
--! @file
--! @brief Top-level file
-- Company: McGill University
-- Engineer: JF Cliche
--
-- Create Date:    2011-05-19
-- Design Name:    chFPGA_PoC
-- Module Name:    top - Behavioral
-- Project Name: CHIME
-- Target Devices: Virtex6 on ML605 Evaluation board, Kintex 7 on KC705
-- Tool versions: ISE 14.4, Vovado 2012.4

-- Dependencies:
--
-- Revision:
-- 2010-10-31 JFC: SP605 File Created
-- 2011-03-12 JFC: SP605 COmplete makeover to generalize the module: make the system more modular
-- 2011-05-19 JFC: Copied from SP605 and modified for Motherboard
-- 2011-07-12 JFC: New structure: ADCDAQ is now within the channelizer
-- 2012-09-20 JFC: many changes since last entry. Implemented correlator. Cleaned up signals. Add some comments.
-- 2012-09-23 JFC: implemented programmable CORR and DATA ports. Moved SYSTEM modules in here to simplify the coding.
-- 2012-10-24 JFC: Added separate sysmon_clk. Moved many ADC configuration vectors into the GENERICS to allow use for Virtex 7 and Kintex 7.
-- 2013-01-28 JFC: Changed name to chFPGA.vhd (no more V6) because it can be used both for V6 and K7
-- 2013-01-30 JFC: Added PLATFORM_ID field to allow the Python software to instantiate the appropriate handlers for the specific platform
--
-- Compile log
-- 2012-11-05 JFC
--  Tried map additional tables. Added many errors.
--  remove additoinal table. Set start placer cost table to 1. Disable register ordering (this might cause buses loke SERDES_AUTO_RESET to be grouped when we don't want to)
--  Cchanged CORR_RESET names with TIMING REG to get more flexibility on those.
--  Fixed FREQ_CTR and FAN logic to reduce logic.
--  CLK125 timing errors not fixed. Hope this is due to extra cost tables.
-- 2012-11-06 JFC
--  Map still running after 10h. Either the cost table=2 or register ordiring at fault. Suspect register ordering.
--  Found that indeed all SERDES_AUTO_RESET were packed into same slice.
--  Set register ordering to 8 to see if speed incrases, and used a fanoutArray in order to not trigger the register ordering on SERDES_AUTO_RESET
-- 2012-11-06 JFC
--    Failed. ADC0 DIVCLK_BUFR failed routing. Lots of hold errors. Some set-up errors related to the SERDES_AUTO_RESET.
--    Changed register_ordering back to 4, and cost table to 1. Not sure which of those is the problem.
-- 2012-11-06 JFC:
--    Success, no timing errors at all, but SERDES_AUTO_RESET regiters are still packed into a sngle LUT.
--    Added BDL constraint in UCF
-- 2012-11-06 JFC:
--    Success, no timing errors. SERDES are now in diferent slices, although they stay close.
--    Added fanout control in ACC (ADD_IN_BYPASS). Added _NOREG general rule in UCF. Shrank ADCDAQ areas a dn remove their CLOCKREGION constraint since there is no BRAM.
-- Additional Comments:
--
---  LIBRARY DECLARATIONS -------------------------------------------------------------------------------
--! Standard libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_misc.ALL; -- for and_reduce

library UNISIM;
use UNISIM.VComponents.all;
--! Project libraries
use work.chFPGA_Package.all; --! Get all component definitions
--use work.chan_package.chan; --! Get chan component
--use work.udp_mac_package.udp_mac; --! Get udp_mac component
--use work.xglink_package.xglink_array; --! Get udp_mac component
--use work.ct_package.shuffle_crossbar; --! Get corner-turn engine components

----ENTITY DECLARATION ------------------------------------------------------------------------------
--! @brief
--!
--! This is the generic **top-level** entity of the CHIME data acquisition/channelizer/correlator firmware.
--! The code is configurable for multiple platforms (Virtex 6, Kintex 7, GMII or SFP+ Ethernet interface, various clock sources, etc) through the generics.
--! A platform-specific wrapper file is used to define these generics for a specific platform and expose the useful ports.
entity chFPGA is
	 GENERIC (
		PLATFORM_ID: INTEGER:= 0; --! identifies the type of platform on which the firmware is running. 0=Motherboard, 1=KC705
--		UDP_MAC_PRESENT: BOOLEAN :=TRUE; --! Indicates if the Ethernet interface is to be implemented (sets the DYMMY flag on the MAC). Used for debugging only.
--		FMC_IF_PRESENT: BOOLEAN :=TRUE; --! Indicates if the SYSTEM submodule is to be implemented (sets its flag on the MAC). Used for debugging only, as the system would not work without it.
		PROTOCOL_VERSION: integer:= 10;
		BLINKER_PRESENT: BOOLEAN :=TRUE; --! Indicates if the LED flasher is to be implemented by setting the DUMMY flag of the BLINKER module
		NUMBER_OF_ADCS: INTEGER :=NUMBER_OF_ADCS_MAX; --! Number of ADC data acquisition blocks (ADCDAQ) to be implemented. If 0, the channelizers ar fed directly from the adc_axis* bus.
		NUMBER_OF_CHANNELIZERS: INTEGER :=NUMBER_OF_CHANNELIZERS_MAX; --! Number of channelizers to be implemented
		NUMBER_OF_CHANNELIZERS_WITH_FFT: integer := NUMBER_OF_CHANNELIZERS_MAX;
		NUMBER_OF_CROSSBAR_INPUTS : integer := GLOBAL_NUMBER_OF_CHANNELIZERS_TO_CORRELATE;
		NUMBER_OF_CROSSBAR_OUTPUTS : integer;
		NUMBER_OF_CORRELATORS: INTEGER :=8; --! Number of correlator blocks (XMUL+ACC) to be implemented
--		NUMBER_OF_CHANNELIZERS_TO_CORRELATE: INTEGER :=GLOBAL_NUMBER_OF_CHANNELIZERS_TO_CORRELATE; --! Number of channelizers to be correlated for each frequency channel. This is hard coded for now. Determines how many channelizer streams are fed to the CORR modules, and how many multipliers to implement in parallel in the CORR module.
		-- Data offloading links
		---- 8x 10G Ethernet Links
		NUMBER_OF_GPU_LINKS: integer := GLOBAL_NUMBER_OF_GPU_LINKS;
		NUMBER_OF_GPU_REFCLKS: integer := GLOBAL_NUMBER_OF_GPU_REFCLKS;
		---- 1x 100G Ethernet Links
		IMPLEMENT_100G_ETHERNET: BOOLEAN :=FALSE; --! If TRUE, a 100G UDP/IP/Ethernet data transmitter is implemented


		NUMBER_OF_BP_PCB_SHUFFLE_LANES: integer := 4;
		NUMBER_OF_BP_QSFP_SHUFFLE_LANES: integer := 4;
		NUMBER_OF_BP_SHUFFLE_LINKS: integer := 3;
		NUMBER_OF_BP_SHUFFLE_REFCLKS: integer := 2;
		BP_LINK_SPEED: integer := 0; -- 0=7.5 Gbps, 1-10Gbps.
		BP_SHUFFLE_LANE_MAP: integerArray := (0=>-1, 1=>0, 2=>1, 3=>2, 4 to 7 => -1); --
		BP_SHUFFLE_LANE_TO_QUAD_MAP : integerArray := (0=>0); --! LANE_TO_QUAD_MAP Indicates which quad is associated each channel. The QUAD number is an integer between 0 and N-1, where N is the total number of quads used.
		BP_SHUFFLE_QUAD_TO_REFCLK_MAP : integerArray := (0=>0); --! QUAD_TO_REFCLK_MAP Indicates which refclk is associated with each QUAD (N integers from 0 to NUMBER_OF_REFCLK-1).
		NUMBER_OF_I2C_PORTS: integer :=1;
		NUMBER_OF_SPI_PORTS: integer :=1;
		NUMBER_OF_ADC_BOARDS: integer := 2; -- One SYNC and REFCLK for each FMC
		SYSTEM_CLOCK_SOURCE : string := "SYSCLK"; --!"SYSCLK": the 200 MHz clock will be taken from sysclk_p/n (CC pins) or "SFP_REFCLK": the system clock is 125 MHz from the GTX reference clock
		CHAN_CLK_SPEED: string:= "200MHZ"; -- "200MHZ" or "300MHZ"
		PHY_TYPE: string; -- "GMII", "SGMII" or "NONE". Determines which ethernet interface to instantiate and connect to the BSB. If NONE, the BSB control interface is connected directly to the top level ports *_bsb_axis_*.
		SGMII_CLOCK_SOURCE: string := "REFCLK"; --! Selects the 125MHz clock source for the SGMII interface; "CLK125": uses the 125 MHz clock (clk125) from the main MMCM, "REFCLK": uses the GTX Reference clock (gtrefclk)

		ADC_TYPE: string := "EV8AQ160"; -- Type of ADC to use.
									    -- "EV8AQ160": Implements ADCDAQ data acquisiton logic for the EV8AQ160.
									    -- "AXIS": Data provided over the axis_adc AXI4-Streaming interface
		--! ADC_IS_DIFFERENTIAL indicates whether each ADC data and clock inputs are single-ended (zero value) or differential (non-zero value).
		ADC_IS_DIFFERENTIAL: BUFMRIndexArrayArray(0 to NUMBER_OF_ADCS_MAX-1) := (others => (others => 1)); -- All inputs are differential by default unless specified otherwise by the top level
		--! ADC_INSTANTIATE_PLL determines which ADCDAQ need to instantiate a PLL to provide IOCLK and DIVCLK to ISERDES that are in non-adjacent banks, and to provide a BUFG-buffered global word clock.
		--! NOTE: A PLL (MMCM) could be used in theory for all data buses, but in practice we would run out of PLLs (there are only 2 per clock region).
		--! NOTE: On the Virtex 6, there is no fast clock routing for the outer IO pads to the PLL. So the use of a PLL is preferably limited to the center IO pads
		ADC_PROVIDE_BUFFERED_DIVCLK: BoolArray( 0 to NUMBER_OF_ADCS_MAX-1):=( 1 => TRUE, others=>FALSE); --! Indicates if this modules provides a buffered (BUFG) 200 MHz ADC clock (to be used to generate the processing clocks). Needs to be set only on those channels that will actually use it because we'll quickly run ot or BUFGs otherwise.
		ADC_INSTANTIATE_PLL: BoolArray(0 to NUMBER_OF_ADCS_MAX-1):=( others=>FALSE); -- No PLL needed on this board, we all have direct or BUFMR connections to the deserializers.
		--! ADC_USE_EXT_DATA_CLK determines which ADC use the external (PLL-generated) IOCLK and DIVCLK. This is needed if the data bus lines end up in non-adjacent banks reachable by the IOBUF or BUFR.
		--! If FALSE, the clocks generated byIOCLK and BUFR will be used.
		--! NOTE: using a single PLL output for multiple ADC data buses is allowed, but that assumes that all data buses are relatively well in phase to be realigned with the IDELAY. This is reasonable assumption if all data buses come from the same ADC chip. It is not clear if this work well across multiple ADC chips.
		ADC_USE_EXT_DATA_CLK: BoolArray(0 to NUMBER_OF_ADCS_MAX-1):=(0 to 3 => TRUE, others=>FALSE);
		ADC_INSTANTIATE_BUFMR: BUFMRIndexArrayArray(0 to NUMBER_OF_ADCS_MAX-1) := (others=>(others=>0)); --! Determines which BUFR is used for each data and clock line
		ANT_CLK_SOURCE: integer := 1; -- Indicate which ADC is the source of the channelizer clocks. Must be one that has PROVIDE_BUFFERED_DIVCLK=TRUE so we have a BUFG that can clock the logic across the chip
		ADC_TO_ADC_BOARD_MAP: IntegerArray(0 to NUMBER_OF_ADCS_MAX-1):=(0 to 7 => 0, 8 to 15 => 1);
		ADC_LSB_POSITION: integer := 8; -- position of the LSB in the 16-bit words provided by the external ADC bus.
		GPU_CHANNEL_QUAD: IntegerArray := (0=>0);
		GPU_QUAD_REFCLK: IntegerArray := (0=>0);
		--IMPLEMENT_ADCDAQ: boolean := TRUE; -- if true, implement and feed the channelizer with ADCDAQ output. If False, the channelizer is fed with adc_axis_* data directly.
		IMPLEMENT_LCD: BOOLEAN := FALSE;
		IMPLEMENT_SWITCHER_SYNC: BOOLEAN := TRUE;
		IMPLEMENT_FAN: BOOLEAN := TRUE;
		SIM: BOOLEAN := FALSE --! Indicates this is running as a simulation. Used to accelerate simulations

		);
    PORT (
			------------------------------------
			-- SYSTEM
			------------------------------------

			-- Reset line
			cpu_reset: in std_logic; --! Hardware reset generated by the Motherboard

			-- Motherboard Buttons and LEDs
			GPIO_BUTTON0 : in  std_logic := '0'; --! Button on the Motherboard
			gpio_led: out  std_logic_vector(7 downto 0); --! Row of 8 leds on the Motherboard
			GPIO_DIP_SW: in std_logic_vector(3 downto 0) := (others =>'0'); --! 4 DIP switches used to set the IP address of the board

			-- Motherboard LCD
			LCD_DB: out  std_logic_vector(7 downto 4); -- Motherboard LCD display data bus (4 bits wide)
			LCD_E : out  std_logic; --! Motherboard LCD display Enable line
			LCD_RS : out  std_logic; --! Motherboard LCD display RS line
			LCD_RW : out  std_logic; --! Motherboard LCD Read/Write line

			-- Motherboard Fan
			FAN_PWM : out  std_logic; --! Controls he transistors that turns on the FPGA fan. Can be used to modulate the fan speed.
			FAN_TACH : in  std_logic := '0'; --! Readout of the FPGA fan tachymeter. Provides 2 pulses per turn, but the pulses are noisy.

			-- Motherboard Current and voltage monitors
			VAUX_CURR_N : in  std_logic:='0';
			VAUX_CURR_P : in  std_logic:='0'; --! Analog input to the internal FPGA System Monitor ADC. Measures the board current on the 12V supply through a current sensor.
			VAUX_VOLT_N : in  std_logic:='0';
			VAUX_VOLT_P : in  std_logic:='0';  --! Analog input to the internal FPGA System Monitor ADC. Measures 12V supply voltage through a voltage divider.
			VP : in  std_logic:='0';
			VN : in  std_logic:='0';

			-- Clock inputs
			clk10: in std_logic; -- Buffered 10 MHz board reference clock with well known phase relative to the ADC clocks and  all other boards. Used to synchronize ADC startup. Typically synchronous to the IRIGB timestamp signal, but not necessary.
			SYSCLK_P : in std_logic := '0'; --! 200 MHz unbuffered differential clock. Used as a master clock if  SYSTEM_CLOCK_SOURCE = "SYSCLK";
			SYSCLK_N : in std_logic := '1';
			sysclk_bufg: in std_logic := '0';--! BUFG-buffered 200 MHz used as a master clock if  SYSTEM_CLOCK_SOURCE = "SYSCLK_BUFG";
			sfp_clk_p: in std_logic := '0'; --! 125 MHz SFP reference clock, generated on-board using a high quality oscillator. Used as a master clock if  SYSTEM_CLOCK_SOURCE = "SFP_REFCLK"; Also used to synchronize the MGT used to communicate to the SFP.
			sfp_clk_n: in std_logic := '1';

			-- Clock monitoring inputs
			raw_clk10: in std_logic := '0'; -- Buffered 10 MHz reference. Used for upstream clock frequency measurement only.
			mgt_clk100: in std_logic := '0'; -- Buffered MGT 100 MHz reference clock. Used by Frequency counter to debug connectivity
			mgt_clk200: in std_logic := '0'; -- Buffered MGT 200 MHz reference clock. Used by Frequency counter to debug connectivity
			mgt_clk125: in std_logic := '0'; -- Buffered MGT 125 MHz reference clock. Used by Frequency counter to debug connectivity

			-- On-board processor serial interface (used to access configuration registers prior to networking setup)
			arm_spi_sck : in std_logic := '0';
			arm_spi_miso : out std_logic;
			arm_spi_mosi : in std_logic :='0';
			arm_spi_cs_n : in std_logic := '0';

			arm_irq_in: in std_logic := '0'; -- Used for hardware validation only
			arm_irq_out: out std_logic; -- Used for hardware validation only
			arm_irq_oe: out std_logic; -- Used for hardware validation only

			flash_cs_in: in std_logic := '0';
			flash_cs_out: out std_logic;
			flash_cs_oe: out std_logic;  -- Active-high: enables GPIO reset output driver.

			gpio_rst_in: in std_logic := '0';
			gpio_rst_out: out std_logic;
			gpio_rst_oe: out std_logic;  -- Active-high: enables GPIO reset output driver.

			gpio_irq_in: in std_logic := '0';
			gpio_irq_out: out std_logic;
			gpio_irq_oe: out std_logic;  -- Active-high: enables GPIO reset output driver.

			uart_rx_in: in std_logic := '0';
			uart_rx_out: out std_logic;
			uart_rx_oe: out std_logic;

			uart_tx_in: in std_logic := '0';
			uart_tx_out: out std_logic;
			uart_tx_oe: out std_logic;


			-- Backplane signals
			bp_time_in: in std_logic:='0';
			bp_trig_in: in std_logic:='0';
			bp_buck_sync: inout std_logic;

			bp_gpio_int_in: in std_logic := '0';
			bp_gpio_int_out: out std_logic;
			bp_gpio_int_oe: out std_logic;

			bp_slot_probe: in std_logic_vector(1 downto 0) := (others=>'0'); --! Signal used to probe the capacitance of the backplane slot-sense line
			bp_slot_sense: in std_logic_vector(1 downto 0) := (others=>'0'); --! Returns the logic level change in response to the probe edge, which is used to determine the board capacitance.

			-- User outputs
			user_mux_out: out std_logic_vector(0 to 3);
			user_mux_in: in std_logic_vector(0 to 3) := (others =>'0');
			user_mux_oe: out std_logic_vector(0 to 3);

			--blinker_leds: out std_logic_vector(7 downto 0); -- see gpio_leds

			-- Motherboard SMA clocks
			clk10_out : out  std_logic; --! Delayed 10 MHz FMC Reference clock monitor. The delay line is used to align the ADC SYNC signal with the ADC clock.

			------------------------------------
			-- Motherboard GMII PHY Gigabit Ethernet Interface (Marvell Alaska 10-100-1000BASE-T PHY)
			------------------------------------
			phy_rxclk : in  std_logic :='0'; --! Receive byte clock recovered  by the PHY chip
			phy_txer: out std_logic; --! Enabled to transmit an error condition to the PHY
			phy_reset_l: out std_logic; --! Active LOW PHY reset
			phy_rxctrl_rxdv: in  std_logic := '0'; --! RX Data Valid flag from the PHY
			phy_rxd: in  std_logic_vector(7 downto 0) := (others=>'0'); -- RX Data from the PHY

			phy_txc_gtxclk: out std_logic; --! 125 MHz clock provided to the PHY to clock the Tx bus
			phy_txctl_txen: out std_logic; --! Indicates that valid data is presented on the PHY TX bus.
			phy_txd: out  std_logic_vector(7 downto 0); --! Tx Data bus to the PHY
			phy_txclk: in std_logic :='0'; --! 125 MHz TX clock supplied *by* the PHY. This is not used as we generate our own clock internally.

			-- ------------------------------------
			-- -- Motherboard PMBus
			-- ------------------------------------
			-- PMBUS_SCK: inout std_logic; --! Motherboard PMBus (I2C) clock (bidirectional)
			-- PMBUS_SDA: inout std_logic; --! Motherboard PMBus (I2C) data (bidirectional)

			------------------------------------
			-- Motherboard SFP (Gbit Ethernet)
			------------------------------------
			-- SFP signals to be conencted to pins according to the UCF
			-- SFP_LOS: in std_logic; --! SFP Loss of Signal flag
			sfp_tx_p: out std_logic; --! Serialized data from the FPGA MGT to the SFP
			sfp_tx_n: out std_logic;
			sfp_rx_p: in std_logic := '0'; --! Serialized data from the SFP to the FPGA MGT
			sfp_rx_n: in std_logic := '1';

			-- Status signals
			sfp_status_vector: out std_logic_vector(15 downto 0); -- Core status.
			sfp_mmcm_locked : out std_logic;
			sfp_reset_done: out std_logic;
			tx_ready: out std_logic;

			------------------------------------
			-- 10G Ethernet Interfaces
			------------------------------------

			xge_tx_p: out std_logic_vector(0 to NUMBER_OF_GPU_LINKS-1);
			xge_tx_n: out std_logic_vector(0 to NUMBER_OF_GPU_LINKS-1);
			xge_rx_p: in std_logic_vector(0 to NUMBER_OF_GPU_LINKS-1) := (others => '0');
			xge_rx_n: in std_logic_vector(0 to NUMBER_OF_GPU_LINKS-1):= (others => '1');
			-- Gigabit transceiver refrenece clocks (typically 156.25 MHz)
			xge_refclk_p: in std_logic_vector(0 to NUMBER_OF_GPU_REFCLKS-1) := (others => '0');
			xge_refclk_n: in std_logic_vector(0 to NUMBER_OF_GPU_REFCLKS-1) := (others => '1');

			------------------------------------
			-- 100G Ethernet Interfaces
			------------------------------------

			cge_tx_p: out std_logic_vector(0 to 3);
			cge_tx_n: out std_logic_vector(0 to 3);
			--cge_rx_p: in std_logic_vector(0 to 3) := (others => '0');
			--cge_rx_n: in std_logic_vector(0 to 3):= (others => '1');
			-- Gigabit transceiver refrenece clocks (typically 156.25 MHz)
			cge_refclk_p: in std_logic := '0';
			cge_refclk_n: in std_logic := '1';

			------------------------------------
			-- Corner-Turn Engine
			------------------------------------
			-- Gigabit Transceiver links to the backplane for intra-crate and inter-crate data transfers
			bp_shuffle_tx_p: out std_logic_vector(0 to NUMBER_OF_BP_SHUFFLE_LINKS -1);
			bp_shuffle_tx_n: out std_logic_vector(0 to NUMBER_OF_BP_SHUFFLE_LINKS -1);
			bp_shuffle_rx_p: in std_logic_vector(0 to NUMBER_OF_BP_SHUFFLE_LINKS -1) := (others => '0');
			bp_shuffle_rx_n: in std_logic_vector(0 to NUMBER_OF_BP_SHUFFLE_LINKS -1) := (others => '1');
			-- Gigabit transceiver refrenece clocks (typically 156.25 MHz)
			bp_shuffle_refclk_p: in std_logic_vector(0 to NUMBER_OF_BP_SHUFFLE_REFCLKS-1) := (others => '0');
			bp_shuffle_refclk_n: in std_logic_vector(0 to NUMBER_OF_BP_SHUFFLE_REFCLKS-1) := (others => '1');



			------------------------------------
			-- AXI-Streaming ADC interface
			------------------------------------
			-- Data bus contains 8x 16-bit words.
			-- Samples are MSB-aligned in the word.
			-- First word in the group is in bits 15:0
			-- AXIS Clock is sampling_frequency / 8
			adc_axis_tdata: in slv128_array(0 to NUMBER_OF_ADCS-1) := (others => (others => '0'));
			adc_axis_tvalid: in std_logic_vector(0 to NUMBER_OF_ADCS-1) := (others => '0');
			adc_axis_clk: in std_logic_vector(0 to NUMBER_OF_ADCS-1) := (others => '0');
			-- Clock output of the ADC tiles (for monitoring)
			adc_clkout: in std_logic_vector(0 to NUMBER_OF_ADCS-1) := (others => '0');
			------------------------------------
			-- FMC ADC interface
			------------------------------------

			adc_data_p: in SLV8_ARRAY(0 to NUMBER_OF_ADCS-1) := (others => (others => '0'));
			adc_data_n: in SLV8_ARRAY(0 to NUMBER_OF_ADCS-1) := (others => (others => '1'));
			adc_clk_p: in std_logic_vector(0 to NUMBER_OF_ADCS-1) := (others => '0');
			adc_clk_n: in std_logic_vector(0 to NUMBER_OF_ADCS-1) := (others => '1');


			-- ADC RESET and SYNC signals
			ADC_SYNC_P: out std_logic_vector(0 to NUMBER_OF_ADC_BOARDS-1); --! SYNC signal to the ADC (or the recynchronization circuit that drives the ADC SYNC)
			ADC_SYNC_N: out std_logic_vector(0 to NUMBER_OF_ADC_BOARDS-1);
			ADC_RST_N: out std_logic_vector(0 to NUMBER_OF_ADC_BOARDS-1); --! Active LOW ADC reset line, common to both ADC chips.

			--SPI signals
			spi_sck: out std_logic; --! SPI clock to the FMC. Typically 1 MHz.
			spi_miso: in std_logic_vector(0 to NUMBER_OF_SPI_PORTS-1) := (others=>'0'); --! SPI data from the FMC
			spi_mosi: out std_logic; --! SPI data to the FMC
			spi_addr: out std_logic_vector(2 downto 0); --! Address bus that selects which SPI device is enabled. Up to 8 devices are possible)
			spi_cs_n: out std_logic_vector(0 to NUMBER_OF_SPI_PORTS-1); --! On Rev0 MGADC08, it is the ADC PLL Latch Enable. On Rev2, is is an active LOW SPI_CS that enables the device selected by the address.
			spi_rst_n: out std_logic; --! Active LOW reset for the SPI devices, namely the IO Expander. This line is used by REV0 boards, and is left floating by REV2 boards. Note that this LPC pinn is normally used by the PRSNT signal, which should normally be grounded by a FMC board when it is installed.
			spi_rst_n_alt: out std_logic; --! Active LOW reset for the SPI devices, namely the IO Expander. This line is used by REV2 boards, and is left floating by REV0 boards.

			adc_pll_lock: in std_logic_vector(0 to NUMBER_OF_ADC_BOARDS-1) := (others=>'0'); --! Lock signal for the ADC PLL on each mezzanine

			-- I2C signals
			i2c_scl: inout std_logic_vector(NUMBER_OF_I2C_PORTS-1 downto 0); --! FMC I2C clock (bidirectional). Used to talk to the on-board EEPROM.
			i2c_sda: inout std_logic_vector(NUMBER_OF_I2C_PORTS-1 downto 0); --! FMC I2C data (bidirectional). Used to talk to the on-board EEPROM.


			-- FMC Reference clock

			REFCLK_M2C_P: in std_logic_vector(0 to NUMBER_OF_ADC_BOARDS-1) := (others =>'0'); --! copy of the 10 MHz reference clock received by the FMC boards (through its SMA connector )and forwarded to the FPGA as a LVDS signal. May contain encoded SYNC information.
			REFCLK_M2C_N: in std_logic_vector(0 to NUMBER_OF_ADC_BOARDS-1)  := (others =>'1');

			mgt_pll_refclk_p: in std_logic_vector(0 to NUMBER_OF_ADC_BOARDS*2-1) := (others=>'0'); --! Clocks generated by the MGT PLL, on MGT reference clock inputs
			mgt_pll_refclk_n: in std_logic_vector(0 to NUMBER_OF_ADC_BOARDS*2-1) := (others=>'1');

			-- FMC MGT interface (eSATA connectors)

			-- Buck control signals
			buck_sync: out std_logic_vector(0 to 15); --! Clock used to synchronize the switching regulators


			--==== Slow data output (PROBER & CORR outputs, 8-bit-wide, on BSB clock)
			--m_sdata_axis_tdata: out std_logic_vector(7 downto 0);
			--m_sdata_axis_tvalid: out std_logic;
			--m_sdata_axis_tlast: out std_logic;
			--m_sdata_axis_tready: in std_logic := '1';

			--==== Fast data output (Corner Turn output, 32-bit wide, 322 MHz clock)
			-- to be implemented
			-- === Debug port
			debug_out: out std_logic_vector(31 downto 0);
			sma_out: out std_logic_vector(0 to 3);

			--==== Direct BSB control interface
			-- Command input stream
			s_bsb_axis_tdata: in std_logic_vector(31 downto 0) := (others => '0');
			s_bsb_axis_tvalid: in std_logic := '0';
			s_bsb_axis_tlast: in std_logic := '0';
			s_bsb_axis_tready: out std_logic;

			-- Reply output stream
			m_bsb_axis_tdata: out std_logic_vector(31 downto 0); -- Data is in bits 7:0, bits 31:30 is "00" for command replies and "01" for data
			m_bsb_axis_tvalid: out std_logic;
			m_bsb_axis_tlast: out std_logic;
			m_bsb_axis_tready: in std_logic := '0';

			bsb_axis_clk : in  std_logic := '0'; -- BSB bus clock, typically between 100-125 MHz
			bsb_axis_rst : in  std_logic  := '0'-- synchronous to bsb_axis_clk

			);
end chFPGA;

---------- chFPGA implementation ------
--! Implements the chFPGA top level functionalities.
--! This simply connects the following instances:
--!  - CLOCK Module, which implements the PLLs that provides the system clocks and channelizer clocks.
--!  - System modules such as GPIO, SPI, I2C etc.
--!  - BLINKER module which blinks the Motherboard leds nicely. Was also historically used to force data transmission while a button was pressed.
--!  - Ethernet/IP/UDP packet receiver/transmitter
--!  - Control interface master, which pass the outgoing control and monitor commands from the Ethernet interface to the command router,  and merges the received reply packets with the capture and correlator packets to be sent to the Ethernet interface
--!  - Control interface router, wich routes the various commands to approprate destination based on the destination port number. Also merges and arbitrates the reply streams coming from those destinations.
--!  - An array of channelizer modules (one for each ADC channel), each containing the ADC data acquisition module, data source selector, FFT module, and data scaler.
--!  - Corner-turn logic, consisting in a first crossbar, backplane links, second crossbar, crate links and third crossbar
--!  - GPU 10G Ethernet data offload links
--!  - In some configuration, an array of Correlator Blocks modules can be instantiated. Each block captures and correlates a range of frequency channels.
--!
--!  Clock management
--!  ----------------
--!
--!  Each channelizer is fed by an ADC data acquisition block (ADCDAQ)
--!  which uses the ADC-provided 400 MHz DDR clock to accurately capture the data
--!  on the ADC data bus at 800 MSPS. The data samples are packaged in groups
--!  of 4 bytes clocked at 200 MHz and is sent into a small asynchronous FIFO.
--!
--!
--!  The 200 MHz word clock from one of the ADC is selected to generate eight
--!  200-MHz clocks, each on a different phase, that are used to clock the channelizers.
--!  Two channelizers use the same phase. This multiphase clock architecture
--!  is used ot to spread out the switching currents in time and potentially
--!  reduce the noise on the board.

--!  The channelizer clocks are used to pull the data from the FIFOs of their
--!  respective ADCDAQs. Although each ADC channel provide its data and clock
--!  with a presumably unknown phases, all the ADC clocks are derived from the
--!  same source (ultimately the 10 MHz reference provided to the FMC board)
--!  and therefore operate strictly at the same frequency. Using the clock
--!  from one ADC channel to read out all the channels will therefore not
--!  cause the ADCDAQ FIFOs to over- or underflow.
--!
--!  We can use the system 200 MHz clock to generate the channelizer clocks,
--!  which is also ultimately derived from the board's reference clock (Ref
--!  clock -> motherboard PLL -> FPGA PLL). However, this clock can be used
--!  ***ONLY*** if the ADC are sampling exactly at 800 MSPS, otherwise the
--!  FIFO to quickly over or underflow.
--!
--!  Using the internal 200 MHz has the advantage that it is not interrupted when
--!  the ADC SYNC signal is activatd, therefore allowing the power-hungry
--!  channelizers to continuously consume the same amount of current during
--!  the SYNC process.
--!
--!  Using the internal 200 MHz clock also allows the channelizers to operate
--!  even when mezzanines are not present.
--!
--!  The corner-turn and correlator clock is independent from the channelizer clock.
--!
--!  ADCDAQ configuration
--!  ----------------------------
--!  Due to FPGA ressources and FMC pinout limitations, some bits of the ADC data buses are not located in banks that do not allow the ADC clock signal to locally clock the incoming data.
--!  In order to solve this problem, the bit and words clock for some of the ADC channels are derived from a PLL driven by one of the ADC channel. These clocks can then reach any part of the chip to properly clock the ADC lines.
--!  Two boolean arrays define how the ADC DAQ clocking is implemented:
--!   - ADC_INSTANTIATE_PLL is a boolean array that indicates if an ADCDAQ module shall instantiate a PLL to generate a bit and word clock
--!   - ADC_USE_EXT_DATA_CLK is a boolean array that indicates if am ADCDAQ module shall use its local ADC bit and word clocks or the PLL clock to capture the ADC data. This is set to TRUE for each module that cannot access all its data bits using he local routing ressources.
--!   - ANT_CLK_SOURCE indicates from which ADCDAQ the external PLL signal to be is coming.
--!
--!   Note for the Virtex 6 240:
--!     - the PLL should be instantiated only for IOs located in the middle columns.
--!     - Outer IO coulmns do not have dedicated high performance connectivity to the PLLs.
--!     - ADC0 lines are the ones that have their data lines inconvenieltly spread over multiple IO banks. These were located on the inner IO column so the PLL can be used to distribute the clocks to all IOs.
--!     - ADC1 data and clock lines are on outer IO column but are all the data lines are accessible using the local clocking ressoirces.
--!
--!     - Also note that it is not recommended to capture  ADC1 data using a clock based on a ADC0 output clock. The two chips have different delays and may be sync'ed differently.
--!
architecture Behavioral of chFPGA is


-- Attributes used in this module
attribute equivalent_register_removal: string;
attribute keep:string;
attribute shreg_extract: string;
attribute async_reg: string; --! used by the simulator and placer to properly handle registers with async inputs, but does not affect timing
attribute user_async_reg: string; --! used by the timing constraints file to identify known registers with async inputs and apply proper timing exception
attribute S: string;
attribute DONT_TOUCH: string;
attribute IOB: string;

-- ==================================================
-- ========== SIGNALS ==============================
-- ==================================================

-- Constants
--constant NUMBER_OF_CHANNELIZERS_WITH_FFT: integer := sel(GLOBAL_IMPLEMENT_FFT, 0*NUMBER_OF_CHANNELIZERS+4, 0); --! Number of channelizers that have an FFT module
constant NUMBER_OF_ADCS_OR_CHANNELIZERS: integer := max(NUMBER_OF_ADCS, NUMBER_OF_CHANNELIZERS);
constant IMPLEMENT_CROSSBAR1: boolean := NUMBER_OF_CROSSBAR_INPUTS>0 and NUMBER_OF_CROSSBAR_OUTPUTS>0;
constant IMPLEMENT_CROSSBAR2_AND_CROSSBAR3: boolean := IMPLEMENT_CROSSBAR1 and NUMBER_OF_BP_SHUFFLE_LINKS>0;
constant FPGA_SERIES: integer :=FPGA_SERIES_LIST(PLATFORM_ID);

-- Top level memory-mapped address ranges
constant SYSTEM_BASE_PORT    : integer := 0; --! Top level address for the SYSTEM subsystem
constant CHAN_BASE_PORT      : integer := 1; --! Top-level address channelizers subsystem (which also includes the ADCs).
constant CROSSBAR1_BASE_PORT : integer := 2; --! Top-level address channelizers subsystem (which also includes the ADCs).
constant GPU_LINK_BASE_PORT  : integer := 3; --! Top level address for the GPU link sybsystem
constant CROSSBAR3_BASE_PORT : integer := 4; --! Top level address for the 3rd crossbar subsystem.
constant CORR_BASE_PORT      : integer := 4; --! Top level address for the correlator subsystem (exclusive with the 2nd and 3rd crossbar)
constant BP_SHUFFLE_BASE_PORT: integer := 5; --! Top level address for the backplane shuffle subsystem.
constant CROSSBAR2_BASE_PORT : integer := 6; --! Top-level address channelizers subsystem (which also includes the ADCs).
constant NUMBER_OF_PORTS     : integer := 7; --! Total number of top-level subsystems to be addressed.

-- SYSTEM modules definition

constant MODULE_GPIO_ADDR     : integer :=0;
constant MODULE_SYSMON_ADDR   : integer :=1;
constant MODULE_FREQ_CTR_ADDR : integer :=2;
constant MODULE_SPI_ADDR      : integer :=3;
constant MODULE_REFCLK_ADDR   : integer :=4;
constant MODULE_I2C_ADDR      : integer :=5;
constant NUMBER_OF_SYS_MODULES: INTEGER :=6;


-- Capture
constant NUMBER_OF_PROBES: INTEGER :=NUMBER_OF_CHANNELIZERS+NUMBER_OF_CORRELATORS; --! Number of data probes (data transsmission channels) that need to be send back to the host computer through the Ethernet
constant CHAN_PROBE_BASE_PORT: INTEGER :=0;
constant CORR_PROBE_BASE_PORT: INTEGER :=NUMBER_OF_CHANNELIZERS; --! Top level address for the first correlator block

constant ADC_INSTANTIATE_IDELAYCTRL: BoolArray(0 to NUMBER_OF_ADCS-1) := (0=>TRUE, others =>FALSE); --! Determines which ADCDAQ instantiates a DELAY controller (calibrator). We need to instantiate only one in the whole design, and the tools will add all the others where needed.



-- Clocks & global reset
signal CLK125: std_logic; --! 125 MHz clock for the command interface and the Ethernet communications
signal clk200: std_logic; --! 200 MHz system clock from the carrier board
signal CORR_CLK: std_logic; --! Correlator clock, derived from the carrier board.
signal CORR_CLK_MMCM: std_logic; --! Correlator clock at the output of the MMCM.
signal CTRL_CLK:   std_logic;
signal sysmon_clk:   std_logic;
signal frame_clk: std_logic;

signal sysmon_reset: std_logic;
signal sysmon_user_reset: std_logic;
signal corr_reset: std_logic; -- reset synchronous to corr_clk
signal clk200_reset: std_logic;
signal clk200_reset_reg: std_logic;
signal clk125_reset: std_logic;
signal ctrl_rst: std_logic;
signal ctrl_reset_pulse: std_logic;


signal fmc_mgt_pll_refclk_nobuf: std_logic_vector(0 to NUMBER_OF_ADC_BOARDS*2-1);
signal fmc_mgt_pll_refclk: std_logic_vector(0 to NUMBER_OF_ADC_BOARDS*2-1);
--signal RESET: std_logic; -- Internal RESET after the clocks are stable
signal user_reset: std_logic:='0'; -- User-controlled global reset
signal ALL_RESET: std_logic:='0'; -- Combined hard and soft global reset

signal chan_clk_reset_async: std_logic; --! Channelizer PLL reset from GPIO. asynchronous
signal chan_reset_async : std_logic; --! User reset for all channelizers, asynchronous

signal CORR_RESET_ASYNC : std_logic; --! user-controlled asynchronous reset for all correlator blocks




signal gpio_led_int: std_logic_vector(7 downto 0);


signal bp_time_io_dly: std_logic;
signal bp_time_io_reg: std_logic;
attribute IOB of bp_time_io_reg :signal is "true";
signal bp_time_reg: std_logic;
signal bp_trig_io_dly: std_logic;
signal bp_trig_io_reg: std_logic;
attribute IOB of bp_trig_io_reg :signal is "true";
signal bp_trig_reg: std_logic;

signal debug1: std_logic;
signal debug2: std_logic;
signal user_bit: std_logic_vector(1 downto 0);

signal irigb_delay: std_logic_vector(4 downto 0);
signal irigb_delay_reset: std_logic;

-- UDP/Ethernet interfaces

signal local_mac_addr: std_logic_vector(47 downto 0);
signal local_subarray: std_logic_vector(1 downto 0);
signal local_ip_addr: std_logic_vector(31 downto 0);
signal local_base_ip_port: std_logic_vector(15 downto 0);
signal remote_ip_port0: std_logic_vector(15 downto 0);
signal remote_mac_addr1: std_logic_vector(47 downto 0);
signal remote_ip_addr1: std_logic_vector(31 downto 0);
signal remote_ip_port1: std_logic_vector(15 downto 0);

signal sfp_status_vector_int: std_logic_vector(15 downto 0); -- Core status.
signal sfp_config_vector: std_logic_vector(31 downto 0); -- Core config.

signal udp_stack_reset: std_logic;
signal ctrl_master_reset: std_logic;

-- signal RX_IP_DEST_ADDR: std_logic_vector(31 downto 0);
-- signal test: unsigned(47 downto 0);

--

-- Ethernet/UDP output / MASTER input  interface buses
signal axis_udp_tx_tdata:   std_logic_vector(7 downto 0);
signal axis_udp_tx_tlast:   std_logic;
signal axis_udp_tx_tvalid:   std_logic;
signal axis_udp_tx_tready:   std_logic;
signal udp0_tx_port:   std_logic_vector(1 downto 0) := (others=>'0');

signal axis_udp_rx_tdata: std_logic_vector(7 downto 0);
signal axis_udp_rx_tvalid: std_logic;
signal axis_udp_rx_tlast: std_logic;
signal axis_udp_rx_tready: std_logic;

-- MASTER output / First router input bus

signal axis_cmd_tdata: std_logic_vector(7 downto 0);
signal axis_cmd_tvalid: std_logic;
signal axis_cmd_tlast: std_logic;
signal axis_cmd_tready: std_logic;


signal axis_rply_tdata: std_logic_vector(7 downto 0);
signal axis_rply_tvalid: std_logic;
signal axis_rply_tlast: std_logic;
signal axis_rply_tready: std_logic;

signal UDP_CMD_DAT: AXIS8_DAT_STRUCT;
signal UDP_CMD_RDY: AXIS8_RDY_STRUCT;
signal UDP_RPLY_DAT: AXIS8_DAT_STRUCT;
signal UDP_RPLY_RDY: AXIS8_RDY_STRUCT;

signal cmd_packet_counter: std_logic_vector(7 downto 0);
signal rply_packet_counter: std_logic_vector(7 downto 0);


-- First router output bus
-- Master to top-level modules control interface buses
signal top_cmd_dat: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_PORTS-1 downto 0);
signal top_cmd_rdy: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_PORTS-1 downto 0):=(others=>(TREADY=>'1'));
signal top_rply_dat: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_PORTS-1 downto 0);
signal top_rply_rdy: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_PORTS-1 downto 0);

signal HOST_FRAME_READ_RATE: std_logic_vector(4 downto 0);


-- Intermediary buses used to split out the top router outputs and avoid a simulator bug when indexing record arrays as an actual parameter of an instance
signal TOP_SYS_CMD_DAT: AXIS8_DAT_STRUCT;
signal TOP_SYS_CMD_RDY: AXIS8_RDY_STRUCT;
signal TOP_SYS_RPLY_DAT: AXIS8_DAT_STRUCT;
signal TOP_SYS_RPLY_RDY: AXIS8_RDY_STRUCT;

signal TOP_CHAN_CMD_DAT: AXIS8_DAT_STRUCT;
signal TOP_CHAN_CMD_RDY: AXIS8_RDY_STRUCT;
signal TOP_CHAN_RPLY_DAT: AXIS8_DAT_STRUCT;
signal TOP_CHAN_RPLY_RDY: AXIS8_RDY_STRUCT;

signal TOP_CROSSBAR1_CMD_DAT: AXIS8_DAT_STRUCT;
signal TOP_CROSSBAR1_CMD_RDY: AXIS8_RDY_STRUCT;
signal TOP_CROSSBAR1_RPLY_DAT: AXIS8_DAT_STRUCT;
signal TOP_CROSSBAR1_RPLY_RDY: AXIS8_RDY_STRUCT;


signal top_bp_shuffle_cmd_dat: AXIS8_DAT_STRUCT;
signal top_bp_shuffle_cmd_rdy: AXIS8_RDY_STRUCT;
signal top_bp_shuffle_rply_dat: AXIS8_DAT_STRUCT;
signal top_bp_shuffle_rply_rdy: AXIS8_RDY_STRUCT;

-- System ROUTER output interface buses
signal SYS_CMD_DAT: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_SYS_MODULES-1 downto 0);
signal SYS_CMD_RDY: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_SYS_MODULES-1 downto 0);
signal SYS_RPLY_DAT: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_SYS_MODULES-1 downto 0);
signal SYS_RPLY_RDY: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_SYS_MODULES-1 downto 0);

-- Intermediary buses used to split out the SYSTEM router outputs and avoid a simulator bug when indexing record arrays as an actual parameter of an instance
signal SYS_GPIO_CMD_DAT: AXIS8_DAT_STRUCT;
signal SYS_GPIO_CMD_RDY: AXIS8_RDY_STRUCT;
signal SYS_GPIO_RPLY_DAT: AXIS8_DAT_STRUCT;
signal SYS_GPIO_RPLY_RDY: AXIS8_RDY_STRUCT;

signal SYS_SYSMON_CMD_DAT: AXIS8_DAT_STRUCT;
signal SYS_SYSMON_CMD_RDY: AXIS8_RDY_STRUCT;
signal SYS_SYSMON_RPLY_DAT: AXIS8_DAT_STRUCT;
signal SYS_SYSMON_RPLY_RDY: AXIS8_RDY_STRUCT;

-- Command buses forwarded from the CHANNELIZER to the corresponding ADCDAQ
signal ADC_CMD_DAT: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_ADCS_OR_CHANNELIZERS-1 downto 0); -- We need to use max because the channelizer and ADCDAQ comamnd buses are linked.
signal ADC_CMD_RDY: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_ADCS_OR_CHANNELIZERS-1 downto 0);
signal ADC_RPLY_DAT: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_ADCS_OR_CHANNELIZERS-1 downto 0);
signal ADC_RPLY_RDY: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_ADCS_OR_CHANNELIZERS-1 downto 0);

signal CHAN_CMD_DAT: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_CHANNELIZERS-1 downto 0); -- We need to use max because the channelizer and ADCDAQ comamnd buses are linked.
signal CHAN_CMD_RDY: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_CHANNELIZERS-1 downto 0);
signal CHAN_RPLY_DAT: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_CHANNELIZERS-1 downto 0);
signal CHAN_RPLY_RDY: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_CHANNELIZERS-1 downto 0);

signal CORR_CMD_DAT: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_CORRELATORS-1 downto 0); -- We need to use max because the channelizer and ADCDAQ comamnd buses are linked.
signal CORR_CMD_RDY: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_CORRELATORS-1 downto 0);
signal CORR_RPLY_DAT: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_CORRELATORS-1 downto 0);
signal CORR_RPLY_RDY: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_CORRELATORS-1 downto 0);

-- Make sure the pipeline registers are not simplified by the synthesizer so they can be useful in helping meeting timing


-- Slow data capture bus (PROBER & CORR output)
signal axis_prb_tdata: slv8_array(NUMBER_OF_PROBES-1 downto 0);
signal axis_prb_tvalid: slv(NUMBER_OF_PROBES-1 downto 0);
signal axis_prb_tlast: slv(NUMBER_OF_PROBES-1 downto 0);
signal axis_prb_tready: slv(NUMBER_OF_PROBES-1 downto 0);

-- REFCLK signals

signal fmc_refclk: std_logic_vector(0 to NUMBER_OF_ADC_BOARDS-1); --
signal ADC_SYNC: std_logic_vector(0 to NUMBER_OF_ADC_BOARDS-1);



signal adc_clk_bufg: std_logic; --! BUFR-buffered ADC clock selected from one of the ADC channels to clock the channelizers
-- signal ADC_DAT: AXIS32_DAT_STRUCT_ARRAY(0 to NUMBER_OF_ADCS-1);
--signal ANT_DAT_TIMING_REG3: AXIS32_DAT_STRUCT_ARRAY(NUMBER_OF_CHANNELIZERS_TO_CORRELATE-1 downto 0);
--signal ANT_RDY: AXIS32_RDY_STRUCT_ARRAY(NUMBER_OF_CHANNELIZERS-1 downto 0);

-- ADC data bus between the ADCDAQ (or top port) to the CHANNELIZER
signal axis_adc_tdata8: slv32_array(0 to NUMBER_OF_ADCS_OR_CHANNELIZERS-1);
signal axis_adc_tdata: slv64_array(0 to NUMBER_OF_ADCS_OR_CHANNELIZERS-1);
signal axis_adc_tvalid: slv(0 to NUMBER_OF_ADCS_OR_CHANNELIZERS-1);
signal axis_adc_tlast: slv(0 to NUMBER_OF_ADCS_OR_CHANNELIZERS-1);
signal axis_adc_tuser: slv4_array(0 to NUMBER_OF_ADCS_OR_CHANNELIZERS-1);

-- attribute S of ADC_DAT: signal is "yes";
-- attribute DONT_TOUCH of ADC_DAT: signal is "yes";


-----------------------
-- Channelizer signals
-----------------------
constant NUMBER_OF_CHAN_CLOCKS : integer := max(8, max( NUMBER_OF_CHANNELIZERS, NUMBER_OF_ADCS)); -- Number of channelizer clocks. There is a minimum of 8 that are always provided by the clock generator, even if we don't use them all. Also, we need at least one for the ADCs even if there is no channelizer connected to it.
signal chan_clk_pll : std_logic_vector(0 to 7); -- Pll-generated, 7-phase clocks
signal chan_reset_pll : std_logic_vector(0 to 7); -- reset signals synchronous to the clocks above

signal chan_clk : std_logic_vector(0 to NUMBER_OF_CHAN_CLOCKS-1); -- channelizer clocks
signal chan_reset : std_logic_vector(0 to NUMBER_OF_CHAN_CLOCKS-1);
signal chan_clk_src_sel: std_logic;
--signal chan_clk_rst_in: std_logic;
--signal user_chan_reset_async: std_logic;

signal axis_chan_out_tdata: slv32_array(0 to NUMBER_OF_CHANNELIZERS-1);
signal axis_chan_out_tuser: slv4_array(0 to NUMBER_OF_CHANNELIZERS-1);
signal axis_chan_out_tvalid: slv(0 to NUMBER_OF_CHANNELIZERS-1);
signal axis_chan_out_tlast: slv(0 to NUMBER_OF_CHANNELIZERS-1);

attribute equivalent_register_removal of axis_chan_out_tdata: signal is "no";
attribute equivalent_register_removal of axis_chan_out_tuser: signal is "no";
attribute equivalent_register_removal of axis_chan_out_tvalid: signal is "no";
attribute equivalent_register_removal of axis_chan_out_tlast: signal is "no";

attribute shreg_extract of axis_chan_out_tdata: signal is "no";
attribute shreg_extract of axis_chan_out_tuser: signal is "no";
attribute shreg_extract of axis_chan_out_tvalid: signal is "no";
attribute shreg_extract of axis_chan_out_tlast: signal is "no";

--attribute shreg_extract of ANT_DAT_TIMING_REG3: signal is "no";

signal TRIG:   std_logic; -- global trigger
signal ADC_DAQ_BUFR_SYNC: std_logic;
signal ADCDAQ_RESET: std_logic;


-----------------------
-- CROSSBAR signals
-----------------------
-- signal axis_crossbar1_in_mosi: AXIS32_DAT_STRUCT_ARRAY(0 to NUMBER_OF_CROSSBAR_INPUTS-1);
signal axis_crossbar1_in_clk: std_logic_vector(0 to NUMBER_OF_CROSSBAR_INPUTS-1);

signal axis_crossbar1_in_tdata: slv32_array(0 to NUMBER_OF_CROSSBAR_INPUTS-1);
signal axis_crossbar1_in_tuser: slv4_array(0 to NUMBER_OF_CROSSBAR_INPUTS-1);
signal axis_crossbar1_in_tvalid: slv(0 to NUMBER_OF_CROSSBAR_INPUTS-1);
signal axis_crossbar1_in_tlast: slv(0 to NUMBER_OF_CROSSBAR_INPUTS-1);

signal axis_crossbar1_in_tdata_reg: slv32_array(0 to NUMBER_OF_CROSSBAR_INPUTS-1);
signal axis_crossbar1_in_tuser_reg: slv4_array(0 to NUMBER_OF_CROSSBAR_INPUTS-1);
signal axis_crossbar1_in_tvalid_reg: slv(0 to NUMBER_OF_CROSSBAR_INPUTS-1);
signal axis_crossbar1_in_tlast_reg: slv(0 to NUMBER_OF_CROSSBAR_INPUTS-1);

signal axis_crossbar1_in_tdata_reg2: slv32_array(0 to NUMBER_OF_CROSSBAR_INPUTS-1);
signal axis_crossbar1_in_tuser_reg2: slv4_array(0 to NUMBER_OF_CROSSBAR_INPUTS-1);
signal axis_crossbar1_in_tvalid_reg2: slv(0 to NUMBER_OF_CROSSBAR_INPUTS-1);
signal axis_crossbar1_in_tlast_reg2: slv(0 to NUMBER_OF_CROSSBAR_INPUTS-1);

attribute shreg_extract of axis_crossbar1_in_tdata_reg: signal is "no";
attribute shreg_extract of axis_crossbar1_in_tuser_reg: signal is "no";
attribute shreg_extract of axis_crossbar1_in_tvalid_reg: signal is "no";
attribute shreg_extract of axis_crossbar1_in_tlast_reg: signal is "no";

attribute shreg_extract of axis_crossbar1_in_tdata_reg2: signal is "no";
attribute shreg_extract of axis_crossbar1_in_tuser_reg2: signal is "no";
attribute shreg_extract of axis_crossbar1_in_tvalid_reg2: signal is "no";
attribute shreg_extract of axis_crossbar1_in_tlast_reg2: signal is "no";


signal cb1_reset: std_logic;
signal cb1_reset_reg: std_logic;
signal cb1_reset_reg2: std_logic;

signal axis_crossbar1_out_tdata: slv32_array(0 to NUMBER_OF_CROSSBAR_OUTPUTS-1);
signal axis_crossbar1_out_tvalid: slv(0 to NUMBER_OF_CROSSBAR_OUTPUTS-1);
signal axis_crossbar1_out_tlast: slv(0 to NUMBER_OF_CROSSBAR_OUTPUTS-1);
-- signal axis_crossbar1_out_tready: slv(0 to NUMBER_OF_CROSSBAR_OUTPUTS-1);

-----------------------
-- Backplane PCB & QUAD shuffle signals
-----------------------
-- PCB and QSFP lanes are concatenated into a single vector to be handled by a single xlink_array module.

-- signal axis_bp_shuffle_bypass: std_logic;

signal axis_bp_shuffle_in_tdata: slv32_array(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES + NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1);
signal axis_bp_shuffle_in_tvalid: slv(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES + NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1);
signal axis_bp_shuffle_in_tlast: slv(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES + NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1);
-- signal axis_bp_shuffle_in_tready: slv(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES + NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1);

signal axis_bp_shuffle_out_tdata: slv32_array(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES + NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1);
-- signal axis_bp_shuffle_out_tuser: slv4_array(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES + NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1);
signal axis_bp_shuffle_out_tvalid: slv(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES + NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1);
signal axis_bp_shuffle_out_tlast: slv(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES + NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1);
-- signal axis_bp_shuffle_out_tready: slv(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES + NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1);
-- signal axis_bp_shuffle_out_clk: slv(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES + NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1);
signal ct_clk: std_logic; -- corner turn engine clock
signal ct_clk_div2: std_logic;
signal bp_shuffle_txclk: std_logic; -- 244/322 MHz data clock from backplane shuffle
signal cge_txclk: std_logic; -- 322 data clock from 100G Ethernet

signal bp_shuffle_reset: std_logic_vector(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES + NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1);
signal bp_shuffle_reset_reg: std_logic;
attribute shreg_extract of bp_shuffle_reset_reg: signal is "no";

-----------------------
-- Crossbar 2 signals
-----------------------

signal axis_crossbar2_in_tdata: slv32_array(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES-1);
signal axis_crossbar2_in_tvalid: slv(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES-1);
signal axis_crossbar2_in_tlast: slv(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES-1);

signal axis_crossbar2_in_tdata_reg: slv32_array(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES-1);
signal axis_crossbar2_in_tvalid_reg: slv(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES-1);
signal axis_crossbar2_in_tlast_reg: slv(0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES-1);

attribute shreg_extract of axis_crossbar2_in_tdata_reg: signal is "no";
attribute shreg_extract of axis_crossbar2_in_tvalid_reg: signal is "no";
attribute shreg_extract of axis_crossbar2_in_tlast_reg: signal is "no";

signal axis_crossbar2_in_reset: std_logic;
signal axis_crossbar2_in_reset_reg: std_logic;
signal axis_crossbar2_in_reset_reg2: std_logic;
attribute shreg_extract of axis_crossbar2_in_reset_reg: signal is "no";
attribute shreg_extract of axis_crossbar2_in_reset_reg2: signal is "no";


signal axis_crossbar2_out_tdata: slv32_array(0 to NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1);
signal axis_crossbar2_out_tvalid: slv(0 to NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1);
signal axis_crossbar2_out_tlast: slv(0 to NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1);

-----------------------
-- Crossbar 3 signals
-----------------------

signal axis_crossbar3_in_tdata: slv32_array(0 to NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1);
signal axis_crossbar3_in_tvalid: slv(0 to NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1);
signal axis_crossbar3_in_tlast: slv(0 to NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1);

signal axis_crossbar3_reset: std_logic;
signal axis_crossbar3_reset_reg: std_logic;
signal axis_crossbar3_reset_reg2: std_logic;

signal axis_crossbar3_out_tdata: slv32_array(0 to NUMBER_OF_GPU_LINKS-1);
signal axis_crossbar3_out_tvalid: slv(0 to NUMBER_OF_GPU_LINKS-1);
signal axis_crossbar3_out_tlast: slv(0 to NUMBER_OF_GPU_LINKS-1);
-- signal axis_crossbar2_out_tready: slv(0 to NUMBER_OF_GPU_LINKS-1);



signal ct_reset: std_logic;
signal ct_reset_pre: std_logic;
signal ct_reset_reg: std_logic;

-----------------------
-- GPU LINK signals
-----------------------

signal axis_gpu_tdata: slv32_array(0 to NUMBER_OF_GPU_LINKS-1);
signal axis_gpu_tvalid: slv(0 to NUMBER_OF_GPU_LINKS-1);
signal axis_gpu_tlast: slv(0 to NUMBER_OF_GPU_LINKS-1);
-- signal axis_gpu_clk: slv(NUMBER_OF_GPU_LINKS-1 downto 0);

-----------------------
-- CORR signals
-----------------------

signal axis_corr_in_tdata: slv32_array(0 to NUMBER_OF_CORRELATORS-1);
signal axis_corr_in_tvalid: slv(0 to NUMBER_OF_CORRELATORS-1);
signal axis_corr_in_tlast: slv(0 to NUMBER_OF_CORRELATORS-1);

signal axis_corr_out_tdata: slv8_array(0 to NUMBER_OF_CORRELATORS-1);
signal axis_corr_out_tvalid: slv(0 to NUMBER_OF_CORRELATORS-1);
signal axis_corr_out_tlast: slv(0 to NUMBER_OF_CORRELATORS-1);
signal axis_corr_out_tready: slv(0 to NUMBER_OF_CORRELATORS-1);


-----------------------
-- RESET network
-----------------------

signal gpu_reset: std_logic;
signal gpu_reset_reg: std_logic;

signal top_router_rst: std_logic;
signal udp_stack_rst: std_logic;
signal ctrl_master_rst: std_logic;
signal sys_ctrl_rst: std_logic;
signal sys_ctrl_rst_reg: std_logic;
signal sysmon_ctrl_rst: std_logic;
signal refclk_ctrl_rst: std_logic;
signal chan_router_ctrl_rst: std_logic;
signal adcdaq_ctrl_rst: std_logic_vector(0 to NUMBER_OF_ADCS-1);
signal adcdaq_ctrl_rst_reg: std_logic_vector(0 to NUMBER_OF_ADCS-1);
signal chan_ctrl_rst: std_logic_vector(0 to NUMBER_OF_CHANNELIZERS-1);
signal chan_ctrl_rst_reg: std_logic_vector(0 to NUMBER_OF_CHANNELIZERS-1);
signal crossbar1_ctrl_rst: std_logic;
signal crossbar2_ctrl_rst: std_logic;
signal crossbar3_ctrl_rst: std_logic;
signal bp_shuffle_ctrl_rst: std_logic;
signal bp_shuffle_ctrl_rst_reg: std_logic;
signal gpu_ctrl_rst: std_logic;
signal gpu_ctrl_rst_reg: std_logic;

-- attribute shreg_extract of top_router_rst: signal is "no";
-- attribute shreg_extract of sys_ctrl_rst: signal is "no";
-- attribute shreg_extract of sys_ctrl_rst_reg: signal is "no";
-- attribute shreg_extract of chan_router_ctrl_rst: signal is "no";
-- attribute shreg_extract of adcdaq_ctrl_rst: signal is "no";
-- attribute shreg_extract of chan_ctrl_rst: signal is "no";
-- attribute shreg_extract of crossbar1_ctrl_rst: signal is "no";
-- attribute shreg_extract of crossbar2_ctrl_rst: signal is "no";
-- attribute shreg_extract of crossbar3_ctrl_rst: signal is "no";
-- attribute shreg_extract of bp_shuffle_ctrl_rst: signal is "no";
-- attribute shreg_extract of bp_shuffle_ctrl_rst_reg: signal is "no";
-- attribute shreg_extract of gpu_ctrl_rst: signal is "no";
-- attribute shreg_extract of gpu_ctrl_rst_reg: signal is "no";


attribute DONT_TOUCH of top_router_rst: signal is "true";
attribute DONT_TOUCH of udp_stack_rst: signal is "true";
attribute DONT_TOUCH of ctrl_master_rst: signal is "true";
attribute DONT_TOUCH of sys_ctrl_rst: signal is "true";
attribute DONT_TOUCH of sys_ctrl_rst_reg: signal is "true";
attribute DONT_TOUCH of sysmon_ctrl_rst: signal is "true";
attribute DONT_TOUCH of refclk_ctrl_rst: signal is "true";
attribute DONT_TOUCH of chan_router_ctrl_rst: signal is "true";
attribute DONT_TOUCH of adcdaq_ctrl_rst: signal is "true";
attribute DONT_TOUCH of adcdaq_ctrl_rst_reg: signal is "true";
attribute DONT_TOUCH of chan_ctrl_rst: signal is "true";
attribute DONT_TOUCH of chan_ctrl_rst_reg: signal is "true";
attribute DONT_TOUCH of crossbar1_ctrl_rst: signal is "true";
attribute DONT_TOUCH of crossbar2_ctrl_rst: signal is "true";
attribute DONT_TOUCH of crossbar3_ctrl_rst: signal is "true";
attribute DONT_TOUCH of bp_shuffle_ctrl_rst: signal is "true";
attribute DONT_TOUCH of bp_shuffle_ctrl_rst_reg: signal is "true";
attribute DONT_TOUCH of gpu_ctrl_rst: signal is "true";
attribute DONT_TOUCH of gpu_ctrl_rst_reg: signal is "true";


-- -----------------------
-- -- CORRELATOR signals
-- -----------------------


-- signal axis_corr_in_mosi: AXIS32_DAT_STRUCT_ARRAY(0 to NUMBER_OF_CORRELATORS-1);
-- signal axis_corr_in_reset: std_logic_vector(0 to NUMBER_OF_CORRELATORS-1); --! synchronous reset for all correlator blocks

-- attribute equivalent_register_removal of axis_corr_in_mosi : signal is "no";
-- attribute shreg_extract of axis_corr_in_mosi: signal is "no";
-- attribute equivalent_register_removal of axis_corr_in_reset : signal is "no";
-- attribute shreg_extract of axis_corr_in_reset: signal is "no";



-- Frequency counter-related signals and constants
constant NUMBER_OF_FREQ_CTR_PORTS: integer:= 39;
signal freq_ctr_in_vect: std_logic_vector(0 to NUMBER_OF_FREQ_CTR_PORTS-1);

signal sfp_refclk_div2: std_logic:= '0'; --init required for sims
signal clk10_div2: std_logic:= '0'; --init required for sims
signal clk200_div2: std_logic:='0'; -- Initialization required
signal CTRL_CLK_DIV2: std_logic :='0'; -- Initialization required
signal chan_clk_div2: std_logic :='0'; -- -- Initialization required
signal CORR_CLK_DIV2: std_logic :='0';  -- Initialization required
signal SYSMON_CLK_DIV2: std_logic :='0'; -- Initialization required
signal adc_clk_div2 : std_logic_vector(0 to NUMBER_OF_ADCS_OR_CHANNELIZERS-1); --! 1/2 ADC_CLK frequency generated by logic to feed the frequyency counter without using clock routing ressources
signal adc_clkout_div2 : std_logic_vector(0 to adc_clkout'LENGTH-1); --! 1/2 ADC_CLK frequency generated by the external ADC output
signal fmc_mgt_pll_refclk_div2: std_logic_vector(0 to max(NUMBER_OF_ADC_BOARDS, 4) - 1); --Need  minimum of four for freq ctr assignments
signal FMC_REFCLK_DIV2: std_logic_vector(0 to max(NUMBER_OF_ADC_BOARDS, 2) - 1); --Need  minimum of two for freq ctr assignments
signal FAN_TACH_DIV2: std_logic;
signal gpu_refclk_div2: std_logic_vector(0 to NUMBER_OF_GPU_REFCLKS-1);
signal gpu_txclk_div2: std_logic;
signal bp_shuffle_refclk_div2: std_logic_vector(0 to NUMBER_OF_BP_SHUFFLE_REFCLKS -1);
signal bp_shuffle_txclk_div2: std_logic;
signal raw_clk10_div2: std_logic := '0'; -- Initialization required for sims
signal mgt_clk100_div2: std_logic := '0'; -- Initialization required for sims
signal mgt_clk200_div2: std_logic := '0'; -- Initialization required for sims
signal mgt_clk125_div2: std_logic := '0'; -- Initialization required for sims



-- SPI signals
signal spi_rst_n_int: std_logic; -- SPI reset output signal

-- GPIO signals
signal ADCDAQ_RESET_ASYNC: std_logic;
signal gpio_irib_mux_in: std_logic_vector(0 to 7);
signal gpio_pwm_ctr_en:  std_logic;
signal gpio_pwm_ctr_en_reg:  std_logic;
constant NUMBER_OF_USER_SMA_SIGNALS: integer := 16;
signal gpio_user_mux_signals:  std_logic_vector(0 to NUMBER_OF_USER_SMA_SIGNALS-1);
signal user_mux_out_int: std_logic_vector(0 to 3);
signal gpio_udp_tx_frame:  std_logic;
signal gpio_udp_rx_frame:  std_logic;
signal gpio_event_ctr_en: std_logic;
signal gpio_event_ctr_inc: std_logic;
signal gpio_event_ctr_en_reg: std_logic;
signal gpio_event_ctr_inc_reg: std_logic;
signal gpio_event_ctr_reset_reg: std_logic;
signal chan_lane_monitor: slv4_array(0 to NUMBER_OF_CHANNELIZERS-1);


-- REFCLK signals
signal refclk_irigb_sync_in: std_logic;
-- Blinker signals
signal blinker_rst: std_logic;
signal blinker_kick: std_logic;

-- buck sync
signal bp_buck_sync_mon: std_logic;

--signal GPIO_BUFR_RST: std_logic;
signal REFCLK_ADCDAQ_RESET: std_logic;
--signal REFCLK_BUFR_RST: std_logic;

signal ADC_RST: std_logic_vector(0 to NUMBER_OF_ADC_BOARDS-1) := (others=>'0'); --! non-inverted ADC Reset line (the external ADC reset is active LOW)


-- signal corr_reset_async_delay  : std_logic; --! Reset for all correlator processors, synchronized to ANT_CLK
signal sfp_refclk_nobuf: std_logic;
signal sfp_refclk_buf: std_logic;

signal BLINKER_RESET: std_logic; --!
signal BLINKER_RESET_ALL: std_logic; --!

signal udp_tx_overflow: std_logic;
signal udp_rx_overflow: std_logic;

-- signal bp_shuffle_lock: std_logic_vector(0 to NUMBER_OF_BP_SHUFFLE_LINKS-1);

signal pwm_out: std_logic;
signal pps_out: std_logic;
signal irigb_gen_out: std_logic;
signal irigb_before_target: std_logic;
signal sync_out: std_logic;

signal clk200_ctr: unsigned(15 downto 0);
signal clk10_ctr: unsigned(7 downto 0);
signal sysmon_clk_ctr: unsigned(7 downto 0);


-- ADC signals



begin

-- Generics validation
assert NUMBER_OF_ADCS>0 and (ADC_TYPE="EV8AQ160" or ADC_TYPE="AXIS") report "ADC_TYPE must be EV8AQ160 or AXIS";

-------------------------------------------------------------------
-- Instantiate System clocks
-------------------------------------------------------------------

--debug_out(7 downto 0) <= cmd_packet_counter;
--debug_out(15 downto 0) <= std_logic_vector(clk200_ctr);
--debug_out(23 downto 16) <= std_logic_vector(clk10_ctr);
--debug_out(31 downto 24) <= std_logic_vector(sysmon_clk_ctr);
--debug_out(16) <= ctrl_rst;
--debug_out(17) <= cpu_reset;
--debug_out(18) <= user_reset;
--debug_out(19) <= clk10_div2;
--debug_out(20) <= clk200_div2;
--debug_out(21) <= CTRL_CLK_DIV2;
--debug_out(22) <= CORR_CLK_DIV2;
--debug_out(23) <= SYSMON_CLK_DIV2;

--debug_out(24) <= axis_cmd_tvalid;
--debug_out(25) <= axis_rply_tvalid;
--debug_out(26) <= top_cmd_dat(0).TVALID;
--debug_out(27) <= top_rply_dat(0).TVALID;
sma_out(0) <= clk200;
sma_out(1) <= clk200_reset;
sma_out(2) <= clk10;
sma_out(3) <= sysclk_bufg;






ALL_RESET<=  cpu_reset or user_reset;
--end generate; --debug7

--! Instantiate the system clock generator that generates the local 200 MHz and 125 MHz from the external 200 MHz lines
CLK0: entity work.CLOCKS
	generic map (
		PLATFORM_ID => PLATFORM_ID,
		CLOCK_SOURCE => SYSTEM_CLOCK_SOURCE, -- "SYSCLK" or "SFP_REFCLK"
		CHAN_CLK_SPEED => CHAN_CLK_SPEED
		)
	port map
		(
		-- System clock input
		SYSCLK_P     => SYSCLK_P, --! differential 200 MHz clock input from CLock-Capable (CC) input pins
		SYSCLK_N     => SYSCLK_N,
		sysclk_bufg  => sysclk_bufg,
		sfp_refclk_p => sfp_clk_p, --! differential 125 MHz clock from GTX reference clock input pins
		sfp_refclk_n => sfp_clk_n,
		sfp_refclk_nobuf => sfp_refclk_nobuf, -- Unbuffered sfp reference clock, to be used by the GTX core
		sfp_refclk_buf => sfp_refclk_buf, -- Buffered (BUFG)

		-- ADC clock input
		adc_clk => adc_clk_bufg,-- BUFG-buffered clock provided by one ADCDAQ, used to generate the 8 channel clocks that are synchronous to the data stream.


		-- System clocks
		clk200 => clk200, -- The directly buffered (BUFG) version of SYSCLK will be used if available for better jitter performance, otherwise the 200 MMCM output is used.
		clk200_reset_out => clk200_reset,

		CLK125 => clk125,
		clk125_reset_out => clk125_reset,

		CORR_CLK => CORR_CLK, -- Correlator clock
		corr_reset_in => corr_reset_async,
		corr_reset_out => corr_reset,

		sysmon_clk => sysmon_clk, -- System monitor clock
		sysmon_reset_out => sysmon_reset,

		-- Channelizer clocks
		chan_clk_src_sel => chan_clk_src_sel, -- '0': ADC clock, '1': internal 200 MHz clock
		chan_pll_reset_in => chan_clk_reset_async, --! resets the channelizer PLL/MMCM (needed whan the clock source is changed)
		chan_clk => chan_clk_pll, --! Channelizer clocks (7 phases)
		chan_reset_in => chan_reset_async,
		chan_reset_out => chan_reset_pll,

		sequence_reset_in => ADCDAQ_RESET, --! starts the channelizer/correlator reset sequence
		-- Reset
		RST_IN=>ALL_RESET -- master asynchronous reset
		);



ctrl_clk_sel7: if PLATFORM_ID=PLATFORM_ID_MGK7MB generate
	ctrl_clk <= clk125; -- Control system master clock
	ctrl_rst_proc: process(ctrl_clk)
	begin
		if rising_edge(ctrl_clk) then
			ctrl_rst <= clk125_reset or ctrl_reset_pulse;
		end if;
	end process;

end generate;

ctrl_clk_up: if PLATFORM_ID=PLATFORM_ID_ZCU111 generate
	ctrl_clk <= bsb_axis_clk; -- Control system master clock
	ctrl_rst <= bsb_axis_rst or ctrl_reset_pulse;
end generate;


-- Pipeline clk125 reset
clk125pipeproc: process(clk125)
	begin
		if rising_edge(clk125) then
			udp_stack_rst <= ctrl_rst or udp_stack_reset;
		end if; -- RST/CLK
	end process;

-- Pipeline the BSB resets to help them propagate across the chip
bsb_rst_proc: process(ctrl_clk)
	begin
		if rising_edge(ctrl_clk) then
			top_router_rst          <= ctrl_rst;
			ctrl_master_rst         <= ctrl_rst or ctrl_master_reset;
			sys_ctrl_rst            <= ctrl_rst;
			sys_ctrl_rst_reg        <= sys_ctrl_rst;
			sysmon_ctrl_rst         <= ctrl_rst;
			refclk_ctrl_rst         <= ctrl_rst;
			chan_router_ctrl_rst    <= ctrl_rst;
			adcdaq_ctrl_rst         <= (others => ctrl_rst);
			chan_ctrl_rst           <= (others => ctrl_rst);
			adcdaq_ctrl_rst_reg     <= adcdaq_ctrl_rst;
			chan_ctrl_rst_reg       <= chan_ctrl_rst;
			crossbar1_ctrl_rst      <= ctrl_rst;
			crossbar2_ctrl_rst      <= ctrl_rst;
			crossbar3_ctrl_rst      <= ctrl_rst;
			bp_shuffle_ctrl_rst     <= ctrl_rst;
			bp_shuffle_ctrl_rst_reg <= bp_shuffle_ctrl_rst;
			gpu_ctrl_rst            <= ctrl_rst;
			gpu_ctrl_rst_reg        <= gpu_ctrl_rst;
		end if; -- RST/CLK
	end process;


-- Pipeline clk200 reset to allow it ti propagate across the chip
clk200pipeproc: process(clk200)
begin
	if rising_edge(clk200) then
		clk200_reset_reg <= clk200_reset;
	end if; -- RST/CLK
end process;



-- Select which clock to use for the corner-turn engine
ct_clk <= bp_shuffle_txclk when IMPLEMENT_CROSSBAR2_AND_CROSSBAR3 else
          cge_txclk when IMPLEMENT_100G_ETHERNET else
          corr_clk;

-- Generate a logic signal for the frequency counter
ct_clk_div2_proc: process(ct_clk)
	begin
		if rising_edge(ct_clk) then
			ct_clk_div2 <= not ct_clk_div2;
		end if; -- clk
end process;

-- Generate a corner-turn engine reset synchronous to ct_clk
ct_reset_cdc0: xpm_cdc_single
	generic map (SRC_INPUT_REG => 0)
	port map (
		src_in => corr_reset_async,
		dest_clk => ct_clk,
		dest_out => ct_reset_pre
	);

-- Generate corner-turn engine root reset signals
ct_reset_pipe_proc: process(ct_clk)
begin
	if rising_edge(ct_clk) then
		ct_reset <= ct_reset_pre;
		ct_reset_reg <= ct_reset; -- pipeline
	end if;
end process;

gen_eth: if PHY_TYPE /= "NONE" generate
---------------------------------------------------------------------
-- UDP Interface
---------------------------------------------------------------------
--! Instantiate UDP / IP / Ethernet interface
	tx_ready <= axis_udp_tx_tready;

--	local_mac_addr <= std_logic_vector'(X"12_34_56_78") & local_ip_addr; -- works
--	local_mac_addr <= std_logic_vector(unsigned(std_logic_vector'(X"12_34_56_78") & local_ip_addr)); -- does not work
--	test <= unsigned(std_logic_vector'(X"12_34_56_78") & local_ip_addr); -- does not work - 9 defs for &
--	test <= unsigned'(std_logic_vector'(X"12_34_56_78") & local_ip_addr); -- does not work - 0 def for &
--	test <= unsigned(std_logic_vector'(std_logic_vector'(X"12_34_56_78") & std_logic_vector'(local_ip_addr))); --  works
--	test <= unsigned(std_logic_vector'(std_logic_vector'(X"12_34_56_78") & local_ip_addr)); -- works
--	test <= unsigned(std_logic_vector'(X"12_34_56_78" & local_ip_addr)); -- works.
--	local_mac_addr <= std_logic_vector(unsigned(std_logic_vector'(X"12_34_56_78") & std_logic_vector'(local_ip_addr)) + unsigned(GPIO_DIP_SW));
	-- local_mac_addr <= to_slv(unsigned(std_logic_vector'(X"12_34_56_78" & local_ip_addr)) + unsigned(GPIO_DIP_SW));
	-- RX_IP_DEST_ADDR <= to_slv((unsigned'(X"0A_0A") & unsigned(local_ip_addr)) + unsigned(GPIO_DIP_SW));
	sfp_status_vector <= sfp_status_vector_int;
	udp_mac0: entity work.udp_mac  -- use component instantitation to defer binding
		GENERIC MAP(
			PHY_TYPE=> PHY_TYPE,  -- "GMII": Alaska 881111 PHY,  or "SGMII": SFP module
			SGMII_CLOCK_SOURCE => SGMII_CLOCK_SOURCE,
			BROADCAST_IP_PORT => 41000, -- port on which broadcast requests and replies are made. This is fixed as it is used to discover the boards on the network and configure them.
			SIM => SIM
			)
		PORT MAP(

			-- UDP incoming traffic network parameters
			local_mac_addr =>local_mac_addr,
			local_ip_addr  =>local_ip_addr,
			local_ip_port  =>local_base_ip_port,
			local_subarray => local_subarray,
			-- User-side streaming interface

			-- UDP outgoing traffic port/channel 0 network parameters
			remote_mac_addr0 => slv48'(others=>'0'), -- Auto detect: Use last incoming packet source mac
			remote_ip_addr0  => slv32'(others=>'0'), -- Auto detect: Use last incoming packet source ip
			remote_ip_port0  => remote_ip_port0, -- If 0: Use last incoming packet source port number

			-- UDP outgoing traffic port/channel 1 network parameters
			remote_mac_addr1 => remote_mac_addr1, -- If 0: Use last incoming packet source mac
			remote_ip_addr1  => remote_ip_addr1, -- If 0: Use last incoming packet source ip
			remote_ip_port1  => remote_ip_port1, -- If 0: Use last incoming packet source port number + 1 (*** Notice the "+ 1" ***)

			-- GMII Phy interface (connects to Marvell chip pins)
			phy_rxclk        => phy_rxclk,
			phy_txer         => phy_txer,
			phy_reset_l      => phy_reset_l,
			phy_rxctrl_rxdv  => phy_rxctrl_rxdv,
			phy_rxd          => phy_rxd,
			phy_txc_gtxclk   => phy_txc_gtxclk, -- TX bus clock povided by the FPGA to the PHY
			phy_txctl_txen   => phy_txctl_txen,
			phy_txd          => phy_txd,
			phy_txclk        => phy_txclk, -- TX bus Clock provided *BY* the PHY for MII interfaces only. Not used.

			-- SGMII PHY interface (connects to SFP module pins and refernence clock source)
			-- sfp_clk_p => sfp_clk_p,
			-- sfp_clk_n => sfp_clk_n,
			sfp_tx_p => sfp_tx_p,
			sfp_tx_n => sfp_tx_n,
			sfp_rx_p => sfp_rx_p,
			sfp_rx_n => sfp_rx_n,

			-- SGMII reference clock
			sfp_refclk_nobuf => sfp_refclk_nobuf, -- Unbuffered 125 MHz clock from the SFP reference clock.
			sfp_refclk_buf => sfp_refclk_buf, -- Buffered 125 MHz clock from the SFP reference clock.

			-- SGMII-specific status signals
			status_vector => sfp_status_vector_int,
			config_vector => sfp_config_vector,

			mmcm_locked => sfp_mmcm_locked,
			reset_done => sfp_reset_done,
			signal_detect => not ctrl_master_reset,
			-- User TX interface
			s_axis_udp_tx_tvalid => axis_udp_tx_tvalid,
			s_axis_udp_tx_tdata  => axis_udp_tx_tdata,
			s_axis_udp_tx_tlast  => axis_udp_tx_tlast,
			s_axis_udp_tx_tready => axis_udp_tx_tready,
			tx_port              => udp0_tx_port,

			m_axis_udp_rx_tdata  => axis_udp_rx_tdata,
			m_axis_udp_rx_tvalid => axis_udp_rx_tvalid,
			m_axis_udp_rx_tlast  => axis_udp_rx_tlast,
			m_axis_udp_rx_tready => axis_udp_rx_tready,

			tx_overflow          => udp_tx_overflow,
			rx_overflow          => udp_rx_overflow,

			clk125 => clk125, -- User RX/TX interface clock AND GMII transmit clock (SGMII uses either this or th SFP reference clock). For SGMII, this must be a stable clock not related to any of the SGMII clocks.
			-- clk200 => clk200, -- used for the SGMII interface to initialize the cores even if the transceiver is not locked

			-- rst => ctrl_rst
			rst => udp_stack_rst
		);


end generate;

-- If we don't have an ethernet interface, take the BSB interface directly from the top level entity.
gen_noeth: if PHY_TYPE = "NONE" generate
	-- Command bus comes from the external bus
	axis_udp_rx_tdata <= s_bsb_axis_tdata(7 downto 0);
	axis_udp_rx_tvalid <= s_bsb_axis_tvalid;
	axis_udp_rx_tlast <= s_bsb_axis_tlast;
	-- Reply bus TREADY
	axis_udp_tx_tready <= m_bsb_axis_tready;
	sfp_status_vector_int(0) <= '1'; -- simulate valid link so the blinker will work
end generate;

-- We also always deive these signals on the output port, weather or not thay are used outside, to prevent warnings of undriven output port
-- Command bus TREADY
s_bsb_axis_tready <= axis_udp_rx_tready;
-- Reply bus
m_bsb_axis_tvalid <= axis_udp_tx_tvalid;
m_bsb_axis_tdata(31 downto 30) <= udp0_tx_port;
m_bsb_axis_tdata(29 downto 8) <= (others => '0');
m_bsb_axis_tdata(7 downto 0) <= axis_udp_tx_tdata;
m_bsb_axis_tlast <= axis_udp_tx_tlast;

ctrl_master0: entity work.ctrl_master
	GENERIC MAP (
		NUMBER_OF_PROBES=>NUMBER_OF_PROBES  -- number of data stream buses
		)
	PORT MAP(
		-- RX UDP stream
		s_axis_udp_rx_tdata => axis_udp_rx_tdata,
		s_axis_udp_rx_tvalid => axis_udp_rx_tvalid,
		s_axis_udp_rx_tlast => axis_udp_rx_tlast,
		s_axis_udp_rx_tready => axis_udp_rx_tready,

		-- TX UDP stream
		m_axis_udp_tx_tvalid => axis_udp_tx_tvalid,
		m_axis_udp_tx_tdata => axis_udp_tx_tdata,
		m_axis_udp_tx_tlast => axis_udp_tx_tlast,
		m_axis_udp_tx_tready => axis_udp_tx_tready,
		m_axis_udp_tx_channel => udp0_tx_port,

		-- Command and reply stream buse
		m_axis_cmd_tdata => axis_cmd_tdata,
		m_axis_cmd_tvalid => axis_cmd_tvalid,
		m_axis_cmd_tlast => axis_cmd_tlast,
		m_axis_cmd_tready => axis_cmd_tready,

		s_axis_rply_tdata => axis_rply_tdata,
		s_axis_rply_tvalid => axis_rply_tvalid,
		s_axis_rply_tlast => axis_rply_tlast,
		s_axis_rply_tready => axis_rply_tready,

		-- Data stream buses
		s_axis_data_tdata => axis_prb_tdata,
		s_axis_data_tvalid => axis_prb_tvalid,
		s_axis_data_tlast => axis_prb_tlast,
		s_axis_data_tready => axis_prb_tready,

		-- System
		cmd_packet_counter => cmd_packet_counter,
		rply_packet_counter => rply_packet_counter,
		HOST_FRAME_READ_RATE => HOST_FRAME_READ_RATE,
		CLK => CTRL_CLK, -- Common clock for all bus accesses
		RST => ctrl_master_rst
	);


------------------------------------------
--! Top level command interface router
------------------------------------------
--! Routes the commands and replies to/from the top-level modules (ANTs, CORRs,  and system modules)


--startLiteralInclude
--------------------------------------------------
-- TOP-LEVEL COMMAND ROUTER
--------------------------------------------------
--!@addtogroup memory_map
--! Top-level Memoy map
--!
--! | #  | Base Addr| Subaddresses                       | Description |
--! |    |----------|------------------------------------|-------------|
--! |  0 | 0x00000  | SYSTEM                             |             |
--! |  1 | 0x10000  | ADC & Channelizers                 |             |
--! |  2 | 0x20000  | Crossbar 1                         |             |
--! |  3 | 0x30000  | GPU Links                          |             |
--! |  4 | 0x40000  | Crossbar 3                         |             |
--! |  5 | 0x50000  | BP Shuffle                         |             |
--! |  6 | 0x60000  | Crossbar 2                         |             |
--! |  7 | 0x70000  | (unused)                           |             |
--stopLiteralInclude

UDP_CMD_DAT.TDATA <= axis_cmd_tdata;
UDP_CMD_DAT.TVALID <= axis_cmd_tvalid;
UDP_CMD_DAT.TLAST <= axis_cmd_tlast;
axis_cmd_tready <= UDP_CMD_RDY.TREADY;

axis_rply_tdata <= UDP_RPLY_DAT.TDATA ;
axis_rply_tvalid <= UDP_RPLY_DAT.TVALID;
axis_rply_tlast <= UDP_RPLY_DAT.TLAST ;
UDP_RPLY_RDY.TREADY <= axis_rply_tready;

top_router0: entity work.CTRL_ROUTER
	GENERIC MAP (
		NUMBER_OF_PORTS=>NUMBER_OF_PORTS,
		ADDRESS_MASK => "-111----------------" --'1': used to generate port index, '-' = don't care,
		-- PORT_NUMBER_HIGH_BIT=> CTRL_PORT_NUMBER_RANGE'HIGH,
		-- PORT_NUMBER_LOW_BIT=> CTRL_PORT_NUMBER_RANGE'LOW
	)
	PORT MAP(
		-- Master control interface
		CMD_IN_DAT=>  UDP_CMD_DAT,
		CMD_IN_RDY=>  UDP_CMD_RDY,
		RPLY_OUT_DAT=> UDP_RPLY_DAT,
		RPLY_OUT_RDY=> UDP_RPLY_RDY,


		CMD_OUT_DAT=> top_cmd_dat,
		CMD_OUT_RDY=> top_cmd_rdy,
		RPLY_IN_DAT=> top_rply_dat,
		RPLY_IN_RDY=> top_rply_rdy,

		-- Slave (module) control interface
		CLK => CTRL_CLK,
		RST => top_router_rst
	);

---------------------------------------------------------------------
---------------------------------------------------------------------
--  SYSTEM (SPI, FreqCTR,SYSMON, GPIO, etc.)
---------------------------------------------------------------------
---------------------------------------------------------------------


--!@addtogroup memory_map
--! SYSTEM Memory Map
--!
--! |#   |  Addr           | Module                       | Description |
--! |----|-----------------|------------------------------|-------------|
--! | 0  | Base + 0x00000  | GPIO                         |             |
--! | 1  | Base + 0x01000  | SYSMON                       |             |
--! | 2  | Base + 0x02000  | FREQ_CTR                     |             |
--! | 3  | Base + 0x03000  | SPI                          |             |
--! | 4  | Base + 0x04000  | REFCLK                       |             |
--! | 5  | Base + 0x05000  | I2C                          |             |
--! | 6  | Base + 0x06000  | (unused)                     |             |
--! | 7  | Base + 0x07000  | (unused)                     |             |

-- Index the system control buses as a separate signal here , because the simulator will make errors if we index it directly on the instantiation
TOP_SYS_CMD_DAT<= top_cmd_dat(SYSTEM_BASE_PORT);
top_cmd_rdy(SYSTEM_BASE_PORT) <= TOP_SYS_CMD_RDY;

TOP_SYS_RPLY_RDY<= top_rply_rdy(SYSTEM_BASE_PORT);
top_rply_dat(SYSTEM_BASE_PORT) <= TOP_SYS_RPLY_DAT;


---------------------------------------------------------------------
--! System command interface router
--! Routes one of the top-level command bus to the system modules (SPI, GPIO etc.)
---------------------------------------------------------------------
sys_router0: entity work.CTRL_ROUTER
	GENERIC MAP (
		NUMBER_OF_PORTS => NUMBER_OF_SYS_MODULES,
		ADDRESS_MASK => "----1111------------" --'1': used to generate port index, '-' = don't care,
		-- PORT_NUMBER_HIGH_BIT=> CTRL_MODULE_NUMBER_RANGE'HIGH,
		-- PORT_NUMBER_LOW_BIT=> CTRL_MODULE_NUMBER_RANGE'LOW
	)
	PORT MAP(
		-- Master control interface
		CMD_IN_DAT   => TOP_SYS_CMD_DAT,
		CMD_IN_RDY   => TOP_SYS_CMD_RDY,
		RPLY_OUT_DAT => TOP_SYS_RPLY_DAT,
		RPLY_OUT_RDY => TOP_SYS_RPLY_RDY,


		CMD_OUT_DAT => SYS_CMD_DAT,
		CMD_OUT_RDY => SYS_CMD_RDY,
		RPLY_IN_DAT => SYS_RPLY_DAT,
		RPLY_IN_RDY => SYS_RPLY_RDY,

		-- Slave (module) control interface
		CLK => CTRL_CLK,
		RST => sys_ctrl_rst_reg
	);


---------------------------------------------------------------------
-- GPIO interface instantiation
---------------------------------------------------------------------
--!   Controls the global hardware lines and system registers like the ADC RESET, LCD, Buck Regulators  etc.

-- Index the system control buses as a separate signal here , because the simulator will make errors if we index it directly on the instantiation
SYS_GPIO_CMD_DAT<= SYS_CMD_DAT(MODULE_GPIO_ADDR);
SYS_CMD_RDY(MODULE_GPIO_ADDR) <= SYS_GPIO_CMD_RDY;

SYS_GPIO_RPLY_RDY<= SYS_RPLY_RDY(MODULE_GPIO_ADDR);
SYS_RPLY_DAT(MODULE_GPIO_ADDR) <= SYS_GPIO_RPLY_DAT;

gen_timedly7: if FPGA_SERIES=FPGA_KINTEX7 generate
bp_time_dly0: IODELAYE1
	generic map (
		CINVCTRL_SEL => FALSE, -- Dynamically inverts the Clock (C) polarity.
		DELAY_SRC => "I", -- Specifies the source to the IODELAY component. "I" means it will be connected directly to an input port or IBUF (input mode)
		HIGH_PERFORMANCE_MODE => TRUE, -- When TRUE, this attribute reduces the output jitter.
		IDELAY_TYPE => "VAR_LOADABLE", -- Specifies a fixed, variable or default (eliminate hold time) input delay.
		REFCLK_FREQUENCY => 200.0, -- When using an associated IDELAYCTRL, specifies the input reference frequency to the component.
		SIGNAL_PATTERN => "CLOCK" -- Used by the delay calculator to determine different propagation
					-- delays through the IODELAY block based on the setting. DATA will be the addition of per tap delay and per tap jitter. No jitter is
					-- introduced for clock-like signals.
	)
	port map (

		-- Inputs
		IDATAIN => bp_time_in, -- 1-bit Data input to device from the I/O (connect directly to port, I/O Buffer). When IDATAIN is used, DATAIN must be tied to a logic zero (ground).
		CLKIN => '0', -- 1-bit Clock Access into the IODELAY (from the IO CLKMUX)
		DATAIN => '0', -- 1-bit Data input for the internal datapath delay. When DATAIN is used, IDATAIN and ODATAIN must be tied to a logic zero (ground).
		ODATAIN => '0', -- 1-bit Data input for the output datapath from the device (connect to output data source). When ODATAIN is used, DATAIN must be tied to a logic zero (ground).
		T => '1', -- 1-bit 3-state input control. Tie high for input-only or internal delay or tie low for output only.
		CINVCTRL => '0', -- 1-bit Dynamically inverts the Clock (C) polarity

		-- Delayed output
		DATAOUT => bp_time_io_dly, -- 1-bit Delayed data output from input port (connect to input datapath logic)

		-- Delay control
		CNTVALUEOUT => open, -- 5-bit Counter value going to fabric for monitoring purpose
		CNTVALUEIN => irigb_delay, -- 5-bit Counter value from fabric for loadable counter application
		C => CTRL_CLK, -- 1-bit Clock input (Must be connected for variable mode)
		INC => '0', -- 1-bit Increment / Decrement tap delay
		CE => '0', -- 1-bit Active high enable increment/decrement function
		RST => irigb_delay_reset -- 1-bit Active high, synchronous reset, resets delay chain to IDELAY_VALUE/

	);
end generate;


-- Pipeline backplane sync and trig signals to allow them to propagate across the chip
-- The IRIG-B decoder uses these signals and is clocked by clk200
bp_trig_sync_proc: process(clk200)
	begin
		if rising_edge(clk200) then
			bp_time_io_reg <= bp_time_io_dly;
			bp_time_reg <= bp_time_io_reg;

			bp_trig_io_reg <= bp_trig_in;
			bp_trig_reg <= bp_trig_io_reg;
		end if; -- RST/CLK
	end process;

-- arm_spi_pipe_proc: process(ctrl_clk)
-- 	begin
-- 		if rising_edge(ctrl_clk) then
-- 			-- Implement IOB Registers
-- 			arm_spi_sck_reg <= arm_spi_sck;
-- 			arm_spi_mosi_reg <= arm_spi_mosi;
-- 			arm_spi_miso <= arm_spi_miso_reg;
-- 			arm_spi_cs_n_reg <= arm_spi_cs_n;
-- 		end if; -- RST/CLK
-- 	end process;

gpio_irib_mux_in <= ( -- source for the IRIG-B signals
	0 => bp_trig_reg,
	1 => bp_time_reg,
	2 => irigb_gen_out,
	3 => bp_gpio_int_in,
	4 => user_mux_in(0), -- sma_a
	5 => user_mux_in(1), -- led2_sma_b
	6 => user_mux_in(2), -- led1_bp_sma
	7 => user_mux_in(3)
	); -- Backplane GPIO_INT signal


gpio_user_mux_signals <= ( -- source of the USER--controlled SMA output
	0 => sync_out, -- Sync signal
	1 => pps_out, -- Pulse-Per_second signal derived from the IRIG-B input
	2 => pwm_out, -- Frame-aligned programmable pulse generator
	3 => not irigb_before_target,
	4 => bp_trig_reg,
	5 => bp_time_reg,
	6 => clk10, --bp_buck_sync_mon,
	7 => irigb_gen_out,
	8 => gpio_led_int(4), -- heartbeat LED
	9 => gpio_led_int(7), -- out of phase heartbeat LED
	10 => adc_clk_div2(4*to_integer(unsigned(user_bit))), --was debug1. Modifiied to debug ADC clock output instabilities
	11 => debug2,
	12 => user_bit(0),
	13 => user_bit(1),
	14 => fmc_refclk(to_integer(unsigned(user_bit))),
	15 => '0'  -- output is disabled - use to read signals from the SMA on user_mux_in()
	-- 8: Copy of the 200 MHz clock of the master ADC. Useful to analyze the timing of the ADC clock relative to the 10 MHz reference clock to validate proper SYNCing.
	);

gpio_udp_tx_frame <= axis_udp_tx_tvalid and axis_udp_tx_tlast and axis_udp_tx_tready;
gpio_udp_rx_frame <= axis_udp_rx_tvalid and axis_udp_rx_tlast and axis_udp_rx_tready;

-- Pipeline event counter signals since they need to go across the FPGA from the ADCDAQ to GPIO areas
eventclkproc: process(chan_clk(0))
	begin
		if rising_edge(chan_clk(0)) then
			gpio_event_ctr_en <= axis_adc_tvalid(0);
			gpio_event_ctr_inc <= axis_adc_tlast(0);
			gpio_event_ctr_en_reg <= gpio_event_ctr_en; -- pipeline. we have a long way to go between ADCDAQ[0] and GPIO
			gpio_event_ctr_inc_reg <= gpio_event_ctr_inc; -- pipeline. we have a long way to go between ADCDAQ[0] and GPIO
			gpio_event_ctr_reset_reg <=  chan_reset(0);

			gpio_pwm_ctr_en <= axis_adc_tvalid(0) and axis_adc_tlast(0);
			gpio_pwm_ctr_en_reg <= gpio_pwm_ctr_en; -- pipeline. we have a long way to go between ADCDAQ[0] and GPIO
		end if; -- RST/CLK
	end process;

user_mux_out <= user_mux_out_int;
bp_gpio_int_out <= user_mux_out_int(3);

GPIO0: entity work.GPIO
	GENERIC MAP (
		PLATFORM_ID=>PLATFORM_ID,
		PROTOCOL_VERSION => PROTOCOL_VERSION,
		NUMBER_OF_ADCS => NUMBER_OF_ADCS,
		CHANNELIZERS_CLOCK_SOURCE => ANT_CLK_SOURCE,
		NUMBER_OF_CHANNELIZERS => NUMBER_OF_CHANNELIZERS,
		NUMBER_OF_CHANNELIZERS_WITH_FFT => NUMBER_OF_CHANNELIZERS_WITH_FFT,
		NUMBER_OF_BP_SHUFFLE_LINKS => NUMBER_OF_BP_PCB_SHUFFLE_LANES,
		NUMBER_OF_CROSSBAR_INPUTS => NUMBER_OF_CROSSBAR_INPUTS,
		NUMBER_OF_CROSSBAR_OUTPUTS => NUMBER_OF_CROSSBAR_OUTPUTS,
		NUMBER_OF_GPU_LINKS => NUMBER_OF_GPU_LINKS,
		NUMBER_OF_CORRELATORS => NUMBER_OF_CORRELATORS,
		NUMBER_OF_CHANNELIZERS_TO_CORRELATE => NUMBER_OF_CROSSBAR_INPUTS,
		NUMBER_OF_ADC_BOARDS => NUMBER_OF_ADC_BOARDS,
		NUMBER_OF_USER_SMA_SIGNALS => NUMBER_OF_USER_SMA_SIGNALS,
		IMPLEMENT_LCD => IMPLEMENT_LCD,
		IMPLEMENT_SWITCHER_SYNC => IMPLEMENT_SWITCHER_SYNC,
		IMPLEMENT_FAN => IMPLEMENT_FAN,
		SIM => SIM
	)
	PORT MAP(
		-- Control interface
		CTRL_CMD_IN_DAT=> SYS_GPIO_CMD_DAT,
		CTRL_CMD_IN_RDY=> SYS_GPIO_CMD_RDY,
		CTRL_RPLY_OUT_DAT=> SYS_GPIO_RPLY_DAT,
		CTRL_RPLY_OUT_RDY=> SYS_GPIO_RPLY_RDY,
		CTRL_CLK => CTRL_CLK,
		CTRL_RST => sys_CTRL_RST_reg,

		-- IP Port setting
		HOST_FRAME_READ_RATE     => HOST_FRAME_READ_RATE,
		local_mac_addr           => local_mac_addr,
		local_base_ip_addr       => local_ip_addr,
		local_base_ip_port       => local_base_ip_port,
		local_subarray           => local_subarray,
		-- remote_mac_addr          => remote_mac_addr,
		remote_ip_port0          => remote_ip_port0,

		remote_mac_addr1           => remote_mac_addr1,
		remote_ip_addr1           => remote_ip_addr1,
		remote_ip_port1          => remote_ip_port1,

		udp_stack_reset => udp_stack_reset,
		ctrl_master_reset => ctrl_master_reset,

		arm_spi_sck => arm_spi_sck,
		arm_spi_miso => arm_spi_miso,
		arm_spi_mosi => arm_spi_mosi,
		arm_spi_cs_n => arm_spi_cs_n,

		arm_irq_in => arm_irq_in,
		arm_irq_out => arm_irq_out,
		arm_irq_oe => arm_irq_oe,

		flash_cs_in => flash_cs_in,
		flash_cs_out => flash_cs_out,
		flash_cs_oe => flash_cs_oe,


		gpio_rst_in => gpio_rst_in,
		gpio_rst_out => gpio_rst_out,
		gpio_rst_oe => gpio_rst_oe,

		gpio_irq_in => gpio_irq_in,
		gpio_irq_out => gpio_irq_out,
		gpio_irq_oe => gpio_irq_oe,


		uart_rx_in => uart_rx_in,
		uart_rx_out => uart_rx_out,
		uart_rx_oe => uart_rx_oe,

		uart_tx_in => uart_tx_in,
		uart_tx_out => uart_tx_out,
		uart_tx_oe => uart_tx_oe,

		-- Backplane signals
		-- bp_time_in => bp_time_in,
		-- sync_in => bp_trig_in,
		slot_probe => bp_slot_probe, -- capacitive slot detector: signal that drives the capacitor line
		slot_sense => bp_slot_sense, -- capacitive slot detector: readback from the driven line to detect when the capacitor is charged
		bp_buck_sync => bp_buck_sync,
		bp_buck_sync_mon => bp_buck_sync_mon,

		bp_gpio_int_in => bp_gpio_int_in,
		bp_gpio_int_out => open, --bp_gpio_int_out, -- Driven by user_mux_out(3)
		bp_gpio_int_oe => bp_gpio_int_oe,

		-- IRIG-B decoder
		irigb_mux_in => gpio_irib_mux_in,
		irigb_before_target => irigb_before_target,
		irigb_pps => pps_out, -- To user output mux
		irigb_out => irigb_gen_out,
		irigb_delay => irigb_delay, -- delay to apply to the IRIG-B inputs on the IOB
		irigb_delay_reset => irigb_delay_reset,

		-- Event counter (counts and capture frame numbers with time)
		event_ctr_clk => chan_clk(0),
		event_ctr_en => gpio_event_ctr_en_reg,
		event_ctr_inc => gpio_event_ctr_inc_reg,
		event_ctr_reset => gpio_event_ctr_reset_reg,

		-- PWM Generator (generates Frame-aligned PWM waveform)
		pwm_clk => chan_clk(0),
		pwm_ctr_en => gpio_pwm_ctr_en_reg,
		pwm_reset => gpio_event_ctr_reset_reg, -- just a register version of chan(0) reset
		pwm_out => pwm_out, -- To user output mux

		-- User muxed outputs
		user_mux_in => gpio_user_mux_signals,
		user_mux_out => user_mux_out_int,
		user_mux_oe => user_mux_oe,
		user_bit => user_bit,

		-- Fan control
		FAN_PWM       => FAN_PWM,
		FAN_TACH      => FAN_TACH,
		FAN_TACH_DIV2 => FAN_TACH_DIV2,

		-- Communication link monitoring
		udp_tx_frame    => gpio_udp_tx_frame,
		udp_rx_frame    => gpio_udp_rx_frame,
		udp_tx_overflow => udp_tx_overflow,
		udp_rx_overflow => udp_rx_overflow,
		sfp_status_vector => sfp_status_vector_int,
		sfp_config_vector => sfp_config_vector,
		cmd_packet_counter => cmd_packet_counter,
		rply_packet_counter => rply_packet_counter,

		-- Mezzanine ADC & PLL Interface
		ADC_RST => ADC_RST,
		adc_pll_lock => adc_pll_lock,

		-- LCD
		LCD_DB=>LCD_DB,
		LCD_E =>LCD_E,
		LCD_RS =>LCD_RS,
		LCD_RW =>LCD_RW,


		-- Global trigger
		TRIG_ASYNC => TRIG,

		-- Resets
--		ADC_DAQ_BUFR_SYNC=>GPIO_BUFR_RST,
		user_reset         => user_reset,
		ctrl_reset_pulse   => ctrl_reset_pulse,
		sysmon_user_reset  => sysmon_user_reset,
		ADCDAQ_RESET_ASYNC => ADCDAQ_RESET_ASYNC,
		CHAN_RESET_ASYNC   => chan_reset_async,
		CORR_RESET_ASYNC   => CORR_RESET_ASYNC,
		BLINKER_RESET      => BLINKER_RESET,

		-- Buck sync
		buck_sync => buck_sync,

		chan_clk_source => chan_clk_src_sel, -- '0': ADC clock, '1': internal 200 MHz clock
		chan_clk_reset_async => chan_clk_reset_async,



		-- Clocks
		clk200 => clk200,
		clk200_reset => clk200_reset_reg,
		clk10 => clk10, -- Backplane reference clock

		DNA_CLK => sysmon_clk
	);

-------------------------------------------------------------------------
-- ADC Reset line
-------------------------------------------------------------------------

ADC_RST_N <= not ADC_RST;


---------------------------------------------------------------------
-- Instantiate the SPI Interface
---------------------------------------------------------------------
gen_spi: if NUMBER_OF_SPI_PORTS > 0 generate
	-- Reset output signal that can be used by some boards to reset SPI devices.
	-- The signal is sent to two separate ports to support different versions of SPI-enabled FMC mezzanines
	spi_rst_n <= spi_rst_n_int;
	spi_rst_n_alt <= spi_rst_n_int;

	SPI0: entity work.SPI
		generic map(
			NUMBER_OF_PORTS => NUMBER_OF_SPI_PORTS
			)
		port map(
			-- Control interface
			CTRL_CMD_IN_DAT=> SYS_CMD_DAT(MODULE_SPI_ADDR),
			CTRL_CMD_IN_RDY=> SYS_CMD_RDY(MODULE_SPI_ADDR),
			CTRL_RPLY_OUT_DAT=> SYS_RPLY_DAT(MODULE_SPI_ADDR),
			CTRL_RPLY_OUT_RDY=> SYS_RPLY_RDY(MODULE_SPI_ADDR),
			CTRL_CLK => CTRL_CLK,
			CTRL_RST => sys_CTRL_RST_reg,

			-- SPI Interface
			spi_rst_n => spi_rst_n_int,
			spi_sck => spi_sck,
			spi_miso => spi_miso,
			spi_mosi => spi_mosi,
			spi_addr => spi_addr,
			spi_cs_n => spi_cs_n,

			clk200 => clk200,

			RST => clk200_reset_reg
		);
end generate gen_spi;

---------------------------------------------------------------------
-- I2C Interface
---------------------------------------------------------------------
gen_i2c: if NUMBER_OF_I2C_PORTS > 0 generate
	I2C0: entity work.I2C
		GENERIC MAP (
			NUMBER_OF_PORTS => NUMBER_OF_I2C_PORTS
		)
		PORT MAP(
			-- Control interface
			CTRL_CMD_IN_DAT=> SYS_CMD_DAT(MODULE_I2C_ADDR),
			CTRL_CMD_IN_RDY=> SYS_CMD_RDY(MODULE_I2C_ADDR),
			CTRL_RPLY_OUT_DAT=> SYS_RPLY_DAT(MODULE_I2C_ADDR),
			CTRL_RPLY_OUT_RDY=> SYS_RPLY_RDY(MODULE_I2C_ADDR),
			CTRL_CLK => CTRL_CLK,
			CTRL_RST => sys_CTRL_RST,

			-- I2C Interface
			i2c_sck => i2c_scl,
			i2c_sda => i2c_sda,

			-- System interfaces
			clk200 => clk200,
			RST => clk200_reset_reg
		);

end generate gen_i2c;

---------------------------------------------------------------------
-- Virtex 6 System Monitor or 7-Series XADC interface instantiation
---------------------------------------------------------------------
--!   Accesses the FPGA`s system monitors, which measures the FPGA core voltages, temperature and a few external analog lines.

-- Index the system control buses as a separate signal here , because the simulator will make errors if we index it directly on the instantiation
SYS_SYSMON_CMD_DAT<= SYS_CMD_DAT(MODULE_SYSMON_ADDR);
SYS_CMD_RDY(MODULE_SYSMON_ADDR) <= SYS_SYSMON_CMD_RDY;

SYS_SYSMON_RPLY_RDY<= SYS_RPLY_RDY(MODULE_SYSMON_ADDR);
SYS_RPLY_DAT(MODULE_SYSMON_ADDR) <= SYS_SYSMON_RPLY_DAT;

debug_out(0) <= SYS_SYSMON_CMD_DAT.TVALID;
debug_out(1) <= SYS_SYSMON_CMD_DAT.TLAST;
debug_out(2) <= SYS_SYSMON_CMD_RDY.TREADY;
debug_out(3) <= SYS_SYSMON_RPLY_DAT.TVALID;
debug_out(4) <= SYS_SYSMON_RPLY_DAT.TLAST;
debug_out(5) <= SYS_SYSMON_RPLY_RDY.TREADY;
debug_out(6) <= CTRL_RST;
debug_out(7) <= sysmon_ctrl_rst;

debug_out(8) <= SYS_GPIO_CMD_DAT.TVALID;
debug_out(9) <= SYS_GPIO_CMD_DAT.TLAST;
debug_out(10) <= SYS_GPIO_CMD_RDY.TREADY;
debug_out(11) <= SYS_GPIO_RPLY_DAT.TVALID;
debug_out(12) <= SYS_GPIO_RPLY_DAT.TLAST;
debug_out(13) <= SYS_GPIO_RPLY_RDY.TREADY;

debug_out(22) <= ctrl_reset_pulse;
debug_out(23) <= sysmon_user_reset;

debug_out(24) <= sysmon_reset;
debug_out(25) <= sysmon_clk;

SYSMON0: entity work.SYSMON_XADC
	GENERIC MAP (
		PLATFORM_ID => PLATFORM_ID
		)
	PORT MAP(
		-- Control interface
		CTRL_CMD_IN_DAT => SYS_SYSMON_CMD_DAT,
		CTRL_CMD_IN_RDY => SYS_SYSMON_CMD_RDY,
		CTRL_RPLY_OUT_DAT => SYS_SYSMON_RPLY_DAT,
		CTRL_RPLY_OUT_RDY => SYS_SYSMON_RPLY_RDY,
		CTRL_CLK => CTRL_CLK,
		CTRL_RST => sysmon_ctrl_rst, -- pipelined synchronous reset

		-- Analog inputs
		VAUX_CURR_N => VAUX_CURR_N,
		VAUX_CURR_P => VAUX_CURR_P,
		VAUX_VOLT_N => VAUX_VOLT_N,
		VAUX_VOLT_P => VAUX_VOLT_P,
		VP => VP,
		VN => VN,

		--debug_out => debug_out,
		sysmon_clk => sysmon_clk,
		SYSMON_RST => sysmon_reset or sysmon_user_reset
	);

---------------------------------------------------------------------
-- Frequency counter
---------------------------------------------------------------------
--!   Measures the toggling frequency of a number of logic signals.
freq_ctr_in_vect(0 to adc_clk_div2'LENGTH-1) <= adc_clk_div2;

gen_adc_clk_monup: if PLATFORM_ID=PLATFORM_ID_ZCU111 generate

	gen_adc_clkoutdiv2i: for i in 0 to adc_clkout'LENGTH-1 generate

		gen_adc_clkout_div2: process(adc_clkout(i))
			begin
			if rising_edge(adc_clkout(i)) then
				adc_clkout_div2(i) <= not adc_clkout_div2(i);
			end if;
		end process;
		freq_ctr_in_vect(i+8) <= adc_clkout_div2(i); -- assumes that NUMBER_OF_CHANNELIZERS <= 8
	end generate;
end generate;

-- Here we assign the clock monitoring signal to each of the frequency counter input channels
freq_ctr_in_vect(16) <= fmc_mgt_pll_refclk_div2(0); -- MGT
freq_ctr_in_vect(17) <= fmc_refclk_div2(1);
freq_ctr_in_vect(18) <= fmc_refclk_div2(0);
freq_ctr_in_vect(19) <= clk200_div2;
freq_ctr_in_vect(20) <= CTRL_CLK_DIV2;
freq_ctr_in_vect(21) <= FAN_TACH_DIV2;
freq_ctr_in_vect(22) <= chan_clk_div2;
freq_ctr_in_vect(23) <= ct_clk_div2; --CORR_CLK_DIV2;
freq_ctr_in_vect(24) <= SYSMON_CLK_DIV2;
gen_freq25: if NUMBER_OF_GPU_REFCLKS > 0 generate
	freq_ctr_in_vect(25) <= gpu_refclk_div2(0); -- MGT
end generate;
freq_ctr_in_vect(26) <= gpu_txclk_div2;
gen_freq27: if NUMBER_OF_BP_SHUFFLE_REFCLKS > 0 generate
	freq_ctr_in_vect(27) <= bp_shuffle_refclk_div2(0); -- MGT
end generate;
freq_ctr_in_vect(28) <= bp_shuffle_txclk_div2;
freq_ctr_in_vect(29) <= fmc_mgt_pll_refclk_div2(1); -- MGT
freq_ctr_in_vect(30) <= fmc_mgt_pll_refclk_div2(2); -- MGT
freq_ctr_in_vect(31) <= fmc_mgt_pll_refclk_div2(3); -- MGT
freq_ctr_in_vect(32) <= raw_clk10_div2;
freq_ctr_in_vect(33) <= mgt_clk100_div2; -- MGT
freq_ctr_in_vect(34) <= mgt_clk200_div2; -- MGT
freq_ctr_in_vect(35) <= sfp_refclk_div2; -- MGT
freq_ctr_in_vect(36) <= clk10_div2; -- MGT
freq_ctr_in_vect(37) <= mgt_clk125_div2; -- MGT
gen_freq38: if NUMBER_OF_BP_SHUFFLE_REFCLKS > 1 generate
	freq_ctr_in_vect(38) <= bp_shuffle_refclk_div2(1); -- MGT
end generate;

FREQ_CTR0: entity work.FREQ_CTR
	GENERIC MAP(
		FPGA_SERIES=>FPGA_SERIES,
		NUMBER_OF_CLK_IN_PORTS=> NUMBER_OF_FREQ_CTR_PORTS
		)
	PORT MAP(
		CTRL_CMD_IN_DAT=> SYS_CMD_DAT(MODULE_FREQ_CTR_ADDR),
		CTRL_CMD_IN_RDY=> SYS_CMD_RDY(MODULE_FREQ_CTR_ADDR),
		CTRL_RPLY_OUT_DAT=> SYS_RPLY_DAT(MODULE_FREQ_CTR_ADDR),
		CTRL_RPLY_OUT_RDY=> SYS_RPLY_RDY(MODULE_FREQ_CTR_ADDR),
		CTRL_CLK => CTRL_CLK,
		CTRL_RST => sys_CTRL_RST_reg,

		clk200 => clk200,
		CLK_IN_DIV2 => freq_ctr_in_vect, --! vector of 'NUMBER_OF_FREQ_CTR_PORTS' signals for which we want to measure the frequencies
		RST => clk200_reset_reg
	);

-------------------------------------------------------------------------
-- FMC reference clock
-------------------------------------------------------------------------
--! Handles the FMC reference clock generation and reception and ADC SYNC generation/alignment

--! Implements the LVDS ADC SYNC output to the FMC board

gen_refclk: if NUMBER_OF_ADC_BOARDS /= 0 generate
	refclk_irigb_sync_in <= not irigb_before_target;
	REFCLK0: entity work.REFCLK
		GENERIC MAP (
			PLATFORM_ID => PLATFORM_ID,
			NUMBER_OF_MEZZANINES => NUMBER_OF_ADC_BOARDS,
			SIM=>SIM
			)
		PORT MAP(
			CTRL_CMD_IN_DAT=> SYS_CMD_DAT(MODULE_REFCLK_ADDR),
			CTRL_CMD_IN_RDY=> SYS_CMD_RDY(MODULE_REFCLK_ADDR),
			CTRL_RPLY_OUT_DAT=> SYS_RPLY_DAT(MODULE_REFCLK_ADDR),
			CTRL_RPLY_OUT_RDY=> SYS_RPLY_RDY(MODULE_REFCLK_ADDR),
			CTRL_CLK => CTRL_CLK,
			CTRL_RST => refclk_ctrl_rst,

			FMC_REFCLK_P => REFCLK_M2C_P, -- IBUFDS instantiated by the module
			FMC_REFCLK_N => REFCLK_M2C_N,

			fmc_refclk => fmc_refclk, -- BUFG'ed reference clocks from the 2 mezzanones
			FMC_REFCLK_DIV2 => FMC_REFCLK_DIV2(0 to NUMBER_OF_ADC_BOARDS-1), -- Logic signal toggling at 1/2 the Mezzanine's reference clocks, for the frequency counter

			ADC_SYNC_P => ADC_SYNC_P, -- OBUFDS is instantiated by the module
			ADC_SYNC_N => ADC_SYNC_N,

			clk10 => clk10, -- Backplane reference clock
			clk10_out => clk10_out,
			-- Sync source signals
			sync_in(0) => bp_trig_in, -- Corresponds to source #2
			sync_in(1) => refclk_irigb_sync_in, -- Corresponds to source #3
			sync_in(2) => bp_time_in, -- Corresponds to source #4
			sync_in(3) => bp_gpio_int_in, -- Corresponds to source #5
			sync_in(4) => user_mux_in(0), -- Corresponds to source #6 - sma_a
			sync_in(5) => user_mux_in(1), -- Corresponds to source #7 - sma_b

			sync_out => sync_out,

	--		SERDES_RST=>REFCLK_SERDES_RST,
	--		BUFR_RST=>REFCLK_BUFR_RST,
			ADCDAQ_RESET => REFCLK_ADCDAQ_RESET,

			clk200 => clk200,
			RST => clk200_reset_reg
		);
	end generate;

-------------------------------------------------------------------------
-- Divided system clocks for the frequency Counter
-------------------------------------------------------------------------
sfprefclkdiv2: process(sfp_refclk_buf)
	begin
		if rising_edge(sfp_refclk_buf) then
			sfp_refclk_div2 <=not sfp_refclk_div2;
		end if;
	end process;

clk10div2: process(clk10)
	begin
		if rising_edge(clk10) then
			clk10_div2 <=not clk10_div2;
			clk10_ctr <= clk10_ctr + 1;
		end if;
	end process;

clk200div2: process(clk200)
	begin
		if rising_edge(clk200) then
			clk200_div2 <= not clk200_div2;
			clk200_ctr <= clk200_ctr + 1;
		end if;
	end process;

ctrlclklogic: process(CTRL_CLK)
	begin
		if rising_edge(CTRL_CLK) then
			CTRL_CLK_DIV2<=not CTRL_CLK_DIV2;
		end if;
	end process;

---------------------------------------------------------------------
--  Generate chan_clk_div2
---------------------------------------------------------------------
-- Generates a logic signal chan_clk_div2 pulsing at half of the chan_clk frequency. To be used for the frequency counter to measure the channelizer clock frequency generated by the PLL from the selected clock source.
-- This signal can be routed using standard fabric ressources and does not require a dedicated clock line.
---------------------------------------------------------------------
chanclkdiv2: process(chan_clk(0))
	begin
		if rising_edge(chan_clk(0)) then
			chan_clk_div2 <=not chan_clk_div2;
		end if; -- RST/CLK
	end process;

---------------------------------------------------------------------
--  Generate COR_CLK_DIV2
---------------------------------------------------------------------
--! @brief Generates a logic signal CORR_CLK_DIV2 pulsing at half of the CORR_CLK frequency. To be used for the frequency counter to measure the Correlator clock frequency.
--! This signal can be routed using standard fabric ressources and does not require a dedicated clock line.
---------------------------------------------------------------------
corrclkdiv2: process(CORR_CLK)
	begin
		if rising_edge(CORR_CLK) then
			CORR_CLK_DIV2<=not CORR_CLK_DIV2;
		end if; -- RST/CLK
	end process;

---------------------------------------------------------------------
--  Generate SYSMON_CLK_DIV2
---------------------------------------------------------------------
--! @brief Generates a logic signal SYSMON_CLK_DIV2 pulsing at half of the sysmon_clk frequency. To be used for the frequency counter to measure the System Monitor clock frequency.
--! This signal can be routed using standard fabric ressources and does not require a dedicated clock line.
---------------------------------------------------------------------
sysmonclkdiv2: process(sysmon_clk)
	begin
		if rising_edge(sysmon_clk) then
			SYSMON_CLK_DIV2<=not SYSMON_CLK_DIV2;
			sysmon_clk_ctr <= sysmon_clk_ctr + 1;

		end if; -- RST/CLK
	end process;

rawclk10div2: process(raw_clk10)
	begin
		if rising_edge(raw_clk10) then
			raw_clk10_div2<=not raw_clk10_div2;
		end if; -- RST/CLK
	end process;


mgt_refclk_gen: for i in 0 to NUMBER_OF_ADC_BOARDS*2-1 generate

	gen_bufgte7: if FPGA_SERIES = FPGA_KINTEX7 generate
		ibufds_mgtpllrefclk : IBUFDS_GTE2
			port map (
				I     => mgt_pll_refclk_p(i),
				IB    => mgt_pll_refclk_n(i),
				CEB   => '0',
				O     => fmc_mgt_pll_refclk_nobuf(i),
				ODIV2 => open
			);
		end generate;
	gen_bufgteup: if FPGA_SERIES = FPGA_ULTRASCALEPLUS generate
		ibufds_mgtpllrefclk : IBUFDS_GTE4
			port map (
				I     => mgt_pll_refclk_p(i),
				IB    => mgt_pll_refclk_n(i),
				CEB   => '0',
				O     => fmc_mgt_pll_refclk_nobuf(i),
				ODIV2 => open
			);
	end generate;

	bufh_mgtclk: BUFH
		port map (
			I     => fmc_mgt_pll_refclk_nobuf(i),
			O     => fmc_mgt_pll_refclk(i)
		);

	mgtclkdiv2: process(fmc_mgt_pll_refclk(i))
	begin
		if rising_edge(fmc_mgt_pll_refclk(i)) then
			fmc_mgt_pll_refclk_div2(i)<=not fmc_mgt_pll_refclk_div2(i);
		end if; -- CLK
	end process;
end generate;

mgtclk100div2: process(mgt_clk100)
	begin
		if rising_edge(mgt_clk100) then
			mgt_clk100_div2<=not mgt_clk100_div2;
		end if; -- RST/CLK
	end process;

mgtclk200div2: process(mgt_clk200)
	begin
		if rising_edge(mgt_clk200) then
			mgt_clk200_div2<=not mgt_clk200_div2;
		end if; -- RST/CLK
	end process;

mgtclk125div2: process(mgt_clk125)
	begin
		if rising_edge(mgt_clk125) then
			mgt_clk125_div2 <=not mgt_clk125_div2;
		end if; -- RST/CLK
	end process;
--end generate; --debug5

--------------------------------------------------------------------
--------------------------------------------------------------------
-- ADCs
--------------------------------------------------------------------
--------------------------------------------------------------------
-- external interface
--
-- adc_clk_bufg: out: BUFG-buffered master clock used by CLOCKS to generate the channelizer clocks
-- Data interface
-- 		axis_adc_tdata
-- 		axis_adc_tvalid
-- 		axis_adc_tlast
-- 		axis_adc_tuser
-- 		chan_clk in: axis_adc clock
-- 		ADCDAQ_RESET
-- Others:
--		adc_clk_div2
-- EV8AQ160-specific:
--    Control interface (EV8AQ160 only)
-- 		ADC_CMD_DAT
--		ADC_CMD_RDY
--		ADC_RPLY_DAT
--		ADC_RPLY_RDY
--		CTRL_CLK
--		adcdaq_ctrl_rst_reg
--    Others
--		fmc_refclk: Used to sample the clock to perform sync align
--		clk200: For IODELAYCTRL
ADCDAQ_RESET <= ADCDAQ_RESET_ASYNC or REFCLK_ADCDAQ_RESET;

---------------
-- EV8AQ160 ADC
---------------

EV8AQ160: if ADC_TYPE="EV8AQ160" generate

	signal adc_ioclk : std_logic;
	signal adc_divclk : std_logic;
	signal adc_divclk_out_bufg : std_logic_vector(0 to NUMBER_OF_ADCS-1);
	signal adc_ioclk_out_pll : std_logic_vector(0 to NUMBER_OF_ADCS-1);
	signal adc_divclk_out_pll : std_logic_vector(0 to NUMBER_OF_ADCS-1);
	signal adc_divclk_out_bufr : std_logic_vector(0 to NUMBER_OF_ADCS-1);

	signal adc_data_ready_reg2 : std_logic_vector(0 to NUMBER_OF_ADCS-1);
	signal adc_send_data : std_logic;


begin
	-- Selects which ADCDAQ will provides the master clock for the clock generator module to provide channelizer clocks.
	adc_clk_bufg <= adc_divclk_out_bufg(ANT_CLK_SOURCE); -- Must use output with ADC_INSTANTIATE_PLL=TRUE , preferably an output without PLL

	-- Generate channalizer clocks.
	-- The clocks are taken  8-phase clock derived the MMCM/PLL in clock module
	-- We resuse the same clocks as needed to cover all the channelizers.
	chclkgen: for i in 0 to NUMBER_OF_CHANNELIZERS-1 generate
		chan_clk(i) <= chan_clk_pll(i mod 8);
		chan_reset(i) <= chan_reset_pll(i mod 8);
	end generate;

	-- Generate a global ``send_data`` signal that is '1' when all ADCs have data to send.
	-- The inputs are all from different clocks
	--   1) Since we do a AND operation and all signals are zero after reset, the outputs should be stable at zero until all inputs are '1'
	--   2) Even if a channelizer started reading one or two clocks after the others, the packets are realigned at the end of the channelizers
	--   3) The adc_send_data should be resynchronized to its clock domain
	--      before being fed to ADCDAQ. The pipelining will take care of that.
	--      Physical separation of the pipeling registers makes this a less
	--      than optimal CDC, but as stated above timing is not critical.
	adc_send_data <= and_reduce(adc_data_ready_reg2); --



	-- Select which ADCDAQ provides an external clock to other ADCDAQs (used only if USE_EXT_DATA_CLK=TRUE)
	adc_ioclk <= adc_ioclk_out_pll(ANT_CLK_SOURCE); -- Must use output with ADC_INSTANTIATE_PLL=TRUE , preferably an output without PLL
	adc_divclk <= adc_divclk_out_pll(ANT_CLK_SOURCE); -- Must use output with ADC_INSTANTIATE_PLL=TRUE , preferably an output without PLL

	ADCGEN: for i in 0 to NUMBER_OF_ADCS-1 generate
		signal adc_data_ready : std_logic;
		signal adc_data_ready_reg1 : std_logic;
		signal adc_send_data_reg : std_logic_vector(2 downto 0);

		--attribute shreg_extract of adc_data_ready_reg1: signal is "no";
		--attribute shreg_extract of adc_send_data_reg: signal is "no";
		attribute keep of adc_data_ready_reg1: signal is "true"; -- prevent equivalent register merging
		attribute keep of adc_send_data_reg: signal is "true"; -- prevent equivalent register merging

	begin

		-- -- Define intermediary signals to eliminate use of indexed record arrays as actuals in the instantiation: this messes up the simulator.
		-- ADC_DAT(i).TDATA <= axis_adc_tdata(i);
		-- ADC_DAT(i).TVALID <= axis_adc_tvalid(i);
		-- ADC_DAT(i).TLAST <= axis_adc_tlast(i);
		-- ADC_DAT(i).TUSER <= axis_adc_tuser(i);

		-- Generate the adc_send_data which will tells all the ADCs to start
		-- sending data once all of them have their FIFO half-full
		adc_send_proc: process(chan_clk(i))
		begin
			if rising_edge(chan_clk(i)) then
				adc_data_ready_reg1 <= adc_data_ready; -- pipeline all adc_data_ready signals so they can be combined (and_reduce) at a central point
				adc_data_ready_reg2(i) <= adc_data_ready_reg1; -- pipeline
				adc_send_data_reg <= adc_send_data & adc_send_data_reg(2 downto 1); -- pipeline AND resync adc_send_data
			end if;
		end process;

		-- Convert 4x 8-bit ADCDAQ bus to 4x 16-bit bus
		repack_gen: for j in 0 to 3  generate
			axis_adc_tdata(i)(16*j+7 downto 16*j) <= axis_adc_tdata8(i)(8*j+7 downto 8*j);
			axis_adc_tdata(i)(16*j+15 downto 16*j+8) <= (others => axis_adc_tdata8(i)(7)); -- sign extend
		end generate;
		-- ADCDAQ is still implemented if IMPLEMENT_ANT=FALSE, but its IMPLEMENT_ADCDAQ generics is forced  to FALSE to the appropriate differential buffers are instantiated and prevent UCF errors.
		--	ADC_CLK_OUT_PLL<=ADC_CLK_OUT_PLL_INT;
		--debug3: if false generate
		ADCDAQ0: entity work.ADCDAQ
			GENERIC MAP(
				IMPLEMENT_ADCDAQ        => TRUE, --
				PROVIDE_BUFFERED_DIVCLK => ADC_PROVIDE_BUFFERED_DIVCLK(i),
				USE_EXT_DATA_CLK        => ADC_USE_EXT_DATA_CLK(i), -- Use array to select whether a PLL should be used for this instance.
				IS_DIFFERENTIAL         => ADC_IS_DIFFERENTIAL(i),
				INSTANTIATE_PLL         => ADC_INSTANTIATE_PLL(i), --
				BUFMR_MAP               => ADC_INSTANTIATE_BUFMR(i),
				INSTANTIATE_IDELAYCTRL  => ADC_INSTANTIATE_IDELAYCTRL(i),
				SIM                     => SIM
				)
			PORT MAP(
				-- ADC interface
				ADC_DATA_H_P => ADC_DATA_P(i),
				ADC_DATA_H_N => ADC_DATA_N(i),
				ADC_CLK_H_P  => ADC_CLK_P(i),
				ADC_CLK_H_N  => ADC_CLK_N(i),

				-- Readout interface
				-- ADC_OUT_DAT => ADC_DAT(i),
				m_axis_adc_tdata => axis_adc_tdata8(i),
				m_axis_adc_tvalid => axis_adc_tvalid(i),
				m_axis_adc_tlast => axis_adc_tlast(i),
				m_axis_adc_tuser => axis_adc_tuser(i),
				ADC_CLK => chan_clk(i),

				-- Clock outputs (before PLL)

				DIVCLK_OUT_BUFG => adc_divclk_out_bufg(i), -- PLL-generated word clock for downstream signal processing (if corresponding ADC_INSTANTIATE_PLL=TRUE)
				DIVCLK_OUT_BUFR => adc_divclk_out_bufr(i),

				-- Clock outputs to deserializer logic (generated by PLL if ADC_INSTANTIATE_PLL=TRUE)
				IOCLK_OUT_PLL => adc_ioclk_out_pll(i), -- PLL-generated IOCLK clock (if corresponding ADC_INSTANTIATE_PLL=TRUE)
				DIVCLK_OUT_PLL => adc_divclk_out_pll(i), -- PLL-generated DIVCLK (word) clock (if corresponding ADC_INSTANTIATE_PLL=TRUE)

				-- Clock monitor
				ADC_CLK_OUT_DIV2 => adc_clk_div2(i), -- Word clock divided by 2 in logic for frequency counter

				-- Data alignment signals
				data_ready => adc_data_ready,
				send_data => adc_send_data_reg(0),

				-- External data clocks
				IOCLK_IN => adc_ioclk, -- External IOCLK, used if USE_EXT_DATA_CLK=TRUE
				DIVCLK_IN => adc_divclk, -- External DIVCLK, used if USE_EXT_DATA_CLK=TRUE

				-- Global synchronization
				ADCDAQ_RESET => ADCDAQ_RESET,

				-- Control lines
				CTRL_CMD_IN_DAT=> ADC_CMD_DAT(i),
				CTRL_CMD_IN_RDY=> ADC_CMD_RDY(i),
				CTRL_RPLY_OUT_DAT=> ADC_RPLY_DAT(i),
				CTRL_RPLY_OUT_RDY=> ADC_RPLY_RDY(i),
				CTRL_CLK => CTRL_CLK,
				CTRL_RST => adcdaq_ctrl_rst_reg(i),


				REF_CLK => fmc_refclk(ADC_TO_ADC_BOARD_MAP(i)), -- Used to sample the ADC clock waveform
				clk200 => clk200 -- Used to clock the IODELAYCTRL
			);

	end generate ADCGEN;
end generate EV8AQ160;

---------------
-- EV8AQ160 ADC
---------------

AXIS_ADC: if ADC_TYPE="AXIS" generate

	signal adc_word_ctr: frame_word_ctr_array(0 to NUMBER_OF_ADCS-1) := (others => (others=>'0')); -- Counts words from 0 to FRAME_LENGTH/4-1
	signal adc_send_data2: slv(0 to NUMBER_OF_ADCS-1); -- indicates when TVALID can be passed on

begin
	-- Select clock to be used as a source to generate channelizer clocks
	-- We don't use the clocks directly, but we use the reset sequencer which use these clocks.
	-- We should separate the reset sequencer from the clock generator.
	adc_clk_bufg <= adc_axis_clk(ANT_CLK_SOURCE);

	-- Generate channalizer clocks.
	-- The channelizer clocks are taken directly from the ADC AXIS bus clock.
	-- The reset is taken from the clock module reset. Since all clocks are based on a SYSCLK_BUFG that feed the clock generator,
	-- we take chan_reset_pll(0) as a clock for everybody. This clock is sequenced.
	-- Reset with index 0 is the most in phae with the input clock, and therefore the most in phase with the data clocks.
	chclkgen: for i in 0 to NUMBER_OF_CHANNELIZERS-1 generate
		chan_clk(i) <= adc_axis_clk(i mod NUMBER_OF_ADCS);
		chan_reset(i) <= chan_reset_pll(0);
	end generate;

	-- Pipeline and frame the ADC with a TLAST signal and generate the divide-by-two adc clock monitoring signals for the frequency counter
	-- The first frame is skipped to provide time for the channelizer pipeline modules to complete their reset cycles.
	GEN_ADC: for i in 0 to NUMBER_OF_ADCS-1 generate
		adc_clk_div2_proc: process(adc_clkout(i))
			begin
				-- Generate a divide-by-2 version of the downscaled sampling clock
				if rising_edge(adc_clkout(i)) then
					adc_clk_div2(i) <= not adc_clk_div2(i);
				end if; -- adc_axis_clk
		end process;

		adc_proc: process(adc_axis_clk(i))

			variable adc_axis_tdata2, adc_axis_tdata3: slv64;

			begin
				if rising_edge(chan_clk(i)) then
					if adc_axis_tvalid(i)='1' then
						adc_word_ctr(i) <= adc_word_ctr(i) + 1;
					end if;

					-- ADC data comes in 128-bit bus that contains 8x 16-bit sample words.
					-- Actual ADC data is 12 or 14 bits, MSB-aligned in each word. First sample is in the lower word.

					-- The FFT currently need 4x 8-bit sample bytes, first sample in the upper word
					-- The following performs the conversion

					-- Downsample the data from 8 samples to 4 samples
					for j in 0 to 3 loop
						adc_axis_tdata2(16*j+15 downto 16*j) := adc_axis_tdata(i)(32*j+15 downto 32*j);
					end loop;

					-- Invert the order of the words to put the first sample in the MSB
					for j in 0 to 3 loop
						adc_axis_tdata3(16*j+15 downto 16*j) := adc_axis_tdata2(16*(3-j)+15 downto 16*(3-j));
					end loop;
					-- Assing the data bus and clear overflow flags
					axis_adc_tdata(i) <= adc_axis_tdata3;
					axis_adc_tuser(i) <= (others =>'0');
					axis_adc_tvalid(i) <= adc_axis_tvalid(i) and adc_send_data2(i);
					axis_adc_tlast(i) <= '0';
					-- generate TLAST
					if signed(adc_word_ctr(i))=-1 then
						axis_adc_tlast(i) <= '1';
						adc_send_data2(i) <= '1'; -- start setting tvalid to 1
					end if; -- last word
					-- Synchronous reset
					if chan_reset(i)='1' then
						axis_adc_tvalid(i) <= '0';
						adc_word_ctr(i) <= (others => '0');
						adc_send_data2(i) <= '0';
					end if;
				end if; -- if clk
			end process;
	end generate GEN_ADC;
end generate AXIS_ADC;



---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------
--  CHANNELIZERS
---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------

--------------------------------------------------
-- CHAN COMMAND ROUTER
--------------------------------------------------
--! @addtogroup memory_map
--! Channel Memoy Map/ Base addresses
--! Offset = Channel # x 0x02000
--! ==============================
--! |#   | Base Addr       | Subaddresses | Description |
--! |----|-----------------|------------- |-------------|
--! | 0  | Base + 0x00000  | CHAN 0       |             |
--! | 1  | Base + 0x02000  | CHAN 1       |             |
--! | 2  | Base + 0x04000  | CHAN 2       |             |
--! | 3  | Base + 0x06000  | CHAN 3       |             |
--! | 4  | Base + 0x08000  | CHAN 4       |             |
--! | 5  | Base + 0x0A000  | CHAN 5       |             |
--! | 6  | Base + 0x0C000  | CHAN 6       |             |
--! | 7  | Base + 0x0E000  | CHAN 7       |             |
--! | 8  | Base + 0x10000  | CHAN 8       |             |
--! | 9  | Base + 0x12000  | CHAN 9       |             |
--! | 10 | Base + 0x14000  | CHAN 10      |             |
--! | 11 | Base + 0x16000  | CHAN 11      |             |
--! | 12 | Base + 0x18000  | CHAN 12      |             |
--! | 13 | Base + 0x1A000  | CHAN 13      |             |
--! | 14 | Base + 0x1C000  | CHAN 14      |             |
--! | 15 | Base + 0x1E000  | CHAN 15      |             |

TOP_CHAN_CMD_DAT<= top_cmd_dat(CHAN_BASE_PORT);
top_cmd_rdy(CHAN_BASE_PORT) <= TOP_CHAN_CMD_RDY;
TOP_CHAN_RPLY_RDY<= top_rply_rdy(CHAN_BASE_PORT);
top_rply_dat(CHAN_BASE_PORT) <= TOP_CHAN_RPLY_DAT;

chan_router0: entity work.CTRL_ROUTER
	GENERIC MAP (
		NUMBER_OF_PORTS=>NUMBER_OF_CHANNELIZERS,
		ADDRESS_MASK => "----1111------------" --'1': used to generate port index, '-' = don't care,
	)
	PORT MAP(
		-- Master control interface
		CMD_IN_DAT   => TOP_CHAN_CMD_DAT,
		CMD_IN_RDY   => TOP_CHAN_CMD_RDY,
		RPLY_OUT_DAT => TOP_CHAN_RPLY_DAT,
		RPLY_OUT_RDY => TOP_CHAN_RPLY_RDY,

		CMD_OUT_DAT=> CHAN_CMD_DAT,
		CMD_OUT_RDY=> CHAN_CMD_RDY,
		RPLY_IN_DAT=> CHAN_RPLY_DAT,
		RPLY_IN_RDY=> CHAN_RPLY_RDY,

		-- Slave (module) control interface
		CLK => CTRL_CLK,
		RST => chan_router_ctrl_rst
	);


CHANGEN: for i in 0 to NUMBER_OF_CHANNELIZERS-1 generate

	signal chan_reset_reg : std_logic_vector(0 to NUMBER_OF_CHANNELIZERS-1); --! Reset for each channelizer input synchronous to their respective clock
	attribute equivalent_register_removal of chan_reset_reg : signal is "no";
	attribute keep of chan_reset_reg :signal is "true";
	attribute shreg_extract of chan_reset_reg: signal is "no";

begin
	-- Pipeline the channel synchronous resets
	rst_proc: process(chan_clk(i))
		begin
			if rising_edge(chan_clk(i)) then
				chan_reset_reg(i) <= chan_reset(i);
			end if;
		end process;

	CHANi: component CHAN
		--GENERIC MAP (
		--	--PLATFORM_ID => PLATFORM_ID
		--	--IMPLEMENT_FFT => i < NUMBER_OF_CHANNELIZERS_WITH_FFT
		--	)
		PORT MAP(
			-- Channelizer input (on ANT_CLK)
			in_dat_tdata  => axis_adc_tdata(i),
			in_dat_tvalid => axis_adc_tvalid(i),
			in_dat_tlast  => axis_adc_tlast(i),
			in_dat_tuser  => axis_adc_tuser(i),
			in_reset => chan_reset_reg(i),
			in_clk => chan_clk(i), -- input and signal processing clock

			-- Channelizer output, resynchronized to out_clk
			out_dat_tdata  => axis_chan_out_tdata(i),
			out_dat_tvalid => axis_chan_out_tvalid(i),
			out_dat_tlast  => axis_chan_out_tlast(i),
			out_dat_tuser  => axis_chan_out_tuser(i),
			out_reset      => ct_reset_reg,
			out_clk        => ct_clk, -- output clock

			-- Misc signals
			TRIG => TRIG,
			lane_monitor => chan_lane_monitor(i),


			-- Control interface

			ctrl_cmd_tdata  => CHAN_CMD_DAT(i).TDATA,
			ctrl_cmd_tvalid => CHAN_CMD_DAT(i).TVALID,
			ctrl_cmd_tlast  => CHAN_CMD_DAT(i).TLAST,
			ctrl_cmd_tready => CHAN_CMD_RDY(i).TREADY,

			ctrl_rply_tdata  => CHAN_RPLY_DAT(i).TDATA,
			ctrl_rply_tvalid => CHAN_RPLY_DAT(i).TVALID,
			ctrl_rply_tlast  => CHAN_RPLY_DAT(i).TLAST,
			ctrl_rply_tready => CHAN_RPLY_RDY(i).TREADY,

			CTRL_CLK => CTRL_CLK,
			CTRL_RST => chan_ctrl_rst_reg(i),

			-- ADCDAQ Control interface

			adc_cmd_tdata   => ADC_CMD_DAT(i).TDATA,
			adc_cmd_tvalid  => ADC_CMD_DAT(i).TVALID,
			adc_cmd_tlast   => ADC_CMD_DAT(i).TLAST,
			adc_cmd_tready  => ADC_CMD_RDY(i).TREADY,

			adc_RPLY_tdata  => ADC_RPLY_DAT(i).TDATA,
			adc_RPLY_tvalid => ADC_RPLY_DAT(i).TVALID,
			adc_RPLY_tlast  => ADC_RPLY_DAT(i).TLAST,
			adc_RPLY_tready => ADC_RPLY_RDY(i).TREADY,

			-- Data capture interface
			PRB_tdata  => axis_prb_tdata(i),
			PRB_tvalid => axis_prb_tvalid(i),
			PRB_tlast  => axis_prb_tlast(i),
			PRB_tready => axis_prb_tready(i),
			PRB_CLK    => CTRL_CLK
		);
end generate;

---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------
--- CORNER-TURN-ENGINE
---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------
-- Implement the corner turn operation
---    a) between channels in the same board
--     b) between boards in the same crate (optional)
--     c) between boards in two crates (optional)
--
-- The corner-turn engine is implemented using the following blocks
--
--    - CROSSBAR: channelizer crosbar a.k.a 1st crossbar
--    - CROSSBAR2: shuffle_crossbar
--    - bp_shuffle
--    - CROSSBAR3 shuffle_crossbar


---------------------------------------------------------------------
-- CHANNELIZER CROSSBAR
---------------------------------------------------------------------
--! Route specified frequency channels from all channelizers to individual streams


-- Index the command bus into an intermediary signal to mitigate simulator problems with indexing record arrays stright in the instantiation
TOP_CROSSBAR1_CMD_DAT             <= top_cmd_dat(CROSSBAR1_BASE_PORT);
top_cmd_rdy(CROSSBAR1_BASE_PORT)  <= TOP_CROSSBAR1_CMD_RDY;
TOP_CROSSBAR1_RPLY_RDY            <= top_rply_rdy(CROSSBAR1_BASE_PORT);
top_rply_dat(CROSSBAR1_BASE_PORT) <= TOP_CROSSBAR1_RPLY_DAT;

--! Pipeline and connect the channelizer output to the 1st crossbar inputs.
--! The pipelining is there to help meeting timing closure, as we need to route long distance from the channelizer to the first crossbar
cb1_pipe_proc: process(ct_clk)
begin
	if rising_edge(ct_clk) then
		cb1_reset <= ct_reset_reg;
		cb1_reset_reg <= cb1_reset;
		cb1_reset_reg2 <= cb1_reset_reg;
		for i in 0 to min(NUMBER_OF_CHANNELIZERS-1, NUMBER_OF_CROSSBAR_INPUTS-1) loop
			axis_crossbar1_in_tdata(i) <= axis_chan_out_tdata(i);
			axis_crossbar1_in_tuser(i) <= axis_chan_out_tuser(i);
			axis_crossbar1_in_tlast(i) <= axis_chan_out_tlast(i);
			axis_crossbar1_in_tvalid(i) <= axis_chan_out_tvalid(i);
			-- JFC: Why was this commenetd out?
			if ct_reset_reg = '1' then
				axis_crossbar1_in_tvalid(i) <= '0';
			end if;

			axis_crossbar1_in_tdata_reg(i) <= axis_crossbar1_in_tdata(i);
			axis_crossbar1_in_tuser_reg(i) <= axis_crossbar1_in_tuser(i);
			axis_crossbar1_in_tlast_reg(i) <= axis_crossbar1_in_tlast(i);
			axis_crossbar1_in_tvalid_reg(i) <= axis_crossbar1_in_tvalid(i);
			-- JFC: Why was this commenetd out?
			if cb1_reset = '1' then
				axis_crossbar1_in_tvalid_reg(i) <= '0';
			end if;

			axis_crossbar1_in_tdata_reg2(i) <= axis_crossbar1_in_tdata_reg(i);
			axis_crossbar1_in_tuser_reg2(i) <= axis_crossbar1_in_tuser_reg(i);
			axis_crossbar1_in_tlast_reg2(i) <= axis_crossbar1_in_tlast_reg(i);
			axis_crossbar1_in_tvalid_reg2(i) <= axis_crossbar1_in_tvalid_reg(i);
			if cb1_reset_reg = '1' then
				axis_crossbar1_in_tvalid_reg2(i) <= '0';
			end if;

		end loop;
	end if;
end process;

crossbar0_gen: if IMPLEMENT_CROSSBAR1 generate
	chan_crossbar0: entity work.CHAN_CROSSBAR
		generic map (
		 	PLATFORM_ID => PLATFORM_ID,  -- needed to select family-dependent FIFOs
			NUMBER_OF_INPUT_LANES  => NUMBER_OF_CROSSBAR_INPUTS,
			NUMBER_OF_OUTPUT_LANES => NUMBER_OF_CROSSBAR_OUTPUTS,
			-- BINSEL_PBLOCK_MAP => (0 to 4 => 0, 5 to 8 => 1, 9 to 12 => 2, 13 to 15 => 3),
			BINSEL_PBLOCK_MAP => (0 to 4 => 0, 5 to 8 => 1, 9 to 12 => 1, 13 to 15 => 0),
			EIGHT_BIT_SUPPORT      => FALSE
		)
		port map (
			-- Input stream from the channelizer (AXI4-streaming, non-blocking, on clk)
			s_axis_tvalid => axis_crossbar1_in_tvalid_reg2,
			s_axis_tdata  => axis_crossbar1_in_tdata_reg2,
			s_axis_tlast  => axis_crossbar1_in_tlast_reg2,
			s_axis_tuser  => axis_crossbar1_in_tuser_reg2,

			-- Output stream to the shuffle module (AXI4-streaming, non-blocking, on clk)
			m_axis_tdata  => axis_crossbar1_out_tdata,
			m_axis_tvalid => axis_crossbar1_out_tvalid,
			m_axis_tlast  => axis_crossbar1_out_tlast,
			-- m_axis_tready => axis_crossbar1_out_tready,

			frame_clk_out => frame_clk,
			clk           => ct_clk,
			rst           => cb1_reset_reg2,

			lane_monitor => debug2,
			-- Control interface (command and reply stream buses)
			ctrl_cmd_dat  => TOP_CROSSBAR1_CMD_DAT,
			ctrl_cmd_rdy  => TOP_CROSSBAR1_CMD_RDY,
			ctrl_rply_dat => TOP_CROSSBAR1_RPLY_DAT,
			ctrl_rply_rdy => TOP_CROSSBAR1_RPLY_RDY,
			ctrl_clk      => CTRL_CLK,
			ctrl_rst      => crossbar1_CTRL_RST
			);
end generate crossbar0_gen;
---------------------------------------------------------------------
-- BACKPLANE PCB and QSFP DATA LINKS
---------------------------------------------------------------------
--! Implements the GTX links to exchange the packetized data over to other boards on the backplane (over the backplane PCB links) or to boards on another crate (using the backplane QSFP links).

BPSHFGEN: if IMPLEMENT_CROSSBAR2_AND_CROSSBAR3 generate
	-- Index the system control buses as a separate signal here , because the simulator will make errors if we index it directly on the instantiation
	top_bp_shuffle_cmd_dat             <= top_cmd_dat(BP_SHUFFLE_BASE_PORT);
	top_cmd_rdy(BP_SHUFFLE_BASE_PORT)  <= top_bp_shuffle_cmd_rdy;
	top_bp_shuffle_rply_rdy            <= top_rply_rdy(BP_SHUFFLE_BASE_PORT);
	top_rply_dat(BP_SHUFFLE_BASE_PORT) <= top_bp_shuffle_rply_dat;

	-- Pipeline the channelizer crossbar output to the backplane PCB shuffle input
	bp_pcb_shuffle_in_pipe_proc: process(ct_clk)
	begin
		if rising_edge(ct_clk) then
			bp_shuffle_reset <= (others=> ct_reset_reg);
			bp_shuffle_reset_reg <= bp_shuffle_reset(0);

			for i in 0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES-1 loop
				axis_bp_shuffle_in_tdata(i) <= axis_crossbar1_out_tdata(i);
				axis_bp_shuffle_in_tvalid(i) <= axis_crossbar1_out_tvalid(i);
				axis_bp_shuffle_in_tlast(i) <= axis_crossbar1_out_tlast(i);
				if bp_shuffle_reset(i) = '1' then
					axis_bp_shuffle_in_tvalid(i) <= '0';
				end if;
			end loop;
			for i in 0 to NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1 loop
				axis_bp_shuffle_in_tdata(NUMBER_OF_BP_PCB_SHUFFLE_LANES + i) <= axis_crossbar2_out_tdata(i);
				axis_bp_shuffle_in_tvalid(NUMBER_OF_BP_PCB_SHUFFLE_LANES + i) <= axis_crossbar2_out_tvalid(i);
				axis_bp_shuffle_in_tlast(NUMBER_OF_BP_PCB_SHUFFLE_LANES + i) <= axis_crossbar2_out_tlast(i);
				if bp_shuffle_reset(NUMBER_OF_BP_PCB_SHUFFLE_LANES + i) = '1' then
					axis_bp_shuffle_in_tvalid(NUMBER_OF_BP_PCB_SHUFFLE_LANES + i) <= '0';
				end if;
			end loop;
		end if;
	end process;

	bp_shuffle0: entity work.xglink_array -- use component instantiation to delay binding in this if-generate block and prevent errors
		generic map (
			LINK_SPEED             => BP_LINK_SPEED, -- 0: 7.5 Gb/s (244 MHz word clock), 1: 10 Gb/s (322 MHz word clock)
			NUMBER_OF_LANES        => NUMBER_OF_BP_PCB_SHUFFLE_LANES + NUMBER_OF_BP_QSFP_SHUFFLE_LANES,
			NUMBER_OF_LANE_GROUPS  => 2,
			-- LANE_GROUP_MAP         => (0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES-1 => 0, NUMBER_OF_BP_PCB_SHUFFLE_LANES to NUMBER_OF_BP_PCB_SHUFFLE_LANES + NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1 => 1),
			LANE_GROUP_MAP         => IntegerArray'(0 to 15 => 0, 16 to 23 => 1), -- We cast to make sure the synthesizer can unambiguously determine the final type and infer the entity in case the entity file is not needed (if-generate is False) and not included in the project
			NUMBER_OF_LINKS        => NUMBER_OF_BP_SHUFFLE_LINKS,
			LANE_TO_LINK_MAP       => BP_SHUFFLE_LANE_MAP,
			NUMBER_OF_REFCLK       => NUMBER_OF_BP_SHUFFLE_REFCLKS,
			LANE_TO_QUAD_MAP       => BP_SHUFFLE_LANE_TO_QUAD_MAP, --! Indicates which quad is associated each channel. The QUAD number is an integer between 0 and N-1, where N is the total number of quads used.
			QUAD_TO_REFCLK_MAP     => BP_SHUFFLE_QUAD_TO_REFCLK_MAP, --! Indicates which refclk is associated with each QUAD (N integers from 0 to NUMBER_OF_REFCLK-1).
			IMPLEMENT_RX           => TRUE,
			SIM                    => FALSE
			)
		port map (
			tx_p     => bp_shuffle_tx_p,
			tx_n     => bp_shuffle_tx_n,
			rx_p     => bp_shuffle_rx_p,
			rx_n     => bp_shuffle_rx_n,
			refclk_p => bp_shuffle_refclk_p,
			refclk_n => bp_shuffle_refclk_n,

			-- TX user interface (AXI-Streaming, non-blocking, on clk_out)
			s_axis_tx_tdata  => axis_bp_shuffle_in_tdata,
			s_axis_tx_tvalid => axis_bp_shuffle_in_tvalid,
			s_axis_tx_tlast  => axis_bp_shuffle_in_tlast,

			-- RX user interface (AXI-Streaming, non-blocking, on clk_out)
			m_axis_rx_tdata  => axis_bp_shuffle_out_tdata,
			m_axis_rx_tvalid => axis_bp_shuffle_out_tvalid,
			m_axis_rx_tlast  => axis_bp_shuffle_out_tlast,

			clk_out    => bp_shuffle_txclk, --! 244 or 322 MHz clock generated by the backplane shuffle transmitter from the reference clock. Must be used to clock all the Tx (slave) interface data.  There is one single clock per array.

			-- Clock monitoring ports
			refclk_div2 => bp_shuffle_refclk_div2, -- divided-by-two version of the 156.25 MHz reference clock fed to the QUAD PLL
			txclk_div2  => bp_shuffle_txclk_div2, -- divided-by-two version of the TX word clock, which is also clk_out

			-- Debug signals
			lane_monitor => open,

			-- User bypass control line
			-- bypass      => axis_bp_shuffle_bypass,

			-- Control and reply streams
			CMD_DAT  => top_bp_shuffle_cmd_dat,
			CMD_RDY  => top_bp_shuffle_cmd_rdy,
			RPLY_DAT => top_bp_shuffle_rply_dat,
			RPLY_RDY => top_bp_shuffle_rply_rdy,
			CTRL_CLK => CTRL_CLK,
			CTRL_RST => bp_shuffle_CTRL_RST_reg,
			areset   => bp_shuffle_reset_reg
		 );

end generate BPSHFGEN;

---------------------------------------------------------------------
-- CROSSBAR 2
---------------------------------------------------------------------

-- Pipeline the backplane PCB shuffle output to the shuffle crossbar input
crossbar2_in_pipe_proc: process(ct_clk)
	begin
		if rising_edge(ct_clk) then
			axis_crossbar2_in_reset <= ct_reset_reg;
			axis_crossbar2_in_reset_reg <= axis_crossbar2_in_reset;

			for i in 0 to NUMBER_OF_BP_PCB_SHUFFLE_LANES-1 loop
					axis_crossbar2_in_tdata(i)  <= axis_bp_shuffle_out_tdata(i);
					axis_crossbar2_in_tvalid(i) <= axis_bp_shuffle_out_tvalid(i);
					axis_crossbar2_in_tlast(i)  <= axis_bp_shuffle_out_tlast(i);
			end loop;
			if ct_reset_reg = '1' then
				axis_crossbar2_in_tvalid <= (others=>'0');
			end if;

			axis_crossbar2_in_tdata_reg  <= axis_crossbar2_in_tdata;
			axis_crossbar2_in_tvalid_reg <= axis_crossbar2_in_tvalid;
			axis_crossbar2_in_tlast_reg  <= axis_crossbar2_in_tlast;
			if axis_crossbar2_in_reset = '1' then
				axis_crossbar2_in_tvalid_reg <= (others=>'0');
			end if;

		end if;
	end process;

CROSSBAR2_GEN: if IMPLEMENT_CROSSBAR2_AND_CROSSBAR3 generate

	signal crossbar2_cmd_dat: AXIS8_DAT_STRUCT;
	signal crossbar2_cmd_rdy: AXIS8_RDY_STRUCT;
	signal crossbar2_rply_dat: AXIS8_DAT_STRUCT;
	signal crossbar2_rply_rdy: AXIS8_RDY_STRUCT;


	signal crossbar3_cmd_dat: AXIS8_DAT_STRUCT;
	signal crossbar3_cmd_rdy: AXIS8_RDY_STRUCT;
	signal crossbar3_rply_dat: AXIS8_DAT_STRUCT;
	signal crossbar3_rply_rdy: AXIS8_RDY_STRUCT;


begin

	crossbar2_cmd_dat<= top_cmd_dat(CROSSBAR2_BASE_PORT);
	top_cmd_rdy(CROSSBAR2_BASE_PORT) <= crossbar2_cmd_rdy;
	crossbar2_rply_rdy<= top_rply_rdy(CROSSBAR2_BASE_PORT);
	top_rply_dat(CROSSBAR2_BASE_PORT) <= crossbar2_rply_dat;

	crossbar2: entity work.shuffle_crossbar -- use component instantiation to delay binding in if-generate block and prevent errors during elaboration
		generic map (
		 	PLATFORM_ID => PLATFORM_ID,  -- needed to select family-dependent FIFOs
			NUMBER_OF_INPUT_LANES              => NUMBER_OF_BP_PCB_SHUFFLE_LANES, -- Number of input streams
			NUMBER_OF_OUTPUT_LANES             => NUMBER_OF_BP_QSFP_SHUFFLE_LANES, -- Number of output streams
			NUMBER_OF_OUTPUT_LANES_PER_BIN_SEL => 4,
			WORDS_PER_BIN_MAX                  => 4,  -- 1st crossbar outputs data for 16 channels max = 4 words
			BINS_PER_FRAME_MAX                 => 128, -- need 128 bins in case i'm in 16
			COMBINE_DATA_FLAGS                 => TRUE,
			SHUFFLE_FLAGS_MASK                 => slv32'(X"00070000") -- count errors from crossbar 2 only
			)
		port map (
			-- Non-blocking AXI-Streaming input
			s_axis_tdata  => axis_crossbar2_in_tdata_reg,
			s_axis_tvalid => axis_crossbar2_in_tvalid_reg,
			s_axis_tlast  => axis_crossbar2_in_tlast_reg,
			-- s_axis_tready => axis_bp_crossbar2_in_tready,

			-- Non-blocking AXI-Streaming output
			m_axis_tdata  => axis_crossbar2_out_tdata,
			m_axis_tvalid => axis_crossbar2_out_tvalid,
			m_axis_tlast  => axis_crossbar2_out_tlast,
			-- m_axis_tready => axis_crossbar2_out_tready,

			-- frame_clk_in => frame_clk,
			clk => ct_clk,
			rst => axis_crossbar2_in_reset_reg,

			align_pulse => debug1,
			-- Control interface (command and reply stream buses)
			ctrl_cmd_dat=> crossbar2_cmd_dat,
			ctrl_cmd_rdy=> crossbar2_cmd_rdy,
			ctrl_rply_dat=> crossbar2_rply_dat,
			ctrl_rply_rdy=> crossbar2_rply_rdy,
			ctrl_clk => CTRL_CLK,
			ctrl_rst => crossbar2_CTRL_RST
		);

	-- Pipeline the backplane PCB shuffle output to the shuffle crossbar input
	crossbar3_in_pipe_proc: process(ct_clk)
	begin
		if rising_edge(ct_clk) then
			axis_crossbar3_reset <= ct_reset_reg;
			axis_crossbar3_reset_reg <= axis_crossbar3_reset;
			for i in 0 to NUMBER_OF_BP_QSFP_SHUFFLE_LANES-1 loop
				axis_crossbar3_in_tdata(i)  <= axis_bp_shuffle_out_tdata(NUMBER_OF_BP_PCB_SHUFFLE_LANES + i); -- QSFP shuffle lanes are concatenated after PCB shuffle lanes
				axis_crossbar3_in_tvalid(i) <= axis_bp_shuffle_out_tvalid(NUMBER_OF_BP_PCB_SHUFFLE_LANES + i);
				axis_crossbar3_in_tlast(i)  <= axis_bp_shuffle_out_tlast(NUMBER_OF_BP_PCB_SHUFFLE_LANES + i);
			end loop;
			if axis_crossbar3_reset = '1' then
				axis_crossbar3_in_tvalid <= (others => '0');
			end if;
		end if;
	end process;

	crossbar3_cmd_dat<= top_cmd_dat(CROSSBAR3_BASE_PORT);
	top_cmd_rdy(CROSSBAR3_BASE_PORT) <= crossbar3_cmd_rdy;
	crossbar3_rply_rdy<= top_rply_rdy(CROSSBAR3_BASE_PORT);
	top_rply_dat(CROSSBAR3_BASE_PORT) <= crossbar3_rply_dat;

	crossbar3: entity work.shuffle_crossbar -- use component instantiation to delay binding in if-generate block and prevent errors during elaboration
		generic map (
		 	PLATFORM_ID => PLATFORM_ID,  -- needed to select family-dependent FIFOs
			NUMBER_OF_INPUT_LANES              => NUMBER_OF_BP_QSFP_SHUFFLE_LANES, -- Number of input streams
			NUMBER_OF_OUTPUT_LANES             => NUMBER_OF_GPU_LINKS, -- Number of output streams
			NUMBER_OF_OUTPUT_LANES_PER_BIN_SEL => 1,
			COMBINE_DATA_FLAGS                 => FALSE,
			WORDS_PER_BIN_MAX                  => 16,
			BINS_PER_FRAME_MAX                 => 64,
			BIN_SEL_FIFO_TYPE_MAP              => integer_16xN_array'(0 to 15 => (0 to 1=>0, others=>0)),
			SHUFFLE_FLAGS_MASK                 => slv32'(X"70000700") -- Count errors from both crossbars. Use a qualified axpression to ensure type is known.

			)
		port map (
			-- Non-blocking AXI-Streaming input
			s_axis_tdata  => axis_crossbar3_in_tdata,
			s_axis_tvalid => axis_crossbar3_in_tvalid,
			s_axis_tlast  => axis_crossbar3_in_tlast,
			-- s_axis_tready => axis_bp_crossbar2_in_tready,

			-- Non-blocking AXI-Streaming output
			m_axis_tdata  => axis_crossbar3_out_tdata,
			m_axis_tvalid => axis_crossbar3_out_tvalid,
			m_axis_tlast  => axis_crossbar3_out_tlast,
			-- m_axis_tready => axis_crossbar2_out_tready,

			-- frame_clk_in => frame_clk,
			clk => ct_clk,
			rst => axis_crossbar3_reset_reg,

			-- Control interface (command and reply stream buses)
			ctrl_cmd_dat=> crossbar3_cmd_dat,
			ctrl_cmd_rdy=> crossbar3_cmd_rdy,
			ctrl_rply_dat=> crossbar3_rply_dat,
			ctrl_rply_rdy=> crossbar3_rply_rdy,
			ctrl_clk => CTRL_CLK,
			ctrl_rst => crossbar3_CTRL_RST
		);

end generate CROSSBAR2_GEN;

-- If there are no shuffle links, connect directly to the output of the 1st crossbar if there are aly lanes there
-- Note: There should be at least as many 1st crossbar outputs as the number of GPU lanes.
--NOXBAR2_GEN: if not IMPLEMENT_CROSSBAR2_AND_CROSSBAR3 generate
--	axis_crossbar2_out_tdata <= axis_crossbar1_out_tdata(0 to NUMBER_OF_GPU_LINKS-1);
--	axis_crossbar2_out_tvalid <= axis_crossbar1_out_tvalid(0 to NUMBER_OF_GPU_LINKS-1);
--	axis_crossbar2_out_tlast <= axis_crossbar1_out_tlast(0 to NUMBER_OF_GPU_LINKS-1);
--	-- axis_crossbar1_out_tready(0 to NUMBER_OF_GPU_LINKS-1) <= (others=>'1');
--	ct_clk <= CORR_CLK;
--end generate;



-----------------------------------------------------------
-----------------------------------------------------------
-- GPU LINKS
-----------------------------------------------------------
-----------------------------------------------------------
-- ! Implements an array of 10G Ethernet transmitters to send data off to the GPUs.
-- ! We have 8x 10G Links connected on the two QSFP+ connectors on the motherboard.

GPUGEN: if NUMBER_OF_GPU_LINKS > 0 generate

	signal gpu_cmd_dat: AXIS8_DAT_STRUCT;
	signal gpu_cmd_rdy: AXIS8_RDY_STRUCT;
	signal gpu_rply_dat: AXIS8_DAT_STRUCT;
	signal gpu_rply_rdy: AXIS8_RDY_STRUCT;


begin
	-- Index the system control buses as a separate signal here , because the simulator will make errors if we index it directly on the instantiation
	gpu_cmd_dat<= top_cmd_dat(GPU_LINK_BASE_PORT);
	top_cmd_rdy(GPU_LINK_BASE_PORT) <= gpu_cmd_rdy;
	gpu_rply_rdy<= top_rply_rdy(GPU_LINK_BASE_PORT);
	top_rply_dat(GPU_LINK_BASE_PORT) <= gpu_rply_dat;

	-- Pipeline the 2nd crossbar output (non-blocking AXI-Streaming bus) to the input to the GPU link blocks to facilitate routing
	gpulinkinpipe_proc: process(ct_clk)
		begin
			if rising_edge(ct_clk) then
				gpu_reset <= ct_reset_reg;
				gpu_reset_reg <= gpu_reset;

				for i in 0 to NUMBER_OF_GPU_LINKS-1 loop
					axis_gpu_tdata(i) <= axis_crossbar3_out_tdata(i);
					axis_gpu_tvalid(i) <= axis_crossbar3_out_tvalid(i);
					axis_gpu_tlast(i) <= axis_crossbar3_out_tlast(i);
					if gpu_reset = '1' then
						axis_gpu_tvalid(i) <= '0';
					end if;
				end loop;
			end if;
		end process;

 -- Use COMPONENT instantiation if this is synthesized as an out-of-context module
	gpulink0: entity work.xge_array
		-- generic map (
		-- 	NUMBER_OF_CHANNELS    => NUMBER_OF_GPU_LINKS,
		-- 	NUMBER_OF_REFCLK      => NUMBER_OF_GPU_REFCLKS,
		-- 	CHANNEL_QUAD          => GPU_CHANNEL_QUAD, --! Indicates which quad is associated each channel. The QUAD number is an integer between 0 and N-1, where N is the total number of quads used.
		-- 	QUAD_REFCLK           => GPU_QUAD_REFCLK, --! Indicates which qua is associated each reference clock.
		-- 	DEFAULT_MAC_SRC_ADDR  => (0 to NUMBER_OF_GPU_LINKS-1=> X"123456789ABC"),
		-- 	DEFAULT_MAC_DEST_ADDR => (0 to NUMBER_OF_GPU_LINKS-1=> X"FFFFFFFFFFFF"),
		-- 	DEFAULT_IP_SRC_ADDR   => (0 to NUMBER_OF_GPU_LINKS-1=> X"0A0A0A0B"),
		-- 	DEFAULT_IP_DEST_ADDR  => (0 to NUMBER_OF_GPU_LINKS-1=> X"0A0A0A0A"),
		-- 	DEFAULT_IP_DEST_PORT  => (0 to NUMBER_OF_GPU_LINKS-1=> X"A028")
		-- 	)
		port map (
			tx_p => xge_tx_p,
			tx_n => xge_tx_n,
			rx_p => xge_rx_p,
			rx_n => xge_rx_n,
			refclk_p => xge_refclk_p,
			refclk_n => xge_refclk_n,
			-- core_status => open,
			-- resetdone => open,

			-- Clock monitors to be fed to the frequency counter
			refclk_div2 => gpu_refclk_div2,
			txclk_div2 => gpu_txclk_div2,

			-- input data interface
			s_axis_tx_tdata  => axis_gpu_tdata,
			s_axis_tx_tvalid => axis_gpu_tvalid,
			s_axis_tx_tlast  => axis_gpu_tlast,
			s_axis_tx_tready => open, -- data is always been sent, independent on whether the transmitter is ready or not. W ehave to set out data rate right to avoid overflows.
			s_axis_tx_clk => std_logic_vector'(axis_gpu_tdata'RANGE=> ct_clk),
			areset => gpu_reset_reg, --async input, so we can use the channel reset

			CMD_DAT => gpu_cmd_dat,
			CMD_RDY => gpu_cmd_rdy,
			RPLY_DAT => gpu_rply_dat,
			RPLY_RDY => gpu_rply_rdy,
			CTRL_CLK => CTRL_CLK,
			CTRL_RST => gpu_ctrl_rst_reg
		 );


end generate GPUGEN;

---------------------------------------------------------
---------------------------------------------------------
-- 100G Ethernet Interface
---------------------------------------------------------
---------------------------------------------------------
CGE_GEN: if IMPLEMENT_100G_ETHERNET generate

	signal axis_cge_tdata: slv32_array(0 to 7); -- First byte to transmit is in in LSB (i.e first bit transmitted is bit 0)
	signal axis_cge_tvalid: std_logic_vector(0 to 7);
	signal axis_cge_tlast: std_logic_vector(0 to 7);
	signal axis_cge_tready: std_logic_vector(0 to 7);
	signal cge_reset, cge_reset_reg: std_logic;

	signal cge_cmd_dat: AXIS8_DAT_STRUCT;
	signal cge_cmd_rdy: AXIS8_RDY_STRUCT;
	signal cge_rply_dat: AXIS8_DAT_STRUCT;
	signal cge_rply_rdy: AXIS8_RDY_STRUCT;


begin

	-- Index the system control buses as a separate signal here , because the simulator will flag errors
	--  if we index it directly on the instantiation
	cge_cmd_dat<= top_cmd_dat(GPU_LINK_BASE_PORT);
	top_cmd_rdy(GPU_LINK_BASE_PORT) <= CGE_CMD_RDY;
	cge_rply_rdy<= top_rply_rdy(GPU_LINK_BASE_PORT);
	top_rply_dat(GPU_LINK_BASE_PORT) <= CGE_RPLY_DAT;

	-- Pipeline the 2nd crossbar output (non-blocking AXI-Streaming bus) to the input to the GPU link blocks to facilitate routing
	cge_pipe_proc: process(ct_clk)
		begin
			if rising_edge(ct_clk) then
				cge_reset <= ct_reset_reg;
				cge_reset_reg <= cge_reset;

				for i in 0 to NUMBER_OF_CHANNELIZERS-1 loop
					axis_cge_tdata(i) <= axis_chan_out_tdata(i);
					axis_cge_tvalid(i) <= axis_chan_out_tvalid(i);
					axis_cge_tlast(i) <= axis_chan_out_tlast(i);
					if cge_reset = '1' then
						axis_cge_tvalid(i) <= '0';
					end if;
				end loop;
			end if;
		end process;

 -- Use COMPONENT instantiation if this is synthesized as an out-of-context module
	cge0: entity work.cge
		-- generic map (
		-- 	NUMBER_OF_CHANNELS    => NUMBER_OF_GPU_LINKS,
		-- 	NUMBER_OF_REFCLK      => NUMBER_OF_GPU_REFCLKS,
		-- 	CHANNEL_QUAD          => GPU_CHANNEL_QUAD, --! Indicates which quad is associated each channel. The QUAD number is an integer between 0 and N-1, where N is the total number of quads used.
		-- 	QUAD_REFCLK           => GPU_QUAD_REFCLK, --! Indicates which qua is associated each reference clock.
		-- 	DEFAULT_MAC_SRC_ADDR  => (0 to NUMBER_OF_GPU_LINKS-1=> X"123456789ABC"),
		-- 	DEFAULT_MAC_DEST_ADDR => (0 to NUMBER_OF_GPU_LINKS-1=> X"FFFFFFFFFFFF"),
		-- 	DEFAULT_IP_SRC_ADDR   => (0 to NUMBER_OF_GPU_LINKS-1=> X"0A0A0A0B"),
		-- 	DEFAULT_IP_DEST_ADDR  => (0 to NUMBER_OF_GPU_LINKS-1=> X"0A0A0A0A"),
		-- 	DEFAULT_IP_DEST_PORT  => (0 to NUMBER_OF_GPU_LINKS-1=> X"A028")
		-- 	)
		port map (
			tx_p => cge_tx_p,
			tx_n => cge_tx_n,
			refclk_p => cge_refclk_p,
			refclk_n => cge_refclk_n,
			-- core_status => open,
			-- resetdone => open,
			-- Clock monitors to be fed to the frequency counter
			refclk_div2 => gpu_refclk_div2(0),

			--txclk_div2 => gpu_txclk_div2,

			-- input data interface
			s_axis_tx_tdata  => axis_cge_tdata,
			s_axis_tx_tvalid => axis_cge_tvalid,
			s_axis_tx_tlast  => axis_cge_tlast,
			s_axis_tx_tready => axis_cge_tready, -- data is always been sent, independent on whether the transmitter is ready or not. W ehave to set out data rate right to avoid overflows.
			clk_out    => cge_txclk, --! 322 MHz generated by the core to clock all user interface signals.

			rst => cge_reset,
			--clk200 => clk200,
			--areset => gpu_reset_reg, --async input, so we can use the channel reset

			CMD_DAT => cge_cmd_dat,
			CMD_RDY => cge_cmd_rdy,
			RPLY_DAT => cge_rply_dat,
			RPLY_RDY => cge_rply_rdy,
			CTRL_CLK => ctrl_clk,
			CTRL_RST => gpu_ctrl_rst_reg
		 );


end generate CGE_GEN;


---------------------------------------------------------------------
--  Correlator
---------------------------------------------------------------------
--! Each correlator feed the corner-turned data to a streaming correlator/integrator.
--! A slow data link is used to capture the output of the integrator after each integration period.

--! Correlator reset process
--! We try to use multiple registered stages and multiple output to ease the timing closure, although the synthesizer might remove some of those extra redundant registers.
-- top_cmd_rdy(CORR_BASE_PORT).TREADY <= 'H';

CORRGEN: if NUMBER_OF_CORRELATORS>0 generate

	signal corr_cmd_dat: AXIS8_DAT_STRUCT; -- shared with CROSSBAR3
	signal corr_cmd_rdy: AXIS8_RDY_STRUCT;
	signal corr_rply_dat: AXIS8_DAT_STRUCT;
	signal corr_rply_rdy: AXIS8_RDY_STRUCT;

	signal corr_reset_reg1: std_logic;
	attribute DONT_TOUCH of corr_reset_reg1: signal is "true";

begin
	--PRB_PORT_OFFSET(CORR_PROBE_BASE_PORT + NUMBER_OF_CORRELATORS-1 downto CORR_PROBE_BASE_PORT) <= (others => CORR_IP_PORT_OFFSET); --! Assign the IP port number to be used for the returned data
 	--! Pipeline and replicate the correlator data reset input to facilitate routing and timing closure.
 	corrrst_proc: process(ct_clk)
 		begin
 			if rising_edge(ct_clk) then
 				corr_reset_reg1 <= ct_reset_reg;
 			end if;
 		end process;

 		-- Connect the correlator inputs and outputs
 		CORR_PRB_GEN: for i in 0 to NUMBER_OF_CORRELATORS-1 generate
 			-- input bus. 1:1 connection between each correlator and crossbar output. Pipeling in the module.
			axis_corr_in_tvalid(i)                 <= axis_crossbar1_out_tvalid(i);
			axis_corr_in_tlast(i)                  <= axis_crossbar1_out_tlast(i);
			axis_corr_in_tdata(i)                  <= axis_crossbar1_out_tdata(i);
			-- output bus. Connects to the probe port
			axis_prb_tdata(CORR_PROBE_BASE_PORT+i)  <= axis_corr_out_tdata(i);
			axis_prb_tvalid(CORR_PROBE_BASE_PORT+i) <= axis_corr_out_tvalid(i);
			axis_prb_tlast(CORR_PROBE_BASE_PORT+i)  <= axis_corr_out_tlast(i);
			axis_corr_out_tready(i)                 <= axis_prb_tready(CORR_PROBE_BASE_PORT+i);
 		end generate;

 		-- Extract the control interface
		corr_cmd_dat<= top_cmd_dat(CORR_BASE_PORT);
	 	top_cmd_rdy(CORR_BASE_PORT) <= corr_cmd_rdy;
	 	corr_rply_rdy<= top_rply_rdy(CORR_BASE_PORT);
	 	top_rply_dat(CORR_BASE_PORT) <= corr_rply_dat;


		corr_array0: entity work.corr44_array
			generic map (
				PLATFORM_ID             => PLATFORM_ID, -- needed to determine the RPM spacing of the DSP and BRAM elements and choose the right primitives
				NUMBER_OF_CORRELATORS   => NUMBER_OF_CORRELATORS,
				NUMBER_OF_WORDS_PER_BIN => NUMBER_OF_CROSSBAR_INPUTS/4 -- Is hardwired as a generics to simplify logic. Also corresponds to the number of clocks per bin.
				-- Position of each correlator (using the RPM grid)
				--LEFT_DSP_RPM_X          => (361, 425, 361, 425, 361, 425, 361, 425 ),
				--LEFT_BRAM_RPM_X         => (350, 438, 350, 438, 350, 438, 350, 438 ),
				--RIGHT_DSP_RPM_X         => (381, 473, 381, 473, 381, 473, 381, 473 ),
				--RIGHT_BRAM_RPM_X        => (394, 462, 394, 462, 394, 462, 394, 462 ),
				--BOTTOM_DSP_RPM_Y        => (0, 0 , 170, 170, 450, 450, 620, 620),
				--BOTTOM_BRAM_RPM_Y       => (0, 0 , 170, 170, 450, 450, 620, 620)

				--LEFT_DSP_RPM_X          => corr_rpm.LEFT_DSP_X,
				--LEFT_BRAM_RPM_X         => corr_rpm.LEFT_BRAM_X,
				--RIGHT_DSP_RPM_X         => corr_rpm.RIGHT_DSP_X,
				--RIGHT_BRAM_RPM_X        => corr_rpm.RIGHT_BRAM_X,
				--BOTTOM_DSP_RPM_Y        => corr_rpm.DSP_BOTTOM_Y,
				--BOTTOM_BRAM_RPM_Y       => corr_rpm.BRAM_BOTTOM_Y
				)
			port map(
				-- Input data interface (AXI4-Streaning, 16-bit wide, non-blocking)

				s_axis_tvalid           => axis_corr_in_tvalid,
				s_axis_tlast            => axis_corr_in_tlast,
				s_axis_tdata            => axis_corr_in_tdata,

				in_clk                  => ct_clk,
				in_rst                  => corr_reset_reg1,

				-- Correlated data output interface (AXI4-Streaning, 8-bit wide, blocking)

				m_axis_data_out_tdata   => axis_corr_out_tdata,
				m_axis_data_out_tvalid  => axis_corr_out_tvalid,
				m_axis_data_out_tlast   => axis_corr_out_tlast,
				m_axis_data_out_tready  => axis_corr_out_tready,

				out_clk                 => ctrl_clk,
				out_rst                 => ctrl_rst,

				-- Control interface

				CMD_DAT  => corr_cmd_dat,
				CMD_RDY  => corr_cmd_rdy,
				RPLY_DAT => corr_rply_dat,
				RPLY_RDY => corr_rply_rdy,
				CTRL_CLK => ctrl_clk,
				CTRL_RST => ctrl_rst
				);

end generate CORRGEN; -- if NUMBER_OF_CORR >0


-----------------------------------------------------------------------
---- LED blinking, for a comfortable user experience
-----------------------------------------------------------------------
BLINKER_RESET_ALL <= sys_ctrl_rst_reg or BLINKER_RESET;
blinker_rst <= BLINKER_RESET_ALL or (not sfp_status_vector_int(0)); -- do not blink if Link Status = 0
blinker_kick <= axis_udp_rx_tvalid and axis_udp_rx_tlast; -- blink faster when packets are received
gpio_led <= gpio_led_int;
--blinker_leds <= gpio_led_int;
BLINKER0: entity work.BLINKER
		GENERIC MAP(
			DUMMY => not BLINKER_PRESENT,
			PING_PONG => PLATFORM_ID=PLATFORM_ID_ZCU111 or PLATFORM_ID=PLATFORM_ID_KC705 or PLATFORM_ID=PLATFORM_ID_ML605 -- We have 8 LEDS on these platform to perform a nice light show
			)
	PORT MAP(
		RST => blinker_rst, -- do not blink if Link Status = 0
		CLK => ctrl_clk,
		LEDS=> gpio_led_int,
		kick => blinker_kick -- blink faster when packets are received
	);
end Behavioral;

