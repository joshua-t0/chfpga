----------------------------------------------------------------------------------
--! @file
-- Company: McGill University
-- Engineer: JF Cliche
--
-- Create Date:    00:57:11 12/02/2010
-- Design Name:    FUNCGEN
-- Module Name:    FUNCGEN - Behavioral
-- Project Name: CHIME
-- Target Devices: Virtex 6 or 7 series
-- Tool versions: ISE 14.2 -  Vivado 2016.2
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
--  2012-10-01 JFC: Splitted from SRCSEL
--  2013-02-06 JFC: Removed RST from main process reset list to limit distribution of that signal
--  2014-01-29 JFC: Added 4-bit functions. Used variables to simplify code. Added use_overflow.
--  See Git repository for further logs

-- Additional Comments:

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_MISC.ALL; -- for or_reduce()

library UNISIM;
use UNISIM.VComponents.all;

use work.chFPGA_Package.all; -- Get all component definitions

------ FUNCGEN Entity -------------
--! @brief Implements a AXI4-Streaming function generator that either forwards
--!     the input from the ADC or replaces it with user-programmable arbitrary
--!     waveforms, noise, or packet test patterns.
--!
entity FUNCGEN is
    PORT (

        in_dat  : in AXIS32_DAT_STRUCT;     --! Data stream from the ADC.
                                            --! The TUSER field contain an overflow bit flag for each byte.
        trig    : in std_logic := '1';

        -- Output data interface
        out_dat : out AXIS32_DAT_STRUCT;    --! Output stream of the function generator
        clk     : in  std_logic;            --! Output stream clock
        rst     : in  std_logic;            --! CLK-synchronous reset for the whole antenna processing chain

        -- Control Interface (command and reply stream buses)
        ctrl_cmd_in_dat     : in  AXIS8_DAT_STRUCT;
        ctrl_cmd_in_rdy     : out AXIS8_RDY_STRUCT;
        ctrl_rply_out_dat   : out AXIS8_DAT_STRUCT;
        ctrl_rply_out_rdy   : in  AXIS8_RDY_STRUCT;
        ctrl_clk            : in  std_logic;
        ctrl_rst            : in  std_logic
    );
end FUNCGEN;

architecture Behavioral of FUNCGEN is

-- Data Sources
subtype  FN_TYPE is std_logic_vector(2 downto 0);
constant FN_ADC                      : FN_TYPE:="000"; -- ADC input
constant FN_RAM                      : FN_TYPE:="001"; -- Outputs RAM contents (2048 bytes, 512 words)
constant FN_NOISE                    : FN_TYPE:="010"; -- noise
constant FN_FRAME_WORD_CTR_RAM_FLAGS : FN_TYPE:="011"; -- Counts frames and words, and ADC flags is set from RAM bit 0 writes page 1 (bytes 512-1023)

signal byte_a: Byte;
signal byte_b: Byte;

-- Control and status bytes
signal control_bytes: ByteArray(0 to 3); -- default value set in the CMD_SLAVE
signal status_bytes: ByteArray(0 to 4);

signal fn_sel: FN_TYPE;
signal ramp_word_ctr: unsigned(LOG2_WORDS_PER_FRAME-1 downto 0) := (others=>'0'); -- Counts words from 0 to FRAME_LENGTH/4-1
signal ramp_word_ctr_dly: unsigned(LOG2_WORDS_PER_FRAME-1 downto 0) := (others=>'0'); -- Counts words from 0 to FRAME_LENGTH/4-1
signal ctr: std_logic_vector(LOG2_WORDS_PER_FRAME-1 downto 0) := (others=>'0'); -- Counts words from 0 to FRAME_LENGTH/4-1
-- signal use_overflow: std_logic;
signal reset_all: std_logic;
signal soft_reset: std_logic:= '0';
signal number_of_frames: unsigned(7 downto 0); -- Counts words from 0 to FRAME_LENGTH/4-1
signal frame_ctr: unsigned(22 downto 0); -- Counts words from 0 to FRAME_LENGTH/4-1
signal enable: std_logic;
signal send_frame: std_logic;
signal ram_page: std_logic_vector(2 downto 0);
signal adc_overflow_flag: std_logic;
signal capture_flag: std_logic;
signal adc_tfirst: std_logic;
signal ramp_tfirst: std_logic;
signal trig_reg: std_logic;


signal ram_ctrl_addr: std_logic_vector(11 downto 0); -- 2048 bytes x 2
signal ram_ctrl_addr_paged: std_logic_vector(11 downto 0); -- 2048 bytes x 2
signal ram_ctrl_wr_en: std_logic;
signal ram_ctrl_din: std_logic_vector(7 downto 0);
signal ram_ctrl_dout: std_logic_vector(7 downto 0);
signal ram_addr: std_logic_vector(9 downto 0); -- 512 words
signal ram_dout: std_logic_vector(31 downto 0);
signal ram_dout_int: std_logic_vector(31 downto 0);
signal crc_out: std_logic_vector(31 downto 0);

signal delay_capture_ctr: unsigned(15 downto 0);
signal delay_capture_ctr_en: std_logic :='0';

begin
-----------------------------------------------------------------------------------
-- CONTROL and STATUS Bytes
-----------------------------------------------------------------------------------
--! \addtogroup memory_map
--! Function Generator Memory Map
--!
--!  ------------------------------------------------------------------------------
--! |  Page   | Addr|Bit(s)|     Name             | Description                   |
--! |---------|-----|------|----------------------|-------------------------------|
--! | CONTROL |  0  |   7  | soft_reset           |                               |
--! |         |     |   6  | enable               | if '1', funcgen continuously generate frame. If '0', stop generating frame and resets the frame counter.|
--! |         |     |  5:3 | ram_page             |  |
--! |         |     |  2:0 | fn_sel               |  Source selection |
--! |         |  1  |  7:0 | byte_a               | |
--! |         |  2  |  7:0 | byte_b               | |
--! | STATUS  |  0  |  7:0 | ramp_word_ctr        | |
--!  ------------------------------------------------------------------------------


-- CONTROL Byte 0
soft_reset   <= control_bytes(0)(7);
enable       <= control_bytes(0)(6);
ram_page     <= control_bytes(0)(5 downto 3);
fn_sel       <= FN_TYPE(control_bytes(0)(2 downto 0)); --
-- CONTROL Bytes 1-2
byte_a <= control_bytes(1);
byte_b <= control_bytes(2);

-- CONTROL Byte 3
number_of_frames <= unsigned(control_bytes(3));

-- STATUS Byte 0
status_bytes(0) <= std_logic_vector(lsb(ramp_word_ctr));
-- STATUS Byte 1
status_bytes(1) <= std_logic_vector(lsb(frame_ctr));
-- STATUS Byte 2
status_bytes(2)(0) <= send_frame;
-- STATUS Byte 3-4
status_bytes(3 to 4) <= to_ByteArray(delay_capture_ctr);

-----------------------------------------------------------------------------------
-- Memory-Mapped interface instantiation
-----------------------------------------------------------------------------------
--! Instantiates a memory-mapped interface to the control and status bytes
CTRL_SLAVE0: entity work.CTRL_SLAVE
    GENERIC MAP (
        NUMBER_OF_CONTROL_BYTES => control_bytes'Length(1), --
        NUMBER_OF_STATUS_BYTES  => status_bytes'Length(1), --
        DEFAULT_CONTROL_BYTES   => X"40_0101_00", -- No reset
        ADDR_WIDTH              => 9, -- We have 9 bits of data left after routing
        RAM_DATA_WIDTH          => 8, -- 8 or 16 bits
        RAM_ADDR_WIDTH          => 12, -- Cannot exceed 9 bits with 8-bit data width because higher bits are used for routing
        RAM_LATENCY             => 2,
        USE_FIFO                => FALSE
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
        RAM_RD_EN => open, -- the ram is always reading


        CLK               => clk,
        RST               => rst
    );

-- ram_ctrl_addr_paged(11 downto 9) <= ram_ctrl_addr(11 downto 9) or ram_page;
ram_ctrl_addr_paged(11 downto 9) <= ram_page;
ram_ctrl_addr_paged(8 downto 0) <= ram_ctrl_addr(8 downto 0);
ram_addr <= ('0' & std_logic_vector(ramp_word_ctr(8 downto 0)));
ram_dout <= reverse_bytes(ram_dout_int); -- reorder so byte 0 is in the MSB of word 0

-- Instantiate block RAM that will contain the user-programmable waveforms
ram0 : entity work.FUNCGEN_RAM
    PORT MAP (
        clka  => ctrl_clk,
        wea(0)   => ram_ctrl_wr_en,
        addra => ram_ctrl_addr_paged,
        dina  => ram_ctrl_din,
        douta => ram_ctrl_dout,

        clkb   => clk,
        web(0) => '0',
        addrb  => ram_addr,
        dinb   => (others=>'0'),
        doutb  => ram_dout_int
    );

-- Instantiate the CRC engine, 32-bit wide input, that is used as a noise generator.
crc32: entity work.xglink_crc32_32
    port map(
        data_in => (byte_a & byte_b & not byte_a & not byte_b), --
        crc_out => crc_out,
        rst => rst,
        crc_en => '1',
        clk => clk
);

---------------------------------------------
-------- Main process -----------------------
---------------------------------------------
--! Implements the function generator

-- Set TUSER
out_dat.TUSER <= (
    TUSER_ADC_OVERFLOW_BIT => adc_overflow_flag,
    TUSER_CAPTURE_BIT      => capture_flag,
    others                 => '0'
    );

funcgen_proc: process (clk)
    -- variable out_dat_var: std_logic_vector(31 downto 0);
    -- variable ctr: std_logic_vector(ramp_word_ctr'range);
    begin
        if rising_edge(clk) then
            reset_all <= soft_reset or rst;
            trig_reg  <= trig;

        -- Monitoring
        if reset_all ='1' then
            delay_capture_ctr <= (others=> '0');
            delay_capture_ctr_en <= '1';
        elsif delay_capture_ctr_en = '1'  then
            delay_capture_ctr <= delay_capture_ctr + 1;
            if signed(delay_capture_ctr)=-2 or (in_dat.TVALID='1' and (byte_a(0)='0' or in_dat.TLAST='1')) then
                delay_capture_ctr_en <= '0';
            end if;
        end if;

            --------------------------------------
            -- Generate an AXIS ramp stream
            --------------------------------------
            -- Count ramp words
            ramp_word_ctr <= ramp_word_ctr + 1;
            ramp_word_ctr_dly <= ramp_word_ctr;
            ctr <= std_logic_vector(ramp_word_ctr_dly); -- This is aligned with the RAM output

            if in_dat.TVALID='1' then
                adc_tfirst <= in_dat.TLAST;
            end if;


            -- Set default TLAST (overriden below)
            out_dat.TLAST <= '0';
            if signed(ctr) = -1 then
                ramp_tfirst <= '1';
                out_dat.TLAST <= '1';
                if enable = '1' then
                    if number_of_frames = 0 or (number_of_frames /= 0 and frame_ctr /= number_of_frames) then
                        send_frame <= '1';
                        frame_ctr <= frame_ctr + 1; -- can be overriden below
                    else
                        send_frame <= '0';
                    end if;
                end if;
            end if;

            if enable = '0' then
                send_frame <= '0';
                frame_ctr <= (others=>'0');
            end if;

            if (fn_sel = FN_ADC and adc_tfirst='1') or (fn_sel /= FN_ADC and ramp_tfirst='1') then
                capture_flag <= trig_reg;
            end if;

            -- Set TDATA
            case fn_sel is

                when FN_ADC =>
                    if in_dat.TVALID='1' then
                        -- Cumulate the overflow flags until the end of the frame so the last word indicates if there was an overflow anywhere in the frame.
                        if adc_tfirst='1' then
                            adc_overflow_flag <= or_reduce(in_dat.TUSER);
                        else
                            adc_overflow_flag <= adc_overflow_flag or or_reduce(in_dat.TUSER);
                        end if;
                    end if; -- if TVALID
                    out_dat.TDATA <= in_dat.TDATA;
                    out_dat.TVALID <= in_dat.TVALID;
                    out_dat.TLAST <= in_dat.TLAST;

                when FN_RAM =>
                    out_dat.TDATA <= ram_dout; -- Byte at address 0 is in the MSB
                    out_dat.TVALID <= send_frame;
                    adc_overflow_flag <= '0';

                when FN_NOISE =>
                    out_dat.TDATA <= crc_out;
                    out_dat.TVALID <= send_frame;
                    adc_overflow_flag <= '0';

                when FN_FRAME_WORD_CTR_RAM_FLAGS =>
                    out_dat.TDATA <= to_slv(frame_ctr) & ctr;
                    out_dat.TVALID <= send_frame;
                    adc_overflow_flag <= ram_dout(0);

                when others =>
                    out_dat.TDATA <= (others=>'0');
            end case;

            if reset_all='1' then -- Synchronous reset
                ramp_word_ctr <= (others=>'0');
                ramp_word_ctr_dly <= (others=>'0');
                ctr <= (others=>'0');
                out_dat.TVALID <= '0'; -- needed
                frame_ctr <= (others=>'0');
                send_frame <= '0';
                adc_tfirst <= '1';
                ramp_tfirst <= '1';
                trig_reg <= '0';
                capture_flag <= '0';
            end if; -- Synchronous RESET
        end if; -- RST & CLK
    end process;

end Behavioral;
