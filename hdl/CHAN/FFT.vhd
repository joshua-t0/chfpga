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
--      2012-09-11 JFC: Set sync_period to zero (no sync) by default.
--    2012-09-20 JFC: Implemented a better OVERFLOW_COUNTER with its own reset. CHanged default values for FFT_SHIFT.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chFPGA_Package.all; -- Get all component definitions

library UNISIM;
use UNISIM.VComponents.all;

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
        ctrl_cmd_in_dat     : in  AXIS8_DAT_STRUCT;
        ctrl_cmd_in_rdy     : out AXIS8_RDY_STRUCT;
        ctrl_rply_out_dat   : out AXIS8_DAT_STRUCT;
        ctrl_rply_out_rdy   : in  AXIS8_RDY_STRUCT;
        ctrl_clk            : in  std_logic;
        ctrl_rst            : in  std_logic
        );
end FFT;


--------- FFT architecture --------------------
--! Implements the FFT module functionnalities
architecture Behavioral of FFT is

signal flags_in, flags_out: std_logic_vector(5 downto 0);


signal fft_pipeline_delay: std_logic_vector(11 downto 0);
signal fft_measured_pipeline_delay: std_logic_vector(11 downto 0);
signal sync_reset: std_logic;


-- FFT block

signal fft_in: AXIS32_DAT_STRUCT;
signal fft_clk_en: std_logic:='1'; -- init value needed for initial sync
signal fft_clk_en_buf: std_logic;
signal delay_clk_en: std_logic;
signal fft_dout0_int, fft_dout1_int: std_logic_vector(out_dat.TDATA'Length/2-1 downto 0) := (others=>'0');
signal fft_tdata: std_logic_vector(out_dat.TDATA'RANGE) := (others=>'0');
signal fft_sync_in: std_logic := '1'; -- init value needed to generate first sync pulse
signal fft_sync_out: std_logic := '0';
signal fft_sync_out2: std_logic := '0';
signal fft_overflow: std_logic := '0';
signal fft_tuser: std_logic_vector(out_dat.TUSER'RANGE);
signal fft_tlast: std_logic;
signal fft_tvalid: std_logic;

--- Define Control word and its signals
signal control_bytes: ByteArray(0 to 6); --
signal status_bytes: ByteArray(0 to 2);

signal bypass_fft: std_logic;
signal soft_reset: std_logic;
--signal DLY_RESET: std_logic;
signal fft_shift_schedule: std_logic_vector(15 downto 0);
signal overflow_count: unsigned(7 downto 0);
signal overflow_reset: std_logic;

signal sync_period: unsigned(15 downto 0);
signal sync_frame_ctr: unsigned(sync_period'Range):=(others=>'0'); -- Counts SYNC pulses
signal sync_period_is_zero: std_logic;
signal is_last_frame_of_sync_period: std_logic;

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
--! | CONTROL |  0  | 7    | soft_reset           | Reset the block. Also reset the computation of the CASPER block pipelining delay. When released, the block will compute the block latency once a CASPER SYNC has passed through the block and make the result available.|
--! |         |     | 6:3  |  Unused              | |
--! |         |     |  2   | overflow_reset       | Resets the overflow counter |
--! |         |     |  1   | Unused            |  |
--! |         |     |  0   | bypass_fft           | Bypass the FFT |
--! |         | 1:2 | 15:0 | fft_shift_schedule   | Sets the shifting schedule through the FFT to prevent overflow. Bit 0 specifies the behavior of stage 0, bit 1 of stage 1, and so on. |
--! |         | 3:4 | 15:0 | sync_period          | Number of clock cycles between SYNC pulses. If zero, no SYNC pulses are generated. See CASPER documentation for minimum SYNC spacing. |
--! |         | 5:6 | 15:0 | fft_pipeline_delay            | Latency (in number of clocks) of the CASPER PFB/FFT. This is used to delay the input flags that accompany the data fed into the FFT so they come out aligned with the FFT output. This should be the values measured by fft_measured_pipeline_delay. |
--! | STATUS  | 0:1 | 15:0 | fft_measured_pipeline_delay   | Measured latency (in number of clocks) of the CASPER PFB/FFT. This is updated when a reset is performed |
--! |         |  2  |  7:0 | overflow_count                | Number of FFT overflows since reset (rolls back) |
--!  ------------------------------------------------------------------------------
--!

-- CONTROL Byte 0
soft_reset <= control_bytes(0)(7);
overflow_reset <= control_bytes(0)(2);
--DLY_RESET <= control_bytes(0)(1);
bypass_fft <= control_bytes(0)(0); --!

--! CONTROL Byte 1-2
fft_shift_schedule <= to_slv(control_bytes(1 to 2),fft_shift_schedule'Length); --Sets the shifting schedule through the FFT to prevent overflow. Bit 0 specifies the behavior of stage 0, bit 1 of stage 1, and so on.

-- CONTROL Bytes 3-4
sync_period <= to_unsigned(control_bytes(3 to 4));

-- CONTROL Bytes 5-6
fft_pipeline_delay <= to_slv(control_bytes(5 to 6),fft_pipeline_delay'Length);

-- STATUS Byte 0-1
status_bytes(0 to 1) <= ("0000" & fft_measured_pipeline_delay(11 downto 8), fft_measured_pipeline_delay(7 downto 0));

-- STATUS Byte 2
status_bytes(2) <= std_logic_vector(overflow_count);

-----------------------------------------------------------------------------------
-- Memory-Mapped interface
-----------------------------------------------------------------------------------
--! Instantiates a memory-mapped interface to the control and status bytes
CTRL_SLAVE0: entity work.CTRL_SLAVE
    GENERIC MAP (
        NUMBER_OF_CONTROL_BYTES => control_bytes'Length(1), -- Number of bits in the control word
        NUMBER_OF_STATUS_BYTES  => status_bytes'Length(1), -- Number of bits in the status word.
        DEFAULT_CONTROL_BYTES   => X"00_03FF_0000_0C9E", -- default values.
        USE_FIFO                => FALSE
    )

    PORT MAP(
        -- Control interface (command and reply stream buses)
        ctrl_cmd_in_dat   => ctrl_cmd_in_dat,
        ctrl_cmd_in_rdy   => ctrl_cmd_in_rdy,
        ctrl_rply_out_dat => ctrl_rply_out_dat,
        ctrl_rply_out_rdy => ctrl_rply_out_rdy,
        ctrl_clk          => ctrl_clk,
        ctrl_rst          => ctrl_rst,

        control_bytes     => control_bytes,
        status_bytes      => status_bytes,

        clk               => clk,
        RST               => reset
    );


-----------------------------------------------------------------------------------
-- Main process
-----------------------------------------------------------------------------------
--! Sends the input data to the FFT input and repackage the FFT output and pass it to the output bus.
fft_clk_en <= '1';
main_proc: process(clk)
    begin
        if rising_edge(clk) then
            sync_reset <= soft_reset or reset; -- Both reset sources are clk-synchronous

            -- Handle Resets
            -- If reset is enabled, the FFT is fed with dummy data and SYNC=1.
            -- When reset is disabled, the FFT is fed with the incoming data and is clocked only if the data is valid.
            -- SYNC is pulsed every N frames afterwards.
            if reset='1' then
                sync_frame_ctr <= (others=>'0'); --needed
                overflow_count <= (others=>'0');
                -- Clock the FFT with a SYNC input
                fft_in.TVALID <= '0';
                fft_in.TDATA <= (others=>'X');
                -- fft_clk_en<='1';
                fft_sync_in <= '1';
                delay_clk_en <= '0'; -- don't write anything to the delay line. we don't want the forced SYNC in there
            else
                -- Define intermediate signals to simplify the logic
                -- These are needed only at the first TLAST, so they have time to initialize before they are needed. No reset values are necessary.
                sync_period_is_zero <= to_std_logic(sync_period=0);

                -- This is set on a TLAST=1, and is not needed until the next TLAST, so they have time to set before then.
                if sync_frame_ctr = (sync_period - 1) then
                    is_last_frame_of_sync_period <='1';
                else
                    is_last_frame_of_sync_period <='0';
                end if;

                -- Counts the FFT overflows and stop at maximum value, and reset when overflow_reset=1
                if overflow_reset='1' then
                    overflow_count <= (others=>'0');
                elsif fft_overflow='1' and signed(overflow_count)/=-1 then
                    overflow_count <= overflow_count + 1;
                end if;

                -- Process the input data
                fft_in       <= in_dat; -- delay the data so it is aligned with the generated sync
                -- fft_clk_en   <= in_dat.TVALID; -- enable passing the valid data into the FFT
                delay_clk_en <= in_dat.TVALID; -- enable writing control signals through the delay line

                if in_dat.TVALID='1' then
                    -- Generate a SYNC pulse every sync_period frames on the last word of the previous frame
                    fft_sync_in <= '0'; -- SYNC returns to zero on every valid word so it lasts only one sample. Will be overriden below.
                    if in_dat.TLAST='1' and sync_period_is_zero='0' then -- if this is the last word of the frame, check if it is time to generate a SYNC pulse
                        if  is_last_frame_of_sync_period='1' then -- if maximum count reach, send a sync pulse, otherwise blank it
                            sync_frame_ctr <= (others=>'0');
                            fft_sync_in <= '1';
                        else
                            sync_frame_ctr <= sync_frame_ctr+1;
                        end if; -- sync_frame_ctr = max count
                    end if; -- TLAST=1
                end if; -- TVALID=1
            end if; -- if RST


            -- if the FFT module is present and it is not bypassed by software, pass the FFT output to the output
            if IMPLEMENT_FFT=TRUE and bypass_fft='0' then -- if the FFT is being used
                out_dat.TVALID <= fft_tvalid and fft_clk_en; -- The FFT outputs valid data only of the FFT is clocked AND the data has gone through the pipeline
                out_dat.TLAST <= fft_tlast;
                out_dat.TUSER <= fft_tuser;
                -- out_dat.TUSER(TUSER_FFT_OVERFLOW_BIT)<=fft_overflow; -- add the FFT overflow flag
                out_dat.TDATA <= fft_tdata;
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
            sync_in  => fft_sync_in,
            in0      => fft_in.TDATA(31 downto 24),
            in1      => fft_in.TDATA(23 downto 16),
            in2      => fft_in.TDATA(15 downto 8),
            in3      => fft_in.TDATA(7 downto 0),

            sync_out => fft_sync_out,
            out1     => fft_dout0_int,
            out2     => fft_dout1_int,

            shift    => fft_shift_schedule(10 downto 0),
            overflow => fft_overflow,
            ce_1     => fft_clk_en,
            clk_1    => clk
        );

-- -- Pass the FFT CE signal through a BUFH to avoid the signal to be replicated a large number of times to meet timing.
-- fft_ce_bufh : BUFH
--  port map (
--      I => fft_clk_en,
--      O => fft_clk_en_buf
--  );

--  sync_reset <= soft_reset;

    flags_in       <= (fft_sync_in & fft_in.TLAST & fft_in.TUSER);
    fft_tuser     <= flags_out(3 downto 0);
    fft_tlast     <= flags_out(4);
    fft_sync_out2 <= flags_out(5); -- for validating proper delay adjustment; should align with fft_sync_out
    fft_tdata     <= (fft_dout0_int & fft_dout1_int);


-----------------------------------------------------------------------------------
-- Pipeline Delay measurer/generator
-----------------------------------------------------------------------------------
--! Measures the CASPER block pipelining delay and propagate a vector containing the data flags with the same delay
    DELAY0: entity work.FFT_DELAY
        GENERIC MAP (
            CTR_WIDTH  => fft_pipeline_delay'Length,
            DATA_WIDTH => flags_in' Length
            )

        PORT MAP(
            -- Delay measurement signals
            SYNC_IN        => fft_sync_in, -- SYNC at the input of the FFT
            SYNC_OUT       => fft_sync_out, -- SYNC at the output of the FFT
            MEASURED_DELAY => fft_measured_pipeline_delay, -- Contains the pipeline delay

            -- Delay line
            DELAY          => fft_pipeline_delay, -- Contains the pipeline delay
            DATA_IN        => flags_in,  -- user data synchronized with the SYNC at the input of the processing block
            DATA_OUT       => flags_out, -- user data synchronized with SYNC_OUT and DOUT
            VALID          => fft_tvalid,

            clk            => clk,
            CE             => delay_clk_en,
            RST            => sync_reset
        );
end generate;


end Behavioral;

