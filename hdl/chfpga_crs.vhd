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

entity chfpga_crs is
    generic (

        PLATFORM_ID: integer                         := CONFIG_PLATFORM_ID; --  Identifies the type of platform on which the firmware is running. 

        -- Clocking config
        SYSTEM_CLOCK_SOURCE: string                  := "SYSCLK_BUFG"; -- System reference clock surce: "SYSCLK": 200 MHz unbuffered differential clock from sysclk_p/n, "SYSCLK_BUFG": 200 MHz BUFG-Buffered clock from sysclk_bufg, "SFP_REFCLK": 125 MHz clock from the GTX reference clock
        SYSTEM_CLOCK_FREQ: real                   := 250.0; -- System reference clock frequency, in MHz. Used to select the system PLL divider/multiplier factors.
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
        NUMBER_OF_ADC_BOARDS: integer                := 0; -- No REFCLK module

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

        CORR_TYPE: string                            := CONFIG_CORR_TYPE; -- "CORR44" or "UCORR44"
        NUMBER_OF_CORRELATORS: integer               := CONFIG_NUMBER_OF_CORRELATORS; -- Number of correlators. Normally NUMBER_OF_CROSSBAR_OUTPUTS. Correlator not implemented if zero.

        -- Real-time data offload links configuration
        GPU_LINK_TYPE: string                        := CONFIG_GPU_LINK_TYPE; -- If TRUE, a 100G UDP/IP/Ethernet data transmitter is implemented
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
        -- 10 MHz reference clock from programmable PLL
        clk10_clk_n : in std_logic_vector(0 to 0);
        clk10_clk_p : in std_logic_vector(0 to 0);

        -- 375 MHz processing clock form programmable PLL
        pl_clk_n : in std_logic_vector(0 to 0);
        pl_clk_p : in std_logic_vector(0 to 0);

        -- 100G Ethernet 

        --   156.25 MHz reference clock
        clk156_n : in std_logic;
        clk156_p : in std_logic;
        --   QSFP data lanes
        qsfp_txn : out std_logic_vector(0 to 3);
        qsfp_txp : out std_logic_vector(0 to 3);

        -- 250 MHz system clock from programmable PLL. Used as source to generate internal clocks using MMCM. 
        clk200_clk_n : in std_logic_vector(0 to 0);
        clk200_clk_p : in std_logic_vector(0 to 0);

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
        led7b : out std_logic_vector ( 7 downto 0 );

        -- User connectors
        smp : out std_logic_vector ( 0 to 3 );

        -- IRIG-B signal
        sma_irig_p: in std_logic;
        sma_irig_n: in std_logic;

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
--    attribute DONT_TOUCH: string;
--    attribute DONT_TOUCH of chfpga_crs: entity is "true";

--PROCEDURE disable_io(port_in: in std_logic) is
--        attribute io_buffer_type of port_in: signal is "none"; 
--	begin
--end procedure;

end entity;


architecture impl of chfpga_crs is
    attribute io_buffer_type : string;


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

    -- System Reference clock (10 MHz) 
    signal sysref_nobuf: std_logic; 
    signal sysref_bufg: std_logic; 

    -- System clock (250 MHz) 
    signal clk200_nobuf: std_logic; 
    signal clk200_bufg: std_logic; 

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

--    signal cpu_reset: std_logic;
    signal cpu_reset_n: std_logic;

--    signal bsb_reset: std_logic;
    signal bsb_reset_n: std_logic;
    signal buck_sync: std_logic_vector(0 to 15);
    signal gpio_led: std_logic_vector(7 downto 0);
    signal buck_sync_0v85_div2: std_logic;
    signal sma_irig: std_logic;

--    attribute DONT_TOUCH of chfpga0: label is "true";

    signal qsfp_txp_int, qsfp_txn_int: std_logic_vector(0 to 3);


begin

--test: if True generate
--        attribute io_buffer_type : string;
--begin
--        attribute io_buffer_type of qsfp_txp, qsfp_txn: signal is "none"; 
--end;

---- Connect the QSFP IO ports only if the 100GE module is used.
---- Otherwise the defaut po
--qsfp_gen: if GPU_LINK_TYPE = "100GE" generate
--        qsfp_txp <= qsfp_txp_int;
--        qsfp_txn <= qsfp_txn_int;
--end generate;

--    qsfp_txp <= qsfp_txp_dummy;
--    qsfp_txn <= qsfp_txn_dummy;
		sysref_ibufds0 : IBUFGDS -- Instantiate a differential (LVDS) input pad pair
			generic map(DIFF_TERM => TRUE)
			port map (
				I => clk10_clk_p(0),
				IB => clk10_clk_n(0),
				O => sysref_nobuf
			);
		sysref_bufg0 : BUFG
            port map (
                I => sysref_nobuf, -- Clock buffer input
                O => sysref_bufg-- Clock buffer output
            );

        clk200_ibufds0 : IBUFGDS -- Instantiate a differential (LVDS) input pad pair
            generic map(DIFF_TERM => TRUE)
            port map (
                I => clk200_clk_p(0),
                IB => clk200_clk_n(0),
                O => clk200_nobuf
            );
        clk200_bufg0 : BUFG
            port map (
                I => clk200_nobuf, -- Clock buffer input
                O => clk200_bufg-- Clock buffer output
            );

		plclk_ibufds0 : IBUFGDS -- Instantiate a differential (LVDS) input pad pair
			generic map(DIFF_TERM => TRUE)
			port map (
				I => pl_clk_p(0),
				IB => pl_clk_n(0),
				O => plclk_nobuf
			);
		plclk_bufg0 : BUFG
            port map (
                I => plclk_nobuf, -- Clock buffer input
                O => plclk_bufg-- Clock buffer output
            );

    -- Buck sync

    bucksyncdiv_proc: process (buck_sync(1))
    begin
        if rising_edge(buck_sync(1)) then
            buck_sync_0v85_div2 <= not buck_sync_0v85_div2;
        end if;
    end process;

    buck_sync_5v0 <= buck_sync(0);
--    buck_sync_0v85 <= buck_sync_0v85_div2; -- two switchers operating in paralle 180deg out of phase. Combined freq is double. 
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


    -- 7-segment display
    led7b(5 downto 0) <= gpio_led(6 downto 1); -- a-f segments (forming a circle)
    led7b(6) <= '0'; -- central g segment
    led7b(7) <= '0'; -- decimal point



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

    -- ADC clock monitoring (Fs/8 or Fs/16)
    clk_adc0_0 => adc_clkout(0),
    clk_adc1_0 => adc_clkout(2),
    clk_adc2_0 => adc_clkout(4),
    clk_adc3_0 => adc_clkout(6),

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

    smp(0) <= axis_cap_tvalid;
    smp(1) <= axis_cap_tlast;
    smp(2) <= axis_cap_tready;
    smp(3) <= aclk;
    
    
    adc_clkout(1) <= adc_clkout(0);
    adc_clkout(3) <= adc_clkout(2);
    adc_clkout(5) <= adc_clkout(4);
    adc_clkout(7) <= adc_clkout(6);


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
            CAPTURE_TYPE                    => CAPTURE_TYPE,
            NUMBER_OF_CHANNELIZERS          => NUMBER_OF_CHANNELIZERS,
            NUMBER_OF_CROSSBAR_INPUTS       => NUMBER_OF_CROSSBAR_INPUTS,
            NUMBER_OF_CROSSBAR1_OUTPUTS      => NUMBER_OF_CROSSBAR1_OUTPUTS,
            CROSSBAR1_TYPE                  => CROSSBAR1_TYPE,
            NUMBER_OF_BP_PCB_SHUFFLE_LANES  => NUMBER_OF_BP_PCB_SHUFFLE_LANES,
            NUMBER_OF_BP_QSFP_SHUFFLE_LANES => NUMBER_OF_BP_QSFP_SHUFFLE_LANES,
            NUMBER_OF_BP_SHUFFLE_LINKS      => NUMBER_OF_BP_SHUFFLE_LINKS,
            NUMBER_OF_BP_SHUFFLE_REFCLKS    => NUMBER_OF_BP_SHUFFLE_REFCLKS,
            --BP_SHUFFLE_LANE_MAP             => BP_SHUFFLE_LANE_MAP,
            --BP_SHUFFLE_LANE_TO_QUAD_MAP     => BP_SHUFFLE_LANE_TO_QUAD_MAP,
            --BP_SHUFFLE_QUAD_TO_REFCLK_MAP   => BP_SHUFFLE_QUAD_TO_REFCLK_MAP,

            -- Correlator config
            CORR_TYPE                       => CORR_TYPE,
            NUMBER_OF_CORRELATORS           => NUMBER_OF_CORRELATORS,

            -- 10/100G Ethernet data streaming
            NUMBER_OF_GPU_LINKS             => NUMBER_OF_GPU_LINKS,
            NUMBER_OF_GPU_REFCLKS           => NUMBER_OF_GPU_REFCLKS,
            GPU_LINK_TYPE                   => GPU_LINK_TYPE,


            -- Peripherals
            BLINKER_PRESENT                 => BLINKER_PRESENT,
            NUMBER_OF_I2C_PORTS             => NUMBER_OF_I2C_PORTS,
            NUMBER_OF_SPI_PORTS             => NUMBER_OF_SPI_PORTS,
            NUMBER_OF_ADC_BOARDS            => NUMBER_OF_ADC_BOARDS,
            -- IMPLEMENT_ANT                =>IMPLEMENT_ANT, -- Selects for which antenna a processing pipeline is implemented
            -- IMPLEMENT_FFT                =>IMPLEMENT_FFT, -- Selects if the FFT block is implemented for each antenna (otherwise the timestream go through directly)
            -- IMPLEMENT_CORR               =>IMPLEMENT_CORR,
            IMPLEMENT_ARM_SPI => IMPLEMENT_ARM_SPI, -- is implemented if not specified
            --ADC_IS_DIFFERENTIAL             => ADC_IS_DIFFERENTIAL,
            --ADC_PROVIDE_BUFFERED_DIVCLK     => ADC_PROVIDE_BUFFERED_DIVCLK,
            --ADC_INSTANTIATE_PLL             => ADC_INSTANTIATE_PLL,
            --ADC_USE_EXT_DATA_CLK            => ADC_USE_EXT_DATA_CLK,
            --ADC_INSTANTIATE_BUFMR           => ADC_INSTANTIATE_BUFMR,
            --ANT_CLK_SOURCE                  => ANT_CLK_SOURCE,
            --GPU_CHANNEL_QUAD                => GPU_CHANNEL_QUAD,
            --GPU_QUAD_REFCLK                 => GPU_QUAD_REFCLK,
            SIM                             => SIM
            )
        PORT MAP(
            -- System reset
            cpu_reset    => not cpu_reset_n,

            -- Reference clock
            clk10 => sysref_bufg, -- Buffered (BUFG) 10 MHz differential reference clock

            -- System clock
            sysclk_bufg => clk200_bufg,

            -- Buck sync
            buck_sync => buck_sync,

            -- Time signal

            bp_time_in => sma_irig,

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
end architecture impl;


