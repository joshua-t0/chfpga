library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.chFPGA_Package.all; -- Get all component definitions


-- Converts a 32-bit wide AXI-Streaming master/slave pair into a 8-bit-wide
-- AXI-Streaming master/slave pair, which is used by the Byte-Serial-Bus (BSB)
-- interfacing protocol
entity axis_to_bsb is
    PORT (


		-- AXIS 32-bit wide interface

		-- Command input stream
		s_axis_tdata: in std_logic_vector(31 downto 0);
		s_axis_tvalid: in std_logic;
		s_axis_tlast: in std_logic;
		s_axis_tready: out std_logic;

		-- Reply output stream
		m_axis_tdata: out std_logic_vector(31 downto 0);
		m_axis_tvalid: out std_logic;
		m_axis_tlast: out std_logic;
		m_axis_tready: in std_logic;

		-- BSB (AXIS 8-bit-wide) interface

		-- Reply input stream
		s_bsb_axis_tdata: in std_logic_vector(7 downto 0);
		s_bsb_axis_tvalid: in std_logic;
		s_bsb_axis_tlast: in std_logic;
		s_bsb_axis_tready: out std_logic;
		s_bsb_axis_tuser: in std_logic_vector(1 downto 0) := "00";

		-- Command output stream
		m_bsb_axis_tdata: out std_logic_vector(7 downto 0);
		m_bsb_axis_tvalid: out std_logic;
		m_bsb_axis_tlast: out std_logic;
		m_bsb_axis_tready: in std_logic;


		clk: in std_logic;
		rstn: in std_logic -- Reset, synchronous to CTRL_CLK
		-- System interface
		);

end entity axis_to_bsb;

architecture impl of axis_to_bsb is
begin
		-- pass commands from AXIS to BSB
		m_bsb_axis_tdata <= s_axis_tdata(7 downto 0);
		m_bsb_axis_tlast <= s_axis_tlast;
		m_bsb_axis_tvalid <= s_axis_tvalid;
		s_axis_tready <= m_bsb_axis_tready;

		-- pass replies from BSB to AXIS
		m_axis_tdata(31 downto 30) <= s_bsb_axis_tuser;
		m_axis_tdata(7 downto 0) <= s_bsb_axis_tdata;
		m_axis_tlast <= s_bsb_axis_tlast;
		m_axis_tvalid <= s_bsb_axis_tvalid;
		s_bsb_axis_tready <= m_axis_tready;
end architecture impl;



