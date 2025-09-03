.. _chfpga_ice:

:entity:`chfpga_ice` platform wrapper (*chfpga_ice.vhd*)
*********************************************************


Description
===========

This platform wrapper is the top-level that is used to implement `chFPGA` on the IceBoard platform (part number MGK7MB) . It is used with multiple firmware configurations.

The platform defines the I/Os that connect the FPGA  with the IceBoard-specific hardware

Key hardware-specific parameters
================================

The wrapper hard-codes the following parameters that are specific to the IceBoard platform:

- PLATFORM_ID = PLATFORM_ID_MGK7MB
- Clocking

  	- System reference clock is the 125 MHz clock provided as the SFP reference clock
  	- Channelizer clock is a 200 MHz multiphase clock produced by a MMCM fed either by the 200 MHz system clock or the adc clock (software selectable)
  	- Corner-turn operates on the backplane transmitter clock ``BP_SHUFFLE_TXCLK``


- ADCs:
   - Supports two ADC FMC mezzanines

- BSB interface

  	- BSB bus is connected to the 1 Gb Ethernet UDP/MAC that interfaces the SFP port using a SGMII interface (serial interface implemented using the gigabit transceiver)

Entity definition
=================

.. parse:: hdl/chfpga_ice.vhd

.. autoentity:: chfpga_ice

