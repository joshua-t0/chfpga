--------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:   17:23:04 11/17/2010
-- Design Name:
-- Module Name:   C:/Xilinx/work/CHIME/SP605_test2/ADCDAQ/ADC_IOSERDES_testbench.vhd
-- Project Name:  ADCDAQ
-- Target Device:
-- Tool versions:
-- Description:
--
-- VHDL Test Bench Created by ISE for module: ADC_IOSERDES
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

ENTITY xge_array_testbench IS
	 GENERIC (
		NUMBER_OF_LANES             : integer := 1;
		NUMBER_OF_REFCLK            : integer := 1;
		LANE_TO_QUAD_MAP            : integer_array := (0=>0, 1=>1); -- Indicates which quad is associated each channel. The QUAD number is an integer between 0 and N-1, where N is the total number of quads used.
		QUAD_TO_REFCLK_MAP          : integer_array := (0=>0, 1=>1) -- Indicates which refclk is associated with each QUAD (N integers from 0 to NUMBER_OF_REFCLK-1).
		);
END xge_array_testbench;


ARCHITECTURE behavior OF xge_array_testbench IS

   -- Clock period definitions
   constant CLK125_PERIOD : time := 8 ns;
   constant CLK200_PERIOD : time := 5 ns;
   constant CLK156_PERIOD : time := 6.4 ns;

	-- SYSTEM Port modules
	-- constant SYSTEM_BASE_ADDR        : integer := 16#00000#;
	-- constant CHAN_BASE_ADDR          : integer := 16#20000#; -- # Channelizer top address
	-- constant CROSSBAR_BASE_ADDR      : integer := 16#40000#; -- # CROSSBAR top address
	-- constant GPU_LINK_BASE_ADDR      : integer := 16#60000#; -- # GPU Link top address
	-- constant CORR_BASE_ADDR          : integer := 16#80000#; -- # Correlator ports are determined dynamically based on the info from the firmware
	-- constant BASE_ADDR          : integer := 16#80000#; -- # Correlator ports are determined dynamically based on the info from the firmware

	--Inputs
	signal CPU_RESET : std_logic := '0';
	signal clk125 :   std_logic;
	signal clk200 :   std_logic;

 -- UDP/Ethernet interfaces

	signal rx_p: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal rx_n: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal tx_p: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal tx_n: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal refclk_p: std_logic;
	signal refclk_n: std_logic;

	signal s_axis_tx_tdata: slv32_array(0 to NUMBER_OF_LANES-1);
	signal s_axis_tx_tvalid: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal s_axis_tx_tlast: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal s_axis_tx_tready: std_logic_vector(0 to NUMBER_OF_LANES-1);
	signal s_axis_tx_clk: std_logic; -- AXI-S data clock. Not related to the 10G Ethernet clocks.


-- Pattern generator signals

	signal ctr: unsigned(6 downto 0):=(others=>'0'); -- init for sim

	constant data5: slv36_array(0 to 17) := (
	  X"1_01010101", X"1_02020202",
	  X"1_03030303", X"1_04040404",
	  X"3_05050505", X"3_06060606",
	  X"1_07070707", X"1_08080808",
	  X"1_09090909", X"1_0A0A0A0A",
	  X"3_0B0B0B0B", X"1_0C0C0C0C",
	  X"3_0D0D0D0D", X"1_0E0E0E0E",
	  X"1_0F0F0F0F", X"1_10101010",
	  X"1_11111111", X"3_12121212"
	    );

	alias data is data5; -- select test patern source

-- PCS/PMA signals
	signal xgmii_rxd : std_logic_vector(63 downto 0);
	signal xgmii_rxc : std_logic_vector(7 downto 0);
	signal xgmii_txd : std_logic_vector(63 downto 0);
	signal xgmii_txc : std_logic_vector(7 downto 0);
	signal txd : std_logic_vector(63 downto 0);
	signal txc : std_logic_vector(7 downto 0);

	signal clk156 :    std_logic;
	signal pcs_tx_p:   std_logic;
	signal pcs_tx_n:   std_logic;

begin

-- rx_p(1) <= tx_p(0);
-- rx_n(1) <= tx_n(0);
-- rx_p(0) <= tx_p(1);
-- rx_n(0) <= tx_n(1);
rx_p(0) <= pcs_tx_p;
rx_n(0) <= pcs_tx_n;

xge_clk_process :process
   begin
		refclk_p <= '0';
		refclk_n <= '1';
		wait for CLK156_PERIOD/2;
		refclk_p <= '1';
		refclk_n <= '0';
		wait for CLK156_PERIOD/2;
   end process;

CLK125_process :process
   begin
		CLK125 <= '0';
		wait for CLK125_PERIOD/2;
		CLK125 <= '1';
		wait for CLK125_PERIOD/2;
   end process;
clk200_process :process
   begin
		clk200 <= '0';
		wait for CLK200_PERIOD/2;
		clk200 <= '1';
		wait for CLK200_PERIOD/2;
	end process;

udp0: entity work.xge_array
	generic map (
		NUMBER_OF_TX_LANES          => NUMBER_OF_LANES,
		NUMBER_OF_REFCLK            => NUMBER_OF_REFCLK,
		LANE_TO_QUAD_MAP            => LANE_TO_QUAD_MAP,
		QUAD_TO_REFCLK_MAP          => QUAD_TO_REFCLK_MAP,
		SIM                         => TRUE
		)
	port map (
		tx_p => tx_p,
		tx_n => tx_n,
		rx_p => rx_p,
		rx_n => rx_n,
		refclk_p => (others=> refclk_p),
		refclk_n => (others=> refclk_n),

		s_axis_tx_tdata =>   s_axis_tx_tdata,
		s_axis_tx_tvalid => s_axis_tx_tvalid,
		s_axis_tx_tlast =>  s_axis_tx_tlast,
		s_axis_tx_tready =>  s_axis_tx_tready,
		s_axis_tx_clk =>    (others=>clk200),

		-- Control and reply streams
		CMD_DAT => (TVALID=>'0', TDATA=>(others=>'0'), TLAST=>'0'),
		CMD_RDY => open,
		RPLY_DAT => open,
		RPLY_RDY=> (TREADY=>'1'),
		CTRL_CLK => CLK125,
		CTRL_RST => '0',

		-- clk: in std_logic; -- AXI-S data clock. Not related to the 10G Ethernet clocks.
		areset=> CPU_RESET -- asynchronous reset
	 );

pcs0: entity work.ten_gig_eth_pcs_pma_0_example_design
    port map (
      reset           => CPU_RESET,
      core_clk156_out => clk156,
      xgmii_txd       => xgmii_txd,
      xgmii_txc       => xgmii_txc,
      xgmii_rx_clk    => open,
      xgmii_rxd       => xgmii_rxd,
      xgmii_rxc       => xgmii_rxc,
      refclk_p        => refclk_p,
      refclk_n        => refclk_n,
-------------------------------------------------------------------------------
-- Serial Interface
-------------------------------------------------------------------------------
      txp             => pcs_tx_p,
      txn             => pcs_tx_n,
      rxp             => tx_p(0),
      rxn             => tx_n(0),
      resetdone       => open,
      signal_detect   => '1',
      tx_fault        => '0',
      tx_disable      => open,
      core_status     => open,
      pma_loopback              => '0',
      pma_reset                 => '0',
      global_tx_disable         => '0',
      pma_vs_loopback           => "0000",
      pcs_loopback              => '0',
      pcs_reset                 => '0',
      test_patt_a_b             => (others => '0'),
      data_patt_sel             => '0',
      test_patt_sel             => '0',
      rx_test_patt_en           => '0',
      tx_test_patt_en           => '0',
      prbs31_tx_en              => '0',
      prbs31_rx_en              => '0',
      pcs_vs_loopback           => "00",
      set_pma_link_status       => '0',
      set_pcs_link_status       => '0',
      clear_pcs_status2         => '0',
      clear_test_patt_err_count => '0',
      pma_link_status           => open,
      rx_sig_det                => open,
      pcs_rx_link_status        => open,
      pcs_rx_locked             => open,
      pcs_hiber                 => open,
      teng_pcs_rx_link_status   => open,
      pcs_err_block_count       => open,
      pcs_ber_count             => open,
      pcs_rx_hiber_lh           => open,
      pcs_rx_locked_ll          => open,
      pcs_test_patt_err_count   => open
    );



txproc: process(all)
begin
    if rising_edge(clk200) then

      	if s_axis_tx_tready(0) then
      		if ctr < data'LENGTH then
				s_axis_tx_tdata(0)  <= data(to_integer(ctr))(31 downto 0);
				s_axis_tx_tvalid(0) <= data(to_integer(ctr))(32);
				s_axis_tx_tlast(0)  <= data(to_integer(ctr))(33);
	       else
				s_axis_tx_tdata(0)  <=X"07070707";
				s_axis_tx_tvalid(0) <='0';
				s_axis_tx_tlast(0)   <='0';
	        end if;
	        ctr<=ctr+1;
		end if;
     end if; --clk
  end process;


  -- txproc: process(clk156)
  -- begin
  --   if rising_edge(clk156) then
  --     -- if GPIO_BUTTON1='1' then
  --       case to_integer(ctr) is
  --         when 0 =>
  --           txd<=X"0707070707070707";
  --           txc<="11111111";
  --         when 1 =>
  --           txd<=X"FB555555555555D5";
  --           txc<="10000000";
  --         when 2=>
  --           txd<=X"90E2BA2FF88090E2";
  --           txc<="00000000";
  --         when 3=>
  --           txd<=X"BA2FF88008004500";
  --           txc<="00000000";
  --         when 4=>
  --           txd<=X"0034013F00000111";
  --           txc<="00000000";
  --         when 5=>
  --           txd<=X"D37B02020201E000";
  --           txc<="00000000";
  --         when 6=>
  --           txd<=X"00FCC31314EB0020";
  --           txc<="00000000";
  --         when 7=>
  --           txd<=X"70AC73D400000001";
  --           txc<="00000000";
  --         when 8=>
  --           txd<=X"0000000000000669";
  --           txc<="00000000";
  --         when 9=>
  --           txd<=X"7361746170000001";
  --           txc<="00000000";
  --         when 10=>
  --           txd<=X"0001B85E5E00FD07";
  --           txc<="00000011";
  --         when others =>
  --           txd<=X"0707070707070707";
  --           txc<="11111111";
  --       end case;
  --       ctr<=ctr+1;
  --     -- else
  --     --   ctr<=(others=>'0');
  --     --   txd<=X"0707070707070707";
  --     --   txc<="11111111";
  --     -- end if;
  --     -- for b in 0 to 7 loop
  --       xgmii_txd <= reverse_bytes(txd);
  --       xgmii_txc <= reverse_bits_same_dir(txc);
  --     -- end loop;
  --    end if; --clk
  -- end process;




phy_process: process
	begin
--	wait for 250 ns;  -- make sure the clocks are stabilized
--
--	for i in 1 to 10 loop
--		wait until CLK125='1';
--	end loop;
--
--	wait until TX_TRIG='1'; -- wait for the reset sequence to be finished before starting sending commands
	-- hold reset state for 100 ns.
	CPU_RESET<='1';
--	ADC_SYNC_P<='1'; -- Enable SYNC
--	ADC_SYNC_N<='0';

	wait for 10*CLK125_PERIOD;
	CPU_RESET<='0';
	wait for 10*CLK125_PERIOD;
--	ADC_SYNC_P<='0'; -- Disable SYNC
--	ADC_SYNC_N<='1';
	wait for 10*CLK125_PERIOD;
	-- for i in 0 to NUMBER_OF_CHANNELIZERS-1 loop
	-- 	fpga_write(clk125, tx_data, tx_wr_en, tx_frame, CHAN_BASE_ADDR + i * CHAN_ADDR_INCREMENT + SRCSEL_OFFSET + 0, 2#00000001#); -- Source = FUNCGEN
	-- 	-- fpga_write(clk125, tx_data, tx_wr_en, tx_frame, CHAN_BASE_ADDR + i * CHAN_ADDR_INCREMENT + FUNCGEN_OFFSET + 0, 2#00000101#); -- Data = 'real ramp'
	-- 	-- fpga_write(clk125, tx_data, tx_wr_en, tx_frame, CHAN_BASE_ADDR + i * CHAN_ADDR_INCREMENT + FUNCGEN_OFFSET + 0, 2#00000100#); -- Data = 'ramp'
	-- 	fpga_write(clk125, tx_data, tx_wr_en, tx_frame, CHAN_BASE_ADDR + i * CHAN_ADDR_INCREMENT + FUNCGEN_OFFSET + 0, 2#00000111#); -- Data = 'real_ramp4'
	-- -- 	fpga_write(clk125, tx_data, tx_wr_en, tx_frame, ANT0_PORT+i, FUNCGEN_MODULE, 0, 2#00000011#); -- Data = AB
	-- -- 	fpga_write(clk125, tx_data, tx_wr_en, tx_frame, ANT0_PORT+i, FUNCGEN_MODULE, 1, 128); -- A
	-- -- 	fpga_write(clk125, tx_data, tx_wr_en, tx_frame, ANT0_PORT+i, FUNCGEN_MODULE, 2, 129); -- B
	-- -- --	fpga_write(clk125, tx_data, tx_wr_en, tx_frame, ANT0_PORT+i, SCALER_MODULE, 0, 2#01000000#); -- BYPASS SCALER
	-- 	-- fpga_write(clk125, tx_data, tx_wr_en, tx_frame,CHAN_BASE_ADDR + i * CHAN_ADDR_INCREMENT + SCALER_OFFSET + 0, 2#00001100#); -- BYPASS SCALER=0, shift left=12
	-- 	--fpga_write(clk125, tx_data, tx_wr_en, tx_frame,CHAN_BASE_ADDR + i * CHAN_ADDR_INCREMENT + SCALER_OFFSET + 0, 2#00100000#+31); -- 4-bit mode, BYPASS SCALER=0, shift left=31
	-- 	fpga_write(clk125, tx_data, tx_wr_en, tx_frame,CHAN_BASE_ADDR + i * CHAN_ADDR_INCREMENT + SCALER_OFFSET + 0, 2#00100000#+27); -- BYPASS SCALER=0, FOUR_BITS=1, shift left=27
	-- 	fpga_write(clk125, tx_data, tx_wr_en, tx_frame,CHAN_BASE_ADDR + i * CHAN_ADDR_INCREMENT + SCALER_OFFSET + 1, 2#00000000#); -- use_offset_binary = 0,  use_gain_table=0, active_gain_bank = 0, gain page=0
	-- 	-- fpga_write(clk125, tx_data, tx_wr_en, tx_frame,CHAN_BASE_ADDR + i * CHAN_ADDR_INCREMENT + SCALER_OFFSET + 16#200#, 10); --
	-- 	-- fpga_write(clk125, tx_data, tx_wr_en, tx_frame,CHAN_BASE_ADDR + i * CHAN_ADDR_INCREMENT + SCALER_OFFSET + 16#201#, 11); --
	-- 	-- fpga_write(clk125, tx_data, tx_wr_en, tx_frame,CHAN_BASE_ADDR + i * CHAN_ADDR_INCREMENT + SCALER_OFFSET + 16#202#, 12); --
	-- 	-- fpga_write(clk125, tx_data, tx_wr_en, tx_frame,CHAN_BASE_ADDR + i * CHAN_ADDR_INCREMENT + SCALER_OFFSET + 16#203#, 13); --
	-- 	-- fpga_write(clk125, tx_data, tx_wr_en, tx_frame,CHAN_BASE_ADDR + i * CHAN_ADDR_INCREMENT + SCALER_OFFSET + 0, 2#00000000#+27); -- BYPASS SCALER=0, shift left=27
	-- 	wait for 3*64*SYSCLK_period; -- prevent the buffers from overflowing by allowing time to send the ethernet framing
	-- end loop;


	wait;

--		end if; -- CLK
	end process;

END;
