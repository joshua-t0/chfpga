--------------------------------------------------------------------------------
-- @file
-- Company:
-- Engineer:
--
-- Create Date:
-- Design Name:
-- Module Name:
-- Project Name:
-- Target Device:
-- Tool versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes:
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.env.finish;

library work;
USE work.chfpga_package.all;
use work.tb_package.all;

ENTITY scaler_mul_testbench IS
END scaler_mul_testbench;


ARCHITECTURE behavior OF scaler_mul_testbench IS

   -- Clock period definitions

constant CLK_PERIOD : time := 2 ns; -- 500 MHz

--	constant FFT_BITS_PER_WORD: integer := FFT_BITS_PER_BIN * FFT_BINS_PER_WORD; -- # CROSSBAR top address
--	constant OUT_BITS_PER_WORD: integer := OUT_BITS_PER_BIN * FFT_BINS_PER_WORD; -- # CROSSBAR top address
--	constant CROSSBAR_ADDR_INCREMENT : integer := 16#00800#; --
--	constant CROSSBAR_BIN_SEL0_ADDR: integer :=CROSSBAR_BASE_ADDR + 1*CROSSBAR_ADDR_INCREMENT;
--	constant CROSSBAR_BIN_SEL1_ADDR: integer :=CROSSBAR_BASE_ADDR + 2*CROSSBAR_ADDR_INCREMENT;

	--Inputs
	signal reset : std_logic := '0';


	signal clk: std_logic; --
--	signal out_clk: std_logic; --
--	signal clk125: std_logic; --
--	signal frame_clk_in: std_logic;

--	signal s_axis_tdata: std_logic_vector(FFT_BITS_PER_WORD-1 downto 0);
--	signal s_axis_tvalid: std_logic; -- needed for sim. If, U, data will not start
--	signal s_axis_tlast: std_logic;
--	signal s_axis_tready: std_logic:='1'; -- init needed for sim

--	signal m_axis_tdata: std_logic_vector(OUT_BITS_PER_WORD-1 downto 0);
--	signal m_axis_tvalid: std_logic;
--	signal m_axis_tlast: std_logic;
--	signal m_axis_tuser: slv4;

--	signal cmd_tdata: slv8;
--	signal cmd_tvalid: std_logic;
--	signal cmd_tlast: std_logic;
--	signal cmd_tready: std_logic;
    signal a: signed(15 downto 0);
    signal b: signed(31 downto 0);
    signal p: signed(47 downto 0);

    signal a_values: integer_array(0 to 8) := (0, -1, 1, -100, 100, -17000, 27812, -32768, 32767);
    signal b_values: integer_array(0 to 12) := (0, -1, 1, 98, -98, 32768, -32768, -50000, 50000, -200000, 200000, -2**31, 2**31-1);
    
begin




dut0: entity work.scaler_mul
    generic map (
        A_WIDTH=> a'LENGTH,
        B_WIDTH=> b'LENGTH
  )
	port map (

        a => a,
        b => b,
        p => p,
		clk => clk,
		rst => reset
	);


clk_process :process
   begin
		clk <= '0';
		wait for CLK_PERIOD/2;
		clk <= '1';
		wait for CLK_PERIOD/2;
   end process;

stim_proc : process
	-- variable number_of_selected_bins: integer :=8;
	-- variable number_of_bins_per_frame: integer :=156;
	-- variable number_of_words_per_bin: integer :=4;
	-- variable actual_number_of_input_lanes: integer := 16;
	-- variable number_of_frames_per_packet: integer :=4;
--	variable gains: slv_array(0 to FFT_BINS_PER_FRAME-1)(COEFF_BITS_PER_BIN-1 downto 0);
--	variable gain_bytes:slv_array(0 to 2*FFT_BINS_PER_FRAME-1)(7 downto 0); -- valid for 16 bits per coeff, real coeff only
--	variable page_bits: std_logic_vector(5 downto 0); -- 16384 coeff bytes/page (+14 bits), 2 pages (+1 bit), 512 bytes/page (-9 bits) = 6 bits
--    constant SCALER_PAGE_REG: integer := 1;
--    constant SCALER_POSTSCALER_REG: integer := 0;
--    variable data_words: slv_array(0 to FFT_BINS_PER_FRAME/4-1)(FFT_BITS_PER_WORD-1 downto 0); -- for 4 bins per word only
--    variable sub_word: integer;
	begin
		reset <= '1';
		sleep(clk, 2);
		reset <= '0';
--		a <= to_signed(10, 16);
--		b <= to_signed(10, 32);
		sleep(clk, 2); -- make sure we start command transmission on a CLK125 edge or we will lose some data

        for i in a_values'RANGE  loop
            for j in b_values'RANGE loop
                a <= to_signed(a_values(i), a'LENGTH);
                b <= to_signed(b_values(j), b'LENGTH);
                sleep(clk,4);
                assert to_integer(p)= a_values(i)*b_values(j) report "Bad product p=" & to_string(to_integer(p)) & " expected p= " & to_string(a_values(i)*b_values(j))  SEVERITY FAILURE; 
            end loop;    
        end loop;
        sleep(clk,10);
        finish;

--        -- Create gain table - Valid for REAL gains only.
--        for i in 0 to FFT_BINS_PER_FRAME-1 loop
--            gains(i) := std_logic_vector(to_signed(4090 + (i MOD 20), COEFF_BITS_PER_BIN));
--            gain_bytes(2*i) := gains(i)(7 downto 0); -- LSB first
--            gain_bytes(2*i+1) := gains(i)(15 downto 8);
--        end loop;

--        -- Program the gain table
--        for page in 0 to 2*FFT_BINS_PER_FRAME/512-1 loop
--            page_bits := to_slv(page, page_bits'LENGTH);
--		    fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, SCALER_PAGE_REG,
--		      std_logic_vector'(page_bits(5 downto 5) & "0" & page_bits(4 downto 4) & "0" & page_bits(3 downto 0))); -- Set the number of words to select
----		      std_logic_vector'(page_bits(5 downto 5) & "0000000") ); -- Set the number of words to select
--            fpga_write_ram(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, gain_bytes(512*page to 512*(page+1)-1));

--            -- Set the page registers
--        end loop;
--        -- Set log gain
--        fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, SCALER_POSTSCALER_REG, 18 + 32);
--        -- Create Test data vector. For 4 bins per word only, 18+18 bits per bin
--        for i in 0 to FFT_BINS_PER_FRAME-1 loop
--            sub_word := 3-(i mod 4); -- first bin in upper 36 bits of word
--            data_words(i/4)(36*sub_word+35 downto 36*sub_word+18) := std_logic_vector(to_signed(-4,18)); -- Re in upper 18 bits of bin
--            data_words(i/4)(36*sub_word+17 downto 36*sub_word+0) := std_logic_vector(to_signed(-4,18)); -- Im in lower 18 bits of bin
--        end loop;

--		-- fpga_write(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BASE_ADDR + 0, 0); --

--		-- for i in 0 to NUMBER_OF_OUTPUT_LANES-1 loop
--		-- 	fpga_write(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + i*CROSSBAR_ADDR_INCREMENT + 3, number_of_bins_per_frame); -- Set the number of words to select
--		-- 	fpga_write(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + i*CROSSBAR_ADDR_INCREMENT + 4, number_of_words_per_bin); -- Set the number of words to select
--		-- 	fpga_write(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + i*CROSSBAR_ADDR_INCREMENT + 5, number_of_frames_per_packet*32 + actual_number_of_input_lanes); -- Set the range of inputs to capture (0 to NUMBER_OF_CROSSBAR_INPUTS-1)
--		-- 	fpga_select_bins( clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + i*CROSSBAR_ADDR_INCREMENT, first_bin=>0, bin_step=>10, number_of_bins=>number_of_selected_bins); -- Enable storage and transmission of N frequency bins.
--		-- 	-- wait for 2*64*SYSCLK_period; -- prevent the buffers from overflowing by allowing time to send the ethernet framing
--		-- 	-- fpga_read(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + 16#200#, 3); -- Re-read the first 8 bytes of the map for debugging
--		-- end loop;
--		sleep(clk125, 10); -- make sure we start command transmission on a CLK125 edge or we will lose some data

--		sleep(out_clk,20);
--		-- sleep(clk,start_delay(i));
--		for j in 0 to 100 loop
--			send_axis_packet(out_clk, s_axis_tdata, s_axis_tvalid, s_axis_tlast, s_axis_tready, data_words); -- 512*244/200=625 clocks = actual duration of  the incoming frames
--			-- sleep(clk,1);
--		end loop;
--		wait;
	end process ; -- lane0_proc

END;
