--Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
--Date        : Tue Mar 28 11:38:21 2023
--Host        : twiddlebug running 64-bit Ubuntu 22.04.1 LTS
--Command     : generate_target chfpga_zcu111.bd
--Design      : chfpga_zcu111
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
-- Top level module to instantiate chFPGA on a ZCU111
-- Instantiates and connects:
--   - Block diagram containing the Zynq, ADC, and DMA interfaces
--   - chFPGA instance parametrized for the platform (ZCU111) and the target functions (chfpga or sispga)
--
-- Manually created by JFC from an automatically generated block diagram wrapper.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

use work.chfpga_package.ALL; -- Get all component definitions
use work.chfpga_config.ALL;  -- Get platform-specific configuration definitions

entity chfpga_zcu111 is
	generic (

		-- NOTE: All generics values must be literals if the module is to be imported in a block diagram
		PLATFORM_ID: integer := PLATFORM_ID_ZCU111; -- Identifies the type of platform on which the firmware is running.

		-- Clocking config
		SYSTEM_CLOCK_SOURCE: clk_source_enum     := CLK10_BUFG; -- 10 MHz BUFG-buffered reference (from FPGA_REFCLK_OUT_C)
		SYSTEM_CLOCK_FREQ: real                  := 10.0;      -- System reference clock frequency, in MHz
		CHAN_CLK_SOURCE: chan_clk_source_enum    := ADC;       -- Channelizer clock comes directly from the ADC
		CT_CLK_SOURCE: ct_clk_source_enum        := CONFIG_CT_CLK_SOURCE; -- corner-turn clock source

		-- Buck synchronization (not used on ZCU111)
		BUCK_SYNC_ENABLE: boolean                := FALSE;
		BUCK_CLK_DIVIDE_FACTOR: integer           := 12;


		BSB_TYPE: bsb_type_enum                   := AXIS;     -- Ethernet provided by the PS
		SGMII_CLOCK_SOURCE: phy_clk_source_enum   := REFCLK;

		-- ADC config
		ADC_TYPE: adc_type_enum                   := AXIS;     -- ADC data is provided through the axis_adc port
		NUMBER_OF_ADCS: integer                   := CONFIG_NUMBER_OF_ADCS;
		NUMBER_OF_ADC_BOARDS: integer             := 0;

		-- Channelizer config
		FFT_TYPE: fft_type_enum                   := CONFIG_CHAN_FFT_TYPE;
		NUMBER_OF_CHANNELIZERS: integer           := CONFIG_NUMBER_OF_ADCS;
		CAPTURE_TYPE: chan_capture_type_enum     := CONFIG_CHAN_CAPTURE_TYPE;

		-- Corner-turn engine config (single board, no backplane)
		CT_TYPE: ct_type_enum                     := CONFIG_CT_TYPE;
		CT_LEVEL: integer                         := CONFIG_CT_LEVEL;
		CT_LANE_TO_LINK_MAP: integer_array        := CONFIG_CT_LANE_TO_LINK_MAP;
		CT_LINK_TO_QUAD_MAP: integer_array       := (1 to 0 => 0); -- no GTY links
		CT_QUAD_TO_REFCLK_MAP: integer_array     := (1 to 0 => 0);
		CT_LANE_TO_GROUP_MAP: integer_array      := (0 => 0);

		-- Correlator config
		CORR_TYPE: corr_type_enum                 := CONFIG_CORR_TYPE;
		CORR_READOUT_BINS: integer_array          := CONFIG_CORR_READOUT_BINS;

		-- Real-time data offload links configuration (100G QSFP)
		GPU_LINK_TYPE: gpu_link_type_enum          := CONFIG_GPU_LINK_TYPE;
		GPU_CHANNEL_QUAD: integer_array           := CONFIG_GPU_CHANNEL_QUAD;
		GPU_QUAD_REFCLK: integer_array            := CONFIG_GPU_QUAD_REFCLK;

		-- Peripheral config
		BLINKER_PRESENT: boolean                  := TRUE;
		NUMBER_OF_I2C_PORTS: integer              := 0;
		NUMBER_OF_SPI_PORTS: integer              := 0;
		IMPLEMENT_ARM_SPI: boolean                := FALSE;
		IMPLEMENT_LCD: boolean                     := FALSE;    -- no OLED on ZCU111

		SIM: boolean                               := FALSE;

		-- Derived parameters
		NUMBER_OF_CT_LINKS: integer                := CT_LINK_TO_QUAD_MAP'LENGTH;
		NUMBER_OF_CT_REFCLKS: integer              := sel(CT_QUAD_TO_REFCLK_MAP'LENGTH > 0, max(CT_QUAD_TO_REFCLK_MAP) + 1, 0);
		NUMBER_OF_GPU_LINKS: integer              := sel(GPU_LINK_TYPE /= NONE, GPU_CHANNEL_QUAD'LENGTH, 0);
		NUMBER_OF_GPU_REFCLKS: integer             := sel(GPU_LINK_TYPE /= NONE, max(GPU_QUAD_REFCLK) + 1, 0)
	);

  port (

    -- Clocks

    FPGA_REFCLK_OUT_C_clk_n : in STD_LOGIC_VECTOR ( 0 to 0 ); -- 10 MHz reference clock
    FPGA_REFCLK_OUT_C_clk_p : in STD_LOGIC_VECTOR ( 0 to 0 );
    SYSREF_FPGA_clk_n : in STD_LOGIC_VECTOR ( 0 to 0 ); -- 375/400 MHz processing clock (ADC sampling/8)
    SYSREF_FPGA_clk_p : in STD_LOGIC_VECTOR ( 0 to 0 );

    -- LEDs

    gpio_led : out STD_LOGIC_VECTOR ( 7 downto 0 );

    -- 100G interface

    clk156_n : in STD_LOGIC; -- 156.25 MHz reference clock for 100G Ethernet
    clk156_p : in STD_LOGIC;

    qsfp_txn : out STD_LOGIC_VECTOR ( 0 to 3 );
    qsfp_txp : out STD_LOGIC_VECTOR ( 0 to 3 );


    -- ADC sampling clocks

    adc0_clk_clk_n : in STD_LOGIC;
    adc0_clk_clk_p : in STD_LOGIC;
    adc1_clk_clk_n : in STD_LOGIC;
    adc1_clk_clk_p : in STD_LOGIC;
    adc2_clk_clk_n : in STD_LOGIC;
    adc2_clk_clk_p : in STD_LOGIC;
    adc3_clk_clk_n : in STD_LOGIC;
    adc3_clk_clk_p : in STD_LOGIC;

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
end chfpga_zcu111;

architecture impl of chfpga_zcu111 is

    attribute DONT_TOUCH: string;

    -- BSB & CAP AXIS clock (100 MHz)
    signal aclk: std_logic;

    -- ADC word clock (Fs/8 = 3000/8 = 375 MHz)
    signal plclk_nobuf: std_logic;
    signal plclk_bufg: std_logic;

    -- System Reference clock (10 MHz)
    signal sysref_nobuf: std_logic;
    signal sysref_bufg: std_logic;

    -- Vectors representing the ADC inputs.
    -- Length is hard coded to the fixed number of inputs provided in the top level port.
    -- We will pass only the first NUMBER_OF_ADCS to chFPGA.
    signal adc_axis_tdata: slv128_array(0 to 7);
    signal adc_axis_tvalid: std_logic_vector(0 to 7);
    signal adc_axis_clk: std_logic_vector(0 to 7);
    signal adc_clkout: std_logic_vector(0 to 7);


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

    signal cpu_reset_n: std_logic;

    signal bsb_reset_n: std_logic;

    attribute DONT_TOUCH of chfpga0: label is "true";

begin

	sysref_ibufds0 : IBUFGDS -- Instantiate a differential (LVDS) input pad pair
		generic map(DIFF_TERM => TRUE)
		port map (
			I => SYSREF_FPGA_clk_p(0),
			IB => SYSREF_FPGA_clk_n(0),
			O => sysref_nobuf
		);
	sysref_bufg0 : BUFG
        port map (
            I => sysref_nobuf, -- Clock buffer input
            O => sysref_bufg-- Clock buffer output
        );

	plclk_ibufds0 : IBUFGDS -- Instantiate a differential (LVDS) input pad pair
		generic map(DIFF_TERM => TRUE)
		port map (
			I => FPGA_REFCLK_OUT_C_clk_p(0),
			IB => FPGA_REFCLK_OUT_C_clk_n(0),
			O => plclk_nobuf
		);
	plclk_bufg0 : BUFG
        port map (
            I => plclk_nobuf, -- Clock buffer input
            O => plclk_bufg-- Clock buffer output
        );




    zynq: entity work.zynq_tcpipe_zcu111
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

    --      clk156_n => clk156_n,
    --      clk156_p => clk156_p,
    --      gpio_led(7 downto 0) => gpio_led(7 downto 0),
    --      qsfp_txn(0 to 3) => qsfp_txn(0 to 3),
    --      qsfp_txp(0 to 3) => qsfp_txp(0 to 3),

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
        m00_axis_tdata_0 => adc_axis_tdata(0),
        m00_axis_tvalid_0 => adc_axis_tvalid(0),
        m02_axis_tdata_0 => adc_axis_tdata(1),
        m02_axis_tvalid_0 => adc_axis_tvalid(1),
        m10_axis_tdata_0 => adc_axis_tdata(2),
        m10_axis_tvalid_0 => adc_axis_tvalid(2),
        m12_axis_tdata_0 => adc_axis_tdata(3),
        m12_axis_tvalid_0 => adc_axis_tvalid(3),
        m20_axis_tdata_0 => adc_axis_tdata(4),
        m20_axis_tvalid_0 => adc_axis_tvalid(4),
        m22_axis_tdata_0 => adc_axis_tdata(5),
        m22_axis_tvalid_0 => adc_axis_tvalid(5),
        m30_axis_tdata_0 => adc_axis_tdata(6),
        m30_axis_tvalid_0 => adc_axis_tvalid(6),
        m32_axis_tdata_0 => adc_axis_tdata(7),
        m32_axis_tvalid_0 => adc_axis_tvalid(7),

        -- Buffered ADC data word clock. Must be fs/8.
        pl_clk => plclk_bufg,

        -- ADC clock monitoring (Fs/8 or Fs/16)
        clk_adc0_0 => adc_clkout(0),
        clk_adc1_0 => adc_clkout(2),
        clk_adc2_0 => adc_clkout(4),
        clk_adc3_0 => adc_clkout(6),

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
        bsb_reset_n(0) => bsb_reset_n,
        cpu_reset_n => cpu_reset_n

        );


    -- Assign clocks to odd-numbered ADCs
    adc_clkout(1) <= adc_clkout(0);
    adc_clkout(3) <= adc_clkout(2);
    adc_clkout(5) <= adc_clkout(4);
    adc_clkout(7) <= adc_clkout(6);


--------*/
	chfpga0: entity work.chfpga
		generic map (
			PLATFORM_ID => PLATFORM_ID,

			-- Clocking config
			SYSTEM_CLOCK_SOURCE => SYSTEM_CLOCK_SOURCE,
			SYSTEM_CLOCK_FREQ   => SYSTEM_CLOCK_FREQ,
			CHAN_CLK_SOURCE     => CHAN_CLK_SOURCE,
			CT_CLK_SOURCE       => CT_CLK_SOURCE,

			BSB_TYPE       => BSB_TYPE,
			ADC_TYPE       => ADC_TYPE,
			NUMBER_OF_ADCS => NUMBER_OF_ADCS,

			-- F-Engine / Channelizers
			FFT_TYPE               => FFT_TYPE,
			NUMBER_OF_CHANNELIZERS => NUMBER_OF_CHANNELIZERS,
			CAPTURE_TYPE           => CAPTURE_TYPE,

			-- Corner-turn engine
			CT_TYPE                 => CT_TYPE,
			CT_LEVEL                => CT_LEVEL,
			CT_LANE_TO_LINK_MAP     => CT_LANE_TO_LINK_MAP,
			CT_LINK_TO_QUAD_MAP     => CT_LINK_TO_QUAD_MAP,
			CT_QUAD_TO_REFCLK_MAP   => CT_QUAD_TO_REFCLK_MAP,
			CT_LANE_TO_GROUP_MAP    => CT_LANE_TO_GROUP_MAP,

			-- Correlator
			CORR_TYPE         => CORR_TYPE,
			CORR_READOUT_BINS => CORR_READOUT_BINS,

			-- Real-time Ethernet data streaming interface
			GPU_LINK_TYPE         => GPU_LINK_TYPE,
			GPU_CHANNEL_QUAD      => integerarray(GPU_CHANNEL_QUAD),
			GPU_QUAD_REFCLK       => integerarray(GPU_QUAD_REFCLK),

			-- Peripherals
			BLINKER_PRESENT     => BLINKER_PRESENT,
			NUMBER_OF_I2C_PORTS => NUMBER_OF_I2C_PORTS,
			NUMBER_OF_SPI_PORTS => NUMBER_OF_SPI_PORTS,
			NUMBER_OF_ADC_BOARDS => NUMBER_OF_ADC_BOARDS,
			IMPLEMENT_ARM_SPI   => IMPLEMENT_ARM_SPI,
			IMPLEMENT_LCD       => IMPLEMENT_LCD,
			SIM                 => SIM
		)
		port map (
			-- System reset
			cpu_reset => not cpu_reset_n,

			-- System clock
			clk10 => sysref_bufg, -- Buffered (BUFG) 10 MHz differential reference clock

            -- ADC inputs
            adc_axis_tdata => adc_axis_tdata(0 to NUMBER_OF_ADCS-1),
            adc_axis_tvalid => adc_axis_tvalid(0 to NUMBER_OF_ADCS-1),
            adc_axis_clk => (0 to NUMBER_OF_ADCS-1 => plclk_bufg),
            adc_clkout => adc_clkout(0 to NUMBER_OF_ADCS-1),

            -- LEDs

            gpio_led => gpio_led,

            -- 100GE interface
            cge_tx_p => qsfp_txp,
            cge_tx_n => qsfp_txn,
            cge_refclk_p => clk156_p,
            cge_refclk_n => clk156_n,

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
			axis_bsb_rst => not bsb_reset_n,

			-- Data capture stream
			m_axis_cap_tdata  => axis_cap_tdata,
			m_axis_cap_tvalid => axis_cap_tvalid,
			m_axis_cap_tlast  => axis_cap_tlast,
			m_axis_cap_tready => axis_cap_tready,

			axis_cap_clk => aclk
		);
end architecture impl;
