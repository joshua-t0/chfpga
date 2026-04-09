``ct`` configuration (*chfpga_crs_ct_config.vhd*)
==================================================

F-Engine with 8 channelizers, UCT corner-turn (single-board), and 100G Ethernet real-time data offload via UPACK+CGE. No on-board correlator; data is offloaded to an external X-Engine.

Configuration parameters
-------------------------

- :ref:`CONFIG_CHAN_IMPLEMENT_FFT <config_chan_implement_fft>` — TRUE; F-Engine with FFT
- :ref:`CONFIG_CHAN_FFT_TYPE <config_chan_fft_type>` — CHORD; 14-bit, 16384 samples, 32+32 output
- :ref:`CONFIG_CHAN_CAPTURE_TYPE <config_chan_capture_type>` — UCAP; URAM-based centralized capture
- :ref:`CONFIG_CHAN_NUMBER_OF_CAPTURE_SOURCES <config_chan_number_of_capture_sources>` — 2
- :ref:`CONFIG_CHAN_SCALER_USE_COMPLEX_GAINS <config_chan_scaler_use_complex_gains>` — FALSE
- :ref:`CONFIG_NUMBER_OF_CHANNELIZERS_WITH_FFT <config_number_of_channelizers_with_fft>` — 8
- :ref:`CONFIG_CT_TYPE <config_ct_type>` — UCT; CHORD-like format
- :ref:`CONFIG_CT_LEVEL <config_ct_level>` — 1; single-board, no backplane
- :ref:`CONFIG_CT_CLK_SOURCE <config_ct_clk_source>` — ADC_CLK; 400 MHz processing clock
- :ref:`CONFIG_CT_LANE_TO_LINK_MAP <config_ct_lane_to_link_map>` — (0 => -1); bypass lane
- :ref:`CONFIG_CORR_TYPE <config_corr_type>` — NONE; X-Engine off-board
- :ref:`CONFIG_DATA_LINK_TYPE <config_data_link_type>` — UPACK_CGE; 100G Ethernet offload

Package definition
------------------

.. parse:: hdl/platforms/crs/chfpga_crs_ct_config.vhd

Implementation details
======================

Principle of operations
-----------------------

This package configures a CRS board as a pure F-Engine and single-board corner-turn node without an on-board correlator. It enables 8 CHORD-format channelizers with URAM-based centralized capture, a UCT single-board corner-turn (``CT_LEVEL = 1``) with a bypass lane, and offloads the corner-turned channelized data to an external X-Engine in real time over 100G Ethernet using the UPACK+CGE link (``DATA_LINK_TYPE = UPACK_CGE``).
