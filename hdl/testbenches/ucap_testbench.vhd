--------------------------------------------------------------------------------
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
	    NUMBER_OF_CHANNELS: integer := 8; -- Warning: current design works only with NUMBER_OF_CHANNELS = 8
	    NUMBER_OF_SOURCES : integer := 2; -- Warning; current design works only with NUMBER_OF_SOURCES = 2

 		BITS_PER_SAMPLE: integer := 16; 
 		SAMPLES_PER_WORD: integer := 8;
 		SAMPLES_PER_FRAME: integer := 16384
 		);
END ucap_testbench;


ARCHITECTURE behavior OF ucap_testbench IS

   -- Clock period definitions
   -- constant CLK_PERIOD : time := 3.2 ns;

    constant CLK_PERIOD : time := 1000000/375 * 1 ps; -- 375 MHz
    constant BSB_CLK_PERIOD : time := 10 ns; --
    constant CTRL_CLK_PERIOD : time := 10 ns; --
    constant WORDS_PER_FRAME : integer:= SAMPLES_PER_FRAME/SAMPLES_PER_WORD;
    constant ADC_BITS_PER_WORD: integer := BITS_PER_SAMPLE * SAMPLES_PER_WORD;

	--Inputs
	--signal reset : std_logic := '0';


	signal clk: std_logic; -- 200 MHz
	signal rst: std_logic := '1';
	signal bsb_clk: std_logic; -- 200 MHz
	signal bsb_rst: std_logic := '1';
 	signal tlast_in, tvalid_in: std_logic_vector(0 to NUMBER_OF_SOURCES - 1) := (others => '0');
	signal tdata_in: slv_array(0 to NUMBER_OF_CHANNELS-1)(ADC_BITS_PER_WORD -1 downto 0);

    signal source_sel_out: std_logic_vector(0 to NUMBER_OF_CHANNELS - 1); -- data source request
    signal source_sel_in: std_logic_vector(0 to NUMBER_OF_CHANNELS - 1) := (others => '0'); -- curent data source on tdata

    signal tlast_out, tvalid_out, tready_out: std_logic;
    signal tdata_out: std_logic_vector(7 downto 0);

	signal cmd_tdata: slv8;
	signal cmd_tvalid: std_logic;
	signal cmd_tlast: std_logic;
	signal cmd_tready: std_logic;


	constant NUMBER_OF_PACKETS : integer :=500;


begin



	clk_process: process
	   begin
			clk <= '0';
			wait for CLK_PERIOD/2;
			clk <= '1';
			wait for CLK_PERIOD/2;
	   end process;

    -- BSB clock, used for both the output stream and control bus.
    bsbclk_process: process
	   begin
			bsb_clk <= '0';
			wait for BSB_CLK_PERIOD/2;
			bsb_clk <= '1';
			wait for BSB_CLK_PERIOD/2;
	   end process;


	ucap0: entity work.ucap
        generic map (
            NUMBER_OF_CHANNELS => NUMBER_OF_CHANNELS,
            NUMBER_OF_SOURCES => NUMBER_OF_SOURCES
--            ADC_BITS_PER_SAMPLE => BITS_PER_SAMPLE,
--            ADC_SAMPLES_PER_WORD => SAMPLES_PER_WORD,
--            ADC_SAMPLES_PER_FRAME => SAMPLES_PER_FRAME,
--            SIM => TRUE
        )
		port map (


			s_axis_tdata => tdata_in, -- First byte to transmit is in in most significant byte
			s_axis_tvalid => tvalid_in,
			s_axis_tlast => tlast_in,

			m_axis_tdata => tdata_out,
			m_axis_tvalid => tvalid_out,
			m_axis_tlast => tlast_out,
            m_axis_tready => '1',

            m_axis_clk => bsb_clk,
    
            source_sel_out => source_sel_out,
            source_sel_in => source_sel_in,
    
			s_axis_clk => clk,
			rst => rst,

		-- CTRL_CMD_DAT => (TDATA=> cmd_tdata, TVALID => cmd_tvalid, TLAST => cmd_tlast),
		CMD_DAT.TDATA => cmd_tdata,
		CMD_DAT.TVALID => cmd_tvalid,
		CMD_DAT.TLAST => cmd_tlast,
		CMD_RDY.TREADY =>cmd_tready,

		RPLY_DAT => open,
		RPLY_RDY => (TREADY => '1'),

			ctrl_clk => bsb_clk,
			ctrl_rst => bsb_rst
		 );


	sim_proc: process

        variable data: std_logic_vector(255 downto 0);
        variable addr, eop, eot: integer;
        variable dat: slv8_array(0 to 127);
        variable src: integer := 0;  
        variable mode, ch0, ch1: integer;  
	begin

		-- wait for init and synchronize to clock
		tvalid_in(src) <='0';
		tlast_in(src) <= '0';
		rst <= '1';
		bsb_rst <= '1';
		sleep(bsb_clk, 10);
		bsb_rst <= '0';
		sleep(bsb_clk, 10);
		sleep(clk, 10);
		rst <= '0';
        sleep(clk, 10); 

        mode := 2;
        ch0:= 0;
        ch1 := 1;
        fpga_write_control(bsb_clk, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, mode*64 + ch1*8 + ch0);  -- 64=bypass

        -- send channelizer data
        for frame in 0 to 1500 loop
            for word in 0 to WORDS_PER_FRAME-1 loop
                for chan in 0 to NUMBER_OF_CHANNELS-1 loop
                    tdata_in(chan) <= (others => '0');
                    tdata_in(chan)(111 downto 111-7) <= to_slv(chan, 8);
                    tdata_in(chan)(2*16-1 downto 0) <= to_slv(frame, 16) & to_slv(word, 16);
--                    for sample in 0 to SAMPLES_PER_WORD-1 loop 
--                        tdata_in(chan)((7-sample)*14+13 downto (7-sample)*14) <=  to_slv(word*8+sample, 14);
--                        tdata_in(chan)((SAMPLES_PER_WORD-sample)*BITS_PER_SAMPLE-1 downto (SAMPLES_PER_WORD-sample-1)*BITS_PER_SAMPLE) <=  to_slv(frame, BITS_PER_SAMPLE);
--                    end loop; -- sample
                end loop; --ch
                tvalid_in(src) <='1';
                tlast_in(src) <= '0';

                if word = WORDS_PER_FRAME-1 then
                    tlast_in(src) <= '1';
                end if;
                sleep(clk);
            end loop; -- bin
        end loop; --frame
        tvalid_in(src) <='0';
 


		wait;
	end process;




END;
