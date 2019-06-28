----------------------------------------------------------------------------------
--! \file
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

use work.chFPGA_Package.all; -- Get all component definitions
use work.ip_package.all; -- Import definition of components used in this module

--! @brief Periodically captures a subset of AXI-S 32-bit wide data packets and send them over a 8-bit AXI-S interface.
--!
--! Captures and buffer data frames and makes them available over a 8-bit AXI4 STREAM interface for transmission over Ethernet
--! A frame header is added to the data to profide flags, frame number, stream ID etc.
--! The number of frames to capture in a contiguous burst,  the number of frames between bursts, and the total number of bursts to send are configurable by software
--! If the number of bursts to transmit= 0, the bursts are sent continuously while the frame capture bit is high.
--! Otherwise, the tranemisision of N bursts is triggered on a 0-to-1 transition of the capture bit. The transition is disregarded while until all the bursts have been sent.
--! The capture-bit transition can happen on any byte of a frame, but transmission is always aligned on the beginning of the next frame.
--!
--! The capture output format is documented [here][Ethernet_frame_formats]
--!
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

architecture Behavioral of PROBER is


-----------------------------------------------------------------------
-- Attributes
-----------------------------------------------------------------------

attribute equivalent_register_removal: string;
attribute shreg_extract: string;

-----------------------------------------------------------------------
-- Signals
-----------------------------------------------------------------------
signal in_dat: AXIS32_DAT_STRUCT_ARRAY(0 to NUMBER_OF_INPUTS-1);
signal in_dat_reg: AXIS32_DAT_STRUCT; --! Registered Input data bus
signal trig_reg: std_logic;

attribute equivalent_register_removal of in_dat_reg: signal is "no";
attribute shreg_extract of in_dat_reg: signal is "no";


-- Header FIFO signals

signal header_fifo_rd_en    : std_logic:='0';
signal header_fifo_wr_en    : std_logic:='0';
signal header_fifo_empty    : std_logic;
signal header_fifo_valid    : std_logic;
signal header_fifo_overflow : std_logic;
signal header_fifo_din      : std_logic_vector(8 downto 0) := (others => '0'); -- initialization for nice simulations
signal header_fifo_dout     : std_logic_vector(8 downto 0);

-- DATA FIFO signals

signal data_fifo_rd_en      : std_logic:='0';
signal data_fifo_wr_en      : std_logic:='0';
signal data_fifo_empty      : std_logic;
signal data_fifo_valid      : std_logic;
signal data_fifo_overflow   : std_logic;
signal data_fifo_overflow_sticky: std_logic;
signal data_fifo_din        : std_logic_vector(35 downto 0) := (others => '0'); -- initialization for nice simulations
signal data_fifo_dout       : std_logic_vector(8 downto 0);

-- global signals
--signal FIFO_RESET_ALL: std_logic;

--signal DATA_FIFO_OUT_DAT: AXIS8_DAT_STRUCT;
--signal DATA_FIFO_OUT_RDY: AXIS8_RDY_STRUCT;

-- FIFO writing logic signals

--signal capture_mode_active: std_logic:='1';
--signal capture_frame: std_logic:='0';
--signal STORE_FRAME: std_logic:='0';
--signal trig_prev: std_logic;
signal frame_flags: std_logic_vector(3 downto 0);

-- Frame counters
signal frame_ctr: u48_array(0 to NUMBER_OF_INPUTS-1);

-- Header bytes & counter
signal frame_header_ctr: integer range 0 to FRAME_HEADER_BYTE_LENGTH;
signal frame_header_bytes: slv8_array(0 to FRAME_HEADER_BYTE_LENGTH-1); --

signal trig_count: unsigned(7 downto 0) := (others => '0'); -- Counts the number of frames that has been captured.

-- FIFO readout logic signals

signal out_dat_int: AXIS8_DAT_STRUCT := (DUMMY=>'0', TVALID=>'0', TDATA=>(others => '0'), TLAST=>'0');
--signal OVERFLOW_DAT: AXIS8_DAT_STRUCT;

signal send_header: std_logic;
signal dest_ready: std_logic;


-- Control and status bytes
signal control_bytes: slv8_array(0 to 14); -- default value set in the CMD_SLAVE
signal status_bytes: slv8_array(0 to 1);

--signal burst_length_reg: unsigned(1 downto 0); --

--signal number_of_bursts: unsigned(7 downto 0); -- total number of bursts to capture

-- Offset and period
signal primary_period: u24_array(0 to NUMBER_OF_INPUTS-1);
--signal burst_period_reg: unsigned(primary_period'RANGE) := (others => '0'); -- registered version of the primary_period minus one used to determine the end of the loop
signal primary_period_ctr: u24_array(0 to NUMBER_OF_INPUTS-1); -- Counts frames within a burst.
signal capture_offset: unsigned(23 downto 0);
--signal capture_offset_reg: unsigned(primary_period'RANGE);

--signal trig: std_logic_vector(0 to NUMBER_OF_INPUTS-1);
signal offset_done: std_logic_vector(0 to NUMBER_OF_INPUTS-1);

-- Number of consecutive frames in a burst
signal burst_length: unsigned(1 downto 0); -- number of consecutives frames in a burst
signal burst_ctr: UNSIGNED(burst_length'Range) := (others => '0'); -- Counts SYNC psignal SYNC_SAMPLE_MISMATCH: std_logic :=  '0';

--signal probe_id: std_logic_vector(7 downto 0);
signal stream_id: std_logic_vector(15 downto 0);
--signal continuous_transmission: std_logic;
signal new_source: unsigned(0 downto 0);
signal current_source: unsigned(0 downto 0);
signal inhibit_data: std_logic; -- inhibit data while transitionning from one source to the other
signal in_dat_reg_tvalid: std_logic;

--signal secondary_trig: std_logic;
--signal secondary_trig_active: std_logic;
--signal secondary_period: unsigned(23 downto 0);
signal sub_period: unsigned(4 downto 0);

--signal is_last_frame_of_period: std_logic;
--signal is_last_frame_of_burst: std_logic;
--signal is_last_burst: std_logic;
--signal burst_active: std_logic := '0';
signal send_delay: unsigned(31 downto 0);
signal send_delay_ctr: unsigned(31 downto 0); -- 16 bit delay + 16 bits prescaler, counts 125 MHz
signal send_data: std_logic;
signal soft_reset: std_logic;
signal fifo_reset: std_logic;
signal reset_all: std_logic;
signal serial_flags: std_logic_vector(2 downto 0);
signal fifo_reset_reg: std_logic;

-- These signals require previous signals to be defined

constant DEFAULT_BURST_PERIOD: std_logic_vector(23 downto 0) := sel(SIM,x"000004",X"05f5e1");

signal out_rst: std_logic;

attribute ASYNC_REG: string;
attribute ASYNC_REG of out_rst: signal is "true"; -- used to resync the soft_reset (in_clk domain) to the OUT_CLK domain.


begin


-----------------------------------------------------------------------------------
-- CONTROL and STATUS Bytes
-----------------------------------------------------------------------------------
--! \addtogroup memory_map
--! CAPTURE (PROBER) Module Memory Map
--!
--!  ------------------------------------------------------------------------------
--! |  Page   | Addr|Bit(s)|     Name             | Description                   |
--! |---------|-----|------|----------------------|-------------------------------|
--! | CONTROL |  0  |  7   | Soft reset           | |
--! |         |     |  6   | fifo_reset           | |
--! |         |     |  5   | input source         | |
--! |         |     | 4:2  | (unused)             |  |
--! |         |     | 1:0  | burst_length         | | Number of consecutive frames in a burst (1-3, limited to 2 max by data FIFO depth)
--! |         | 1-3 | 23:0 | capture_offset(23:0)     | Number of frames to skip before starting the capture (multiplied by 256)|
--! |         | 4-6 | 23:0 | primary_period(0)    | |
--! |         | 7-8 | 15:0 | stream_id(15:0)      | |
--! |         | 9-10| 15:0 | send_delay           | Time to wait before sending captured data |
--! |         |11-13| 23:0 | primary_period(1)    | |
--! |         | 14  | 4:0  | sub_period            | |  range: 0-23.  Create additional captures every N=2^(sub_period+1) frames after the primary period. If N > primary_period, only the primary period frames are captured. If the primary period is not a multiple of N, the last sub capture of a period might be close to the beginning of the next period.
--! | STATUS  |  0  |   7  | TUSER_CAPTURE_BIT    | For debugging. |
--! |         |     |   6  | inhibit_data        | For debugging. |
--! |         |     |   5  | current_source         |  |
--! |         |     |   4  | data_fifo_4mpty      | For debugging. |
--! |         |     |   3  | data_fifo_overflow   | For debugging. |
--! |         |     |   2  | data_fifo_overflow_sticky         |  |
--! |         |     |   1  | header_fifo_overflow   | For debugging. |
--! |         |     |   0  | '0'  |  |
--! |         |  1  |  7:0 | trig_count           | |
--!  ------------------------------------------------------------------------------

-- CONTROL Byte 0
soft_reset <= control_bytes(0)(7);
fifo_reset <= control_bytes(0)(6);
new_source <= unsigned(control_bytes(0)(5 downto 5));
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
send_delay <= to_unsigned(control_bytes(9 to 10)) & X"0000";

-- CONTROL Bytes 11-13
primary_period(1) <= to_unsigned(control_bytes(11 to 13)); -- 24 bit period for input 1
---- CONTROL Bytes 14-16
sub_period <= unsigned(control_bytes(14)(4 downto 0)); -- Create additional captures every 2**(N+1) frames


-- control_bytes(11) used by capture_offset2

-- STATUS Byte 0
status_bytes(0)(7) <= in_dat_reg.TUSER(TUSER_CAPTURE_BIT); -- for debugging
status_bytes(0)(6) <= inhibit_data; -- for debugging
status_bytes(0)(5) <= current_source(0);
status_bytes(0)(4) <= data_fifo_empty; -- for debugging
status_bytes(0)(3) <= data_fifo_overflow; -- for debugging
status_bytes(0)(2) <= data_fifo_overflow_sticky; -- for debugging
status_bytes(0)(1) <= header_fifo_overflow;
status_bytes(0)(0) <= '0';
-- STATUS Byte 1
status_bytes(1) <= std_logic_vector(trig_count);

-----------------------------------------------------------------------------------
-- Memory-Mapped interface instantiation
-----------------------------------------------------------------------------------
--! Instantiates a memory-mapped interface to the control and status bytes
CTRL_SLAVE0: entity work.CTRL_SLAVE
    GENERIC MAP (
        NUMBER_OF_CONTROL_BYTES => control_bytes'Length(1), --
        NUMBER_OF_STATUS_BYTES => status_bytes'Length(1), --
        DEFAULT_CONTROL_BYTES => (X"01_000000" & DEFAULT_BURST_PERIOD & X"0000_0000" & DEFAULT_BURST_PERIOD & X"17"), -- reset=0, burst length=1, burst period=1s @ 800 MHz/2048 samples, burst number = 0 (infinite), Probe ID=0xAA (unassigned yet)
        USE_FIFO => FALSE
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
        status_bytes  => status_bytes,

        clk => in_clk,
        rst => in_reset
    );


------------------------------------
-- Header and Data FIFO instantiation
------------------------------------

-- Data FIFO: 36 bit input, 9 bits output.
-- FIFO is First Word Fall Through
--FIFO_RESET_ALL<=rst or soft_reset or fifo_reset;

-----------------------------------------------------------------------
-- Data FIFO Definition
-----------------------------------------------------------------------
--! The data FIFO contains the captured frame data. It has a 36-bit wide input and a 9 bit wide clocked.
--! Only 32 bits and 8 bits are used for the data at th einput and output respectively. The extra bits are used to flag the end of the frame.
--! The input and output operate on independent clocks
--! The FIFO is First Word Fall Through.

DATA_FIFO0 : prober_data_fifo
  port map (
    rst      => fifo_reset_reg, -- clocked on OUT_CLK
    wr_clk   => in_clk,
    rd_clk   => OUT_CLK,
    din      => data_fifo_din,
    wr_en    => data_fifo_wr_en,
    rd_en    => data_fifo_rd_en,
    dout     => data_fifo_dout,
    full     => open,
    overflow => data_fifo_overflow,
    valid    => data_fifo_valid,
    empty    => data_fifo_empty
  );

-----------------------------------------------------------------------
-- Header FIFO Definition
-----------------------------------------------------------------------
--! The Header FIFO contains the frame header. It has a 9-bit wide input and a 9 bit wide.
--! The input and output operate on independent clocks
--! The FIFO is First Word Fall Through.
HEADER_FIFO0 : prober_frame_fifo
  PORT MAP (
    rst      => fifo_reset_reg, -- clocked on OUT_CLK
    wr_clk   => in_clk,
    rd_clk   => OUT_CLK,
    din      => header_fifo_din,
    wr_en    => header_fifo_wr_en,
    rd_en    => header_fifo_rd_en,
    dout     => header_fifo_dout,
    full     => open,
    overflow => header_fifo_overflow,
    valid    => header_fifo_valid,
    empty    => header_fifo_empty
  );


in_dat(0) <= in_dat0;
in_dat(1) <= in_dat1;

------------------------------------
-- FIFO Writing process
------------------------------------
--! Captures the data and writes it to the data and header FIFO
--!
--! Writes the incoming words in the data FIFO along with the LAST_WORD bit. The FIFO will be read one byte at a time by the reading interface.
--! The header FIFO is written when the frame is complete.
fifo_write_proc: process(in_clk)
    variable frame_header: FRAME_HEADER_STRUCT;
    variable trig_var: std_logic;
    variable source: integer range 0 to NUMBER_OF_INPUTS-1;
    begin
        if rising_edge(in_clk) then
            -- Synchronous reset
            reset_all <= soft_reset or in_reset; -- aggregate reset lines into a single, registered lines to simplify the logic. Both resets are synchronous to in_clk.
            if fifo_reset='1' or reset_all='1' then
                data_fifo_overflow_sticky <= '0';
            else
                data_fifo_overflow_sticky <= data_fifo_overflow_sticky or data_fifo_overflow;
            end if;



            -- -------------------------------------------
            -- Frame and period counter
            -- -------------------------------------------
            -- Counts incoming frames and the primary period  for each input
            --
            -- Note: We don't hold trig for the burst length because the
            -- capture logic might want to capture multiple bursts
            -- synchronized to this trig.
            for i in 0 to NUMBER_OF_INPUTS-1 loop
                if in_dat(i).TVALID='1' and in_dat(i).TLAST='1' then
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

            source := to_integer(current_source);

            if in_dat(source).TVALID='1' then

                -- -------------------------------------------
                -- Keep track of serial flags
                -- -------------------------------------------
                -- Keep track of the serial flags provided with each incoming
                -- word. We put those in N-bit shift register, so we can have
                -- access to the last N flags of the frame.
                serial_flags(2 downto 1) <= serial_flags(1 downto 0);
                serial_flags(0) <= in_dat(source).TUSER(TUSER_SERIAL_FLAGS_BIT);

                -- -------------------------------------------
                -- Cumulate user flags
                -- -------------------------------------------
                -- Cumulate the flags for each incoming word. Clear when the last word is received.
                -- When  TLAST=1, `last_flag` contains the or'ed version of all flags EXCEPT the ones sent along the last word. We need to add them later.
                frame_flags <= frame_flags or in_dat_reg.TUSER;


                if in_dat(source).TLAST = '1' then
                    -- Clear the frame flags
                    frame_flags <= (others => '0');

                    -- Freeze the frame information. It might be sent out or not, depending on whether the frame is captured. The data is sent
                    frame_header.PROBE_ID := X"A0";
                    frame_header.PROBE_ID(0) := current_source(0);
                    frame_header.STREAM_ID := stream_id;
                    frame_header.SERIAL_FLAGS := serial_flags(2 downto 0) & in_dat(source).TUSER(TUSER_SERIAL_FLAGS_BIT);
                    frame_header.FLAGS := frame_flags or in_dat(source).TUSER;
                    frame_header.TIMESTAMP := std_logic_vector(frame_ctr(source));
                    -- Store the header into an adday of bytes for insertion into the FIFO
                    frame_header_bytes <= struct_to_bytes(frame_header);

                    -- switch to the new data source on a frame boundary
                    inhibit_data <= '0';
                    if new_source /= current_source then
                        current_source <= new_source;
                        inhibit_data <= '1';
                    end if;
                end if;
            end if;

            -- register the selected input bus and corresponding trigger
            in_dat_reg <= in_dat(source);
            --trig_reg <= trig(source);
            trig_reg <= offset_done(source) and not inhibit_data;
            for i in 0 to 23 loop
                if i <= to_integer(sub_period) and primary_period_ctr(source)(i)='1' then
                    trig_reg <= '0';
                end if;
            end loop;

            if reset_all='1' then
                trig_reg <= '0';
                inhibit_data <= '0';
                current_source <= new_source;
                in_dat_reg_tvalid <= '0';
                frame_ctr <= (others => (others => '0')); -- needed
                primary_period_ctr <= (others=> (others => '0')); -- needed.
                if capture_offset=0 then
                    offset_done <= (others => '1');
                else
                    offset_done <= (others => '0');
                end if;
            end if; -- reset


            -- -------------------------------------------
            -- Write frame header bytes in the header FIFO
            -- -------------------------------------------
            --
            -- Write bytes from frame_header_bytes into the HEADER_FIFO until frame_header_ctr=0. The last byte of the frame has bit 8 set to '1'.
            -- This block has to be before frame_header_ctr is assigned for transmission of a new frame so it can be overriden
            header_fifo_wr_en <= '0'; -- by default do not write to the header FIFO - will be overriden below
            header_fifo_din(7 downto 0) <= frame_header_bytes(0);  -- always assign to save logic
            header_fifo_din(8) <= '0'; -- this is not the last word by default
            if frame_header_ctr /= 0 then  -- if we have bytes to send
                frame_header_ctr <= frame_header_ctr - 1; -- is overriden below is a new header is to be stored
                if frame_header_ctr = 1 then -- if the last byte
                    header_fifo_din(8) <= '1'; -- set bit 8 to '1' to indicate this is the last byte of the frame in the FIFO.
                end if;
                header_fifo_wr_en <= '1'; -- write byte to the FIFO
                frame_header_bytes(0 to frame_header_bytes'Length-2) <= frame_header_bytes(1 to frame_header_bytes'Length-1); -- Shift bytes by one position towards byte 0
            end if;

            -- -------------------------------------------
            -- Extend burst capture
            -- -------------------------------------------
            --
            -- Generate the capture_frame signal, which tells whether the words of this frames are to be stored in the data FIFO
            if in_dat_reg.TVALID='1' and in_dat_reg.TLAST='1' then -- If first word of the frame

                -- Extend the trig for the burst length
                if trig_reg = '1'  then
                    burst_ctr <= burst_length - 1;
                elsif burst_ctr /= 0 then
                    burst_ctr <= burst_ctr - 1;
                end if;
            end if; -- if FIRST word of frame


            -- -------------------------------------------
            -- Prepare data to be written into data FIFO
            -- -------------------------------------------
            -- The FIFO will be read one 9-bit byte at a time. The MSB is read first.
            -- The extra bit on each byte is zero, except for the LSB , where it indicate whether this is the last byte
            data_fifo_din <= (others => '0'); -- Clear unused bits (other bits 8, or unused data bits when sending flags)
            data_fifo_din(8) <= in_dat_reg.TLAST; -- this is bit 8 of the last byte to be read out of the FIFO for each word written in

            data_fifo_din(34 downto 27) <= in_dat_reg.TDATA(31 downto 24);
            data_fifo_din(25 downto 18) <= in_dat_reg.TDATA(23 downto 16);
            data_fifo_din(16 downto 9) <= in_dat_reg.TDATA(15 downto 8);
            data_fifo_din(7 downto 0) <= in_dat_reg.TDATA(7 downto 0);
            if current_source=1 then
                data_fifo_din(30 downto 27) <= in_dat_reg.TUSER;
                data_fifo_din(21 downto 18) <= in_dat_reg.TUSER;
                data_fifo_din(12 downto 9) <= in_dat_reg.TUSER;
                data_fifo_din(3 downto 0) <= in_dat_reg.TUSER;
            end if;


            -- -------------------------------------------
            -- Generate the data FIFO write signals for words in a burst
            -- -------------------------------------------
            data_fifo_wr_en <= '0'; -- by default, do not wtite to the DATA FIFOs. Will be overriden below when appropriate
            if in_dat_reg.TVALID='1' and (trig_reg='1' or burst_ctr /= 0) then
                data_fifo_wr_en <= '1'; -- by default, do not wtite to the DATA FIFOs. Will be overriden below when appropriate

                if in_dat_reg.TLAST='1' then

                    -- Decrement burst counter or reset it when a new trigger arrives
                    burst_ctr <= burst_ctr - 1; -- at this point burst_ctr is either non-zero (burst_ctr /= 0) or we will reset it anyway below (trig_reg='1')
                    if trig_reg = '1'  then
                        burst_ctr <= burst_length;
                    end if;

                    -- If this is the last word, start the writing of the frame header info in the header FIFO
                    -- We do this by setting frame_header_ctr to the number of header bytes to indicate that the header bytes are ready to be sent into the FIFO
                    frame_header_ctr <= FRAME_HEADER_BYTE_LENGTH;
                    trig_count <= trig_count + 1; -- keep track of how manny triggers we detected for debugging purposes
                end if; -- capture_frame=1
            end if; -- TVALID='1' and capture word

            if reset_all='1' then
                in_dat_reg.TVALID <= '0';
                -- FIFO signals
                header_fifo_wr_en <= '0'; -- needed
                frame_header_ctr <= 0;
                data_fifo_wr_en <= '0'; -- needed

                -- Secondary triggers
                burst_ctr <= (others => '0'); -- needed
                -- Captured frame counter
                trig_count <= (others => '0'); -- needed

            end if; -- if reset
        end if; -- clk
    end process;



----------------------------------------
-- FIFO Readout process
----------------------------------------
--! Reads the data and header FIFOs and send the data to the destination bus when it is ready.
--!
--! When the destination is ready, sends the header FIFO  bytes until we encounter bit(8)=1, then sends the DATA FIFO bytes until we encounter bit(8)=1 and go back to send headr bytes.
--! Implementation Note:
--!    - The FIFO readout signals are generated combinatorially from the external OUT_RDY.TREADY signal and additional locally registered signals.
--!    - There is a combinatorial propagation path from OUT_RDY.TREADY through the logic below and through the FIFO_RD_EN logic.
--!    - This path is more prone to cause timing problems. registering  OUT_RDY.TREADY would have required to implement a 1-byte FIFO to deal with the latency.

OUT_DAT <= out_dat_int;

-- Determines when the source and destination are ready
dest_ready <='1' when OUT_RDY.TREADY='1' or out_dat_int.TVALID='0' else '0'; -- the output is ready for a new byte if there is currently no valid byte or if the destination is accepting current one.

-- Determine when to read the data and header FIFOs
data_fifo_rd_en <= dest_ready and (not send_header); -- Read data FIFO on the TREADY singal and only if there is a valid frame and we are not sending the header byte
header_fifo_rd_en <= dest_ready and send_header and send_data; -- read the new frame status when we read the last byte of a frame


read_proc: process(OUT_CLK)
    begin
        if rising_edge(OUT_CLK) then
            out_rst <= ctrl_rst or soft_reset; -- Retime the reset to OUT_CLK (which is normally ctrl_clk). We use an ASYNC_REG attribute because soft_reset is in the in_clk domain.
            fifo_reset_reg <= fifo_reset;

            -- synchronous reset is at the bottom of this process

            -- Handle send delay
            if send_header = '1' then
                if header_fifo_valid='0' then
                    send_delay_ctr <= (others => '0');
                    send_data <= '0';
                elsif send_delay_ctr=send_delay then
                    send_data <= '1';
                else
                    send_data <= '0';
                    send_delay_ctr <= send_delay_ctr + 1;
                end if;
            end if;

            -- Clear the TREADY if the data is read by the destination. This will be overriden below if a new byte is sent at the same time
            if OUT_RDY.TREADY='1' then
                out_dat_int.TVALID <= '0';
            end if;

            -- Output the data to the destination
            if dest_ready='1'  then -- if the bus is ready to receive a new byte
                if send_header='1' and send_data='1' and header_fifo_valid='1' then -- if we have a header byte to send
                    out_dat_int.TDATA <= lsb(header_fifo_dout);
                    out_dat_int.TVALID <= '1';
                    out_dat_int.TLAST <= '0';
                    if header_fifo_dout(8) = '1' then -- if this is the last header byte
                        send_header <= '0'; -- start sending the data
                    end if;
                elsif send_header='0' and  data_fifo_valid='1' then
                    out_dat_int.TDATA <= lsb(data_fifo_dout);
                    out_dat_int.TVALID <= '1';
                    out_dat_int.TLAST <= data_fifo_dout(8);
                    if data_fifo_dout(8)='1' then -- if this is the last data byte
                        send_header <= '1'; -- start sending the next header
                    end if;

                --else -- if we have nothing to send
                --    out_dat_int.TVALID <= '0';
                end if; -- HEADER or DATA ready to be sent
            end if; -- if destination ready
            -- Synchronous reset

            if out_rst='1' then
                out_dat_int.TVALID <= '0'; -- needed
                send_header <= '1'; -- needed to make sure we start with header transmission
                send_data <= '0';
                send_delay_ctr <= (others => '0');
            end if; -- reset
        end if; -- clk
    end process;


end Behavioral;

