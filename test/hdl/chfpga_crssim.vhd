library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

use work.chfpga_package.ALL; -- Get all component definitions
use work.chfpga_config.ALL; -- Get platform-specific configuration definitions

library xpm;
use xpm.vcomponents.ALL;

entity chfpga_crssim is
	generic (

		PLATFORM_ID: integer := CONFIG_PLATFORM_ID; --  Identifies the type of platform on which the firmware is running.

		-- Clocking config

		-- System reference clock surce:
		--    "SYSCLK": 200 MHz unbuffered differential clock from sysclk_p/n,
		--    "SYSCLK_BUFG": 200 MHz BUFG-Buffered clock from sysclk_bufg,
		--    "SFP_REFCLK": 125 MHz clock from the GTX reference clock
		SYSTEM_CLOCK_SOURCE: clk_source_enum := SYSCLK_BUFG;
		SYSTEM_CLOCK_FREQ: real     := 10.0; -- System reference clock frequency, in MHz. Must be a real value (i.e. float). Used to select the system PLL divider/multiplier factors.
		CHAN_CLK_SOURCE: chan_clk_source_enum := ADC; -- Clock sources for the system PLL. Here, Channelizer clock comes directly from the ADC
		CT_CLK_SOURCE: ct_clk_source_enum := CONFIG_CT_CLK_SOURCE; -- corner-turn clock source

		-- Buck synchronization

		BUCK_SYNC_ENABLE: boolean       := TRUE; -- default state of the buck sync enable at startup
		BUCK_CLK_DIVIDE_FACTOR: integer := 12; -- Buck frequency is 200MHz/16/BUCK_CLK_DIVIDE_FACTOR, 12=> 1.0416 MHz, 17 => 0.73529 MHz, 24=>0.5208333 MHz

		PHY_TYPE: PHY_TYPE_ENUM := NONE;
		SGMII_CLOCK_SOURCE: string := "REFCLK"; -- Selects the 125MHz clock source for the SGMII interface; "CLK125": uses the 125 MHz clock (clk125) from the main MMCM, "REFCLK": uses the GTX Reference clock (gtrefclk)

		-- ADC config
		ADC_TYPE: ADC_TYPE_ENUM := AXIS; -- ADC data is provided through the axis_adc port
		NUMBER_OF_ADCS: integer := CONFIG_NUMBER_OF_ADCS; -- Number of ADC inputs

		-- Mezzanines
		NUMBER_OF_ADC_BOARDS: integer := 0; -- No mezzanine, therefore no associated clocks etc.

		-- Channelizer configuration
		FFT_TYPE: fft_type_enum         := CONFIG_CHAN_FFT_TYPE;
		NUMBER_OF_CHANNELIZERS: integer := CONFIG_NUMBER_OF_ADCS;  -- (Typ. =16)  (0-NUMBER_OF_ADCS) Number of channelizer blocks to be implemented
		CAPTURE_TYPE: chan_capture_type_enum := CONFIG_CHAN_CAPTURE_TYPE;

		-- Corner-turn engine configuration
		CT_TYPE: ct_type_enum                    := CONFIG_CT_TYPE; -- "BCT" (CHIME-like) or "UCT" (CHORD-like)
		CT_LEVEL: integer                        := CONFIG_CT_LEVEL;
		NUMBER_OF_CROSSBAR_INPUTS: integer       := CONFIG_NUMBER_OF_CROSSBAR_INPUTS; -- (Typ. =16)(0-NUMBER_OF_CHANNELIZERS): Number of channelizers output that are being aligned, filtered and repacked for the corrleator or GPU links
		NUMBER_OF_CROSSBAR1_OUTPUTS: integer     := CONFIG_NUMBER_OF_CROSSBAR1_OUTPUTS; -- (Typ. =16): Number of output lanes of CROSSBAR1. Should be 8 for URAM-based crossbar1.
		NUMBER_OF_BP_PCB_SHUFFLE_LANES: integer  := CONFIG_NUMBER_OF_BP_PCB_SHUFFLE_LANES;
		NUMBER_OF_BP_QSFP_SHUFFLE_LANES: integer := CONFIG_NUMBER_OF_BP_QSFP_SHUFFLE_LANES;
		NUMBER_OF_BP_SHUFFLE_LINKS: integer      := CONFIG_NUMBER_OF_BP_SHUFFLE_LINKS; -- Number of GTXes for both the backplane PCB and QSFP shuffle links. Usually matches the number of 1st crossbar output lanes.
		NUMBER_OF_BP_SHUFFLE_REFCLKS: integer    := CONFIG_NUMBER_OF_BP_SHUFFLE_REFCLKS;

		-- Correlator config
		CORR_TYPE: CORR_TYPE_ENUM := CONFIG_CORR_TYPE; -- "CORR44" or "UCORR44"
		NUMBER_OF_CORRELATORS: integer := CONFIG_NUMBER_OF_CORRELATORS; -- Number of correlators. Normally NUMBER_OF_CROSSBAR_OUTPUTS. Correlator not implemented if zero.

		-- Real-time data offload links configuration
		GPU_LINK_TYPE: gpu_link_type_enum := CONFIG_GPU_LINK_TYPE; --
		GPU_CHANNEL_QUAD: integer_array := (0 to 3 => 0); -- Channels 0-3 use QUAD0, Channels 4-7 use QUAD1. Ignored if GPU_LINK_TYPE is NONE
		GPU_QUAD_REFCLK: integer_array := (0 to 0 =>0 ); -- Both QUAD0 and QUAD1 use refclk(0)


		-- Peripheral config
		BLINKER_PRESENT: boolean     := TRUE; -- Indicates if the LED flasher is to be implemented by setting the DUMMY flag of the BLINKER module
		NUMBER_OF_I2C_PORTS: integer := 0;
		NUMBER_OF_SPI_PORTS: integer := 0; -- One port for each FMC
		IMPLEMENT_ARM_SPI: boolean   := FALSE;
		IMPLEMENT_LCD: boolean       := TRUE; -- OLED display clock select & clock line
		SIM: boolean                 := FALSE; -- Indicates this is running as a simulation. Used to accelerate simulations

		-- Derived parameters

		NUMBER_OF_GPU_LINKS: integer := sel(GPU_LINK_TYPE /= NONE, GPU_CHANNEL_QUAD'LENGTH, 0); -- Number of 100Gb Ethernet links. 0 if if GPU_LINK_TYPE is "NONE"
		NUMBER_OF_GPU_REFCLKS: integer               := max(GPU_QUAD_REFCLK)+1 -- Number of Reference clocks provided for the 100GE links.


	);
	port (
		-- CONTROL INTERFACE

		-- Clock and reset
		axis_bsb_rst: in std_logic;
		cpu_reset : in std_logic;
		aclk : in std_logic;

		-- Commands in
		axis_bsb_cmd_tdata: in std_logic_vector(7 downto 0) := x"00";
		axis_bsb_cmd_tvalid: in std_logic := '0';
		axis_bsb_cmd_tlast: in std_logic := '0';
		axis_bsb_cmd_tready: out std_logic;

		-- Responses out
		axis_bsb_rply_tdata: out std_logic_vector(7 downto 0);
		axis_bsb_rply_tvalid: out std_logic;
		axis_bsb_rply_tlast: out std_logic;
		axis_bsb_rply_tready: in std_logic := '1';

		-- RTL clocks

		-- Copy of the 10 MHz SMA reference clock that feeds the programmable PLL
		sma_clk10: in std_logic;

		-- Copy of the 10 MHz Backplane reference clock that feeds the programmable PLL
		bp_clk10: in std_logic;

		-- 50 MHz VCXO frequency from programmable PLL (output of PLL1). Is in phase with the external 10 MHz reference clocks.
		pll_oscout: in std_logic;
		pll_sync: out std_logic;

		-- 375 MHz processing clock form programmable PLL
		plclk: in std_logic;

		-- SYSREF clock from programmable PLL - used to synchronize the ADCs
		rf_sysref_n: in std_logic;
		rf_sysref_p: in std_logic;

		pl_sysref: in std_logic;

		-- 10 MHz system clock from programmable PLL. Used as source to generate internal clocks (200 MHz, 62.5 MHz etc) using MMCM.
		sysclk: in std_logic;

		-- 100G Ethernet

		--   156.25 MHz reference clock
		clk156_n: in std_logic;
		clk156_p: in std_logic;

		--   QSFP data lanes
		qsfp_txn: out std_logic_vector(0 to 3);
		qsfp_txp: out std_logic_vector(0 to 3);

		-- Corner-turn engine shuffle links
		bp_shuffle_tx_p: out std_logic_vector(0 to NUMBER_OF_BP_SHUFFLE_LINKS - 1);
		bp_shuffle_tx_n: out std_logic_vector(0 to NUMBER_OF_BP_SHUFFLE_LINKS - 1);
		bp_shuffle_rx_p: in std_logic_vector(0 to NUMBER_OF_BP_SHUFFLE_LINKS - 1);
		bp_shuffle_rx_n: in std_logic_vector(0 to NUMBER_OF_BP_SHUFFLE_LINKS - 1);
		bp_shuffle_refclk_p: in std_logic_vector(0 to NUMBER_OF_BP_SHUFFLE_REFCLKS - 1);
		bp_shuffle_refclk_n: in std_logic_vector(0 to NUMBER_OF_BP_SHUFFLE_REFCLKS - 1);

		-- Buck sync signals

		buck_sync_0v85: out std_logic;
		buck_sync_1v2a: out std_logic;
		buck_sync_1v2b: out std_logic;
		buck_sync_1v4: out std_logic;
		buck_sync_1v8: out std_logic;
		buck_sync_2v5: out std_logic;
		buck_sync_3v3: out std_logic;
		buck_sync_5v0: out std_logic;
		buck_sync_bp: out std_logic;

		-- LEDs (PL's 7-segment display)
		led7b: out std_logic_vector(7 downto 0);

		-- OLED display
		fpc_d: out std_logic_vector(1 downto 0); -- D0: CLK, D1: CLS (clock select, 0=external (i.e. CLK line on D0), 1=internal)

		-- User connectors
		smp: out std_logic_vector(0 to 3);

		-- AUX signals
		sma_aux_drv: out std_logic;

		-- IRIG-B signals
		sma_irig_p: in std_logic;
		sma_irig_n: in std_logic;

		bp_irig_p: in std_logic;
		bp_irig_n: in std_logic;

		-- ADC sampling clocks
		adc0_clk_clk_n: in std_logic;
		adc0_clk_clk_p: in std_logic;
		adc1_clk_clk_n: in std_logic;
		adc1_clk_clk_p: in std_logic;
		adc2_clk_clk_n: in std_logic;
		adc2_clk_clk_p: in std_logic;
		adc3_clk_clk_n: in std_logic;
		adc3_clk_clk_p: in std_logic
	);
end entity chfpga_crssim;

architecture impl of chfpga_crssim is

	signal bp_shuffle_tx_p_int, bp_shuffle_tx_n_int: std_logic_vector(0 to NUMBER_OF_BP_SHUFFLE_LINKS - 1);
	-- Tell the tools not to infer buffers and autoplace IO ports for the following if the ports are not connected
	-- If 100GE is not implemented, the placer assigns random IOs to these ports, and since those have no specifiec IO standard, the bitstream
	-- fails its DRC.
	-- "None" tells the tools not to implement an IO port. "OBUF" implements the IO port.
	--  In the case of "OBUF", it looks like the output buffer is adapted to the type of output such as a transceiver output etc.

	-- PLL VCXO clock (50 MHz)
	signal pll_oscout_nobuf: std_logic;
	signal pll_oscout_bufg: std_logic;
	signal pll_sync_bsb, pll_sync10: std_logic;
	signal pll_sync50_pre1, pll_sync50_pre2, pll_sync50_pre3: std_logic;
	-- System Reference clock (Submultiple of ADC sampling clock/16, < 10 MHz)
	-- Used to calibrate the ADC latency
	signal pl_sysref_pre, pl_sysref_pre2, pl_sysref_reg: std_logic;

	-- 10 MHz reference clocks
	signal clk10_bufg: std_logic;
	signal clk10_sel: std_logic;

	-- Vectors representing the ADC inputs.
	-- Length is hard coded to the fixed number of inputs provided in the top level port.
	-- We will pass only the first NUMBER_OF_ADCS to chFPGA.
	signal adc_axis_tdata: slv128_array(0 to 7);
	signal adc_axis_tvalid: std_logic_vector(0 to 7);
	signal adc_axis_clk: std_logic_vector(0 to 7);
	signal adc_clkout: std_logic_vector(0 to 7);
	signal adc_cal_frozen: std_logic_vector(0 to 7);
	signal adc_cal_freeze: std_logic_vector(0 to 7);
	signal adc_cal_signal_detect: std_logic_vector(0 to 7);

	signal adc_clear_or: std_logic_vector(0 to 7); -- clear overrange flag
	signal adc_clear_ov: std_logic_vector(0 to 7); -- clear overvoltage flag
	signal adc_cm_ov: std_logic_vector(0 to 7); -- common mode overvoltageflag
	signal adc_cm_uv: std_logic_vector(0 to 7); -- common mode overvoltage flag
	signal adc_or: std_logic_vector(0 to 7); -- overvoltage flag
	signal adc_ot1: std_logic_vector(0 to 7); -- over threshold 1 flag
	signal adc_ot2: std_logic_vector(0 to 7); -- over threshold 2 flag
	signal adc_ov: std_logic_vector(0 to 7); -- overvoltage flag

	signal axis_cap_tdata: std_logic_vector(7 downto 0);
	signal axis_cap_tvalid: std_logic;
	signal axis_cap_tlast: std_logic;
	signal axis_cap_tready: std_logic;

	signal buck_sync: std_logic_vector(0 to 15);
	signal gpio_led: std_logic_vector(7 downto 0);
	signal sma_irig, bp_irig: std_logic;
	signal sma_out: std_logic_vector(0 to 3);
	signal qsfp_txp_int, qsfp_txn_int: std_logic_vector(0 to 3);
	signal irigb_reg: std_logic;

	signal lcd_db: std_logic_vector(3 downto 0);

begin

	bp_gen: if CT_LEVEL > 1 generate
		bp_shuffle_tx_p <= bp_shuffle_tx_p_int;
		bp_shuffle_tx_n <= bp_shuffle_tx_n_int;
	end generate bp_gen;

	-----------
	-- 10 MHz Reference clocks from SMA and BP
	-----------
	-- Note: We tried using the DIFF_SSTL18_I_DCI input standard with DQS_BIAS=TRUE parameter to
	-- provide a differential bias and ensure a stable signal if no clock is present, but that makes
	-- the clock signal very noisy, so we stick to LVDS.

	clk10_ibuf0: BUFGMUX
		generic map (
			CLK_SEL_TYPE => "ASYNC"  -- ASYNC, SYNC
		)
		port map (
			i0 => sma_clk10, -- 1-bit input: Clock input (S=0)
			i1 => bp_clk10, -- 1-bit input: Clock input (S=1)
			o  => clk10_bufg,   -- 1-bit output: Clock output
			s  => clk10_sel    -- 1-bit input: Clock select
		);

	-----------
	-- 2.5 MHz SYSREF clock from PLL, used for ADC latency calibration
	-----------

	-- Register SYSREF
	-- This is required for the Multi-Converter synchronization
	process(all) begin
		if rising_edge(plclk) then
			pl_sysref_pre <= pl_sysref;
			pl_sysref_pre2 <= pl_sysref_pre;
			pl_sysref_reg <= pl_sysref_pre2;
		end if;
	end process;

	-- CLK10: 1111100000111110000011110000
	-- CLK50: 1010101010101010101010101010
	-- SYNC10:          111111111111111111
	-- PRE1:             11111111111111111
	-- PRE2:               111111111111111
	-- PRE3:                 1111111111111
	-- SYNC_OUT                11111111111
	-- registered sync:          111111111
	-- CLK10: 1111100000111110000011110000

	-- Resynchronize pll_sync to the clk10 reference clock so it is roughly aligned to pll_oscout
	pll_sync_cdc0: xpm_cdc_single
		generic map (
			SRC_INPUT_REG => 0
		)
		port map (
			src_clk  => '0',
			src_in   => pll_sync_bsb,
			dest_clk => clk10_bufg,
			dest_out => pll_sync10
		);

	-- Synchronize SYNC to OSCOUT
	pllsync0_proc: process(all) begin
		if falling_edge(pll_oscout) then  -- *** Notice the *falling* edge
			-- pll_sync50_pre1 <= pll_sync10;
			pll_sync50_pre2 <= pll_sync50_pre1;
			pll_sync50_pre3 <= pll_sync50_pre2;
		-- pll_sync <= pll_sync50_pre3;
		end if;
		if rising_edge(pll_oscout) then
			pll_sync50_pre1 <= pll_sync10;
			pll_sync <= pll_sync50_pre3;
		end if;
	end process;

	-- Buck sync
	buck_sync_5v0  <= buck_sync(0);
	buck_sync_0v85 <= buck_sync(1); -- two switchers operating in paralle 180deg out of phase. Combined freq is double.
	buck_sync_3v3  <= buck_sync(2);
	buck_sync_2v5  <= buck_sync(3);
	buck_sync_1v8  <= buck_sync(4);
	buck_sync_1v2a <= buck_sync(5);
	buck_sync_1v2b <= buck_sync(6);
	buck_sync_1v4  <= buck_sync(7);
	buck_sync_bp   <= buck_sync(8);

	-- IRIG time signal
	irig_ibufds0: IBUFDS -- Instantiate a differential (LVDS) input pad pair
		generic map (
			DIFF_TERM => TRUE
		)
		port map (
			i  => sma_irig_p,
			ib => sma_irig_n,
			o  => sma_irig
		);

	-- IRIG time signal
	irig_ibufds1: IBUFDS -- Instantiate a differential (LVDS) input pad pair
		generic map (
			DIFF_TERM => TRUE
		)
		port map (
			i  => bp_irig_p,
			ib => bp_irig_n,
			o  => bp_irig
		);

	-- Select IRIG-B source
	irigb_proc: process(all) begin
		if rising_edge(plclk) then
			irigb_reg <= sma_irig when clk10_sel else bp_irig;
		end if;
	end process;

	-- 7-segment display
	led7b(5 downto 0) <= gpio_led(6 downto 1); -- a-f segments (forming a circle)
	led7b(6)          <= sma_out(2);           -- central g segment
	led7b(7)          <= sma_out(3);           -- decimal point

	-- OLED Display (SSD1306)
	-- fpc_d(0): CLK (333 - 407 kHz?) We provide 500 kHz, but divide by 2 in the display. Dividing by 1 caused intermittent init failures.
	-- fpc_d(1): CLS (clock select, 0=external (i.e. CLK line on D0), 1=internal)
	-- CLK clock is enabled when CLS = fpc_d(1) = lcd_db(0)= '0'. Otherwise it is Hi-Z.
	-- To generate CLK, We divide pll_oscout (50 MHz) by 50 then by 2: 50 MHz/50/2 = 500 kHz
	-- We use pll_oscout because it is always there, even if the PLL is not programmed
	oled_blk: block
		signal ctr: unsigned(6 downto 0);
		signal clk: std_logic;
	begin

		lcdclk_proc: process(all) begin
			if rising_edge(pll_oscout) then
				ctr <= ctr + 1;
				if ctr = unsigned(lcd_db) + 50 - 1  then
					ctr <= (others => '0');
					clk <= not clk;
				end if;
			end if; -- clk
		end process;

		--        fpc_d(1) <= lcd_db(0); -- CLS
		--        fpc_clkbuf: OBUFT port map (I => clk, O => fpc_d(0), T => fpc_d(1)); -- CLK: tristate clock output when fpc_d(1)=1 (internal clock)
		fpc_d(1) <= '0'; -- CLS = 0: Display will use the external clock source
		fpc_d(0) <= clk; -- CLK

	end block oled_blk;

	-- Connect debugging signals to SMP connectors
	--
	-- This is the row of 4 SMP (clip-on SMT coax connectors) located on the PCB towards the front of the board, behind the DAC SMAs.
	-- The connectors are, from the edge towards the center (or from top to bottom when the board is in a crate):
	--  -------- Top/Edge of board ----------------------------------------------
	--     SMP5 => smp(1)
	--     SMP6 => smp(0)
	--     SMP7 => smp(3)
	--     SMP8 => smp(2)
	smp(1) <= sma_out(0); -- SMP5 (1st from top), user-programmable
	smp(0) <= clk10_bufg; -- SMP6 (2nd from top), SMA/BP REFCLK from BUFGMUX
	-- smp(3) <= plclk; -- SMP7 (3rd form top)
	smp(3) <= pll_oscout; -- SMP7 (3rd form top), PLL OSCOUT 50 MHz VCXO
	smp(2) <= sysclk;     -- SMP8 (4th from top), 10 MHz clock from programmable PLL

	sma_aux_drv <= sma_out(1);

	/*
	zynq: entity work.zynq_tcpipe_crs
		port map (
			-- ADC sampling clocks
			adc0_clk_clk_n   => adc0_clk_clk_n,
			adc0_clk_clk_p   => adc0_clk_clk_p,
			adc1_clk_clk_n   => adc1_clk_clk_n,
			adc1_clk_clk_p   => adc1_clk_clk_p,
			adc2_clk_clk_n   => adc2_clk_clk_n,
			adc2_clk_clk_p   => adc2_clk_clk_p,
			adc3_clk_clk_n   => adc3_clk_clk_n,
			adc3_clk_clk_p   => adc3_clk_clk_p,
			rf_sysref_diff_p => rf_sysref_p,
			rf_sysref_diff_n => rf_sysref_n,

			user_sysref => pl_sysref_reg, -- PL SYSREF resynchronized to PLCLK


			-- ADC data buses (synchronous to pl_clk)
			m00_axis_0_tdata  => adc_axis_tdata(0),
			m00_axis_0_tvalid => adc_axis_tvalid(0),
			m00_axis_0_tready => '1',
			m02_axis_0_tdata  => adc_axis_tdata(1),
			m02_axis_0_tvalid => adc_axis_tvalid(1),
			m02_axis_0_tready => '1',
			m10_axis_0_tdata  => adc_axis_tdata(2),
			m10_axis_0_tvalid => adc_axis_tvalid(2),
			m10_axis_0_tready => '1',
			m12_axis_0_tdata  => adc_axis_tdata(3),
			m12_axis_0_tvalid => adc_axis_tvalid(3),
			m12_axis_0_tready => '1',
			m20_axis_0_tdata  => adc_axis_tdata(4),
			m20_axis_0_tvalid => adc_axis_tvalid(4),
			m20_axis_0_tready => '1',
			m22_axis_0_tdata  => adc_axis_tdata(5),
			m22_axis_0_tvalid => adc_axis_tvalid(5),
			m22_axis_0_tready => '1',
			m30_axis_0_tdata  => adc_axis_tdata(6),
			m30_axis_0_tvalid => adc_axis_tvalid(6),
			m30_axis_0_tready => '1',
			m32_axis_0_tdata  => adc_axis_tdata(7),
			m32_axis_0_tvalid => adc_axis_tvalid(7),
			m32_axis_0_tready => '1',

			-- Buffered ADC data word clock. Must be fs/8.
			pl_clk => plclk,

			-- ADC calibration control

			adc0_cal_converter01_cal_frozen => adc_cal_frozen(0),
			adc0_cal_converter23_cal_frozen => adc_cal_frozen(1),
			adc1_cal_converter01_cal_frozen => adc_cal_frozen(2),
			adc1_cal_converter23_cal_frozen => adc_cal_frozen(3),
			adc2_cal_converter01_cal_frozen => adc_cal_frozen(4),
			adc2_cal_converter23_cal_frozen => adc_cal_frozen(5),
			adc3_cal_converter01_cal_frozen => adc_cal_frozen(6),
			adc3_cal_converter23_cal_frozen => adc_cal_frozen(7),

			adc0_cal_converter01_int_cal_freeze => adc_cal_freeze(0),
			adc0_cal_converter23_int_cal_freeze => adc_cal_freeze(1),
			adc1_cal_converter01_int_cal_freeze => adc_cal_freeze(2),
			adc1_cal_converter23_int_cal_freeze => adc_cal_freeze(3),
			adc2_cal_converter01_int_cal_freeze => adc_cal_freeze(4),
			adc2_cal_converter23_int_cal_freeze => adc_cal_freeze(5),
			adc3_cal_converter01_int_cal_freeze => adc_cal_freeze(6),
			adc3_cal_converter23_int_cal_freeze => adc_cal_freeze(7),

			adc0_cal_converter01_signal_detect => adc_cal_signal_detect(0),
			adc0_cal_converter23_signal_detect => adc_cal_signal_detect(1),
			adc1_cal_converter01_signal_detect => adc_cal_signal_detect(2),
			adc1_cal_converter23_signal_detect => adc_cal_signal_detect(3),
			adc2_cal_converter01_signal_detect => adc_cal_signal_detect(4),
			adc2_cal_converter23_signal_detect => adc_cal_signal_detect(5),
			adc3_cal_converter01_signal_detect => adc_cal_signal_detect(6),
			adc3_cal_converter23_signal_detect => adc_cal_signal_detect(7),

			-- ADC clock monitoring (Fs/8 or Fs/16)
			clk_adc0_0 => adc_clkout(0),
			clk_adc1_0 => adc_clkout(2),
			clk_adc2_0 => adc_clkout(4),
			clk_adc3_0 => adc_clkout(6),

			-- ADC real-time signals
			adc0_rts_converter0_datapath_overflow => open, -- out: High indicates that a sub-block in the signal chain has exceeded fll scale and has been saturated.
			adc0_rts_converter0_pl_event          => '0', --- in: assert to update ADC settings from the PL
			adc0_rts_converter01_clear_or         => adc_clear_or(0), -- in: when asserted the over range is cleared. Synchronous to AXI clock.
			adc0_rts_converter01_clear_ov         => adc_clear_ov(0),  -- in: When asserted the over voltage output is cleared. Synchronous to AXI clock. Gen 3 only.
			adc0_rts_converter01_cm_over_voltage  => adc_cm_ov(0), -- out: common mode overvoltage. Async.
			adc0_rts_converter01_cm_under_voltage => adc_cm_uv(0), -- out: common mode undervoltage. Async.
			adc0_rts_converter01_over_range       => adc_or(0), -- out: A high indicates that the signal exceeds the full-scale input of the ADC. Async.
			adc0_rts_converter01_over_threshold1  => adc_ot1(0), -- out: High indicates the threshold 1 is exceeded. Synchronous to clk_adcX.
			adc0_rts_converter01_over_threshold2  => adc_ot2(0), -- out: High indicates the threshold 2 is exceeded. Synchronous to clk_adcX.
			adc0_rts_converter01_over_voltage     => adc_ov(0), -- out: High when the signal far exceeds the normal operating input range. Async.

			adc0_rts_converter2_datapath_overflow => open,
			adc0_rts_converter2_pl_event          => '0',
			adc0_rts_converter23_clear_or         => adc_clear_or(1),
			adc0_rts_converter23_clear_ov         => adc_clear_ov(1),
			adc0_rts_converter23_cm_over_voltage  => adc_cm_ov(1),
			adc0_rts_converter23_cm_under_voltage => adc_cm_uv(1),
			adc0_rts_converter23_over_range       => adc_or(1),
			adc0_rts_converter23_over_threshold1  => adc_ot1(1),
			adc0_rts_converter23_over_threshold2  => adc_ot2(1),
			adc0_rts_converter23_over_voltage     => adc_ov(1),

			adc0_rts_sync_out    => open, -- out: one-cycle pulse asserted when sysref event has arrived and indicated divider values are valid. Synchronous to clk_adcX.
			adc0_rts_sysref_gate => '0', -- in: when asserted, sysref is not acted on by the ADC.


			adc1_rts_converter0_datapath_overflow => open, -- out: High indicates that a sub-block in the signal chain has exceeded fll scale and has been saturated.
			adc1_rts_converter0_pl_event          => '0', -- in: assert to update ADC settings from the PL
			adc1_rts_converter01_clear_or         => adc_clear_or(2), -- in: when asserted the over range is cleared. Synchronous to AXI clock.
			adc1_rts_converter01_clear_ov         => adc_clear_ov(2),  -- in: When asserted the over voltage output is cleared. Synchronous to AXI clock. Gen 3 only.
			adc1_rts_converter01_cm_over_voltage  => adc_cm_ov(2), -- out: common mode overvoltage. Async.
			adc1_rts_converter01_cm_under_voltage => adc_cm_uv(2), -- out: common mode undervoltage. Async.
			adc1_rts_converter01_over_range       => adc_or(2), -- out: A high indicates that the signal exceeds the full-scale input of the ADC. Async.
			adc1_rts_converter01_over_threshold1  => adc_ot1(2), -- out: High indicates the threshold 1 is exceeded. Synchronous to clk_adcX.
			adc1_rts_converter01_over_threshold2  => adc_ot2(2), -- out: High indicates the threshold 2 is exceeded. Synchronous to clk_adcX.
			adc1_rts_converter01_over_voltage     => adc_ov(2), -- out: High when the signal far exceeds the normal operating input range. Async.

			adc1_rts_converter2_datapath_overflow => open,
			adc1_rts_converter2_pl_event          => '0',
			adc1_rts_converter23_clear_or         => adc_clear_or(3),
			adc1_rts_converter23_clear_ov         => adc_clear_ov(3),
			adc1_rts_converter23_cm_over_voltage  => adc_cm_ov(3),
			adc1_rts_converter23_cm_under_voltage => adc_cm_uv(3),
			adc1_rts_converter23_over_range       => adc_or(3),
			adc1_rts_converter23_over_threshold1  => adc_ot1(3),
			adc1_rts_converter23_over_threshold2  => adc_ot2(3),
			adc1_rts_converter23_over_voltage     => adc_ov(3),

			adc1_rts_sync_out    => open, -- out: one-cycle pulse asserted when sysref event has arrived and indicated divider values are valid. Synchronous to clk_adcX.
			adc1_rts_sysref_gate => '0', -- in: when asserted, sysref is not acted on by the ADC.


			adc2_rts_converter0_datapath_overflow => open, -- out: High indicates that a sub-block in the signal chain has exceeded fll scale and has been saturated.
			adc2_rts_converter0_pl_event          => '0', -- in: assert to update ADC settings from the PL
			adc2_rts_converter01_clear_or         => adc_clear_or(4), -- in: when asserted the over range is cleared. Synchronous to AXI clock.
			adc2_rts_converter01_clear_ov         => adc_clear_ov(4),  -- in: When asserted the over voltage output is cleared. Synchronous to AXI clock. Gen 3 only.
			adc2_rts_converter01_cm_over_voltage  => adc_cm_ov(4), -- out: common mode overvoltage. Async.
			adc2_rts_converter01_cm_under_voltage => adc_cm_uv(4), -- out: common mode undervoltage. Async.
			adc2_rts_converter01_over_range       => adc_or(4), -- out: A high indicates that the signal exceeds the full-scale input of the ADC. Async.
			adc2_rts_converter01_over_threshold1  => adc_ot1(4), -- out: High indicates the threshold 1 is exceeded. Synchronous to clk_adcX.
			adc2_rts_converter01_over_threshold2  => adc_ot2(4), -- out: High indicates the threshold 2 is exceeded. Synchronous to clk_adcX.
			adc2_rts_converter01_over_voltage     => adc_ov(4), -- out: High when the signal far exceeds the normal operating input range. Async.

			adc2_rts_converter2_datapath_overflow => open,
			adc2_rts_converter2_pl_event          => '0',
			adc2_rts_converter23_clear_or         => adc_clear_or(5),
			adc2_rts_converter23_clear_ov         => adc_clear_ov(5),
			adc2_rts_converter23_cm_over_voltage  => adc_cm_ov(5),
			adc2_rts_converter23_cm_under_voltage => adc_cm_uv(5),
			adc2_rts_converter23_over_range       => adc_or(5),
			adc2_rts_converter23_over_threshold1  => adc_ot1(5),
			adc2_rts_converter23_over_threshold2  => adc_ot2(5),
			adc2_rts_converter23_over_voltage     => adc_ov(5),

			adc2_rts_sync_out    => open, -- out: one-cycle pulse asserted when sysref event has arrived and indicated divider values are valid. Synchronous to clk_adcX.
			adc2_rts_sysref_gate => '0', -- in: when asserted, sysref is not acted on by the ADC.

			adc3_rts_converter0_datapath_overflow => open, -- out: High indicates that a sub-block in the signal chain has exceeded fll scale and has been saturated.
			adc3_rts_converter0_pl_event          => '0', -- in: assert to update ADC settings from the PL
			adc3_rts_converter01_clear_or         => adc_clear_or(6), -- in: when asserted the over range is cleared. Synchronous to AXI clock.
			adc3_rts_converter01_clear_ov         => adc_clear_ov(6),  -- in: When asserted the over voltage output is cleared. Synchronous to AXI clock. Gen 3 only.
			adc3_rts_converter01_cm_over_voltage  => adc_cm_ov(6), -- out: common mode overvoltage. Async.
			adc3_rts_converter01_cm_under_voltage => adc_cm_uv(6), -- out: common mode undervoltage. Async.
			adc3_rts_converter01_over_range       => adc_or(6), -- out: A high indicates that the signal exceeds the full-scale input of the ADC. Async.
			adc3_rts_converter01_over_threshold1  => adc_ot1(6), -- out: High indicates the threshold 1 is exceeded. Synchronous to clk_adcX.
			adc3_rts_converter01_over_threshold2  => adc_ot2(6), -- out: High indicates the threshold 2 is exceeded. Synchronous to clk_adcX.
			adc3_rts_converter01_over_voltage     => adc_ov(6), -- out: High when the signal far exceeds the normal operating input range. Async.

			adc3_rts_converter2_datapath_overflow => open,
			adc3_rts_converter2_pl_event          => '0',
			adc3_rts_converter23_clear_or         => adc_clear_or(7),
			adc3_rts_converter23_clear_ov         => adc_clear_ov(7),
			adc3_rts_converter23_cm_over_voltage  => adc_cm_ov(7),
			adc3_rts_converter23_cm_under_voltage => adc_cm_uv(7),
			adc3_rts_converter23_over_range       => adc_or(7),
			adc3_rts_converter23_over_threshold1  => adc_ot1(7),
			adc3_rts_converter23_over_threshold2  => adc_ot2(7),
			adc3_rts_converter23_over_voltage     => adc_ov(7),

			adc3_rts_sync_out    => open, -- out: one-cycle pulse asserted when sysref event has arrived and indicated divider values are valid. Synchronous to clk_adcX.
			adc3_rts_sysref_gate => '0', -- in: when asserted, sysref is not acted on by the ADC.

			--    -- 100GE interface
			--    cge_tx_p => qsfp_txp,
			--    cge_tx_n => qsfp_txn,
			--    cge_refclk_p => clk156_p,
			--    cge_refclk_n => clk156_n,

			-- Capture data stream from the FPGA to the ARM
			s_axis_cap_tdata  => axis_cap_tdata,
			s_axis_cap_tvalid => axis_cap_tvalid,
			s_axis_cap_tlast  => axis_cap_tlast,
			s_axis_cap_tready => axis_cap_tready,
			s_axis_cap_tkeep  => (others => '1'),
		);
	*/

	-- Assign clocks to odd-numbered
	adc_clkout(1) <= adc_clkout(0);
	adc_clkout(3) <= adc_clkout(2);
	adc_clkout(5) <= adc_clkout(4);
	adc_clkout(7) <= adc_clkout(6);

	chfpga0: entity work.chfpga
		generic map (
			PLATFORM_ID => PLATFORM_ID,

			-- Clocking config
			SYSTEM_CLOCK_SOURCE => SYSTEM_CLOCK_SOURCE,
			SYSTEM_CLOCK_FREQ   => SYSTEM_CLOCK_FREQ,
			CHAN_CLK_SOURCE     => CHAN_CLK_SOURCE,
			CT_CLK_SOURCE       => CT_CLK_SOURCE,

			PHY_TYPE       => PHY_TYPE,
			ADC_TYPE       => ADC_TYPE,
			NUMBER_OF_ADCS => NUMBER_OF_ADCS,

			-- F-Engine / Channelizers
			FFT_TYPE               => FFT_TYPE,
			NUMBER_OF_CHANNELIZERS => NUMBER_OF_CHANNELIZERS,
			CAPTURE_TYPE           => CAPTURE_TYPE,

			-- Corner Turn Engine
			CT_TYPE                     => CT_TYPE,
			CT_LEVEL                    => CT_LEVEL,
			NUMBER_OF_CROSSBAR_INPUTS   => NUMBER_OF_CROSSBAR_INPUTS,
			NUMBER_OF_CROSSBAR1_OUTPUTS => NUMBER_OF_CROSSBAR1_OUTPUTS,

			NUMBER_OF_BP_PCB_SHUFFLE_LANES  => NUMBER_OF_BP_PCB_SHUFFLE_LANES,
			NUMBER_OF_BP_QSFP_SHUFFLE_LANES => NUMBER_OF_BP_QSFP_SHUFFLE_LANES,
			NUMBER_OF_BP_SHUFFLE_LINKS      => NUMBER_OF_BP_SHUFFLE_LINKS,
			NUMBER_OF_BP_SHUFFLE_REFCLKS    => NUMBER_OF_BP_SHUFFLE_REFCLKS,

			-- Real time Ethernet data streaming interface
			GPU_LINK_TYPE         => GPU_LINK_TYPE,
			GPU_CHANNEL_QUAD                => integerarray(GPU_CHANNEL_QUAD),
			GPU_QUAD_REFCLK                 => integerarray(GPU_QUAD_REFCLK),

			-- Correlator
			CORR_TYPE             => CORR_TYPE,
			NUMBER_OF_CORRELATORS => NUMBER_OF_CORRELATORS,

			-- Peripherals
			BLINKER_PRESENT      => BLINKER_PRESENT,
			NUMBER_OF_I2C_PORTS  => NUMBER_OF_I2C_PORTS,
			NUMBER_OF_SPI_PORTS  => NUMBER_OF_SPI_PORTS,
			NUMBER_OF_ADC_BOARDS => NUMBER_OF_ADC_BOARDS,
			IMPLEMENT_ARM_SPI    => IMPLEMENT_ARM_SPI, -- is implemented if not specified
			IMPLEMENT_LCD        => IMPLEMENT_LCD,
			SIM                  => SIM
		)

		port map (
			-- System reset
			cpu_reset => cpu_reset,

			-- Reference clock
			clk10     => sysclk, -- Buffered (BUFG) 10 MHz differential reference clock
			clk10_sel => clk10_sel,

			-- External PLL
			pll_oscout => pll_oscout,
			pll_sync   => pll_sync_bsb, -- sync signal approximately synchronous to pll_oscout. Will be rtimed on the falline edge then rising edge of pll_oscout.

			-- System clock
			sysclk_bufg => sysclk,

			-- Buck sync
			buck_sync => buck_sync,

			-- Time signal

			bp_time_in => sma_irig,
			bp_trig_in => bp_irig,

			-- ADC inputs
			adc_axis_tdata        => adc_axis_tdata(0 to NUMBER_OF_ADCS - 1),
			adc_axis_tvalid       => adc_axis_tvalid(0 to NUMBER_OF_ADCS - 1),
			adc_axis_clk          => (0 to NUMBER_OF_ADCS - 1 => plclk),
			adc_sysref            => pl_sysref_reg,
			adc_clkout            => adc_clkout(0 to NUMBER_OF_ADCS - 1),
			adc_cal_frozen        => adc_cal_frozen(0 to NUMBER_OF_ADCS - 1),
			adc_cal_freeze        => adc_cal_freeze(0 to NUMBER_OF_ADCS - 1),
			adc_cal_signal_detect => adc_cal_signal_detect(0 to NUMBER_OF_ADCS - 1),
			adc_clear_or          => adc_clear_or(0 to NUMBER_OF_ADCS - 1),
			adc_clear_ov          => adc_clear_ov(0 to NUMBER_OF_ADCS - 1),
			adc_cm_ov             => adc_cm_ov(0 to NUMBER_OF_ADCS - 1),
			adc_cm_uv             => adc_cm_uv(0 to NUMBER_OF_ADCS - 1),
			adc_or                => adc_or(0 to NUMBER_OF_ADCS - 1),
			adc_ot1               => adc_ot1(0 to NUMBER_OF_ADCS - 1),
			adc_ot2               => adc_ot2(0 to NUMBER_OF_ADCS - 1),
			adc_ov                => adc_ov(0 to NUMBER_OF_ADCS - 1),

			------------------------------------
			-- Corner-Turn Engine
			------------------------------------
			-- Gigabit Transceiver links to the backplane for intra-crate and inter-crate data transfers
			bp_shuffle_tx_p => bp_shuffle_tx_p_int,
			bp_shuffle_tx_n => bp_shuffle_tx_n_int,
			bp_shuffle_rx_p => bp_shuffle_rx_p,
			bp_shuffle_rx_n => bp_shuffle_rx_n,
			-- Gigabit transceiver reference clocks (typically 156.25 MHz)
			bp_shuffle_refclk_p => bp_shuffle_refclk_p,
			bp_shuffle_refclk_n => bp_shuffle_refclk_n,

			-- LEDs
			gpio_led => gpio_led,

			-- Display
			lcd_db => lcd_db,

			-- 100GE interface
			cge_tx_p     => qsfp_txp,
			cge_tx_n     => qsfp_txn,
			cge_refclk_p => clk156_p,
			cge_refclk_n => clk156_n,

			-- debug bus
			-- debug_out => debug_out,
			-- sma_out => , --smp,
			user_mux_out => sma_out,

			-- Command input stream
			s_axis_bsb_tdata  => axis_bsb_cmd_tdata,
			s_axis_bsb_tvalid => axis_bsb_cmd_tvalid,
			s_axis_bsb_tlast  => axis_bsb_cmd_tlast,
			s_axis_bsb_tready => axis_bsb_cmd_tready,

			-- Reply output stream
			m_axis_bsb_tdata  => axis_bsb_rply_tdata,
			m_axis_bsb_tvalid => axis_bsb_rply_tvalid,
			m_axis_bsb_tlast  => axis_bsb_rply_tlast,
			m_axis_bsb_tready => axis_bsb_rply_tready,

			axis_bsb_clk => aclk,
			axis_bsb_rst => axis_bsb_rst,

			-- Data capture stream
			m_axis_cap_tdata  => axis_cap_tdata,
			m_axis_cap_tvalid => axis_cap_tvalid,
			m_axis_cap_tlast  => axis_cap_tlast,
			m_axis_cap_tready => axis_cap_tready,

			axis_cap_clk => aclk
		);

end architecture impl;
