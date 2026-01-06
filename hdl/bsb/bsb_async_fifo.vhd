----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    2012-10-17
-- Design Name:
-- Module Name:    CMD_ASYNC_FIFO - impl
-- Project Name: chFPGA
-- Target Devices: Virtex 6, Kintex 7, Ultrascale+
-- Tool versions: Vivado 2022.2
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

library xpm;
use xpm.vcomponents.all;

library work;
use work.chFPGA_Package.all; -- Get all component definitions



-- Implements a bidirectional asynchronous FIFO for the Byte-Serial command bus from A to B
entity bsb_async_fifo is
	GENERIC (
		SIM: boolean :=FALSE
		);
     PORT (
		-- Command streams from single slave input to multiple master outputs
		cmd_a_tdata: in std_logic_vector(7 downto 0);
		cmd_a_tvalid: in std_logic;
		cmd_a_tlast: in std_logic;
		cmd_a_tready: out std_logic;
		rply_a_tdata: out std_logic_vector(7 downto 0);
		rply_a_tvalid: out std_logic;
		rply_a_tlast: out std_logic;
		rply_a_tready: in std_logic;
		a_clk: in STD_LOGIC;

		cmd_b_tdata: out std_logic_vector(7 downto 0);
		cmd_b_tvalid: out std_logic;
		cmd_b_tlast: out std_logic;
		cmd_b_tready: in std_logic;
		rply_b_tdata: in std_logic_vector(7 downto 0);
		rply_b_tvalid: in std_logic;
		rply_b_tlast: in std_logic;
		rply_b_tready: out std_logic;
		b_clk: in std_logic;

		-- System interface
		
		rst: in std_logic;
		a_rst_out: out std_logic; -- extended reset pulse synchronous to a_clk
		b_rst_out: out std_logic -- extended reset pulse synchronous to b_clk
		);

end bsb_async_fifo;


architecture impl of bsb_async_fifo is

signal rst_n: std_logic;
signal a_rst, b_rst: std_logic;
signal a_rst_ctr, b_rst_ctr: unsigned(2 downto 0); -- reset will be at least 8 clk long
signal cmd_rd_rst_busy, cmd_wr_rst_busy, rply_rd_rst_busy, rply_wr_rst_busy: std_logic;
signal cmd_a_full, rply_b_full: std_logic;
signal cmd_b_empty, rply_a_empty: std_logic;

begin

-- Command FIFO
-- Independent clock, 9 bits x 16 (minimum), Distributed RAM

cmd_a_tready <= not cmd_a_full;
cmd_b_tvalid <= not cmd_b_empty;
cmd_fifo0: xpm_fifo_async
           generic map (
              FIFO_MEMORY_TYPE => "distributed",
              FIFO_WRITE_DEPTH => 16,   -- 16 is the minimum
              WRITE_DATA_WIDTH => 9,     -- same as READ_DATA_WIDTH
              READ_DATA_WIDTH => 9,      -- 8 data + 1 tlast
              READ_MODE => "fwft"
           )
           port map (
              din =>        cmd_a_tlast & cmd_a_tdata,
              wr_en =>      cmd_a_tvalid and not (a_rst or cmd_wr_rst_busy),  --  Must be low when rst=1 or wr_rst_busy=1
              full =>  cmd_a_full,
              wr_clk =>     a_clk,
              rst =>        a_rst,         -- synchronous to wr_clk.

              dout(8) => cmd_b_tlast,
              dout(7 downto 0) =>  cmd_b_tdata,
              empty => cmd_b_empty,
              rd_en =>      cmd_b_tready and not (b_rst or cmd_rd_rst_busy), -- Must be low when rst=1 or rd_rst_busy=1
              rd_clk =>     b_clk,

              rd_rst_busy => cmd_rd_rst_busy,
              wr_rst_busy => cmd_wr_rst_busy,

              sleep => '0',
              injectsbiterr => '0',
              injectdbiterr => '0'
           );


rply_b_tready <= not rply_b_full;
rply_a_tvalid <= not rply_a_empty;

rply_fifo0: xpm_fifo_async
           generic map (
              FIFO_MEMORY_TYPE => "distributed",
              FIFO_WRITE_DEPTH => 16,   -- 16 is the minimum
              WRITE_DATA_WIDTH => 9,     -- same as READ_DATA_WIDTH
              READ_DATA_WIDTH => 9,      -- 8 data + 1 tlast
              READ_MODE => "fwft"
           )
           port map (
							din    => rply_b_tlast & rply_b_tdata,
							wr_en  => rply_b_tvalid and not (b_rst or rply_wr_rst_busy),  --  Must be low when rst=1 or wr_rst_busy=1
							full   => rply_b_full,
							wr_clk => b_clk,
							rst    => b_rst,         -- synchronous to wr_clk.

							dout(8)          => rply_a_tlast,
							dout(7 downto 0) => rply_a_tdata,
							empty       => rply_a_empty,
							rd_en            => rply_a_tready and not (a_rst or rply_rd_rst_busy), -- Must be low when rst=1 or rd_rst_busy=1
							rd_clk           => a_clk,

              rd_rst_busy => rply_rd_rst_busy,
              wr_rst_busy => rply_wr_rst_busy,

              sleep => '0',
              injectsbiterr => '0',
              injectdbiterr => '0'
           );

-- we have to make sure that the RST signal stays active until there has been a few clocks on both a_clk and B_CLK to make sure the FIFO is reset properly.
arst_proc: process(a_clk, rst)
begin
	if rst then
		a_rst_ctr <= (others => '0');
		a_rst <= '1';
	elsif rising_edge(a_clk) then
		if all_ones(a_rst_ctr) then
			a_rst <= '0';
		else
			a_rst_ctr <= a_rst_ctr + 1;
		end if;
	end if;
end process;

brst_proc: process(all) begin
	if rst then
		b_rst_ctr <= (others => '0');
		b_rst <= '1';
	elsif rising_edge(b_clk) then
		if all_ones(b_rst_ctr) then
			b_rst <= '0';
		else
			b_rst_ctr <= b_rst_ctr + 1;
		end if;
	end if;
end process;

a_rst_out <= a_rst;
b_rst_out <= b_rst;
--rst_n <= not (a_rst or b_rst); -- rst_n is asynchronous, we don't have to worry about resyncing


end impl;

