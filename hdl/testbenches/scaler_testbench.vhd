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

library work;
USE work.chfpga_package.all;
use work.tb_package.all;

ENTITY scaler_testbench IS
 	generic (
       FFT_BITS_PER_BIN: integer := 32+32; -- Real + Imaginary part
        FFT_BINS_PER_WORD: integer := 4;
        FFT_BINS_PER_FRAME: integer:= 8192;
        USE_COMPLEX_GAINS: boolean := FALSE;
        COEFF_BITS_PER_BIN: integer := 16; -- typically 16 or 16+16. Includes both real and imaginary part. If USE_COMPLEX_GAINS=TRUE, half the bits are used for real and half for imaginary. Must be multiple of 8 as it is configured byte-wise.
        OUT_BITS_PER_BIN: integer := 16+16 -- minimum is 4+4, but can be increased to use 8-bit mode or get more of the input data in bypass mode for capture purposes.
   		);
END scaler_testbench;


ARCHITECTURE behavior OF scaler_testbench IS

   -- Clock period definitions

constant IN_CLK_PERIOD : time := 5 ns; -- 200 MHz
constant OUT_CLK_PERIOD : time := 4.096 ns; -- 244 MHz
constant CLK125_period : time := 8 ns;

	constant FFT_BITS_PER_WORD: integer := FFT_BITS_PER_BIN * FFT_BINS_PER_WORD; -- # CROSSBAR top address
	constant OUT_BITS_PER_WORD: integer := OUT_BITS_PER_BIN * FFT_BINS_PER_WORD; -- # CROSSBAR top address
--	constant CROSSBAR_ADDR_INCREMENT : integer := 16#00800#; --
--	constant CROSSBAR_BIN_SEL0_ADDR: integer :=CROSSBAR_BASE_ADDR + 1*CROSSBAR_ADDR_INCREMENT;
--	constant CROSSBAR_BIN_SEL1_ADDR: integer :=CROSSBAR_BASE_ADDR + 2*CROSSBAR_ADDR_INCREMENT;

	--Inputs
	signal reset : std_logic := '0';


	signal in_clk: std_logic; --
	signal out_clk: std_logic; --
	signal clk125: std_logic; --
	signal frame_clk_in: std_logic;

	signal s_axis_tdata: std_logic_vector(FFT_BITS_PER_WORD-1 downto 0);
	signal s_axis_tvalid: std_logic; -- needed for sim. If, U, data will not start
	signal s_axis_tlast: std_logic;
	signal s_axis_tready: std_logic:='1'; -- init needed for sim

	signal m_axis_tdata: std_logic_vector(OUT_BITS_PER_WORD-1 downto 0);
	signal m_axis_tvalid: std_logic;
	signal m_axis_tlast: std_logic;
	signal m_axis_tuser: slv4;

	signal cmd_tdata: slv8;
	signal cmd_tvalid: std_logic;
	signal cmd_tlast: std_logic;
	signal cmd_tready: std_logic;


begin




dut0: entity work.scaler
    generic map (
        FFT_BITS_PER_BIN => FFT_BITS_PER_BIN, -- Real + Imaginary part
        FFT_BINS_PER_WORD=> FFT_BINS_PER_WORD,
        FFT_BINS_PER_FRAME => FFT_BINS_PER_FRAME,
        USE_COMPLEX_GAINS => USE_COMPLEX_GAINS,
        COEFF_BITS_PER_BIN => COEFF_BITS_PER_BIN, -- typically 16 or 16+16. Includes both real and imaginary part. If USE_COMPLEX_GAINS=TRUE, half the bits are used for real and half for imaginary. Must be multiple of 8 as it is configured byte-wise.
        OUT_BITS_PER_BIN=> OUT_BITS_PER_BIN -- minimum is 4+4, but can be increased to use 8-bit mode or get more of the input data in bypass mode for capture purposes.
  )
	port map (


		s_axis_in_tdata  => s_axis_tdata,
		s_axis_in_tvalid => s_axis_tvalid,
		s_axis_in_tlast  => s_axis_tlast,
		s_axis_in_tuser  => "0101", --(ADC overflow, scaler even, scaler odd, FFT overflow)

		m_axis_out_tdata  => m_axis_tdata,
		m_axis_out_tvalid => m_axis_tvalid,
		m_axis_out_tlast  => m_axis_tlast,
		m_axis_out_tuser  => m_axis_tuser,

		clk => out_clk,
		reset => reset,

		-- CTRL_CMD_DAT => (TDATA=> cmd_tdata, TVALID => cmd_tvalid, TLAST => cmd_tlast),
		CTRL_CMD_IN_DAT.TDATA => cmd_tdata,
		CTRL_CMD_IN_DAT.TVALID => cmd_tvalid,
		CTRL_CMD_IN_DAT.TLAST => cmd_tlast,
		CTRL_CMD_IN_RDY.TREADY =>cmd_tready,

		CTRL_RPLY_OUT_DAT => open,
		CTRL_RPLY_OUT_RDY => (TREADY => '1'),

		CTRL_CLK => clk125,
		CTRL_RST => reset
	);

--in_clk_process :process
--   begin
--		in_clk <= '0';
--		wait for IN_CLK_PERIOD/2;
--		in_clk <= '1';
--		wait for IN_CLK_PERIOD/2;
--   end process;

out_clk_process :process
   begin
		out_clk <= '0';
		wait for OUT_CLK_PERIOD/2;
		out_clk <= '1';
		wait for OUT_CLK_PERIOD/2;
   end process;

clk125_process :process
   begin
		clk125 <= '0';
		wait for clk125_period/2;
		clk125 <= '1';
		wait for clk125_period/2;
   end process;

stim_proc : process
	-- variable number_of_selected_bins: integer :=8;
	-- variable number_of_bins_per_frame: integer :=156;
	-- variable number_of_words_per_bin: integer :=4;
	-- variable actual_number_of_input_lanes: integer := 16;
	-- variable number_of_frames_per_packet: integer :=4;
	variable gains: slv_array(0 to FFT_BINS_PER_FRAME-1)(COEFF_BITS_PER_BIN-1 downto 0);
	variable gain_bytes:slv_array(0 to 2*FFT_BINS_PER_FRAME-1)(7 downto 0); -- valid for 16 bits per coeff, real coeff only
	variable page_bits: std_logic_vector(5 downto 0); -- 16384 coeff bytes/page (+14 bits), 2 pages (+1 bit), 512 bytes/page (-9 bits) = 6 bits
    constant SCALER_PAGE_REG: integer := 1; 
    constant SCALER_POSTSCALER_REG: integer := 0;
    variable data_words: slv_array(0 to FFT_BINS_PER_FRAME/4-1)(FFT_BITS_PER_WORD-1 downto 0); -- for 4 bins per word only
    variable sub_word: integer;
	begin
		reset <= '1';
		sleep(out_clk, 10);
		reset <= '0';
		sleep(clk125, 10); -- make sure we start command transmission on a CLK125 edge or we will lose some data


        -- Create gain table - Valid for REAL gains only.
        for i in 0 to FFT_BINS_PER_FRAME-1 loop
--            gains(i) := std_logic_vector(to_signed(4090 + (i MOD 20), COEFF_BITS_PER_BIN));
            gains(i)(15 downto 11) := to_slv(i MOD 32, 5); -- set log gain
            gains(i)(10 downto 0) := to_slv(1, 11); -- set lin gain
            gain_bytes(2*i) := gains(i)(7 downto 0); -- LSB first
            gain_bytes(2*i+1) := gains(i)(15 downto 8); 
        end loop;
        
        -- Program the gain table, page per page
        for page in 0 to 2*FFT_BINS_PER_FRAME/512-1 loop
            page_bits := to_slv(page, page_bits'LENGTH);
		    fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, SCALER_PAGE_REG, 
		      std_logic_vector'(page_bits(5 downto 5) & "0" & page_bits(4 downto 4) & "0" & page_bits(3 downto 0))); -- Set the number of words to select
--		      std_logic_vector'(page_bits(5 downto 5) & "0000000") ); -- Set the number of words to select
            fpga_write_ram(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, gain_bytes(512*page to 512*(page+1)-1));

            -- Set the page registers
        end loop;            
        -- Set log gain
        fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, SCALER_POSTSCALER_REG, 64);  -- 64=bypass
        fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 10, 1 + 128);  -- 1:DATA_MODE=1, 128: use_float_gains=1
        -- Create Test data vector. For 4 bins per word only, 18+18 bits per bin
        for i in 0 to FFT_BINS_PER_FRAME/FFT_BINS_PER_WORD-1 loop
            for j in 0 to FFT_BINS_PER_WORD-1 loop
                sub_word := 3-(i mod 4); -- first bin in upper 36 bits of word
--                data_words(i)((j+1)*FFT_BITS_PER_BIN-1 downto j*FFT_BITS_PER_BIN) := std_logic_vector(to_signed(-16384,FFT_BITS_PER_BIN/2)) & std_logic_vector(to_signed(0,FFT_BITS_PER_BIN/2)); -- Re in upper 18 bits of bin
                data_words(i)((j+1)*FFT_BITS_PER_BIN-1 downto j*FFT_BITS_PER_BIN) := X"00040000_FFFC0000"; -- Re in upper 18 bits of bin
--                data_words(i)(36*sub_word+17 downto 36*sub_word+0) := std_logic_vector(to_signed(0,18)); -- Im in lower 18 bits of bin
            end loop;
        end loop;
		-- fpga_write(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BASE_ADDR + 0, 0); --

		-- for i in 0 to NUMBER_OF_OUTPUT_LANES-1 loop
		-- 	fpga_write(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + i*CROSSBAR_ADDR_INCREMENT + 3, number_of_bins_per_frame); -- Set the number of words to select
		-- 	fpga_write(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + i*CROSSBAR_ADDR_INCREMENT + 4, number_of_words_per_bin); -- Set the number of words to select
		-- 	fpga_write(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + i*CROSSBAR_ADDR_INCREMENT + 5, number_of_frames_per_packet*32 + actual_number_of_input_lanes); -- Set the range of inputs to capture (0 to NUMBER_OF_CROSSBAR_INPUTS-1)
		-- 	fpga_select_bins( clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + i*CROSSBAR_ADDR_INCREMENT, first_bin=>0, bin_step=>10, number_of_bins=>number_of_selected_bins); -- Enable storage and transmission of N frequency bins.
		-- 	-- wait for 2*64*SYSCLK_period; -- prevent the buffers from overflowing by allowing time to send the ethernet framing
		-- 	-- fpga_read(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + 16#200#, 3); -- Re-read the first 8 bytes of the map for debugging
		-- end loop;
		sleep(clk125, 10); -- make sure we start command transmission on a CLK125 edge or we will lose some data

		sleep(out_clk,20);
		-- sleep(clk,start_delay(i));
		for j in 0 to 100 loop
			send_axis_packet(out_clk, s_axis_tdata, s_axis_tvalid, s_axis_tlast, s_axis_tready, data_words); -- 512*244/200=625 clocks = actual duration of  the incoming frames
			-- sleep(clk,1);
		end loop;
		wait;
	end process ; -- lane0_proc

END;
