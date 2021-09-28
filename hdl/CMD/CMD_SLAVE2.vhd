----------------------------------------------------------------------------------
--! @file
-- Company: McGill University
-- Engineer: J.F. Cliche
--
-- Create Date:    14:41:37 04/26/2011
-- Design Name:
-- Module Name:    CMD_SLAVE - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:

-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:

-- 110518 JFC: Major modifications
-- 			- The number of internal STATUS and CONTROl byte register now scales with the CONTROL and STATUS Word width
--				- The CONTROL and STATUS Words are now clocked using the  external clock to keep the clock domain crossing within this module so we can better handle the timing exceptions that are required.
--				- The address space allocated for the CONTROL and STATUS words is now 8 bytes. All system address should be changed.
-- 110725 JFC: Implemented 16-bit RAM mode based on the code in SYSMON. Now this module can talk to SYSMON and MGT directly without glue logic.
-- 110806 JFC: Corrected bug: added CTRL_RD_EN =1 condition in the 16-bit odd address read, otherwise the RDY line was enable even if the read was not for this module.
-- 110808 JFC: Modified address to 10 bits
-- 111008 JFC: Removed STICKY bits register since it is not used and causes lots of warnings
-- 111009 JFC: CTRL_DOUT and CTRL_DOUT_READY are now registered, which adds one clock latency but will cut the combinatorial path to the MASTER. Was a problem with some DRP
-- 111017 JFC: Updated header comments block to reflect the current functionnalities
-- 120212 JFC: Major revision. Modified control bus to use AXI4 STREAM buses for command input and reply output. The command interpretation is now done here instead of the MASTER. Reads can now have multiple bytes.
-- 120331 JFC: Modified address management to support arbitrart RAM_ADDR width (although the value loaded in the counter is still 9 bits, but higher addreses can be read by incrementing)
--					The address space is determined when address is loaded. Overflows can no longer change address space.
--					The length field is now exponential (0=1 byte, 1=2 bytes, 2=4 bytes etc. up to 15=32768 bytes)
--	121019 JFC: Added AXI4S FIFO at the input to help timing
-- 121020 JFC: Added ASYNC FIFO capability
-- 131108 JFC: Added separate CTRL_RST. Switched to synchronous resets. Added ASYNC_REG attributes to clock-domain crossing registers.
-- 140909 JFC: Rewrite of the whole module to simplify the code
-- Notes:

-- 120212 JFC: The code assumes that the address is in the LSB of the command word.
-- The command receives properly sets its TREADY line to indicate when it can receive commands. The only time it cannot receive commands is when it is reading internal data and sending it on the reply stream.
-- The reply bus will wait for the destination TREADY before sending next data byte. The system will hang up is TREADY is never asserted.

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chFPGA_Package.all; -- Get all component definitions
--use work.ip_package.all; -- Import definition of components used in this module

library UNISIM;
use UNISIM.VComponents.all;

--! @brief Processes commands received on the  AXI4 command stream, and sends any replies on the AIX4 reply stream.
--! Commands include read/write of internal control bytes, read of status bytes, and read/write to an external RAM/FIFO or 16-bit wide DRP port (used by Xilinx blocks such as MMCM, MGTs, SYSTEM_MONITOR etc).
--! The module does NOT decode the destination address. It accepts and executes any command coming in.  It is assumed that only the relevant commands are routed here.
--!
--!		  Byte 0 | Byte 1 | Byte 2
--!    [pppNNAAA AAAAAAAA AAAAAAAA]
--!
--!
--!  Byte 0 - 2: (Byte 0 is received first and is MSB)
--!    Bit 23-21 (ppp) Operation opcode
--!    Bit 20-19 (NN): Log2 of number of bytes to read (Read command only). 0: 1 byte, 1: 2 bytes, 2: 4 bytes, 3: 8 bytes
--!    Bit 18-0: 19-bit address
--!
--! | 000 | Read 2^NN control bytes | [000NNxxx] [xxxxxxxx] [aaaaaaaa]
--! | 001 | No operation (reserved for future operations)|
--! | 010 | Read 2^^NN status byte |
--! | 011 | Read 2^NN RAM bytes or 2^NN DRP words (LSB fist)|
--! | 100 | Write control bytes |
--! | 101 | Write control bytes with mask |
--! | 110 | No operation (reserved for future operations)|
--! | 111 | Write RAM bytes or DRP words (LSB first) |
--!
--!
--!  In 16-bit mode, The LSB is stored at even addresses and the MSB is at odd addresses (little endian). This is the opposite to the general big endian convention used for the control registers.
--!   e.g.
--!      Addr 2*N = bits 7-0 = LSB
--!      Addr 2*N+1 = bits 15-8 = MSB
--!   where N is the DRP register word address
--!
--!   NOTE: The even address must be read/write before the odd for the 16-bit (such as DRP) operation to succeed
--!
--! If USE_ASYNC_FIFO is True, the CONTROL, STATUS and RAM/DRP interface operate on the CLK clock and RST reset.
--! Otherwiser  CLRT_CLK/CTRL_RST are used.
--!
--!
--! Possible architectures for a command system
--! 1) basic bus: 8-bit data in, 8-bit data out, N-bit addr, wen, ren, rack: Assumes the module is alwats ready to accept a word. Does not work with slow write devices (DRP).
--! 2) serialized bus

entity CTRL_SLAVE is
	GENERIC (
		DEFAULT_CONTROL_BYTES: std_logic_vector := X"00000000"; --! Vector of bits to initialize the control register to a known value
		NUMBER_OF_CONTROL_BYTES: integer        := 1; --! Number of bytes in the control word
		NUMBER_OF_STATUS_BYTES: integer         := 1; --! Number of bytes in the status word.
		ADDR_WIDTH: integer                     := 19; --! Number of command address bits available to this module (all other bits are zeroed, useful to have large RAM address buses)
		RAM_DATA_WIDTH: integer                 := 8; --! Either 8 or 16 bits
		RAM_ADDR_WIDTH: integer                 := 0; --! Number of bits in the RAB/DRP adress bus. A velue of 0 removes most of the RAM/DRP access logic.
		USE_PIPELINED_RAM_WRITE: boolean        := TRUE;
		USE_RAM_DOUT_RDY: boolean               := FALSE; --! Indicates is the RAM interface provides a DOUT_RDY signal. If FALSE, it is assumed that the data is available the clock after RD_EN.
		RAM_LATENCY: integer                    := 1; --! Number of cycles if takes for the RAM data to be ready after a read. Can be 1 or 2. Not used if USE_RAM_DOUT_RDY=TRUE.
		USE_FIFO: boolean                       := FALSE; --! Indicates if a FIFO is to be used.
		USE_ASYNC_FIFO: boolean                 := FALSE --! Indicates if an asynchronous FIFO is to be used. In this case the external size of the FIFO is clocked by CTRL_CLK, and the internal side is clocked by CLK.
		);
    PORT (

		-- Control interface

		-- Command stream bus (slave)
		CTRL_CMD_IN_DAT: in AXIS8_DAT_STRUCT; -- Command stream input, signals from master (Data, Valid, Last)
		CTRL_CMD_IN_RDY: out AXIS8_RDY_STRUCT; -- Command stream input, signals to master (Ready)
		CTRL_RPLY_OUT_DAT: out AXIS8_DAT_STRUCT; -- Reply stream output, signals to slave (Data, Valid, Last)
		CTRL_RPLY_OUT_RDY: in AXIS8_RDY_STRUCT; -- Reply stream output,  signals from slave (Ready)
		CTRL_CLK: in STD_LOGIC;
		CTRL_RST: in std_logic; --! Reset, synchronous to CTRL_CLK

		-- Control/status words
		CONTROL_BYTES: out slv8_array(0 to NUMBER_OF_CONTROL_BYTES-1); --
		STATUS_BYTES: in slv8_array(0 to NUMBER_OF_STATUS_BYTES-1):=(others=> (others=>'0')); --
		CLK: in STD_LOGIC; -- Clock used to sample the status bits and output the control bits
		RST : in  STD_LOGIC:='0'; --! *NOT USED * reset, synchronous to CLK

		-- FIFO/RAM interface
		RAM_DIN : OUT  STD_LOGIC_VECTOR (RAM_DATA_WIDTH-1 downto 0);
		RAM_DOUT : IN  STD_LOGIC_VECTOR (RAM_DATA_WIDTH-1 downto 0):=(others=>'0');
		RAM_DOUT_RDY : IN  STD_LOGIC :='0'; -- To interface devices that have a ready pin. Set GLOBAL variable USE_RAM_DOUT_RDY to determine whether this pin is used or not
		RAM_ADDR : OUT  STD_LOGIC_VECTOR (RAM_ADDR_WIDTH-1 downto 0);
		RAM_WR_EN : OUT  STD_LOGIC;
		RAM_RD_EN : OUT  STD_LOGIC;
		RAM_EN : OUT  STD_LOGIC

		-- System interface
		);
end CTRL_SLAVE;

architecture Behavioral of CTRL_SLAVE is


	attribute ASYNC_REG : string;
	attribute TO_TIG : string;
	attribute FROM_TIG : string;

	signal CLK_SEL: std_logic; --! Clock to be used on the internal side of the FIFO
	signal RST_SEL: std_logic; --! Reset to be used on the internal side of the FIFO
	signal RAM_RD_EN_INT: STD_LOGIC;
	signal RAM_WR_EN_INT: std_logic := '0'; -- init for sim only to prevent contamination of RAM first byte
	signal RAM_DIN_INT: std_logic_vector(15 downto 0);

	constant CONTROL_STATUS_ADDR_WIDTH: integer := width(max(NUMBER_OF_CONTROL_BYTES, NUMBER_OF_STATUS_BYTES));
	constant INT_ADDR_WIDTH: integer :=19;

	subtype OPCODE_TYPE is std_logic_vector(2 downto 0);
	constant OPCODE_WRITE_CONTROL: OPCODE_TYPE        := "100";
	constant OPCODE_WRITE_CONTROL_MASK: OPCODE_TYPE   := "101";
	constant OPCODE_NOP: OPCODE_TYPE                  := "110";
	constant OPCODE_WRITE_RAM: OPCODE_TYPE            := "111";
	constant OPCODE_READ_CONTROL: OPCODE_TYPE         := "000";
	constant OPCODE_READ_STATUS: OPCODE_TYPE          := "010";
	constant OPCODE_READ_RAM: OPCODE_TYPE             := "011";

--	signal is_write: std_logic;
	signal incr: std_logic;
	-- signal is_ram: std_logic;
	signal addr: unsigned(INT_ADDR_WIDTH-1 downto 0); --
	signal count: unsigned(2**CTRL_CMD_COUNT_WIDTH-1 downto 0);
	signal opcode: OPCODE_TYPE;
	signal previous_byte: std_logic_vector(7 downto 0);

	signal CONTROL_BYTES_INT: slv8_array(0 to NUMBER_OF_CONTROL_BYTES-1):= (others=>(others=>'0')); -- Will be initialized with the default values at reset
	signal STATUS_BYTES_INT: slv8_array(0 to NUMBER_OF_STATUS_BYTES-1);

	attribute FROM_TIG of CONTROL_BYTES_INT: signal is "true"; --!
	attribute TO_TIG of STATUS_BYTES_INT : signal is "true"; --

	signal ram_rdy_dly1: STD_LOGIC := '0';
	signal ram_rdy_dly2: STD_LOGIC := '0';
	signal RAM_RDY: STD_LOGIC := '0';
	signal ram_en_int: std_logic;

	signal ram_dout_msb: STD_LOGIC_VECTOR(7 downto 0);

	TYPE RX_STATE_TYPE IS (COMMAND_BYTE1, COMMAND_BYTE2, COMMAND_BYTE3, EXECUTE_COMMAND); -- States of the RX state machine
	signal RX_STATE: RX_STATE_TYPE := COMMAND_BYTE1; -- Init for sim


	signal first: std_logic;
	signal is_msb: std_logic;
	signal send_msb: std_logic;
	signal was_last: std_logic;
	signal wait_state: std_logic;


	signal CMD_IN_DAT_FIFO:  AXIS8_DAT_STRUCT;
	signal CMD_IN_RDY_FIFO:  AXIS8_RDY_STRUCT;
	signal RPLY_OUT_DAT_FIFO:  AXIS8_DAT_STRUCT;
	signal RPLY_OUT_RDY_FIFO: AXIS8_RDY_STRUCT;

	signal timeout: std_logic;
	signal timeout_int: std_logic;
	signal timeout_reset: std_logic;
	signal timeout_ctr: unsigned(7 downto 0);
	constant dly: time := 10 ps;
begin

--! Selects which clock is used for the logic connected to the SLAVE.
clk_sel_gen: if USE_FIFO=TRUE and USE_ASYNC_FIFO=TRUE generate
	CLK_SEL <= CLK; -- watch out, might mess up simulations.
end generate;

clk_sel_not_gen: if not(USE_FIFO=TRUE and USE_ASYNC_FIFO=TRUE) generate
	CLK_SEL <= CTRL_CLK after 1 ps; -- watch out, might mess up simulations. Shoud this be here? Is it for the outputs?
end generate;

RST_SEL <= CTRL_RST;

--fifo_gen: if USE_FIFO generate

--	--! Implement a FIFO to improve timing
--	FIFO0 : entity work.CTRL_FIFO
--	  GENERIC MAP (
--			USE_ASYNC_FIFO=> USE_ASYNC_FIFO
--			)
--	  PORT MAP (
--			CMD_A_DAT  => CTRL_CMD_IN_DAT,
--			CMD_A_RDY  => CTRL_CMD_IN_RDY,
--			RPLY_A_DAT => CTRL_RPLY_OUT_DAT,
--			RPLY_A_RDY => CTRL_RPLY_OUT_RDY,
--			A_CLK      => CTRL_CLK,

--			CMD_B_DAT  => CMD_IN_DAT_FIFO,
--			CMD_B_RDY  => CMD_IN_RDY_FIFO,
--			-- RPLY_B_DAT => (TVALID=>RPLY_OUT_DAT_FIFO.TVALID, TDATA=>RPLY_OUT_DAT_FIFO.TDATA, TLAST=>RPLY_OUT_DAT_FIFO.TLAST, DUMMY => '0'),
--			RPLY_B_DAT => RPLY_OUT_DAT_FIFO,
--			RPLY_B_RDY => RPLY_OUT_RDY_FIFO,
--			B_CLK      => CLK_SEL,

--			-- System interface
--			RST => CTRL_RST
--			);
--end generate;

nofifo_gen: if not USE_FIFO generate
	CMD_IN_DAT_FIFO <= CTRL_CMD_IN_DAT after dly;  -- make simulations work by ensuring that the command data changes after the clock.
	CTRL_CMD_IN_RDY <= CMD_IN_RDY_FIFO; -- does not work if sim with direct structure assignment of ports
	-- CTRL_CMD_IN_RDY.TREADY <= CMD_IN_RDY_FIFO.TREADY; -- Does not help either
	-- CTRL_RPLY_OUT_DAT <= RPLY_OUT_DAT_FIFO;
	CTRL_RPLY_OUT_DAT.TDATA <= RPLY_OUT_DAT_FIFO.TDATA after dly;
	CTRL_RPLY_OUT_DAT.TVALID <= RPLY_OUT_DAT_FIFO.TVALID after dly;
	CTRL_RPLY_OUT_DAT.TLAST <= RPLY_OUT_DAT_FIFO.TLAST after dly;
	RPLY_OUT_RDY_FIFO <= CTRL_RPLY_OUT_RDY after dly;  -- needd for sims. Otherwise  the ready flag from the sink changes before our re-assigned CLK_SEL...
end generate;

-- COMMAND_WORD  <= command_data(2) & command_data(1) & command_data(0);
-- COMMAND_DIR   <= COMMAND_WORD(CTRL_CMD_DIR_BIT);
-- COMMAND_INCR  <= COMMAND_WORD(CTRL_CMD_INCR_BIT);
-- COMMAND_COUNT <= UNSIGNED(COMMAND_WORD((CTRL_CMD_COUNT_LSB+CTRL_CMD_COUNT_WIDTH-1) downto CTRL_CMD_COUNT_LSB));
-- COMMAND_ADDR  <= COMMAND_WORD(CTRL_ADDR_WIDTH-1 downto 0);

-- RPLY_OUT_DAT_FIFO<=RPLY_OUT_DAT_FIFO;
RAM_RDY <=
	RAM_DOUT_RDY when USE_RAM_DOUT_RDY=TRUE else
	ram_rdy_dly1 when RAM_LATENCY=1 else -- USE RDY signal from RAM if available, otherwise use delayed version of RAM_EN Pulse
	ram_rdy_dly2;


CONTROL_BYTES <= CONTROL_BYTES_INT;
STATUS_BYTES_INT <= STATUS_BYTES;

RAM_ADDR  <= std_logic_vector(addr(RAM_ADDR_WIDTH downto 1)) when RAM_DATA_WIDTH=16 else std_logic_vector(addr(RAM_ADDR_WIDTH-1 downto 0));
ram_en_int <= RAM_RD_EN_INT or RAM_WR_EN_INT; -- Added for tdevices with EN and WR control signals instead of RD and WR signals
RAM_WR_EN <= RAM_WR_EN_INT;
RAM_RD_EN <= RAM_RD_EN_INT;
RAM_EN    <= ram_en_int;
RAM_DIN <= RAM_DIN_INT(RAM_DATA_WIDTH-1 downto 0);

timeout <= '1' when timeout_int='1' and timeout_reset = '0' else '0';

-- Command processor process
cmd_proc: process(CLK_SEL)
	variable byte_index_var: integer range 0 to max(NUMBER_OF_STATUS_BYTES, NUMBER_OF_CONTROL_BYTES)-1;
	-- variable opcode_var: OPCODE_TYPE;

	begin
		if rising_edge(CLK_SEL) then

			-- if the byte at the reply is read, clear the valid flag. This is overriden below when we send a new byte.
			if (RPLY_OUT_RDY_FIFO.TREADY='1') then
				RPLY_OUT_DAT_FIFO.TVALID<='0';
			end if;


			if CMD_IN_DAT_FIFO.TVALID='1' and CMD_IN_RDY_FIFO.TREADY ='1'then
				first <= CMD_IN_DAT_FIFO.TLAST;
				is_msb <= not is_msb; -- toggles for each incoming byte. If overriden below to align msb/lsb.
				previous_byte <= CMD_IN_DAT_FIFO.TDATA;
			end if;

			ram_rdy_dly1 <= ram_en_int; -- delayed version of RAM_RD_EN used to generate the RAM_DOUT_RDY if the RAM does not provide one
			ram_rdy_dly2 <= ram_rdy_dly1; -- delayed version of RAM_RD_EN used to generate the RAM_DOUT_RDY if the RAM does not provide one

			byte_index_var := to_integer(unsigned(addr(CONTROL_STATUS_ADDR_WIDTH-1 downto 0))); -- Three bits of the address are used to distinguish between RAM access "1XX", Coontrol "000", Status "010", Sticky "011" . The rest is used to index the control/status bytes.

			RAM_WR_EN_INT <='0'; -- Read/writes are single pulses. Overriden below when needed.
			RAM_RD_EN_INT <='0';

			-- Manage timeout counter and flags
			timeout_reset <= '0'; -- overriden below
			if timeout_reset='1' then
				timeout_int <= '0';
				timeout_ctr <= (others=>'0');
			elsif signed(timeout_ctr) = -1 then
				timeout_int <= '1';
			else
				timeout_ctr <= timeout_ctr + 1;
			end if;

			-- Force a new state if timeout occurs
			-- if timeout='1' then
			-- 	CMD_IN_RDY_FIFO.TREADY<='1'; -- we will capture the next byte
			-- 	RX_STATE <= COMMAND_BYTE1;
			-- end if;

			CASE RX_STATE IS
				---------------------
				when COMMAND_BYTE1 =>
				---------------------
--					is_write <= CMD_IN_DAT_FIFO.TDATA(7);
					opcode <= CMD_IN_DAT_FIFO.TDATA(7 downto 5);
					count <= shift_left(to_unsigned(1, count'length), to_integer(unsigned(CMD_IN_DAT_FIFO.TDATA(4 downto 3)))); -- initialize byte counter as 2^COMMAND_COUNT
					addr(18 downto 16) <= unsigned(CMD_IN_DAT_FIFO.TDATA(2 downto 0));
					incr <='1';
					timeout_reset <= '1'; -- Ignore timeouts while waiting for first command byte
					CMD_IN_RDY_FIFO.TREADY <= '1'; -- We will always be ready to capture the next byte when it comes

					if CMD_IN_DAT_FIFO.TVALID='1' and first='1' then
						if CMD_IN_DAT_FIFO.TLAST='0' then
							RX_STATE <= COMMAND_BYTE2;
						end if;
					end if;

				---------------------
				when COMMAND_BYTE2 =>
				---------------------
					addr(15 downto 8) <= unsigned(CMD_IN_DAT_FIFO.TDATA);

					if CMD_IN_DAT_FIFO.TVALID='1' then
						timeout_reset <= '1';
						CMD_IN_RDY_FIFO.TREADY<='1'; -- We will always capture the next byte when it comes
						if CMD_IN_DAT_FIFO.TLAST='1' then
							RX_STATE <= COMMAND_BYTE1;
						else
							RX_STATE <= COMMAND_BYTE3;
						end if;

					end if;

				---------------------
				when COMMAND_BYTE3 =>
				---------------------

					if  CMD_IN_DAT_FIFO.TVALID='1' and CMD_IN_RDY_FIFO.TREADY='1' then -- we use TREADY to determine if we have already obtained a byte.
						timeout_reset <= '1';
						addr(7 downto 0) <= unsigned(CMD_IN_DAT_FIFO.TDATA); -- grab the final byte of the address
						addr(18 downto ADDR_WIDTH) <= (others=>'0'); -- zero all the address bits we dont need
						CMD_IN_RDY_FIFO.TREADY <= '0'; -- Don't read any incoming byte by default. Will be overriden below as needed.
					end if;

					-- Prepare reply byte in case it is needed
					is_msb <= '0';
					send_msb <='0';
					wait_state <= '0'; -- we do not start in a wait state for RAM reads
					if opcode = OPCODE_WRITE_RAM then
							incr <='0'; -- don't pre-increment address on the first RAM write: we need it to be stable during the read
					end if;

                    -- we use TREADY to determine if we have already obtained a byte
					if (CMD_IN_DAT_FIFO.TVALID='1' or CMD_IN_RDY_FIFO.TREADY='0') and (RPLY_OUT_DAT_FIFO.TVALID='0' or  RPLY_OUT_RDY_FIFO.TREADY='1') then -- if the last command byte is available and the reply channel is ready
						-- Send a dummy reply byte header. The value is not important: it will be replaced by MASTER with a sequence number.
						-- RPLY_OUT_DAT_FIFO.TDATA <= is_write & incr & "000000";
						RPLY_OUT_DAT_FIFO.TVALID <= '1';

						if opcode=OPCODE_READ_CONTROL or opcode=OPCODE_READ_STATUS or opcode=OPCODE_READ_RAM  then -- if is_write='0'
    						RPLY_OUT_DAT_FIFO.TLAST <= '0'; -- the first reply byte was not the last one - there are more to come
							CMD_IN_RDY_FIFO.TREADY <= '0'; -- do not accept more bytes
							if opcode = OPCODE_READ_RAM then
								RAM_RD_EN_INT <='1';
							end if;
							RX_STATE <= EXECUTE_COMMAND;

						else -- if we have a write command and the last command byte has arrived
							RPLY_OUT_DAT_FIFO.TLAST <= '1'; -- the first reply byte is our last one
							CMD_IN_RDY_FIFO.TREADY <= '1'; -- the next data or command byte will be consumed
							if CMD_IN_DAT_FIFO.TLAST='1' then -- if this is the last byte of the packet, abort. This being a write command, we need more data coming!
								RX_STATE <= COMMAND_BYTE1;
							else
								RX_STATE <= EXECUTE_COMMAND;
							end if;
						end if;
					end if;

				---------------------
				when EXECUTE_COMMAND =>
				---------------------

					case opcode is
						---------------------
						when OPCODE_WRITE_CONTROL | OPCODE_WRITE_CONTROL_MASK=> -- wait for an incoming byte, and write it to the appropriate control byte
						---------------------
							if CMD_IN_DAT_FIFO.TVALID='1' then
								timeout_reset <= '1';
								if opcode = OPCODE_WRITE_CONTROL_MASK then -- if in mask mode, write only when you get 2 bytes
									if is_msb='1' then
										CONTROL_BYTES_INT(byte_index_var) <= (CONTROL_BYTES_INT(byte_index_var) and not CMD_IN_DAT_FIFO.TDATA) or (previous_byte and CMD_IN_DAT_FIFO.TDATA); -- Store byte in control word
										addr <= addr + 1;
									end if; -- otherwise do nothing but wait for the next byte
								else
									CONTROL_BYTES_INT(byte_index_var) <= CMD_IN_DAT_FIFO.TDATA; -- Store byte in control word
									addr <= addr + 1;
								end if;
								CMD_IN_RDY_FIFO.TREADY <='1'; -- the next byte will be processed
								if CMD_IN_DAT_FIFO.TLAST='1' then
									RX_STATE <= COMMAND_BYTE1;
								end if;
							end if;

						---------------------
						when OPCODE_READ_CONTROL =>
						-- wait for the reply bus to be ready and send a control byte value. Repeat 'count' times.
						---------------------
							if RPLY_OUT_DAT_FIFO.TVALID='0' or RPLY_OUT_RDY_FIFO.TREADY='1' then -- if reply channel ready
								timeout_reset <= '1';
								RPLY_OUT_DAT_FIFO.TDATA <= CONTROL_BYTES_INT(byte_index_var);
								RPLY_OUT_DAT_FIFO.TVALID <= '1';
								RPLY_OUT_DAT_FIFO.TLAST <= '0';
								addr <= addr + 1;
								count <= count - 1;
								if count=1 then
									RPLY_OUT_DAT_FIFO.TLAST <= '1';
									CMD_IN_RDY_FIFO.TREADY <= '1'; -- the next byte will be processed
									RX_STATE <= COMMAND_BYTE1;
								end if;
							end if;

						---------------------
						when OPCODE_READ_STATUS =>
						-- wait for the reply bus to be ready and send a status byte value. Repeat 'count' times.
						---------------------
							if RPLY_OUT_DAT_FIFO.TVALID='0' or RPLY_OUT_RDY_FIFO.TREADY='1' then -- if reply channel ready
								timeout_reset <= '1';
								RPLY_OUT_DAT_FIFO.TDATA <= STATUS_BYTES_INT(byte_index_var);
								RPLY_OUT_DAT_FIFO.TVALID <= '1';
								RPLY_OUT_DAT_FIFO.TLAST <= '0';
								addr <= addr + 1;
								count <= count - 1;
								if count=1 then
									RPLY_OUT_DAT_FIFO.TLAST<='1';
									CMD_IN_RDY_FIFO.TREADY <='1'; -- the next byte will be processed
									RX_STATE <= COMMAND_BYTE1;
								end if;
							end if;

						---------------------
						when OPCODE_WRITE_RAM =>
						-- if RAM/DRP is used, write control byte to RAM/DRP. In 16-bit mode, Write only when MSB is ready. Wait for RDY is not pipelined and a write occured.
						---------------------
							if RAM_ADDR_WIDTH/=0 then --Make sure this block of code is not synthesized if no RAM/DRP access is needed

								if wait_state='0' and CMD_IN_DAT_FIFO.TVALID='1' then
									timeout_reset <= '1';
									if RAM_DATA_WIDTH=16 and is_msb='1' then -- if we are in 16-bit mode and this is the second byte (MSB)
										RAM_DIN_INT(15 downto 8) <= CMD_IN_DAT_FIFO.TDATA;
										RAM_DIN_INT(7 downto 0) <= previous_byte;
										RAM_WR_EN_INT <='1';
										addr <= addr + 1;
									else -- if 8 bit mode, store and write always
										RAM_DIN_INT(7 downto 0) <= CMD_IN_DAT_FIFO.TDATA;
										RAM_WR_EN_INT <='1';
										if incr='1' then
											addr <= addr + 1;
										end if;
										incr<='1';
									end if;

									if USE_PIPELINED_RAM_WRITE=FALSE and (RAM_DATA_WIDTH/=16 or is_msb='1') then -- if we need to wait for a ready signal and we actually wrote a byte/word (i.e. not interrupted half-word), then process a wait state. The end of frame will be handled there.
										CMD_IN_RDY_FIFO.TREADY <='0'; -- we won't grab new data until the RAM is ready
										was_last <= CMD_IN_DAT_FIFO.TLAST; -- store the end of frame flag so we process it once the write is acknowledged.
										wait_state <= '1';
									elsif CMD_IN_DAT_FIFO.TLAST='1' then -- this is the last byte and we don't have to wait for the write to complete, process the next command
										CMD_IN_RDY_FIFO.TREADY <='1'; -- the next byte will be processed
										RX_STATE <= COMMAND_BYTE1;
									else -- if we don't have to wait for the write and this is not the last byte, we stay in this state
										CMD_IN_RDY_FIFO.TREADY <='1'; -- the next byte will be processed
									end if;
								elsif wait_state='1'and USE_PIPELINED_RAM_WRITE=FALSE then -- wait for the RDY signal to be asserted before reading another byte
									if RAM_RDY='1' then
										wait_state <= '0';
										CMD_IN_RDY_FIFO.TREADY <='1'; -- the next byte will be processed
										if was_last='1' then -- was the byte written the last one?
											RX_STATE <= COMMAND_BYTE1;
										end if;
									end if;
								end if; -- if new data available
							else -- no RAM/DRP support, just return to next command. We should never get here.
								CMD_IN_RDY_FIFO.TREADY <= '1'; -- the next byte will be processed
								RX_STATE <= COMMAND_BYTE1;
							end if; -- if RAM/DRP present

						---------------------
						when OPCODE_READ_RAM =>
						---------------------
							-- RAM_RD_EN_INT <='0'; -- stop the read pulse
							if RAM_ADDR_WIDTH /=0 then
								if RPLY_OUT_DAT_FIFO.TVALID='0' or RPLY_OUT_RDY_FIFO.TREADY='1' then -- if reply channel ready
									if RAM_DATA_WIDTH=16 then
										if send_msb='1' then -- if send msb
											timeout_reset <= '1';
											RPLY_OUT_DAT_FIFO.TVALID <= '1';
											RPLY_OUT_DAT_FIFO.TDATA <= ram_dout_msb;
											send_msb <= '0';
											RAM_RD_EN_INT <= '1'; -- fetch next word
										elsif RAM_RDY='1' then
											timeout_reset <= '1';
											RPLY_OUT_DAT_FIFO.TVALID <= '1';
											RPLY_OUT_DAT_FIFO.TDATA <= RAM_DOUT(7 downto 0);
											ram_dout_msb <= RAM_DOUT(15 downto 8); -- store the MSB for later transmission
											send_msb <= '1'; -- next cycle will send the stored MSB
											-- RAM_RD_EN_INT <='0'; -- stop reading while we send the MSB
										end if;
									elsif RAM_RDY='1' then
										timeout_reset <= '1';
										RPLY_OUT_DAT_FIFO.TVALID <= '1';
										RPLY_OUT_DAT_FIFO.TDATA <= RAM_DOUT(7 downto 0);
										RAM_RD_EN_INT <= '1'; -- fetch next byte
									end if;

									if (RAM_DATA_WIDTH=16 and send_msb='1') or RAM_RDY='1' then
										addr <= addr + 1;
										count <= count - 1;
											RPLY_OUT_DAT_FIFO.TLAST <= '0';
										if count=1 then -- if this is the last byte/word
											RAM_RD_EN_INT <='0'; -- cancel any data fetch
											RPLY_OUT_DAT_FIFO.TLAST <= '1';
											CMD_IN_RDY_FIFO.TREADY <= '1'; -- the next byte will be processed
											RX_STATE <= COMMAND_BYTE1;
										end if;
									end if;
								end if; -- if reply channel ready
							else -- no RAM/DRP support, just return to next command. We should never get here.
								CMD_IN_RDY_FIFO.TREADY <='1'; -- the next byte will be processed
								RX_STATE <= COMMAND_BYTE1;
							end if;

						when others => -- any other opcode is NOP
							RPLY_OUT_DAT_FIFO.TVALID <= '0'; -- do not send reply header
							CMD_IN_RDY_FIFO.TREADY <= '1'; -- next state will consume a byte when available
							RX_STATE <= COMMAND_BYTE1;
					end case;
			end case;



			if RST_SEL='1' then
				-- Reset buses
				RPLY_OUT_DAT_FIFO.TVALID<='0';
				CMD_IN_RDY_FIFO.TREADY <='1'; -- we are ready to accept the next byte
				first <= '1'; -- make sure we accept the first command after reset

				RX_STATE<=COMMAND_BYTE1;
				-- RAM_RD_EN_INT <='0';
				-- RAM_WR_EN_INT <='0';
				timeout_reset <= '1';
				for i in 0 to NUMBER_OF_CONTROL_BYTES-1 loop
					for j in 0 to 7 loop
						CONTROL_BYTES_INT(i)(j)<=DEFAULT_CONTROL_BYTES(i*8+7-j); -- Clock the control  bytes on the user clock
					end loop;
				end loop;
			end if; -- RST

		end if; --CLK
	end process;

end Behavioral;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.chFPGA_Package.all; -- Get all component definitions
entity ctrl_slave_bd is
GENERIC (
		DEFAULT_CONTROL_BYTES: std_logic_vector := X"00000000"; --! Vector of bits to initialize the control register to a known value
		NUMBER_OF_CONTROL_BYTES: integer        := 1; --! Number of bytes in the control word
		NUMBER_OF_STATUS_BYTES: integer         := 1 --! Number of bytes in the status word.
		);
    PORT (

		-- Control interface

		-- Command stream bus (slave)
		s_ctrl_tdata: in std_logic_vector(31 downto 0);
		s_ctrl_tvalid: in std_logic;
		s_ctrl_tlast: in std_logic;
		s_ctrl_tready: out std_logic;

		m_ctrl_tdata: out std_logic_vector(31 downto 0);
		m_ctrl_tvalid: out std_logic;
		m_ctrl_tlast: out std_logic;
		m_ctrl_tready: in std_logic;


		-- Control/status words
--		CONTROL_BYTES: out slv8_array(0 to NUMBER_OF_CONTROL_BYTES-1); --
--		STATUS_BYTES: in slv8_array(0 to NUMBER_OF_STATUS_BYTES-1):=(others=> (others=>'0')) --

		clk: in STD_LOGIC;
		rstn: in std_logic --! Reset, synchronous to CTRL_CLK

		-- System interface
		);
end ctrl_slave_bd;

architecture arch_impl of ctrl_slave_bd is

signal CTRL_CMD_IN_DAT: AXIS8_DAT_STRUCT;
signal CTRL_CMD_IN_RDY: AXIS8_RDY_STRUCT;
signal CTRL_RPLY_OUT_DAT:  AXIS8_DAT_STRUCT;
signal CTRL_RPLY_OUT_RDY: AXIS8_RDY_STRUCT;

signal control_bytes: slv8_array(0 to NUMBER_OF_CONTROL_BYTES-1); -- default value set in the CMD_SLAVE
signal status_bytes: slv8_array(0 to NUMBER_OF_STATUS_BYTES-1); -- default value set in the CMD_SLAVE

begin

		CTRL_CMD_IN_DAT.TDATA <= s_ctrl_tdata(7 downto 0);
		CTRL_CMD_IN_DAT.TLAST <= s_ctrl_tlast;
		CTRL_CMD_IN_DAT.TVALID <= s_ctrl_tvalid;
		CTRL_CMD_IN_DAT.DUMMY <= '0';
		s_ctrl_tready <= CTRL_CMD_IN_RDY.TREADY;

		m_ctrl_tdata(7 downto 0) <= CTRL_RPLY_OUT_DAT.TDATA;
		m_ctrl_tlast <= CTRL_RPLY_OUT_DAT.TLAST;
		m_ctrl_tvalid <= CTRL_RPLY_OUT_DAT.TVALID;
--		CTRL_RPLY_OUT_DAT.DUMMY => '0',
		CTRL_RPLY_OUT_RDY.TREADY<= m_ctrl_tready;


CTRL_SLAVE0: entity work.CTRL_SLAVE
	GENERIC MAP (
		NUMBER_OF_CONTROL_BYTES=>NUMBER_OF_CONTROL_BYTES , --
		NUMBER_OF_STATUS_BYTES=>NUMBER_OF_STATUS_BYTES , --
		DEFAULT_CONTROL_BYTES=> DEFAULT_CONTROL_BYTES
	)

	PORT MAP(
		-- Control interface (command and reply stream buses)
		CTRL_CMD_IN_DAT => CTRL_CMD_IN_DAT,
		CTRL_CMD_IN_RDY => CTRL_CMD_IN_RDY,

		CTRL_RPLY_OUT_DAT => CTRL_RPLY_OUT_DAT,
		CTRL_RPLY_OUT_RDY => CTRL_RPLY_OUT_RDY,
		CTRL_CLK => clk,
		CTRL_RST => not rstn,

		control_bytes => control_bytes,
		status_bytes => status_bytes,
		CLK => clk,
		RST => not rstn	);
end arch_impl;
			
			




