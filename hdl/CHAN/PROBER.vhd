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

        CTRL_CMD_IN_DAT     : in  AXIS8_DAT_STRUCT;
        CTRL_CMD_IN_RDY     : out AXIS8_RDY_STRUCT;
        CTRL_RPLY_OUT_DAT   : out AXIS8_DAT_STRUCT;
        CTRL_RPLY_OUT_RDY   : in  AXIS8_RDY_STRUCT;
        CTRL_CLK            : in  std_logic;
        CTRL_RST            : in  std_logic
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

signal HEADER_FIFO_RD_EN    : STD_LOGIC:='0';
signal HEADER_FIFO_WR_EN    : STD_LOGIC:='0';
signal HEADER_FIFO_EMPTY    : STD_LOGIC;
signal HEADER_FIFO_VALID    : STD_LOGIC;
signal HEADER_FIFO_OVERFLOW : STD_LOGIC;
signal HEADER_FIFO_DIN      : STD_LOGIC_VECTOR(8 downto 0):=(others=>'0'); -- initialization for nice simulations
signal HEADER_FIFO_DOUT     : STD_LOGIC_VECTOR(8 downto 0);

-- DATA FIFO signals

signal DATA_FIFO_RD_EN      : STD_LOGIC:='0';
signal DATA_FIFO_WR_EN      : STD_LOGIC:='0';
signal DATA_FIFO_EMPTY      : STD_LOGIC;
signal DATA_FIFO_VALID      : STD_LOGIC;
signal DATA_FIFO_OVERFLOW   : STD_LOGIC;
signal data_fifo_overflow_sticky: STD_LOGIC;
signal DATA_FIFO_DIN        : STD_LOGIC_VECTOR(35 downto 0):=(others=>'0'); -- initialization for nice simulations
signal DATA_FIFO_DOUT       : STD_LOGIC_VECTOR(8 downto 0);

-- global signals
--signal FIFO_RESET_ALL: STD_LOGIC;

--signal DATA_FIFO_OUT_DAT: AXIS8_DAT_STRUCT;
--signal DATA_FIFO_OUT_RDY: AXIS8_RDY_STRUCT;

-- FIFO writing logic signals

signal CAPTURE_MODE_ACTIVE: STD_LOGIC:='1';
signal CAPTURE_FRAME: STD_LOGIC:='0';
--signal STORE_FRAME: STD_LOGIC:='0';
signal TRIG_PREV: std_logic;
signal FIRST_WORD: STD_LOGIC:='1';
signal FRAME_FLAGS: STD_LOGIC_VECTOR(3 downto 0);

signal DIN_WORD_CTR: UNSIGNED(FRAME_HEADER_STRUCT.WORD_LENGTH'Range):=(others=>'0'); -- Counts the number of words stored in a frame. We need one additional bit in case all the samples are stored.
signal FRAME_CTR: UNSIGNED(FRAME_HEADER_STRUCT.TIMESTAMP'Range):=(others=>'0');
signal FRAME_HEADER_CTR: integer range 0 to 4*FRAME_HEADER_WORD_LENGTH+1;
signal FRAME_HEADER_BYTES: ByteArray(0 to 4*FRAME_HEADER_WORD_LENGTH-1+1); -- added one to include the PROBE_ID.
constant FRAME_HEADER_BYTE_LENGTH: integer := FRAME_HEADER_WORD_LENGTH*4;
signal WRITE_FRAME_HEADER_BYTES: std_logic; --

signal TRIG_COUNT: unsigned(7 downto 0):=(others=>'0'); -- Counts the number of frames that has been captured.

-- FIFO readout logic signals

signal OUT_DAT_INT: AXIS8_DAT_STRUCT:=(DUMMY=>'0',TVALID=>'0', TDATA=>(others=>'0'), TLAST=>'0');
--signal OVERFLOW_DAT: AXIS8_DAT_STRUCT;

signal SEND_HEADER: STD_LOGIC;
signal DEST_READY: STD_LOGIC;


-- Control and status bytes
signal CONTROL_BYTES: ByteArray(0 to 6); -- default value set in the CMD_SLAVE
signal STATUS_BYTES: ByteArray(0 to 1);

signal BURST_LENGTH: unsigned(7 downto 0);
signal BURST_NUMBER: unsigned(7 downto 0);
signal BURST_PERIOD: unsigned(23 downto 0);
signal BURST_PERIOD_MINUS_1: unsigned(BURST_PERIOD'Range):=(others=>'0'); -- registered version of the BURST_PERIOD minus one used to determine the end of the loop
signal PROBE_ID: std_logic_vector(7 downto 0);
signal CONTINUOUS_TRANSMISSION: std_logic;
signal input_source: std_logic;

signal IS_LAST_FRAME_OF_PERIOD: std_logic;
signal IS_LAST_FRAME_OF_BURST: std_logic;
signal IS_LAST_BURST: std_logic;
signal BURST_ACTIVE: std_logic := '0';
signal BURST_DELAY: unsigned(23 downto 0);
signal BURST_DELAY2: unsigned(23 downto 0);

signal SOFT_RESET: STD_LOGIC;
signal FIFO_RESET: STD_LOGIC;
signal RESET_ALL: std_logic;

signal fifo_reset_reg: std_logic;

-- These signals require previous signals to be defined
signal BURST_FRAME_CTR: unsigned(BURST_PERIOD'Range):=(others=>'0'); -- Counts frames within a burst.
signal BURST_CTR: UNSIGNED(BURST_NUMBER'Range):=(others=>'0'); -- Counts SYNC psignal SYNC_SAMPLE_MISMATCH: STD_LOGIC:= '0';

constant DEFAULT_BURST_PERIOD: std_logic_vector(23 downto 0):=sel(SIM,x"000004",X"05f5e1");

signal OUT_RST: std_logic;

attribute ASYNC_REG : string;
attribute ASYNC_REG of OUT_RST : signal is "true"; -- used to resync the SOFT_RESET (in_clk domain) to the OUT_CLK domain.


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
--! | CONTROL |  0  |  7:2 | Unused                 | |
--! |         |     |   1  | FIFO_RESET           | |
--! |         |     |   0  | SOFT_RESET           | |
--! |         |  1  |  7:0 | BURST_LENGTH         | |
--! |         | 2:4 | 23:0 | BURST_PERIOD         | |
--! |         |  5  |  7:0 | BURST_NUMBER         | |
--! |         |  6  |  7:0 | PROBE_ID             | |
--! | STATUS  |  0  |   7  | TUSER_CAPTURE_BIT    | For debugging. |
--! |         |     |   6  | CAPTURE_FRAME        | For debugging. |
--! |         |     |   5  | '0' (unused)         |  |
--! |         |     |   4  | DATA_FIFO_EMPTY      | For debugging. |
--! |         |     |   3  | DATA_FIFO_OVERFLOW   | For debugging. |
--! |         |     |  2:1 | '0' (unused)         |  |
--! |         |     |   0  | CAPTURE_MODE_ACTIVE  |  |
--! |         |  1  |  7:0 | TRIG_COUNT           | |
--!  ------------------------------------------------------------------------------

-- CONTROL Byte 0
SOFT_RESET <= CONTROL_BYTES(0)(7);
FIFO_RESET <= CONTROL_BYTES(0)(6);
input_source <= CONTROL_BYTES(0)(5);
-- Burst from an iceboard of 16 channels ~250uS
-- Make roughly twice the burst time so run at half max speed.
BURST_DELAY2 <= ("000000000000" & unsigned(CONTROL_BYTES(0)(3 downto 0)) & "00000000");

-- CONTROL Byte 1
BURST_LENGTH <= unsigned(CONTROL_BYTES(1));
-- CONTROL Bytes 2-4
BURST_PERIOD <= (unsigned(CONTROL_BYTES(2)) & unsigned(CONTROL_BYTES(3)) & unsigned(CONTROL_BYTES(4))); -- 24 bit burst period. Period = 1/850e6 samples/s *2048samples/frame * 2^24 frames = 40.4 seconds max between bursts
-- CONTROL Byte 5
BURST_NUMBER <= unsigned(CONTROL_BYTES(5));
-- CONTROL Byte 6
PROBE_ID <= CONTROL_BYTES(6);

-- STATUS Byte 0
STATUS_BYTES(0)(7) <= in_dat_reg.TUSER(TUSER_CAPTURE_BIT); -- for debugging
STATUS_BYTES(0)(6) <= CAPTURE_FRAME; -- for debugging
STATUS_BYTES(0)(5) <= input_source;
STATUS_BYTES(0)(4) <= DATA_FIFO_EMPTY; -- for debugging
STATUS_BYTES(0)(3) <= DATA_FIFO_OVERFLOW; -- for debugging
STATUS_BYTES(0)(2) <= data_fifo_overflow_sticky; -- for debugging
STATUS_BYTES(0)(1) <= '0';
STATUS_BYTES(0)(0) <= CAPTURE_MODE_ACTIVE;
-- STATUS Byte 1
STATUS_BYTES(1)<=STD_LOGIC_VECTOR(TRIG_COUNT);

-----------------------------------------------------------------------------------
-- Memory-Mapped interface instantiation
-----------------------------------------------------------------------------------
--! Instantiates a memory-mapped interface to the control and status bytes
CTRL_SLAVE0: entity work.CTRL_SLAVE
    GENERIC MAP (
        NUMBER_OF_CONTROL_BYTES=>CONTROL_BYTES'Length(1), --
        NUMBER_OF_STATUS_BYTES=>STATUS_BYTES'Length(1), --
        DEFAULT_CONTROL_BYTES=> (X"00_01" & DEFAULT_BURST_PERIOD & X"00_AA"), -- reset=0, burst length=1, burst period=1s @ 800 MHz/2048 samples, burst number = 0 (infinite), Probe ID=0xAA (unassigned yet)
        USE_FIFO => FALSE
            )
    PORT MAP(
        -- Control interface (command and reply stream buses)
        CTRL_CMD_IN_DAT => CTRL_CMD_IN_DAT,
        CTRL_CMD_IN_RDY => CTRL_CMD_IN_RDY,
        CTRL_RPLY_OUT_DAT => CTRL_RPLY_OUT_DAT,
        CTRL_RPLY_OUT_RDY => CTRL_RPLY_OUT_RDY,
        CTRL_CLK=>CTRL_CLK,
        CTRL_RST => CTRL_RST,

        CONTROL_BYTES => CONTROL_BYTES,
        STATUS_BYTES => STATUS_BYTES,

        CLK => in_clk,
        RST => in_reset
    );


------------------------------------
-- Header and Data FIFO instantiation
------------------------------------

-- Data FIFO: 36 bit input, 9 bits output.
-- FIFO is First Word Fall Through
--FIFO_RESET_ALL<=RST or SOFT_RESET or FIFO_RESET;

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
    din      => DATA_FIFO_DIN,
    wr_en    => DATA_FIFO_WR_EN,
    rd_en    => DATA_FIFO_RD_EN,
    dout     => DATA_FIFO_DOUT,
    full     => open,
    overflow => DATA_FIFO_OVERFLOW,
    valid    => DATA_FIFO_VALID,
    empty    => DATA_FIFO_EMPTY
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
    din      => HEADER_FIFO_DIN,
    wr_en    => HEADER_FIFO_WR_EN,
    rd_en    => HEADER_FIFO_RD_EN,
    dout     => HEADER_FIFO_DOUT,
    full     => open,
    overflow => HEADER_FIFO_OVERFLOW,
    valid    => HEADER_FIFO_VALID,
    empty    => HEADER_FIFO_EMPTY
  );

------------------------------------
-- FIFO Writing process
------------------------------------
--! Captures the data and writes it to the data and header FIFO
--!
--! Writes the incoming words in the data FIFO along with the LAST_WORD bit. The FIFO will be read one byte at a time by the reading interface.
--! The header FIFO is written when the frame is complete.
write_proc: process(in_clk)
    variable FRAME_HEADER: FRAME_HEADER_STRUCT;
    variable FRAME_HEADER_WORDS: Word32Array(0 to FRAME_HEADER_WORD_LENGTH-1);
    variable TRIG_VAR: std_logic;

    begin

        if rising_edge(in_clk) then
            -- Synchronous reset
            RESET_ALL<= SOFT_RESET or in_reset; -- aggregate reset lines into a single, registered lines to simplify the logic. Both resets are synchronous to in_clk.
            BURST_DELAY <= BURST_DELAY2;
            if FIFO_RESET='1' or RESET_ALL='1' then
                data_fifo_overflow_sticky <= '0';
            else
                data_fifo_overflow_sticky <= data_fifo_overflow_sticky or DATA_FIFO_OVERFLOW;
            end if;
            if RESET_ALL='1' then
                in_dat_reg.TVALID<='0';
                -- FIFO signals
                HEADER_FIFO_WR_EN<='0'; -- needed
                DATA_FIFO_WR_EN<='0'; -- needed
--              DATA_FIFO_DIN<=(others=>'0'); -- for nice simulation
                DIN_WORD_CTR<=to_unsigned(1,DIN_WORD_CTR'Length); -- store 1
--              STORE_FRAME<='0';
                FRAME_CTR<=(others=>'0'); -- needed

                -- Capture engine
                CAPTURE_FRAME<='0'; -- needed.
                CAPTURE_MODE_ACTIVE<='1'; -- needed. '1' is needed in case we set BURST_NUMBER=0, in which case we transmit whenever TRIG=1
                BURST_FRAME_CTR<=(others=>'0'); -- needed
                BURST_CTR<=(others=>'0'); -- needed
                TRIG_COUNT<=(others=>'0'); -- needed
                TRIG_PREV<='0'; -- needed (mostly)
                FIRST_WORD<='1'; -- needed
                BURST_PERIOD_MINUS_1<=(others=>'0');
--              CONTINUOUS_TRANSMISSION<='0'; -- not needed. This is not needed until the first TLAST, which gives time to the signal to be set before it is needed.
                WRITE_FRAME_HEADER_BYTES<='0'; -- needed
                IS_LAST_FRAME_OF_PERIOD<='0';--needed
                IS_LAST_FRAME_OF_BURST<='0'; --needd
                IS_LAST_BURST<='0'; --needed
                BURST_ACTIVE <= '0';
            else -- if not reset
                -- register the selected input bus
                if input_source='0' then
                    in_dat_reg <= in_dat0;
                else
                    in_dat_reg <= in_dat1;
                end if;

                -- Determine if we are using continuous transmissions (i.e unlimited number of bursts). Having this in the single bit simplifies the logic.
                if BURST_NUMBER=0 then
                    CONTINUOUS_TRANSMISSION<='1';
                else
                    CONTINUOUS_TRANSMISSION<='0';
                end if;

                ------  Define a few intermediate variables to simplify the logic implementation and help meet timing
                -- Determine if we are at the last frame of the period. This is arriving one clock after the counter is set to its new value on a TLAST=1, but the value is not needed until the next TLAST so this is ok.
                BURST_PERIOD_MINUS_1 <= BURST_PERIOD-1; -- This is a quasi-static value, so latency is not important
                if BURST_FRAME_CTR=BURST_PERIOD_MINUS_1 then
                    IS_LAST_FRAME_OF_PERIOD<='1';
                else
                    IS_LAST_FRAME_OF_PERIOD<='0';
                end if;

                -- Determine if we are the last frame of the burst. Same comments as above
                if BURST_FRAME_CTR=BURST_LENGTH-1 then
                    IS_LAST_FRAME_OF_BURST<='1';
                else
                    IS_LAST_FRAME_OF_BURST<='0';
                end if;

                -- Determine if we are the last burst. Same comments as above
                if BURST_CTR=BURST_NUMBER-1 then
                    IS_LAST_BURST<='1';
                else
                    IS_LAST_BURST<='0';
                end if;

                -- Write frame header into HEADER_FIFO until FRAME_HEADER_CTR=0. The last byte of the frame has bit 8 set to '1'.
                -- This block has to be before FRAME_HEADER_CTR is assigned for transmission of a new frame so it can be overriden
                HEADER_FIFO_WR_EN <= '0'; -- by default do not write to the header FIFO - will be overriden below
                if WRITE_FRAME_HEADER_BYTES='1' then
                    FRAME_HEADER_CTR <= FRAME_HEADER_CTR-1; -- is overriden below is a new header is to be stored

                    HEADER_FIFO_DIN(7 downto 0) <= FRAME_HEADER_BYTES(0);
                    if FRAME_HEADER_CTR = 1 then
                        HEADER_FIFO_DIN(8) <= '1'; -- set bit 8 to '1' to indicate this is the last byte of the frame.
                        WRITE_FRAME_HEADER_BYTES <= '0'; -- Stop writing the bytes to the FIFO
                    else
                        HEADER_FIFO_DIN(8)<='0';
                    end if;
                    HEADER_FIFO_WR_EN<='1'; -- write byte to the FIFO
                    FRAME_HEADER_BYTES(0 to FRAME_HEADER_BYTES'Length-2) <= FRAME_HEADER_BYTES(1 to FRAME_HEADER_BYTES'Length-1); -- Shift bytes by one position towards byte 0
                end if;

                -- Store the data into the FIFO, and start header storage when the end of frame is detected.

                DATA_FIFO_WR_EN<='0'; -- by default, do not wtite to the DATA FIFOs. Will be overriden below when appropriate


                if in_dat_reg.TVALID='1' then
                    TRIG_VAR:=in_dat_reg.TUSER(TUSER_CAPTURE_BIT); -- assign the trigger to a temporary variable for clarity
                    TRIG_PREV<=TRIG_VAR; -- store previous state of the trig signal so we can detect edges

                    -- Generate the CAPTURE_FRAME signal, which tells whether the words of this frames are to be stored in the data FIFO
                    if in_dat_reg.TLAST='1' then -- If first word of the frame
                        if CAPTURE_MODE_ACTIVE='0' then -- if the capture mode is not active
                            -- If BURST_NUMBER/=0 and a rising edge is seen on the trigger signal, restart a new acquisition
                            -- Default values. Those are here to minimize the amount of logic (these are wide counters) and eliminare inverred feedback.
                            BURST_FRAME_CTR<=(others=>'0'); -- needed
                            BURST_CTR<=(others=>'0'); -- needed
                            TRIG_COUNT<=(others=>'0'); -- needed
                            CAPTURE_FRAME<='0'; -- Do not send data
                            if TRIG_VAR='1' and TRIG_PREV='0' and CONTINUOUS_TRANSMISSION='0' then
                                CAPTURE_MODE_ACTIVE<='1'; -- needed
                                CAPTURE_FRAME<='1'; -- We always start by transmitting at least one frame
                            end if;
                        else -- if the capture mode is active (TLAST=1 and CAPTURE_MODE_ACTIVE=1)
                            if BURST_ACTIVE='0' then
                                BURST_FRAME_CTR<=BURST_FRAME_CTR+1; -- count frames in burst - may be overriden below
                                if BURST_FRAME_CTR = BURST_DELAY then
                                    BURST_ACTIVE <= '1';
                                    BURST_FRAME_CTR <= (others=>'0'); -- reset the frame counter
                                    -- Might need to zero/reset other things here
                                    -- And if get to end of period before this, just won't do anything
                                    -- Timing problems?
                                end if;
                            else
                                BURST_FRAME_CTR<=BURST_FRAME_CTR+1; -- count frames in burst - may be overriden below
                            end if;
                            if IS_LAST_FRAME_OF_PERIOD='1' then -- if we are and the end of the period
                                BURST_FRAME_CTR<=(others=>'0'); -- reset the frame counter
                                if CONTINUOUS_TRANSMISSION='1' then -- if BURST_NUMBER=0, tranmit bursts continuously
                                    CAPTURE_FRAME<=in_dat_reg.TUSER(TUSER_CAPTURE_BIT); -- transmit frames whenever the CAPTURE bit embedeed in the frame is set
                                elsif IS_LAST_BURST='1' then  -- if we are the last burst then stop
                                    CAPTURE_FRAME<='0'; -- stop transmitting bursts
                                    CAPTURE_MODE_ACTIVE<='0'; -- Stop the capture mode. Will have to reset to restart a new sequence of bursts
                                else -- if we have not tranmitted the last burst
                                    CAPTURE_FRAME<='1'; -- Flag the frame to be captured
                                    BURST_CTR <= BURST_CTR+1; -- increase the number of bursts sent
                                end if; -- if BURST_CTR=N
                            elsif IS_LAST_FRAME_OF_BURST='1' then -- if we have reached the burst length (but not the burst period yet) stop transmissing frames. It will be restarted on the next period
                                CAPTURE_FRAME <= '0'; -- Stop capturing frames for the rest of the BURST_PERIOD
                            end if; -- if BURST_FRAME_CTR=N
                        end if; -- if CAPTURE_MODE_ACTIVE
                    end if; -- if FIRST word of frame


                    -- Counts incoming frames
                    if in_dat_reg.TLAST='1' then
                        FRAME_CTR<=FRAME_CTR+1;
                    end if;

                    -- Sets a flag indicating when is the first word
                    FIRST_WORD<=in_dat_reg.TLAST;
                    -- Cumulate the flags for each incoming word. Start over when the first work is received.
                    if FIRST_WORD='1' then
                        FRAME_FLAGS<=in_dat_reg.TUSER;
                    else
                        FRAME_FLAGS<=FRAME_FLAGS or in_dat_reg.TUSER;
                    end if;

                    --Assign bytes in the incoming word to the fifo word.
                    -- The FIFO will be read one 9-bit byte at a time. The MSB is read first.
                    --The extra bit on each byte is zero, except for the LSB , where it indicate whether this is the last byte
                    if CAPTURE_FRAME='1' then
                        DATA_FIFO_WR_EN<='1';
                        DATA_FIFO_DIN<=
                            (
                            '0' & in_dat_reg.TDATA(31 downto 24) &
                            '0' & in_dat_reg.TDATA(23 downto 16) &
                            '0' & in_dat_reg.TDATA(15 downto 8) &
                            in_dat_reg.TLAST & in_dat_reg.TDATA(7 downto 0)
                            );
                        DIN_WORD_CTR<=DIN_WORD_CTR+1;

                        -- If this is the last word, build the frame header and set it up for injection into the header FIFO
                        if in_dat_reg.TLAST='1' then
                            DIN_WORD_CTR <= to_unsigned(1,DIN_WORD_CTR'Length); -- store 1
                            -- Build the header VARIABLE
                            FRAME_HEADER.ID := (others=>'0');
                            FRAME_HEADER.FLAGS := FRAME_FLAGS;
                            FRAME_HEADER.TIMESTAMP := std_logic_vector(FRAME_CTR);
                            FRAME_HEADER.WORD_LENGTH := std_logic_vector(DIN_WORD_CTR);
                            -- Store the header into an adday of bytes for insertion into the FIFO
                            FRAME_HEADER_WORDS := struct_to_word(FRAME_HEADER);
                            FRAME_HEADER_BYTES(0) <= PROBE_ID;
                            for i in 0 to FRAME_HEADER_WORD_LENGTH-1 loop
                                FRAME_HEADER_BYTES(4*i+1 to 4*i+3+1) <= (FRAME_HEADER_WORDS(i)(31 downto 24), FRAME_HEADER_WORDS(i)(23 downto 16), FRAME_HEADER_WORDS(i)(15 downto 8), FRAME_HEADER_WORDS(i)(7 downto 0));
                            end loop;
                            -- Set FRAME_HEADER_CTR to the number of header bytes to indicate that the header bytes are ready to be sent into the FIFO
                            FRAME_HEADER_CTR <= 4*FRAME_HEADER_WORD_LENGTH+1;
                            WRITE_FRAME_HEADER_BYTES <= '1'; -- Starts writing the bytes to the FIFO
                            TRIG_COUNT <= TRIG_COUNT+1; -- keep track of how manny triggers we detected for debugging purposes
                        end if; -- if TLAST
                    end if; -- CAPTURE_FRAME=1
                end if; -- TVALID='1'
            end if; -- if reset
        end if; -- RST/CLK
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

OUT_DAT <= OUT_DAT_INT;

-- Determines when the source and destination are ready
DEST_READY<='1' when OUT_RDY.TREADY='1' or OUT_DAT_INT.TVALID='0' else '0'; -- the output is ready for a new byte if there is currently no valid byte or if the destination is accepting current one.

-- Determine when to read the data and header FIFOs
DATA_FIFO_RD_EN<= DEST_READY and (not SEND_HEADER); -- Read data FIFO on the TREADY singal and only if there is a valid frame and we are not sending the header byte
HEADER_FIFO_RD_EN<=DEST_READY and SEND_HEADER; -- read the new frame status when we read the last byte of a frame


read_proc: process(OUT_CLK)
    begin
        if rising_edge(OUT_CLK) then
            OUT_RST <= CTRL_RST or SOFT_RESET; -- Retime the reset to OUT_CLK (which is normally CTRL_CLK). We use an ASYNC_REG attribute because SOFT_RESET is in the in_clk domain.
            fifo_reset_reg <= FIFO_RESET;
            -- synchronous reset
            if OUT_RST='1' then
                OUT_DAT_INT.TVALID<='0'; -- needed
                --OUT_DAT_INT.TLAST<='0'; -- optional
                --OUT_DAT_INT.TDATA<=(others=>'0'); -- optional
                SEND_HEADER<='1'; -- needed to make sure we start with header transmission
            else
                -- Clear the TREADY if the data is read by the destination. This will be overriden below if a new byte is sent at the same time
                if OUT_RDY.TREADY='1' then
                    OUT_DAT_INT.TVALID<='0';
                end if;

                -- Output the data to the destination
                if DEST_READY='1'  then -- if the bus is ready to receive a new byte and we have
                    if SEND_HEADER='1' and  HEADER_FIFO_VALID='1' then
                        OUT_DAT_INT.TDATA<=lsb(HEADER_FIFO_DOUT);
                        OUT_DAT_INT.TVALID<='1';
                        OUT_DAT_INT.TLAST<='0';
                        if HEADER_FIFO_DOUT(8)='1' then -- if this is the last header byte
                            SEND_HEADER<='0'; -- start sending the data
                        end if;
                    elsif SEND_HEADER='0' and  DATA_FIFO_VALID='1' then
                        OUT_DAT_INT.TDATA<=lsb(DATA_FIFO_DOUT);
                        OUT_DAT_INT.TVALID<='1';
                        OUT_DAT_INT.TLAST<=DATA_FIFO_DOUT(8);
                        if DATA_FIFO_DOUT(8)='1' then -- if this is the last data byte
                            SEND_HEADER<='1'; -- start sending the next header
                        end if;
                    else -- if we have nothing to send
                        OUT_DAT_INT.TVALID<='0';
                    end if; -- HEADER or DATA ready to be sent
                end if; -- if destination ready
            end if; -- reset
        end if; -- CLK
    end process;


end Behavioral;

