--------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:   17:23:04 11/17/2010
-- Design Name:
-- Module Name:   C:/Xilinx/work/CHIME/SP605_test2/ADCDAQ/ADC_IOSERDES_testbench.vhd
-- Project Name:  ADCDAQ
-- Target Device:
-- Tool versions:
-- Description:
--
-- VHDL Test Bench Created by ISE for module: ADC_IOSERDES
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes:
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

library work;
USE work.chFPGA_Package.all;
use work.tb_package.all;

ENTITY chFPGA_testbench IS
	 GENERIC (
		PLATFORM_ID: INTEGER:= PLATFORM_ID_MGK7MB; -- identifies the type of platform on which the firmware is running. 0=ML605, 1=KC705, 2= ICEBoard

		BLINKER_PRESENT: BOOLEAN :=TRUE; -- Indicates if the LED flasher is to be implemented by setting the DUMMY flag of the BLINKER module

		-- System configuration
		NUMBER_OF_ADCS: INTEGER :=16; --
		NUMBER_OF_CHANNELIZERS: INTEGER :=16; -- Number of antenna processing blocks to be implemented
		NUMBER_OF_CROSSBAR_INPUTS : integer := 16;
		NUMBER_OF_CROSSBAR_OUTPUTS: integer := 0;
		NUMBER_OF_CORRELATORS: INTEGER :=0; -- Number of correlator blocks (CH_DIST+CORR+ACC) to be implemented if IMPLEMENT_CORR=TRUE
		NUMBER_OF_GPU_LINKS: integer := 0*GLOBAL_NUMBER_OF_GPU_LINKS;
		NUMBER_OF_GPU_REFCLKS: integer := 1; --0*GLOBAL_NUMBER_OF_GPU_REFCLKS;
		NUMBER_OF_BP_SHUFFLE_LINKS: integer := 3;
		NUMBER_OF_BP_SHUFFLE_REFCLKS: integer := 2;
		NUMBER_OF_I2C_PORTS: integer := 1;
		NUMBER_OF_SPI_PORTS: integer :=1;
		NUMBER_OF_ADC_BOARDS: integer := 1;
		ADC_TO_ADC_BOARD_MAP: integer_array(0 to NUMBER_OF_ADCS_MAX-1):=(0 to 15 => 0);
		SYSTEM_CLOCK_SOURCE: string := "SFP_REFCLK"; --"SYSCLK": the 200 MHz clock will be taken from sysclk_p/n (CC pins) or "SFP_REFCLK": the system clock is 125 MHz from the GTX reference clock

		-- Ethernet MAC Configuration (BSB interface type)
		BSB_INTERFACE: bsb_interface_enum := UDP_GMII; -- UDP_GMII or UDP_SGMII
		CAP_INTERFACE: cap_interface_enum := BSB;
		SGMII_CLOCK_SOURCE: string :="REFCLK"; -- Selects the 125MHz clock source for the SGMII interface; "CLK125": uses the 125 MHz clock (clk125) from the main MMCM, "REFCLK": uses the GTX Reference clock (gtrefclk)

		-- IMPLEMENT_ANT: bool_array(0 to NUMBER_OF_CHANNELIZERS_MAX-1):=(0 to 7 => TRUE, others=>FALSE); -- Selects for which antenna a processing pipeline is implemented
		-- IMPLEMENT_FFT: bool_array(0 to NUMBER_OF_CHANNELIZERS_MAX-1):=(others=>FALSE); -- Selects if the FFT block is implemented for each antenna (otherwise the timestream go through directly)
		-- IMPLEMENT_CORR: bool_array(0 to NUMBER_OF_CORRELATORS_MAX-1):=(others=> TRUE);


		-- ADCDAQ Configuration
		ADC_IS_DIFFERENTIAL: bool_array_array := (0 to NUMBER_OF_ADCS_MAX-1 => (0 to 8 => TRUE)); -- All inputs are differential by default unless specified otherwise by the top level
		ADC_INSTANTIATE_PLL: bool_array(0 to NUMBER_OF_ADCS_MAX-1):=( others=>FALSE);
		ADC_USE_EXT_DATA_CLK: bool_array(0 to NUMBER_OF_ADCS_MAX-1):=(others=>FALSE);
		ADC_CLOCKING_REGION_MAP: integer_array_array(0 to NUMBER_OF_ADCS_MAX-1) := (0 to NUMBER_OF_ADCS_MAX-1 => (0 to 8 => -1));
		ADC_PROVIDE_BUFFERED_DIVCLK: bool_array(0 to NUMBER_OF_ADCS_MAX-1) := (0=>TRUE, others=>FALSE);
		CHAN_CLK_SOURCE_LANE: integer :=0; -- Indicate which ADC is the source of the antenna processing clock. Must be one that has ADC_INSTANTIATE_PLL=TRUE so we have a BUFG that can clock the logic across the chip

		-- Simulation parameters
		ADC_SAMPLING_FREQUENCY: REAL:= 800.0E6; -- MHz. Must be a multiple of 10 MHz. Must be exactly 800 MHz if CLK200 is used for the antenna processor clock.
		IMPLEMENT_ADC_BOARD: BOOLEAN:= TRUE; -- If used, make sure to implement ANT(1) to provide the system clock
		SIM: BOOLEAN := TRUE
		);


END chFPGA_testbench;


ARCHITECTURE behavior OF chFPGA_testbench IS

   -- Clock period definitions
   constant CLK125_period : time := 8 ns;
   constant PHY_RXCLK_period : time := 8 ns;
   constant PHY_TXCLK_period : time := 8 ns;
   constant SYSCLK_period : time := 5 ns;
   constant SFPCLK_period : time := 8 ns;
   constant MGT_REFCLK_period : time := 3.2 ns;
   constant FMC_REFCLK_period : time := 100 ns;
   constant XGECLK_period: time := 66*98 ps; -- this is normally 6.4 ns (156.25 MHz) but for the simulation to work with a resolution of 1 ps we need an exact multiple of a picosecond




	constant SYSTEM_PORT: integer :=0;
	constant ANT0_PORT: integer := SYSTEM_PORT + 1;
	-- constant ANT1_PORT: integer := ANT0_PORT + 1;
	-- constant ANT2_PORT: integer :=3;
	-- constant ANT3_PORT: integer :=4;
	-- constant ANT4_PORT: integer :=5;
	-- constant ANT5_PORT: integer :=6;
	-- constant MGT_PORT: integer :=9;



	constant CORR0_PORT: integer :=1 + NUMBER_OF_CHANNELIZERS;

	constant CHDIST_MODULE: integer :=0;
	constant ACC_MODULE: integer :=2;


	-- SYSTEM Port modules
	constant SYSTEM_BASE_ADDR        : integer := 16#00000#;
	constant CHAN_BASE_ADDR          : integer := 16#10000#; -- # Channelizer top address
	constant CROSSBAR_BASE_ADDR      : integer := 16#20000#; -- # CROSSBAR top address
	constant GPU_LINK_BASE_ADDR      : integer := 16#30000#; -- # GPU Link top address
	constant CORR_BASE_ADDR          : integer := 16#40000#; -- # Correlator ports are determined dynamically based on the info from the firmware

	constant SYSTEM_ADDR_INCREMENT   : integer := 16#01000#;
	constant CHAN_ADDR_INCREMENT     : integer := 16#01000#; -- # Address increment between each channelizer address spaces
	constant CROSSBAR_ADDR_INCREMENT : integer := 16#00800#; --
	constant GPU_LINK_ADDR_INCREMENT : integer := 16#00800#; -- # Address increment between each subsystem of the GPU links
	constant CORR_ADDR_INCREMENT     : integer := 16#01000#; -- # Address increment between each correlator



	constant SYSTEM_GPIO_BASE_ADDR    : integer :=SYSTEM_BASE_ADDR + 0 * SYSTEM_ADDR_INCREMENT;
	constant SYSTEM_SYSMON_BASE_ADDR  : integer :=SYSTEM_BASE_ADDR + 1 * SYSTEM_ADDR_INCREMENT;
	constant SYSTEM_FREQCTR_BASE_ADDR : integer :=SYSTEM_BASE_ADDR + 2 * SYSTEM_ADDR_INCREMENT;
	constant SYSTEM_SPI_BASE_ADDR     : integer :=SYSTEM_BASE_ADDR + 3 * SYSTEM_ADDR_INCREMENT;
	constant SYSTEM_REFCLK_BASE_ADDR  : integer :=SYSTEM_BASE_ADDR + 4 * SYSTEM_ADDR_INCREMENT;
	constant SYSTEM_I2C_BASE_ADDR     : integer :=SYSTEM_BASE_ADDR + 5 * SYSTEM_ADDR_INCREMENT;

	constant CROSSBAR0_CHDIST_BASE_ADDR: integer := CROSSBAR_BASE_ADDR + 1 * CROSSBAR_ADDR_INCREMENT;
	constant CHAN0_BASE_ADDR : integer := CHAN_BASE_ADDR + 0 * CHAN_ADDR_INCREMENT;
	constant CHAN1_BASE_ADDR : integer := CHAN_BASE_ADDR + 1 * CHAN_ADDR_INCREMENT;

	constant CHAN_SUBSYSTEM_INCREMENT : integer := 16#00200#;
	constant ADCDAQ_OFFSET  : integer := 0 * CHAN_SUBSYSTEM_INCREMENT;
	constant SRCSEL_OFFSET  : integer := 1 * CHAN_SUBSYSTEM_INCREMENT;
	constant FFT_OFFSET     : integer := 2 * CHAN_SUBSYSTEM_INCREMENT;
	constant SCALER_OFFSET  : integer := 3 * CHAN_SUBSYSTEM_INCREMENT;
	constant PROBER_OFFSET  : integer := 4 * CHAN_SUBSYSTEM_INCREMENT;
	constant FUNCGEN_OFFSET : integer := 5 * CHAN_SUBSYSTEM_INCREMENT; -- Address of the function generator module
	constant INJECT_OFFSET  : integer := 6 * CHAN_SUBSYSTEM_INCREMENT; -- Address of the data injection module


	--Inputs
	signal CPU_RESET : std_logic := '0';
	signal GPIO_BUTTON0 : std_logic := '0';
	signal SYSCLK_P : std_logic := '0';
	signal SYSCLK_N : std_logic := '0';


	-- SFP Signals
	signal sfp_clk_p : std_logic := '0';
	signal sfp_clk_n : std_logic := '0';
	signal sfp_rx_p  : std_logic := '0';
	signal sfp_rx_n  : std_logic := '0';
	signal sfp_los   : std_logic;
	signal sfp_tx_p  : std_logic;
	signal sfp_tx_n  : std_logic;

	signal xge_tx_p : std_logic_vector(0 to NUMBER_OF_GPU_LINKS-1);
	signal xge_tx_n : std_logic_vector(0 to NUMBER_OF_GPU_LINKS-1);
	signal xge_rx_p : std_logic_vector(0 to NUMBER_OF_GPU_LINKS-1);
	signal xge_rx_n : std_logic_vector(0 to NUMBER_OF_GPU_LINKS-1);
	signal xge_refclk_p : std_logic;
	signal xge_refclk_n : std_logic;
	signal xge_refclk_p_vect: std_logic_vector(0 to NUMBER_OF_GPU_REFCLKS-1);
	signal xge_refclk_n_vect: std_logic_vector(0 to NUMBER_OF_GPU_REFCLKS-1);

	signal ADC0_AHDP, ADC0_AHDN, ADC0_BHDP_ALDP, ADC0_BHDN_ALDN: std_logic_vector(7 downto 0) := (others => '0');
	signal ADC0_CHDP, ADC0_CHDN, ADC0_DHDP_CLDP, ADC0_DHDN_CLDN: std_logic_vector(7 downto 0) := (others => '0');
	signal ADC1_AHDP, ADC1_AHDN, ADC1_BHDP_ALDP, ADC1_BHDN_ALDN: std_logic_vector(7 downto 0) := (others => '0');
	signal ADC1_CHDP, ADC1_CHDN, ADC1_DHDP_CLDP, ADC1_DHDN_CLDN: std_logic_vector(7 downto 0) := (others => '0');

	signal ADC0_ADRP, ADC0_BDRP, ADC0_CDRP, ADC0_DDRP, ADC1_ADRP, ADC1_BDRP, ADC1_CDRP, ADC1_DDRP : std_logic := '0';
	signal ADC0_ADRN, ADC0_BDRN, ADC0_CDRN, ADC0_DDRN, ADC1_ADRN, ADC1_BDRN, ADC1_CDRN, ADC1_DDRN : std_logic := '1';

	signal adc_data_p: slv8_array(0 to 15);
	signal adc_data_n: slv8_array(0 to 15);
	signal adc_clk_p: std_logic_vector(0 to 15);
	signal adc_clk_n: std_logic_vector(0 to 15);


	signal ADC_SYNC_P : STD_LOGIC :='0';
	signal ADC_SYNC_N : STD_LOGIC :='1';

	signal USER_SMA_GPIO_P : STD_LOGIC ;
	signal USER_SMA_GPIO_N : STD_LOGIC ;
	signal NOT_USER_SMA_GPIO_P : STD_LOGIC ;


 --Outputs
   signal GPIO_LED : std_logic_vector(7 downto 0);

	-- PHY signals
   signal PHY_RXCLK : std_logic := '0';
   signal PHY_RXCTRL_RXDV : std_logic := '0';
   signal PHY_RXD : std_logic_vector(7 downto 0) := (others => '0');
   signal PHY_TXCLK : std_logic := '0';
   signal PHY_TXER : std_logic;
   signal PHY_RESET_L : std_logic;
   signal PHY_TXC_GTXCLK : std_logic;
   signal PHY_TXCTL_TXEN : std_logic;
   signal PHY_TXD : std_logic_vector(7 downto 0);

-- FMC SPI
	signal SPI_MOSI: STD_LOGIC;
	signal SPI_MISO: STD_LOGIC;
	signal SPI_SCK: STD_LOGIC;
	signal SPI_ADDR: STD_LOGIC_VECTOR(2 downto 0);

-- FMC I2C signals
	signal FMC_I2C_SCK: STD_LOGIC:='H'; -- weak pullup
	signal FMC_I2C_SDA: STD_LOGIC:='H'; -- weak pullup
	signal SDA, SCK, SLAVE_SDA: STD_LOGIC:='H'; -- weak pullup
	signal bit_ctr: unsigned(3 downto 0):=(others=>'0');

-- FMC reference clock
	signal FMC_REFCLK_M2C_P: STD_LOGIC;
	signal FMC_REFCLK_M2C_N: STD_LOGIC;
	signal FMC_REFCLK_C2M_P: STD_LOGIC;
	signal FMC_REFCLK_C2M_N: STD_LOGIC;



	-- MGT

			-- MGT Reference Clock 0_112

	signal MGT_REFCLK_P: STD_LOGIC;
	signal MGT_REFCLK_N: STD_LOGIC;

			-- MGT Transceiver 3_112 (SATA4 - Master)
	signal MGT4_D_C2M_P:  STD_LOGIC;
	signal MGT4_D_C2M_N:  STD_LOGIC;
	signal MGT4_D_M2C_P:  STD_LOGIC;
	signal MGT4_D_M2C_N:  STD_LOGIC;

			-- MGT Transceiver 0_112 (SATA7 - Slave)
	signal MGT7_D_C2M_P:  STD_LOGIC;
	signal MGT7_D_C2M_N:  STD_LOGIC;
	signal MGT7_D_M2C_P: STD_LOGIC;
	signal MGT7_D_M2C_N: STD_LOGIC;

	signal MGT6_D_C2M_P:  STD_LOGIC;
	signal MGT6_D_C2M_N:  STD_LOGIC;
	signal MGT6_D_M2C_P: STD_LOGIC;
	signal MGT6_D_M2C_N: STD_LOGIC;
	signal MGT5_D_C2M_P:  STD_LOGIC;
	signal MGT5_D_C2M_N:  STD_LOGIC;
	signal MGT5_D_M2C_P: STD_LOGIC;
	signal MGT5_D_M2C_N: STD_LOGIC;

	signal bp_shuffle_rxtx_p: std_logic_vector(0 to NUMBER_OF_BP_SHUFFLE_LINKS-1);
	signal bp_shuffle_rxtx_n: std_logic_vector(0 to NUMBER_OF_BP_SHUFFLE_LINKS-1);
	signal bp_shuffle_refclk_p_vect: std_logic_vector(0 to NUMBER_OF_BP_SHUFFLE_REFCLKS-1);
	signal bp_shuffle_refclk_n_vect: std_logic_vector(0 to NUMBER_OF_BP_SHUFFLE_REFCLKS-1);

 -- UDP/Ethernet interfaces

signal tx_data   :   std_logic_vector(7 downto 0) := (others=>'0');
signal tx_last  :   std_logic:='0';
signal tx_valid  :   std_logic:='0';
signal tx_ready  :   std_logic:='1';

signal rx_tdata  :   std_logic_vector(7 downto 0);
signal rx_tvalid :   std_logic;
signal rx_tlast  :   std_logic;

signal dummy  :   std_logic;
signal clk125 :   std_logic;

TYPE TX_STATE_TYPE IS (TX_STATE_IDLE, TX_STATE_CMD, TX_STATE_ADDR1, TX_STATE_ADDR2, TX_STATE_DATA, TX_STATE_STOP); -- States of the TX state machine
signal TX_STATE: TX_STATE_TYPE:=TX_STATE_IDLE; -- Initialization needed

signal TX_CTR: UNSIGNED(10 downto 0):=(others=>'0');
signal TX_TRIG:   STD_LOGIC:='0';

--   signal SUM_OUT : std_logic_vector(63 downto 0);


BEGIN

-- Static connection

-- MGT Loopbacks
			-- SATA 4
--			MGT4_D_M2C_P<=MGT4_D_C2M_P;
--			MGT4_D_M2C_N<=MGT4_D_C2M_N;

			-- MGT Transceiver 0_112 (SATA7 - Slave)
--			MGT7_D_M2C_P<=MGT7_D_C2M_P;
--			MGT7_D_M2C_N<=MGT7_D_C2M_N;

-- Connection between two MGTs
			MGT4_D_M2C_P<=MGT7_D_C2M_P;
			MGT4_D_M2C_N<=MGT7_D_C2M_N;

			-- MGT Transceiver 0_112 (SATA7 - Slave)
			MGT7_D_M2C_P<=MGT6_D_C2M_P;
			MGT7_D_M2C_N<=MGT6_D_C2M_N;

			MGT6_D_M2C_P<=MGT5_D_C2M_P;
			MGT6_D_M2C_N<=MGT5_D_C2M_N;

			MGT5_D_M2C_P<=MGT4_D_C2M_P;
			MGT5_D_M2C_N<=MGT4_D_C2M_N;

NOT_USER_SMA_GPIO_P<= not USER_SMA_GPIO_P;


adc_data_p <= (adc0_ahdp, adc0_bhdp_aldp, adc0_chdp, adc0_dhdp_cldp, adc1_ahdp, adc1_bhdp_aldp, adc1_chdp, adc1_dhdp_cldp,     adc0_ahdp, adc0_bhdp_aldp, adc0_chdp, adc0_dhdp_cldp, adc1_ahdp, adc1_bhdp_aldp, adc1_chdp, adc1_dhdp_cldp);
adc_data_n <= (adc0_ahdn, adc0_bhdn_aldn, adc0_chdn, adc0_dhdn_cldn, adc1_ahdn, adc1_bhdn_aldn, adc1_chdn, adc1_dhdn_cldn,     adc0_ahdn, adc0_bhdn_aldn, adc0_chdn, adc0_dhdn_cldn, adc1_ahdn, adc1_bhdn_aldn, adc1_chdn, adc1_dhdn_cldn);
adc_clk_p <= (adc0_adrp, adc0_bdrp, adc0_cdrp, adc0_ddrp, adc1_adrp, adc1_bdrp, adc1_cdrp, adc1_ddrp,      adc0_adrp, adc0_bdrp, adc0_cdrp, adc0_ddrp, adc1_adrp, adc1_bdrp, adc1_cdrp, adc1_ddrp);
adc_clk_n <= (adc0_adrn, adc0_bdrn, adc0_cdrn, adc0_ddrn, adc1_adrn, adc1_bdrn, adc1_cdrn, adc1_ddrn,      adc0_adrn, adc0_bdrn, adc0_cdrn, adc0_ddrn, adc1_adrn, adc1_bdrn, adc1_cdrn, adc1_ddrn);
--	-- Instantiate the Unit Under Test (UUT)

xge_refclk_p_vect <= (others => xge_refclk_p);
xge_refclk_n_vect <= (others => xge_refclk_n);
bp_shuffle_refclk_p_vect <= (others => xge_refclk_p);
bp_shuffle_refclk_n_vect <= (others => xge_refclk_n);

CHFPGA0: entity work.chFPGA
	GENERIC MAP(
		PLATFORM_ID                   => PLATFORM_ID,
		BLINKER_PRESENT               => BLINKER_PRESENT,
		SYSTEM_CLOCK_SOURCE           => SYSTEM_CLOCK_SOURCE,
		BSB_INTERFACE                 => BSB_INTERFACE,
	CAP_INTERFACE                 => CAP_INTERFACE,
		SGMII_CLOCK_SOURCE            => SGMII_CLOCK_SOURCE,
		NUMBER_OF_ADCS                => NUMBER_OF_ADCS,
		NUMBER_OF_CHANNELIZERS        => NUMBER_OF_CHANNELIZERS,
		NUMBER_OF_CORRELATORS         => NUMBER_OF_CORRELATORS,
		NUMBER_OF_CROSSBAR_INPUTS     => NUMBER_OF_CROSSBAR_INPUTS,
		NUMBER_OF_CROSSBAR_OUTPUTS    => NUMBER_OF_CROSSBAR_OUTPUTS,
		NUMBER_OF_BP_SHUFFLE_LINKS    => NUMBER_OF_BP_SHUFFLE_LINKS,
		NUMBER_OF_BP_SHUFFLE_REFCLKS  => NUMBER_OF_BP_SHUFFLE_REFCLKS,
		NUMBER_OF_I2C_PORTS           => NUMBER_OF_I2C_PORTS,
		NUMBER_OF_SPI_PORTS           => NUMBER_OF_SPI_PORTS,
		NUMBER_OF_ADC_BOARDS          => NUMBER_OF_ADC_BOARDS,
		ADC_TO_ADC_BOARD_MAP          => ADC_TO_ADC_BOARD_MAP,
		BP_SHUFFLE_LANE_TO_QUAD_MAP   => (0 to 3=>0, 4 to 7=>1, 8 to 11=> 2, 12 to 14 => 3, 15 => 4), --  Indicates which quad is associated each channel. The QUAD number is an integer between 0 and N-1, where N is the total number of quads used.
		BP_SHUFFLE_QUAD_TO_REFCLK_MAP => (0|3 => 1, 1|2 => 0, 4 =>2), -- Indicates which refclk is associated with each QUAD (N integers from 0 to NUMBER_OF_REFCLK-1).
		-- IMPLEMENT_ANT              =>IMPLEMENT_ANT, -- Selects for which antenna a processing pipeline is implemented
		-- IMPLEMENT_FFT              =>IMPLEMENT_FFT, -- Selects if the FFT block is implemented for each antenna (otherwise the timestream go through directly)
		-- IMPLEMENT_CORR             =>IMPLEMENT_CORR,
		ADC_IS_DIFFERENTIAL           => ADC_IS_DIFFERENTIAL,
		ADC_INSTANTIATE_PLL           => ADC_INSTANTIATE_PLL,
		ADC_USE_EXT_DATA_CLK          => ADC_USE_EXT_DATA_CLK,
		ADC_CLOCKING_REGION_MAP       => ADC_CLOCKING_REGION_MAP,
		ADC_PROVIDE_BUFFERED_DIVCLK   => ADC_PROVIDE_BUFFERED_DIVCLK,
		CHAN_CLK_SOURCE_LANE                => CHAN_CLK_SOURCE_LANE,
		SIM                           => SIM
		)
	PORT MAP(
		-- System
		 cpu_reset => '0',
		 clk10 => FMC_REFCLK_M2C_P,
		 raw_clk10 => FMC_REFCLK_M2C_P,
		 gpio_button0 => gpio_button0,
		 gpio_led => gpio_led,
		 sysclk_p => '0',
		 sysclk_n => '1',
		 gpio_dip_sw => "0000",
		 arm_spi_sck => '0',
		 arm_spi_mosi => '0',
		 arm_spi_cs_n => '1',
		 arm_irq_in => '0',
		 flash_cs_in => '0',
		 gpio_rst_in => '0',
		 gpio_irq_in => '0',

		-- phy
		 phy_rxclk => phy_rxclk,
		 phy_txer => phy_txer,
		 phy_reset_l => phy_reset_l,
		 phy_rxctrl_rxdv => phy_rxctrl_rxdv,
		 phy_rxd => phy_rxd,
		 phy_txc_gtxclk => phy_txc_gtxclk,
		 phy_txctl_txen => phy_txctl_txen,
		 phy_txd => phy_txd,
		 phy_txclk => phy_txclk,

		-- sfp
		 --sfp_los => sfp_los,
		 sfp_clk_p => sfp_clk_p,
		 sfp_clk_n => sfp_clk_n,
		 sfp_tx_p => sfp_tx_p,
		 sfp_tx_n => sfp_tx_n,
		 sfp_rx_p => sfp_rx_p,
		 sfp_rx_n => sfp_rx_n,

		xge_tx_p => xge_tx_p,
		xge_tx_n => xge_tx_n,
		xge_rx_p => xge_tx_p, -- loopback tx into rx for testing
		xge_rx_n => xge_tx_n,
		xge_refclk_p => xge_refclk_p_vect,
		xge_refclk_n => xge_refclk_n_vect,
		-- fmc

		bp_shuffle_tx_p => bp_shuffle_rxtx_p,
		bp_shuffle_tx_n => bp_shuffle_rxtx_n,
		bp_shuffle_rx_p => bp_shuffle_rxtx_p, -- loopback tx into rx for testing
		bp_shuffle_rx_n => bp_shuffle_rxtx_n,

		bp_shuffle_refclk_p => bp_shuffle_refclk_p_vect,
		bp_shuffle_refclk_n => bp_shuffle_refclk_n_vect,

		adc_data_p => adc_data_p(0 to NUMBER_OF_ADCS-1),
		adc_data_n => adc_data_n(0 to NUMBER_OF_ADCS-1),
		adc_clk_p => adc_clk_p(0 to NUMBER_OF_ADCS-1),
		adc_clk_n => adc_clk_n(0 to NUMBER_OF_ADCS-1),

		adc_sync_p(0) => adc_sync_p,
		adc_sync_n(0) => adc_sync_n,

		-- USER_SMA_GPIO_P=>USER_SMA_GPIO_P, -- 10 MHz reference clock generated by FPGA
		-- USER_SMA_GPIO_N=>USER_SMA_GPIO_N,

		-- Fan
		FAN_PWM=> open,
		FAN_TACH=> '1',

		bp_slot_probe => (others=>'0'),
		bp_slot_sense => (others=>'0'),

		-- SPI
		spi_miso(0) => spi_miso,
		spi_mosi => spi_mosi,
		spi_addr => spi_addr,
		spi_sck => spi_sck,

		-- FMC I2C signals
		i2c_scl(0)=>FMC_I2C_SCK,
		i2c_sda(0)=>FMC_I2C_SDA,

		-- System Monitor


		-- FMC Reference clock
		REFCLK_M2C_P => (others=> FMC_REFCLK_M2C_N), -- inverted on purpose, like mezzanines
		REFCLK_M2C_N => (others=> FMC_REFCLK_M2C_P)

		-- refclk_m2c_p => USER_SMA_GPIO_P, -- use 10 MHz clock generated by FPGA
		-- refclk_m2c_n => NOT_USER_SMA_GPIO_P

--			------------------------------------
--			-- MGT interface
--			------------------------------------
--			-- MGT Reference Clock 0_112
--		MGT4_CLK_M2C_P=>MGT_REFCLK_P,
--		MGT4_CLK_M2C_N=>MGT_REFCLK_N,
--
--		-- MGT Transceiver 3_112 (SATA4 - Master)
--		MGT4_D_C2M_P=>MGT4_D_C2M_P,
--		MGT4_D_C2M_N=>MGT4_D_C2M_N,
--		MGT4_D_M2C_P=>MGT4_D_M2C_P,
--		MGT4_D_M2C_N=>MGT4_D_M2C_N,
--
--		-- MGT Transceiver 0_112 (SATA7 - Slave)
--		MGT7_D_C2M_P=>MGT7_D_C2M_P,
--		MGT7_D_C2M_N=>MGT7_D_C2M_N,
--		MGT7_D_M2C_P=>MGT7_D_M2C_P,
--		MGT7_D_M2C_N=>MGT7_D_M2C_N,
--
--		MGT6_D_C2M_P=>MGT6_D_C2M_P,
--		MGT6_D_C2M_N=>MGT6_D_C2M_N,
--		MGT6_D_M2C_P=>MGT6_D_M2C_P,
--		MGT6_D_M2C_N=>MGT6_D_M2C_N,
--
--		MGT5_D_C2M_P=>MGT5_D_C2M_P,
--		MGT5_D_C2M_N=>MGT5_D_C2M_N,
--		MGT5_D_M2C_P=>MGT5_D_M2C_P,
--		MGT5_D_M2C_N=>MGT5_D_M2C_N


		);

FMC_EMUL0: entity work.FMC_EMUL
		GENERIC MAP (
			PRESENT=>IMPLEMENT_ADC_BOARD,
			SAMPLING_FREQUENCY => ADC_SAMPLING_FREQUENCY
			)
		PORT MAP(
			ADC_RESET => CPU_RESET,
			ADC0_AHDP => ADC0_AHDP,
			ADC0_AHDN => ADC0_AHDN,
			ADC0_ADRP => ADC0_ADRP,
			ADC0_ADRN => ADC0_ADRN,
			ADC0_BHDP_ALDP => ADC0_BHDP_ALDP,
			ADC0_BHDN_ALDN => ADC0_BHDN_ALDN,
			ADC0_BDRP => ADC0_BDRP,
			ADC0_BDRN => ADC0_BDRN,
			ADC0_CHDP => ADC0_CHDP,
			ADC0_CHDN => ADC0_CHDN,
			ADC0_CDRP => ADC0_CDRP,
			ADC0_CDRN => ADC0_CDRN,
			ADC0_DHDP_CLDP => ADC0_DHDP_CLDP,
			ADC0_DHDN_CLDN => ADC0_DHDN_CLDN,
			ADC0_DDRP => ADC0_DDRP,
			ADC0_DDRN => ADC0_DDRN,

			ADC1_AHDP => ADC1_AHDP,
			ADC1_AHDN => ADC1_AHDN,
			ADC1_ADRP => ADC1_ADRP,
			ADC1_ADRN => ADC1_ADRN,
			ADC1_BHDP_ALDP => ADC1_BHDP_ALDP,
			ADC1_BHDN_ALDN => ADC1_BHDN_ALDN,
			ADC1_BDRP => ADC1_BDRP,
			ADC1_BDRN => ADC1_BDRN,
			ADC1_CHDP => ADC1_CHDP,
			ADC1_CHDN => ADC1_CHDN,
			ADC1_CDRP => ADC1_CDRP,
			ADC1_CDRN => ADC1_CDRN,
			ADC1_DHDP_CLDP => ADC1_DHDP_CLDP,
			ADC1_DHDN_CLDN => ADC1_DHDN_CLDN,
			ADC1_DDRP => ADC1_DDRP,
			ADC1_DDRN => ADC1_DDRN,

			ADC_SYNCP => ADC_SYNC_P,
			ADC_SYNCN => ADC_SYNC_N,

		-- SPI signals

		SPI_MISO => SPI_MISO,
		SPI_MOSI => SPI_MOSI,
		SPI_ADDR => SPI_ADDR,
		SPI_SCK => SPI_SCK,

		REFCLK_C2M_P=>FMC_REFCLK_C2M_P,
		REFCLK_C2M_N=>FMC_REFCLK_C2M_N,

		REFCLK_M2C_P=>FMC_REFCLK_M2C_P,
		REFCLK_M2C_N=>FMC_REFCLK_M2C_N
		);




--  Clock process definitions

  -- PHY_RXCLK_process :process
  -- This process is not needed. the  rx clk is provided by the udp_mac (a copy of CLK125)
  -- begin
		-- PHY_RXCLK <= '0';
		-- wait for PHY_RXCLK_period/2;
		-- PHY_RXCLK <= '1';
		-- wait for PHY_RXCLK_period/2;
  -- end process;


PHY_TXCLK_process :process
   begin
		PHY_TXCLK <= '0';
		wait for PHY_TXCLK_period/2;
		PHY_TXCLK <= '1';
		wait for PHY_TXCLK_period/2;
   end process;

SYSCLK_process :process
   begin
		SYSCLK_P <= '0';
		SYSCLK_N <= '1';
		wait for SYSCLK_period/2;
		SYSCLK_P <= '1';
		SYSCLK_N <= '0';
		wait for SYSCLK_period/2;
   end process;

SFPCLK_process :process
   begin
		sfp_clk_p <= '0';
		sfp_clk_n <= '1';
		wait for SFPCLK_period/2;
		sfp_clk_p <= '1';
		sfp_clk_n <= '0';
		wait for SFPCLK_period/2;
   end process;

xge_process :process
   begin
		xge_refclk_p <= '0';
		xge_refclk_n <= '1';
		wait for XGECLK_period/2;
		xge_refclk_p <= '1';
		xge_refclk_n <= '0';
		wait for XGECLK_period/2;
   end process;

CLK125_process :process
   begin
		CLK125 <= '0';
		wait for CLK125_period/2;
		CLK125 <= '1';
		wait for CLK125_period/2;
   end process;

FMC_REFCLK_process :process
   begin
		FMC_REFCLK_C2M_P <= '0';
		FMC_REFCLK_C2M_N <= '1';
		wait for FMC_REFCLK_period/2;
		FMC_REFCLK_C2M_P <= '1';
		FMC_REFCLK_C2M_N <= '0';
		wait for FMC_REFCLK_period/2;
   end process;

MGT_REFCLK_process :process
   begin
		MGT_REFCLK_P <= '0';
		MGT_REFCLK_N <= '1';
		wait for MGT_REFCLK_period/2;
		MGT_REFCLK_P <= '1';
		MGT_REFCLK_N <= '0';
		wait for MGT_REFCLK_period/2;
   end process;

FMC_I2C_SCK<='H'; -- weak pullup
FMC_I2C_SDA<='H'; -- weak pullup
FMC_I2C_SDA<=SLAVE_SDA; -- weak pullup

SDA<=to_UX01(FMC_I2C_SDA);
SCK<=to_UX01(FMC_I2C_SCK);
--SLAVE_SDA<='0' when bit_ctr=9 and SCK='1' else 'H';

i2c_process :process(all)
   begin
		if falling_edge(SDA) and SCK then
			bit_ctr<=(others=>'0');
		elsif rising_edge(SCK) then
			if bit_ctr/=15 then
				bit_ctr<=bit_ctr+1;
			end if;
		end if;

		if falling_edge(SCK) then
			if bit_ctr=8 then
				SLAVE_SDA<='0';
			elsif bit_ctr=9 then
				SLAVE_SDA<='H';
			end if;
		end if;

	end process;






---------------------------------------------------------------------
-- Instantiate UDP / IP / Ethernet interface to talk to the PHY
---------------------------------------------------------------------


	SIM_UDP0: entity work.udp_mac
			generic map (
				PHY_TYPE => sel(BSB_INTERFACE = UDP_GMII, GMII, SGMII),
				SGMII_CLOCK_SOURCE => SGMII_CLOCK_SOURCE,
				BROADCAST_IP_PORT => 41000,
				SIM => SIM
				)
			port map(
				-- Set DESTINATION address to simulate those used by the test computer
				local_mac_addr     => X"001BFC43BAFF",
				local_ip_addr      => X"0A0A0A0A",
				local_ip_port      => X"A028",
				local_subarray     => "00",
				-- tx_mac_dest_addr     => X"123456780A0B", -- last bits must match the address set by the switch
				-- tx_ip_dest_addr      => X"0A0A0A0B",
				remote_mac_addr0     => X"FFFFFFFFFFFF", -- last bits must match the address set by the switch
				remote_ip_addr0      => X"FFFFFFFF",
				remote_ip_port0     => X"A028",
				remote_ip_port1     => X"A029",

				-- GMII PHY interface
				phy_rxclk            =>phy_txclk,
				phy_reset_l          => open,
				phy_rxctrl_rxdv      => phy_txctl_txen,
				phy_rxd              => phy_txd,

				phy_txc_gtxclk       => phy_rxclk, -- TX bus clock provided to the PHY by the FPGA
				phy_txer             => phy_txer,
				phy_txctl_txen       => phy_rxctrl_rxdv,
				phy_txd              => phy_rxd,

				--SGMII PHY interface
				sfp_refclk_buf       => sfp_clk_p,
				sfp_refclk_nobuf     => sfp_clk_p,
				sfp_tx_p             => sfp_rx_p, -- we swap RX and TX here
				sfp_tx_n             => sfp_rx_n,
				sfp_rx_p             => sfp_tx_p, -- we swap RX and TX here
				sfp_rx_n             => sfp_tx_n,

				-- User interface
				-- TX interface
				s_axis_udp_tx_tvalid => tx_valid,
				s_axis_udp_tx_tdata  => tx_data,
				s_axis_udp_tx_tlast  => tx_last,
 				s_axis_udp_tx_tready => tx_ready,
				tx_port              => "00",

				-- RX interface
				m_axis_udp_rx_tdata  => rx_tdata,
				m_axis_udp_rx_tvalid => rx_tvalid,
				m_axis_udp_rx_tlast  => rx_tlast,
				m_axis_udp_rx_tready => '1',

				clk125               => clk125,
				-- clk200               => sysclk_p,
				rst                  => cpu_reset
		);

--TX_valid<=TX_last;

   -- Stimulus process
stim_proc: process
begin

	TX_TRIG<='1'; -- Start sending commands via PHY

	-- simulate button press
	wait for 100*SYSCLK_period;
	GPIO_BUTTON0<='1';
	wait for 1000*SYSCLK_period;
	GPIO_BUTTON0<='0';

	-- insert stimulus here

	wait;
end process;


phy_process: process
	begin
--	wait for 250 ns;  -- make sure the clocks are stabilized
--
--	for i in 1 to 10 loop
--		wait until CLK125='1';
--	end loop;
--
--	wait until TX_TRIG='1'; -- wait for the reset sequence to be finished before starting sending commands
	-- hold reset state for 100 ns.
	CPU_RESET<='1';
--	ADC_SYNC_P<='1'; -- Enable SYNC
--	ADC_SYNC_N<='0';

	wait for 10*SYSCLK_period;
	CPU_RESET<='0';
	wait for 10*SYSCLK_period;
--	ADC_SYNC_P<='0'; -- Disable SYNC
--	ADC_SYNC_N<='1';
	wait for 10*SYSCLK_period;
-- 2012-03-26  - Dummy read test to check AXI4
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, 0, 1, 2, 3); --

	-- Test I2C
	-- 2012-03-28
--fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_PORT, I2C_MODULE, 4, 16#85#); -- start transmission of 3 bytes


-- READ FR_DIST[0]
-- JFC 110809
--Read_Command(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, 0, 1, 2); --
--Read_Command(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, 0, 1, 3); --

--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, 8, 0, 4, 16#45#); -- Start SPI transmission/reception of 2 bytes
--	Read_Command(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, 8, 0, 0); --
--	Read_Command(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, 8, 0, 1); --

--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, 0, 1, 0, 16#AB#); --
--	Read_Command(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, 0, 1, 0); --

	-- ADC SYNC Pulse
	-- 110906
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, 8, 3, 0, 2); --
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, 8, 3, 0, 0); --

	-- test new AXI4 command stream system (watch out: bad commands make the simulator stop)
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, 1, 0, 0, 16#AA#); -- Send random byte to test
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, 2, 3, 4, 16#BB#); -- Send random byte to test

--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, SRCSEL_MODULE, 1, 2); -- Set number of frames to force
--	Read_Command(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, ANT0_PORT, SRCSEL_MODULE, 1); -- Read number of frames to force

	-- Send ADC SYNC through encoded 10 MHz
	-- 111102
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_PORT, REFCLK_MODULE, 0, 16#10#); -- Enable ENCODE_SYNC

	-- FORCE ADC SYNC Locally
	-- 111207
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_PORT, REFCLK_MODULE, 0, 16#20#); -- Enable FORCE_SYNC
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_PORT, REFCLK_MODULE, 0, 16#00#); -- DISAble FORCE_SYNC

	-- ADCDAQ CAPTURE
	-- 2011-09-29
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT1_PORT, ADCDAQ_MODULE, 8, 128); --
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT1_PORT, ADCDAQ_MODULE, 8, 0); --
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT1_PORT, ADCDAQ_MODULE, 8, 128); --
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT1_PORT, ADCDAQ_MODULE, 8, 0); --

	-- ADCDAQ PLL DRP test
	-- 2011-10-17
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT1_PORT, ADCDAQ_MODULE, 16#09#, 16#80#); -- Enable  MMCM RESET
--	Write_Word(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, ANT1_PORT, ADCDAQ_MODULE, 16#200#+2*16#0A#, 16#6104#); -- Write to CLKOUT1 Register 1
--	Read_Command(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, ANT1_PORT, ADCDAQ_MODULE, 16#200# +2*16#0A#); -- Read  CLKOUT1 Register 1 MSB
--	Read_Command(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, ANT1_PORT, ADCDAQ_MODULE, 16#200# +2*16#0A#+1); -- Read  CLKOUT1 Register 1 LSB
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT1_PORT, ADCDAQ_MODULE, 16#09#, 16#00#); -- Disable  MMCM RESET


	-- SYSMON Read/Write tests
	-- 110725
--	Write_Word(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, 8, 1, 0, 1); -- Enable Bank 1
--	Write_Word(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, 8, 1, 128, 16#1234#); -- Write word to SYSMON
--	Read_Command(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, 8, 1, 128+0); --
--	Read_Command(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, 8, 1, 128+1); --



	-- MGT Tests
	-- 110601
	-- Read MGT[1] PRBS Error counter at DRP address 0x82
	--Read_Command(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, 9, 1, 16#200#+2*16#82#); -- Read PRBS_ERR_COUNTER
	--Read_Command(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, 9, 1, 16#200#+2*16#82#+1); -- Read PRBS_ERR_COUNTER


	-- Read MGT[1] RX_PLL_COM_CFG[15:0]  counter at DRP address 0x19. Should yield 0x680A
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, 9, 1, 8, 0); -- Enable Bank 0 (DRP starting address 0x00)
--	Read_Command(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, 9, 1, 16#200#+16#19#*2); -- Read MSB
--	Read_Command(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, 9, 1, 16#200#+16#19#*2+1); -- Read LSB

--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, 0, 0, 0, 16); -- Sync FRAME_DIST Ramp with ADC output
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, 0, 0, 0, 0); -- Stop Sync FRAME_DIST Ramp with ADC output


   -- GTX Test
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, 9, 0, 0, 55); -- Write to GTX module
--	Read_Command(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, 9, 0, 0); -- Read GTX register

--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, 0, 1, 128, 16#FF#); -- Enable storing 8 first samples of each frame


--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, 8, 0, 8, 2); -- Enable ADCDAQ-level ramp generator


	if BSB_INTERFACE = UDP_SGMII then
		wait for 20 us;
	else
		wait for 0.5 us;
	end if;
--
--	wait for 20 us; -- for SGMII and 10G-based sims
	-- 2012-05-28 JFC
	-- Set internal clock for ADC1 PLL
	fpga_read(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_GPIO_BASE_ADDR + 0); -- Read cookie
	-- fpga_read(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_GPIO_BASE_ADDR + 128 + 0, log2_length => 3); -- Read 8 bytes in a single command
	-- fpga_read(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_SYSMON_BASE_ADDR + 16#200# + 0, log2_length => 1); -- Read 2 bytes (TEMP_REG) in SYSMON
	-- fpga_read(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_SYSMON_BASE_ADDR + 16#200# + 2, log2_length => 1); -- Read 2 bytes (TEMP_MAX or MIN?) in SYSMON
	-- fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_GPIO_BASE_ADDR + 0, 2#00110000#); -- Set PLL clock source to internal CLK200 and reset channelizer MMCM
	-- fpga_read(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_SYSMON_BASE_ADDR + 16#200#, 3); -- Read SYSMON

	fpga_write_control(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_GPIO_BASE_ADDR + 0, 2#00110000#); -- Set PLL clock source to internal CLK200 and reset channelizer MMCM
	fpga_write_control(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_GPIO_BASE_ADDR + 0, 2#00010000#); -- Release channelizer MMCM reset

	-- fpga_read(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_GPIO_BASE_ADDR + 16#01#); -- Read PLL clock source
	-- fpga_read(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_GPIO_BASE_ADDR + 16#81#); -- Read PLL clock source
	-- fpga_read(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_GPIO_BASE_ADDR + 16#82#); -- Read PLL clock source
	-- fpga_read(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_GPIO_BASE_ADDR + 16#83#); -- Read PLL clock source

--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, SRCSEL_MODULE, 0, 2#00000000#); -- Source = ADC
	-- fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, SRCSEL_MODULE, 0, 2#00000001#); -- Source = FUNCGEN
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, SRCSEL_MODULE, 0, 2#00000010#); -- Source = INJECT

--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, FUNCGEN_MODULE, 0, 2#00000001#); -- Data = A
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, FUNCGEN_MODULE, 0, 2#00000010#); -- Data = B
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, FUNCGEN_MODULE, 0, 2#00000011#); -- Data = AB
	-- fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, FUNCGEN_MODULE, 0, 2#00000100#); -- Data = 'ramp'
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, FUNCGEN_MODULE, 0, 2#00000101#); -- Data = 'real ramp'

	-- fpga_read(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_BASE_ADDR + SRCSEL_OFFSET_ADDR + 0);
	-- fpga_read(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_BASE_ADDR + SRCSEL_OFFSET_ADDR + 0);

	-- Valid code, as of 2016
	-- -- ANT[i] setup
	-- for i in 0 to NUMBER_OF_CHANNELIZERS-1 loop
	-- 	report "COnfiguring channel";
	-- 	fpga_write_control(clk125, tx_data, tx_valid, tx_last, tx_ready, CHAN_BASE_ADDR + i * CHAN_ADDR_INCREMENT + SRCSEL_OFFSET + 0, 2#00000001#); -- Source = FUNCGEN
	-- 	-- fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, CHAN_BASE_ADDR + i * CHAN_ADDR_INCREMENT + FUNCGEN_OFFSET + 0, 2#00000101#); -- Data = 'real ramp'
	-- 	-- fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, CHAN_BASE_ADDR + i * CHAN_ADDR_INCREMENT + FUNCGEN_OFFSET + 0, 2#00000100#); -- Data = 'ramp'
	-- 	fpga_write_control(clk125, tx_data, tx_valid, tx_last, tx_ready, CHAN_BASE_ADDR + i * CHAN_ADDR_INCREMENT + FUNCGEN_OFFSET + 0, 2#00000111#); -- Data = 'real_ramp4'
	-- -- 	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT+i, FUNCGEN_MODULE, 0, 2#00000011#); -- Data = AB
	-- -- 	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT+i, FUNCGEN_MODULE, 1, 128); -- A
	-- -- 	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT+i, FUNCGEN_MODULE, 2, 129); -- B
	-- -- --	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT+i, SCALER_MODULE, 0, 2#01000000#); -- BYPASS SCALER
	-- 	-- fpga_write(clk125, tx_data, tx_valid, tx_last,Ctx_ready, HAN_BASE_ADDR + i * CHAN_ADDR_INCREMENT + SCALER_OFFSET + 0, 2#00001100#); -- BYPASS SCALER=0, shift left=12
	-- 	--fpga_write(clk125, tx_data, tx_valid, tx_last,Ctx_ready, HAN_BASE_ADDR + i * CHAN_ADDR_INCREMENT + SCALER_OFFSET + 0, 2#00100000#+31); -- 4-bit mode, BYPASS SCALER=0, shift left=31
	-- 	fpga_write_control(clk125, tx_data, tx_valid, tx_last, tx_ready, CHAN_BASE_ADDR + i * CHAN_ADDR_INCREMENT + SCALER_OFFSET + 0, 2#00100000#+27); -- BYPASS SCALER=0, FOUR_BITS=1, shift left=27
	-- 	fpga_write_control(clk125, tx_data, tx_valid, tx_last, tx_ready, CHAN_BASE_ADDR + i * CHAN_ADDR_INCREMENT + SCALER_OFFSET + 1, 2#00000000#); -- use_offset_binary = 0,  use_gain_table=0, active_gain_bank = 0, gain page=0
	-- 	sleep(clk125, 3*64); -- prevent the buffers from overflowing by allowing time to send the ethernet framing
	-- end loop;


	-- for i in 0 to NUMBER_OF_CROSSBAR_OUTPUTS-1 loop
	-- 	fpga_write_control(clk125, tx_data, tx_valid, tx_last, tx_ready, CROSSBAR0_CHDIST_BASE_ADDR + i * CROSSBAR_ADDR_INCREMENT + 4, 1); -- Set the number of frames per packet
	-- 	fpga_write_control(clk125, tx_data, tx_valid, tx_last, tx_ready, CROSSBAR0_CHDIST_BASE_ADDR + i * CROSSBAR_ADDR_INCREMENT + 3, 128); -- Set the number of words to select
	-- 	fpga_write_control(clk125, tx_data, tx_valid, tx_last, tx_ready, CROSSBAR0_CHDIST_BASE_ADDR + i * CROSSBAR_ADDR_INCREMENT + 5, NUMBER_OF_CROSSBAR_INPUTS-1); -- Set the range of inputs to capture (0 to NUMBER_OF_CROSSBAR_INPUTS-1)
	-- 	fpga_select_bins(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, CROSSBAR0_CHDIST_BASE_ADDR + i * CROSSBAR_ADDR_INCREMENT, i, 8, 128); -- Enable storage and transmission of N frequency bins.
	-- 	sleep(clk125, 2*64); -- prevent the buffers from overflowing by allowing time to send the ethernet framing
	-- end loop;

--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_PORT, GPIO_MODULE, 3, 2#01000000#); -- Activate ANT_RESET

--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_PORT, GPIO_MODULE, 0, 2#10000000#); -- Send global trigger to start data capture and transmission over Ethernet
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_PORT, GPIO_MODULE, 0, 0); -- clear global trigger to prevent data tranmission and data capture
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, FFT_MODULE, 0, 2#00000001#); -- BYPASS FFT
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, SCALER_MODULE, 0, 2#01000000#); -- BYPASS SCALER
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT1_PORT, SCALER_MODULE, 0, 2#01000000#); -- BYPASS SCALER
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT2_PORT, SCALER_MODULE, 0, 2#01000000#); -- BYPASS SCALER
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT3_PORT, SCALER_MODULE, 0, 2#01000000#); -- BYPASS SCALER
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT4_PORT, SCALER_MODULE, 0, 2#01000000#); -- BYPASS SCALER

--	Enable_Frame(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, CORR0_PORT, 8); -- Enable storage and transmission of N words (N must be a multiple of 8). 1 word = 4 samples or 2 frequency bins.

--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, SCALER_MODULE, 0, 2#01000000#); -- BYPASS SCALER
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, CORR0_PORT, CHDIST_MODULE, 3, 8); -- Set the number of words to select
--	Enable_Frame(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, CORR0_PORT, 8); -- Enable storage and transmission of N words (N must be a multiple of 8). 1 word = 4 samples or 2 frequency bins.


	fpga_write_control(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_GPIO_BASE_ADDR + 3, 2#00000000#); -- Deactivate ANT_RESET and CORR_RESET


   -- 2012-09-30 JFC
	-- ADC SYNC test
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_PORT, GPIO_MODULE, 3, 2#00000000#); -- Deactivate ANT_RESET
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_PORT, GPIO_MODULE, 3, 2#00000000#); -- Deactivate ANT_RESET
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, SRCSEL_MODULE, 0, 2#00000000#); -- Source = ADC
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_PORT, GPIO_MODULE, 0, 128); -- Send global trigger to start data tranmission and data capture
--
	-- 2012-11-01 JFC
	-- Generate SYNC
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_PORT, REFCLK_MODULE, 1, 2#01000000#); -- Enable SYNC Generation state machine
	fpga_write_control(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_REFCLK_BASE_ADDR + 0, 16#20#); -- Enable FORCE_SYNC
	fpga_write_control(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_REFCLK_BASE_ADDR + 0, 16#00#); -- Disable FORCE_SYNC

   -- 2012-09-30 JFC
	-- Function generator test
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_PORT, GPIO_MODULE, 3, 2#01000000#); -- Enable ANT_RESET
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_PORT, GPIO_MODULE, 3, 2#01000000#); -- Enable ANT_RESET
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, SRCSEL_MODULE, 0, 2#00000001#); -- Source = FUNCGEN
----	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, FUNCGEN_MODULE, 0, 2#00000100#); -- Data = 'ramp'
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, FUNCGEN_MODULE, 0, 2#00000101#); -- Data = 'real ramp'
----	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_PORT, GPIO_MODULE, 0, 128); -- Set global trigger to flag the frames for data capture
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_PORT, GPIO_MODULE, 3, 2#00000000#); -- Deactivate ANT_RESET
--


	-- 2012-09-30 JFC
	-- Inject Frame
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_PORT, GPIO_MODULE, 3, 2#00000000#); -- Deactivate ANT_RESET
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_PORT, GPIO_MODULE, 3, 2#00000000#); -- Deactivate ANT_RESET
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, SRCSEL_MODULE, 0, 2#00000010#); -- Source = INJECT
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, FFT_MODULE, 0, 2#00000001#); -- BYPASS FFT
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, SCALER_MODULE, 0, 2#01000000#); -- BYPASS SCALER
--
--	for i in 0 to 20 loop
--		fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_PORT, GPIO_MODULE, 0, 0); -- clear global trigger to prevent data transmission and data capture
--		for j in 0 to 1 loop
--			Write_Frame(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, ANT0_PORT+j); -- Inject frame (ramp)
--		end loop;
--		for j in 0 to 10 loop
--		fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_PORT, GPIO_MODULE, 0, 128); -- Send global trigger to start data tranmission and data capture
--		end loop;
--	end loop;

   -- 2012-09-30 JFC
	-- Function generator test
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_PORT, GPIO_MODULE, 3, 2#01000000#); -- Enable ANT_RESET
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_PORT, GPIO_MODULE, 3, 2#01000000#); -- Enable ANT_RESET
--	for i in 0 to 3 loop
--		fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT+i, SRCSEL_MODULE, 0, 2#00000001#); -- Source = FUNCGEN
--		fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT+i, FFT_MODULE, 0, 2#00000001#); -- BYPASS FFT
--		fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT+i, SCALER_MODULE, 0, 2#01000000#); -- BYPASS SCALER
	--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT+i, FUNCGEN_MODULE, 0, 2#00000100#); -- Data = 'ramp'
--		fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT+i, FUNCGEN_MODULE, 0, 2#00000101#); -- Data = 'real ramp'
--	end loop;
--	Enable_Frame(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, CORR0_PORT, 16); -- Enable storage and transmission of N words (N must be a multiple of 8). 1 word = 4 samples or 2 frequency bins.
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_PORT, GPIO_MODULE, 0, 128); -- Set global trigger to flag the frames for data capture
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_PORT, GPIO_MODULE, 3, 2#00000000#); -- Deactivate ANT_RESET and CORR_RESET
--


--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, SRCSEL_MODULE, 0, 2#00000010#); -- set data source= ramp

	-- Force N frames
	-- 2012-05-28
	-- Setup ANT0
	-- Select data source
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, SRCSEL_MODULE, 0, 2#10000000#); -- Stop data source

--
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, SRCSEL_MODULE, 0, 2#00000011#); -- Select real ramp transmission
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT1_PORT, SRCSEL_MODULE, 0, 2#00000011#); -- Select real ramp transmission

	-- Trig transmission
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, SYSTEM_PORT, GPIO_MODULE, 0, 128); -- Send global trigger to start data tranmission and data capture

	--	Read_Command(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, ANT0_PORT, CHDIST_MODULE, 16#200#, 4); --
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, SRCSEL_MODULE, 1, 2); -- Set number of frames to force
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, SRCSEL_MODULE, 0, 3); -- Enable ADC clock and ADC data source
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, SRCSEL_MODULE, 0, 2#00000110#); -- on FR_DIST, Trigger Frame transmission (ramps) using internal clock and data
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, SRCSEL_MODULE, 0, 2#00000101#); -- select FIFO, trigger frame capture
--	Write_Frame(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, ANT0_PORT); -- Inject frame
--	Write_Frame(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, ANT0_PORT); -- Inject frame
--	Write_Frame(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, ANT0_PORT); -- Inject frame

	-- Setup ANT1
--	Enable_Frame(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, 1, 1024/4); -- Enable storage and transmission of N words (N must be a multiple of 8). 1 word = 4 samples or 2 frequency bins.
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, 1, 1, 1, 2); -- Set number of frames to force
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, 1, 1, 0, 3); -- Enable ADC clock and ADC data source


--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, 0, 0, 0, 16#20#); -- Enable dual frame
--	Write_Frame(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, 0); -- Inject frame
--	Write_Frame(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, 0); -- Inject frame

	-- Send 2 internal frames using ANT1
--	Enable_Frame(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, 1, 8*1); -- Enable storage and transmission of N samples (when N is a multiple of 8)
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, 1, 0, 1, 2); -- Set number of frames to force
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, 1, 0, 0, 3); -- Enable ADC clock and ADC data source
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, 1, 0, 0, 4+0); -- on FR_DIST, Trigger Frame transmission (ramps) using internal clock and data

--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, 8, 8, 5, 128); -- on FR_DIST, Trigger Frame transmission (ramps) using internal clock and data

	-- Force 2 frames on ANT4
	-- 111209
--	Enable_Frame(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, ANT4_PORT, 1024/4); -- Enable storage and transmission of N words (N must be a multiple of 8). 1 word = 4 samples or 2 frequency bins.
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT4_PORT, SRCSEL_MODULE, 1, 2); -- Set number of frames to force
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT4_PORT, SRCSEL_MODULE, 0, 3); -- Enable ADC clock and ADC data source
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT4_PORT, SRCSEL_MODULE, 0, 4+3); -- on FR_DIST, Trigger Frame transmission (ramps) using internal clock and data


--	fpga_write2(clk125 , tx_data, tx_valid , tx_last , 0, 1, 255, 128);
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, 0, 0, 0, 2);

--	DUMMY<='1';
	wait for 1 ms;
--	DUMMY<='0';
--	fpga_write(clk125, tx_data, tx_valid, tx_last, tx_ready, ANT0_PORT, SRCSEL_MODULE, 0, 2#00000001#); -- test: this is to see if that would prevent the simulation to stop after 40 us

--	for i in 1 to 10000 loop
--		wait until rising_edge(CLK125);
--	end loop;

--	Read_Command(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, 0, 0, 0);
--	Read_Command(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, 0, 1, 255);
--	Read_Command(CLK125, TX_DATA, tx_valid, TX_last, tx_ready, 0, 0, 0);
	wait;

--		end if; -- CLK
	end process;

END;
