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
--USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;

library work;
USE work.chFPGA_Package.all;
use work.tb_package.all;

ENTITY align_testbench IS
	generic (
		NUMBER_OF_LANES: integer := 6 -- minimum to fit bits on lane monitor source 0
		);
END align_testbench;


ARCHITECTURE behavior OF align_testbench IS

   -- Clock period definitions
   -- constant CLK_PERIOD : time := 3.2 ns;

constant IN_CLK_PERIOD : time := 5 ns; -- 200 MHz
constant OUT_CLK_PERIOD : time := 4.096 ns; -- 244 MHz


	--Inputs
	signal reset : std_logic := '0';


	signal in_clk: std_logic; -- 200 MHz
	signal out_clk: std_logic; -- 244 MHz


	signal s_axis_tdata: slv32_array(0 to NUMBER_OF_LANES-1) := (others=> (others=>'0'));
	signal s_axis_tvalid: std_logic_vector(0 to NUMBER_OF_LANES-1) := (others=>'0'); -- needed for sim. If, U, data will not start
	signal s_axis_tlast: std_logic_vector(0 to NUMBER_OF_LANES-1):= (others=>'0');
	signal s_axis_tready: std_logic_vector(0 to NUMBER_OF_LANES-1):=(others=>'1'); -- init needed for sim

	signal m_axis_fifo_tdata: slv32_array(0 to NUMBER_OF_LANES-1);
	signal m_axis_fifo_tvalid: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal m_axis_fifo_tlast: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal m_axis_fifo_tuser: slv4_array(0 to NUMBER_OF_LANES-1);
	-- signal m_axis_fifo_tready: std_logic_vector(0 to NUMBER_OF_LANES-1);

	signal m_axis_tdata: slv32_array(0 to NUMBER_OF_LANES-1);
	signal m_axis_tvalid: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal m_axis_tlast: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal m_axis_tuser: slv4_array(0 to NUMBER_OF_LANES-1);

	signal m_axis_global_tvalid: std_logic;
	signal m_axis_global_tlast: std_logic;
	signal tvalid_error: std_logic_vector(0 to NUMBER_OF_LANES-1);

	signal fifo_rd_en: std_logic_vector(0 to NUMBER_OF_LANES-1) := (others=> '0');
	signal fifo_rst: std_logic;
	signal fifo_inhibit: std_logic;
	signal fifo_rst_ctr : unsigned(5 downto 0);

	signal frame_clk: std_logic;
	signal first: std_logic := '1';
	signal timeout_ctr: unsigned(7 downto 0);

	constant NUMBER_OF_PACKETS : integer :=500;
	type lane_config_type is array (0 to NUMBER_OF_LANES-1) of integer_array(0 to NUMBER_OF_PACKETS-1);
	-- back to back frames, same length, aligned within timeout
	-- constant start_delay: integer_array := (4,0,2);
	-- constant interpacket_delay: integer_array := (0,0,0);
	-- constant packet_length: integer_array := (8,8,8);

	-- -- back to back frames, same length, aligned within timeout except missing frame
	-- constant PL: integer := 20;
	-- constant PP: integer := 22;
	-- constant start_delay: integer_array          := (0=> 4,          1=> 0,          2=> 2);
	-- constant packet_length: lane_config_type     := (0=>(others=>PL), 1=>(1=>0, others=>PL), 2=>(others=>PL));
	-- constant packet_period: lane_config_type     := (others=> (others=>PP));

	constant PL: integer := 512; -- packet length
	constant PP: integer := 512; -- packet period (packet length + interpacket delay)
	constant start_delay: integer_array          := (0=> 0, 1=> 600, 2=> 37, 3 to 5 => 0); -- normal delay
	-- constant start_delay: integer_array          := (0=> 0,          1=> 0,          2=> 0); -- normal delay
	constant lane_active: integer_array          := (0=> 1, 1=> 1, 2=> 1, 3 to 5 => 1);
	-- constant start_delay: integer_array          := (0=> 0,          1=> 9,          2=> 1); -- borderline delay
	constant packet_length: lane_config_type     := (others=>(others=>PL)); -- All lanes normal
	constant packet_period: lane_config_type     := (others=>(others=>PP)); -- All lanes normal, with interpacket space
	-- constant packet_length: lane_config_type     := (0=>(others=>PL), 1=>(1=>0, others=>PL), 2=>(others=>PL)); -- missing frame
	-- constant packet_period: lane_config_type     := (others=> (others=>PP));
	-- constant packet_length: lane_config_type     := (1=>(others=>1), others=> (others=>PL)); -- Lane 1 single word
	-- constant packet_period: lane_config_type     := (1=>(others=>1), others=> (others=>PP)); -- lane 1 single word back to back
	-- constant packet_length: lane_config_type     := (2=>(others=>0), others=>(others=>PL)); -- Missing lane 3
	-- constant packet_length: lane_config_type     := (2=>(others=>PL-1), others=>(others=>PL)); -- Lane 2 sends shorter packets
	-- constant packet_length: lane_config_type     := (2=>(others=>1111), others=>(others=>PL)); -- Lane 2 twice as long packets
	-- constant packet_period: lane_config_type     := (2=> (others=>1321), others=>(others=>PP)); -- Lane 2 short period
	-- constant packet_length: lane_config_type     := (0=>(others=>PL), 1=>(1=>PL+6, 2=>PL-6, others=>PL), 2=>(others=>PL)); -- 1st packet on lanet 2 too long
	-- constant packet_period: lane_config_type     := (0=>(others=>PL), 1=>(1=>PL+6, 2=>PL-6, others=>PL), 2=>(others=>PL)); -- All lanes normal, with interpacket space


-- Tests
-- Normal mode
-- Borderline delay
-- Missing frame
-- Short frame
-- One lane with bursts on back-to-back 1 word frame
-- All single word, back-to-back packets: cannot work because  too fast for the frame clock processing

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

-- clk_process :process
--    begin
-- 		clk <= '0';
-- 		wait for CLK_PERIOD/2;
-- 		clk <= '1';
-- 		wait for CLK_PERIOD/2;
--    end process;

rst_proc : process
	begin
		reset <= '1';
		sleep(out_clk, 10);
		reset <= '0';
		sleep(out_clk, 257);


		wait; -- comment out to implement periodic resets
	end process ; -- lane0_proc
-- tests
-- 5 back-to back frames, all same length, aligned: ok
-- 5 frames, 1 clock spacing, same length, aligned: ok
-- 5 frames, same_length, aligned within timeout: ok
-- 5 frames, same_length, lane2 delayed by frame length:

-- data(0) <= (X"A0A0A0A0", X"A1A1A1A1", X"A2A2A2A2", X"A3A3A3A3", X"A4A4A4A4", X"A5A5A5A5", X"A6A6A6A6", X"A7A7A7A7");

lane_gen: for i in 0 to NUMBER_OF_LANES-1 generate

	-- fifo0: entity work.chan_fifo
	-- 	port map (
	-- 		-- Input interface (non-blocking, i.e. always accept data)

	-- 		s_axis_tvalid => s_axis_tvalid(i),
	-- 		s_axis_tdata => s_axis_tdata(i),
	-- 		s_axis_tlast => s_axis_tlast(i),
	-- 		s_axis_tuser => "1100",
	-- 		s_axis_clk => in_clk,

	-- 		m_axis_tvalid => m_axis_fifo_tvalid(i),
	-- 		m_axis_tdata => m_axis_fifo_tdata(i),
	-- 		m_axis_tlast => m_axis_fifo_tlast(i),
	-- 		m_axis_tuser => m_axis_fifo_tuser(i),
	-- 		m_axis_tready => '1', -- always stream data
	-- 		m_axis_clk => out_clk,

	-- 		-- frame_clk => frame_clk(i), -- Frame clock, toggling on the first word of each frame fed INTO the fifo. The data will appear a few FIFO latency cycles later. This is used by the frame aligner to detect frame timeout.

	-- 		rst => reset
	-- 	);


	fifo0 : entity work.CHAN_FIFO2
		PORT MAP (
			rst                => fifo_rst,
			wr_clk             => in_clk,
			wr_en              => s_axis_tvalid(i) and not fifo_inhibit,
			din(31 downto 0)   => s_axis_tdata(i),
			din(32)            => s_axis_tlast(i),
			din(36 downto 33)  => "1100",

			rd_clk             => out_clk,
			rd_en              => m_axis_fifo_tvalid(i),
			dout(31 downto 0)  => m_axis_fifo_tdata(i),
			dout(32)           => m_axis_fifo_tlast(i),
			dout(36 downto 33) => m_axis_fifo_tuser(i),
			valid              => m_axis_fifo_tvalid(i),
			full               => open,
			overflow           => open,
			empty              => open
		);

----------------------
-- FIFO reset process.
----------------------
-- According to the user manual, for Async FIFOs, reset
-- must be held for 31 clocks of the slowest clk (in_clk) when there is no safety circuit, and there must be no
-- read or write during that period. There does not seem to be a safety circuit from the core generator GUI.
fifo_rst_proc: process(all) begin
        if rising_edge(in_clk) then
            if reset ='1' then
                fifo_inhibit <='1';
                fifo_rst_ctr <= (others => '0'); -- this is a 5-bit counter
            elsif signed(fifo_rst_ctr) = -1 then
                fifo_inhibit <= '0';
            else
	            if fifo_rst_ctr = 10 then
	   	                fifo_rst <= '1';
	            elsif signed(fifo_rst_ctr) = -20 then
	   	                fifo_rst <= '0';
  				end if;
                fifo_rst_ctr <= fifo_rst_ctr + 1;
            end if; --reset
        end if; --clk
    end process;


	lane_proc : process
		begin
			wait until reset='0';
			sleep(in_clk, 80);
			fifo_rd_en(i) <= '1';
			if lane_active(i)>0 then
				sleep(in_clk, start_delay(i));
				for j in 0 to NUMBER_OF_PACKETS-1 loop
					send_axis32_packet(in_clk, s_axis_tdata(i), s_axis_tvalid(i), s_axis_tlast(i), s_axis_tready(i), create_packet(i,j, packet_length(i)(j)));
					sleep(in_clk, packet_period(i)(j) - packet_length(i)(j));
				end loop;
			end if;
			wait;
		end process ; -- lane0_proc

end generate;

process(all) begin
	if rising_edge(out_clk) then
		if s_axis_tvalid(0)='1' then
			first <= s_axis_tlast(0);
		end if;
		frame_clk <= s_axis_tvalid(0) and first;
		for i in 0 to NUMBER_OF_LANES-1  loop
			tvalid_error(i) <=m_axis_global_tvalid and not m_axis_tvalid(i);
		end loop;

		timeout_ctr <= timeout_ctr + 1;
		if timeout_ctr > 80 then
			s_axis_tready(2) <= '0';
		else
			s_axis_tready(2) <= '1';
		end if;
		if timeout_ctr = 111 then
			timeout_ctr <= (others=>'0');
		end if;

	end if; --clk
end process;

-- frame_clk <= s_axis_tvalid and s_axis_tlast;
align0: entity work.chan_align
	generic map (
		NUMBER_OF_LANES => NUMBER_OF_LANES
		)
	port map (
		s_axis_tdata  => m_axis_fifo_tdata,
		s_axis_tvalid => m_axis_fifo_tvalid,
		s_axis_tlast  => m_axis_fifo_tlast,
		s_axis_tuser  => (others=>"1100"),

		-- frame_clk_sel => '0',
		m_axis_tdata  => m_axis_tdata,
		m_axis_tvalid => m_axis_tvalid,
		m_axis_tlast  => m_axis_tlast,
		m_axis_tuser  => m_axis_tuser,

		m_axis_global_tvalid => m_axis_global_tvalid,
		m_axis_global_tlast => m_axis_global_tlast,

		lane_monitor_source => (others=>'0'),
		reset_stats => '0',
		lane_monitor => open,
		overflow => open,
		in_frame_ctr => open,
		out_frame_ctr => open,
		clk => out_clk,
		-- sof_window_start => to_slv(0,8),
		--sof_window_stop => to_slv(50,8),
		--use_timeout => '1',
		--timeout_period => to_slv(7,8),
		-- frame_clk => frame_clk,
		rst => reset
	);


END;
