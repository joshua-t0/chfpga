----------------------------------------------------------------------------------
--! Top-level file to implement siFPGA on the ZCU111 Zynq RfSOC evaluation board
-- Company: McGill University
-- Engineer: JF Cliche
--
-- Create Date:    2021-09-29
-- Design Name:    sifpga_zcu111
-- Target Devices: Zynq Ultrascale+ RfSoC ZU29
-- Tool versions: Vivado 2021.1

---  LIBRARY DECLARATIONS -------------------------------------------------------------------------------

--! Standard libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;
--! Project libraries
use work.chFPGA_Package.all; --! Get all component definitions

----ENTITY DECLARATION --------
-- This is the _top level entity of the data acquisition/channelizer/correlator firmware.
-- It is meant to be integrated as a block diagram block in Vivado. The top level block diagram must provide the following
--   - IO ports to the FPGA pins, including constraints
--   - ADC streams
--
--The ports of this top-level entity correspond to physical pins on the Kintex 7 FPGA on that board. The location of these pins are defined in the constraint file.
entity sifpga_zcu111_chfpga_wrapper is
	 generic (

	 		-- NOTE: All generics values must be literals if the module is to be imported in a block diagram
			PLATFORM_ID: integer                         := 4; --! identifies the type of platform on which the firmware is running. 0=ML605, 1=KC705

			SYSTEM_CLOCK_SOURCE: string                  := "CLK10_BUFG"; --! System reference clock surce: "SYSCLK": 200 MHz unbuffered differential clock from sysclk_p/n, "SYSCLK_BUFG": 200 MHz BUFG-Buffered clock from sysclk_bufg, "SFP_REFCLK": 125 MHz clock from the GTX reference clock
			SYSTEM_CLOCK_FREQ: integer                   := 10; -- System reference clock frequency, in MHz *** Is an integer because IP packager does not support real. ***
			CHAN_CLK_SOURCE: string                      := "ADC"; -- Channelizer clock comes directly from the ADC
			CT_CLK_SOURCE: string                        := "ADC_CLK";

			-- Control interface config
			PHY_TYPE: string                             := "NONE"; -- "GMII" or "SGMII"
			SGMII_CLOCK_SOURCE: string                   := "REFCLK"; --! Selects the 125MHz clock source for the SGMII interface; "CLK125": uses the 125 MHz clock (clk125) from the main MMCM, "REFCLK": uses the GTX Reference clock (gtrefclk)
			--IMPLEMENT_ADCDAQ: boolean                    := FALSE; -- use ADC data directly from adc_axis_* ports.

			-- ADC config
			NUMBER_OF_ADC_BOARDS: integer                := 0; -- No REFCLK module
			NUMBER_OF_ADCS: integer                      := 8; --! Number of ADC Data acquisition blocks to implement
			ADC_TYPE: string                             := "AXIS"; -- ADC data is provided through the axis_adc port

			-- Channelizer config
			NUMBER_OF_CHANNELIZERS:integer               := 8;  --!(Typ. =16)  (0-NUMBER_OF_ADCS) Number of channelizer blocks to be implemented


			-- Corner-turn config
			CROSSBAR1_TYPE: string                       := "URAM"; -- "BRAM" or "URAM"
			NUMBER_OF_CROSSBAR_INPUTS: integer           := 8; --! (Typ. =16)(0-NUMBER_OF_CHANNELIZERS): Number of channelizers output that are being aligned, filtered and repacked for the corrleator or GPU links
			NUMBER_OF_CROSSBAR_OUTPUTS: integer          := 8; --! (Typ. =16): Number of repacked data streams to feed to the corrleator or GPU links
			NUMBER_OF_CORRELATORS: integer               := 0; --! Number of correlators. Normally NUMBER_OF_CROSSBAR_OUTPUTS. Correlator not implemented if zero.
			NUMBER_OF_BP_PCB_SHUFFLE_LANES: integer      := 0;
			NUMBER_OF_BP_QSFP_SHUFFLE_LANES: integer     := 0;
			NUMBER_OF_BP_SHUFFLE_LINKS: integer          := 0; --! Number of GTXes for both the backplane PCB and QSFP shuffle links. Usually matches the number of 1st crossbar output lanes.
			NUMBER_OF_BP_SHUFFLE_REFCLKS: integer        := 0;

			-- Real-time data offload config
			IMPLEMENT_100G_ETHERNET: boolean             := TRUE; --! If TRUE, a 100G UDP/IP/Ethernet data transmitter is implemented
			NUMBER_OF_GPU_LINKS: integer                 := 0; --! (0- NUMBER_OF_REORDER_OUTPUTS) Number of 10Gb Ethernet links to connecto to the GPUs
			NUMBER_OF_GPU_REFCLKS: integer               := 1; --! Number of Reference clocks provided for the 10GE links to the GPU
			--ANT_CLK_SOURCE: integer := 0; -- Indicate which ADC is the source of the antenna processing clock. Must be one that has ADC_INSTANTIATE_PLL=TRUE so we have a BUFG that can clock the logic across the chip

			-- Peripheral config
			BLINKER_PRESENT: boolean                     := TRUE; --! Indicates if the LED flasher is to be implemented by setting the DUMMY flag of the BLINKER module
			NUMBER_OF_I2C_PORTS: integer                 := 0;
			NUMBER_OF_SPI_PORTS: integer                 := 0; -- One port for each FMC

			SIM: boolean := FALSE--! Indicates this is running as a simulation. Used to accelerate simulations

	);
    PORT (
			------------------------------------
			-- SYSTEM
			------------------------------------

			-- Reset line
			cpu_reset_n: in std_logic; --! Hardware reset generated by the board


			--raw_clk10: in std_logic; -- 10 MHz Board clock reference (From primary clock buffer, no PLL. Single-ended. Not.
			--mgt_clk10_p: in std_logic; --! 10 MHz backplane reference clock (From PLL in Bypass mode). Used for synchronizing ADCs.
			--mgt_clk10_n: in std_logic;
			--mgt_clk100_p: in std_logic; --! 100 MHz MGT reference clock (From PLL). Used only with frequency counter for connectivity tests.
			--mgt_clk100_n: in std_logic;
			--mgt_clk200_p: in std_logic; --! 200 MHz MGT reference clock (From PLL). Used only with frequency counter for connectivity tests.
			--mgt_clk200_n: in std_logic;
			--mgt_clk125_p: in std_logic; --! 125 MHz MGT reference clock (From PLL). Used only with frequency counter for connectivity tests.
			--mgt_clk125_n: in std_logic;

--			bp_io: out  std_logic_vector(8 downto 0); --! Backplane IO
			--sma_a: inout std_logic; -- sync out
			--sma_b_fpga_led2: inout std_logic; -- LED2
			--bp_time_p: in std_logic; -- Time_P
			--bp_time_n: in std_logic; -- Time_N
			--bp_trig_p: in std_logic; -- Trig_P (used as Sync in)
			--bp_trig_n: in std_logic; -- Trig_N
			--bp_gpio_int: inout std_logic;
			--bp_buck_sync: inout std_logic;
			--fpga_led1_bp_sma: inout std_logic; -- FPGA LED1 & Backplane SMA
			gpio_led: out std_logic_vector(7 downto 0);

			------------------------------------
			--  IIC/PMBus
			------------------------------------
			--i2c_scl: inout std_logic; --!   (I2C) clock (bidirectional)
			--i2c_sda: inout std_logic; --!   (I2C) data (bidirectional)

			------------------------------------
			-- ARM <-> FPGA SPI port
			------------------------------------
			--arm_spi_sck : in std_logic;
			--arm_spi_miso : out std_logic;
			--arm_spi_mosi : in std_logic;
			--arm_spi_cs_n : in std_logic;
			--flash_spi_cs_n: inout std_logic;
			------------------------------------
			-- ARM IRQ line
			------------------------------------
			--arm_irq_n: inout std_logic;

			------------------------------------
			-- IceBoard GPIO devices reset
			------------------------------------
			--gpio_rst_n: inout std_logic;
			--gpio_irq_n: inout std_logic;

			------------------------------------
			-- UART to/from ARM or connector
			------------------------------------

			--uart_tx: inout std_logic; --
			--uart_rx: inout std_logic; --

			------------------------------------
			-- SFP Module (Gbit Ethernet)
			------------------------------------

			-- SFP_LOS: out std_logic; --! SFP Loss of Signal flag

			-- system clock
			clk200_bufg: in std_logic;

			-- Unbuffered 125 MHz clock. Used to internally generate system
			-- and other clocks with a MMCM. (is sfp_clk on other boards).
			-- Generated by the SI5341B clock generator which generates
			-- (generally) fixed frequencies for the PS and PL. This clock
			-- does not have a phase relationship with the ADC clock.
			--clk125_p: in std_logic;
			--clk125_n: in std_logic; --!

			-- Buffered 10 MHz clock, provided by the RF PLL output 0 (SYSREF_FPGA). The PLL needs to be software configured to this frequency.
			clk10: in std_logic;
			--sfp_clk_n: in std_logic;
			--sfp_tx_p: out std_logic; --! Serialized data from the FPGA MGT to the SFP
			--sfp_tx_n: out std_logic;
			--sfp_rx_p: in std_logic; --! Serialized data from the SFP to the FPGA MGT
			--sfp_rx_n: in std_logic;

			--xge_tx_p: out std_logic_vector(0 to NUMBER_OF_GPU_LINKS-1);
			--xge_tx_n: out std_logic_vector(0 to NUMBER_OF_GPU_LINKS-1);
			--xge_rx_p: in std_logic_vector(0 to NUMBER_OF_GPU_LINKS-1);
			--xge_rx_n: in std_logic_vector(0 to NUMBER_OF_GPU_LINKS-1);
			--xge_refclk_p: in std_logic_vector(0 to NUMBER_OF_GPU_REFCLKS-1);
			--xge_refclk_n: in std_logic_vector(0 to NUMBER_OF_GPU_REFCLKS-1);

			--bp_shuffle_tx_p: out std_logic_vector(0 to NUMBER_OF_BP_SHUFFLE_LINKS-1);
			--bp_shuffle_tx_n: out std_logic_vector(0 to NUMBER_OF_BP_SHUFFLE_LINKS-1);
			--bp_shuffle_rx_p: in std_logic_vector(0 to NUMBER_OF_BP_SHUFFLE_LINKS-1);
			--bp_shuffle_rx_n: in std_logic_vector(0 to NUMBER_OF_BP_SHUFFLE_LINKS-1);
			--bp_shuffle_refclk_p: in std_logic_vector(0 to NUMBER_OF_BP_SHUFFLE_REFCLKS-1);
			--bp_shuffle_refclk_n: in std_logic_vector(0 to NUMBER_OF_BP_SHUFFLE_REFCLKS-1);

			--sync_1v0_gtx: out std_logic;
			--sync_3v3: out std_logic;
			--sync_12v0: out std_logic;
			--sync_5v0: out std_logic;
			--sync_1v0: out std_logic;
			--sync_vadj: out std_logic;
			--sync_1v5: out std_logic;
			--sync_1v8: out std_logic;
			--sync_1v2: out std_logic;

			------------------------------------
			-- ADCs
			------------------------------------

			-- ADC0 signals
			adc0_axis_tdata : in  std_logic_vector (127 downto 0); --! AH data bus from the ADC chip 0 on the ADC board. This is DDR. The AL bus and overrange lines are not used.
			adc0_axis_tvalid : in  std_logic;
			adc0_axis_tready : out  std_logic;
			adc0_axis_clk : in  std_logic; --! data clock generated by the LMK04208 output 2 (FPGA_REFCLK_OUT). Is 1/4 the frequency of the the sampling clock.
			-- ADC1 signals
			adc1_axis_tdata : in  std_logic_vector (127 downto 0); --! AH data bus from the ADC chip 0 on the ADC board. This is DDR. The AL bus and overrange lines are not used.
			adc1_axis_tvalid : in  std_logic;
			adc1_axis_tready : out  std_logic;
			adc1_axis_clk : in  std_logic; --! data clock
			-- ADC2 signals
			adc2_axis_tdata : in  std_logic_vector (127 downto 0); --! AH data bus from the ADC chip 0 on the ADC board. This is DDR. The AL bus and overrange lines are not used.
			adc2_axis_tvalid : in  std_logic;
			adc2_axis_tready : out  std_logic;
			adc2_axis_clk : in  std_logic; --! data clock
			-- ADC3 signals
			adc3_axis_tdata : in  std_logic_vector (127 downto 0); --! AH data bus from the ADC chip 0 on the ADC board. This is DDR. The AL bus and overrange lines are not used.
			adc3_axis_tvalid : in  std_logic;
			adc3_axis_tready : out  std_logic;
			adc3_axis_clk : in  std_logic; --! data clock
			-- ADC4 signals
			adc4_axis_tdata : in  std_logic_vector (127 downto 0); --! AH data bus from the ADC chip 0 on the ADC board. This is DDR. The AL bus and overrange lines are not used.
			adc4_axis_tvalid : in  std_logic;
			adc4_axis_tready : out  std_logic;
			adc4_axis_clk : in  std_logic; --! data clock
			-- ADC5 signals
			adc5_axis_tdata : in  std_logic_vector (127 downto 0); --! AH data bus from the ADC chip 0 on the ADC board. This is DDR. The AL bus and overrange lines are not used.
			adc5_axis_tvalid : in  std_logic;
			adc5_axis_tready : out  std_logic;
			adc5_axis_clk : in  std_logic; --! data clock
			-- ADC6 signals
			adc6_axis_tdata : in  std_logic_vector (127 downto 0); --! AH data bus from the ADC chip 0 on the ADC board. This is DDR. The AL bus and overrange lines are not used.
			adc6_axis_tvalid : in  std_logic;
			adc6_axis_tready : out  std_logic;
			adc6_axis_clk : in  std_logic; --! data clock
			-- ADC7 signals
			adc7_axis_tdata : in  std_logic_vector (127 downto 0); --! AH data bus from the ADC chip 0 on the ADC board. This is DDR. The AL bus and overrange lines are not used.
			adc7_axis_tvalid : in  std_logic;
			adc7_axis_tready : out  std_logic;
			adc7_axis_clk : in  std_logic; --! data clock
			-- ADC tile output clocks
			adc0_clkout : in  std_logic;
			adc1_clkout : in  std_logic;
			adc2_clkout : in  std_logic;
			adc3_clkout : in  std_logic;

			--==== 100G Ethernet QSFP28 interface

			qsfp_txp: out std_logic_vector(0 to 3);
			qsfp_txn: out std_logic_vector(0 to 3);
			--cge_rx_p: in std_logic_vector(0 to 3) := (others => '0');
			--cge_rx_n: in std_logic_vector(0 to 3):= (others => '1');
			-- Gigabit transceiver refrenece clocks (typically 156.25 MHz)
			clk156_p: in std_logic := '0';
			clk156_n: in std_logic := '1';

			--==== BSB control interface
			-- Command input stream
			s_bsb_axis_tdata: in std_logic_vector(31 downto 0) := (others => '0');
			s_bsb_axis_tvalid: in std_logic := '0';
			s_bsb_axis_tlast: in std_logic := '0';
			s_bsb_axis_tready: out std_logic;

			-- Reply output stream
			m_bsb_axis_tdata: out std_logic_vector(31 downto 0);
			m_bsb_axis_tvalid: out std_logic;
			m_bsb_axis_tlast: out std_logic;
			m_bsb_axis_tready: in std_logic := '1';

			bsb_axis_clk : in  std_logic; -- 125 MHz clock
			bsb_axis_rst : in  std_logic -- synchronous to bsb_axis_clk


		);
end entity sifpga_zcu111_chfpga_wrapper;

---------- chFPGA implementation ------
--! Implements the chFPGA CHIME PoC Data acquisition/channelizer/corrrlator for the KC705 evaluation board (equipped with a Kintex 7 7K355 FPGA).
--! This simply instantiate the generic chFPGA code with the appropriate generics for that hardware platform.
--!
architecture impl of sifpga_zcu111_chfpga_wrapper is 
	-- SIGNALS

	attribute IOB: string;
	attribute DONT_TOUCH: string;

	ATTRIBUTE X_INTERFACE_INFO : STRING;
--	ATTRIBUTE X_INTERFACE_INFO of clk125_p: SIGNAL is "xilinx.com:interface:diff_clock:1.0 sysclk125 CLK_P";
--	ATTRIBUTE X_INTERFACE_INFO of clk125_n: SIGNAL is "xilinx.com:interface:diff_clock:1.0 sysclk125 CLK_N";
	ATTRIBUTE X_INTERFACE_PARAMETER : STRING;
	--ATTRIBUTE X_INTERFACE_PARAMETER of clk125_p: SIGNAL is "FREQ_HZ 125000000";
	ATTRIBUTE X_INTERFACE_PARAMETER of clk200_bufg: SIGNAL is "FREQ_HZ 200000000";
	ATTRIBUTE X_INTERFACE_PARAMETER of clk10: SIGNAL is "FREQ_HZ 10000000";


	signal adc_axis_tdata: slv128_array(0 to 7);
	signal adc_axis_tvalid: std_logic_vector(0 to 7);
	signal adc_axis_clk: std_logic_vector(0 to 7);
	signal adc_clkout: std_logic_vector(0 to 7);

	signal cpu_reset: std_logic;

begin

	cpu_reset <= not cpu_reset_n; --! Reset is active LOW on the ICEBoard

	-- Remap the separate ADC inputs into an array
	-- ADC data comes in 64-bit bus that contains 4 samples, 16-bit word per sample. Data is MSB-aligned in each word. First sample is presumably in the lower word.
	-- chFPGA input requires 32-bit bus, 1 byte per sample. THE FIRST SAMPLE IS IN THE MSB. This is a convention of the Casper FFT.

	--adc_axis_tdata <= (
	--    adc0_axis_tdata(15 downto 0) &  adc0_axis_tdata(31 downto 16) & adc0_axis_tdata(47 downto 32) &  adc0_axis_tdata(63 downto 48),
	--    adc1_axis_tdata(15 downto 0) &  adc1_axis_tdata(31 downto 16) & adc1_axis_tdata(47 downto 32) &  adc1_axis_tdata(63 downto 48),
	--    adc2_axis_tdata(15 downto 0) &  adc2_axis_tdata(31 downto 16) & adc2_axis_tdata(47 downto 32) &  adc2_axis_tdata(63 downto 48),
	--    adc3_axis_tdata(15 downto 0) &  adc3_axis_tdata(31 downto 16) & adc3_axis_tdata(47 downto 32) &  adc3_axis_tdata(63 downto 48),
	--    adc4_axis_tdata(15 downto 0) &  adc4_axis_tdata(31 downto 16) & adc4_axis_tdata(47 downto 32) &  adc4_axis_tdata(63 downto 48),
	--    adc5_axis_tdata(15 downto 0) &  adc5_axis_tdata(31 downto 16) & adc5_axis_tdata(47 downto 32) &  adc5_axis_tdata(63 downto 48),
	--    adc6_axis_tdata(15 downto 0) &  adc6_axis_tdata(31 downto 16) & adc6_axis_tdata(47 downto 32) &  adc6_axis_tdata(63 downto 48),
	--    adc7_axis_tdata(15 downto 0) &  adc7_axis_tdata(31 downto 16) & adc7_axis_tdata(47 downto 32) &  adc7_axis_tdata(63 downto 48)
 --       );
	-- ADC data comes in 128-bit bus that contains 8 samples, 16-bit word per sample. Data is MSB-aligned in each word. First sample is in the lower word.
	-- We downsample by 2:1
	adc_axis_tdata <= (
	    adc0_axis_tdata,
	    adc1_axis_tdata,
	    adc2_axis_tdata,
	    adc3_axis_tdata,
	    adc4_axis_tdata,
	    adc5_axis_tdata,
	    adc6_axis_tdata,
	    adc7_axis_tdata);

	adc_axis_tvalid <= (
		adc0_axis_tvalid,
		adc1_axis_tvalid,
		adc2_axis_tvalid,
		adc3_axis_tvalid,
		adc4_axis_tvalid,
		adc5_axis_tvalid,
		adc6_axis_tvalid,
		adc7_axis_tvalid);

	adc_axis_clk <= (
		adc0_axis_clk,
		adc1_axis_clk,
		adc2_axis_clk,
		adc3_axis_clk,
		adc4_axis_clk,
		adc5_axis_clk,
		adc6_axis_clk,
		adc7_axis_clk);

	adc_clkout <= (
		adc0_clkout,
		adc0_clkout,
		adc1_clkout,
		adc1_clkout,
		adc2_clkout,
		adc2_clkout,
		adc3_clkout,
		adc3_clkout);


	-- Always ready to receive data from the ADC
	adc0_axis_tready <= '1';
	adc1_axis_tready <= '1';
	adc2_axis_tready <= '1';
	adc3_axis_tready <= '1';
	adc4_axis_tready <= '1';
	adc5_axis_tready <= '1';
	adc6_axis_tready <= '1';
	adc7_axis_tready <= '1';


	chfpga0: entity work.chfpga
		GENERIC MAP(
			PLATFORM_ID                     => PLATFORM_ID,

			-- Clocking config
			SYSTEM_CLOCK_SOURCE             => SYSTEM_CLOCK_SOURCE,
			SYSTEM_CLOCK_FREQ               => real(SYSTEM_CLOCK_FREQ),
			CHAN_CLK_SOURCE                 => CHAN_CLK_SOURCE,
			CT_CLK_SOURCE                   => CT_CLK_SOURCE,

			-- Control interface config
			PHY_TYPE                        => PHY_TYPE,
			SGMII_CLOCK_SOURCE              => SGMII_CLOCK_SOURCE,

			-- ADC config
			NUMBER_OF_ADCS                  => NUMBER_OF_ADCS,
			ADC_TYPE                        => ADC_TYPE,

			-- Channelizer config
			NUMBER_OF_CHANNELIZERS          => NUMBER_OF_CHANNELIZERS,


			-- Correlator config
			NUMBER_OF_CORRELATORS           => NUMBER_OF_CORRELATORS,

			-- Corner-turn engine config
			NUMBER_OF_CROSSBAR_INPUTS       => NUMBER_OF_CROSSBAR_INPUTS,
			NUMBER_OF_CROSSBAR_OUTPUTS      => NUMBER_OF_CROSSBAR_OUTPUTS,
			CROSSBAR1_TYPE                  => CROSSBAR1_TYPE,
			NUMBER_OF_GPU_LINKS             => NUMBER_OF_GPU_LINKS,
			NUMBER_OF_GPU_REFCLKS           => NUMBER_OF_GPU_REFCLKS,
			IMPLEMENT_100G_ETHERNET         => IMPLEMENT_100G_ETHERNET,
			NUMBER_OF_BP_PCB_SHUFFLE_LANES  => NUMBER_OF_BP_PCB_SHUFFLE_LANES,
			NUMBER_OF_BP_QSFP_SHUFFLE_LANES => NUMBER_OF_BP_QSFP_SHUFFLE_LANES,
			NUMBER_OF_BP_SHUFFLE_LINKS      => NUMBER_OF_BP_SHUFFLE_LINKS,
			NUMBER_OF_BP_SHUFFLE_REFCLKS    => NUMBER_OF_BP_SHUFFLE_REFCLKS,
			--BP_SHUFFLE_LANE_MAP             => BP_SHUFFLE_LANE_MAP,
			--BP_SHUFFLE_LANE_TO_QUAD_MAP     => BP_SHUFFLE_LANE_TO_QUAD_MAP,
			--BP_SHUFFLE_QUAD_TO_REFCLK_MAP   => BP_SHUFFLE_QUAD_TO_REFCLK_MAP,

			-- Peripherals
			BLINKER_PRESENT                 => BLINKER_PRESENT,
			NUMBER_OF_I2C_PORTS             => NUMBER_OF_I2C_PORTS,
			NUMBER_OF_SPI_PORTS             => NUMBER_OF_SPI_PORTS,
			NUMBER_OF_ADC_BOARDS            => NUMBER_OF_ADC_BOARDS,
			-- IMPLEMENT_ANT                =>IMPLEMENT_ANT, -- Selects for which antenna a processing pipeline is implemented
			-- IMPLEMENT_FFT                =>IMPLEMENT_FFT, -- Selects if the FFT block is implemented for each antenna (otherwise the timestream go through directly)
			-- IMPLEMENT_CORR               =>IMPLEMENT_CORR,
			--ADC_IS_DIFFERENTIAL             => ADC_IS_DIFFERENTIAL,
			--ADC_PROVIDE_BUFFERED_DIVCLK     => ADC_PROVIDE_BUFFERED_DIVCLK,
			--ADC_INSTANTIATE_PLL             => ADC_INSTANTIATE_PLL,
			--ADC_USE_EXT_DATA_CLK            => ADC_USE_EXT_DATA_CLK,
			--ADC_INSTANTIATE_BUFMR           => ADC_INSTANTIATE_BUFMR,
			--ANT_CLK_SOURCE                  => ANT_CLK_SOURCE,
			--GPU_CHANNEL_QUAD                => GPU_CHANNEL_QUAD,
			--GPU_QUAD_REFCLK                 => GPU_QUAD_REFCLK,
			SIM                             => SIM
			)
		PORT MAP(
			-- System
			cpu_reset    => cpu_reset,

			-- LEDs and switches
			gpio_led     => gpio_led,
			--gpio_button0 => '0', -- No pushbutton on the ICEBoard
			--gpio_dip_sw  => (others=>'0'), -- Was used on ML605 Virtex 6 eval board

			-- Clocks
			clk10 => clk10, -- Buffered (BUFG) 10 MHz differential reference clock
			sysclk_bufg => clk200_bufg,

			-- ADC inputs
			adc_axis_tdata => adc_axis_tdata(0 to NUMBER_OF_ADCS-1),
			adc_axis_tvalid => adc_axis_tvalid(0 to NUMBER_OF_ADCS-1),
			adc_axis_clk => adc_axis_clk(0 to NUMBER_OF_ADCS-1),
			adc_clkout => adc_clkout(0 to NUMBER_OF_ADCS-1),

			-- 100GE interface
			cge_tx_p => qsfp_txp,
			cge_tx_n => qsfp_txn,
			cge_refclk_p => clk156_p,
			cge_refclk_n => clk156_n,

			-- Command input stream
			s_bsb_axis_tdata => s_bsb_axis_tdata,
			s_bsb_axis_tvalid => s_bsb_axis_tvalid,
			s_bsb_axis_tlast => s_bsb_axis_tlast,
			s_bsb_axis_tready => s_bsb_axis_tready,

			-- Reply output stream
			m_bsb_axis_tdata => m_bsb_axis_tdata,
			m_bsb_axis_tvalid => m_bsb_axis_tvalid,
			m_bsb_axis_tlast => m_bsb_axis_tlast,
			m_bsb_axis_tready => m_bsb_axis_tready,
			
			bsb_axis_clk => bsb_axis_clk,
			bsb_axis_rst => bsb_axis_rst

			);

end architecture impl;

