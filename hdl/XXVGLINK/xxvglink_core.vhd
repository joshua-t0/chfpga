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
use UNISIM.VComponents.ALL;

library xpm;
use xpm.vcomponents.ALL;

library work;
use work.chFPGA_Package.ALL;

entity xxvglink_core is
	generic (
		LINK_TO_QUAD_MAP: integer_array        := (0 to 1=> 0, 2 => 1); -- LINK_TO_QUAD_MAP Indicates which quad is associated each channel. The QUAD number is an integer between 0 and N-1, where N is the total number of quads used.
		QUAD_TO_REFCLK_MAP: integer_array      := (0, 0); -- QUAD_TO_REFCLK_MAP Indicates which refclk is associated with each QUAD (N integers from 0 to NUMBER_OF_REFCLK-1).
		USED_LINKS: integer_array := (others => 0); -- list of links that are used. The others will be stripped from scrambling/unscrambling/block locking logic
		IMPLEMENT_TX: boolean                  := TRUE;
		IMPLEMENT_RX: boolean                  := TRUE;
		DONT_RESET_ON_DATA_ERROR_IN: std_logic := '0';
		NUMBER_OF_CONTROL_BYTES: integer       := 0; -- Number of additional control bytes to be appended to the common control register array
		NUMBER_OF_STATUS_BYTES: integer        := 0; -- Number of additional status bytes to be appended to the common status register array

		-- Derived parameters
		NUMBER_OF_REFCLK: integer   := max(QUAD_TO_REFCLK_MAP) + 1;
		NUMBER_OF_RX_LINKS: integer := sel(IMPLEMENT_RX, LINK_TO_QUAD_MAP'LENGTH, 0);
		NUMBER_OF_TX_LINKS: integer := sel(IMPLEMENT_TX, LINK_TO_QUAD_MAP'LENGTH, 0);
		NUMBER_OF_LINKS: integer    := max(NUMBER_OF_RX_LINKS, NUMBER_OF_TX_LINKS); -- computed value - do not override

		-- Simulation parameters
		EXAMPLE_SIMULATION: integer         := 1;
		EXAMPLE_SIM_GTRESET_SPEEDUP: string := "TRUE";    -- simulation setting for GT SecureIP model
		SIM: boolean                        := false
	);
	port (
		tx_p: out std_logic_vector(0 to NUMBER_OF_LINKS - 1);
		tx_n: out std_logic_vector(0 to NUMBER_OF_LINKS - 1);
		rx_p: in std_logic_vector(0 to NUMBER_OF_LINKS - 1);
		rx_n: in std_logic_vector(0 to NUMBER_OF_LINKS - 1);
		refclk_p: in std_logic_vector(0 to NUMBER_OF_REFCLK - 1); -- 156.250 high quality reference clocks to feed all the quads in the array. One reference clock can feed the bank it is  on, and the banks above and below.
		refclk_n: in std_logic_vector(0 to NUMBER_OF_REFCLK - 1);

		refclk_div2: out std_logic_vector(0 to NUMBER_OF_REFCLK - 1); -- 156.25 MHz reference clock
		txclk_div2: out std_logic; -- Data clock generated from MMCM

		tx_data: in slv64_array(0 to NUMBER_OF_TX_LINKS - 1); -- The most significant byte is transmitted first
		tx_header: in slv2_array(0 to NUMBER_OF_TX_LINKS - 1);
		tx_ready: out std_logic_vector(0 to NUMBER_OF_TX_LINKS - 1); -- Indicates when the transmitter will accept the data on the data bus
		tx_clk: out std_logic; -- 244.140625 MHz for LINK_SPEED=0, 322.265615 MHz for LINK_SPEED=1.
		tx_resetdone: out std_logic_vector(0 to NUMBER_OF_TX_LINKS - 1); -- Indicates that the transmitter is ready to send data

		rx_data: out slv64_array(0 to max(NUMBER_OF_RX_LINKS - 1, 0));
		rx_data_valid: out std_logic_vector(0 to max(NUMBER_OF_RX_LINKS - 1, 0)); -- Active high when  valid data is  placed on the bus
		rx_header: out slv2_array(0 to max(NUMBER_OF_RX_LINKS - 1, 0));
		rx_header_valid: out std_logic_vector(0 to max(NUMBER_OF_RX_LINKS - 1, 0)); -- Indicates when the header is valid. This happen on the first half of each word.
		rx_clk: out std_logic_vector(0 to max(NUMBER_OF_RX_LINKS - 1, 0)); -- clock synchronous with the rx data. Recovered from the received link.
		rx_resetdone: out std_logic_vector(0 to max(NUMBER_OF_RX_LINKS - 1, 0)); -- Indicates that the receiver is ready to receive data

		stable_clk: in std_logic; -- free-running stable clock for reset state machines.

		control_bytes: out slv8_array(0 to NUMBER_OF_CONTROL_BYTES - 1); -- additional control bytes appended to the common control registers
		status_bytes: in slv8_array(0 to NUMBER_OF_STATUS_BYTES - 1) := (others => (others => '0')); -- additional status bytes appended to the common status registers

		-- Control and reply streams
		cmd_dat: in AXIS8_DAT_STRUCT;
		cmd_rdy: out AXIS8_RDY_STRUCT;
		rply_dat: out AXIS8_DAT_STRUCT;
		rply_rdy: in AXIS8_RDY_STRUCT;
		ctrl_clk: in std_logic; -- control clock
		ctrl_rst: in std_logic;

		areset: in std_logic -- asynchronous reset
	);
end entity xxvglink_core;

architecture behavioral of xxvglink_core is

	attribute ASYNC_REG: string;
	attribute SHREG_EXTRACT: string;
	attribute DONT_TOUCH: string;

	--- CONSTANTS
	constant DLY: time := 10 ps; -- delta delay used to ensure the simulator changes the data after the clock edge (which is a problem because we do a clock assignment which might be evaluated in any order)
	constant NUMBER_OF_QUADS: integer := MAX(LINK_TO_QUAD_MAP(0 to NUMBER_OF_LINKS - 1)) + 1; -- get the maximum QUAD index from the list of actually implemented channels
	constant NUMBER_OF_MODULES: integer := NUMBER_OF_QUADS + NUMBER_OF_LINKS + 1; -- One common module, and one for each quad (QPLL) and channel (GTX)
	constant MODULE_ADDR_WIDTH: integer := 10; -- number of remaining addressable space for each module


	---- CLOCKS
	signal txusrclk2: std_logic; -- txusrclk2 for all GTX
	signal rxusrclk2: slv(0 to NUMBER_OF_LINKS - 1); -- rxusrclk2 for all GTX

	signal refclk_nobuf: std_logic_vector(0 to NUMBER_OF_REFCLK - 1); -- unbuffered GTX reference clock
	signal refclk_buf: std_logic_vector(0 to NUMBER_OF_REFCLK - 1); -- buffered GTX reference clock

	-- Reset signals

	signal reset_all: std_logic; -- all reset sources combined, including manual and ffrom reset FSM
	--signal reset_rx_datapath: std_logic; -- reset from reset FSM to GTY
	signal tx_reset: std_logic_vector(0 to NUMBER_OF_LINKS - 1); -- User Tx logic reset from reset FSM
	signal rx_reset: std_logic_vector(0 to NUMBER_OF_LINKS - 1); -- User Rx logic reset from reset FSM
	signal tx_resetdone_int: std_logic_vector(0 to NUMBER_OF_LINKS - 1); -- User TX reset done, in txclk clock domain
	signal rx_resetdone_int: std_logic_vector(0 to NUMBER_OF_LINKS - 1); -- User RX reset done, in rxclk clock domain


	--- QPLL signals
	signal qpllreset: std_logic; -- QPLL reset signal for all QPLLs, generated after 500us following the release of areset
	signal qplloutclk: std_logic_vector(0 to NUMBER_OF_QUADS - 1);
	signal qplloutrefclk: std_logic_vector(0 to NUMBER_OF_QUADS - 1);
	signal qplllock, qplllock_debug: std_logic_vector(0 to NUMBER_OF_QUADS - 1);
	signal not_qplllock: std_logic;

	signal module_cmd_dat: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_MODULES - 1 downto 0);
	signal module_cmd_rdy: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_MODULES - 1 downto 0);
	signal module_rply_dat: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_MODULES - 1 downto 0);
	signal module_rply_rdy: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_MODULES - 1 downto 0);

	signal ctrl_rst_reg: std_logic_vector(NUMBER_OF_MODULES - 1 downto 0);
	attribute dont_touch of ctrl_rst_reg: signal is "true";
	attribute shreg_extract of ctrl_rst_reg: signal is "false";

	signal quad_drp_dout: slv16_array(NUMBER_OF_QUADS - 1 downto 0);
	signal quad_drp_din: slv16_array(NUMBER_OF_QUADS - 1 downto 0);
	signal quad_drp_addr: slv10_array(NUMBER_OF_QUADS - 1 downto 0);
	signal quad_drp_drdy: slv(NUMBER_OF_QUADS - 1 downto 0);
	signal quad_drp_den: slv(NUMBER_OF_QUADS - 1 downto 0);
	signal quad_drp_wr_en: slv(NUMBER_OF_QUADS - 1 downto 0);

	signal common_control_bytes: slv8_array(0 to 3 + NUMBER_OF_CONTROL_BYTES);
	signal common_status_bytes: slv8_array(0 to 1 + NUMBER_OF_STATUS_BYTES);

	type quad_control_bytes_array is array (natural range <>) of slv8_array(0 to 0);

	signal quad_control_bytes: quad_control_bytes_array(0 to NUMBER_OF_QUADS - 1);

	type quad_status_bytes_array is array (natural range <>) of slv8_array(0 to 0);

	signal quad_status_bytes: quad_status_bytes_array(0 to NUMBER_OF_QUADS - 1);

	type gt_control_bytes_array is array (natural range <>) of slv8_array(0 to 5);

	signal gt_control_bytes: gt_control_bytes_array(0 to NUMBER_OF_LINKS - 1);

	type gt_status_bytes_array is array (natural range <>) of slv8_array(0 to sel(NUMBER_OF_RX_LINKS>0, 11, 4));

	signal gt_status_bytes: gt_status_bytes_array(0 to NUMBER_OF_LINKS - 1);

	signal common_user_reset: std_logic;
	signal common_user_tx_data: std_logic_vector(23 downto 0);
	signal common_rx_pll_datapath_reset: std_logic;
	signal common_tx_pll_datapath_reset: std_logic;
	signal common_rx_datapath_reset: std_logic;
	signal common_tx_datapath_reset: std_logic;
	signal common_rx_cdr_stable_out: std_logic;
	signal common_drp_page: std_logic_vector(0 downto 0);

	-------------------------------------------------------------------
	signal gt_drp_dout: slv16_array(NUMBER_OF_LINKS - 1 downto 0);
	signal gt_drp_din: slv16_array(NUMBER_OF_LINKS - 1 downto 0);
	signal gt_drp_addr: slv9_array(NUMBER_OF_LINKS - 1 downto 0); -- GTY needs 10 bits, 9 bits (word address) available in address space. Use page register for upper bit.
	signal gt_drp_rdy: slv(NUMBER_OF_LINKS - 1 downto 0);
	signal gt_drp_en: slv(NUMBER_OF_LINKS - 1 downto 0);
	signal gt_drp_wr_en: slv(NUMBER_OF_LINKS - 1 downto 0);

	--constant STABLE_CLOCK_PERIOD: integer := 6; -- in fact 1/156.25 = 6.4 ns
	--constant WAIT_TIME_CDRLOCK: integer := sel(SIM, 1000,  50000 / integer(10.3125)) / STABLE_CLOCK_PERIOD;

	signal gt_dmonitorout_out: slv8_array(0 to NUMBER_OF_LINKS - 1);
	signal gt_rxmonitorout_out: slv8_array(0 to NUMBER_OF_LINKS - 1);
	signal gt_rxmonitorsel_in: slv2_array(0 to NUMBER_OF_LINKS - 1) := (others => "00");

	signal gt_loopback_in: slv3_array(0 to NUMBER_OF_LINKS - 1);
	signal gt_rxdata_out: slv64_array(0 to NUMBER_OF_LINKS - 1);
	signal gt_rxprbserr_out: slv(0 to NUMBER_OF_LINKS - 1);
	signal gt_rxprbslocked_out: slv(0 to NUMBER_OF_LINKS - 1);
	signal gt_rxprbssel_in: slv3_array(0 to NUMBER_OF_LINKS - 1) := (others => "000");
	signal gt_txprbssel_in: slv3_array(0 to NUMBER_OF_LINKS - 1) := (others => "000");
	signal gt_rxprbscntreset_in: slv(0 to NUMBER_OF_LINKS - 1) := (others => '0');
	signal gt_rxbufstatus_out: slv3_array(0 to NUMBER_OF_LINKS - 1); -- unused
	signal gt_rxdfeagchold_in: slv(0 to NUMBER_OF_LINKS - 1);
	signal gt_rxdfelfhold_in: slv(0 to NUMBER_OF_LINKS - 1);
	signal gt_rxdatavalid_out: slv(0 to NUMBER_OF_LINKS - 1);
	signal gt_rxheader_out: slv2_array(0 to NUMBER_OF_LINKS - 1);
	signal gt_rxheader_capture: slv2_array(0 to NUMBER_OF_LINKS - 1);
	signal gt_rxheadervalid_out: slv(0 to NUMBER_OF_LINKS - 1);
	signal gt_rxgearboxslip_in: slv(0 to NUMBER_OF_LINKS - 1) := (others => '0');
	signal gt_rxgearboxforceslip: slv(0 to NUMBER_OF_LINKS - 1);
	signal gt_txpostcursor_in: slv5_array(0 to NUMBER_OF_LINKS - 1);
	signal gt_txprecursor_in: slv5_array(0 to NUMBER_OF_LINKS - 1);
	signal gt_txprbsforceerr_in: slv(0 to NUMBER_OF_LINKS - 1) := (others => '0');
	signal gt_txbufstatus_out: slv2_array(0 to NUMBER_OF_LINKS - 1); -- unused
	signal gt_txdiffctrl_in: slv4_array(0 to NUMBER_OF_LINKS - 1);
	signal gt_txinhibit_in: slv(0 to NUMBER_OF_LINKS - 1);
	signal gt_txdata_in: slv64_array(0 to NUMBER_OF_LINKS - 1);
	signal gt_user_tx_data: slv64_array(0 to NUMBER_OF_LINKS - 1);
	signal gt_user_source_sel: slv(0 to NUMBER_OF_LINKS - 1);
	signal gt_txheader_in: slv2_array(0 to NUMBER_OF_LINKS - 1);
	signal gt_user_tx_header: slv2_array(0 to NUMBER_OF_LINKS - 1);
	signal gt_txsequence_in: unsigned_array(0 to NUMBER_OF_LINKS - 1)(6 downto 0);
	--signal gt_rxresetdone_out: slv(0 to NUMBER_OF_LINKS - 1); -- txresetdone from GTY
	--signal gt_txresetdone_out: slv(0 to NUMBER_OF_LINKS - 1); -- rxresetdone form GTY
	signal gt_block_lock: slv(0 to NUMBER_OF_LINKS - 1) := (others => '0'); -- default provided to attempt to squash undriven warnings when there is no RX
	signal gt_scramble_en: slv(0 to NUMBER_OF_LINKS - 1);
	signal gt_descramble_en: slv(0 to NUMBER_OF_LINKS - 1);
	signal gt_block_lock_reset: slv(0 to NUMBER_OF_LINKS - 1) := (others => '0');
	signal gt_scrambler_reset: slv(0 to NUMBER_OF_LINKS - 1);
	signal gt_unscrambler_reset: slv(0 to NUMBER_OF_LINKS - 1);
	signal gt_err_ctr: slv32_array(0 to NUMBER_OF_LINKS - 1);
	signal gt_capture_en: slv(0 to NUMBER_OF_LINKS - 1) := (others => '0');
	signal gt_user_gtrxreset: slv(0 to NUMBER_OF_LINKS - 1) := (others => '0'); -- unused

	signal gt_rxdfelpmreset_in: slv(0 to NUMBER_OF_LINKS - 1) := (others => '0');
	signal gt_rxlpmen_in: slv(0 to NUMBER_OF_LINKS - 1) := (others => '0');

	-- User data interface
	signal tx_ready_int: slv(0 to NUMBER_OF_LINKS - 1);

	signal rx_data_capture: slv64_array(0 to NUMBER_OF_LINKS - 1);

begin

	ctrl_rst_proc: process(ctrl_clk)
	begin
		if rising_edge(ctrl_clk) then
			ctrl_rst_reg <= (others => ctrl_rst);
		end if; -- clk
	end process;

	---------------------------------------------------------------------
	-- Instantiate the BSB packet router
	-- Routes the commands to the requested module
	bsb_router0: entity work.bsb_router
		generic map (
			NUMBER_OF_PORTS => NUMBER_OF_MODULES,
			ADDRESS_MASK    => "-----1111----------" -- 4-bit routing address (1 common, 4 PLL max, 11 GTY max),  10-bit internal address
		)
		port map (
			-- Master control interface
			cmd_in_dat   => cmd_dat,
			cmd_in_rdy   => cmd_rdy,
			rply_out_dat => rply_dat,
			rply_out_rdy => rply_rdy,


			cmd_out_dat => module_cmd_dat,
			cmd_out_rdy => module_cmd_rdy,
			rply_in_dat => module_rply_dat,
			rply_in_rdy => module_rply_rdy,

			clk => ctrl_clk,
			rst => ctrl_rst
		);

	----------------------------------
	-- MGT REFERENCE CLOCK BUFFERS
	----------------------------------

	-- We have up to NUMBER_OF_REFCLK reference clocks to clock the GTXes. These are physically assigned to pins so at least one can reach each of the QPLL used in the array.
	-- Every refclk is received by a IBUFDS_GTE2
	-- refclk[0] (aka clk156) is sent to a BUFG to be used as an always-on control logic clock and frequency monitor. The control logic can be spread across multiple clock regions.
	-- refclk[1:n] are send to BUFH to be used only in the frequency monitor located in the bank where it arrives.
	refclk_blk: block
		signal refclk_div_nobuf: std_logic_vector(0 to NUMBER_OF_REFCLK - 1); -- unbuffered GTX reference clock
	begin

		-- Instantiate reference clock buffers for each reference clock
		ibuf_gen: for i in 0 to NUMBER_OF_REFCLK - 1 generate
			-- Instantiate differential input buffer
			ibufds0: IBUFDS_GTE4
				generic map ( -- we need to profide these generics otherwise we have failed nets on refclk_nobuf
					REFCLK_EN_TX_PATH  => '0', -- Reserved
					REFCLK_HROW_CK_SEL => "00", -- ODIV2 output selection: "00"=divide by 1, "01"= divide by 2, "10"=1, "11"=reserved
					REFCLK_ICNTL_RX    => "00" -- Reserved; use value from wizard
				)
				port map (
					i     => refclk_p(i),
					ib    => refclk_n(i),
					odiv2 => refclk_div_nobuf(i), -- refclk_buf(i), -- **JFC was open
					ceb   => '0',
					o     => refclk_nobuf(i)
				);
			div2_gen: if i = 0 generate
			-- Instantiate global clock buffers
			refclk_bufg0: BUFG_GT
				port map (
					i       => refclk_div_nobuf(i),
					o       => refclk_buf(i),
					ce      => '1',
					cemask  => '0',
					clr     => '0',
					clrmask => '0',
					div     => "000"
				);

			-- Generate REFCLK divided-by-two signal for clock monitoring
			process(all) begin
				if rising_edge(refclk_buf(i)) then
					refclk_div2(i) <= not refclk_div2(i);
				end if;
			end process;
		end generate div2_gen;
		end generate ibuf_gen; -- for each refclk

	end block refclk_blk;

	-------------------------------------------------------------------------------
	-- MASTER RESET SEQUENCER
	-------------------------------------------------------------------------------

	reset_all         <= areset or common_user_reset;
	--reset_rx_datapath <= common_rx_reset;

	--rst_blk: block
	--	constant P_FREERUN_FREQUENCY: real     := 200.0; -- MHz, worst case
	--	constant P_TX_TIMER_DURATION_US: real  := sel(SIM, 25.0, 30000.0); -- us
	--	constant P_RX_TIMER_DURATION_US: real  := sel(SIM, 40.0, 130000.0); -- us

	--	constant P_TX_TIMER_TERM_CYC_INT: unsigned(24 downto 0) := to_unsigned(integer(P_TX_TIMER_DURATION_US * P_FREERUN_FREQUENCY), 25);
	--	constant P_RX_TIMER_TERM_CYC_INT: unsigned(24 downto 0) := to_unsigned(integer(P_RX_TIMER_DURATION_US * P_FREERUN_FREQUENCY), 25);

	--	signal reset_all_out: std_logic;
	--	signal reset_all_sync: std_logic;
	--	signal reset_rx_out: std_logic;
	--	signal tx_resetdone_sync: std_logic; -- resetdone sync'ed to stable_clk
	--	signal rx_resetdone_sync: std_logic;
	--	--signal rx_data_good_sync: std_logic := '1';
	--	signal init_done_out: std_logic; -- not used

	--	signal timer_clr: std_logic := '1';
	--	signal timer_ctr: unsigned (24 downto 0) := (others => '0');
	--	signal tx_timer_sat, rx_timer_sat: std_logic;

	--	signal retry_ctr_incr: std_logic;
	--	signal retry_ctr_out: unsigned(3 downto 0) := (others => '0');

	--	type state_type is (ST_START, ST_TX_WAIT, ST_RX_WAIT, ST_MONITOR);

	--	signal state: state_type := ST_START;
	--	signal sm_init_active: std_logic;
	--begin
	--	reset_all         <= areset or common_user_reset or reset_all_out;
	--	reset_rx_datapath <= reset_rx_out;



	--	rall_cdc0: xpm_cdc_single
	--		generic map (
	--			SRC_INPUT_REG => 0
	--		)
	--		port map (
	--			src_clk  => '0',
	--			src_in   => reset_all,
	--			dest_clk => stable_clk,
	--			dest_out => reset_all_sync
	--		);

	--	txdone_cdc0: xpm_cdc_single
	--		generic map (
	--			SRC_INPUT_REG => 0
	--		)
	--		port map (
	--			src_clk  => '0',
	--			src_in   => and tx_resetdone_int,
	--			dest_clk => stable_clk,
	--			dest_out => tx_resetdone_sync
	--		);

	--	rxdone_cdc0: xpm_cdc_single
	--		generic map (
	--			SRC_INPUT_REG => 0
	--		)
	--		port map (
	--			src_clk  => '0',
	--			src_in   => and rx_resetdone_int,
	--			dest_clk => stable_clk,
	--			dest_out => rx_resetdone_sync
	--		);

	--	process(all) begin
	--		-- Timer: raises the tx and rx timout flags after specified time
	--		if rising_edge(stable_clk) then
	--			timer_clr      <= '0'; -- single pulse
	--			tx_timer_sat <= '1' when timer_ctr = P_TX_TIMER_TERM_CYC_INT;
	--			rx_timer_sat <= '1' when timer_ctr = P_RX_TIMER_TERM_CYC_INT;
	--			timer_ctr <= timer_ctr + 1 when not rx_timer_sat;
	--			if timer_clr then
	--				timer_ctr    <= (others => '0');
	--				tx_timer_sat <= '0';
	--				rx_timer_sat <= '0';
	--			end if;

	--			-- count retries
	--			retry_ctr_incr <= '0'; -- single pulse
	--			retry_ctr_out <= retry_ctr_out + 1 when ??retry_ctr_incr and not all_ones(retry_ctr_out);

	--			-- State machine
	--			case state is

	--				when ST_START =>
	--					if sm_init_active then
	--						timer_clr      <= '1';
	--						reset_all_out  <= '0';
	--						reset_rx_out   <= '0';
	--						state          <= ST_TX_WAIT;
	--					end if;

	--				when ST_TX_WAIT =>
	--					if tx_resetdone_sync then
	--						timer_clr <= '1';
	--						state   <= ST_RX_WAIT;
	--					elsif tx_timer_sat then
	--						timer_clr      <= '1'; -- redundant
	--						reset_all_out  <= '1';
	--						retry_ctr_incr <= '1';
	--						state          <= ST_START;
	--					end if;

	--				when ST_RX_WAIT =>
	--					if rx_timer_sat then
	--						if rx_resetdone_sync then
	--							init_done_out <= '1';
	--							state         <= ST_MONITOR;
	--						else
	--							timer_clr      <= '1';
	--							reset_rx_out   <= '1';
	--							retry_ctr_incr <= '1';
	--							state          <= ST_START;
	--						end if; -- rx done
	--					else
	--						timer_clr <= '0';
	--					end if; -- rx timeout

	--				when ST_MONITOR =>
	--					if not rx_resetdone_sync then
	--						init_done_out  <= '0';
	--						timer_clr      <= '1';
	--						reset_rx_out   <= '1';
	--						retry_ctr_incr <= '1';
	--						state          <= ST_START;
	--					end if;

	--			end case;

	--			-- State machine reset
	--			if reset_all_sync then
	--				timer_clr      <= '1';
	--				reset_all_out  <= '0';
	--				reset_rx_out   <= '0';
	--				retry_ctr_incr <= '0';
	--				init_done_out  <= '0';
	--				sm_init_active <= '1';
	--				state          <= ST_START;
	--			end if; -- reset
	--		end if; -- clk
	--	end process;

	--end block rst_blk;

	----------------------------------
	-- REFERENCE CLOCK-BASED RESETS
	----------------------------------
	-- Common Registers Memory Map
	-- ------------------------------------------------------------------------------
	-- |  Page   | Addr|Bit(s)|     Name             | Description                   |
	-- |---------|-----|------|----------------------|-------------------------------|
	-- | CONTROL |  0  |  7   | common_user_reset    | User reset |
	-- |         |     |  4   | common_drp_page      | DRP page selection |
	-- |         |     |  3   | common_tx_datapath_reset | TX datapath reset (core only) |
	-- |         |     |  2   | common_rx_pll_datapath_reset | RX PLL datapath reset (core only) |
	-- |         |     |  1   | common_rx_datapath_reset | RX datapath reset (core only) |
	-- |         |     |  0   | common_tx_pll_datapath_reset | TX PLL datapath reset (core only) |
	-- |         | 1-3 | 23:0 | common_user_tx_data   | User TX data (24 bits) |
	-- |         | 4+  | -    | control_bytes         | Per-link control bytes (passed to individual links) |
	-- | STATUS  |  0  | 7:5  | NUMBER_OF_QUADS       | Number of quads |
	-- |         |     | 4:0  | NUMBER_OF_LINKS      | Number of links |
	-- |         |  1  |  4   | (tx_reset and rx_reset status) | TX and RX reset status |
	-- |         |     |  3   | qpllreset            | QPLL reset status |
	-- |         |     |  2   | common_rx_cdr_stable_out | RX CDR stable (core only) |
	-- |         |     | 1:0  | (unused)             |                               |
	-- |         |     |  5   | (unused)             |                               |
	-- |         |     | 7:6  | (unused)             |                               |
	-- |         | 2+  | -    | status_bytes         | Per-link status bytes (from individual links) |
	-- ------------------------------------------------------------------------------
	-- Note: This module also has per-quad and per-lane bsb_regs instances for DRP access.
	-- See quad_regs0 and lane_regs0 instances for per-instance memory maps.

	common_regs0: entity work.bsb_regs
		generic map (
			DEFAULT_CONTROL_BYTES   => X"00_FF2833" & repeat(X"00", NUMBER_OF_CONTROL_BYTES),
			NUMBER_OF_CONTROL_BYTES => common_control_bytes'Length(1), -- Number of bits in the control word
			NUMBER_OF_STATUS_BYTES  => common_status_bytes'Length(1) -- Number of bits in the status word.
		)
		port map (
			ctrl_cmd_in_dat   => module_cmd_dat(0),
			ctrl_cmd_in_rdy   => module_cmd_rdy(0),
			ctrl_rply_out_dat => module_rply_dat(0),
			ctrl_rply_out_rdy => module_rply_rdy(0),
			ctrl_clk          => ctrl_clk,
			ctrl_rst          => ctrl_rst_reg(0),
			control_bytes     => common_control_bytes,
			status_bytes      => common_status_bytes
		);

	-- CONTROL Byte 0
	common_user_reset                <= common_control_bytes(0)(7);
	common_drp_page                  <= common_control_bytes(0)(4 downto 4);
	common_tx_datapath_reset         <= common_control_bytes(0)(3); -- core only
	common_rx_pll_datapath_reset     <= common_control_bytes(0)(2); -- core only
	common_rx_datapath_reset         <= common_control_bytes(0)(1); -- core only
	common_tx_pll_datapath_reset     <= common_control_bytes(0)(0); -- core only

	-- CONTROL Byte 1-3
	common_user_tx_data <= to_slv(common_control_bytes(1 to 3));

	-- CONTROL Byte 4+
	control_bytes <= slv8_array(common_control_bytes(4 to 4 + NUMBER_OF_CONTROL_BYTES - 1));

	common_status_bytes(0)(7 downto 5) <= to_slv(NUMBER_OF_QUADS, 3);
	common_status_bytes(0)(4 downto 0) <= to_slv(NUMBER_OF_LINKS, 5);

	common_status_bytes(1)(4) <= (not (or tx_reset) or to_std_logic(NUMBER_OF_TX_LINKS = 0)) and (not (or rx_reset) or to_std_logic(NUMBER_OF_RX_LINKS = 0));
	common_status_bytes(1)(3) <= qpllreset;
	common_status_bytes(1)(2) <= common_rx_cdr_stable_out; -- core only

	common_status_bytes(2 to 2 + NUMBER_OF_STATUS_BYTES - 1) <= slv8_array(status_bytes);

	--------------------------------------
	-- GTYE4_COMMON (QPLL)
	--------------------------------------
	-- Instantiates a GTYE4_COMMON (QPLL) block for each quad
	-- The reference clock use for each quad is specified in the QUAD_TO_REFCLK_MAP list.
	--
	-- The GTYE4_COMMON DRP Address bus is 10 bits (word address), so we need 11-bits of BSB (byte) address space.
	-- The router allocated 10 bits of BSB address to this module, so we can access only 9-bits DRP address (0x000-0x1FF).
	-- However the highest register is at 0x00B0 (8-bit word address) so we are ok.

	quad_gen: for i in 0 to NUMBER_OF_QUADS - 1 generate

		quad_regs0: entity work.bsb_regs
			generic map (
				DEFAULT_CONTROL_BYTES   => X"00",
				USE_RAM_DOUT_RDY        => TRUE, -- need to wait for the RDY signal on RAM read accesses
				ADDR_WIDTH              => MODULE_ADDR_WIDTH, -- needed because RAM byte address width is bigger than available address bits
				RAM_DATA_WIDTH          => 16,
				RAM_ADDR_WIDTH          => 10,
				NUMBER_OF_CONTROL_BYTES => quad_control_bytes(i)'Length(1), -- Number of bits in the control word
				NUMBER_OF_STATUS_BYTES  => quad_status_bytes(i)'Length(1) -- Number of bits in the status word.
			)
			port map (
				control_bytes => quad_control_bytes(i),
				status_bytes  => quad_status_bytes(i),

				ctrl_cmd_in_dat   => module_cmd_dat(i + 1),
				ctrl_cmd_in_rdy   => module_cmd_rdy(i + 1),
				ctrl_rply_out_dat => module_rply_dat(i + 1),
				ctrl_rply_out_rdy => module_rply_rdy(i + 1),
				ctrl_clk          => ctrl_clk,
				ctrl_rst          => ctrl_rst_reg(i + 1),

				-- DRP interface
				ram_din      => quad_drp_din(i),
				ram_dout     => quad_drp_dout(i),
				ram_dout_rdy => quad_drp_drdy(i),
				ram_wr_en    => quad_drp_wr_en(i),
				ram_en       => quad_drp_den(i),
				ram_addr     => quad_drp_addr(i)
			);

		quad_status_bytes(i)(0)(0) <= qplllock(i);

	end generate quad_gen;


	-- -----------------------------------------------------------------------------
	-- GTY Core
	-- -----------------------------------------------------------------------------
	gtycore_blk: block

		constant NL: integer := NUMBER_OF_LINKS; --  number of lanes in core
		constant NQ: integer := NUMBER_OF_QUADS; -- number of QUADs (COMMON)

		-- Differential data inputs/outputs
		signal gtyrxn_in: std_logic_vector(NL - 1 downto 0);
		signal gtyrxp_in: std_logic_vector(NL - 1 downto 0);
		signal gtytxn_out: std_logic_vector(NL - 1 downto 0);
		signal gtytxp_out: std_logic_vector(NL - 1 downto 0);

		-- Reference clocks
		signal gtrefclk00_in: std_logic_vector(NQ - 1 downto 0); -- Should be NUMBER_OF_REFCLKS?

		-- QPLL DRP
		signal drpaddr_common_in: std_logic_vector(16 * NQ - 1 downto 0);
		signal drpclk_common_in: std_logic_vector(NQ - 1 downto 0);
		signal drpdi_common_in: std_logic_vector(16 * NQ - 1 downto 0);
		signal drpen_common_in: std_logic_vector(NQ - 1 downto 0);
		signal drpwe_common_in: std_logic_vector(NQ - 1 downto 0);
		signal drpdo_common_out: std_logic_vector(16 * NQ - 1 downto 0);
		signal drprdy_common_out: std_logic_vector(NQ - 1 downto 0);

		-- Lane DRP
		signal drpaddr_in: std_logic_vector(10 * NL - 1 downto 0);
		signal drpclk_in: std_logic_vector(NL - 1 downto 0);
		signal drpdi_in: std_logic_vector(16 * NL - 1 downto 0);
		signal drpen_in: std_logic_vector(NL - 1 downto 0);
		signal drpwe_in: std_logic_vector(NL - 1 downto 0);
		signal drpdo_out: std_logic_vector(16 * NL - 1 downto 0);
		signal drprdy_out: std_logic_vector(NL - 1 downto 0);

		-- QPLL
		signal qpll0outclk_out: std_logic_vector(NQ - 1 downto 0);
		signal qpll0outrefclk_out: std_logic_vector(NQ - 1 downto 0);

		-- Clock inputs

		signal gtwiz_reset_clk_freerun_in: std_logic_vector(0 downto 0);

		-- Clock outputs
		signal gtwiz_userclk_tx_usrclk2_out: std_logic_vector(0 downto 0);
		signal gtwiz_userclk_rx_usrclk2_out: std_logic_vector(0 downto 0);

		-- TX interface
		signal gtwiz_userdata_tx_in: std_logic_vector(64 * NL - 1 downto 0);
		signal txheader_in: std_logic_vector(6 * NL - 1 downto 0);
		signal txsequence_in: std_logic_vector(7 * NL - 1 downto 0);

		-- Rx interface
		signal gtwiz_userdata_rx_out: std_logic_vector(64 * NL - 1 downto 0);
		signal rxdatavalid_out: std_logic_vector(2 * NL - 1 downto 0);
		signal rxheader_out: std_logic_vector(6 * NL - 1 downto 0);
		signal rxcdrhold_in : std_logic_vector(NL-1 downto 0);
		signal rxheadervalid_out: std_logic_vector(2 * NL - 1 downto 0);
		signal rxgearboxslip_in: std_logic_vector(NL - 1 downto 0);
		signal rxstartofseq_out: std_logic_vector(2 * NL - 1 downto 0); -- not used

		-- Control/reset signals
		signal gtpowergood_out: std_logic_vector(NL - 1 downto 0);

		-- reset inputs
		signal gtwiz_reset_all_in: std_logic_vector(0 downto 0);

		signal gtwiz_userclk_tx_reset_in: std_logic_vector(0 downto 0);
		signal gtwiz_reset_tx_pll_and_datapath_in: std_logic_vector(0 downto 0);
		signal gtwiz_reset_tx_datapath_in: std_logic_vector(0 downto 0);

		signal gtwiz_userclk_rx_reset_in: std_logic_vector(0 downto 0);
		signal gtwiz_reset_rx_pll_and_datapath_in: std_logic_vector(0 downto 0);
		signal gtwiz_reset_rx_datapath_in: std_logic_vector(0 downto 0);


		-- Reset outputs
		signal txpmaresetdone_out: std_logic_vector(NL - 1 downto 0);
		signal txprgdivresetdone_out: std_logic_vector(NL - 1 downto 0);
		signal rxpmaresetdone_out: std_logic_vector(NL - 1 downto 0);

		signal gtwiz_userclk_tx_active_out: std_logic_vector(0 downto 0);

		signal gtwiz_userclk_rx_active_out: std_logic_vector(0 downto 0);
		signal gtwiz_reset_rx_cdr_stable_out: std_logic_vector(0 downto 0);
		signal gtwiz_reset_tx_done_out: std_logic_vector(0 downto 0);
		signal gtwiz_reset_rx_done_out: std_logic_vector(0 downto 0);

		-- Debugging signals

		signal loopback_in: std_logic_vector(3 * NL - 1 downto 0);
		signal rxdfeagchold_in: std_logic_vector(NL - 1 downto 0);
		signal rxdfelfhold_in: std_logic_vector(NL - 1 downto 0);
		signal rxdfelpmreset_in: std_logic_vector(NL - 1 downto 0);
		signal rxlpmen_in: std_logic_vector(NL - 1 downto 0);
		signal rxlpmoshold_in: std_logic_vector(NL - 1 downto 0);
		signal rxmonitorsel_in: std_logic_vector(2 * NL - 1 downto 0);
		signal rxprbscntreset_in: std_logic_vector(NL - 1 downto 0);
		signal rxprbssel_in: std_logic_vector(4 * NL - 1 downto 0); -- extra bit in GTY compared to GTX
		signal txdiffctrl_in: std_logic_vector(5 * NL - 1 downto 0); -- extra bit in GTY compared to GTX
		signal txinhibit_in: std_logic_vector(NL - 1 downto 0);
		signal txpostcursor_in: std_logic_vector(5 * NL -1 downto 0);
		signal txprbsforceerr_in: std_logic_vector(NL - 1 downto 0);
		signal txprbssel_in: std_logic_vector(4 * NL - 1 downto 0); -- extra bit in GTY compared to GTX
		signal txprecursor_in: std_logic_vector(5 * NL -1 downto 0);
		signal rxmonitorout_out: std_logic_vector(8 * NL -1 downto 0);
		signal rxprbserr_out: std_logic_vector(NL - 1 downto 0);
		signal rxprbslocked_out: std_logic_vector(NL - 1 downto 0);
	begin

		-- Map all vectorized signals to the GTY core signals

		-- Connect Quad signals
		quad_gen: for i in 0 to NQ - 1 generate

			-- QPLL input reference clocks
			gtrefclk00_in(i) <= refclk_nobuf(QUAD_TO_REFCLK_MAP(i));

			-- QPLL output clocks
			qplloutclk(i)    <= qpll0outclk_out(i);
			qplloutrefclk(i) <= qpll0outrefclk_out(i);

			-- QPLL DRP bus
			drpdi_common_in(16 * (i + 1) - 1 downto 16 * i)   <= quad_drp_din(i);
			quad_drp_dout(i)                                  <= drpdo_common_out(16 * (i + 1) - 1 downto 16 * i);
			quad_drp_drdy(i)                                  <= drprdy_common_out(i);
			drpwe_common_in(i)                                <= quad_drp_wr_en(i);
			drpen_common_in(i)                                <= quad_drp_den(i);
			drpaddr_common_in(16 * (i + 1) - 1 downto 16 * i) <= "000000" & quad_drp_addr(i); -- the core wants 16-bit addresses, but max GTYE4_COMMON address is 0x9F
			drpclk_common_in(i)                               <= ctrl_clk;
		end generate quad_gen; -- for each quad


		-- Connect Channel signals
		lane_gen: for i in 0 to NL - 1 generate

			-- Differential signals
			gtyrxn_in(i) <= rx_n(i);
			gtyrxp_in(i) <= rx_p(i);
			tx_n(i)      <= gtytxn_out(i);
			tx_p(i)      <= gtytxp_out(i);


			-- DRP port
			drpaddr_in(10 * (i + 1) - 1 downto 10 * i) <= common_drp_page & gt_drp_addr(i);
			drpdi_in(16 * (i + 1) - 1 downto 16 * i)   <= gt_drp_din(i);
			drpclk_in(i)                               <= ctrl_clk;
			gt_drp_dout(i)                             <= drpdo_out(16 * (i + 1) - 1 downto 16 * i);
			drpen_in(i)                                <= gt_drp_en(i);
			gt_drp_rdy(i)                              <= drprdy_out(i);
			drpwe_in(i)                                <= gt_drp_wr_en(i);

			-- Clocks
			rxusrclk2(i) <= gtwiz_userclk_rx_usrclk2_out(0);

			-- reset outputs
			tx_resetdone_int(i)   <= gtwiz_reset_tx_done_out(0);
			rx_resetdone_int(i)   <= gtwiz_reset_rx_done_out(0);

			-- reset to be used by RX user logic, on rxclk(i)
			-- asserts asynchronously but deasserts synchronously
			rxrrst_cdc0: xpm_cdc_async_rst
				generic map (
					RST_ACTIVE_HIGH => 1
				)
				port map (
					src_arst  => reset_all or not gtwiz_userclk_rx_active_out(0),
					dest_clk  => rxusrclk2(i),
					dest_arst => rx_reset(i)
				);

			-- reset to be used by RX user logic, on txclk
			-- asserts asynchronously but deasserts synchronously
			txrrst_cdc0: xpm_cdc_async_rst
				generic map (
					RST_ACTIVE_HIGH => 1
				)
				port map (
					src_arst  => reset_all or not gtwiz_userclk_tx_active_out(0),
					dest_clk  => txusrclk2,
					dest_arst => tx_reset(i)
				);

			-- TX data
			gtwiz_userdata_tx_in(64 * (i + 1) - 1 downto 64 * i) <= gt_txdata_in(i);
			txheader_in(6 * (i + 1) - 1 downto 6 * i)            <= "0000" & gt_txheader_in(i);
			txsequence_in(7 * (i + 1) - 1 downto 7 * i)          <= std_logic_vector(gt_txsequence_in(i));

			-- RX data
			rxgearboxslip_in(i)     <= gt_rxgearboxslip_in(i) or gt_rxgearboxforceslip(i);
			gt_rxdata_out(i)        <= gtwiz_userdata_rx_out(64 * (i + 1) - 1 downto 64 * i);
			gt_rxdatavalid_out(i)   <= rxdatavalid_out(2 * i);
			gt_rxheader_out(i)      <= rxheader_out(6 * i + 1 downto 6 * i);
			gt_rxheadervalid_out(i) <= rxheadervalid_out(2 * i);

			-- debug signals


			rxdfeagchold_in(i)  <= gt_rxdfeagchold_in(i);
			rxdfelfhold_in(i)   <= gt_rxdfelfhold_in(i);
			rxdfelpmreset_in(i) <= gt_rxdfelpmreset_in(i);

			rxlpmen_in(i)                                 <= gt_rxlpmen_in(i);
			rxlpmoshold_in(i)                             <= '0';
			rxmonitorsel_in(2 * (i + 1) - 1 downto 2 * i) <= gt_rxmonitorsel_in(i);
			txdiffctrl_in(5 * (i + 1) - 1 downto 5 * i)   <= gt_txdiffctrl_in(i) & '1'; -- convert 4-bit to 5-bit
			txinhibit_in(i)                               <= gt_txinhibit_in(i);
			txpostcursor_in(5 * (i + 1) - 1 downto 5 * i) <= gt_txpostcursor_in(i);
			txprecursor_in(5 * (i + 1) - 1 downto 5 * i)  <= gt_txprecursor_in(i);

			-- PRBS
			txprbssel_in(4 * (i + 1) - 1 downto 4 * i) <= '0' & gt_txprbssel_in(i);
			rxprbssel_in(4 * (i + 1) - 1 downto 4 * i) <= '0' & gt_rxprbssel_in(i);
			txprbsforceerr_in(i)                       <= gt_txprbsforceerr_in(i);
			rxprbscntreset_in(i)                       <= gt_rxprbscntreset_in(i);
			gt_rxprbserr_out(i)                        <= rxprbserr_out(i);

			gt_rxprbslocked_out(i) <= rxprbslocked_out(i);

		end generate lane_gen; -- for each lane

		rxcdrhold_in <= (others => '0'); -- for SATA only
		loopback_in         <= flatten(slv_array(gt_loopback_in));
		gt_rxmonitorout_out <= slv8_array(unflatten(rxmonitorout_out, NUMBER_OF_LINKS));

		-- Clocks
		gtwiz_reset_clk_freerun_in(0) <= stable_clk; -- free-running stable clock
		txusrclk2                     <= gtwiz_userclk_tx_usrclk2_out(0);

		-- Status flags
		common_rx_cdr_stable_out <= gtwiz_reset_rx_cdr_stable_out(0);


		-- Resets inputs
		gtwiz_reset_all_in(0)         <= reset_all;
		gtwiz_reset_rx_datapath_in(0) <= common_rx_datapath_reset;

		-- // The TX user clocking helper block should be held in reset until the clock source of that block is known to be
		-- // stable. The following assignment is an example of how that stability can be determined, based on the selected TX
		-- // user clock source. Replace the assignment with the appropriate signal or logic to achieve that behavior as needed.
		gtwiz_userclk_tx_reset_in(0) <= not (and txprgdivresetdone_out) and (and txpmaresetdone_out);

		-- // The RX user clocking helper block should be held in reset until the clock source of that block is known to be
		-- // stable. The following assignment is an example of how that stability can be determined, based on the selected RX
		-- // user clock source. Replace the assignment with the appropriate signal or logic to achieve that behavior as needed.
		gtwiz_userclk_rx_reset_in(0) <= not (and rxpmaresetdone_out);


		-- Optional resets
		gtwiz_reset_tx_pll_and_datapath_in(0) <= common_tx_pll_datapath_reset;
		gtwiz_reset_tx_datapath_in(0)         <= common_tx_datapath_reset;
		gtwiz_reset_rx_pll_and_datapath_in(0) <= common_rx_pll_datapath_reset; -- not necessary


		gty_core0: entity work.gtwizard_ultrascale_0
			port map (
				gtwiz_userclk_tx_reset_in => gtwiz_userclk_tx_reset_in,
				-- gtwiz_userclk_tx_srcclk_out => gtwiz_userclk_tx_srcclk_out, -- nc
				-- gtwiz_userclk_tx_usrclk_out => gtwiz_userclk_tx_usrclk_out, -- not used
				gtwiz_userclk_tx_usrclk2_out => gtwiz_userclk_tx_usrclk2_out, -- user clock
				gtwiz_userclk_tx_active_out  => gtwiz_userclk_tx_active_out, -- not used
				gtwiz_userclk_rx_reset_in    => gtwiz_userclk_rx_reset_in, -- must be held in reset until clocks
				-- gtwiz_userclk_rx_srcclk_out => gtwiz_userclk_rx_srcclk_out, -- nc
				-- gtwiz_userclk_rx_usrclk_out => gtwiz_userclk_rx_usrclk_out,
				gtwiz_userclk_rx_usrclk2_out       => gtwiz_userclk_rx_usrclk2_out, -- used
				gtwiz_userclk_rx_active_out        => gtwiz_userclk_rx_active_out, -- used
				gtwiz_reset_clk_freerun_in         => gtwiz_reset_clk_freerun_in, -- used
				gtwiz_reset_all_in                 => gtwiz_reset_all_in, -- used
				gtwiz_reset_tx_pll_and_datapath_in => gtwiz_reset_tx_pll_and_datapath_in, -- set to 0
				gtwiz_reset_tx_datapath_in         => gtwiz_reset_tx_datapath_in, -- set to 0
				gtwiz_reset_rx_pll_and_datapath_in => gtwiz_reset_rx_pll_and_datapath_in, -- not necessary, using commoon
				gtwiz_reset_rx_datapath_in         => gtwiz_reset_rx_datapath_in, -- from reset FSM
				gtwiz_reset_rx_cdr_stable_out      => gtwiz_reset_rx_cdr_stable_out, -- not used
				gtwiz_reset_tx_done_out            => gtwiz_reset_tx_done_out, -- used
				gtwiz_reset_rx_done_out            => gtwiz_reset_rx_done_out,
				gtwiz_userdata_tx_in               => gtwiz_userdata_tx_in,
				gtwiz_userdata_rx_out              => gtwiz_userdata_rx_out,
				drpaddr_common_in                  => drpaddr_common_in,
				drpclk_common_in                   => drpclk_common_in,
				drpdi_common_in                    => drpdi_common_in,
				drpen_common_in                    => drpen_common_in,
				drpwe_common_in                    => drpwe_common_in,
				gtrefclk00_in                      => gtrefclk00_in,
				drpdo_common_out                   => drpdo_common_out,
				drprdy_common_out                  => drprdy_common_out,
				qpll0outclk_out                    => qpll0outclk_out,
				qpll0outrefclk_out                 => qpll0outrefclk_out,
				drpaddr_in                         => drpaddr_in,
				drpclk_in                          => drpclk_in,
				drpdi_in                           => drpdi_in,
				drpen_in                           => drpen_in,
				drpwe_in                           => drpwe_in,
				gtyrxn_in                          => gtyrxn_in,
				gtyrxp_in                          => gtyrxp_in,
				loopback_in                        => loopback_in,
				rxcdrhold_in                       => rxcdrhold_in,
				rxdfeagchold_in                    => rxdfeagchold_in,
				rxdfelfhold_in                     => rxdfelfhold_in,
				rxdfelpmreset_in                   => rxdfelpmreset_in,
				rxgearboxslip_in                   => rxgearboxslip_in,
				rxlpmen_in                         => rxlpmen_in,
				rxlpmoshold_in                     => rxlpmoshold_in,
				rxmonitorsel_in                    => rxmonitorsel_in,
				rxprbscntreset_in                  => rxprbscntreset_in,
				rxprbssel_in                       => rxprbssel_in,
				txdiffctrl_in                      => txdiffctrl_in,
				txheader_in                        => txheader_in,
				txinhibit_in                       => txinhibit_in,
				txpostcursor_in                    => txpostcursor_in,
				txprbsforceerr_in                  => txprbsforceerr_in,
				txprbssel_in                       => txprbssel_in,
				txprecursor_in                     => txprecursor_in,
				txsequence_in                      => txsequence_in,
				drpdo_out                          => drpdo_out,
				drprdy_out                         => drprdy_out,
				gtpowergood_out                    => gtpowergood_out,
				gtytxn_out                         => gtytxn_out,
				gtytxp_out                         => gtytxp_out,
				rxdatavalid_out                    => rxdatavalid_out,
				rxheader_out                       => rxheader_out,
				rxheadervalid_out                  => rxheadervalid_out,
				rxmonitorout_out                   => rxmonitorout_out,
				rxpmaresetdone_out                 => rxpmaresetdone_out, -- used in userclk_rx_reset
				rxprbserr_out                      => rxprbserr_out,
				rxprbslocked_out                   => rxprbslocked_out,
				rxstartofseq_out                   => rxstartofseq_out,
				txpmaresetdone_out                 => txpmaresetdone_out, -- used in userclk_tx_reset
				txprgdivresetdone_out              => txprgdivresetdone_out -- used in userclk_tx_reset
			);

	end block gtycore_blk;


	gtx_gen: for i in 0 to NUMBER_OF_LINKS - 1 generate

		lane_regs0: entity work.bsb_regs
			generic map (
				DEFAULT_CONTROL_BYTES   => X"80_00_01_40_00_00",
				USE_RAM_DOUT_RDY        => TRUE, -- need to wait for the RDY signal on RAM read accesses
				ADDR_WIDTH              => MODULE_ADDR_WIDTH, -- needed because RAM byte address width is bigger than available address bits
				RAM_DATA_WIDTH          => 16,
				RAM_ADDR_WIDTH          => 9, -- GTY DRP word Address is 10 bits (11 bit byte address on BSB bus). Maximum register is at 0x28C (10-bit word address)
				NUMBER_OF_CONTROL_BYTES => gt_control_bytes(i)'LENGTH(1), -- Number of bits in the control word
				NUMBER_OF_STATUS_BYTES  => gt_status_bytes(i)'LENGTH(1) -- Number of bits in the status word.
			)
			port map (
				ctrl_cmd_in_dat   => module_cmd_dat(i + NUMBER_OF_QUADS + 1),
				ctrl_cmd_in_rdy   => module_cmd_rdy(i + NUMBER_OF_QUADS + 1),
				ctrl_rply_out_dat => module_rply_dat(i + NUMBER_OF_QUADS + 1),
				ctrl_rply_out_rdy => module_rply_rdy(i + NUMBER_OF_QUADS + 1),
				ctrl_clk          => ctrl_clk,
				ctrl_rst          => ctrl_rst_reg(i + NUMBER_OF_QUADS + 1),

				control_bytes => gt_control_bytes(i),
				status_bytes  => gt_status_bytes(i),
				-- DRP interface
				ram_din      => gt_drp_din(i),
				ram_dout     => gt_drp_dout(i),
				ram_dout_rdy => gt_drp_rdy(i),
				ram_wr_en    => gt_drp_wr_en(i),
				ram_en       => gt_drp_en(i),
				ram_addr     => gt_drp_addr(i)
			);

		-- TX CONTROL Bytes
		--------------------

		-- CONTROL Byte 0

		gt_scramble_en(i)               <= gt_control_bytes(i)(0)(7);
		gt_rxgearboxforceslip(i)        <= gt_control_bytes(i)(0)(6);
		gt_txinhibit_in(i)              <= gt_control_bytes(i)(0)(5);
		gt_txpostcursor_in(i)           <= gt_control_bytes(i)(0)(4 downto 0);

		-- CONTROL Byte 1
		gt_txdiffctrl_in(i)             <= gt_control_bytes(i)(1)(7 downto 4);
		gt_unscrambler_reset(i)         <= gt_control_bytes(i)(1)(3);
		gt_loopback_in(i)               <= gt_control_bytes(i)(1)(2 downto 0); -- '000' = normal operation

		-- CONTROL Byte 2
		gt_user_source_sel(i)           <= gt_control_bytes(i)(2)(7);
		gt_txprecursor_in(i)            <= gt_control_bytes(i)(2)(6 downto 2);
		gt_user_tx_header(i)            <= gt_control_bytes(i)(2)(1 downto 0);

		-- CONTROL Byte 3
		gt_user_tx_data(i)(7 downto 0)  <= gt_control_bytes(i)(3);
		gt_user_tx_data(i)(31 downto 8) <= common_user_tx_data;


		-- CONTROL Byte 4

		gt_rxdfelpmreset_in(i)  <= gt_control_bytes(i)(4)(7);          -- needed for link tests
		gt_user_gtrxreset(i)    <= gt_control_bytes(i)(4)(6);          -- unused by core
		gt_rxlpmen_in(i)        <= gt_control_bytes(i)(4)(5);          -- may be needed for link tests
		gt_rxmonitorsel_in(i)   <= gt_control_bytes(i)(4)(4 downto 3); -- may be needed for link tests (if so, will need to make rxmonitor status available)
		gt_capture_en(i)        <= gt_control_bytes(i)(4)(2);
		gt_block_lock_reset(i)  <= gt_control_bytes(i)(4)(1);          -- could be global, but routing is easier if it is local
		gt_rxdfeagchold_in(i)   <= gt_control_bytes(i)(4)(0);

		-- CONTROL Byte 5

		gt_rxprbscntreset_in(i) <= gt_control_bytes(i)(5)(7);          -- needed for link tests
		gt_txprbsforceerr_in(i) <= gt_control_bytes(i)(5)(6);          -- needed for link tests
		gt_txprbssel_in(i)      <= gt_control_bytes(i)(5)(5 downto 3); -- needed for link tests
		gt_rxprbssel_in(i)      <= gt_control_bytes(i)(5)(2 downto 0); -- needed for link tests

		-- Common CONTROL bytes

		-- gt_scrambler_reset(i)   <= common_scrambler_reset;
		-- gt_unscrambler_reset(i) <= common_unscrambler_reset;
		-- gt_scramble_en(i)       <= common_scramble_en;
		-- gt_descramble_en(i)     <= common_descramble_en;

		-- Constant control signals

		gt_scrambler_reset(i)   <= '0';
		-- gt_unscrambler_reset(i) <= '0';
		-- gt_scramble_en(i)       <= '1'; -- ***JFC Normally 1, 0 for debug
		-- gt_descramble_en(i)     <= '1'; ---***JFC Normally 1, 0 for debug
		gt_descramble_en(i)     <= gt_scramble_en(i);

		-- TX STATUS BYTES
		------------------

		-- STATUS BYTE 0
		gt_status_bytes(i)(0)(7)          <= tx_resetdone_int(i);
		gt_status_bytes(i)(0)(6)          <= rx_resetdone_int(i);
		gt_status_bytes(i)(0)(5 downto 4) <= gt_txbufstatus_out(i); -- unused
		gt_status_bytes(i)(0)(3)          <= tx_resetdone(i);
		gt_status_bytes(i)(0)(2)          <= rx_resetdone(i);
		gt_status_bytes(i)(0)(1)          <= gt_block_lock(i);
		gt_status_bytes(i)(0)(0)          <= to_std_logic(NUMBER_OF_RX_LINKS > 0); -- Indicates if RX part is present

		-- STATUS BYTE 1-4
		gt_status_bytes(i)(1 to 4) <= to_slv8_array(gt_err_ctr(i)); -- needed for link tests

		-- RX STATUS BYTES
		--------------------
		rxstatus_gen: if NUMBER_OF_RX_LINKS > 0 generate
			-- STATUS BYTE 5
			gt_status_bytes(i)(5)(7 downto 6) <= gt_rxheader_capture(i);
			gt_status_bytes(i)(5)(5)          <= gt_rxgearboxslip_in(i); -- optional
			gt_status_bytes(i)(5)(3)          <= gt_rxprbslocked_out(i);
			gt_status_bytes(i)(5)(2 downto 0) <= gt_rxbufstatus_out(i); -- unused

			-- STATUS BYTE 6
			gt_status_bytes(i)(6) <= gt_rxmonitorout_out(i); -- Needed for link tests?

			-- STATUS BYTE 7-10
			gt_status_bytes(i)(7 to 10) <= to_slv8_array(rx_data_capture(i)(31 downto 0)); -- Capture only the lower 31 bits

			-- STATUS BYTE 11
			gt_status_bytes(i)(11) <= gt_dmonitorout_out(i); -- Always needed? state of the receiver LPM and DFE mode adaptation loops, such as the adapted continuous time linear equalizer (CTLE) gains and DFE taps
		end generate rxstatus_gen;

		------------------------------------------------
		-- RX PRBS Error Counter
		------------------------------------------------
		-- We need RX error counters for every GTX to perform link tests.

		process(rxusrclk2(i))
		begin
			if rising_edge(rxusrclk2(i)) then
				if gt_rxprbscntreset_in(i) = '1' then
					gt_err_ctr(i) <= (others => '0');
				elsif gt_rxprbserr_out(i) = '1' and signed(gt_err_ctr(i)) /= -1 then
					gt_err_ctr(i) <= std_logic_vector(unsigned(gt_err_ctr(i)) + 1);
				end if;
			end if;
		end process;

	end generate gtx_gen; -- for number of GTX


	----------------------------------------------
	-- Global TX Clock
	----------------------------------------------
	-- Assign Tx clock output
	tx_clk <= txusrclk2;

	-- Generate a logic signal that toggles at half the rate of the tx clock for the frequency counter
	txclkdiv2_proc: process(all) begin
		if rising_edge(txusrclk2) then
			txclk_div2 <= not txclk_div2;
		end if;
	end process;

	----------------------------------------------
	-- TX Data Logic
	----------------------------------------------
	tx_gen: for i in  0 to NUMBER_OF_TX_LINKS - 1 generate
		tx_impl: if is_in(i, USED_LINKS) generate

			signal user_tx_data_reg: slv64;
			signal user_tx_header_reg: slv2;

			signal tx_header_reg: slv2;
			signal tx_data_reg: slv64 := (others => '0'); -- init for sim
			signal tx_data_scr_bypass: slv64 := (others => '0'); -- init for sim
			signal tx_data_scr: slv64 := (others => '0'); -- init for sim
			signal tx_header_scr: slv2 := (others => '0'); -- init for sim
			signal txsequence_bit: std_logic;

			signal scrambler_reset: std_logic;

		begin

			tx_ready(i)     <= tx_ready_int(i) after DLY;
			tx_resetdone(i) <= tx_resetdone_int(i) after DLY;

			process(all) begin
				if rising_edge(txusrclk2) then
					txsequence_bit <= not txsequence_bit;
					if txsequence_bit then
						gt_txsequence_in(i) <= gt_txsequence_in(i) + 1 after DLY;
						gt_txsequence_in(i) <= (others => '0') after DLY when gt_txsequence_in(i) = 32;
						tx_ready_int(i) <= '0' when gt_txsequence_in(i) = 31 else '1'; -- we need the delays to ensure the signal changes after all copies of the clock
					end if; -- txsequence_bit
					-- Resets
					if tx_reset(i) then
						txsequence_bit <= '0';
						gt_txsequence_in(i) <= (others => '0');
					end if;
				end if; -- clk
			end process;


			-- Data tranmission path
			-- User_data => reverse bytes => scramble => reverse bits => GTY Tx
			txproc: process(all) begin
				if rising_edge(txusrclk2) then
					user_tx_data_reg <= gt_user_tx_data(i); -- Pipeline user data and header words.
					user_tx_header_reg <= gt_user_tx_header(i);

					if tx_ready(i) then
						tx_data_reg <= reverse_bytes(tx_data(i));
						tx_header_reg <= tx_header(i);

						-- Override with user-specified register values if source_sel=1
						if gt_user_source_sel(i) = '1' then -- select values from registers
							tx_data_reg <= reverse_bytes(user_tx_data_reg);
							tx_header_reg <= user_tx_header_reg;
						end if;

						-- Delay tx_header and data to compensate for the scrambler latency
						tx_data_scr_bypass <= tx_data_reg; -- for scrambler bypass path
						tx_header_scr <= tx_header_reg;

						-- Send data to GTY, scrambled or not
						gt_txdata_in(i) <= reverse_bits_same_dir(tx_data_scr) when gt_scramble_en(i) else
		                   reverse_bits_same_dir(tx_data_scr_bypass);
						gt_txheader_in(i) <= tx_header_scr;
					end if; -- tx_ready
				end if; -- clk
			end process;

			------------------------------------------------
			-- SCRAMBLER
			------------------------------------------------

			scrambler_reset <= tx_reset(i) or not tx_resetdone_int(i) or gt_scrambler_reset(i);

			scrambler0: entity work.xxvglink_scrambler
				port map (
					-- User Interface
					unscrambled_data_in => tx_data_reg, -- first bit transmitted is in the LSB
					scrambled_data_out  => tx_data_scr, -- first bit transmitted is in the LSB
					data_valid_in       => tx_ready_int(i),

					-- System Interface
					user_clk     => txusrclk2,
					system_reset => scrambler_reset
				);
		end generate tx_impl;
	end generate tx_gen; -- for NUMBER_OF_TX_LINKS

	----------------------------------------------
	-- RX Data Logic
	----------------------------------------------
	rx_gen: for i in  0 to NUMBER_OF_RX_LINKS - 1 generate
		rx_impl: if is_in(i, USED_LINKS) generate

			signal block_sync_reset: std_logic;

			signal rx_data_unscr_bypass: slv64;
			signal rx_data_unscr: slv64;
			signal rx_data_valid_reg: std_logic;
			signal rx_header_reg: slv2;
			signal rx_header_valid_reg: std_logic;

			signal rx_capture_en: std_logic;
			signal unscrambler_reset: std_logic;

			signal rx_data_int: slv64;
			signal rx_data_valid_int: std_logic;
			signal rx_header_int: slv2;
			signal rx_header_valid_int: std_logic;

		begin
			-- Assign clock and reset outputs
			rx_clk(i)       <= rxusrclk2(i); -- Danger Will Robinson! In sims, the clock assignment might be evaluated AFTER the output signals are evaluated, causing the data to appear on the wrong clock. That's why we have a DLY for each output purt assignments.
			rx_resetdone(i) <= (rx_resetdone_int(i) and gt_block_lock(i)) after DLY;

			-- apply output with delays for simulations
			rx_data(i)         <= rx_data_int after DLY;
			rx_data_valid(i)   <= rx_data_valid_int after DLY;
			rx_header(i)       <= rx_header_int after DLY;
			rx_header_valid(i) <= rx_header_valid_int after DLY;
			------------------------------------------------
			-- RX BLOCK SYNCHRONIZATION
			------------------------------------------------
			block_sync_reset <= rx_reset(i) or not rx_resetdone_int(i) or gt_block_lock_reset(i);

			block_sync0: entity work.xxvglink_block_sync
				generic map (
					SH_CNT_MAX         => 64,
					SH_INVALID_CNT_MAX => 16
				)
				port map (
					-- User Interface
					blocksync_out     => gt_block_lock(i),
					rxgearboxslip_out => gt_rxgearboxslip_in(i),
					rxheader_in       => gt_rxheader_out(i),
					rxheadervalid_in  => gt_rxheadervalid_out(i),

					-- System Interface
					clk => rxusrclk2(i),
					rst => block_sync_reset
				);

			-- Synchronize the capture signal to the local rx clock
			cap_cdc0: xpm_cdc_single
				generic map (
					SRC_INPUT_REG => 0
				)
				port map (
					src_clk  => ctrl_clk,
					src_in   => gt_capture_en(i),
					dest_clk => rxusrclk2(i),
					dest_out => rx_capture_en
				);

			-- Data receive path
			--   GTY Rx => reverse_bits => descrambler => reverse bytes => user data
			-- Also Capture descrambled or unscambled data when valid and capture=1
			process(all) begin
				if rising_edge(rxusrclk2(i)) then
					-- Compensate unscrambler latency
					rx_data_unscr_bypass <= reverse_bits_same_dir(gt_rxdata_out(i)); -- descrambler bypass
					rx_data_valid_reg <= gt_rxdatavalid_out(i);
					rx_header_reg <= gt_rxheader_out(i);
					rx_header_valid_reg <= gt_rxheadervalid_out(i);

					if rx_reset(i) or not rx_resetdone_int(i) then -- Added reset to try to prevent spurious sends after reset
						rx_header_reg <= "00";
						rx_header_valid_reg <= '0';
						rx_data_valid_reg <= '0';
					end if;

					-- Assign user outputs, scrambled or unscrambled
					-- Add assignment delays to make sure the signal changes AFTER all copies of the clocks have propagated in simulation
					rx_data_int <= reverse_bytes(rx_data_unscr) when gt_descramble_en(i) else
		               reverse_bytes(rx_data_unscr_bypass); -- first byte received is in bits 31-24 (MSB-LSB)
					rx_data_valid_int <= rx_data_valid_reg;
					rx_header_int <= rx_header_reg;
					rx_header_valid_int <= rx_header_valid_reg;

					-- Word capture logic
					if rx_capture_en then
						rx_data_capture(i) <= rx_data_int when rx_data_valid_int;
						gt_rxheader_capture(i) <= rx_header_int when rx_header_valid_int;
					end if;
				end if; -- clk
			end process;

			------------------------------------------------
			-- RX DESCRAMBLER
			------------------------------------------------
			unscrambler_reset <= rx_reset(i) or not rx_resetdone_int(i) or gt_unscrambler_reset(i);

			descrambler0: entity work.xxvglink_descrambler
				port map (
					-- User Interface
					scrambled_data_in    => reverse_bits_same_dir(gt_rxdata_out(i)), -- first bit received is in the LSB
					data_valid_in        => gt_rxdatavalid_out(i),
					unscrambled_data_out => rx_data_unscr, -- first bit received is in the LSB

					-- System Interface
					clk => rxusrclk2(i),
					rst => unscrambler_reset -- or not gt_block_lock(i)
				);
		end generate rx_impl;
	end generate rx_gen; -- for RX lane

end architecture behavioral;
