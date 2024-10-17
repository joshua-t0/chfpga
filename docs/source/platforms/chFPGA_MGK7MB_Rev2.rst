.. _chFPGA_MGK7MB_Rev2:

:entity:`chFPGA_MGK7MB_Rev2` (`chfpga_mgk7mb_rev2.vhd`)
*******************************************************


Description
===========

This platform wrapper file implements `chFPGA` for the IceBoard in the Corner-Turn configuration.

The wrapper hard-codes the following parameters that are specific to the IceBoard platform:

- PLATFORM_ID = PLATFORM_ID_MGK7MB
- Clocking

  	- System reference clock is the 125 MHz clock provided as the SFP reference clock
  	- Channelizer clock is a 200 MHz multiphase clock produced by a MMCM fed either by the 200 MHz system clock or the adc clock (software selectable)
  	- Corner-turn operates on the backplane transmitter clock ``BP_SHUFFLE_TXCLK``

- BSB interface

  	- BSB bus is  connected to the 1 Gb Ethernet UDP/MAC that interfaces the SFP port using a SGMII interface (serial interface implemented using the gigabit transceiver)

Entity definition
=================

.. parse:: hdl/chfpga_mgk7mb_rev2.vhd

.. autoentity:: chFPGA_MGK7MB_Rev2


