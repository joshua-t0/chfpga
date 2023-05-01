----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: JF Cliche
--
-- Create Date: 2016-06-29
-- Design Name: chFPGA
-- Module Name: corr_core - Behavioral
-- Project Name: CHIME
-- Target Devices: Kintex 7
-- Tool versions: Vivado 2016.1
-- Description: Performs n^2 correlation between all samples for each frequency bins provided in the incoming stream, integrate the products, and stream the integrated output.
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- HISTORY
--      2012-09-04 JFC: Fixed IMPLEMENT_CORR=FALSE to make sure all control channels are properly terminated. Otherwise would hang the interface if access is tried.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chFPGA_Package.all; -- Get all component definitions
use work.chFPGA_config.all; -- Get all component definitions

library UNISIM;
use UNISIM.VComponents.all;

------------------------------------
------- CORR ENTITY ----------
------------------------------------
-- Implements a correlator block, which consists of
--   1) a correlator that computes the products between all inputs for every freqyency bin in the input frame
--   2) an accumulator that cumulates the results over time and periodically sends the sum over the capture (Ethernet) interface.
--   3) a command router that routes the commands to one of the modules above based on the destination address
--
-- The correlator received a packaged stream consisting of a frame header, frequency bin data from all antennas for one channel, then the frequency bin data for another channel etc.
-- The products between every antenna for each channels are computed and integrated, and the result is framed and streamed through a 8-bit interface  for transmission over the (prober) control channel.
--
-- Location of each CMAC44
entity CORR44 is
	generic (
		PLATFORM_ID: integer := CONFIG_PLATFORM_ID; -- necessary to select the DSP RPM spacing and instantiate the proper DSP and FIFO primitives
		RPM_LAYOUT: string; -- Name of the layout of the correlator DSP, BRAM and FIFO elements  (e.g. "BDDB" or "DBBD")
		CORR_NUMBER: integer := 0; -- used for packet header and to determine the CORR44 RPM locations
		NUMBER_OF_WORDS_PER_BIN: integer := 4; -- also corresponds to the number of clocks per bin. There are 4 samples per word.
		NUMBER_OF_HEADER_WORDS: integer := 4; -- must be <= 4
		DEFAULT_INTEGRATION_PERIOD: integer := 390625; -- 1 sec
		DEFAULT_BINS_PER_FRAME: integer := 128;
		DEFAULT_CONTROL_BYTE0: integer:= 2#10000000#
		--LEFT_DSP_RPM_X: integer := 361;
		--LEFT_BRAM_RPM_X: integer := 350;
		--RIGHT_DSP_RPM_X: integer := 381;
		--RIGHT_BRAM_RPM_X: integer := 394;
		--BOTTOM_DSP_RPM_Y: integer := 0;
		--BOTTOM_BRAM_RPM_Y: integer := 0
		);

	port (

		-- Non-blocking AXI-Stream data input

		s_axis_tdata : in  slv32; --! input data stream containing the channelized data from every antenna processor. Each frame must contain up to 512 words each containing four (4+4) bit signed complex values.
		s_axis_tvalid : in  std_logic; --!
		s_axis_tlast : in  std_logic; --!

		in_clk : in std_logic; --! Input clock channelized data.
		in_rst: in std_logic; --! Reset synchronous to the input clock

		-- Integrated product output
		-- AXI4-Streaming, blocking, 8-bit wide

		m_axis_data_out_tdata: out slv8;
		m_axis_data_out_tvalid: out std_logic;
		m_axis_data_out_tlast: out std_logic;
		m_axis_data_out_tready: in std_logic;

		out_clk : in std_logic; --! clock for the integrated product outputs
		out_rst: in std_logic; --! Reset synchronous to the output clock

		-- Control interface
		cmd_dat: in AXIS8_DAT_STRUCT;
		cmd_rdy: out AXIS8_RDY_STRUCT;
		rply_dat: out AXIS8_DAT_STRUCT;
		rply_rdy: in AXIS8_RDY_STRUCT;
		ctrl_clk : IN std_logic; -- control clock
		ctrl_rst : in STD_LOGIC


		-- -- Correlator clock
		-- clk: in STD_LOGIC; --! Correlator clock, which operates independently from the antenna processors. Should be higher rate than the input clock to allow for the freame header overheads
		-- CORR_RESET: in std_logic; --! Reset synchronous to the correlator clock

		-- -- Data Probe output interface (blocking)
		-- PRB_DAT : out  AXIS8_DAT_STRUCT; --! Output data stream containing the integrated values. Packaged in 8 bit stream for transmission over the Ethernet.
		-- PRB_RDY : in  AXIS8_RDY_STRUCT; --! Handshaking for the output data stream to control the data flow
		-- PRB_CLK : in STD_LOGIC; --! Output data stream clock


		-- -- Control and reply streams
		-- CMD_DAT: in AXIS8_DAT_STRUCT;
		-- CMD_RDY: out AXIS8_RDY_STRUCT;
		-- RPLY_DAT: out AXIS8_DAT_STRUCT;
		-- RPLY_RDY: in AXIS8_RDY_STRUCT;
		-- CTRL_CLK : IN std_logic; -- control clock
		-- CTRL_RST : in STD_LOGIC
		);

end CORR44;


--! @brief Correlator Implementation
--!
--! The correlator must process the data at the same rate it comes in. If it takes 4 clocks to bring
--all the complex values to correlate, all the correlation products must be produced in 4 clocks.
--
-- Given N samples, a matrix of N rows x N columns would take N clocks to compute, column by column.
-- However, the upper triangle is redundant with the lower one. We can therefore compute the
-- products in N/2 clocks by organizine the data such that all products of the lower triangle are covered within those N/2 clocks.
--
-- With this principle, It takes 2*N samples are computed by clock, but data is coming in at the rate of 4*N samples per clock.
-- To deal with this, we parallelize the correlator such that the equivalent of 2 clocks are computed


architecture Behavioral of CORR44 is

-- Attributes used in this design
attribute equivalent_register_removal: string;
attribute shreg_extract: string;


-- Control signals
-- constant NUMBER_OF_MODULES: INTEGER :=3;
-- constant MODULE_CORR_ADDR: integer :=1;
-- constant MODULE_ACC_ADDR: integer :=2;

constant FPGA_SERIES: integer := FPGA_SERIES_LIST(PLATFORM_ID);

constant N: integer := 4 * NUMBER_OF_WORDS_PER_BIN; -- number of complex samples per frequency bin = number of channels per frequency bin

constant NUMBER_OF_CMACS : integer := (N+1)*2;


-- Get the relative RPM position of the elements in the corr44 cores for the specified layout
constant cmac_rpms: cmac44_rpm_coord_struct_array := get_cmac44_rpm_coords_struct_array(PLATFORM_ID, N, RPM_LAYOUT);

-- DSP & BRAM vertical spacing in RPM coordinates
constant DSP_TILE_DELTA_RPM_Y: integer := PLATFORM_INFO(PLATFORM_ID).DSP_TILE_DELTA_RPM_Y;
constant BRAM_TILE_DELTA_RPM_Y: integer := PLATFORM_INFO(PLATFORM_ID).BRAM_TILE_DELTA_RPM_Y;
constant DSP_BEL_DELTA_RPM_Y: integer := PLATFORM_INFO(PLATFORM_ID).DSP_BEL_DELTA_RPM_Y;
constant BRAM_BEL_DELTA_RPM_Y: integer := PLATFORM_INFO(PLATFORM_ID).BRAM_BEL_DELTA_RPM_Y;

signal buf: slv32_array(0 to NUMBER_OF_WORDS_PER_BIN-1);
signal x: slv8_array(0 to N-1);
signal y: slv8_array(0 to N-1);
signal s: std_logic_vector(0 to N-1);
signal cmac_x: slv8_array(0 to NUMBER_OF_CMACS-1);
signal cmac_y: slv8_array(0 to NUMBER_OF_CMACS-1);
signal cmac_x_conj: slv(0 to NUMBER_OF_CMACS-1);
signal cmac_y_conj: slv(0 to NUMBER_OF_CMACS-1);
signal cmac_rd_err: slv(0 to NUMBER_OF_CMACS-1);
signal cmac_wr_err: slv(0 to NUMBER_OF_CMACS-1);
signal cmac_readout_err: slv(0 to NUMBER_OF_CMACS-1);

signal cmac_z_tdata: slv36_array(0 to NUMBER_OF_CMACS);
signal cmac_z_tvalid: slv(0 to NUMBER_OF_CMACS);
signal cmac_z_tlast: slv(0 to NUMBER_OF_CMACS);
signal cmac_z_send: slv(0 to NUMBER_OF_CMACS);
signal cmac_z_start: slv(0 to NUMBER_OF_CMACS);
signal cmac_z_local_data: slv(0 to NUMBER_OF_CMACS-1);

signal xy_tvalid: std_logic;
signal xy_tlast: std_logic;
signal xy_last_frame: std_logic;

signal load: std_logic;
signal last: std_logic;
signal last_reg: std_logic;
signal last_frame: std_logic;

signal is_header: std_logic;
signal is_data: std_logic;
signal word_ctr: unsigned(1 downto 0); -- counts header words (0..3) and words in bins (up to 4)
signal bin_ctr: unsigned(11 downto 0); -- counts bins in frames (up to 128)
signal frame_ctr: unsigned(31 downto 0); -- counts frames to implement the integration period
--type zz_array is array (NATURAL RANGE <>) of slv36_array(0 to 2*N-2-1);
--signal zz: zz_array(0 to 3);

--  attribute dont_touch: string;
--  attribute dont_touch of m_axis_align_out_tvalid_reg: signal is "no"; --

-- Readout signals
signal byte_ctr: integer range 0 to 11; -- Counts header words (0 to 11) and bytes within words (0 to 4)
signal cmac_id: unsigned(bitwidth(NUMBER_OF_CMACS-1) downto 0);
signal m_axis_data_out_tvalid_int: std_logic;
signal integration_number: unsigned(31 downto 0);
signal send_header: std_logic;
signal rst_all: std_logic;
signal in_rst_all: std_logic;

signal data_fifo_din: std_logic_vector(37 downto 0);
signal data_fifo_dout: std_logic_vector(37 downto 0);
signal data_fifo_dout_padded: std_logic_vector(39 downto 0);
signal data_fifo_wr_en: std_logic;
signal data_fifo_rd_en: std_logic;
signal data_fifo_valid: std_logic;
signal data_fifo_prog_full: std_logic;
signal data_fifo_overflow: std_logic;
signal data_fifo_empty: std_logic;

signal started: std_logic;

-- Control and status bytes
signal control_bytes: slv8_array(0 to 6); -- default value set in the CMD_SLAVE
signal status_bytes: slv8_array(0 to 2);

signal integration_period: std_logic_vector(31 downto 0);
signal number_of_bins_per_frame: std_logic_vector(11 downto 0);
signal user_reset: std_logic;
signal user_id: std_logic_vector(3 downto 0);
signal in_frame_ctr: unsigned(7 downto 0);
signal out_frame_ctr: unsigned(7 downto 0);
signal in_frame_ctr_reg: unsigned(7 downto 0);
signal out_frame_ctr_reg: unsigned(7 downto 0);
signal data_fifo_overflow_sticky: std_logic;
signal autocorr_only: std_logic;
signal no_accum: std_logic;
signal autocorr_only_reg: std_logic; --timing
signal no_accum_reg: std_logic; --timing

FUNCTION corr_header_words(
		-- Word 0
		---- Byte 0 - sent first
		COOKIE: std_logic_vector(7 downto 0) := X"BF"; --! 8 Bits (hardcoded) used to identify the type of frame. The cookie is last in the word so it appears first in the packet.
		---- Byte 1
		PROTOCOL_VERSION: std_logic_vector(3 downto 0) := X"1"; --! Along with the cookie, identifies how the data is encoded in this header and the data. The cookie will have to change if we run out of space for versions.
		HEADER_LENGTH_IN_WORDS: std_logic_vector(3 downto 0) := X"3"; --! Number of 32-bit words in this header, to help the GPU skip this part if needed
		---- Byte 2
		USER_ID: std_logic_vector(3 downto 0); --! 4-bit value arbitrary user ID
		CORR_ID: std_logic_vector(3 downto 0); --! 4-bit value that identifies the corrlator core number
		---- Byte 3
		CMAC_ID: std_logic_vector(7 downto 0); --! 8-bit value that identifies from which CMAC the data is coming (0 .. 2(N+1)-1), (0..33 for N=16)

		-- Word 1
		UNUSED: std_logic_vector(7 downto 0) := X"00"; --! bit 0: '0' = 8 bit mode, '1' = 4 bit mode; bit 1: '0'= 2's complement, '1'=offset binary, bits 2-3: reserved
		NUMBER_OF_BINS_PER_FRAME: std_logic_vector(11 downto 0); --! Number of frequency bins included in each frame (1-4095) (there are up to 1024 bins in full CHIME)
		NUMBER_OF_CHANNELS: std_logic_vector(11 downto 0); --! Number of ADC analog channels included for each frequency bin (1-4095) (there are up to 2560 antennas in full CHIME)

		-- Word 2
		INTEGRATION_NUMBER: std_logic_vector(31 downto 0) -- --! 32-bit number that counts the integration periods.
		) return slv32_array is
	variable w : slv32_array(0 to 2);
	begin
		w(0):= (CMAC_ID & (USER_ID & CORR_ID) & (PROTOCOL_VERSION & HEADER_LENGTH_IN_WORDS) & COOKIE );
		w(1):= (UNUSED & NUMBER_OF_BINS_PER_FRAME & NUMBER_OF_CHANNELS);
		w(2):= INTEGRATION_NUMBER;
		return w;
	end corr_header_words;


begin

---------------------------------------------------------------------
--! Correlator input pipelining process
---------------------------------------------------------------------
--! Pipelines the correlator input to facilitate routing and timing closure to the correlators
--! This pileline stage will be located within the PBLOCK associated with this correlator, so it won't help long-distance routing but still might help internally
--! 130204 JFC: removed reset from most registers to eliminate timing constraints from that signal on the registers
-- inpipe_proc: process(clk)
--  begin
--      if rising_edge(clk) then
--          IN_RESET_REG<=IN_RESET;
--          IN_DAT_REG<=IN_DAT;
--          if IN_RESET='1' then
--              IN_DAT_REG.TVALID<='0';
--          end if;
--      end if;
--  end process;

---------------------------------------------------------------------
--! Instantiate the memory-mapped registers
---------------------------------------------------------------------

-----------------------------------------------------------------------------------
-- CONTROL and STATUS Bytes
-----------------------------------------------------------------------------------
--! \addtogroup memory_map
--! ACC Module
--! =============
--! ------------------------------------------------------------------------------
--! |  Page   | Addr|Bit(s)|     Name             | Description                   |
--! |---------|-----|------|----------------------|-------------------------------|
--! | CONTROL |  0  |  7   | USER_RESET          | Reset the CH_DIST and clears the FIFOs.|
--! |         | 1-4 | 31:0 | INTEGRATION_PERIOD   | Number of frames that are integrated before the intergation starts over. 32 bit value, must be >=3.  |
--! |         | 5-8 | 31:0 | CAPTURE_PERIOD       | Number of frames between the transmission of the current integrated result. 32 bit value, must be >=3. |
--! |         |   9 | 7:0  | PROBE_ID             | First byte of the transmitted correlation frame |
--! | STATUS  |  0  | 7:0  | FRAME_CTR            | Received frame counter (wraps around) |
--! |         |  1  |  0   | CAPTURE_OVERFLOW     | An overflow was detected on any of the CAPTURE FIFO. Cleared by any reset. |
--! |         |     |  1   | CAPTURE_UNDERFLOW    | An underflow was detected on any of the CAPTURE FIFO. Cleared by any reset. |
--! |         |     |  2   | ACCUM_OVERFLOW       | An underflow was detected on any of the CAPTURE FIFO. Cleared by any reset. |
--! |         |     |  3   | ACCUM_UNDERFLOW      | An underflow was detected on any of the CAPTURE FIFO. Cleared by any reset. |
--! ------------------------------------------------------------------------------
--!
-- CONTROL Byte 0
user_reset <= control_bytes(0)(7);
autocorr_only <= control_bytes(0)(6);
no_accum <= control_bytes(0)(5);
user_id <= control_bytes(0)(3 downto 0);
-- CONTROL Bytes 1-4
integration_period <= to_slv(control_bytes(1 to 4));

-- CONTROL Byte 5
number_of_bins_per_frame <= "000" & to_slv(control_bytes(5 to 6))(8 downto 0);

--! STATUS Byte 0
--status_bytes(0)(7 downto 4) <= (others=>'0');
--status_bytes(0)(3)          <= ACCUM_UNDERFLOW;
--status_bytes(0)(2)          <= ACCUM_OVERFLOW;
status_bytes(0)(0) <= rst_all;
status_bytes(0)(1) <= data_fifo_prog_full;
status_bytes(0)(2) <= data_fifo_overflow_sticky;
status_bytes(0)(3) <= cmac_z_local_data(0);
status_bytes(0)(4) <= m_axis_data_out_tready;
status_bytes(0)(5) <= cmac_readout_err(0);
status_bytes(0)(6) <= cmac_wr_err(0);
status_bytes(0)(7) <= cmac_rd_err(0);

status_bytes(1) <= to_slv(in_frame_ctr_reg);
status_bytes(2) <= to_slv(out_frame_ctr_reg);

CTRL_SLAVE0: entity work.CTRL_SLAVE
	generic map (
		NUMBER_OF_CONTROL_BYTES => control_bytes'Length(1), --
		NUMBER_OF_STATUS_BYTES  => status_bytes'Length(1), --
		--DEFAULT_CONTROL_BYTES   => (X"00" & X"0005F5E0" & x"7F") -- reset=0, user_id="0000", integration_period=390625-1 = 1s, bins_per_frame=128-1
		DEFAULT_CONTROL_BYTES   => (to_slv(DEFAULT_CONTROL_BYTE0, 8) & to_slv(DEFAULT_INTEGRATION_PERIOD-1, 32) & "0000000" & to_slv(DEFAULT_BINS_PER_FRAME-1, 9)) -- reset=0, user_id="0000", integration_period=390625-1 = 1s, bins_per_frame=128-1
	)

	port map (
		-- Control interface (command and reply stream buses)
		CTRL_CMD_IN_DAT   => cmd_dat,
		CTRL_CMD_IN_RDY   => cmd_rdy,
		CTRL_RPLY_OUT_DAT => rply_dat,
		CTRL_RPLY_OUT_RDY => rply_rdy,
		CTRL_CLK          => ctrl_clk,
		CTRL_RST          => ctrl_rst,

		CONTROL_BYTES => control_bytes,
		STATUS_BYTES => status_bytes
	);


-- Instantiate an array of CMAC44s
-- CMACS are placed in two columns (left & right) of N+1 CMAC44. Each CMAC is 2 DSP high (and 2 BRAM high as well).
-- CMAC outputs are daisy chained, with data flowing out from CMAC(0)
cmac: for i in 0 to NUMBER_OF_CMACS-1 generate

begin
	cmac0: entity work.CMAC44
		GENERIC map (
			PLATFORM_ID => PLATFORM_ID,
			RPM_NAME => "RPM_CORR" & integer'IMAGE(CORR_NUMBER),
			RPM_COORDS => cmac_rpms(i) -- relative coordinates of the DSPs, FIFO and BRAM
			)
		PORT MAP(
			s_axis_xy_tvalid             => xy_tvalid,
			s_axis_xy_tlast              => xy_tlast,
			s_axis_xy_last_frame         => xy_last_frame,
			s_axis_xy_tdata(15 downto 8) => cmac_x(i),
			s_axis_xy_tdata(7 downto 0)  => cmac_y(i),
			s_axis_xy_xconj              => cmac_x_conj(i),
			s_axis_xy_yconj              => cmac_y_conj(i),

			-- Data output from this CMAC

			m_axis_z_out_tdata           => cmac_z_tdata(i),
			m_axis_z_out_tlast           => cmac_z_tlast(i),
			m_axis_z_out_tvalid          => cmac_z_tvalid(i),
			m_axis_z_out_send            => cmac_z_send(i),
			m_axis_z_out_start           => cmac_z_start(i),
			m_axis_z_out_local_data      => cmac_z_local_data(i),

			-- Data input from the neighboring CMAC

			s_axis_z_in_tdata            => cmac_z_tdata(i+1),
			s_axis_z_in_tlast            => cmac_z_tlast(i+1),
			s_axis_z_in_tvalid           => cmac_z_tvalid(i+1) and not to_std_logic(i=3 and autocorr_only_reg='1'), -- break the tvalid chain at the input of the last autocorr cmac
			-- s_axis_z_in_tvalid           => '0',
			s_axis_z_in_send             => cmac_z_send(i+1),
			s_axis_z_in_start            => cmac_z_start(i+1),

			rd_err                       => cmac_rd_err(i),
			wr_err                       => cmac_wr_err(i),
			readout_err                  => cmac_readout_err(i),
			no_accum                     => no_accum_reg,

			clk                          => in_clk,
			rst                          => in_rst_all
			);


end generate;


-- Connect the 4 autocorrelators
cmac_x(0) <= x(N/2-1);
cmac_x(1) <= x(N/2-2);
cmac_x(2) <= x(N-1);
cmac_x(3) <= x(N-2);
cmac_y(0 to 3) <= cmac_x(0 to 3);

cmac_x_conj(0 to 3) <= (others => '0');
cmac_y_conj(0 to 3) <= (others => '1');

-- Connect the cross-correlators
cross_cmac: for i in 0 to N-1-1 generate
	cmac_x(4+2*i+0) <= x(i);
	cmac_y(4+2*i+0) <= y(i) when i<N/2-2 and s(i)='1' else y(i+1); -- we never get to rotate up to index N/2-2, so let's not create muxes needlessly
	cmac_x(4+2*i+1) <= x((N-1+i) mod N); -- access x value as if the vector was rotated by one
	cmac_y(4+2*i+1) <= y(i) when i=0 or (i < N/2-1 and s(i-1)='1') else y(i+1); -- since we assume x is rotated by one, the first element is always rotated. Also, we never get to rotate beyond up to index N/2-1

	cmac_x_conj(4+2*i+0) <= '1' when i < N/2-2 and s(i)='1' else '0';
	cmac_y_conj(4+2*i+0) <= not cmac_x_conj(4+2*i+0); -- we never get to rotate up to index N/2-2
	cmac_x_conj(4+2*i+1) <= '1' when i=0 or (i < N/2-1 and s(i-1)='1') else '0'; -- access x value as if the vector was rotated by one
	cmac_y_conj(4+2*i+1) <= not cmac_x_conj(4+2*i+1) ; -- since we assume x is rotated by one, the first element is always rotated. Also, we never get to rotate beyond up to index N/2-1

end generate;



-- terminate the dangling radout input of the last CMAC in the chain
cmac_z_tdata(NUMBER_OF_CMACS) <= (others => '0');
cmac_z_tvalid(NUMBER_OF_CMACS) <= '0';
cmac_z_tlast(NUMBER_OF_CMACS) <= '0';


main: process(in_clk)
	begin
		if rising_edge(in_clk) then
			in_rst_all <= in_rst or user_reset;
			autocorr_only_reg <= autocorr_only;
			no_accum_reg <= no_accum;

			-- Data fifo input
			-- We pipeline because the FIFO input has a heavy load and pulls all the CMAC0 logic at the other end of the CORR44
			data_fifo_din <= cmac_z_local_data(0) & cmac_z_tlast(0) & cmac_z_tdata(0);
			data_fifo_wr_en <= cmac_z_tvalid(0);

			in_frame_ctr_reg <= in_frame_ctr;
			if data_fifo_overflow='1' then
				data_fifo_overflow_sticky <='1';
			end if;
			load <= '0';
			if s_axis_tvalid='1' then
				word_ctr <= word_ctr + 1;
				if is_header='1' and started='1' then
					bin_ctr <= (others=> '0');
					if word_ctr = NUMBER_OF_HEADER_WORDS-1 then
						is_header <='0';
						is_data <= '1';
						last <= '0'; -- are we loading he last word of the frame
						word_ctr <= (others=> '0');
						if frame_ctr = unsigned(integration_period)  then
							last_frame <= '1';
							frame_ctr <= (others => '0');
						else
							last_frame <= '0';
							frame_ctr <= frame_ctr + 1;
						end if;
					end if;
				end if;
				if is_data = '1' then -- Header='0'
					--if autocorr_only_reg='1' then
					--	buf(to_integer(word_ctr)) <= X"10101010";
					--else
						buf(to_integer(word_ctr)) <= s_axis_tdata xor X"88888888";
					--end if;
					if word_ctr = NUMBER_OF_WORDS_PER_BIN-1 then
						load <='1'; -- Start the correlation process
						word_ctr <= (others=> '0');
						bin_ctr <= bin_ctr + 1;
						if bin_ctr = unsigned(number_of_bins_per_frame) then
							last <= '1';
							is_data <= '0'; -- stop capturing data
						else
							last <= '0'; -- are we loading he last word of the frame
						end if;
					end if;
				end if;
				if s_axis_tlast='1' then
					-- in_frame_ctr <= in_frame_ctr + 1;
					word_ctr <= (others=> '0');
					is_header <='1';
					is_data <= '0';
					started <='1';
				end if;

			end if; -- tvalid = 1

			if xy_tvalid='1' and xy_tlast='1' and xy_last_frame='1' then
				in_frame_ctr <= in_frame_ctr + 1;
			end if;

			--------------------------------------------
			-- Once we have all the samples for one bin in the buffer (load=1), transfer the data into the X & Y vectors.
			-- Otherwise, rotate X by 2 slots
			--------------------------------------------
			x(2 to N-1)  <= x(0 to N-2-1);
			x(0 to 1) <= x(N-2 to N-1);
			s(2 to N-1) <= s(0 to N-2-1);
			s(0 to 1) <= "11";

			-- tvalid is set when  we load new data until we have shifted N/4 times
			if load = '1' then
				xy_tvalid <= '1';
			elsif N=4 or s(N/2-4)='1' then -- s is initialized
				xy_tvalid <= '0';
			end if;

			-- tlast is set when  we have shifted N/4 times
			if N<12 then -- probably not right
				xy_tlast <= last; -- if we have only one word per bin, this is always the last word
			elsif load='1' then
				last_reg <= last;
				xy_tlast <= '0';
			elsif s(N/2-6)='1' then
				xy_tlast <= last_reg;
			end if;

			if load='1' then    -- Load the data into the multiplier vectors
				xy_last_frame <= last_frame;
				s <= (others => '0');
				for i in  0 to NUMBER_OF_WORDS_PER_BIN-1 loop
					for j in 0 to 3 loop
						x(4*i+j) <= buf(i)(8*j+7 downto 8*j);
						y(4*i+j) <= buf(i)(8*j+7 downto 8*j);
					end loop;
				end loop;
			end if;

			if in_rst_all='1' then
				load <= '0';
				last <= '0'; -- not necessary
				word_ctr <= (others=>'0');
				bin_ctr <= (others=>'0');
				frame_ctr <= (others=>'0');
				is_header <= '1';
				is_data <= '0';
				started <= '0';
				s <= (others => '0'); -- is used when load='0', but is reset only after load='1'.
				data_fifo_overflow_sticky <= '0';
				xy_tvalid <= '0';
			end if; -- RST
		end if; -- CLK
	end process;

-- 38bits x 512 words Embedded FIFO
-- 36 bits for data, 1 bit for TLAST, 1 bit to indicate a new readout sequence (i.e data is from CMAC0)
-- EMbedded FIFO has only rs on K7, and only srst on Ultrascale+
DATA_FIFO_K7: if FPGA_SERIES=FPGA_KINTEX7 generate
	data_fifo : entity work.CORR44_DATA_FIFO
	  PORT MAP (
		rst       => rst_all, -- async reset on K7 Embed FIFO
		wr_clk    => in_clk,
		wr_en     => data_fifo_wr_en,
		din       => data_fifo_din,
		overflow  => data_fifo_overflow,
		full      => open,
		prog_full => data_fifo_prog_full,

		rd_clk    => out_clk,
		rd_en     => data_fifo_rd_en,
		dout      => data_fifo_dout,
		empty     => data_fifo_empty,
		valid     => data_fifo_valid
	  );
end generate;
DATA_FIFO_UP: if FPGA_SERIES=FPGA_ULTRASCALEPLUS generate
	data_fifo : entity work.CORR44_DATA_FIFO_UP
	  PORT MAP (
		srst       => rst_all, -- sync reset on u+ embedded FIFO
		wr_clk    => in_clk,
		wr_en     => data_fifo_wr_en,
		din       => data_fifo_din,
		overflow  => data_fifo_overflow,
		full      => open,
		prog_full => data_fifo_prog_full,

		rd_clk    => out_clk,
		rd_en     => data_fifo_rd_en,
		dout      => data_fifo_dout,
		empty     => data_fifo_empty,
		valid     => data_fifo_valid
	  );
end generate;


-- FIFO write interface
cmac_z_send(0) <= not data_fifo_prog_full;
cmac_z_start(0) <= cmac_z_local_data(0);

-- FIFO read interface

data_fifo_rd_en <= to_std_logic(send_header='0' and byte_ctr=4 and ((m_axis_data_out_tvalid_int='0' or m_axis_data_out_tready='1') and data_fifo_valid='1'));
m_axis_data_out_tvalid <= m_axis_data_out_tvalid_int;

data_fifo_dout_padded(39) <= '0';
data_fifo_dout_padded(38) <= data_fifo_dout_padded(37) or data_fifo_dout_padded(36);
data_fifo_dout_padded(37) <= to_std_logic(
	data_fifo_dout(35 downto 18) = "011111111111111111" or
    data_fifo_dout(35 downto 18) = "100000000000000000");

data_fifo_dout_padded(36) <= to_std_logic(
	data_fifo_dout(17 downto 0) = "011111111111111111" or
	data_fifo_dout(17 downto 0) =	"100000000000000000");
data_fifo_dout_padded(35 downto 0) <=  data_fifo_dout(35 downto 0); -- pad to 40 bits (5 bytes)


-- FIFO Read Process
--
-- We do not use a assymetric FIFO to convert the 36 bits of data into 5 bytes, as the aspect ratio is either 1:4 or 1:8, not 1:5.
fifo_readout_proc: process(out_clk)
	variable header_words: slv32_array(0 to 2);
	variable header_bytes: slv8_array(0 to 11);

	begin
		if rising_edge(out_clk) then
			rst_all <= out_rst or in_rst or user_reset; -- Retime the reset to OUT_CLK (which is normally CTRL_CLK). We use an ASYNC_REG attribute because SOFT_RESET is in the in_clk domain.
			out_frame_ctr_reg <= out_frame_ctr;
			-- synchronous reset
			-- Clear the TREADY if the data is read by the destination. This will be overriden below if a new byte is sent at the same time
			if m_axis_data_out_tready='1' then
				m_axis_data_out_tvalid_int<='0';
			end if;

			-- Output the data to the destination
			if (m_axis_data_out_tvalid_int='0' or m_axis_data_out_tready='1') and data_fifo_valid='1'  then -- if the bus is ready to receive a new byte and we have
				header_words := corr_header_words(
						USER_ID =>  user_id,
						CORR_ID => to_slv(CORR_NUMBER, 4),
						CMAC_ID => std_logic_vector(resize(cmac_id, 8)),
						NUMBER_OF_BINS_PER_FRAME => number_of_bins_per_frame,
						NUMBER_OF_CHANNELS => to_slv(N, 12),
						INTEGRATION_NUMBER => std_logic_vector(integration_number)
						);
				header_bytes := to_slv8_array_le(header_words);
				byte_ctr <= byte_ctr + 1;
				if send_header='1' then
					m_axis_data_out_tvalid_int <= '1';
					m_axis_data_out_tdata <= header_bytes(byte_ctr);
					m_axis_data_out_tlast <= '0';

					if byte_ctr = 0 then -- if this is the first header byte

						-- Clear or increment the CMAC_ID and integration number before we send it
						-- in the header
						--
						-- We do this at the beginning of a new readout (as opposed to doing it on
						-- the last frame of a readout) to make sure we are robust in case not all
						-- CMAC data is sent (e.g. if the integration period is too short)
						--
						-- Note that we set the ID while we are already started sending the first
						-- header byte, but this first byte is the cookie so this is ok
						cmac_id <= cmac_id + 1;
						if data_fifo_dout(37) = '1' then -- if this is a new readout
							cmac_id <= (others=>'0');
							integration_number <= integration_number + 1;
						end if;

					elsif byte_ctr = header_bytes'HIGH then -- if this is the last header byte
						send_header <= '0'; -- start sending the data
						byte_ctr <= 0; -- prepare for counting bytes in data words
					end if;
				else
					m_axis_data_out_tvalid_int <= '1';
					m_axis_data_out_tdata <= data_fifo_dout_padded(byte_ctr*8+7 downto byte_ctr*8);
					m_axis_data_out_tlast <= '0';

					if byte_ctr = 4 then
						byte_ctr <= 0;

						if data_fifo_dout(36) = '1' then -- if that was the last word of a frame
							m_axis_data_out_tlast <= '1';
							send_header <= '1';
							out_frame_ctr <= out_frame_ctr + 1;
						end if;
					end if; -- byte_ctr=4
				end if; -- if header
			end if; -- if data and destination ready
			if rst_all='1' then
				m_axis_data_out_tvalid_int <= '0'; -- needed
				send_header <= '1'; -- needed to make sure we start with header transmission
				byte_ctr <= 0;
				cmac_id <= (others=> '0');
				integration_number <= (others => '1'); -- is pre-incremented at the beginning of the first frame of a readout
				out_frame_ctr <= (others => '0');
			end if; -- reset
		end if; -- CLK
	end process;



end Behavioral;

