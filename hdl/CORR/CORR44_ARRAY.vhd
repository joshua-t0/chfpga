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

------------------------------------
------- CORR ENTITY ----------
------------------------------------
--! Implements a correlator block, which consists of
--!   1) a correlator that computes the products of all antennas for every channel and
--!   2) an accumulator that cumulates the results over time and periodically sends the sum over the capture (Ethernet) interface.
--!   3) a command router that routes the commands to one of the modules above based on the destination address
--!
--! The correlator received a packaged stream consisting of a frame header, frequency bin data from all antennas for one channel, then the frequency bin data for another channel etc.
--! The products between every antenna for each channels are computed and integrated, and the result is framed and streamed through a 8-bit interface  for transmission over the (prober) control channel.
--!
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

		s_axis_tdata : in  slv32_array(0 to NUMBER_OF_CORRELATORS-1); --! input data stream containing the channelized data from every antenna processor. Each frame must contain up to 512 words each containing four (4+4) bit signed complex values.
		s_axis_tvalid : in  slv(0 to NUMBER_OF_CORRELATORS-1); --!
		s_axis_tlast : in  slv(0 to NUMBER_OF_CORRELATORS-1); --!

		in_clk : in std_logic; --! Input clock channelized data.
		in_rst: in std_logic; --! Reset synchronous to the input clock


		-- Integrated product output
		-- AXI4-Streaming, blocking, 8-bit wide

		m_axis_data_out_tdata: out slv8_array(0 to NUMBER_OF_CORRELATORS-1);
		m_axis_data_out_tvalid: out slv(0 to NUMBER_OF_CORRELATORS-1);
		m_axis_data_out_tlast: out slv(0 to NUMBER_OF_CORRELATORS-1);
		m_axis_data_out_tready: in slv(0 to NUMBER_OF_CORRELATORS-1);

		out_clk : in std_logic; --! clock for the integrated product outputs
		out_rst: in std_logic; --! Reset synchronous to the output clock

		-- Control and reply streams
		cmd_dat:  in AXIS8_DAT_STRUCT;
		cmd_rdy:  out AXIS8_RDY_STRUCT;
		rply_dat: out AXIS8_DAT_STRUCT;
		rply_rdy: in AXIS8_RDY_STRUCT;
		ctrl_clk: in std_logic; -- control clock
		ctrl_rst: in STD_LOGIC
		);

end CORR44_ARRAY;

architecture Behavioral of CORR44_ARRAY is

-- Attributes used in this design
attribute equivalent_register_removal: string;
attribute shreg_extract: string;
attribute DONT_TOUCH: string;


signal s_axis_tdata_reg: slv32_array(0 to NUMBER_OF_CORRELATORS-1); --! input data stream containing the channelized data from every antenna processor. Each frame must contain up to 512 words each containing four (4+4) bit signed complex values.
signal s_axis_tvalid_reg: slv(0 to NUMBER_OF_CORRELATORS-1); --!
signal s_axis_tlast_reg: slv(0 to NUMBER_OF_CORRELATORS-1); --!
signal in_rst_reg: slv(0 to NUMBER_OF_CORRELATORS-1);
signal out_rst_reg: slv(0 to NUMBER_OF_CORRELATORS-1);

-- make sure the fanout pipeline register are not recombined into one
attribute DONT_TOUCH of in_rst_reg: signal is "true";
attribute DONT_TOUCH of out_rst_reg: signal is "true";

-- Control signals

signal corr_cmd_dat: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_CORRELATORS-1 downto 0);
signal corr_cmd_rdy: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_CORRELATORS-1 downto 0);
signal corr_rply_dat: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_CORRELATORS-1 downto 0);
signal corr_rply_rdy: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_CORRELATORS-1 downto 0);

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
--! Instantiate the Command router
--! Routes the commands to the requested correlator unit
---------------------------------------------------------------------

CTRL_ROUTER0: entity work.CTRL_ROUTER
	GENERIC MAP (
		NUMBER_OF_PORTS=>NUMBER_OF_CORRELATORS,
		ADDRESS_MASK => "----1111------------" --'1': used to generate port index, '-' = don't care,
	)
	PORT MAP(
		-- Master control interface
		CMD_IN_DAT   => cmd_dat,
		CMD_IN_RDY   => cmd_rdy,
		RPLY_OUT_DAT => rply_dat,
		RPLY_OUT_RDY => rply_rdy,


		CMD_OUT_DAT  => corr_cmd_dat,
		CMD_OUT_RDY  => corr_cmd_rdy,
		RPLY_IN_DAT  => corr_rply_dat,
		RPLY_IN_RDY  => corr_rply_rdy,

		-- Slave (module) control interface
		CLK          => ctrl_clk,
		RST          => ctrl_rst
	);

---------------------------------------------------------------------
--! Correlator input pipelining process
---------------------------------------------------------------------
--! Pipeline the reset and data buses inputs to facilitate routing and timing closure.
inpipe_proc: process(in_clk)
	begin
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

outpipe_proc: process(out_clk)
	begin
		if rising_edge(out_clk) then
			out_rst_reg <= (others=> out_rst);
		end if;
	end process;


CORRGENi: for i in 0 to NUMBER_OF_CORRELATORS-1 generate
	corr0: entity work.corr44
		generic map (
			PLATFORM_ID             => PLATFORM_ID,
			CORR_NUMBER             => i, -- will be used in the packet header and to determine the RPM location of the CORR44 cores
			NUMBER_OF_WORDS_PER_BIN => NUMBER_OF_WORDS_PER_BIN-- corresponds to the number of clocks per bin
			--LEFT_DSP_RPM_X          => LEFT_DSP_RPM_X(i),
			--LEFT_BRAM_RPM_X         => LEFT_BRAM_RPM_X(i),
			--RIGHT_DSP_RPM_X         => RIGHT_DSP_RPM_X(i),
			--RIGHT_BRAM_RPM_X        => RIGHT_BRAM_RPM_X(i),
			--BOTTOM_DSP_RPM_Y        => BOTTOM_DSP_RPM_Y(i),
			--BOTTOM_BRAM_RPM_Y       => BOTTOM_BRAM_RPM_Y(i)
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
			CMD_DAT  => corr_cmd_dat(i),
			CMD_RDY  => corr_cmd_rdy(i),
			RPLY_DAT => corr_rply_dat(i),
			RPLY_RDY => corr_rply_rdy(i),
			CTRL_CLK => ctrl_clk,
			CTRL_RST => ctrl_rst

			);

end generate;

end Behavioral;

