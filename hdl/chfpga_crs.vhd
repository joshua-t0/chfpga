--Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
--Date        : Tue Mar 28 11:38:21 2023
--Host        : twiddlebug running 64-bit Ubuntu 22.04.1 LTS
--Command     :
--Design      : chfpga_crs
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
-- Top level module to instantiate chFPGA on a crs
-- Instantiates and connects:
--   - Block diagram containing the Zynq, ADC, and DMA interfaces
--   - chFPGA instance parametrized for the platform (crs) and the target functions (chfpga or sispga)
--
-- Manually created by JFC from an automatically generated block diagram wrapper.


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

use work.chfpga_package.all; -- Get all component definitions
use work.chfpga_config.all; --Get platform-specific configuration definitions

library xpm;
use xpm.vcomponents.all;

entity chfpga_crs is
    generic (

        PLATFORM_ID: integer                         := CONFIG_PLATFORM_ID; --  Identifies the type of platform on which the firmware is running.

        -- Clocking config
        SYSTEM_CLOCK_SOURCE: string                  := "SYSCLK_BUFG"; -- System reference clock surce: "SYSCLK": 200 MHz unbuffered differential clock from sysclk_p/n, "SYSCLK_BUFG": 200 MHz BUFG-Buffered clock from sysclk_bufg, "SFP_REFCLK": 125 MHz clock from the GTX reference clock
        SYSTEM_CLOCK_FREQ: real                      := 10.0; -- System reference clock frequency, in MHz. Must be a real value (i.e. float). Used to select the system PLL divider/multiplier factors.
        CHAN_CLK_SOURCE: string                      := "ADC"; -- Clock sources for the system PLL. Here, Channelizer clock comes directly from the ADC
        CT_CLK_SOURCE: string                        := "ADC_CLK"; -- corner-turn clock source

        -- Buck synchronization

        BUCK_SYNC_ENABLE: boolean                    := TRUE; -- default state of the buck sync enable at startup
        BUCK_CLK_DIVIDE_FACTOR: integer              := 12; -- Buck frequency is 200MHz/16/BUCK_CLK_DIVIDE_FACTOR, 12=> 1.0416 MHz, 17 => 0.73529 MHz, 24=>0.5208333 MHz

        PHY_TYPE: string                             := "NONE"; -- "GMII" or "SGMII"
        SGMII_CLOCK_SOURCE: string                   := "REFCLK"; -- Selects the 125MHz clock source for the SGMII interface; "CLK125": uses the 125 MHz clock (clk125) from the main MMCM, "REFCLK": uses the GTX Reference clock (gtrefclk)

        -- ADC config
        ADC_TYPE: string                             := "AXIS"; -- ADC data is provided through the axis_adc port
        NUMBER_OF_ADCS: integer                      := CONFIG_NUMBER_OF_ADCS; -- Number of ADC inputs

        -- Mezzanines
        NUMBER_OF_ADC_BOARDS: integer                := 0; -- No mezzanine, therefore no associated clocks etc.

        -- Channelizer configuration
        NUMBER_OF_CHANNELIZERS:integer               := CONFIG_NUMBER_OF_ADCS;  --(Typ. =16)  (0-NUMBER_OF_ADCS) Number of channelizer blocks to be implemented
        CAPTURE_TYPE: string                         := CONFIG_CHAN_CAPTURE_TYPE;

        -- Corner-turn engine configuration
        CROSSBAR1_TYPE: string                       := CONFIG_CROSSBAR1_TYPE; -- "BRAM" or "URAM"
        NUMBER_OF_CROSSBAR_INPUTS: integer           := CONFIG_NUMBER_OF_CROSSBAR_INPUTS; -- (Typ. =16)(0-NUMBER_OF_CHANNELIZERS): Number of channelizers output that are being aligned, filtered and repacked for the corrleator or GPU links
        NUMBER_OF_CROSSBAR1_OUTPUTS: integer         := CONFIG_NUMBER_OF_CROSSBAR1_OUTPUTS; -- (Typ. =16): Number of output lanes of CROSSBAR1. Should be 8 for URAM-based crossbar1.
        NUMBER_OF_BP_PCB_SHUFFLE_LANES: integer      := CONFIG_NUMBER_OF_BP_PCB_SHUFFLE_LANES;
        NUMBER_OF_BP_QSFP_SHUFFLE_LANES: integer     := CONFIG_NUMBER_OF_BP_QSFP_SHUFFLE_LANES;
        NUMBER_OF_BP_SHUFFLE_LINKS: integer          := CONFIG_NUMBER_OF_BP_SHUFFLE_LINKS; -- Number of GTXes for both the backplane PCB and QSFP shuffle links. Usually matches the number of 1st crossbar output lanes.
        NUMBER_OF_BP_SHUFFLE_REFCLKS: integer        := CONFIG_NUMBER_OF_BP_SHUFFLE_REFCLKS;

        -- Correlator config
        CORR_TYPE: string                            := CONFIG_CORR_TYPE; -- "CORR44" or "UCORR44"
        NUMBER_OF_CORRELATORS: integer               := CONFIG_NUMBER_OF_CORRELATORS; -- Number of correlators. Normally NUMBER_OF_CROSSBAR_OUTPUTS. Correlator not implemented if zero.

        -- Real-time data offload links configuration
        GPU_LINK_TYPE: string                        := CONFIG_GPU_LINK_TYPE; --
        NUMBER_OF_GPU_LINKS: integer                 := CONFIG_NUMBER_OF_GPU_LINKS; -- (0- NUMBER_OF_REORDER_OUTPUTS) Number of 10Gb Ethernet links to connecto to the GPUs
        NUMBER_OF_GPU_REFCLKS: integer               := CONFIG_NUMBER_OF_GPU_REFCLKS; -- Number of Reference clocks provided for the 10GE links to the GPU

        -- Peripheral config
        BLINKER_PRESENT: boolean                     := TRUE; -- Indicates if the LED flasher is to be implemented by setting the DUMMY flag of the BLINKER module
        NUMBER_OF_I2C_PORTS: integer                 := 0;
        NUMBER_OF_SPI_PORTS: integer                 := 0; -- One port for each FMC
        IMPLEMENT_ARM_SPI: boolean                   := FALSE;

        SIM: boolean := FALSE-- Indicates this is running as a simulation. Used to accelerate simulations

    );

    port (

        -- Copy of the 10 MHz SMA reference clock that feeds the programmable PLL
        sma_clk10_n : in std_logic;
        sma_clk10_p : in std_logic;


        -- Copy of the 10 MHz Backplane reference clock that feeds the programmable PLL
        bp_clk10_n : in std_logic;
        bp_clk10_p : in std_logic;


        -- 50 MHz VCXO frequency from programmable PLL (output of PLL1). Is in phase with the external 10 MHz reference clocks.
        pll_oscout_n : in std_logic;
        pll_oscout_p : in std_logic;
        pll_sync: out std_logic;

        -- 375 MHz processing clock form programmable PLL
        plclk_n : in std_logic;
        plclk_p : in std_logic;

        -- SYSREF clock from programmable PLL - used to synchronize the ADCs
        rf_sysref_n : in std_logic;
        rf_sysref_p : in std_logic;

        pl_sysref_n : in std_logic;
        pl_sysref_p : in std_logic;


        -- 250 MHz system clock from programmable PLL. Used as source to generate internal clocks using MMCM.
        sysclk_n : in std_logic;
        sysclk_p : in std_logic;




        -- 100G Ethernet

        --   156.25 MHz reference clock
        clk156_n : in std_logic;
        clk156_p : in std_logic;
        --   QSFP data lanes
        qsfp_txn : out std_logic_vector(0 to 3);
        qsfp_txp : out std_logic_vector(0 to 3);


        -- Buck sync signals

        buck_sync_0v85 : out std_logic;
        buck_sync_1v2a : out std_logic;
        buck_sync_1v2b : out std_logic;
        buck_sync_1v4 : out std_logic;
        buck_sync_1v8 : out std_logic;
        buck_sync_2v5 : out std_logic;
        buck_sync_3v3 : out std_logic;
        buck_sync_5v0 : out std_logic;
        buck_sync_bp : out std_logic;

        -- LEDs (PL's 7-segment display)
        led7b : out std_logic_vector (7 downto 0);

        -- User connectors
        smp : out std_logic_vector (0 to 3);

        -- IRIG-B signals
        sma_irig_p: in std_logic;
        sma_irig_n: in std_logic;

        bp_irig_p: in std_logic;
        bp_irig_n: in std_logic;

        -- ADC sampling clocks
        adc0_clk_clk_n : in std_logic;
        adc0_clk_clk_p : in std_logic;
        adc1_clk_clk_n : in std_logic;
        adc1_clk_clk_p : in std_logic;
        adc2_clk_clk_n : in std_logic;
        adc2_clk_clk_p : in std_logic;
        adc3_clk_clk_n : in std_logic;
        adc3_clk_clk_p : in std_logic;

        -- ADC analog inputs
        vin0_01_v_n : in std_logic;
        vin0_01_v_p : in std_logic;
        vin0_23_v_n : in std_logic;
        vin0_23_v_p : in std_logic;
        vin1_01_v_n : in std_logic;
        vin1_01_v_p : in std_logic;
        vin1_23_v_n : in std_logic;
        vin1_23_v_p : in std_logic;
        vin2_01_v_n : in std_logic;
        vin2_01_v_p : in std_logic;
        vin2_23_v_n : in std_logic;
        vin2_23_v_p : in std_logic;
        vin3_01_v_n : in std_logic;
        vin3_01_v_p : in std_logic;
        vin3_23_v_n : in std_logic;
        vin3_23_v_p : in std_logic
        );
        -- Don't put a DONT_TOUCH attribute to this entity: we need qsfp_tx/rx to be removed if unused
end entity;


architecture impl of chfpga_crs is

    attribute io_buffer_type : string;
    attribute dont_touch: string;
    attribute IOB: string;

    -- Tell the tools not to infer buffers and autoplace IO ports for the following if the ports are not connected
    -- If 100GE is not implemented, the placer assigns random IOs to these ports, and since those have no specifiec IO standard, the bitstream
    -- fails its DRC.
    -- "None" tells the tools not to implement an IO port. "OBUF" implements the IO port.
    --  In the case of "OBUF", it looks like the output buffer is adapted to the type of output such as a transceiver output etc.
    attribute io_buffer_type of qsfp_txp, qsfp_txn: signal is sel(GPU_LINK_TYPE="100GE", "OBUF", "NONE");
    attribute io_buffer_type of clk156_p, clk156_n: signal is sel(GPU_LINK_TYPE="100GE", "IBUF", "NONE");

    -- BSB & CAP AXIS clock (100 MHz)
    signal aclk: std_logic;

    -- ADC word clock (Fs/8 = 3000/8 = 375 MHz)
    signal plclk_nobuf: std_logic;
    signal plclk_bufg: std_logic;

    -- PLL VCXO clock (50 MHz)
    signal pll_oscout_nobuf: std_logic;
    signal pll_oscout_bufg: std_logic;
    signal pll_sync_bsb, pll_sync10, pll_sync50_pre1,pll_sync50_pre2,pll_sync50_pre3: std_logic;
    -- System Reference clock (Submultiple of ADC sampling clock/16, < 10 MHz)
    -- Used to calibrate the ADC latency
    signal pl_sysref, pl_sysref_pre, pl_sysref_pre2, pl_sysref_reg: std_logic;
--    attribute IOB of pl_sysref_reg :signal is "true"; -- make sure PL_SYSREF is registered in the IOB to ensure the best and reproducible timing
    attribute dont_touch of pl_sysref_pre, pl_sysref_pre2, pl_sysref_reg: signal is "true";

    --signal sysref_bufg: std_logic;

    -- System clock (250 MHz)
    signal sysclk_nobuf: std_logic;
    signal sysclk_bufg: std_logic;

    -- 10 MHz reference clocks
    signal sma_clk10_nobuf, bp_clk10_nobuf: std_logic;
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

    signal axis_bsb_cmd_tdata: std_logic_vector(7 downto 0);
    signal axis_bsb_cmd_tvalid: std_logic;
    signal axis_bsb_cmd_tlast: std_logic;
    signal axis_bsb_cmd_tready: std_logic;

    signal axis_bsb_rply_tdata: std_logic_vector(7 downto 0);
    signal axis_bsb_rply_tvalid: std_logic;
    signal axis_bsb_rply_tlast: std_logic;
    signal axis_bsb_rply_tready: std_logic;

    signal axis_cap_tdata: std_logic_vector(7 downto 0);
    signal axis_cap_tvalid: std_logic;
    signal axis_cap_tlast: std_logic;
    signal axis_cap_tready: std_logic;

--    signal cpu_reset: std_logic;
    signal cpu_reset_n: std_logic;

--    signal bsb_reset: std_logic;
    signal bsb_reset_n: std_logic;
    signal buck_sync: std_logic_vector(0 to 15);
    signal gpio_led: std_logic_vector(7 downto 0);
    signal sma_irig, bp_irig: std_logic;

    signal qsfp_txp_int, qsfp_txn_int: std_logic_vector(0 to 3);
    signal irigb_reg:std_logic;

    signal pl400, pl10:std_logic;
    attribute dont_touch of pl400, pl10: signal is "true";

begin
    -----------
    -- 10 MHz Reference clocks from SMA and BP
    -----------
    clk10_ibufds0 : IBUFGDS -- Instantiate a differential (LVDS) input pad pair
        generic map(DIFF_TERM => TRUE)
        port map (
            I => sma_clk10_p,
            IB => sma_clk10_n,
            O => sma_clk10_nobuf
        );

    clk10_ibufds1 : IBUFGDS -- Instantiate a differential (LVDS) input pad pair
        generic map(DIFF_TERM => TRUE)
        port map (
            I => bp_clk10_p,
            IB => bp_clk10_n,
            O => bp_clk10_nobuf
        );

    clk10_ibuf0 : BUFGMUX
        generic map (
           CLK_SEL_TYPE => "ASYNC"  -- ASYNC, SYNC
        )
        port map (
           I0 => sma_clk10_nobuf, -- 1-bit input: Clock input (S=0)
           I1 => bp_clk10_nobuf, -- 1-bit input: Clock input (S=1)
           O => clk10_bufg,   -- 1-bit output: Clock output
           S => clk10_sel    -- 1-bit input: Clock select
        );


    -----------
    -- 2.5 MHz SYSREF clock from PLL, used for ADC latency calibration
    -----------

	sysref_ibufds0 : IBUFGDS -- Instantiate a differential (LVDS) input pad pair
		generic map(DIFF_TERM => TRUE)
		port map (
			I => pl_sysref_p,
			IB => pl_sysref_n,
			O => pl_sysref
		);

    -- Register SYSREF
    -- This is required for the Multi-Converter synchronization
    sysref0_proc: process (plclk_bufg)
    begin
        if rising_edge(plclk_bufg) then
            pl_sysref_pre <= pl_sysref;
            pl_sysref_pre2 <= pl_sysref_pre;
            pl_sysref_reg <= pl_sysref_pre2;

            pl400 <= pl10;
        end if;
    end process;


    -----------
    -- 10 MHz SYSCLK clock from PLL
    -----------

    sysclk_ibufds0 : IBUFGDS -- Instantiate a differential (LVDS) input pad pair
        generic map(DIFF_TERM => TRUE)
        port map (
            I => sysclk_p,
            IB => sysclk_n,
            O => sysclk_nobuf
        );
    sysclk_bufg0 : BUFG
        port map (
            I => sysclk_nobuf, -- Clock buffer input
            O => sysclk_bufg-- Clock buffer output
        );

   sysclk0_proc: process (sysclk_bufg)
    begin
        if rising_edge(sysclk_bufg) then

            pl10 <= not pl10;
        end if;
    end process;


    -----------
    -- 50 MHz OSCOUT clock from PLL
    -----------
    -- This clock is aligned to the external 10 MHz refernece clock and is used to synchronize the SYNC signal to the PLL

	oscout_ibufds0 : IBUFGDS -- Instantiate a differential (LVDS) input pad pair
		generic map(DIFF_TERM => TRUE)
		port map (
			I => pll_oscout_p,
			IB => pll_oscout_n,
			O => pll_oscout_nobuf
		);
	oscout_bufg0 : BUFG
        port map (
            I => pll_oscout_nobuf, -- Clock buffer input
            O => pll_oscout_bufg-- Clock buffer output
        );

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
        generic map (SRC_INPUT_REG => 0)
        port map (src_clk => '0', src_in => pll_sync_bsb, dest_clk => clk10_bufg, dest_out => pll_sync10);

    -- Synchronize SYNC to OSCOUT
        pllsync0_proc: process (pll_oscout_bufg)
    begin
        if falling_edge(pll_oscout_bufg) then
            pll_sync50_pre1 <= pll_sync10;
            pll_sync50_pre2 <= pll_sync50_pre1;
            pll_sync50_pre3 <= pll_sync50_pre2;
            pll_sync <= pll_sync50_pre3;
        end if;
--        if rising_edge(pll_oscout_bufg) then
--        end if;
    end process;


	plclk_ibufds0 : IBUFGDS -- Instantiate a differential (LVDS) input pad pair
		generic map(DIFF_TERM => TRUE)
		port map (
			I => plclk_p,
			IB => plclk_n,
			O => plclk_nobuf
		);
	plclk_bufg0 : BUFG
        port map (
            I => plclk_nobuf, -- Clock buffer input
            O => plclk_bufg-- Clock buffer output
        );

    -- Buck sync

    buck_sync_5v0 <= buck_sync(0);
    buck_sync_0v85 <= buck_sync(1); -- two switchers operating in paralle 180deg out of phase. Combined freq is double.
    buck_sync_3v3 <= buck_sync(2);
    buck_sync_2v5 <= buck_sync(3);
    buck_sync_1v8 <= buck_sync(4);
    buck_sync_1v2a <= buck_sync(5);
    buck_sync_1v2b <= buck_sync(6);
    buck_sync_1v4 <= buck_sync(7);
    buck_sync_bp <= buck_sync(8);

    -- IRIG time signal
    irig_ibufds0 : IBUFDS -- Instantiate a differential (LVDS) input pad pair
        generic map(DIFF_TERM => TRUE)
        port map (
            I => sma_irig_p,
            IB => sma_irig_n,
            O => sma_irig
        );


    -- IRIG time signal
    irig_ibufds1 : IBUFDS -- Instantiate a differential (LVDS) input pad pair
        generic map(DIFF_TERM => TRUE)
        port map (
            I => bp_irig_p,
            IB => bp_irig_n,
            O => bp_irig
        );


    -- Register SYSREF
    -- This is required for the Multi-Converter synchronization
    irigb_proc: process (plclk_bufg)
    begin
        if rising_edge(plclk_bufg) then
            irigb_reg <= sma_irig when clk10_sel else bp_irig;
        end if;
    end process;

    -- 7-segment display
    led7b(5 downto 0) <= gpio_led(6 downto 1); -- a-f segments (forming a circle)
    led7b(6) <= '0'; -- central g segment
    led7b(7) <= '0'; -- decimal point

--dbg1: if FALSE generate
zynq: entity work.zynq_tcpipe_crs
    port map (

    -- ADC sampling clocks
    adc0_clk_clk_n => adc0_clk_clk_n,
    adc0_clk_clk_p => adc0_clk_clk_p,
    adc1_clk_clk_n => adc1_clk_clk_n,
    adc1_clk_clk_p => adc1_clk_clk_p,
    adc2_clk_clk_n => adc2_clk_clk_n,
    adc2_clk_clk_p => adc2_clk_clk_p,
    adc3_clk_clk_n => adc3_clk_clk_n,
    adc3_clk_clk_p => adc3_clk_clk_p,
    rf_sysref_diff_p => rf_sysref_p,
    rf_sysref_diff_n => rf_sysref_n,

    user_sysref => pl_sysref_reg, -- PL SYSREF resynchronized to PLCLK



    -- ADC analog inputs
    vin0_01_v_n => vin0_01_v_n,
    vin0_01_v_p => vin0_01_v_p,
    vin0_23_v_n => vin0_23_v_n,
    vin0_23_v_p => vin0_23_v_p,
    vin1_01_v_n => vin1_01_v_n,
    vin1_01_v_p => vin1_01_v_p,
    vin1_23_v_n => vin1_23_v_n,
    vin1_23_v_p => vin1_23_v_p,
    vin2_01_v_n => vin2_01_v_n,
    vin2_01_v_p => vin2_01_v_p,
    vin2_23_v_n => vin2_23_v_n,
    vin2_23_v_p => vin2_23_v_p,
    vin3_01_v_n => vin3_01_v_n,
    vin3_01_v_p => vin3_01_v_p,
    vin3_23_v_n => vin3_23_v_n,
    vin3_23_v_p => vin3_23_v_p,

      -- ADC data buses (synchronous to pl_clk)
    m00_axis_0_tdata => adc_axis_tdata(0),
    m00_axis_0_tvalid => adc_axis_tvalid(0),
    m00_axis_0_tready => '1',
    m02_axis_0_tdata => adc_axis_tdata(1),
    m02_axis_0_tvalid => adc_axis_tvalid(1),
    m02_axis_0_tready => '1',
    m10_axis_0_tdata => adc_axis_tdata(2),
    m10_axis_0_tvalid => adc_axis_tvalid(2),
    m10_axis_0_tready => '1',
    m12_axis_0_tdata => adc_axis_tdata(3),
    m12_axis_0_tvalid => adc_axis_tvalid(3),
    m12_axis_0_tready => '1',
    m20_axis_0_tdata => adc_axis_tdata(4),
    m20_axis_0_tvalid => adc_axis_tvalid(4),
    m20_axis_0_tready => '1',
    m22_axis_0_tdata => adc_axis_tdata(5),
    m22_axis_0_tvalid => adc_axis_tvalid(5),
    m22_axis_0_tready => '1',
    m30_axis_0_tdata => adc_axis_tdata(6),
    m30_axis_0_tvalid => adc_axis_tvalid(6),
    m30_axis_0_tready => '1',
    m32_axis_0_tdata => adc_axis_tdata(7),
    m32_axis_0_tvalid => adc_axis_tvalid(7),
    m32_axis_0_tready => '1',

    -- Buffered ADC data word clock. Must be fs/8.
    pl_clk => plclk_bufg,

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
    adc0_rts_converter0_pl_event => '0', --- in: assert to update ADC settings from the PL
    adc0_rts_converter01_clear_or => adc_clear_or(0), -- in: when asserted the over range is cleared. Synchronous to AXI clock.
    adc0_rts_converter01_clear_ov => adc_clear_ov(0),  --in: When asserted the over voltage output is cleared. Synchronous to AXI clock. Gen 3 only.
    adc0_rts_converter01_cm_over_voltage => adc_cm_ov(0), -- out: common mode overvoltage. Async.
    adc0_rts_converter01_cm_under_voltage => adc_cm_uv(0), -- out: common mode undervoltage. Async.
    adc0_rts_converter01_over_range => adc_or(0), -- out: A high indicates that the signal exceeds the full-scale input of the ADC. Async.
    adc0_rts_converter01_over_threshold1 => adc_ot1(0), -- out: High indicates the threshold 1 is exceeded. Synchronous to clk_adcX.
    adc0_rts_converter01_over_threshold2 => adc_ot2(0), -- out: High indicates the threshold 2 is exceeded. Synchronous to clk_adcX.
    adc0_rts_converter01_over_voltage => adc_ov(0), -- out: High when the signal far exceeds the normal operating input range. Async.

    adc0_rts_converter2_datapath_overflow => open,
    adc0_rts_converter2_pl_event => '0',
    adc0_rts_converter23_clear_or => adc_clear_or(1),
    adc0_rts_converter23_clear_ov => adc_clear_ov(1),
    adc0_rts_converter23_cm_over_voltage => adc_cm_ov(1),
    adc0_rts_converter23_cm_under_voltage => adc_cm_uv(1),
    adc0_rts_converter23_over_range => adc_or(1),
    adc0_rts_converter23_over_threshold1 => adc_ot1(1),
    adc0_rts_converter23_over_threshold2 => adc_ot2(1),
    adc0_rts_converter23_over_voltage => adc_ov(1),

    adc0_rts_sync_out => open,-- out: one-cycle pulse asserted when sysref event has arrived and indicated divider values are valid. Synchronous to clk_adcX.
    adc0_rts_sysref_gate => '0', -- in: when asserted, sysref is not acted on by the ADC.


    adc1_rts_converter0_datapath_overflow => open, -- out: High indicates that a sub-block in the signal chain has exceeded fll scale and has been saturated.
    adc1_rts_converter0_pl_event => '0', --- in: assert to update ADC settings from the PL
    adc1_rts_converter01_clear_or => adc_clear_or(2), -- in: when asserted the over range is cleared. Synchronous to AXI clock.
    adc1_rts_converter01_clear_ov => adc_clear_ov(2),  --in: When asserted the over voltage output is cleared. Synchronous to AXI clock. Gen 3 only.
    adc1_rts_converter01_cm_over_voltage => adc_cm_ov(2), -- out: common mode overvoltage. Async.
    adc1_rts_converter01_cm_under_voltage => adc_cm_uv(2), -- out: common mode undervoltage. Async.
    adc1_rts_converter01_over_range => adc_or(2), -- out: A high indicates that the signal exceeds the full-scale input of the ADC. Async.
    adc1_rts_converter01_over_threshold1 => adc_ot1(2), -- out: High indicates the threshold 1 is exceeded. Synchronous to clk_adcX.
    adc1_rts_converter01_over_threshold2 => adc_ot2(2), -- out: High indicates the threshold 2 is exceeded. Synchronous to clk_adcX.
    adc1_rts_converter01_over_voltage => adc_ov(2), -- out: High when the signal far exceeds the normal operating input range. Async.

    adc1_rts_converter2_datapath_overflow => open,
    adc1_rts_converter2_pl_event => '0',
    adc1_rts_converter23_clear_or => adc_clear_or(3),
    adc1_rts_converter23_clear_ov => adc_clear_ov(3),
    adc1_rts_converter23_cm_over_voltage => adc_cm_ov(3),
    adc1_rts_converter23_cm_under_voltage => adc_cm_uv(3),
    adc1_rts_converter23_over_range => adc_or(3),
    adc1_rts_converter23_over_threshold1 => adc_ot1(3),
    adc1_rts_converter23_over_threshold2 => adc_ot2(3),
    adc1_rts_converter23_over_voltage => adc_ov(3),

    adc1_rts_sync_out => open,-- out: one-cycle pulse asserted when sysref event has arrived and indicated divider values are valid. Synchronous to clk_adcX.
    adc1_rts_sysref_gate => '0', -- in: when asserted, sysref is not acted on by the ADC.


    adc2_rts_converter0_datapath_overflow => open, -- out: High indicates that a sub-block in the signal chain has exceeded fll scale and has been saturated.
    adc2_rts_converter0_pl_event => '0', --- in: assert to update ADC settings from the PL
    adc2_rts_converter01_clear_or => adc_clear_or(4), -- in: when asserted the over range is cleared. Synchronous to AXI clock.
    adc2_rts_converter01_clear_ov => adc_clear_ov(4),  --in: When asserted the over voltage output is cleared. Synchronous to AXI clock. Gen 3 only.
    adc2_rts_converter01_cm_over_voltage => adc_cm_ov(4), -- out: common mode overvoltage. Async.
    adc2_rts_converter01_cm_under_voltage => adc_cm_uv(4), -- out: common mode undervoltage. Async.
    adc2_rts_converter01_over_range => adc_or(4), -- out: A high indicates that the signal exceeds the full-scale input of the ADC. Async.
    adc2_rts_converter01_over_threshold1 => adc_ot1(4), -- out: High indicates the threshold 1 is exceeded. Synchronous to clk_adcX.
    adc2_rts_converter01_over_threshold2 => adc_ot2(4), -- out: High indicates the threshold 2 is exceeded. Synchronous to clk_adcX.
    adc2_rts_converter01_over_voltage => adc_ov(4), -- out: High when the signal far exceeds the normal operating input range. Async.

    adc2_rts_converter2_datapath_overflow => open,
    adc2_rts_converter2_pl_event => '0',
    adc2_rts_converter23_clear_or => adc_clear_or(5),
    adc2_rts_converter23_clear_ov => adc_clear_ov(5),
    adc2_rts_converter23_cm_over_voltage => adc_cm_ov(5),
    adc2_rts_converter23_cm_under_voltage => adc_cm_uv(5),
    adc2_rts_converter23_over_range => adc_or(5),
    adc2_rts_converter23_over_threshold1 => adc_ot1(5),
    adc2_rts_converter23_over_threshold2 => adc_ot2(5),
    adc2_rts_converter23_over_voltage => adc_ov(5),

    adc2_rts_sync_out => open,-- out: one-cycle pulse asserted when sysref event has arrived and indicated divider values are valid. Synchronous to clk_adcX.
    adc2_rts_sysref_gate => '0', -- in: when asserted, sysref is not acted on by the ADC.

    adc3_rts_converter0_datapath_overflow => open, -- out: High indicates that a sub-block in the signal chain has exceeded fll scale and has been saturated.
    adc3_rts_converter0_pl_event => '0', --- in: assert to update ADC settings from the PL
    adc3_rts_converter01_clear_or => adc_clear_or(6), -- in: when asserted the over range is cleared. Synchronous to AXI clock.
    adc3_rts_converter01_clear_ov => adc_clear_ov(6),  --in: When asserted the over voltage output is cleared. Synchronous to AXI clock. Gen 3 only.
    adc3_rts_converter01_cm_over_voltage => adc_cm_ov(6), -- out: common mode overvoltage. Async.
    adc3_rts_converter01_cm_under_voltage => adc_cm_uv(6), -- out: common mode undervoltage. Async.
    adc3_rts_converter01_over_range => adc_or(6), -- out: A high indicates that the signal exceeds the full-scale input of the ADC. Async.
    adc3_rts_converter01_over_threshold1 => adc_ot1(6), -- out: High indicates the threshold 1 is exceeded. Synchronous to clk_adcX.
    adc3_rts_converter01_over_threshold2 => adc_ot2(6), -- out: High indicates the threshold 2 is exceeded. Synchronous to clk_adcX.
    adc3_rts_converter01_over_voltage => adc_ov(6), -- out: High when the signal far exceeds the normal operating input range. Async.

    adc3_rts_converter2_datapath_overflow => open,
    adc3_rts_converter2_pl_event => '0',
    adc3_rts_converter23_clear_or => adc_clear_or(7),
    adc3_rts_converter23_clear_ov => adc_clear_ov(7),
    adc3_rts_converter23_cm_over_voltage => adc_cm_ov(7),
    adc3_rts_converter23_cm_under_voltage => adc_cm_uv(7),
    adc3_rts_converter23_over_range => adc_or(7),
    adc3_rts_converter23_over_threshold1 => adc_ot1(7),
    adc3_rts_converter23_over_threshold2 => adc_ot2(7),
    adc3_rts_converter23_over_voltage => adc_ov(7),

    adc3_rts_sync_out => open,-- out: one-cycle pulse asserted when sysref event has arrived and indicated divider values are valid. Synchronous to clk_adcX.
    adc3_rts_sysref_gate => '0', -- in: when asserted, sysref is not acted on by the ADC.


--    -- 100GE interface
--    cge_tx_p => qsfp_txp,
--    cge_tx_n => qsfp_txn,
--    cge_refclk_p => clk156_p,
--    cge_refclk_n => clk156_n,

    -- BSB Command stream from the ARM to the FPGA
    m_axis_bsb_tdata => axis_bsb_cmd_tdata,
    m_axis_bsb_tvalid => axis_bsb_cmd_tvalid,
    m_axis_bsb_tlast => axis_bsb_cmd_tlast,
    m_axis_bsb_tready => axis_bsb_cmd_tready,

    -- Command reply stream from the FPGA to the ARM
    s_axis_bsb_tdata => axis_bsb_rply_tdata,
    s_axis_bsb_tvalid => axis_bsb_rply_tvalid,
    s_axis_bsb_tlast => axis_bsb_rply_tlast,
    s_axis_bsb_tready => axis_bsb_rply_tready,
    s_axis_bsb_tkeep => (others => '1'),

    -- Capture data stream from the FPGA to the ARM
    s_axis_cap_tdata => axis_cap_tdata,
    s_axis_cap_tvalid => axis_cap_tvalid,
    s_axis_cap_tlast => axis_cap_tlast,
    s_axis_cap_tready => axis_cap_tready,
    s_axis_cap_tkeep => (others => '1'),

    -- BSB & CAP clock and reset
    aclk => aclk,
    bsb_rst_n(0) => bsb_reset_n,
    cpu_rst_n => cpu_reset_n

    );


    -- Assign clocks to odd-numbered
    adc_clkout(1) <= adc_clkout(0);
    adc_clkout(3) <= adc_clkout(2);
    adc_clkout(5) <= adc_clkout(4);
    adc_clkout(7) <= adc_clkout(6);

    -- Connect debugging signals to SMP connectors
    smp(0) <= clk10_bufg;
    smp(1) <= pll_oscout_bufg;
    smp(2) <= sysclk_bufg;
    smp(3) <= plclk_bufg;



--dbg2: if FALSE generate
    chfpga0: entity work.chfpga
        GENERIC MAP(
            PLATFORM_ID                     => PLATFORM_ID,

            -- Clocking config
            SYSTEM_CLOCK_SOURCE             => SYSTEM_CLOCK_SOURCE,
            SYSTEM_CLOCK_FREQ               => SYSTEM_CLOCK_FREQ,
            CHAN_CLK_SOURCE                 => CHAN_CLK_SOURCE,
            CT_CLK_SOURCE                   => CT_CLK_SOURCE,

            PHY_TYPE                        => PHY_TYPE,
            ADC_TYPE                        => ADC_TYPE,
            NUMBER_OF_ADCS                  => NUMBER_OF_ADCS,


            -- F-Engine / Channelizers

            NUMBER_OF_CHANNELIZERS          => NUMBER_OF_CHANNELIZERS,
            CAPTURE_TYPE                    => CAPTURE_TYPE,

            -- Corner Turn Engine

            NUMBER_OF_CROSSBAR_INPUTS       => NUMBER_OF_CROSSBAR_INPUTS,
            NUMBER_OF_CROSSBAR1_OUTPUTS      => NUMBER_OF_CROSSBAR1_OUTPUTS,
            CROSSBAR1_TYPE                  => CROSSBAR1_TYPE,

            NUMBER_OF_BP_PCB_SHUFFLE_LANES  => NUMBER_OF_BP_PCB_SHUFFLE_LANES,
            NUMBER_OF_BP_QSFP_SHUFFLE_LANES => NUMBER_OF_BP_QSFP_SHUFFLE_LANES,
            NUMBER_OF_BP_SHUFFLE_LINKS      => NUMBER_OF_BP_SHUFFLE_LINKS,
            NUMBER_OF_BP_SHUFFLE_REFCLKS    => NUMBER_OF_BP_SHUFFLE_REFCLKS,

            -- Real time Ethernet data streaming interface

            GPU_LINK_TYPE                   => GPU_LINK_TYPE,
            NUMBER_OF_GPU_LINKS             => NUMBER_OF_GPU_LINKS,
            NUMBER_OF_GPU_REFCLKS           => NUMBER_OF_GPU_REFCLKS,

            -- Correlator config
            CORR_TYPE                       => CORR_TYPE,
            NUMBER_OF_CORRELATORS           => NUMBER_OF_CORRELATORS,


            -- Peripherals

            BLINKER_PRESENT                 => BLINKER_PRESENT,
            NUMBER_OF_I2C_PORTS             => NUMBER_OF_I2C_PORTS,
            NUMBER_OF_SPI_PORTS             => NUMBER_OF_SPI_PORTS,
            NUMBER_OF_ADC_BOARDS            => NUMBER_OF_ADC_BOARDS,
            IMPLEMENT_ARM_SPI               => IMPLEMENT_ARM_SPI, -- is implemented if not specified
            SIM                             => SIM
            )

        PORT MAP(
            -- System reset
            cpu_reset    => not cpu_reset_n,

            -- Reference clock
            clk10 => sysclk_bufg, -- Buffered (BUFG) 10 MHz differential reference clock
            clk10_sel => clk10_sel,

            -- External PLL
            pll_oscout => pll_oscout_bufg,
            pll_sync => pll_sync_bsb, -- sync signal approximately synchronous to pll_oscout. Will be rtimed on the falline edge then rising edge of pll_oscout.

            -- System clock
            sysclk_bufg => sysclk_bufg,

            -- Buck sync
            buck_sync => buck_sync,

            -- Time signal

            bp_time_in => sma_irig,
            bp_trig_in => bp_irig,

            -- ADC inputs
            adc_axis_tdata => adc_axis_tdata(0 to NUMBER_OF_ADCS-1),
            adc_axis_tvalid => adc_axis_tvalid(0 to NUMBER_OF_ADCS-1),
            adc_axis_clk => (0 to NUMBER_OF_ADCS-1 => plclk_bufg),
            adc_sysref => pl_sysref_reg,
            adc_clkout => adc_clkout(0 to NUMBER_OF_ADCS-1),
            adc_cal_frozen => adc_cal_frozen(0 to NUMBER_OF_ADCS-1),
            adc_cal_freeze => adc_cal_freeze(0 to NUMBER_OF_ADCS-1),
            adc_cal_signal_detect => adc_cal_signal_detect(0 to NUMBER_OF_ADCS-1),
            adc_clear_or => adc_clear_or(0 to NUMBER_OF_ADCS-1),
            adc_clear_ov => adc_clear_ov(0 to NUMBER_OF_ADCS-1),
            adc_cm_ov => adc_cm_ov(0 to NUMBER_OF_ADCS-1),
            adc_cm_uv => adc_cm_uv(0 to NUMBER_OF_ADCS-1),
            adc_or => adc_or(0 to NUMBER_OF_ADCS-1),
            adc_ot1 => adc_ot1(0 to NUMBER_OF_ADCS-1),
            adc_ot2 => adc_ot2(0 to NUMBER_OF_ADCS-1),
            adc_ov => adc_ov(0 to NUMBER_OF_ADCS-1),

            -- LEDs

            gpio_led => gpio_led,

            -- 100GE interface
            cge_tx_p => qsfp_txp,
            cge_tx_n => qsfp_txn,
            cge_refclk_p => clk156_p,
            cge_refclk_n => clk156_n,

            -- debug bus
--            debug_out => debug_out,
            sma_out => open, --smp,

            -- Command input stream
            s_axis_bsb_tdata => axis_bsb_cmd_tdata,
            s_axis_bsb_tvalid => axis_bsb_cmd_tvalid,
            s_axis_bsb_tlast => axis_bsb_cmd_tlast,
            s_axis_bsb_tready => axis_bsb_cmd_tready,

            -- Reply output stream
            m_axis_bsb_tdata => axis_bsb_rply_tdata,
            m_axis_bsb_tvalid => axis_bsb_rply_tvalid,
            m_axis_bsb_tlast => axis_bsb_rply_tlast,
            m_axis_bsb_tready => axis_bsb_rply_tready,

            axis_bsb_clk => aclk,
            axis_bsb_rst => not bsb_reset_n,

            -- Data capture stream
            m_axis_cap_tdata => axis_cap_tdata,
            m_axis_cap_tvalid => axis_cap_tvalid,
            m_axis_cap_tlast => axis_cap_tlast,
            m_axis_cap_tready => axis_cap_tready,

            axis_cap_clk => aclk

            );
--end generate;

end architecture impl;


