----------------------------------------------------------------------------------
-- @file
-- Company: McGill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    2015-07-20
-- Design Name: chFPGA
-- Module Name:    CHAN_ALIGN
-- Project Name: CHIME
-- Target Devices: K7
-- Tool versions: Vivado 2015.1
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_misc.ALL; -- for and_reduce

library UNISIM;
use UNISIM.VComponents.all;
use work.chFPGA_Package.all; -- Get all component definitions
use work.ip_package.all; -- Import definition of components used in this module

------- CHAN_ALIGN ENTITY DECLARATION ----------------------
--! @brief Align data from all the channelizers.
--!
entity CHAN_ALIGN is
	GENERIC (
		NUMBER_OF_LANES: INTEGER --! Number of channelizer lanes to align
		);
	PORT (
		s_axis_tvalid: in slv(0 to NUMBER_OF_LANES-1);
		s_axis_tdata: in slv32_array(0 to NUMBER_OF_LANES-1);
		s_axis_tlast: in slv(0 to NUMBER_OF_LANES-1);
		s_axis_tuser: in slv4_array(0 to NUMBER_OF_LANES-1) := (others=> (others=>'0'));

		-- Output interface (non-blocking, i.e. always sends data)
		m_axis_tvalid: out slv(0 to NUMBER_OF_LANES-1);
		m_axis_tdata: out slv32_array(0 to NUMBER_OF_LANES-1);
		m_axis_tlast: out slv(0 to NUMBER_OF_LANES-1);
		m_axis_tuser: out slv4_array(0 to NUMBER_OF_LANES-1);

		m_axis_global_tvalid: out std_logic; --! Active high when data is present on the longest frame. Check the individual lane's tvalid to see if a lane ended up prematurely.
		m_axis_global_tlast: out std_logic; --! Active high on the last word of the longest frame.

		lane_monitor: out slv(0 to NUMBER_OF_LANES-1);
		lane_monitor_source: in std_logic_vector(3 downto 0);

		reset_stats: in std_logic;
		overflow: out slv(0 to NUMBER_OF_LANES-1);
		-- missing_frame: out slv(0 to NUMBER_OF_LANES-1);
		in_frame_ctr: out slv8_array(0 to NUMBER_OF_LANES-1);
		out_frame_ctr: out slv8_array(0 to NUMBER_OF_LANES-1);

		clk: in std_logic;
		rst : in STD_LOGIC --! Synchronous  reset synchronized to CLK
	);


end CHAN_ALIGN;

--- ARCHITECTURE DECLARATION and DEFINITION ---------------------
--! Describes the logic that implement the entity's functionnalities. See this architecture for the implementation details.
architecture Behavioral of CHAN_ALIGN is

signal s_axis_tfirst: slv(0 to NUMBER_OF_LANES-1);
signal fifo_din:      slv36_array(0 to NUMBER_OF_LANES-1);
signal fifo_dout:     slv36_array(0 to NUMBER_OF_LANES-1);
signal fifo_wr_en:    slv(0 to NUMBER_OF_LANES-1);
signal fifo_rd_en:    slv(0 to NUMBER_OF_LANES-1);
-- signal fifo_empty:    slv(0 to NUMBER_OF_LANES-1);
signal fifo_tvalid:    slv(0 to NUMBER_OF_LANES-1);
signal fifo_overflow: slv(0 to NUMBER_OF_LANES-1);

signal fifo_tdata:      slv32_array(0 to NUMBER_OF_LANES-1);
signal fifo_tuser:      slv4_array(0 to NUMBER_OF_LANES-1);
signal fifo_tlast:      slv(0 to NUMBER_OF_LANES-1);
signal fifo_tfirst:      slv(0 to NUMBER_OF_LANES-1);

signal all_valid: std_logic;

signal fifo_overflow_int: slv(0 to NUMBER_OF_LANES-1);
signal in_frame_ctr_int: slv8_array(0 to NUMBER_OF_LANES-1);
signal out_frame_ctr_int:slv8_array(0 to NUMBER_OF_LANES-1);

begin


fifogen: for i in 0 to NUMBER_OF_LANES-1 generate

	fifo_din(i)(35 downto 33) <= s_axis_tuser(i)(3 downto 1);
	fifo_din(i)(32) <= s_axis_tlast(i);
	fifo_din(i)(31 downto 0) <= s_axis_tdata(i);
	fifo_wr_en(i) <= s_axis_tvalid(i);

	fifo0: entity work.shuffle_crossbar_align_fifo
		PORT MAP (
			din          => fifo_din(i),
			wr_en        => fifo_wr_en(i),
			full         => open,
			overflow     => fifo_overflow(i),

			dout         => fifo_dout(i),
			valid        => fifo_tvalid(i),
			rd_en        => fifo_rd_en(i),
			empty        => open,
			almost_empty => open,
			clk          => clk,
			srst         => rst
		);

		fifo_tuser(i)(3 downto 1) <= fifo_dout(i)(35 downto 33);
		fifo_tuser(i)(0)          <= '0';
		fifo_tlast(i)             <= fifo_dout(i)(32);
		fifo_tdata(i)             <= fifo_dout(i)(31 downto 0);

end generate;


all_valid <= and_reduce(fifo_tvalid); -- We are ready to read when all FIFOs have valid data. NOTE: This extends one extra clock as data is valid one extra clock since tvalid is delayed
fifo_rd_en <= (others=> all_valid);

-- output signals
-- missing_frame <= (others => '0');
out_frame_ctr <= out_frame_ctr_int;
in_frame_ctr <= in_frame_ctr_int;
overflow <= fifo_overflow_int;

outpipe_proc: process(clk)
	begin
		-- Pipeline the output
		if rising_edge(clk) then
			m_axis_tvalid <= (others => all_valid);
			m_axis_tdata <= fifo_tdata;
			m_axis_tuser <= fifo_tuser;
			m_axis_tlast <= fifo_tlast;
			m_axis_global_tvalid <= all_valid;
			m_axis_global_tlast <= fifo_tlast(0);

			for i in 0 to NUMBER_OF_LANES-1 loop
				if rst='1' then
					s_axis_tfirst(i) <= '1';
				elsif s_axis_tvalid(i)='1' then
					s_axis_tfirst(i) <= s_axis_tlast(i);
				end if;

				if rst='1' then
					fifo_tfirst(i) <= '1';
				elsif fifo_tvalid(i)='1' and fifo_rd_en(i)='1' then
					fifo_tfirst(i) <= fifo_tlast(i);
				end if;

				-- if s_axis_tvalid(0)='1' and s_axis_tfirst(0)='1' then
				-- 	align_pulse(i) <= '1';
				-- elsif s_axis_tvalid(i)='1' and s_axis_tfirst(i)='1' then
				-- 	align_pulse(i) <= '0';
				-- end if;
			end loop;


			case to_integer(unsigned(lane_monitor_source)) is
				when 0 =>
					lane_monitor <= (
						0 => all_valid,
						1 => rst,
						2 => fifo_tvalid(0),
						3 => fifo_tfirst(0),
						4 => fifo_tlast(0),
						others => '0');
				when 1 =>
					lane_monitor <= s_axis_tvalid and s_axis_tfirst;
				when 2 =>
					lane_monitor <= s_axis_tvalid and s_axis_tlast;
				when 3 =>
					lane_monitor <= fifo_overflow;
				when 4 =>
					lane_monitor <= fifo_tvalid;
				when 5 =>
					lane_monitor <= fifo_tvalid and fifo_tfirst;
				when 6 =>
					lane_monitor <= fifo_tvalid and fifo_tlast;
				when 7 =>
					lane_monitor <= s_axis_tvalid;
				when others =>
					lane_monitor <= (others => '0');
			end case;


			for i in 0 to NUMBER_OF_LANES-1 loop
				-- Gather statistics
				if reset_stats='1' then
					fifo_overflow_int(i) <= '0';
				else
					fifo_overflow_int(i) <= fifo_overflow_int(i) or fifo_overflow(i);
				end if;

				if reset_stats='1' then
					out_frame_ctr_int(i) <= (others=>'0');
				elsif all_valid='1' and fifo_tlast(i)='1'  then  -- if end of frame
					out_frame_ctr_int(i) <= to_slv(unsigned(out_frame_ctr_int(i)) + 1);
				end if;

				if reset_stats='1' then
					in_frame_ctr_int(i) <= (others=>'0');
				elsif s_axis_tvalid(i)='1' and s_axis_tlast(i)='1'  then  -- if end of frame
					in_frame_ctr_int(i) <= to_slv(unsigned(in_frame_ctr_int(i)) + 1);
				end if;
			end loop;

		end if; --clk

	end process;



end Behavioral;

