----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer:  JF Cliche
--
-- Create Date:    13:05:19 11/17/2010
-- Design Name:    chFPGA
-- Module Name:    ADCDAC
-- Project Name: CHIME
-- Target Devices: Originally worked on Virtex 6, now targetting Kintex 7, might have lost some Virtex 6 compatibility
-- Tool versions: ISE 13.1 - Vivado 2022.2

--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
--  110114 JFC: Changed how the clock bugffer outputs are selected for the ISERDES. Now use the IO_CLK_SEL array that are muxed using the CLKREGION generic instead of generating an integer array of indexes. Eliminates the warnings that the assignment to the ISERDES2 is not static
--  110125 JFC: Re-coded how the output word bits are assigned. Dumped the generate statement that crashed the simulator. Used procedural IF instead.
--  				 Implemented DMUX mode, and simulated
--  110127 JFC: included USE_ALTERNATE_CLKDIV to move the output word clock to the BUFIO2_A1 buffer due to interference with BUFGMUX of SFP and PHY
--              Assigned default bus values to "Z" so they can be left open in the instantiations.
--  110601 JFC: Modify for IODELAY, CMD_SLAVE and 32 bit output word
--  110922 JFC: Added RESET on output_word_ctr
--  110927 JFC: Added separate SYNC for BUFR and ISERDES
--  110929 JFC: Added logic to support software-based automatic delay adjustments
--  111006 JFC: Added a readout FIFO will accompanying synchronization logic
--  111009 JFC: Removed IBUFGDS from PLL. Now common to both PLL/NOPLL design
--              Added feedback input to PLL, and connect to ioclk_vect instead of using a feedback using a separate BUFG
--              Added 10 deg phase shift to PLL output 2 (divclk) to match delay with BUFR
--  1205xx JFC: Major cleanup. Implemented AXI4 interface.
--					Local counter now always present (possible by forcing the REFCLK BUFG in another bank).
--					ADC output clock can be switched to clk200.
--					Removed obsolete support for DMUX mode
--					Implemented dummy IBUGDS and output drivers if IMPLEMENT_ADCDAQ=FALSE
--					etc.
--  120608 JFC: changed RAMP_CR to output_word_ctr, and generate TLAST signal on frame boundaries
--  120612 JFC: registered send_data to break combinatorial loop with outside logic and allow timing closure
--  120926 JFC: Cleanup the reset logic. Now uses a single adcdaq_reset line.
--  120938 JFC: separated the SERDES RESET process from fifo write process. Now Start the Fifo write based on the SERDES_RESET state.
--  121101 JFC: Added multiple SERDES_AUTO_RESET to facilitate placement and timing closure
--  130130 JFC: Implemented better support for BUFMR: we can now specify how many BUFMR to use and which BUFMR is used for the clock input (the IDELAY) or the data inputs (IDELAY and ISERDES)
--  130805 JFC: Added differential flag to support the ICEBoard which has some non-differntial inputs.
--  See Git repositiry for more logs

-- Additional Comments:
--    - "SAVE" property ios applied to output nets to ensure the logic and BUFIO2s are not optimized out of the design (to validate fully populated design constraints)
--    - A PLL-generated ioclk_vect and divclk can be used to clock data if the bits are in different, non-adjacent banks.
--    - ADC data ports are always 8 bits.
--    - Data lines go through IDELAY2. Clock lines are also delayed.

-- Feature request

----------- LIBRARY DECLARATIONS -----------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chFPGA_Package.all; -- Get all component definitions
--use work.ip_package.all; -- Import definition of components used in this module

library UNISIM;
use UNISIM.VComponents.all;

library xpm;
use xpm.vcomponents.all;

----------- ENTITY DECLARATIONS -----------------------------------------------------------


-- Implements the data acquisition of one EV8AQ160 ADC channel running at 800 MSPS in non-DMUX mode
-- and outputs a non-blocking 200 MHz 32-bit AXI4-Streaming bus (4 samples per word).
--
entity adcdaq is
	GENERIC (
		FPGA_SERIES            : fpga_series_enum := KINTEX7; -- Used by low-level primitives selected inside ADCDAQ, including generic_fifo
		SAMPLES_PER_FRAME       : integer := 2048; -- Number of samples per frame, used to packetize the output data stream
		IMPLEMENT_ADCDAQ 		: BOOLEAN:= TRUE; -- Indicates if the block is to be implemented. If False, a dummy module will be generated but the I/Os will be preserved.
		INSTANTIATE_IDELAYCTRL 	: BOOLEAN:= TRUE;  -- Indicates if this module implements a IDELAYCTRL. Only one of the DAQ modules needs to implemt it. The tools will generate and place the other ones automatically.
		INSTANTIATE_PLL 		: BOOLEAN:= FALSE; -- Indicates if this module instantiate a PLL to generate a I/O and a word clock.
		CLOCKING_REGION_MAP 	: integer_array := (0 to 8 => 0); -- For K7 designs, maps each data line (indices 0 to 7) and the clock line (index 8) to the BUFR/BUFIO clocking region used by the ADCDAQ. If all entries are -1, no BUFMR is instantiated and all lines connect to a single BUFR/BUFIO.
		IS_DIFFERENTIAL 		: bool_array := (0 to 8 => TRUE); -- Indicates whether each data line (indices 0 to 7) and the clock line (index 8) uses a differential receiver. When FALSE, only the P input is used as a single-ended input.
		PROVIDE_BUFFERED_DIVCLK : BOOLEAN:= FALSE; -- Indicates if this modules provides a buffered (BUFG) 200 MHz ADC clock (to be used to generate the processing clocks). Needs to be set only on those channels that will actually use it because we'll quickly run ot or BUFGs otherwise.
		USE_EXT_DATA_CLK 		: BOOLEAN:= TRUE;  -- Indicates if this modules uses the IO and WORD clocks coming from ioclk_in and divclk_in (TRUE) or of these cloks are generated directly from the ADC (FALSE)
		CLK_VALID_OFFSET 		: INTEGER:= -3;   -- Number of clocks to wait after a full frame before data is declared valid. The software-configurable sample_delay also offsets this delay.
		SIM 					: BOOLEAN:= FALSE -- Indicates if this is code is being simulated. Used to shorten simulation times.
		);
	PORT
		(

		-- ADC High Port

		adc_data_h_p: in  std_logic_vector(7 downto 0); -- Data bus from the ADC
		adc_data_h_n: in  std_logic_vector(7 downto 0);
		adc_clk_h_p : in  std_logic; -- Clock signal from the ADC (Double data rate, i.e one byte both on the rising and falling edge)
		adc_clk_h_n : in  std_logic;

		-- Readout Interface

		m_axis_adc_tdata 	: out std_logic_vector(31 downto 0);
		m_axis_adc_tvalid 	: out std_logic;
		m_axis_adc_tlast  	: out std_logic;
		m_axis_adc_tuser 	: out std_logic_vector(3 downto 0);

		data_ready 	: out std_logic; -- Indicates when the ADC is ready to start sending data. The data won't start to be pushed out until send_data is True. Synchronous to adc_clk;
		send_data 	: in std_logic:= '1'; -- Indicates that we can start sending data on ADC_OUT_DAT. This input signal is used to allow the data transmission to be aligned betweeen all ADC channels. Synchronous to adc_clk.

		adc_clk 	: in std_logic; -- Clock for the readout interface. Should be the same speed or faster than the

		-- Output Clocks

		ioclk_out_pll 	: out  std_logic; -- PLL-generated ioclk_vect clock buffered by BUFG, available if INSTANTIATE_PLL=TRUE. To be used to clock the ISERDES' ioclk_vect when they are spread in non-adjacent banks
		divclk_out_pll 	: out  std_logic; -- PLL-generated divclk clock buffered by BUFG, available if INSTANTIATE_PLL=TRUE. To be used to clock the ISERDES' divclk and FIFO input logic when they are spread in non-adjacent banks

		divclk_out_bufr : out  std_logic; -- 200-MHz divclk generated directly from the ADC clock using a BUFR. Can be fed to a MMCM/PLL in the clocking region covered by the BUFR (to generate channelizer clock). This clock stops when adcdaq_reset is asserted, and starts forwarding the ADC clock immediately when deasserted.
		divclk_out_bufg : out  std_logic; -- Buffered verison divclk_out_bufr, provided only if PROVIDE_BUFFERED_DIVCLK is TRUE.
		adc_clk_out_div2: out  std_logic :='0'; -- Logic line (not a clock) pulsing at half the local divclk frequency, to be used by the frequency counter. Init required for sims.

		-- External clocks

		ioclk_in : in  std_logic; -- ioclk_vect used by ISERDES if USE_EXT_DATA_CLK=TRUE. Otherwise uses the ioclk_vect generated directly from the ADC clock.
		divclk_in : in  std_logic; -- divclk used by ISERDES and the FIFO input logic if USE_EXT_DATA_CLK=TRUE. Otherwise uses the divclk derived directly from the ADC clock.

		-- Global synchronization lines

		adcdaq_reset : in  std_logic; -- Resets the ADCDAQ module asynchronously. Restart the word counters. To be released before the ADC SYNC is released so it count incoming words properly.

		-- Control interface (command and reply stream buses)

		s_axis_bsb_tdata  : in  std_logic_vector(7 downto 0);
		s_axis_bsb_tvalid : in  std_logic;
		s_axis_bsb_tlast  : in  std_logic;
		s_axis_bsb_tready : out std_logic;
		m_axis_bsb_tdata  : out std_logic_vector(7 downto 0);
		m_axis_bsb_tvalid : out std_logic;
		m_axis_bsb_tlast  : out std_logic;
		m_axis_bsb_tready : in  std_logic;
		bsb_clk           : in  std_logic;
		bsb_rst           : in  std_logic; --

		ref_clk: in std_logic; -- Clock used to sample the ADC CLK
		clk200: in  std_logic -- Clock for the IODELAYCTRL (when implemented)
		);
end adcdaq;

------------- ADCDAQ Implementation ---------------
-- Implements the ADC Data acquisition system
--

architecture Implementation of ADCDAQ is




attribute KEEP: string;
attribute EQUIVALENT_REGISTER_REMOVAL: string;
attribute DONT_TOUCH: string;
attribute ASYNC_REG : string;
attribute S: string;

constant WORDS_PER_FRAME: integer := SAMPLES_PER_FRAME / 4;
constant LOG2_WORDS_PER_FRAME : integer := integer_log2(WORDS_PER_FRAME);
-- Internal data buses

-- SERDES output (shuffled)
--signal SERDES_OUT_ALIGN: std_logic_vector(31 downto 0); -- Output of the serdes, realigned to skip invalid samples

-- Output data (deshuffled)
--signal A_OUT_RAW: std_logic_vector(31 downto 0); -- Output word (4 bytes, 4 sampels) in original ADC encoding (offset encoding)

signal output_word_ctr: unsigned(LOG2_WORDS_PER_FRAME-1 downto 0) :=(others=>'0');

signal pll_locked: std_logic;

signal idelayctrl_rdy, idelayctrl_present: std_logic;

signal idelayctrl_reset_all: std_logic;

signal adcdaq_reset_all: std_logic;
signal serdes_auto_reset: std_logic_vector(7 downto 0); -- SERDES automatically generated in sequence. Many SERDES resets signals are generated to ease routing delays when reaching the SERDES in various banks. We add one to be used for the readout logic.
signal pll_reset_all: std_logic;

attribute KEEP  of serdes_auto_reset:signal is "true";
attribute EQUIVALENT_REGISTER_REMOVAL of serdes_auto_reset: signal is "no";

signal serdes_sync_dly: std_logic_vector(5 downto 0):=(others=>'0');

signal capture2_word_ctr: unsigned(7 downto 0) :=(others=>'0');
signal capture2_period: unsigned(7 downto 0) :=(others=>'0');
signal capture2_word_number: unsigned(7 downto 0) :=(others=>'0');
signal capture2_pattern: std_logic_vector(31 downto 0);


signal fifo_overflow: std_logic;
signal fifo_overflow_sticky: std_logic;
signal fifo_underflow: std_logic;
signal fifo_underflow_sticky: std_logic;
signal fifo_data_valid: std_logic;
signal fifo_empty: std_logic;
signal fifo_empty_sticky: std_logic;
signal fifo_wr_data_count: std_logic_vector(9 downto 0);
signal fifo_rd_data_count: std_logic_vector(9 downto 0);
signal clear_fifo_flags: std_logic;

signal fifo_wr_en: std_logic;
signal fifo_rd_en: std_logic;
signal fifo_rst: std_logic;
signal fifo_prog_full: std_logic;
attribute ASYNC_REG of fifo_rst : signal is "true";

signal fifo_rst_ctr: unsigned(3 downto 0);
signal fifo_din: std_logic_vector(31 downto 0);
signal fifo_dout: std_logic_vector(31 downto 0);

signal drp_dout: std_logic_vector(15 downto 0);
signal drp_din: std_logic_vector(15 downto 0);
signal drp_addr: std_logic_vector(6 downto 0);
signal drp_drdy: std_logic;
signal drp_den: std_logic;
signal drp_dwe: std_logic;

--- Define Control word and its signals
signal control_bytes: slv8_array(0 to 14); -- default value set in the CMD_SLAVE
signal status_bytes: slv8_array(0 to 26) := (others=>(others=>'0')); -- default value set in the CMD_SLAVE

signal enable_ramp: std_logic;
signal serdes_soft_reset: std_logic;
signal idelayctrl_rst: std_logic;
signal data_iodelay_soft_reset: std_logic;
signal clk_iodelay_soft_reset: std_logic;
signal bufr_soft_reset: std_logic;
signal pll_soft_reset: std_logic;
signal adc_clk_sample: std_logic_vector(1 downto 0);
signal sample_delay: unsigned(11 downto 0);
signal word_delay: unsigned(9 downto 0);
signal word_delay_ctr: unsigned(9 downto 0);
signal ramp_err_ctr: unsigned(15 downto 0);
signal ramp_err: std_logic;
signal ramp_err_clear: std_logic;
signal ramp_err_clear_reg: std_logic; -- usd to resynchronize the signal -- apply ASYNC_REG attribute
attribute ASYNC_REG of ramp_err_clear_reg : signal is "true";
signal ramp_err_clear_dly: std_logic;
signal ramp_err_clear_pulse: std_logic;
signal ramp_bit_err_ctr: std_logic_vector(31 downto 0); -- Contains 8 x 4-bit counter
signal ramp_bit_err: std_logic_vector( 7 downto 0);
signal send_data_reg: std_logic;
signal data_ready_int: std_logic;
signal data_mask: std_logic_vector(7 downto 0);
signal force_data_ready: std_logic;

begin

	-- Check vector dimensions and value range for clocking/differential generics
	assert CLOCKING_REGION_MAP'length = 9
		report "adcdaq: CLOCKING_REGION_MAP must have length 9 (indices 0 to 8)" severity failure;
	assert IS_DIFFERENTIAL'length = 9
		report "adcdaq: IS_DIFFERENTIAL must have length 9 (indices 0 to 8)" severity failure;
	assert min(CLOCKING_REGION_MAP) >= -1 and max(CLOCKING_REGION_MAP) <= 2
		report "adcdaq: CLOCKING_REGION_MAP values must be between -1 and 2" severity failure;

-- ADCDAQ Memory Map
--
-- Memory Map
--
-- ------------------------------------------------------------------------------
-- |  Page   | Addr|Bit(s)|     Name             | Description                   |
-- |---------|-----|------|----------------------|-------------------------------|
-- | CONTROL | 0-7 | 4:0  | data_iodelay_value   | IODELAY tap delay values for data lines 0-7 (5 bits per line) |
-- |         |  8  | 4:0  | clk_iodelay_value    | IODELAY tap delay value for clock line (5 bits) |
-- |         |     | 7:5  | (unused)             |                               |
-- |         |  9  |   7  | pll_soft_reset       | Soft reset for PLL            |
-- |         |     |   6  | (unused)             |                               |
-- |         |     |   5  | clk_iodelay_soft_reset| Soft reset for clock IODELAY  |
-- |         |     |   4  | enable_ramp           | Enable ADC test ramp pattern |
-- |         |     |   3  | idelayctrl_rst        | Reset IODELAY controller     |
-- |         |     |   2  | bufr_soft_reset       | Soft reset for BUFR           |
-- |         |     |   1  | serdes_soft_reset     | Soft reset for SERDES         |
-- |         |     |   0  | data_iodelay_soft_reset| Soft reset for data IODELAY  |
-- |         | 10  |   7  | (unused)             |                               |
-- |         |     |   6  | force_data_ready      | Force data_ready signal high  |
-- |         |     |   5  | ramp_err_clear        | Clear ramp error counter     |
-- |         |     |   4  | clear_fifo_flags      | Clear FIFO overflow/underflow flags |
-- |         |     | 3:0  | sample_delay(11:8)   | Upper 4 bits of sample delay  |
-- |         | 11  | 7:0  | sample_delay(7:0)     | Lower 8 bits of sample delay  |
-- |         | 12  | 7:0  | capture2_period       | Period for pattern capture   |
-- |         | 13  | 7:0  | capture2_word_number  | Word number for pattern capture |
-- |         | 14  | 7:0  | data_mask             | Data mask for output         |
-- | STATUS  | 0-7 | 4:0  | data_iodelay_cntvalueout| IODELAY tap delay readback for data lines 0-7 |
-- |         |     | 7:5  | (unused)             |                               |
-- |         |  8  | 4:0  | clk_iodelay_cntvalueout| IODELAY tap delay readback for clock line |
-- |         |     | 7:5  | (unused)             |                               |
-- |         |  9  |   7  | (unused)             |                               |
-- |         |     |   6  | (unused)             |                               |
-- |         |     |   5  | (unused)             |                               |
-- |         |     |   4  | (unused)             |                               |
-- |         |     |   3  | pll_locked            | PLL lock status               |
-- |         |     |   2  | fifo_rst               | FIFO reset status             |
-- |         |     |   1  | idelayctrl_present     | IODELAY controller present    |
-- |         |     |   0  | idelayctrl_rdy        | IODELAY controller ready     |
-- |         | 10  |   7  | fifo_overflow         | FIFO overflow flag            |
-- |         |     |   6  | fifo_underflow        | FIFO underflow flag           |
-- |         |     |   5  | fifo_empty             | FIFO empty flag               |
-- |         |     |   4  | fifo_overflow_sticky  | FIFO overflow sticky flag     |
-- |         |     |   3  | fifo_underflow_sticky | FIFO underflow sticky flag    |
-- |         |     |   2  | fifo_empty_sticky      | FIFO empty sticky flag        |
-- |         |     | 1:0  | (unused)             |                               |
-- |         |11-12|15:0  | ramp_err_ctr          | Ramp error counter            |
-- |         | 13  |   7  | (unused)             |                               |
-- |         |     |   6  | (unused)             |                               |
-- |         |     |   5  | (unused)             |                               |
-- |         |     |   4  | (unused)             |                               |
-- |         |     |   3  | data_ready_int        | Internal data ready signal    |
-- |         |     |   2  | fifo_data_valid       | FIFO data valid flag          |
-- |         |     |   1  | fifo_rd_en            | FIFO read enable              |
-- |         |     |   0  | fifo_wr_en            | FIFO write enable              |
-- |         | 14  | 7:0  | (unused)             |                               |
-- |         | 15  | 7:0  | output_word_ctr       | Last 8 bits of output word counter |
-- |         |16-17|15:0  | (unused)             |                               |
-- |         | 18  | 7:2  | (unused)             |                               |
-- |         |     | 1:0  | adc_clk_sample        | ADC clock sample value       |
-- |         |19-22|31:0  | capture2_pattern      | Captured ADC test pattern    |
-- |         |23-26|31:0  | ramp_bit_err_ctr      | Ramp bit error counter (8 x 4-bit counters) |
-- ------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- Control interface
---------------------------------------------------------------------------------
-- control_bytes(0..7) are the delay values inputs to the IODELAY

-- CONTROL BYTE 9
pll_soft_reset          <= control_bytes(9)(7);
clk_iodelay_soft_reset  <= control_bytes(9)(5);
enable_ramp             <= control_bytes(9)(4);
idelayctrl_rst          <= control_bytes(9)(3);
bufr_soft_reset         <= control_bytes(9)(2);
serdes_soft_reset       <= control_bytes(9)(1);
data_iodelay_soft_reset <= control_bytes(9)(0);
-- CONTROL BYTE 10-11
force_data_ready        <= control_bytes(10)(6);
ramp_err_clear          <= control_bytes(10)(5);
clear_fifo_flags        <= control_bytes(10)(4);
sample_delay(11 downto 8) <= unsigned(control_bytes(10)(3 downto 0) );
sample_delay(7 downto 0)  <= unsigned(control_bytes(11)(7 downto 0) );
-- CONTROL BYTE 12
capture2_period         <= unsigned(control_bytes(12));
-- CONTROL BYTE 13
capture2_word_number    <= unsigned(control_bytes(13));
-- CONTROL BYTE 14
data_mask               <= control_bytes(14);


-- status_bytes(0..8) are the delay values inputs from the IODELAY
--status_bytes(9)(7)<=CAPTURE_DONE;
status_bytes(9)(3) <= pll_locked;
status_bytes(9)(2) <= fifo_rst;
status_bytes(9)(1) <= idelayctrl_present;
status_bytes(9)(0) <= idelayctrl_rdy;

status_bytes(10)(7) <= fifo_overflow;
status_bytes(10)(6) <= fifo_underflow;
status_bytes(10)(5) <= fifo_empty;
status_bytes(10)(4) <= fifo_overflow_sticky;
status_bytes(10)(3) <= fifo_underflow_sticky;
status_bytes(10)(2) <= fifo_empty_sticky;

status_bytes(11 to 12) <= to_slv8_array(ramp_err_ctr);

-- STATUS BYTES 13-14: Not used
status_bytes(13)(0) <= fifo_wr_en;
status_bytes(13)(1) <= fifo_rd_en;
status_bytes(13)(2) <= fifo_data_valid;
status_bytes(13)(3) <= data_ready_int;

status_bytes(15)<=to_slv(lsb(output_word_ctr, 8));

-- STATUS BYTES 16-17: Not used

-- status_bytes(16) <= lsb(fifo_wr_data_count, 8);
-- status_bytes(17) <= lsb(fifo_rd_data_count, 8);

status_bytes(18)(1 downto 0) <= adc_clk_sample;

status_bytes(19) <= capture2_pattern(31 downto 24);
status_bytes(20) <= capture2_pattern(23 downto 16);
status_bytes(21) <= capture2_pattern(15 downto 8);
status_bytes(22) <= capture2_pattern(7 downto 0);

status_bytes(23 to 26) <= to_slv8_array(ramp_bit_err_ctr);

-- IODELAY and IODELAYCTRL Resets
idelayctrl_reset_all <= bsb_rst or idelayctrl_rst; -- resets the IODELAY Controller
adcdaq_reset_all     <= bsb_rst or adcdaq_reset or serdes_soft_reset or bufr_soft_reset; -- Reset the SERDES on 1) Global chip reset, 2) Software reset flag or 3) Global external SERDES reset line
pll_reset_all        <= bsb_rst or pll_soft_reset or bufr_soft_reset or adcdaq_reset;

bsb_regs0: entity work.bsb_regs
	GENERIC MAP (
		USE_RAM_DOUT_RDY => TRUE, -- need to wait for the RDY signal on RAM read accesses
		RAM_DATA_WIDTH   => 16,
		RAM_ADDR_WIDTH   => 7, --  DRP Address bus width is 7 bits

		NUMBER_OF_CONTROL_BYTES => control_bytes'length(1), -- Length of array in the first dimension: number of bytes
		NUMBER_OF_STATUS_BYTES  => status_bytes'length(1),
		DEFAULT_CONTROL_BYTES   => X"00_00_00_00_00_00_00_00_00_00_00_02_40_00_FF"
	)

	PORT MAP(

		-- Control interface (command and reply stream buses)
		s_axis_bsb_tdata => s_axis_bsb_tdata,
		s_axis_bsb_tvalid => s_axis_bsb_tvalid,
		s_axis_bsb_tlast => s_axis_bsb_tlast,
		s_axis_bsb_tready => s_axis_bsb_tready,
		m_axis_bsb_tdata => m_axis_bsb_tdata,
		m_axis_bsb_tvalid => m_axis_bsb_tvalid,
		m_axis_bsb_tlast => m_axis_bsb_tlast,
		m_axis_bsb_tready => m_axis_bsb_tready,
		bsb_clk => bsb_clk,
		bsb_rst => bsb_rst,

		control_bytes => control_bytes,
		status_bytes  => status_bytes,

		RAM_DIN      => drp_din,
		RAM_DOUT     => drp_dout,
		RAM_DOUT_RDY => drp_drdy,
		RAM_WR_EN    => drp_dwe,
		RAM_EN       => drp_den,
		RAM_ADDR     => drp_addr
	);


impl_gen: if IMPLEMENT_ADCDAQ generate
	-- Determine how many BUFMR we need based on the
	-- BUFR+MAP indices. We need a BUFMR in every region where data lines come in,
	-- but we also need one in the clock region where the clock enters the chip to
	-- clock the clock IODELAY and clock-related logic. Hence we look into CLOCKING_REGION_MAP(0 to 8).
	constant BUFR_INDEX_MIN: integer := MIN(CLOCKING_REGION_MAP);
	constant BUFR_INDEX_MAX: integer := MAX(CLOCKING_REGION_MAP);
	constant NUMBER_OF_BUFR: integer := BUFR_INDEX_MAX-BUFR_INDEX_MIN+1;

	-- Determines how many BUFIO we need.
	-- We need BUFIOs only in the clock regions where there is data (only the SERDES needs them)
	-- Hence we check only CLOCKING_REGION_MAP(0 to 7)
	constant BUFIO_INDEX_MIN: integer := MIN(CLOCKING_REGION_MAP(0 to 7));
	constant BUFIO_INDEX_MAX: integer := MAX(CLOCKING_REGION_MAP(0 to 7));
	constant NUMBER_OF_BUFIO: integer := BUFIO_INDEX_MAX-BUFIO_INDEX_MIN+1;

	-- Determines whether we need to instantiate a BUFMR at all.
	constant INSTANTIATE_BUFMR: BOOLEAN := (BUFR_INDEX_MIN >= 0) or (BUFIO_INDEX_MIN >= 0);

	-- Clock
	signal clka: std_logic; -- ADC 400 MHz clock after differential receiver
	signal clka_dly: std_logic; -- ADC 400 MHz clock after delay and before BUFMR
	signal clka_bufmr: std_logic; -- ADC 400 MHz clock after BUFMR (if applicable)

	-- Local (ADC-derived) clocks
	signal ioclk_local_vect: std_logic_vector(0 to NUMBER_OF_BUFIO-1); -- Buffered Bit clock after BUFIO
	signal divclk_local_vect: std_logic_vector(0 to NUMBER_OF_BUFR-1); -- Word clock (internal) from each BUFMR
	signal divclk_local_vect_d: std_logic_vector(0 to NUMBER_OF_BUFR-1); -- Word clock (output of BUFR)

	-- Local (ADC-derived) or remote (PLL-derived) clocks, selected by USE_EXT_DATA_CLK
	signal ioclk_vect: std_logic_vector(0 to NUMBER_OF_BUFIO-1); -- Buffered Bit clock after BUFIO
	signal divclk_vect: std_logic_vector(0 to NUMBER_OF_BUFR-1); -- Word clock (local or external) to be used by IDELAY and ISERDES

	-- signal ioclk180: std_logic_vector(0 to NUMBER_OF_BUFIO-1); -- inverted bit clock after BUFIO
	-- signal divclk: std_logic; -- Word clock (local or external) used for signal processing
	-- signal divclk_local: std_logic; -- Word clock (internal) used for fabric

	signal serdes_out: std_logic_vector(31 downto 0); -- Output of the serdes
	signal serdes_out_dly: std_logic_vector(31 downto 0); -- Output of the serdes delayed one word
	signal word_ctr: unsigned(14 downto 0) := (others => '0'); -- MCMM guarantees lock un 100 us (20000 divclk cycles). We set a 15 bit counter (32768 counts)
	signal adc_clk_valid: std_logic;
	signal clk_iodelay_reset: std_logic;
	signal clk_iodelay_clk: std_logic;
	signal clk_iodelay_load: std_logic;

	-- signal DIVCLK_BUFR  : std_logic; -- Word clock - bypass PLL
	-- signal adc_clk_out_div2_int: std_logic := '0'; -- Init required

	attribute S of serdes_out : signal is "yes"; -- Make sure that no logic (particularly the BUFIO2, ISERDES, IDELAY2) is trimmed out by ensuring that the output word is "SAVEd"
	attribute DONT_TOUCH of divclk_local_vect_d: signal is "yes"; -- preserve clock net name to facilitate timing constraining and analysis
begin

---------------------------------------------------------------------------------------
----- CLOCK signal generation
-- Generates the bit and word clock
-- The technique varies whether a PLL is used or not (The PLL is used to generate the word clock when some input lines are in regions that cannot be reached by a simple BUFR).
---------------------------------------------------------------------------------------
gen_clk_ibuf: if IS_DIFFERENTIAL(8) generate
	ibufgds0 : IBUFGDS -- Instantiate a differential (LVDS) input pad pair
		generic map(
			DIFF_TERM => TRUE
		)
		port map (
			I  => adc_clk_h_p,
			IB => adc_clk_h_n,
			O  => clka
		);
else generate
	clka <= adc_clk_h_p;
end generate;



-- Synchronize the IDELAY control signals to their clock
clk_iodelay_clk <= divclk_local_vect_d(CLOCKING_REGION_MAP(8)-BUFR_INDEX_MIN); -- clock to be used by the IDELAY
clk_iodelay_reset_cdc0: xpm_cdc_single
	generic map (
		SRC_INPUT_REG => 0
	)
	port map (
		src_clk  => '0',
		src_in   => bsb_rst, -- Resets the IODELAY for the ADC clock line
		dest_clk => clk_iodelay_clk,
		dest_out => clk_iodelay_reset
	);

clk_iodelay_load_cdc0: xpm_cdc_single
	port map (
		src_clk  => bsb_clk,
		src_in   => clk_iodelay_soft_reset, -- Load IODELAY for the ADC clock line
		dest_clk => clk_iodelay_clk,
		dest_out => clk_iodelay_load
	);

clkdly0: IDELAYE2 -- For 7-series
	generic map (
		CINVCTRL_SEL => "FALSE", -- Dynamically inverts the Clock (C) polarity.
		DELAY_SRC => "IDATAIN", -- Specifies the source to the IODELAY component.
		HIGH_PERFORMANCE_MODE => "TRUE", -- When TRUE, this attribute reduces the output jitter.
		IDELAY_TYPE => "VAR_LOAD", -- Specifies a fixed, variable or default (eliminate hold time) input delay.
		PIPE_SEL => "FALSE", -- Select pipelined mode, FALSE, TRUE
		REFCLK_FREQUENCY => 200.0, -- When using an associated IDELAYCTRL, specifies the input reference frequency to the component.
		SIGNAL_PATTERN => "CLOCK" -- Used by the delay calculator to determine different propagation delays through the IODELAY block based on the setting. DATA will be the addition of per tap delay and per tap jitter. No jitter is introduced for clock-like signals.
	)
	port map (
		-- Inputs
		IDATAIN     => clka, -- 1-bit Data input to device from the I/O (connect directly to port, I/O Buffer). When IDATAIN is used, DATAIN must be tied to a logic zero (ground).
		DATAIN      => '0', -- 1-bit Data input for the internal datapath delay. When DATAIN is used, IDATAIN and ODATAIN must be tied to a logic zero (ground).
		-- Delayed output
		DATAOUT     => clka_dly, -- 1-bit Delayed data output from input port (connect to input datapath logic)

		-- Delay control
		CINVCTRL    => '0', -- 1-bit Dynamically inverts the Clock (C) polarity
		LDPIPEEN    => '0', -- 1-bit input: Enable PIPELINE register to load data input
		CNTVALUEOUT => status_bytes(8)(4 downto 0), -- 5-bit Counter value going to fabric for monitoring purpose
		CNTVALUEIN  => control_bytes(8)(4 downto 0), -- 5-bit Counter value from fabric for loadable counter application
		C           => clk_iodelay_clk, -- 1-bit Clock input (Must be connected for variable mode)
		INC         => '0', -- 1-bit Increment / Decrement tap delay
		CE          => '0', -- 1-bit Active high enable increment/decrement function
		LD          => clk_iodelay_load,
		REGRST      => clk_iodelay_reset -- 1-bit Active high, synchronous reset, resets delay chain to IDELAY_VALUE/
	);


status_bytes(8)(7 downto 5)<=(others=>'0');

-- Instantiate BUFMRs if needed for a 7-series FPGA
-- This is needed to allow the clock signal to reach the BUFIO and BUFRs in adjacent clocking regions.
bufmr_gen: if INSTANTIATE_BUFMR generate
	bufmr0 : BUFMR
		port map (
		I => clka_dly, -- 1-bit input: Clock input (Connect to IBUFG)
		O => clka_bufmr -- 1-bit output: Clock output (connect to BUFIOs/BUFRs)
		);
else generate
	clka_bufmr <= clka_dly;
end generate;


-- Instantiate BUFR
-- The BUFR clocks the local logic and I/O ressources and divide the incoming clock by two.
-- If the external clocks (from another PLL) is used for the data acquisition, it is used only for clocking the local logic and determine when a sufficient number of bytes have passed to activate data storage.
-- Otherwise, the BUFR drives the output clock of the SERDES and the input of the FIFO.
-- Very impotaantly, this divider is resettable so we know its phase relating to the data clock.
bufr_gen: for i in 0 to NUMBER_OF_BUFR-1 generate
	bufr0 : BUFR
		generic map (
			BUFR_DIVIDE => "2", -- use 2 since we are in DDR ("BYPASS", "1", "2", "3", "4", "5", "6", "7", "8")
			SIM_DEVICE => "7SERIES"
			)
		port map (
			I   => clka_bufmr, -- Clock buffer input
			O   => divclk_local_vect_d(i), -- Clock buffer output. We use a temporary variable to create a delay on divclk_local for simulations (see assignment below)
			CE  => '1', -- Clock enable input
			CLR => adcdaq_reset_all -- Clock buffer reset input
		);
end generate;

divclk_local_vect <= divclk_local_vect_d after 100 ps; -- to make simulations more realistic
-- divclk_local <= divclk_local_vect(0); -- local clock used for logic
divclk_out_bufr <= divclk_local_vect(0); -- Make the divclk BUFR output acessible to the outside


-- Clock sampler
-- samples the ADC clock using the 10 MHz reference clock.
-- Since the reference clock can be delayed (See REFCLK module), and the ADC clock is synchronous to this reference clock,
-- we can scan the reference clock delay and acquire the ADC clock waveform.
-- Phase jumps caused by the timing of the ADC SYNC signal  vs the ADC input clock can be thus measured, and the timing can be optimized.
clk_iddr0:IDDR
	generic map(
		DDR_CLK_EDGE=>"SAME_EDGE_PIPELINED"--"OPPOSITE_EDGE","SAME_EDGE"--or "SAME_EDGE_PIPELINED"
		)
	port map(
		Q1 => adc_clk_sample(0),--1-bit output for positive edge of clock
		Q2 => adc_clk_sample(1),--1-bit output for negative edge of clock
		C  => ref_clk,--1-bit clock input
		CE => '1',--1-bit clock enable input
		D  => clka_dly--1-bit DDR data input
	);

divclk_bufg_gen: if PROVIDE_BUFFERED_DIVCLK generate
	divclk_bufg0 : BUFG
		port map (
			I => divclk_local_vect(0), -- Clock buffer input
			O => divclk_out_bufg -- Clock buffer output
		);
else generate
	divclk_out_bufg <= '0'; -- Clock buffer output
end generate;


pll_gen: if INSTANTIATE_PLL=TRUE generate
	signal clk_fb_bufg_out: std_logic;
	signal clk_fb_bufg_in: std_logic;
	-- signal ADC_CLK_OUT_PLL_NOBUF: std_logic; -- PLL-generated clock before BUFG buffering
	signal ioclk_out_pll_nobuf: std_logic; -- PLL-generated clock before BUFG buffering
	signal divclk_out_pll_nobuf: std_logic; -- PLL-generated clock before BUFG buffering

	attribute DONT_TOUCH of ioclk_out_pll_nobuf: signal is "yes"; -- preserve clock net name to facilitate timing constraining and analysis
	attribute DONT_TOUCH of divclk_out_pll_nobuf: signal is "yes"; -- preserve clock net name to facilitate timing constraining and analysis
	--attribute DONT_TOUCH of ADC_CLK_OUT_PLL_NOBUF: signal is "yes"; -- preserve clock net name to facilitate timing constraining and analysis
begin
	-- Implement the PLL that will generate the global bit and global word clock from the ADC clock
	-- ** WARNING: Clocking Wizard 3.6 (coming winth ISE 14.2) does not work with Virtex 6. Simulation shows no output. Xilinx says to use 3.5 instead.
	------------------------------------------------------------------------------
	-- ADC PLL -- Will be instantiated and connected if INSTANTIATE_PLL=TRUE
	------------------------------------------------------------------------------
	-- User entered comments
	------------------------------------------------------------------------------
	-- None
	--
	------------------------------------------------------------------------------
	-- Output     Output      Phase    Duty Cycle   Pk-to-Pk     Phase
	-- Clock     Freq (MHz)  (degrees)    (%)     Jitter (ps)  Error (ps)
	------------------------------------------------------------------------------
	-- CLK_OUT1   425.080      0.000      50.0      104.676    109.111
	-- CLK_OUT2   212.540      0.000      50.0      119.334    109.111
	-- CLK_OUT3   212.540      0.000      50.0      119.334    109.111
	--
	------------------------------------------------------------------------------
	-- Input Clock   Input Freq (MHz)   Input Jitter (UI)
	------------------------------------------------------------------------------
	-- primary           212.5            0.010
	pll0 : MMCME2_ADV
	generic map (
		BANDWIDTH            => "HIGH",
		CLKOUT4_CASCADE      => FALSE,
		COMPENSATION         => "ZHOLD",
		STARTUP_WAIT         => FALSE,
		DIVCLK_DIVIDE        => 1,
		CLKFBOUT_MULT_F      => 5.000,
		CLKFBOUT_PHASE       => 0.000,
		CLKFBOUT_USE_FINE_PS => FALSE,
		CLKOUT0_DIVIDE_F     => 2.500,
		CLKOUT0_PHASE        => 0.000,
		CLKOUT0_DUTY_CYCLE   => 0.500,
		CLKOUT0_USE_FINE_PS  => FALSE,
		CLKOUT1_DIVIDE       => 5,
		CLKOUT1_PHASE        => 0.000,
		CLKOUT1_DUTY_CYCLE   => 0.500,
		CLKOUT1_USE_FINE_PS  => FALSE,
		CLKIN1_PERIOD        => 4.705)
	port map (
		CLKFBOUT            => clk_fb_bufg_in,
		CLKOUT0             => ioclk_out_pll_nobuf,
		CLKOUT1             => divclk_out_pll_nobuf,
		-- Input clock control
		CLKFBIN             => clk_fb_bufg_out,
		CLKIN1              => divclk_local_vect(0),
		CLKIN2              => '0',
		-- Tied to always select the primary input clock
		CLKINSEL            => '1',
		-- Ports for dynamic reconfiguration
		DADDR               => drp_addr,
		DCLK                => bsb_clk,
		DEN                 => drp_den,
		DI                  => drp_din,
		DO                  => drp_dout,
		DRDY                => drp_drdy,
		DWE                 => drp_dwe,
		-- Ports for dynamic phase shift
		PSCLK               => '0',
		PSEN                => '0',
		PSINCDEC            => '0',
		PSDONE              => open,
		-- Other control and status signals
		LOCKED              => pll_locked,
		CLKINSTOPPED        => open,
		CLKFBSTOPPED        => open,
		PWRDWN              => '0',
		RST                 => pll_reset_all
		);


	-- Feedback buffer, to cancel out the delays from the PLL to the loads
	io_bufg0 : BUFG
		port map (
			I => ioclk_out_pll_nobuf, -- Clock buffer input
			O => ioclk_out_pll -- Clock buffer output
		);

	div_bufg0 : BUFG
		port map (
			I => divclk_out_pll_nobuf, -- Clock buffer input
			O => divclk_out_pll -- Clock buffer output
		);
	fb_bufg0 : BUFG
		port map (
			I => clk_fb_bufg_in, -- Clock buffer input
			O => clk_fb_bufg_out -- Clock buffer output
		);

else generate -- If the PLL is not instantiated, tie the related output signals to fixed values
	ioclk_out_pll <= '0';
	divclk_out_pll <= '0';
	drp_drdy <= drp_dwe and drp_den;
	drp_dout <= X"1234";
	pll_locked <= '1'; -- not used
end generate;


extclk_gen: if USE_EXT_DATA_CLK generate
	---------------------------------------------------------
	-- Clocks are provided by an external PLL.
	---------------------------------------------------------
	-- ioclk_vect comes from the external PLL
	-- divclk comes from the external PLL
	ioclk_vect <= (others=> ioclk_in);
	divclk_vect <= (others=>divclk_in);

else generate
	---------------------------------------------------------
	-- Use local clocks
	---------------------------------------------------------
	-- ioclk_vect comes from BUFIO connected to clka_bufmr
	-- divclk comes from the BUFR

	bufio_gen: for i in 0 to NUMBER_OF_BUFIO-1 generate
		bufio0 : BUFIO
			port map (
				I => clka_bufmr, -- Buffer input
				O => ioclk_local_vect(i) -- Buffer output
			);
		-- ioclk180(i)<=not ioclk_vect(i);
	end generate;
	ioclk_vect <= ioclk_local_vect;
	divclk_vect <= divclk_local_vect;
end generate;



---------------------------------------------------------------------------------------
--   IDELAYCTRL
---------------------------------------------------------------------------------------

-- Instantiate a IDELAYCTRL if requested. There must be one and only one of these instantiated in each clocking region
dlyctrl_gen: if INSTANTIATE_IDELAYCTRL generate
	idelayctrl0 : IDELAYCTRL
		port map (
			REFCLK => clk200, -- 1-bit reference clock input
			RST => idelayctrl_reset_all, -- 1-bit reset input
			RDY => idelayctrl_rdy -- 1-bit output indicates validity of the REFCLK
		);
	idelayctrl_present <= '1';
else generate
	idelayctrl_present <= '0';
	idelayctrl_rdy <= '1';
end generate;

---------------------------------------------------------------------------------------
--   DATA
---------------------------------------------------------------------------------------

bit_gen: for i in 0 to 7 generate
	signal ad_bit: std_logic;
	signal ad_dly_bit: std_logic;
	signal serdes_clk_bit: std_logic;
	signal serdes_clkdiv_bit: std_logic;
	signal data_iodelay_reset_bit: std_logic;
	signal data_iodelay_load_bit: std_logic;
begin

	gen_data_ibuf: if IS_DIFFERENTIAL(i) generate
	   ibufds0 : IBUFDS -- Instantiate a differential (LVDS) input pad & buffer
			generic map(
				DIFF_TERM => TRUE -- Make sure the 100 ohm termination is enabled
				)
		  port map (
				I=>ADC_DATA_H_P(i),
				IB=>adc_data_h_n(i),
				O=>ad_bit
				);
	else generate
			ad_bit <= ADC_DATA_H_P(i);
	end generate;
	

	-- Select bit and word clocks from the source in the appropriate clock region

	serdes_clk_bit <= ioclk_vect(CLOCKING_REGION_MAP(i)-BUFIO_INDEX_MIN); -- 1-bit Clock input
	serdes_clkdiv_bit <= divclk_vect(CLOCKING_REGION_MAP(i)-BUFR_INDEX_MIN); -- 1-bit Divided clock input

	-- Resynchronize the BSB delay control signals to the word clock that drived the delay line
	data_iodelay_reset_cdc0: xpm_cdc_single
		port map (
			src_clk  => bsb_clk,
			src_in   => bsb_rst, -- Resets the IODELAY for the ADC clock line
			dest_clk => serdes_clkdiv_bit,
			dest_out => data_iodelay_reset_bit
		);

	data_iodelay_load_cdc0: xpm_cdc_single
		port map (
			src_clk  => bsb_clk,
			src_in   => data_iodelay_soft_reset, -- Load IODELAY for the ADC clock line
			dest_clk => serdes_clkdiv_bit,
			dest_out => data_iodelay_load_bit
		);


	dly0: IDELAYE2 -- For 7-series
		generic map (
			CINVCTRL_SEL => "FALSE", -- Dynamically inverts the Clock (C) polarity.
			DELAY_SRC => "IDATAIN", -- Specifies the source to the IODELAY component.
			HIGH_PERFORMANCE_MODE => "TRUE", -- When TRUE, this attribute reduces the output jitter.
			IDELAY_TYPE => "VAR_LOAD", -- Specifies a fixed, variable or default (eliminate hold time) input delay.
			PIPE_SEL => "FALSE", -- Select pipelined mode, FALSE, TRUE
			REFCLK_FREQUENCY => 200.0, -- When using an associated IDELAYCTRL, specifies the input reference frequency to the component.
			SIGNAL_PATTERN => "DATA" -- Used by the delay calculator to determine different propagation delays through the IODELAY block based on the setting. DATA will be the addition of per tap delay and per tap jitter. No jitter is introduced for clock-like signals.
		)
		port map (
			-- Inputs
			IDATAIN     => ad_bit, -- 1-bit Data input to device from the I/O (connect directly to port, I/O Buffer). When IDATAIN is used, DATAIN must be tied to a logic zero (ground).
			DATAIN      => '0', -- 1-bit Data input for the internal datapath delay. When DATAIN is used, IDATAIN and ODATAIN must be tied to a logic zero (ground).
			-- Delayed output
			DATAOUT     => ad_dly_bit, -- 1-bit Delayed data output from input port (connect to input datapath logic)
			-- Delay control
			CNTVALUEOUT => status_bytes(i)(4 downto 0), -- 5-bit Counter value going to fabric for monitoring purpose
			CNTVALUEIN  => control_bytes(i)(4 downto 0), -- 5-bit Counter value from fabric for loadable counter application
			CINVCTRL    => '0', -- 1-bit Dynamically inverts the Clock (C) polarity
			C           => serdes_clkdiv_bit, -- 1-bit Clock input (Must be connected for variable mode)
			INC         => '0', -- 1-bit Increment / Decrement tap delay
			CE          => '0', -- 1-bit Active high enable increment/decrement function
			LD          => data_iodelay_load_bit,
			LDPIPEEN    => '0', -- 1-bit input: Enable PIPELINE register to load data input
			REGRST      => data_iodelay_reset_bit -- 1-bit Active high, synchronous reset, resets delay chain to IDELAY_VALUE/
		);

	

	status_bytes(i)(7 downto 5)<=(others=>'0'); -- do not leave these status bits undriven
	iserdes0 : ISERDESE1
		generic map (
			DATA_RATE => "DDR", -- SDR or DDR
			DATA_WIDTH => 4, -- Parallel data width (2-8, 10)
			DYN_CLKDIV_INV_EN => FALSE, -- Must not use clock inversion with NETWORKING mode. Creates weird delays.
			DYN_CLK_INV_EN => FALSE, -- Must not use clock inversion with NETWORKING mode. Creates weird delays.
			INIT_Q1 => '1', 		-- INIT_Q1 - INIT_Q4: Initial value on the Q outputs (0/1)
			INIT_Q2 => '1',
			INIT_Q3 => '1',
			INIT_Q4 => '1',
			INTERFACE_TYPE => "NETWORKING", -- MEMORY, MEMORY_DDR3, MEMORY_QDR, NETWORKING, or OVERSAMPLE
			IOBDELAY => "IFD", -- NONE, IBUF, IFD, BOTH (IFD because We use only the DDLY input and O is associated to the unused D input. With BOTH, the DRC complains we should connect the O output)
			NUM_CE => 1, -- Number of clock enables (1 or 2)
			OFB_USED => FALSE, -- Select OFB path (TRUE/FALSE)
			SERDES_MODE => "MASTER", -- MASTER or SLAVE
			-- SRVAL_Q1 - SRVAL_Q4: Q output values when SR is used (0/1)
			SRVAL_Q1 => '0',
			SRVAL_Q2 => '0',
			SRVAL_Q3 => '0',
			SRVAL_Q4 => '0'
		)
		port map (

			-- Data Inputs
			D => '0', -- 1-bit Data input
			DDLY => ad_dly_bit, -- 1-bit Serial input data from IODELAY

			-- Deserialized outputs Q1 - Q6: 1-bit (each) Data outputs
			Q1 => serdes_out(0+i),
			Q2 => serdes_out(8+i),
			Q3 => serdes_out(16+i),
			Q4 => serdes_out(24+i), -- First bit received for DATA_WIDTH=4
			Q5 => open,
			Q6 => open,
			O => open, -- 1-bit Combinatorial output

			-- SHIFTIN1/SHIFTIN2: 1-bit (each) Cascade inputs for data width expansion
			SHIFTIN1 => '0',
			SHIFTIN2 => '0',
			-- SHIFTOUT1/SHIFTOUT2: 1-bit (each) Cascade outputs for data width expansion
			SHIFTOUT1 => open,
			SHIFTOUT2 => open,

			-- Clocks and clock management
			CLK => serdes_clk_bit, -- 1-bit Clock input
			CLKB => not serdes_clk_bit, -- 1-bit Secondary clock input
			CLKDIV => serdes_clkdiv_bit, -- 1-bit Divided clock input

			OCLK => '0', -- 1-bit High speed output clock input
			DYNCLKDIVSEL => '0', -- 1-bit Dynamic CLKDIV inversion input
			DYNCLKSEL => '0', -- 1-bit Dynamic CLK/CLKB inversion input
			OFB => '0', -- 1-bit Feedback path input

			BITSLIP => '0', -- 1-bit The BITSLIP pin performs a Bitslip operation synchronous to CLKDIV
			-- when asserted (active High). Subsequently, the data seen on the Q1 to Q6
			-- output ports will shift, as in a barrel-shifter operation, one position
			-- every time Bitslip is invoked (DDR operation is different from SDR).

			CE1 => '1',		-- CE1, CE2: 1-bit (each) Data register clock enable inputs
			CE2 => '1',
			RST => serdes_auto_reset(i) -- 1-bit Active high asynchronous reset input. IMPORTANT NOTE: The reset will work only if there is an input clock!
		);

	serdes_rst_proc: process(all)
		begin
			if adcdaq_reset_all then
				serdes_auto_reset(i) <= '1'; -- Needed
			elsif rising_edge(serdes_clkdiv_bit) then
				if adc_clk_valid then
					serdes_auto_reset(i) <= '0';
				end if;
			end if; -- RST/CLK
		end process;
	end generate;



---------------------------------------------------------------------------------
-- Word clock divided by 2
---------------------------------------------------------------------------------
-- Generates a signal pulsing at half the adc_clk (word) frequency.
-- Used by the frequency counter to measure frequency of the clock.
-- Since this is a signal (and not a clock using dedicated lines), it is easy to route to and use by the frequency counter because
--  1) the divided signal not not require a clock buffer, which are very limited
--  2) The frequency is slow enough that timing is not an issue
clkdiv2: process(all) begin
	if rising_edge(divclk_vect(0)) then
			adc_clk_out_div2 <= not adc_clk_out_div2;
		end if; -- RST/CLK
	end process;
-- adc_clk_out_div2 <= adc_clk_out_div2_int;

---------------------------------------------------------------------------------
----- Clock valid process
---------------------------------------------------------------------------------
-- Waits a number or local divclk cycles before setting adc_clk_valid and start capturing data.
-- If USE_EXT_DATA_CLK = TRUE, we wait longer to make sure that the MMCMs had time to finish their lock.
-- Otherwise we wait just a single frame
-- We shorten the wait with CLK_VALID_OFFSET to account for the time it takes to take the SERDES out of reset.
-- We have to use the local (ADC-Derived) divclk because divclk_vect might come from the PLL and will not be clocking until locked.
-- Every ADCs will discard the same number of samples on their local clock, allowing synchronization to be maintained independent of the MMCM lock delay.
-- NOTE: The adc_clk_valid is set ont the divclk_local_vect(0) clock, but it is used by processes clocked on divclk (which is either from divclk_local or from the PLL). We assume the tools are smart enough to know the delays between the two and ensure proper timing.
clkvalid_proc: process(all) begin
	if adcdaq_reset_all then
			word_ctr <= (others=>'0');
			adc_clk_valid <= '0';
	elsif rising_edge(divclk_local_vect(0)) then
		word_ctr <= word_ctr + 1;
		if (SIM=FALSE and ((USE_EXT_DATA_CLK=TRUE and SIGNED(word_ctr)=CLK_VALID_OFFSET) or (USE_EXT_DATA_CLK=FALSE and word_ctr=512+CLK_VALID_OFFSET))) or (SIM=TRUE and word_ctr=64+CLK_VALID_OFFSET) then -- In SIM mode, just wait 64 words (256 samples). We substract 2 to let time for the sample alignment process to accumulate an extra word for alignment.
			adc_clk_valid <= '1' after 10 ps; -- delay to make sure that simulation work. Otherwise AUTO_SERDES_RESET rise at same time as CLK_VALID
		end if;
	end if; -- RST/CLK
end process;


---------------------------------------------------------------------------------
-- Reset process (overall process)
---------------------------------------------------------------------------------
-- Uses the local divclk, which is always obtained directly fron a BUFR (is not dependent on PLL locking delay if one is used)
-- Upon reset
--  a) reset the FIFO
--  b) disable FIFO writes
--  c) resets the SERDES
--  d) clears the word counter
-- After N divclk_local_vect(0) clocks, release ISERDES reset and stars writing incomung words in the FIFO

---------------------------------------------------------------------------------
------- FIFO Reset process ------
---------------------------------------------------------------------------------
-- Resets the data FIFO in a way consistent with the FIFO requiremenmts
-- The fifo_rst line is a delayed version of the adcdaq_reset_all.
-- Upon the reset event, the fifo_wr_en is set immediately to zero.
-- We need to RESEt the fifo a few clocks later to make sure that the change in WR_EN is registered.
-- When adcdaq_reset_all is released, the FIFO is released a few clocks later.
-- We will not miss any data because the FIFO  data writes will not start until a large number of words have passed in otder to allow time for the PLL to lock.
-- By the time the fifo_wr_en is set, the fifo_rst is already cleared.
--fifo_rst_proc: process(divclk, RST)
--		begin
--			-- generate the fifo_rst, which is a delayed version of the adcdaq_reset_all.
--			if (RST='1') then -- Resets only on global reset
--				serdes_sync_dly<=(others=>'0');
--			elsif rising_edge(divclk) then
--				-- Delay the SERDES_SYNC signal to reset the FIFO only after a few cycles with fifo_wr_en=0
--				serdes_sync_dly<=(serdes_sync_dly(4 downto 0) &  adcdaq_reset_all);
--				fifo_rst<=serdes_sync_dly(5);
--			end if;
--		end process;
-- Ensures that the FIFO RST is held active for at least 1 WR clock, + 3 WR clocks to complete the reset process
-- But we release RST on the read clock
-- We now use a built-in FIFO. The reset controld the PRE input of a register clocked on the wr clock.
-- And the core generator includes logic to stretch the pulse.
fifo_rst_proc: process(all)	begin
	-- generate the fifo_rst, which is a delayed version of the adcdaq_reset_all.
	if adcdaq_reset_all then -- Resets only on global reset
		fifo_rst_ctr <= (others=>'0');
		fifo_rst <= '1';
	elsif rising_edge(divclk_vect(0)) then
		fifo_rst_ctr <= fifo_rst_ctr + 1;
		if signed(fifo_rst_ctr) = -1 then
			fifo_rst <= '0';
		end if;
	end if;
end process;

-- fifo_rst <= fifo_rst_int; -- for the built-in FIFO, the reset circuitry is in the divclk clock domain

-- -- Ensures that the FIFO RESET is released on the RD clock
-- fifo_rst_proc2: process(adc_clk, adcdaq_reset_all)
-- 		begin
-- 			-- generate the fifo_rst, which is a delayed version of the adcdaq_reset_all.
-- 			if (adcdaq_reset_all='1') then -- Resets only on global reset
-- 				fifo_rst <= '1';
-- 			elsif rising_edge(adc_clk) then
-- 				fifo_rst <= fifo_rst_int; -- clock domain crossing: fifo_rst_int is in the divclk clock domain
-- 			end if;
-- 		end process;


---------------------------------------------------------------------------------
-------- FIFO Write process -------
---------------------------------------------------------------------------------
-- Determines when to start writing the SERDES output data in the FIFO. Also handles the SERDES automatic RESET.
-- When a adcdaq_reset event occur, all writes to the FIFO are stopped and the SERDES are put into reset.
-- When the reset event is released, we wait for divclk to return.
-- On the first divclk occuring with adc_clk_valid='1, we clear the SERDES reset and start counting words to account for the propagation delays in the SERDES and tis process logic.
-- When we reach a certain count we start storing the data into the FIFO.
-- In order to delay the data with a byte granularity, we delay and realign the SERDES output word based on the last 2 bits of the delay.
fifo_wr_proc: process(all) begin
		if adcdaq_reset_all then
			fifo_wr_en <= '0';
			word_delay_ctr <= (others=>'0');
			fifo_overflow_sticky <= '0';
			serdes_out_dly <= (others=>'0'); -- prevent inferring logic to hold value during reset (using CE pins or otherwise)
			fifo_din <= (others=>'0'); -- prevent inferring logic to hold value during reset (using CE pins or otherwise)

		elsif rising_edge(divclk_vect(0)) then
			word_delay <= unsigned(sample_delay(sample_delay'HIGH downto 2)) + 5;
			-- get a delayed version of SERDES output to implement byte-level delay


			-- Generate sticky overflow flags
			if clear_fifo_flags='1' then fifo_overflow_sticky <= '0'; elsif fifo_overflow='1' then fifo_overflow_sticky <= '1'; end if;

			serdes_out_dly <= serdes_out;
			case sample_delay(1 downto 0) is
				when "00" =>
					fifo_din <= serdes_out_dly;
				when "01" =>
					fifo_din <= (serdes_out_dly(23 downto 0) & serdes_out(31 downto 24));
				when "10" =>
					fifo_din <= (serdes_out_dly(15 downto 0) & serdes_out(31 downto 16));
				when "11" =>
					fifo_din <= (serdes_out_dly(7 downto 0) & serdes_out(31 downto 8));
				when others => -- XST issues a warning saying case statement is complete and will not be used, but if I remove the 'others' clause XST issues an error sayong case statement does not cover all choices...
			end case;

			-- Start writing to the FIFO when valid data is getting out of the SERDES and the 1-word delay above, which is a few clock cycles after the SERDES_RESET is released.
			if not serdes_auto_reset(0) then -- we use serdes_auto_reset from bit 0 , which is normally clocked on divclk_vect(0)
				-- Skip additional words to account for ISERDES and this process delays
				if word_delay_ctr = word_delay then -- need to concatenate "00" to extend the variable by 2 bits - otherwise +5 overflows silently
					fifo_wr_en <= '1';
				else
					word_delay_ctr <= word_delay_ctr + 1;
				end if;
			end if;

		end if; -- RST/CLK
	end process;


---------------------------------------------------------------------------------
-- FIFO readout process
---------------------------------------------------------------------------------

-- FIFO readout process
-- Sets ADC_READY when there is something in the FIFO
-- Readout is performed when ADC_RD_EN is active. This should be done not too late after ADC_READY so the FIFO does not overflow
fifo_rd_proc: process(all)
	variable i,k: INTEGER;
	variable ramp_word : std_logic_vector(31 downto 0);
	begin
		if adcdaq_reset_all then
			m_axis_adc_tvalid <= '0';
			m_axis_adc_tlast <= '0'; -- not really needed. Added during reset glitch debugging.

			output_word_ctr <= (others=>'0');
			send_data_reg <= '0'; --needed
			data_ready_int <= '0';
			data_ready <= '0';

			fifo_underflow_sticky <= '0';
			fifo_empty_sticky <= '0';
			fifo_rd_en <= '0'; --needed

			ramp_err_ctr <= (others=>'0');
			ramp_err_clear_reg <= '0';
			ramp_err_clear_dly <= '0';
			ramp_err_clear_pulse <= '0';
			ramp_err <= '0'; --needed
			ramp_bit_err <= (others=>'0');
			ramp_bit_err_ctr <= (others=>'0'); -- try to prevent register enable logic to depend from the async reset

		elsif rising_edge(adc_clk) then
			-- Pipeline flow control signals to isolate them from the internal cominatorial logic
			data_ready <= data_ready_int or force_data_ready; -- indicates that we have data to send
			send_data_reg <= send_data; -- Determine when we start to send data to the user

			-- Generate sticky overflow flags
			if clear_fifo_flags='1' then fifo_underflow_sticky <= '0'; elsif fifo_underflow='1' then fifo_underflow_sticky <= '1'; end if;
			if clear_fifo_flags='1' then fifo_empty_sticky <= '0'; elsif fifo_empty='1' then fifo_empty_sticky <= '1'; end if;

			-- Word error counter and edge-sensitive clearing mechanism
			ramp_err_clear_reg <= ramp_err_clear; -- resync the clear signal on this clock (it is on ctrl_clk).
			ramp_err_clear_dly <= ramp_err_clear_reg; -- used to detect change from 0 to 1
			ramp_err_clear_pulse <= ramp_err_clear_reg and not ramp_err_clear_dly; -- high when a 0-to-1 transition is seen on the ramp_err_clear signal

			ramp_err <= '0'; -- Active for one clock only. May be overriden below
			if ramp_err_clear_pulse then -- the ramp zeroing/incrementing is controlled by a single signal. We used to have the output of async logic involving 2 clock domains, so some bits of the counter were not cleared properly
				ramp_err_ctr <= (others=>'0');
			elsif ramp_err='1' and signed(ramp_err_ctr) /= -1 then -- stop counting when max is reached
				ramp_err_ctr <= ramp_err_ctr + 1;
			end if;

			-- Bit error counters and edge-sensitive clearing mechanism
			ramp_bit_err <= (others=>'0');
			if ramp_err_clear_pulse then
				ramp_bit_err_ctr <= (others=>'0'); -- CLear all 4-bit bit error counters at once
			else
				for i in 0 to 7 loop
					if ramp_bit_err(i) = '1' and signed(ramp_bit_err_ctr(i*4+3 downto i*4)) /= -1 then
						ramp_bit_err_ctr(i*4+3 downto i*4) <= to_slv(unsigned(ramp_bit_err_ctr(i*4+3 downto i*4)) + 1);
					end if;
				end loop;
			end if;

			-- Compute ramp word to be used later
			ramp_word :=to_slv(lsb(output_word_ctr,6) & "00" & lsb(output_word_ctr,6) & "01" & lsb(output_word_ctr,6) & "10" & lsb(output_word_ctr,6) & "11");

			-- Set default data vaklid flag
			m_axis_adc_tvalid<='0'; -- by default there is no data unless overriden below

			if enable_ramp then
				data_ready_int <= '1'; -- Data is always ready
				fifo_rd_en <= '0'; -- We do not read the FIFO
				if send_data_reg then -- if we are instructed to send data
					m_axis_adc_tvalid <= '1';
					m_axis_adc_tdata <= ramp_word;
					m_axis_adc_tuser <= (others=>'0');
					m_axis_adc_tlast <= '0';
					if signed(output_word_ctr) = -1 then
						m_axis_adc_tlast <= '1';
					end if;
					-- Count the words that we send. This counter rolls over naturally
					output_word_ctr <= output_word_ctr + 1;
				end if;

			else -- if enable_ramp='0'
				-- Indicate to the user that we are ready to read data when there is enough words in the buffer to prevent an underflow
				-- The user shall soon set the send_data input to allow the module to send the data that is accumulating in the FIFO
				if fifo_prog_full then -- if there are enough samples (8 or more) in the FIFO
					data_ready_int <= '1';
				end if;

				-- Start reading the FIFO when told to
				fifo_rd_en <= send_data_reg and data_ready_int; -- allow reads only when FIFO has a minimum number of words stored.
				-- Send the FIFO data out when it is ready
				-- Note that the FIFO will start reading only when send_data_reg is set.
				if fifo_rd_en and fifo_data_valid then -- If there is a word ready that is about to be overwritten
					-- Flag word errors
					if fifo_dout /= ramp_word then
						ramp_err <= '1'; -- Pulse ramp_err for one clock on each error
					end if;

					-- Flag bit errors
					for i in 0 to 7 loop
						for j in 0 to 3 loop
							if fifo_dout(i+8*j) /= ramp_word(i+8*j) then
								ramp_bit_err(i) <= '1';
							end if;
						end loop;
					end loop;

					-- Tell there is a valid word on the bus
					m_axis_adc_tvalid <= '1';

					-- Set the TLAST flag if this is the last word of a frame
					if signed(output_word_ctr)=-1 then
						m_axis_adc_tlast <= '1';
					else
						m_axis_adc_tlast <= '0';
					end if;

				-- Put the data word on the bus
					-- Invert bit 7 of each byte to obtain 2's complement encoding insted of offset encoding
					for i in 0 to 3 loop
						m_axis_adc_tdata(i*8+7)<= (not fifo_dout(i*8+7)) and data_mask(7); -- Invert bit 7
						m_axis_adc_tdata(i*8+6 downto i*8)<= fifo_dout(i*8+6 downto i*8) and data_mask(6 downto 0);
						-- Pass the overflow flags to the TUSER field.
						-- We did not have enough FMC pint to get the ADC hardware overflow lines to the FPGA. We therefore determine overflow by checking if the signal value is at the ends of the valid range
						if SIGNED(fifo_dout(i*8+7 downto i*8))=0 or SIGNED(fifo_dout(i*8+7 downto i*8))=-1 then
							m_axis_adc_tuser(i)<='1';
						else
							m_axis_adc_tuser(i)<='0';
						end if;
					end loop;

					-- Count the words that we send. This counter rolls over naturally
					output_word_ctr <= output_word_ctr + 1;
				end if; -- if FIFO data ready
			end if; -- if ramp
		end if; -- if CLK
	end process;

-- This is a First-Word fall through FIFO
fifo_underflow <= fifo_rd_en and fifo_empty;

fifo0 : entity work.generic_fifo
	generic map (
		FPGA_SERIES      => FPGA_SERIES,
		MEMORY_TYPE      => "embedded",
		IS_ASYNC         => TRUE,
		IS_FWFT          => TRUE,
		DATA_WIDTH       => 32,
		DEPTH            => 1024, -- 1024 words is enough for 4096 samples. Needs to be large enough in case one channel is configured with a delay compared to the others.
		PROG_FULL_THRESH => 16
	)
	port map (
		wr_clk      => divclk_vect(0),
		wr_en       => fifo_wr_en,
		din         => fifo_din,
		prog_full   => fifo_prog_full, -- on the wr_clk
		overflow    => fifo_overflow,

		rd_clk      => adc_clk,
		rd_en       => fifo_rd_en,
		dout        => fifo_dout, -- FIFO is fallthrough
		empty       => fifo_empty,
		valid       => fifo_data_valid,

		rst         => fifo_rst
	);


-----------------------------------------------------------------------------------
--  Pattern capture process (to support delay adjustment)
-----------------------------------------------------------------------------------
-- The process takes advantage that the ADC test pattern is 11 samples, whereas we aquire samples by groups of 4 samples.
-- This means that a one-sample long pulse will have appeared on each byte of the captured 4-byte word, with a repetition pattern of 11 words
-- The sequence is: 1000 0000 0001 0000 0000 0010 0000 0000 0100 0000 0000 (all bits in the byte are ideally the same)
-- This capture engine  bypasses FIFO and samples absolute sample numbers
-- It clocks on the same clock that the ISERDES works, i.e. either the internal or external divclk
capture2_proc: process(all)
	begin
		if (bsb_rst or not fifo_wr_en) then
--					capture2_done<='1'; -- Needed
					capture2_word_ctr <= (others=>'0'); -- Not really necessary
					capture2_pattern <= (others=>'0'); -- Not really necessary

			elsif rising_edge(divclk_vect(0)) then
				-- Word counter.
				capture2_word_ctr <= capture2_word_ctr+1; -- Word counter. May be overriden (reset) below.
				if capture2_word_ctr=(capture2_period-1) then --
					capture2_word_ctr <= (others=>'0');
				end if;

				if (capture2_word_ctr=capture2_word_number) then -- ADC test pulse pattern has a 11-sample cycle (10 zeros, 1 one). We capture once every 11 words, i.e. every 44 samples.
					capture2_pattern <= serdes_out;
				end if;
			end if; -- RST,CLK
		end process;
else generate -- do not implement the ADCDAQ, just connect the inputs to the outputs
-- generate dummy IBUFDS to prevent errors with the UCF
	BIT_GEN: for i in 0 to 7 generate
		data_ibuf : IBUFGDS -- Instantiate a differential (LVDS) input pad
			  generic map( DIFF_TERM => TRUE)
			  port map
					(
					I  => ADC_DATA_H_P(i),
					IB => adc_data_h_n(i),
					O  => open -- let`s see if the synth removes this
				);
	end generate; -- for j


	clk_ibuf : IBUFGDS -- Instantiate a differential (LVDS) input pad
		  generic map( DIFF_TERM => TRUE)
		  port map
				(
				I  => adc_clk_h_p,
				IB => adc_clk_h_n,
				O  => open -- let`s see if the synth removes this
			);

	-- make sure the outputs are driven
	m_axis_adc_tvalid <= '0';
	m_axis_adc_tlast <= '0';
	m_axis_adc_tdata <= (others=>'0');
	m_axis_adc_tuser <= (others=>'0');

	-- ADC_OUT_DAT<=(TVALID=>'0',TDATA=>(others=>'0'), TLAST=>'0', TUSER=>(others=>'0'));
	ioclk_out_pll <= '0';
	divclk_out_pll <= '0';
	data_ready <= '1';
end generate; --if IMPLEMENT_ADCDAQ=FALSE


end Implementation;

