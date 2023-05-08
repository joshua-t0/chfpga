--! @file
----------------------------------------------------------------------------------
-- Company:  McGill University
-- Engineer: JF CLiche
--
-- Create Date: 2014-05-07
-- Design Name: ChFPGA
-- Module Name: bp_shuffle
-- Project Name: CHIME
-- Target Devices: Kintex 7
-- Tool Versions: Vivado 2013.4
-- Description: Implements an array of GTX that transmit data across the backplane.
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_misc.ALL; -- for reduce functions

library UNISIM;
use UNISIM.VComponents.all;

library work;
use work.chFPGA_Package.all;
--use work.ip_package.all; -- Import definition of components used in this module

entity xglink_core is
	generic (
		LINK_SPEED                  : integer := 1; --! 0: 7.8125 Gbps, 1: 10.3125 Gbps line rate, assuming a 156.25 MHz reference clock.
		NUMBER_OF_TX_LANES          : integer := 2;
		NUMBER_OF_RX_LANES          : integer := 2;
		NUMBER_OF_REFCLK            : integer := 2;
		LANE_TO_QUAD_MAP            : integerArray := (0 to 3=>0, 4 to 7=>1, 8 to 11=> 2, 12 to 14 => 3); --! LANE_TO_QUAD_MAP Indicates which quad is associated each channel. The QUAD number is an integer between 0 and N-1, where N is the total number of quads used.
		QUAD_TO_REFCLK_MAP          : integerArray := (1,0,0,1); --! QUAD_TO_REFCLK_MAP Indicates which refclk is associated with each QUAD (N integers from 0 to NUMBER_OF_REFCLK-1).
		EXAMPLE_SIMULATION          : integer :=1;
		EXAMPLE_SIM_GTRESET_SPEEDUP : string := "TRUE";    -- simulation setting for GT SecureIP model
		DONT_RESET_ON_DATA_ERROR_IN : std_logic := '0';
		NUMBER_OF_CONTROL_BYTES     : integer :=0;
		NUMBER_OF_STATUS_BYTES      : integer :=0;
		SIM                         : boolean := false
		);
	port (
		tx_p: out std_logic_vector(0 to max(NUMBER_OF_TX_LANES, NUMBER_OF_RX_LANES)-1);
		tx_n: out std_logic_vector(0 to max(NUMBER_OF_TX_LANES, NUMBER_OF_RX_LANES)-1);
		rx_p: in std_logic_vector(0 to max(NUMBER_OF_TX_LANES, NUMBER_OF_RX_LANES)-1);
		rx_n: in std_logic_vector(0 to max(NUMBER_OF_TX_LANES, NUMBER_OF_RX_LANES)-1);
		refclk_p : in std_logic_vector(0 to NUMBER_OF_REFCLK-1); --156.250 high quality reference clocks to feed all the quads in the array. One reference clock can feed the bank it is  on, and the banks above and below.
		refclk_n : in std_logic_vector(0 to NUMBER_OF_REFCLK-1);

		refclk_div2: out std_logic_vector(0 to NUMBER_OF_REFCLK-1); -- 156.25 MHz reference clock
		txclk_div2: out std_logic; -- Data clock generated from MMCM

		tx_data: in slv32_array(0 to NUMBER_OF_TX_LANES-1); --! The most significant byte is transmitted first
		tx_header: in slv2_array(0 to NUMBER_OF_TX_LANES-1);
		tx_ready: out std_logic_vector(0 to NUMBER_OF_TX_LANES-1); --! Indicates when the transmitter will accept the data on the data bus
		tx_clk: out std_logic; -- 244.140625 MHz for LINK_SPEED=0, 322.265615 MHz for LINK_SPEED=1.
		tx_resetdone: out std_logic_vector(0 to NUMBER_OF_TX_LANES-1); --! Indicates that the transmitter is ready to send data

		rx_data: out slv32_array(0 to max(NUMBER_OF_RX_LANES-1, 0));
		rx_data_valid: out std_logic_vector(0 to max(NUMBER_OF_RX_LANES-1, 0)); --! Active high when  valid data is  placed on the bus
		rx_header: out slv2_array(0 to max(NUMBER_OF_RX_LANES-1, 0));
		rx_header_valid: out std_logic_vector(0 to max(NUMBER_OF_RX_LANES-1, 0)); --! Indicates when the header is valid. This happen on the first half of each word.
		rx_clk: out std_logic_vector(0 to max(NUMBER_OF_RX_LANES-1, 0)); --! clock synchronous with the rx data. Recovered from the received link.
		rx_resetdone: out std_logic_vector(0 to max(NUMBER_OF_RX_LANES-1, 0)); --! Indicates that the receiver is ready to receive data

		control_bytes: out slv8_array(0 to NUMBER_OF_CONTROL_BYTES-1);
		status_bytes: in slv8_array(0 to NUMBER_OF_STATUS_BYTES-1):=(others=>(others=>'0'));

		-- Control and reply streams
		CMD_DAT: in AXIS8_DAT_STRUCT;
		CMD_RDY: out AXIS8_RDY_STRUCT;
		RPLY_DAT: out AXIS8_DAT_STRUCT;
		RPLY_RDY: in AXIS8_RDY_STRUCT;
		CTRL_CLK : IN std_logic; -- control clock
		CTRL_RST : in std_logic;

		-- clk: in std_logic; --! AXI-S data clock. Not related to the 10G Ethernet clocks.
		areset: in std_logic --! asynchronous reset
	 );

end xglink_core;

architecture Behavioral of xglink_core is

attribute ASYNC_REG : string;
attribute SHREG_EXTRACT : string;
attribute DONT_TOUCH : string;

--- CONSTANTS
constant DLY : time := 1 ps; -- delta delay used to ensure the simulator changes the data after the clock edge (which is a problem because we do a clock assignment which might be evaluated in any order)

constant NUMBER_OF_GTX : integer := max(NUMBER_OF_RX_LANES, NUMBER_OF_TX_LANES);
constant NUMBER_OF_QUADS : integer := MAX(LANE_TO_QUAD_MAP(0 to NUMBER_OF_GTX-1))+1; --! get the maximum QUAD index from the list of actually implemented channels


-- QPLL parameters
-- Assumes a 156.25 MHz reference clock
-- Line rate = F_Refclk * N / (M * D)
-- M = 1,2,3,4
-- N = 16, 20, 32, 40, 64, 66, 80, 100
-- D = 1,2,4,8,16 (always 1 in our application)
-- Word clock = line rate / 32
-- We send 33 bits raw word (data+header bit) on every word clock, but we skip 1 word every 33 words, so
-- Actual word rate = word_clock * 32/33 words
-- Actual bit rate is Actual word rate * 32 = Line_rate * 32/33
-- Speed 0 = N/M=100/2, 7.8125 Gbps line rate, 244.140625 word clock (no RX/TX every 2 out of 66 clocks), 7.5757 Gbps / 946.92 MB/s effective
-- Speed 1 = N/M=66/1, 10.3125 Gbps line rate, 322.265625 word clock (see comment above), 10.000 Gbps / 1250 MB/s effective

constant QPLL_FBDIV_IN_TABLE : slv10_array := (
			0 => "0101110000", -- N=100
			1 => "0101000000" -- N=66
			);

constant QPLL_FBDIV_RATIO_TABLE : std_logic_vector := (
			0 => '1', -- used when N=100
			1 => '0' -- used when N=66
			);

constant QPLL_CFG_TABLE : slv28_array := (
			0 => x"06801C1",
			1 => x"0680181"
			);

constant QPLL_REFCLK_DIV_TABLE : integer_array := (
			0 => 2, -- M=2 (0 in the DRP register)
			1 => 1 -- M=1 (16 in the DRP register)
			);

constant QPLL_FBDIV_IN    : std_logic_vector(9 downto 0) := QPLL_FBDIV_IN_TABLE(LINK_SPEED);
constant QPLL_FBDIV_RATIO : std_logic := QPLL_FBDIV_RATIO_TABLE(LINK_SPEED);
constant QPLL_CFG: std_logic_vector(26 downto 0) := QPLL_CFG_TABLE(LINK_SPEED)(26 downto 0);
constant QPLL_REFCLK_DIV: integer := QPLL_REFCLK_DIV_TABLE(LINK_SPEED);

---- CLOCKS
-- signal clk156_nobuf : std_logic; --! unbuffered 156.25 MHz data clock at the output of MMCM
signal clk156 : std_logic; --! buffered 156.25 MHz data clock derived from the reference clock

-- signal txclk322_nobuf : std_logic_vector(0 to NUMBER_OF_GTX-1); --! Unbuffered TXOUTCLK from each GTX
signal txclk322 : std_logic; --! buffered TXOUTCLK used to clock all GTX TX subsystems
signal rxclk322 : slv(0 to NUMBER_OF_GTX-1); --!

signal txusrclk : std_logic; --! txusrclk for all GTX
signal txusrclk2 : std_logic; --! txusrclk2 for all GTX
signal rxusrclk : slv(0 to NUMBER_OF_GTX-1); --! rxusrclk for all GTX
signal rxusrclk2 : slv(0 to NUMBER_OF_GTX-1); --! rxusrclk2 for all GTX

signal refclk_nobuf : std_logic_vector(0 to NUMBER_OF_REFCLK-1); --! unbuffered GTX reference clock
signal refclk_buf : std_logic_vector(0 to NUMBER_OF_REFCLK-1); --! buffered GTX reference clock

--- QPLL signals
signal qpllreset : std_logic; --! QPLL reset signal for all QPLLs, generated after 500us following the release of areset
signal qplloutclk : std_logic_vector(0 to NUMBER_OF_QUADS-1);
signal qplloutrefclk : std_logic_vector(0 to NUMBER_OF_QUADS-1);
signal qplllock, qplllock_debug : std_logic_vector(0 to NUMBER_OF_QUADS-1);
signal not_qplllock: std_logic;

-- signal qplllock_txusrclk2: std_logic;--_vector(0 to NUMBER_OF_QUADS-1);
-- attribute ASYNC_REG of qplllock_txusrclk2 : signal is "true";

-- signal txuserrdy : std_logic;
signal resetdone: std_logic;


-- Reset signals

signal tx_resetdone_int: std_logic_vector(0 to NUMBER_OF_GTX-1);
signal rx_resetdone_int: std_logic_vector(0 to NUMBER_OF_GTX-1);

signal scrambler_reset: std_logic_vector(0 to NUMBER_OF_GTX-1);


-- signal areset_refclk_tmp : std_logic; --!
-- signal areset_refclk : std_logic; --! user reset, synchronized to refclk

-- attribute ASYNC_REG of areset_refclk_tmp : signal is "true";
-- attribute ASYNC_REG of areset_refclk : signal is "true";

-- signal areset_clk156_tmp : std_logic;
-- signal areset_clk156 : std_logic;
-- attribute ASYNC_REG of areset_clk156_tmp : signal is "true";
-- attribute ASYNC_REG of areset_clk156 : signal is "true";

-- signal gttxreset : std_logic; --! Generated 500 us after areset release. Synchronous to refclk. Goes to all PCS/PMAs.

-- signal gttxreset_txusrclk2_tmp : std_logic;
-- signal gttxreset_txusrclk2 : std_logic; --! Generated 500 us after areset release. Synchronous to txusrclk2. Goes to all PCS/PMAs.
-- attribute ASYNC_REG of gttxreset_txusrclk2_tmp : signal is "true";
-- attribute ASYNC_REG of gttxreset_txusrclk2 : signal is "true";

signal reset_counter  : unsigned(7 downto 0) := X"00";
signal reset_pulse : std_logic_vector(3 downto 0);
-- signal reset_counter_done : std_logic;

-- signal core_status_vect: slv8_array(0 to NUMBER_OF_GTX-1);
-- signal configuration_vector : std_logic_vector(535 downto 0) := (others=>'0');
-- type STATUS_VECTOR_ARRAY is array (natural range <>) of slv(447 downto 0);
-- signal status_vector        : STATUS_VECTOR_ARRAY(0 to NUMBER_OF_GTX-1);
-- signal tx_fault: std_logic;
-- signal signal_detect: std_logic;
-- signal test_enable: std_logic;
-- signal link_enable: std_logic;


-- signal xgmii_txd: slv64_array(0 to NUMBER_OF_GTX-1);
-- signal xgmii_txc: slv8_array(0 to NUMBER_OF_GTX-1);
-- signal xgmii_rxd: slv64_array(0 to NUMBER_OF_GTX-1);
-- signal xgmii_rxc: slv8_array(0 to NUMBER_OF_GTX-1);


-- signal mac_src_addr: slv48_array(0 to NUMBER_OF_GTX-1);
-- signal mac_dest_addr: slv48_array(0 to NUMBER_OF_GTX-1);
-- signal ip_src_addr: slv32_array(0 to NUMBER_OF_GTX-1);
-- signal ip_dest_addr: slv32_array(0 to NUMBER_OF_GTX-1);
-- signal ip_dest_port: slv16_array(0 to NUMBER_OF_GTX-1);

---  Test packet generator
-- signal word_counter: unsigned(31 downto 0) := X"00000000";
-- signal frame_counter: unsigned(7 downto 0) := (others=>'0');
-- signal ctr: unsigned(15 downto 0) :=(others=>'0');-- X"00", to_unsigned(0,16)
-- signal startup_ctr: unsigned(31 downto 0) :=(others=>'0');
-- signal wait_ctr: unsigned(11 downto 0) :=(others=>'0');
-- signal din: AXIS32_DAT_STRUCT_ARRAY(0 to NUMBER_OF_GTX-1);
-- signal test_din: AXIS32_DAT_STRUCT;

  -- signal refclk : std_logic;
constant NUMBER_OF_MODULES: integer := NUMBER_OF_QUADS + NUMBER_OF_GTX + 1; -- One common module, and one for each quad (QPLL) and channel (GTX)

signal MODULE_CMD_DAT: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_MODULES-1 downto 0);
signal MODULE_CMD_RDY: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_MODULES-1 downto 0);
signal MODULE_RPLY_DAT: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_MODULES-1 downto 0);
signal MODULE_RPLY_RDY: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_MODULES-1 downto 0);

signal ctrl_rst_reg: std_logic_vector(NUMBER_OF_MODULES-1 downto 0);
attribute DONT_TOUCH of ctrl_rst_reg : signal is "true";
attribute SHREG_EXTRACT of ctrl_rst_reg : signal is "false";


signal quad_drp_dout: slv16_array(NUMBER_OF_QUADS-1 downto 0);
signal quad_drp_din: slv16_array(NUMBER_OF_QUADS-1 downto 0);
signal quad_drp_addr: slv8_array(NUMBER_OF_QUADS-1 downto 0);
signal quad_drp_drdy: slv(NUMBER_OF_QUADS-1 downto 0);
signal quad_drp_den: slv(NUMBER_OF_QUADS-1 downto 0);
signal quad_drp_wr_en: slv(NUMBER_OF_QUADS-1 downto 0);

--signal DRP_BANK: STD_LOGIC_VECTOR(1 downto 0);



signal common_control_bytes: slv8_array(0 to 3 + NUMBER_OF_CONTROL_BYTES);
signal common_status_bytes: slv8_array(0 to 1 + NUMBER_OF_STATUS_BYTES);

type QUAD_CONTROL_BYTES_ARRAY is array (natural range <>) of slv8_array(0 to 0);
signal quad_control_bytes: QUAD_CONTROL_BYTES_ARRAY(0 to NUMBER_OF_QUADS-1);
type QUAD_STATUS_BYTES_ARRAY is array (natural range <>) of slv8_array(0 to 0);
signal quad_status_bytes: QUAD_STATUS_BYTES_ARRAY(0 to NUMBER_OF_QUADS-1);

type gt_CONTROL_BYTES_ARRAY is array (natural range <>) of slv8_array(0 to 5);
signal gt_control_bytes: gt_control_bytes_array(0 to NUMBER_OF_GTX-1);
type gt_STATUS_BYTES_ARRAY is array (natural range <>) of slv8_array(0 to sel(NUMBER_OF_RX_LANES>0, 11, 4));
signal gt_status_bytes: gt_status_bytes_array(0 to NUMBER_OF_GTX-1);

signal txclk_div2_int: std_logic := '0'; -- init needed
signal refclk_div2_int: std_logic_vector(0 to NUMBER_OF_REFCLK-1) := (others=> '0'); -- init needed

signal common_user_reset: std_logic;
signal common_user_tx_data: std_logic_vector(23 downto 0);
-- signal common_block_lock_reset: std_logic;
-- signal common_scrambler_reset: std_logic;
-- signal common_unscrambler_reset: std_logic;
-- signal common_scramble_en: std_logic;
-- signal common_descramble_en: std_logic;
-- signal common_capture_en: std_logic;

-------------------------------------------------------------------
signal gt_drp_dout: slv16_array(NUMBER_OF_GTX-1 downto 0);
signal gt_drp_din: slv16_array(NUMBER_OF_GTX-1 downto 0);
signal gt_drp_addr: slv9_array(NUMBER_OF_GTX-1 downto 0);
signal gt_drp_rdy: slv(NUMBER_OF_GTX-1 downto 0);
signal gt_drp_en: slv(NUMBER_OF_GTX-1 downto 0);
signal gt_drp_wr_en: slv(NUMBER_OF_GTX-1 downto 0);


constant STABLE_CLOCK_PERIOD: integer := 6; -- in fact 1/156.25 = 6.4 ns
constant WAIT_TIME_CDRLOCK: integer := sel(SIM, 1000,  50000 / integer(10.3125))/STABLE_CLOCK_PERIOD;
signal rx_cdrlock_counter  :   integer range 0 to WAIT_TIME_CDRLOCK:= 0 ;
signal rx_cdrlocked                    : std_logic;

signal gt_dmonitorout_out: slv8_array(0 to NUMBER_OF_GTX-1);
signal gt_rxmonitorout_out: slv7_array(0 to NUMBER_OF_GTX-1);
signal gt_rxmonitorsel_in: slv2_array(0 to NUMBER_OF_GTX-1) := (others=>"00");

signal gt_loopback_in: slv3_array(0 to NUMBER_OF_GTX-1);
signal gt_rxcdrhold_in: slv(0 to NUMBER_OF_GTX-1);
signal gt_rxdata_out: slv32_array(0 to NUMBER_OF_GTX-1);
signal gt_rxprbserr_out: slv(0 to NUMBER_OF_GTX-1);
signal gt_rxprbssel_in: slv3_array(0 to NUMBER_OF_GTX-1) := (others=> "000");
signal gt_txprbssel_in: slv3_array(0 to NUMBER_OF_GTX-1) := (others=> "000");
signal gt_rxprbscntreset_in: slv(0 to NUMBER_OF_GTX-1) := (others=>'0');
signal gt_rxbufstatus_out: slv3_array(0 to NUMBER_OF_GTX-1);
signal gt_rxdfeagchold_in: slv(0 to NUMBER_OF_GTX-1);
signal gt_rxdfelfhold_in: slv(0 to NUMBER_OF_GTX-1);
signal gt_rxoutclk_out: slv(0 to NUMBER_OF_GTX-1);
signal gt_rxdatavalid_out: slv(0 to NUMBER_OF_GTX-1);
signal gt_rxheader_out: slv2_array(0 to NUMBER_OF_GTX-1);
signal gt_rxheader_capture: slv2_array(0 to NUMBER_OF_GTX-1);
signal gt_rxheadervalid_out: slv(0 to NUMBER_OF_GTX-1);
signal gt_rxstartofseq_out: slv(0 to NUMBER_OF_GTX-1);
signal gt_rxgearboxslip_in: slv(0 to NUMBER_OF_GTX-1) := (others=>'0');
signal gt_rxpolarity_in: slv(0 to NUMBER_OF_GTX-1);
signal gt_txpolarity_in: slv(0 to NUMBER_OF_GTX-1);
signal gt_txpostcursor_in: slv5_array(0 to NUMBER_OF_GTX-1);
signal gt_txprecursor_in: slv5_array(0 to NUMBER_OF_GTX-1);
signal gt_gttxreset_in: slv(0 to NUMBER_OF_GTX-1);
signal gt_gttxreset_all: slv(0 to NUMBER_OF_GTX-1);
signal gt_txuserrdy_in: slv(0 to NUMBER_OF_GTX-1);
signal gt_rxuserrdy_in: slv(0 to NUMBER_OF_GTX-1);
signal gt_txprbsforceerr_in: slv(0 to NUMBER_OF_GTX-1) := (others=>'0');
signal gt_txbufstatus_out: slv2_array(0 to NUMBER_OF_GTX-1);
signal gt_txdiffctrl_in: slv4_array(0 to NUMBER_OF_GTX-1);
signal gt_txinhibit_in: slv(0 to NUMBER_OF_GTX-1);
signal gt_txdata_in: slv32_array(0 to NUMBER_OF_GTX-1);
signal gt_txdata_i: slv32_array(0 to NUMBER_OF_GTX-1);
signal gt_user_tx_data: slv32_array(0 to NUMBER_OF_GTX-1);
signal gt_user_tx_data_int: slv32_array(0 to NUMBER_OF_GTX-1);
signal gt_unscrambled_data: slv32_array(0 to NUMBER_OF_GTX-1);
signal gt_unscrambled_data_valid: slv(0 to NUMBER_OF_GTX-1);
signal gt_user_source_sel: slv(0 to NUMBER_OF_GTX-1);
signal gt_txoutclk_out: slv(0 to NUMBER_OF_GTX-1);
signal gt_txheader_in: slv2_array(0 to NUMBER_OF_GTX-1);
signal gt_user_tx_header: slv2_array(0 to NUMBER_OF_GTX-1);
signal gt_gtrxreset_in : slv(0 to NUMBER_OF_GTX-1);
signal gt_gtrxreset_all : slv(0 to NUMBER_OF_GTX-1);
signal gt_txsequence_in: slv7_array(0 to NUMBER_OF_GTX-1);
signal gt_rxresetdone_out: slv(0 to NUMBER_OF_GTX-1);
signal gt_txresetdone_out: slv(0 to NUMBER_OF_GTX-1);
signal gt_block_lock: slv(0 to NUMBER_OF_GTX-1) := (others => '0'); -- default provided to attempt to squash undriven warnings when there is no RX
signal quad_sel: std_logic_vector(1 downto 0);
signal gt_seq_counter: slv8_array(0 to NUMBER_OF_GTX-1); -- counts from 0 to 65
signal gt_scramble_en: slv(0 to NUMBER_OF_GTX-1);
signal gt_descramble_en: slv(0 to NUMBER_OF_GTX-1);
signal gt_block_lock_reset: slv(0 to NUMBER_OF_GTX-1) := (others=>'0');
signal gt_scrambler_reset: slv(0 to NUMBER_OF_GTX-1);
signal gt_unscrambler_reset: slv(0 to NUMBER_OF_GTX-1);
signal gt_err_ctr: slv32_array(0 to NUMBER_OF_GTX-1);
signal gt_capture_en: slv(0 to NUMBER_OF_GTX-1) := (others=>'0');
signal gt_capture_en_rxusrclk2: slv2_array(0 to NUMBER_OF_GTX-1);
signal gt_user_gttxreset: slv(0 to NUMBER_OF_GTX-1);
signal gt_user_gtrxreset: slv(0 to NUMBER_OF_GTX-1) := (others=>'0');
signal gt_user_reset: slv(0 to NUMBER_OF_GTX-1);

signal gt_rxdfelpmreset_in: slv(0 to NUMBER_OF_GTX-1) := (others=>'0');
signal gt_rxlpmen_in: slv(0 to NUMBER_OF_GTX-1) := (others => '0');
signal gt_rxlpmhold_in: slv2_array(0 to NUMBER_OF_GTX-1);
signal gt_rxlpmovrd_in: slv2_array(0 to NUMBER_OF_GTX-1);
signal gt_rxdfehold_in: slv9_array(0 to NUMBER_OF_GTX-1);
signal gt_rxdfeovrd_in: slv9_array(0 to NUMBER_OF_GTX-1);
signal gt_stop_bitslip: slv(0 to NUMBER_OF_GTX-1);

	attribute SHREG_EXTRACT of gt_capture_en_rxusrclk2 : signal is "no";
	attribute ASYNC_REG of gt_capture_en_rxusrclk2 : signal is "true";

-- User data interface
signal tx_data_int: slv32_array(0 to NUMBER_OF_GTX-1) := (others=> (others=>'0')); -- init for sim
signal tx_data_dly: slv32_array(0 to NUMBER_OF_GTX-1) := (others=> (others=>'0')); -- init for sim
signal tx_header_int: slv2_array(0 to NUMBER_OF_GTX-1) := (others=> (others=>'0')); -- init for sim
signal tx_ready_int: slv(0 to NUMBER_OF_GTX-1);

signal rx_data_capture: slv32_array(0 to NUMBER_OF_GTX-1);

signal tx_ctr: u16_array(0 to NUMBER_OF_GTX-1) := (others=> (others=>'0')); -- init for sim

signal tx_fsm_soft_reset: slv(0 to NUMBER_OF_GTX-1);
signal rx_fsm_soft_reset: slv(0 to NUMBER_OF_GTX-1);
signal block_sync_reset: slv(0 to NUMBER_OF_GTX-1);

begin
-- assign internal signals to output ports
txclk_div2 <= txclk_div2_int;
refclk_div2 <= refclk_div2_int;



ctrl_rst_proc: process(CTRL_CLK)
begin
	if rising_edge(CTRL_CLK) then
		ctrl_rst_reg <= (others => CTRL_RST);
	end if; --clk
end process;

---------------------------------------------------------------------
-- Instantiate the Command splitter
--! Routes the commands to the requested module
---------------------------------------------------------------------
--! Address format:
-- DRP:    xxxMMMMMxa1aaaaaaaaa (10 address bits, 512 words (0x000 - 1FF)
-- CONTROL:xxxMMMMMxx00aaaaaaaa
-- STATUS :xxxMMMMMxx01aaaaaaaa
CTRL_ROUTER0: entity work.CTRL_ROUTER
	generic map (
		NUMBER_OF_PORTS=> NUMBER_OF_MODULES,
		ADDRESS_MASK => "---11111-----------" --'1': used to generate port index, '-' = don't care,
	)
	port map(
		-- Master control interface
		CMD_IN_DAT=>CMD_DAT,
		CMD_IN_RDY=>CMD_RDY,
		RPLY_OUT_DAT=>RPLY_DAT,
		RPLY_OUT_RDY=>RPLY_RDY,


		CMD_OUT_DAT=> MODULE_CMD_DAT,
		CMD_OUT_RDY=> MODULE_CMD_RDY,
		RPLY_IN_DAT=> MODULE_RPLY_DAT,
		RPLY_IN_RDY=> MODULE_RPLY_RDY,

		CLK => CTRL_CLK,
		RST => CTRL_RST
	);




----------------------------------
-- MGT REFERENCE CLOCK BUFFERS
----------------------------------

-- We have up to NUMBER_OF_REFCLK reference clocks to clock the GTXes. These are physically assigned to pins so at least one can reach each of the QPLL used in the array.
-- Every refclk is received by a IBUFDS_GTE2
-- refclk[0] (aka clk156) is sent to a BUFG to be used as an always-on control logic clock and frequency monitor. The control logic can be spread across multiple clock regions.
-- refclk[1:n] are send to BUFH to be used only in the frequency monitor located in the bank where it arrives.

--! Instantiate reference clock buffers for each reference clock
ibuf_gen: for i in 0 to NUMBER_OF_REFCLK-1 generate
	ibufds0 : IBUFDS_GTE2
		-- generic map(
		-- 	CLKSWING_CFG => "11"
		-- 	)
		port map(
			I     => refclk_p(i),
			IB    => refclk_n(i),
			ODIV2 => open,
			CEB   => '0',
			O     => refclk_nobuf(i)
		);
end generate;


-- Instantiate BUFG for refclk[0] only
refclk_bufg0 : BUFG --
	port map(
		I => refclk_nobuf(0),
		O => refclk_buf(0)
	);
-- Instantiate BUFH for the other refclks
refclkbuf_gen: for i in 1 to NUMBER_OF_REFCLK-1 generate
	refclk_bufh0 : BUFH --
		port map(
			I => refclk_nobuf(i),
			O => refclk_buf(i)
		);
end generate;

clk156 <= refclk_buf(0);

-- Generate a logic signal that toggles at half the rate of the reference clock for the frequency counter
refclkdiv2_gen: for i in 0 to NUMBER_OF_REFCLK-1 generate
	refclkdiv2_proc: process(refclk_buf(i))
		begin
			if rising_edge(refclk_buf(i)) then
				refclk_div2_int(i) <=not refclk_div2_int(i);
			end if;
		end process;
end generate;

----------------------------------
-- REFERENCE CLOCK-BASED RESETS
----------------------------------




-- common signals
cdrlock_timeout:process(clk156)
  begin
    if rising_edge(clk156) then
        if(gt_gtrxreset_in(0) = '1') then
          rx_cdrlocked       <= '0';
          rx_cdrlock_counter <=  0;
        elsif (rx_cdrlock_counter = WAIT_TIME_CDRLOCK) then
          rx_cdrlocked       <= '1'; -- Used by RX startup FSM
          rx_cdrlock_counter <= rx_cdrlock_counter;
        else
          rx_cdrlock_counter <= rx_cdrlock_counter + 1;
        end if;
    end if;
  end process;


-----------------------------
-- Post configuration resets
-- Happens only once after config, and is nor affected by any other signal
-----------------------------
-- Hold off release the GT resets until 500ns after configuration.
-- 128 ticks at 6.4ns period will be >> 500 ns.

--! Reset counter process
--! Clear counter on areset, and increment until bit 7 = '1' otherwise
reset_ctr_proc: process (clk156)
	begin
		if rising_edge(clk156) then
			if common_user_reset='1' then
				reset_counter <= (others=>'0');
			elsif(reset_counter(7) = '0')  then
			   reset_counter <= reset_counter + 1;
			else
			   reset_counter <= reset_counter;
			end if;
		end if;
	end process;

--! Once the counter reaches its limit, generate a 3 refclk reset pulse
--! on gttxreset, gtrxreset and qpllreset
reset_pulse_proc: process (clk156)
	begin
	 if rising_edge(clk156) then
	   if(reset_counter(7) = '0' or common_user_reset='1')  then
	      reset_pulse <=  "1110";
	   else
	      reset_pulse(3)            <=  '0';
	      reset_pulse(2 downto 0)   <=  reset_pulse(3 downto 1);
	   end if;
	 end if;
	end process;
qpllreset  <=     reset_pulse(0); -- resets all QPLLs directly


---------------------------------
--! TXOUTCLK buffer
--! Buffer the TXOUTCLK generated by the first GTX to generate the txusrclk and txusrclk2 for ALL channels
--! There is only one per array since all transceivers are clocked by the same reference clock
--! Since the GTX is configured with a 4-byte external interface  and 4-byte internal data path, both txusrclk and txusrclk2 are at the same frequency.
---------------------------------
txoutclk_bufg0 : BUFG
	port map (
		I => gt_txoutclk_out(0), --txclk322_nobuf(0),
		O => txclk322
	);

txusrclk2 <= txclk322;
txusrclk <= txclk322;

common_slave0: entity work.CTRL_SLAVE
	GENERIC MAP (
		DEFAULT_CONTROL_BYTES=> X"00_FF2833" & repeat(X"00", NUMBER_OF_CONTROL_BYTES),
		NUMBER_OF_CONTROL_BYTES=>common_control_bytes'Length(1) , -- Number of bits in the control word
		NUMBER_OF_STATUS_BYTES=>common_status_bytes'Length(1) -- Number of bits in the status word.
	)
	PORT MAP(
		CTRL_CMD_IN_DAT=>   MODULE_CMD_DAT(0),
		CTRL_CMD_IN_RDY=>   MODULE_CMD_RDY(0),
		CTRL_RPLY_OUT_DAT=> MODULE_RPLY_DAT(0),
		CTRL_RPLY_OUT_RDY=> MODULE_RPLY_RDY(0),
		CTRL_CLK => CTRL_CLK,
		CTRL_RST => ctrl_rst_reg(0),
		CONTROL_BYTES => common_control_bytes,
		STATUS_BYTES => common_status_bytes
);

resetdone <= (and_reduce(tx_resetdone_int) or to_std_logic(NUMBER_OF_TX_LANES=0)) and (and_reduce(rx_resetdone_int) or to_std_logic(NUMBER_OF_RX_LANES=0)) after DLY;


-- CONTROL Byte 0
common_user_reset                <= common_control_bytes(0)(7);
-- common_block_lock_reset          <= common_control_bytes(0)(6);
-- common_scrambler_reset           <= common_control_bytes(0)(5);
-- common_unscrambler_reset         <= common_control_bytes(0)(4);
-- common_scramble_en               <= common_control_bytes(0)(3);
-- common_descramble_en             <= common_control_bytes(0)(2);
-- common_capture_en                <= common_control_bytes(0)(1);

-- CONTROL Byte 1-3
common_user_tx_data <= to_slv(common_control_bytes(1 to 3));

-- CONTROL Byte 4+
control_bytes <= slv8_array(common_control_bytes(4 to 4+NUMBER_OF_CONTROL_BYTES-1));


common_status_bytes(0)(7 downto 5) <= to_slv(NUMBER_OF_QUADS, 3);
common_status_bytes(0)(4 downto 0) <= to_slv(NUMBER_OF_GTX, 5);

common_status_bytes(1)(5) <= reset_pulse(0);
common_status_bytes(1)(4) <= resetdone;
common_status_bytes(1)(3) <= qpllreset;

-- common_status_bytes(3) <= to_slv(frame_counter);
-- common_status_bytes(4) <= to_slv(lsb(word_counter, 8));

common_status_bytes(2 to 2 + NUMBER_OF_STATUS_BYTES-1) <= slv8_array(status_bytes);


--------------------------------------
-- GTXE2_COMMON (QPLL)
--------------------------------------
--! Instantiates a GTXE2_COMMON (QPLL) block for each quad
--! The refeence clock use for each quad is specified in the QUAD_TO_REFCLK_MAP list.
quad_gen: for i in 0 to NUMBER_OF_QUADS-1 generate

	quad_slave0: entity work.CTRL_SLAVE
		GENERIC MAP (
			DEFAULT_CONTROL_BYTES=> X"00",
			USE_RAM_DOUT_RDY=>TRUE, -- need to wait for the RDY signal on RAM read accesses
			RAM_DATA_WIDTH=>16,
			RAM_ADDR_WIDTH=>8, -- GTX DRP Address bus is 8 bits
			NUMBER_OF_CONTROL_BYTES=>quad_control_bytes(i)'Length(1), -- Number of bits in the control word
			NUMBER_OF_STATUS_BYTES=>quad_status_bytes(i)'Length(1) -- Number of bits in the status word.
		)
		PORT MAP(
			CTRL_CMD_IN_DAT=>   MODULE_CMD_DAT(i+1),
			CTRL_CMD_IN_RDY=>   MODULE_CMD_RDY(i+1),
			CTRL_RPLY_OUT_DAT=> MODULE_RPLY_DAT(i+1),
			CTRL_RPLY_OUT_RDY=> MODULE_RPLY_RDY(i+1),
			CTRL_CLK => CTRL_CLK,
			CTRL_RST => ctrl_rst_reg(i+1),

			CONTROL_BYTES => quad_control_bytes(i),
			STATUS_BYTES => quad_status_bytes(i),

			-- DRP interface
			RAM_DIN      => quad_drp_din(i),
			RAM_DOUT     => quad_drp_dout(i),
			RAM_DOUT_RDY => quad_drp_drdy(i),
			RAM_WR_EN    => quad_drp_wr_en(i),
			RAM_EN       => quad_drp_den(i),
			RAM_ADDR     => quad_drp_addr(i)

			-- -- System
			-- RST => areset
	);

	quad_status_bytes(i)(0)(0) <= qplllock(i);


	gtxe2_common_0_i : GTXE2_COMMON
		generic map(
			-- Simulation attributes
			SIM_RESET_SPEEDUP    => "TRUE",
			SIM_QPLLREFCLK_SEL   => ("001"),
			SIM_VERSION          => "4.0",
			------------------COMMON BLOCK Attributes---------------
			BIAS_CFG                                =>     (x"0000040000001000"),
			COMMON_CFG                              =>     (x"00000000"),
			QPLL_CFG                                =>     to_bitvector(QPLL_CFG),
			QPLL_CLKOUT_CFG                         =>     ("0000"),
			QPLL_COARSE_FREQ_OVRD                   =>     ("010000"),
			QPLL_COARSE_FREQ_OVRD_EN                =>     ('0'),
			QPLL_CP                                 =>     ("0000011111"),
			QPLL_CP_MONITOR_EN                      =>     ('0'),
			QPLL_DMONITOR_SEL                       =>     ('0'),
			QPLL_FBDIV                              =>     to_bitvector(QPLL_FBDIV_IN),
			QPLL_FBDIV_MONITOR_EN                   =>     ('0'),
			QPLL_FBDIV_RATIO                        =>     to_bit(QPLL_FBDIV_RATIO),
			QPLL_INIT_CFG                           =>     (x"000006"),
			QPLL_LOCK_CFG                           =>     (x"21E8"),
			QPLL_LPF                                =>     ("1111"),
			QPLL_REFCLK_DIV                         =>     QPLL_REFCLK_DIV
			)
		port map (
			------------- Common Block  - Dynamic Reconfiguration Port (DRP) -----------
			DRPADDR                         =>      quad_drp_addr(i), --to_ground_vec_i(7 downto 0),
			DRPCLK                          =>      CTRL_CLK,
			DRPDI                           =>      quad_drp_din(i),
			DRPDO                           =>      quad_drp_dout(i),
			DRPEN                           =>      quad_drp_den(i),
			DRPRDY                          =>      quad_drp_drdy(i),
			DRPWE                           =>      quad_drp_wr_en(i),
			---------------------- Common Block  - Ref Clock Ports ---------------------
			GTGREFCLK                       =>      '0',
			GTNORTHREFCLK0                  =>      '0',
			GTNORTHREFCLK1                  =>      '0',
			GTREFCLK0                       =>      refclk_nobuf(QUAD_TO_REFCLK_MAP(i)),
			GTREFCLK1                       =>      '0',
			GTSOUTHREFCLK0                  =>      '0',
			GTSOUTHREFCLK1                  =>      '0',
			------------------------- Common Block - QPLL Ports ------------------------
			QPLLDMONITOR                    =>      open,
			QPLLFBCLKLOST                   =>      open,
			QPLLLOCK                        =>      qplllock(i),
			QPLLLOCKDETCLK                  =>      '0',
			QPLLLOCKEN                      =>      '1',
			QPLLOUTCLK                      =>      qplloutclk(i),
			QPLLOUTREFCLK                   =>      qplloutrefclk(i),
			QPLLOUTRESET                    =>      '0',
			QPLLPD                          =>      '0',
			QPLLREFCLKLOST                  =>      open,
			QPLLREFCLKSEL                   =>      "001",
			QPLLRESET                       =>      qpllreset, -- input
			QPLLRSVD1                       =>      "0000000000000000",
			QPLLRSVD2                       =>      "11111",
			REFCLKOUTMONITOR                =>      open,
			----------------------------- Common Block Ports ---------------------------
			BGBYPASSB                       =>      '1',
			BGMONITORENB                    =>      '1',
			BGPDB                           =>      '1',
			BGRCALOVRD                      =>      "00000",
			PMARSVD                         =>      "00000000",
			RCALENB                         =>      '1'
		);

end generate;


gtx_gen: for i in 0 to NUMBER_OF_GTX-1 generate

	gt_slave0: entity work.CTRL_SLAVE
		GENERIC MAP (
			DEFAULT_CONTROL_BYTES=>
				X"00_00_01_40_00_00",
			USE_RAM_DOUT_RDY=>TRUE, -- need to wait for the RDY signal on RAM read accesses
			RAM_DATA_WIDTH=>16,
			RAM_ADDR_WIDTH=>9, -- GTX DRP Address bus is 9 bits, we use 10 bits of address in the memory-mapepd interface since we access bytes
			NUMBER_OF_CONTROL_BYTES=>gt_control_bytes(i)'Length(1), -- Number of bits in the control word
			NUMBER_OF_STATUS_BYTES=>gt_status_bytes(i)'Length(1) -- Number of bits in the status word.
	  	)
		PORT MAP(
			CTRL_CMD_IN_DAT=>   MODULE_CMD_DAT(i+NUMBER_OF_QUADS+1),
			CTRL_CMD_IN_RDY=>   MODULE_CMD_RDY(i+NUMBER_OF_QUADS+1),
			CTRL_RPLY_OUT_DAT=> MODULE_RPLY_DAT(i+NUMBER_OF_QUADS+1),
			CTRL_RPLY_OUT_RDY=> MODULE_RPLY_RDY(i+NUMBER_OF_QUADS+1),
			CTRL_CLK => CTRL_CLK,
			CTRL_RST => ctrl_rst_reg(i+NUMBER_OF_QUADS+1),

			CONTROL_BYTES => gt_control_bytes(i),
			STATUS_BYTES => gt_status_bytes(i),
			-- DRP interface
			RAM_DIN      => gt_drp_din(i),
			RAM_DOUT     => gt_drp_dout(i),
			RAM_DOUT_RDY => gt_drp_rdy(i),
			RAM_WR_EN    => gt_drp_wr_en(i),
			RAM_EN       => gt_drp_en(i),
			RAM_ADDR     => gt_drp_addr(i)
			-- System
		);

	-- TX CONTROL Bytes
	--------------------

	-- CONTROL Byte 0
	gt_user_reset(i)                <= gt_control_bytes(i)(0)(7);
	gt_user_gttxreset(i)            <= gt_control_bytes(i)(0)(6);
	gt_txinhibit_in(i)              <= gt_control_bytes(i)(0)(5);
	gt_txpostcursor_in(i)           <= gt_control_bytes(i)(0)(4 downto 0);

	-- CONTROL Byte 1
	gt_txdiffctrl_in(i)             <= gt_control_bytes(i)(1)(7 downto 4);
	gt_loopback_in(i)               <= gt_control_bytes(i)(1)(2 downto 0); -- '000' = normal operation

	-- CONTROL Byte 2
	gt_user_source_sel(i)           <= gt_control_bytes(i)(2)(7);
	gt_txprecursor_in(i)            <= gt_control_bytes(i)(2)(6 downto 2);
	gt_user_tx_header(i)            <= gt_control_bytes(i)(2)(1 downto 0);

	-- CONTROL Byte 3
	gt_user_tx_data(i)(7 downto 0)  <= gt_control_bytes(i)(3);
	gt_user_tx_data(i)(31 downto 8) <= common_user_tx_data;


	-- CONTROL Byte 4

	gt_rxdfelpmreset_in(i)  <= gt_control_bytes(i)(4)(7); -- needed for link tests
	gt_user_gtrxreset(i)    <= gt_control_bytes(i)(4)(6); -- may be needed for link tests
	gt_rxlpmen_in(i)        <= gt_control_bytes(i)(4)(5); -- may be needed for link tests
	gt_rxmonitorsel_in(i)   <= gt_control_bytes(i)(4)(4 downto 3); -- may be needed for link tests (if so, will need to make rxmonitor status available)
	gt_capture_en(i)        <= gt_control_bytes(i)(4)(2);
	gt_block_lock_reset(i)  <= gt_control_bytes(i)(4)(1); -- could be global, but routing is easier if it is local

	-- CONTROL Byte 5

	gt_rxprbscntreset_in(i) <= gt_control_bytes(i)(5)(7); -- needed for link tests
	gt_txprbsforceerr_in(i) <= gt_control_bytes(i)(5)(6); -- needed for link tests
	gt_txprbssel_in(i)      <= gt_control_bytes(i)(5)(5 downto 3); -- needed for link tests
	gt_rxprbssel_in(i)      <= gt_control_bytes(i)(5)(2 downto 0); -- needed for link tests

	-- Common CONTROL bytes

	-- gt_scrambler_reset(i)   <= common_scrambler_reset;
	-- gt_unscrambler_reset(i) <= common_unscrambler_reset;
	-- gt_scramble_en(i)       <= common_scramble_en;
	-- gt_descramble_en(i)     <= common_descramble_en;

	-- Constant control signals

	gt_scrambler_reset(i)   <= '0';
	gt_unscrambler_reset(i) <= '0';
	gt_scramble_en(i)       <= '1';
	gt_descramble_en(i)     <= '1';

	gt_txpolarity_in(i)            <= '0';
	gt_rxpolarity_in(i)            <= '0';
	gt_stop_bitslip(i)             <= '0';--optional
	gt_rxlpmhold_in(i)(1 downto 0) <= "00";--optional
	gt_rxdfehold_in(i)(8)          <= '0';--optional
	gt_rxdfehold_in(i)(7 downto 0) <= "00000000";--optional
	gt_rxlpmovrd_in(i)(1 downto 0) <= "00";--optional
	gt_rxdfeovrd_in(i)(8)          <= '0';--optional
	gt_rxdfeovrd_in(i)(7 downto 0) <= "00000000";--optional
	gt_rxcdrhold_in(i)             <= '0';--optional

	-- TX STATUS BYTES
	------------------

	-- STATUS BYTE 0
	gt_status_bytes(i)(0)(7) <= gt_txresetdone_out(i);
	gt_status_bytes(i)(0)(6) <= gt_rxresetdone_out(i);
	gt_status_bytes(i)(0)(5 downto 4) <= gt_txbufstatus_out(i);
	gt_status_bytes(i)(0)(3) <= tx_resetdone_int(i);
	gt_status_bytes(i)(0)(2) <= rx_resetdone_int(i);
	gt_status_bytes(i)(0)(1) <= gt_block_lock(i);
	gt_status_bytes(i)(0)(0) <= to_std_logic(NUMBER_OF_RX_LANES > 0); -- Indicates if RX part is present


	-- STATUS BYTE 1-4
	gt_status_bytes(i)(1 to 4) <= to_slv8_array(gt_err_ctr(i)); -- needed for link tests

	-- RX STATUS BYTES
	--------------------
	rxstatus_gen: if NUMBER_OF_RX_LANES>0 generate
	-- STATUS BYTE 5
		gt_status_bytes(i)(5)(7 downto 6) <= gt_rxheader_capture(i);
		gt_status_bytes(i)(5)(2 downto 0) <= gt_rxbufstatus_out(i);

		-- STATUS BYTE 6
		gt_status_bytes(i)(6)(6 downto 0) <= gt_rxmonitorout_out(i); -- Needed for link tests?

		-- STATUS BYTE 7-10
		gt_status_bytes(i)(7 to 10) <= to_slv8_array(rx_data_capture(i));
		-- STATUS BYTE 11
		gt_status_bytes(i)(11) <= gt_dmonitorout_out(i); -- Always needed? state of the receiver LPM and DFE mode adaptation loops, such as the adapted continuous time linear equalizer (CTLE) gains and DFE taps
	end generate;
-- Unused status signals
	-- gt_status_bytes(i)(6)(0) <= gt_txuserrdy_in(i);
	-- gt_status_bytes(i)(6)(3) <= rx_cdrlocked; --optional
	-- gt_status_bytes(i)(6)(4) <= gt_gttxreset_in(i); --optional
	-- gt_status_bytes(i)(6)(5) <= gt_rxuserrdy_in(i);
	-- gt_status_bytes(i)(7)(2) <= gt_rxdatavalid_out(i); --optional
	-- gt_status_bytes(i)(7)(4) <= gt_rxgearboxslip_in(i); --optional
	-- gt_status_bytes(i)(7)(5) <= gt_rxheadervalid_out(i); --optional
	-- gt_status_bytes(i)(7)(6) <= gt_gtrxreset_in(i); --optional
	-- gt_status_bytes(i)(13)(6 downto 0) <= gt_txsequence_in(i);--optional
	-- gt_status_bytes(i)(5)(0) <= gt_rxprbserr_out(i);


gt_gtrxreset_all(i) <= gt_gtrxreset_in(i) or gt_user_gtrxreset(i);
gt_gttxreset_all(i) <= gt_gttxreset_in(i) or gt_user_gttxreset(i);


gtx_i : entity work.xglink_gtx
	generic map (
		-- Simulation attributes
		GT_SIM_GTRESET_SPEEDUP        =>  EXAMPLE_SIM_GTRESET_SPEEDUP,
		RX_DFE_KL_CFG2_IN             =>  X"301148AC",
		PMA_RSV_IN                    =>  x"001E7080",
		PCS_RSVD_ATTR_IN              =>  X"000000000000"
	)
	port map (
		---------------------------- Channel - DRP Ports  --------------------------
		drpaddr_in                      =>      gt_drp_addr(i),
		drpclk_in                       =>      CTRL_CLK,
		drpdi_in                        =>      gt_drp_din(i),
		drpdo_out                       =>      gt_drp_dout(i),
		drpen_in                        =>      gt_drp_en(i),
		drprdy_out                      =>      gt_drp_rdy(i),
		drpwe_in                        =>      gt_drp_wr_en(i),
		------------------------------- Clocking Ports -----------------------------
		qpllclk_in                      =>      qplloutclk(LANE_TO_QUAD_MAP(i)),
		qpllrefclk_in                   =>      qplloutrefclk(LANE_TO_QUAD_MAP(i)),
		------------------------------- Loopback Ports -----------------------------
		loopback_in                     =>      gt_loopback_in(i),
		----------------------------- PCI Express Ports ----------------------------
		rxrate_in                       =>      (others => '0'),
		-------------------------- RX Margin Analysis Ports ------------------------
		eyescanreset_in                 =>      '0',
		eyescandataerror_out            =>      open,
		eyescantrigger_in               =>      '0',
		------------------------- Receive Ports - CDR Ports ------------------------
		rxcdrhold_in                    =>      gt_rxcdrhold_in(i),
		------------------ Receive Ports - FPGA RX Interface Ports -----------------
		rxusrclk_in                     =>      rxusrclk(i),
		rxusrclk2_in                    =>      rxusrclk2(i),
		------------------ Receive Ports - FPGA RX interface Ports -----------------
		rxdata_out                      =>      gt_rxdata_out(i),
		------------------- Receive Ports - Pattern Checker Ports ------------------
		rxprbserr_out                   =>      gt_rxprbserr_out(i),
		rxprbssel_in                    =>      gt_rxprbssel_in(i),
		rxprbscntreset_in               =>      gt_rxprbscntreset_in(i),
		--------------------------- Receive Ports - RX Analog Front End (AFE) ------
		gtxrxp_in                       =>      rx_p(i),
		gtxrxn_in                       =>      rx_n(i),

		------------------- Receive Ports - RX Buffer Bypass Ports -----------------
		rxbufreset_in                   =>      '0',
		rxbufstatus_out                 =>      gt_rxbufstatus_out(i),
		--------------------- Receive Ports - RX Equalizer Ports -------------------
		rxlpmen_in                      =>      gt_rxlpmen_in(i),
		rxdfelpmreset_in                =>      gt_rxdfelpmreset_in(i),
		rxmonitorout_out                =>      gt_rxmonitorout_out(i),
		rxmonitorsel_in                 =>      gt_rxmonitorsel_in(i),
		dmonitorout_out                 =>      gt_dmonitorout_out(i),

		rxlpmhold_in                    =>     gt_rxlpmhold_in(i),
		rxlpmovrd_in                    =>     gt_rxlpmovrd_in(i),
		rxdfehold_in(0)                 =>     gt_rxdfeagchold_in(i), -- AGC Hold ( was: gt_rxdfehold_in(i)(0) or gt_rxdfeagchold_in(i))
		rxdfehold_in(1)                 =>     gt_rxdfelfhold_in(i), --LF Hold (was: gt_rxdfehold_in(i)(1) or gt_rxdfelfhold_in(i))
		rxdfehold_in(8 downto 2)        =>     gt_rxdfehold_in(i)(8 downto 2),
		rxdfeovrd_in                    =>     gt_rxdfeovrd_in(i),
		------------ Receive Ports - RX Fabric ClocK Output Control Ports ----------
		rxratedone_out                  =>      open,
		--------------- Receive Ports - RX Fabric Output Control Ports -------------
		rxoutclk_out                    =>      gt_rxoutclk_out(i),
		---------------------- Receive Ports - RX Gearbox Ports --------------------
		rxdatavalid_out                 =>      gt_rxdatavalid_out(i),
		rxheader_out                    =>      gt_rxheader_out(i),
		rxheadervalid_out               =>      gt_rxheadervalid_out(i),
		rxstartofseq_out                =>      gt_rxstartofseq_out(i),
		rxgearboxslip_in                =>      gt_rxgearboxslip_in(i), -- (was: gt_rxgearboxslip_in(i) and (not gt_stop_bitslip(i)))
		------------- Receive Ports - RX Initialization and Reset Ports ------------
		rxuserrdy_in                    =>      gt_rxuserrdy_in(i), --? Was '0' on core: prevents RXRESETDONE to go high?
		gtrxreset_in                    =>      gt_gtrxreset_all(i),
		rxpcsreset_in                   =>      '0',
		rxpmareset_in                   =>      '0',
		rxresetdone_out                 =>      gt_rxresetdone_out(i),
		---------------- Receive Ports - RX Polarity Control Ports ----------------
		rxpolarity_in                   =>      gt_rxpolarity_in(i),
		------------------- Receive Ports - RX8B/10B Decoder Ports -----------------
		rxcharisk_out                   =>      open,

		------------------------ TX Configurable Driver Ports ----------------------
		txpostcursor_in                 =>      gt_txpostcursor_in(i),
		txprecursor_in                  =>      gt_txprecursor_in(i),
		--------------------- TX Initialization and Reset Ports --------------------
		gttxreset_in                    =>      gt_gttxreset_all(i),
		txuserrdy_in                    =>      gt_txuserrdy_in(i),
		------------------ Transmit Ports - FPGA TX Interface Ports ----------------
		txusrclk_in                     =>      txusrclk,
		txusrclk2_in                    =>      txusrclk2,
		------------------ Transmit Ports - Pattern Generator Ports ----------------
		txprbsforceerr_in               =>      gt_txprbsforceerr_in(i),
		---------------------- Transmit Ports - TX Buffer Ports --------------------
		txbufstatus_out                 =>      gt_txbufstatus_out(i),
		--------------- Transmit Ports - TX Configurable Driver Ports --------------
		txdiffctrl_in                   =>      gt_txdiffctrl_in(i),
		txinhibit_in                    =>      gt_txinhibit_in(i),
		txmaincursor_in                 =>      "0000000", -- controllable through DRP
		------------------ Transmit Ports - TX Data Path interface -----------------
		txdata_in                       =>      gt_txdata_in(i),
		---------------- Transmit Ports - TX Driver and OOB signaling --------------
		gtxtxn_out                      =>      tx_n(i),
		gtxtxp_out                      =>      tx_p(i),
		----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
		txoutclk_out                    =>      gt_txoutclk_out(i),
		txoutclkfabric_out              =>      open,
		txoutclkpcs_out                 =>      open,
		--------------------- Transmit Ports - TX Gearbox Ports --------------------
		txheader_in                     =>      gt_txheader_in(i),
		txsequence_in                   =>      gt_txsequence_in(i),
		------------- Transmit Ports - TX Initialization and Reset Ports -----------
		txpcsreset_in                   =>      '0',
		txpmareset_in                   =>      '0',
		txresetdone_out                 =>      gt_txresetdone_out(i),
		----------------- Transmit Ports - TX Polarity Control Ports ---------------
		txpolarity_in                   =>      gt_txpolarity_in(i),
		------------------ Transmit Ports - pattern Generator Ports ----------------
		txprbssel_in                    =>      gt_txprbssel_in(i)
	);

-----------------------------------------------
-- Minimum RX logic needed to operate BER tests
-----------------------------------------------

-- Implement RX clock buffer for local logic
rxoutclk_bufg0 : BUFH
	port map (
		I => gt_rxoutclk_out(i),
		O => rxclk322(i)
	);
rxusrclk2(i) <= rxclk322(i);
rxusrclk(i) <= rxclk322(i);

rx_fsm_soft_reset(i) <= common_user_reset or gt_user_reset(i);
------------------------------------------------
-- GTX Starttup state machine
------------------------------------------------
	gt_rxresetfsm_i: entity work.xglink_rx_startup_fsm
		generic map(
			EXAMPLE_SIMULATION       => EXAMPLE_SIMULATION,
			GT_TYPE                  => "GTX", --GTX or GTH or GTP
			EQ_MODE                  => "DFE",                 --Rx Equalization Mode - Set to DFE or LPM
			STABLE_CLOCK_PERIOD      => STABLE_CLOCK_PERIOD,           --Period of the stable clock driving this state-machine, unit is [ns]
			RETRY_COUNTER_BITWIDTH   => 8,
			TX_QPLL_USED             => TRUE ,                        -- the TX and RX Reset FSMs must
			RX_QPLL_USED             => TRUE,                         -- share these two generic values
			PHASE_ALIGNMENT_MANUAL   =>  FALSE                        -- Decision if a manual phase-alignment is necessary or the automatic
			                                                          -- is enough. For single-lane applications the automatic alignment is
			                                                          -- sufficient
			)
		port map (
			STABLE_CLOCK                    =>      clk156,
			RXUSERCLK                       =>      rxusrclk2(i),
			SOFT_RESET                      =>      rx_fsm_soft_reset(i),
			DONT_RESET_ON_DATA_ERROR        =>      DONT_RESET_ON_DATA_ERROR_IN,
			QPLLREFCLKLOST                  =>      '0', --GT_QPLLREFCLKLOST_IN(i),
			CPLLREFCLKLOST                  =>      '0',
			QPLLLOCK                        =>      qplllock(LANE_TO_QUAD_MAP(i)),
			CPLLLOCK                        =>      '1',
			RXRESETDONE                     =>      gt_rxresetdone_out(i), --ok
			MMCM_LOCK                       =>      '1',
			RECCLK_STABLE                   =>      rx_cdrlocked,
			RECCLK_MONITOR_RESTART          =>      '0',
			DATA_VALID                      =>      '1', --GT_DATA_VALID_IN(i),
			TXUSERRDY                       =>      '1',
			GTRXRESET                       =>      gt_gtrxreset_in(i),
			MMCM_RESET                      =>      open,
			QPLL_RESET                      =>      open,
			CPLL_RESET                      =>      open,
			RX_FSM_RESET_DONE               =>      rx_resetdone_int(i),
			RXUSERRDY                       =>      gt_rxuserrdy_in(i),
			RUN_PHALIGNMENT                 =>      open,
			RESET_PHALIGNMENT               =>      open,
			PHALIGNMENT_DONE                =>      '1',
			RXDFEAGCHOLD                    =>      gt_rxdfeagchold_in(i),
			RXDFELFHOLD                     =>      gt_rxdfelfhold_in(i),
			RXLPMLFHOLD                     =>      open, --gt_rxlpmlfhold_in(i),
			RXLPMHFHOLD                     =>      open, --gt_rxlpmhfhold_in(i),
			RETRY_COUNTER                   =>      open
			);




------------------------------------------------
-- RX PRBS Error Counter
------------------------------------------------
-- We need RX error counters for every GTX to perform link tests.

	process(rxusrclk2(i))
	begin
		if rising_edge(rxusrclk2(i)) then
			if gt_rxprbscntreset_in(i)='1' then
			     gt_err_ctr(i) <= (others => '0');
			elsif gt_rxprbserr_out(i)='1' and signed(gt_err_ctr(i)) /= -1 then
			     gt_err_ctr(i) <= std_logic_vector(unsigned(gt_err_ctr(i)) + 1);
			end if;
		end if;
	end process;

end generate; -- for number of GTX



----------------------------------------------
-- Global TX Clock
----------------------------------------------

tx_clk <= txusrclk2;

-- Generate a logic signal that toggles at half the rate of the tx clock for the frequency counter
txclkdiv2_proc: process(txusrclk2)
	begin
		if rising_edge(txusrclk2) then
			txclk_div2_int <= not txclk_div2_int;
			gt_user_tx_data_int <= gt_user_tx_data; -- Pipeline signals from SLAVEs. Keep it out of gtx_gen[] to allow free placement.
		end if;
	end process;


----------------------------------------------
-- TX Data Logic
----------------------------------------------
tx_gen: for i in  0 to NUMBER_OF_TX_LANES-1 generate

	tx_fsm_soft_reset(i) <= common_user_reset or gt_user_reset(i);

	gt_txresetfsm: entity work.xglink_tx_startup_fsm
		generic map(
			STABLE_CLOCK_PERIOD      => STABLE_CLOCK_PERIOD,           -- Period of the stable clock driving this state-machine, unit is [ns]
			RETRY_COUNTER_BITWIDTH   => 8,
			TX_QPLL_USED             => TRUE ,                        -- the TX and RX Reset FSMs must
			RX_QPLL_USED             => TRUE,                         -- share these two generic values
			PHASE_ALIGNMENT_MANUAL   => FALSE                 -- Decision if a manual phase-alignment is necessary or the automatic
			                                                         -- is enough. For single-lane applications the automatic alignment is
			                                                         -- sufficient
			)
	port map (
		STABLE_CLOCK                    =>      clk156,
		TXUSERCLK                       =>      txusrclk2,
		SOFT_RESET                      =>      tx_fsm_soft_reset(i),
		QPLLREFCLKLOST                  =>      '0', -- GT_QPLLREFCLKLOST_IN(i),
		CPLLREFCLKLOST                  =>      '0',
		QPLLLOCK                        =>      qplllock(LANE_TO_QUAD_MAP(i)),
		CPLLLOCK                        =>      '1',
		TXRESETDONE                     =>      gt_txresetdone_out(i), --ok
		MMCM_LOCK                       =>      '1',
		GTTXRESET                       =>      gt_gttxreset_in(i), --ok
		MMCM_RESET                      =>      open,
		QPLL_RESET                      =>      open, --gt_qpllreset_t(i),
		CPLL_RESET                      =>      open,
		TX_FSM_RESET_DONE               =>      tx_resetdone_int(i),
		TXUSERRDY                       =>      gt_txuserrdy_in(i),
		RUN_PHALIGNMENT                 =>      open,
		RESET_PHALIGNMENT               =>      open,
		PHALIGNMENT_DONE                =>      '1',
		RETRY_COUNTER                   =>      open
		);



	------------------------------------
	-- TX Gearbox Sequence counter
	------------------------------------
	-- The Gearbox counter is incremented for every 64-bit word, i.e. every two txusrclk2.
	-- The counter counts from 0 to 32 (not 31)
	-- The GTX does not take data when the counter is 32 (tready=0), i.e new data should be clocked in only when tready=1

	-- seq_ctr  txsequence                      tx_ready_int              scrambler din     scrambler dout     gtx use value
	--                                          scrambler valid in                        gtx data in
	-- 00        00            1                1                           a
	-- ...                     1                1                           b    78            a                    y
	-- 62        31            0                1                           c    55            b     78             y
	-- 63        31            0                0                           x                  c 31  55             y
	-- 64        32            1                0                           x                  c 32  78             n
	-- 65        32            1                1                           d                  c 32  55             n
	-- 00        00            1                1                           e                  d 00  78             y
	-- 01        00            1                1                           f                  e     55             y

	gt_txsequence_in(i)(6) <= '0';
	gt_txsequence_in(i)(5 downto 0) <= gt_seq_counter(i)(6 downto 1);

	process(txusrclk2)
	begin
		if rising_edge(txusrclk2) then
			if tx_resetdone_int(i)='0' or unsigned(gt_seq_counter(i)) = 65 then
			     gt_seq_counter(i) <= (others => '0');
			else
			     gt_seq_counter(i) <= std_logic_vector(unsigned(gt_seq_counter(i)) + 1);
			end if;
			if unsigned(gt_txsequence_in(i))=31 then
				tx_ready_int(i) <= '0';
				tx_ready(i) <= '0' after DLY; -- delay needed to ensure proper evaluation order of outside modules since tx_clk is generated by assignment
			else
				tx_ready_int(i) <= '1';
				tx_ready(i) <= '1' after DLY;
			end if;
		end if;
	end process;



	tx_resetdone(i) <= tx_resetdone_int(i) after DLY;

	txproc: process(txusrclk2)
	begin
		if rising_edge(txusrclk2) then

			if tx_ready_int(i) = '1' then

				tx_data_dly(i) <= tx_data(i);
				gt_txheader_in(i) <= tx_header_int(i);

				if gt_user_source_sel(i)='1' then
					tx_data_int(i) <= gt_user_tx_data_int(i);
					tx_header_int(i) <= gt_user_tx_header(i);
				else
					tx_data_int(i) <= reverse_bytes(tx_data_dly(i));
					tx_header_int(i) <= tx_header(i);
				end if;

			end if; -- tx_ready_int='1'

		end if; --clk
	end process;


	------------------------------------------------
	-- SCRAMBLER
	------------------------------------------------


	gt_txdata_in(i) <= reverse_bits_same_dir(gt_txdata_i(i)) when gt_scramble_en(i)='1' else reverse_bits_same_dir(tx_data_int(i)); -- first bit transmitted is in the MSB
	scrambler_reset(i) <= not tx_resetdone_int(i) or gt_scrambler_reset(i);

	scrambler0: entity work.xglink_scrambler
		generic map (
			TX_DATA_WIDTH       =>     32
			)
		port map (
			-- User Interface
			UNSCRAMBLED_DATA_IN =>     tx_data_int(i), -- first bit transmitted is in the LSB
			SCRAMBLED_DATA_OUT  =>     gt_txdata_i(i), -- first bit transmitted is in the LSB
			DATA_VALID_IN       =>     tx_ready_int(i),

			-- System Interface
			USER_CLK            =>     txusrclk2,
			SYSTEM_RESET        => scrambler_reset(i)
	    );

end generate; -- for NUMBER_OF_TX_LANES



----------------------------------------------
-- RX Data Logic
----------------------------------------------
rx_gen: for i in  0 to NUMBER_OF_RX_LANES-1 generate

	rx_clk(i) <= rxusrclk2(i); --! Danger Will Robinson! In sims, the clock assignment might be evaluated AFTER the output signals are evaluated, causing the data to appear on the wrong clock. That's why we have a DLY for each output purt assignments.


	------------------------------------------------
	-- RX BLOCK SYNCHRONIZATION
	------------------------------------------------
	block_sync_reset(i) <= not gt_rxresetdone_out(i) or gt_block_lock_reset(i);

	block_sync0 :  entity work.xglink_block_sync
		generic map
		(
		    SH_CNT_MAX          => 64,
		    SH_INVALID_CNT_MAX  => 16
		)
		port map
		(
			-- User Interface
			BLOCKSYNC_OUT             =>    gt_block_lock(i),
			RXGEARBOXSLIP_OUT         =>    gt_rxgearboxslip_in(i),
			RXHEADER_IN(2)            =>    '0',
			RXHEADER_IN(1 downto 0)   =>    gt_rxheader_out(i),
			RXHEADERVALID_IN          =>    gt_rxheadervalid_out(i),

			-- System Interface
			USER_CLK                  =>    rxusrclk2(i),
			SYSTEM_RESET              => block_sync_reset(i)
		);

	------------------------------------------------
	-- RX DESCRAMBLER
	------------------------------------------------

		-- Capture descrambled or unscambled data when valid and capture=1
	process(rxusrclk2(i))
	begin
	      if rising_edge(rxusrclk2(i)) then
			gt_capture_en_rxusrclk2(i)(1) <=gt_capture_en(i);
			gt_capture_en_rxusrclk2(i)(0) <=gt_capture_en_rxusrclk2(i)(1);
			gt_unscrambled_data_valid(i) <= gt_rxdatavalid_out(i);
			-- gt_rxheader_valid_dly(i) <= gt_rxheadervalid_out(i);

			rx_header_valid(i) <= gt_rxheadervalid_out(i) after DLY;
			if gt_rxheadervalid_out(i)='1' then
				rx_header(i) <= gt_rxheader_out(i) after DLY;
			end if;
			if gt_capture_en_rxusrclk2(i)(0)='1' then
				if gt_descramble_en(i)='0' and gt_rxdatavalid_out(i)='1' then
					rx_data_capture(i) <= reverse_bits_same_dir(gt_rxdata_out(i));
				elsif gt_descramble_en(i)='1' and gt_unscrambled_data_valid(i)='1' then
					rx_data_capture(i) <= gt_unscrambled_data(i);
				end if;
				if gt_rxheadervalid_out(i)='1' then
					gt_rxheader_capture(i) <= gt_rxheader_out(i);
				end if;
			end if;

			if rx_resetdone_int(i)='0' then -- Added reset to try to prevent spurious sends after reset
				rx_header(i) <="00";
			end if;

	      end if; -- clk
	end process;

	rx_data(i) <= reverse_bytes(gt_unscrambled_data(i)) after DLY; -- first byte received is in bits 31-24 (MSB-LSB)
	rx_data_valid(i) <= gt_unscrambled_data_valid(i) after DLY;
	-- rx_header(i) <= gt_rxheader_capture(i);
	-- rx_header_valid(i) <= gt_rxheader_capture_valid(i);
	rx_resetdone(i) <= rx_resetdone_int(i) after DLY;


	-- Descramble
	descrambler0  :  entity work.xglink_descrambler
	    generic map
	    (
			RX_DATA_WIDTH         =>     32
	    )
	    port map
	    (
	        -- User Interface
	        SCRAMBLED_DATA_IN     =>     reverse_bits_same_dir(gt_rxdata_out(i)), -- first bit received is in the LSB
	        DATA_VALID_IN         =>     gt_rxdatavalid_out(i),
	        UNSCRAMBLED_DATA_OUT  =>     gt_unscrambled_data(i), -- first bit received is in the LSB

	        -- System Interface
	        USER_CLK              =>     rxusrclk2(i),
	        SYSTEM_RESET          =>     gt_unscrambler_reset(i) or not gt_block_lock(i)
	    );
end generate; -- if RX in implemented


end Behavioral;
