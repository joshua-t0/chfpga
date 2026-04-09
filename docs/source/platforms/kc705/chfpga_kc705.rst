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


``corr8`` configuration (*chfpga_kc705_corr8_config.vhd*)
*********************************************************

Description
===========

The file :file:`chfpga_kc705_corr8_config.vhd` defines the package `chfpga_config` used to configure `chFPGA` for the 8-channel correlator configuration on the KC705. This configuration includes data acquisition from one FMC ADC mezzanine (8 channels), 8 channelizers with FFT (HIRAX 3-DSP style), an 8-input :math:`N^2` correlator (UCORR44), and no real-time data offload.

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
