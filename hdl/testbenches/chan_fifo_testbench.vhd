
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
--USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;

library work;
USE work.chFPGA_Package.all;
USE work.tb_package.all;

ENTITY packetizer_testbench IS
	generic (
		NUMBER_OF_LANES: integer := 4
		);
END packetizer_testbench;


ARCHITECTURE behavior OF packetizer_testbench IS

   -- Clock period definitions

	constant IN_CLK_PERIOD : time := 2.5 ns; -- 200 MHz
--	constant OUT_CLK_PERIOD : time := 4.9 ns; -- 244 MHz

	--Inputs
	signal reset : std_logic := '0';


	signal in_clk: std_logic_vector(0 to NUMBER_OF_LANES-1); --
	signal out_clk: std_logic; --
    constant OUT_BITS_PER_WORD: integer := 32;
    constant NUMBER_OF_CHANNELIZERS: integer := NUMBER_OF_LANES;
    
--	signal s_axis_tdata: slv32;
--	signal s_axis_tvalid: std_logic; -- needed for sim. If, U, data will not start
--	signal s_axis_tlast: std_logic;
--	signal s_axis_tready: std_logic:='1'; -- init needed for sim

--	signal m_axis_tdata: slv32;
--	signal m_axis_tvalid: std_logic;
--	signal m_axis_tlast: std_logic;
--	signal m_axis_tuser: slv4;

--		signal fifo_rst: std_logic;


	signal out_dat_tdata: slv_array(0 to NUMBER_OF_LANES-1)(OUT_BITS_PER_WORD - 1 downto 0);
	signal out_dat_tvalid: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal out_dat_tlast: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal out_dat_tuser: slv_array(0 to NUMBER_OF_LANES-1)(3 downto 0); -- TODO: make this also variable width and propagated at that width through ct engine
	signal out_dat_almost_empty: std_logic_vector(0 to NUMBER_OF_LANES-1); -- asserts about 15 clocks before the FIFO has no more data
	signal out_dat_send:  std_logic_vector(0 to NUMBER_OF_LANES-1) := (others => '1'); -- Set to '1' by the sink to indicate that output data can be sent. Has a one clock latency.
	signal out_reset:  std_logic;

	signal almost_empty_reg1, almost_empty_reg2: std_logic_vector(0 to NUMBER_OF_CHANNELIZERS - 1);
	signal send_reg1, send_reg2: std_logic_vector(0 to NUMBER_OF_CHANNELIZERS - 1);

	signal send: std_logic;


                
begin



--out_clk_process :process
--   begin
--		out_clk <= '0';
--		wait for OUT_CLK_PERIOD/2;
--		out_clk <= '1';
--		wait for OUT_CLK_PERIOD/2;
--   end process;

out_clk <= in_clk(0);

rst_proc : process
	begin
		reset <= '1';
		sleep(in_clk(0), 10);
		reset <= '0';
		sleep(in_clk(0), 1);
		wait;
	end process ; -- lane0_proc

fifo_gen: for i in 0 to NUMBER_OF_LANES-1 generate

		signal fifo_in_tdata: std_logic_vector(OUT_BITS_PER_WORD - 1 downto 0);
		signal fifo_in_tvalid: std_logic;
		signal fifo_in_tlast: std_logic;
		signal fifo_in_tuser: std_logic_vector(3 downto 0);
		signal fifo_in_ready: std_logic:= '1';

		signal fifo_out_tdata: std_logic_vector(OUT_BITS_PER_WORD - 1 downto 0);
		signal fifo_out_tvalid: std_logic;
		signal fifo_out_tvalid_not_rst: std_logic;
		signal fifo_out_tlast: std_logic;
		signal fifo_out_tuser: std_logic_vector(3 downto 0);

		signal fifo_out_ready: std_logic:= '1';

		signal fifo_almost_full: std_logic;
		signal fifo_almost_empty: std_logic;

		signal fifo_overflow: std_logic;

begin

       process begin
            wait for 0.8ns*i;
            loop
            in_clk(i) <= '0';
            wait for IN_CLK_PERIOD/2;
            in_clk(i) <= '1';
            wait for IN_CLK_PERIOD/2;
            end loop;
       end process;
    
    data_proc : process begin
--		sleep(in_clk,20);
		-- sleep(clk,start_delay(i));
		loop
			send_axis32_packet(in_clk(i), fifo_in_tdata, fifo_in_tvalid, fifo_in_tlast, fifo_in_ready, create_packet(16#FA#,0,2048));
			-- sleep(clk,1);
		end loop;
		wait;
	end process ; -- lane0_proc

		fifo_overflow <= fifo_almost_full;

		fifo0: entity work.chan_fifo
			generic map (
				FPGA_SERIES => ULTRASCALEPLUS,
				DATA_WIDTH => OUT_BITS_PER_WORD,
				USER_WIDTH  => 4
				)
			port map (
				-- User AXI-Streaming data input (non-blocking)
				s_axis_tdata => fifo_in_tdata,
				s_axis_tuser => (others => '0'),
				s_axis_tlast => fifo_in_tlast,
				s_axis_tvalid => fifo_in_tvalid,
				s_axis_clk => in_clk(i),

				m_axis_tdata => fifo_out_tdata,
				m_axis_tuser => fifo_out_tuser,
				m_axis_tlast => fifo_out_tlast,
				m_axis_tready => out_dat_send(i),
				m_axis_tvalid => fifo_out_tvalid,
				m_axis_clk => out_clk,

				almost_full => fifo_almost_full,
				almost_empty => fifo_almost_empty,
				overflow => open, -- ignored because we consider almost_full to be an overflow, otherwise will never happen due to protection above
				rst => reset
				);

		---------------------------------------------------------------------
		-- Assign the FIFO output to the channelizer output
		---------------------------------------------------------------------
		out_proc: process(all) begin
			if rising_edge(out_clk) then
				out_dat_almost_empty(i) <= fifo_almost_empty;
				out_dat_tdata(i) <= fifo_out_tdata;
				out_dat_tuser(i) <= fifo_out_tuser(3 downto 0);
				out_dat_tlast(i) <= fifo_out_tlast;
				out_dat_tvalid(i) <= fifo_out_tvalid when out_dat_send(i) and not out_reset else '0'; -- it is important to clear tvalid when send=0 as the FIFO still says it has new valid data but we are not sending that data
			end if; -- clk
		end process;
end generate;

		chan_align_proc: process(all) begin
			if rising_edge(out_clk) then
    			almost_empty_reg1 <= out_dat_almost_empty;
				almost_empty_reg2 <= almost_empty_reg1;
				send <= '0' when reset else not(or almost_empty_reg2);
				send_reg1 <= (others => send);
				send_reg2 <= send_reg1;
				out_dat_send <= send_reg2;

			end if; -- clk
		end process;

END;
