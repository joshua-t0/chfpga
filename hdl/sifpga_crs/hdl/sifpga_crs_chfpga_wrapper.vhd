----------------------------------------------------------------------------------
-- Top-level file to implement siFPGA on the crs Zynq RfSOC board
-- Company: McGill University
-- Engineer: JF Cliche
--
-- Create Date:    2021-09-29
-- Design Name:    sifpga_crs
-- Target Devices: Zynq Ultrascale+ RfSoC ZU29
-- Tool versions: Vivado 2021.1

---  LIBRARY DECLARATIONS -------------------------------------------------------------------------------

-- Standard libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;
-- Project libraries
use work.chFPGA_Package.all; -- Get all component definitions
use work.chFPGA_config.all; --Get platform-specific configuration definitions

----ENTITY DECLARATION --------
-- This is the _top level entity of the data acquisition/channelizer/correlator firmware.
-- It is meant to be integrated as a block diagram block in Vivado. The top level block diagram must provide the following
--   - IO ports to the FPGA pins, including constraints
--   - ADC streams
--
--The ports of this top-level entity correspond to physical pins on the FPGA on that board. 
-- The location of these pins are defined in the constraint file.
entity sifpga_crs_chfpga_wrapper is
	generic (

	 		-- NOTE: All generics values must be literals if the module is to be imported in a block diagram
			PLATFORM_ID: integer                         := 5; -- =CONFIG_PLATFORM_ID = PLATFORM_ID_CRS. 
															   -- Identifies the type of platform on which the firmware is running. 
															   -- Has to be an integer (not a constant name) for the IP integrator 

			-- Clocking config

			SYSTEM_CLOCK_SOURCE: string                  := "SYSCLK_BUFG"; -- System reference clock surce: "SYSCLK": 200 MHz unbuffered differential clock from sysclk_p/n, "SYSCLK_BUFG": 200 MHz BUFG-Buffered clock from sysclk_bufg, "SFP_REFCLK": 125 MHz clock from the GTX reference clock
			SYSTEM_CLOCK_FREQ: integer                   := 250; -- System reference clock frequency, in MHz *** Is an integer because IP packager does not support real. ***
			CHAN_CLK_SOURCE: string                      := "ADC"; -- Channelizer clock comes directly from the ADC
			CT_CLK_SOURCE: string                        := "ADC_CLK"; -- corner-turn clock source

			-- Buck synchronization

			BUCK_SYNC_ENABLE: boolean                    := False; -- default state of the buck sync enable at startup
			BUCK_CLK_DIVIDE_FACTOR: integer              := 12; -- Buck frequency is 200MHz/16/BUCK_CLK_DIVIDE_FACTOR, 12=> 1.0416 MHz, 17 => 0.73529 MHz, 24=>0.5208333 MHz

			PHY_TYPE: string                             := "NONE"; -- "GMII" or "SGMII"
			SGMII_CLOCK_SOURCE: string                   := "REFCLK"; -- Selects the 125MHz clock source for the SGMII interface; "CLK125": uses the 125 MHz clock (clk125) from the main MMCM, "REFCLK": uses the GTX Reference clock (gtrefclk)

			-- ADC config
			--IMPLEMENT_ADCDAQ: boolean                    := FALSE; -- use ADC data directly from adc_axis_* ports.
			ADC_TYPE: string                             := "AXIS"; -- ADC data is provided through the axis_adc port
			NUMBER_OF_ADCS: integer                      := 8; -- Number of ADC inputs

			NUMBER_OF_ADC_BOARDS: integer                := 0; -- No REFCLK module

			-- Channelizer config
			NUMBER_OF_CHANNELIZERS:integer               := 8;  --(Typ. =16)  (0-NUMBER_OF_ADCS) Number of channelizer blocks to be implemented
            CAPTURE_TYPE: string                         := "URAM";
			-- Corner-turn engine config
			CROSSBAR1_TYPE: string                       := "URAM"; -- "BRAM" or "URAM"
			NUMBER_OF_CROSSBAR_INPUTS: integer           := 8; -- (Typ. =16)(0-NUMBER_OF_CHANNELIZERS): Number of channelizers output that are being aligned, filtered and repacked for the corrleator or GPU links
			NUMBER_OF_CROSSBAR1_OUTPUTS: integer         := 8; -- (Typ. =16): Number of output lanes of CROSSBAR1. Should be 8 for URAM-based crossbar1.
			NUMBER_OF_CORRELATORS: integer               := 0; -- Number of correlators. Normally NUMBER_OF_CROSSBAR_OUTPUTS. Correlator not implemented if zero.
			NUMBER_OF_BP_PCB_SHUFFLE_LANES: integer      := 0;
			NUMBER_OF_BP_QSFP_SHUFFLE_LANES: integer     := 0;
			NUMBER_OF_BP_SHUFFLE_LINKS: integer          := 0; -- Number of GTXes for both the backplane PCB and QSFP shuffle links. Usually matches the number of 1st crossbar output lanes.
			NUMBER_OF_BP_SHUFFLE_REFCLKS: integer        := 0;

			-- Real-time data offload link config
			IMPLEMENT_100G_ETHERNET: boolean             := TRUE; -- If TRUE, a 100G UDP/IP/Ethernet data transmitter is implemented

			NUMBER_OF_GPU_LINKS: integer                 := 0; -- (0- NUMBER_OF_REORDER_OUTPUTS) Number of 10Gb Ethernet links to connecto to the GPUs
			NUMBER_OF_GPU_REFCLKS: integer               := 1; -- Number of Reference clocks provided for the 10GE links to the GPU
			--ANT_CLK_SOURCE: integer := 0; -- Indicate which ADC is the source of the antenna processing clock. Must be one that has ADC_INSTANTIATE_PLL=TRUE so we have a BUFG that can clock the logic across the chip

			--GPU_CHANNEL_QUAD: IntegerArray := GLOBAL_GPU_CHANNEL_QUAD; -- Channels 0-3 use QUAD0, Channels 4-7 use QUAD1
			--GPU_QUAD_REFCLK: IntegerArray := GLOBAL_GPU_QUAD_REFCLK; -- Both QUAD0 and QUAD1 use refclk(0)

			-- Peripheral config

			BLINKER_PRESENT: boolean                     := TRUE; -- Indicates if the LED flasher is to be implemented by setting the DUMMY flag of the BLINKER module
			NUMBER_OF_I2C_PORTS: integer                 := 0;
			NUMBER_OF_SPI_PORTS: integer                 := 0; -- One port for each FMC


			SIM: boolean := FALSE-- Indicates this is running as a simulation. Used to accelerate simulations

	);
    PORT (
			------------------------------------
			-- SYSTEM
			------------------------------------

			-- Reset line
			cpu_reset_n: in std_logic; -- Hardware reset generated by the board


			-- System clocks
			clk200_bufg: in std_logic;

			-- Buffered 10 MHz clock, provided by the RF PLL output 0 (SYSREF_FPGA). The PLL needs to be software configured to this frequency.
			clk10_bufg: in std_logic;


			-- Buck Sync signals
			buck_sync_5v0: out std_logic;
			buck_sync_0v85: out std_logic;
			buck_sync_3v3: out std_logic;
			buck_sync_2v5: out std_logic;
			buck_sync_1v8: out std_logic;
			buck_sync_1v2a: out std_logic;
			buck_sync_1v2b: out std_logic;
			buck_sync_1v4: out std_logic;
			buck_sync_bp: out std_logic;


			------------------------------------
			-- ADCs
			------------------------------------
			-- ADC data is provided in TDATA 8 samples at a time as 8x 16-bit words.
			-- Samples are MSB-aligned in the word.
			-- The first sample in the group in in bits 15:0.
			-- clock must be RF Sampling clock / 8 (e.g 1600 MSPS / 8 = 200 MHz, or 3000 MSPS/8=325 MHz)

			-- ADC0 signals
			adc0_axis_tdata : in  std_logic_vector (127 downto 0);
			adc0_axis_tvalid : in  std_logic;
			adc0_axis_tready : out  std_logic;
			adc0_axis_clk : in  std_logic;
			-- ADC1 signals
			adc1_axis_tdata : in  std_logic_vector (127 downto 0);
			adc1_axis_tvalid : in  std_logic;
			adc1_axis_tready : out  std_logic;
			adc1_axis_clk : in  std_logic; -- data clock
			-- ADC2 signals
			adc2_axis_tdata : in  std_logic_vector (127 downto 0);
			adc2_axis_tvalid : in  std_logic;
			adc2_axis_tready : out  std_logic;
			adc2_axis_clk : in  std_logic; -- data clock
			-- ADC3 signals
			adc3_axis_tdata : in  std_logic_vector (127 downto 0);
			adc3_axis_tvalid : in  std_logic;
			adc3_axis_tready : out  std_logic;
			adc3_axis_clk : in  std_logic; -- data clock
			-- ADC4 signals
			adc4_axis_tdata : in  std_logic_vector (127 downto 0);
			adc4_axis_tvalid : in  std_logic;
			adc4_axis_tready : out  std_logic;
			adc4_axis_clk : in  std_logic; -- data clock
			-- ADC5 signals
			adc5_axis_tdata : in  std_logic_vector (127 downto 0);
			adc5_axis_tvalid : in  std_logic;
			adc5_axis_tready : out  std_logic;
			adc5_axis_clk : in  std_logic; -- data clock
			-- ADC6 signals
			adc6_axis_tdata : in  std_logic_vector (127 downto 0);
			adc6_axis_tvalid : in  std_logic;
			adc6_axis_tready : out  std_logic;
			adc6_axis_clk : in  std_logic; -- data clock
			-- ADC7 signals
			adc7_axis_tdata : in  std_logic_vector (127 downto 0);
			adc7_axis_tvalid : in  std_logic;
			adc7_axis_tready : out  std_logic;
			adc7_axis_clk : in  std_logic; -- data clock
			-- ADC tile output clocks.
			-- These are divided version of the RF sampling clocks.
			-- They are used for monitoring only, as they are not guaranteed to be present until initialized.
			adc0_clkout : in  std_logic; -- ADC 0 and 1.
			adc1_clkout : in  std_logic; -- ADC 2 and 3
			adc2_clkout : in  std_logic; -- ADC 4 and 5
			adc3_clkout : in  std_logic; -- ADC 6 and 7


			--==== 100G Ethernet QSFP28 interface

			qsfp_txp: out std_logic_vector(0 to 3);
			qsfp_txn: out std_logic_vector(0 to 3);
			--cge_rx_p: in std_logic_vector(0 to 3) := (others => '0');
			--cge_rx_n: in std_logic_vector(0 to 3):= (others => '1');
			-- Gigabit transceiver refrenece clocks (typically 156.25 MHz)
			clk156_p: in std_logic := '0';
			clk156_n: in std_logic := '1';

			--=== LEDs

			led7b: out std_logic_vector(7 downto 0); -- bits 7:0: dp, g, f, e, d, c, b, a

			--==== Debug interface
			debug_out: out std_logic_vector(31 downto 0);
			smp_out: out std_logic_vector(0 to 3);

			--==== BSB control interface

			-- Command input stream
			s_axis_bsb_tdata: in std_logic_vector(7 downto 0) := (others => '0');
			s_axis_bsb_tvalid: in std_logic := '0';
			s_axis_bsb_tlast: in std_logic := '0';
			s_axis_bsb_tready: out std_logic;

			-- Reply output stream
			m_axis_bsb_tdata: out std_logic_vector(7 downto 0);
			m_axis_bsb_tvalid: out std_logic;
			m_axis_bsb_tlast: out std_logic;
			m_axis_bsb_tready: in std_logic := '1';

			axis_bsb_clk : in  std_logic := '0'; -- 125 MHz clock
			axis_bsb_aresetn : in  std_logic := '1'; -- synchronous to bsb_axis_clk

			-- Data capture stream
			m_axis_cap_tdata: out std_logic_vector(7 downto 0);
			m_axis_cap_tvalid: out std_logic;
			m_axis_cap_tlast: out std_logic;
			m_axis_cap_tready: in std_logic := '1';
			axis_cap_clk: in std_logic

		);
end entity sifpga_crs_chfpga_wrapper;

---------- chFPGA implementation ------
-- Implements the chFPGA CHIME PoC Data acquisition/channelizer/corrrlator for the KC705 evaluation board (equipped with a Kintex 7 7K355 FPGA).
-- This simply instantiate the generic chFPGA code with the appropriate generics for that hardware platform.
--
architecture impl of sifpga_crs_chfpga_wrapper is
	-- SIGNALS

	attribute IOB: string;
	attribute DONT_TOUCH: string;
	ATTRIBUTE X_INTERFACE_INFO : STRING;
	ATTRIBUTE X_INTERFACE_PARAMETER : STRING;

	ATTRIBUTE X_INTERFACE_PARAMETER of clk200_bufg: SIGNAL is "FREQ_HZ 200000000";
	ATTRIBUTE X_INTERFACE_PARAMETER of clk10_bufg: SIGNAL is "FREQ_HZ 10000000";



	-- Vectors representing the ADC inputs.
	-- Length is hard coded to the fixed number of inputs provided in the top level port.
	-- We will pass only the first NUMBER_OF_ADCS to chFPGA.
	signal adc_axis_tdata: slv128_array(0 to 7);
	signal adc_axis_tvalid: std_logic_vector(0 to 7);
	signal adc_axis_clk: std_logic_vector(0 to 7);
	signal adc_clkout: std_logic_vector(0 to 7);

	signal cpu_reset: std_logic;
	--signal clk10_nobuf, clk10: std_logic;
	signal buck_sync: std_logic_vector(0 to 15);
	signal gpio_led: std_logic_vector(7 downto 0);

attribute DONT_TOUCH of chfpga0: label is "true";
begin

	cpu_reset <= not cpu_reset_n; -- Reset is active LOW on the ICEBoard


	buck_sync_5v0 <= buck_sync(0);
	buck_sync_0v85 <= buck_sync(1);
	buck_sync_3v3 <= buck_sync(2);
	buck_sync_2v5 <= buck_sync(3);
	buck_sync_1v8 <= buck_sync(4);
	buck_sync_1v2a <= buck_sync(5);
	buck_sync_1v2b <= buck_sync(6);
	buck_sync_1v4 <= buck_sync(7);
	buck_sync_bp <= buck_sync(8);


	led7b(5 downto 0) <= gpio_led(6 downto 1); -- a-f segments (forming a circle)
	led7b(6) <= '0'; -- central g segment
	led7b(7) <= '0'; -- decimal point

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

			BUCK_SYNC_ENABLE => BUCK_SYNC_ENABLE,
			BUCK_CLK_DIVIDE_FACTOR => BUCK_CLK_DIVIDE_FACTOR,

			PHY_TYPE                        => PHY_TYPE,
			SGMII_CLOCK_SOURCE              => SGMII_CLOCK_SOURCE,
			ADC_TYPE                        => ADC_TYPE,
			NUMBER_OF_ADCS                  => NUMBER_OF_ADCS,
			CAPTURE_TYPE                    => CAPTURE_TYPE,
			NUMBER_OF_CHANNELIZERS          => NUMBER_OF_CHANNELIZERS,
			NUMBER_OF_CORRELATORS           => NUMBER_OF_CORRELATORS,
			NUMBER_OF_CROSSBAR_INPUTS       => NUMBER_OF_CROSSBAR_INPUTS,
			NUMBER_OF_CROSSBAR1_OUTPUTS      => NUMBER_OF_CROSSBAR1_OUTPUTS,
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
			--gpio_led     => gpio_led,
			--gpio_button0 => '0', -- No pushbutton on the ICEBoard
			--gpio_dip_sw  => (others=>'0'), -- Was used on ML605 Virtex 6 eval board

			-- Clocks
			clk10 => clk10_bufg, -- Buffered (BUFG) 10 MHz differential reference clock
			sysclk_bufg => clk200_bufg,
			-- Buck sync
			buck_sync => buck_sync,

			-- ADC inputs
			adc_axis_tdata => adc_axis_tdata(0 to NUMBER_OF_ADCS-1),
			adc_axis_tvalid => adc_axis_tvalid(0 to NUMBER_OF_ADCS-1),
			adc_axis_clk => adc_axis_clk(0 to NUMBER_OF_ADCS-1),
			adc_clkout => adc_clkout(0 to NUMBER_OF_ADCS-1),

			-- LEDs

			gpio_led => gpio_led,

			-- 100GE interface
			cge_tx_p => qsfp_txp,
			cge_tx_n => qsfp_txn,
			cge_refclk_p => clk156_p,
			cge_refclk_n => clk156_n,

			-- debug bus
			debug_out => debug_out,
			sma_out => smp_out,

			-- Command input stream
			s_axis_bsb_tdata => s_axis_bsb_tdata,
			s_axis_bsb_tvalid => s_axis_bsb_tvalid,
			s_axis_bsb_tlast => s_axis_bsb_tlast,
			s_axis_bsb_tready => s_axis_bsb_tready,

			-- Reply output stream
			m_axis_bsb_tdata => m_axis_bsb_tdata,
			m_axis_bsb_tvalid => m_axis_bsb_tvalid,
			m_axis_bsb_tlast => m_axis_bsb_tlast,
			m_axis_bsb_tready => m_axis_bsb_tready,

			axis_bsb_clk => axis_bsb_clk,
			axis_bsb_rst => not axis_bsb_aresetn,

			-- Data capture interface
			m_axis_cap_tdata => m_axis_cap_tdata,
			m_axis_cap_tvalid => m_axis_cap_tvalid,
			m_axis_cap_tlast => m_axis_cap_tlast,
			m_axis_cap_tready => m_axis_cap_tready,

			axis_cap_clk => axis_cap_clk

			);

end architecture impl;

