----------------------------------------------------------------------------------
-- Company: Mc Gill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    13:01:47 05/18/2011
-- Design Name:
-- Module Name:    SYNC_SPI - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description: Implements a SPI interface for the FMC board devices and generates the ADC sync signals
--
-- Dependencies:
--
-- Revision:
--   2011-08-25 JFC: Added SPI_CLK_ENABLE flag to stop the SPI clock
--   2012-04-04 JFC: Changed to synchrounous reset to eliminate unwanted latch
--   2013-08-16 JFC: Cleanup. Removed REV0.

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chFPGA_Package.all; -- Get all component definitions

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SPI is
	generic (
		NUMBER_OF_PORTS: integer;
		CLK_DIVIDE_FACTOR: INTEGER :=200/4 -- SPI clock is ADC_CLK/CLK_DIVIDE_FACTOR/4
		);
    port (
		-- Control interface
		CTRL_CMD_IN_DAT: in AXIS8_DAT_STRUCT; -- Command stream input, signals from master (Data, Valid, Last)
		CTRL_CMD_IN_RDY: out AXIS8_RDY_STRUCT; -- Command stream input, signals to master (Ready)
		CTRL_RPLY_OUT_DAT: out AXIS8_DAT_STRUCT; -- Reply stream output, signals to slave (Data, Valid, Last)
		CTRL_RPLY_OUT_RDY: in AXIS8_RDY_STRUCT; -- Reply stream output,  signals from slave (Ready)
		CTRL_CLK: in  STD_LOGIC;
		CTRL_RST: in std_logic;

		--SPI signals
		SPI_SCK: out STD_LOGIC;
		SPI_MISO: in std_logic_vector(0 to NUMBER_OF_PORTS-1);
		SPI_MOSI: out STD_LOGIC;
		SPI_ADDR: out STD_LOGIC_VECTOR(2 downto 0);
		SPI_CS_N: out std_logic_vector(0 to NUMBER_OF_PORTS-1); -- was also used as PLL_LE on obsolete REV0 ADC boards
		SPI_RST_N: out STD_LOGIC;

		clk200: in STD_LOGIC;
		-- System-level signals
		RST: in STD_LOGIC -- Synchronous to clk200
	);
end SPI;

architecture Behavioral of SPI is

constant SPI_PORT_WIDTH: integer := width(NUMBER_OF_PORTS);
--- Define Control word and its signals
--signal CONTROL_WORD: STD_LOGIC_VECTOR(47 downto 0); -- default value set in the CMD_SLAVE
signal CONTROL_BYTES: slv8_array(0 to 5); -- default value set in the CMD_SLAVE
signal STATUS_BYTES: slv8_array(0 to 4); -- default value set in the CMD_SLAVE

signal CTRL_FLAG_TX_DATA: STD_LOGIC_VECTOR(31 downto 0);
signal CTRL_FLAG_ADDR: STD_LOGIC_VECTOR(3 downto 0);
signal CTRL_FLAG_DEFAULT_ADDR: STD_LOGIC_VECTOR(2 downto 0);
signal CTRL_FLAG_BYTES: unsigned(1 downto 0);
signal CTRL_FLAG_START: STD_LOGIC;
signal CTRL_FLAG_START_PREVIOUS: STD_LOGIC:='0';
signal CTRL_FLAG_SPI_RESET: STD_LOGIC;
signal CTRL_FLAG_ADC_RESET: STD_LOGIC;
signal CTRL_FLAG_ADCDAQ_RESET: STD_LOGIC;
signal CTRL_FLAG_ADC_SYNC: STD_LOGIC;
signal CTRL_FLAG_GLOBAL_TRIG: STD_LOGIC;
signal CTRL_FLAG_SPI_CLK_ENABLE: STD_LOGIC;
--signal REV0: std_logic;
signal ALT_TIMING: std_logic;

--signal STATUS_WORD: STD_LOGIC_VECTOR(39 downto 0):=(others=>'0');

--constant STATUS_FLAG_READY_BIT: INTEGER :=32;

-- SPI State machine signals

signal CLK_CTR: unsigned(7 downto 0):=(others=>'0'); -- Divides the ADC clock by up to 255
signal CE: STD_LOGIC:='0';
signal START: STD_LOGIC:='0';
signal PHASE: unsigned(1 downto 0):=(others=>'0'); -- Divides the clock in 4 phases
signal BIT_CTR: unsigned(6 downto 0):=(others=>'0'); -- Counts the bits to transmit/receive. Zero means there is no transmission
signal TX_REGISTER,RX_REGISTER: unsigned(31 downto 0):=(others=>'0');
signal READY,FIRST_BIT: STD_LOGIC:='0';
signal SPI_PORT: unsigned(SPI_PORT_WIDTH-1 downto 0);

begin
-- Assign signals to CONTROL and STATUS WORDS
-----------------------------------------------------------------------------------
-- CONTROL and STATUS Bytes
-----------------------------------------------------------------------------------
--! @addtogroup memory_map
--! REFCLK Module
--! =============
--! ----------------------------------------------------------------------------------------
--! | Page | Addr | Bit(s)|     Name                | Description                           |
--! |---------|-----|-----|-------------------------|---------------------------------------|
--! | CONTROL | 0-3 | 31:0| TX_DATA                 | Data to be sent. MSB is in byte 0 and is sent first. |
--! |         |  4  | 7:4 | ADDR                    | Address of the SPI device to access. Note that there are only 3 hardware address lines. ADDR[4] is used to control PLL_LE in REV0 mode only. |
--! |         |     |  3  | RESET                   | Controls the hardware SPI_RESET (or SPI_RESET_ALT) lines. Is active high. |
--! |         |     |  2  | START                   | A 0-to-1 transition starts the SPI transaction|
--! |         |     | 1:0 | BYTES                   | Indicates the number of bytes to transfer. 0=1 byte ... 3= 4 bytes. Byte at address 0 i salways transmitted first.|
--! |         |  5  |  7  | (unused)              | |
--! |         |     | 6:4 | DEFAULT_ADDR            | Address to set on the hardware address lines when a transation is not in progress.|
--! |         |     |  3  | CLK_EN                  | Enables SPI clock generation. Active High. |
--! |         |     |  2  | ALT_TIMING              | Uses alternate timing to accomodate the ADC PLL Latch Enable timing, which differs from the standard SPI Chip Enable timing. |
--! |         |     |  1  | (reserved)              | Might be used to expand the number of SPI ports.|
--! |         |     |  0  | PORT                    | Indicates to which port the transation will be made. |
--! | STATUS  | 0-3 | 31:0| RX_DATA                 | Data received during the transation. MSB is in byte 0. MSB is always bit 31 independent of the number of bytes in the transation|
--! |         |  4  | 7:1 | (unused)                | |
--! |         |     |  0  | READY                   | Indicates when the transation is completed and is ready to make another one.|
--! ------------------------------------------------------------------------------

CTRL_FLAG_TX_DATA           <= (CONTROL_BYTES(0) & CONTROL_BYTES(1) & CONTROL_BYTES(2) & CONTROL_BYTES(3));

CTRL_FLAG_ADDR              <= CONTROL_BYTES(4)(7 downto 4);
CTRL_FLAG_SPI_RESET         <= CONTROL_BYTES(4)(3);
CTRL_FLAG_START             <= CONTROL_BYTES(4)(2);
CTRL_FLAG_BYTES             <= unsigned(CONTROL_BYTES(4)(1 downto 0));

CTRL_FLAG_DEFAULT_ADDR      <= CONTROL_BYTES(5)(6 downto 4);
CTRL_FLAG_SPI_CLK_ENABLE    <= CONTROL_BYTES(5)(3);
--REV0                      <= CONTROL_BYTES(5)(2);
ALT_TIMING                  <= CONTROL_BYTES(5)(2);
SPI_PORT                    <= unsigned(CONTROL_BYTES(5)(SPI_PORT_WIDTH-1 downto 0));
STATUS_BYTES(0)             <= STD_LOGIC_VECTOR(RX_REGISTER(31 downto 24));
STATUS_BYTES(1)             <= STD_LOGIC_VECTOR(RX_REGISTER(23 downto 16));
STATUS_BYTES(2)             <= STD_LOGIC_VECTOR(RX_REGISTER(15 downto 8));
STATUS_BYTES(3)             <= STD_LOGIC_VECTOR(RX_REGISTER(7 downto 0));
STATUS_BYTES(4)(7 downto 1) <= (others=>'0');
STATUS_BYTES(4)(0)          <= READY;



SPI_MOSI<=TX_REGISTER(31);
SPI_RST_N<=not CTRL_FLAG_SPI_RESET;



CTRL_SLAVE0: entity work.CTRL_SLAVE
	GENERIC MAP (
		NUMBER_OF_CONTROL_BYTES=>CONTROL_BYTES'Length(1), -- Length of array in the first dimension: number of bytes
		NUMBER_OF_STATUS_BYTES=>STATUS_BYTES'Length(1),
		DEFAULT_CONTROL_BYTES=> X"12345678_73_78"
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
		CLK               => clk200,
		RST               => RST
	);

spiproc: process(clk200)
	begin
		if rising_edge(clk200) then

			-- synchrounous reset
			if RST='1' then
					CLK_CTR <= (others=>'0');
					CE <= '0';
					BIT_CTR <= (others=>'0');
					PHASE <= (others=>'0');
					READY <= '0';
					START <= '0';
					FIRST_BIT <= '0';
					SPI_ADDR <= CTRL_FLAG_DEFAULT_ADDR; -- watch out: this was creating a latch if used in an async reset
					SPI_CS_N  <= (others=>'1');
			else
				-- Generate Clock Enable signal at a fraction of the system clock
				if CLK_CTR = CLK_DIVIDE_FACTOR-1 then
					CLK_CTR <= (others=>'0');
					CE <= '1';
				else
					CLK_CTR <= CLK_CTR+1;
					CE <= '0';
				end if;

				-- Set the START bit if a 0-to-1 transition is detected on the CTRL_FLAG_START bit.
				CTRL_FLAG_START_PREVIOUS<=CTRL_FLAG_START;
				if CTRL_FLAG_START='1' and CTRL_FLAG_START_PREVIOUS='0' then
					START<='1';
				end if;


				-- Actions taken on the divided clock
				if(CE='1') then
				-- Generate phase counter. This divides every SPI clock cycles into 4 phases
					PHASE<=PHASE+1;

				-- Generate SPI clk. Going down in phase 0 and up in phase 2.
					if(PHASE=0) then
						SPI_SCK<='0';
					elsif(PHASE=2 and CTRL_FLAG_SPI_CLK_ENABLE='1') then
						SPI_SCK<='1';
					end if;

					if	(BIT_CTR=0) then -- if we are not transmitting
						if (START='1' and PHASE=3) then --
							READY<='0';
							START<='0'; -- weird since the setting was done outside this group, but the HDL should be able to handle that
							BIT_CTR<=to_unsigned((to_integer(CTRL_FLAG_BYTES)+1)*8,BIT_CTR'Length); -- "00" = 8 bits, "01" = 16 bits, "10" = 24 bits, "11" = 32 bits
							FIRST_BIT<='1';
						end if;
						-- Disable SPI_CS later if ALT_TIMING=1. This is to accompdate the ADC_PLL whose LE should go inactive later than the standard SPI protocol
						if (PHASE=1 and ALT_TIMING='1') then
							SPI_CS_N <= (others=>'1'); -- Disable PLL latch if is was enabled. That will clock in the data we just sent
						end if;

					else -- We are transmitting and receiving
						if PHASE=0 then -- SCK goes down on this clock
							if FIRST_BIT='1' then
								TX_REGISTER <= unsigned(CTRL_FLAG_TX_DATA);
							else
								TX_REGISTER <= shift_left(TX_REGISTER, 1); -- left shift TX register (send MSB first). shift in a '0' to facilitate debugging at the cost of a few extra gates
							end if;
							-- On Rev2 boards, Set the address early so it is stable when SPI_CS is enabled. This is to prevent glitches on the device CS.
--							if FIRST_BIT='1' and REV0='0' then
							SPI_ADDR<=CTRL_FLAG_ADDR(2 downto 0);
--							end if;
						elsif PHASE=1 then
							if FIRST_BIT='1' then
									-- if REV0='1' then -- If Rev0 board
									-- 	SPI_ADDR<=CTRL_FLAG_ADDR(2 downto 0);
									-- 	PLL_LE<=not CTRL_FLAG_ADDR(3);
									-- else -- if Rev2 board
								SPI_CS_N(to_integer(SPI_PORT)) <= '0'; -- activate SPI_CS to enable the device CS
									-- end if;
							end if;

						elsif PHASE=2 then -- SCK goes up on this clock
							if FIRST_BIT='1' then
								RX_REGISTER<=(others=>'0');
							else
								RX_REGISTER<=RX_REGISTER SLL 1; -- left shift RX register while shifting in received SPI data. The last bit (LSB) will be in bit 0.
							end if;
							RX_REGISTER((3-to_integer(CTRL_FLAG_BYTES))*8) <= SPI_MISO(to_integer(SPI_PORT)); -- Override pervious assigmnet: insert received bit in the word at the correct position to make sure the received data is in the Most significant bits

						else -- Phase =3  -- The ADC needs the CS to be disabled 1/4 clk after last rising edge
							FIRST_BIT<='0';
							BIT_CTR<=BIT_CTR-1;

							if(BIT_CTR=1) then -- if we transmitted the last bit
								READY<='1';
									-- if REV0='1' then -- On Rev0 boards
									-- 	SPI_ADDR<=CTRL_FLAG_DEFAULT_ADDR;
									-- 	-- The PLL LE is disabled later
									-- elsif ALT_TIMING='0' then
								SPI_CS_N <= (others=>'1'); -- disable SPI_CS, which disables all CS
									-- end if;
							end if;
						end if; --PHASE=0,1,2,3
					end if; -- BIT_CTR=0

				end if; --CE=1
			end if; -- if synchronous RST
		end if; -- CLK

	end process;


end Behavioral;

