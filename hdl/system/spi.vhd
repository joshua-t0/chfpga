----------------------------------------------------------------------------------
-- Company: Mc Gill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    13:01:47 05/18/2011
-- Design Name:
-- Module Name:    SYNC_SPI - impl
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description: Implements a simple SPI interface
--
-- Dependencies:
--
-- Revision:
--   2011-08-25 JFC: Added SPI_CLK_ENABLE flag to stop the SPI clock
--   2012-04-04 JFC: Changed to synchrounous reset to eliminate unwanted latch
--   2013-08-16 JFC: Cleanup. Removed REV0.

----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.chFPGA_Package.ALL; -- Get all component definitions

entity spi is
	generic (
		NUMBER_OF_PORTS: integer; -- Number of SPI devices on the buse. Determines the number of MISO and CS lines.
		CLK_DIVIDE_FACTOR: integer := 200 / 4 -- SPI clock speed, where actual bit rate = 200 MHz / CLK_DIVIDE_FACTOR / 4
	);
	port (
		-- BSB Control interface

		ctrl_cmd_in_dat: in    AXIS8_DAT_STRUCT; -- Command stream input, signals from master (Data, Valid, Last)
		ctrl_cmd_in_rdy: out   AXIS8_RDY_STRUCT; -- Command stream input, signals to master (Ready)
		ctrl_rply_out_dat: out AXIS8_DAT_STRUCT; -- Reply stream output, signals to slave (Data, Valid, Last)
		ctrl_rply_out_rdy: in  AXIS8_RDY_STRUCT; -- Reply stream output,  signals from slave (Ready)
		ctrl_clk: in  std_logic;
		ctrl_rst: in std_logic;

		-- SPI signals

		spi_sck: out std_logic; -- SPI clock output
		spi_miso: in std_logic_vector(0 to NUMBER_OF_PORTS - 1); -- Data input from each SPI device
		spi_mosi: out std_logic; -- Data output , common to all slave devices
		spi_cs_n: out std_logic_vector(0 to NUMBER_OF_PORTS - 1); -- Active low chip select signals. Only the bit specified in the SPI port register is active low during the transaction
		-- Address provided to the SPI slave device during a transaction  in addition to the Chip Select signal
		-- for cases where further decoding is needed. This address is set directly in the ADDR bitfield. The value in
		-- the DEFAULT_ADDR bitfield appears on the bus when there is no active transaction.
		spi_addr: out std_logic_vector(2 downto 0);
		spi_rst_n: out std_logic; -- SPI Reset signal directly controlled by a register bitfield

		-- System-level signals

		clk200: in std_logic;
		rst: in std_logic -- Module reset, synchronous to clk200
	);
end entity spi;

architecture impl of spi is

	constant SPI_PORT_WIDTH: integer := width(NUMBER_OF_PORTS);

	--- Control and status bytes
	signal control_bytes: slv8_array(0 to 5); -- default value set in the CMD_SLAVE
	signal status_bytes: slv8_array(0 to 4); -- default value set in the CMD_SLAVE

	signal tx_data: std_logic_vector(31 downto 0);
	signal addr: std_logic_vector(3 downto 0);
	signal default_addr: std_logic_vector(2 downto 0);
	signal bytes: unsigned(1 downto 0);
	signal start_trig: std_logic;
	signal start_trig_previous: std_logic;
	signal spi_reset: std_logic;
	signal spi_clk_enable: std_logic;
	signal alt_timing: std_logic;

	-- SPI State machine signals

	signal clk_ctr: unsigned(7 downto 0); -- Divides the ADC clock by up to 255
	signal ce: std_logic;
	signal start: std_logic;
	signal phase: unsigned(1 downto 0); -- Divides the clock in 4 phases
	signal bit_ctr: unsigned(6 downto 0); -- Counts the bits to transmit/receive. Zero means there is no transmission
	signal tx_register, rx_register: unsigned(31 downto 0) := (others => '0');
	signal ready, first_bit: std_logic;
	signal spi_port: unsigned(SPI_PORT_WIDTH - 1 downto 0);

begin

	-----------------------------------------------------------------------------------
	-- Memory map
	--
	--
	-- -----------------------------------------------------------------------------------------
	-- | Page    |Addr | Bit(s) |     Name               | Description                           |
	-- |---------|-----|-----|-------------------------|---------------------------------------|
	-- | CONTROL | 0-3 | 31:0| tx_data                 | Data to be sent. MSB is in byte 0 and is sent first. |
	-- |         |  4  | 7:4 | addr                    | Address of the SPI device to access. Note that there are only 3 hardware address lines. ADDR[4] is always '0' |
	-- |         |     |  3  | RESET                   | Controls the hardware SPI_RESET (or SPI_RESET_ALT) lines. Is active high. |
	-- |         |     |  2  | start_trig              | A 0-to-1 transition starts the SPI transaction|
	-- |         |     | 1:0 | BYTES                   | Indicates the number of bytes to transfer. 0=1 byte ... 3= 4 bytes. Byte at address 0 is always transmitted first.|
	-- |         |  5  |  7  | (unused)                | |
	-- |         |     | 6:4 | DEFAULT_ADDR            | Address to set on the hardware address lines when a transation is not in progress.|
	-- |         |     |  3  | CLK_EN                  | Enables SPI clock generation. Active High. |
	-- |         |     |  2  | alt_timing              | Uses alternate timing to accomodate the ADC PLL Latch Enable timing, which differs from the standard SPI Chip Enable timing. |
	-- |         |     |  1  | (reserved)              | Might be used to expand the number of SPI ports.|
	-- |         |     |  0  | PORT                    | Indicates to which port the transation will be made. |
	-- | STATUS  | 0-3 | 31:0| RX_DATA                 | Data received during the transation. MSB is in byte 0. MSB is always bit 31 independent of the number of bytes in the transation|
	-- |         |  4  | 7:1 | (unused)                | |
	-- |         |     |  0  | ready                   | Indicates when the transation is completed and is ready to make another one.|
	-- ------------------------------------------------------------------------------

	tx_data                     <= to_slv(control_bytes(0 to 3));

	addr                        <= control_bytes(4)(7 downto 4);
	spi_reset                   <= control_bytes(4)(3);
	start_trig                  <= control_bytes(4)(2);
	bytes                       <= unsigned(control_bytes(4)(1 downto 0));

	default_addr                <= control_bytes(5)(6 downto 4);
	spi_clk_enable              <= control_bytes(5)(3);
	alt_timing                  <= control_bytes(5)(2);
	spi_port                    <= unsigned(control_bytes(5)(SPI_PORT_WIDTH - 1 downto 0));
	status_bytes(0)             <= std_logic_vector(rx_register(31 downto 24));
	status_bytes(1)             <= std_logic_vector(rx_register(23 downto 16));
	status_bytes(2)             <= std_logic_vector(rx_register(15 downto 8));
	status_bytes(3)             <= std_logic_vector(rx_register(7 downto 0));
	status_bytes(4)(7 downto 1) <= (others => '0');
	status_bytes(4)(0)          <= ready;

	spi_mosi  <= tx_register(31);
	spi_rst_n <= not spi_reset;


	bsb_regs0: entity work.bsb_regs
		generic map (
			NUMBER_OF_CONTROL_BYTES => control_bytes'LENGTH(1), -- Length of array in the first dimension: number of bytes
			NUMBER_OF_STATUS_BYTES  => status_bytes'LENGTH(1),
			DEFAULT_CONTROL_BYTES   => X"12345678_73_78"
		)

		port map (
			-- Control interface (command and reply stream buses)
			ctrl_cmd_in_dat   => ctrl_cmd_in_dat,
			ctrl_cmd_in_rdy   => ctrl_cmd_in_rdy,
			ctrl_rply_out_dat => ctrl_rply_out_dat,
			ctrl_rply_out_rdy => ctrl_rply_out_rdy,
			ctrl_clk          => ctrl_clk,
			ctrl_rst          => ctrl_rst,
			control_bytes     => control_bytes,
			status_bytes      => status_bytes
		);

	spiproc: process(clk200) is
	begin
		if rising_edge(clk200) then
			-- synchrounous reset
			if rst = '1' then
				clk_ctr <= (others => '0');
				ce <= '0';
				bit_ctr <= (others => '0');
				phase <= (others => '0');
				ready <= '0';
				start <= '0';
				first_bit <= '0';
				spi_addr <= default_addr;  -- watch out: this was creating a latch if used in an async reset
				spi_cs_n  <= (others => '1');
				start_trig_previous <= '0';
			else
				-- Generate Clock Enable signal at a fraction of the system clock
				if clk_ctr = CLK_DIVIDE_FACTOR - 1 then
					clk_ctr  <= (others => '0');
					ce <= '1';
				else
					clk_ctr <= clk_ctr + 1;
					ce <= '0';
				end if;

				-- Set  the start bit if a 0-to-1 transition is detected on the start_trig bit.
				start_trig_previous <= start_trig;
				if start_trig = '1' and start_trig_previous = '0' then
					start <= '1';
				end if;


				-- Actions taken on the divided clock
				if ce = '1' then
					-- Increment phase counter. This divides every SPI clock cycles into 4 phases
					phase <= phase + 1;

					-- Generate SPI clk. Going down in phase 0 and up in phase 2.
					if phase = 0 then
						spi_sck <= '0';
					elsif phase = 2 and spi_clk_enable = '1' then
						spi_sck <= '1';
					end if;

					if bit_ctr = 0 then -- if we are not transmitting
						if start = '1' and phase = 3 then
							ready <= '0';
							start <= '0'; -- weird since the setting was done outside this group, but the HDL should be able to handle that
							bit_ctr <= to_unsigned((to_integer(bytes) + 1) * 8, bit_ctr'LENGTH); -- "00" = 8 bits, "01" = 16 bits, "10" = 24 bits, "11" = 32 bits
							first_bit <= '1';
						end if;
						-- Disable SPI_CS later if alt_timing=1. This is to accompdate the ADC_PLL whose LE should go inactive later than the standard SPI protocol
						if phase = 1 and alt_timing = '1' then
							spi_cs_n <= (others => '1'); -- Disable PLL latch if is was enabled. That will clock in the data we just sent
						end if;

					else -- We are transmitting and receiving
						if phase = 0 then -- SCK goes down on this clock
							if first_bit = '1' then
								tx_register <= unsigned(tx_data);
							else
								tx_register <= shift_left(tx_register, 1); -- left shift TX register (send MSB first). shift in a '0' to facilitate debugging at the cost of a few extra gates
							end if;
							--  Set the address early so it is stable when SPI_CS is enabled. This is to prevent glitches on the device CS.
							spi_addr <= addr(2 downto 0);
						elsif phase = 1 then
							if first_bit = '1' then
								spi_cs_n(to_integer(spi_port)) <= '0'; -- activate SPI_CS to enable the device CS
							end if;

						elsif phase = 2 then -- SCK goes up on this clock
							if first_bit = '1' then
								rx_register <= (others => '0');
							else
								rx_register <= rx_register sll 1; -- left shift RX register while shifting in received SPI data. The last bit (LSB) will be in bit 0.
							end if;
							-- Override pervious assigmnet: insert received bit in the word at the correct position to make sure the received data is in the Most significant bits
							rx_register((3 - to_integer(bytes)) * 8) <= spi_miso(to_integer(spi_port));

						else -- Phase =3  -- The ADC needs the CS to be disabled 1/4 clk after last rising edge
							first_bit <= '0';
							bit_ctr <= bit_ctr - 1;

							if bit_ctr = 1  then -- if we transmitted the last bit
								ready <= '1';
								spi_cs_n <= (others => '1'); -- disable SPI_CS, which disables all CS
							end if;
						end if; -- phase=0,1,2,3
					end if; -- bit_ctr=0

				end if; -- ce=1
			end if; -- if synchronous rst
		end if; -- CLK
	end process;

end architecture impl;

