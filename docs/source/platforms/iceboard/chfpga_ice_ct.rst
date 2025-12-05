.. _chfpga_ice_ct_config:

``ct`` configuration (*chfpga_ice_ct_config.vhd*)
*********************************************************

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


Package definition
==================

.. parse:: hdl/chfpga_ice_ct_config.vhd




