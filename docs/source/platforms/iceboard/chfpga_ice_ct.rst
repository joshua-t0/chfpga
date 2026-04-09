.. _chfpga_ice_ct_config:

``ct`` configuration (*hdl/platforms/ice/chfpga_ice_ct_config.vhd*)
*******************************************************************

Description
===========

This module defines the package `chfpga_config` that provides the constants used to configure the `chFPGA` firmware for correlator operations on the IceBoard platform.

This configuration includes:

- F-Engine

   - 16 Channelizers
   - FFT: 8-bit, 2048 sample CASPER FFT with (18+18) bits complex values and programmable bitshift, with sample rotation
   - SCALER: Use floating point gains
   - PROBER: Use distributed (per channelizer) data capture module

- Corner-turn Engine

   - BCT-type corner-turn with 3 stages (3 crossbars + GTY data shuffling links between each crossbars).
   - Allows data shuffling within the board, between boards in a crate and between boards between two crates

- X-Engine

   + Disabled


- Real-time data offload

   - 8x10G Ethernet real-time data offload of corner-turned channelized data

Configuration parameters
========================

This config uses the following parameters (see :ref:`config_param_reference` for full descriptions):

- :ref:`CONFIG_CHAN_IMPLEMENT_FFT <config_chan_implement_fft>` — TRUE; F-Engine with FFT
- :ref:`CONFIG_CHAN_FFT_TYPE <config_chan_fft_type>` — HIRAX; 8-bit, 2048 samples, 18+18 output
- :ref:`CONFIG_NUMBER_OF_CHANNELIZERS_WITH_FFT <config_number_of_channelizers_with_fft>` — 16
- :ref:`CONFIG_CHAN_SCALER_USE_COMPLEX_GAINS <config_chan_scaler_use_complex_gains>` — FALSE
- :ref:`CONFIG_CHAN_CAPTURE_TYPE <config_chan_capture_type>` — PROBER; per-channelizer BRAM capture
- :ref:`CONFIG_CHAN_NUMBER_OF_CAPTURE_SOURCES <config_chan_number_of_capture_sources>` — 2
- :ref:`CONFIG_CT_TYPE <config_ct_type>` — BCT; multi-board backplane shuffle
- :ref:`CONFIG_CT_LEVEL <config_ct_level>` — 3; within board, crate, and between crates
- :ref:`CONFIG_CT_CLK_SOURCE <config_ct_clk_source>` — BP_SHUFFLE_TXCLK; backplane TX clock for packet overhead
- :ref:`CONFIG_CORR_TYPE <config_corr_type>` — NONE; X-Engine off-board
- :ref:`CONFIG_CORR_READOUT_BINS <config_corr_readout_bins>` — (0, 0); not used
- :ref:`CONFIG_DATA_LINK_TYPE <config_data_link_type>` — XGE; 8×10G Ethernet offload

Package definition
==================

.. parse:: hdl/platforms/ice/chfpga_ice_ct_config.vhd


Implementation details
======================

Principle of operations
-----------------------

This package configures the IceBoard firmware as a multi-board F-Engine and corner-turn node without an on-board correlator. It enables 16 HIRAX-format channelizers (8-bit, 2048-sample FFT, 18+18-bit complex output) with per-channelizer PROBER BRAM capture, a BCT corner-turn at level 3 (within-board, intra-crate, and inter-crate GTY backplane shuffling), and 8×10G Ethernet real-time offload (``DATA_LINK_TYPE = XGE``) of the corner-turned data to an external X-Engine.
