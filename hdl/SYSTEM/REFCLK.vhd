----------------------------------------------------------------------------------
--! @file
-- Company: Mc Gill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    2011-08-24
-- Design Name:
-- Module Name:    REFCLK - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
--
-- Dependencies:
--
-- Revision:
--		2011-09-22 JFC: Created
--		2012-09-05 JFC: Inverted polarity of enable_sync_detection in the IF() statement, which was wrong.
--		2012-09-05 JFC: Cleanup. Removed MMCM references. Added enable_sync_generation flag. Disable enable_sync_detection by default. These last two are to try prevent the SYNC generator state machine to start generating a SYNC sequence (and resetting the SERDES) when the FMC board is absent and REFCLK is clocked randomly.
--		2012-09-28 JFC: Changed SYNC event sequencing process to use a single adcdaq_reset.
--		2012-10-22 JFC: Added internal REFCLK selection with a BUFGMUX instead of the BUFG. Removed unused logic.
-- LIBRARY DECLARATIONS --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chFPGA_Package.all; -- Get all component definitions

library UNISIM;
use UNISIM.VComponents.all;

--- ENTITY DECLARATIONS -------------------------------------------------------------------------------
--! \brief
--! Handles the FMC Reference Clock generation, SYNC event detection and generation, and ADC SYNC signal generation
entity REFCLK is
	 GENERIC (
	 	PLATFORM_ID: integer;
	 	NUMBER_OF_MEZZANINES: integer;
		SIM: BOOLEAN := FALSE
		);

	port (
		-- Control interface
		CTRL_CMD_IN_DAT: in AXIS8_DAT_STRUCT; --! Command stream input, signals from master (Data, Valid, Last)
		CTRL_CMD_IN_RDY: out AXIS8_RDY_STRUCT; --! Command stream input, signals to master (Ready)
		CTRL_RPLY_OUT_DAT: out AXIS8_DAT_STRUCT; --! Reply stream output, signals to slave (Data, Valid, Last)
		CTRL_RPLY_OUT_RDY: in AXIS8_RDY_STRUCT; --! Reply stream output,  signals from slave (Ready)
		CTRL_CLK: in  STD_LOGIC;
		CTRL_RST: in std_logic;

		-- FMC reference clock
		fmc_refclk_p: in std_logic_vector(0 to NUMBER_OF_MEZZANINES-1); --! Reference Clock LVDS input from the FMC. The Input pad is instantiated in this module.
		fmc_refclk_n: in std_logic_vector(0 to NUMBER_OF_MEZZANINES-1);

		fmc_refclk: out std_logic_vector(0 to NUMBER_OF_MEZZANINES-1); --! BUFG-buffered, delayed FMC Mezzanine reference clock, used to scan the ADC clock waveform
		fmc_refclk_div2: out std_logic_vector(0 to NUMBER_OF_MEZZANINES-1); --! Logic signal pulsing at half the REFCLK frequency to be used by the Frequency Counter.

		adc_sync_P: out std_logic_vector(0 to NUMBER_OF_MEZZANINES-1); --! LVDS ADC SYNC output. The LVDS output pad is instantiated in this module.
		adc_sync_N: out std_logic_vector(0 to NUMBER_OF_MEZZANINES-1);

		clk10: in std_logic; -- Buffered 10 MHz backplane reference clock (with well defined phase relationship with all other boards in the system)
		clk10_out: out std_logic;

		sync_in: in std_logic_vector(0 to 5); -- External sync request signals (from backplane or IRIG-B comparator)
		sync_out: out std_logic;

		adcdaq_reset: out std_logic; --! Resets the ADCDAQ upon a SYNC event

		clk200: in STD_LOGIC;
		-- System-level signals
		RST: in STD_LOGIC -- synchronous to clk200
	);

end REFCLK;

architecture Behavioral of REFCLK is

-- Attributes used in this module
attribute dont_touch: string;
attribute IOB: string;
attribute ASYNC_REG: string;

constant FPGA_SERIES: integer :=FPGA_SERIES_LIST(PLATFORM_ID);

--- Define Control word and its signals
--signal CONTROL_WORD: STD_LOGIC_VECTOR(47 downto 0); -- default value set in the CMD_SLAVE
signal control_bytes: slv8_array(0 to 2); -- default value set in the CMD_SLAVE
signal status_bytes: slv8_array(0 to 2); -- default value set in the CMD_SLAVE

--signal fmc_clk200_nobuf: STD_LOGIC;
--signal fmc_clk200_int: STD_LOGIC;
signal fmc_refclk_buf: std_logic_vector(0 to NUMBER_OF_MEZZANINES-1);
signal fmc_refclk_dly: std_logic_vector(0 to NUMBER_OF_MEZZANINES-1);
signal fmc_refclk_int: std_logic_vector(0 to NUMBER_OF_MEZZANINES-1);
signal FMC_REFCLK_BUFR: STD_LOGIC;
signal fmc_refclk_div2_int: std_logic_vector(0 to NUMBER_OF_MEZZANINES-1) := (others=>'0'); -- Initialization required
signal fmc_refclk_sel: std_logic;

signal FMC_REFCLK_SAMPLE: STD_LOGIC;
signal FMC_REFCLK_PREVIOUS: STD_LOGIC;

-- signal clk10: STD_LOGIC; -- Fabric-generated 10 MHz clock
-- Make sure the net anem is preserved so it can be sued in defining constraints
-- attribute DONT_TOUCH of clk10: signal is "yes";

--signal EXT_SYNC_OUT: STD_LOGIC;
-- signal EXT_SYNC_IN: STD_LOGIC;
signal adc_sync: std_logic_vector(0 to NUMBER_OF_MEZZANINES-1);
attribute IOB of adc_sync: signal is "true"; -- Make sure the ADC SYNC registers are placed in the IO block
signal adc_sync_pre: std_logic;
-- signal adc_sync_pre2: std_logic_vector(0 to NUMBER_OF_MEZZANINES-1);

signal sync_event_ctr: UNSIGNED(3 downto 0);
signal clk200_counter: UNSIGNED(4 downto 0);
signal refclk_counter: UNSIGNED(4 downto 0);
--signal ADC_CLK_COUNTER: UNSIGNED(7 downto 0);
--signal fmc_clk200_counter: UNSIGNED(7 downto 0);
signal remote_sync: std_logic;
signal remote_sync_dly: std_logic;
signal remote_sync_oneshot: std_logic;


signal local_sync: std_logic; -- asynchronous (on clk125)
signal local_sync_reg: std_logic;  -- on clk10
signal local_sync_dly: std_logic;  -- on clk10

attribute ASYNC_REG of local_sync_reg: signal is "true";
attribute ASYNC_REG of local_sync_dly: signal is "true";




signal recovered_sync: std_logic;
signal adc_sync_user: std_logic;
signal sync_done: std_logic;

-- signal dci_reset: std_logic;
-- signal dci_locked: std_logic;

signal sync_ctr: UNSIGNED(15 downto 0);
signal sync: std_logic;
signal sync_dly: std_logic;
signal sync_source: std_logic_vector(2 downto 0);
signal sync_source_vect: std_logic_vector(0 to 7);

signal refclk_delay: slv5_array(0 to 1);
signal refclk_delay_dly: slv5_array(0 to 1);
signal refclk_delay_rst: std_logic;
signal refclk_delay_rst_dly: std_logic;

type SYNC_STATE_TYPE is (SYNC_STATE_IDLE, SYNC_STATE_STABILIZE_PLL, SYNC_STATE_SYNC_RELEASE, SYNC_STATE_ADCDAQ_RESET_RELEASE);
signal sync_state: SYNC_STATE_TYPE:=SYNC_STATE_IDLE;
signal adcdaq_reset_int: std_logic;
--signal BUFR_RST: std_logic;


begin
-----------------------------------------------------------------------------------
-- CONTROL and STATUS Bytes
-----------------------------------------------------------------------------------
--! @addtogroup memory_map
--! REFCLK Module
--! =============
--! ----------------------------------------------------------------------------------------
--! | Page | Addr | Bit(s)|     Name                | Description                           |
--! |---------|-----|-----|-------------------------|---------------------------------------|
--! | CONTROL |  0  |  7  | adc_sync_user           | if TRUE, forces ADC SYNC to be asserted. If FALSE, the adc_sync is generated by the SYNC state machine. |
--! |         |     |  6  | (unused)                |  |
--! |         |     |  5  | local_sync              | Force the generation of a local SYNC sequence on the local board only. Has the same effect as an external SYNC.  The SYNC is synchronized to the 10 MHz output (transitions on its falling edge) |
--! |         |     |  4  | remote_sync             | Generate an external SYNC signal, but does not cause a local sync. The external sync is both sent on the sync_out port and is encoded on the 10 MHz clock output generated by this block. |
--! |         |     | 3:2 | (unused)                |  |
--! |         |     | 1:0 | sync_source             | Selects the source of the SYNC signal: '00': local sync only, '01': sync recovered from the clock, '01': backplane sync, '11': IRIG-B-based sync|
--! |         |  1  |  7  | REFCLK_SEL              | Selects the source of the REFCLK needed for SYNC generation. 0=FMC, 1=internal REFCLK generator. |
--! |         |     | 6:5 | (unused)                | |
--! |         |     | 4:0 | REFCLK1_DLY             | Delay on the Mezzanine 1 REFCLK, used to scan the ADC clock waveform and set the ADC SYNC timing. |
--! |         |  2  |  7  | REFCLK_DLY_RST          | Resets the REFCLK delay line. Needed to load a new delay value.|
--! |         |     | 4:0 | REFCLK0_DLY             | Delay on Mezzanine 0 REFCLK, used to scan the ADC clock waveform and set the ADC SYNC timing. |
--! | STATUS  |  0  | 7:4 | sync_event_ctr          | |
--! |         |     |  3  | (unused)                | |
--! |         |     |  2  | recovered_sync          | |
--! |         |     |  1  | SYNC                    | |
--! |         |     |  0  | adcdaq_reset_int        | |
--! |         |  1  | 7:0 | (unused)                | |
--! |         |  2  | 7:6 | (unused)                | |
--! |         |     |  5  | sync_done               | |
--! |         |     | 4:0 | (unused)                | |
--! ------------------------------------------------------------------------------
--!

-- CONTROL Byte 0
adc_sync_user <= control_bytes(0)(7);
-- dci_reset     <= control_bytes(0)(6);
local_sync    <= control_bytes(0)(5);
remote_sync   <= control_bytes(0)(4);
sync_source   <= control_bytes(0)(2 downto 0);

-- CONTROL Byte 1

fmc_refclk_sel      <= control_bytes(1)(7);
refclk_delay(1)     <= control_bytes(1)(4 downto 0);

-- CONTROL Byte 2
refclk_delay_rst    <= control_bytes(2)(7);
refclk_delay(0)     <= control_bytes(2)(4 downto 0);

--STATUS Byte 0
status_bytes(0)(7 downto 4) <= std_logic_vector(sync_event_ctr);
-- status_bytes(0)(3)          <= dci_locked;
status_bytes(0)(2)          <= recovered_sync;
status_bytes(0)(1)          <= sync;
status_bytes(0)(0)          <= adcdaq_reset_int;

--STATUS Byte 1
status_bytes(1) <= (others=>'0');

--STATUS Byte 2
status_bytes(2)(7 downto 6) <= (others=>'0');
status_bytes(2)(5)          <= sync_done;
status_bytes(2)(4 downto 3) <= (others=>'0');
status_bytes(2)(2)          <= sync_in(2);
status_bytes(2)(1)          <= sync_in(1);
status_bytes(2)(0)          <= sync_in(0);

-----------------------------------------------------------------------------------
-- Memory-Mapped interface
-----------------------------------------------------------------------------------
--! Instantiates a memory-mapped interface to the control and status bytes
CTRL_SLAVE0: entity work.CTRL_SLAVE
	GENERIC MAP (
		NUMBER_OF_control_bytes=>control_bytes'Length(1), -- Number of bits in the control word
		NUMBER_OF_status_bytes=>status_bytes'Length(1), -- Number of bits in the status word.
		DEFAULT_control_bytes=> X"00_80_00"
 	)

	PORT MAP(

		-- Control interface (command and reply stream buses)
		CTRL_CMD_IN_DAT => CTRL_CMD_IN_DAT,
		CTRL_CMD_IN_RDY => CTRL_CMD_IN_RDY,
		CTRL_RPLY_OUT_DAT => CTRL_RPLY_OUT_DAT,
		CTRL_RPLY_OUT_RDY => CTRL_RPLY_OUT_RDY,
		CTRL_CLK => CTRL_CLK,
		CTRL_RST => CTRL_RST,

		control_bytes => control_bytes,
		status_bytes => status_bytes
	);

-------------------------------------------------------------------------
-- 10 MHz reference clock generation and buffer
-------------------------------------------------------------------------

clk10gen_proc: process(clk200,RST)
	begin
		if RST='1' then
			clk200_counter<=(others=>'0');
			remote_sync_dly<='0';
			remote_sync_oneshot<='0';

		elsif rising_edge(clk200) then

			-- Free running counter from 0 to 19
			if clk200_counter=20-1 then
				clk200_counter<=(others=>'0');
			else
				clk200_counter<=clk200_counter+1;
			end if;

			-- Detect rising edge on remote_sync
			remote_sync_dly<=remote_sync;
			if remote_sync_dly='0' and remote_sync='1' then
				remote_sync_oneshot<='1'; -- will be set back to zero below
			end if;

			-- Set or reset clk10 bit depending on the value of the clk200 counter
			if (clk200_counter=0) then
				clk10_out<='1';

			elsif clk200_counter=5 and remote_sync_oneshot='1' then -- Generate a shorter "high" period of the SYNC signal is enabled
				clk10_out<='0';
				remote_sync_oneshot<='0';
			elsif clk200_counter=10 then
				clk10_out<='0';
			end if;

			-- Generate the external SYNC halfway between the rising edge to ensure proparagtion delays will not cause matastable states
--			if clk200_counter=10 then
--				EXT_SYNC_OUT<=local_sync or remote_sync;
--			end if;

		end if; --RST/CLK
	end process;


-- Pipeline the IDELAY control lines because they may be at the other end of the chip.
idelay_pipe_proc: process(ctrl_clk)
begin
	if rising_edge(ctrl_clk) then
		refclk_delay_dly <= refclk_delay;
		refclk_delay_rst_dly <= refclk_delay_rst;
	end if;
end process;


gensync: for i in 0 to NUMBER_OF_MEZZANINES-1 generate
	SYNCBUF0: OBUFDS
		generic map(
	--		DRIVE=>24,
			IOSTANDARD=>"DEFAULT",
			SLEW=>"FAST"
			)
		port map (
			I => adc_sync(i), -- Buffer input
			O => adc_sync_P(i), -- Diff_p output (connect directly to top-level port)
			OB => adc_sync_N(i) -- Diff_n output (connect directly to top-level port)
			);

	-------------------------------------------------------------------------
	-- FMC 10 MHz reference clock reception
	-------------------------------------------------------------------------
	--! Instantiate the LVDS pad that receives the Reference clock from the FMC board
	FMCCLK0: IBUFGDS
		generic map(
			DIFF_TERM=>TRUE, --Differential Termination
			IBUF_LOW_PWR=>FALSE--Low power(TRUE) vs. performance(FALSE)
			)
		port map(
			I  => fmc_refclk_p(i),
			IB => fmc_refclk_n(i),
			O  => fmc_refclk_buf(i)
			);

	--! Delay the clock so we can scan its phase and determine the phase of the ADC clock.
	--! We will use this to
	--!    1) analyze the phase of the 200 MHz ADC_CLK signal relative to the received 10 MHz reference clock reference and determine what is the optimal adc_sync timing
	--!    2) set the timing of the SYNC pulse to ensure reliable synchronization on a non-ambiguous 1600 MHz ADC reference clock edge.
	REFCLKDLY0: IODELAYE1
		generic map (
			CINVCTRL_SEL => FALSE, -- Dynamically inverts the Clock (C) polarity.
			DELAY_SRC => "I", -- Specifies the source to the IODELAY component. "I" means it will be
					-- connected directly to an input port or IBUF (input mode), "O" means it will be connected to an output port or OBUF (output mode), "IO"
					-- means it will be connected to a port, and "DATAIN" means it will not be connected to any port (internal mode).
			HIGH_PERFORMANCE_MODE => TRUE, -- When TRUE, this attribute reduces the output jitter.
			IDELAY_TYPE => "VAR_LOADABLE", -- Specifies a fixed, variable or default (eliminate hold time) input delay.
	--		IDELAY_VALUE => 0, -- Specifies the number of taps of delay for the input path when in fixed mode or the initial delay tap value for variable mode.
	--		ODELAY_TYPE => "FIXED",
	--		ODELAY_VALUE => 0, -- Specifies the number of taps of delay for the output path.
			REFCLK_FREQUENCY => 200.0, -- When using an associated IDELAYCTRL, specifies the input reference frequency to the component.
			SIGNAL_PATTERN => "CLOCK" -- Used by the delay calculator to determine different propagation
						-- delays through the IODELAY block based on the setting. DATA will be the addition of per tap delay and per tap jitter. No jitter is
						-- introduced for clock-like signals.
		)
		port map (

			-- Inputs
			IDATAIN => fmc_refclk_buf(i), -- 1-bit Data input to device from the I/O (connect directly to port, I/O Buffer). When IDATAIN is used, DATAIN must be tied to a logic zero (ground).
			CLKIN => '0', -- 1-bit Clock Access into the IODELAY (from the IO CLKMUX)
			DATAIN => '0', -- 1-bit Data input for the internal datapath delay. When DATAIN is used, IDATAIN and ODATAIN must be tied to a logic zero (ground).
			ODATAIN => '0', -- 1-bit Data input for the output datapath from the device (connect to output data source). When ODATAIN is used, DATAIN must be tied to a logic zero (ground).
			T => '1', -- 1-bit 3-state input control. Tie high for input-only or internal delay or tie low for output only.
			CINVCTRL => '0', -- 1-bit Dynamically inverts the Clock (C) polarity

			-- Delayed output
			DATAOUT => fmc_refclk_dly(i), -- 1-bit Delayed data output from input port (connect to input datapath logic)

			-- Delay control
			CNTVALUEOUT => open, -- 5-bit Counter value going to fabric for monitoring purpose
			CNTVALUEIN => refclk_delay_dly(i), -- 5-bit Counter value from fabric for loadable counter application
			C => CTRL_CLK, -- 1-bit Clock input (Must be connected for variable mode)
			INC => '0', -- 1-bit Increment / Decrement tap delay
			CE => '0', -- 1-bit Active high enable increment/decrement function
			RST => refclk_delay_rst_dly -- 1-bit Active high, synchronous reset, resets delay chain to IDELAY_VALUE/

		);

	--! ML605/ Virtex 6 notes:
	--! Instantiate a BUFR to help route the Reference Clock to the BUFG
	--! We cannot use a BUFR in the same bank to distribute REFCLK since all the BUFR are used by the ADC channels.
	--! Consequently, we route to a BUFR 2 banks above, then to the BUFG.
	--! We could route directly to a BUFG but the path is less clean.
	-- FMCBUFR0 : BUFR -- NOTE: Instance name is associated with a UCF LOC contraint
	-- 		generic map (
	-- 			BUFR_DIVIDE => "BYPASS", --  ("BYPASS", "1", "2", "3", "4", "5", "6", "7", "8")
	-- 			SIM_DEVICE => "7SERIES"
	-- 			) -- Specify target device, "VIRTEX4", "VIRTEX5", "VIRTEX6"
	-- 		port map (
	-- 			I => fmc_refclk_dly, -- Clock buffer input
	-- 			O => FMC_REFCLK_BUFR, -- Clock buffer output
	-- 			CE => '1', -- Clock enable input
	-- 			CLR => '0'-- Clock buffer reset input
	-- 		);
	--! Instantiate the BUFG that distribute the Refrence Clock through the design
	--! Among other things, that clock is used by the ADCDAQ module to sample the ADC clock using a IDDR
	-- FMCBUFG0 : BUFGMUX
	-- 	port map (
	-- 		I0 => FMC_REFCLK_BUFR,
	-- 		I1 => clk10,
	-- 		S => fmc_refclk_sel,
	-- 		O => fmc_refclk_int -- 1-bit Clock Output pin
	-- 	);

	-- fmc_bufg_gen: if i=0 generate
		-- Kintex 7 does not uses the BUFR
		-- Temporary bypass of FMC REFCLK. Will need to re-introduce SYNC delay
		FMCBUFG0 : BUFG
			port map (
				I => fmc_refclk_dly(i),
				O => fmc_refclk_int(i) -- 1-bit Clock Output pin
			);

		fmc_refclk(i) <= fmc_refclk_int(i); -- This clock has a BUFG and can reach every ADCDAQs for clock waveform sampling

	-- end generate;

	-- fmc_bufh_gen: if i/=0 generate
	-- 	-- Kintex 7 does not uses the BUFR
	-- 	-- Temporary bypass of FMC REFCLK. Will need to re-introduce SYNC delay
	-- 	FMCBUFH0 : BUFH
	-- 		port map (
	-- 			I => fmc_refclk_dly(i),
	-- 			O => fmc_refclk_int(i) -- 1-bit Clock Output pin
	-- 		);
	-- end generate;

	--! Generates a logic signal pulsing at half the Reference Clock frequency to be used for the frequency counter.
	fmc_refclk_div2(i) <= fmc_refclk_div2_int(i);
	fmcrefclklogic: process(fmc_refclk_int(i))
		begin
			if rising_edge(fmc_refclk_int(i)) then
				fmc_refclk_div2_int(i) <=not fmc_refclk_div2_int(i);
			end if;
		end process;

	--! The state machine requests a SYNC on the motherboard 10 MHz rising
	--! edge. The reference clock sent to the mezzanine *is inverted* relative
	--! to the motherboard reference. The Mezzanine send a copy of its
	--! internal 10 MHz used to lock the PLL. The 10 MHz is therefore approximately an
	--! inverted version of the motherboard 10 MHz, plus or minus a small
	--! delay.
	--!
	--! We want the SYNC signal edge to be timed relative to the rising edge
	--! of the mezzanine reference to allow accurate positioning between the
	--! ADC 1600 MHz clock rising edges. So we need to transfer an internal
	--! sync signal clocked on the motherboard reference and generate an
	--! external sync clocked on the external reference.
	--!
	--! The Mezz reference falls when the internal sync toggles in the rising
	--! edge of the motherboard reference. So we can directly clock the
	--! external sync signal on the next rising edge of the mezzanine
	--! reference, which happens hald a cycle (50 ns) later. This should gives
	--! us plenty of setup and hold time (50 us of each ideally).
	--!
	adcsync_proc: process(fmc_refclk_int(i))
		begin
			if rising_edge(fmc_refclk_int(i)) then -- rising edge happens 50 us after the adc_sync_pre toggle.
				adc_sync(i) <= adc_sync_pre;
				-- adc_sync_pre2(i) <= adc_sync_pre;
			end if;
		end process;

end generate;



-- fmc_refclk_int <= clk10;





-------------------------------------------------------------------------
--! SYNC recovery
-------------------------------------------------------------------------
--! Detects sync events based on the duty cycle of the 10MHz REFCLK
sync_det_proc: process(clk200,RST)
	begin
		if RST='1' then
			refclk_counter<=(others=>'0');
			recovered_sync<='0';
			FMC_REFCLK_PREVIOUS<='0';

		elsif rising_edge(clk200) then
			FMC_REFCLK_SAMPLE <= clk10;
			FMC_REFCLK_PREVIOUS <= FMC_REFCLK_SAMPLE;

			-- count how many 200 MHz cycles the 10 MHz stays high
			if FMC_REFCLK_SAMPLE='0' then
				refclk_counter<=(others=>'0');
			elsif SIGNED(refclk_counter)/=-1 then -- if not maximum count value possible, increase counter
				refclk_counter<=refclk_counter+1;
			end if;

			if FMC_REFCLK_SAMPLE='0' and FMC_REFCLK_PREVIOUS='1' then
				if refclk_counter<=8 then
					recovered_sync<='1';
				else
					recovered_sync<='0';
				end if;
			end if;
		end if; --RST/CLK
	end process;

syncout_proc: process(clk10)
	begin
		if falling_edge(clk10) then
			sync_out <= remote_sync;
		end if;
	end process;

-------------------------------------------------------------------------
-- ADC SYNC state machine
-------------------------------------------------------------------------
--! Implements the SYNC process, which resets the ADC and the ADCDAQ in the right order to ensure reproducible data acquisition delays
--EXT_SYNC_OUT<=adc_sync;
adcdaq_reset <= adcdaq_reset_int;
sync_source_vect <= (
	0=>'0',
	1=> recovered_sync,
	2=> sync_in(0),
	3=> sync_in(1),
	4=> sync_in(2),
	5=> sync_in(3),
	6=> sync_in(4),
	7=> sync_in(5)
	);

clksync: process(clk10, RST)
	begin
		-- The reset is asynchonous to make sure it is executed even in the absence of the Reference Clock.
		if RST='1' then
			sync_state <= SYNC_STATE_IDLE;
			adc_sync_pre <= '0';
			adcdaq_reset_int <= '0';
--			BUFR_RST<='0';
			sync_ctr <= (others=>'0');
			sync <= '0';
			sync_dly <= '0';
			local_sync_reg <= '0';
			local_sync_dly <= '0';
			sync_event_ctr <= (others=>'0');
			sync_done <= '1';
		elsif rising_edge(clk10) then
			-- sync <= recovered_sync or local_sync or (slave and EXT_SYNC_IN);

			-- Implement a synchronizer for local_sync
			local_sync_reg <= local_sync;
			local_sync_dly <= local_sync_reg;

			sync <= sync_source_vect(to_integer(unsigned(sync_source)));
			sync_dly <= sync;

			adc_sync_pre <= '0'; -- overriden below if needed.
			adcdaq_reset_int <= '0'; -- overriden below if needed.

			if adc_sync_user='1' then
				adc_sync_pre <= '1';
			else
				-- Warning: Because adc_sync is to be implemented on a IOB, it must be assigned a new value on every clock to prevent the inferring of a memory element that is implemented by feeding he output back to the input. Reading the output is not possible from the IOB.
				if (sync='1' and sync_dly='0') or (local_sync_reg='1' and local_sync_dly='0') then --! reset the ADCDAQ SERDES and enable the SYNC line to stop the ADC clock
					sync_done<='0';
					sync_event_ctr <= sync_event_ctr + 1;
					sync_state <=SYNC_STATE_STABILIZE_PLL;
					sync_ctr <= (others=>'0'); -- clear counter for the next phase

				elsif sync_state=SYNC_STATE_STABILIZE_PLL then -- wait for the ADC PLL to stabilize after the change of duty cycle of the clock to ensure we get a reliable timing relative to the 1600 MHz clock
					sync_ctr <= sync_ctr+1;
					if (SIM=FALSE and SIGNED(sync_ctr)=-1) or (SIM=TRUE and sync_ctr=16-1) then
						adcdaq_reset_int <= '1';
						adc_sync_pre <= '1';
						sync_state <= SYNC_STATE_ADCDAQ_RESET_RELEASE;
					end if;

				elsif sync_state=SYNC_STATE_ADCDAQ_RESET_RELEASE then -- Releases the ADCDAQ reset
					adcdaq_reset_int<='0'; -- statement for clarity only
					adc_sync_pre <= '1';
					sync_state<=SYNC_STATE_SYNC_RELEASE;

				elsif sync_state=SYNC_STATE_SYNC_RELEASE then -- Disable the SYNC line, which starts the ADC clock
					adcdaq_reset_int<='0'; -- statement for clarity only
					adc_sync_pre <= '0'; -- statement for clarity only
					sync_done <= '1';
					sync_state <= SYNC_STATE_IDLE;
				end if;
			end if;
		end if; -- RST/CLK
	end process;



end Behavioral;

