----------------------------------------------------------------------------------
-- Company: McGill University Cosmology Instrumentation Lab
-- Engineer: J.-F. Cliche
--
-- Create Date:    2012-07-05
-- Design Name:     SCALER
-- Module Name:    SCALER - Behavioral
-- Project Name: CHIME
-- Target Devices: Virtex 6 or 7 series
-- Tool versions: ISE 14.4
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--      2012-05-31 JFC: Rewritten for the new PFB_FFT and AXI4 Streaming input and output buses
--      2012-09-05 JFC: Fixed the output TREADY: ANDed  FFT_CE, othewise the output is valid even if we don't clock
--      2012-04-11 JFC: pipelined the scaler to remove timing closure bottleneck
--      2013-11-29 JFC: implemented FOUR_BIT flag and 4-bit rounding.
--      2015-01-27 JFC: refactored to include saturation at -127/-7, zero on saturation, add stats to the registers

------ LIBRARY DECLARATIONS -------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library xpm;
use xpm.vcomponents.all;

use work.chFPGA_Package.all; -- Get all component definitions

-------- ENTITY DECLARATION ---------------------

-- Scales the FFT output into (8+8) bits or (4+4) bits complex values
-- by applying a constant or table-based complex gain, shifting the results,
-- and truncate or round the value to the desired format.
--
-- The scaler converts each of the two (even,odd) (18+18) bits FFT output to (8+8) bit or (4+4) bits by applying a separate
-- (16+16) bit complex gain to each frequency sample and applying a global binary scaling to all the
-- results.
--
-- The order of the FFT data is, from MSB to LSB: Re(N), Im(N), Re(N+1), Im(N+1), ...
-- The output data is in the same order.

-- Overflows are detected during the scaling process, and saturations are applied if those occur.
-- Saturation of negative values can be selected to occur at -7 (in 4-bit mode) or -15 (in 8-bit mode) instead of -8 or -16. , the later case being used to
-- ensure symmetric statistics in the outgoing data.
--
-- Various rounding methods can be applied to the result.
--
-- SCALER has a statistics module that counts scaler overflows and ADC saturations. These stats use
-- 16-bit counters and are gathered over a programmable number of frames so we always get counts
-- that are taken over the same period of time.
--
-- FFT overflow are NOT handled by the statistics module.
--
--
-- In BYPASS mode, the last 8 bit of each of the four 18-bit numbers in the input (From MSB to LSB:
-- Re Even, Im Even, Re Odd, Im Odd) are placed in the 32 bits of the output without any
-- transformation. The CAPTURE and ADC_OVERFLOW user bits are passed on, but the SCALER overflow
-- bits are cleared.
--
-- The BYPASS mode, if also enabled in the SCALER module, allows the FUNCGEN output to be passed
-- directly to the output of the channelizer.
--
entity scaler is
    generic (
        FFT_BITS_PER_BIN: integer := 32+32; --18+18; -- Real + Imaginary part
        FFT_BINS_PER_WORD: integer := 4;
        FFT_BINS_PER_FRAME: integer:= 8192;
        FFT_BITS_PER_WORD: integer := FFT_BITS_PER_BIN * FFT_BINS_PER_WORD;
        USE_COMPLEX_GAINS: boolean := FALSE;
        COEFF_BITS_PER_BIN: integer := 16; -- typically 16 or 16+16. Includes both real and imaginary part. If USE_COMPLEX_GAINS=TRUE, half the bits are used for real and half for imaginary. Must be multiple of 8 as it is configured byte-wise.
        OUT_BITS_PER_BIN: integer := 8+8; -- Fixed to (8+8) to support 8-bit mode or get more of the input data in bypass mode.
        CAP_BITS_PER_WORD: integer := 128; -- 32 for Iceboard, 128 for CRS
        FFT_TUSER_BITS_PER_WORD: integer := 2; -- number of tuser bits coming from FFT (fft overflow, adc overflow)
        SCALER_TUSER_BITS_PER_WORD: integer := FFT_BINS_PER_WORD + FFT_TUSER_BITS_PER_WORD + 1; -- add overflow bits (one per bin) and current gain bank
        OUT_BITS_PER_WORD: integer := OUT_BITS_PER_BIN * FFT_BINS_PER_WORD;
        CAP_BITS_PER_BIN: integer := CAP_BITS_PER_WORD / FFT_BINS_PER_WORD; -- minimum is 4+4, but can be increased to use 8-bit mode or get more of the input data in bypass mode for capture purposes.
        EIGHT_BIT_SUPPORT: boolean := OUT_BITS_PER_BIN >= 8+8 -- TRUE of the scaler supports (8+8) bit output in addition to the 4+4 bit output
        );
    port (
        -- Input Interface
        s_axis_in_tdata    : in std_logic_vector(FFT_BITS_PER_WORD-1 downto 0); -- Format: MSB->LSB: Re(N),   Im(N),   Re(N+1), Im(N+1)
        s_axis_in_tvalid   : in std_logic;
        s_axis_in_tlast    : in std_logic;
        s_axis_in_tuser    : in std_logic_vector(FFT_TUSER_BITS_PER_WORD-1 downto 0);  -- Bit 0: ADC overflow, Bit 1: FFT Overflow; Valid on TLAST only.

        -- Main output interface
        m_axis_out_tdata    : out std_logic_vector(OUT_BITS_PER_WORD-1 downto 0); -- Format: MSB->LSB: Re(N),   Im(N),   Re(N+1), Im(N+1)
        m_axis_out_tvalid   : out std_logic;
        m_axis_out_tlast    : out std_logic;
        m_axis_out_tuser    : out std_logic_vector(SCALER_TUSER_BITS_PER_WORD-1 downto 0);  -- Bit 0: ADC overflow, Bit 1: FFT Overflow; Bit 2+ Scaler overflow for bin 0,1,2..., last bit: gain bank.  Valid on TLAST only

        -- Capture output interface
        m_axis_cap_tdata    : out std_logic_vector(CAP_BITS_PER_WORD-1 downto 0); -- Format: MSB->LSB: Re(N),   Im(N),   Re(N+1), Im(N+1)
        m_axis_cap_tvalid   : out std_logic;
        m_axis_cap_tlast    : out std_logic;
        m_axis_cap_tuser    : out std_logic_vector(SCALER_TUSER_BITS_PER_WORD-1 downto 0); -- same contents as m_axis_out_tuser

        -- Common Clock and Reset
        clk     : in  std_logic;
        reset   : in  std_logic; -- clk-synchronous reset

        -- Channel FIFO monitoring
        fifo_overflow   : in std_logic:= '0'; -- Used to monitor the channelizer FIFO since it does not haveits own BSB registers.
        mon_clk: in std_logic := '0';
        mon_tvalid: in std_logic:= '0';
        mon_tlast: in std_logic:= '0';
        mon_word: in std_logic_vector(15 downto 0) := (others => '0');
        mon_ctrl: out std_logic;

        -- Control Interface (command and reply stream buses)
        CTRL_CMD_IN_DAT     : in  AXIS8_DAT_STRUCT;
        CTRL_CMD_IN_RDY     : out AXIS8_RDY_STRUCT;
        CTRL_RPLY_OUT_DAT   : out AXIS8_DAT_STRUCT;
        CTRL_RPLY_OUT_RDY   : in  AXIS8_RDY_STRUCT;
        ctrl_clk            : in  std_logic;
        CTRL_RST            : in  std_logic
        );

    attribute DONT_TOUCH: string;
    attribute DONT_TOUCH of SCALER: entity is "yes";
end scaler;

------- ARCHITECTURE DECLARATION and DEFINITION ---------------------
-- Implements the functional code of the SCALER
architecture Behavioral of SCALER is

    constant COEFF_BITS_PER_WORD: integer := COEFF_BITS_PER_BIN * FFT_BINS_PER_WORD;
    constant FFT_WORDS_PER_FRAME: integer := FFT_BINS_PER_FRAME / FFT_BINS_PER_WORD;
    constant LOG2_FFT_WORDS_PER_FRAME: integer := integer_log2(FFT_WORDS_PER_FRAME); -- word counter width
    -- The following is to establosh how much storage space we need to store the gain coefficients and how many bits of addtess we need to access them
    constant COEFF_WORDS_PER_FRAME: integer := FFT_WORDS_PER_FRAME;
    constant COEFF_BYTES_PER_FRAME: integer := COEFF_WORDS_PER_FRAME * COEFF_BITS_PER_WORD / 8;
    constant LOG2_COEFF_BYTES_PER_FRAME: integer := integer_log2(COEFF_BYTES_PER_FRAME); -- number of address bits to access gain coefficients byte-wise
    constant LOG2_COEFF_WORDS_PER_FRAME: integer := integer_log2(FFT_WORDS_PER_FRAME); -- number of address bits to access gain coefficients word-wise
    -- Describe how many integers in total there are in a post-gain word. The number includes both real or imaginary parts.
    -- The post-gain processing applies post-scaling, rounding and saturation to each integer individually,
    -- whether they are the real or complex component of the product.
    constant INTEGERS_PER_WORD:integer := FFT_BINS_PER_WORD * 2;
    constant INTEGER_WIDTH: integer := sel(USE_COMPLEX_GAINS,
                                           FFT_BITS_PER_BIN/2 + COEFF_BITS_PER_BIN/2 + 1, -- complex gains, +1 to account for add operation in complex multiplication
                                           FFT_BITS_PER_BIN/2 + COEFF_BITS_PER_BIN); -- real gain (float or not)
    --constant SCALAR_WIDTH:integer := FFT_BITS_PER_BIN * sel(USE_COMPLEX_GAINS, 2, 1);
    constant BSB_RAM_ADDR_WIDTH: integer :=9; -- Maximum number of RAM address bits allowed by the BSB interface. The remaining address space must be accessed by paging.
    constant RAM_LATENCY: integer:=2; -- RAM access latency on both the control and readout side of the RAM. **Do not change**: Latency compensation is hardcoded in the code.
    constant NUMBER_OF_COEFF_BANKS: integer := 2; -- **do not change**: the bank address width is hardcoded to a single bit.
    constant LOG2_NUMBER_OF_COEFF_BANKS: integer := integer_log2(NUMBER_OF_COEFF_BANKS);
    constant LOG2_NUMBER_OF_COEFF_PAGES: integer := LOG2_COEFF_BYTES_PER_FRAME + LOG2_NUMBER_OF_COEFF_BANKS - BSB_RAM_ADDR_WIDTH; -- width of the page register for byte-wise access to both banks

    -- Shortcuts to keep line lengths reasonable
    constant FB: integer := FFT_BITS_PER_BIN; -- FFT complex sample width
    constant OB: integer := OUT_BITS_PER_BIN; -- Output complex sample width
    constant CB: integer := CAP_BITS_PER_BIN; -- Capture complex sample width
    constant IPW: integer := INTEGERS_PER_WORD; -- Integers per word
    constant BPW: integer := FFT_BITS_PER_WORD; -- Number of bits in an FFT word (all bins combined)

    -- pipelined reset
    signal rst_reg: std_logic;

    -- Data bus pipeline to compensate for RAM_LATENCY
    signal in_dat_dly1_tdata    : std_logic_vector(FFT_BITS_PER_WORD-1 downto 0);
    signal in_dat_dly1_tvalid   : std_logic;
    signal in_dat_dly1_tlast    : std_logic;
    signal in_dat_dly1_tuser    : std_logic_vector(FFT_TUSER_BITS_PER_WORD-1 downto 0);  --


    signal in_dat_dly2_tdata    : std_logic_vector(FFT_BITS_PER_WORD-1 downto 0);
    signal in_dat_dly2_tvalid   : std_logic;
    signal in_dat_dly2_tlast    : std_logic;
    signal in_dat_dly2_tuser    : std_logic_vector(FFT_TUSER_BITS_PER_WORD-1 downto 0);  --

    --signal IN_DAT_DLY1: AXIS72_DAT_STRUCT; --
    --signal IN_DAT_DLY2: AXIS72_DAT_STRUCT; --

    --- Define Control word and its signals
    signal control_bytes: slv8_array(0 to 12); -- default value set in the CMD_SLAVE
    signal status_bytes: slv8_array(0 to 17);

    signal bypass_scaler: std_logic;
    signal soft_reset: std_logic;
    signal post_scaler_left_shift: std_logic_vector(4 downto 0); -- can shift up to 31 bits left

    -- Stage 1: shift result
    signal stage1_word: signed_array(0 to INTEGERS_PER_WORD-1)(INTEGER_WIDTH-1 downto 0);
    signal stage1_sign: std_logic_vector(0 to INTEGERS_PER_WORD-1); -- Indicates the sign of each of the 4 numbers in the incoming word
    signal stage1_overflow: std_logic_vector(0 to INTEGERS_PER_WORD-1);
    signal stage1_tvalid: std_logic;
    signal stage1_tlast: std_logic;
    signal stage1_tuser: std_logic_vector(FFT_TUSER_BITS_PER_WORD-1 downto 0);

    -- stage 2: rounding result
    signal stage2_word: signed_array(0 to INTEGERS_PER_WORD-1)(7 downto 0);
    signal stage2_sign: std_logic_vector(0 to INTEGERS_PER_WORD-1); -- Indicates the sign of each of the 4 numbers in the incoming word
    signal stage2_overflow: std_logic_vector(0 to INTEGERS_PER_WORD-1);
    signal stage2_tvalid: std_logic;
    signal stage2_tlast: std_logic;
    signal stage2_tuser: std_logic_vector(FFT_TUSER_BITS_PER_WORD-1 downto 0);

    -- stage 3: saturation and output
    signal stage3_word: signed_array(0 to INTEGERS_PER_WORD-1)(7 downto 0);
    signal stage3_sign: std_logic_vector(0 to INTEGERS_PER_WORD-1); -- Indicates the sign of each of the 4 numbers in the incoming word
    signal stage3_overflow: std_logic_vector(0 to INTEGERS_PER_WORD-1);
    signal stage3_tvalid: std_logic;
    signal stage3_tlast: std_logic;
    signal stage3_tuser: std_logic_vector(FFT_TUSER_BITS_PER_WORD-1 downto 0);

    -- Control signals
    signal four_bits: std_logic;
    signal symmetric_saturation: std_logic;
    signal zero_on_saturation: std_logic;
    signal use_float_gains: std_logic;

    signal rounding_mode: std_logic_vector(1 downto 0);
    constant ROUNDING_MODE_TRUNCATE: std_logic_vector(1 downto 0):= "00";
    constant ROUNDING_MODE_ROUND: std_logic_vector(1 downto 0):= "01";
    constant ROUNDING_MODE_CONVERGENT_ROUND: std_logic_vector(1 downto 0):= "10";

    signal gain_table_page : std_logic_vector(LOG2_NUMBER_OF_COEFF_PAGES-1 downto 0); -- 4 bits, used only to read/write the gain table from the control interface. Includes pages.
    signal gain_table_page_padded : std_logic_vector(5 downto 0); -- largest gain_table_page vector that can fit in the control registers

    -- Gain coefficient memory signals
    signal coeff_ram_ctrl_addr: std_logic_vector(BSB_RAM_ADDR_WIDTH-1 downto 0); -- limited by BSB
    signal coeff_ram_ctrl_addr_int: std_logic_vector(LOG2_COEFF_BYTES_PER_FRAME+LOG2_NUMBER_OF_COEFF_BANKS-1 downto 0); -- there are two gain table in memory (2 pages)
    -- signal coeff_ram_ctrl_rd_en: std_logic;
    signal coeff_ram_ctrl_wr_en: std_logic;
    --signal coeff_ram_ctrl_wr_en_vect: std_logic_vector(0 downto 0);
    signal coeff_ram_ctrl_din: std_logic_vector(7 downto 0);
    signal coeff_ram_ctrl_dout: std_logic_vector(7 downto 0);
    signal coeff_ram_addr: std_logic_vector(LOG2_COEFF_WORDS_PER_FRAME+LOG2_NUMBER_OF_COEFF_BANKS-1 downto 0);

    signal word_ctr: unsigned(LOG2_FFT_WORDS_PER_FRAME-1 downto 0); -- 10 bits
    signal frame_ctr: unsigned(31 downto 0); -- 10 bits
    signal cap_frame_ctr: unsigned(7 downto 0); -- 8 bits counter for debugging
    signal use_offset_binary: std_logic;
    signal cap_data_type: std_logic_vector(2 downto 0);
    signal bypass_data_type: std_logic_vector(1 downto 0) := (others => '0'); -- init for sims

    signal next_gain_bank: std_logic; -- 1 bit
    signal gain_bank_switch_frame_number: std_logic_vector(31 downto 0);
    signal current_gain_bank: std_logic;
    signal synchronize_gain_bank_switch: std_logic;


    -- Multiplier output
    signal scaled_data_tvalid: std_logic;
    signal scaled_data_tuser: std_logic_vector(FFT_TUSER_BITS_PER_WORD-1 downto 0);
    signal scaled_data_tlast: std_logic;
    signal scaled_data_tdata: std_logic_vector(INTEGER_WIDTH*INTEGERS_PER_WORD-1 downto 0);
    signal scaled_data_log_gain: unsigned_array(0 to FFT_BINS_PER_WORD-1)(5 downto 0);


    signal coeff_ram_dout: std_logic_vector(COEFF_BITS_PER_WORD-1 downto 0);

    signal stats_frame_count: unsigned(23 downto 0); -- Number of frames to include in stats
    signal stats_single_bin: std_logic;
    signal stats_bin_number: unsigned(15 downto 0);


    signal stats_scaler_overflows: unsigned(15 downto 0);
    signal stats_adc_overflows: unsigned(15 downto 0);

    signal stats_capture: std_logic;
    signal stats_ready: std_logic;

    signal delay_capture_ctr: unsigned(15 downto 0);
    signal delay_capture_ctr_en: std_logic :='0';

    signal fifo_overflow_reset: std_logic;
    signal fifo_overflow_sticky: std_logic;

    signal mon_packet_length: unsigned(15 downto 0);
    signal mon_word_ctr: unsigned(15 downto 0);
    signal mon_packet_ctr: unsigned(7 downto 0);
    signal mon_reset_stats: std_logic;
    signal mon_clk_ctr: unsigned(7 downto 0);
    signal mon_bit_ctr: unsigned(7 downto 0);
    -- 3  33  22 22      11
    -- 4  10  76 43      65      87      0
    -- ---========--------========--------
    --                  IIIIIIIIIIIIIIIIII  - 18 bit input from the FFT
    --                    SSSSSSSSSSSSSSSS  - 16 bit gain
    -- PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP  - 35 bit product
    -- 00001
    -- 4444
    -- 000000001
    -- 88888888
begin

-----------------------------------------------------------------------------------
-- CONTROL and STATUS Bytes
-----------------------------------------------------------------------------------
-- SCALER Module Memory Map
--
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- |  Page    | Addr   | Bit(s)  | Name                              | Description                                                                                     |
-- |----------|--------|---------|-----------------------------------|---------------------------------------------------------------------------------------------------|
-- | CONTROL  |  0     |  7      | soft_reset                        | Soft reset signal. When '1', resets internal counters and state.                                 |
-- |          |        |  6      | bypass_scaler                     | When '1', bypasses the scaling operations and passes input data directly to output (with optional transformations based on bypass_data_type). |
-- |          |        |  5      | four_bits                         | Is '1' when only the top 4 bits are of interest (i.e. rounding is done on the 5th bit). In this case the lower 4 bits of the results are zero. |
-- |          |        |  4:0    | post_scaler_left_shift            | Post-scaler left shift amount (0-31). Applied after gain multiplication for global scaling.      |
-- |          |  1     |  7      | gain_table_page(5)                | MSB of gain table page address                                                                   |
-- |          |        |  6      | use_offset_binary                 | When '1', Offset_binary encoding is used on the output of the scaler. The input data and gains are not affected and are always provided in 2's complement. |
-- |          |        |  5      | gain_table_page(4)                | Bit 4 of gain table page address                                                                 |
-- |          |        |  4      | next_gain_bank                    | Indicates which bank of gain coefficients is to be used by the scaler                            |
-- |          |        |  3:0    | gain_table_page(3:0)              | LSBs of gain table page address. Indicates which page of gain coefficients table is being read or written to by the user. |
-- |          |  2     |  7      | stats_capture                     | '0' clears the stats_done flag. when '1', the stats are captured and stats_done is set to '1' when the next frame block completes |
-- |          |        |  6      | symmetric_saturation              | When '1', negative values will saturate to -127 (8-bit mode) or -7 (4-bit mode). Otherwise they saturate on -128 and -8 respectively. |
-- |          |        |  5      | zero_on_saturation                | When '1', the real/imaginary pairs are zeroed if either the real part or imaginary part encounters an overflow. |
-- |          |        |  4      | synchronize_gain_bank_switch      | When '1', The target gain bank is activated only when the target frame number has been reached   |
-- |          |        |  3      | fifo_overflow_reset               | Resets the fifo_overflow_sticky status bit                                                       |
-- |          |        |  2      | stats_single_bin                  | When '1', overflow stats operate only on bin specified in stats_bin_number                       |
-- |          |        |  1:0    | rounding_mode                     | Specifies the type of rounding: '00' = No rounding (truncation), '01' = standard rounding (ties always round up), '10' = convergent rounding (ties round toward the even values) |
-- |          | 3:5    | 23:0    | stats_frame_count                 | Number of frames to include in the statistics. 1 = 1 frame.                                      |
-- |          | 6:9    | 31:0    | gain_bank_switch_frame_number     | Target frame number at which the next gain bank will be activated.                               |
-- |          | 10     |  7      | use_float_gains                   | When '1', bin-specific log gain is encoded in the upper 5 bits of the gain. For real gains only |
-- |          |        |  6      | mon_reset_stats                   | Reset mon_packet_length and mon_packet_ctr                                                       |
-- |          |        |  5      | mon_ctrl                          | Monitor control signal                                                                           |
-- |          |        |  4:3    | bypass_data_type                  | When bypass_scaler is '1': "00": input, "01": 1+0j if any saturation, "10": 1+0j or 0+1j if positive or negative saturation respectively |
-- |          |        |  2:0    | cap_data_type                     | "000": raw output, "001": scaled input, "010": 4-bit, "100": Even bins, "101": odd bins          |
-- |          |11:12   | 15:0    | stats_bin_number                  | Bin number on which to measure overflow stats when stats_single_bin='1'.                        |
-- | STATUS   |  0     |  7      | stats_ready                       | '1' when new stats data has been captured                                                       |
-- |          |        |  6      | current_gain_bank                 | Currently used gain bank.                                                                       |
-- |          |        |  5      | eight_bit_support                 | '1' when this scaler implementation supports (8+8) bit output mode                              |
-- |          |        |  4      | fifo_overflow_sticky              | Set when channeliser fifo overflows and remains set until reset.                                |
-- |          |        |  3      | USE_COMPLEX_GAINS                 | '1' when the scaler is using complex gain coefficients                                          |
-- |          |        |  2:0    | coeff_page_width                  | Width of the page register for bytewise access to both banks                                    |
-- |          | 1:2    | 15:0    | stats_scaler_overflows            | Number of scaler overflows in the last captured frame block. Saturates at 0xFFFE or 0xFFFF.    |
-- |          | 3:4    | 15:0    | stats_adc_overflows               | Number of frames that have at least one adc overflow in the last captured frame block. Saturates at 0xFFFF. |
-- |          |  5     |  7:0    | frame_ctr                         | Last 8 bits of the frame counter.                                                               |
-- |          | 6:7    | 15:0    | delay_capture_ctr                 | Number of clocks it took for first frame of data to arrive after reset                          |
-- |          | 8:9    | 15:0    | mon_packet_length                 | Length in words of longest packet so far                                                        |
-- |          | 10     |  7:0    | mon_packet_ctr                    | Number of packets so far                                                                        |
-- |          |11:12   | 15:0    | mon_word_ctr                      | Number of words in current packet so far                                                        |
-- |          | 13     |  7:0    | cap_frame_ctr                     | Number of frames of data captured by capture outputs so far                                     |
-- |          |14:15   | 15:0    | mon_word                          | Monitor word value                                                                              |
-- |          | 16     |  7:0    | mon_clk_ctr                       | Monitor clock counter                                                                           |
-- |          | 17     |  7:0    | mon_bit_ctr                       | Monitor bit counter                                                                             |
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- CONTROL Byte 0
soft_reset             <= control_bytes(0)(7);
bypass_scaler          <= control_bytes(0)(6);
four_bits              <= control_bytes(0)(5);
post_scaler_left_shift <= control_bytes(0)(4 downto 0);

-- CONTROL Byte 1
assert gain_table_page'LENGTH <= gain_table_page_padded'LENGTH report "Not enough register space for gain_table_page (have "&str(gain_table_page_padded'LENGTH)&" but need " & str(gain_table_page'LENGTH) & ")" severity FAILURE;
gain_table_page <= gain_table_page_padded(gain_table_page'RANGE); -- Padded page vector to acount for different number of pages. Will cause errors if we exceed the number of bits we can assign to the control registers.

gain_table_page_padded(5)          <= control_bytes(1)(7);
use_offset_binary                  <= control_bytes(1)(6);
gain_table_page_padded(4)          <= control_bytes(1)(5);
next_gain_bank                     <= control_bytes(1)(4);
gain_table_page_padded(3 downto 0) <= control_bytes(1)(3 downto 0);


-- CONTROL Byte 2
stats_capture                <= control_bytes(2)(7);
symmetric_saturation         <= control_bytes(2)(6);
zero_on_saturation           <= control_bytes(2)(5);
synchronize_gain_bank_switch <= control_bytes(2)(4);
fifo_overflow_reset          <= control_bytes(2)(3);
stats_single_bin             <= control_bytes(2)(2);
rounding_mode                <= control_bytes(2)(1 downto 0);

-- CONTROL Byte 3-5
stats_frame_count <= to_unsigned(control_bytes(3 to 5));

-- CONTROL Byte 6-9
gain_bank_switch_frame_number <= to_slv(control_bytes(6 to 9));

-- CONTROL Byte 10
use_float_gains <= control_bytes(10)(7); -- if True, bin-specific log gain is encoded in the upper 5 bits of the gain. For real gains only (USE_COMPLEX_GAINS=FALSE)
mon_reset_stats <= control_bytes(10)(6);
mon_ctrl <= control_bytes(10)(5);
bypass_data_type  <= control_bytes(10)(4 downto 3); -- if bypass=1: "00": input, "01": 1+0j if any saturation, "10": 1+0j or 0+1j if positive or negative saturation respectively
cap_data_type  <= control_bytes(10)(2 downto 0); -- "000": raw output, "001": scaled input, "010": 4-bit, "100": Even bins, "101": odd bins, "110": scaled even bins, "111": scaled odd bins

-- CONTROL bytes 11-12
stats_bin_number <= to_unsigned(control_bytes(11 to 12));

-- STATUS Byte 0
status_bytes(0)(7)   <= stats_ready;
status_bytes(0)(6)   <= current_gain_bank;
status_bytes(0)(5)   <= to_std_logic(EIGHT_BIT_SUPPORT);
status_bytes(0)(4)   <= fifo_overflow_sticky;
status_bytes(0)(3)   <= to_std_logic(USE_COMPLEX_GAINS);

-- log2 of the number of gain table pages .
--   - 1024 bins x 16-bit complex gains x 2 banks = 1024*4*2 = 8 Kbytes, log2(8K) 13 bit address space, 13 - 9 = 4 bit page address
--   - 8192 bins x 16-bit real gains x 2 banks: log2(8k*2*2)-9 = 6
-- Gain bank size in bytes = 2**(value+9-1)
status_bytes(0)(2 downto 0) <= to_slv(LOG2_NUMBER_OF_COEFF_PAGES, 3);

-- STATUS Byte 1-2: scaler overflows
status_bytes(1 to 2) <= to_slv8_array(stats_scaler_overflows);

-- STATUS Byte 3-4: ADC overflows
status_bytes(3 to 4) <= to_slv8_array(stats_adc_overflows);

-- STATUS Byte 5
status_bytes(5)      <= to_slv(lsb(frame_ctr, 8));

-- STATUS Byte 6-7
status_bytes(6 to 7) <= to_slv8_array(delay_capture_ctr);

status_bytes(8 to 9) <= to_slv8_array(mon_packet_length);
status_bytes(10) <= std_logic_vector(mon_packet_ctr);
status_bytes(11 to 12) <= to_slv8_array(mon_word_ctr);

status_bytes(13) <= std_logic_vector(cap_frame_ctr);

status_bytes(14 to 15) <= to_slv8_array(mon_word);
status_bytes(16) <= std_logic_vector(mon_clk_ctr);
status_bytes(17) <= std_logic_vector(mon_bit_ctr);

-----------------------------------------------------------------------------------
-- Memory-Mapped interface
-----------------------------------------------------------------------------------
-- Instantiates a memory-mapped interface to the control and status bytes
bsb_regs0: entity work.bsb_regs
    GENERIC MAP (
        NUMBER_OF_CONTROL_BYTES=>control_bytes'Length(1), -- Number of bits in the control word
        NUMBER_OF_STATUS_BYTES=>status_bytes'Length(1), -- Number of bits in the status word.
        DEFAULT_CONTROL_BYTES=> X"21" & -- Byte 0
                                X"60" & -- Byte 1
                                X"02" & -- Byte 2: stats_capture=0, symmetric_saturation=0,, zero_on_saturation=0, synchronize_gain_bank_switch=0,, fifo_overflow_reset=0, stats_single_bin=0, rounding_mode =2
                                X"05F5E1" & -- Bytes 3-5: stats_frame_count
                                X"00000000" & --Bytes 6-9: gain_bank_switch_frame_number
                                X"00"& -- Byte 10: use_float_gains=0,mon_reset_stats=0, mon_ctrl=0, bypass_data_type[1:0]="00", cap_data_type[1:0]="00"
                                X"0000", -- Bytes 11-12: stats_bin_number
        RAM_ADDR_WIDTH => BSB_RAM_ADDR_WIDTH,
        RAM_LATENCY=> RAM_LATENCY
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
        status_bytes => status_bytes,

        RAM_DIN => coeff_ram_ctrl_din,
        RAM_DOUT => coeff_ram_ctrl_dout,
        RAM_ADDR => coeff_ram_ctrl_addr,
        RAM_WR_EN => coeff_ram_ctrl_wr_en,
        RAM_RD_EN => open -- the ram is always reading
    );

--coeff_ram_ctrl_wr_en_vect <= (0 => coeff_ram_ctrl_wr_en);
coeff_ram_ctrl_addr_int <= (gain_table_page & coeff_ram_ctrl_addr);
coeff_ram_addr <= (current_gain_bank & std_logic_vector(word_ctr));


--coeff_ram0 : entity work.SCALER_COEFF_RAM
--    PORT MAP (
--        clka  => CTRL_CLK,
--        wea   => coeff_ram_ctrl_wr_en_vect,
--        addra => coeff_ram_ctrl_addr_int,
--        dina  => coeff_ram_ctrl_din,
--        douta => coeff_ram_ctrl_dout,

--        clkb  => clk,
--        web   => (others=>'0'),
--        dinb  => (others=>'0'),
--        addrb => coeff_ram_addr,
--        doutb => coeff_ram_dout -- two flags for each bin number
--    );


        -- Instantiate block RAM that will contain the scaler coefficients
        -- When storing a complex value, Imaginary component is in the high bits of the word.
        -- Mapping:
        --                ---------------------------------------------
        --                 7         0 7        0 7        0 7       0
        --     BSB bytes: |    4N+3   |   4N+2   | 4N + 1   |   4N    |
        --                | MSB Re(N) | LSB Re(N)| MSB Im(N)| LSB Im(N)
        --                ---------------------------------------------
        --                31        24 23      16 15       8 7       0
        --     COeff:     |           Re(N)      |        Im(N)       |
        --                ---------------------------------------------
        -- xpm_memory_tdpram: True Dual Port RAM
        -- Xilinx Parameterized Macro, version 2022.2
        coeff_ram0 : xpm_memory_tdpram
        generic map (
            CLOCKING_MODE => "independent_clock",
            MEMORY_PRIMITIVE => "block",

            -- Port A (control port) geometry

            WRITE_DATA_WIDTH_A => 8,
            BYTE_WRITE_WIDTH_A => 8,
            READ_DATA_WIDTH_A  => 8,
            ADDR_WIDTH_A       => LOG2_COEFF_BYTES_PER_FRAME+LOG2_NUMBER_OF_COEFF_BANKS,
            READ_LATENCY_A     => RAM_LATENCY,

            -- Port B (coefficient readout port) geometry

            WRITE_DATA_WIDTH_B => COEFF_BITS_PER_WORD,
            BYTE_WRITE_WIDTH_B => COEFF_BITS_PER_WORD,
            READ_DATA_WIDTH_B  => COEFF_BITS_PER_WORD,
            ADDR_WIDTH_B       => LOG2_COEFF_WORDS_PER_FRAME+LOG2_NUMBER_OF_COEFF_BANKS,
            READ_LATENCY_B     => RAM_LATENCY,

            MEMORY_SIZE => COEFF_BITS_PER_WORD * COEFF_WORDS_PER_FRAME * NUMBER_OF_COEFF_BANKS, -- in bits

            USE_EMBEDDED_CONSTRAINT => 0,    -- DRC says 1 is only for distributed RAM

            -- defaults
            -- RST_MODE_A => "SYNC", RST_MODE_B => "SYNC", AUTO_SLEEP_TIME => 0, CASCADE_HEIGHT => 0, ECC_MODE => "no_ecc",
            -- MEMORY_INIT_FILE => "none", MEMORY_INIT_PARAM => "0", READ_RESET_VALUE_A => "0", READ_RESET_VALUE_B => "0",
            -- USE_MEM_INIT_MMI => 0, WAKEUP_TIME => "disable_sleep"
            MEMORY_OPTIMIZATION => "true",   -- String
            MESSAGE_CONTROL => 1,            -- for sims

            SIM_ASSERT_CHK => 0,             -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
            USE_MEM_INIT => 0,               -- DECIMAL

            WRITE_MODE_A => "no_change",     -- String
            WRITE_MODE_B => "no_change",     -- String
            WRITE_PROTECT => 1               -- DECIMAL
        )
        port map (
            -- Port A: 8-bit read/write programming interface

            addra => coeff_ram_ctrl_addr_int,
            dina => coeff_ram_ctrl_din,
            douta => coeff_ram_ctrl_dout,
            ena => '1',
            wea(0) => coeff_ram_ctrl_wr_en,
            clka => ctrl_clk,
            rsta => ctrl_rst,

            -- Port B: Gain coefficient readout port

            addrb => coeff_ram_addr,
            dinb => (others=>'0'),
            doutb => coeff_ram_dout,
            enb => '1',
            web(0) => '0',
            clkb => clk,
            rstb => '0',

            injectdbiterra => '0', injectdbiterrb => '0', injectsbiterra => '0', injectsbiterrb => '0',
            regcea => '1',
            regceb => '1',
            sleep => '0'

            );
    -- Implement the gain multipliers for both the REAL-only or complex gains configurations
    --
    ---------------
    -- COMPLEX gains
    ---------------
    mul_gen: if USE_COMPLEX_GAINS generate

        signal scaled_data_even_tdata: slv80;
        signal scaled_data_odd_tdata: slv80;

        signal coeff_even_din: slv32;
        signal coeff_odd_din: slv32;

        signal cmul0_a_tdata: std_logic_vector(47 downto 0);
        signal cmul1_a_tdata: std_logic_vector(47 downto 0);


    begin
        cplx_width_gen: if FFT_BINS_PER_WORD /= 2 generate
            assert FALSE report "Complex gains are currently only supported with 2 bins per word" severity FAILURE;
        end generate;

        -- fft data word:     MSB->LSB: Re(N),   Im(N),   Re(N+1), Im(N+1)
        -- gain word: MSB->LSB: Re(N+1), Im(N+1), Re(N),   Im(N)
        -- single multiplier product format: Im, Re
        -- Final scaled output format: MSB->LSB: Re(N), Im(N), Re(N+1), Im(N+1)

        -- Select gain coefficient for the even bin
        coeff_even_din <= coeff_ram_dout(15 downto 0) & coeff_ram_dout(31 downto 16); -- Im:Re
        cmul0_a_tdata <= ("000000" & in_dat_dly2_tdata(2*18+17 downto 2*18+0) & "000000" & in_dat_dly2_tdata(3*18+17 downto 3*18+0)); -- Im:Re, padded for byte align
        -- Instantiate complex multiplier for the even bin
        -- Data packing: byte-aligned, imaginary in the high bits
        cmul0: entity work.SCALER_CMUL
        PORT MAP (
            aclk => clk,
            s_axis_a_tvalid => in_dat_dly2_tvalid,
            s_axis_a_tuser => in_dat_dly2_tuser,
            s_axis_a_tlast => in_dat_dly2_tlast,
            s_axis_a_tdata => cmul0_a_tdata,
            s_axis_b_tvalid => in_dat_dly2_tvalid,
            s_axis_b_tdata => coeff_even_din,
            m_axis_dout_tvalid => scaled_data_tvalid,
            m_axis_dout_tuser => scaled_data_tuser,
            m_axis_dout_tlast => scaled_data_tlast,
            m_axis_dout_tdata => scaled_data_even_tdata
          );
          scaled_data_tdata(4*INTEGER_WIDTH - 1 downto 3*INTEGER_WIDTH) <= scaled_data_even_tdata(34 downto 0); -- Re(N)
          scaled_data_tdata(3*INTEGER_WIDTH - 1 downto 2*INTEGER_WIDTH) <= scaled_data_even_tdata(74 downto 40); -- Im(N)

          scaled_data_log_gain(1) <= resize(unsigned(post_scaler_left_shift), 6);


        -- Instantiate complex multiplier for the odd bin
         coeff_odd_din <= coeff_ram_dout(32+15 downto 32+0) & coeff_ram_dout(32+31 downto 32+16);
        cmul1_a_tdata <= ("000000" & in_dat_dly2_tdata(0*18+17 downto 0*18+0) & "000000" & in_dat_dly2_tdata(1*18+17 downto 1*18+0));
        cmul1: entity work.SCALER_CMUL
          PORT MAP (
            aclk => clk,
            s_axis_a_tvalid => in_dat_dly2_tvalid,
            s_axis_a_tuser => "00",
            s_axis_a_tlast => in_dat_dly2_tlast,
            s_axis_a_tdata => cmul1_a_tdata,
            s_axis_b_tvalid => in_dat_dly2_tvalid,
            s_axis_b_tdata => coeff_odd_din,
            m_axis_dout_tvalid => open,
            m_axis_dout_tuser => open,
            m_axis_dout_tlast => open,
            m_axis_dout_tdata => scaled_data_odd_tdata
          );

          -- remap the CMUL output into the scaled_data vector (order from MSB to LSB: Re(N), Im(N), Re(N+1), Im(N+1))
          scaled_data_tdata(2*INTEGER_WIDTH - 1 downto 1*INTEGER_WIDTH) <= scaled_data_odd_tdata(34 downto 0); -- Re(N+1)
          scaled_data_tdata(1*INTEGER_WIDTH - 1 downto 0*INTEGER_WIDTH) <= scaled_data_odd_tdata(74 downto 40); -- Im(N+1)

          scaled_data_log_gain(0) <= resize(unsigned(post_scaler_left_shift), 6);

    ---------------
    -- REAL gains
    ---------------
    else generate -- if no complex gains

        signal coeff: unsigned_array(0 to FFT_BINS_PER_WORD-1)(COEFF_BITS_PER_BIN-1 downto 0);
        signal fft_reg_tdata: signed_array(0 to INTEGERS_PER_WORD-1)(FFT_BITS_PER_BIN/2-1 downto 0);
        signal fft_reg_tvalid: std_logic;
        signal fft_reg_tlast: std_logic;
        signal fft_reg_tuser: std_logic_vector(FFT_TUSER_BITS_PER_WORD-1 downto 0);
        signal fft_reg_log_gain: unsigned_array(0 to FFT_BINS_PER_WORD-1)(5 downto 0);

--        signal scaled_data_tdata_dly1, scaled_data_tdata_dly2: std_logic_vector(INTEGER_WIDTH*INTEGERS_PER_WORD-1 downto 0);
        signal scaled_data_tvalid_dly1, scaled_data_tvalid_dly2: std_logic;
        signal scaled_data_tuser_dly1, scaled_data_tuser_dly2: std_logic_vector(FFT_TUSER_BITS_PER_WORD-1 downto 0);
        signal scaled_data_tlast_dly1, scaled_data_tlast_dly2: std_logic;
        signal scaled_data_log_gain_dly1, scaled_data_log_gain_dly2: unsigned_array(0 to FFT_BINS_PER_WORD-1)(5 downto 0);

--        constant MUL_B_WIDTH_MAX: integer := 18; -- use  2 multipliers if B_WIDTH (i.e. FFT data) > B_WIDTH_MAX
--        constant PROD_LO_WIDTH:integer := MUL_B_WIDTH_MAX + 1 + COEFF_BITS_PER_BIN + 1; -- b1 unsigned slice has a extra guard bit to make it signed
--        constant PROD_HI_WIDTH: integer := FFT_BITS_PER_BIN/2 - MUL_B_WIDTH_MAX + COEFF_BITS_PER_BIN + 1;

--        signal prod_re_lo_dly1, prod_im_lo_dly1: signed_array(0 to FFT_BINS_PER_WORD-1)(PROD_LO_WIDTH-1 downto 0);
--        signal prod_re_hi_dly1, prod_im_hi_dly1: signed_array(0 to FFT_BINS_PER_WORD-1)(PROD_HI_WIDTH-1 downto 0);
--        signal prod_re_dly1, prod_im_dly1: signed_array(0 to FFT_BINS_PER_WORD-1)(INTEGER_WIDTH-1 downto 0);

    begin

        -- fft data format:                    MSB->LSB: Re(N),   Im(N),   Re(N+1), Im(N+1)
        -- gain storage format (Complex gain): MSB->LSB: Re(N+1), Im(N+1), Re(N),   Im(N)
        -- gain storage format (Real gain):    MSB->LSB:                   Re(N+1), Re(N)
        -- product data format:                MSB->LSB: Re(N),   Im(N),   Re(N+1), Im(N+1)
        --
        -- BRAM storage format: (16bit gain words are is stored little-endian)
        --                -----------------------------------------------
        --                 7          0 7         0 7        0 7       0
        --     BSB bytes: |    2N+3    |   2N+2    | 2N + 1   |   2N    |
        --                | MSB G(N+1) | LSB G(N+1)| MSB G(N) | LSB G(N)
        --                -----------------------------------------------
        --                31        24 23      16 15       8 7       0
        --     COeff:     |           G(N+1)      |        G(N)          |
        --                ---------------------------------------------

        -- Real multiplier, A= 18/32 bit signed, B=16 bit unsigned, P=34/48 bit signed, Latency = 3
        gen_rmul: for i in 2 * FFT_BINS_PER_WORD - 1 downto 0 generate
            rmul0: entity work.scaler_mul
              generic map (
                A_WIDTH =>  FFT_BITS_PER_BIN/2,
                B_WIDTH =>  16
              )
              port map (
                CLK => clk,
                A => std_logic_vector(fft_reg_tdata(i)), -- 18/32-bit signed
                B => std_logic_vector(coeff(i / 2)), -- 16 bit unsigned
                P => scaled_data_tdata((i + 1) * INTEGER_WIDTH - 1 downto i * INTEGER_WIDTH) -- 34/48 bit signed
              );
        end generate;

        mul_proc: process (all)
            variable coeff_var: unsigned(COEFF_BITS_PER_BIN - 1 downto 0);
        begin
            if rising_edge(clk) then
                -- Clock 0: Register the gain and fft values at the input of the mutiplier.
                -- These registers can be absorbed as the input registers
                -- of the DSP48 block and should greatly help with timing closure.
                for i in FFT_BINS_PER_WORD - 1 downto 0 loop
                    -- Extract 16-bit coefficient. Word order is reversed coming out of RAM.
                    coeff_var := unsigned(coeff_ram_dout((FFT_BINS_PER_WORD - 1 - i + 1) * COEFF_BITS_PER_BIN - 1 downto (FFT_BINS_PER_WORD-1-i)*COEFF_BITS_PER_BIN));
                    if use_float_gains then
                        fft_reg_log_gain(i) <= resize(coeff_var(COEFF_BITS_PER_BIN - 1 downto COEFF_BITS_PER_BIN - 5), 6) + resize(unsigned(post_scaler_left_shift), 6); -- upper 5 bits are the log gain, which is added to the common log gain
                        coeff(i) <= resize(coeff_var(COEFF_BITS_PER_BIN - 6 downto 0), COEFF_BITS_PER_BIN); -- resize prepends zeros. Signed value will be positive.
                    else
                        fft_reg_log_gain(i) <= resize(unsigned(post_scaler_left_shift), 6);
                        coeff(i) <= coeff_var;
                    end if; -- if USE_FLOAT_GAINS
                end loop;


                -- Register the data bus. This register could also be absorbed in the DSP48
                for i in 2 * FFT_BINS_PER_WORD - 1 downto 0 loop
                    fft_reg_tdata(i) <= signed(in_dat_dly2_tdata((i + 1) * FFT_BITS_PER_BIN / 2 - 1 downto i * FFT_BITS_PER_BIN / 2));
                end loop;
                fft_reg_tvalid <= in_dat_dly2_tvalid;
                fft_reg_tlast <= in_dat_dly2_tlast;
                fft_reg_tuser <= in_dat_dly2_tuser;

                -- Delay the bus control and log gain signals to match the multiplier latency
                -- Clock 1
                scaled_data_tvalid_dly1 <= fft_reg_tvalid;
                scaled_data_tlast_dly1 <= fft_reg_tlast;
                scaled_data_tuser_dly1 <= fft_reg_tuser;
                scaled_data_log_gain_dly1 <= fft_reg_log_gain;

                -- Clock 2
                scaled_data_tvalid_dly2 <= scaled_data_tvalid_dly1;
                scaled_data_tlast_dly2 <= scaled_data_tlast_dly1;
                scaled_data_tuser_dly2 <= scaled_data_tuser_dly1;
                scaled_data_log_gain_dly2 <= scaled_data_log_gain_dly1;

                -- Clock 3: Multiplier Products appears on this clock
                scaled_data_tlast <= scaled_data_tlast_dly2;
                scaled_data_tvalid <= scaled_data_tvalid_dly2;
                scaled_data_tuser <= scaled_data_tuser_dly2;
                scaled_data_log_gain <= scaled_data_log_gain_dly2;

                if rst_reg then
                    fft_reg_tvalid <= '0';
                    scaled_data_tvalid_dly1 <= '0';
                    scaled_data_tvalid_dly2 <= '0';
                end if; -- rst

            end if; --clk
        end process;
    end generate mul_gen;


-------------------------------------------------------------------
-- Apply shift, saturation, and assign outputs
-------------------------------------------------------------------
-- Reads the input bus, scales the values, and send them to the output bus.
--
    scaler_proc: process(all)
        variable scaled_data_log_gain_var: integer range 0 to 63;
    --    variable stage1_word_var: int35_array(3 downto 0);
        variable word_var: signed(INTEGER_WIDTH-1 downto 0);
        variable OUT_WORD_VAR: signed_array(0 to INTEGERS_PER_WORD - 1)(7 downto 0);
        variable round_down_var: std_logic;
    begin
        if rising_edge(clk) then

            rst_reg <= soft_reset or reset;

            -- Count the bin numbers to address the coefficient RAM
            if s_axis_in_tvalid='1' then
                word_ctr <= word_ctr + 1;
                if s_axis_in_tlast='1' then
                    word_ctr <= (others=> '0');
                    frame_ctr <= frame_ctr + 1;
                    if synchronize_gain_bank_switch='0' or std_logic_vector(frame_ctr) = gain_bank_switch_frame_number then
                        current_gain_bank <= next_gain_bank;
                    end if;
                end if;
            end if;


            -- Pipeline the data to compensate for the RAM access latency to
            -- the coefficients arrive at the same time as their corresponding
            -- bin. Also use the pipeline to propagate the signal to the output
            -- in bypass modes.

            in_dat_dly1_tdata  <= s_axis_in_tdata;
            in_dat_dly1_tvalid <= s_axis_in_tvalid;
            in_dat_dly1_tlast  <= s_axis_in_tlast;
            in_dat_dly1_tuser  <= s_axis_in_tuser;


            in_dat_dly2_tdata  <= in_dat_dly1_tdata;
            in_dat_dly2_tvalid <= in_dat_dly1_tvalid;
            in_dat_dly2_tlast  <= in_dat_dly1_tlast;
            in_dat_dly2_tuser  <= in_dat_dly1_tuser;


            -- RESET:  See at the bottom of this process

            ----------
            -- Scaling
            ----------

            -- PIPELINE STAGE 1: Implement a barrel shifter to
            -- shift-left the read/imaginary parts of the products and
            -- determine if there is an overflow
            stage1_tvalid  <= scaled_data_tvalid;
            stage1_tlast   <= scaled_data_tlast;
            stage1_tuser   <= scaled_data_tuser;

            for i in 0 to INTEGERS_PER_WORD-1 loop
                -- get an integer. The to_10() standard function makes sure that 'U' values are converted to zeros and
                -- prevent simulation warnings in the following computations
                word_var := to_01(signed(scaled_data_tdata((i+1)*INTEGER_WIDTH-1 downto i*INTEGER_WIDTH)));

                -- Store the sign bit before shifting
                stage1_sign(i) <= sign_bit(word_var); -- preserve the sign that may be destroyed by the shift operation
                -- Store the shifted integer. We'll fix overflows in the next phase.
                -- convert shift value into an integer
                scaled_data_log_gain_var := to_integer(scaled_data_log_gain(i/2));
                stage1_word(i) <= shift_left(word_var, scaled_data_log_gain_var);

                -- Determine if all bits shifted out and the final sign bits have the same sign as the sign bit. If not, we are in overflow condition.
                -- Note: We cannot use and_reduce() with a range determined from a variable: it does not synthersize. But we can compare a variable range of a
                -- signed value with a constant.

--                stage1_overflow(i) <= not to_std_logic(word_var(INTEGER_WIDTH-1 downto INTEGER_WIDTH-1-scaled_data_log_gain_var)=0 or
--                                                   word_var(INTEGER_WIDTH-1 downto INTEGER_WIDTH-1-scaled_data_log_gain_var)=-1);
                stage1_overflow(i) <= '0';
                for j in 1 to word_var'LENGTH-1 loop
                    if j <= scaled_data_log_gain_var and word_var(word_var'LENGTH-1-j) /= sign_bit(word_var) then
                        stage1_overflow(i) <= '1';
                    end if;
                end loop;
            end loop;


            -- PIPELINE STAGE 2: apply rounding and detect rounding overflows
            stage2_tvalid  <= stage1_tvalid;
            stage2_tlast   <= stage1_tlast;
            stage2_tuser   <= stage1_tuser;
            stage2_sign <= stage1_sign;
            stage2_overflow <= stage1_overflow; -- overriden below if rounding overflow detected
            for i in 0 to INTEGERS_PER_WORD-1 loop
                if four_bits = '1' or EIGHT_BIT_SUPPORT = FALSE then
                    if rounding_mode = ROUNDING_MODE_CONVERGENT_ROUND or rounding_mode = ROUNDING_MODE_ROUND then -- if rounding
                        stage2_word(i)(7 downto 4) <= msb(msb(stage1_word(i), 4 + 1) + 1, 4);
                        stage2_word(i)(3 downto 0) <= "0000";
                        round_down_var := to_std_logic(rounding_mode = ROUNDING_MODE_CONVERGENT_ROUND and stage1_word(i)(INTEGER_WIDTH-1-4)='1' and stage1_word(i)(INTEGER_WIDTH-1-4-1 downto 0)=0);
                        if round_down_var = '1' then
                            stage2_word(i)(4) <= '0';
                        end if;
                        -- Detect post-rounding saturations to be applied on next pipeline stage
                        -- First: if the rounding causes a positive value to overflow (rounds 7.5 to -8)
                        if msb(stage1_word(i), 5) = "01111" then -- If we have a tie, convergent rounding would make the number even, but it's already even after rounding, so the test is the same for normal and convergent rounding.
                            stage2_overflow(i) <= '1';-- the rounding will cause a overflow
                        -- Second, if the rounding adds 0.5, so we can never overflow a negative value.
                        -- Instead, here we check that the value is not -8 after rounding, so we can saturate to -7 if symmetric saturation is enabled
                        -- We check for 2 conditions.
                        --     a) we had -8.0 prior to rounding, so we are still -8 after rounding.
                        --     b) We were -7.5 and rounded back down to -8 by convergent rounding
                        elsif symmetric_saturation='1' and ( msb(stage1_word(i), 5) = "10000" or (msb(stage1_word(i), 5) = "10001" and round_down_var = '1')) then --if the rounding causes a negative value to overflow
                            stage2_overflow(i) <= '1';-- the rounded value will exceed -7
                        end if;
                    else -- no rounding (i.e truncate)
                        stage2_word(i)(7 downto 4) <= msb(stage1_word(i), 4);
                        stage2_word(i)(3 downto 0) <= "0000";
                        if symmetric_saturation='1' and msb(stage1_word(i), 4) = "1000" then --if the rounding causes a negative value to overflow
                            stage2_overflow(i) <= '1';
                        end if;
                    end if;

                elsif EIGHT_BIT_SUPPORT then -- four_bits = '0'
                    if rounding_mode = ROUNDING_MODE_CONVERGENT_ROUND or rounding_mode = ROUNDING_MODE_ROUND then -- if rounding
                        stage2_word(i) <= msb(msb(stage1_word(i), 8 + 1) + 1, 8);
                        round_down_var := to_std_logic(rounding_mode = ROUNDING_MODE_CONVERGENT_ROUND and stage1_word(i)(INTEGER_WIDTH-1-8)='1' and stage1_word(i)(INTEGER_WIDTH-1-8-1 downto 0)=0);
                        if round_down_var = '1' then
                            stage2_word(i)(0) <= '0';
                        end if;
                        -- Detect saturations to be applied on next pipeline stage
                        if msb(stage1_word(i), 9) = "011111111" then --if the rounding causes a positive value to overflow
                            stage2_overflow(i) <= '1';-- the rounding will cause a overflow
                        elsif symmetric_saturation='1' and ( msb(stage1_word(i), 9) = "100000000" or (msb(stage1_word(i), 9) = "100000001" and round_down_var = '1')) then --if the rounding causes a negative value to overflow
                            stage2_overflow(i) <= '1';-- the rounded value will exceed -7
                        end if;
                    else -- no rounding (i.e. truncate)
                        stage2_word(i) <= msb(stage1_word(i), 8);
                        if symmetric_saturation='1' and msb(stage1_word(i), 8) = "10000000" then --if the rounding causes a negative value to overflow
                            stage2_overflow(i) <= '1';
                        end if;
                    end if;
                end if;
            end loop;

            -- PIPELINE STAGE 3: Correct final result

            -- Stage 3a: Apply saturation
            for i in 0 to INTEGERS_PER_WORD-1 loop
                OUT_WORD_VAR(i) := stage2_word(i);
                if stage2_overflow(i) then
                    if stage2_sign(i)='0' then
                        OUT_WORD_VAR(i) := X"7F"; -- if a positive value overflowed in 4-bit or 8-bit mode
                    elsif symmetric_saturation ='0' then
                        OUT_WORD_VAR(i) :=X"80"; -- if a negative value overflow in 4-bit or 8-bit mode, and we do NOT saturate at -7
                    elsif four_bits='0' and EIGHT_BIT_SUPPORT=TRUE then
                        OUT_WORD_VAR(i) :=X"81"; -- if a negative value overflow in 8 bit mode, and we saturate at -7
                    else
                        OUT_WORD_VAR(i) :=X"90"; -- if a negative value overflow in 4 bit mode, and we saturate at -7
                    end if;
                end if;
            end loop;

            -- Stage 3b: Zero Re/Im pairs on overflows if requested
            if zero_on_saturation then
                for i in 0 to FFT_BINS_PER_WORD-1 loop
                    if stage2_overflow(2*i to 2*i+1) /= "00" then
                        OUT_WORD_VAR(2*i) := X"00";
                        OUT_WORD_VAR(2*i+1) := X"00";
                    end if;
                end loop;
            end if;

            -- Stage 3c: apply offset encoding if requested
            if use_offset_binary='1' then
                for i in 0 to INTEGERS_PER_WORD-1 loop
                    OUT_WORD_VAR(i)(7) := not OUT_WORD_VAR(i)(7); -- Implement offset binary by inverting the sign bit.
                end loop;
            end if;

            -- Stage 3d: Clear lower nibble in 4-bit mode
            if four_bits='1' or EIGHT_BIT_SUPPORT = FALSE then
                for i in 0 to INTEGERS_PER_WORD-1 loop
                    OUT_WORD_VAR(i)(3 downto 0) := "0000";
                end loop;
            end if;

            -- Register saturated/zeroed/encoded outputs
            stage3_word <= OUT_WORD_VAR;
            stage3_tvalid <= stage2_tvalid;
            stage3_tlast <= stage2_tlast;
            stage3_overflow <= stage2_overflow;
            stage3_sign <= stage2_sign;
            stage3_tuser <= stage2_tuser;

            -- Synchronous reset
            if rst_reg then
                stage1_tvalid <= '0'; --needed
                stage2_tvalid <= '0'; --needed
                stage3_tvalid <= '0'; --needed
                in_dat_dly1_tvalid <= '0';
                in_dat_dly2_tvalid <= '0';
                word_ctr <= (others=> '0');
                frame_ctr <= (others=> '0');
                current_gain_bank <= '0';
            end if; -- IF RST

        end if; -- clk
    end process scaler_proc;

    -- Assign MAIN OUTPUT
    out_blk: block begin
        process(all) begin
            if rising_edge(clk) then
                -- Stage 4a: Assign Main outputs

                -- Set defaults in case we don't assign them below
                m_axis_out_tdata<= (others => '0');
                m_axis_out_tuser <= (others => '0'); -- sets flags only set on last frame to 0

                m_axis_out_tuser(FFT_TUSER_BITS_PER_WORD-1 downto 0) <= stage3_tuser; -- pass on the USER bits
                -- Add gain bank flag
                -- Todo: make sure the gain flag is synchronized
                m_axis_out_tuser(FFT_TUSER_BITS_PER_WORD) <= current_gain_bank when stage3_tvalid and stage3_tlast;

                -- Set the scaler overflow bits in the user data.

                m_axis_out_tlast <= stage3_tlast;
                m_axis_out_tvalid <= stage3_tvalid;

                case? bypass_scaler & bypass_data_type is
                    when "0--" => -- send the 4+4 bit scaled values
                        for i in 0 to FFT_BINS_PER_WORD-1 loop
                            m_axis_out_tdata((2*i+1)*OB/2-1 downto (2*i+0)*OB/2) <= msb_pad(std_logic_vector(stage3_word(2*i)), OB/2); -- MSB->LSB: 3,2,1,0 = Re(N), Im(N), Re(N+1), Im(N+1)
                            m_axis_out_tdata((2*i+2)*OB/2-1 downto (2*i+1)*OB/2) <= msb_pad(std_logic_vector(stage3_word(2*i+1)), OB/2); -- MSB->LSB: 3,2,1,0 = Re(N), Im(N), Re(N+1), Im(N+1)
                            m_axis_out_tuser(FFT_TUSER_BITS_PER_WORD+i+1) <= stage3_overflow(2*i) or stage3_overflow(2*i+1); -- Set overflow flag if either Re or Im overflow
                        end loop;

                    when "100" => -- send the MSBs of the raw FFT input. Used to send FUNCGEN data to correlator/corner-turn engines with FFT bypass
                        for i in 0 to INTEGERS_PER_WORD-1 loop
                            m_axis_out_tdata((i+1)*OB/2-1 downto i*OB/2) <= msb_pad(in_dat_dly1_tdata((i+1)*FB/2-1 downto i*FB/2), OB/2);
                        end loop;
                        m_axis_out_tlast <= in_dat_dly1_tlast;
                        m_axis_out_tvalid <= in_dat_dly1_tvalid;
                        m_axis_out_tuser(FFT_TUSER_BITS_PER_WORD-1 downto 0) <= in_dat_dly1_tuser;

                    when "101" => -- Send 1+0j on overflow. Autocorr counts any saturation
                        for i in 0 to FFT_BINS_PER_WORD-1 loop
                             m_axis_out_tdata((2*i+2)*OB/2-4) <= '1' when stage3_overflow(2*i)='1' or stage3_overflow(2*i+1)='1'; -- set LSB of upper 4 bits, Re only
                        end loop;
                    when "110" => -- Send (1+0j) if Re has a positive saturation and (0+1j) if it has a negative saturation. Autocorr is 0 of positive and negative Re  saturations are balanced
                        for i in 0 to FFT_BINS_PER_WORD-1 loop
                            if  stage3_overflow(2*i+1)='1' then -- Re overflow
                                if stage3_sign(2*i+1)='0' then -- if positive Re overflow set output to 1+0j
                                    m_axis_out_tdata((2*i+2)*OB/2-4) <= '1'; -- set LSB of upper 4 bits of Re part
                                else -- if negative Re overflow, set output to 0+1j
                                    m_axis_out_tdata((2*i+1)*OB/2-4) <= '1'; -- set LSB of upper 4 bits of Im part
                                end if;
                            end if;
                        end loop;
                    when "111" => -- Send (1+0j) if Im has a positive saturation and (0+1j) if it has a negative saturation. Autocorr is 0 of positive and negative Im saturations are balanced
                        for i in 0 to FFT_BINS_PER_WORD-1 loop
                            if  stage3_overflow(2*i)='1' then -- Im overflow
                                if stage3_sign(2*i)='0' then -- if positive Im overflow set output to 1+0j
                                    m_axis_out_tdata((2*i+2)*OB/2-4) <= '1'; -- set LSB of upper 4 bits of Re part
                                else -- if negative Im overflow, set output to 0+1j
                                    m_axis_out_tdata((2*i+1)*OB/2-4) <= '1'; -- set LSB of upper 4 bits of Im part
                                end if;
                            end if;
                        end loop;
                    when others=>
    --                    assert FALSE report "Unhandled data type case" severity FAILURE;
                end case?;

                -- Synchronous resets
                if rst_reg then
                    m_axis_out_tvalid <= '0'; -- by default, nothing is coming out, unless something is coming in, in which case this asignment is overriden below
                end if; --rst
                    -- If we reset, override key signals only
            end if; -- clk
        end process;
    end block out_blk;


    -- Assign CAPTURE OUTPUT
    cap_blk: block

        signal fres_tdata: slv_array(0 to 1)(FFT_BITS_PER_BIN/2-1 downto 0); -- Delayed Re/Im pair
        signal fres_flags: slv_array(0 to 1)(1 downto 0);

--        signal fres_tuser_reg, fres_tuser_reg2: std_logic_vector(FFT_TUSER_BITS_PER_WORD-1 downto 0);

--        signal fres_send_im, fres_send_tlast: std_logic;
--        signal fres_frame_reg, fres_word_reg, fres_tlast_reg: std_logic;

--        signal in_dat_dly1_tdata_reg  : std_logic_vector(FFT_BITS_PER_WORD-1 downto 0);
--        signal in_dat_dly1_tvalid_reg : std_logic;
--        signal in_dat_dly1_tlast_reg  : std_logic;
--        signal in_dat_dly1_tuser_reg  : std_logic_vector(FFT_TUSER_BITS_PER_WORD-1 downto 0);  --

        signal in_dat_dly1_word_ctr   : unsigned(1 downto 0); -- counts words for double and quad resolution modes
        signal in_dat_dly1_frame_ctr  : unsigned(INTEGER_LOG2(FFT_BINS_PER_WORD) downto 0); -- counts frames double and full resolution modes. Needs 2 frames (Re, Im) per bin in full res mode.
--        signal subword_ctr  : unsigned(1 downto 0); -- counts transmitted words for double and quad resolution modes
    begin
        process(all)
            variable pos: integer; -- integer representation of subword_ctr
--            variable subword_ctr_width: integer range 1 to 2; -- number of bits needed to count subwords
            variable fres_re_var, fres_im_var: std_logic_vector(FFT_BITS_PER_BIN/2-1 downto 0);
            variable fres_tdata_var: slv_array(0 to 2)(FFT_BITS_PER_BIN/2-1 downto 0);
            variable fres_flags_var: slv_array(0 to 2)(1 downto 0);
        begin
            if rising_edge(clk) then


                -- Count words and frames on in_dat_dly1
                if in_dat_dly1_tvalid then
                    in_dat_dly1_word_ctr <= in_dat_dly1_word_ctr + 1;
                    if in_dat_dly1_tlast then
                        in_dat_dly1_word_ctr <= (others => '0');
                        in_dat_dly1_frame_ctr <= in_dat_dly1_frame_ctr + 1;
                    end if;
                end if;
                if rst_reg then
                    in_dat_dly1_word_ctr <= (others => '0');
                    in_dat_dly1_frame_ctr <= (others => '0');
                end if;



                -- Stage 3e: Assign Capture outputs

                m_axis_cap_tdata <= (others => '0'); -- ensure any unassigned bit is zero
                m_axis_cap_tuser <= (others => '0');
                m_axis_cap_tuser(FFT_TUSER_BITS_PER_WORD) <= m_axis_out_tuser(FFT_TUSER_BITS_PER_WORD); -- current gain bank
                m_axis_cap_tlast <= in_dat_dly1_tlast; -- default framing sources
                m_axis_cap_tvalid <= in_dat_dly1_tvalid;
                -- Count capture frames for debugging
                if m_axis_cap_tvalid and m_axis_cap_tlast then
                    cap_frame_ctr <= cap_frame_ctr + 1;
                end if;

                case cap_data_type is
                    when "000" => -- send main scaler output (default)
                        for i in 0 to INTEGERS_PER_WORD-1 loop
                            m_axis_cap_tdata((i+1)*CB/2-1 downto i*CB/2) <= msb_pad(m_axis_out_tdata((i+1)*OB/2-1 downto i*OB/2), CB/2);
                        end loop;
                        m_axis_cap_tlast <= m_axis_out_tlast;
                        m_axis_cap_tvalid <= m_axis_out_tvalid;
                        m_axis_cap_tuser <= m_axis_out_tuser;

                    when "001" => -- send MSBs of pre-gain (raw) FFT output

                        -- We forward the upper N bits of the FFT integers to the upper N bits of the output integer
                        for i in 0 to INTEGERS_PER_WORD-1 loop
                            m_axis_cap_tdata((i+1)*CB/2-1 downto i*CB/2) <= msb_pad(in_dat_dly1_tdata((i+1)*FB/2-1 downto i*FB/2), CB/2);
                        end loop;
                        m_axis_cap_tuser(FFT_TUSER_BITS_PER_WORD-1 downto 0) <= in_dat_dly1_tuser;


                    when "010" => -- send MSBs of the post-gain FFT output with saturation
                        for i in 0 to INTEGERS_PER_WORD-1 loop
                            m_axis_cap_tdata((i+1)*CB/2-1 downto i*CB/2) <=
                                ('1', others => '0') when stage1_overflow(i)='1' and stage1_sign(i)='1' else
                                ('0', others => '1') when stage1_overflow(i)='1' and stage1_sign(i)='0' else
                                msb(std_logic_vector(stage1_word(i)), CB/2);
                        end loop;
                        m_axis_cap_tlast <= stage1_tlast;
                        m_axis_cap_tvalid <= stage1_tvalid;
                        m_axis_cap_tuser(FFT_TUSER_BITS_PER_WORD-1 downto 0) <= stage1_tuser;

                    when "011" => -- send the 4+4 bit scaled values
                        for i in 0 to INTEGERS_PER_WORD-1 loop
                            m_axis_cap_tdata((i+1)*CB/2-1 downto i*CB/2) <= msb_pad(std_logic_vector(stage3_word(i)), CB/2); -- MSB->LSB: 3,2,1,0 = Re(N), Im(N), Re(N+1), Im(N+1)
                        end loop;
                        m_axis_cap_tlast <= stage3_tlast;
                        m_axis_cap_tvalid <= stage3_tvalid;
                        m_axis_cap_tuser(FFT_TUSER_BITS_PER_WORD-1 downto 0) <= stage3_tuser;

                    when "100"  => -- Double  resolution modes: send even bins on even frames and odd bins on odd frames at twice the bit width
                        -- for CRS: CB=128/4= 32 bits/bin (CB/2+CB/2) = (16+16) = 32 bits/bin, 2x mode => (CB+CB)= (32 + 32) = 2*CB  = 64 bits/bin,  4/2=2 bins/word, 8/2= 4 integers/word
                        -- for ICE: CB=32/2= 16 bits/bin= (CB/2+CB/2) = (8+8) , 2x mode => 32 bits/bin, (16+16)= 32 bits/bin,  2/2=1 bin/word, 4/2= 2 integers/word

                        pos := to_integer(in_dat_dly1_frame_ctr(0 downto 0));
                        for i in 0 to IPW/4-1 loop -- 0 to 1 for CRS, 0 to 0 for ICE
                            set_subword(m_axis_cap_tdata, msb_pad(get_subword(in_dat_dly1_tdata, FB/2, 4*i+2*pos, from_msb => TRUE), CB), 2*i, from_msb => TRUE); -- Re
                            set_subword(m_axis_cap_tdata, msb_pad(get_subword(in_dat_dly1_tdata, FB/2, 4*i+2*pos+1, from_msb => TRUE), CB), 2*i+1, from_msb => TRUE); -- Im
--                            m_axis_cap_tdata((IPW/4-i)*CB-1 downto (IPW/4-i-1)*CB) <= msb_pad(in_dat_dly1_tdata((IPW/2 - IPW/4 * subword - i) * FB - 1  downto (IPW/2 - IPW/4 * subword -i -1) * FB), CB);
                        end loop;
                    when  "101" => -- Full resolution mode (Re and Im each in their full capture word) sent over 2*B frames, where B is the number fo bins per word,
                        --
                        -- Full resolution mode sends each Re or Im component of the raw FFT output with the full witdh of the capture output.
                        -- We send Re on one clock and Im on the following clock, as it is important that both component come from the same frame.
                        -- We therefore only send only half the bins per frame: the even bins are sent on even frames, and the odd bins on the odd frames.
                        -- Since a FFT word contains multiple bins, we send the top bin on the first 2 frames, then the next bins on the next 2 frames etc.
                        -- If the FFT has 2 bins per word, it takes 4 consecutive frames to transmit all bins. It it has 4 bins per frames, it takes 8 consicutive frames,
                        -- Due to memory limitations, we cannot store the first frame and send the captured data in multiple subsequent frames.
                        -- Each frame is based on new input data, so arteftacts may occur is the spectrum of the measured signal varies between frames.
                        --
                        -- In this implementation, we implement a 2-element shift register FIFO to store the even bins on even frames and odd bins on odd frames.
                        -- The Re and Im parts are placed in the FIFO, with a flag indicating their status:
                        --   "00": no element
                        --   "01": Valid element , but seed to grab tlast on next odd word
                        --   "10": Valid element, tlast=0
                        --   "11": Valid element, tlast=1
                        -- In order not to miss the tlast on the original stream (which is always on an odd word),
                        -- Im bin grabbed on an even word are flagged so the tlast signal on the following odd word will be applied to it.
                        -- A word is not pushed out of the FIFO until its tlast status is resolved, so we can operate even if words are widely spaced (with a lot of tvalid=0).

                        -- Extract a single complex number from the FFT vector
                        pos := to_integer(in_dat_dly1_frame_ctr(INTEGER_LOG2(FFT_BINS_PER_WORD) downto 1));
                        fres_re_var := get_subword(in_dat_dly1_tdata, FFT_BITS_PER_BIN/2, 2*pos, from_msb => TRUE);
                        fres_im_var := get_subword(in_dat_dly1_tdata, FFT_BITS_PER_BIN/2, 2*pos+1, from_msb => TRUE);

                        m_axis_cap_tvalid <='0';

                        -- get the current flags and data, allowing one extra slot in case we need it
                        -- We will shift left: the element to be sent out is in posiiton 0
                        fres_flags_var:= (fres_flags(0), fres_flags(1), "00");
                        fres_tdata_var := (fres_tdata(0), fres_tdata(1), (others => '0'));

                        -- Append new Re/Im pair to the list when on the right word and frame
                        if in_dat_dly1_tvalid='1' and in_dat_dly1_frame_ctr(0) = in_dat_dly1_word_ctr(0)  then -- Put odd or even word at end of fifo
                            pos := 0 when fres_flags_var(0) = "00" else 1 when fres_flags_var(1)="00" else 2; -- first free slot
                            assert pos <=1 report "fres: full res overflow" severity ERROR;
                            fres_tdata_var(pos) := fres_re_var;  fres_flags_var(pos) := "10"; -- Store Re. It is valid  and not tlast,
                            fres_tdata_var(pos + 1) := fres_im_var; fres_flags_var(pos + 1) := "01"; -- Store Im. Its tlast needs to be resolved
                        end if;

                        -- Resolve pending tlast on odd words. This is either an even bin aded previously, or an odd bin that was just added now
                        for i in 0 to 2 loop
                            fres_flags_var(i) := ('1' , in_dat_dly1_tlast) when fres_flags_var(i)="01" and in_dat_dly1_tvalid = '1' and in_dat_dly1_word_ctr(0)='1';
                        end loop;

                        -- Shift out element 0 to output if we have data ready to go
                        if fres_flags_var(0) ?= "1-" then
                            m_axis_cap_tdata <= msb_pad(fres_tdata_var(0),  m_axis_cap_tdata'LENGTH);
                            m_axis_cap_tvalid <= fres_flags_var(0)(1);
                            m_axis_cap_tlast <= fres_flags_var(0)(0);
                            fres_tdata_var(0 to 1) := fres_tdata_var(1 to 2);
                            fres_flags_var(0 to 1) := fres_flags_var(1 to 2);
                            fres_flags_var(2) := "00"; -- not needed except for checks below
                        end if;
                        assert fres_flags_var(2) = "00" report "fres: too much data left in fifo";
                        fres_tdata <= fres_tdata_var(0 to 1);
                        fres_flags <= fres_flags_var(0 to 1);


                    when "110" => -- send saturation flags, for each Re and Im part: 0 = no sat, 1 = positive sat, -1 = negative sat

                        for i in 0 to IPW-1 loop
                            m_axis_cap_tdata((i+1)*CB/2-1 downto i*CB/2) <=
                                ('1', others => '0') when stage1_overflow(i)='1' and stage1_sign(i)='1' else
                                ('0', others => '1') when stage1_overflow(i)='1' and stage1_sign(i)='0' else
                                ('0', others => '0');
                        end loop;
                        m_axis_cap_tlast <= stage1_tlast;
                        m_axis_cap_tvalid <= stage1_tvalid;
                        m_axis_cap_tuser(FFT_TUSER_BITS_PER_WORD-1 downto 0) <= stage1_tuser;


                    when others =>
    --                    assert FALSE report "Unhandled data type case" severity FAILURE;
                end case;

                if rst_reg then
--                    fres_send_im <= '0';
                    fres_flags <= (others => "00");
                end if;

            end if; --clk
        end process;
    end block cap_blk;

    dlycap_blk: block begin
        process(all) begin
            if rising_edge(clk) then
                -- Computes how many clocks it takes for the first frame to arrive after reset
                if rst_reg then
                    delay_capture_ctr <= (others=> '0');
                    delay_capture_ctr_en <= '1';
                elsif delay_capture_ctr_en  then
                    delay_capture_ctr <= delay_capture_ctr + 1;
                    if signed(delay_capture_ctr)=-2 or in_dat_dly2_tvalid='1' then
                        delay_capture_ctr_en <= '0';
                    end if;
                end if;

            end if; -- clk
        end process;
    end block dlycap_blk;

    ----------------------------------
    -- Statistics logic
    ----------------------------------
    -- Counts the number of scaler and ADC frame overflows over a specific number of frames

    stats_blk: block
        signal stats_frame_ctr: unsigned(23 downto 0);
        signal stats_word_ctr: unsigned(LOG2_FFT_WORDS_PER_FRAME-1 downto 0);

        signal scaler_overflow_ctr: unsigned(15+1 downto 0); -- one extra bit for carry
        signal adc_overflow_ctr: unsigned(15+1 downto 0);

        signal stats_capture_resync: std_logic;
--        signal stats_first_frame: std_logic;
        signal last_frame: std_logic;

        signal n_sat1: unsigned(3 downto 0); -- 0 to 8 saturations
        signal use_bin1: std_logic;
--        signal add_bin1: std_logic;
        signal last_bin1, last_bin2: std_logic;
        signal first_bin0, first_bin1: std_logic;
        signal adc_flag1: std_logic;

    begin

        -- resynchronize the stats_capture signal to make sure we have clean captures
        stats_capture_cdc0: xpm_cdc_single
            generic map (SRC_INPUT_REG => 0)
            port map (src_clk => '0', src_in => stats_capture, dest_clk => clk, dest_out => stats_capture_resync);

        --
        stat_proc: process(all)
--            variable scaler_overflow_var: unsigned(scaler_overflow_ctr'RANGE);
            variable n_sat_var: unsigned(n_sat1'RANGE);
        begin
            if rising_edge(clk) then

                -- Channel FIFO overflow monitoring
                --if rst_reg='1' or fifo_overflow_reset='1' then
                --    fifo_overflow_sticky <= '0';
                --elsif fifo_overflow='1' then
                --    fifo_overflow_sticky <= '1';
                --end if;

                fifo_overflow_sticky <= '0' when rst_reg or fifo_overflow_reset else
                                        '1' when fifo_overflow;



                -- Phase 0
                ----------
                -- Set n_sat, use_bin, first_bin, new_integ

                -- Register the last frame flag to help timing. Changes on tlast, and we use it only on the following tlast, so we don't mind the latency
                last_frame <=  to_std_logic(stats_frame_ctr = stats_frame_count);

                use_bin1 <= '0'; -- inactive unless overriden below
                last_bin1 <= '0'; -- single pulse, overriden below
--                add_bin1 <= '0' when last_bin1 else
--                            '1' when use_bin1; -- overriden below. Start adding as soon as we've processed usable bin
                adc_flag1 <= '0';
                if stage3_tvalid then
                    use_bin1 <= '1' when stats_single_bin='0' or stats_word_ctr = stats_bin_number(stats_word_ctr'RANGE) else '0';
                    stats_word_ctr <= stats_word_ctr + 1;
                    first_bin0 <= '0';
                    first_bin1 <= first_bin0;
                    if stage3_tlast then
                        stats_frame_ctr <= stats_frame_ctr + 1;
                        stats_word_ctr <= (others => '0');
                        adc_flag1 <= stage3_tuser(TUSER_ADC_OVERFLOW_BIT);
                        if last_frame then -- stats_last_frame has time to register before the next TLAST.
                            first_bin0 <= '1';
                            last_bin1 <= '1';
                            stats_frame_ctr <= (0 => '1', others => '0');
                        end if;
                    end if;
                end if;

                -- Count scaler overflows
                -- Determine if how many scaler overflows we have on this word sample
                -- We count a saturation on either the real or imaginary part as a single count
                n_sat_var := (others => '0');
                for i in 0 to FFT_BINS_PER_WORD-1 loop
                    if stage3_overflow(2*i) or stage3_overflow(2*i+1) then
                        n_sat_var := n_sat_var +1;
                    end if;
                end loop;
                n_sat1 <= n_sat_var;

               -- Phase 2
               -- Add sats
               if first_bin1 then
                    scaler_overflow_ctr <= resize(n_sat1, scaler_overflow_ctr'LENGTH) when use_bin1  else
                                           (others => '0');
               elsif use_bin1 and not msb(scaler_overflow_ctr) then -- stop adding if the carry is set: we have overflown
                         scaler_overflow_ctr <= scaler_overflow_ctr + resize(n_sat1, scaler_overflow_ctr'LENGTH) ;
               end if;

               last_bin2 <= last_bin1;

                    -- Count ADC overflows (counts how many frames have at least one overflow, as stated in the ADC_OVERFLOW flag thn TLAST=1)
                    adc_overflow_ctr <= (others => '0') when first_bin1 else
                                        adc_overflow_ctr + 1 when adc_flag1 and not msb(adc_overflow_ctr); -- This is the first sample of a frame, don't have to worry about the ADC_OVERFLOW flag yet


                -- Phase 3
                -- Capture stats when requested

                if stats_capture_resync = '0' then -- Clear the ready flags whenever trig is low
                    stats_ready <= '0';
                elsif last_bin2 then -- Capture stats of the last frame block when the new block begins
                    stats_scaler_overflows <= scaler_overflow_ctr(stats_scaler_overflows'RANGE) when msb(scaler_overflow_ctr)='0' else (others => '1'); -- saturate if carry is set (overflow)
                    stats_adc_overflows <= adc_overflow_ctr(stats_adc_overflows'RANGE);
                    stats_ready <='1';
                end if;

                if rst_reg='1' then
                    stats_ready <= '0';
                    stats_frame_ctr <= (0=>'1', others=>'0');
                    last_frame <= '0';
                    first_bin0 <= '1';
                    first_bin1 <= '0';
                    use_bin1 <= '0';
                    last_bin1 <= '0';
--                    add_bin1 <= '0';
                    last_bin2 <= '0';
                  end if; -- IF RST
            end if; -- clk
        end process stat_proc;
    end block stats_blk;


    -- External signal monitoring
    mon_blk: block begin
        process(all) begin
            if rising_edge(mon_clk) then
                mon_clk_ctr <= mon_clk_ctr + 1;
                mon_bit_ctr <= mon_bit_ctr + 1 when mon_word(mon_word'HIGH) = mon_ctrl;
                -- Count words
                if mon_tvalid  then
                    mon_word_ctr <= mon_word_ctr + 1;
                    if mon_tlast then
                        mon_word_ctr <= (others => '0');
                        mon_packet_ctr <= mon_packet_ctr + 1;
                        mon_packet_length <= mon_word_ctr when mon_word_ctr > mon_packet_length;
                    end if;

                end if;
                if mon_reset_stats then
                    mon_packet_length <= (others =>'0');
                    mon_packet_ctr <= (others =>'0');
                end if;
            end if; -- clk
        end process;
    end block mon_blk;

end Behavioral;

