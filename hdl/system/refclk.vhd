----------------------------------------------------------------------------------
-- Company: Mc Gill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    2011-08-24
-- Design Name:
-- Module Name:    REFCLK - impl
-- Project Name:
-- Target Devices:
-- Tool versions:
--
-- Dependencies:
--
-- Revision:
--    2011-09-22 JFC: Created
--
--    2012-09-05 JFC: Inverted polarity of enable_sync_detection in the IF() statement, which was wrong.
--
--    2012-09-05 JFC: Cleanup. Removed MMCM references. Added enable_sync_generation flag. Disable
--       enable_sync_detection by default. These last two are to try prevent the SYNC generator
--       state machine to start generating a SYNC sequence (and resetting the SERDES) when the FMC
--       board is absent and REFCLK is clocked randomly.
--
--    2012-09-28 JFC: Changed SYNC event sequencing process to use a single adcdaq_reset.
--
--    2012-10-22 JFC: Added internal REFCLK selection with a BUFGMUX instead of the BUFG. Removed unused logic.
-- --------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chFPGA_Package.ALL; -- Get all component definitions

library UNISIM;
use UNISIM.vcomponents.ALL;

library xpm;
use xpm.vcomponents.ALL;

-- Handles the FMC Reference Clock generation, SYNC event detection and generation, and ADC SYNC signal generation
entity refclk is
	generic (
		PLATFORM_ID: integer;
		NUMBER_OF_MEZZANINES: integer;
		IMPLEMENT_CLOCK_ENCODED_SYNC: boolean := FALSE;
		SIM: BOOLEAN                          := FALSE
	);
	port (
		-- Control interface
		ctrl_cmd_in_dat: in AXIS8_DAT_STRUCT; -- Command stream input, signals from master (Data, Valid, Last)
		ctrl_cmd_in_rdy: out AXIS8_RDY_STRUCT; -- Command stream input, signals to master (Ready)
		ctrl_rply_out_dat: out AXIS8_DAT_STRUCT; -- Reply stream output, signals to slave (Data, Valid, Last)
		ctrl_rply_out_rdy: in AXIS8_RDY_STRUCT; -- Reply stream output,  signals from slave (Ready)
		ctrl_clk: in  std_logic;
		ctrl_rst: in std_logic;

		------------------------------------------------------------------------
		-- SYNC sequencing signals
		------------------------------------------------------------------------

		clk10: in std_logic; -- Buffered 10 MHz reference clock (with well defined phase relationship with all other boards in the system)

		sync_in: in std_logic_vector(0 to 5); -- External sync request signals (from backplane or IRIG-B comparator)

		adcdaq_reset: out std_logic; -- When a SYNC event is detected, is activated to initiate reset of the ADC data acquisition and processing pipeline

		------------------------------------------------------------------------
		-- Mezzanine signals
		--------------------------------------------------------------------------

		-- Reference clocks from mezzanines (LVDS)
		fmc_refclk_p: in std_logic_vector(0 to NUMBER_OF_MEZZANINES - 1); -- Reference Clock LVDS input from the FMC. The Input pad is instantiated in this module.
		fmc_refclk_n: in std_logic_vector(0 to NUMBER_OF_MEZZANINES - 1);

		-- Buffered reference clocks from mezzanines
		fmc_refclk: out std_logic_vector(0 to NUMBER_OF_MEZZANINES - 1); -- BUFG-buffered, delayed FMC Mezzanine reference clock, used to scan the ADC clock waveform

		-- Divide-by-2 version of the mezzanine clocks for monitoring
		fmc_refclk_div2: out std_logic_vector(0 to NUMBER_OF_MEZZANINES - 1); -- Logic signal pulsing at half the REFCLK frequency to be used by the Frequency Counter.

		-- LVDS SYNC signal outputs to the mezzanines
		adc_sync_p: out std_logic_vector(0 to NUMBER_OF_MEZZANINES - 1); -- LVDS ADC SYNC output. The LVDS output pad is instantiated in this module.
		adc_sync_n: out std_logic_vector(0 to NUMBER_OF_MEZZANINES - 1);


		------------------------------------------------------------------------
		-- Clock-encoded sync signal (if IMPLEMENT_CLOCK_ENCODED_SYNC is TRUE)
		------------------------------------------------------------------------
		clk10_out: out std_logic; -- Generated clock that is pulse-width modulated to encode a sync on a 0-to-1 transition of the user_sync user-controlled signal
		sync_out: out std_logic; -- registered version of the user_sync user-controlled signal that is used to generate cock-encoded sync signals


		clk200: in std_logic;
		-- System-level signals
		rst: in std_logic -- synchronous to clk200
	);
end entity refclk;

architecture impl of refclk is

	-- Attributes used in this module
	attribute DONT_TOUCH: string;
	attribute IOB: string;
	attribute ASYNC_REG: string;

	constant FPGA_SERIES: integer := FPGA_SERIES_LIST(PLATFORM_ID);

	-- Control and monitor signals
	signal control_bytes: slv8_array(0 to 2); -- default value set in the CMD_SLAVE
	signal status_bytes: slv8_array(0 to 2); -- default value set in the CMD_SLAVE

	signal adc_sync_user: std_logic;
	signal user_sync: std_logic; -- user controlled bit to trigger sync encoding on the generated 10 MHz clock
	signal local_sync: std_logic; -- user controlled bit to trigger local sync sequence
	signal sync_source: std_logic_vector(2 downto 0);
	signal sync_event_ctr: unsigned(3 downto 0);


	-- Sync encoder/decoder signals
	signal recovered_sync: std_logic;

	-- Mezzanine-specific global signals
	-- signal fmc_refclk_div2_int: std_logic_vector(0 to NUMBER_OF_MEZZANINES-1) := (others=>'0'); -- Initialization required


	-- Sync sequencer signals
	--------------------------------------------------------------------------------

	signal local_sync_reg: std_logic;  -- on clk10
	signal local_sync_dly: std_logic;  -- on clk10
	attribute async_reg of local_sync_reg, local_sync_dly: signal is "true";

	signal adc_sync_pre: std_logic; -- precursor to the adc_sync signal

	signal sync_done: std_logic;

	signal sync_ctr: unsigned(15 downto 0);
	signal sync: std_logic;
	signal sync_dly: std_logic;
	signal sync_source_vect: std_logic_vector(0 to 7);

	signal refclk_delay: slv_array(0 to 1)(4 downto 0);
	signal refclk_delay_rst: std_logic;

	type sync_state_type is (SYNC_STATE_IDLE, SYNC_STATE_STABILIZE_PLL, SYNC_STATE_SYNC_RELEASE, SYNC_STATE_ADCDAQ_RESET_RELEASE);

	signal sync_state: sync_state_type := SYNC_STATE_IDLE;


begin

	-----------------------------------------------------------------------------------
	-- CONTROL and STATUS Bytes
	-----------------------------------------------------------------------------------
	-- Memory Map
	-- ----------------------------------------------------------------------------------------
	-- | Page | Addr | Bit(s)|     Name                | Description                           |
	-- |---------|-----|-----|-------------------------|---------------------------------------|
	-- | CONTROL |  0  |  7  | adc_sync_user           | if TRUE, forces ADC SYNC to be asserted. If FALSE, the adc_sync is generated by the SYNC state machine. |
	-- |         |     |  6  | (unused)                |  |
	-- |         |     |  5  | local_sync              | Force the generation of a local SYNC sequence on the local board only. Has the same effect as an external SYNC.  The SYNC is synchronized to the 10 MHz output (transitions on its falling edge) |
	-- |         |     |  4  | user_sync               | Drives the sync_out signl, reclocked to the *falling* edge of clk10. Does NOT cause a local sync. If the 10 MHz clock generator logic is present, a rising edge causes the generation of a clock-encoded sync on that clock. |
	-- |         |     | 3:2 | (unused)                |  |
	-- |         |     | 1:0 | sync_source             | Selects the source of the SYNC signal: '00': local sync only, '01': sync recovered from the clock, '01': backplane sync, '11': IRIG-B-based sync|
-- |         |  1  |  7  | (unused)                |                               |
-- |         |     | 6:5 | (unused)                |                               |
-- |         |     | 4:0 | REFCLK1_DLY             | Delay on the Mezzanine 1 REFCLK, used to scan the ADC clock waveform and set the ADC SYNC timing. |
	-- |         |  2  |  7  | REFCLK_DLY_RST          | Resets the REFCLK delay line. Needed to load a new delay value.|
	-- |         |     | 4:0 | REFCLK0_DLY             | Delay on Mezzanine 0 REFCLK, used to scan the ADC clock waveform and set the ADC SYNC timing. |
	-- | STATUS  |  0  | 7:4 | sync_event_ctr          | |
	-- |         |     |  3  | (unused)                | |
	-- |         |     |  2  | recovered_sync          | |
	-- |         |     |  1  | SYNC                    | |
	-- |         |     |  0  | adcdaq_reset        | |
	-- |         |  1  | 7:0 | (unused)                | |
-- |         |  2  | 7:6 | (unused)                |                               |
-- |         |     |  5  | sync_done               | Indicates when sync sequence is completed |
-- |         |     |  4  | (unused)                |                               |
-- |         |     |  3  | (unused)                |                               |
-- |         |     |  2  | sync_in(2)              | Debug: monitors sync input 2 |
-- |         |     |  1  | sync_in(1)              | Debug: monitors sync input 1 |
-- |         |     |  0  | sync_in(0)              | Debug: monitors sync input 0 |
	-- ------------------------------------------------------------------------------
	--

	-- CONTROL Byte 0
	adc_sync_user <= control_bytes(0)(7); -- When '1', forces the sync_out outputs to '1' without initiating the SYNC sequence
	local_sync    <= control_bytes(0)(5); -- 0 to 1 transition initiates a SYNC sequence (same as a 0-to-1 transition on the sync_in signals)
	user_sync   <= control_bytes(0)(4); -- 0 to 1 transition generates a clock-encoded sync signal
	sync_source   <= control_bytes(0)(2 downto 0);

	-- CONTROL Byte 1

	refclk_delay(1)     <= control_bytes(1)(4 downto 0); -- Delay applied to the Mezzanine 1 reference clock (sets the sync signal timing)

	-- CONTROL Byte 2
	refclk_delay_rst    <= control_bytes(2)(7);          -- Resets the delay lines and loads the delays
	refclk_delay(0)     <= control_bytes(2)(4 downto 0); -- Delay applied to the Mezzanine 0 reference clock (sets the sync signal timing)

	-- STATUS Byte 0
	status_bytes(0)(7 downto 4) <= std_logic_vector(sync_event_ctr); -- counts the number of SYNC events detected so far
	status_bytes(0)(2)          <= recovered_sync;                   -- debug: monitors sync recovered from the 10 MHz clock
	status_bytes(0)(1)          <= sync;                             -- debug: monitor the currently selected sync source
	status_bytes(0)(0)          <= adcdaq_reset;                     -- debug: monitors the data acquisition and processing pipeline reset state

	-- STATUS Byte 1
	status_bytes(1) <= (others => '0'); -- Unused

	-- STATUS Byte 2
	status_bytes(2)(7 downto 6) <= (others => '0');
	status_bytes(2)(5)          <= sync_done;  -- Indicates when sync sequence is completed
	status_bytes(2)(4 downto 3) <= (others => '0');
	status_bytes(2)(2)          <= sync_in(2); -- debug: monitors the sync input
	status_bytes(2)(1)          <= sync_in(1); -- debug: monitors the sync input
	status_bytes(2)(0)          <= sync_in(0); -- debug: monitors the sync input

	-----------------------------------------------------------------------------------
	-- BSB Memory-Mapped Registers
	-----------------------------------------------------------------------------------
	-- Instantiates control and status bytes accessibled from the BSB
	bsb_regs0: entity work.bsb_regs
		generic map (
			NUMBER_OF_CONTROL_BYTES => control_bytes'Length(1), -- Number of bits in the control word
			NUMBER_OF_STATUS_BYTES  => status_bytes'Length(1), -- Number of bits in the status word.
			DEFAULT_CONTROL_BYTES   => X"00_80_00"
		)

		port map (
			-- Control interface (command and reply stream buses)
			ctrl_cmd_in_dat   => ctrl_cmd_in_dat,
			ctrl_cmd_in_rdy   => ctrl_cmd_in_rdy,
			ctrl_rply_out_dat => ctrl_rply_out_dat,
			ctrl_rply_out_rdy => ctrl_rply_out_rdy,
			ctrl_clk          => ctrl_clk,
			ctrl_rst          => ctrl_rst,

			control_bytes => control_bytes,
			status_bytes  => status_bytes
		);


	encodedsync_gen: if IMPLEMENT_CLOCK_ENCODED_SYNC generate

		-- SYNC encoding signals
		signal user_sync_dly: std_logic;
		signal user_sync_oneshot: std_logic;
		signal clk200_counter: unsigned(4 downto 0);

		-- SYNC decoding signals
		signal refclk_counter: unsigned(4 downto 0);
		signal fmc_refclk_sample: std_logic;
		signal fmc_refclk_previous: std_logic;


	begin
		-------------------------------------------------------------------------
		-- 10 MHz reference clock generation with encoded SYNC
		-------------------------------------------------------------------------

		clk10gen_proc: process(clk200, rst)
		begin
			if rst = '1' then
				clk200_counter <= (others => '0');
				user_sync_dly <= '0';
				user_sync_oneshot <= '0';

			elsif rising_edge(clk200) then
				-- Free running counter from 0 to 19
				if clk200_counter = 20 - 1 then
					clk200_counter <= (others => '0');
				else
					clk200_counter <= clk200_counter + 1;
				end if;

				-- Detect rising edge on user_sync
				user_sync_dly <= user_sync;
				if user_sync_dly = '0' and user_sync = '1' then
					user_sync_oneshot <= '1'; -- will be set back to zero below
				end if;

				-- Set or reset clk10 bit depending on the value of the clk200 counter
				if (clk200_counter = 0) then
					clk10_out <= '1';

				elsif clk200_counter = 5 and user_sync_oneshot = '1' then -- Generate a shorter "high" period of the SYNC signal is enabled
					clk10_out <= '0';
					user_sync_oneshot <= '0';
				elsif clk200_counter = 10 then
					clk10_out <= '0';
				end if;

			-- Generate the external SYNC halfway between the rising edge to ensure proparagtion delays will not cause matastable states
			--      if clk200_counter=10 then
			--        EXT_SYNC_OUT<=local_sync or user_sync;
			--      end if;

			end if; -- rst/CLK
		end process;


		-------------------------------------------------------------------------
		-- SYNC recovery
		-------------------------------------------------------------------------
		-- Detects sync events based on the duty cycle of the 10MHz REFCLK
		--
		-- We sample the 10 MHz reference clock with the internal 200 MHz clock. There are 20 samples per REFCLK (10 high, 10 low for a 50 % duty cycle.)
		-- We enable the rcovered_sync signal when a high pulse of the 10 MHz clock is 8 samples or less (<=40% duty cycle).
		-- Since we detect the high time, the position of the rising edge is not affected by the pulse width modulation.
		-- Devices that are sensitive to the rising edge (such as PLLs) should therefore not be affected by the scheme.
		sync_det_proc: process(clk200, rst)
		begin
			if rst = '1' then
				refclk_counter <= (others => '0');
				recovered_sync <= '0';
				fmc_refclk_previous <= '0';

			elsif rising_edge(clk200) then
				-- sample the 10 MHz reference clock with the internal 200 MHz clock.
				fmc_refclk_sample <= clk10;
				fmc_refclk_previous <= fmc_refclk_sample;

				-- count how many 200 MHz cycles the 10 MHz stays high
				if fmc_refclk_sample = '0' then
					refclk_counter <= (others => '0');
				elsif signed(refclk_counter) /= -1 then -- if not maximum count value possible, increase counter
					refclk_counter <= refclk_counter + 1;
				end if;
				-- On the falling edge of the reference clock, set recovered_sync if the clock has stayed high for less than 8 samples.
				if fmc_refclk_sample = '0' and fmc_refclk_previous = '1' then
					if refclk_counter <= 8 then
						recovered_sync <= '1';
					else
						recovered_sync <= '0';
					end if;
				end if;
			end if; -- rst/CLK
		end process;

	end generate encodedsync_gen; -- if IMPLEMENT_CLOCK_ENCODED_SYNC

	-- Pass the user-controlled sync signal to the output after resynchronizing it to clk10
	--syncout_proc: process(clk10)
	--begin
	--	if falling_edge(clk10) then
	--		sync_out <= user_sync;
	--	end if;
	--end process;


	-- Resynchronize user_sync to the falling edge clk10. This will give margin for the boards that will capture this sync signals on the following rising edge of their clk10.
	syncout_cdc0: xpm_cdc_single
		generic map (
			SRC_INPUT_REG => 0
		)
		port map (
			src_clk  => '0',
			src_in   => user_sync,
			dest_clk => not clk10, -- synchronize on the falling edge of clk10
			dest_out => sync_out
		);

	mezzsync_gen: for i in 0 to NUMBER_OF_MEZZANINES - 1 generate
		signal refclk_delay_dly: std_logic_vector(4 downto 0);
		signal refclk_delay_rst_dly: std_logic;

		signal fmc_refclk_buf: std_logic;
		signal fmc_refclk_dly: std_logic;

		-- Make sure the ADC SYNC registers are placed in the IO block with the OBUFDS buffer to ensure
		-- timing reproducibility and low jitter
		signal adc_sync: std_logic; attribute iob of adc_sync: signal is "true";


	begin

		-- Pipeline the IDELAY control lines because they may be at the other end of the chip.
		idelay_pipe_proc: process(ctrl_clk)
		begin
			if rising_edge(ctrl_clk) then
				refclk_delay_dly <= refclk_delay(i);
				refclk_delay_rst_dly <= refclk_delay_rst;
			end if;
		end process;

		-------------------------------------------------------------------------
		-- FMC 10 MHz reference clock reception
		-------------------------------------------------------------------------
		-- Instantiate the LVDS pad that receives the Reference clock from the FMC board
		fmcclk0: IBUFGDS
			generic map (
				DIFF_TERM    => TRUE, -- Differential Termination
				IBUF_LOW_PWR => FALSE -- Low power(TRUE) vs. performance(FALSE)
			)
			port map (
				i  => fmc_refclk_p(i),
				ib => fmc_refclk_n(i),
				o  => fmc_refclk_buf
			);

		-- Delay the clock so we can scan its phase and determine the phase of the ADC clock.
		-- We will use this to
		--    1) analyze the phase of the 200 MHz ADC_CLK signal relative to the received 10 MHz reference clock reference and determine what is the optimal adc_sync timing
		--    2) set the timing of the SYNC pulse to ensure reliable synchronization on a non-ambiguous 1600 MHz ADC reference clock edge.
		refclkdly0: IODELAYE1
			generic map (
				CINVCTRL_SEL => FALSE, -- Dynamically inverts the Clock (C) polarity.
				DELAY_SRC    => "I", -- Specifies the source to the IODELAY component. "I" means it will be
				-- connected directly to an input port or IBUF (input mode), "O" means it will be connected to an output port or OBUF (output mode), "IO"
				-- means it will be connected to a port, and "DATAIN" means it will not be connected to any port (internal mode).
				HIGH_PERFORMANCE_MODE => TRUE, -- When TRUE, this attribute reduces the output jitter.
				IDELAY_TYPE           => "VAR_LOADABLE", -- Specifies a fixed, variable or default (eliminate hold time) input delay.
				--    IDELAY_VALUE => 0, -- Specifies the number of taps of delay for the input path when in fixed mode or the initial delay tap value for variable mode.
				--    ODELAY_TYPE => "FIXED",
				--    ODELAY_VALUE => 0, -- Specifies the number of taps of delay for the output path.
				REFCLK_FREQUENCY => 200.0, -- When using an associated IDELAYCTRL, specifies the input reference frequency to the component.
				SIGNAL_PATTERN   => "CLOCK" -- Used by the delay calculator to determine different propagation
			-- delays through the IODELAY block based on the setting. DATA will be the addition of per tap delay and per tap jitter. No jitter is
			-- introduced for clock-like signals.
			)
			port map (
				-- Inputs
				idatain  => fmc_refclk_buf, -- 1-bit Data input to device from the I/O (connect directly to port, I/O Buffer). When IDATAIN is used, DATAIN must be tied to a logic zero (ground).
				clkin    => '0', -- 1-bit Clock Access into the IODELAY (from the IO CLKMUX)
				datain   => '0', -- 1-bit Data input for the internal datapath delay. When DATAIN is used, IDATAIN and ODATAIN must be tied to a logic zero (ground).
				odatain  => '0', -- 1-bit Data input for the output datapath from the device (connect to output data source). When ODATAIN is used, DATAIN must be tied to a logic zero (ground).
				t        => '1', -- 1-bit 3-state input control. Tie high for input-only or internal delay or tie low for output only.
				cinvctrl => '0', -- 1-bit Dynamically inverts the Clock (C) polarity

				-- Delayed output
				dataout => fmc_refclk_dly, -- 1-bit Delayed data output from input port (connect to input datapath logic)

				-- Delay control
				cntvalueout => open, -- 5-bit Counter value going to fabric for monitoring purpose
				cntvaluein  => refclk_delay_dly, -- 5-bit Counter value from fabric for loadable counter application
				c           => ctrl_clk, -- 1-bit Clock input (Must be connected for variable mode)
				inc         => '0', -- 1-bit Increment / Decrement tap delay
				ce          => '0', -- 1-bit Active high enable increment/decrement function
				rst         => refclk_delay_rst_dly -- 1-bit Active high, synchronous reset, resets delay chain to IDELAY_VALUE/

			);

		refclk_bufg_gen: case FPGA_SERIES generate

			when v6_case: FPGA_VIRTEX6 =>
				signal fmc_refclk_bufr: std_logic;
			begin
				-- ML605/ Virtex 6 notes:
				-- Instantiate a BUFR to help route the Reference Clock to the BUFG
				-- We cannot use a BUFR in the same bank to distribute REFCLK since all the BUFR are used by the ADC channels.
				-- Consequently, we route to a BUFR 2 banks above, then to the BUFG.
				-- We could route directly to a BUFG but the path is less clean.

				fmcbufr0: BUFR
					generic map (
						BUFR_DIVIDE => "BYPASS", --  ("BYPASS", "1", "2", "3", "4", "5", "6", "7", "8")
						SIM_DEVICE  => "7SERIES"
					) -- Specify target device, "VIRTEX4", "VIRTEX5", "VIRTEX6"
					port map (
						i   => fmc_refclk_dly, -- Clock buffer input
						o   => fmc_refclk_bufr, -- Clock buffer output
						ce  => '1', -- Clock enable input
						clr => '0' -- Clock buffer reset input
					);
				-- Instantiate the BUFG that distribute the Refrence Clock through the design
				-- Among other things, that clock is used by the ADCDAQ module to sample the ADC clock using a IDDR

				fmcbufg0: BUFG
					port map (
						i => fmc_refclk_bufr,
						o => fmc_refclk(i) -- 1-bit Clock Output pin
					);
			end v6_case;

			when others=>
				-- Kintex 7 and Ultrascale(+) do not need a BUFR
				fmcbufg0: BUFG
					port map (
						i => fmc_refclk_dly,
						o => fmc_refclk(i) -- 1-bit Clock Output pin
					);

		--   -- We might have used the BUFH in the past
		--   FMCBUFH0 : BUFH
		--     port map (
		--       I => fmc_refclk_dly(i),
		--       O => fmc_refclk(i) -- 1-bit Clock Output pin
		--     );

		end generate refclk_bufg_gen;



		-- Generate a logic signal pulsing at half the Reference Clock frequency to be used for the frequency counter.
		process(all) begin
			if rising_edge(fmc_refclk(i)) then
				fmc_refclk_div2(i) <= not fmc_refclk_div2(i);
			end if;
		end process;

		-- The state machine requests a SYNC on the motherboard 10 MHz rising
		-- edge. The reference clock sent to the mezzanine *is inverted* relative
		-- to the motherboard reference. The Mezzanine sends a copy of its
		-- internal 10 MHz used to lock the PLL. The 10 MHz is therefore approximately an
		-- inverted version of the motherboard 10 MHz, plus or minus a small
		-- delay.
		--
		-- We want the SYNC signal edge to be timed relative to the rising edge
		-- of the mezzanine reference to allow accurate positioning between the
		-- ADC 1600 MHz clock rising edges. So we need to transfer an internal
		-- sync signal clocked on the motherboard reference and generate an
		-- external sync clocked on the external reference.
		--
		-- The Mezz reference falls when the internal sync toggles in the rising
		-- edge of the motherboard reference. So we can directly clock the
		-- external sync signal on the next rising edge of the mezzanine
		-- reference, which happens hald a cycle (50 ns) later. This should gives
		-- us plenty of setup and hold time (50 us of each ideally).
		--
		process(all) begin
			if rising_edge(fmc_refclk(i)) then -- rising edge happens 50 us after the adc_sync_pre toggle.
				adc_sync <= adc_sync_pre;
			-- adc_sync_pre2(i) <= adc_sync_pre;
			end if;
		end process;

		-- Instantiate the LVDS sync signals to be sent to the mezzanines
		-- The adc_sync signal shall be registered direcly in the IOB for best performance.
		syncbuf0: OBUFDS
			generic map (
				--    DRIVE=>24,
				IOSTANDARD => "DEFAULT",
				SLEW       => "FAST"
			)
			port map (
				i  => adc_sync, -- Buffer input
				o  => adc_sync_p(i), -- Diff_p output (connect directly to top-level port)
				ob => adc_sync_n(i) -- Diff_n output (connect directly to top-level port)
			);

	end generate mezzsync_gen;


	-------------------------------------------------------------------------
	-- ADC SYNC state machine
	-------------------------------------------------------------------------
	-- Implements the SYNC process, which resets the ADC and the ADCDAQ in the right order to ensure reproducible data acquisition delays
	sync_source_vect <= (
	                     0 => '0',
	                     1 => recovered_sync,
	                     2 => sync_in(0),
	                     3 => sync_in(1),
	                     4 => sync_in(2),
	                     5 => sync_in(3),
	                     6 => sync_in(4),
	                     7 => sync_in(5)
	                    );

	clksync: process(clk10, rst)
	begin
		-- The reset is asynchonous to make sure it is executed even in the absence of the Reference Clock.
		if rst = '1' then
			sync_state <= SYNC_STATE_IDLE;
			adc_sync_pre <= '0';
			adcdaq_reset <= '0';
			--      BUFR_RST<='0';
			sync_ctr <= (others => '0');
			sync <= '0';
			sync_dly <= '0';
			local_sync_reg <= '0';
			local_sync_dly <= '0';
			sync_event_ctr <= (others => '0');
			sync_done <= '1';
		elsif rising_edge(clk10) then
			-- sync <= recovered_sync or local_sync or (slave and EXT_SYNC_IN);

			-- Implement a synchronizer for local_sync
			local_sync_reg <= local_sync;
			local_sync_dly <= local_sync_reg;

			sync <= sync_source_vect(to_integer(unsigned(sync_source)));
			sync_dly <= sync;

			adc_sync_pre <= '0'; -- overriden below if needed.
			adcdaq_reset <= '0'; -- overriden below if needed.

			if adc_sync_user = '1' then
				adc_sync_pre <= '1';
			else
				if (sync = '1' and sync_dly = '0') or (local_sync_reg = '1' and local_sync_dly = '0') then -- reset the ADCDAQ SERDES and enable the SYNC line to stop the ADC clock
					sync_done <= '0';
					sync_event_ctr <= sync_event_ctr + 1;
					sync_state <= SYNC_STATE_STABILIZE_PLL;
					sync_ctr <= (others => '0'); -- clear counter for the next phase

				elsif sync_state = SYNC_STATE_STABILIZE_PLL then -- wait for the ADC PLL to stabilize after the change of duty cycle of the clock to ensure we get a reliable timing relative to the 1600 MHz clock
					sync_ctr <= sync_ctr + 1;
					if (SIM = FALSE and signed(sync_ctr) = -1) or (SIM = TRUE and sync_ctr = 16 - 1) then
						adcdaq_reset <= '1';
						adc_sync_pre <= '1';
						sync_state <= SYNC_STATE_ADCDAQ_RESET_RELEASE;
					end if;

				elsif sync_state = SYNC_STATE_ADCDAQ_RESET_RELEASE then -- Releases the ADCDAQ reset
					adcdaq_reset <= '0'; -- statement for clarity only
					adc_sync_pre <= '1';
					sync_state <= SYNC_STATE_SYNC_RELEASE;

				elsif sync_state = SYNC_STATE_SYNC_RELEASE then -- Disable the SYNC line, which starts the ADC clock
					adcdaq_reset <= '0'; -- statement for clarity only
					adc_sync_pre <= '0'; -- statement for clarity only
					sync_done <= '1';
					sync_state <= SYNC_STATE_IDLE;
				end if;
			end if;
		end if; -- rst/CLK
	end process;


end architecture impl;

