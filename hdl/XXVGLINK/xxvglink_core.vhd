----------------------------------------------------------------------------------
-- Company:  McGill University
-- Engineer: JF Cliche
--
-- Create Date: 2025-01-22
-- Design Name: chFPGA
-- Module Name: xxvglink_core
-- Project Name: CHORD
-- Target Devices: Kintex 7
-- Tool Versions: Vivado 2022.2
-- Description: Implements an array of GTY
------------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_misc.ALL; -- for reduce functions

library UNISIM;
use UNISIM.VComponents.all;

library work;
use work.chFPGA_Package.all;


entity xxvglink_core is
	generic (
		LINK_TO_QUAD_MAP            : integer_array := (0 to 1=>0, 2 => 1); --! LINK_TO_QUAD_MAP Indicates which quad is associated each channel. The QUAD number is an integer between 0 and N-1, where N is the total number of quads used.
		QUAD_TO_REFCLK_MAP          : integer_array := (0,0); --! QUAD_TO_REFCLK_MAP Indicates which refclk is associated with each QUAD (N integers from 0 to NUMBER_OF_REFCLK-1).
		IMPLEMENT_TX                : boolean := TRUE;
		IMPLEMENT_RX                : boolean := TRUE;
		DONT_RESET_ON_DATA_ERROR_IN : std_logic := '0';
		NUMBER_OF_CONTROL_BYTES     : integer :=0; -- Number of additional control bytes to be appended to the common control register array
		NUMBER_OF_STATUS_BYTES      : integer :=0; -- Number of additional status bytes to be appended to the common status register array

		-- Derived parameters
		NUMBER_OF_REFCLK   : integer := max(QUAD_TO_REFCLK_MAP) + 1;
		NUMBER_OF_RX_LINKS : integer := sel(IMPLEMENT_RX, LINK_TO_QUAD_MAP'LENGTH, 0);
		NUMBER_OF_TX_LINKS : integer := sel(IMPLEMENT_TX, LINK_TO_QUAD_MAP'LENGTH, 0);
		NUMBER_OF_GT       : integer := max(NUMBER_OF_RX_LINKS, NUMBER_OF_TX_LINKS); -- computed value - do not override

		-- Simulation parameters
		EXAMPLE_SIMULATION          : integer :=1;
		EXAMPLE_SIM_GTRESET_SPEEDUP : string := "TRUE";    -- simulation setting for GT SecureIP model
		SIM                         : boolean := false
		);
	port (
		tx_p     : out std_logic_vector(0 to NUMBER_OF_GT-1);
		tx_n     : out std_logic_vector(0 to NUMBER_OF_GT-1);
		rx_p     : in std_logic_vector(0 to NUMBER_OF_GT-1);
		rx_n     : in std_logic_vector(0 to NUMBER_OF_GT-1);
		refclk_p : in std_logic_vector(0 to NUMBER_OF_REFCLK-1); --156.250 high quality reference clocks to feed all the quads in the array. One reference clock can feed the bank it is  on, and the banks above and below.
		refclk_n : in std_logic_vector(0 to NUMBER_OF_REFCLK-1);

		refclk_div2 : out std_logic_vector(0 to NUMBER_OF_REFCLK-1); -- 156.25 MHz reference clock
		txclk_div2  : out std_logic; -- Data clock generated from MMCM

		tx_data      : in slv64_array(0 to NUMBER_OF_TX_LINKS-1); --! The most significant byte is transmitted first
		tx_header    : in slv2_array(0 to NUMBER_OF_TX_LINKS-1);
		tx_ready     : out std_logic_vector(0 to NUMBER_OF_TX_LINKS-1); --! Indicates when the transmitter will accept the data on the data bus
		tx_clk       : out std_logic; -- 244.140625 MHz for LINK_SPEED=0, 322.265615 MHz for LINK_SPEED=1.
		tx_resetdone : out std_logic_vector(0 to NUMBER_OF_TX_LINKS-1); --! Indicates that the transmitter is ready to send data

		rx_data         : out slv64_array(0 to max(NUMBER_OF_RX_LINKS-1, 0));
		rx_data_valid   : out std_logic_vector(0 to max(NUMBER_OF_RX_LINKS-1, 0)); --! Active high when  valid data is  placed on the bus
		rx_header       : out slv2_array(0 to max(NUMBER_OF_RX_LINKS-1, 0));
		rx_header_valid : out std_logic_vector(0 to max(NUMBER_OF_RX_LINKS-1, 0)); --! Indicates when the header is valid. This happen on the first half of each word.
		rx_clk          : out std_logic_vector(0 to max(NUMBER_OF_RX_LINKS-1, 0)); --! clock synchronous with the rx data. Recovered from the received link.
		rx_resetdone    : out std_logic_vector(0 to max(NUMBER_OF_RX_LINKS-1, 0)); --! Indicates that the receiver is ready to receive data

		control_bytes : out slv8_array(0 to NUMBER_OF_CONTROL_BYTES-1); -- additional control bytes appended to the common control registers
		status_bytes  : in slv8_array(0 to NUMBER_OF_STATUS_BYTES-1):=(others=>(others=>'0')); -- additional status bytes appended to the common status registers

		-- Control and reply streams
		CMD_DAT  : in AXIS8_DAT_STRUCT;
		CMD_RDY  : out AXIS8_RDY_STRUCT;
		RPLY_DAT : out AXIS8_DAT_STRUCT;
		RPLY_RDY : in AXIS8_RDY_STRUCT;
		CTRL_CLK : IN std_logic; -- control clock
		CTRL_RST : in std_logic;

		-- clk: in std_logic; --! AXI-S data clock. Not related to the 10G Ethernet clocks.
		areset: in std_logic --! asynchronous reset
	 );

end xxvglink_core;

architecture Behavioral of xxvglink_core is

attribute ASYNC_REG : string;
attribute SHREG_EXTRACT : string;
attribute DONT_TOUCH : string;

--- CONSTANTS
constant DLY : time := 1 ps; -- delta delay used to ensure the simulator changes the data after the clock edge (which is a problem because we do a clock assignment which might be evaluated in any order)

constant NUMBER_OF_QUADS : integer := MAX(LINK_TO_QUAD_MAP(0 to NUMBER_OF_GT-1))+1; --! get the maximum QUAD index from the list of actually implemented channels


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

--constant QPLL_FBDIV_IN    : std_logic_vector(9 downto 0) := QPLL_FBDIV_IN_TABLE(LINK_SPEED);
--constant QPLL_FBDIV_RATIO : std_logic := QPLL_FBDIV_RATIO_TABLE(LINK_SPEED);
--constant QPLL_CFG: std_logic_vector(26 downto 0) := QPLL_CFG_TABLE(LINK_SPEED)(26 downto 0);
--constant QPLL_REFCLK_DIV: integer := QPLL_REFCLK_DIV_TABLE(LINK_SPEED);

---- CLOCKS
-- signal clk156_nobuf : std_logic; --! unbuffered 156.25 MHz data clock at the output of MMCM
signal clk156 : std_logic; --! buffered 156.25 MHz data clock derived from the reference clock

-- signal txclk322_nobuf : std_logic_vector(0 to NUMBER_OF_GT-1); --! Unbuffered TXOUTCLK from each GTX
signal txclk322 : std_logic; --! buffered TXOUTCLK used to clock all GTX TX subsystems
signal rxclk322 : slv(0 to NUMBER_OF_GT-1); --!

signal txusrclk : std_logic; --! txusrclk for all GTX
signal txusrclk2 : std_logic; --! txusrclk2 for all GTX
signal rxusrclk : slv(0 to NUMBER_OF_GT-1); --! rxusrclk for all GTX
signal rxusrclk2 : slv(0 to NUMBER_OF_GT-1); --! rxusrclk2 for all GTX

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

signal tx_resetdone_int: std_logic_vector(0 to NUMBER_OF_GT-1);
signal rx_resetdone_int: std_logic_vector(0 to NUMBER_OF_GT-1);

signal scrambler_reset: std_logic_vector(0 to NUMBER_OF_GT-1);

signal reset_pulse : std_logic_vector(3 downto 0);

constant NUMBER_OF_MODULES: integer := NUMBER_OF_QUADS + NUMBER_OF_GT + 1; -- One common module, and one for each quad (QPLL) and channel (GTX)

signal MODULE_CMD_DAT: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_MODULES-1 downto 0);
signal MODULE_CMD_RDY: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_MODULES-1 downto 0);
signal MODULE_RPLY_DAT: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_MODULES-1 downto 0);
signal MODULE_RPLY_RDY: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_MODULES-1 downto 0);

signal ctrl_rst_reg: std_logic_vector(NUMBER_OF_MODULES-1 downto 0);
attribute DONT_TOUCH of ctrl_rst_reg : signal is "true";
attribute SHREG_EXTRACT of ctrl_rst_reg : signal is "false";


signal quad_drp_dout: slv16_array(NUMBER_OF_QUADS-1 downto 0);
signal quad_drp_din: slv16_array(NUMBER_OF_QUADS-1 downto 0);
signal quad_drp_addr: slv10_array(NUMBER_OF_QUADS-1 downto 0);
signal quad_drp_drdy: slv(NUMBER_OF_QUADS-1 downto 0);
signal quad_drp_den: slv(NUMBER_OF_QUADS-1 downto 0);
signal quad_drp_wr_en: slv(NUMBER_OF_QUADS-1 downto 0);

signal common_control_bytes: slv8_array(0 to 3 + NUMBER_OF_CONTROL_BYTES);
signal common_status_bytes: slv8_array(0 to 1 + NUMBER_OF_STATUS_BYTES);

type QUAD_CONTROL_BYTES_ARRAY is array (natural range <>) of slv8_array(0 to 0);
signal quad_control_bytes: QUAD_CONTROL_BYTES_ARRAY(0 to NUMBER_OF_QUADS-1);
type QUAD_STATUS_BYTES_ARRAY is array (natural range <>) of slv8_array(0 to 0);
signal quad_status_bytes: QUAD_STATUS_BYTES_ARRAY(0 to NUMBER_OF_QUADS-1);

type gt_CONTROL_BYTES_ARRAY is array (natural range <>) of slv8_array(0 to 5);
signal gt_control_bytes: gt_control_bytes_array(0 to NUMBER_OF_GT-1);
type gt_STATUS_BYTES_ARRAY is array (natural range <>) of slv8_array(0 to sel(NUMBER_OF_RX_LINKS>0, 11, 4));
signal gt_status_bytes: gt_status_bytes_array(0 to NUMBER_OF_GT-1);

signal txclk_div2_int: std_logic := '0'; -- init needed
signal refclk_div2_int: std_logic_vector(0 to NUMBER_OF_REFCLK-1) := (others=> '0'); -- init needed

signal common_user_reset: std_logic;
signal common_user_tx_data: std_logic_vector(23 downto 0);

-------------------------------------------------------------------
signal gt_drp_dout: slv16_array(NUMBER_OF_GT-1 downto 0);
signal gt_drp_din: slv16_array(NUMBER_OF_GT-1 downto 0);
signal gt_drp_addr: slv10_array(NUMBER_OF_GT-1 downto 0);
signal gt_drp_rdy: slv(NUMBER_OF_GT-1 downto 0);
signal gt_drp_en: slv(NUMBER_OF_GT-1 downto 0);
signal gt_drp_wr_en: slv(NUMBER_OF_GT-1 downto 0);


constant STABLE_CLOCK_PERIOD: integer := 6; -- in fact 1/156.25 = 6.4 ns
constant WAIT_TIME_CDRLOCK: integer := sel(SIM, 1000,  50000 / integer(10.3125))/STABLE_CLOCK_PERIOD;
signal rx_cdrlock_counter  :   integer range 0 to WAIT_TIME_CDRLOCK:= 0 ;
signal rx_cdrlocked                    : std_logic;

signal gt_dmonitorout_out: slv8_array(0 to NUMBER_OF_GT-1);
signal gt_rxmonitorout_out: slv7_array(0 to NUMBER_OF_GT-1);
signal gt_rxmonitorsel_in: slv2_array(0 to NUMBER_OF_GT-1) := (others=>"00");

signal gt_loopback_in: slv3_array(0 to NUMBER_OF_GT-1);
signal gt_rxcdrhold_in: slv(0 to NUMBER_OF_GT-1);
signal gt_rxdata_out: slv64_array(0 to NUMBER_OF_GT-1);
signal gt_rxprbserr_out: slv(0 to NUMBER_OF_GT-1);
signal gt_rxprbslocked_out: slv(0 to NUMBER_OF_GT-1);
signal gt_rxprbssel_in: slv3_array(0 to NUMBER_OF_GT-1) := (others=> "000");
signal gt_txprbssel_in: slv3_array(0 to NUMBER_OF_GT-1) := (others=> "000");
signal gt_rxprbscntreset_in: slv(0 to NUMBER_OF_GT-1) := (others=>'0');
signal gt_rxbufstatus_out: slv3_array(0 to NUMBER_OF_GT-1);
signal gt_rxdfeagchold_in: slv(0 to NUMBER_OF_GT-1);
signal gt_rxdfelfhold_in: slv(0 to NUMBER_OF_GT-1);
signal gt_rxoutclk_out: slv(0 to NUMBER_OF_GT-1);
signal gt_rxdatavalid_out: slv(0 to NUMBER_OF_GT-1);
signal gt_rxheader_out: slv2_array(0 to NUMBER_OF_GT-1);
signal gt_rxheader_capture: slv2_array(0 to NUMBER_OF_GT-1);
signal gt_rxheadervalid_out: slv(0 to NUMBER_OF_GT-1);
signal gt_rxstartofseq_out: slv(0 to NUMBER_OF_GT-1);
signal gt_rxgearboxslip_in: slv(0 to NUMBER_OF_GT-1) := (others=>'0');
signal gt_rxpolarity_in: slv(0 to NUMBER_OF_GT-1);
signal gt_txpolarity_in: slv(0 to NUMBER_OF_GT-1);
signal gt_txpostcursor_in: slv5_array(0 to NUMBER_OF_GT-1);
signal gt_txprecursor_in: slv5_array(0 to NUMBER_OF_GT-1);
signal gt_gttxreset_in: slv(0 to NUMBER_OF_GT-1);
signal gt_gttxreset_all: slv(0 to NUMBER_OF_GT-1);
signal gt_txuserrdy_in: slv(0 to NUMBER_OF_GT-1);
signal gt_rxuserrdy_in: slv(0 to NUMBER_OF_GT-1);
signal gt_txprbsforceerr_in: slv(0 to NUMBER_OF_GT-1) := (others=>'0');
signal gt_txbufstatus_out: slv2_array(0 to NUMBER_OF_GT-1);
signal gt_txdiffctrl_in: slv4_array(0 to NUMBER_OF_GT-1);
signal gt_txinhibit_in: slv(0 to NUMBER_OF_GT-1);
signal gt_txdata_in: slv64_array(0 to NUMBER_OF_GT-1);
signal gt_user_tx_data: slv64_array(0 to NUMBER_OF_GT-1);
signal gt_user_tx_data_int: slv64_array(0 to NUMBER_OF_GT-1);
signal gt_user_source_sel: slv(0 to NUMBER_OF_GT-1);
signal gt_txoutclk_out: slv(0 to NUMBER_OF_GT-1);
signal gt_txheader_in: slv2_array(0 to NUMBER_OF_GT-1);
signal gt_user_tx_header: slv2_array(0 to NUMBER_OF_GT-1);
signal gt_gtrxreset_in : slv(0 to NUMBER_OF_GT-1);
signal gt_gtrxreset_all : slv(0 to NUMBER_OF_GT-1);
signal gt_txsequence_in: slv7_array(0 to NUMBER_OF_GT-1);
signal gt_rxresetdone_out: slv(0 to NUMBER_OF_GT-1);
signal gt_txresetdone_out: slv(0 to NUMBER_OF_GT-1);
signal gt_block_lock: slv(0 to NUMBER_OF_GT-1) := (others => '0'); -- default provided to attempt to squash undriven warnings when there is no RX
signal quad_sel: std_logic_vector(1 downto 0);
signal gt_seq_counter: unsigned_array(0 to NUMBER_OF_GT-1)(6 downto 0); -- counts from 0 to 65
signal gt_scramble_en: slv(0 to NUMBER_OF_GT-1);
signal gt_descramble_en: slv(0 to NUMBER_OF_GT-1);
signal gt_block_lock_reset: slv(0 to NUMBER_OF_GT-1) := (others=>'0');
signal gt_scrambler_reset: slv(0 to NUMBER_OF_GT-1);
signal gt_unscrambler_reset: slv(0 to NUMBER_OF_GT-1);
signal gt_err_ctr: slv32_array(0 to NUMBER_OF_GT-1);
signal gt_capture_en: slv(0 to NUMBER_OF_GT-1) := (others=>'0');
signal gt_capture_en_rxusrclk2: slv2_array(0 to NUMBER_OF_GT-1);
signal gt_user_gttxreset: slv(0 to NUMBER_OF_GT-1);
signal gt_user_gtrxreset: slv(0 to NUMBER_OF_GT-1) := (others=>'0');
signal gt_user_reset: slv(0 to NUMBER_OF_GT-1);

signal gt_rxdfelpmreset_in: slv(0 to NUMBER_OF_GT-1) := (others=>'0');
signal gt_rxlpmen_in: slv(0 to NUMBER_OF_GT-1) := (others => '0');
signal gt_rxlpmhold_in: slv2_array(0 to NUMBER_OF_GT-1);
signal gt_rxlpmovrd_in: slv2_array(0 to NUMBER_OF_GT-1);
signal gt_rxdfehold_in: slv9_array(0 to NUMBER_OF_GT-1);
signal gt_rxdfeovrd_in: slv9_array(0 to NUMBER_OF_GT-1);
signal gt_stop_bitslip: slv(0 to NUMBER_OF_GT-1);

	attribute SHREG_EXTRACT of gt_capture_en_rxusrclk2 : signal is "no";
	attribute ASYNC_REG of gt_capture_en_rxusrclk2 : signal is "true";

-- User data interface
signal tx_ready_int: slv(0 to NUMBER_OF_GT-1);

signal rx_data_capture: slv64_array(0 to NUMBER_OF_GT-1);

--signal tx_ctr: u16_array(0 to NUMBER_OF_GT-1) := (others=> (others=>'0')); -- init for sim

signal tx_fsm_soft_reset: slv(0 to NUMBER_OF_GT-1);
signal rx_fsm_soft_reset: slv(0 to NUMBER_OF_GT-1);
signal block_sync_reset: slv(0 to NUMBER_OF_GT-1);

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
-- Instantiate the BSB packet router
-- Routes the commands to the requested module
bsb_router0: entity work.CTRL_ROUTER
	generic map (
		NUMBER_OF_PORTS=> NUMBER_OF_MODULES,
		ADDRESS_MASK => "---11111-----------" -- 5-bit routing address,  11-bit internal address
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
refclk_blk: block
    signal refclk_div_nobuf : std_logic_vector(0 to NUMBER_OF_REFCLK-1); --! unbuffered GTX reference clock

begin
	-- Instantiate reference clock buffers for each reference clock
	ibuf_gen: for i in 0 to NUMBER_OF_REFCLK-1 generate
		-- Instantiate differential input buffer
		ibufds0 : IBUFDS_GTE4
			 generic map( -- we need to profide these generics otherwise we have failed nets on refclk_nobuf
                REFCLK_EN_TX_PATH => '0', -- Reserved
                REFCLK_HROW_CK_SEL => "00", -- ODIV2 output selection: "00"=divide by 1, "01"= divide by 2, "10"=1, "11"=reserved
                REFCLK_ICNTL_RX    => "00" -- Reserved; use value from wizard
    			 )
			port map(
				I     => refclk_p(i),
				IB    => refclk_n(i),
				ODIV2 => refclk_div_nobuf(i), -- refclk_buf(i), -- **JFC was open
				CEB   => '0',
				O     => refclk_nobuf(i)
			);
--		-- Instantiate global clock buffers
--		refclkbuftype_gen: if i = 0 generate 	-- Instantiate BUFG for refclk[0] only to ve used as global free-runnning clock
			refclk_bufg0 : BUFG_GT --
				port map(
					I => refclk_div_nobuf(i),
					O => refclk_buf(i),
					CE => '1',
					CEMASK => '0',
					CLR => '0',
					CLRMASK => '0',
					DIV => "000"
				);
--		else generate
--			refclk_bufh0 : BUFH -- Instantiate BUFH for the local divide-by-2 counter
--				port map(
--					I => refclk_nobuf(i),
--					O => refclk_buf(i)
--				);
--		end generate; -- if i==0
	end generate; -- for each refclk

--	clk156 <= refclk_buf(0); -- free running stable clock
	clk156 <= ctrl_clk; -- free running stable clock

	-- Generate a logic signal that toggles at half the rate of the reference clock for the frequency counter
	refclkdiv2_gen: for i in 0 to NUMBER_OF_REFCLK-1 generate
		refclkdiv2_proc: process(refclk_buf(i))
			begin
				if rising_edge(refclk_buf(i)) then
					refclk_div2_int(i) <=not refclk_div2_int(i);
				end if;
			end process;
	end generate;
end block;


----------------------------------
-- REFERENCE CLOCK-BASED RESETS
----------------------------------




-- common signals
-- *** Not used with GTY core
--cdrlock_timeout:process(clk156)
--  begin
--    if rising_edge(clk156) then
--        if(gt_gtrxreset_in(0) = '1') then
--          rx_cdrlocked       <= '0';
--          rx_cdrlock_counter <=  0;
--        elsif (rx_cdrlock_counter = WAIT_TIME_CDRLOCK) then
--          rx_cdrlocked       <= '1'; -- Used by RX startup FSM
--          rx_cdrlock_counter <= rx_cdrlock_counter;
--        else
--          rx_cdrlock_counter <= rx_cdrlock_counter + 1;
--        end if;
--    end if;
--  end process;


-----------------------------
-- Post configuration resets
-- Happens only once after config, and is nor affected by any other signal
-----------------------------
-- *** Not used with GTY core
-- Hold off release the GT resets until 500ns after configuration.
-- 128 ticks at 6.4ns period will be >> 500 ns.
--conf_rst_blk: block
--	signal reset_counter  : unsigned(7 downto 0) := X"00";
--begin
--	--! Reset counter process
--	--! Clear counter on areset, and increment until bit 7 = '1' otherwise
--	reset_ctr_proc: process (clk156)
--		begin
--			if rising_edge(clk156) then
--				if common_user_reset='1' then
--					reset_counter <= (others=>'0');
--				elsif(reset_counter(7) = '0')  then
--				   reset_counter <= reset_counter + 1;
--				else
--				   reset_counter <= reset_counter;
--				end if;
--			end if;
--		end process;

--	--! Once the counter reaches its limit, generate a 3 refclk reset pulse
--	--! on gttxreset, gtrxreset and qpllreset
--	reset_pulse_proc: process (clk156)
--		begin
--		 if rising_edge(clk156) then
--		   if(reset_counter(7) = '0' or common_user_reset='1')  then
--		      reset_pulse <=  "1110";
--		   else
--		      reset_pulse(3)            <=  '0';
--		      reset_pulse(2 downto 0)   <=  reset_pulse(3 downto 1);
--		   end if;
--		 end if;
--		end process;
--	qpllreset  <=     reset_pulse(0); -- resets all QPLLs directly
--end block; -- post conf reset

---------------------------------
--! TXOUTCLK buffer
--! Buffer the TXOUTCLK generated by the first GTX to generate the txusrclk and txusrclk2 for ALL channels
--! There is only one per array since all transceivers are clocked by the same reference clock
--! Since the GTX is configured with a 4-byte external interface  and 4-byte internal data path, both txusrclk and txusrclk2 are at the same frequency.
---------------------------------
-- *** Not used with GTY core
--txoutclk_bufg0 : BUFG
--	port map (
--		I => gt_txoutclk_out(0), --txclk322_nobuf(0),
--		O => txclk322
--	);

--txusrclk2 <= txclk322;
--txusrclk <= txclk322;

common_regs0: entity work.CTRL_SLAVE
	GENERIC MAP (
		DEFAULT_CONTROL_BYTES   => X"00_FF2833" & repeat(X"00", NUMBER_OF_CONTROL_BYTES),
		NUMBER_OF_CONTROL_BYTES => common_control_bytes'Length(1) , -- Number of bits in the control word
		NUMBER_OF_STATUS_BYTES  => common_status_bytes'Length(1) -- Number of bits in the status word.
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

resetdone <= (and_reduce(tx_resetdone_int) or to_std_logic(NUMBER_OF_TX_LINKS=0)) and (and_reduce(rx_resetdone_int) or to_std_logic(NUMBER_OF_RX_LINKS=0)) after DLY;


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
common_status_bytes(0)(4 downto 0) <= to_slv(NUMBER_OF_GT, 5);

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

	quad_regs0: entity work.CTRL_SLAVE
		GENERIC MAP (
			DEFAULT_CONTROL_BYTES   => X"00",
			USE_RAM_DOUT_RDY        => TRUE, -- need to wait for the RDY signal on RAM read accesses
			RAM_DATA_WIDTH          => 16,
			RAM_ADDR_WIDTH          => 10, -- GTYE4_COMMON DRP Address bus is 10 bits
			NUMBER_OF_CONTROL_BYTES => quad_control_bytes(i)'Length(1), -- Number of bits in the control word
			NUMBER_OF_STATUS_BYTES  => quad_status_bytes(i)'Length(1) -- Number of bits in the status word.
		)
		PORT MAP(
			CONTROL_BYTES => quad_control_bytes(i),
			STATUS_BYTES  => quad_status_bytes(i),

			CTRL_CMD_IN_DAT   =>   MODULE_CMD_DAT(i+1),
			CTRL_CMD_IN_RDY   =>   MODULE_CMD_RDY(i+1),
			CTRL_RPLY_OUT_DAT => MODULE_RPLY_DAT(i+1),
			CTRL_RPLY_OUT_RDY => MODULE_RPLY_RDY(i+1),
			CTRL_CLK          => CTRL_CLK,
			CTRL_RST          => ctrl_rst_reg(i+1),

			-- DRP interface
			RAM_DIN      => quad_drp_din(i),
			RAM_DOUT     => quad_drp_dout(i),
			RAM_DOUT_RDY => quad_drp_drdy(i),
			RAM_WR_EN    => quad_drp_wr_en(i),
			RAM_EN       => quad_drp_den(i),
			RAM_ADDR     => quad_drp_addr(i)
	);

	quad_status_bytes(i)(0)(0) <= qplllock(i);


	-- *** Not used with GTY core
	--gtxe2_common_0_i : GTXE2_COMMON
	--	generic map(
	--		-- Simulation attributes
	--		SIM_RESET_SPEEDUP    => "TRUE",
	--		SIM_QPLLREFCLK_SEL   => ("001"),
	--		SIM_VERSION          => "4.0",
	--		------------------COMMON BLOCK Attributes---------------
	--		BIAS_CFG                                =>     (x"0000040000001000"),
	--		COMMON_CFG                              =>     (x"00000000"),
	--		QPLL_CFG                                =>     to_bitvector(QPLL_CFG),
	--		QPLL_CLKOUT_CFG                         =>     ("0000"),
	--		QPLL_COARSE_FREQ_OVRD                   =>     ("010000"),
	--		QPLL_COARSE_FREQ_OVRD_EN                =>     ('0'),
	--		QPLL_CP                                 =>     ("0000011111"),
	--		QPLL_CP_MONITOR_EN                      =>     ('0'),
	--		QPLL_DMONITOR_SEL                       =>     ('0'),
	--		QPLL_FBDIV                              =>     to_bitvector(QPLL_FBDIV_IN),
	--		QPLL_FBDIV_MONITOR_EN                   =>     ('0'),
	--		QPLL_FBDIV_RATIO                        =>     to_bit(QPLL_FBDIV_RATIO),
	--		QPLL_INIT_CFG                           =>     (x"000006"),
	--		QPLL_LOCK_CFG                           =>     (x"21E8"),
	--		QPLL_LPF                                =>     ("1111"),
	--		QPLL_REFCLK_DIV                         =>     QPLL_REFCLK_DIV
	--		)
	--	port map (
	--		------------- Common Block  - Dynamic Reconfiguration Port (DRP) -----------
	--		DRPADDR                         =>      quad_drp_addr(i), --to_ground_vec_i(7 downto 0),
	--		DRPCLK                          =>      CTRL_CLK,
	--		DRPDI                           =>      quad_drp_din(i),
	--		DRPDO                           =>      quad_drp_dout(i),
	--		DRPEN                           =>      quad_drp_den(i),
	--		DRPRDY                          =>      quad_drp_drdy(i),
	--		DRPWE                           =>      quad_drp_wr_en(i),
	--		---------------------- Common Block  - Ref Clock Ports ---------------------
	--		GTGREFCLK                       =>      '0',
	--		GTNORTHREFCLK0                  =>      '0',
	--		GTNORTHREFCLK1                  =>      '0',
	--		GTREFCLK0                       =>      refclk_nobuf(QUAD_TO_REFCLK_MAP(i)),
	--		GTREFCLK1                       =>      '0',
	--		GTSOUTHREFCLK0                  =>      '0',
	--		GTSOUTHREFCLK1                  =>      '0',
	--		------------------------- Common Block - QPLL Ports ------------------------
	--		QPLLDMONITOR                    =>      open,
	--		QPLLFBCLKLOST                   =>      open,
	--		QPLLLOCK                        =>      qplllock(i),
	--		QPLLLOCKDETCLK                  =>      '0',
	--		QPLLLOCKEN                      =>      '1',
	--		QPLLOUTCLK                      =>      qplloutclk(i),
	--		QPLLOUTREFCLK                   =>      qplloutrefclk(i),
	--		QPLLOUTRESET                    =>      '0',
	--		QPLLPD                          =>      '0',
	--		QPLLREFCLKLOST                  =>      open,
	--		QPLLREFCLKSEL                   =>      "001",
	--		QPLLRESET                       =>      qpllreset, -- input
	--		QPLLRSVD1                       =>      "0000000000000000",
	--		QPLLRSVD2                       =>      "11111",
	--		REFCLKOUTMONITOR                =>      open,
	--		----------------------------- Common Block Ports ---------------------------
	--		BGBYPASSB                       =>      '1',
	--		BGMONITORENB                    =>      '1',
	--		BGPDB                           =>      '1',
	--		BGRCALOVRD                      =>      "00000",
	--		PMARSVD                         =>      "00000000",
	--		RCALENB                         =>      '1'
	--	);

end generate;


-- -----------------------------------------------------------------------------
-- GTY Core
-- -----------------------------------------------------------------------------
gtycore_blk: block

	constant NL: integer:= 3; --  number of lanes in core
	constant NQ: integer:= 2; -- number of QUADs (COMMON)



    -- Differential data inputs/outputs
    signal gtyrxn_in : std_logic_vector(NL-1 downto 0); --
    signal gtyrxp_in : std_logic_vector(NL-1 downto 0); --
    signal gtytxn_out : std_logic_vector(NL-1 downto 0); --
    signal gtytxp_out : std_logic_vector(NL-1 downto 0); --

    -- Reference clocks
    signal gtrefclk00_in : std_logic_vector(NQ-1 downto 0); --

    -- QPLL DRP
    signal drpaddr_common_in : std_logic_vector(16*NQ-1 downto 0); --
    signal drpclk_common_in : std_logic_vector(NQ-1 downto 0); --
    signal drpdi_common_in : std_logic_vector(16*NQ-1 downto 0); --
    signal drpen_common_in : std_logic_vector(NQ-1 downto 0); --
    signal drpwe_common_in : std_logic_vector(NQ-1 downto 0); --
    signal drpdo_common_out : std_logic_vector(16*NQ-1 downto 0); --
    signal drprdy_common_out : std_logic_vector(NQ-1 downto 0); --

    -- Lane DRP
    signal drpaddr_in : std_logic_vector(10*NL-1 downto 0); --
    signal drpclk_in : std_logic_vector(NL-1 downto 0); --
    signal drpdi_in : std_logic_vector(16*NL-1 downto 0); --
    signal drpen_in : std_logic_vector(NL-1 downto 0); --
    signal drpwe_in : std_logic_vector(NL-1 downto 0); --
    signal drpdo_out : std_logic_vector(16*NL-1 downto 0); --
    signal drprdy_out : std_logic_vector(NL-1 downto 0); --

    -- QPLL
    signal qpll0outclk_out : std_logic_vector(NQ-1 downto 0); --
    signal qpll0outrefclk_out : std_logic_vector(NQ-1 downto 0); --

    -- Clock inputs

    signal gtwiz_reset_clk_freerun_in : std_logic_vector(0 downto 0); --


    -- Clock outputs
    signal gtwiz_userclk_tx_srcclk_out : std_logic_vector(0 downto 0);
    signal gtwiz_userclk_tx_usrclk_out : std_logic_vector(0 downto 0); --
    signal gtwiz_userclk_tx_usrclk2_out : std_logic_vector(0 downto 0); --
    signal gtwiz_userclk_rx_srcclk_out : std_logic_vector(0 downto 0);
    signal gtwiz_userclk_rx_usrclk_out : std_logic_vector(0 downto 0); --
    signal gtwiz_userclk_rx_usrclk2_out : std_logic_vector(0 downto 0); --


    -- TX interface
    signal gtwiz_userdata_tx_in : std_logic_vector(64*NL-1 downto 0);
    signal txheader_in : std_logic_vector(6*NL-1 downto 0);
    signal txsequence_in : std_logic_vector(7*NL-1 downto 0);


    -- Rx interface
    signal gtwiz_userdata_rx_out : std_logic_vector(64*NL-1 downto 0); --
    signal rxdatavalid_out : std_logic_vector(2*NL-1 downto 0); --
    signal rxheader_out : std_logic_vector(6*NL-1 downto 0); --
    signal rxheadervalid_out : std_logic_vector(2*NL-1 downto 0);--
    signal rxcdrhold_in : std_logic_vector(NL-1 downto 0); --
    signal rxgearboxslip_in : std_logic_vector(NL-1 downto 0); --
    signal rxstartofseq_out : std_logic_vector(2*NL-1 downto 0); -- not used

    -- Control/reset signals
    signal gtpowergood_out : std_logic_vector(NL-1 downto 0);



    -- reset inputs
    signal gtwiz_reset_all_in : std_logic_vector(0 downto 0); --

    signal gtwiz_userclk_tx_reset_in : std_logic_vector(0 downto 0);--
    signal gtwiz_reset_tx_pll_and_datapath_in : std_logic_vector(0 downto 0);--
    signal gtwiz_reset_tx_datapath_in : std_logic_vector(0 downto 0);--

    signal gtwiz_userclk_rx_reset_in : std_logic_vector(0 downto 0);--
    signal gtwiz_reset_rx_pll_and_datapath_in : std_logic_vector(0 downto 0);--
    signal gtwiz_reset_rx_datapath_in : std_logic_vector(0 downto 0);--



    -- Reset outputs
    signal txpmaresetdone_out : std_logic_vector(NL-1 downto 0);
    signal txprgdivresetdone_out : std_logic_vector(NL-1 downto 0);
    signal rxpmaresetdone_out : std_logic_vector(NL-1 downto 0);

    signal gtwiz_userclk_tx_active_out : std_logic_vector(0 downto 0);

    signal gtwiz_userclk_rx_active_out : std_logic_vector(0 downto 0);
    signal gtwiz_reset_rx_cdr_stable_out : std_logic_vector(0 downto 0);
    signal gtwiz_reset_tx_done_out : std_logic_vector(0 downto 0); --
    signal gtwiz_reset_rx_done_out : std_logic_vector(0 downto 0); --

    -- Debugging signals

    signal loopback_in : std_logic_vector(8 downto 0);
    signal rxdfeagchold_in : std_logic_vector(2 downto 0);
    signal rxdfelfhold_in : std_logic_vector(2 downto 0);
    signal rxdfelpmreset_in : std_logic_vector(2 downto 0);
    signal rxlpmen_in : std_logic_vector(2 downto 0);
    signal rxlpmoshold_in : std_logic_vector(2 downto 0);
    signal rxmonitorsel_in : std_logic_vector(5 downto 0);
    signal rxprbscntreset_in : std_logic_vector(2 downto 0);
    signal rxprbssel_in : std_logic_vector(11 downto 0);
    signal txdiffctrl_in : std_logic_vector(14 downto 0);
    signal txinhibit_in : std_logic_vector(2 downto 0);
    signal txpostcursor_in : std_logic_vector(14 downto 0);
    signal txprbsforceerr_in : std_logic_vector(2 downto 0);
    signal txprbssel_in : std_logic_vector(11 downto 0);
    signal txprecursor_in : std_logic_vector(14 downto 0);
    signal rxmonitorout_out : std_logic_vector(23 downto 0);
    signal rxprbserr_out : std_logic_vector(2 downto 0);
    signal rxprbslocked_out : std_logic_vector(2 downto 0);



begin

    -- Map all vectorized signals to the GTY core signals

	-- Quad signals
	quad_gen: for i in 0 to NQ-1 generate

		-- QPLL input reference clocks
		gtrefclk00_in(i) <= refclk_nobuf(QUAD_TO_REFCLK_MAP(i));

		-- QPLL output clocks
		qplloutclk(i) <= qpll0outclk_out(i);
		qplloutrefclk(i) <= qpll0outrefclk_out(i);

		-- clock
		drpdi_common_in(16*(i+1)-1 downto 16*i) <= quad_drp_din(i);
		quad_drp_dout(i) <= drpdo_common_out(16*(i+1)-1 downto 16*i);
		quad_drp_drdy(i) <= drprdy_common_out(i);
		drpwe_common_in(i) <= quad_drp_wr_en(i);
		drpen_common_in(i) <= quad_drp_den(i);
		drpaddr_common_in(16*(i+1)-1 downto 16*i) <= "000000" & quad_drp_addr(i); -- the core wants 16-bit addresses, but max GTYE4_COMMON address is 0x9F
		drpclk_common_in(i) <= ctrl_clk;
	end generate; -- for each quad


	-- Lane signals
	lane_gen: for i in 0 to NL-1 generate

		-- Differential signals
		gtyrxn_in(i) <= rx_n(i);
		gtyrxp_in(i) <= rx_p(i);
		tx_n(i) <= gtytxn_out(i);
		tx_p(i) <= gtytxp_out(i);


		-- DRP port
		drpaddr_in(10*(i+1)-1 downto 10*i) <= gt_drp_addr(i);
		drpdi_in(16*(i+1)-1 downto 16*i) <= gt_drp_din(i);
		drpclk_in(i) <= ctrl_clk;
		gt_drp_dout(i) <= drpdo_out(16*(i+1)-1 downto 16*i);
		drpen_in(i) <= gt_drp_en(i);
		gt_drp_rdy(i) <= drprdy_out(i);
		drpwe_in(i) <= gt_drp_wr_en(i);

		-- Clocks
		rxusrclk2(i) <= gtwiz_userclk_rx_usrclk2_out(0);
		rxusrclk(i) <= gtwiz_userclk_rx_usrclk_out(0);

	    -- reset outputs
	    tx_resetdone_int(i) <= gtwiz_reset_tx_done_out(0);

	    rx_resetdone_int(i) <= gtwiz_reset_rx_done_out(0);
		gt_rxresetdone_out(i) <= gtwiz_reset_rx_done_out(0);
	    -- data

	    gtwiz_userdata_tx_in(64*(i+1)-1 downto 64*i) <= gt_txdata_in(i);
		txheader_in(6*(i+1)-1 downto 6*i) <= "0000" & gt_txheader_in(i);
		rxgearboxslip_in(i) <= gt_rxgearboxslip_in(i);
		gt_rxheader_out(i) <= rxheader_out(6*i+1 downto 6*i);
		gt_rxheadervalid_out(i) <= rxheadervalid_out(2*i);
		gt_rxdatavalid_out(i) <= rxdatavalid_out(2*i);
		gt_rxdata_out(i) <= gtwiz_userdata_rx_out(64*(i+1)-1 downto 64*i);
		rxcdrhold_in(i) <= '0'; -- for SATA only
        txsequence_in(7*(i+1)-1 downto 7*i) <= gt_txsequence_in(i);

        -- debug signals

        loopback_in(3*(i+1)-1 downto 3*i) <= gt_loopback_in(i);

        rxdfeagchold_in(i) <= gt_rxdfeagchold_in(i);
		rxdfeagchold_in(i) <= gt_rxdfeagchold_in(i);
		rxdfelfhold_in(i) <= gt_rxdfelfhold_in(i);
		rxdfelpmreset_in(i) <= gt_rxdfelpmreset_in(i);

	    rxlpmen_in(i) <= gt_rxlpmen_in(i);
	    --rxlpmoshold_in(i) <= gt_rxlpmoshold_in(i);
	    rxlpmoshold_in(i) <= '0';
	    rxmonitorsel_in(2*(i+1)-1 downto 2*i) <= gt_rxmonitorsel_in(i);
		txdiffctrl_in(5*(i+1)-1 downto 5*i) <= '0' & gt_txdiffctrl_in(i);
		txinhibit_in(i) <= gt_txinhibit_in(i);
		txpostcursor_in(5*(i+1)-1 downto 5*i) <= gt_txpostcursor_in(i);
		txprecursor_in(5*(i+1)-1 downto 5*i) <= gt_txprecursor_in(i);

		txprbssel_in(4*(i+1)-1 downto 4*i) <= '0' & gt_txprbssel_in(i);
		rxprbssel_in(4*(i+1)-1 downto 4*i) <= '0' & gt_rxprbssel_in(i);
		txprbsforceerr_in(i) <= gt_txprbsforceerr_in(i);
		rxprbscntreset_in(i) <= gt_rxprbscntreset_in(i);
	    gt_rxprbserr_out(i) <= rxprbserr_out(i);

		gt_rxmonitorout_out(i) <= rxmonitorout_out(7*(i+1)-1 downto 7*i);

	    gt_rxprbslocked_out(i) <= rxprbslocked_out(i);

	end generate; -- for each lane

	-- Clocks
	gtwiz_reset_clk_freerun_in(0) <= clk156; -- free-running stable clock
	txusrclk2 <= gtwiz_userclk_tx_usrclk_out(0);
	txusrclk <= gtwiz_userclk_tx_usrclk_out(0);

	-- Resets inputs
	gtwiz_reset_all_in(0) <= common_user_reset or areset;  -- ***JFC replace areset by real sync clock
	gtwiz_userclk_rx_reset_in(0) <= areset; -- ***JFC replace areset by real sync clock
	gtwiz_userclk_tx_reset_in(0) <= areset; -- ***JFC replace areset by real sync clock
    gtwiz_reset_tx_pll_and_datapath_in(0) <= '0';
    gtwiz_reset_tx_datapath_in(0) <= '0';
    gtwiz_reset_rx_pll_and_datapath_in(0) <= '0';
    gtwiz_reset_rx_datapath_in(0) <= '0';



gty_core0 : entity work.gtwizard_ultrascale_0
  PORT MAP (
    gtwiz_userclk_tx_reset_in => gtwiz_userclk_tx_reset_in,
    gtwiz_userclk_tx_srcclk_out => gtwiz_userclk_tx_srcclk_out,
    gtwiz_userclk_tx_usrclk_out => gtwiz_userclk_tx_usrclk_out,
    gtwiz_userclk_tx_usrclk2_out => gtwiz_userclk_tx_usrclk2_out,
    gtwiz_userclk_tx_active_out => gtwiz_userclk_tx_active_out,
    gtwiz_userclk_rx_reset_in => gtwiz_userclk_rx_reset_in,
    gtwiz_userclk_rx_srcclk_out => gtwiz_userclk_rx_srcclk_out,
    gtwiz_userclk_rx_usrclk_out => gtwiz_userclk_rx_usrclk_out,
    gtwiz_userclk_rx_usrclk2_out => gtwiz_userclk_rx_usrclk2_out,
    gtwiz_userclk_rx_active_out => gtwiz_userclk_rx_active_out,
    gtwiz_reset_clk_freerun_in => gtwiz_reset_clk_freerun_in,
    gtwiz_reset_all_in => gtwiz_reset_all_in,
    gtwiz_reset_tx_pll_and_datapath_in => gtwiz_reset_tx_pll_and_datapath_in,
    gtwiz_reset_tx_datapath_in => gtwiz_reset_tx_datapath_in,
    gtwiz_reset_rx_pll_and_datapath_in => gtwiz_reset_rx_pll_and_datapath_in,
    gtwiz_reset_rx_datapath_in => gtwiz_reset_rx_datapath_in,
    gtwiz_reset_rx_cdr_stable_out => gtwiz_reset_rx_cdr_stable_out,
    gtwiz_reset_tx_done_out => gtwiz_reset_tx_done_out,
    gtwiz_reset_rx_done_out => gtwiz_reset_rx_done_out,
    gtwiz_userdata_tx_in => gtwiz_userdata_tx_in,
    gtwiz_userdata_rx_out => gtwiz_userdata_rx_out,
    drpaddr_common_in => drpaddr_common_in,
    drpclk_common_in => drpclk_common_in,
    drpdi_common_in => drpdi_common_in,
    drpen_common_in => drpen_common_in,
    drpwe_common_in => drpwe_common_in,
    gtrefclk00_in => gtrefclk00_in,
    drpdo_common_out => drpdo_common_out,
    drprdy_common_out => drprdy_common_out,
    qpll0outclk_out => qpll0outclk_out,
    qpll0outrefclk_out => qpll0outrefclk_out,
    drpaddr_in => drpaddr_in,
    drpclk_in => drpclk_in,
    drpdi_in => drpdi_in,
    drpen_in => drpen_in,
    drpwe_in => drpwe_in,
    gtyrxn_in => gtyrxn_in,
    gtyrxp_in => gtyrxp_in,
    loopback_in => loopback_in,
    rxcdrhold_in => rxcdrhold_in,
    rxdfeagchold_in => rxdfeagchold_in,
    rxdfelfhold_in => rxdfelfhold_in,
    rxdfelpmreset_in => rxdfelpmreset_in,
    rxgearboxslip_in => rxgearboxslip_in,
    rxlpmen_in => rxlpmen_in,
    rxlpmoshold_in => rxlpmoshold_in,
    rxmonitorsel_in => rxmonitorsel_in,
    rxprbscntreset_in => rxprbscntreset_in,
    rxprbssel_in => rxprbssel_in,
    txdiffctrl_in => txdiffctrl_in,
    txheader_in => txheader_in,
    txinhibit_in => txinhibit_in,
    txpostcursor_in => txpostcursor_in,
    txprbsforceerr_in => txprbsforceerr_in,
    txprbssel_in => txprbssel_in,
    txprecursor_in => txprecursor_in,
    txsequence_in => txsequence_in,
    drpdo_out => drpdo_out,
    drprdy_out => drprdy_out,
    gtpowergood_out => gtpowergood_out,
    gtytxn_out => gtytxn_out,
    gtytxp_out => gtytxp_out,
    rxdatavalid_out => rxdatavalid_out,
    rxheader_out => rxheader_out,
    rxheadervalid_out => rxheadervalid_out,
    rxmonitorout_out => rxmonitorout_out,
    rxpmaresetdone_out => rxpmaresetdone_out,
    rxprbserr_out => rxprbserr_out,
    rxprbslocked_out => rxprbslocked_out,
    rxstartofseq_out => rxstartofseq_out,
    txpmaresetdone_out => txpmaresetdone_out,
    txprgdivresetdone_out => txprgdivresetdone_out
  );

    -- Instantiate GTY core
	--gty_core0 : entity work.gtwizard_ultrascale_0
	--  port map (
    --    gtwiz_userclk_tx_reset_in => gtwiz_userclk_tx_reset_in,
    --    gtwiz_userclk_tx_srcclk_out => gtwiz_userclk_tx_srcclk_out,
    --    gtwiz_userclk_tx_usrclk_out => gtwiz_userclk_tx_usrclk_out,
    --    gtwiz_userclk_tx_usrclk2_out => gtwiz_userclk_tx_usrclk2_out,
    --    gtwiz_userclk_tx_active_out => gtwiz_userclk_tx_active_out,
    --    gtwiz_userclk_rx_reset_in => gtwiz_userclk_rx_reset_in,
    --    gtwiz_userclk_rx_srcclk_out => gtwiz_userclk_rx_srcclk_out,
    --    gtwiz_userclk_rx_usrclk_out => gtwiz_userclk_rx_usrclk_out,
    --    gtwiz_userclk_rx_usrclk2_out => gtwiz_userclk_rx_usrclk2_out,
    --    gtwiz_userclk_rx_active_out => gtwiz_userclk_rx_active_out,
    --    gtwiz_reset_clk_freerun_in => gtwiz_reset_clk_freerun_in,
    --    gtwiz_reset_all_in => gtwiz_reset_all_in,
    --    gtwiz_reset_tx_pll_and_datapath_in => gtwiz_reset_tx_pll_and_datapath_in,
    --    gtwiz_reset_tx_datapath_in => gtwiz_reset_tx_datapath_in,
    --    gtwiz_reset_rx_pll_and_datapath_in => gtwiz_reset_rx_pll_and_datapath_in,
    --    gtwiz_reset_rx_datapath_in => gtwiz_reset_rx_datapath_in,
    --    gtwiz_reset_rx_cdr_stable_out => gtwiz_reset_rx_cdr_stable_out,
    --    gtwiz_reset_tx_done_out => gtwiz_reset_tx_done_out,
    --    gtwiz_reset_rx_done_out => gtwiz_reset_rx_done_out,
    --    gtwiz_userdata_tx_in => gtwiz_userdata_tx_in,
    --    gtwiz_userdata_rx_out => gtwiz_userdata_rx_out,
    --    drpaddr_common_in => drpaddr_common_in,
    --    drpclk_common_in => drpclk_common_in,
    --    drpdi_common_in => drpdi_common_in,
    --    drpen_common_in => drpen_common_in,
    --    drpwe_common_in => drpwe_common_in,
    --    gtrefclk00_in => gtrefclk00_in,
    --    drpdo_common_out => drpdo_common_out,
    --    drprdy_common_out => drprdy_common_out,
    --    qpll0outclk_out => qpll0outclk_out,
    --    qpll0outrefclk_out => qpll0outrefclk_out,
    --    drpaddr_in => drpaddr_in,
    --    drpclk_in => drpclk_in,
    --    drpdi_in => drpdi_in,
    --    drpen_in => drpen_in,
    --    drpwe_in => drpwe_in,
    --    gtyrxn_in => gtyrxn_in,
    --    gtyrxp_in => gtyrxp_in,
    --    rxcdrhold_in => rxcdrhold_in,
    --    rxgearboxslip_in => rxgearboxslip_in,
    --    txheader_in => txheader_in,
    --    txsequence_in => txsequence_in,
    --    drpdo_out => drpdo_out,
    --    drprdy_out => drprdy_out,
    --    gtpowergood_out => gtpowergood_out,
    --    gtytxn_out => gtytxn_out,
    --    gtytxp_out => gtytxp_out,
    --    rxdatavalid_out => rxdatavalid_out,
    --    rxheader_out => rxheader_out,
    --    rxheadervalid_out => rxheadervalid_out,
    --    rxpmaresetdone_out => rxpmaresetdone_out,
    --    rxstartofseq_out => rxstartofseq_out,
    --    txpmaresetdone_out => txpmaresetdone_out,
    --    txprgdivresetdone_out => txprgdivresetdone_out
    --    );

end block;


gtx_gen: for i in 0 to NUMBER_OF_GT-1 generate

	lane_regs0: entity work.CTRL_SLAVE
		GENERIC MAP (
			DEFAULT_CONTROL_BYTES => X"00_00_01_40_00_00",
			USE_RAM_DOUT_RDY      => TRUE, -- need to wait for the RDY signal on RAM read accesses
			RAM_DATA_WIDTH        => 16,
			RAM_ADDR_WIDTH        => 10, -- GTX DRP Address bus is 10 bits, we use 11 bits of address in the memory-mapepd interface since we access bytes
			NUMBER_OF_CONTROL_BYTES => gt_control_bytes(i)'LENGTH(1), -- Number of bits in the control word
			NUMBER_OF_STATUS_BYTES => gt_status_bytes(i)'LENGTH(1) -- Number of bits in the status word.
	  	)
		PORT MAP(
			CTRL_CMD_IN_DAT   =>   MODULE_CMD_DAT(i+NUMBER_OF_QUADS+1),
			CTRL_CMD_IN_RDY   =>   MODULE_CMD_RDY(i+NUMBER_OF_QUADS+1),
			CTRL_RPLY_OUT_DAT => MODULE_RPLY_DAT(i+NUMBER_OF_QUADS+1),
			CTRL_RPLY_OUT_RDY => MODULE_RPLY_RDY(i+NUMBER_OF_QUADS+1),
			CTRL_CLK          => CTRL_CLK,
			CTRL_RST          => ctrl_rst_reg(i+NUMBER_OF_QUADS+1),

			CONTROL_BYTES => gt_control_bytes(i),
			STATUS_BYTES => gt_status_bytes(i),
			-- DRP interface
			RAM_DIN      => gt_drp_din(i),
			RAM_DOUT     => gt_drp_dout(i),
			RAM_DOUT_RDY => gt_drp_rdy(i),
			RAM_WR_EN    => gt_drp_wr_en(i),
			RAM_EN       => gt_drp_en(i),
			RAM_ADDR     => gt_drp_addr(i)
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
	gt_scramble_en(i)       <= '1'; -- ***JFC Normally 1, 0 for debug
	gt_descramble_en(i)     <= '1'; ---***JFC Normally 1, 0 for debug

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
	gt_status_bytes(i)(0)(0) <= to_std_logic(NUMBER_OF_RX_LINKS > 0); -- Indicates if RX part is present


	-- STATUS BYTE 1-4
	gt_status_bytes(i)(1 to 4) <= to_slv8_array(gt_err_ctr(i)); -- needed for link tests

	-- RX STATUS BYTES
	--------------------
	rxstatus_gen: if NUMBER_OF_RX_LINKS>0 generate
	-- STATUS BYTE 5
		gt_status_bytes(i)(5)(7 downto 6) <= gt_rxheader_capture(i);
		gt_status_bytes(i)(5)(2 downto 0) <= gt_rxbufstatus_out(i);

		-- STATUS BYTE 6
		gt_status_bytes(i)(6)(7) <= gt_rxprbslocked_out(i);
		gt_status_bytes(i)(6)(6 downto 0) <= gt_rxmonitorout_out(i); -- Needed for link tests?

		-- STATUS BYTE 7-10
		gt_status_bytes(i)(7 to 10) <= to_slv8_array(rx_data_capture(i)(31 downto 0)); -- Capture only the lower 31 bits

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




--gtx_i : entity work.xglink_gtx
--	generic map (
--		-- Simulation attributes
--		GT_SIM_GTRESET_SPEEDUP        =>  EXAMPLE_SIM_GTRESET_SPEEDUP,
--		RX_DFE_KL_CFG2_IN             =>  X"301148AC",
--		PMA_RSV_IN                    =>  x"001E7080",
--		PCS_RSVD_ATTR_IN              =>  X"000000000000"
--	)
--	port map (
--		---------------------------- Channel - DRP Ports  --------------------------
--		drpaddr_in                      =>      gt_drp_addr(i),
--		drpclk_in                       =>      CTRL_CLK,
--		drpdi_in                        =>      gt_drp_din(i),
--		drpdo_out                       =>      gt_drp_dout(i),
--		drpen_in                        =>      gt_drp_en(i),
--		drprdy_out                      =>      gt_drp_rdy(i),
--		drpwe_in                        =>      gt_drp_wr_en(i),
--		------------------------------- Clocking Ports -----------------------------
--		qpllclk_in                      =>      qplloutclk(LINK_TO_QUAD_MAP(i)),
--		qpllrefclk_in                   =>      qplloutrefclk(LINK_TO_QUAD_MAP(i)),
--		------------------------------- Loopback Ports -----------------------------
--		loopback_in                     =>      gt_loopback_in(i),
--		----------------------------- PCI Express Ports ----------------------------
--		rxrate_in                       =>      (others => '0'),
--		-------------------------- RX Margin Analysis Ports ------------------------
--		eyescanreset_in                 =>      '0',
--		eyescandataerror_out            =>      open,
--		eyescantrigger_in               =>      '0',
--		------------------------- Receive Ports - CDR Ports ------------------------
--		rxcdrhold_in                    =>      gt_rxcdrhold_in(i),
--		------------------ Receive Ports - FPGA RX Interface Ports -----------------
--		rxusrclk_in                     =>      rxusrclk(i),
--		rxusrclk2_in                    =>      rxusrclk2(i),
--		------------------ Receive Ports - FPGA RX interface Ports -----------------
--		rxdata_out                      =>      gt_rxdata_out(i),
--		------------------- Receive Ports - Pattern Checker Ports ------------------
--		rxprbserr_out                   =>      gt_rxprbserr_out(i),
--		rxprbssel_in                    =>      gt_rxprbssel_in(i),
--		rxprbscntreset_in               =>      gt_rxprbscntreset_in(i),
--		--------------------------- Receive Ports - RX Analog Front End (AFE) ------
--		gtxrxp_in                       =>      rx_p(i),
--		gtxrxn_in                       =>      rx_n(i),

--		------------------- Receive Ports - RX Buffer Bypass Ports -----------------
--		rxbufreset_in                   =>      '0',
--		rxbufstatus_out                 =>      gt_rxbufstatus_out(i),
--		--------------------- Receive Ports - RX Equalizer Ports -------------------
--		rxlpmen_in                      =>      gt_rxlpmen_in(i),
--		rxdfelpmreset_in                =>      gt_rxdfelpmreset_in(i),
--		rxmonitorout_out                =>      gt_rxmonitorout_out(i),
--		rxmonitorsel_in                 =>      gt_rxmonitorsel_in(i),
--		dmonitorout_out                 =>      gt_dmonitorout_out(i),

--		rxlpmhold_in                    =>     gt_rxlpmhold_in(i),
--		rxlpmovrd_in                    =>     gt_rxlpmovrd_in(i),
--		rxdfehold_in(0)                 =>     gt_rxdfeagchold_in(i), -- AGC Hold ( was: gt_rxdfehold_in(i)(0) or gt_rxdfeagchold_in(i))
--		rxdfehold_in(1)                 =>     gt_rxdfelfhold_in(i), --LF Hold (was: gt_rxdfehold_in(i)(1) or gt_rxdfelfhold_in(i))
--		rxdfehold_in(8 downto 2)        =>     gt_rxdfehold_in(i)(8 downto 2),
--		rxdfeovrd_in                    =>     gt_rxdfeovrd_in(i),
--		------------ Receive Ports - RX Fabric ClocK Output Control Ports ----------
--		rxratedone_out                  =>      open,
--		--------------- Receive Ports - RX Fabric Output Control Ports -------------
--		rxoutclk_out                    =>      gt_rxoutclk_out(i),
--		---------------------- Receive Ports - RX Gearbox Ports --------------------
--		rxdatavalid_out                 =>      gt_rxdatavalid_out(i),
--		rxheader_out                    =>      gt_rxheader_out(i),
--		rxheadervalid_out               =>      gt_rxheadervalid_out(i),
--		rxstartofseq_out                =>      gt_rxstartofseq_out(i),
--		rxgearboxslip_in                =>      gt_rxgearboxslip_in(i), -- (was: gt_rxgearboxslip_in(i) and (not gt_stop_bitslip(i)))
--		------------- Receive Ports - RX Initialization and Reset Ports ------------
--		rxuserrdy_in                    =>      gt_rxuserrdy_in(i), --? Was '0' on core: prevents RXRESETDONE to go high?
--		gtrxreset_in                    =>      gt_gtrxreset_all(i),
--		rxpcsreset_in                   =>      '0',
--		rxpmareset_in                   =>      '0',
--		rxresetdone_out                 =>      gt_rxresetdone_out(i),
--		---------------- Receive Ports - RX Polarity Control Ports ----------------
--		rxpolarity_in                   =>      gt_rxpolarity_in(i),
--		------------------- Receive Ports - RX8B/10B Decoder Ports -----------------
--		rxcharisk_out                   =>      open,

--		------------------------ TX Configurable Driver Ports ----------------------
--		txpostcursor_in                 =>      gt_txpostcursor_in(i),
--		txprecursor_in                  =>      gt_txprecursor_in(i),
--		--------------------- TX Initialization and Reset Ports --------------------
--		gttxreset_in                    =>      gt_gttxreset_all(i),
--		txuserrdy_in                    =>      gt_txuserrdy_in(i),
--		------------------ Transmit Ports - FPGA TX Interface Ports ----------------
--		txusrclk_in                     =>      txusrclk,
--		txusrclk2_in                    =>      txusrclk2,
--		------------------ Transmit Ports - Pattern Generator Ports ----------------
--		txprbsforceerr_in               =>      gt_txprbsforceerr_in(i),
--		---------------------- Transmit Ports - TX Buffer Ports --------------------
--		txbufstatus_out                 =>      gt_txbufstatus_out(i),
--		--------------- Transmit Ports - TX Configurable Driver Ports --------------
--		txdiffctrl_in                   =>      gt_txdiffctrl_in(i),
--		txinhibit_in                    =>      gt_txinhibit_in(i),
--		txmaincursor_in                 =>      "0000000", -- controllable through DRP
--		------------------ Transmit Ports - TX Data Path interface -----------------
--		txdata_in                       =>      gt_txdata_in(i),
--		---------------- Transmit Ports - TX Driver and OOB signaling --------------
--		gtxtxn_out                      =>      tx_n(i),
--		gtxtxp_out                      =>      tx_p(i),
--		----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
--		txoutclk_out                    =>      gt_txoutclk_out(i),
--		txoutclkfabric_out              =>      open,
--		txoutclkpcs_out                 =>      open,
--		--------------------- Transmit Ports - TX Gearbox Ports --------------------
--		txheader_in                     =>      gt_txheader_in(i),
--		txsequence_in                   =>      gt_txsequence_in(i),
--		------------- Transmit Ports - TX Initialization and Reset Ports -----------
--		txpcsreset_in                   =>      '0',
--		txpmareset_in                   =>      '0',
--		txresetdone_out                 =>      gt_txresetdone_out(i),
--		----------------- Transmit Ports - TX Polarity Control Ports ---------------
--		txpolarity_in                   =>      gt_txpolarity_in(i),
--		------------------ Transmit Ports - pattern Generator Ports ----------------
--		txprbssel_in                    =>      gt_txprbssel_in(i)
--	);

-----------------------------------------------
-- Minimum RX logic needed to operate BER tests
-----------------------------------------------
-- *** Not used with GTY core
-- Implement RX clock buffer for local logic
--rxoutclk_bufg0 : BUFH
--	port map (
--		I => gt_rxoutclk_out(i),
--		O => rxclk322(i)
--	);

--rxusrclk2(i) <= rxclk322(i);
--rxusrclk(i) <= rxclk322(i);



------------------------------------------------
-- GTX Starttup state machine
------------------------------------------------
-- *** Not used with GTY core
--rx_fsm_soft_reset(i) <= common_user_reset or gt_user_reset(i);
--
	--gt_rxresetfsm_i: entity work.xglink_rx_startup_fsm
	--	generic map(
	--		EXAMPLE_SIMULATION       => EXAMPLE_SIMULATION,
	--		GT_TYPE                  => "GTX", --GTX or GTH or GTP
	--		EQ_MODE                  => "DFE",                 --Rx Equalization Mode - Set to DFE or LPM
	--		STABLE_CLOCK_PERIOD      => STABLE_CLOCK_PERIOD,           --Period of the stable clock driving this state-machine, unit is [ns]
	--		RETRY_COUNTER_BITWIDTH   => 8,
	--		TX_QPLL_USED             => TRUE ,                        -- the TX and RX Reset FSMs must
	--		RX_QPLL_USED             => TRUE,                         -- share these two generic values
	--		PHASE_ALIGNMENT_MANUAL   =>  FALSE                        -- Decision if a manual phase-alignment is necessary or the automatic
	--		                                                          -- is enough. For single-lane applications the automatic alignment is
	--		                                                          -- sufficient
	--		)
	--	port map (
	--		STABLE_CLOCK                    =>      clk156,
	--		RXUSERCLK                       =>      rxusrclk2(i),
	--		SOFT_RESET                      =>      rx_fsm_soft_reset(i),
	--		DONT_RESET_ON_DATA_ERROR        =>      DONT_RESET_ON_DATA_ERROR_IN,
	--		QPLLREFCLKLOST                  =>      '0', --GT_QPLLREFCLKLOST_IN(i),
	--		CPLLREFCLKLOST                  =>      '0',
	--		QPLLLOCK                        =>      qplllock(LINK_TO_QUAD_MAP(i)),
	--		CPLLLOCK                        =>      '1',
	--		RXRESETDONE                     =>      gt_rxresetdone_out(i), --ok
	--		MMCM_LOCK                       =>      '1',
	--		RECCLK_STABLE                   =>      rx_cdrlocked,
	--		RECCLK_MONITOR_RESTART          =>      '0',
	--		DATA_VALID                      =>      '1', --GT_DATA_VALID_IN(i),
	--		TXUSERRDY                       =>      '1',
	--		GTRXRESET                       =>      gt_gtrxreset_in(i),
	--		MMCM_RESET                      =>      open,
	--		QPLL_RESET                      =>      open,
	--		CPLL_RESET                      =>      open,
	--		RX_FSM_RESET_DONE               =>      rx_resetdone_int(i),
	--		RXUSERRDY                       =>      gt_rxuserrdy_in(i),
	--		RUN_PHALIGNMENT                 =>      open,
	--		RESET_PHALIGNMENT               =>      open,
	--		PHALIGNMENT_DONE                =>      '1',
	--		RXDFEAGCHOLD                    =>      gt_rxdfeagchold_in(i),
	--		RXDFELFHOLD                     =>      gt_rxdfelfhold_in(i),
	--		RXLPMLFHOLD                     =>      open, --gt_rxlpmlfhold_in(i),
	--		RXLPMHFHOLD                     =>      open, --gt_rxlpmhfhold_in(i),
	--		RETRY_COUNTER                   =>      open
	--		);




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
tx_gen: for i in  0 to NUMBER_OF_TX_LINKS-1 generate
--    signal tx_data_unscrambled: slv64;
--    signal tx_data_scrambled: slv64;
--    signal tx_data_valid: std_logic;
    signal tx_header_reg: slv2;
    signal tx_data_reg: slv64 := (others=>'0'); -- init for sim
--    signal tx_header_valid: std_logic;
    signal tx_data_unscr: slv64 := (others=> '0'); -- init for sim
    signal tx_header_unscr: slv2 := (others=> '0'); -- init for sim
    signal tx_data_scr: slv64 := (others=> '0'); -- init for sim
    signal tx_header_scr: slv2 := (others=> '0'); -- init for sim


begin

-- ** Not use with GTY core
	tx_fsm_soft_reset(i) <= common_user_reset or gt_user_reset(i);

	--gt_txresetfsm: entity work.xglink_tx_startup_fsm
	--	generic map(
	--		STABLE_CLOCK_PERIOD      => STABLE_CLOCK_PERIOD,           -- Period of the stable clock driving this state-machine, unit is [ns]
	--		RETRY_COUNTER_BITWIDTH   => 8,
	--		TX_QPLL_USED             => TRUE ,                        -- the TX and RX Reset FSMs must
	--		RX_QPLL_USED             => TRUE,                         -- share these two generic values
	--		PHASE_ALIGNMENT_MANUAL   => FALSE                 -- Decision if a manual phase-alignment is necessary or the automatic
	--		                                                         -- is enough. For single-lane applications the automatic alignment is
	--		                                                         -- sufficient
	--		)
	--port map (
	--	STABLE_CLOCK                    =>      clk156,
	--	TXUSERCLK                       =>      txusrclk2,
	--	SOFT_RESET                      =>      tx_fsm_soft_reset(i),
	--	QPLLREFCLKLOST                  =>      '0', -- GT_QPLLREFCLKLOST_IN(i),
	--	CPLLREFCLKLOST                  =>      '0',
	--	QPLLLOCK                        =>      qplllock(LINK_TO_QUAD_MAP(i)),
	--	CPLLLOCK                        =>      '1',
	--	TXRESETDONE                     =>      gt_txresetdone_out(i), --ok
	--	MMCM_LOCK                       =>      '1',
	--	GTTXRESET                       =>      gt_gttxreset_in(i), --ok
	--	MMCM_RESET                      =>      open,
	--	QPLL_RESET                      =>      open, --gt_qpllreset_t(i),
	--	CPLL_RESET                      =>      open,
	--	TX_FSM_RESET_DONE               =>      tx_resetdone_int(i),
	--	TXUSERRDY                       =>      gt_txuserrdy_in(i),
	--	RUN_PHALIGNMENT                 =>      open,
	--	RESET_PHALIGNMENT               =>      open,
	--	PHALIGNMENT_DONE                =>      '1',
	--	RETRY_COUNTER                   =>      open
	--	);



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

	gt_txsequence_in(i) <= "0" & std_logic_vector(gt_seq_counter(i)(6 downto 1));

	process(txusrclk2)
	begin
		if rising_edge(txusrclk2) then
			if tx_resetdone_int(i)='0' or gt_seq_counter(i) = 65 then
			     gt_seq_counter(i) <= (others => '0');
			else
			     gt_seq_counter(i) <= gt_seq_counter(i) + 1;
			end if;
			if gt_seq_counter(i)(6 downto 1) = 31 then
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

				tx_data_reg <= tx_data(i);
				tx_header_reg <= tx_header(i);


				tx_header_scr <= tx_header_unscr; -- delay header to compensate for the scrambler latency

				if gt_user_source_sel(i)='1' then -- select values from registers
					tx_data_unscr <= gt_user_tx_data_int(i);
					tx_header_unscr <= gt_user_tx_header(i);
				else -- select values from module input
					tx_data_unscr <= reverse_bytes(tx_data_reg);
					tx_header_unscr <= tx_header_reg;
--					tx_data_int(i) <= (others => '0'); ---*** JFC debug
				end if;

			end if; -- tx_ready_int='1'

		end if; --clk
	end process;


	------------------------------------------------
	-- SCRAMBLER
	------------------------------------------------


	gt_txdata_in(i) <= reverse_bits_same_dir(tx_data_scr) when gt_scramble_en(i)='1' else reverse_bits_same_dir(tx_data_unscr); -- first bit transmitted is in the MSB
    gt_txheader_in(i) <= tx_header_scr when gt_scramble_en(i)='1' else tx_header_unscr;
	scrambler_reset(i) <= not tx_resetdone_int(i) or gt_scrambler_reset(i);

	scrambler0: entity work.xxvglink_scrambler
		port map (
			-- User Interface
			unscrambled_data_in => tx_data_unscr, -- first bit transmitted is in the LSB
			scrambled_data_out  => tx_data_scr, -- first bit transmitted is in the LSB
			data_valid_in       => tx_ready_int(i),

			-- System Interface
			USER_CLK            => txusrclk2,
			SYSTEM_RESET        => scrambler_reset(i)
	    );

end generate; -- for NUMBER_OF_TX_LINKS



----------------------------------------------
-- RX Data Logic
----------------------------------------------
rx_gen: for i in  0 to NUMBER_OF_RX_LINKS-1 generate
    signal rx_data_unscr: slv64;
    signal rx_data_valid_unscr: std_logic;
    signal rx_header_unscr: slv2;
    signal rx_header_valid_unscr: std_logic;
--    signal rx_data_scr: slv64;
--    signal rx_data_valid_scr: std_logic;
--    signal rx_data_unscr: slv64;
--    signal rx_data_valid_unscr: std_logic;



begin
	rx_clk(i) <= rxusrclk2(i); --! Danger Will Robinson! In sims, the clock assignment might be evaluated AFTER the output signals are evaluated, causing the data to appear on the wrong clock. That's why we have a DLY for each output purt assignments.


	------------------------------------------------
	-- RX BLOCK SYNCHRONIZATION
	------------------------------------------------
	block_sync_reset(i) <= not gt_rxresetdone_out(i) or gt_block_lock_reset(i);

	block_sync0 :  entity work.xxvglink_block_sync
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
			RXHEADER_IN               =>    gt_rxheader_out(i),
			RXHEADERVALID_IN          =>    gt_rxheadervalid_out(i),

			-- System Interface
			clk                  =>    rxusrclk2(i),
			rst                  => block_sync_reset(i)
		);

	------------------------------------------------
	-- RX DESCRAMBLER
	------------------------------------------------

	rx_resetdone(i) <= rx_resetdone_int(i) after DLY;

		-- Capture descrambled or unscambled data when valid and capture=1
	process(rxusrclk2(i))
	begin
	      if rising_edge(rxusrclk2(i)) then
            -- Compensate unscrambler latency
   			rx_data_valid_unscr <= gt_rxdatavalid_out(i) after DLY;
    		rx_header_unscr <= gt_rxheader_out(i) after DLY;
			rx_header_valid_unscr <= gt_rxheadervalid_out(i) after DLY;

			if rx_resetdone_int(i)='0' or gt_block_lock(i)='0' then -- Added reset to try to prevent spurious sends after reset
				rx_header_unscr <="00";
				rx_header_valid_unscr <= '0';
				rx_data_valid_unscr <= '0';
			end if;

            if gt_descramble_en(i)='1' then
                rx_data(i) <= reverse_bytes(rx_data_unscr) after DLY; -- first byte received is in bits 31-24 (MSB-LSB)
                rx_data_valid(i) <= rx_data_valid_unscr after DLY;
                rx_header(i) <= rx_header_unscr after DLY;
                rx_header_valid(i) <= rx_header_valid_unscr after DLY;
            else
                rx_data(i) <= reverse_bytes(reverse_bits_same_dir(gt_rxdata_out(i))) after DLY; -- first byte received is in bits 31-24 (MSB-LSB)
                rx_data_valid(i) <= gt_rxdatavalid_out(i) and gt_block_lock(i) after DLY;
                rx_header(i) <= gt_rxheader_out(i) after DLY;
                rx_header_valid(i) <= gt_rxheadervalid_out(i) and gt_block_lock(i) after DLY;
            end if;

            -- Word capture logic
			gt_capture_en_rxusrclk2(i)(1) <= gt_capture_en(i);
			gt_capture_en_rxusrclk2(i)(0) <= gt_capture_en_rxusrclk2(i)(1);
			if gt_capture_en_rxusrclk2(i)(0)='1' then
				if gt_descramble_en(i)='0' and gt_rxdatavalid_out(i)='1' then
					rx_data_capture(i) <= reverse_bits_same_dir(gt_rxdata_out(i));
				elsif gt_descramble_en(i)='1' and rx_data_valid_unscr='1' then
					rx_data_capture(i) <= rx_data_unscr;
				end if;
				if gt_rxheadervalid_out(i)='1' then
					gt_rxheader_capture(i) <= gt_rxheader_out(i);
				end if;
			end if;


	      end if; -- clk
	end process;



	-- Descramble
	descrambler0  :  entity work.xxvglink_descrambler
	    port map (
	        -- User Interface
	        scrambled_data_in     =>     reverse_bits_same_dir(gt_rxdata_out(i)), -- first bit received is in the LSB
	        data_valid_in         =>     gt_rxdatavalid_out(i),
	        unscrambled_data_out  =>     rx_data_unscr, -- first bit received is in the LSB

	        -- System Interface
	        clk => rxusrclk2(i),
	        rst => gt_unscrambler_reset(i) or not gt_block_lock(i)
	    );
end generate; -- if RX in implemented


end Behavioral;
