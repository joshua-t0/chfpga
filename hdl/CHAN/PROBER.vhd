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
        SIM: BOOLEAN :=FALSE
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

signal in_dat_reg: AXIS32_DAT_STRUCT; --! Registered Input data bus
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

signal capture_mode_active: std_logic:='1';
signal capture_frame: std_logic:='0';
--signal STORE_FRAME: std_logic:='0';
signal trig_prev: std_logic;
signal frame_flags: std_logic_vector(3 downto 0);

signal frame_ctr: UNSIGNED(FRAME_HEADER_STRUCT.TIMESTAMP'Range) := (others => '0');
signal frame_header_ctr: integer range 0 to FRAME_HEADER_BYTE_LENGTH;
signal frame_header_bytes: slv8_array(0 to FRAME_HEADER_BYTE_LENGTH-1); --
signal write_frame_header_bytes: std_logic; --

signal trig_count: unsigned(7 downto 0) := (others => '0'); -- Counts the number of frames that has been captured.

-- FIFO readout logic signals

signal out_dat_int: AXIS8_DAT_STRUCT := (DUMMY=>'0', TVALID=>'0', TDATA=>(others => '0'), TLAST=>'0');
--signal OVERFLOW_DAT: AXIS8_DAT_STRUCT;

signal send_header: std_logic;
signal dest_ready: std_logic;


-- Control and status bytes
signal control_bytes: slv8_array(0 to 11); -- default value set in the CMD_SLAVE
signal status_bytes: slv8_array(0 to 1);

signal burst_length: unsigned(7 downto 0);
signal burst_number: unsigned(7 downto 0);
signal burst_period: unsigned(23 downto 0);
signal burst_period_minus_1: unsigned(burst_period'Range) := (others => '0'); -- registered version of the burst_period minus one used to determine the end of the loop
signal probe_id: std_logic_vector(7 downto 0);
signal stream_id: std_logic_vector(15 downto 0);
signal continuous_transmission: std_logic;
signal input_source: std_logic;

signal is_last_frame_of_period: std_logic;
signal is_last_frame_of_burst: std_logic;
signal is_last_burst: std_logic;
signal burst_active: std_logic := '0';
signal burst_delay: unsigned(23 downto 0);
signal burst_delay2: unsigned(23 downto 0);
signal send_delay: unsigned(31 downto 0);
signal send_delay_ctr: unsigned(31 downto 0); -- 16 bit delay + 16 bits prescaler, counts 125 MHz
signal send_data: std_logic;
signal soft_reset: std_logic;
signal fifo_reset: std_logic;
signal reset_all: std_logic;
signal serial_flags: std_logic_vector(2 downto 0);
signal fifo_reset_reg: std_logic;

-- These signals require previous signals to be defined
signal burst_frame_ctr: unsigned(burst_period'Range) := (others => '0'); -- Counts frames within a burst.
signal burst_ctr: UNSIGNED(burst_number'Range) := (others => '0'); -- Counts SYNC psignal SYNC_SAMPLE_MISMATCH: std_logic :=  '0';

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
--! |         |     |  4:0 | burst_delay(12:8)     | Number of frames to skip before starting the capture (multiplied by 256)|
--! |         |  1  |  7:4 | burst_delay(16:13)     | Number of frames to skip before starting the capture (multiplied by 256)|
--! |         |  1  |  3:0 | burst_length         | |
--! |         | 2:4 | 23:0 | burst_period         | |
--! |         |  5  |  7:0 | burst_number         | |
--! |         |  6  |  7:0 | probe_id             | |
--! |         |  7  |  7:4 | burst_delay(20:17)   | |
--! |         | 7-8 | 15:0 | stream_id(15:0)      | |
--! |         | 9-10| 15:0 | send_delay           | Time to wait before sending captured data |
--! |         | 11  | 7:0  | burst_delay(7:0)     | |
--! | STATUS  |  0  |   7  | TUSER_CAPTURE_BIT    | For debugging. |
--! |         |     |   6  | capture_frame        | For debugging. |
--! |         |     |   5  | '0' (unused)         |  |
--! |         |     |   4  | data_fifo_empty      | For debugging. |
--! |         |     |   3  | data_fifo_overflow   | For debugging. |
--! |         |     |  2:1 | '0' (unused)         |  |
--! |         |     |   0  | capture_mode_active  |  |
--! |         |  1  |  7:0 | trig_count           | |
--!  ------------------------------------------------------------------------------

-- CONTROL Byte 0
soft_reset <= control_bytes(0)(7);
fifo_reset <= control_bytes(0)(6);
input_source <= control_bytes(0)(5);
-- Burst from an iceboard of 16 channels ~250uS
-- Make roughly twice the burst time so run at half max speed.
burst_delay2 <= ("000" & unsigned(control_bytes(7)(7 downto 4)) &
                         unsigned(control_bytes(1)(7 downto 4)) &
                         unsigned(control_bytes(0)(4 downto 0)) &
                         unsigned(control_bytes(11)));

-- CONTROL Byte 1
--  Bits 7:4 used by burst_delay2
burst_length <= ("0000" & unsigned(control_bytes(1)(3 downto 0)));
-- CONTROL Bytes 2-4
burst_period <= (unsigned(control_bytes(2)) & unsigned(control_bytes(3)) & unsigned(control_bytes(4))); -- 24 bit burst period. Period = 1/850e6 samples/s *2048samples/frame * 2^24 frames = 40.4 seconds max between bursts
-- CONTROL Byte 5
burst_number <= unsigned(control_bytes(5));
-- CONTROL Byte 6
probe_id <= control_bytes(6);
-- CONTROL Byte 7-8
-- control_bytes(7)(7 downto 4) used by burst_delay2
stream_id <= to_slv(control_bytes(7 to 8));
-- CONTROL Byte 9-10
send_delay <= to_unsigned(control_bytes(9 to 10)) & X"0000";
-- CONTROL Byte 11
-- control_bytes(11) used by burst_delay2

-- STATUS Byte 0
status_bytes(0)(7) <= in_dat_reg.TUSER(TUSER_CAPTURE_BIT); -- for debugging
status_bytes(0)(6) <= capture_frame; -- for debugging
status_bytes(0)(5) <= input_source;
status_bytes(0)(4) <= data_fifo_empty; -- for debugging
status_bytes(0)(3) <= data_fifo_overflow; -- for debugging
status_bytes(0)(2) <= data_fifo_overflow_sticky; -- for debugging
status_bytes(0)(1) <= '0';
status_bytes(0)(0) <= capture_mode_active;
-- STATUS Byte 1
status_bytes(1)<=std_logic_vector(trig_count);

-----------------------------------------------------------------------------------
-- Memory-Mapped interface instantiation
-----------------------------------------------------------------------------------
--! Instantiates a memory-mapped interface to the control and status bytes
CTRL_SLAVE0: entity work.CTRL_SLAVE
    GENERIC MAP (
        NUMBER_OF_CONTROL_BYTES => control_bytes'Length(1), --
        NUMBER_OF_STATUS_BYTES => status_bytes'Length(1), --
        DEFAULT_CONTROL_BYTES => (X"00_01" & DEFAULT_BURST_PERIOD & X"00_AA_0000_0000_00"), -- reset=0, burst length=1, burst period=1s @ 800 MHz/2048 samples, burst number = 0 (infinite), Probe ID=0xAA (unassigned yet)
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

------------------------------------
-- FIFO Writing process
------------------------------------
--! Captures the data and writes it to the data and header FIFO
--!
--! Writes the incoming words in the data FIFO along with the LAST_WORD bit. The FIFO will be read one byte at a time by the reading interface.
--! The header FIFO is written when the frame is complete.
write_proc: process(in_clk)
    variable frame_header: FRAME_HEADER_STRUCT;
    variable trig_var: std_logic;

    begin
        if rising_edge(in_clk) then
            -- Synchronous reset
            reset_all <= soft_reset or in_reset; -- aggregate reset lines into a single, registered lines to simplify the logic. Both resets are synchronous to in_clk.
            burst_delay <= burst_delay2;
            if fifo_reset='1' or reset_all='1' then
                data_fifo_overflow_sticky <= '0';
            else
                data_fifo_overflow_sticky <= data_fifo_overflow_sticky or data_fifo_overflow;
            end if;

            -- register the selected input bus
            if input_source='0' then
                in_dat_reg <= in_dat0;
            else
                in_dat_reg <= in_dat1;
            end if;

            -- Determine if we are using continuous transmissions (i.e unlimited number of bursts). Having this in the single bit simplifies the logic.
            if burst_number=0 then
                continuous_transmission <= '1';
            else
                continuous_transmission <= '0';
            end if;

            ------  Define a few intermediate variables to simplify the logic implementation and help meet timing
            -- Determine if we are at the last frame of the period. This is arriving one clock after the counter is set to its new value on a TLAST=1, but the value is not needed until the next TLAST so this is ok.
            burst_period_minus_1 <= burst_period - 1; -- This is a quasi-static value, so latency is not important
            if burst_frame_ctr = burst_period_minus_1 then
                is_last_frame_of_period <= '1';
            else
                is_last_frame_of_period <= '0';
            end if;

            -- Determine if we are the last frame of the burst. Same comments as above
            if burst_frame_ctr = burst_length - 1 then
                is_last_frame_of_burst <= '1';
            else
                is_last_frame_of_burst <= '0';
            end if;

            -- Determine if we are the last burst. Same comments as above
            if burst_ctr = burst_number - 1 then
                is_last_burst <= '1';
            else
                is_last_burst <= '0';
            end if;

            -- Write frame header into HEADER_FIFO until frame_header_ctr=0. The last byte of the frame has bit 8 set to '1'.
            -- This block has to be before frame_header_ctr is assigned for transmission of a new frame so it can be overriden
            header_fifo_wr_en <= '0'; -- by default do not write to the header FIFO - will be overriden below
            if write_frame_header_bytes='1' then
                frame_header_ctr <= frame_header_ctr-1; -- is overriden below is a new header is to be stored

                header_fifo_din(7 downto 0) <= frame_header_bytes(0);
                if frame_header_ctr = 1 then
                    header_fifo_din(8) <= '1'; -- set bit 8 to '1' to indicate this is the last byte of the frame.
                    write_frame_header_bytes <= '0'; -- Stop writing the bytes to the FIFO
                else
                    header_fifo_din(8) <= '0';
                end if;
                header_fifo_wr_en <= '1'; -- write byte to the FIFO
                frame_header_bytes(0 to frame_header_bytes'Length-2) <= frame_header_bytes(1 to frame_header_bytes'Length-1); -- Shift bytes by one position towards byte 0
            end if;

            -- Store the data into the FIFO, and start header storage when the end of frame is detected.

            data_fifo_wr_en <= '0'; -- by default, do not wtite to the DATA FIFOs. Will be overriden below when appropriate


            if in_dat_reg.TVALID='1' then
                -- Keep track of the serial flags
                serial_flags(2 downto 1) <= serial_flags(1 downto 0);
                serial_flags(0) <= in_dat_reg.TUSER(TUSER_SERIAL_FLAGS_BIT);
                --serial_flags(2) <= '1';

                trig_var:=in_dat_reg.TUSER(TUSER_CAPTURE_BIT); -- assign the trigger to a temporary variable for clarity
                trig_prev <= trig_var; -- store previous state of the trig signal so we can detect edges

                -- Generate the capture_frame signal, which tells whether the words of this frames are to be stored in the data FIFO
                if in_dat_reg.TLAST='1' then -- If first word of the frame
                    burst_frame_ctr <= burst_frame_ctr + 1; -- count frames in burst - may be overriden below
                    if capture_mode_active='0' then -- if the capture mode is not active. capture_mode_active defaults to '1'.
                        -- If burst_number/=0 and a rising edge is seen on the trigger signal, restart a new acquisition
                        -- Default values. Those are here to minimize the amount of logic (these are wide counters) and eliminare inverred feedback.
                        burst_frame_ctr <= (others => '0'); -- needed
                        burst_ctr <= (others => '0'); -- needed
                        trig_count <= (others => '0'); -- needed
                        capture_frame <= '0'; -- Do not send data
                        if trig_var='1' and trig_prev='0' and continuous_transmission='0' then
                            capture_mode_active <= '1'; -- needed
                            capture_frame <= '1'; -- We always start by transmitting at least one frame
                        end if;
                    else -- if the capture mode is active (TLAST=1 and capture_mode_active=1)
                        if burst_active='0' then
                            if burst_frame_ctr = burst_delay then
                                burst_active <= '1';
                                burst_frame_ctr <= (others => '0'); -- reset the frame counter
                            end if;
                        else
                            -- Stop capturing when we reach the number of frames per burst
                            if is_last_frame_of_burst='1' then -- if burst_active=1 and if we have reached the burst length (but not the burst period yet) stop transmissing frames. It will be restarted on the next period
                                capture_frame <= '0'; -- Stop capturing frames for the rest of the burst_period
                            end if; -- if last frame of burst
                            -- Restart capture if we reach the end of period and we should be capturing more bursts
                            if is_last_frame_of_period='1' then -- burst_active=1 and if we are and the end of the period
                                burst_frame_ctr <= (others => '0'); -- reset the frame counter
                                burst_ctr <= burst_ctr + 1; -- increase the number of bursts sent
                                if continuous_transmission='1' then -- if burst_number=0, tranmit bursts continuously
                                    capture_frame <= in_dat_reg.TUSER(TUSER_CAPTURE_BIT); -- transmit frames whenever the CAPTURE bit embedded in the frame is set
                                elsif is_last_burst='1' then  -- if we are the last burst then stop
                                    capture_frame <= '0'; -- stop transmitting bursts
                                    capture_mode_active<='0'; -- Stop the capture mode. Will have to reset to restart a new sequence of bursts
                                else -- if we have not tranmitted the last burst
                                    capture_frame <= '1'; -- Flag the frame to be captured
                                end if; -- if burst_ctr=N
                            end if; -- if last frame of period
                        end if; -- if burst active
                    end if; -- if capture_mode_active
                end if; -- if FIRST word of frame


                -- Counts incoming frames
                if in_dat_reg.TLAST='1' then
                    frame_ctr <= frame_ctr + 1;
                end if;

                -- Cumulate the flags for each incoming word. Clear when the last word is received.
                -- When  TLAST=1, `last_flag` contains the or'ed version of all flags EXCEPT the ones sent along the last word. We need to add them later.
                if in_dat_reg.TLAST = '1' then
                    frame_flags <= (others => '0');
                else
                    frame_flags <= frame_flags or in_dat_reg.TUSER;
                end if;

                --Assign bytes in the incoming word to the fifo word.
                -- The FIFO will be read one 9-bit byte at a time. The MSB is read first.
                --The extra bit on each byte is zero, except for the LSB , where it indicate whether this is the last byte
                if capture_frame = '1' then
                    data_fifo_wr_en <= '1';
                    data_fifo_din <=
                        (
                        '0' & in_dat_reg.TDATA(31 downto 24) &
                        '0' & in_dat_reg.TDATA(23 downto 16) &
                        '0' & in_dat_reg.TDATA(15 downto 8) &
                        in_dat_reg.TLAST & in_dat_reg.TDATA(7 downto 0)
                        );

                    if input_source='1' then
                        data_fifo_din(30 downto 27) <= in_dat_reg.TUSER;
                        data_fifo_din(21 downto 18) <= in_dat_reg.TUSER;
                        data_fifo_din(12 downto 9) <= in_dat_reg.TUSER;
                        data_fifo_din(3 downto 0) <= in_dat_reg.TUSER;
                    end if;

                    -- If this is the last word, build the frame header and set it up for injection into the header FIFO
                    if in_dat_reg.TLAST='1' then
                        -- Build the header VARIABLE
                        frame_header.PROBE_ID := probe_id;
                        frame_header.STREAM_ID(15) := input_source;
                        frame_header.STREAM_ID(14 downto 0) := stream_id(14 downto 0);
                        frame_header.SERIAL_FLAGS := serial_flags(2 downto 0) & in_dat_reg.TUSER(TUSER_SERIAL_FLAGS_BIT);
                        frame_header.FLAGS := frame_flags or in_dat_reg.TUSER;
                        frame_header.TIMESTAMP := std_logic_vector(frame_ctr);
                        -- Store the header into an adday of bytes for insertion into the FIFO
                        frame_header_bytes <= struct_to_bytes(frame_header);
                        -- Set frame_header_ctr to the number of header bytes to indicate that the header bytes are ready to be sent into the FIFO
                        frame_header_ctr <= FRAME_HEADER_BYTE_LENGTH;
                        write_frame_header_bytes <= '1'; -- Starts writing the bytes to the FIFO
                        trig_count <= trig_count + 1; -- keep track of how manny triggers we detected for debugging purposes
                    end if; -- if TLAST
                end if; -- capture_frame=1
            end if; -- TVALID='1'

            if reset_all='1' then
                in_dat_reg.TVALID <= '0';
                -- FIFO signals
                header_fifo_wr_en <= '0'; -- needed
                data_fifo_wr_en <= '0'; -- needed
                frame_ctr <= (others => '0'); -- needed

                -- Capture engine
                capture_frame <= '0'; -- needed.
                capture_mode_active <= '1'; -- needed. '1' is needed in case we set burst_number=0, in which case we transmit whenever TRIG=1
                burst_frame_ctr <= (others => '0'); -- needed
                burst_ctr <= (others => '0'); -- needed
                trig_count <= (others => '0'); -- needed
                trig_prev <= '0'; -- needed (mostly)
                burst_period_minus_1 <= (others => '0');
--              continuous_transmission <= '0'; -- not needed. This is not needed until the first TLAST, which gives time to the signal to be set before it is needed.
                write_frame_header_bytes <= '0'; -- needed
                is_last_frame_of_period <= '0';--needed
                is_last_frame_of_burst <= '0'; --needd
                is_last_burst <= '0'; --needed
                burst_active  <=  '0';
            end if; -- if reset
        end if; -- rst/clk
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

