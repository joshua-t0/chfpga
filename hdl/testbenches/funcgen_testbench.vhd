--------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:   17:23:04 11/17/2010
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
USE work.chFPGA_Package.all;
use work.tb_package.all;

ENTITY funcgen_testbench IS
 	generic (
 		BITS_PER_SAMPLE: integer := 14; 
 		SAMPLES_PER_WORD: integer := 8;
 		SAMPLES_PER_FRAME: integer := 16384;
 		FUNCGEN_TUSER_BITS_PER_WORD: integer := 1
 		);
END funcgen_testbench;


ARCHITECTURE behavior OF funcgen_testbench IS

   -- Clock period definitions

	constant IN_CLK_PERIOD : time := 5 ns; -- 200 MHz
	--constant OUT_CLK_PERIOD : time := 4.096 ns; -- 244 MHz
	constant CLK125_period : time := 8 ns;

	-- SYSTEM Port modules
	--constant CROSSBAR_BASE_ADDR      : integer := 16#60000#; -- # CROSSBAR top address
	--constant CROSSBAR_ADDR_INCREMENT : integer := 16#00800#; --
	--constant CROSSBAR_BIN_SEL0_ADDR: integer :=CROSSBAR_BASE_ADDR + 1*CROSSBAR_ADDR_INCREMENT;
	--constant CROSSBAR_BIN_SEL1_ADDR: integer :=CROSSBAR_BASE_ADDR + 2*CROSSBAR_ADDR_INCREMENT;

	--Inputs
    subtype sample is std_logic_vector(BITS_PER_SAMPLE-1 downto 0); 
    type sample_array is array (0 to SAMPLES_PER_FRAME-1) of sample;
    constant BYTES_PER_FRAME: integer := (BITS_PER_SAMPLE+7)/8*SAMPLES_PER_FRAME;
	signal clk: std_logic; --
	signal out_clk: std_logic; --
	signal clk125: std_logic; --
	signal frame_clk_in: std_logic;

	signal s_axis_tdata: std_logic_vector(BITS_PER_SAMPLE*SAMPLES_PER_WORD-1 downto 0);
	signal s_axis_tvalid: std_logic; -- needed for sim. If, U, data will not start
	signal s_axis_tlast: std_logic;
	signal s_axis_tready: std_logic:='1'; -- init needed for sim



	signal m_axis_tdata: std_logic_vector(BITS_PER_SAMPLE*SAMPLES_PER_WORD-1 downto 0);
	signal m_axis_tvalid: std_logic;
	signal m_axis_tlast: std_logic;
	signal m_axis_tuser: std_logic_vector(3 downto 0);

	signal cmd_tdata: slv8;
	signal cmd_tvalid: std_logic;
	signal cmd_tlast: std_logic;
	signal cmd_tready: std_logic;

	signal ctrl_rst: std_logic;
	signal rst: std_logic;

begin

funcgen0: entity work.funcgen
    generic map (
 		ADC_BITS_PER_SAMPLE => BITS_PER_SAMPLE, 
 		ADC_SAMPLES_PER_WORD => SAMPLES_PER_WORD,
 		ADC_SAMPLES_PER_FRAME => SAMPLES_PER_FRAME
)
	port map (
		s_axis_adc_tdata  => s_axis_tdata,
		s_axis_adc_tvalid => s_axis_tvalid,
		s_axis_adc_tlast  => s_axis_tlast,
		s_axis_adc_tuser  => (others => '0'), --(ADC overflows)

		m_axis_adc_tdata  => m_axis_tdata,
		m_axis_adc_tvalid => m_axis_tvalid,
		m_axis_adc_tlast  => m_axis_tlast,
		m_axis_adc_tuser  => m_axis_tuser,

		clk => clk,
		rst => rst,

		-- CTRL_CMD_DAT => (TDATA=> cmd_tdata, TVALID => cmd_tvalid, TLAST => cmd_tlast),
		CTRL_CMD_IN_DAT.TDATA => cmd_tdata,
		CTRL_CMD_IN_DAT.TVALID => cmd_tvalid,
		CTRL_CMD_IN_DAT.TLAST => cmd_tlast,
		CTRL_CMD_IN_RDY.TREADY =>cmd_tready,

		CTRL_RPLY_OUT_DAT => open,
		CTRL_RPLY_OUT_RDY => (TREADY => '1'),

		CTRL_CLK => clk125,
		CTRL_RST => ctrl_rst
	);

clk_process :process
   begin
		clk <= '0';
		wait for IN_CLK_PERIOD/2;
		clk <= '1';
		wait for IN_CLK_PERIOD/2;
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
	variable func: integer :=0; -- 0=adc, 1=ram, 2=noise, 3=ctr
	variable ram_page: integer :=0; --
	variable pattern: sample_array;
	variable bytes: slv8_array(0 to BYTES_PER_FRAME-1);
	variable page_slv: std_logic_vector(6 downto 0);
	variable cmd_byte: std_logic_vector(7 downto 0);
	constant MODE:std_logic_vector(2 downto 0) := "011"; -- "010": Noise
	constant NFRAMES: integer := 0; -- 0= infinite
	constant SHIFT: integer := 5;
	constant STATS_PERIOD: integer := 10;
	begin

        -- pulse the resets
		rst <= '1';
		ctrl_rst <= '1';
		sleep(clk125, 10); 
		ctrl_rst <= '0';
		sleep(clk, 10);
		rst <= '0';

		sleep(clk125, 10); -- make sure we start command transmission on a CLK125 edge or we will lose some data

    
		-- -- Program buffer
		-- fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, 2#00000000# + ram_page * 8); -- source=funcgen, enable=1, select last page of ram
		-- fpga_write_ram(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 511, (0=>X"01"));

        if MODE="001" then
            for i in pattern'range loop
                pattern(i) := to_slv(i,BITS_PER_SAMPLE);
                bytes(2*i to 2*i+1) := to_slv8_array(pattern(i));
            end loop;
    
            for page in 0 to (bytes'length)/512  -1 loop
                page_slv := to_slv(page, page_slv'length);
                cmd_byte := "00" & page_slv(2 downto 0) & "000";
                fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, cmd_byte); -- Make sure we use page 0
                cmd_byte := page_slv(6 downto 3) & "0000";
                fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 5, cmd_byte); -- Make sure we use page 0
                fpga_write_ram(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, bytes(512*page to 512*(page+1)-1)); -- write all 2048 bytes at once.
            end loop;
    --		chan_reset <= '0';
        end if; -- mode
        
        if MODE="011" then
            for i in pattern'range loop
                pattern(i) := (others => '0');
                pattern(i)(5) := '1';
--                pattern(i)(BITS_PER_SAMPLE - 1) := '1';
                bytes(2*i to 2*i+1) := to_slv8_array(pattern(i));
            end loop;
    
            for page in 0 to (bytes'length)/512  -1 loop
                page_slv := to_slv(page, page_slv'length);
                cmd_byte := "00" & page_slv(2 downto 0) & "000";
                fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, cmd_byte); -- Make sure we use page 0
                cmd_byte := page_slv(6 downto 3) & "0000";
                fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 5, cmd_byte); -- Make sure we use page 0
                fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 6, "10000000");
                fpga_write_ram(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, bytes(512*page to 512*(page+1)-1)); -- write all 2048 bytes at once.
                
                -- Set stats_period
		        fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 3, 0);
		        fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 4, STATS_PERIOD-1); 
            end loop;
    --		chan_reset <= '0';
        end if; -- mode
        
        
 
    
        -- Set the mode
        sleep(clk125, 10); -- make sure we start command transmission on a CLK125 edge or we will lose some data
        fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, "00000" & MODE ); --
        fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, "01000" & MODE ); 

        

			sleep(clk,512*7);
		-- fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, 2#01000000# + 1); -- source=funcgen, enable=1

		-- for i in 0 to NUMBER_OF_OUTPUT_LANES-1 loop
		-- 	fpga_write(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + i*CROSSBAR_ADDR_INCREMENT + 3, number_of_bins_per_frame); -- Set the number of words to select
		-- 	fpga_write(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + i*CROSSBAR_ADDR_INCREMENT + 4, number_of_words_per_bin); -- Set the number of words to select
		-- 	fpga_write(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + i*CROSSBAR_ADDR_INCREMENT + 5, number_of_frames_per_packet*32 + actual_number_of_input_lanes); -- Set the range of inputs to capture (0 to NUMBER_OF_CROSSBAR_INPUTS-1)
		-- 	fpga_select_bins( clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + i*CROSSBAR_ADDR_INCREMENT, first_bin=>0, bin_step=>10, number_of_bins=>number_of_selected_bins); -- Enable storage and transmission of N frequency bins.
		-- 	-- wait for 2*64*SYSCLK_period; -- prevent the buffers from overflowing by allowing time to send the ethernet framing
		-- 	-- fpga_read(       clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, CROSSBAR_BIN_SEL0_ADDR + 16#200#, 3); -- Re-read the first 8 bytes of the map for debugging
		-- end loop;

		sleep(clk,20);
		-- sleep(clk,start_delay(i));
		for j in 0 to 10 loop
--			send_axis32_packet(clk, s_axis_tdata, s_axis_tvalid, s_axis_tlast, s_axis_tready, create_packet(16#FA#, j ,625)); -- 512*244/200=625 clocks = actual duration of  the incoming frames
			-- sleep(clk,1);
		end loop;
		wait;
	end process ; -- lane0_proc

END;
