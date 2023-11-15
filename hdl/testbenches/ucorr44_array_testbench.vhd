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

use std.textio.all;
ENTITY ucorr44_array_testbench IS
	generic (
	    NUMBER_OF_CHANNELS: integer := 8; -- Warning: current design works only with NUMBER_OF_CHANNELS = 8
	    NUMBER_OF_CORRELATORS: integer := 4; -- Warning: current design works only with NUMBER_OF_CHANNELS = 8
--	    NUMBER_OF_SOURCES : integer := 2; -- Warning; current design works only with NUMBER_OF_SOURCES = 2

 		BITS_PER_SAMPLE: integer := 14; 
 		SAMPLES_PER_WORD: integer := 8;
 		SAMPLES_PER_FRAME: integer := 16384;
        NBINS: integer := 16;
 		INTEG_PERIOD : integer:= 2048
 		);
END ucorr44_array_testbench;


ARCHITECTURE behavior OF ucorr44_array_testbench IS

   -- Clock period definitions
   -- constant CLK_PERIOD : time := 3.2 ns;

    constant CLK_PERIOD : time := 1000000/375 * 1 ps; -- 375 MHz
    constant BSB_CLK_PERIOD : time := 10 ns; --
    constant CTRL_CLK_PERIOD : time := 10 ns; --
    constant WORDS_PER_FRAME : integer:= SAMPLES_PER_FRAME/SAMPLES_PER_WORD;
    constant ADC_BITS_PER_WORD: integer := BITS_PER_SAMPLE * SAMPLES_PER_WORD;
    constant NCHAN: integer := NUMBER_OF_CHANNELS;
    constant NCORR: integer:= NUMBER_OF_CORRELATORS;

	--Inputs
	--signal reset : std_logic := '0';


	signal clk: std_logic; -- 200 MHz
	signal rst: std_logic := '1';
	signal bsb_clk: std_logic; -- 200 MHz
	signal bsb_rst: std_logic := '1';
 	signal tlast_in, tvalid_in: std_logic := '0';
	signal tdata_in: slv_array(0 to NUMBER_OF_CHANNELS-1)(31 downto 0);

    signal source_sel_out: std_logic_vector(0 to NUMBER_OF_CHANNELS - 1); -- data source request
    signal source_sel_in: std_logic_vector(0 to NUMBER_OF_CHANNELS - 1) := (others => '0'); -- curent data source on tdata

    signal tlast_out, tvalid_out, tready_out: std_logic;
    signal tdata_out: std_logic_vector(7 downto 0);


	constant NUMBER_OF_PACKETS : integer :=500;


            signal axis_corr_in_tdata: slv_array(0 to NCHAN-1)(31 downto 0);
            signal axis_corr_in_tvalid: std_logic;
            signal axis_corr_in_tlast: std_logic;
        
            signal axis_corr_out_tdata: std_logic_vector(7 downto 0);
            signal axis_corr_out_tvalid: std_logic;
            signal axis_corr_out_tlast: std_logic;
            signal axis_corr_out_tready: std_logic:='1';

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

       ucorr44_array0: entity work.ucorr44_array
            generic map (
                PLATFORM_ID => PLATFORM_ID_CRS, -- needed to determine the RPM spacing of the DSP and BRAM elements and choose the right primitives
                NCHAN => NCHAN, 
                NCORR   => NCORR,
                NBINS_TO_READOUT => NBINS
                )
            port map(
                -- Input data interface (AXI4-Streaning, non-blocking)
                -- One input per channelizer
    
                s_axis_data_tvalid           => tvalid_in,
                s_axis_data_tlast            => tlast_in,
                s_axis_data_tdata            => tdata_in,
    
                clk                  => clk,
                rst                  => rst,
    
                -- Correlated data output interface (AXI4-Streaning, 8-bit wide, blocking)
    
                m_axis_data_tdata   => axis_corr_out_tdata,
                m_axis_data_tvalid  => axis_corr_out_tvalid,
                m_axis_data_tlast   => axis_corr_out_tlast,
                m_axis_data_tready  => axis_corr_out_tready,
    
                -- Control interface
    
                s_axis_bsb_DAT  => (TDATA=>(others => '0'),TVALID=>'0',TLAST=>'0'),
                s_axis_bsb_RDY  => open,
                m_axis_bsb_DAT => open,
                m_axis_bsb_RDY => (TREADY => '1'),
                CTRL_CLK => bsb_clk,
                CTRL_RST => bsb_rst
                );

	sim_proc: process

        variable data: std_logic_vector(255 downto 0);
        variable addr, eop, eot: integer;
        variable dat: slv8_array(0 to 127);
        variable src: integer := 0;
        variable bin:integer;    
	begin

		-- wait for init and synchronize to clock
		tlast_in <= '0';
		tvalid_in <= '0';
		rst <= '1';
		bsb_rst <= '1';
		sleep(bsb_clk, 10);
		bsb_rst <= '0';
		sleep(bsb_clk, 10);
		sleep(clk, 10);
		rst <= '0';
        sleep(clk, 10); 

        -- send channelizer data
        loop
            for word in 0 to NBINS-1 loop
--                for chan in 0 to NUMBER_OF_CHANNELS-1 loop
--                    tdata_in(chan) <= (others => '0');
--                    tdata_in(chan)(111 downto 111-7) <= to_slv(chan, 8);
--                    tdata_in(chan)(2*16-1 downto 0) <= to_slv(frame, 16) & to_slv(word, 16);
----                    for sample in 0 to SAMPLES_PER_WORD-1 loop 
----                        tdata_in(chan)((7-sample)*14+13 downto (7-sample)*14) <=  to_slv(word*8+sample, 14);
----                        tdata_in(chan)((SAMPLES_PER_WORD-sample)*BITS_PER_SAMPLE-1 downto (SAMPLES_PER_WORD-sample-1)*BITS_PER_SAMPLE) <=  to_slv(frame, BITS_PER_SAMPLE);
----                    end loop; -- sample
--                end loop; --ch
                for b in 0 to 3 loop
                    bin := 4*word + b;
                    for ch in 0 to NCHAN-1 loop
                        tdata_in(ch)(8*(3-b)+7 downto 8*(3-b)) <= std_logic_vector(to_unsigned((bin MOD 16)*16,8));
                    end loop;
                end loop;
--        		tdata_in <=(X"10101010", X"20202020", X"30303030", X"40404040", X"50505050", X"60606060", X"70707070",X"F0F0F0F0");
                tvalid_in <='1';
                tlast_in <= '0';

                if word = NBINS-1 then
                    tlast_in <= '1';
                end if;
                sleep(clk);
            end loop; -- bin
        end loop; --frame
        tvalid_in <='0';
 


		wait;
	end process;

decode_proc: process(clk)
        constant NPROD: integer := NCHAN*(NCHAN+1)/2;
        variable bytes: slv8_array(0 to (10 + 5 *NPROD)-1);
        variable data: unsigned(8*(10+5*NPROD)-1 downto 0);
        variable byte_ctr: integer := 0;
        variable cookie: integer;
        variable bin: integer;
        variable ts: integer;
        variable re, im: integer;
        variable buf: line;
        variable clk_ctr:unsigned(1 downto 0) := "00";
        variable prod_bits: std_logic_vector(5*8-1 downto 0);
	begin

        if rising_edge(clk) then
            clk_ctr := clk_ctr + 1;
            axis_corr_out_tready <= to_std_logic(clk_ctr="00");
            if  axis_corr_out_tvalid then
                bytes(byte_ctr) := axis_corr_out_tdata;
                byte_ctr := byte_ctr +1;
                if axis_corr_out_tlast then
                    cookie := to_integer(unsigned(bytes(0)));
                    assert cookie=16#CF# report "Invalid cookie" severity FAILURE;
                    bin := to_integer(to_unsigned(bytes(1 to 2)));
                    ts := to_integer(to_unsigned(bytes(4 to 9)));

                    write(buf, "ts=" & str(ts) & " bin=" & str(bin) & ": ");
--                    writeline(output, buf);
                    for p in 0 to (byte_ctr-10)/5-1 loop
                        prod_bits := reverse_bytes(std_logic_vector(to_unsigned(bytes(10+5*P to 10+5*p+5-1))));
--                        re := to_integer(signed(prod_bits(4+18-1 downto 4)));                       
--                        im := to_integer(signed(prod_bits(4+36-1 downto 4+18)));
                        re := to_integer(signed(prod_bits(35 downto 18)));                       
                        im := to_integer(signed(prod_bits(17 downto 0)));
                        write(buf, "(" & str(re) & "+" & str(im) & "i) ");
                    end loop;                       
                    writeline(output, buf);
                    assert byte_ctr=50 report("bad packet length") severity failure;
                    byte_ctr := 0;
                end if;
            end if; -- tvalid
        end if; -- clk

	end process;




END;
