``corr32`` configuration (*chfpga_crs_corr32_config.vhd*)
=========================================================

8-channel F-Engine, UCT corner-turn with crate-level shuffle (3× PCB links), and 32-input correlator. Data is shuffled across 4 boards in a crate via backplane links.

Configuration parameters
------------------------

- :ref:`CONFIG_CHAN_IMPLEMENT_FFT <config_chan_implement_fft>` — TRUE; F-Engine with FFT
- :ref:`CONFIG_CHAN_FFT_TYPE <config_chan_fft_type>` — CHORD; 14-bit, 16384 samples, 32+32 output
- :ref:`CONFIG_CHAN_CAPTURE_TYPE <config_chan_capture_type>` — UCAP; URAM-based centralized capture
- :ref:`CONFIG_CHAN_NUMBER_OF_CAPTURE_SOURCES <config_chan_number_of_capture_sources>` — 2
- :ref:`CONFIG_CHAN_SCALER_USE_COMPLEX_GAINS <config_chan_scaler_use_complex_gains>` — FALSE
- :ref:`CONFIG_NUMBER_OF_CHANNELIZERS_WITH_FFT <config_number_of_channelizers_with_fft>` — 8
- :ref:`CONFIG_CT_TYPE <config_ct_type>` — UCT; CHORD-like format
- :ref:`CONFIG_CT_LEVEL <config_ct_level>` — 2; crate-level shuffle
- :ref:`CONFIG_CT_CLK_SOURCE <config_ct_clk_source>` — ADC_CLK; 400 MHz processing clock
- :ref:`CONFIG_CT_LANE_TO_LINK_MAP <config_ct_lane_to_link_map>` — (-1, 6, 8, 10); bypass + 3 PCB links
- :ref:`CONFIG_CORR_TYPE <config_corr_type>` — UCORR44; 32-input correlator
- :ref:`CONFIG_CORR_READOUT_BINS <config_corr_readout_bins>` — (0 => 0)
- :ref:`CONFIG_DATA_LINK_TYPE <config_data_link_type>` — NONE; no real-time offload

Package definition
------------------

.. parse:: hdl/platforms/crs/chfpga_crs_corr32_config.vhd

Implementation details
======================

Principle of operations
-----------------------

This package defines compile-time constants that select the firmware personality for a CRS board acting as a 32-input correlator node in a single crate. It enables 8 CHORD-format F-Engine channelizers with URAM-based centralized capture, configures a UCT crate-level corner-turn (``CT_LEVEL = 2``) that exchanges data across 4 boards via 3 PCB backplane links, and instantiates a 32-input UCORR44 correlator that accumulates products locally. No real-time data offload is active; all output is through the register/BSB interface.
