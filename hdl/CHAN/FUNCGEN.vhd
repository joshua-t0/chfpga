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

------ FUNCGEN Entity -------------
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
-- The output of FUNCGEN is also a non-blocking AXI4-Streaming bus and has the same structure as the input, except for the ``TUSER`` signal.
-- ``TUSER`` is a 1-bit vector containing the following information:
--   - Bit 0: (TUSER_ADC_OVERFLOW_BIT): Set on the last word of a frame (i.e. valid only when TLAST=1) to indicate if an ADC saturation has occured on any sample of the frame.
--
-- Operation modes
-- ---------------
--
-- The output of the FUNCGEN module is selected by the 3-bit `fn_sel` memory-mapped field. The supported modes are:
--  - 0 / FN_ADC: Passes on the ADC input. The ADC overflow bits are aggregated througout the frame
--    and the resulting TUSER_ADC_OVERFLOW_BIT TUSER but is provided on the last frame.
--
--  - 1 / FN_RAM: Outputs the RAM contents (2048 bytes, 512 words). TUSER_ADC_OVERFLOW_BIT is always zero.
--
--  - 2 / FN_NOISE: Outputs Pseudo-Random noise. TUSER_ADC_OVERFLOW_BIT is always zero. The noise
--    generator is seeeded by the 8-bit A and B fields to allow each channelizer to have up to 65536
--    different (presumamly uncorrelated) patterns.
--
--  - 3 / FN_FRAME_WORD_CTR_RAM_FLAGS: Counts frames and words, with programmable ADC overflow bit
--    patterns. This mode is mostly used for testing. The output data is grouped in 32-bit words,
--    containing a 23-bit frame count in the MSB followed bit 9-bit word count (0-511). This pattern
--    does not generate nice data when splitted in 4-bytes (and even less when going through the
--    FFT), but it ensures that consecutive frames will contain unique data when looked word-wise.
--    In that mode, the ADC overflow flag of each sample is taken from the RAM bit 0.
--
--  - 4 / FN_FRAME8: Each sample is the last 8 bits of the current frame number.
--    TUSER_ADC_OVERFLOW_BIT is always zero.
--
--  - 5 / FN_FRAME4: The most significant 4 bits of each sample is the last 4 bits of the current
--    frame number. The lower 4 bits are zero. TUSER_ADC_OVERFLOW_BIT is always zero.
--
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
-- The noise is generated as a 32-bit output CRC generator fed by the 8-bit A and B signals (the
-- 32-bit input is a combination of A, B, not A, and not B). These A and B parameters act as seed.
-- The same A and B value will always result in the same sequence.
--
-- The 32-bit output values generated bu the CRC32 are simply distributed
-- amongst the 4 samples.
--
-- We have not analyzed the entropy of this generator, nor how uncorrelated the outputs are, or
-- whether some seed values are better than other. Is it ok to assume that 8-bit portions of the
-- 32-bit word are uncorrelated with others? Will some seeds provide extremely bad entropy?
--
-- The conclusion here is that the noise generator is an experimental feature that might be useful
-- but needs to be tested.
--

--Overflow counter
-- ---------------
--
-- The overflow counter counts over ```stats_period```(user defined) frames the number of sample overflows from the ADC or the number of overflows injected through the buffer (either from modes FN_FRAME_WORD_CTR_RAM_FLAGS, FN_FRAME8 or FN_FRAME4). The overflow count for other modes (FN_RAM, FN_NOISE, FN_RAM_NIBBLE4) is 0. The maximum number of frames over which to count the number of overflows is 65535. When counting overflows from the buffer, each sample's LSB indicate if there is an overflow or not, so to simulate an overflow in a sample, set the sample value to 1. Overflow counting is enabled with ```stats_enable``` and the result can be read from ```overflow_ctr```. 


entity FUNCGEN is
    generic (
        ADC_SAMPLES_PER_WORD: integer := 8;
        ADC_BITS_PER_SAMPLE: integer := 14;
        FUNCGEN_TUSER_BITS_PER_WORD: integer := 1;
        ADC_SAMPLES_PER_FRAME: integer := 16384;
        IMPLEMENT_DELAY_CAPTURE: boolean := FALSE
    );
    port (

        -- ADC data input stream (AXI-Streaming, non blocking)

        s_axis_adc_tdata: in std_logic_vector(ADC_SAMPLES_PER_WORD*ADC_BITS_PER_SAMPLE-1 downto 0);
        s_axis_adc_tvalid: in std_logic;
        s_axis_adc_tuser: in std_logic_vector(ADC_SAMPLES_PER_WORD-1 downto 0); --  Contain an overflow bit flag for group of samples.
        s_axis_adc_tlast: in std_logic;
        trig    : in std_logic := '1';

        -- Output data interface

        m_axis_adc_tdata: out std_logic_vector(ADC_SAMPLES_PER_WORD*ADC_BITS_PER_SAMPLE-1 downto 0);
        m_axis_adc_tvalid: out std_logic;
        m_axis_adc_tuser: out std_logic_vector(FUNCGEN_TUSER_BITS_PER_WORD-1 downto 0); --  Contain an overflow bit flag for group of samples.
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
signal in_dat_tuser: std_logic_vector(ADC_SAMPLES_PER_WORD-1 downto 0);
signal in_dat_tvalid: std_logic;
signal in_dat_tlast: std_logic;

signal out_dat_tdata: std_logic_vector(ADC_SAMPLES_PER_WORD*ADC_BITS_PER_SAMPLE-1 downto 0);
signal out_dat_tuser: std_logic_vector(FUNCGEN_TUSER_BITS_PER_WORD-1 downto 0);
signal out_dat_tvalid: std_logic;
signal out_dat_tlast: std_logic;


-- Control and status bytes
signal control_bytes: slv8_array(0 to 7); -- default value set in the CMD_SLAVE
signal status_bytes: slv8_array(0 to 8);

signal byte_a: slv8;
signal byte_b: slv8;
signal byte_c: slv8;

signal shift: unsigned(3 downto 0);
signal clip_width: unsigned(3 downto 0);

signal fn_sel: FN_TYPE;
signal ramp_word_ctr: unsigned(LOG2_WORDS_PER_FRAME-1 downto 0) := (others=>'0'); -- Counts words from 0 to FRAME_LENGTH/4-1
signal ramp_word_ctr_dly: unsigned(LOG2_WORDS_PER_FRAME-1 downto 0) := (others=>'0'); -- Counts words from 0 to FRAME_LENGTH/4-1
signal word_ctr: std_logic_vector(LOG2_WORDS_PER_FRAME-1 downto 0) := (others=>'0'); -- Counts words from 0 to FRAME_LENGTH/4-1
-- signal use_overflow: std_logic;
signal reset_all, reset_all_reg: std_logic;
signal soft_reset: std_logic:= '0';
signal overflow_ctr_period: unsigned(15 downto 0); -- Number of frames over which to count the number of sample overflows
signal frame_ctr: unsigned(31-LOG2_WORDS_PER_FRAME downto 0); -- Counts frame from 0 to FRAME_LENGTH/4-1. Concatenation of word_ctr & frame_ctr is always 32 bits.
signal enable: std_logic;
signal send_frame: std_logic;
-- signal a_reg: std_logic_vector(LSFR_WIDTH-1 downto 0) := (others=>'0'); --lsfr register used for noise generation

--signal ram_page_lsb: std_logic_vector(2 downto 0); -- 3 bits
--signal ram_page_msb: std_logic_vector(3 downto 0); -- 4 bits
signal ram_page: std_logic_vector(6 downto 0); -- combined ram_page_msb and _lsb. 7 bits, more than we need. 9 bits BSB RAM addr + 7 bits page = 16 bit address = 65536 bytes.

signal frame_overflow_flag: std_logic;
signal capture_flag: std_logic;
signal adc_tfirst: std_logic;
signal ramp_tfirst: std_logic;
signal trig_reg: std_logic;

-- Input interface to the RAM is always 8 bit.
signal ram_ctrl_addr: std_logic_vector(CMD_ADDR_WIDTH-1 downto 0); -- 2048 bytes x 2
signal ram_ctrl_addr_paged: std_logic_vector(LOG2_BYTES_PER_FRAME-1 downto 0); -- 2048 bytes x 2
signal ram_ctrl_wr_en: std_logic;
signal ram_ctrl_din: std_logic_vector(7 downto 0);
signal ram_ctrl_dout: std_logic_vector(7 downto 0);

-- Output interface to the RAM
signal ram_addr: std_logic_vector(LOG2_WORDS_PER_FRAME-1 downto 0);
-- Intermediary RAM output words used to repack the word in the extected format.
-- We make sure the those are a multiple of 8 bits so the packing order of the input bytes
-- into the output word is easier to understand.
signal ram_dout_int1, ram_dout_int2: std_logic_vector(8*BYTES_PER_SAMPLE*ADC_SAMPLES_PER_WORD-1 downto 0);
-- RAM Output word, in the same packing format as the function generator input/output word.
signal ram_dout: std_logic_vector(BITS_PER_WORD-1 downto 0);

signal delay_capture_ctr: unsigned(15 downto 0);
signal overflow_ctr, overflow_ctr_reg: unsigned(31 downto 0):= (others => '0');
signal stats_enable, stats_enable_resync: std_logic;
signal stats_done: std_logic:= '0';
signal overflow_frame_ctr: unsigned(15 downto 0):= (others => '0');
signal out_dat_overflows: std_logic_vector(ADC_SAMPLES_PER_WORD-1 downto 0);

--lfsr
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
-- | STATUS  |  0  |  7:0 | ramp_word_ctr        | Last 8 bits of the word counter |
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
status_bytes(0) <= std_logic_vector(lsb(ramp_word_ctr));

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

-- ram_ctrl_addr_paged(11 downto 9) <= ram_ctrl_addr(11 downto 9) or ram_page;
ram_ctrl_addr_paged(LOG2_BYTES_PER_FRAME-1 downto CMD_ADDR_WIDTH) <= ram_page(LOG2_BYTES_PER_FRAME-CMD_ADDR_WIDTH-1 downto 0);
ram_ctrl_addr_paged(CMD_ADDR_WIDTH-1 downto 0) <= ram_ctrl_addr(8 downto 0);
ram_addr <= std_logic_vector(ramp_word_ctr);
-- reorder RAM output word so samples appear in the expected order with the expected width
ram_dout_int2 <= reverse_bytes(ram_dout_int1); -- reorder so byte 0 is in the MSB of word 0
reorder_gen: for j in 0 to ADC_SAMPLES_PER_WORD-1 generate
    ram_dout(ADC_BITS_PER_SAMPLE*(j+1)-1 downto ADC_BITS_PER_SAMPLE*j) <= ram_dout_int2(8*BYTES_PER_SAMPLE*(j+1)-1 downto 8*BYTES_PER_SAMPLE*(j+1)-ADC_BITS_PER_SAMPLE);
end generate;

lsfr_in <= (byte_a & byte_b & not byte_a & not byte_b);
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
--! Implements the function generator

-- Set TUSER
out_dat_tuser <= (
    TUSER_ADC_OVERFLOW_BIT => frame_overflow_flag,
    others => '0'
    );

stats_enable_cdc0: xpm_cdc_single
		generic map (SRC_INPUT_REG => 0)
		port map (src_clk => '0', src_in => stats_enable, dest_clk => clk, dest_out => stats_enable_resync);

funcgen_proc: process (clk)
    -- variable out_dat_var: std_logic_vector(31 downto 0);
    -- variable word_ctr: std_logic_vector(ramp_word_ctr'range);
    variable sample_var: signed(ADC_BITS_PER_SAMPLE-1 downto 0);
    variable int_shift: integer;
    variable int_clip_width: integer range 0 to 15;
    variable new_overflow_ctr: unsigned(overflow_ctr'RANGE);
    variable reversed_ram_dout: std_logic_vector(ram_dout'RANGE);

    begin
        if rising_edge(clk) then
            reset_all <= soft_reset or rst;
            reset_all_reg <= reset_all; -- pipeline
            trig_reg  <= trig;

            in_dat_tdata <= s_axis_adc_tdata;
            in_dat_tuser <= s_axis_adc_tuser;
            in_dat_tvalid <= s_axis_adc_tvalid;
            in_dat_tlast <= s_axis_adc_tlast;

            int_shift := to_integer(shift);
            int_clip_width := to_integer(clip_width);

            for j in 0 to ADC_SAMPLES_PER_WORD-1 loop
                sample_var := signed(out_dat_tdata(ADC_BITS_PER_SAMPLE*(j+1)-1 downto ADC_BITS_PER_SAMPLE*j));
                sample_var := shift_right(sample_var, int_shift);
                if int_clip_width /= 15 then
                    sample_var := clip(sample_var, int_clip_width);
                end if;
                m_axis_adc_tdata(ADC_BITS_PER_SAMPLE*(j+1)-1 downto ADC_BITS_PER_SAMPLE*j) <= std_logic_vector(sample_var);
            end loop;

            -- Register the output bus. out_dat_* registers are tied to a lot of logic and can't be placed optimally to meet timing at high speeds.
            m_axis_adc_tvalid <= out_dat_tvalid;
            m_axis_adc_tuser <= out_dat_tuser;
            m_axis_adc_tlast <= out_dat_tlast;
            
           --------------------------------------
            -- Generate an AXIS ramp stream
            --------------------------------------
            -- Count ramp words
            ramp_word_ctr <= ramp_word_ctr + 1;
            ramp_word_ctr_dly <= ramp_word_ctr;
            word_ctr <= std_logic_vector(ramp_word_ctr_dly); -- This is aligned with the RAM output

            -- Generate a tfirst signal
            if in_dat_tvalid='1' then
                adc_tfirst <= in_dat_tlast;
            end if;


            -- Set default TLAST (overriden below)
            out_dat_tlast <= '0';

            -- Generate ``send_frame``
            if signed(word_ctr) = -1 then
                ramp_tfirst <= '1';
                out_dat_tlast <= '1';
                if enable = '1' then
                    send_frame <= '1';
                    frame_ctr <= frame_ctr + 1; 
                else
                    send_frame <= '0';
                end if; -- send frame
            end if; -- end of a frame

            if out_dat_tvalid then
                new_overflow_ctr := overflow_ctr + to_unsigned(num_ones(out_dat_overflows), overflow_ctr'LENGTH);
                overflow_ctr <= new_overflow_ctr; --overidden below when last word of integration period 
                if out_dat_tlast then
                    overflow_frame_ctr <= overflow_frame_ctr + 1;
                    if overflow_frame_ctr = overflow_ctr_period then
                        overflow_ctr_reg <= new_overflow_ctr when stats_enable_resync;
                        overflow_ctr <= (others => '0');
                        overflow_frame_ctr <= (others => '0'); 
                        stats_done <= '1';
                    end if; --end of integration period 
                end if; -- tlast
            end if; -- tvalid

            stats_done <= '0' when not stats_enable_resync;
            
            if reset_all then
                overflow_frame_ctr <= (others => '0');
                stats_done <= '0';
                overflow_ctr <= (others => '0');
                overflow_ctr_reg <= (others => '0');
            end if; 

            if enable = '0' then
                frame_ctr <= (others=>'0');
            end if;

            if (fn_sel = FN_ADC and adc_tfirst='1') or (fn_sel /= FN_ADC and ramp_tfirst='1') then
                capture_flag <= trig_reg;
            end if;

            -- Set TDATA
            case fn_sel is

                when FN_ADC =>
                    out_dat_tdata <= in_dat_tdata;
                    out_dat_tvalid <= in_dat_tvalid;
                    out_dat_tlast <= in_dat_tlast;
                    out_dat_overflows <= in_dat_tuser;

--                when FN_ADC16 => -- **OBSOLETE**
--                    -- This mode is now identical to FN_ADC now that we handle wider buses
--                    frame_overflow_flag <= '0';
--                    out_dat_tdata <= in_dat_tdata;
--                    out_dat_tvalid <= in_dat_tvalid;
--                    out_dat_tlast <= in_dat_tlast;

                when FN_RAM =>
                    out_dat_tdata <= ram_dout; -- Byte at address 0 is in the MSB
                    out_dat_tvalid <= send_frame;
                    -- frame_overflow_flag <= '0';
                    out_dat_overflows <= (others => '0');

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
                    out_dat_tvalid <= send_frame;
                    out_dat_overflows <= (others => '0');

                -- Send peudo-random noise on all samples.
                -- The 32-bit bits of the PNRG is distributed on the MSB of all samples, and the samples are right-shifted by the value in byte_c.
                when FN_NOISE =>                    
                    out_dat_tdata <= lfsr_out;
                    out_dat_tvalid <= send_frame;
                    out_dat_overflows <= (others => '0');

                when FN_FRAME_WORD_CTR_RAM_FLAGS =>
                    out_dat_tdata <= (others => '0');
                    out_dat_tdata(31 downto 0) <= to_slv(frame_ctr) & word_ctr; -- store frame & word counter only in the lower 32 bits.
                    out_dat_tvalid <= send_frame;

                    for i in 0 to ADC_SAMPLES_PER_WORD-1 loop
                        reversed_ram_dout := reverse_bits_same_dir(ram_dout);
                        out_dat_overflows(i) <= reversed_ram_dout(ADC_BITS_PER_SAMPLE*(i+1)-1); --reverse bits so that the MSB of ram is aligned with the MSB of tuser (first sample). The MSB of each sample indicates if there is an overflow.
                    end loop; --overflow count per word (LSB of each sample indicates overflow)

                -- Send the The ADC_BITS_PER_SAMPLE-2 LSBs of the frame counter on every sample of the frame
                when FN_FRAME8 =>
                    for i in 0 to ADC_SAMPLES_PER_WORD-1 loop
                        out_dat_tdata(ADC_BITS_PER_SAMPLE*(i+1)-1 downto ADC_BITS_PER_SAMPLE*i) <= to_slv(frame_ctr(ADC_BITS_PER_SAMPLE-3 downto 0)) & "00";
                    end loop;
                    out_dat_tvalid <= send_frame;

                    for i in 0 to ADC_SAMPLES_PER_WORD-1 loop
                        reversed_ram_dout := reverse_bits_same_dir(ram_dout);
                        out_dat_overflows(i) <= reversed_ram_dout(ADC_BITS_PER_SAMPLE*i); --reverse bits so that the MSB of ram is aligned with the MSB of tuser (first sample). The MSB of each sample indicates if there is an overflow.
                    end loop;

                -- Send the 4 LSBs of the frame counter on the upper 4 MSBs of each sample in the frame
                when FN_FRAME4 =>
                    out_dat_tdata <= (others => '0');
                    for i in 0 to ADC_SAMPLES_PER_WORD-1 loop
                        out_dat_tdata(ADC_BITS_PER_SAMPLE*(i+1)-1 downto ADC_BITS_PER_SAMPLE*(i+1)-4) <= to_slv(frame_ctr(3 downto 0));
                    end loop;
                    out_dat_tvalid <= send_frame;

                    for i in 0 to ADC_SAMPLES_PER_WORD-1 loop
                        reversed_ram_dout := reverse_bits_same_dir(ram_dout);
                        out_dat_overflows(i) <= reversed_ram_dout(ADC_BITS_PER_SAMPLE*i); --reverse bits so that the MSB of ram is aligned with the MSB of tuser (first sample). The MSB of each sample indicates if there is an overflow.
                    end loop;

                when others =>
                    out_dat_tdata <= (others=>'0');
            end case;

            if in_dat_tvalid then
                if adc_tfirst then
                    frame_overflow_flag <= or(out_dat_overflows);
                else
                    frame_overflow_flag <= frame_overflow_flag or or(out_dat_overflows);
                end if;
            end if;

            -- Synchronous resets -- override signals above
            if reset_all='1' then -- Synchronous reset
                ramp_word_ctr <= (others=>'0');
                ramp_word_ctr_dly <= (others=>'0');
                word_ctr <= (others=>'0');
                out_dat_tvalid <= '0'; -- needed
                frame_ctr <= (others=>'0');
                send_frame <= '0';
                adc_tfirst <= '1';
                ramp_tfirst <= '1';
                trig_reg <= '0';
                capture_flag <= '0';
                overflow_ctr <= (others=>'0');
                
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

-- only if IMPLEMENT_DELAY_CAPTURE=TRUE
-- Instantiate block RAM that will contain the user-programmable waveforms
--ram0 : entity work.FUNCGEN_RAM
--    PORT MAP (
--        clka  => ctrl_clk,
--        wea(0)   => ram_ctrl_wr_en,
--        addra => ram_ctrl_addr_paged,
--        dina  => ram_ctrl_din,
--        douta => ram_ctrl_dout,

--        clkb   => clk,
--        web(0) => '0',
--        addrb  => ram_addr,
--        dinb   => (others=>'0'),
--        doutb  => ram_dout_int
--    );


    -- Instantiate block RAM that will contain the user-programmable waveforms
   -- xpm_memory_tdpram: True Dual Port RAM
   -- Xilinx Parameterized Macro, version 2022.2

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

      -- defaults
--      RST_MODE_A => "SYNC",            -- String
--      RST_MODE_B => "SYNC",            -- String

      --AUTO_SLEEP_TIME => 0,            -- DECIMAL
--      CASCADE_HEIGHT => 0,             -- DECIMAL
      --ECC_MODE => "no_ecc",            -- String
      --MEMORY_INIT_FILE => "none",      -- String
      --MEMORY_INIT_PARAM => "0",        -- String
      MEMORY_OPTIMIZATION => "true",   -- String
      MESSAGE_CONTROL => 1,            -- for sims

      --READ_RESET_VALUE_A => "0",       -- String
      --READ_RESET_VALUE_B => "0",       -- String
      SIM_ASSERT_CHK => 0,             -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      USE_MEM_INIT => 0,               -- DECIMAL
      --USE_MEM_INIT_MMI => 0,           -- DECIMAL
      --WAKEUP_TIME => "disable_sleep",  -- String
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




end impl;
