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
	   PLATFORM_ID: integer  := PLATFORM_ID_CRS;
	    NCHAN: integer := 8; 
        NBINS: integer := 2048;-- bins per correlator (not total)
        NBINS_MAX: integer := 2048;-- max bins per correlator (not total) - sets memory depth
	    NCORR: integer := 4;
	    NINTEG: integer := 8192; -- 1024 is ok for autocorr only. requires 2048*1024*2.5ns clocks,= 
	    N_BINS_PER_WORD: integer := 4;
	    N_BITS_PER_BIN: integer := 4+4;
	    AUTOCORR_ONLY: boolean := TRUE 
 		);
END ucorr44_array_testbench;


ARCHITECTURE behavior OF ucorr44_array_testbench IS

   -- Clock period definitions
   -- constant CLK_PERIOD : time := 3.2 ns;

    constant CLK_PERIOD : time := 1000000/400 * 1 ps; -- 400 MHz
    constant BSB_CLK_PERIOD : time := 10 ns; --
	constant NUMBER_OF_PACKETS : integer :=500;


	signal clk: std_logic; -- 400 MHz
	signal rst: std_logic := '1';
	signal bsb_clk: std_logic; -- 200 MHz
	signal bsb_rst: std_logic := '1';

    signal clk_ctr:unsigned(2 downto 0) := (others => '0');

 	signal tlast_in, tvalid_in: std_logic := '0';
	signal tdata_in: std_logic_vector(255 downto 0);

    signal source_sel_out: std_logic_vector(0 to NCHAN - 1); -- data source request
    signal source_sel_in: std_logic_vector(0 to NCHAN - 1) := (others => '0'); -- curent data source on tdata

    signal tlast_out, tvalid_out, tready_out: std_logic;
    signal tdata_out: std_logic_vector(7 downto 0);



    signal ct_in_tdata: slv32_array(0 to NCHAN - 1) := (others => (others => '0'));
    signal ct_in_tuser: slv_array(0 to NCHAN - 1)(3 downto 0);
    signal ct_in_tvalid: std_logic;
    signal ct_in_tlast: std_logic;


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
    bsbclk_process: process begin
        bsb_clk <= '0';
        wait for BSB_CLK_PERIOD/2;
        bsb_clk <= '1';
        wait for BSB_CLK_PERIOD/2;
   end process;

    ct0: entity work.u_ct_engine
        generic map (
            PLATFORM_ID => PLATFORM_ID,
            NUMBER_OF_INPUT_LANES => NCHAN, -- Number of channelizer inputs
            CT_LEVEL => 1 -- Corner-turning level: 1: single-board (local) only (no backplane), 2: Option 1 plus 4x4 subbackplane corner-turn (4 boards, using GTY), 3: Option 2 + additional 4x4 corner-turn between 2 or 4 sub-backplanes (8 or 16 boards)
        )
        port map (
            -- Non-blocking input stream from the channelizer, synchronous to `clk`
            s_axis_tdata => ct_in_tdata,
            s_axis_tvalid => ct_in_tvalid, -- we assume all lanes are aligned and therefore use only one `tvalid`
            s_axis_tlast => ct_in_tlast, -- idem

            -- Non-blocking output stream, synchronous to `clk`
            m_axis_tdata => tdata_in,
            m_axis_tvalid => tvalid_in,
            m_axis_tlast => tlast_in,

            axis_clk => clk,

            -- Backplane 25 Gbps GTY links
--            tx_p      => bp_shuffle_tx_p,
--            tx_n      => bp_shuffle_tx_n,
--            rx_p      => bp_shuffle_rx_p,
--            rx_n      => bp_shuffle_rx_n,
--            refclk_p  => bp_shuffle_refclk_p,
--            refclk_n  => bp_shuffle_refclk_n,


            rst => rst, -- synchronous reset (sync to ct_clk, which is derived from corr_reset)
            arst => rst, -- asynchronous reset that is independent from ct_clk (because reset stops bp_shuffle_txclk and therefore ct_clk)

            -- Control interface (command and reply stream buses)
            bsb_cmd_dat  => (TDATA=>(others => '0'),TVALID=>'0',TLAST=>'0'),
            bsb_cmd_rdy  => open,
            bsb_rply_dat => open,
            bsb_rply_rdy => (TREADY => '1'),
            bsb_clk      => bsb_clk,
            bsb_rst      => bsb_rst
        );



       ucorr44_array0: entity work.ucorr44_array
            generic map (
                PLATFORM_ID => PLATFORM_ID_CRS, -- needed to determine the RPM spacing of the DSP and BRAM elements and choose the right primitives
                NCHAN => NCHAN, 
                NCORR   => NCORR,
                NBINS_PER_CORR => NBINS_MAX,
                BIN_DECIMATION_FACTOR => 1,
                SOFT_NINTEG => NINTEG,
                SOFT_AUTOCORR_ONLY => AUTOCORR_ONLY,
                READOUT_BINS => (others=>0)
                )
            port map(
                -- Input data interface (AXI4-Streaning, non-blocking)
                -- One input per channelizer
    
                s_axis_data_tvalid => tvalid_in,
                s_axis_data_tlast  => tlast_in,
                s_axis_data_tdata  => tdata_in,
    
                clk => clk,
                rst => rst,
    
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
        variable rb: integer;
        variable re, im: integer;
        variable lsb, rch, rbin: integer;   
	begin

		-- wait for init and synchronize to clock
		ct_in_tlast <= '0';
		ct_in_tvalid <= '0';
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
                for ch in 0 to NCHAN-1 loop
                    rch := NCHAN-1-ch;
                    for b in 0 to N_BINS_PER_WORD-1 loop
                        rbin := N_BINS_PER_WORD-1-b;
                        bin := N_BINS_PER_WORD * word + b; -- bin number
                        rb := N_BINS_PER_WORD-1-b;  -- reverse-order bin index in word
--                        re := (bin MOD 16);
--                        im := -1;
                          re := 1;
                          im := 0;
--                        lsb := N_BITS_PER_BIN * (rbin + rch*N_BINS_PER_WORD);
--                        tdata_in(lsb + N_BITS_PER_BIN -1 downto lsb) <= to_slv(re, N_BITS_PER_BIN/2) & to_slv(im, N_BITS_PER_BIN/2);
                        ct_in_tdata(ch)(8*(rbin+1)-1 downto 8*(rbin+1)-N_BITS_PER_BIN) <= to_slv(re, N_BITS_PER_BIN/2) & to_slv(im, N_BITS_PER_BIN/2);
                    end loop;
                end loop;
--        		tdata_in <=(X"10101010", X"20202020", X"30303030", X"40404040", X"50505050", X"60606060", X"70707070",X"F0F0F0F0");
--                tvalid_in <='1';
--                tlast_in <= '0';
                ct_in_tvalid <='1';
                ct_in_tlast <= '0';

                if word = NBINS-1 then
                    ct_in_tlast <= '1';
                end if;
                sleep(clk);
            end loop; -- bin
        end loop; --frame
        ct_in_tvalid <='0';
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
        variable flags: std_logic_vector(7 downto 0);
        variable re, im: integer;
        variable buf: line;
        variable prod_bits: std_logic_vector(5*8-1 downto 0);
        constant expected_length: integer := sel(AUTOCORR_ONLY, NCHAN, NPROD)*5+10;
	begin

        if rising_edge(clk) then
            clk_ctr <= clk_ctr + 1;
            axis_corr_out_tready <= to_std_logic(clk_ctr(2) = '1');
--            axis_corr_out_tready <= '1';

            if  axis_corr_out_tvalid then
                bytes(byte_ctr) := axis_corr_out_tdata;
                byte_ctr := byte_ctr +1;
                if axis_corr_out_tlast then
                    cookie := to_integer(unsigned(bytes(0)));
                    assert cookie=16#CF# report "Invalid cookie" severity FAILURE;
                    bin := to_integer(to_unsigned(bytes(1 to 2)));
                    ts := to_integer(to_unsigned(bytes(4 to 9)));
                    flags := bytes(3);
                    assert flags(0) = '0' report "Overrun" severity WARNING;

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
                    assert byte_ctr=expected_length report("bad packet length of " & to_string(byte_ctr) & "bytes") severity failure;
                    byte_ctr := 0;
                end if;
            end if; -- tvalid
        end if; -- clk

	end process;




END;
