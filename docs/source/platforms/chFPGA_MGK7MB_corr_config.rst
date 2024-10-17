.. _chfpga_mgk7mb_corr_config:

IceBoard corr configuration (*chfpga_mgk7mb_corr_config.vhd*)
*************************************************************


Description
=========================

The file `chfpga_mgk7mb_corr_config.vhd` defines the package `chfpga_config` containing constants that configure the `chFPGA` firmware for correlator operations on the IceBoard platform.

This configuration includes:

- Data acquisition from the two MGADC08 FMC ADC mezzanine
- 16 Channelizers
- 16-input N^2 correlator

Package definition
=================

.. parse:: hdl/chfpga_mgk7mb_config.vhd

.. .. autoentity:: chFPGA_MGK7MB_Rev2

