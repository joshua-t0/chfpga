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
 		SAMPLES_PER_FRAME: integer := 16384
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
    constant BYTES_PER_FRAME: integer := BITS_PER_SAMPLE/8*SAMPLES_PER_FRAME;
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
	-- variable actual_number_of_input_lanes: integer := 16;-
	constant MODE:std_logic_vector(2 downto 0) := "010"; -- "010": Noise
	constant NFRAMES: integer := 0; -- 0= infinite
	-- constant SHIFT: integer := 5;
    constant A: slv8 := "00000000";
    constant B: slv8 := "00000001";
	begin

        -- pulse the resets
		rst <= '1';
		ctrl_rst <= '1';
		sleep(clk125, 10); 
		ctrl_rst <= '0';
		sleep(clk, 10);
		rst <= '0';

		sleep(clk125, 10); -- make sure we start command transmission on a CLK125 edge or we will lose some data

        
        -- Set number of frames
		fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 3, NFRAMES); -- Send 5 frames
    
        -- Set the shift factor
		-- fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 5, SHIFT); 
    
        -- Set the mode
        sleep(clk125, 10); -- make sure we start command transmission on a CLK125 edge or we will lose some data
        fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, "00000" & MODE ); 
        -- fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 0, "01000" & MODE ); 

        -- Set the seed for the lfsr
        fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 1, A);
        fpga_write_control(clk125, cmd_tdata, cmd_tvalid, cmd_tlast, cmd_tready, 2, B);

        rst <= '1';
		sleep(clk, 10);
		rst <= '0';

		wait;
	end process ; -- lane0_proc

END;
