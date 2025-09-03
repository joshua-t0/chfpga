-- Company: McGill University
-- Engineer: JF Cliche
--
-- Create Date:    12/02/2010
-- Design Name:    FUNCGEN
-- Module Name:    FUNCGEN - Behavioral
-- Project Name: CHIME, HIRAX, CHORD, and other standalone radiotelescopes
-- Target Devices: Evolved through Virtex 6, Kintex 7, Zynq Ultrascale+
-- Tool versions: ISE 14.2 -  Vivado 2022.2
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
--  2012-10-01 JFC: Splitted from SRCSEL
--  2013-02-06 JFC: Removed RST from main process reset list to limit distribution of that signal
--  2014-01-29 JFC: Added 4-bit functions. Used variables to simplify code. Added use_overflow.
--  See Git repository for further logs

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;
use IEEE.std_logic_misc.ALL; -- for or_reduce()
use IEEE.math_real.all; -- log2, ceil

library UNISIM;
use UNISIM.VComponents.all;

library xpm;
use xpm.vcomponents.all;

use work.chFPGA_Package.all; -- Get all component definitions

-- Implements a AXI4-Streaming function generator that either forwards
--     the input from the ADC or replaces it with user-programmable arbitrary
--     waveforms, noise, or packet test patterns.
--
-- Interface
-- ---------
--
-- The data from the ADC is provided to the `s_axis_adc_*` port , which is a non-blocking AXI4-Streaming
-- bus. ``ADC_SAMPLES_PER_WORD`` ADC samples are packed into the data word in `s_axis_adx_tdata`, each sample being ``ADC_BITS_PER_SAMPLE``-bit wide.
-- The first sample is stored in
-- the MSB of the word, and each sample is stored as a big endian value. This order facilitate visualizing data in simulation (incoming samples are read left to right in the word).
-- The input bus from the ADC contains the usual AXI-S TVALID and TLAST lines to frame the data in the packet.
--
-- Additionaly, the ``ADC_SAMPLES_PER_WORD``-bit wide TUSER signal provides a saturation flag for each of the sample in the word.
-- The leftmost (MSB) bit correspond to the saturation sample of the sample in the MSB of the word (i.e. first sample).
--
--
-- The output of FUNCGEN is also a non-blocking AXI4-Streaming bus and has the same structure as the
-- input, except for the ``TUSER`` signal which a single bit frame over flow flag that indicates is
-- **any** sample has an overflow in the frame. This bit is set on the last word of a frame (i.e.
-- valid only when TLAST=1).
--
-- Operation modes
-- ---------------
--
-- The output of the FUNCGEN module is selected by the 3-bit `fn_sel` memory-mapped field. The supported modes are:
--  - 0 / FN_ADC: Passes on the ADC input. The ADC overflow bits are aggregated througout the frame
--    and the resulting ``frame_overflow_flag`` bit is provided on the last frame. The number of sample overflows
--    over a specified period of frames (through the control register ``stats_period``) can be accessed by the status register ``overflow_ctr``.
--
--  - 1 / FN_RAM: Outputs the RAM contents (2048 bytes, 512 words). ``frame_overflow_flag`` and ``overflow_ctr`` are always zero.
--
--  - 2 / FN_NOISE: Outputs Pseudo-Random noise. ``frame_overflow_flag`` and ``overflow_ctr`` are always zero. The noise
--    generator is seeeded by the 8-bit A and B fields to allow each channelizer to have up to 65536
--    different (presumamly uncorrelated) patterns. ``frame_overflow_flag`` and ``overflow_ctr`` are always zero.
--
--  - 3 / FN_FRAME_WORD_CTR_RAM_FLAGS: Counts frames and words, with programmable ADC overflow bit
--    patterns. This mode is mostly used for testing. The output data is grouped in 32-bit words (the whole word for Iceboard and the LSB 32 bits for CRS),
--    containing a 21-bit frame count in the MSB followed bit 11-bit word count for the Iceboard. This pattern
--    does not generate nice data when splitted in 4-bytes (and even less when going through the
--    FFT), but it ensures that consecutive frames will contain unique data when looked word-wise.
--    In this mode, ``frame_overflow_flag`` and ``overflow_ctr`` can be programmed by injecting specific values into the buffer. ``frame_overflow_flag`` will be '1' if there is any bit that is '1' in the buffer. ``overflow_ctr`` increments for every sample whose value is LSB is '1'. An overflow for a sample can thus be simulated by injecting a '1' in that sample.
--
--  - 4 / FN_FRAME8: Each sample is the last 6 bits (for IceBoard)/12 bits (for CRS) of the current frame number  .
--    In this mode, ``frame_overflow_flag`` and ``overflow_ctr`` can be programmed by injecting specific values into the buffer. ``frame_overflow_flag`` will be '1' if there is any bit that is '1' in the buffer. ``overflow_ctr`` increments for every sample whose value is LSB is '1'. An overflow for a sample can thus be simulated by injecting a '1' in that sample.
--
--  - 5 / FN_FRAME4: The most significant 4 bits of each sample is the last 4 bits of the current
--    frame number. The lower 4 bits are zero.
--    In this mode, ``frame_overflow_flag`` and ``overflow_ctr`` can be programmed by injecting specific values into the buffer. ``frame_overflow_flag`` will be '1' if there is any bit that is '1' in the buffer. ``overflow_ctr`` increments for every sample whose value is LSB is '1'. An overflow for a sample can thus be simulated by injecting a '1' in that sample.
--
--  - 6 / FN_RAM_NIBBLE4: Sends bits 3:0 of RAM samples on even frames an bits 7:4 of RAM samples on odd frames. Data is aligned with the 4 MSBS
--      of each sample, and the rest of the bits in the sample are zero. In this mode, ``frame_overflow_flag`` and ``overflow_ctr`` are always zero.

-- Waveform buffer
-- ---------------
--
-- The waveform buffer consist of 4096 bytes that can be programmed in banks of 512 bytes. Only the
-- first 2048 bytes are currently used to generate waveform in the FN_RAM mode.
--
-- NOTE: The new MMI interface supports writing all 4096 bytes in a single command, but the logic
-- here does not support it and uses paging instead.
--
-- Noise generator
-- ---------------
--
-- The noise is generated as a 32-bit output LFSR generator fed by the 8-bit A and B signals (the
-- 32-bit input is a combination of A, B, not A, and not B). These A and B parameters act as seed.
-- The same A and B value will always result in the same sequence. Note that the LFSR outputs will be stuck at zero if A and B are both zero.
-- The sequence repeats after 2**32 - 1 words for IceBoard and (2**32 - 1)/4 word for CRS.
--
-- Overflow counter
-- ---------------
--
-- The overflow counter counts over ```stats_period```(user defined) frames the number of sample overflows from the ADC or the number of overflows injected
-- Through the buffer (either from modes FN_FRAME_WORD_CTR_RAM_FLAGS, FN_FRAME8 or FN_FRAME4). The overflow count for other modes
-- (FN_RAM, FN_NOISE, FN_RAM_NIBBLE4) is 0. The maximum number of frames over which to count the number of overflows is 65535. When counting overflows from
-- the buffer, each sample's LSB indicate if there is an overflow or not, so to simulate an overflow in a sample, set the sample value to 1.
-- Overflow counting is enabled with ```stats_enable``` and the result can be read from ```overflow_ctr```.
--
entity FUNCGEN is
    generic (
        ADC_SAMPLES_PER_WORD: integer := 8;
        ADC_BITS_PER_SAMPLE: integer := 14;
        ADC_SAMPLES_PER_FRAME: integer := 16384;
        IMPLEMENT_DELAY_CAPTURE: boolean := FALSE
    );
    port (

        -- ADC data input stream (AXI-Streaming, non blocking)

        s_axis_adc_tdata: in std_logic_vector(ADC_SAMPLES_PER_WORD*ADC_BITS_PER_SAMPLE-1 downto 0); -- ADC samples (first sample in MSBs)
        s_axis_adc_tvalid: in std_logic;
        s_axis_adc_tuser: in std_logic_vector(ADC_SAMPLES_PER_WORD-1 downto 0); --  Contains one overflow bit per samples (first sample in MSB).
        s_axis_adc_tlast: in std_logic;

        -- Output data interface

        m_axis_adc_tdata: out std_logic_vector(ADC_SAMPLES_PER_WORD*ADC_BITS_PER_SAMPLE-1 downto 0);
        m_axis_adc_tvalid: out std_logic;
        m_axis_adc_tuser: out std_logic_vector(0 downto 0); --  Contains one overflow bit per frame on TLAST.
        m_axis_adc_tlast: out std_logic;

        clk     : in  std_logic;            --! clock for both input and output streams
        rst     : in  std_logic;            --! synchronous reset

        -- BSB Control Interface (command and reply stream buses)

        ctrl_cmd_in_dat     : in  AXIS8_DAT_STRUCT;
        ctrl_cmd_in_rdy     : out AXIS8_RDY_STRUCT;
        ctrl_rply_out_dat   : out AXIS8_DAT_STRUCT;
        ctrl_rply_out_rdy   : in  AXIS8_RDY_STRUCT;
        ctrl_clk            : in  std_logic;
        ctrl_rst            : in  std_logic
    );
end FUNCGEN;

architecture impl of FUNCGEN is

-- Data Sources
subtype  FN_TYPE is std_logic_vector(2 downto 0);
constant FN_ADC                      : FN_TYPE:="000"; -- ADC input
constant FN_RAM                      : FN_TYPE:="001"; -- Outputs RAM contents (2048 bytes, 512 words)
constant FN_NOISE                    : FN_TYPE:="010"; -- noise
constant FN_FRAME_WORD_CTR_RAM_FLAGS : FN_TYPE:="011"; -- Counts frames and words, and ADC flags is set from RAM bit 0 writes page 1 (bytes 512-1023)
constant FN_FRAME8                   : FN_TYPE:="100"; -- Current frame number in each 8-bit sample
constant FN_FRAME4                   : FN_TYPE:="101"; -- Current frame number in the upper 4-bit of each sample (lower bits are zero)
constant FN_RAM_NIBBLE4              : FN_TYPE:="110"; -- Current frame number in the upper 4-bit of each sample (lower bits are zero)
constant FN_UNUSED                   : FN_TYPE:="111"; -- Unused

constant WORDS_PER_FRAME: integer := ADC_SAMPLES_PER_FRAME / ADC_SAMPLES_PER_WORD;
constant LOG2_WORDS_PER_FRAME: integer := integer_log2(WORDS_PER_FRAME); --! Number of words per frame. One word is 4 8-bit time samples or 2 8+8-bits frequency samples.
constant LOG2_ADC_SAMPLES_PER_FRAME: integer := integer_log2(ADC_SAMPLES_PER_FRAME);
constant BYTES_PER_SAMPLE: integer := integer(ceil(real(ADC_BITS_PER_SAMPLE) / 8.0));
constant BYTES_PER_FRAME: integer := ADC_SAMPLES_PER_FRAME * BYTES_PER_SAMPLE;
constant LOG2_BYTES_PER_FRAME: integer := integer_log2(BYTES_PER_FRAME);
constant CMD_ADDR_WIDTH: integer := 9; -- Number of usable address bits in the command (the upper bits have been used for routing)
constant BITS_PER_WORD: integer := ADC_SAMPLES_PER_WORD * ADC_BITS_PER_SAMPLE;

signal in_dat_tdata: std_logic_vector(ADC_SAMPLES_PER_WORD*ADC_BITS_PER_SAMPLE-1 downto 0);
signal in_dat_tuser: std_logic_vector(ADC_SAMPLES_PER_WORD - 1 downto 0); -- one overflow bit per sample
signal in_dat_tvalid: std_logic;
signal in_dat_tlast: std_logic;

-- Output if the selected function
signal out_dat_tdata: std_logic_vector(ADC_SAMPLES_PER_WORD*ADC_BITS_PER_SAMPLE-1 downto 0);
signal out_dat_tuser: std_logic_vector(0 downto 0); -- one overflow bit per frame on TLAST
signal out_dat_tvalid: std_logic;
signal out_dat_tlast: std_logic;
signal out_dat_tfirst: std_logic;
signal out_dat_overflows: std_logic_vector(ADC_SAMPLES_PER_WORD-1 downto 0):= (others => '0');

-- Output of the data shifter
signal out_dat_shifted_tdata: std_logic_vector(ADC_SAMPLES_PER_WORD*ADC_BITS_PER_SAMPLE-1 downto 0);
signal out_dat_shifted_tuser: std_logic_vector(0 downto 0);
signal out_dat_shifted_tvalid: std_logic;
signal out_dat_shifted_tlast: std_logic;


-- Word counter
signal word_ctr_pre2: unsigned(LOG2_WORDS_PER_FRAME-1 downto 0) := (others=>'0'); -- Counts words from 0 to FRAME_LENGTH/4-1
signal word_ctr_pre1: unsigned(LOG2_WORDS_PER_FRAME-1 downto 0) := (others=>'0'); -- Counts words from 0 to FRAME_LENGTH/4-1
signal word_valid_pre1: std_logic;
signal word_ctr: std_logic_vector(LOG2_WORDS_PER_FRAME-1 downto 0) := (others=>'0'); -- Counts words from 0 to FRAME_LENGTH/4-1
signal word_valid, word_last: std_logic;

signal frame_ctr: unsigned(31-LOG2_WORDS_PER_FRAME downto 0); -- Counts frame from 0 to FRAME_LENGTH/4-1. Concatenation of word_ctr & frame_ctr is always 32 bits.
signal send_frame: std_logic;

-- Resets
signal reset_all, reset_all_reg: std_logic;
signal soft_reset: std_logic:= '0';

-- Control and status bytes

signal control_bytes: slv8_array(0 to 7); -- default value set in the CMD_SLAVE
signal status_bytes: slv8_array(0 to 8);

signal byte_a: slv8;
signal byte_b: slv8;
signal byte_c: slv8;

signal shift: unsigned(3 downto 0);
signal clip_width: unsigned(3 downto 0);

signal fn_sel: FN_TYPE;

signal overflow_ctr_period: unsigned(15 downto 0); -- Number of frames over which to count the number of sample overflows
signal enable, enable_resync: std_logic;

signal ram_page: std_logic_vector(6 downto 0); -- combined ram_page_msb and _lsb. 7 bits, more than we need. 9 bits BSB RAM addr + 7 bits page = 16 bit address = 65536 bytes.

signal frame_overflow_flag: std_logic;

-- Input interface to the RAM is always 8 bit.
signal ram_ctrl_addr: std_logic_vector(CMD_ADDR_WIDTH-1 downto 0); -- 2048 bytes x 2
signal ram_ctrl_wr_en: std_logic;
signal ram_ctrl_din: std_logic_vector(7 downto 0);
signal ram_ctrl_dout: std_logic_vector(7 downto 0);

-- RAM Output word, in the same packing format as the function generator input/output word.
signal ram_dout: std_logic_vector(BITS_PER_WORD-1 downto 0);

signal delay_capture_ctr: unsigned(15 downto 0);
signal overflow_ctr, overflow_ctr_reg: unsigned(31 downto 0):= (others => '0');
signal stats_enable, stats_enable_resync: std_logic;
signal stats_done: std_logic:= '0';
signal overflow_frame_ctr: unsigned(15 downto 0):= (others => '0');

-- LFSR
signal lsfr_in: std_logic_vector(31 downto 0); -- seed for lfsr
signal lfsr_out: std_logic_vector(ADC_SAMPLES_PER_WORD*ADC_BITS_PER_SAMPLE-1 downto 0):= (others=>'0'); --output from lfsr
signal rst_lfsr: std_logic;

begin
-----------------------------------------------------------------------------------
-- CONTROL and STATUS Bytes
-----------------------------------------------------------------------------------
-- Function Generator Memory Map
--
--  ------------------------------------------------------------------------------
-- |  Page   | Addr|Bit(s)|     Name             | Description                   |
-- |---------|-----|------|----------------------|-------------------------------|
-- | CONTROL |  0  |   7  | soft_reset           |                               |
-- |         |     |   6  | enable               | if '1', funcgen continuously generate frame. If '0', stop generating frame and resets the frame counter.|
-- |         |     |  5:3 | ram_page[2:0]        | LSB of the RAM page number. Each page can address 512 bytes in RAM memory space |
-- |         |     |  2:0 | fn_sel               |   |
-- |         |  1  |  7:0 | byte_a               | Byte A, used as parameters in some functions |
-- |         |  2  |  7:0 | byte_b               | Byte B, used as parameters in some functions |
-- |         | 3-4 | 15:0 | stats_period         | Number of frames during which the number of sample overflows is counted.
-- |         |  5  |  7:4 | ram_page[6:3]        | MSB of the RAM page number |
-- |         |     |  3:0 | shift                | Number of bits to right-shift the output data |
-- |         |  6  |  7   | stats_enable         | Enables overflow_ctr update. Clears stats_done when stats_enabled cleared.|
-- |         |     |  6   | rst_lfsr             | Resets seed and output of LFSR |
-- |         |     |  5:4 | (unused)             | |
-- |         |     |  3:0 | clip_width           | Saturates the output data to a ``clip_width-1``-bit wide signed value (i.e. clip_width is the position of the sign bit). Saturation is applied after the right-shift. |
-- |         |  7  |  7:0 | function_number      | Function number stored in buffer. Doesn't change waveform.
-- | STATUS  |  0  |  7:0 | word_ctr_pre2        | Last 8 bits of the word counter |
-- |         |  1  |  7:0 | frame_ctr            | Last 8 bits of the frame counter |
-- |         |  2  |  7:3 | (unused)             | |
-- |         |  2  |  2   | frame_overflow_flag  | Indicates if there is at least an adc overflow in current frame.
-- |         |  2  |  1   | stats_done           | overflow_ctr ready with new value for new integration period
-- |         |     |  0   | send_frame           | High when frame sending is enabled |
-- |         | 3-4 | 15:0 | delay_capture_ctr    | Delay capture value. |
-- |         | 5-8 | 31:0 | overflow_ctr         | Number of samples that are saturated over ``overflow_ctr_period``. The maximum number is bigger than possible amount of overflows over any initegration period, so no saturation. |
--  ------------------------------------------------------------------------------


-- CONTROL Byte 0
soft_reset   <= control_bytes(0)(7);
enable       <= control_bytes(0)(6);
ram_page(2 downto 0) <= control_bytes(0)(5 downto 3); -- 3 least significant bits of the page register
fn_sel       <= FN_TYPE(control_bytes(0)(2 downto 0)); --

-- CONTROL Bytes 1-2: Bytes A and B
byte_a <= control_bytes(1);
byte_b <= control_bytes(2);

-- CONTROL Byte 3 and 4
overflow_ctr_period <= to_unsigned(control_bytes(3 to 4));

-- CONTROL Bytes 4: Byte C
byte_c <= control_bytes(4);

-- CONTROL Bytes 5: RAM page and bit shift
ram_page(6 downto 3) <= control_bytes(5)(7 downto 4); -- 4 most significant bits of the page register
shift <= unsigned(control_bytes(5)(3 downto 0));

-- CONTROL Bytes 6: Saturation width and overrange count reset
stats_enable <= control_bytes(6)(7);
rst_lfsr  <= control_bytes(6)(6);
clip_width <= unsigned(control_bytes(6)(3 downto 0));

-- CONTROL Bytes 7: User defined function number


-- STATUS Byte 0
status_bytes(0) <= std_logic_vector(lsb(word_ctr_pre2));

-- STATUS Byte 1
status_bytes(1) <= std_logic_vector(lsb(frame_ctr));

-- STATUS Byte 2
status_bytes(2)(2) <= frame_overflow_flag;
status_bytes(2)(1) <= stats_done;
status_bytes(2)(0) <= send_frame;

-- STATUS Byte 3-4
status_bytes(3 to 4) <= to_slv8_array(delay_capture_ctr);

-- STATUS Byte 5
status_bytes(5 to 8) <= to_slv8_array(overflow_ctr_reg);

--ram_page <= ram_page_msb & ram_page_lsb;

-----------------------------------------------------------------------------------
-- Memory-Mapped interface instantiation
-----------------------------------------------------------------------------------
-- Instantiates the memory-mapped registers
CTRL_SLAVE0: entity work.CTRL_SLAVE
    GENERIC MAP (
        NUMBER_OF_CONTROL_BYTES => control_bytes'Length(1), --
        NUMBER_OF_STATUS_BYTES  => status_bytes'Length(1), --
        DEFAULT_CONTROL_BYTES   => X"40" & -- Byte 0: soft_reset, enable, ram_page[2:0], fn_sel[2:0]
                                   X"0101" & -- Bytes 1-2: Byte A & Byte B
                                   X"0000" & -- Byte 3-4: overflow_ctr_period
                                   X"00" & -- Byte 5: ram_page[6:3], shift[3:0]
                                   X"8F" & -- Byte 6: stats_enable, rst_lfsr, unused[1:0], clip_width[3:0]
                                   X"00", --Byte 7: User defined function number
        ADDR_WIDTH              => 9, -- We have 9 bits of data left after routing
        RAM_DATA_WIDTH          => 8, -- 8 or 16 bits
        RAM_ADDR_WIDTH          => CMD_ADDR_WIDTH, -- Cannot exceed 9 bits with 8-bit data width because higher bits are used for routing
        RAM_LATENCY             => 2
        )
    PORT MAP(
        -- Control interface (command and reply stream buses)
        CTRL_CMD_IN_DAT   => ctrl_cmd_in_dat,
        CTRL_CMD_IN_RDY   => ctrl_cmd_in_rdy,
        CTRL_RPLY_OUT_DAT => ctrl_rply_out_dat,
        CTRL_RPLY_OUT_RDY => ctrl_rply_out_rdy,
        CTRL_CLK          => ctrl_clk,
        CTRL_RST          => ctrl_rst,

        control_bytes     => control_bytes,
        status_bytes      => status_bytes,

        RAM_DIN   => ram_ctrl_din,
        RAM_DOUT  => ram_ctrl_dout,
        RAM_ADDR  => ram_ctrl_addr,
        RAM_WR_EN => ram_ctrl_wr_en,
        RAM_RD_EN => open -- the ram is always reading
        );

lsfr_in <= (byte_a & byte_b & not byte_a & not byte_b); -- guaranteed to be non-zero
--Instantiate LFSR used as a noise generator. Seed is 32 bit and output is the size of a word
lfsr: entity work.lfsr
    generic map (
        DATA_WIDTH => ADC_SAMPLES_PER_WORD * ADC_BITS_PER_SAMPLE
        )
    port map(
        seed => lsfr_in,
        output => lfsr_out,
        rst => rst_lfsr or reset_all,
        clk => clk
    );



---------------------------------------------
-------- Main process -----------------------
---------------------------------------------


-- Resync the stats_enable from the BSB clock to the data clock. Without it, all bits of the the
-- overflow counter might not be frozen at the same time, causing readout glitches.
stats_enable_cdc0: xpm_cdc_single
		generic map (SRC_INPUT_REG => 0)
		port map (src_clk => '0', src_in => stats_enable, dest_clk => clk, dest_out => stats_enable_resync);

-- Resync the enable signal from the BSB clock to the data clock.
enable_cdc0: xpm_cdc_single
        generic map (SRC_INPUT_REG => 0)
        port map (src_clk => '0', src_in => enable, dest_clk => clk, dest_out => enable_resync);

funcgen_proc: process (clk)
    variable int_shift: integer;
    variable int_clip_width: integer range 0 to 15;
    variable new_overflow_ctr: unsigned(overflow_ctr'RANGE);
    variable use_ram_overflow: boolean := FALSE;
    variable sample_var: signed(ADC_BITS_PER_SAMPLE-1 downto 0);

    begin
        if rising_edge(clk) then
            reset_all <= soft_reset or rst;
            reset_all_reg <= reset_all; -- pipeline

            -------------------------------------------------------------
            -- PHASE 0:
            --    - pipeline input
            --    - count words
            --    - RAM read address is clocked in
            -------------------------------------------------------------

            in_dat_tdata <= s_axis_adc_tdata;
            in_dat_tuser <= s_axis_adc_tuser;
            in_dat_tvalid <= s_axis_adc_tvalid;
            in_dat_tlast <= s_axis_adc_tlast;

            -- Count words
            word_ctr_pre2 <= word_ctr_pre2 + 1;
            -------------------------------------------------------------
            -- PHASE 1:
            --    - Delay word counter
            -------------------------------------------------------------
            word_ctr_pre1 <= word_ctr_pre2;
            word_valid_pre1 <= '1';

            -------------------------------------------------------------
            -- PHASE 2:
            --    - word_ctr, word_valid, word_last
            --    - frame_ctr: frame number of current word number
            --    - ram_dout: RAM data for current word number/word address
            --    - send_frame: High for all words of frame when transmit is enabled
            -------------------------------------------------------------

            word_ctr <= std_logic_vector(word_ctr_pre1); -- This is aligned with the RAM output
            word_valid <= word_valid_pre1;
            word_last <= to_std_logic(all_ones(word_ctr_pre1));

            if word_valid and word_last then
                frame_ctr <= frame_ctr + 1 when enable_resync else (others => '0'); -- count frames
                send_frame <= enable_resync; -- register enable on frame boundaries
            end if; -- last word

            -------------------------------------------------------------
            -- PHASE 3:
            --    - out_dat_tvalid, tlast, tdata, overflows
            --
            -- These are generally computed from PHASE 2 signals (word_ctr/valid/last, frame_ctr, ram_dout) unless we use ADC data.
            -------------------------------------------------------------

            -- Default ouputs. Overriden below as needed.
            out_dat_overflows <= (others => '0');
            out_dat_tvalid <= word_valid and send_frame;
            out_dat_tlast <= word_last;

            -- Set output data
            case fn_sel is

                when FN_ADC =>
                    -- Completely override bus with pipeline ADC data.
                    -- This is nor frame-aligned with word_ctr or ram_dout since we don't know when the ADC tvalid came out.
                    -- So there's no issue using data from PHASE 0.
                    out_dat_tdata <= in_dat_tdata;
                    out_dat_tvalid <= in_dat_tvalid;
                    out_dat_tlast <= in_dat_tlast;
                    out_dat_overflows <= in_dat_tuser;

                when FN_RAM =>
                    out_dat_tdata <= ram_dout; -- Byte at address 0 is in the MSB

                -- Send bits 3:0 of RAM samples on even frames an bits 7:4 of RAM samples on odd frames.
                -- Data is aligned on the 4 MSBs of each sample.
                when FN_RAM_NIBBLE4 =>
                    out_dat_tdata <= (others => '0');
                    for i in 0 to ADC_SAMPLES_PER_WORD-1 loop
                        if frame_ctr(0)='0' then
                            out_dat_tdata(ADC_BITS_PER_SAMPLE*(i+1)-1 downto ADC_BITS_PER_SAMPLE*(i+1)-4) <= ram_dout(ADC_BITS_PER_SAMPLE*i+3 downto ADC_BITS_PER_SAMPLE*i);
                        else
                            out_dat_tdata(ADC_BITS_PER_SAMPLE*(i+1)-1 downto ADC_BITS_PER_SAMPLE*(i+1)-4) <= ram_dout(ADC_BITS_PER_SAMPLE*i+7 downto ADC_BITS_PER_SAMPLE*i+4);
                        end if;
                    end loop;

                -- Send peudo-random noise on all samples.
                -- The 32-bit bits of the PNRG is distributed on the MSB of all samples, and the samples are right-shifted by the value in byte_c.
                when FN_NOISE =>
                    out_dat_tdata <= lfsr_out;

                when FN_FRAME_WORD_CTR_RAM_FLAGS =>
                    out_dat_tdata <= (others => '0');
                    out_dat_tdata(31 downto 0) <= to_slv(frame_ctr) & word_ctr; -- store frame & word counter only in the lower 32 bits.
                    use_ram_overflow := TRUE; -- take overflow bit from RAM

                -- Send the The ADC_BITS_PER_SAMPLE-2 LSBs of the frame counter on every sample of the frame
                when FN_FRAME8 =>
                    for i in 0 to ADC_SAMPLES_PER_WORD-1 loop
                        out_dat_tdata(ADC_BITS_PER_SAMPLE*(i+1)-1 downto ADC_BITS_PER_SAMPLE*i) <= to_slv(frame_ctr(ADC_BITS_PER_SAMPLE-3 downto 0)) & "00";
                    end loop;
                    use_ram_overflow := TRUE; -- take overflow bit from RAM

                -- Send the 4 LSBs of the frame counter on the upper 4 MSBs of each sample in the frame
                when FN_FRAME4 =>
                    out_dat_tdata <= (others => '0');
                    for i in 0 to ADC_SAMPLES_PER_WORD-1 loop
                        out_dat_tdata(ADC_BITS_PER_SAMPLE*(i+1)-1 downto ADC_BITS_PER_SAMPLE*(i+1)-4) <= to_slv(frame_ctr(3 downto 0));
                    end loop;
                    use_ram_overflow := TRUE; -- take overflow bit from RAM

                when others =>
                    out_dat_tdata <= (others=>'0');
            end case;

            -- Take overflow bits from RAM if requested by the selected mode
            -- (Used in FN_FRAME_WORD_CTR_RAM_FLAGS, FRAME8 and FRAME4).
            -- Overflow bit is stored in Bit 0 of each RAM sample.
            -- MSB of out_dat_overflows is the overflow bit of first sample, i.e. overflow bits are in the same order as samples in ram_dout.
            if use_ram_overflow then
                for i in ADC_SAMPLES_PER_WORD-1 downto 0 loop
                    out_dat_overflows(i) <= ram_dout(ADC_BITS_PER_SAMPLE*i);
                end loop; --overflow count per word
            end if; -- use_ram_overflow

            -- Overflow statistics: count number of overflows within a programmable period
            if out_dat_tvalid then
                new_overflow_ctr := overflow_ctr + to_unsigned(num_ones(out_dat_overflows), overflow_ctr'LENGTH);
                overflow_ctr <= new_overflow_ctr; --overidden below when last word of integration period
                if out_dat_tlast then
                    overflow_frame_ctr <= overflow_frame_ctr + 1;
                    if overflow_frame_ctr = overflow_ctr_period then
                        overflow_ctr_reg <= new_overflow_ctr when stats_enable_resync;
                        overflow_ctr <= (others => '0');
                        overflow_frame_ctr <= (others => '0');
                        stats_done <= '1'; -- indicate we have new updated data but continue counting and updating
                    end if; --end of integration period
                end if; -- tlast
            end if; -- tvalid
            stats_done <= '0' when not stats_enable_resync; -- clear stats_done whenever we freeze statistics update for readout

            ---------------------------------------------------------------------
            -- PHASE 4:
            --   - out_dat_shifted
            --   - frame overflow flag in out_dat_shifted_tuser
            ---------------------------------------------------------------------


            -- Implement data shifting (digital attenuation)
            int_shift := to_integer(shift);
            for j in 0 to ADC_SAMPLES_PER_WORD-1 loop
                sample_var := signed(out_dat_tdata(ADC_BITS_PER_SAMPLE*(j+1)-1 downto ADC_BITS_PER_SAMPLE*j));
                out_dat_shifted_tdata(ADC_BITS_PER_SAMPLE*(j+1)-1 downto ADC_BITS_PER_SAMPLE*j) <= std_logic_vector(shift_right(sample_var, int_shift));
            end loop;
            out_dat_shifted_tvalid <= out_dat_tvalid;
            out_dat_shifted_tlast <= out_dat_tlast;

            -- Keep track of the frame-wide ADC overflow flag to be passed into TUSER on last word of frame
            if out_dat_tvalid then
                out_dat_tfirst <= out_dat_tlast;
                out_dat_shifted_tuser(TUSER_ADC_OVERFLOW_BIT) <= or(out_dat_overflows) when out_dat_tfirst else
                                       out_dat_shifted_tuser(TUSER_ADC_OVERFLOW_BIT) or or(out_dat_overflows);
            end if; -- in_dat_tvalid

            -- Implement data clipping and assign output
            int_clip_width := to_integer(clip_width);
            m_axis_adc_tdata  <= out_dat_shifted_tdata; -- default value, overriden below if we clip.
            if int_clip_width /= 15 then
                for j in 0 to ADC_SAMPLES_PER_WORD-1 loop
                    sample_var := signed(out_dat_shifted_tdata(ADC_BITS_PER_SAMPLE*(j+1)-1 downto ADC_BITS_PER_SAMPLE*j));
                    m_axis_adc_tdata(ADC_BITS_PER_SAMPLE*(j+1)-1 downto ADC_BITS_PER_SAMPLE*j) <= std_logic_vector(clip(sample_var, int_clip_width));
                end loop;
            end if; -- if we clip
            m_axis_adc_tvalid <= out_dat_shifted_tvalid;
            m_axis_adc_tuser <= out_dat_shifted_tuser;
            m_axis_adc_tlast <= out_dat_shifted_tlast;


            -- Synchronous resets -- override signals above
            if reset_all then -- Synchronous reset
                word_ctr_pre2 <= (others=>'0');
                word_ctr_pre1 <= (others=>'0');
                word_valid_pre1 <= '0';
                word_ctr <= (others=>'0');
                word_valid <= '0';
                frame_ctr <= (others=>'0');
                send_frame <= enable;
                out_dat_tvalid <= '0';
                out_dat_tfirst <= '1'; -- set to '0' to skip the first frame after reset
                out_dat_shifted_tvalid <= '0';

                -- Overflow statistics
                overflow_frame_ctr <= (others => '0');
                stats_done <= '0';
                overflow_ctr <= (others => '0');
                overflow_ctr_reg <= (others => '0');
             end if; -- reset_all

            if reset_all_reg='1' then
                m_axis_adc_tvalid <= '0'; -- needed
            end if; -- reset_all_reg

        end if; -- CLK
end process;

-- Optional delay capture
delaycap_gen: if IMPLEMENT_DELAY_CAPTURE generate
    signal delay_capture_ctr_en: std_logic :='0';
begin
    -- STATUS Byte 3-4
    delaycap_proc: process (clk)
    begin
        if reset_all ='1' then
            delay_capture_ctr <= (others=> '0');
            delay_capture_ctr_en <= '1';
        elsif delay_capture_ctr_en = '1'  then
            delay_capture_ctr <= delay_capture_ctr + 1;
            if signed(delay_capture_ctr)=-2 or (s_axis_adc_tvalid='1' and (byte_a(0)='0' or s_axis_adc_tlast='1')) then
                delay_capture_ctr_en <= '0';
            end if;
        end if;
    end process;
end generate delaycap_gen;

ram_blk: block is


    signal ram_addr: std_logic_vector(LOG2_WORDS_PER_FRAME-1 downto 0);

    signal ram_ctrl_addr_paged: std_logic_vector(LOG2_BYTES_PER_FRAME-1 downto 0); -- 2048 bytes x 2

    -- Intermediary RAM output words used to repack the word in the extected format.
    -- We make sure the those are a multiple of 8 bits so the packing order of the input bytes
    -- into the output word is easier to understand.
    signal ram_dout_int1, ram_dout_int2: std_logic_vector(8*BYTES_PER_SAMPLE*ADC_SAMPLES_PER_WORD-1 downto 0);
begin


    -- Reorder RAM output word so samples appear in the expected order with the expected width
    -- Data is written byte-wise but read word-wise.
    -- If we want to write the following 14-bit values (0,1,2 , ... 7). We write them as big-endian 16-bit data, MSB-aligned (i.e we multiply the values by 4)
    --    Bytes at address 0-15: 00 00 00 04 00 08 00 0c 00 10 00 14 00 18 00 1C
    -- Ram output word will be, at address 0:
    --    ram_dout_int1 = 1C00_1800_1400_1000_0C00_0800_0400_0000 (128 bit value, MSB on the left)
    -- We reverse bytes so the first value is in the MSBs
    --    ram_dout_int2 = 0000_0004_0008_000c_0010_00014_00018_001C (128 bit value, MSB on the left)
    -- We then extract the top ADC_BITS_PER_SAMPLE bits into dout
    --    ram_dout = 000_001_002_003_004_005_006_007 (8*14=112 bit value, MSB on the left, only 12 bits/sample shown here in hex for clarity)
    ram_dout_int2 <= reverse_bytes(ram_dout_int1); -- reorder so byte 0 is in the MSB of word 0
    reorder_gen: for j in 0 to ADC_SAMPLES_PER_WORD-1 generate
        ram_dout(ADC_BITS_PER_SAMPLE*(j+1)-1 downto ADC_BITS_PER_SAMPLE*j) <= ram_dout_int2(8*BYTES_PER_SAMPLE*(j+1)-1 downto 8*BYTES_PER_SAMPLE*(j+1)-ADC_BITS_PER_SAMPLE);
    end generate;

    -- ram_ctrl_addr_paged(11 downto 9) <= ram_ctrl_addr(11 downto 9) or ram_page;
    ram_ctrl_addr_paged(LOG2_BYTES_PER_FRAME-1 downto CMD_ADDR_WIDTH) <= ram_page(LOG2_BYTES_PER_FRAME-CMD_ADDR_WIDTH-1 downto 0);
    ram_ctrl_addr_paged(CMD_ADDR_WIDTH-1 downto 0) <= ram_ctrl_addr(8 downto 0);
    ram_addr <= std_logic_vector(word_ctr_pre2);

    -- Instantiate block RAM that will contain the user-programmable waveforms
    -- xpm_memory_tdpram: True Dual Port RAM
    -- Xilinx Parameterized Macro, version 2022.2
    -- RAM has a read latency of 2 clocks
    ram0 : xpm_memory_tdpram
        generic map (
            WRITE_DATA_WIDTH_A => 8,        -- DECIMAL
            BYTE_WRITE_WIDTH_A => 8,        -- DECIMAL
            READ_DATA_WIDTH_A => 8,         -- DECIMAL
            ADDR_WIDTH_A => LOG2_BYTES_PER_FRAME,
            READ_LATENCY_A => 2,             -- DECIMAL

            WRITE_DATA_WIDTH_B => 8*BYTES_PER_SAMPLE*ADC_SAMPLES_PER_WORD, -- BITS_PER_WORD,
            BYTE_WRITE_WIDTH_B => 8*BYTES_PER_SAMPLE*ADC_SAMPLES_PER_WORD, --BITS_PER_WORD,
            READ_DATA_WIDTH_B => 8*BYTES_PER_SAMPLE*ADC_SAMPLES_PER_WORD, --BITS_PER_WORD,
            ADDR_WIDTH_B => LOG2_WORDS_PER_FRAME,
            READ_LATENCY_B => 2,             -- DECIMAL

            CLOCKING_MODE => "independent_clock",
            MEMORY_PRIMITIVE => "block",

            MEMORY_SIZE => 8 * BYTES_PER_FRAME,

            USE_EMBEDDED_CONSTRAINT => 0,    -- DRC says 1 is only for distributed RAM

            MEMORY_OPTIMIZATION => "true",   -- String
            MESSAGE_CONTROL => 1,            -- for sims

            SIM_ASSERT_CHK => 0,             -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
            USE_MEM_INIT => 0,               -- DECIMAL
            WRITE_MODE_A => "no_change",     -- String
            WRITE_MODE_B => "no_change",     -- String
            WRITE_PROTECT => 1               -- DECIMAL
        )
        port map (
            addra => ram_ctrl_addr_paged,                   -- ADDR_WIDTH_A-bit input: Address for port A write and read operations.
            dina => ram_ctrl_din,                     -- WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
            douta => ram_ctrl_dout,                   -- READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
            ena => '1',                       -- 1-bit input: Memory enable signal for port A. Must be high on clock
            wea(0) => ram_ctrl_wr_en,
            clka => ctrl_clk,                     -- 1-bit input: Clock signal for port A. Also clocks port B when
            rsta => ctrl_rst,                     -- 1-bit input: Reset signal for the final port A output register

            addrb => ram_addr,                   -- ADDR_WIDTH_B-bit input: Address for port B write and read operations.
            dinb => (others=>'0'),                     -- WRITE_DATA_WIDTH_B-bit input: Data input for port B write operations.
            doutb => ram_dout_int1,                   -- READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
            enb => '1',                       -- 1-bit input: Memory enable signal for port B. Must be high on clock
            web(0) => '0',                       -- WRITE_DATA_WIDTH_B/BYTE_WRITE_WIDTH_B-bit input: Write enable vector
            clkb => clk,                     -- 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
            rstb => reset_all_reg,                     -- 1-bit input: Reset signal for the final port B output register
                                            -- cycles when read or write operations are initiated. Pipelined
            injectdbiterra => '0', -- 1-bit input: Controls double bit error injection on input data when
            injectdbiterrb => '0', -- 1-bit input: Controls double bit error injection on input data when
            injectsbiterra => '0', -- 1-bit input: Controls single bit error injection on input data when
            injectsbiterrb => '0', -- 1-bit input: Controls single bit error injection on input data when

            regcea => '1',                 -- 1-bit input: Clock Enable for the last register stage on the output
            regceb => '1',                 -- 1-bit input: Clock Enable for the last register stage on the output
            sleep => '0'                   -- 1-bit input: sleep signal to enable the dynamic power saving feature.

        );
end block ram_blk;



end impl;
