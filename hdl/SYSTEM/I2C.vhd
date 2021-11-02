----------------------------------------------------------------------------------
--! @file
--! @brief IIC interface
-- Company: Mc Gill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    2012-03-28
-- Design Name:
-- Module Name:    I2C - Behavioral
-- Project Name: CHIME
-- Target Devices:
-- Tool versions: ISE 13.4
-- Description: Implements a I2C interface
--
-- Dependencies:
--
-- Revision:
--   2012-03-28 JFC: Created
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chFPGA_Package.all; -- Get all component definitions

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

------------ ENTITY DECLAREATION ------------------
--! @brief
--! This module implements I^2C interface that is compliant with the I2C and PMBUs standard.
--! The interface operate at a fixed speed of about 100 KHz.
--! The I2C transaction can be performed in 1 or 2 phases:
--!  Phase 1: The I2C address is sent, and BYTES1 bytes are read or written depending on the R/W bit of the command
--!  Phase 2: if
entity I2C is
	generic (
		NUMBER_OF_PORTS: integer;
		T_HIGH: real :=4.0e-6; -- clock minimum high time tHIGH, assumed to be equal to tHD,STA  , tSU,STO
		T_LOW: real :=4.7e-6; -- clock minimum high time tLOW, assumed to be equal tSU,STA, tBUF
		CLK_FREQ: real:= 200.0e6 -- input clock frequency
			);
    port (
		-- Control interface
		CTRL_CMD_IN_DAT: in AXIS8_DAT_STRUCT; -- Command stream input, signals from master (Data, Valid, Last)
		CTRL_CMD_IN_RDY: out AXIS8_RDY_STRUCT; -- Command stream input, signals to master (Ready)
		CTRL_RPLY_OUT_DAT: out AXIS8_DAT_STRUCT; -- Reply stream output, signals to slave (Data, Valid, Last)
		CTRL_RPLY_OUT_RDY: in AXIS8_RDY_STRUCT; -- Reply stream output,  signals from slave (Ready)
		CTRL_CLK: in  STD_LOGIC;
		CTRL_RST: in std_logic;


		--I2C signals
		I2C_SCK: inout std_logic_vector(NUMBER_OF_PORTS-1 downto 0);
		I2C_SDA: inout std_logic_vector(NUMBER_OF_PORTS-1 downto 0);


		-- System-level signals
		CLK200: in STD_LOGIC;
		RST: in STD_LOGIC -- synchronous to CLK200
	);
end I2C;

architecture Behavioral of I2C is

-- I2C Time constants in clock cycles
constant tHIGH: integer := integer(CLK_FREQ*T_HIGH);
constant tHIGH_MAX: integer := integer(CLK_FREQ*50.0e-6);
constant tLOW: integer := integer(CLK_FREQ*T_LOW);
constant tBUF: integer := tLOW;
constant tHD_STA: integer := tHIGH;
constant tSU_STA: integer := tLOW;
constant tSU_STO: integer := tHIGH;
constant tSP: integer := integer(CLK_FREQ*50.0e-9);  -- 10 clocks at 200 MHz
constant tTIMEOUT_MIN: integer := integer(CLK_FREQ*35.0e-3);

constant CLK_CTR_MAX: integer:=tTIMEOUT_MIN+1; -- use the largest possible count +1 to account that we clear on the following clock
constant IDLE_CTR_MAX: integer:=tHIGH_MAX; -- use the largest possible count

signal CLK_AT_tHIGH: std_logic;
signal CLK_AT_tLOW: std_logic;
signal CLK_AT_tHD_STA: std_logic;
signal CLK_AT_HALF_tLOW: std_logic;
signal CLK_AT_tTIMEOUT_MIN: std_logic;
signal CLK_AT_tSU_STA: std_logic;
signal CLK_AT_tSU_STA_PLUS_tHD_STA: std_logic;
signal CLK_AT_tSU_STO: std_logic;
signal CLK_AT_tSU_STO_PLUS_tBUF: std_logic;

signal IDLE_CLK_AT_tBUF: std_logic;
signal IDLE_CLK_AT_tHIGH: std_logic;

--- Define Control word and its signals
--signal CONTROL_WORD: STD_LOGIC_VECTOR(47 downto 0); -- default value set in the CMD_SLAVE
signal control_bytes: slv8_array(0 to 5); -- default value set in the CMD_SLAVE
signal status_bytes: slv8_array(0 to 8); -- default value set in the CMD_SLAVE

signal CTRL_DATA: slv8_array(0 to 3);

constant CTRL_DIR_READ: std_logic:='1';
constant CTRL_DIR_WRITE: std_logic:='0';

signal CTRL_START,CTRL_START_PREVIOUS,CTRL_START_PREVIOUS2: STD_LOGIC;
signal CTRL_BYTES1: unsigned(1 downto 0);
signal CTRL_BYTES2: unsigned(2 downto 0);
signal CTRL_FORCE_SCK: STD_LOGIC;
signal CTRL_FORCE_SDA: STD_LOGIC;
signal CTRL_FORCE_SCK_STATE: STD_LOGIC;
signal CTRL_FORCE_SDA_STATE: STD_LOGIC;
signal ctrl_always_clk: STD_LOGIC;

-- I2C State machine signals
type MASTER_STATE_TYPE is (
	MASTER_STATE_IDLE,
	MASTER_STATE_IDLE_LOW,
	MASTER_STATE_START,
	MASTER_STATE_DATA_LOW,
	MASTER_STATE_DATA_WAIT_HIGH,
	MASTER_STATE_DATA_HIGH,
	MASTER_STATE_ACK_LOW,
	MASTER_STATE_ACK_WAIT_HIGH,
	MASTER_STATE_ACK_HIGH,
	MASTER_STATE_STOP_LOW,
	MASTER_STATE_STOP_WAIT_HIGH,
	MASTER_STATE_STOP_HIGH,
	MASTER_STATE_RESTART_LOW,
	MASTER_STATE_RESTART_WAIT_HIGH,
	MASTER_STATE_RESTART_HIGH
	);

signal master_state: MASTER_STATE_TYPE:=MASTER_STATE_IDLE;


--signal CLK: STD_LOGIC;
signal sda_in_vect, sda_in_weak_vect: std_logic_vector(NUMBER_OF_PORTS-1 downto 0);
signal sck_in_vect, sck_in_weak_vect: std_logic_vector(NUMBER_OF_PORTS-1 downto 0);

signal sda_tristate_vect, sda_out_vect: std_logic_vector(NUMBER_OF_PORTS-1 downto 0):=(others => '1');
signal sck_tristate_vect, sck_out_vect: std_logic_vector(NUMBER_OF_PORTS-1 downto 0):=(others => '1');

signal sda_in,sda_in_raw, sda_in_prev: std_logic;
signal sck_in,sck_in_raw: std_logic;

signal sda_out: std_logic:='1';
signal sck_out: std_logic:='1';

signal start_prev: STD_LOGIC:='0';
signal start: STD_LOGIC:='0';

signal done: STD_LOGIC:='0';
signal bus_idle: STD_LOGIC:='0';
signal stop_detected: STD_LOGIC:='0';
signal clk_ctr: integer range 0 to CLK_CTR_MAX; -- use the largest possible count
signal idle_ctr: integer range 0 to IDLE_CTR_MAX; -- use the largest possible count
signal sck_debounce_ctr,sda_debounce_ctr: integer range 0 to tSP; --
signal clk_ctr_clear: std_logic;
signal bit_ctr: unsigned(2 downto 0); -- Counts the bits to transmit/receive
signal byte_ctr: unsigned(2 downto 0); -- Counts the bytes to transmit/receive
signal master_ack_status: unsigned(7 downto 0);
signal write_word: unsigned(31 downto 0);
signal read_word: unsigned(31 downto 0);
signal ctrl_port: integer range 0 to NUMBER_OF_PORTS-1;
signal ctrl_reset: std_logic;
signal dir: STD_LOGIC;
signal next_dir: STD_LOGIC;
signal read_phase: STD_LOGIC;
signal collision: STD_LOGIC;
signal timeout: STD_LOGIC;
--signal STATE_MON: std_logic_vector(3 downto 0);
signal all_reset: STD_LOGIC;
--signal FLAG: std_logic_vector(7 downto 0);
signal start_ctr: unsigned(3 downto 0); --
signal done_ctr: unsigned(3 downto 0); --



begin


-----------------------------------------------------------------------------------
-- CONTROL and STATUS Bytes
-----------------------------------------------------------------------------------
--! @addtogroup memory_map
--! REFCLK Module
--! =============
--! ----------------------------------------------------------------------------------------
--! | Page | Addr | Bit(s)|     Name                | Description                           |
--! |---------|-----|-----|-------------------------|---------------------------------------|
--! | CONTROL | 0-3 | 31:0| TX_DATA                 | Data to be sent. MSB is in byte 0 and is sent first. Byte 0 is the address/RW bit. |
--! |         |  4  |  7  | start                   | A 0-to-1 transition starts the I2C transaction|
--! |         |     | 6:4 | BYTES2                  | Number of bytes to read after sending BYTES1 bytes|
--! |         |     | 3:2 | (unused)                | |
--! |         |     | 1:0 | BYTES1                  | Number of bytes to send |
--! |         |  5  |  7  | RESET                   | Resets the I2C logic |
--! |         |     |  6  | ALWAYS_CLK              | When High, the I2C clock always toggle even when there are no transactions on the bus. |
--! |         |     | 5:4 | PORT                    | Indicates which I2C port to use |
--! |         |     |  3  | FORCE_SCK               | When High, Force SCK line to the value set by SCK_STATE |
--! |         |     |  2  | FORCE_SDA               | When High, Force SDA line to the value set by SDA_STATE |
--! |         |     |  1  | SCK_STATE               | Value forced on the SCK line when FORCE_SCK='1'|
--! |         |     |  0  | SDA_STATE               | Value forced on the SDA line when FORCE_SDA='1'|
--! |         |     |  1  | (reserved)              | Might be used to expand the number of SPI ports.|
--! |         |     |  0  | PORT                    | Indicates to which port the transation will be made. |
--! | STATUS  | 0-3 | 31:0| RX_DATA                 | Data received during the transation. |
--! |         |  4  |  7  | bus_idle                | High when the bus is IDLE|
--! |         |     | 6:5 | (unused)                | |
--! |         |     |  4  | timeout                 | High when a timeout has been detected in the previous transaction attempt|
--! |         |     |  3  | collision               | High when a collision has been detected in the previous transaction attempt|
--! |         |     |  2  | sck_in                  | Current state of the SCK line.|
--! |         |     |  1  | sda_in                  | Current state of the SDA line.|
--! |         |     |  0  | done                    | High when the transation is complete|
--! |         |  5  | 7:0 | ACK_STATUS              | Indicates the value of the ACK bits for each bytes transferred|
--! |         |  6  |  7  | (unused)                | |
--! |         |     | 6:4 | byte_ctr                | For debugging |
--! |         |     |  3  | dir                     | For debugging |
--! |         |     | 2:0 | bit_ctr                 | For debugging |
--! |         |     | 2:0 | bit_ctr                 | For debugging |
--! |         |  7  | 7:4 | start_ctr               | For debugging |
--! |         |     | 3:0 | done_ctr                | For debugging |
--! |         |  8  | 7:0 | (unused)                | |
--! ------------------------------------------------------------------------------

CTRL_DATA            <=		control_bytes(0 to 3);
--CTRL_DIR           <=		control_bytes(0)(0);


CTRL_START           <=	control_bytes(4)(7);
CTRL_BYTES2          <=	unsigned(control_bytes(4)(6 downto 4));
CTRL_BYTES1          <=	unsigned(control_bytes(4)(1 downto 0));
ctrl_reset           <=	control_bytes(5)(7);
ctrl_always_clk      <= control_bytes(5)(6);
ctrl_port            <= to_integer(unsigned(control_bytes(5)(5 downto 4)));
CTRL_FORCE_SCK       <= control_bytes(5)(3);
CTRL_FORCE_SDA       <= control_bytes(5)(2);
CTRL_FORCE_SCK_STATE <= control_bytes(5)(1);
CTRL_FORCE_SDA_STATE <= control_bytes(5)(0);

status_bytes(0) <= Byte(read_word(31 downto 24));
status_bytes(1) <= Byte(read_word(23 downto 16));
status_bytes(2) <= Byte(read_word(15 downto 8));
status_bytes(3) <= Byte(read_word(7 downto 0));

status_bytes(4)(7)          <= bus_idle;
status_bytes(4)(6 downto 5) <= (others => '0');
status_bytes(4)(4)          <= timeout;
status_bytes(4)(3)          <= collision;
status_bytes(4)(2)          <= sck_in;
status_bytes(4)(1)          <= sda_in;
status_bytes(4)(0)          <= done;

status_bytes(5)             <= std_logic_vector(master_ack_status);

status_bytes(6)(7)          <= '0';
status_bytes(6)(6 downto 4) <= std_logic_vector(byte_ctr);
status_bytes(6)(3)          <= dir;
status_bytes(6)(2 downto 0) <= std_logic_vector(bit_ctr);

status_bytes(7)             <= std_logic_vector(unsigned'(start_ctr & done_ctr));

--status_bytes(8)           <= FLAG;
status_bytes(8)             <= (others => '0');


--CLK <= CLK200; -- select clock

CTRL_SLAVE0: entity work.CTRL_SLAVE
	GENERIC MAP (
		NUMBER_OF_CONTROL_BYTES => control_bytes'Length(1), -- Length of array in the first dimension: number of bytes
		NUMBER_OF_STATUS_BYTES => status_bytes'Length(1),
		DEFAULT_CONTROL_BYTES => X"A000000D_03_00"
		)
	PORT MAP(
		-- Control interface (command and reply stream buses)
		CTRL_CMD_IN_DAT   => CTRL_CMD_IN_DAT,
		CTRL_CMD_IN_RDY   => CTRL_CMD_IN_RDY,
		CTRL_RPLY_OUT_DAT => CTRL_RPLY_OUT_DAT,
		CTRL_RPLY_OUT_RDY => CTRL_RPLY_OUT_RDY,
		CTRL_CLK => CTRL_CLK,
		CTRL_RST => CTRL_RST,
		control_bytes => control_bytes,
		status_bytes => status_bytes
		);

-- Output buffers


-------------------------------------------------
-- Instantiate the bidirectional IO buffers for the I2C clock and data lines
gen_io: for i in 0 to NUMBER_OF_PORTS-1 generate
	-- Instantiate SDA tristate buffer
	IOBUF_SDA : IOBUF
		generic map (
			DRIVE => 2,
			IOSTANDARD => "DEFAULT",
			SLEW => "SLOW"
			)
		port map (
			O => sda_in_weak_vect(i), -- Buffer output. Conversion needed for simulation (converts weak H into '1')
			IO => I2C_SDA(i), -- Buffer inout port (connect directly to top-level port)
			I => sda_out_vect(i), -- Buffer input
			T => sda_tristate_vect(i) -- 3-state enable input, high=input, low=output
		);

	-- Instantiate SCK tristate buffer
	IOBUF_SCK : IOBUF
		generic map (
			DRIVE => 2,
			IOSTANDARD => "DEFAULT",
			SLEW => "SLOW"
			)
		port map (
			O => sck_in_weak_vect(i), -- Buffer output. Conversion needed for simulation (converts weak H into '1')
			IO => I2C_SCK(i), -- Buffer inout port (connect directly to top-level port)
			I => sck_out_vect(i), -- Buffer input
			T => sck_tristate_vect(i) -- 3-state enable input, high=input, low=output
		);
end generate;


all_reset <= RST or ctrl_reset;

-- Implement I2C process
i2c: process(CLK200,all_reset)
	begin
		if all_reset='1' then

			-- Reset I2C lines to idle (Hi-z)
			sda_out <= '1';
			sck_out <= '1';
			sda_out_vect <= (others => '1');
			sck_out_vect <= (others => '1');
			sda_tristate_vect <= (others => '1'); -- Hi-Z by default
			sck_tristate_vect <= (others => '1');

			-- Reset state machine variables
			master_state <= MASTER_STATE_IDLE;
			clk_ctr <= 0;
			clk_ctr_clear <= '1';
			bit_ctr <= (others => '0');
			byte_ctr <= (others => '0');
			master_ack_status <= (others => '0');
			start <= '0';
			done <= '0';
			CTRL_START_PREVIOUS <= '0';
			write_word <= (others => '0');
			read_word <= X"AABBCCDD";
			read_phase <= '0';
			dir <= '0';
			next_dir <= '0';
			collision <= '0';

			bus_idle <= '0';
			idle_ctr <= 0;
			stop_detected <= '0';

			--SCK_OUT_VECT_PREV <= (others => '0');
			--SDA_OUT_VECT_PREV <= (others => '0');
			--FLAG <= (others => '0');
			sck_debounce_ctr <= 0;
			sda_debounce_ctr <= 0;

			CLK_AT_tHIGH <= '0';
			CLK_AT_tLOW <= '0';
			CLK_AT_tHD_STA <= '0';
			CLK_AT_HALF_tLOW <= '0';
			CLK_AT_tTIMEOUT_MIN <= '0';
			CLK_AT_tSU_STO <= '0';
			CLK_AT_tSU_STO_PLUS_tBUF <= '0';
			CLK_AT_tSU_STA_PLUS_tHD_STA <= '0';

			IDLE_CLK_AT_tBUF <= '0';
			IDLE_CLK_AT_tHIGH <= '0';

		elsif rising_edge(CLK200) then


			for i in 0 to NUMBER_OF_PORTS-1 loop

				-- We register the data here because we don't want to feed untimed data to combinatorial logic that drives multiple LUT/registers inputs.
				-- This can cause some of the registers to get a different value than others, even if the HDL says they will all get the same value...
				sda_in_vect(i) <= TO_UX01(sda_in_weak_vect(i)); -- for sims
				sck_in_vect(i) <= TO_UX01(sck_in_weak_vect(i));
				-- Keep track of a delayed version of the output buts to implement transient 0-1 drive to accelerate bus response
				--SCK_OUT_VECT_PREV(i) <= sck_out_vect(i);
				--SDA_OUT_VECT_PREV(i) <= sda_out_vect(i);

				-- Select output sources. Make sure they are Hi-Z ('1') when not selected.
				-- we make this synchronous to avoid glitches. The one clock delay is not a problem.
				sck_out_vect(i) <= '1'; -- default value, overriden below
				sda_out_vect(i) <= '1'; -- default value, overriden below
				if (CTRL_FORCE_SDA = '0' and CTRL_FORCE_SDA_STATE='1') then
					sda_tristate_vect(i) <= '0';
				else
					sda_tristate_vect(i) <= '1';
				end if;
				if (CTRL_FORCE_SCK = '0' and CTRL_FORCE_SCK_STATE = '1') then
					sck_tristate_vect(i) <= '0';
				else
					sck_tristate_vect(i) <= '1';
				end if;

				if i=ctrl_port then
					if sck_out = '0' or (CTRL_FORCE_SCK = '1' and CTRL_FORCE_SCK_STATE = '0') then
						sck_out_vect(i) <= '0';
						sck_tristate_vect(i) <= '0';
					end if;

					if sda_out='0' or (CTRL_FORCE_SDA = '1' and CTRL_FORCE_SDA_STATE = '0') then
						sda_out_vect(i) <= '0';
						sda_tristate_vect(i) <= '0';
					end if;
				end if;
			end loop;

			-- select the SCK and SDA input source
			sck_in_raw <= sck_in_vect(ctrl_port);
			sda_in_raw <= sda_in_vect(ctrl_port);

			-- Debounce SCK input
			-- SCK_IN won't change to a sck_in_raw unless sck_in_raw was consistently in the opposite state for tSP clocks
			if sck_in = sck_in_raw then
				sck_debounce_ctr <= 0;
			elsif sck_debounce_ctr = tSP then
				sck_in <= sck_in_raw;
				sck_debounce_ctr <= 0;
			else
				sck_debounce_ctr <= sck_debounce_ctr + 1;
			end if;

			-- Debounce SDA input
			if sda_in = sda_in_raw then
				sda_debounce_ctr <= 0;
			elsif sda_debounce_ctr=tSP then
				sda_in <= sda_in_raw;
				sda_debounce_ctr <= 0;
			else
				sda_debounce_ctr <= sda_debounce_ctr + 1;
			end if;

			-- Store previous version of SCK and SDA to detect transitions
			sda_in_prev <= sda_in;
			--SCK_OUT_PREV <= sck_out;
			--SDA_OUT_PREV <= sda_out;



			-- Bus IDLE detection
			-- Detect when bus is ready to receive a new command.
			-- According to the PMBus spec, the bus is idle when either
			--   a) SCK and SDA high for tBUF after a STOP condtion, or
			---  b) SCK and SDA high for tHIGH_MAX

			if idle_ctr /= IDLE_CTR_MAX then
				idle_ctr <= idle_ctr+1;
			end if;
			if idle_ctr = tBUF-1 then IDLE_CLK_AT_tBUF <= '1'; else IDLE_CLK_AT_tBUF <= '0'; end if;
			if idle_ctr = tHIGH_MAX-1 then IDLE_CLK_AT_tHIGH <= '1'; else IDLE_CLK_AT_tHIGH <= '0'; end if;

			if (sck_in='0' or sda_in='0') then -- if SDK or SDA are low, reset IDLE detection
				idle_ctr <= 0;
				bus_idle <= '0';
				stop_detected <= '0';
			elsif (sda_in_prev='0' and sda_in='1' and sck_in='1') then -- if STOP condition (low-to-high SDA transition while CLK=High)
				stop_detected <= '1';
				idle_ctr <= 0;
				bus_idle <= '0';
			elsif (stop_detected='1' and IDLE_CLK_AT_tBUF='1') or (stop_detected='0' and IDLE_CLK_AT_tHIGH='1') then
				bus_idle <= '1';
			end if;



			-- Set the start bit if a 0-to-1 transition is detected on the CTRL_FLAG_START bit.
			CTRL_START_PREVIOUS <= CTRL_START;
			CTRL_START_PREVIOUS2 <= CTRL_START_PREVIOUS;

			if CTRL_START_PREVIOUS='1' and CTRL_START_PREVIOUS2='0' then
						start <= '1'; --. This will start the state machine. Will be cleared when transmission actually starts
						done <= '0'; -- will be set when transmission is done
						master_ack_status <= (others => '0'); -- clear ack status - will be overriden below
						collision <= '0'; -- will be overriden below
						timeout <= '0';
			end if;

			-- Timing counter. Counts up by default, unless resetted by the code below
			if clk_ctr_clear = '1' then
				clk_ctr <= 0;
			elsif clk_ctr /= CLK_CTR_MAX then -- don't roll over
				clk_ctr <= clk_ctr+1; -- invrement unless overriden below
			end if;
			clk_ctr_clear <= '0'; -- this is a single pulse signal. Always return to zero unless overriden below.

			-- Check time limits. Make sure that the value is zero on the next clock if clk_ctr_clear is active (even if the counter is not yet cleared).
			-- if clk_ctr = tHIGH-1 then CLK_AT_tHIGH <= not clk_ctr_clear; else CLK_AT_tHIGH <= '0'; end if;
			-- if clk_ctr = tLOW-1 then CLK_AT_tLOW <= not clk_ctr_clear; else CLK_AT_tLOW <= '0'; end if;
			-- if clk_ctr = tHD_STA-1 then CLK_AT_tHD_STA <= not clk_ctr_clear; else CLK_AT_tHD_STA <= '0'; end if;
			-- if clk_ctr = tLOW/2-1 then CLK_AT_HALF_tLOW <= not clk_ctr_clear; else CLK_AT_HALF_tLOW <= '0'; end if;
			-- if clk_ctr = tTIMEOUT_MIN-1 then CLK_AT_tTIMEOUT_MIN <= not clk_ctr_clear; else CLK_AT_tTIMEOUT_MIN <= '0'; end if;
			-- if clk_ctr = tSU_STO-1 then CLK_AT_tSU_STO <= not clk_ctr_clear; else CLK_AT_tSU_STO <= '0'; end if;
			-- if clk_ctr = tSU_STA-1 then CLK_AT_tSU_STA <= not clk_ctr_clear; else CLK_AT_tSU_STA <= '0'; end if;
			-- if clk_ctr = tSU_STO+tBUF-1 then CLK_AT_tSU_STO_PLUS_tBUF <= not clk_ctr_clear; else CLK_AT_tSU_STO_PLUS_tBUF <= '0'; end if;
			-- if clk_ctr = tSU_STA+tHD_STA-1 then CLK_AT_tSU_STA_PLUS_tHD_STA <= not clk_ctr_clear; else CLK_AT_tSU_STA_PLUS_tHD_STA <= '0'; end if;

			-- Check time limits. Make sure that the value is zero on the next clock if clk_ctr_clear is active (even if the counter is not yet cleared).
			CLK_AT_tHIGH                <= to_std_logic(clk_ctr = tHIGH-1           and clk_ctr_clear = '0');
			CLK_AT_tLOW                 <= to_std_logic(clk_ctr = tLOW-1            and clk_ctr_clear = '0');
			CLK_AT_tHD_STA              <= to_std_logic(clk_ctr = tHD_STA-1         and clk_ctr_clear = '0');
			CLK_AT_HALF_tLOW            <= to_std_logic(clk_ctr = tLOW/2-1          and clk_ctr_clear = '0');
			CLK_AT_tTIMEOUT_MIN         <= to_std_logic(clk_ctr = tTIMEOUT_MIN-1    and clk_ctr_clear = '0');
			CLK_AT_tSU_STO              <= to_std_logic(clk_ctr = tSU_STO-1         and clk_ctr_clear = '0');
			CLK_AT_tSU_STA              <= to_std_logic(clk_ctr = tSU_STA-1         and clk_ctr_clear = '0');
			CLK_AT_tSU_STO_PLUS_tBUF    <= to_std_logic(clk_ctr = tSU_STO+tBUF-1    and clk_ctr_clear = '0');
			CLK_AT_tSU_STA_PLUS_tHD_STA <= to_std_logic(clk_ctr = tSU_STA+tHD_STA-1 and clk_ctr_clear = '0');



			-- Main state machine
			case master_state is
				when MASTER_STATE_IDLE => -- do nothing. Do not drive SCK and SDA. When start=1, generate a I2C Start signal
					--STATE_MON <= X"F";
					sck_out <= '1';
					sda_out <= '1';

					--	BUS_READY <= '1';

					-- If start was detected and the bus is ready, generate the start condition on the bus
					if start='1' and bus_idle='1' then
							start <= '0'; -- clear the start flag so we don't start a new transaction when we return here
							sda_out <= '0'; -- create a 1-to-0 transition while SCK=1 to signal a start condition
							clk_ctr_clear <= '1';
							master_state <= MASTER_STATE_START;
							start_ctr <= start_ctr + 1; -- keep track of how many transactions we started for checking and debugging
					elsif CLK_AT_tHIGH='1' then
						if ctrl_always_clk='1' then
							sck_out <= '0';
						end if;
						clk_ctr_clear <= '1';
						master_state <= MASTER_STATE_IDLE_LOW;
					end if;


				when MASTER_STATE_IDLE_LOW => -- release SDK when tLOW has passed
--					STATE_MON <= X"E";
					if CLK_AT_tLOW='1' and clk_ctr_clear='0' then
						sck_out <= '1';
						clk_ctr_clear <= '1';
						master_state <= MASTER_STATE_IDLE;
					end if;

				when MASTER_STATE_START => -- wait for the required set-up time after the start condition before brining SCK to 0
--					STATE_MON <= X"1";
					if CLK_AT_tHD_STA='1' and clk_ctr_clear='0' then -- or sck_in='0' go to address transmission when hold time is elapsed or if we are forced down by another master
						sck_out <= '0';
						read_phase <= '0';
						byte_ctr <= ('0'& CTRL_BYTES1);
						write_word <= unsigned(CTRL_DATA(0)) & unsigned(CTRL_DATA(1)) & unsigned(CTRL_DATA(2)) & unsigned(CTRL_DATA(3));
						read_word <= (others => '0');
						bit_ctr <= (others => '0');
						dir <= CTRL_DIR_WRITE; -- first byte is the address, use write mode
						next_dir <= CTRL_DATA(0)(0); -- following bytes are read or write depending on the direction set in the address byte
						clk_ctr_clear <= '1';
						master_state <= MASTER_STATE_DATA_LOW;
					end if;

				when MASTER_STATE_DATA_LOW => -- SCK is low. If we are writing, set SDA to the data to be written at tLow/2. Release SCK at tLow.
--					STATE_MON <= X"2";
					if CLK_AT_HALF_tLOW='1' and clk_ctr_clear='0' then		-- wait half of the LOW time to elapse before setting the data
						-- set data bit
						if dir=CTRL_DIR_WRITE then -- if we write
							sda_out <= write_word(write_word'LEFT);
							write_word <= write_word sll 1; -- shift word left one bit
						else -- if we read
							sda_out <= '1'; -- hi-z to let the slave drive the data bus
						end if;
					elsif CLK_AT_tLOW='1' and clk_ctr_clear='0' then	-- end of low time. Clock goes high.
						sck_out <= '1';
						clk_ctr_clear <= '1';
						master_state <= MASTER_STATE_DATA_WAIT_HIGH;
					end if;

				when MASTER_STATE_DATA_WAIT_HIGH => -- SCK was released. Wait for the clock line to go high (in case another device is holding it down) then sample the data line
--					STATE_MON <= X"A";

					if sck_in='1' then -- wait until all devices have released the clock before counting the high time
						-- sample data bit
--						if dir=CTRL_DIR_WRITE then -- if we are writing
--							if sda_in/=sda_out then -- if there is a collision we lose the arbitration war - release the bus and go to IDLE
--								-- Release the bus
--								sda_out <= '1'; -- go Hi-Z
--								sck_out <= '1'; -- go Hi-Z
--								-- set the flags
--								collision <= '1';
--								done <= '1'; -- Indicate we have finished the transfer
--								clk_ctr <= 0;
--								BUS_READY <= '0'; -- Make sure we wait for tBUF before starting a new transaction
--								master_state <= MASTER_STATE_IDLE;
--							end if;
						--Capture the bit on the bus and shift it in
						read_word <= read_word SLL 1;
						read_word(0) <= sda_in;
						--read_word(0) <= '1';
						clk_ctr_clear <= '1';
						master_state <= MASTER_STATE_DATA_HIGH;
					elsif CLK_AT_tTIMEOUT_MIN='1' and clk_ctr_clear='0' then
						sck_out <= '1';
						clk_ctr_clear <= '1';
						timeout <= '1';
						master_state <= MASTER_STATE_STOP_HIGH;
					end if;

				when MASTER_STATE_DATA_HIGH => -- We just released SCK. Wait for the HIGH time before setting SCK to LOW
--					STATE_MON <= X"3";
					if CLK_AT_tHIGH='1' and clk_ctr_clear='0'  then	-- or sck_in='0' go to next state when high time is elapsed or if we are forced by another master
						sck_out <= '0';
						--FLAG(0) <= '1';
						-- if this is the last bit, go back to ACK phase, otherwise proceed with next bit
						if bit_ctr = 7 then -- if we just finished tranmitting the last bit
							bit_ctr <= (others => '0');
							clk_ctr_clear <= '1';
							master_state <= MASTER_STATE_ACK_LOW;
						else
							bit_ctr <= bit_ctr + 1;
							clk_ctr_clear <= '1';
							master_state <= MASTER_STATE_DATA_LOW;
						end if;
					end if;


				when MASTER_STATE_ACK_LOW => -- SCK is being forced low prior to ACK sampling. Release SDA at tLow/2 to let the slave put its ACK. Release SCK at tLow.
--					STATE_MON <= X"4";
					if CLK_AT_HALF_tLOW = '1' and clk_ctr_clear = '0' then	-- wait for half of the LOW time before setting SDA to send/receive the acknowledge
						if dir = CTRL_DIR_WRITE then -- if we are writing
							sda_out <= '1'; -- Hi-Z to let the slave respond
						else -- if we are reading
							if byte_ctr = 0 then -- if last byte
								sda_out <= '1'; -- Last byte, Send a NACK
							else -- not last byte
								sda_out <= '0'; -- Send an ACK
							end if;
						end if;
					elsif CLK_AT_tLOW='1' and clk_ctr_clear='0' then
						sck_out <= '1';
						clk_ctr_clear <= '1';
						master_state <= MASTER_STATE_ACK_WAIT_HIGH;
					end if;

				when MASTER_STATE_ACK_WAIT_HIGH => -- We stopped pulling SCK low, we wait for it to come up so we can sample the ACK state.
--					STATE_MON <= X"5";
					if sck_in='1' then -- wait until all devices have released the clock before sampling the bit

						-- sample ACK bit
						master_ack_status <= master_ack_status SLL 1; -- shift left, we'll fill in bit 0 below
						if dir = CTRL_DIR_WRITE then -- if we write
							master_ack_status(0) <= not sda_in; -- get the ACK/NACK status from the bus
						else -- if we read
							master_ack_status(0) <= '1'; -- assume a ACK
						end if;

						clk_ctr_clear <= '1';
						master_state <= MASTER_STATE_ACK_HIGH;
					elsif CLK_AT_tTIMEOUT_MIN='1' and clk_ctr_clear='0' then
						sck_out <= '1';
						clk_ctr_clear <= '1';
						timeout <= '1';
						master_state <= MASTER_STATE_STOP_HIGH;
					end if;

				when MASTER_STATE_ACK_HIGH => -- SCK has come up and we have sampled out ACK. Now we wait tHigh before forcing SCK low.
--					STATE_MON <= X"B";
					if CLK_AT_tHIGH='1' and clk_ctr_clear='0'  then -- or sck_in='0' if the end o gthe High clock perod, or if forced low by another master
						sck_out <= '0';

						-- if we didn't get an ACK or if this is not the last byte, go to send the next byte, otherwise send the STOP condition
						if master_ack_status(0) = '0' then -- if NACK
							clk_ctr_clear <= '1';
							master_state <= MASTER_STATE_STOP_LOW; -- go to STOP condition
						else -- if ACK.
							if byte_ctr/=0 then -- if not last byte.
								byte_ctr <= byte_ctr-1;
								dir <= next_dir;
								clk_ctr_clear <= '1';
								master_state <= MASTER_STATE_DATA_LOW;
							else -- this is the last byte, restart if there is a following read phase, otherwise stop
								--FLAG(1) <= '1';
								if read_phase='0' and CTRL_BYTES2/=0 then -- if we have a following read phase, proceed with a restart
									--FLAG(2) <= '1';
									clk_ctr_clear <= '1';
									master_state <= MASTER_STATE_RESTART_LOW;
								else -- otherwise proceed with a STOP
									clk_ctr_clear <= '1';
									master_state <= MASTER_STATE_STOP_LOW;
								end if; -- if following phase
							end if; -- if last byte
						end if; -- if ACK/NACK
					end if; -- if end of HIGH time

				when MASTER_STATE_STOP_LOW =>
--					STATE_MON <= X"6";
					if CLK_AT_HALF_tLOW='1' and clk_ctr_clear='0' then		-- wait for half of the LOW time
						sda_out <= '0'; -- prepare for the 0-to-1 transition
					elsif CLK_AT_tLOW='1' and clk_ctr_clear='0' then
						--FLAG(3) <= '1';
						sck_out <= '1';
						clk_ctr_clear <= '1';
						master_state <= MASTER_STATE_STOP_WAIT_HIGH;
					end if;

				when MASTER_STATE_STOP_WAIT_HIGH => -- wait for the clock line to go high (in case another device is holding it down) then sample the data line

					if sck_in='1' then -- wait until all devices have released the clock before counting the high time
						clk_ctr_clear <= '1';
						master_state <= MASTER_STATE_STOP_HIGH;
					elsif CLK_AT_tTIMEOUT_MIN='1' and clk_ctr_clear='0' then
						sck_out <= '1';
						timeout <= '1';
						clk_ctr_clear <= '1';
						master_state <= MASTER_STATE_STOP_HIGH;
					end if;

				when MASTER_STATE_STOP_HIGH => -- wait for half of the LOW time
--					STATE_MON <= X"7";
					if CLK_AT_tSU_STO='1' and clk_ctr_clear='0' then
						--FLAG(4) <= '1';
						sda_out <= '1'; -- create 0 to 1 transition that signify the STOP codition
					elsif CLK_AT_tSU_STO_PLUS_tBUF='1' and clk_ctr_clear='0' then	-- wait for additional bus free time before proceeding to next bit.
						--BUS_READY <= '0'; -- idem
						done <= '1'; -- finished the transactions
						done_ctr <= done_ctr+1;
						clk_ctr_clear <= '1'; -- clear counter to tell the IDLE state to wait at least tBUF before sending the next command
						master_state <= MASTER_STATE_IDLE;
					end if;

				when MASTER_STATE_RESTART_LOW =>
--					STATE_MON <= X"8";
					if CLK_AT_HALF_tLOW='1' and clk_ctr_clear='0' then		-- wait for half of the LOW time
						sda_out <= '1'; -- prepare for the 1-to-0 transition
					elsif CLK_AT_tLOW='1' and clk_ctr_clear='0' then
						--FLAG(5) <= '1';
						sck_out <= '1';
						clk_ctr_clear <= '1';
						master_state <= MASTER_STATE_RESTART_WAIT_HIGH;
					end if;

				when MASTER_STATE_RESTART_WAIT_HIGH => -- wait for the clock line to go high (in case another device is holding it down) then sample the data line

					if sck_in='1' then -- wait until all devices have released the clock before counting the high time
						clk_ctr_clear <= '1';
						master_state <= MASTER_STATE_RESTART_HIGH;
					elsif CLK_AT_tTIMEOUT_MIN='1' and clk_ctr_clear='0' then
						sck_out <= '1';
						timeout <= '1';
						clk_ctr_clear <= '1';
						master_state <= MASTER_STATE_RESTART_HIGH;
					end if;

				when MASTER_STATE_RESTART_HIGH => -- wait for half of the LOW time
--					STATE_MON <= X"9";
					if CLK_AT_tSU_STA='1' and clk_ctr_clear='0' then
						sda_out <= '0'; -- create 0 to 1 transition that signify the STOP codition
					elsif CLK_AT_tSU_STA_PLUS_tHD_STA='1' and clk_ctr_clear='0' then
						--FLAG(6) <= '1';
						sck_out <= '0';
						read_phase <= '1';
						bit_ctr <= (others => '0');
						clk_ctr_clear <= '1';
						write_word(31 downto 24) <= unsigned(CTRL_DATA(0));
						write_word(24) <= CTRL_DIR_READ; -- force READ mode
						dir <= CTRL_DIR_WRITE; -- first byte is address, write
						next_dir <= CTRL_DIR_READ;
						byte_ctr <= CTRL_BYTES2; -- number of bytes to read
						master_state <= MASTER_STATE_DATA_LOW;
					end if;

			end case;
		end if; -- CLK

	end process;


end Behavioral;

