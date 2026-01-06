----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: JF Cliche
--
-- Create Date:    2012-06-12
-- Design Name: 	  chFPGA
-- Module Name:    CORR_ARRAY - Behavioral
-- Project Name: 	CHIME
-- Target Devices: Virtex 6, Kintex 7
-- Tool versions: ISE 13.3, Vivado 2013.3
-- Description: Correlator array - Correlate the frequency bins provided in the incoming stream, integrate the products, and stream the integrated output.
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- HISTORY
--		2012-09-04 JFC: Fixed IMPLEMENT_CORR=FALSE to make sure all control channels are properly terminated. Otherwise would hang the interface if access is tried.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chFPGA_Package.all; -- Get all component definitions

library UNISIM;
use UNISIM.VComponents.all;

-- Implements a correlator block, which consists of
--   1) a correlator that computes the products of all antennas for every channel and
--   2) an accumulator that cumulates the results over time and periodically sends the sum over the capture (Ethernet) interface.
--   3) a command router that routes the commands to one of the modules above based on the destination address
--
-- The correlator received a packaged stream consisting of a frame header, frequency bin data from all antennas for one channel, then the frequency bin data for another channel etc.
-- The products between every antenna for each channels are computed and integrated, and the result is framed and streamed through a 8-bit interface  for transmission over the (prober) control channel.
--
entity CORR44_ARRAY is
	GENERIC (
		PLATFORM_ID: integer;
		NUMBER_OF_CORRELATORS: integer;
		NUMBER_OF_WORDS_PER_BIN: integer
		--LEFT_DSP_RPM_X: integer_array;
		--LEFT_BRAM_RPM_X: integer_array;
		--RIGHT_DSP_RPM_X: integer_array;
		--RIGHT_BRAM_RPM_X: integer_array;
		--BOTTOM_DSP_RPM_Y: integer_array;
		--BOTTOM_BRAM_RPM_Y: integer_array
	);

	PORT (

		s_axis_tdata : in  slv32_array(0 to NUMBER_OF_CORRELATORS-1); -- input data stream containing the channelized data from every antenna processor. Each frame must contain up to 512 words each containing four (4+4) bit signed complex values.
		s_axis_tvalid : in  slv(0 to NUMBER_OF_CORRELATORS-1); --
		s_axis_tlast : in  slv(0 to NUMBER_OF_CORRELATORS-1); --

		in_clk : in std_logic; -- Input clock channelized data.
		in_rst: in std_logic; -- Reset synchronous to the input clock


		-- Integrated product output
		-- AXI4-Streaming, blocking, 8-bit wide

		m_axis_data_out_tdata: out slv8_array(0 to NUMBER_OF_CORRELATORS-1);
		m_axis_data_out_tvalid: out slv(0 to NUMBER_OF_CORRELATORS-1);
		m_axis_data_out_tlast: out slv(0 to NUMBER_OF_CORRELATORS-1);
		m_axis_data_out_tready: in slv(0 to NUMBER_OF_CORRELATORS-1);

		out_clk : in std_logic; -- clock for the integrated product outputs
		out_rst: in std_logic; -- Reset synchronous to the output clock

		-- Control and reply streams
		s_axis_bsb_tdata: in std_logic_vector(7 downto 0);
		s_axis_bsb_tvalid: in std_logic;
		s_axis_bsb_tlast: in std_logic;
		s_axis_bsb_tready: out std_logic;
		m_axis_bsb_tdata: out std_logic_vector(7 downto 0);
		m_axis_bsb_tvalid: out std_logic;
		m_axis_bsb_tlast: out std_logic;
		m_axis_bsb_tready: in std_logic;
		bsb_clk: in std_logic; -- control clock
		bsb_rst: in STD_LOGIC
		);

end CORR44_ARRAY;

architecture Behavioral of CORR44_ARRAY is

-- Attributes used in this design
attribute equivalent_register_removal: string;
attribute shreg_extract: string;
attribute DONT_TOUCH: string;
attribute RLOC_ORIGIN : string;

constant N: integer := 4 * NUMBER_OF_WORDS_PER_BIN; -- number of complex samples per frequency bin = number of channels per frequency bin

-- Get the lower left coordinate of each corr44 core
constant corr44_rpm: corr44_rloc_origins_struct_array := get_corr44_rloc_origins_struct_array(PLATFORM_ID, N);


signal s_axis_tdata_reg: slv32_array(0 to NUMBER_OF_CORRELATORS-1); -- input data stream containing the channelized data from every antenna processor. Each frame must contain up to 512 words each containing four (4+4) bit signed complex values.
signal s_axis_tvalid_reg: slv(0 to NUMBER_OF_CORRELATORS-1); --
signal s_axis_tlast_reg: slv(0 to NUMBER_OF_CORRELATORS-1); --
signal in_rst_reg: slv(0 to NUMBER_OF_CORRELATORS-1);
signal out_rst_reg: slv(0 to NUMBER_OF_CORRELATORS-1);

-- make sure the fanout pipeline register are not recombined into one
attribute DONT_TOUCH of in_rst_reg: signal is "true";
attribute DONT_TOUCH of out_rst_reg: signal is "true";

-- Control signals

signal corr_router_bsb_cmd_tdata: slv8_array(NUMBER_OF_CORRELATORS-1 downto 0);
signal corr_router_bsb_cmd_tvalid: slv(NUMBER_OF_CORRELATORS-1 downto 0);
signal corr_router_bsb_cmd_tlast: slv(NUMBER_OF_CORRELATORS-1 downto 0);
signal corr_router_bsb_cmd_tready: slv(NUMBER_OF_CORRELATORS-1 downto 0);
signal corr_router_bsb_rply_tdata: slv8_array(NUMBER_OF_CORRELATORS-1 downto 0);
signal corr_router_bsb_rply_tvalid: slv(NUMBER_OF_CORRELATORS-1 downto 0);
signal corr_router_bsb_rply_tlast: slv(NUMBER_OF_CORRELATORS-1 downto 0);
signal corr_router_bsb_rply_tready: slv(NUMBER_OF_CORRELATORS-1 downto 0);

---- make sure that the router logic is not removed if nothing is connected downstream (when the correlators are not implemented)
--attribute S: string;
--attribute S of CMD_DAT_ARRAY: signal is "yes";
--attribute S of CMD_RDY_ARRAY: signal is "yes";
--attribute S of RPLY_DAT_ARRAY: signal is "yes";
--attribute S of RPLY_RDY_ARRAY: signal is "yes";

--signal IN_DAT_REG: AXIS32_DAT_STRUCT;
--signal IN_RESET_REG: std_logic:='1'; -- Make sure we start in a reset state before the reset signal propagates

-- Make sure the pipeline registers are not simplified by the synthesizer so they can be useful in helping meeting timing
--attribute equivalent_register_removal of IN_DAT_REG: signal is "no";
--attribute shreg_extract of IN_DAT_REG: signal is "no";


begin


---------------------------------------------------------------------
-- Instantiate the Command router
-- Routes the commands to the requested correlator unit
---------------------------------------------------------------------

bsb_router0: entity work.bsb_router
	GENERIC MAP (
		NUMBER_OF_PORTS=>NUMBER_OF_CORRELATORS,
		ADDRESS_MASK => "---1111------------" --'1': used to generate port index, '-' = don't care,
	)
	PORT MAP(
		-- Upstream BSB interface
		s_axis_bsb_tdata => s_axis_bsb_tdata,
		s_axis_bsb_tvalid => s_axis_bsb_tvalid,
		s_axis_bsb_tlast => s_axis_bsb_tlast,
		s_axis_bsb_tready => s_axis_bsb_tready,
		m_axis_bsb_tdata => m_axis_bsb_tdata,
		m_axis_bsb_tvalid => m_axis_bsb_tvalid,
		m_axis_bsb_tlast => m_axis_bsb_tlast,
		m_axis_bsb_tready => m_axis_bsb_tready,

		-- Downstream BSB interface
		m_axis_routed_bsb_tdata => corr_router_bsb_cmd_tdata,
		m_axis_routed_bsb_tvalid => corr_router_bsb_cmd_tvalid,
		m_axis_routed_bsb_tlast => corr_router_bsb_cmd_tlast,
		m_axis_routed_bsb_tready => corr_router_bsb_cmd_tready,
		s_axis_routed_bsb_tdata => corr_router_bsb_rply_tdata,
		s_axis_routed_bsb_tvalid => corr_router_bsb_rply_tvalid,
		s_axis_routed_bsb_tlast => corr_router_bsb_rply_tlast,
		s_axis_routed_bsb_tready => corr_router_bsb_rply_tready,

		cmd_overflow => open,

		clk => bsb_clk,
		rst => bsb_rst
	);

---------------------------------------------------------------------
-- Correlator input pipelining process
---------------------------------------------------------------------
-- Pipeline the reset and data buses inputs to facilitate routing and timing closure.
inpipe_proc: process(all) begin
	if rising_edge(in_clk) then
			in_rst_reg <= (others=> in_rst);
			s_axis_tdata_reg <= s_axis_tdata;
			s_axis_tvalid_reg <= s_axis_tvalid;
			if in_rst='1' then
				s_axis_tvalid_reg <= (others=>'0');
			end if;
			s_axis_tlast_reg <= s_axis_tlast;
		end if;
	end process;

outpipe_proc: process(all) begin
	if rising_edge(out_clk) then
			out_rst_reg <= (others=> out_rst);
		end if;
	end process;


CORRGENi: for i in 0 to NUMBER_OF_CORRELATORS-1 generate
	-- set the position of the core44 core
	attribute RLOC_ORIGIN of corr0: label is rpm_to_string(corr44_rpm(i).loc);
begin
	corr0: entity work.corr44
		generic map (
			PLATFORM_ID             => PLATFORM_ID,
			RPM_LAYOUT              => corr44_rpm(i).layout,
			CORR_NUMBER             => i, -- will be used in the packet header and to determine the RPM location of the CORR44 cores
			NUMBER_OF_WORDS_PER_BIN => NUMBER_OF_WORDS_PER_BIN-- corresponds to the number of clocks per bin
			)
		port map(
			s_axis_tvalid           => s_axis_tvalid_reg(i),
			s_axis_tlast            => s_axis_tlast_reg(i),
			s_axis_tdata            => s_axis_tdata_reg(i),

			in_clk                  => in_clk,
			in_rst                  => in_rst_reg(i),

			m_axis_data_out_tdata   => m_axis_data_out_tdata(i),
			m_axis_data_out_tvalid  => m_axis_data_out_tvalid(i),
			m_axis_data_out_tlast   => m_axis_data_out_tlast(i),
			m_axis_data_out_tready  => m_axis_data_out_tready(i),

			out_clk                  => out_clk,
			out_rst                  => out_rst_reg(i),

				-- Control Interface
			s_axis_bsb_tdata => corr_router_bsb_cmd_tdata(i),
			s_axis_bsb_tvalid => corr_router_bsb_cmd_tvalid(i),
			s_axis_bsb_tlast => corr_router_bsb_cmd_tlast(i),
			s_axis_bsb_tready => corr_router_bsb_cmd_tready(i),
			m_axis_bsb_tdata => corr_router_bsb_rply_tdata(i),
			m_axis_bsb_tvalid => corr_router_bsb_rply_tvalid(i),
			m_axis_bsb_tlast => corr_router_bsb_rply_tlast(i),
			m_axis_bsb_tready => corr_router_bsb_rply_tready(i),
			bsb_clk => bsb_clk,
			bsb_rst => bsb_rst

			);

end generate;

end Behavioral;

