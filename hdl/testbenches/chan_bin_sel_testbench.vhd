--------------------------------------------------------------------------------
-- @file
-- Company:
-- Engineer:
--
-- Create Date:   17:23:04 11/17/2010
-- Design Name:
-- Module Name:   C:/Xilinx/work/CHIME/SP605_test2/ADCDAQ/ADC_IOSERDES_testbench.vhd
-- Project Name:  ADCDAQ
-- Target Device:
-- Tool versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes:
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
--USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;

library work;
USE work.chFPGA_Package.all;
USE work.tb_package.all;

ENTITY packetizer_testbench IS
	generic (
		NUMBER_OF_LANES: integer := 3
		);
END packetizer_testbench;


ARCHITECTURE behavior OF packetizer_testbench IS

   -- Clock period definitions

constant IN_CLK_PERIOD : time := 5 ns; -- 200 MHz
constant OUT_CLK_PERIOD : time := 4.9 ns; -- 244 MHz

	--Inputs
	signal reset : std_logic := '0';


	signal in_clk: std_logic; --
	signal out_clk: std_logic; --


	signal s_axis_tdata: slv32;
	signal s_axis_tvalid: std_logic; -- needed for sim. If, U, data will not start
	signal s_axis_tlast: std_logic;
	signal s_axis_tready: std_logic:='1'; -- init needed for sim

	signal m_axis_tdata: slv32;
	signal m_axis_tvalid: std_logic;
	signal m_axis_tlast: std_logic;
	signal m_axis_tuser: slv4;

	-- constant NUMBER_OF_PACKETS : integer :=5;
	-- type lane_config_type is array (0 to NUMBER_OF_LANES-1) of integer_array(0 to NUMBER_OF_PACKETS-1);
	-- -- back to back frames, same length, aligned within timeout
	-- -- constant start_delay: integer_array := (4,0,2);
	-- -- constant interpacket_delay: integer_array := (0,0,0);
	-- -- constant packet_length: integer_array := (8,8,8);

	-- -- -- back to back frames, same length, aligned within timeout except missing frame
	-- -- constant PL: integer := 20;
	-- -- constant PP: integer := 22;
	-- -- constant start_delay: integer_array          := (0=> 4,          1=> 0,          2=> 2);
	-- -- constant packet_length: lane_config_type     := (0=>(others=>PL), 1=>(1=>0, others=>PL), 2=>(others=>PL));
	-- -- constant packet_period: lane_config_type     := (others=> (others=>PP));

	-- constant PL: integer := 20;
	-- constant PP: integer := 22;
	-- constant start_delay: integer_array          := (0=> 0,          1=> 6,          2=> 0);
	-- constant packet_length: lane_config_type     := (0=>(others=>PL), 1=>(1=>0, others=>PL), 2=>(others=>PL));
	-- constant packet_period: lane_config_type     := (others=> (others=>PP));


	-- signal t1: slv8;
	-- signal t2,t3: std_logic;
begin


in_clk_process :process
   begin
		in_clk <= '0';
		wait for IN_CLK_PERIOD/2;
		in_clk <= '1';
		wait for IN_CLK_PERIOD/2;
   end process;

out_clk_process :process
   begin
		out_clk <= '0';
		wait for OUT_CLK_PERIOD/2;
		out_clk <= '1';
		wait for OUT_CLK_PERIOD/2;
   end process;

rst_proc : process
	begin
		reset <= '1';
		sleep(in_clk, 10);
		reset <= '0';
		sleep(in_clk, 1);
		wait;
	end process ; -- lane0_proc

-- data(0) <= (X"A0A0A0A0", X"A1A1A1A1", X"A2A2A2A2", X"A3A3A3A3", X"A4A4A4A4", X"A5A5A5A5", X"A6A6A6A6", X"A7A7A7A7");
data_proc : process
	begin
		sleep(in_clk,20);
		-- sleep(clk,start_delay(i));
		for j in 0 to 100 loop
			send_axis32_packet(in_clk, s_axis_tdata, s_axis_tvalid, s_axis_tlast, s_axis_tready, create_packet(16#FA#,j,512));
			-- sleep(clk,1);
		end loop;
		wait;
	end process ; -- lane0_proc


dut0: entity work.packetizer
	generic map (
		LANE_NUMBER => 1
		)
	port map (
		s_axis_tdata  => s_axis_tdata,
		s_axis_tvalid => s_axis_tvalid,
		s_axis_tlast  => s_axis_tlast,
		s_axis_tuser  => "0101", --(ADC overflow, scaler even, scaler odd, FFT overflow)
		in_clk => in_clk,
		-- s_axis_tready => s_axis_tready,

		m_axis_tdata  => m_axis_tdata,
		m_axis_tvalid => m_axis_tvalid,
		m_axis_tlast  => m_axis_tlast,
		m_axis_tuser  => m_axis_tuser,
		m_axis_tready  => '1',
		out_clk =>out_clk,

		rst => reset,

		CTRL_CMD_DAT => (TDATA=> (others=>'0'), TVALID => '0', TLAST => '0', DUMMY =>'0'),
		CTRL_CMD_RDY => open,
		CTRL_RPLY_DAT => open,
		CTRL_RPLY_RDY => (TREADY => '1'),
		CTRL_CLK => in_clk,
		CTRL_RST => reset
	);


END;
