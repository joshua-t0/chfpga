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
		RAM_LATENCY: integer                    := 1 --! Number of cycles if takes for the RAM data to be ready after a read. Can be 1 or 2. Not used if USE_RAM_DOUT_RDY=TRUE.
		);
    PORT (

		-- Control interface

		-- Command stream bus (slave)
		ctrl_cmd_in_dat: in AXIS8_DAT_STRUCT; -- Command stream input, signals from master (Data, Valid, Last)
		ctrl_cmd_in_rdy: out AXIS8_RDY_STRUCT; -- Command stream input, signals to master (Ready)
		ctrl_rply_out_dat: out AXIS8_DAT_STRUCT; -- Reply stream output, signals to slave (Data, Valid, Last)
		ctrl_rply_out_rdy: in AXIS8_RDY_STRUCT; -- Reply stream output,  signals from slave (Ready)
		ctrl_clk: in STD_LOGIC;
		ctrl_rst: in std_logic; --! Reset, synchronous to CTRL_CLK

		-- Control/status words
		CONTROL_BYTES: out slv8_array(0 to NUMBER_OF_CONTROL_BYTES-1); --
		STATUS_BYTES: in slv8_array(0 to NUMBER_OF_STATUS_BYTES-1):=(others=> (others=>'0')); --

		-- FIFO/RAM interface
		RAM_DIN : OUT  STD_LOGIC_VECTOR (RAM_DATA_WIDTH-1 downto 0);
		RAM_DOUT : IN  STD_LOGIC_VECTOR (RAM_DATA_WIDTH-1 downto 0):=(others=>'0');
		RAM_DOUT_RDY : IN  STD_LOGIC :='0'; -- To interface devices that have a ready pin. Set GLOBAL variable USE_RAM_DOUT_RDY to determine whether this pin is used or not
		RAM_ADDR : OUT  STD_LOGIC_VECTOR (max(RAM_ADDR_WIDTH-1, 0) downto 0); -- max() used to prevent null port warning
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

	signal RAM_RD_EN_INT: STD_LOGIC;
	signal RAM_WR_EN_INT: std_logic := '0'; -- init for sim only to prevent contamination of RAM first byte
	signal RAM_DIN_INT: std_logic_vector(15 downto 0);

	constant INT_ADDR_WIDTH: integer :=19;

	subtype OPCODE_TYPE is std_logic_vector(2 downto 0);
	constant OPCODE_WRITE_CONTROL: OPCODE_TYPE        := "100";
	constant OPCODE_WRITE_CONTROL_MASK: OPCODE_TYPE   := "101";
	constant OPCODE_NOP: OPCODE_TYPE                  := "110";
	constant OPCODE_WRITE_RAM: OPCODE_TYPE            := "111";
	constant OPCODE_READ_CONTROL: OPCODE_TYPE         := "000";
	constant OPCODE_READ_STATUS: OPCODE_TYPE          := "010";
	constant OPCODE_READ_RAM: OPCODE_TYPE             := "011";

	signal ctrl_cmd_in_rdy_int: AXIS8_RDY_STRUCT;
	signal ctrl_rply_out_dat_int: AXIS8_DAT_STRUCT;

	signal ram_write_addr_incr: std_logic;
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


	--signal timeout: std_logic;
	--signal timeout_int: std_logic;
	--signal timeout_reset: std_logic;
	--signal timeout_ctr: unsigned(7 downto 0);
	constant dly: time := 10 ps;
begin

-- Use intermediary signals so we can read them back
ctrl_cmd_in_rdy <= ctrl_cmd_in_rdy_int;
ctrl_rply_out_dat <= ctrl_rply_out_dat_int;

RAM_RDY <=
	RAM_DOUT_RDY when USE_RAM_DOUT_RDY=TRUE else
	ram_rdy_dly1 when RAM_LATENCY=1 else -- USE RDY signal from RAM if available, otherwise use delayed version of RAM_EN Pulse
	ram_rdy_dly2;


CONTROL_BYTES <= CONTROL_BYTES_INT;
STATUS_BYTES_INT <= STATUS_BYTES;

-- Assign internal RAM_ADDR to output
gen_ram_addr: if RAM_ADDR_WIDTH /= 0 generate
	ram_en_int <= RAM_RD_EN_INT or RAM_WR_EN_INT; -- Added for tdevices with EN and WR control signals instead of RD and WR signals
	RAM_ADDR  <= std_logic_vector(addr(RAM_ADDR_WIDTH downto 1)) when RAM_DATA_WIDTH=16 else std_logic_vector(addr(RAM_ADDR_WIDTH-1 downto 0));
	RAM_WR_EN <= RAM_WR_EN_INT;
	RAM_RD_EN <= RAM_RD_EN_INT;
	RAM_EN    <= ram_en_int;
	RAM_DIN   <= RAM_DIN_INT(RAM_DATA_WIDTH-1 downto 0);
end generate;
gen_noram_addr: if RAM_ADDR_WIDTH = 0 generate -- special case to avoid null assignment warning if we don't use RAM
	RAM_ADDR  <= (others => '0');
	RAM_WR_EN <= '0';
	RAM_RD_EN <= '0';
	RAM_EN    <= '0';
	RAM_DIN   <= (others => '0');
	RAM_DIN_INT <= (others => '0');
end generate;



--timeout <= '1' when timeout_int='1' and timeout_reset = '0' else '0';

-- Command processor process
cmd_proc: process(ctrl_clk)
	variable byte_index_var: integer range 0 to max(NUMBER_OF_STATUS_BYTES, NUMBER_OF_CONTROL_BYTES)-1;
	constant CONTROL_STATUS_ADDR_WIDTH: integer := width(max(NUMBER_OF_CONTROL_BYTES, NUMBER_OF_STATUS_BYTES));

	-- variable opcode_var: OPCODE_TYPE;

	begin
		if rising_edge(ctrl_clk) then

			-- if the byte at the reply is read, clear the valid flag. This is overriden below when we send a new byte.
			if (ctrl_rply_out_rdy.TREADY='1') then
				ctrl_rply_out_dat_int.TVALID<='0';
			end if;


			if ctrl_cmd_in_dat.TVALID='1' and ctrl_cmd_in_rdy_int.TREADY ='1'then
				first <= ctrl_cmd_in_dat.TLAST;
				is_msb <= not is_msb; -- toggles for each incoming byte. If overriden below to align msb/lsb.
				previous_byte <= ctrl_cmd_in_dat.TDATA;
			end if;

			-- `byte_index_var` is the address of the byte to be accessed within the CONTROL or STATUS pages, as an integer.
			-- Those are just the applicable LSBs of the address word. 
			byte_index_var := to_integer(unsigned(addr(CONTROL_STATUS_ADDR_WIDTH-1 downto 0))); 

			if RAM_ADDR_WIDTH /=0 then -- initialize only when used to prevent warnings
				ram_rdy_dly1 <= ram_en_int; -- delayed version of RAM_RD_EN used to generate the RAM_DOUT_RDY if the RAM does not provide one
				ram_rdy_dly2 <= ram_rdy_dly1; -- delayed version of RAM_RD_EN used to generate the RAM_DOUT_RDY if the RAM does not provide one
				RAM_WR_EN_INT <='0'; -- Read/writes are single pulses. Overriden below when needed.
				RAM_RD_EN_INT <='0';
			end if;


			-- Manage timeout counter and flags
			--timeout_reset <= '0'; -- overriden below
			--if timeout_reset='1' then
			--	timeout_int <= '0';
			--	timeout_ctr <= (others=>'0');
			--elsif signed(timeout_ctr) = -1 then
			--	timeout_int <= '1';
			--else
			--	timeout_ctr <= timeout_ctr + 1;
			--end if;

			-- Force a new state if timeout occurs
			-- if timeout='1' then
			-- 	ctrl_cmd_in_rdy_int.TREADY<='1'; -- we will capture the next byte
			-- 	RX_STATE <= COMMAND_BYTE1;
			-- end if;

			CASE RX_STATE IS
				---------------------
				when COMMAND_BYTE1 =>
				---------------------
--					is_write <= ctrl_cmd_in_dat.TDATA(7);
					opcode <= ctrl_cmd_in_dat.TDATA(7 downto 5);
					count <= shift_left(to_unsigned(1, count'length), to_integer(unsigned(ctrl_cmd_in_dat.TDATA(4 downto 3)))); -- initialize byte counter as 2^COMMAND_COUNT
					addr(18 downto 16) <= unsigned(ctrl_cmd_in_dat.TDATA(2 downto 0));
					--timeout_reset <= '1'; -- Ignore timeouts while waiting for first command byte
					ctrl_cmd_in_rdy_int.TREADY <= '1'; -- We will always be ready to capture the next byte when it comes

					if ctrl_cmd_in_dat.TVALID='1' and first='1' then
						if ctrl_cmd_in_dat.TLAST='0' then
							RX_STATE <= COMMAND_BYTE2;
						end if;
					end if;

				---------------------
				when COMMAND_BYTE2 =>
				---------------------
					addr(15 downto 8) <= unsigned(ctrl_cmd_in_dat.TDATA);

					if ctrl_cmd_in_dat.TVALID = '1' then
						--timeout_reset <= '1';
						ctrl_cmd_in_rdy_int.TREADY <= '1'; -- We will always capture the next byte when it comes
						if ctrl_cmd_in_dat.TLAST = '1' then
							RX_STATE <= COMMAND_BYTE1;
						else
							RX_STATE <= COMMAND_BYTE3;
						end if;

					end if;

				---------------------
				when COMMAND_BYTE3 =>
				---------------------

					if  ctrl_cmd_in_dat.TVALID = '1' and ctrl_cmd_in_rdy_int.TREADY = '1' then -- we use TREADY to determine if we have already obtained a byte.
						--timeout_reset <= '1';
						addr(7 downto 0) <= unsigned(ctrl_cmd_in_dat.TDATA); -- grab the final byte of the address
						if ADDR_WIDTH <= 18 then -- avoid null assignment warnings
							addr(18 downto ADDR_WIDTH) <= (others=>'0'); -- zero all the address bits we dont need
						end if;
						ctrl_cmd_in_rdy_int.TREADY <= '0'; -- Don't read any incoming byte by default. Will be overriden below as needed.
					end if;

					-- Prepare reply byte in case it is needed

					-- Initialize RAM access-related signals
					if RAM_ADDR_WIDTH /= 0 then
						if RAM_DATA_WIDTH = 16 then -- initialize only when used to prevent warnings
							send_msb <= '0';
						end if;
						ram_write_addr_incr <='0'; -- If we write to RAM, don't increment the address on when we setup the first RAM write as addr is already the target address
					end if;

					is_msb <= '0'; -- start with even byte
					wait_state <= '0'; -- we do not start in a wait state for RAM reads

					-- We send a dummy reply byte as soon as the last byte of the command has been received.
					-- We'll stay in this state until we can put the reply byte on the bus.  
                    -- We have received the last command byte either when it arrived on this clock (TVALID=1) or it was received earlier and TREADY was set to 0.
                    -- We can put a byte on the reply bus either if there is no byte on the bus (TREADY=0) or if there is a byte but is being consumed on this clock (TREADY=1)
					if (ctrl_cmd_in_dat.TVALID='1' or ctrl_cmd_in_rdy_int.TREADY='0') and (ctrl_rply_out_dat_int.TVALID='0' or  ctrl_rply_out_rdy.TREADY='1') then -- if the last command byte is available and the reply channel is ready
						-- Send a dummy reply byte header. The value is not important: it will be replaced by MASTER with a sequence number.
						ctrl_rply_out_dat_int.TVALID <= '1';

						if opcode=OPCODE_READ_CONTROL or opcode=OPCODE_READ_STATUS or opcode=OPCODE_READ_RAM  then -- if is_write='0'
    						ctrl_rply_out_dat_int.TLAST <= '0'; -- the first reply byte was not the last one - there are more to come
							ctrl_cmd_in_rdy_int.TREADY <= '0'; -- do not accept more bytes
							if opcode = OPCODE_READ_RAM then
								RAM_RD_EN_INT <='1';
							end if;
							RX_STATE <= EXECUTE_COMMAND;

						else -- if we have a write command and the last command byte has arrived
							ctrl_rply_out_dat_int.TLAST <= '1'; -- the first reply byte is our last one
							ctrl_cmd_in_rdy_int.TREADY <= '1'; -- the next data or command byte will be consumed
							if ctrl_cmd_in_dat.TLAST='1' then -- if this is the last byte of the packet, abort. This being a write command, we need more data coming!
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
							if ctrl_cmd_in_dat.TVALID='1' then
								--timeout_reset <= '1';
								if opcode = OPCODE_WRITE_CONTROL_MASK then -- if in mask mode, write only when you get 2 bytes
									if is_msb='1' then
										CONTROL_BYTES_INT(byte_index_var) <= (CONTROL_BYTES_INT(byte_index_var) and not ctrl_cmd_in_dat.TDATA) or (previous_byte and ctrl_cmd_in_dat.TDATA); -- Store byte in control word
										addr <= addr + 1;
									end if; -- otherwise do nothing but wait for the next byte
								else
									CONTROL_BYTES_INT(byte_index_var) <= ctrl_cmd_in_dat.TDATA; -- Store byte in control word
									addr <= addr + 1;
								end if;
								ctrl_cmd_in_rdy_int.TREADY <='1'; -- the next byte will be processed
								if ctrl_cmd_in_dat.TLAST='1' then
									RX_STATE <= COMMAND_BYTE1;
								end if;
							end if;

						---------------------
						when OPCODE_READ_CONTROL =>
						-- wait for the reply bus to be ready and send a control byte value. Repeat 'count' times.
						---------------------
							if ctrl_rply_out_dat_int.TVALID='0' or ctrl_rply_out_rdy.TREADY='1' then -- if reply channel ready
								--timeout_reset <= '1';
								ctrl_rply_out_dat_int.TDATA <= CONTROL_BYTES_INT(byte_index_var);
								ctrl_rply_out_dat_int.TVALID <= '1';
								ctrl_rply_out_dat_int.TLAST <= '0';
								addr <= addr + 1;
								count <= count - 1;
								if count=1 then
									ctrl_rply_out_dat_int.TLAST <= '1';
									ctrl_cmd_in_rdy_int.TREADY <= '1'; -- the next byte will be processed
									RX_STATE <= COMMAND_BYTE1;
								end if;
							end if;

						---------------------
						when OPCODE_READ_STATUS =>
						-- wait for the reply bus to be ready and send a status byte value. Repeat 'count' times.
						---------------------
							if ctrl_rply_out_dat_int.TVALID='0' or ctrl_rply_out_rdy.TREADY='1' then -- if reply channel ready
								--timeout_reset <= '1';
								ctrl_rply_out_dat_int.TDATA <= STATUS_BYTES_INT(byte_index_var);
								ctrl_rply_out_dat_int.TVALID <= '1';
								ctrl_rply_out_dat_int.TLAST <= '0';
								addr <= addr + 1;
								count <= count - 1;
								if count=1 then
									ctrl_rply_out_dat_int.TLAST<='1';
									ctrl_cmd_in_rdy_int.TREADY <='1'; -- the next byte will be processed
									RX_STATE <= COMMAND_BYTE1;
								end if;
							end if;

						---------------------
						when OPCODE_WRITE_RAM =>
						-- if RAM/DRP is used, write control byte to RAM/DRP. In 16-bit mode, Write only when MSB is ready. Wait for RDY is not pipelined and a write occured.
						---------------------
							if RAM_ADDR_WIDTH/=0 then --Make sure this block of code is not synthesized if no RAM/DRP access is needed

								if wait_state='0' and ctrl_cmd_in_dat.TVALID='1' then
									--timeout_reset <= '1';
									if RAM_DATA_WIDTH=16 and is_msb='1' then -- if we are in 16-bit mode and this is the second byte (MSB)
										RAM_DIN_INT(15 downto 8) <= ctrl_cmd_in_dat.TDATA;
										RAM_DIN_INT(7 downto 0) <= previous_byte;
										RAM_WR_EN_INT <='1';
										addr <= addr + 1;
									else -- if 8 bit mode, store and write always
										RAM_DIN_INT(15 downto 8) <= (others => '0'); -- make sure the net is always driven even in 8-bit mode to suppress warnings
										RAM_DIN_INT(7 downto 0) <= ctrl_cmd_in_dat.TDATA;
										RAM_WR_EN_INT <='1';
										-- Set the write address along with WR_EN=1 and the data.
										-- We don't increment the address on the first write of the block, as addr already contains our first target address.
										-- But we set ram_write_addr_incr=1 so we will increment it when we setup the next write cycles.
										if ram_write_addr_incr='1' then
											addr <= addr + 1;
										end if;
										ram_write_addr_incr<='1';
									end if;

									if USE_PIPELINED_RAM_WRITE=FALSE and (RAM_DATA_WIDTH/=16 or is_msb='1') then -- if we need to wait for a ready signal and we actually wrote a byte/word (i.e. not interrupted half-word), then process a wait state. The end of frame will be handled there.
										ctrl_cmd_in_rdy_int.TREADY <='0'; -- we won't grab new data until the RAM is ready
										was_last <= ctrl_cmd_in_dat.TLAST; -- store the end of frame flag so we process it once the write is acknowledged.
										wait_state <= '1';
									elsif ctrl_cmd_in_dat.TLAST='1' then -- this is the last byte and we don't have to wait for the write to complete, process the next command
										ctrl_cmd_in_rdy_int.TREADY <='1'; -- the next byte will be processed
										RX_STATE <= COMMAND_BYTE1;
									else -- if we don't have to wait for the write and this is not the last byte, we stay in this state
										ctrl_cmd_in_rdy_int.TREADY <='1'; -- the next byte will be processed
									end if;
								elsif wait_state='1'and USE_PIPELINED_RAM_WRITE=FALSE then -- wait for the RDY signal to be asserted before reading another byte
									if RAM_RDY='1' then
										wait_state <= '0';
										ctrl_cmd_in_rdy_int.TREADY <='1'; -- the next byte will be processed
										if was_last='1' then -- was the byte written the last one?
											RX_STATE <= COMMAND_BYTE1;
										end if;
									end if;
								end if; -- if new data available
							else -- no RAM/DRP support, just return to next command. We should never get here.
								ctrl_cmd_in_rdy_int.TREADY <= '1'; -- the next byte will be processed
								RX_STATE <= COMMAND_BYTE1;
							end if; -- if RAM/DRP present

						---------------------
						when OPCODE_READ_RAM =>
						---------------------
							-- RAM_RD_EN_INT <='0'; -- stop the read pulse
							if RAM_ADDR_WIDTH /=0 then
								if ctrl_rply_out_dat_int.TVALID='0' or ctrl_rply_out_rdy.TREADY='1' then -- if reply channel ready
									if RAM_DATA_WIDTH=16 then
										if send_msb='1' then -- if send msb
											--timeout_reset <= '1';
											ctrl_rply_out_dat_int.TVALID <= '1';
											ctrl_rply_out_dat_int.TDATA <= ram_dout_msb;
											send_msb <= '0';
											RAM_RD_EN_INT <= '1'; -- fetch next word
										elsif RAM_RDY='1' then
											--timeout_reset <= '1';
											ctrl_rply_out_dat_int.TVALID <= '1';
											ctrl_rply_out_dat_int.TDATA <= RAM_DOUT(7 downto 0);
											ram_dout_msb <= RAM_DOUT(15 downto 8); -- store the MSB for later transmission
											send_msb <= '1'; -- next cycle will send the stored MSB
											-- RAM_RD_EN_INT <='0'; -- stop reading while we send the MSB
										end if;
									elsif RAM_RDY='1' then
										--timeout_reset <= '1';
										ctrl_rply_out_dat_int.TVALID <= '1';
										ctrl_rply_out_dat_int.TDATA <= RAM_DOUT(7 downto 0);
										RAM_RD_EN_INT <= '1'; -- fetch next byte
									end if;

									if (RAM_DATA_WIDTH=16 and send_msb='1') or RAM_RDY='1' then
										addr <= addr + 1;
										count <= count - 1;
											ctrl_rply_out_dat_int.TLAST <= '0';
										if count=1 then -- if this is the last byte/word
											RAM_RD_EN_INT <='0'; -- cancel any data fetch
											ctrl_rply_out_dat_int.TLAST <= '1';
											ctrl_cmd_in_rdy_int.TREADY <= '1'; -- the next byte will be processed
											RX_STATE <= COMMAND_BYTE1;
										end if;
									end if;
								end if; -- if reply channel ready
							else -- no RAM/DRP support, just return to next command. We should never get here.
								ctrl_cmd_in_rdy_int.TREADY <='1'; -- the next byte will be processed
								RX_STATE <= COMMAND_BYTE1;
							end if;

						when others => -- any other opcode is NOP
							ctrl_rply_out_dat_int.TVALID <= '0'; -- do not send reply header
							ctrl_cmd_in_rdy_int.TREADY <= '1'; -- next state will consume a byte when available
							RX_STATE <= COMMAND_BYTE1;
					end case;
			end case;



			if ctrl_rst='1' then
				-- Reset buses
				ctrl_rply_out_dat_int.TVALID<='0';
				ctrl_cmd_in_rdy_int.TREADY <='1'; -- we are ready to accept the next byte
				first <= '1'; -- make sure we accept the first command after reset

				RX_STATE<=COMMAND_BYTE1;
				-- RAM_RD_EN_INT <='0';
				-- RAM_WR_EN_INT <='0';
				--timeout_reset <= '1';
				for i in 0 to NUMBER_OF_CONTROL_BYTES-1 loop
					for j in 0 to 7 loop
						CONTROL_BYTES_INT(i)(j)<=DEFAULT_CONTROL_BYTES(i*8+7-j); -- Clock the control bytes on the user clock
					end loop;
				end loop;
			end if; -- RST

		end if; --CLK
	end process;

end Behavioral;






