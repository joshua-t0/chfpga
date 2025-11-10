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
USE ieee.math_complex.ALL;
USE std.env.finish;
USE std.textio.all;

library work;
USE work.chFPGA_Package.all;
use work.tb_package.all;

ENTITY ucorr44_testbench IS
	generic (
	    N: integer := 64; -- Warning: current design works only with NUMBER_OF_CHANNELS = 8
	    NCHAN_PER_CLK: integer := 32;
	    N_BINS: integer := 128; -- must be >
	    N_INTEG: integer := 150;
	    BIN_DECIMATION_FACTOR: integer := 8
 		);
END ucorr44_testbench;


ARCHITECTURE behavior OF ucorr44_testbench IS

   -- Clock period definitions
   -- constant CLK_PERIOD : time := 3.2 ns;

    constant CLK_PERIOD : time := 2 ns; -- 375 MHz
    constant NCLK_PER_BIN: integer := N/NCHAN_PER_CLK;
	--Inputs
	--signal reset : std_logic := '0';


	signal clk: std_logic; -- 200 MHz
	signal rst: std_logic := '1';
--	signal bsb_clk: std_logic; -- 200 MHz
--	signal bsb_rst: std_logic := '1';
 	signal tlast_in, tvalid_in: std_logic := '0';
	signal tdata_in: slv_array(0 to NCHAN_PER_CLK-1)(7 downto 0);

    signal tlast_out, tvalid_out: std_logic;
    signal tdata_out: std_logic_vector(7 downto 0);


--	constant NUMBER_OF_PACKETS : integer :=500;


begin
	clk_process: process
	   begin
			clk <= '0';
			wait for CLK_PERIOD/2;
			clk <= '1';
			wait for CLK_PERIOD/2;
	   end process;

 	UCORR440: entity work.ucorr44
        generic map (
            NCHAN => N,
            NCHAN_PER_CLK => NCHAN_PER_CLK,
            NBINS => N_BINS,
            BIN_DECIMATION_FACTOR => BIN_DECIMATION_FACTOR,
            NCORR => 8,
            CORR_NUMBER => 0
        )
		port map (
			s_axis_tdata => tdata_in, -- First byte to transmit is in in most significant byte
			s_axis_tvalid => tvalid_in,
			s_axis_tlast => tlast_in,

			z_out_tdata => tdata_out,
			z_out_tvalid => tvalid_out,
			z_out_tlast => tlast_out,
            z_out_send => '1',

            integ_period => to_slv(N_INTEG-1, 16),
            autocorr_only => '0',
            no_accum => '0',
            corr_id => "0000",

            overrun_reset => '0',

			clk=> clk,
			rst => rst
		 );


	sim_proc: process

        variable data: std_logic_vector(255 downto 0);
        variable addr, eop, eot: integer;
        variable dat: slv8_array(0 to 127);
        variable src: integer := 0;
        variable ix: integer;     
	begin

		tlast_in <= '0';
		tvalid_in <= '0';
		tdata_in <= (others => (others => '0'));
		rst <= '1';
		sleep(clk, 10);
		rst <= '0';
        sleep(clk, 10); 

        -- send channelizer data
        for frame in 0 to 1000*N_INTEG loop
            for bin in 0 to N_BINS-1 loop
                for word in 0 to NCLK_PER_BIN-1 loop
                    for sample in 0 to NCHAN_PER_CLK-1 loop
--                        tdata_in(sample) <= x"10" when bin=BIN_DECIMATION_FACTOR-1 and word=0 and sample=0 else x"00";
--                        tdata_in(sample) <= to_slv(sample + NCHAN_PER_CLK * (word + NCLK_PER_BIN * bin), 8) and x"07";
                        tdata_in(sample) <= to_slv(word*32+sample, 8);
--                        tdata_in(sample) <= to_slv(1, 8);
                    end loop; -- sample
                    tvalid_in <= '1';
                    tlast_in <= '0';
                    if word = NCLK_PER_BIN-1 and bin=N_BINS-1 then
                        tlast_in <= '1';
                    end if;
                    sleep(clk);
                end loop; --word
            end loop; -- bin
        end loop; --frame
        tvalid_in <='0'; 
        finish;
	end process;

cap_blk: block

        signal byte_ctr, bin: integer := 0;
    
begin

	capture_proc: process(clk)
        variable is_header: boolean := true;
        variable header_bytes: slv8_array(0 to 9);
        variable prod_word: std_logic_vector(39 downto 0); 
        variable prod: complex;
        variable prod_ctr: integer;
        variable re, im: integer;
        variable buf: line;
        variable cookie: integer;
        variable bin: integer;
        variable ts: integer;
        
	begin
        if rising_edge(clk) then
--            sleep(clk);
--            wait for 10 ps;
            if tvalid_out then
                byte_ctr <= byte_ctr + 1;
--                write(buf, "Byte # " & to_string(byte_ctr) & "= 0x" & to_hstring(unsigned(tdata_out)));
--                writeline(output, buf);

                if is_header then
                    header_bytes(byte_ctr) := tdata_out;
                    if byte_ctr = 10-1 then
                        byte_ctr <= 0;
                        prod_ctr := 0;
                        is_header := False;        
                        cookie := to_integer(unsigned(header_bytes(0)));
                        assert cookie=16#CF# report "Invalid cookie" severity FAILURE;
                        bin := to_integer(to_unsigned(header_bytes(1 to 2)));
                        ts := to_integer(to_unsigned(header_bytes(4 to 9)));
                        write(buf, "Starting Frame #" & to_string(ts) & " bin #" & to_string(bin));
                        writeline(output, buf);
                        end if;
                else -- not header
--                    prod_word((4-byte_ctr)*8+7 downto (4-byte_ctr)*8) := tdata_out;
                    prod_word((byte_ctr)*8+7 downto (byte_ctr)*8) := tdata_out;
                    if byte_ctr=4 then
                        byte_ctr <= 0;
--                        prod := COMPLEX'(real(to_integer(signed(prod_word(35 downto 18)))), real(to_integer(signed(prod_word(17 downto 0)))));
                        re := to_integer(signed(prod_word(35 downto 18)));                       
                        im := to_integer(signed(prod_word(17 downto 0)));
                       write(buf, "Prod #" & to_string(prod_ctr) & ":" & to_string(Re) & " + i" & to_string(Im)) ;
                       writeline(output, buf);
                       prod_ctr := prod_ctr + 1;
                    end if; --last byte
                end if; --header
                if tlast_out then
                    byte_ctr <= 0;
                    is_header:= true;
                end if;

           end if; --tvalid                 
--        end loop; --while True
            end if;
	end process;

end block cap_blk;


END;
