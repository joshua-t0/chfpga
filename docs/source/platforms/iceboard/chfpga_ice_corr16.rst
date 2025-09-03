.. _chfpga_ice_corr16_config:

``corr16`` configuration (*chfpga_ice_corr16_config.vhd*)
*********************************************************


Description
===========

The file `chfpga_ice_corr_config.vhd` defines the package `chfpga_config` containing constants that configure the `chFPGA` firmware for correlator operations on the IceBoard platform.

This configuration includes:

- Data acquisition from the two MGADC08 FMC ADC mezzanine
- 16 Channelizers
- 16-input N^2 correlator


Package definition
==================

.. parse:: hdl/chfpga_ice_corr16_config.vhd


