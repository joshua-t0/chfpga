``corr64`` configuration (*chfpga_crs_corr64_config.vhd*)
=========================================================

8-channel F-Engine, UCT corner-turn with multi-crate shuffle (3× PCB + 2× SFP links), and 64-input correlator. Data is shuffled across 8 boards in two crates via backplane and SFP links.

Configuration parameters
-------------------------

- :ref:`CONFIG_CHAN_IMPLEMENT_FFT <config_chan_implement_fft>` — TRUE; F-Engine with FFT
- :ref:`CONFIG_CHAN_FFT_TYPE <config_chan_fft_type>` — CHORD; 14-bit, 16384 samples, 32+32 output
- :ref:`CONFIG_CHAN_CAPTURE_TYPE <config_chan_capture_type>` — UCAP; URAM-based centralized capture
- :ref:`CONFIG_CHAN_NUMBER_OF_CAPTURE_SOURCES <config_chan_number_of_capture_sources>` — 2
- :ref:`CONFIG_CHAN_SCALER_USE_COMPLEX_GAINS <config_chan_scaler_use_complex_gains>` — FALSE
- :ref:`CONFIG_NUMBER_OF_CHANNELIZERS_WITH_FFT <config_number_of_channelizers_with_fft>` — 8
- :ref:`CONFIG_CT_TYPE <config_ct_type>` — UCT; CHORD-like format
- :ref:`CONFIG_CT_LEVEL <config_ct_level>` — 3; multi-crate shuffle
- :ref:`CONFIG_CT_CLK_SOURCE <config_ct_clk_source>` — ADC_CLK; 400 MHz processing clock
- :ref:`CONFIG_CT_LANE_TO_LINK_MAP <config_ct_lane_to_link_map>` — (-1, 6, 8, 10, -1, -1, 0, 1); CT2 bypass + 3 PCB links, CT3 SFP links
- :ref:`CONFIG_CORR_TYPE <config_corr_type>` — UCORR44; 64-input correlator
- :ref:`CONFIG_CORR_READOUT_BINS <config_corr_readout_bins>` — (0 => 0)
- :ref:`CONFIG_DATA_LINK_TYPE <config_data_link_type>` — NONE; no real-time offload

Package definition
------------------

.. parse:: hdl/platforms/crs/chfpga_crs_corr64_config.vhd

Implementation details
======================

Principle of operations
-----------------------

This package defines compile-time constants for a CRS board acting as a 64-input correlator node spanning two crates. It configures 8 CHORD-format F-Engine channelizers with URAM-based centralized capture, a multi-crate UCT corner-turn (``CT_LEVEL = 3``) that uses 3 PCB backplane links for intra-crate shuffling and 2 SFP links for inter-crate shuffling across 8 boards total, and a 64-input UCORR44 correlator that accumulates all baselines locally. No real-time data offload is active.
