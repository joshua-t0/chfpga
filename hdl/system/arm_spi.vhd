library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity arm_spi is port (
	clk : in std_logic;
	reset : in std_logic;

	sck : in std_logic;
	miso : out std_logic;
	mosi : in std_logic;
	cs_n : in std_logic;

	addr : out std_logic_vector(31 downto 0);
	din : in std_logic_vector(31 downto 0);
	dout : out std_logic_vector(31 downto 0);
	wreq, rreq : out std_logic;
	wack, rack : in std_logic
);
end arm_spi;

architecture behav of arm_spi is

	-- Shift registers
	signal sck_dly : std_logic_vector(1 to 3) := (others => '0');
	signal sck_rising, sck_falling : std_logic := '0';
	signal spi_read_counter : unsigned(5 downto 0) := (others => '0');

	signal mosi_dly : std_logic := '0';

	signal mosi_shreg, miso_shreg_in : std_logic_vector(31 downto 0) := (others => '0');
	signal miso_shreg : std_logic_vector(30 downto 0) := (others => '0');
	signal bit_count : unsigned(4 downto 0) := (others => '0');
	signal word_strobe, miso_shreg_ld : std_logic := '0';

	-- Byte-wide state machine
	type SPI_STATE_TYPE is (SPI_IDLE, SPI_A, SPI_R1, SPI_R2, SPI_W, SPI_MW1, SPI_MW2);
	signal spi_state : SPI_STATE_TYPE := SPI_IDLE;

	signal read_latched, write_latched : std_logic_vector(31 downto 0) := (others => '0');

begin

	shreg_proc : process(all) begin
		if rising_edge(clk) then

			sck_dly <= sck & sck_dly(1 to sck_dly'high-1);
			mosi_dly <= mosi;
			word_strobe <= '0';

			if reset='1' or cs_n='1' then
				-- Idle state; everything held in
				-- reset.
				mosi_shreg <= (others => '0');
				miso_shreg <= (others => '0');
				bit_count <= (others => '0');
				miso <= '0';
			else
				if miso_shreg_ld='1' then
					-- Load when commanded.
					miso_shreg <= miso_shreg_in(miso_shreg'range);
					miso <= miso_shreg_in(31);
				end if;

				-- On rising clock edges, sample MOSI and update MISO. Strobe
				-- when done.
				if sck_dly="100" then
					mosi_shreg <= mosi_shreg(30 downto 0) & mosi_dly;
					bit_count <= bit_count + 1;

					if bit_count=31 then
						word_strobe <= '1';
					else
						miso <= miso_shreg(30);
					end if;

					miso_shreg <= miso_shreg(29 downto 0) & '0';
				end if;
			end if;

		end if;
	end process;

	state_proc : process(all) begin
		if rising_edge(clk) then

			rreq <= '0';
			wreq <= '0';
			spi_read_counter <= (others => '0');

			miso_shreg_ld <= '0';

			if reset='1' or cs_n='1' then
				spi_state <= SPI_IDLE;
				addr <= (others => '0');
				dout <= (others => '0');
			else

				case spi_state is
					when SPI_IDLE =>
						-- Here, we've latched the entire address. We
						-- diverge depending on the operation: for reads,
						-- we need to dispatch them immediately.
						if word_strobe='1' then
							addr <= mosi_shreg(31 downto 2) & "00";
							case mosi_shreg(1 downto 0) is
								when "00" =>
									-- read! Dispatch immediately.
									rreq <= '1';
									spi_state <= SPI_R1;
								when "01" =>
									-- write
									spi_state <= SPI_W;
								when "10" =>
									-- masked write! Dispatch read.
									rreq <= '1';
									spi_state <= SPI_MW1;
								when others => -- eek!
									spi_state <= SPI_IDLE;
							end case;
						end if;

					--
					-- Reads
					--
					when SPI_R1 =>
						-- Wait for RACK. This needs to happen
						-- quickly enough that the SPI bus has not
						-- started transferring and will miss bits as
						-- a result.
						spi_read_counter <= spi_read_counter + 1;

						if rack='1' then
							miso_shreg_in <= din;
							miso_shreg_ld <= '1';
							spi_state <= SPI_R2;
						elsif spi_read_counter = (spi_read_counter'range => '1') then
							miso_shreg_in <= x"deaddead";
							miso_shreg_ld <= '1';
							spi_state <= SPI_R2;
						end if;

					when SPI_R2 =>
						if word_strobe='1' then
							spi_state <= SPI_IDLE;
						end if;

					--
					-- Writes
					--
					when SPI_W =>
						-- Dispatch the write. TODO: timeouts and
						-- listen for wack?
						if word_strobe='1' then
							dout <= mosi_shreg;
							wreq <= '1';
							spi_state <= SPI_IDLE;
						end if;

					--
					-- Masked write
					--

					when SPI_MW1 =>
						-- receive data word from SPI, complete internal read
						if rack='1' then
							read_latched <= din;
						end if;

						if word_strobe='1' then
							write_latched <= mosi_shreg;
							spi_state <= SPI_MW2;
						end if;

					when SPI_MW2 =>
						-- receive mask word from SPI
						if word_strobe='1' then
							dout <= (write_latched and mosi_shreg) or
									(read_latched and not mosi_shreg);
							wreq <= '1';
							spi_state <= SPI_IDLE;
						end if;

					when others =>
						spi_state <= SPI_IDLE;
				end case;
			end if;
		end if;
	end process;
end behav;

-- vim: ts=4 sts=4

