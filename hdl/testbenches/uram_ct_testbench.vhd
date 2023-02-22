--------------------------------------------------------------------------------
-- @file
-- Company:
-- Engineer:
--
-- Create Date:  2023-02
-- Project Name:  CHORD
-- Target Device: Ultrascale+
-- Tool versions:
-- Description: testbench for the UltraRAM-based, 8 channel, 8k bins, 16 frames corner-turn engine.
--
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

library work;
USE work.chFPGA_Package.all;
use work.tb_package.all;

ENTITY uram_ct_testbench IS
	generic (
		NUMBER_OF_LANES: integer := 6 -- minimum to fit bits on lane monitor source 0
		);
END uram_ct_testbench;


ARCHITECTURE behavior OF uram_ct_testbench IS

   -- Clock period definitions
   -- constant CLK_PERIOD : time := 3.2 ns;

constant CLK_PERIOD : time := 1000000/375 * 1 ps; -- 375 MHz


	--Inputs
	--signal reset : std_logic := '0';


	signal clk: std_logic; -- 200 MHz
	signal rst: std_logic := '1';

	signal tlast_in, tlast_out, tvalid_in, tvalid_out: std_logic;
	signal tdata_in, tdata_out: std_logic_vector(255 downto 0);

	constant NUMBER_OF_PACKETS : integer :=500;

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


	--dut_inst: entity work.cge_test
	--	port map (
	--		tx_p=> txp,
	--		tx_n=> txn,
	--		gt_ref_clk_p => clk,
	--		gt_ref_clk_n => not clk
	--	);


	refclk_process: process
	   begin
			clk <= '0';
			wait for CLK_PERIOD/2;
			clk <= '1';
			wait for CLK_PERIOD/2;
	   end process;



	ct0: entity work.uram_ct
		--generic map (
		--	IMPLEMENT_PACKET_GENERATOR => TRUE
		-- 	)
		port map (
			s_axis_in_tdata => tdata_in, -- First byte to transmit is in in most significant byte
			s_axis_in_tvalid => tvalid_in,
			s_axis_in_tlast => tlast_in,

			m_axis_out_tdata => tdata_out,
			m_axis_out_tvalid => tvalid_out,
			m_axis_out_tlast => tlast_out,

			clk=> clk,
			rst => rst,
			ctrl_clk => clk, -- used as init_clk
			ctrl_rst => rst
		 );

	rst_proc: process(clk)
	begin
		if rising_edge(clk) then
		end if;
	end process;


	sim_proc: process
	begin

		-- wait for init and synchronize to clock
		tvalid_in <='0';
		tlast_in <= '0';
		rst <= '1';
		-- wait a bit
		sleep(clk, 10);

		-- release reset
		rst <= '0';
		sleep(clk);

		-- send channelizer data
		for bank in 0 to 1 loop
			for frame in 0 to 15 loop
				for bin in 0 to 2047 loop
					for i in 0 to 3 loop
						tdata_in(64*(3-i)+63 downto 64*(3-i)) <= X"B" & to_slv(bank,4) & X"F" & to_slv(frame, 4) & X"B" & to_slv(bin*4+i, 16) & to_slv(0, 64-36);
					end loop; --i
					tvalid_in <='1';
					tlast_in <= '0';

					if bin=2047 then
						tlast_in <= '1';
					end if;
					sleep(clk);
				end loop; -- bin
			end loop; --frame
		end loop; --bin
		tvalid_in <='0';
		wait;
	end process;




--rst_proc : process
--	begin
--		reset <= '1';
--		sleep(out_clk, 10);
--		reset <= '0';
--		sleep(out_clk, 257);


--		wait; -- comment out to implement periodic resets


END;
