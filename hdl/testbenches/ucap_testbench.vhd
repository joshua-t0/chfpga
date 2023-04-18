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

ENTITY ucap_testbench IS
	generic (
		USE_CHAN_DATA: boolean := TRUE -- minimum to fit bits on lane monitor source 0
		);
END ucap_testbench;


ARCHITECTURE behavior OF ucap_testbench IS

   -- Clock period definitions
   -- constant CLK_PERIOD : time := 3.2 ns;

constant CLK_PERIOD : time := 1000000/375 * 1 ps; -- 375 MHz
constant BSB_CLK_PERIOD : time := 10 ns; --


	--Inputs
	--signal reset : std_logic := '0';


	signal clk: std_logic; -- 200 MHz
	signal rst: std_logic := '1';
	signal bsb_clk: std_logic; -- 200 MHz

	signal tlast_in, tvalid_in: std_logic;
	signal tdata_in: slv112_array(0 to 7);


    signal tlast_out, tvalid_out, tready_out: std_logic;
    signal tdata_out: std_logic_vector(7 downto 0);


	constant NUMBER_OF_PACKETS : integer :=500;


begin



	clk_process: process
	   begin
			clk <= '0';
			wait for CLK_PERIOD/2;
			clk <= '1';
			wait for CLK_PERIOD/2;
	   end process;

    bsbclk_process: process
	   begin
			bsb_clk <= '0';
			wait for BSB_CLK_PERIOD/2;
			bsb_clk <= '1';
			wait for BSB_CLK_PERIOD/2;
	   end process;


	UCAP: entity work.ucap
		--generic map (
		--	IMPLEMENT_PACKET_GENERATOR => TRUE
		-- 	)
		port map (

            mode => "00",
            chan_sel_map => ("000", "001", "010", "011"),

			s_axis_tdata => tdata_in, -- First byte to transmit is in in most significant byte
			s_axis_tvalid => (others => tvalid_in),
			s_axis_tlast => (others => tlast_in),

			m_axis_bsb_tdata => tdata_out,
			m_axis_bsb_tvalid => tvalid_out,
			m_axis_bsb_tlast => tlast_out,
            m_axis_bsb_tready => '1',
            bsb_clk => bsb_clk,
    

			clk=> clk,
			rst => rst
		 );


	sim_proc: process

        variable data: std_logic_vector(255 downto 0);
        variable addr, eop, eot: integer;
        variable dat: slv8_array(0 to 127);
            
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


        sleep(clk, 10); --let the wripe propagate through the FIFO and opcode decoding
        -- send channelizer data
        for frame in 0 to 15 loop
            for word in 0 to 2048-1 loop
                for chan in 0 to 7 loop
                    for sample in 0 to 7 loop 
                        tdata_in(chan)((7-sample)*14+13 downto (7-sample)*14) <=  to_slv(word*8+sample, 14);
                    end loop; -- sample
                end loop; --ch
                tvalid_in <='1';
                tlast_in <= '0';

                if word=2047 then
                    tlast_in <= '1';
                end if;
                sleep(clk);
            end loop; -- bin
        end loop; --frame
        tvalid_in <='0';
 


		wait;
	end process;




END;
