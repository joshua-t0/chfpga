----------------------------------------------------------------------------------
--! \file
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
entity SCALER is
    generic (
        FFT_BITS_PER_BIN: integer := 18+18; -- Real + Imaginary part
        FFT_BINS_PER_WORD: integer := 4;
        FFT_BINS_PER_FRAME: integer:= 8192;
        FFT_BITS_PER_WORD: integer := FFT_BITS_PER_BIN * FFT_BINS_PER_WORD;
        USE_COMPLEX_GAINS: boolean := FALSE;
        COEFF_BITS_PER_BIN: integer := 16; -- typically 16 or 16+16. Includes both real and imaginary part. If USE_COMPLEX_GAINS=TRUE, half the bits are used for real and half for imaginary. Must be multiple of 8 as it is configured byte-wise.
        OUT_BITS_PER_BIN: integer := 16+16; -- minimum is 4+4, but can be increased to use 8-bit mode or get more of the input data in bypass mode for capture purposes.
        OUT_BITS_PER_WORD: integer := OUT_BITS_PER_BIN * FFT_BINS_PER_WORD;
        EIGHT_BIT_SUPPORT: BOOLEAN := OUT_BITS_PER_BIN >= 8+8 -- TRUE of the scaler supports (8+8) bit output in addition to the 4+4 bit output 
        );
    port (
        -- Input Interface
        s_axis_in_tdata    : in std_logic_vector(FFT_BITS_PER_WORD-1 downto 0); -- Format: MSB->LSB: Re(N),   Im(N),   Re(N+1), Im(N+1)
        s_axis_in_tvalid   : in std_logic;
        s_axis_in_tlast    : in std_logic;
        s_axis_in_tuser    : in std_logic_vector(3 downto 0);  -- 

        -- Output interface
        --out_dat : out AXIS32_DAT_STRUCT;

        m_axis_out_tdata    : out std_logic_vector(OUT_BITS_PER_WORD-1 downto 0); -- Format: MSB->LSB: Re(N),   Im(N),   Re(N+1), Im(N+1)
        m_axis_out_tvalid   : out std_logic;
        m_axis_out_tlast    : out std_logic;
        m_axis_out_tuser    : out std_logic_vector(3 downto 0);  -- 

        -- Common Clock and Reset
        clk     : in  std_logic;
        reset   : in  std_logic; --! clk-synchronous reset

        -- Channel FIFO monitoring
        fifo_overflow   : in std_logic;

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
end SCALER;

------- ARCHITECTURE DECLARATION and DEFINITION ---------------------
--! Implements the functional code of the SCALER
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
                                           FFT_BITS_PER_BIN/2 + COEFF_BITS_PER_BIN +1); -- read gain. We keep the +1 for compatibility with complex gains
    --constant SCALAR_WIDTH:integer := FFT_BITS_PER_BIN * sel(USE_COMPLEX_GAINS, 2, 1);
    constant BSB_RAM_ADDR_WIDTH: integer :=9; -- Maximum number of RAM address bits allowed by the BSB interface. The remaining address space must be accessed by paging.
    constant RAM_LATENCY: integer:=2; -- RAM access latency on both the control and readout side of the RAM. **Do not change**: Latency compensation is hardcoded in the code.
    constant NUMBER_OF_COEFF_BANKS: integer := 2; -- **do not change**: the bank address width is hardcoded to a single bit.
    constant LOG2_NUMBER_OF_COEFF_BANKS: integer := integer_log2(NUMBER_OF_COEFF_BANKS);
    constant LOG2_NUMBER_OF_COEFF_PAGES: integer := LOG2_COEFF_BYTES_PER_FRAME + LOG2_NUMBER_OF_COEFF_BANKS - BSB_RAM_ADDR_WIDTH; -- width of the page register for byte-wise access to both banks

    -- Data bus pipeline to compensate for RAM_LATENCY
    signal in_dat_dly1_tdata    : std_logic_vector(FFT_BITS_PER_WORD-1 downto 0);
    signal in_dat_dly1_tvalid   : std_logic;
    signal in_dat_dly1_tlast    : std_logic;
    signal in_dat_dly1_tuser    : std_logic_vector(3 downto 0);  -- 

    signal in_dat_dly2_tdata    : std_logic_vector(FFT_BITS_PER_WORD-1 downto 0);
    signal in_dat_dly2_tvalid   : std_logic;
    signal in_dat_dly2_tlast    : std_logic;
    signal in_dat_dly2_tuser    : std_logic_vector(3 downto 0);  -- 

--signal IN_DAT_DLY1: AXIS72_DAT_STRUCT; --!
--signal IN_DAT_DLY2: AXIS72_DAT_STRUCT; --!

--- Define Control word and its signals
signal control_bytes: slv8_array(0 to 9); -- default value set in the CMD_SLAVE
signal status_bytes: slv8_array(0 to 7);

signal bypass_scaler: std_logic;
signal soft_reset: std_logic;
signal post_scaler_left_shift: std_logic_vector(4 downto 0); -- can shift up to 31 bits left

signal stage1_word: signed_array(0 to INTEGERS_PER_WORD-1)(INTEGER_WIDTH-1 downto 0);
signal stage1_sign: std_logic_vector(0 to INTEGERS_PER_WORD-1); --! Indicates the sign of each of the 4 numbers in the incoming word
signal stage1_overflow: std_logic_vector(0 to INTEGERS_PER_WORD-1);
signal stage1_tvalid: std_logic;
signal stage1_tlast: std_logic;
signal stage1_tuser: std_logic_vector(3 downto 0);

signal stage2_word: signed_array(0 to INTEGERS_PER_WORD-1)(7 downto 0);
signal stage2_sign: std_logic_vector(0 to INTEGERS_PER_WORD-1); --! Indicates the sign of each of the 4 numbers in the incoming word
signal stage2_overflow: std_logic_vector(0 to INTEGERS_PER_WORD-1);
signal stage2_tvalid: std_logic;
signal stage2_tlast: std_logic;
signal stage2_tuser: std_logic_vector(3 downto 0);

-- Control signals
signal four_bits: std_logic;
signal symmetric_saturation: std_logic;
signal zero_on_saturation: std_logic;

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
signal use_offset_binary: std_logic;

signal next_gain_bank: std_logic; -- 1 bit
signal gain_bank_switch_frame_number: std_logic_vector(31 downto 0);
signal current_gain_bank: std_logic;
signal synchronize_gain_bank_switch: std_logic;


-- Multiplier output
signal scaled_data_tvalid: std_logic;
signal scaled_data_tuser: std_logic_vector(3 downto 0);
signal scaled_data_tlast: std_logic;
signal scaled_data_tdata: std_logic_vector(INTEGER_WIDTH*INTEGERS_PER_WORD-1 downto 0);


signal coeff_ram_dout: std_logic_vector(COEFF_BITS_PER_WORD-1 downto 0);

signal stats_frame_count: unsigned(23 downto 0); -- Number of frames to include in stats
signal stats_frame_ctr: unsigned(23 downto 0);

signal scaler_overflow_ctr: unsigned(15 downto 0);
signal adc_overflow_ctr: unsigned(15 downto 0);

signal stats_scaler_overflows: unsigned(15 downto 0);
signal stats_adc_overflows: unsigned(15 downto 0);

signal stats_capture: std_logic;
signal stats_first_frame: std_logic;
signal stats_ready: std_logic;

signal delay_capture_ctr: unsigned(15 downto 0);
signal delay_capture_ctr_en: std_logic :='0';

signal fifo_overflow_reset: std_logic;
signal fifo_overflow_sticky: std_logic;

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
--! \addtogroup memory_map
--! SCALER Module Memory Map
--!
--! ----------------------------------------------------------------------------------------------
--! |  Page   | Addr|Bit(s)|     Name                     | Description
--! |---------|-----|------|------------------------------|---------------------------------------
--! | CONTROL |  0  |  7   | soft_reset                   |  |
--! |         |     |   6  | bypass_scaler                |  |
--! |         |     |   5  | four_bits                    | Is '1' when only the top 4 bits are of interest (i.e. rounding is done on the 5th bit). In this case the lower 4 bits of the results are zero.  |
--! |         |     |  4:0 | post_scaler_left_shift       |  Post-scaler |
--! |         |  1  |   7  | (unused)                     |  |
--! |         |     |   6  | USE_OFFSET_BINARY            | When '1', Offset_binary encoding is used on the output of the scaler. The input data and gains are not affected and are always provided in 2's complement. |
--! |         |     |   5  | (unused)                     |  |
--! |         |     |   4  | next_gain_bank               | Indicates which bank of gain coefficients is to be used by the scaler|
--! |         |     |  3:0 | gain_table_page              | Indicates which page of gain coefficients table is being read or written to by the user.|
--! |         |  2  |   7  | stats_capture                | '0' clears the stats_done flag. when '1', the stats are captured and stats_done is set to '1' when the next frame block completes |
--! |         |     |   6  | symmetric_saturation         | When '1', negative values will saturate to -127 (8-bit mode) or -7 (4-bit mode). Otherwise they saturate on -128 and -8 respectively. |
--! |         |     |   5  | zero_on_saturation           | When '1', the real/imaginary pairs are zeroed if wither the real part or imaginary part encounters an overflow.|
--! |         |     |   4  | synchronize_gain_bank_switch | When '1', The target gain bank is activated only when the target frame number has been reached|
--! |         |     |  3:2 | (unused)                     |  |
--! |         |     |  1:0 | rounding_mode                | Specified the type of rounding: '00' = No rounding (truncation), '01'= standard rounding (ties always round up), '10' = convergent rounding (ties round toward the even values)|
--! |         | 3:5 | 23:0 | stats_frame_count            | Number of frames to include in the statistics. 1 = 1 frame. |
--! |         | 6:9 | 31:0 | gain_bank_switch_frame_number| Target frame number at which the next gain bank will be activated. |
--! | STATUS  |  0  |  7   | stats_ready                  | '1' when new stats data has been captured|
--! |         |     |  6   | current_gain_bank            | Currently used gain bank. |
--! |         |     |  5   | eight_bit_support            | '1' when this scaler implementation supports (8+8) bit output mode|
--! |         |     |  4:0 | (unused)                     |  |
--! |         | 1:2 | 15:0 | stats_scaler_overflows       | Number of scaler overflows in the last captured frame block. Saturates at 0xFFFE or 0xFFFF. |
--! |         | 3:4 | 15:0 | stats_adc_overflows          | Number of adc overflows in the last captured frame block. Saturates at 0xFFFF. |
--! |         |  5  |  7:0 | frame_ctr                    | Last 8 bits of the frame counter. |
--! -----------------------------------------------------------------------------------------------


-- CONTROL Byte 0
soft_reset             <= control_bytes(0)(7);
bypass_scaler          <= control_bytes(0)(6);
four_bits              <= control_bytes(0)(5);
post_scaler_left_shift <= control_bytes(0)(4 downto 0);

-- CONTROL Byte 1
assert gain_table_page'LENGTH <= gain_table_page_padded'LENGTH report "Not enough register space for gain_table_page (have "&str(gain_table_page_padded'LENGTH)&" but need " & str(gain_table_page'LENGTH) & ")" severity FAILURE;
gain_table_page_padded(gain_table_page'RANGE) <= gain_table_page; -- Padded page vector to acount for different page sizes. Will cause errors if we exceed the number of bits we can assign to the control registers.

gain_table_page_padded(5) <= control_bytes(1)(7);
use_offset_binary <= control_bytes(1)(6);
gain_table_page_padded(4) <= control_bytes(1)(5);
next_gain_bank    <= control_bytes(1)(4);
gain_table_page_padded(3 downto 0) <= control_bytes(1)(3 downto 0);


-- CONTROL Byte 2
stats_capture                <= control_bytes(2)(7);
symmetric_saturation         <= control_bytes(2)(6);
zero_on_saturation           <= control_bytes(2)(5);
synchronize_gain_bank_switch <= control_bytes(2)(4);
fifo_overflow_reset          <= control_bytes(2)(3);
rounding_mode                <= control_bytes(2)(1 downto 0);

-- CONTROL Byte 3-5
stats_frame_count <= to_unsigned(control_bytes(3 to 5));

-- CONTROL Byte 6-9
gain_bank_switch_frame_number <= to_slv(control_bytes(6 to 9));

-- STATUS Byte 0
status_bytes(0)(7)   <= stats_ready;
status_bytes(0)(6)   <= current_gain_bank;
status_bytes(0)(5)   <= to_std_logic(EIGHT_BIT_SUPPORT);
status_bytes(0)(4)   <= fifo_overflow_sticky;
status_bytes(0)(3)   <= to_std_logic(USE_COMPLEX_GAINS);

-- log2 of the number of gain table pages . 
--   - 8192 bins x 16-bit real gains x 2 banks: log2(8k*2*2)-9 = 6
--   -  1024 bins * 16-bit complex gains * 2 banks: log2(1024*4*2)-9 = 4
-- Gain bank size in bytes = 2**(value+9-1)
status_bytes(0)(2 downto 0) <= to_slv(LOG2_NUMBER_OF_COEFF_PAGES, 3);  

-- STATUS Byte 1-2: scaler overflows
status_bytes(1 to 2) <= to_slv8_array(stats_scaler_overflows);

-- STATUS Byte 3-4: ADC overflows
status_bytes(3 to 4) <= to_slv8_array(stats_adc_overflows);

-- STATUS Byte 5
status_bytes(5)      <= to_slv(lsb(frame_ctr, 8));

-- STATUS Byte 5
status_bytes(6 to 7) <= to_slv8_array(delay_capture_ctr);
-----------------------------------------------------------------------------------
-- Memory-Mapped interface
-----------------------------------------------------------------------------------
--! Instantiates a memory-mapped interface to the control and status bytes
CTRL_SLAVE0: entity work.CTRL_SLAVE
    GENERIC MAP (
        NUMBER_OF_CONTROL_BYTES=>control_bytes'Length(1), -- Number of bits in the control word
        NUMBER_OF_STATUS_BYTES=>status_bytes'Length(1), -- Number of bits in the status word.
        DEFAULT_CONTROL_BYTES=> X"21_60_02_05F5E1_00000000", -- post_scaler_left_shift=1, (if FFT input is a constant 1, bin 0 will be = 1)
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

        -- fft data format:     MSB->LSB: Re(N),   Im(N),   Re(N+1), Im(N+1)
        -- gain storage format: MSB->LSB: Re(N+1), Im(N+1), Re(N),   Im(N)
        -- single multiplier product format: Im, Re 
        -- Final scaled output format: Re(N), Im(N), Re(N+1), Im(N+1)

        -- Select gain coefficient for the even bin
        coeff_even_din <= (coeff_ram_dout(15 downto 0) & coeff_ram_dout(31 downto 16)); -- Im:Re
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

        -- Instantiate complex multiplier for the odd bin
        coeff_odd_din <= (coeff_ram_dout(32+15 downto 32+0) & coeff_ram_dout(32+31 downto 32+16));
        cmul1_a_tdata <= ("000000" & in_dat_dly2_tdata(0*18+17 downto 0*18+0) & "000000" & in_dat_dly2_tdata(1*18+17 downto 1*18+0));
        cmul1: entity work.SCALER_CMUL
          PORT MAP (
            aclk => clk,
            s_axis_a_tvalid => in_dat_dly2_tvalid,
            s_axis_a_tuser => "0000",
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
          scaled_data_tdata(4*INTEGER_WIDTH - 1 downto 3*INTEGER_WIDTH) <= scaled_data_even_tdata(34 downto 0); -- Re(N)
          scaled_data_tdata(3*INTEGER_WIDTH - 1 downto 2*INTEGER_WIDTH) <= scaled_data_even_tdata(74 downto 40); -- Im(N)
          scaled_data_tdata(2*INTEGER_WIDTH - 1 downto 1*INTEGER_WIDTH) <= scaled_data_odd_tdata(34 downto 0); -- Re(N+1)
          scaled_data_tdata(1*INTEGER_WIDTH - 1 downto 0*INTEGER_WIDTH) <= scaled_data_odd_tdata(74 downto 40); -- Im(N+1)
    else generate -- if no complex gains

            signal coeff_reg: std_logic_vector(COEFF_BITS_PER_WORD-1 downto 0);
            signal fft_reg_tdata: std_logic_vector(FFT_BITS_PER_WORD-1 downto 0);
            signal fft_reg_tvalid: std_logic;
            signal fft_reg_tlast: std_logic;
            signal fft_reg_tuser: std_logic_vector(3 downto 0);
            
        begin

            -- fft data format:     MSB->LSB: Re(N),   Im(N),   Re(N+1), Im(N+1)
            -- gain storage format: MSB->LSB: Re(N+1), Im(N+1), Re(N),   Im(N) 
            -- product data format:     MSB->LSB: Re(N),   Im(N),   Re(N+1), Im(N+1)

            mul_proc: process (clk) 
                variable fft_re, fft_im: signed(FFT_BITS_PER_BIN/2-1 downto 0);
                variable gain: signed(COEFF_BITS_PER_BIN-1 downto 0);
                variable re_lsb, im_lsb: integer;
            begin
                if rising_edge(clk) then
                        -- Pipeline the gain and fft values. These registers should be absorbed as the input registers 
                        -- of the DSP48 block and should greatly help with timing closure.
                        coeff_reg <= coeff_ram_dout;
                        fft_reg_tdata <= in_dat_dly2_tdata;
                        -- Make sure the control signals are delayed as much as the data
                        fft_reg_tvalid <= in_dat_dly2_tvalid;
                        fft_reg_tlast <= in_dat_dly2_tlast;
                        fft_reg_tuser <= in_dat_dly2_tuser;
                    for i in FFT_BINS_PER_WORD-1 downto 0 loop
                        gain := signed(coeff_reg((FFT_BINS_PER_WORD-i)*COEFF_BITS_PER_BIN-1 downto (FFT_BINS_PER_WORD-i-1)*COEFF_BITS_PER_BIN));
                        re_lsb := i*FFT_BITS_PER_BIN + FFT_BITS_PER_BIN/2;
                        im_lsb := i*FFT_BITS_PER_BIN;
                        fft_re := signed(fft_reg_tdata(re_lsb + FFT_BITS_PER_BIN/2-1 downto re_lsb)); -- we must use dly2 signals which are synchronized with the gain coefficient
                        fft_im := signed(fft_reg_tdata(im_lsb + FFT_BITS_PER_BIN/2-1 downto im_lsb));
                        re_lsb := 2*i*INTEGER_WIDTH + INTEGER_WIDTH;
                        im_lsb := 2*i*INTEGER_WIDTH;
                        scaled_data_tdata(re_lsb + INTEGER_WIDTH-1 downto re_lsb) <= "0" & std_logic_vector(gain * fft_re);
                        scaled_data_tdata(im_lsb + INTEGER_WIDTH-1 downto im_lsb) <= "0" & std_logic_vector(gain * fft_im);
                    end loop;
                    scaled_data_tvalid <= fft_reg_tvalid;
                    scaled_data_tlast <= fft_reg_tlast;
                    scaled_data_tuser <= fft_reg_tuser;
                end if;
            end process;
    end generate mul_gen;


-- out: Imag: 74:40
-- real: 34:0
-------------------------------------------------------------------
-- Main process
-------------------------------------------------------------------
--! Reads the input bus, scales the values, and send them to the output bus.
scaler_proc: process(clk)
    variable shift_left_value_var: integer range 0 to (2**post_scaler_left_shift'LENGTH - 1);
--    variable stage1_word_var: int35_array(3 downto 0);
    variable word_var: signed(INTEGER_WIDTH-1 downto 0);
    variable OUT_WORD_VAR: int8_array(0 to INTEGERS_PER_WORD-1);
    variable round_down_var: std_logic;
    variable len: integer;
    begin
        if rising_edge(clk) then


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
            -- bin

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
            -- convert shift value into an integer
            shift_left_value_var := to_integer(unsigned(post_scaler_left_shift)); 

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
                stage1_sign(i) <= sign_bit(word_var); -- preserve the sign that may have been destroyed by the shift operation
                -- Store the shifted integer. We'll fix overflows in the next phase.
                stage1_word(i) <= shift_left(word_var, shift_left_value_var);

                -- Determine if all bits shifted out and the final sign bits have the same sign as the sign bit. If not, we are in overflow condition.
                -- Note: We cannot use and_reduce() with a range determined from a variable: it does not synthersize.
                stage1_overflow(i) <= '0';
                for j in 1 to 31 loop
                    if j <= shift_left_value_var and word_var(word_var'LENGTH-1-j) /= sign_bit(word_var) then
                        stage1_overflow(i)<='1';
                    end if;
                end loop;
            end loop;


            -- PIPELINE STAGE 2: apply rounding and detect rounding overflows
            stage2_tvalid  <= stage1_tvalid;
            stage2_tlast   <= stage1_tlast;
            stage2_tuser   <= stage1_tuser;
            for i in 0 to INTEGERS_PER_WORD-1 loop
                stage2_sign(i) <= stage1_sign(i);
                stage2_overflow(i) <= stage1_overflow(i);
                if four_bits = '1' or EIGHT_BIT_SUPPORT = FALSE then
                    if rounding_mode = ROUNDING_MODE_CONVERGENT_ROUND or rounding_mode = ROUNDING_MODE_ROUND then -- if rounding
                        stage2_word(i)(7 downto 4) <= msb(msb(stage1_word(i), 4 + 1) + 1, 4);
                        stage2_word(i)(3 downto 0) <= "0000";
                        round_down_var := to_std_logic(rounding_mode = ROUNDING_MODE_CONVERGENT_ROUND and stage1_word(i)(35-1-4)='1' and stage1_word(i)(35-1-4-1 downto 0)=0);
                        if round_down_var = '1' then
                            stage2_word(i)(4) <= '0';
                        end if;
                        -- Detect saturations
                        if msb(stage1_word(i), 5) = "01111" then --if the rounding causes a positive value to overflow
                            stage2_overflow(i) <= '1';-- the rounding will cause a overflow
                        elsif symmetric_saturation='1' and ( msb(stage1_word(i), 5) = "10000" or round_down_var = '1') then --if the rounding causes a negative value to overflow
                            stage2_overflow(i) <= '1';-- the rounded value will exceed -7
                        end if;
                    else -- no rounding (i.e truncate)
                        stage2_word(i)(7 downto 4) <= msb(stage1_word(i), 4);
                        stage2_word(i)(3 downto 0) <= "0000";
                        if symmetric_saturation='1' and msb(stage1_word(i), 4) = "1000" then --if the rounding causes a negative value to overflow
                            stage2_overflow(i) <= '1';
                        end if;
                    end if;

                elsif EIGHT_BIT_SUPPORT=TRUE then -- four_bits = '0'
                    if rounding_mode = ROUNDING_MODE_CONVERGENT_ROUND or rounding_mode = ROUNDING_MODE_ROUND then -- if rounding
                        stage2_word(i) <= msb(msb(stage1_word(i), 8 + 1) + 1, 8);
                        round_down_var := to_std_logic(rounding_mode = ROUNDING_MODE_CONVERGENT_ROUND and stage1_word(i)(35-1-8)='1' and stage1_word(i)(35-1-8-1 downto 0)=0);
                        if round_down_var = '1' then
                            stage2_word(i)(0) <= '0';
                        end if;
                        -- Detect saturations
                        if msb(stage1_word(i), 9) = "011111111" then --if the rounding causes a positive value to overflow
                            stage2_overflow(i) <= '1';-- the rounding will cause a overflow
                        elsif symmetric_saturation='1' and ( msb(stage1_word(i), 9) = "100000000" or round_down_var = '1') then --if the rounding causes a negative value to overflow
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
                if stage2_overflow(i) = '1' then
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

            -- Stage 3b: Zero Re/Im pairs on overflows
            if zero_on_saturation='1' then
                for i in 0 to FFT_BINS_PER_WORD-1 loop
                    if stage2_overflow(2*i to 2*i+1)/="00" then
                        OUT_WORD_VAR(2*i) := X"00";
                        OUT_WORD_VAR(2*i+1) := X"00";
                    end if;
                end loop;
            end if;

            -- Stage 3c: apply offset encoding
            if use_offset_binary='1' then
                for i in 0 to INTEGERS_PER_WORD-1 loop
                    OUT_WORD_VAR(i)(7) := not OUT_WORD_VAR(i)(7); -- Implement offset binary by inverting the sign bit.
                end loop;
            end if;

            -- Stage 3d: Clear lower nibble in 4-bit mode
            if four_bits='1' or EIGHT_BIT_SUPPORT=FALSE then
                for i in 0 to INTEGERS_PER_WORD-1 loop
                    OUT_WORD_VAR(i)(3 downto 0) := "0000";
                end loop;
            end if;

            -- Stage 3e: Assign outputs
            if bypass_scaler then
                -- In bypass mode, we forward the last 8 bit of every real and imaginary components to the output
                for i in 0 to INTEGERS_PER_WORD-1 loop
                    m_axis_out_tdata((i+1)*OUT_BITS_PER_BIN/2-1 downto i*OUT_BITS_PER_BIN/2) <= s_axis_in_tdata(i*FFT_BITS_PER_BIN/2 + OUT_BITS_PER_BIN/2 - 1 downto i*FFT_BITS_PER_BIN/2);
                end loop;
                m_axis_out_tlast <= s_axis_in_tlast;
                m_axis_out_tvalid <= s_axis_in_tvalid;
                m_axis_out_tuser(TUSER_CAPTURE_BIT) <= s_axis_in_tuser(TUSER_CAPTURE_BIT);
                if s_axis_in_tlast='1' then
                    m_axis_out_tuser(TUSER_ADC_OVERFLOW_BIT) <= s_axis_in_tuser(TUSER_ADC_OVERFLOW_BIT);
                else
                    m_axis_out_tuser(TUSER_ADC_OVERFLOW_BIT) <= current_gain_bank;
                end if;
                m_axis_out_tuser(TUSER_SCALER_LOW_OVERFLOW_BIT) <= '0';
                m_axis_out_tuser(TUSER_SCALER_HIGH_OVERFLOW_BIT) <= '0';
            else
                m_axis_out_tdata <= (others => '0'); -- overriden below
                len := minimum(OUT_BITS_PER_BIN/2, 8); -- copy at most 8 bits to the output, or less if the ouutput word is narrower
                for i in 0 to INTEGERS_PER_WORD-1 loop
                    m_axis_out_tdata((i+1)*OUT_BITS_PER_BIN/2-1 downto (i+1)*OUT_BITS_PER_BIN/2-len) <= std_logic_vector(OUT_WORD_VAR(i)(7 downto 8-len)); -- MSB->LSB: 3,2,1,0 = Re(N), Im(N), Re(N+1), Im(N+1)
                end loop;
                m_axis_out_tuser <= stage2_tuser; -- pass on the USER bits
                -- insert the current bank in the TLAST-2 serial flag bit (TLAST-0 (stage2_tlast): ADC overflow, TLAST-1 (stage1_tlast) = FFT overflow, TLAST-2 (scaled_data_even_tlast) = gain bank)
                if scaled_data_tvalid='1' and scaled_data_tlast='1' then
                    m_axis_out_tuser(TUSER_SERIAL_FLAGS_BIT) <= current_gain_bank;
                else
                    m_axis_out_tuser(TUSER_SERIAL_FLAGS_BIT) <= stage2_tuser(TUSER_SERIAL_FLAGS_BIT);
                end if;
                -- Set the scaler overflow bits in the user data
                m_axis_out_tuser(TUSER_SCALER_LOW_OVERFLOW_BIT) <= stage2_overflow(0) or stage2_overflow(1); -- Overflow for the low word is when either its real or imaginary value overflows
                m_axis_out_tuser(TUSER_SCALER_HIGH_OVERFLOW_BIT) <= stage2_overflow(2) or stage2_overflow(3); -- Overflow for the low word is when either its real or imaginary value overflows
                m_axis_out_tlast <= stage2_tlast;
                m_axis_out_tvalid <= stage2_tvalid;
            end if; -- if BYPASS


            --out_dat.TDATA <= (others =>'0'); // as for debugging

            -- Computes how many clocks it takes for the first frame to arrive after reset
            if reset ='1' then
                delay_capture_ctr <= (others=> '0');
                delay_capture_ctr_en <= '1';
            elsif delay_capture_ctr_en = '1'  then
                delay_capture_ctr <= delay_capture_ctr + 1;
                if signed(delay_capture_ctr)=-2 or in_dat_dly2_tvalid='1' then
                    delay_capture_ctr_en <= '0';
                end if;
            end if;

            -- If we reset, override key signals only
            if soft_reset='1' or reset='1' then
                -- IN_DAT_TIMING_REG.TVALID<='0'; --needed
                stage1_tvalid <= '0'; --needed
                stage2_tvalid <= '0'; --needed
                in_dat_dly1_tvalid <= '0';
                in_dat_dly2_tvalid <= '0';
                m_axis_out_tvalid <= '0'; -- by default, nothing is coming out, unless something is coming in, in which case this asignment is overriden below
                word_ctr <= (others=> '0');
                frame_ctr <= (others=> '0');
            end if; -- IF RST
        end if; -- clk
    end process;

----------------------------------
-- Statistics process
----------------------------------
--
stat_proc: process(clk)
    variable scaler_overflow_incr: integer;

    begin
        if rising_edge(clk) then

            -- Channel FIFO overflow monitoring
            if soft_reset='1' or reset='1' or fifo_overflow_reset='1' then
                fifo_overflow_sticky <= '0';
            elsif fifo_overflow='1' then
                fifo_overflow_sticky <= '1';
            end if;

            if soft_reset='1' or reset='1' then
                stats_ready <= '0';
                stats_frame_ctr <= (0=>'1', others=>'0');
                stats_first_frame <= '1';
            else


                if stage2_tvalid='1' then

                    -- set stats_first_frame in the first sample of the first frame of each frame block
                    stats_first_frame <= '0';
                    if stage2_tlast='1' then
                        stats_frame_ctr <= stats_frame_ctr + 1;
                        if stats_frame_ctr = stats_frame_count then
                            stats_first_frame <= '1';
                            stats_frame_ctr <= (0=>'1', others=>'0');
                        end if;
                    end if;


                    -- Determine if how many scaler overflows we have on this word sample
                    -- We count a saturation on either the real or imaginary part as a single count
                    scaler_overflow_incr := 0;
                    for i in 0 to FFT_BINS_PER_WORD-1 loop
                        if  stage2_overflow(2*i to 2*i+1) /= "00" then
                            scaler_overflow_incr := scaler_overflow_incr + 1;
                        end if;
                    end loop;
                        
                    -- Count scaler overflows
                    if stats_first_frame = '1' then
                        scaler_overflow_ctr <= to_unsigned(scaler_overflow_incr, scaler_overflow_ctr'length);
                    elsif signed(scaler_overflow_ctr) /= -2 and signed(scaler_overflow_ctr) /= -1 then
                        scaler_overflow_ctr <= scaler_overflow_ctr + scaler_overflow_incr;
                    end if;

                    -- Count ADC overflows (counts how many frames have at least one overflow, as stated in the ADC_OVERFLOW flag thn TLAST=1)
                    if stats_first_frame = '1' then
                        adc_overflow_ctr <= (others=>'0'); -- This is the first sample of a frame, don't have to worry about the ADC_OVERFLOW flag yet
                    elsif stage2_tlast='1' and stage2_tuser(TUSER_ADC_OVERFLOW_BIT)='1' and signed(adc_overflow_ctr)/=-1 then
                        adc_overflow_ctr <= adc_overflow_ctr + 1;
                    end if;
                end if; -- if TVALID


                -- Capture stats when requested
                if stats_capture='0' then -- Clear the ready flags whenever trig is low
                    stats_ready <= '0';
                elsif stage2_tvalid='1' and stats_first_frame = '1' and stats_capture='1' then -- Capture stats of the last frame block when the new block begins
                    stats_scaler_overflows <= scaler_overflow_ctr;
                    stats_adc_overflows <= adc_overflow_ctr;
                    stats_ready <='1';
                end if;

            end if; -- IF RST
        end if; -- clk
    end process;

end Behavioral;

