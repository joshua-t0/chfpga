----------------------------------------------------------------------------------
-- @file
-- Company: McGill University, Cosmology Instrumentation Lab
-- Engineer: J.-F. Cliche
--
-- Create Date:    20:34:01 03/26/2011
-- Design Name:     chFPGA
-- Module Name:    FFT - Behavioral
-- Project Name: CHIME
-- Target Devices: Virtex 6
-- Tool versions: ISE 13.4
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--  2012-05-31 JFC: Rewritten for the new PFB_FFT and AXI4 Streaming input and output buses
--      2012-08-31 JFC: Rewritten to include the SYNC generator, cleanup reset sequence, and use the new latency counter/delay line.
--      2012-09-11 JFC: Set SYNC_PERIOD to zero (no sync) by default.
--    2012-09-20 JFC: Implemented a better OVERFLOW_COUNTER with its own reset. CHanged default values for FFT_SHIFT.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chFPGA_Package.all; -- Get all component definitions
--c0
library UNISIM;
use UNISIM.VComponents.all;
-- c1

--===== ENTITY DECLARATION ======================

--! @brief Wraps a CASPER channelizer (Typically a FFT or a variant) with a CASPER-compatible SYNC generator and delay line to accept a AXI4-STREAMING input and output bus.
--! @details
--!
--! Generating the CASPER FFT block
--! -------------------------------
--!
--! The following system setup was used:
--!     - Matlab 200Xb
--!     - ISE 12.X
--!     - CASPER libraries 10.X
--!     - Path added to MATLAB:
--!        - mlib_devel_10_X/casper_library
--!
--! Other configurations might work.
--!
--! The CASPER toolset must be open in the Simulink library browser before the FFT model is loaded to force it to re-parse the library
--!
--! ------------------------------------------------------------------------------
--! |  Page   | Addr|Bit(s)|     Name             | Description                   |
--! |---------|-----|------|---------------------:|------------|
--! | CONTROL |  0  | 7    | **SOFT_RESET**           | Reset the `FFT` block. Also reset the computation of the CASPER block pipelining delay. When released, the block will compute the block latency once a CASPER SYNC has passed through the block and make the result available.|
--! |         |     | 6:3  |  Unused              | |
--! |         |     |  2   | overflow_reset       | Resets the overflow counter |
--! |         |     |  1   | Unused            |  |
--! |         |     |  0   | BYPASS_FFT           | Bypass the FFT |
--! |         | 1:2 | 15:0 | FFT_SHIFT_SCHEDULE   | Sets the shifting schedule through the FFT to prevent overflow. Bit 0 specifies the behavior of stage 0, bit 1 of stage 1, and so on. |
--! |         | 3:4 | 15:0 | SYNC_PERIOD          | Number of clock cycles between SYNC pulses. If zero, no SYNC pulses are generated. See CASPER documentation for minimum SYNC spacing. |
--! |         | 5:6 | 15:0 | FFT_PIPELINE_DELAY            | Latency (in number of clocks) of the CASPER PFB/FFT. This is used to delay the input flags that accompany the data fed into the FFT so they come out aligned with the FFT output. This should be the values measured by FFT_MEASURED_PIPELINE_DELAY. |
--! | STATUS  | 0:1 | 15:0 | FFT_MEASURED_PIPELINE_DELAY   | Measured latency (in number of clocks) of the CASPER PFB/FFT. This is updated when a reset is performed |
--! |         |  2  |  7:0 | overflow_count                | Number of FFT overflows since reset (rolls back) |
--! ------------------------------------------------------------------------------
entity FFT is
    generic (
        IMPLEMENT_FFT: BOOLEAN :=TRUE
        );
    port (
        -- Input Interface
        --! Input time stream, implemented as a non-blocking AXI4 Streaming Interface with a 32-bit data bus.
        --! Each word presents 4 time samples, where the early sample is in the MSB.
        in_dat  : in AXIS32_DAT_STRUCT;

        -- Output Interface
        --! Output spectrum stream, implemented as a non-blocking AXI4 Streaming interface with a 72 bit bus.
        --! Each 72-bit word contains two 36-bit complex numbers (18 bit real signed + 18 bit imaginary signed values).
        --! The most significant 36 bits contains the value for the even frequency bins,
        --! while the lower ones is the value for the odd frequency bin.
        --! The Most significant bits of a complex values contain the real part.
        out_dat : out AXIS72_DAT_STRUCT;

        -- Common Clock and Reset
        clk     : in  std_logic; --! Processing clock, common to the input and output bus
        reset   : in  std_logic; --! clk-synchronous Antenna processor reset.
                                 --! In this module, resets the SYNC generator and send SYNC signals to the FFT

        -- Control interface (command and reply stream buses)
        CTRL_CMD_IN_DAT     : in  AXIS8_DAT_STRUCT;
        CTRL_CMD_IN_RDY     : out AXIS8_RDY_STRUCT;
        CTRL_RPLY_OUT_DAT   : out AXIS8_DAT_STRUCT;
        CTRL_RPLY_OUT_RDY   : in  AXIS8_RDY_STRUCT;
        CTRL_CLK            : in  std_logic;
        CTRL_RST            : in  std_logic
        );
end FFT;
--------- FFT architecture --------------------
--! Implements the FFT module functionnalities
architecture Behavioral of FFT is

signal FLAGS_IN,FLAGS_OUT: STD_LOGIC_VECTOR(5 downto 0);
signal FRAME_IN_DLY1,FRAME_IN_DLY2,FRAME_IN_DLY3,DLY_FRAME_OUT: STD_LOGIC:='0';
signal FRAME_VALID_IN_DLY1,FRAME_VALID_IN_DLY2,FRAME_VALID_IN_DLY3,DLY_FRAME_VALID_OUT: STD_LOGIC:='0';


signal FFT_PIPELINE_DELAY: STD_LOGIC_VECTOR(11 downto 0);
signal FFT_MEASURED_PIPELINE_DELAY: STD_LOGIC_VECTOR(11 downto 0);
signal SYNC_RESET: STD_LOGIC;


-- FFT block

signal FFT_IN:AXIS32_DAT_STRUCT;
signal FFT_CLK_EN: std_logic:='1'; -- init value needed for initial sync
signal fft_clk_en_buf: std_logic;
signal DELAY_CLK_EN: std_logic;
signal FFT_DOUT0, FFT_DOUT1, FFT_DOUT0_INT, FFT_DOUT1_INT: STD_LOGIC_VECTOR(out_dat.TDATA'Length/2-1 downto 0):=(others=>'0');
signal FFT_TDATA: STD_LOGIC_VECTOR(out_dat.TDATA'Range):=(others=>'0');
signal FFT_SYNC_IN: STD_LOGIC:='1'; -- init value needed to generate first sync pulse
signal FFT_SYNC_OUT: STD_LOGIC:='0';
signal FFT_SYNC_OUT2: STD_LOGIC:='0';
signal FFT_OVERFLOW, FFT_OVERFLOW_INT: STD_LOGIC:='0';
signal FFT_TUSER: std_logic_vector(out_dat.TUSER'Range);
signal FFT_TLAST: std_logic;
signal FFT_TVALID: std_logic;

--- Define Control word and its signals
signal CONTROL_BYTES: ByteArray(0 to 6); --
signal STATUS_BYTES: ByteArray(0 to 2);

signal BYPASS_FFT: STD_LOGIC;
signal SOFT_RESET: STD_LOGIC;
--signal DLY_RESET: STD_LOGIC;
signal FFT_SHIFT_SCHEDULE: STD_LOGIC_VECTOR(15 downto 0);
signal overflow_count: unsigned(7 downto 0);
signal overflow_reset: STD_LOGIC;

signal SYNC_PERIOD: unsigned(15 downto 0);
signal SYNC_FRAME_CTR: unsigned(SYNC_PERIOD'Range):=(others=>'0'); -- Counts SYNC pulses
signal SYNC_PERIOD_IS_ZERO: STD_LOGIC;
signal is_last_frame_of_sync_period: STD_LOGIC;

begin

-----------------------------------------------------------------------------------
-- CONTROL and STATUS Bytes
-----------------------------------------------------------------------------------
--! \addtogroup memory_map
--! FFT Module Memory Map
--!
--!  ------------------------------------------------------------------------------
--! |  Page   | Addr|Bit(s)|     Name             | Description                   |
--! |---------|-----|------|----------------------|-------------------------------|
--! | CONTROL |  0  | 7    | SOFT_RESET           | Reset the block. Also reset the computation of the CASPER block pipelining delay. When released, the block will compute the block latency once a CASPER SYNC has passed through the block and make the result available.|
--! |         |     | 6:3  |  Unused              | |
--! |         |     |  2   | overflow_reset       | Resets the overflow counter |
--! |         |     |  1   | Unused            |  |
--! |         |     |  0   | BYPASS_FFT           | Bypass the FFT |
--! |         | 1:2 | 15:0 | FFT_SHIFT_SCHEDULE   | Sets the shifting schedule through the FFT to prevent overflow. Bit 0 specifies the behavior of stage 0, bit 1 of stage 1, and so on. |
--! |         | 3:4 | 15:0 | SYNC_PERIOD          | Number of clock cycles between SYNC pulses. If zero, no SYNC pulses are generated. See CASPER documentation for minimum SYNC spacing. |
--! |         | 5:6 | 15:0 | FFT_PIPELINE_DELAY            | Latency (in number of clocks) of the CASPER PFB/FFT. This is used to delay the input flags that accompany the data fed into the FFT so they come out aligned with the FFT output. This should be the values measured by FFT_MEASURED_PIPELINE_DELAY. |
--! | STATUS  | 0:1 | 15:0 | FFT_MEASURED_PIPELINE_DELAY   | Measured latency (in number of clocks) of the CASPER PFB/FFT. This is updated when a reset is performed |
--! |         |  2  |  7:0 | overflow_count                | Number of FFT overflows since reset (rolls back) |
--!  ------------------------------------------------------------------------------
--!

-- CONTROL Byte 0
SOFT_RESET<=CONTROL_BYTES(0)(7);
overflow_reset<=CONTROL_BYTES(0)(2);
--DLY_RESET<=CONTROL_BYTES(0)(1);
BYPASS_FFT<=CONTROL_BYTES(0)(0); --!

--! CONTROL Byte 1-2
FFT_SHIFT_SCHEDULE<=to_slv(CONTROL_BYTES(1 to 2),FFT_SHIFT_SCHEDULE'Length); --Sets the shifting schedule through the FFT to prevent overflow. Bit 0 specifies the behavior of stage 0, bit 1 of stage 1, and so on.

-- CONTROL Bytes 3-4
SYNC_PERIOD<=to_unsigned(CONTROL_BYTES(3 to 4));

-- CONTROL Bytes 5-6
FFT_PIPELINE_DELAY<=to_slv(CONTROL_BYTES(5 to 6),FFT_PIPELINE_DELAY'Length);

-- STATUS Byte 0-1
STATUS_BYTES(0 to 1)<=("0000" & FFT_MEASURED_PIPELINE_DELAY(11 downto 8), FFT_MEASURED_PIPELINE_DELAY(7 downto 0));

-- STATUS Byte 2
STATUS_BYTES(2)<=std_logic_vector(overflow_count);

-----------------------------------------------------------------------------------
-- Memory-Mapped interface
-----------------------------------------------------------------------------------
--! Instantiates a memory-mapped interface to the control and status bytes
CTRL_SLAVE0: entity work.CTRL_SLAVE
    GENERIC MAP (
        NUMBER_OF_CONTROL_BYTES => CONTROL_BYTES'Length(1), -- Number of bits in the control word
        NUMBER_OF_STATUS_BYTES  => STATUS_BYTES'Length(1), -- Number of bits in the status word.
        DEFAULT_CONTROL_BYTES   => X"00_03FF_0000_0C9E", -- default values.
        USE_FIFO                => FALSE
    )

    PORT MAP(
        -- Control interface (command and reply stream buses)
        CTRL_CMD_IN_DAT   => CTRL_CMD_IN_DAT,
        CTRL_CMD_IN_RDY   => CTRL_CMD_IN_RDY,
        CTRL_RPLY_OUT_DAT => CTRL_RPLY_OUT_DAT,
        CTRL_RPLY_OUT_RDY => CTRL_RPLY_OUT_RDY,
        CTRL_CLK          => CTRL_CLK,
        CTRL_RST          => CTRL_RST,

        CONTROL_BYTES     => CONTROL_BYTES,
        STATUS_BYTES      => STATUS_BYTES,

        clk               => clk,
        RST               => reset
    );


-----------------------------------------------------------------------------------
-- Main process
-----------------------------------------------------------------------------------
--! Sends the input data to the FFT input and repackage the FFT output and pass it to the output bus.
FFT_CLK_EN<='1';
main_proc: process(clk)
    begin
        if rising_edge(clk) then
            SYNC_RESET<=SOFT_RESET or reset; -- Both reset sources are clk-synchronous

            -- Handle Resets
            -- If reset is enabled, the FFT is fed with dummy data and SYNC=1.
            -- When reset is disabled, the FFT is fed with the incoming data and is clocked only if the data is valid.
            -- SYNC is pulsed every N frames afterwards.
            if reset='1' then
                SYNC_FRAME_CTR<=(others=>'0'); --needed
                overflow_count<=(others=>'0');
                -- Clock the FFT with a SYNC input
                FFT_IN.TVALID<='0';
                FFT_IN.TDATA<=(others=>'X');
                -- FFT_CLK_EN<='1';
                FFT_SYNC_IN<='1';
                DELAY_CLK_EN<='0'; -- don't write anything to the delay line. we don't want the forced SYNC in there
            else
                -- Define intermediate signals to simplify the logic
                -- These are needed only at the first TLAST, so they have time to initialize before they are needed. No reset values are necessary.
                SYNC_PERIOD_IS_ZERO <= to_std_logic(SYNC_PERIOD=0);

                -- This is set on a TLAST=1, and is not needed until the next TLAST, so they have time to set before then.
                if SYNC_FRAME_CTR=(SYNC_PERIOD-1) then
                    is_last_frame_of_sync_period <='1';
                else
                    is_last_frame_of_sync_period <='0';
                end if;

                -- Counts the FFT overflows and stop at maximum value, and reset when overflow_reset=1
                if overflow_reset='1' then
                    overflow_count <= (others=>'0');
                elsif FFT_OVERFLOW='1' and signed(overflow_count)/=-1 then
                    overflow_count <= overflow_count + 1;
                end if;

                -- Process the input data
                FFT_IN       <= in_dat; -- delay the data so it is aligned with the generated sync
                -- FFT_CLK_EN   <= in_dat.TVALID; -- enable passing the valid data into the FFT
                DELAY_CLK_EN <= in_dat.TVALID; -- enable writing control signals through the delay line

                if in_dat.TVALID='1' then
                    -- Generate a SYNC pulse every SYNC_PERIOD frames on the last word of the previous frame
                    FFT_SYNC_IN<='0'; -- SYNC returns to zero on every valid word so it lasts only one sample. Will be overriden below.
                    if in_dat.TLAST='1' and SYNC_PERIOD_IS_ZERO='0' then -- if this is the last word of the frame, check if it is time to generate a SYNC pulse
                        if  is_last_frame_of_sync_period='1' then -- if maximum count reach, send a sync pulse, otherwise blank it
                            SYNC_FRAME_CTR<=(others=>'0');
                            FFT_SYNC_IN<='1';
                        else
                            SYNC_FRAME_CTR<=SYNC_FRAME_CTR+1;
                        end if; -- SYNC_FRAME_CTR = max count
                    end if; -- TLAST=1
                end if; -- TVALID=1
            end if; -- if RST


            -- if the FFT module is present and it is not bypassed by software, pass the FFT output to the output
            if IMPLEMENT_FFT=TRUE and BYPASS_FFT='0' then -- if the FFT is being used
                out_dat.TVALID <= FFT_TVALID and FFT_CLK_EN; -- The FFT outputs valid data only of the FFT is clocked AND the data has gone through the pipeline
                out_dat.TLAST <= FFT_TLAST;
                out_dat.TUSER <= FFT_TUSER;
                -- out_dat.TUSER(TUSER_FFT_OVERFLOW_BIT)<=FFT_OVERFLOW; -- add the FFT overflow flag
                out_dat.TDATA <= FFT_TDATA;
            else
                -- otherwise, just pass the input to the output, adapting the data width.
                out_dat.TVALID <= in_dat.TVALID;
                out_dat.TLAST <= in_dat.TLAST;
                out_dat.TUSER <= in_dat.TUSER;
--              out_dat.TUSER(TUSER_FFT_OVERFLOW_BIT)<='0'; -- add the FFT overflow flag
                out_dat.TDATA <= (others=>'0');
                for i in 0 to 3 loop
                    out_dat.TDATA(18*i+17 downto 18*i) <= std_logic_vector(resize(signed(in_dat.TDATA(8*i+7 downto 8*i)), 18)); -- make sure to sign extend the byte to the full 18 bits
                end loop; -- if FFT is implemented
            end if;

            if reset='1' then
                out_dat.TVALID<='0'; --! needed to make sure we don't sent invalid data after reset.
            end if;
        end if; -- clk
    end process;


FFT_GEN: if IMPLEMENT_FFT=TRUE generate

-----------------------------------------------------------------------------------
-- PFB/FFT Instance
-----------------------------------------------------------------------------------
--! This is a CASPER PFB/FFT geneted using Xilinx System Generator
--! Time-based data is presented 4 samples at a time,  in0 being the earliest sample. A time sample is 8 bit wide.
--! Output is the complex frequency samples (18 bits real + 18 bits imaginary). Out0 and out 1 provide the even and odd frequencies respectively. The upper
    FFT0: SIMPLE_PFB_V2
        PORT MAP(
            sync_in  => FFT_SYNC_IN,
            in0      => FFT_IN.TDATA(31 downto 24),
            in1      => FFT_IN.TDATA(23 downto 16),
            in2      => FFT_IN.TDATA(15 downto 8),
            in3      => FFT_IN.TDATA(7 downto 0),

            sync_out => FFT_SYNC_OUT,
            out1     => FFT_DOUT0_INT,
            out2     => FFT_DOUT1_INT,

            shift    => FFT_SHIFT_SCHEDULE(10 downto 0),
            overflow => FFT_OVERFLOW,
            ce_1     => fft_clk_en,
            clk_1    => clk
        );

-- -- Pass the FFT CE signal through a BUFH to avoid the signal to be replicated a large number of times to meet timing.
-- fft_ce_bufh : BUFH
--  port map (
--      I => FFT_CLK_EN,
--      O => fft_clk_en_buf
--  );

--  SYNC_RESET<=SOFT_RESET;

    FLAGS_IN      <= (FFT_SYNC_IN & FFT_IN.TLAST & FFT_IN.TUSER);
    FFT_TUSER     <= FLAGS_OUT(3 downto 0);
    FFT_TLAST     <= FLAGS_OUT(4);
    FFT_SYNC_OUT2 <= FLAGS_OUT(5); -- for validating proper delay adjustment; should align with FFT_SYNC_OUT
    FFT_TDATA     <= (FFT_DOUT0_INT & FFT_DOUT1_INT);


-----------------------------------------------------------------------------------
-- Pipeline Delay measurer/generator
-----------------------------------------------------------------------------------
--! Measures the CASPER block pipelining delay and propagate a vector containing the data flags with the same delay
    DELAY0: entity work.FFT_DELAY
        GENERIC MAP (
            CTR_WIDTH  => FFT_PIPELINE_DELAY'Length,
            DATA_WIDTH => FLAGS_IN'Length
            )

        PORT MAP(
            -- Delay measurement signals
            SYNC_IN        => FFT_SYNC_IN, -- SYNC at the input of the FFT
            SYNC_OUT       => FFT_SYNC_OUT, -- SYNC at the output of the FFT
            MEASURED_DELAY => FFT_MEASURED_PIPELINE_DELAY, -- Contains the pipeline delay

            -- Delay line
            DELAY          => FFT_PIPELINE_DELAY, -- Contains the pipeline delay
            DATA_IN        => FLAGS_IN, -- user data synchronized with the SYNC at the input of the processing block
            DATA_OUT       => FLAGS_OUT, -- user data synchronized with SYNC_OUT and DOUT
            VALID          => FFT_TVALID,

            clk            => clk,
            CE             => DELAY_CLK_EN,
            RST            => SYNC_RESET
        );
end generate;


end Behavioral;

