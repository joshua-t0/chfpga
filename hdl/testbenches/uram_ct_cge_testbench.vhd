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

ENTITY uram_ct_cge_testbench IS
	generic (
		USE_CHAN_DATA: boolean := TRUE -- minimum to fit bits on lane monitor source 0
		);
END uram_ct_cge_testbench;


ARCHITECTURE behavior OF uram_ct_cge_testbench IS

   -- Clock period definitions
   -- constant CLK_PERIOD : time := 3.2 ns;

constant CLK_PERIOD : time := 1000000/375 * 1 ps; -- 375 MHz
constant CTRL_CLK_PERIOD : time := 3.2 ns; --
constant REFCLK_PERIOD : time := 6.4 ns; -- 156.25 MHz


	--Inputs
	--signal reset : std_logic := '0';


	signal clk: std_logic; -- 200 MHz
	signal rst: std_logic := '1';
	signal ctrl_clk: std_logic; -- 200 MHz
	signal refclk, refclkb: std_logic; -- 200 MHz

	signal tlast_in, tlast_out, tvalid_in, tvalid_out: std_logic;
	signal tdata_in, tdata_out: std_logic_vector(255 downto 0);

    signal cmd_dat: axis8_dat_struct := (TDATA=>(others=>'0'), TVALID=>'0', TLAST=>'0');
    signal cmd_rdy: axis8_rdy_struct;
    signal rply_dat: axis8_dat_struct;
    signal rply_rdy: axis8_rdy_struct := (TREADY=>'0');
	signal txp, txn: std_logic_vector(3 downto 0);

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


--	refclk_process: process
--	   begin
--			clk <= '0';
--			wait for CLK_PERIOD/2;
--			clk <= '1';
--			wait for CLK_PERIOD/2;
--	   end process;

    bsbclk_process: process
	   begin
			ctrl_clk <= '0';
			wait for CTRL_CLK_PERIOD/2;
			ctrl_clk <= '1';
			wait for CTRL_CLK_PERIOD/2;
	   end process;
--    ctrl_clk <= clk;
    
	refclk_process: process
	   begin
			refclk <= '0';
			wait for REFCLK_PERIOD/2;
			refclk <= '1';
			wait for REFCLK_PERIOD/2;
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

            cmd_dat => cmd_dat,
            cmd_rdy => cmd_rdy,
            rply_dat => rply_dat,
            rply_rdy => rply_rdy,
    

			clk=> clk,
			rst => rst,
			ctrl_clk => ctrl_clk, -- used as init_clk
			ctrl_rst => rst
		 );

    rply_rdy.TREADY <= '1';
    --	rst_proc: process(clk)
    --	begin
    --		if rising_edge(clk) then
    --		end if;
    --	end process;
    refclkb <= not refclk;
	cge0: entity work.cge
		generic map (
			IMPLEMENT_PACKET_GENERATOR => TRUE
		 	)
		port map (
			tx_p => txp,
			tx_n => txn,
			refclk_p => refclk,
			refclk_n => refclkb,

			clk_out => clk,

			s_axis_tx_tdata => tdata_out,
			s_axis_tx_tvalid => tvalid_out,
			s_axis_tx_tlast => tlast_out,

			rst => rst,
			ctrl_clk => ctrl_clk, -- used as init_clk - must be stable! (not clk_out!)
			ctrl_rst => rst
		 );

	sim_proc: process

        variable data: std_logic_vector(255 downto 0);
        variable addr, eop, eot: integer;
	begin

		-- wait for init and synchronize to clock
		tvalid_in <='0';
		tlast_in <= '0';
		rst <= '1';
		-- wait a bit
		sleep(ctrl_clk, 10);
		sleep(clk,10);
        wait for 100 ns;
		-- release reset
		rst <= '0';
		sleep(clk,10);

        -- Program the packet playlist

        -- Enable playlist write
        fpga_write_control(clk=> ctrl_CLK , tdata => cmd_dat.TDATA, tvalid=>cmd_dat.TVALID, tlast => cmd_dat.TLAST, tready=>cmd_rdy.TREADY, addr=> 0, data => 32);
        sleep(clk, 10);
        addr := 0;
        for pkt in 0 to 127 loop
            for bin in 0 to 63 loop
                if bin=0 or bin >10 then
                    eop:= 0;
                    eot:= 0;
                    if bin=63 then
                        eop:= 1;
                        if pkt=127 then
                            eot:=1;
                        end if;
                    end if;
    
                    fpga_write_ram(clk=> ctrl_CLK , tdata => cmd_dat.TDATA, tvalid=>cmd_dat.TVALID, tlast => cmd_dat.TLAST, tready=>cmd_rdy.TREADY, 
                                   addr=> addr*2, data => to_slv8_array(to_unsigned(bin*128 + pkt + 8192 + 16384*eop+32768*eot,16)));
                    addr := addr + 1;
                end if; --bin=0 or > 10
            end loop; --bin
        end loop; --pkt    
        
        if USE_CHAN_DATA then
            -- enable channelizer write
            fpga_write_control(clk=> ctrl_CLK , tdata => cmd_dat.TDATA, tvalid=>cmd_dat.TVALID, tlast => cmd_dat.TLAST, tready=>cmd_rdy.TREADY, addr=> 0, data => 128);
            sleep(clk, 10); --let the wripe propagate through the FIFO and opcode decoding
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
        else    
            -- Program the memory
            for bank in 0 to 1 loop
                for frame in 0 to 15 loop
                    fpga_write_control(clk=> ctrl_CLK , tdata => cmd_dat.TDATA, tvalid=>cmd_dat.TVALID, tlast => cmd_dat.TLAST, tready=>cmd_rdy.TREADY, addr=> 0, data => 16*bank+frame);
                    for bin in 0 to 2047 loop
                        for i in 0 to 3 loop
                            data(64*(3-i)+63 downto 64*(3-i)) := X"B" & to_slv(bank,4) & X"F" & to_slv(frame, 4) & X"B" & to_slv(bin*4+i, 16) & to_slv(0, 64-36);
                        end loop; --i
                        fpga_write_ram(clk=> ctrl_CLK , tdata => cmd_dat.TDATA, tvalid=>cmd_dat.TVALID, tlast => cmd_dat.TLAST, tready=>cmd_rdy.TREADY, addr=> bin*32+frame*8192*32+bank*16*8192*32, data => to_slv8_array(data));
    
                        sleep(ctrl_clk);
                    end loop; -- bin
                end loop; --frame
            end loop; --bin
            fpga_write_control(clk=> ctrl_CLK , tdata => cmd_dat.TDATA, tvalid=>cmd_dat.TVALID, tlast => cmd_dat.TLAST, tready=>cmd_rdy.TREADY, addr=> 0, data => 64); -- auto_trig=1
    
            sleep(clk, 10);
        end if; -- USE_CHAN_DATA    



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
