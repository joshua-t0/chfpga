
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
--USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
use std.textio.all;

library work;
USE work.chFPGA_Package.all;
USE work.tb_package.all;

ENTITY axis_sync_fifo_testbench IS
END axis_sync_fifo_testbench;


ARCHITECTURE sim OF axis_sync_fifo_testbench IS

   -- Constants

	constant CLK_PERIOD : time := 2.5 ns; -- 400 MHz

	-- Signals

	signal clk: std_logic := '0'; -- init needed
	signal reset : std_logic := '0';

	signal s_axis_tdata: std_logic_vector(7 downto 0) := X"00";
	signal s_axis_tvalid: std_logic := '0'; -- needed for sim. If, U, data will not start
	signal s_axis_tlast: std_logic;
	signal s_axis_tready: std_logic:='1'; -- init needed for sim

	signal m_axis_tdata: std_logic_vector(7 downto 0);
	signal m_axis_tvalid: std_logic;
	signal m_axis_tlast: std_logic;
	signal m_axis_tready: std_logic := '0';
	signal wr_ctr, rd_ctr:integer := 0;

begin

	clk <= not clk after CLK_PERIOD/2;

	fifo0: entity work.axis_sync_fifo
		port map (
			-- User AXI-Streaming data input (non-blocking)
			s_axis_tdata => s_axis_tdata,
			s_axis_tlast => s_axis_tlast,
			s_axis_tvalid => s_axis_tvalid,
			s_axis_tready => s_axis_tready,

			m_axis_tdata => m_axis_tdata,
			m_axis_tlast => m_axis_tlast,
			m_axis_tvalid => m_axis_tvalid,
			m_axis_tready => m_axis_tready,

			clk => clk,
			rst => reset
			);

    rst_proc: process
    
        begin
            reset <= '1';
            sleep(clk, 10);
            reset <= '0';
            sleep(clk, 10);
            wait;
        end process;
    
    rw_proc: process(all) 
    
            variable buf: line;

    begin
        if rising_edge(clk) then
    
        if not reset then
            if s_axis_tready then
                s_axis_tvalid <= '0';
                if wr_ctr MOD 23 < 5 then
                    s_axis_tdata <= to_slv(unsigned(s_axis_tdata)+1);
                    s_axis_tvalid <= '1';
                    s_axis_tlast <= '1' when wr_ctr mod 17 = 0 else '0';
                end if;
                wr_ctr  <= wr_ctr + 1;
            end if;
    
            rd_ctr <= rd_ctr + 1;
            m_axis_tready <= '1' when rd_ctr mod 7 = 0 or rd_ctr mod 3=0 else '0';
            if m_axis_tvalid and m_axis_tready then
                write(buf, to_string(to_integer(unsigned(m_axis_tdata))) & " tlast=" & to_string(m_axis_tlast));
                writeline(output, buf);
            end if;
        end if;
        end if; -- clk
     end process;

END architecture sim;
