--------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: JF Cliche
--
-- Create Date:   2025-01-23
-- Design Name:
-- Module Name:   xxvglink_array_testbench.vhd
-- Project Name:  chFPGA
-- Target Device: Ultrascale+
-- Tool versions: Vivado 2022.2+
-- Description: Used to test 25Gbps packet transmitter array
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

library work;
use work.chFPGA_Package.ALL;
use work.tb_package.ALL;

entity xxvglink_array_testbench is
	generic (
		NUMBER_OF_LANES: integer := 4;
		NUMBER_OF_LINKS: integer := 3
	);
end entity xxvglink_array_testbench;

architecture behavior of xxvglink_array_testbench is

	-- Clock period definitions
	constant REFCLK_PERIOD: time := 6.4 ns;
	constant CLK125_PERIOD: time := 8 ns;
	constant CHAN_CLK_PERIOD: time := 2.5 ns;

	-- Inputs
	signal cpu_reset: std_logic := '0';
	signal send_data: std_logic := '0';

	-- UDP/Ethernet interfaces
	signal ctr: unsigned(6 downto 0) := (others => '0'); -- init for sim

	signal clk: std_logic := '0'; -- 402 MHx Tx_clk clock
	signal chan_clk: std_logic := '0'; -- 400 MHx Tx_clk clock
	signal clk125: std_logic := '0';

	signal rst: std_logic := '0'; -- asynchronous reset

	signal tx_ctr: unsigned(7 downto 0) := (others => '0'); -- init needed for sim
	signal word_ctr: unsigned(10 downto 0) := (others => '0'); -- counts 2048 words
	signal word_ctr2: u11_array(0 to NUMBER_OF_LANES - 1) := (others => (others => '0')); -- counts 2048 words
	signal frame_ctr: unsigned(15 downto 0) := (others => '0');

	signal cb1_out_tdata: slv_array(0 to NUMBER_OF_LANES - 1)(63 downto 0);
	signal cb1_out_tvalid: std_logic_vector(0 to NUMBER_OF_LANES - 1);
	signal cb1_out_tlast: std_logic_vector(0 to NUMBER_OF_LANES - 1);

	signal fifo_out_tdata: slv_array(0 to NUMBER_OF_LANES - 1)(63 downto 0);
	signal fifo_out_tvalid: std_logic_vector(0 to NUMBER_OF_LANES - 1);
	signal fifo_out_tlast: std_logic_vector(0 to NUMBER_OF_LANES - 1);

	signal rx_p: std_logic_vector(0 to NUMBER_OF_LINKS - 1);
	signal rx_n: std_logic_vector(0 to NUMBER_OF_LINKS - 1);
	signal tx_p: std_logic_vector(0 to NUMBER_OF_LINKS - 1);
	signal tx_n: std_logic_vector(0 to NUMBER_OF_LINKS - 1);
	signal refclk_p: std_logic := '0';
	signal refclk_n: std_logic := '1';

	signal s_axis_tx_tdata: slv_array(0 to NUMBER_OF_LANES - 1)(63 downto 0);
	signal s_axis_tx_tvalid: std_logic_vector(0 to NUMBER_OF_LANES - 1);
	signal s_axis_tx_tlast: std_logic_vector(0 to NUMBER_OF_LANES - 1);

	signal m_axis_rx_tdata: slv_array(0 to NUMBER_OF_LANES - 1)(63 downto 0);
	signal m_axis_rx_tvalid: std_logic_vector(0 to NUMBER_OF_LANES - 1);
	signal m_axis_rx_tlast: std_logic_vector(0 to NUMBER_OF_LANES - 1);


			-- Align buses

			signal align1_out_tdata: slv_array(0 to NUMBER_OF_LANES - 1)(64 - 1 downto 0);
			signal align1_out_tvalid: std_logic_vector(0 to NUMBER_OF_LANES - 1);
			signal align1_out_tlast: std_logic_vector(0 to NUMBER_OF_LANES - 1);
			signal align1_out_global_tvalid: std_logic;
			signal align1_out_global_tlast: std_logic;


			-- Align monitoring

			signal align1_mon_reset: std_logic;
			signal align1_mon_lane: std_logic_vector(3 downto 0);
			signal align1_mon_source: std_logic_vector(3 downto 0);
			signal align1_mon_word: std_logic_vector(15 downto 0);


	signal resetdone: std_logic;

	signal cmd_tdata: slv8 := x"00";
	signal cmd_tvalid: std_logic := '0';
	signal cmd_tlast: std_logic := '0';
	signal cmd_tready: std_logic := '1';

begin

	-- Clocks
	(refclk_p, refclk_n) <= std_logic_vector'(refclk_n & refclk_p) after REFCLK_PERIOD / 2;
	clk125               <= not clk125 after CLK125_PERIOD / 2;
	chan_clk             <= not chan_clk after CHAN_CLK_PERIOD / 2;

	reset_process: process
	begin
		cpu_reset <= '1';
		sleep(refclk_p, 100); -- not really needed
		-- sleep(clk, 10); -- wait for the QPLL to lock and starts generating the main clock
		cpu_reset <= '0'; -- release RESET. FIFOs start their reset sequence
		wait until resetdone;
		sleep(clk, 32); -- wait for the FIFO to finish their resent before writing into them
		send_data <= '1';
		wait;
	end process;

	-- Loopback
	rx_p <= tx_p;
	rx_n <= tx_n;

	dut0: entity work.xxvglink_array
		generic map (
			LANE_TO_LINK_MAP   => (-1,0,1,2),
			LINK_TO_QUAD_MAP   => (0,1,1),
			QUAD_TO_REFCLK_MAP => (0,0),
			SIM                => True
		)
		port map (
			tx_p     => tx_p,
			tx_n     => tx_n,
			rx_p     => rx_p,
			rx_n     => rx_n,
			refclk_p => (others => refclk_p),
			refclk_n => (others => refclk_n),

			axis_clk => clk,

			s_axis_tx_tdata  => cb1_out_tdata,
			s_axis_tx_tvalid => cb1_out_tvalid,
			s_axis_tx_tlast  => cb1_out_tlast,

			m_axis_rx_tdata  => m_axis_rx_tdata,
			m_axis_rx_tvalid => m_axis_rx_tvalid,
			m_axis_rx_tlast  => m_axis_rx_tlast,

			resetdone => resetdone,

			clk_out => clk,
			areset  => cpu_reset,

			cmd_dat        => (tdata=> cmd_tdata, tvalid => cmd_tvalid, tlast => cmd_tlast),
			cmd_rdy.tready => cmd_tready,
			rply_dat       => open,
			rply_rdy       => (TREADY => '1'),
			ctrl_clk       => clk125,
			ctrl_rst       => cpu_reset
		);

	fifo_gen: for i in 0 to NUMBER_OF_LANES - 1 generate
		fifo0: entity work.xxvglink_data_fifo
			port map (
				s_axis_tvalid => s_axis_tx_tvalid(i),
				s_axis_tdata  => s_axis_tx_tdata(i),
				s_axis_tlast  => s_axis_tx_tlast(i),
				s_clk         => chan_clk,

				m_axis_tvalid => fifo_out_tvalid(i),
				m_axis_tdata  => fifo_out_tdata(i),
				m_axis_tlast  => fifo_out_tlast(i),
				m_clk         => clk,

				overflow => open,
				arst     => rst
			);
	end generate fifo_gen;

    -- Instantiate packet aligner
    align1: entity work.align64
        generic map (
            NUMBER_OF_LANES         => NUMBER_OF_LANES,
            ENABLE_MONITORING_LOGIC => TRUE
        )
        port map (
            -- Data from the channelizers outputs (AXI Streaming, blocking)
            s_axis_tvalid => m_axis_rx_tvalid,
            s_axis_tdata  => m_axis_rx_tdata,
            s_axis_tlast  => m_axis_rx_tlast,

            -- Data to the remapper (AXI Streaming, non-blocking)
            m_axis_global_tvalid => align1_out_global_tvalid,
            m_axis_global_tlast  => align1_out_global_tlast,
            m_axis_tvalid        => align1_out_tvalid,
            m_axis_tdata         => align1_out_tdata,
            m_axis_tlast         => align1_out_tlast,


            -- Aligner configuration
            sof_window_stop => X"30",
            ignore_lane     => (others => '0'),

            -- Monitoring (if enabled)
            mon_reset  => '0',
            mon_lane   => X"1",
            mon_source => X"1",
            mon_word   => align1_mon_word,

            clk => clk,
            rst => rst
        );


	-- Stimulus: generate data packets for FIFO
	chan_proc: process(chan_clk)
	begin
		if rising_edge(chan_clk) then
			s_axis_tx_tdata  <= (others => (others => '0'));
			s_axis_tx_tvalid <= (others => '0');
			s_axis_tx_tlast  <= (others => '0');
			if send_data = '1' then
				for i in 0 to NUMBER_OF_LANES - 1 loop
					s_axis_tx_tdata(i)(word_ctr'RANGE)  <= std_logic_vector(word_ctr);
					s_axis_tx_tdata(i)(31 downto 16)  <= std_logic_vector(frame_ctr);
					s_axis_tx_tdata(i)(63 downto 60)  <= to_slv(i, 4);
					s_axis_tx_tvalid(i) <= '1';
					s_axis_tx_tlast(i)  <= to_std_logic(all_ones(word_ctr));
					word_ctr <= word_ctr + 1;
					if all_ones(word_ctr) then
						frame_ctr <= frame_ctr + 1;
					end if;
					ctr <= ctr + 1;
					if cpu_reset = '1' or send_data = '0' then
						word_ctr <= (others => '0');
						frame_ctr <= (others => '0');
					end if;
				end loop; -- i
			end if; -- if send_data
		end if; -- clk
	end process;

	-- Stimulus: transfer data packets from FIFO to GTYs
	stim_proc: process(clk)
	begin
		if rising_edge(clk) then
			if send_data then
				for i in 0 to NUMBER_OF_LANES - 1 loop
					if fifo_out_tvalid(i) then
						word_ctr2(i) <= word_ctr2(i) + 1;
						if fifo_out_tlast(i) then
							word_ctr2(i) <= (others => '0');
						end if;
					end if;
					if cpu_reset then
						word_ctr2(i) <= (others => '0');
					end if;
					cb1_out_tdata(i) <= fifo_out_tdata(i);
					cb1_out_tvalid(i) <= fifo_out_tvalid(i);
--					if cpu_reset = '1' or (word_ctr2(i)(10 downto 8) = 0 and word_ctr2(i)(1 downto 0) = i and fifo_out_tlast(i) = '0') then
					if cpu_reset = '1' or (word_ctr2(i)(10 downto 6) = 0) then
						cb1_out_tvalid(i) <= '0';
					end if;
					cb1_out_tlast(i) <= fifo_out_tlast(i);
				end loop; -- i
			end if; -- if send_data
		end if; -- clk
	end process;

end architecture behavior;
