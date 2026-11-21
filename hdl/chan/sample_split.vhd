----------------------------------------------------------------------------------
-- Split-sample stage between the channelizers and the corner-turn engine.
--
-- The correlator takes (4+4)-bit values. This stage gives it values of nearly 7 bits from half of
-- the channelizers: each wide value is sent as two parts, each on one correlator input. The host
-- makes the products of the wide values from the products of the parts.
--
-- Default mode (split_mode = '0'): each lane passes the (4+4)-bit value of its channelizer, which
-- is in the 4 MSBs of each component of the input word. The output is the same as without this stage.
--
-- Split mode (split_mode = '1'): the first NUMBER_OF_LANES / 2 channelizers must send 8-bit
-- components (two's complement). For each component:
--
--     w = the component, saturated to -60 ... 59
--     t = w + 4
--     high = t(6 downto 3)                              -7 ... 7
--     low  = (not t(2)) & t(1 downto 0), sign-extended  -4 ... 3
--     so that w = 8 * high + low. No part is ever -8.
--
-- Wide input i (channelizer i) drives output lane 2i with ``high`` and lane 2i + 1 with ``low``. The
-- two parts of a sample are in the same word, so they are in the same frame and bin in the correlator.
--
-- A change of split_mode takes effect at the end of a frame (tlast of lane 0): a frame has one mode
-- only. All the lanes have a latency of 2 clocks in the two modes. The valid, last and user signals
-- of each lane pass with the same latency.
--
-- sat_count(i) counts the words of wide input i in which a component was saturated (it stops at
-- 65535). It is cleared by sat_count_reset.
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

library work;
use work.chFPGA_Package.ALL;

entity sample_split is
	generic (
		NUMBER_OF_LANES: integer := 8; -- channelizers, and correlator inputs
		BINS_PER_WORD: integer := 4
	);
	port (
		-- From the channelizers: components of 8 bits. From MSB to LSB: Re(N), Im(N), Re(N+1), Im(N+1)...
		s_axis_tdata  : in slv_array(0 to NUMBER_OF_LANES - 1)(16 * BINS_PER_WORD - 1 downto 0);
		s_axis_tuser  : in slv_array(0 to NUMBER_OF_LANES - 1)(3 downto 0);
		s_axis_tvalid : in std_logic_vector(0 to NUMBER_OF_LANES - 1);
		s_axis_tlast  : in std_logic_vector(0 to NUMBER_OF_LANES - 1);

		-- To the corner-turn engine: components of 4 bits, in the same order
		m_axis_tdata  : out slv_array(0 to NUMBER_OF_LANES - 1)(8 * BINS_PER_WORD - 1 downto 0);
		m_axis_tuser  : out slv_array(0 to NUMBER_OF_LANES - 1)(3 downto 0);
		m_axis_tvalid : out std_logic_vector(0 to NUMBER_OF_LANES - 1) := (others => '0');
		m_axis_tlast  : out std_logic_vector(0 to NUMBER_OF_LANES - 1);

		split_mode      : in std_logic; -- synchronous to clk
		sat_count       : out slv_array(0 to NUMBER_OF_LANES / 2 - 1)(15 downto 0);
		sat_count_reset : in std_logic;

		clk : in std_logic;
		rst : in std_logic
	);
end entity sample_split;

architecture impl of sample_split is
	constant COMPONENTS: integer := 2 * BINS_PER_WORD;
	constant WIDE: integer := NUMBER_OF_LANES / 2;

	type t_array is array (0 to WIDE - 1, 0 to COMPONENTS - 1) of signed(6 downto 0);
	signal mode, mode1: std_logic := '0'; -- mode of the frame on the input, and of the word in stage 1
	signal t1: t_array; -- w + 4
	signal sat1: std_logic_vector(0 to WIDE - 1);
	signal narrow1: slv_array(0 to NUMBER_OF_LANES - 1)(8 * BINS_PER_WORD - 1 downto 0); -- the 4 MSBs of each component
	signal tuser1: slv_array(0 to NUMBER_OF_LANES - 1)(3 downto 0);
	signal tvalid1, tlast1: std_logic_vector(0 to NUMBER_OF_LANES - 1) := (others => '0');
	signal sat_ctr: unsigned_array(0 to WIDE - 1)(15 downto 0) := (others => (others => '0'));
begin
	split_proc: process(all)
		variable v: signed(7 downto 0);
		variable sat: std_logic;
		variable t: signed(6 downto 0);
		variable low: std_logic_vector(3 downto 0);
	begin
		if rising_edge(clk) then
			-- Stage 1: saturation of the wide values, and the 4 MSBs of all the components
			for l in 0 to NUMBER_OF_LANES - 1 loop
				for c in 0 to COMPONENTS - 1 loop
					narrow1(l)(4 * c + 3 downto 4 * c) <= s_axis_tdata(l)(8 * c + 7 downto 8 * c + 4);
				end loop;
			end loop;
			for i in 0 to WIDE - 1 loop
				sat := '0';
				for c in 0 to COMPONENTS - 1 loop
					v := signed(s_axis_tdata(i)(8 * c + 7 downto 8 * c));
					if v > 59 then
						t1(i, c) <= to_signed(59 + 4, 7);
						sat := '1';
					elsif v < -60 then
						t1(i, c) <= to_signed(-60 + 4, 7);
						sat := '1';
					else
						t1(i, c) <= resize(v, 7) + 4;
					end if;
				end loop;
				sat1(i) <= sat and s_axis_tvalid(i) and mode;
			end loop;
			tuser1 <= s_axis_tuser;
			tvalid1 <= s_axis_tvalid;
			tlast1 <= s_axis_tlast;
			mode1 <= mode;
			if s_axis_tvalid(0) = '1' and s_axis_tlast(0) = '1' then
				mode <= split_mode; -- the next frame
			end if;

			-- Stage 2: the two parts of the wide values, or the narrow values
			m_axis_tdata <= narrow1;
			if mode1 then
				for i in 0 to WIDE - 1 loop
					for c in 0 to COMPONENTS - 1 loop
						t := t1(i, c);
						low := (not t(2)) & (not t(2)) & std_logic_vector(t(1 downto 0));
						m_axis_tdata(2 * i)(4 * c + 3 downto 4 * c) <= std_logic_vector(t(6 downto 3));
						m_axis_tdata(2 * i + 1)(4 * c + 3 downto 4 * c) <= low;
					end loop;
				end loop;
			end if;
			m_axis_tuser <= tuser1;
			m_axis_tvalid <= tvalid1;
			m_axis_tlast <= tlast1;

			for i in 0 to WIDE - 1 loop
				if sat_count_reset then
					sat_ctr(i) <= (others => '0');
				elsif sat1(i) = '1' and sat_ctr(i) /= X"FFFF" then
					sat_ctr(i) <= sat_ctr(i) + 1;
				end if;
			end loop;

			if rst then
				mode <= '0';
				mode1 <= '0';
				tvalid1 <= (others => '0');
				m_axis_tvalid <= (others => '0');
			end if;
		end if;
	end process split_proc;

	sat_gen: for i in 0 to WIDE - 1 generate
		sat_count(i) <= std_logic_vector(sat_ctr(i));
	end generate sat_gen;
end architecture impl;
