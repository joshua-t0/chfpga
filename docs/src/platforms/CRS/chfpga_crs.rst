.. _chfpga_crs:

:entity:`chfpga_crs` platform wrapper (*hdl/platforms/crs/chfpga_crs.vhd*)
**************************************************************************


Description
===========

This platform wrapper is the top-level entity that is used to implement `chFPGA` on the CRS platform. It is used with multiple firmware configurations.

The entity defines the I/Os that connect the FPGA with the board-specific hardware. it also instantiates the TCPIPE block diagram, which "instantiate" the ZYNQ processor, the ADCs, and adds DMA engines to communicate with `chFPGA`'s BSB (command bus) streams and raw capture bus streams.

Key hardware-specific parameters
================================

The wrapper hard-codes the following parameters that are specific to the IceBoard platform:


.. todo:: Update hardware config parameters

- PLATFORM_TYPE = CRS
- Clocking


- ADCs:

- BSB interface

  	- BSB bus is connected to the ARM processor

Entity definition
=================

.. parse:: hdl/platforms/crs/chfpga_crs.vhd

.. autoentity:: chfpga_crs

Parameters
==========

- **PLATFORM_TYPE:** Platform type identifier. Fixed to ``CRS`` for this wrapper.
- **SYSTEM_CLOCK_SOURCE:** Source of the system reference clock. ``SYSCLK_BUFG`` uses a BUFG-buffered version of the 10 MHz PLL output on ``sysclk_p/n``.
- **SYSTEM_CLOCK_FREQ:** System reference clock frequency in MHz (default: 10.0). Used to configure the MMCM divider/multiplier factors that generate internal system clocks.
- **CHAN_CLK_SOURCE:** Channelizer clock source. Set to ``ADC`` so that the channelizer clock is derived from the ADC word clock (``plclk``).
- **CT_CLK_SOURCE:** Corner-turn engine clock source, taken from the active configuration package via ``CONFIG_CT_CLK_SOURCE``.
- **BUCK_SYNC_ENABLE:** Default enable state of the buck regulator synchronization signals at startup.
- **BUCK_CLK_DIVIDE_FACTOR:** Sets the buck synchronization frequency: f\ :sub:`buck` = 200 MHz / 16 / ``BUCK_CLK_DIVIDE_FACTOR``. Default of 12 gives approximately 1.04 MHz.
- **BSB_INTERFACE:** BSB interface type. Set to ``AXIS`` to connect the BSB command/reply bus to the Zynq ARM processor via AXI-Stream DMA.
- **CAP_INTERFACE:** Capture data interface type. Set to ``AXIS`` to stream captured data to the Zynq ARM via AXI-Stream DMA.
- **SGMII_CLOCK_SOURCE:** 125 MHz clock source for the SGMII GTY. ``REFCLK`` uses the GTY reference clock.
- **ADC_TYPE:** ADC interface type. Set to ``AXIS`` since the integrated RF-ADCs are accessed through an AXI-Stream interface from the Zynq block diagram.
- **NUMBER_OF_ADCS:** Number of ADC input channels (default: 8).
- **NUMBER_OF_ADC_BOARDS:** Number of FMC ADC mezzanine boards. Set to 0 since the CRS uses integrated RF-ADCs with no external mezzanine.
- **FFT_TYPE:** Channelizer FFT type, selected from the configuration package via ``CONFIG_CHAN_FFT_TYPE``.
- **NUMBER_OF_CHANNELIZERS_WITH_FFT:** Number of channelizers that include an FFT block, from the configuration package.
- **NUMBER_OF_CHANNELIZERS:** Total number of channelizer blocks (default: ``NUMBER_OF_ADCS``).
- **CAPTURE_TYPE:** Channelizer data capture type, from the configuration package.
- **CT_TYPE:** Corner-turn type (``BCT`` or ``UCT``), from the configuration package.
- **CT_LEVEL:** Corner-turn level: 1 = single-board, 2 = crate-level, 3 = multi-crate. From the configuration package.
- **CT_LANE_TO_LINK_MAP:** Integer array mapping each corner-turn lane to a GTY link index. A value of −1 designates a bypass lane (stays internal to the board, no GTY).
- **CT_LINK_TO_QUAD_MAP:** Integer array mapping each GTY link to a QPLL/QUAD. Determines the number of QPLLs instantiated. The CRS board provides 12 links: SFP28-1–6 (links 0–5) and backplane PCB/QSFP slots (links 6–11).
- **CT_QUAD_TO_REFCLK_MAP:** Integer array mapping each QUAD to a reference clock index.
- **CT_LANE_TO_GROUP_MAP:** Integer array assigning each lane to a lane group (e.g., group 0 for CT level-2 lanes, group 1 for CT level-3 lanes).
- **CORR_TYPE:** Correlator type (``UCORR44``, ``CORR44``, or ``NONE``), from the configuration package.
- **CORR_READOUT_BINS:** Integer array listing the frequency bins to read out from the correlator.
- **DATA_LINK_TYPE:** Real-time data offload type. ``UPACK_CGE`` enables the QSFP 100G Ethernet interface; ``NONE`` disables it.
- **DATA_LINK_LINK_TO_QUAD_MAP:** Maps data-link channels to GTY QUADs. Ignored when ``DATA_LINK_TYPE = NONE``.
- **DATA_LINK_QUAD_TO_REFCLK_MAP:** Maps data-link QUADs to reference clocks. Ignored when ``DATA_LINK_TYPE = NONE``.
- **BLINKER_PRESENT:** Whether the LED blinker/status module is implemented.
- **NUMBER_OF_I2C_PORTS:** Number of I2C ports (default: 0 — no direct I2C on the CRS PL).
- **NUMBER_OF_SPI_PORTS:** Number of SPI ports (default: 0 — no FMC mezzanine).
- **IMPLEMENT_ARM_SPI:** Whether an ARM SPI interface is implemented. False on CRS since the ARM communicates via AXI DMA.
- **IMPLEMENT_LCD:** Whether the OLED display driver is implemented.
- **SIM:** Simulation mode. When ``TRUE``, accelerates simulations.
- **NUMBER_OF_CT_LINKS** *(derived)*: Total GTY link count for corner-turn, equal to the length of ``CT_LINK_TO_QUAD_MAP``.
- **NUMBER_OF_CT_REFCLKS** *(derived)*: Number of corner-turn GTY reference clocks, derived from ``CT_QUAD_TO_REFCLK_MAP``.
- **NUMBER_OF_GPU_LINKS** *(derived)*: Number of 100G Ethernet links; 0 if ``DATA_LINK_TYPE = NONE``.
- **NUMBER_OF_GPU_REFCLKS** *(derived)*: Number of reference clocks for the 100G Ethernet links.

Interface
=========

Clocking
--------

- ``sma_clk10_p/n``: (in) LVDS 10 MHz reference clock from the on-board SMA connector; one of two selectable 10 MHz reference sources.
- ``bp_clk10_p/n``: (in) LVDS 10 MHz reference clock from the backplane; selectable alternative to the SMA clock.
- ``pll_oscout_p/n``: (in) LVDS 50 MHz VCXO output from the programmable PLL, phase-locked to the active 10 MHz reference clock.
- ``pll_sync``: (out) Synchronization signal to the programmable PLL, timed to the rising edge of ``pll_oscout``.
- ``plclk_p/n``: (in) LVDS 375 MHz ADC word clock from the PLL (fs/8 = 3000/8 MHz).
- ``rf_sysref_p/n``: (in) RF SYSREF differential clock from the PLL, used to trigger multi-converter synchronization for the integrated ADCs.
- ``pl_sysref_p/n``: (in) PL SYSREF differential clock (submultiple of ADC sampling clock) for ADC latency calibration.
- ``sysclk_p/n``: (in) LVDS 10 MHz system clock from the programmable PLL, used as the MMCM reference to generate internal system clocks.

100G Ethernet
-------------

- ``clk156_p/n``: (in) 156.25 MHz LVDS reference clock for the QSFP 100G Ethernet interface. Active only when ``DATA_LINK_TYPE = UPACK_CGE``.
- ``qsfp_txp/n[0:3]``: (out) Serialized 100G Ethernet transmit lanes to the QSFP cage. Active only when ``DATA_LINK_TYPE = UPACK_CGE``.

Corner-turn shuffle links
-------------------------

- ``bp_shuffle_tx_p/n[0:NUMBER_OF_CT_LINKS-1]``: (out) GTY transmit lanes for backplane and SFP28 data shuffling.
- ``bp_shuffle_rx_p/n[0:NUMBER_OF_CT_LINKS-1]``: (in) GTY receive lanes for backplane and SFP28 data shuffling.
- ``bp_shuffle_refclk_p/n[0:NUMBER_OF_CT_REFCLKS-1]``: (in) GTY reference clocks for the corner-turn shuffle links.

Power supply synchronization
-----------------------------

- ``buck_sync_0v85/1v2a/1v2b/1v4/1v8/2v5/3v3/5v0/bp``: (out) Individual synchronization outputs for the board's buck switching regulators, driven from ``chfpga``'s internal ``buck_sync`` vector.

Indicators and user I/O
------------------------

- ``led7b[7:0]``: (out) 7-segment LED display. Bits [5:0] are the a–f ring segments, bit [6] is the center (g) segment, bit [7] is the decimal point.
- ``fpc_d[1:0]``: (out) OLED display interface. ``fpc_d[0]`` carries the ~500 kHz clock (generated by dividing the 50 MHz PLL OSCOUT); ``fpc_d[1]`` is the clock-select line (held ``'0'`` to use the external clock source).
- ``smp[0:3]``: (out) SMP coax connectors for oscilloscope debugging. Fixed routing: SMP5→``smp[1]``, SMP6→``smp[0]`` (10 MHz refclk from BUFGMUX), SMP7→``smp[3]`` (50 MHz OSCOUT), SMP8→``smp[2]`` (10 MHz sysclk).
- ``sma_aux_drv``: (out) Auxiliary SMA driver output.

IRIG-B
------

- ``sma_irig_p/n``: (in) LVDS IRIG-B time signal from the SMA connector.
- ``bp_irig_p/n``: (in) LVDS IRIG-B time signal from the backplane. The active source is selected by ``clk10_sel`` inside ``chfpga``.

ADC analog inputs
-----------------

- ``adc0_clk_clk_p/n`` … ``adc3_clk_clk_p/n``: (in) Differential sampling clocks for the four RF-ADC tiles (one differential clock per tile, two channels per tile).
- ``vin0_01_v_p/n`` … ``vin3_23_v_p/n``: (in) RF-ADC differential analog input pairs. ``vinX_YZ`` is the input for converters Y and Z of tile X.

Implementation details
======================

Architecture
------------

The entity instantiates:

- ``zynq_tcpipe_crs``: The Zynq MPSoC block diagram containing the Zynq processing system, the integrated RF-ADC IP core (providing 8 analog channels as 128-bit-wide AXI-Stream buses at the ``plclk`` word rate), and two AXI-Stream DMA engines connecting the BSB command/reply and data capture buses to the ARM processor.
- `chfpga`: The main chFPGA signal-processing core, configured with CRS-specific platform generics.

The wrapper also instantiates the following Xilinx primitives directly:

- ``IBUFGDS``/``BUFG`` pairs for all differential clock inputs (10 MHz reference clocks, PLL OSCOUT, PLCLK, SYSCLK, SYSREF).
- A ``BUFGMUX`` to select between the SMA and backplane 10 MHz reference clocks.
- A ``xpm_cdc_single`` CDC synchronizer and register pipeline to align the ``pll_sync`` output to the PLL OSCOUT clock.
- ``IBUFDS`` primitives for the differential IRIG-B time signal inputs.

Principle of operations
-----------------------

The CRS board uses a programmable PLL (LMK04832 or similar) to derive all clocks from a selectable 10 MHz reference (SMA or backplane). The integrated Zynq RF-ADCs sample the 8 analog inputs at 3 GHz, producing 128-bit parallel words at 375 MHz (the ADC word clock, ``plclk``). ADC data reaches ``chfpga`` as AXI-Stream buses at the ``plclk`` rate via the block diagram.

The BSB and capture interfaces are AXI-Stream buses clocked at 100 MHz (``aclk``), connected to the Zynq ARM via DMA engines in the block diagram. The 10 MHz PLL clock output (``sysclk``) is the MMCM reference inside ``chfpga`` for generating the main internal system clocks (200 MHz, etc.).

For configurations with ``CT_LEVEL > 1``, the backplane shuffle GTY links are driven; otherwise their IO buffers are suppressed (``IO_BUFFER_TYPE = NONE``) so that the unused pins do not cause DRC errors in the bitstream. Similarly, the QSFP interface is only instantiated when ``DATA_LINK_TYPE = UPACK_CGE``.
