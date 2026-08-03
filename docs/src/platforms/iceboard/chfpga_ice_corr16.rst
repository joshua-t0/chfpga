.. _chfpga_ice_corr16_config:

``corr16`` configuration (*hdl/platforms/ice/chfpga_ice_corr16_config.vhd*)
***************************************************************************


Description
===========

The file ``chfpga_ice_corr16_config.vhd`` defines the package ``chfpga_config`` containing constants that configure the ``chFPGA`` firmware for correlator operations on the IceBoard platform.

This configuration includes:

- Data acquisition from the two MGADC08 FMC ADC mezzanine
- 16 Channelizers
- 16-input N^2 correlator

Configuration parameters
========================

This config uses the following parameters (see :ref:`config_param_reference` for full descriptions):

- :ref:`CONFIG_CHAN_IMPLEMENT_FFT <config_chan_implement_fft>` — TRUE; F-Engine with FFT
- :ref:`CONFIG_CHAN_FFT_TYPE <config_chan_fft_type>` — HIRAX_3DSP; 8-bit, 2048 samples, 24+24 output
- :ref:`CONFIG_NUMBER_OF_CHANNELIZERS_WITH_FFT <config_number_of_channelizers_with_fft>` — 16
- :ref:`CONFIG_CHAN_SCALER_USE_COMPLEX_GAINS <config_chan_scaler_use_complex_gains>` — FALSE
- :ref:`CONFIG_CHAN_CAPTURE_TYPE <config_chan_capture_type>` — PROBER; per-channelizer BRAM capture
- :ref:`CONFIG_CT_TYPE <config_ct_type>` — BCT; simple internal corner-turn
- :ref:`CONFIG_CT_LEVEL <config_ct_level>` — 1; single-board, no backplane
- :ref:`CONFIG_CT_CLK_SOURCE <config_ct_clk_source>` — ADC_CLK; 400 MHz sufficient at CT_LEVEL=1
- :ref:`CONFIG_CORR_TYPE <config_corr_type>` — UCORR44; 16-input correlator
- :ref:`CONFIG_CORR_READOUT_BINS <config_corr_readout_bins>` — (0, 0)
- :ref:`CONFIG_DATA_LINK_TYPE <config_data_link_type>` — NONE; no real-time offload

Package definition
==================

.. parse:: hdl/platforms/ice/chfpga_ice_corr16_config.vhd


Implementation details
======================

Principle of operations
-----------------------

This package defines compile-time constants that configure the IceBoard firmware for a self-contained 16-input on-board correlator. It enables 16 HIRAX_3DSP-format F-Engine channelizers (8-bit, 2048-sample FFT, 25+25-bit complex output) with per-channelizer PROBER BRAM capture, a BCT single-board corner-turn (``CT_LEVEL = 1``) with no backplane data exchange, and a 16-input UCORR44 correlator. No real-time data offload is active.
