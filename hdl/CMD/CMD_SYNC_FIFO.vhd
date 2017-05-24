----------------------------------------------------------------------------------
--! @file
-- Company: McGill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    2012-10-17
-- Design Name:
-- Module Name:    CTRL_FIFO - Behavioral
-- Project Name: CHIME PoC
-- Target Devices: Virtex 6 or 7 series
-- Tool versions: ISE 14.2
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 	2012-10-17 JFC: Created

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

library work;
use work.chFPGA_Package.all; -- Get all component definitions
use work.ip_package.all; -- Import definition of components used in this module



--! @brief Implements a shallow FIFO for the command system from A to B
entity CTRL_FIFO is
	GENERIC (
		DATA_WIDTH: integer := 8;
		USER_WIDTH: integer := 0
		);
     PORT (
		-- Command streams from single slave input to multiple master outputs
		s_axis_tdata: in std_logic_vector(DATA_WIDTH-1 downto 0);
		s_axis_tuser: in std_logic_vector(USER_WIDTH-1 downto 0) := (others=>'0'); -- optional user fields
		s_axis_tvalid: in std_logic;
		s_axis_tlast: in std_logic;
		s_axis_tready: out std_logic;

		m_axis_tdata:  out std_logic_vector(DATA_WIDTH-1 downto 0);
		m_axis_tuser:  out std_logic_vector(USER_WIDTH-1 downto 0);
		m_axis_tvalid: out std_logic;
		m_axis_tlast:  out std_logic;
		m_axis_tready: in std_logic;

		clk: in std_logic;
		rst: in std_logic
		);

end CTRL_FIFO;


architecture Behavioral of CTRL_FIFO is

	signal m_axis_tdata_int: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal m_axis_tuser_int: std_logic_vector(USER_WIDTH-1 downto 0);
	signal m_axis_tvalid_int: std_logic;
	signal m_axis_tlast_int: std_logic;

	signal overflow_tdata: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal overflow_tuser: std_logic_vector(USER_WIDTH-1 downto 0);
	signal overflow_tvalid: std_logic;
	signal overflow_tlast: std_logic;

begin

s_axis_tready <= s_axis_tready_int;
m_axis_tdata <= m_axis_tdata_int;
m_axis_tuser <= m_axis_tuser_int;
m_axis_tvalid <= m_axis_tvalid_int;
m_axis_tlast <= m_axis_tlast_int;

fifo_proc: process(clk)
	variable dest_ready: std_logic;
begin
	if rising_edge(clk) then

		dest_ready := m_axis_tready or not m_axis_tdata_int;

		s_axis_tready <= dest_ready;

		-- Read from input or from overflow
		if dest_ready='1' then
			if overflow_tvalid='1' then
				m_axis_tdata_int<=overflow_tdata;
				m_axis_tuser_int<=overflow_tuser;
				m_axis_tlast_int<=overflow_tlast;
				m_axis_tvalid_int<='1';
				overflow_tvalid <='0'; -- is overriden below if we write data at the same time we read it
			else
				m_axis_tdata_int <= s_axis_tdata;
				m_axis_tuser_int <= s_axis_tuser;
				m_axis_tlast_int <= s_axis_tlast;
				m_axis_tvalid_int <= s_axis_tready and s_axis_tvalid;
			end if;
		end if;

		--Write to overflow. This block has to come after the read block because we override the overflow register.
		if s_axis_tvalid='1' and s_axis_tready_int='1' then -- if we accept a word
			if dest_ready='0' or overflow_tvalid='1' then -- if destination not ready to accept a word, or if there is a valid overflow word
				overflow_tdata <= s_axis_tdata;
				overflow_tuser <= s_axis_tuser;
				overflow_tlast <= s_axis_tlast;
				overflow_tvalid <= '1';
			end if;
		end if;

		if rst='1' then
			overflow_tvalid<='0';
			m_axis_tvalid_int<='0';
			s_axis_tready <= '0';
		end if; -- rst

	end if; --clk

end process;


end Behavioral;

