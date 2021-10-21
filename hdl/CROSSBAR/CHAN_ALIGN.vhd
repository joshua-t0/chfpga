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
--use work.ip_package.all; -- Import definition of components used in this module

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

		lane_monitor: out slv(0 to max(NUMBER_OF_LANES, 16)-1);
		lane_monitor_source: in std_logic_vector(3 downto 0);

		reset_stats: in std_logic;
		overflow: out slv(0 to NUMBER_OF_LANES-1);
		-- missing_frame: out slv(0 to NUMBER_OF_LANES-1);
		in_frame_ctr: out slv8_array(0 to NUMBER_OF_LANES-1);
		out_frame_ctr: out slv8_array(0 to NUMBER_OF_LANES-1);

		clk: in std_logic;
		rst : in std_logic --! Synchronous  reset synchronized to CLK
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
signal fifo_empty: slv(0 to NUMBER_OF_LANES-1);
signal fifo_full: slv(0 to NUMBER_OF_LANES-1);
signal fifo_almost_full: slv(0 to NUMBER_OF_LANES-1);
signal fifo_almost_empty: slv(0 to NUMBER_OF_LANES-1);

signal fifo_tdata:      slv32_array(0 to NUMBER_OF_LANES-1);
signal fifo_tuser:      slv4_array(0 to NUMBER_OF_LANES-1);
signal fifo_tlast:      slv(0 to NUMBER_OF_LANES-1);
signal fifo_tfirst:      slv(0 to NUMBER_OF_LANES-1);
signal fifo_data_count:      slv10_array(0 to NUMBER_OF_LANES-1);

signal fifo_rst_ctr : unsigned(3 downto 0); -- 16-clk FIFO reset cycle
signal fifo_rst: std_logic;
signal fifo_inhibit: std_logic;

signal all_valid: std_logic;

signal fifo_overflow_int: slv(0 to NUMBER_OF_LANES-1);
signal in_frame_ctr_int: slv8_array(0 to NUMBER_OF_LANES-1);
signal out_frame_ctr_int:slv8_array(0 to NUMBER_OF_LANES-1);
signal reset_ctr: unsigned(NUMBER_OF_LANES-1 downto 0);


signal tvalid_during_reset:      slv(0 to NUMBER_OF_LANES-1);
signal rst_detect: std_logic := '0';
signal rst_dly: std_logic;

begin


fifogen: for i in 0 to NUMBER_OF_LANES-1 generate

	fifo_din(i)(35 downto 33) <= s_axis_tuser(i)(3 downto 1);
	fifo_din(i)(32) <= s_axis_tlast(i);
	fifo_din(i)(31 downto 0) <= s_axis_tdata(i);
	fifo_wr_en(i) <= s_axis_tvalid(i) and not fifo_inhibit;

	fifo0: entity work.shuffle_crossbar_align_fifo
		PORT MAP (
			din          => fifo_din(i),
			wr_en        => fifo_wr_en(i),
			full         => fifo_full(i),
			overflow     => fifo_overflow(i),

			dout         => fifo_dout(i),
			valid        => fifo_tvalid(i),
			rd_en        => fifo_rd_en(i),
			empty        => fifo_empty(i),
			almost_empty => fifo_almost_empty(i),
			almost_full  => fifo_almost_full(i),
			data_count => fifo_data_count(i),
			clk          => clk,
			srst         => fifo_rst
		);

		fifo_tuser(i)(3 downto 1) <= fifo_dout(i)(35 downto 33);
		fifo_tuser(i)(0)          <= '0';
		fifo_tlast(i)             <= fifo_dout(i)(32);
		fifo_tdata(i)             <= fifo_dout(i)(31 downto 0);

	--fifo_rd_en(i) <= fifo_tvalid(i) and not fifo_inhibit;
	fifo_rd_en(i) <= all_valid;

end generate;


all_valid <= and_reduce(fifo_tvalid) and not fifo_inhibit; -- We are ready to read when all FIFOs have valid data. NOTE: This extends one extra clock as data is valid one extra clock since tvalid is delayed


----------------------
-- FIFO reset process.
----------------------
-- According to the user manual, for Async FIFOs, reset
-- must be held for 31 clocks of the slowest clk (in_clk) when there is no safety circuit, and there must be no
-- read or write during that period. There does not seem to be a safety circuit from the core generator GUI.
fifo_rst_proc: process(clk)
    begin
        if rising_edge(clk) then
            if rst ='1' then
                fifo_inhibit <='1';
                fifo_rst_ctr <= (others => '0'); -- this is a 5-bit counter
            elsif signed(fifo_rst_ctr) = -1 then
                fifo_inhibit <= '0';
            else
            	fifo_rst_ctr <= fifo_rst_ctr + 1;
	            if fifo_rst_ctr = 5 then
	   	                fifo_rst <= '1';
	            elsif signed(fifo_rst_ctr) = -5 then
	   	                fifo_rst <= '0';
  				end if;
            end if; --reset
			rst_dly <= rst;

          	if rst='1' and rst_dly='0' then
            	reset_ctr <= reset_ctr + 1;
            end if;
        end if; --clk
    end process;

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

				-- detect if a reset has occured at all
				if rst='1' then
					rst_detect <= '1';
				end if;
				if rst='1' then
					fifo_tfirst(i) <= '1';
				elsif fifo_tvalid(i)='1' and fifo_rd_en(i)='1' then
					fifo_tfirst(i) <= fifo_tlast(i);
				end if;

				if s_axis_tvalid(i) = '1' and rst='1' then
					tvalid_during_reset(i) <= '1';
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
						5 => rst_detect,
						6 => fifo_inhibit,
						7 => fifo_rst,
						others => '0');
				when 1 =>
					lane_monitor(0 to NUMBER_OF_LANES-1) <= s_axis_tvalid and s_axis_tfirst;
				when 2 =>
					lane_monitor(0 to NUMBER_OF_LANES-1) <= s_axis_tvalid and s_axis_tlast;
				when 3 =>
					lane_monitor(0 to NUMBER_OF_LANES-1) <= fifo_overflow;
				when 4 =>
					lane_monitor(0 to NUMBER_OF_LANES-1) <= fifo_tvalid;
				when 5 =>
					lane_monitor(0 to NUMBER_OF_LANES-1) <= fifo_tvalid and fifo_tfirst;
				when 6 =>
					lane_monitor(0 to NUMBER_OF_LANES-1) <= fifo_tvalid and fifo_tlast;
				when 7 =>
					lane_monitor(0 to NUMBER_OF_LANES-1) <= s_axis_tvalid;
				when 8 =>
					lane_monitor(0 to NUMBER_OF_LANES-1) <= tvalid_during_reset;
				when 9 =>
					lane_monitor(0 to NUMBER_OF_LANES-1) <= fifo_empty;
				when 10 =>
					lane_monitor(0 to NUMBER_OF_LANES-1) <= fifo_full;
				when 11 =>
					lane_monitor(0 to NUMBER_OF_LANES-1) <= fifo_almost_full;
				when 12 =>
					lane_monitor(0 to NUMBER_OF_LANES-1) <= fifo_almost_empty;
				when 13 =>
					lane_monitor(0 to NUMBER_OF_LANES-1) <= slv(reset_ctr);
				when 14 =>
					for i in 0 to NUMBER_OF_LANES-1 loop
						lane_monitor(i) <= fifo_data_count(i)(8);
					end loop;
				when 15 =>
					for i in 0 to NUMBER_OF_LANES-1 loop
						lane_monitor(i) <= fifo_data_count(i)(9);
					end loop;
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
				elsif fifo_tvalid(i)='1'  then  -- if end of frame
				--elsif all_valid='1' and fifo_tlast(i)='1'  then  -- if end of frame
					out_frame_ctr_int(i) <= to_slv(unsigned(out_frame_ctr_int(i)) + 1);
				end if;

				if reset_stats='1' then
					in_frame_ctr_int(i) <= (others=>'0');
				elsif s_axis_tvalid(i)='1' and s_axis_tlast(i)='1'  then  -- if end of frame
					in_frame_ctr_int(i) <= to_slv(unsigned(in_frame_ctr_int(i)) + 1);
				end if;
				in_frame_ctr_int(i) <= fifo_data_count(i)(7 downto 0);
				--in_frame_ctr_int(i)(15 downto 10) <= (others=>'0');

			end loop;

		end if; --clk

	end process;



end Behavioral;

