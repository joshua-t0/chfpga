.. _chfpga_kc705:
.. _chfpga_kc705_corr8_config:

**********************************************************
:entity:`chfpga_kc705` platform wrapper and configurations
**********************************************************

.. default-role:: vhdl:entity

===========
Description
===========

The platform wrapper :file:`chfpga_kc705.vhd` is the top-level entity used to implement `chFPGA` on the KC705. It defines the I/Os that connect the FPGA to the board-specific hardware. All entity port names are **lowercase** (e.g. ``cpu_reset``, ``gpio_led``, ``sysclk_p``, ``phy_rxclk``, ``adc0_ahdp``, ``refclk_m2c_p``, ``mgt_pll_m2c_p``).

The wrapper passes ``MGK7MB`` to the `chfpga` core (shared Kintex-7 BSB clock logic; the core's ``bsb_clk_sel`` supports both ``KC705`` and ``MGK7MB``).

================================
Key hardware-specific parameters
================================

As in the main :ref:`KC705 platform document <kc705_platform>`: SYSCLK 200 MHz, GMII PHY, one ADC board, 8 ADCs, EV8AQ160 with ``ADC_CLOCKING_REGION_MAP`` defining the BUFMR/BUFIO mapping for the KC705 pinout.

Entity definition
=================

.. parse:: hdl/platforms/kc705/chfpga_kc705.vhd

.. autoentity:: chFPGA_KC705

Parameters
==========

- **PLATFORM_TYPE:** Platform type identifier. Fixed to ``KC705`` for this wrapper.
- **SYSTEM_CLOCK_SOURCE:** Source of the system reference clock. ``SYSCLK`` uses the 200 MHz differential crystal oscillator on ``sysclk_p/n``.
- **SYSTEM_CLOCK_FREQ:** System reference clock frequency in MHz (default: 200.0).
- **CHAN_CLK_SOURCE:** Channelizer clock source. ``ADC`` derives the channelizer clock from the word clock of the ADC channel selected by ``CHAN_CLK_SOURCE_LANE``.
- **CHAN_CLK_SOURCE_LANE:** Index of the ADC channel providing the channelizer clock (default: 1, i.e. ADC0B, which instantiates a PLL and BUFG-buffered divclk).
- **CHAN_CLK_FREQ:** Channelizer clock frequency in MHz when using an MMCM source (default: 200.0).
- **CT_CLK_SOURCE:** Corner-turn engine clock source, from the active configuration package via ``CONFIG_CT_CLK_SOURCE``.
- **BSB_INTERFACE:** BSB interface type. ``UDP_GMII`` uses the on-board Marvell GMII 1G Ethernet PHY.
- **CAP_INTERFACE:** Capture interface type. ``BSB`` returns captured and correlator data over the BSB interface.
- **ADC_TYPE:** ADC chip type. ``EV8AQ160`` selects the EV8AQ160 8-bit quad-channel ADC on the MGADC08 FMC mezzanine.
- **NUMBER_OF_ADC_BOARDS:** Number of FMC ADC mezzanine boards (default: 1).
- **NUMBER_OF_ADCS:** Number of ADC channels (default: 8).
- **ADC_INSTANTIATE_PLL:** Boolean array indicating which ADC channels require a PLL for multi-bank ISERDES clocking. Only ADC1B (index 1) uses a PLL.
- **ADC_USE_EXT_DATA_CLK:** Boolean array indicating which ADC channels use the PLL-generated external clock. ADCs 0–3 use it due to non-adjacent IO bank routing.
- **ADC_CLOCKING_REGION_MAP:** Per-channel BUFMR/BUFR/BUFIO assignment for the Kintex-7 IO bank layout. Each entry maps bit/clock indices to a BUFMR region; a value of -1 disables BUFMR for that signal.
- **ADC_IS_DIFFERENTIAL:** All ADC data and clock inputs are LVDS differential.
- **ADC_PROVIDE_BUFFERED_DIVCLK:** ADC 1 (ADC0B) provides the BUFG-buffered word clock used by all channelizers.
- **NUMBER_OF_CHANNELIZERS:** Total number of channelizer blocks (default: ``NUMBER_OF_ADCS``).
- **NUMBER_OF_CHANNELIZERS_WITH_FFT:** Number of channelizers with an FFT block, from the configuration package.
- **FFT_TYPE:** Channelizer FFT type, from the configuration package.
- **CAPTURE_TYPE:** Channelizer data capture type, from the configuration package.
- **CT_TYPE:** Corner-turn type (``BCT`` or ``UCT``), from the configuration package.
- **CT_LEVEL:** Corner-turn level: 1 = single-board, 2 = crate-level, 3 = multi-crate.
- **CT_LANE_TO_LINK_MAP:** Integer array mapping corner-turn lanes to GTX link indices (null by default — no backplane links on KC705).
- **CT_LINK_TO_QUAD_MAP:** Integer array mapping each GTX link to a QPLL/QUAD.
- **CT_QUAD_TO_REFCLK_MAP:** Integer array mapping each QUAD to a reference clock index.
- **CT_LANE_TO_GROUP_MAP:** Integer array assigning each lane to a lane group.
- **CORR_TYPE:** Correlator type (``UCORR44``, ``CORR44``, or ``NONE``), from the configuration package.
- **CORR_READOUT_BINS:** Frequency bins to read out from the correlator, from the configuration package.
- **DATA_LINK_TYPE:** Real-time data offload type, from the configuration package. ``NONE`` by default.
- **DATA_LINK_LINK_TO_QUAD_MAP:** Maps data-link channels to GTX QUADs. Ignored when ``DATA_LINK_TYPE = NONE``.
- **DATA_LINK_QUAD_TO_REFCLK_MAP:** Maps data-link QUADs to reference clocks.
- **NUMBER_OF_I2C_PORTS:** Number of I2C ports (default: 1, for the KC705 PMBus/IIC hub).
- **NUMBER_OF_SPI_PORTS:** Number of SPI ports (default: ``NUMBER_OF_ADC_BOARDS`` = 1, for the FMC mezzanine).
- **BLINKER_PRESENT:** Whether the LED blinker/status module is implemented.
- **IMPLEMENT_LCD:** Whether the LCD display driver is implemented (default: TRUE — KC705 has a character LCD).
- **IMPLEMENT_ARM_SPI:** Whether an ARM SPI interface is implemented (default: FALSE — KC705 is a pure FPGA board with no Zynq ARM).
- **SIM:** Simulation mode. When ``TRUE``, accelerates simulations (uses ``GLOBAL_SIM`` package constant).

Interface
=========

System
------

- ``cpu_reset``: (in) Active-high hardware reset button on the KC705.
- ``gpio_button0``: (in) User pushbutton on the KC705.
- ``gpio_led[7:0]``: (out) Row of 8 LEDs on the KC705.
- ``gpio_dip_sw[3:0]``: (in) 4 DIP switches used to set the board's IP address.

LCD display
-----------

- ``lcd_db[7:4]``: (out) LCD data bus (upper nibble only, 4-bit mode).
- ``lcd_e``: (out) LCD enable strobe.
- ``lcd_rs``: (out) LCD register select (0 = command, 1 = data).
- ``lcd_rw``: (out) LCD read/write select.

Fan
---

- ``fan_pwm``: (out) Fan speed control PWM signal.
- ``fan_tach``: (in) Fan tachometer readout (2 pulses per revolution).

Clocks
------

- ``sysclk_p/n``: (in) LVDS 200 MHz system clock from an on-board crystal oscillator.
- ``user_sma_clock_p``: (in) User-provided 10 MHz reference clock from the SMA connector (same clock as the ADC board). Buffered through a BUFG and passed to ``chfpga`` as ``clk10``.
- ``user_sma_clock_n``: (out) Delayed 10 MHz reference clock output for ADC board timing alignment monitoring.
- ``user_sma_gpio_p/n``: (inout) Not used.

GMII PHY (1G Ethernet)
-----------------------

- ``phy_rxclk``: (in) Receive byte clock recovered by the Marvell PHY chip.
- ``phy_txer``: (out) Transmit error flag to the PHY.
- ``phy_reset_l``: (out) Active-low PHY hardware reset.
- ``phy_rxctrl_rxdv``: (in) Receive data valid flag from the PHY.
- ``phy_rxd[7:0]``: (in) 8-bit receive data bus from the PHY.
- ``phy_txc_gtxclk``: (out) 125 MHz clock provided to the PHY to clock the TX bus (GTXCLK mode).
- ``phy_txctl_txen``: (out) Transmit enable flag to the PHY.
- ``phy_txd[7:0]``: (out) 8-bit transmit data bus to the PHY.
- ``phy_txclk``: (in) TX clock supplied by the PHY (not used internally).
- ``sfp_los``: (out) SFP loss-of-signal flag (tied to ``'0'``, not used).
- ``sfpclk_qo_p/n``: (in) SFP reference clock from the on-board oscillator (used only if ``BSB_INTERFACE = UDP_SGMII``).

I2C / PMBus
-----------

- ``pmbus_sck/sda``: (inout) PMBus (I2C) clock and data for board power management.
- ``i2c_sck/sda``: (inout) General I2C bus.

FMC ADC (EV8AQ160, 2 chips on MGADC08)
----------------------------------------

- ``adc0_ahd{p,n}[7:0]`` / ``adc0_adr{p,n}`` … ``adc1_dhd{p,n}[7:0]`` / ``adc1_ddr{p,n}``: (in) 8-bit DDR parallel data buses and clocks for the two EV8AQ160 ADC chips. ``adc0``/``adc1`` identify the chip; A/B/C/D are the four output ports; ``ahd`` is the high-bit data bus; ``adr`` is the Data Ready clock. Each port delivers 8 bits DDR (16 samples per clock cycle).
- ``adc_sync_p/n``: (out) Differential SYNC signal to both ADC chips (or their resynchronization circuit).
- ``adc_rst_n``: (out) Active-low reset common to both ADC chips.

SPI (to FMC mezzanine)
-----------------------

- ``spi_sck``: (out) SPI clock to the FMC (~1 MHz).
- ``spi_miso``: (in) SPI MISO from the FMC.
- ``spi_mosi``: (out) SPI MOSI to the FMC.
- ``spi_addr[2:0]``: (out) SPI device address (selects up to 8 on-board devices).
- ``pll_le``: (out) ADC PLL Latch Enable (Rev0) or active-low SPI_CS (Rev2).
- ``spi_rst_n``: (out) Active-low SPI device reset (Rev0 boards).
- ``spi_rst_n_alt``: (out) Active-low SPI device reset (Rev2 boards).

Buck synchronization
---------------------

- ``buck3v3_sync``: (out) 3.3 V buck regulator synchronization clock.
- ``buck1v8_sync``: (out) 1.8 V buck regulator synchronization clock.

FMC reference clocks
---------------------

- ``refclk_m2c_p/n``: (in) LVDS 10 MHz reference clock forwarded from the FMC mezzanine SMA connector to the FPGA.
- ``mgt_pll_m2c_p/n[0:NUMBER_OF_ADC_BOARDS*2-1]``: (in) MGT PLL reference clocks from the FMC mezzanine.

Implementation details
======================

Architecture
------------

The entity instantiates `chfpga` with KC705-specific generics. The 10 MHz user reference clock from ``user_sma_clock_p`` is buffered through a ``BUFG`` primitive in the wrapper and passed to ``chfpga`` as ``clk10``. All other ADC and PHY signals are routed directly to ``chfpga`` with minor vector packing/unpacking (e.g., ADC data buses are assembled into arrays, buck sync outputs are demultiplexed).

Principle of operations
-----------------------

The KC705 uses a 200 MHz crystal oscillator as the system clock. The user connects a 10 MHz reference clock to the SMA connector; this clock is routed to the ADC mezzanine and also enters the FPGA through ``user_sma_clock_p``. ADC word clock from ADC1B is BUFG-buffered inside ``chfpga`` and distributes the channelizer clock across the FPGA.

The BSB interface uses the Marvell Alaska GMII 1G Ethernet PHY on the KC705 for command/reply communication. The board's IP address is configured by the four DIP switches. Capture and correlator data are returned over the same BSB link.

The KC705 does not have any backplane GTX shuffle links; accordingly ``CT_LEVEL = 1`` (single-board) is the only meaningful corner-turn configuration for this platform.


``corr8`` configuration (*chfpga_kc705_corr8_config.vhd*)
*********************************************************

Description
===========

The file :file:`chfpga_kc705_corr8_config.vhd` defines the package ``chfpga_config`` used to configure `chFPGA` for the 8-channel correlator configuration on the KC705. This configuration includes data acquisition from one FMC ADC mezzanine (8 channels), 8 channelizers with FFT (HIRAX 3-DSP style), an 8-input :math:`N^2` correlator (UCORR44), and no real-time data offload.

Configuration parameters
========================

This config uses the following parameters (see :ref:`config_param_reference` for full descriptions):

- :ref:`CONFIG_CHAN_IMPLEMENT_FFT <config_chan_implement_fft>` — TRUE; F-Engine with FFT
- :ref:`CONFIG_CHAN_FFT_TYPE <config_chan_fft_type>` — HIRAX_3DSP; 8-bit, 2048 samples, 25+25 output
- :ref:`CONFIG_NUMBER_OF_CHANNELIZERS_WITH_FFT <config_number_of_channelizers_with_fft>` — 8
- :ref:`CONFIG_CHAN_SCALER_USE_COMPLEX_GAINS <config_chan_scaler_use_complex_gains>` — FALSE
- :ref:`CONFIG_CHAN_CAPTURE_TYPE <config_chan_capture_type>` — PROBER; per-channelizer BRAM capture
- :ref:`CONFIG_CT_TYPE <config_ct_type>` — BCT; simple internal corner-turn
- :ref:`CONFIG_CT_LEVEL <config_ct_level>` — 1; single-board, no backplane
- :ref:`CONFIG_CT_CLK_SOURCE <config_ct_clk_source>` — ADC_CLK; sufficient at CT_LEVEL=1
- :ref:`CONFIG_CORR_TYPE <config_corr_type>` — UCORR44; 8-input correlator
- :ref:`CONFIG_CORR_READOUT_BINS <config_corr_readout_bins>` — (0, 0)
- :ref:`CONFIG_DATA_LINK_TYPE <config_data_link_type>` — NONE; no real-time offload

Package definition
==================

.. parse:: hdl/platforms/kc705/chfpga_kc705_corr8_config.vhd
