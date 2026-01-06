--------------------------------------------------------------------------------
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
USE ieee.numeric_std.ALL;

library work;
USE work.chFPGA_Package.all;
use work.tb_package.all;

ENTITY prober_testbench IS
 	generic (
 		NUMBER_OF_PROBES: integer := 4 -- Must be a multiple of 4
 		);
END prober_testbench;


ARCHITECTURE behavior OF prober_testbench IS

   -- Clock period definitions

constant IN_CLK_PERIOD : time := 5 ns; -- 200 MHz
constant OUT_CLK_PERIOD : time := 4.096 ns; -- 244 MHz
constant CLK125_period : time := 8 ns;

-- SYSTEM Port modules
--constant CROSSBAR_BASE_ADDR      : integer := 16#60000#; -- # CROSSBAR top address
--constant CROSSBAR_ADDR_INCREMENT : integer := 16#00800#; --
--constant CROSSBAR_BIN_SEL0_ADDR: integer :=CROSSBAR_BASE_ADDR + 1*CROSSBAR_ADDR_INCREMENT;
--constant CROSSBAR_BIN_SEL1_ADDR: integer :=CROSSBAR_BASE_ADDR + 2*CROSSBAR_ADDR_INCREMENT;

--Inputs
signal reset : std_logic := '0';


signal clk: std_logic; --
signal out_clk: std_logic; --
signal clk125: std_logic; --
signal frame_clk_in: std_logic;

signal s_axis_tdata: slv32;
signal s_axis_tvalid: std_logic :='0'; -- needed for sim. If, U, data will not start
signal s_axis_tlast: std_logic:='0';
signal s_axis_tready: std_logic:='1'; -- init needed for sim



signal m_axis_tdata: slv32;
signal m_axis_tvalid: std_logic;
signal m_axis_tlast: std_logic;
signal m_axis_tuser: slv4;

signal cmd_tdata: slv8;
signal cmd_tvalid: std_logic;
signal cmd_tlast: std_logic;
signal cmd_tready: std_logic;

signal chan_reset: std_logic;
-- constant NUMBER_OF_PACKETS : integer :=5;
-- type lane_config_type is array (0 to NUMBER_OF_INPUT_LANES-1) of integer_array(0 to NUMBER_OF_PACKETS-1);
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


signal udp_rx_dat: AXIS8_DAT_STRUCT := (tvalid=>'0', tdata=>x"00", tlast=>'0');
signal udp_rx_rdy: AXIS8_RDY_STRUCT;

signal prb_dat, cmd_dat, rply_dat: AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_PROBES-1 downto 0) := (others => (tvalid=>'0', tdata=>x"00", tlast=>'0'));
signal prb_rdy, cmd_rdy, rply_rdy: AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_PROBES-1 downto 0);

signal prb_tdata: slv8_array(NUMBER_OF_PROBES-1 downto 0);
signal prb_tvalid, prb_tlast, prb_tready: slv(NUMBER_OF_PROBES-1 downto 0);

begin



-- data(0) <= (X"A0A0A0A0", X"A1A1A1A1", X"A2A2A2A2", X"A3A3A3A3", X"A4A4A4A4", X"A5A5A5A5", X"A6A6A6A6", X"A7A7A7A7");




prober0: entity work.prober
	generic map (
			SIM => TRUE,
			NUMBER_OF_INPUTS => 2
		)
	port map (
		in_dat0.tdata  => s_axis_tdata,
		in_dat0.tvalid => s_axis_tvalid,
		in_dat0.tlast  => s_axis_tlast,
		in_dat0.tuser  => "0101", --(ADC overflows)

		in_dat1.tdata  => s_axis_tdata,
		in_dat1.tvalid => s_axis_tvalid,
		in_dat1.tlast  => s_axis_tlast,
		in_dat1.tuser  => "0101", --(ADC overflows)

		in_clk => clk,
		in_reset => chan_reset,


        OUT_DAT.TDATA => prb_tdata(0), 
        OUT_DAT.TVALID => prb_tvalid(0),
        OUT_DAT.TLAST => prb_tlast(0),
        OUT_RDY.TREADY => prb_tready(0),
        OUT_CLK => clk125,

		-- CTRL_CMD_DAT => (TDATA=> cmd_tdata, TVALID => cmd_tvalid, TLAST => cmd_tlast),
		s_axis_bsb_tdata => cmd_dat(0).tdata,
		s_axis_bsb_tvalid => cmd_dat(0).tvalid,
		s_axis_bsb_tlast => cmd_dat(0).tlast,
		s_axis_bsb_tready => cmd_rdy(0).tready,

		m_axis_bsb_tdata => rply_dat(0).tdata,
		m_axis_bsb_tvalid => rply_dat(0).tvalid,
		m_axis_bsb_tlast => rply_dat(0).tlast,
		m_axis_bsb_tready => rply_rdy(0).tready,

		CTRL_CLK => clk125,
		CTRL_RST => reset
	);

master0: entity work.bsb_master
	generic map (
		NUMBER_OF_PROBES => NUMBER_OF_PROBES
	)

	PORT map (
		-- UDP Transmitter/Receiver interface

		-- UDP Rx interface
		s_axis_udp_rx_tdata  => udp_rx_dat.tdata,
		s_axis_udp_rx_tvalid => udp_rx_dat.tvalid,
		s_axis_udp_rx_tlast  => udp_rx_dat.tlast,
		s_axis_udp_rx_tready => udp_rx_rdy.tready,

		-- UDP Tx interface
		m_axis_udp_tx_tvalid => open,
		m_axis_udp_tx_tdata => open,
		m_axis_udp_tx_tlast => open,
		m_axis_udp_tx_tready => '1',
--		udp_tx_port => open,


		-- Command and reply stream buses

		m_axis_cmd_tdata  => cmd_dat(0).tdata,
		m_axis_cmd_tvalid => cmd_dat(0).tvalid,
		m_axis_cmd_tlast  => cmd_dat(0).tlast,
		m_axis_cmd_tready => cmd_rdy(0).tready,

		s_axis_rply_tdata  => rply_dat(0).tdata,
		s_axis_rply_tvalid => rply_dat(0).tvalid,
		s_axis_rply_tlast  => rply_dat(0).tlast,
		s_axis_rply_tready => rply_rdy(0).tready,
--		rply_port_offset => "00",


		cmd_packet_counter => open,
		rply_packet_counter => open,


		-- Raw Data (probe) inputs

		s_axis_data_tdata => prb_tdata,
		s_axis_data_tvalid => prb_tvalid,
		s_axis_data_tlast => prb_tlast,
		s_axis_data_tready=> prb_tready, 
		-- System
		host_frame_read_rate => "00100",
		clk => clk125,
		rst => reset
		);

clk_process :process
   begin
		clk <= '0';
		wait for IN_CLK_PERIOD/2;
		clk <= '1';
		wait for IN_CLK_PERIOD/2;
   end process;


clk125_process :process
   begin
		clk125 <= '0';
		wait for clk125_period/2;
		clk125 <= '1';
		wait for clk125_period/2;
   end process;

stim_proc : process
	-- variable number_of_selected_bins: integer :=8;
	-- variable number_of_bins_per_frame: integer :=156;
	-- variable number_of_words_per_bin: integer :=4;
	-- variable actual_number_of_input_lanes: integer := 16;
	variable func: integer :=0; -- 0=adc, 1=ram, 2=noise, 3=ctr
	variable ram_page: integer :=0; --
--	variable pattern: slv8_array(0 to 2047);
	constant BURST_LENGTH: integer := 4-1;
	constant PRIMARY_PERIOD0: integer := 69-1;
    constant SOURCE: integer := 0;

	begin

		reset <= '1';
		chan_reset <= '1';
		sleep(clk, 10);
		reset <= '0';
		sleep(clk125, 10); -- make sure we start command transmission on a CLK125 edge or we will lose some data
		fpga_write_control(clk125, udp_rx_dat.tdata, udp_rx_dat.tvalid, udp_rx_dat.tlast, udp_rx_rdy.tready, 0, "00" & to_slv(SOURCE , 1) & "000" & to_slv(BURST_LENGTH,2) ); 
		fpga_write_control(clk125, udp_rx_dat.tdata, udp_rx_dat.tvalid, udp_rx_dat.tlast, udp_rx_rdy.tready, 4, PRIMARY_PERIOD0, 3); -- 3 bytes
--		fpga_write_control(clk125, udp_rx_dat.tdata, udp_rx_dat.tvalid, udp_rx_dat.tlast, udp_rx_rdy.tready, 9, 1, 2); -- Send 5 frames

		-- -- Program buffer
		-- fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, 2#00000000# + ram_page * 8); -- source=funcgen, enable=1, select last page of ram
		-- fpga_write_ram(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 511, (0=>X"01"));

		--for i in pattern'range loop
		--	pattern(i) := to_slv(i,8);
		--end loop;
		--fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, 2#00000000#); -- Make sure we use page 0
		--fpga_write_ram(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, pattern); -- write all 2048 bytes at once.

		sleep(clk,20);
		chan_reset <= '0';

--		sleep(clk, 100);
		for j in 0 to 1000 loop
			send_axis32_packet(clk, s_axis_tdata, s_axis_tvalid, s_axis_tlast, s_axis_tready, create_packet(16#FA#, j, 512)); -- 512*244/200=624.64 clocks = actual duration of  the incoming frames
			-- sleep(clk,1);
		end loop;

--		-- Send a reset in the middle of the data to see what it does
--		sleep(clk,200);
--		chan_reset <= '1';
--		sleep(clk,210);
--		chan_reset <= '0';



		-- Continuously send read commands to try to throw off CMD_MASTER
		--loop
		-- 	fpga_read(clk125, udp_rx_dat.tdata, udp_rx_dat.tvalid, udp_rx_dat.tlast, udp_rx_rdy.tready, 0, 0);
		--	sleep(clk,20);
		--end loop;
		wait;
	end process ; -- lane0_proc

--data_proc: process
--	begin
--		sleep(clk, 100);
--		for j in 0 to 1000 loop
--			send_axis32_packet(clk, s_axis_tdata, s_axis_tvalid, s_axis_tlast, s_axis_tready, create_packet(16#FA#, j ,624)); -- 512*244/200=624.64 clocks = actual duration of  the incoming frames
--			-- sleep(clk,1);
--		end loop;

--	end process;

END;
