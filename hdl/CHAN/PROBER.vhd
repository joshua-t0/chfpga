----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    01:03:42 09/15/2011
-- Design Name: chFPGA
-- Module Name:    PROBER - Behavioral
-- Project Name: CHIME PoC
-- Target Devices: Virtex 6 or 7 series
-- Tool versions: ISE 13.4  - Vivado 2016.4
-- Dependencies:
--
-- Revision:
--  2011-09-14 - File created
--  2012-05 - Major update.
--          Now can capture in bursts.
--          Frame headers are or arbitrary length and are stored in the header FIFO byte by byte.
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_MISC.ALL; -- for or_reduce()

library UNISIM;
use UNISIM.VComponents.all;

library xpm;
use xpm.vcomponents.all;

use work.chFPGA_Package.all; -- Get all component definitions

-- @brief Periodically captures a subset of AXI-S 32-bit wide data packets and send them over a 8-bit AXI-S interface.
--
-- Captures and buffer data frames and makes them available over a 8-bit AXI4 STREAM interface for transmission over Ethernet
-- A frame header is added to the data to profide flags, frame number, stream ID etc.
-- The number of frames to capture in a contiguous burst,  the number of frames between bursts, and the total number of bursts to send are configurable by software
-- If the number of bursts to transmit= 0, the bursts are sent continuously while the frame capture bit is high.
-- Otherwise, the tranemisision of N bursts is triggered on a 0-to-1 transition of the capture bit. The transition is disregarded while until all the bursts have been sent.
-- The capture-bit transition can happen on any byte of a frame, but transmission is always aligned on the beginning of the next frame.
--
-- The capture output format is documented [here][Ethernet_frame_formats]
--
entity PROBER is
    generic (
        SIM: BOOLEAN :=FALSE;
        NUMBER_OF_INPUTS : INTEGER := 2
        );
    port (
        -- Input Interface

        in_dat0     : in  AXIS32_DAT_STRUCT; -- Word to be captured (TDATA)
        in_dat1     : in  AXIS32_DAT_STRUCT; -- Word to be captured (TDATA)
        in_clk      : in  std_logic;
        in_reset    : in  std_logic;

        -- Output Interface

        OUT_DAT     : out AXIS8_DAT_STRUCT;
        OUT_RDY     : in  AXIS8_RDY_STRUCT;
        OUT_CLK     : in  std_logic;

        -- Control Interface (command and reply stream buses)

        ctrl_cmd_in_dat     : in  AXIS8_DAT_STRUCT;
        ctrl_cmd_in_rdy     : out AXIS8_RDY_STRUCT;
        ctrl_rply_out_dat   : out AXIS8_DAT_STRUCT;
        ctrl_rply_out_rdy   : in  AXIS8_RDY_STRUCT;
        ctrl_clk            : in  std_logic;
        ctrl_rst            : in  std_logic
    );

end PROBER;

---- ARCHITECTURE DECLARATION and DEFINITION --------------------------

architecture impl of PROBER is


    -----------------------------------------------------------------------
    -- Attributes
    -----------------------------------------------------------------------

    attribute equivalent_register_removal: string;
    attribute shreg_extract: string;
    attribute async_reg: string;

    -----------------------------------------------------------------------
    -- Constants
    -----------------------------------------------------------------------
    constant DEFAULT_BURST_PERIOD: std_logic_vector(23 downto 0) := sel(SIM, X"000004", X"05f5e1");

    -----------------------------------------------------------------------
    -- Signals
    -----------------------------------------------------------------------
     --attribute equivalent_register_removal of in_dat_reg: signal is "no";
    --attribute shreg_extract of in_dat_reg: signal is "no";

      -- DATA FIFO signals

    signal data_fifo_rd_en      : std_logic:='0';
    signal data_fifo_wr_en      : std_logic:='0';
    signal data_fifo_empty      : std_logic_vector(0 to 1);
    signal data_fifo_valid      : std_logic;
    signal data_fifo_full     : std_logic_vector(0 to 1);
--    signal data_fifo_almost_full : std_logic;
    signal data_fifo_overflow   : std_logic_vector(0 to 1);
    signal data_fifo_overflow_sticky: std_logic;
    signal data_fifo_din        : std_logic_vector(35 downto 0) := (others => '0'); -- initialization for nice simulations
    signal data_fifo_dout       : std_logic_vector(35 downto 0);

    -- global signals
    --signal FIFO_RESET_ALL: std_logic;

    --signal DATA_FIFO_OUT_DAT: AXIS8_DAT_STRUCT;
    --signal DATA_FIFO_OUT_RDY: AXIS8_RDY_STRUCT;

  
    -- Control and status bytes

    signal control_bytes: slv8_array(0 to 14); -- default value set in the CMD_SLAVE
    signal status_bytes: slv8_array(0 to 0);

    signal capture_offset: unsigned(23 downto 0);
    signal send_delay_target: unsigned(31 downto 0);
    signal burst_length: unsigned(1 downto 0); -- number of consecutives frames in a burst minus one
    signal stream_id: std_logic_vector(15 downto 0);
    signal new_source: std_logic;
    signal soft_reset: std_logic;
    signal fifo_reset: std_logic;
    signal prober_user_flags: std_logic;
    signal sub_period: unsigned(4 downto 0);
    signal primary_period: u24_array(0 to NUMBER_OF_INPUTS-1);

    signal current_source: std_logic;
    signal overrun: std_logic;

    signal rd_rst, wr_rst: std_logic;
    
    -- Communication between the write and read logic

    signal readout_req: std_logic; -- readout request flag , on the write clock
    signal readout_ack: std_logic; -- readout acknowledge flag, on the read clock
    signal burst_source: std_logic;
    signal burst_timestamp: std_logic_vector(47 downto 0);
    signal burst_flags: slv_array(0 to 3)(3 downto 0); -- flags for each frame of a burst

begin


-----------------------------------------------------------------------------------
-- CONTROL and STATUS Bytes
-----------------------------------------------------------------------------------
-- CAPTURE (PROBER) Module Memory Map
--
--  ------------------------------------------------------------------------------
-- |  Page   | Addr|Bit(s)|     Name             | Description                   |
-- |---------|-----|------|----------------------|-------------------------------|
-- | CONTROL |  0  |  7   | Soft reset           |                |
-- |         |     |  6   | fifo_reset           |                |
-- |         |     |  5   | input source         |                |
-- |         |     | 4:3  | (unused)             |                |
-- |         |     |  2   | prober_user_flags    | If True, returns user flags in last 4 bits captured from scaler |
-- |         |     | 1:0  | burst_length         | Number of consecutive frames in a burst minus one (0: 1 frame, 1: 2 frames etc.)|
-- |         | 1-3 | 23:0 | capture_offset(23:0) | Number of frames to skip before starting the capture (multiplied by 256)|
-- |         | 4-6 | 23:0 | primary_period(0)    |                |
-- |         | 7-8 | 15:0 | stream_id(15:0)      |                |
-- |         | 9-10| 15:0 | send_delay           | Time to wait before sending captured data |
-- |         |11-13| 23:0 | primary_period(1)    |                |
-- |         | 14  | 4:0  | sub_period           | range: 0-23.  Create additional captures every N=2^(sub_period+1) frames after the primary period. If N > primary_period, only the primary period frames are captured. If the primary period is not a multiple of N, the last sub capture of a period might be close to the beginning of the next period.|
-- | STATUS  |  0  |   7  | TUSER_CAPTURE_BIT    | For debugging. |
-- |         |     |   6  | inhibit_data         | For debugging. |
-- |         |     |   5  | current_source       |  |
-- |         |     |   4  | data_fifo_4mpty      | For debugging. |
-- |         |     |   3  | data_fifo_overflow   | For debugging. |
-- |         |     |   2  | data_fifo_overflow_sticky |           |
-- |         |     |   1  | header_fifo_overflow | For debugging. |
-- |         |     |   0  | '0'                  |                |
--  ------------------------------------------------------------------------------

-- CONTROL Byte 0
soft_reset <= control_bytes(0)(7);
--fifo_reset <= control_bytes(0)(6);
new_source <= control_bytes(0)(5);
prober_user_flags <= control_bytes(0)(2);
burst_length <= unsigned(control_bytes(0)(1 downto 0));
-- Burst from an iceboard of 16 channels ~250uS
-- Make roughly twice the burst time so run at half max speed.

-- CONTROL Byte 1-3
capture_offset <= to_unsigned(control_bytes(1 to 3));

-- CONTROL Bytes 4-6
primary_period(0) <= to_unsigned(control_bytes(4 to 6)); -- 24 bit period for input 0.


---- CONTROL Byte 5
--number_of_bursts <= unsigned(control_bytes(5));
---- CONTROL Byte 6
--probe_id <= control_bytes(6);

-- CONTROL Byte 7-8
stream_id <= to_slv(control_bytes(7 to 8));
-- CONTROL Byte 9-10
send_delay_target <= to_unsigned(control_bytes(9 to 10)) & X"0000";

-- CONTROL Bytes 11-13
primary_period(1) <= to_unsigned(control_bytes(11 to 13)); -- 24 bit period for input 1
---- CONTROL Bytes 14-16
sub_period <= unsigned(control_bytes(14)(4 downto 0)); -- Create additional captures every 2**(N+1) frames


-- control_bytes(11) used by capture_offset2

-- STATUS Byte 0
status_bytes(0)(5) <= current_source;
status_bytes(0)(4) <= data_fifo_empty(0); -- for debugging
status_bytes(0)(3) <= data_fifo_overflow(0); -- for debugging
status_bytes(0)(2) <= data_fifo_overflow_sticky; -- for debugging
status_bytes(0)(1) <= overrun; -- high if we attempted to capture a new burst when the readout of the previous one was not finished
status_bytes(0)(0) <= '0';
-- STATUS Byte 1
--status_bytes(1) <= std_logic_vector(trig_count);

-----------------------------------------------------------------------------------
-- Memory-Mapped interface instantiation
-----------------------------------------------------------------------------------
-- Instantiates a memory-mapped interface to the control and status bytes
CTRL_SLAVE0: entity work.CTRL_SLAVE
    GENERIC MAP (
        NUMBER_OF_CONTROL_BYTES => control_bytes'Length(1), --
        NUMBER_OF_STATUS_BYTES => status_bytes'Length(1), --
        -- 04 is equal to 00000100, setting prober_user_flags <= control_bytes(0)(2) <= '1'
        DEFAULT_CONTROL_BYTES => (X"04_000000" & DEFAULT_BURST_PERIOD & X"0000_0000" & DEFAULT_BURST_PERIOD & X"17") -- reset=0, burst length=1, burst period=1s @ 800 MHz/2048 samples, burst number = 0 (infinite), Probe ID=0xAA (unassigned yet)
        )
    PORT MAP(
        -- Control interface (command and reply stream buses)

        ctrl_cmd_in_dat   => ctrl_cmd_in_dat,
        ctrl_cmd_in_rdy   => ctrl_cmd_in_rdy,
        ctrl_rply_out_dat => ctrl_rply_out_dat,
        ctrl_rply_out_rdy => ctrl_rply_out_rdy,
        ctrl_clk          => ctrl_clk,
        ctrl_rst          => ctrl_rst,

        control_bytes => control_bytes,
        status_bytes  => status_bytes
    );



    fifo_blk: block
    
        signal por_rst: std_logic := '1'; -- Initialize to 1 to ensure power on reset.

    begin
        -----------------------------------------------------------------------
        -- Data FIFO
        -----------------------------------------------------------------------
        -- 36-bit x 2048 word FWFT Async Embed FIFO, latency=0
        --
        -- Implemented as two FIFO36E1 in parallel, each 18-bitx2048 words. We therefore can store 4 2048-sample frames.
        -- Using an embedded FIFO saves resources, but does not support assymetric aspect ratios, so we'll need to mux out the output into bytes, but this is still much smaller.
        --
        -- This works only for the 7-Series platforms.
        --
        -- Lower 32 bits are the data. Bit 32 is TLAST. Others are unused. 
        
        data_fifo_valid <= to_std_logic(all_zeros(data_fifo_empty)); -- We have valid data when none of the FIFOs are empty
         
        data_fifo_gen: for i in 0 to 1 generate -- Implement two FIFOs
    
            -- Define native wide data buses. Only part of those are actually used.
            signal di, do: std_logic_vector(63 downto 0);
            signal dip, dop: std_logic_vector(7 downto 0);
        begin
            di(15 downto 0) <= data_fifo_din(18*(i+1)-3 downto 18*i);
            dip(1 downto 0) <= data_fifo_din(18*(i+1)-1 downto 18*(i+1)-2);
            data_fifo_dout(18*(i+1)-1 downto 18*i) <= dop(1 downto 0) & do(15 downto 0);
            data_fifo_overflow(i) <= data_fifo_wr_en and data_fifo_full(i);
            -- FIFO36E1 (7-Series), 18-bit x 2048 words, Async, FWFT, latency=0
            data_fifo0 : FIFO36E1
                generic map (
                    --ALMOST_FULL_OFFSET      => to_bit_vector(ALMOST_FULL_THRESH_OFFSET, 13),    -- Number of words before FULL
                    --ALMOST_EMPTY_OFFSET     => to_bit_vector(ALMOST_EMPTY_THRESH_OFFSET, 13),    -- Number of words before EMPTY
                    DATA_WIDTH              => 18,                  --  each FIFO will be 18 bits x 2048
                    DO_REG                  => 1,                      -- Enable output register (1-0) Must be 1 if EN_SYN = FALSE
                    EN_SYN                  => FALSE,                  -- Asynchronous FIFO
                    FIFO_MODE               => "FIFO36",            -- "FIFO36" or "FIFO36_72"
                    FIRST_WORD_FALL_THROUGH => TRUE   -- We want FWFT
                )
                port map (
                    -- Write interfce
                    wrclk      => in_clk,              -- 1-bit input: Rising edge write clock.
                    wren       => data_fifo_wr_en and not wr_rst and to_std_logic(all_zeros(data_fifo_full)),     -- 1-bit input: Write enable
                    di         => di,
                    dip        => dip,
                    --almostfull => almost_full, -- 1-bit output: Almost full flag
                    full       => data_fifo_full(i),
                       
                    -- Read interface
                    rdclk       => out_clk, -- Read clock
                    rden        => data_fifo_rd_en and not rd_rst and to_std_logic(all_zeros(data_fifo_empty)), -- Read enable
                    regce       => '1', -- 1-bit input: Clock enable
                    do          => do,
                    dop         => dop,
                    --almostempty => almost_empty,
                    empty       => data_fifo_empty(i),
    
                    -- ECC Signals (unused)
                    injectdbiterr => '0',
                    injectsbiterr => '0',
    
                    -- Resets
                    rst    => rd_rst, -- Async -- write domain reset reset, must be high at least 5 cycles of the slowest clock
                    rstreg => '0'  -- Output register reset
                );
        end generate;
    
        -- Clear Power-on reset as soon as we have a clock
        process(all) begin
            por_rst <= '0' when rising_edge(out_clk);
        end process;
        
        -- Implement proper FIFO resets: reset pulse must be 5 clocks long (i.e 5 clocks of the slowest clock), and rd_en/wr_en must be masked by reset signals
        --
        -- Slow clock reset. 5x rd_clk.
        -- Async assert on por, external reset or user reset; sync deassert on rd_clk
       rd_rst0: xpm_cdc_async_rst 
            generic map (
                RST_ACTIVE_HIGH => 1, -- Active high reset
                DEST_SYNC_FF => 5 -- Reset pulse minimum width
            )
            port map (
                src_arst => in_reset or soft_reset or por_rst,
                dest_clk => out_clk,
                dest_arst => rd_rst
            );
        
        -- Extend wr reset until rd_reset is finished. Used only to mask wr_en.
        wr_rst0: xpm_cdc_async_rst
            generic map (
                RST_ACTIVE_HIGH => 1 -- Active high reset
            )
            port map (
                src_arst => rd_rst,
                dest_clk => in_clk,
                dest_arst => wr_rst
            );
end block fifo_blk;        

write_blk: block is
    -----------------------------
    -- FIFO readout signals
    -----------------------------

    signal in_dat: AXIS32_DAT_STRUCT_ARRAY(0 to NUMBER_OF_INPUTS-1);

    -- Offset and period counters
    signal primary_period_ctr: u24_array(0 to NUMBER_OF_INPUTS-1); -- Counts frames within a burst.
    signal offset_done: std_logic_vector(0 to NUMBER_OF_INPUTS-1);

    signal frame_ctr: unsigned_array(0 to NUMBER_OF_INPUTS-1)(47 downto 0); -- Frame counters

    signal burst_ctr: unsigned(burst_length'RANGE) := (others => '0'); -- Burst number being sent, from burst_length+1 down to 0, hence the extra bit. 0 means no data is to be sent.
    signal burst_capture: std_logic; -- high when burst capture is in progress on delayed data

    signal readout_acq_resync: std_logic;

begin

    readout_acq_cdc0: xpm_cdc_single
        generic map (SRC_INPUT_REG => 0)
        port map (src_clk => '0', src_in => readout_ack, dest_clk => in_clk, dest_out => readout_acq_resync);


    -- Remap input buses into an indexable array
    in_dat(0) <= in_dat0;
    in_dat(1) <= in_dat1;

    ------------------------------------
    -- FIFO Writing process
    ------------------------------------
    -- Captures the data and writes it to the data and header FIFO
    --
    -- Writes the incoming words in the data FIFO along with the LAST_WORD bit. The FIFO will be read one byte at a time by the reading interface.
    -- The header FIFO is written when the frame is complete.
    fifo_write_proc: process(all)
        variable frame_header: FRAME_HEADER_STRUCT;
        variable trig_var: std_logic;
        variable source: integer range 0 to NUMBER_OF_INPUTS-1;
        variable is_first_frame_of_burst: boolean;
    begin
        if rising_edge(in_clk) then
            -- Synchronous reset
--            reset_all <= soft_reset or in_reset; -- aggregate reset lines into a single, registered lines to simplify the logic. Both resets are synchronous to in_clk.
--            fifo_reset_reg <= fifo_reset or in_reset or soft_reset;

            data_fifo_overflow_sticky <= '0' when wr_rst else '1' when not all_zeros(data_fifo_overflow);

            -- -------------------------------------------
            -- Frame and period counter
            -- -------------------------------------------
            -- Counts incoming frames and the primary period for each input
            --
            -- Note: We don't hold trig for the burst length because the
            -- capture logic might want to capture multiple bursts
            -- synchronized to this trig.
            for i in 0 to NUMBER_OF_INPUTS-1 loop
                if in_dat(i).TVALID and in_dat(i).TLAST then
                        frame_ctr(i) <= frame_ctr(i) + 1;  -- always count the 48-bit frame number. We will put this in the header.
                        primary_period_ctr(i) <= primary_period_ctr(i) + 1; -- cound frames within a period on a 24-bit counter (~43s period max)
                        if offset_done(i)='0' then
                            if primary_period_ctr(i) = capture_offset then
                                offset_done(i) <= '1';
                                primary_period_ctr(i) <= (others=> '0');
                            end if;
                        else
                            if primary_period_ctr(i) = primary_period(i) then
                                primary_period_ctr(i) <= (others=> '0');
                            end if; -- if period done
                        end if; -- if offset done
                end if; -- last word
            end loop;

            source := to_integer(to_unsigned(current_source));

            -- Register the FIFO input data bus from selected input. This is in phase with data_fifo_wr_en and burst_capture.
            data_fifo_din(32) <= in_dat(source).TLAST;
            data_fifo_din(31 downto 0) <= in_dat(source).TDATA;
            -- Replace lower nibble of each byte with TUSER when prober_user_flags is set and we use source 1
            if prober_user_flags and current_source then
                for i in 0 to 3 loop
                    data_fifo_din(8*i+3 downto 8*i+0) <= in_dat(source).TUSER(3 downto 0);
                end loop;
            end if; -- send flags as LSB

            data_fifo_wr_en <= '0'; -- don't write data to FIFO unless overriden below

            if in_dat(source).TVALID then

                -- Determine if this is the first frame of a burst to be capture. This is true when 1)
                -- the offset for the selected source is elapsed and 2) all the bits in the sub-period
                -- range are zero. This necessarily always include the first frame of the period
                -- (counter is zero)
                is_first_frame_of_burst := offset_done(source)='1' and all_zeros(primary_period_ctr(source), to_integer(sub_period), 0);

                if burst_capture then
                    data_fifo_wr_en <= '1'; -- continue writing delayed data
                    if in_dat(source).TLAST then
                        burst_flags(to_integer(burst_ctr)) <= in_dat(source).TUSER; -- store TLAST flags for this frame
                        burst_ctr <= burst_ctr + 1;
                        if burst_ctr = burst_length then -- This was the last word of the last frame of the burst
                            burst_capture <= '0'; -- stop burst
                            readout_req <= not readout_req; -- toggle bit to signal readout should start now
                        end if; -- if last burst
                    end if; -- tlast
                elsif is_first_frame_of_burst then
                    if readout_acq_resync = readout_req then -- if previous readout is completed
                        burst_ctr <= (others => '0');
                        burst_capture <= '1';
                        data_fifo_wr_en <= '1'; -- start writing delayed data
                        burst_source <= current_source; -- capture burst info
                        burst_timestamp <= std_logic_vector(frame_ctr(source));
                    else -- oops, overrun. Flag it, and just skip this capture so we don't overflow the data FIFO.
                        overrun <= '1';
                    end if;
                else
                    -- change source only if we are between bursts
                    current_source <= new_source;
                end if; -- burst_capture or first_frame_of_burst
            end if; -- tvalid

            if wr_rst then
                burst_ctr <= (others => '0'); -- needed
                burst_capture <= '0';
                data_fifo_wr_en <= '0';
                current_source <= new_source;
                frame_ctr <= (others => (others => '0')); -- needed
                primary_period_ctr <= (others=> (others => '0')); -- needed.
                offset_done <= (others => '1') when capture_offset=0 else (others => '0');
                overrun <= '0';
                readout_req <= '0';
            end if; -- reset

        end if; -- clk
    end process;

end block write_blk;




read_blk: block is

    type SEND_STATE_TYPE IS (
        SEND_STDBY,
        SEND_DELAY,
        SEND_HEADER,
        SEND_DATA);
    signal send_state: SEND_STATE_TYPE;

    signal dest_ready: std_logic;
    signal send_delay_ctr: unsigned(send_delay_target'RANGE); -- 16 bit delay + 16 bits prescaler, counts 125 MHz
    signal byte_ctr: unsigned(3 downto 0); -- Must be wide enough to count header bytes and data word bytes
    signal frame_header_bytes: slv8_array(0 to FRAME_HEADER_BYTE_LENGTH-1); --
    signal burst_ctr: unsigned(burst_length'RANGE);
    signal readout_req_resync, readout_req_dly: std_logic;

begin


    -- Safely register the readout request flag from the write domain into the read domain
    readout_req_cdc0: xpm_cdc_single
        generic map (SRC_INPUT_REG => 0)
        port map (src_clk => '0', src_in => readout_req, dest_clk => out_clk, dest_out => readout_req_resync);

    -- Determine when we can write new data on the output bus
    dest_ready <= OUT_RDY.TREADY or not out_dat.TVALID; -- the output is ready for a new byte if there is currently no valid byte or if the destination is accepting current one.

    -- Fecth the next data word when when we are in the SEND_DATA phase, the destination can receive the data, and we just sent the last byte of the word.
    data_fifo_rd_en <= to_std_logic(send_state=SEND_DATA and dest_ready='1' and byte_ctr(1 downto 0) = "11");

    ----------------------------------------
    -- FIFO Readout process
    ----------------------------------------
    -- Sends the data stored inthe FIFO along with packet headers.
    --
    -- We sent one packet per frame, each with its own header.
    --
    -- Tranmission is trggered when readout_req is toggled. We acknoweledge completion of the readout by setting readout_ack to the value of readout_req.
    -- Since readout_req  is in the write clock domain, we use a CDC block to bring it in the readout domain.
    --
    -- We Use the data stored in burst_source, burst_timestamp and burst_flags to populate the headers of each packet. These are in the write clock domain, but we assume those are stable and unchanging when used in this readout clock domain. The delay in the readout_req CDC ensures those have stabilized before being used. The interlocking between readout_req and reasout_acq functionally ensures those are not changing until the readout is completed.
    --
    -- We use a large (16:1) mux to select bytes from the header or data words in order to minimize resource utilization. 
    -- Muxin the header avoids duplicaiton of the burst info registers above and opens possibilities for simplifications.
    -- Muxing the data words into bytes allows the use of embedded FIFO, which uses much less LUTs and REGs than a assymetric BRAM with external FIFO logic. 
    --
    -- Implementation Note:
    --    - The FIFO readout signals are generated combinatorially from the external OUT_RDY.TREADY signal and additional locally registered signals.
    --    - There is a combinatorial propagation path from OUT_RDY.TREADY through the logic below and through the FIFO_RD_EN logic.
    --    - This path is more prone to cause timing problems. registering  OUT_RDY.TREADY would have required to implement a 1-byte FIFO to deal with the latency.
    --
    read_proc: process(all)
        variable byte: integer;
        variable frame_header: FRAME_HEADER_STRUCT;
        variable frame_header_bytes: slv8_array(0 to FRAME_HEADER_BYTE_LENGTH-1); 
    begin
        if rising_edge(OUT_CLK) then
--            out_rst <= ctrl_rst or soft_reset; -- Retime the reset to OUT_CLK (which is normally ctrl_clk). We use an ASYNC_REG attribute because soft_reset is in the in_clk domain.

            -- delay
            readout_req_dly <= readout_req_resync;

            -- synchronous reset is at the bottom of this process

            -- Clear the TREADY if the data is read by the destination. This will be overriden below if a new byte is sent at the same time
            out_dat.TVALID <= '0' when OUT_RDY.TREADY;


            -- Implementing the send delay is tricky, as we do not want to
            -- delay every packets, but only the first packet in a burst.
            -- Otherwise this will limit our throughput.

            -- We start sending the packet only when the send delay counter has
            -- reached the target delay. We reset the delay counter only when we
            -- are finished sending a packet and  there is no more data in the
            -- FIFO, meaning we have finished that burst. We increment
            -- the counter when data appears on frame FIFO, as this event is
            -- related in time to the capture edge. Once the counter has
            -- reached its target delay, data transmission of the header starts.

            -- Once header transmision is finished, the data follows without
            -- interruption.
            --
            -- We implement this as a tree-state state machine.



            -- Count clocks to implement a programmable delay between a burst being captured and when it is read out
            send_delay_ctr <= send_delay_ctr + 1;

            case send_state is
                when SEND_STDBY => -- wait until burst data is ready
                    send_delay_ctr <= (others => '0');
                    send_state <= SEND_DELAY when readout_req_resync /= readout_req_dly; -- start readong out data when readout_req toggles 

                when SEND_DELAY => -- pre-burst readout delay
                    byte_ctr <= (others => '0');
                    burst_ctr <= (others => '0');
                    send_state <= SEND_HEADER when send_delay_ctr = send_delay_target;

                when SEND_HEADER => -- send packet header bytes

                    -- Pack the  frame information structure into an array of bytes.
                    frame_header.PROBE_ID := X"A0";
                    frame_header.PROBE_ID(0) := burst_source;
                    frame_header.STREAM_ID := stream_id;
                    frame_header.STREAM_ID(15 downto 12) := std_logic_vector(resize(burst_ctr, 4)); -- place the burst frame number in the top 4 bits of STREAM ID
                    frame_header.SERIAL_FLAGS :=  '0' & burst_flags(to_integer(burst_ctr))(TUSER_GAINBANK_BIT downto 0); -- capture serial flags (gain bank, adc overflow, fft overflow on last word
                    frame_header.FLAGS := burst_flags(to_integer(burst_ctr));
                    frame_header.TIMESTAMP := std_logic_vector(burst_timestamp); -- timestamp of the first frame in the burst
                    frame_header_bytes := struct_to_bytes(frame_header); -- Store the header into an array of bytes for insertion into the FIFO

                    byte := to_integer(byte_ctr);

                    if dest_ready then -- if we can send a new byte
                        out_dat.TDATA <= frame_header_bytes(byte);
                        out_dat.TVALID <= '1';
                        out_dat.TLAST <= '0';
                        byte_ctr <= byte_ctr + 1;
                        if byte_ctr = frame_header_bytes'LENGTH-1 then -- if this is the last header byte
                            send_state <= SEND_DATA; -- start sending the data
                            byte_ctr <= (others => '0');
                        end if;
                    end if; -- if header fifo & send_delay & dest_ready

                when SEND_DATA => -- send data
                    -- Send data until there is no more data in the buffer, going back to SEND_HEADER after each TLAST
                    if data_fifo_valid then -- if there is burst data
                        if dest_ready then
                            byte := 3 - to_integer(byte_ctr(1 downto 0)); -- Index bytes MSB first
                            out_dat.TDATA <= data_fifo_dout(8*byte+7 downto 8*byte);
                            out_dat.TVALID <= '1';
                            out_dat.TLAST <= '0';
                            byte_ctr <= byte_ctr + 1;
                            if byte_ctr(1 downto 0) = "11" then -- last byte of word
                                out_dat.TLAST <= data_fifo_dout(32);
                                byte_ctr <= (others => '0');
                                if data_fifo_dout(32) then -- if this is the last data byte, send next packet
                                    burst_ctr <= burst_ctr + 1;
                                    send_state <= SEND_HEADER;
                                end if;
                            end if; -- last byte of word
                        end if;
                    else
                        send_state <= SEND_STDBY;
                        readout_ack <= readout_req_resync; -- match readout acknowledge flag with the request flag to indicate the request has been fulfilled
                    end if;
            end case;

            if rd_rst then
                out_dat.TVALID <= '0'; -- needed
                send_state <= SEND_STDBY; -- needed to make sure we start with header transmission
                readout_ack <= '0';
            end if; -- reset
        end if; -- clk
    end process;
end block read_blk;
end impl;

