.. _chfpga_kc705:
.. _chfpga_kc705_corr8_config:

**********************************************************
:entity:`chfpga_kc705` platform wrapper and configurations
**********************************************************

===========
Description
===========

The platform wrapper :file:`chfpga_kc705.vhd` is the top-level entity used to implement `chFPGA` on the KC705. It defines the I/Os that connect the FPGA to the board-specific hardware. All entity port names are **lowercase** (e.g. ``cpu_reset``, ``gpio_led``, ``sysclk_p``, ``phy_rxclk``, ``adc0_ahdp``, ``refclk_m2c_p``, ``mgt_pll_m2c_p``).

The wrapper passes ``PLATFORM_ID_MGK7MB`` to the `chfpga` core (shared Kintex-7 BSB clock logic; the core's ``bsb_clk_sel`` supports both ``PLATFORM_ID_KC705`` and ``PLATFORM_ID_MGK7MB``).

================================
Key hardware-specific parameters
================================

As in the main :ref:`KC705 platform document <kc705_platform>`: SYSCLK 200 MHz, GMII PHY, one ADC board, 8 ADCs, EV8AQ160 with BUFMR/BUFIO mapping for the KC705 pinout.

Entity definition
=================

.. parse:: hdl/chfpga_kc705.vhd

.. autoentity:: chFPGA_KC705


``corr8`` configuration (*chfpga_kc705_corr8_config.vhd*)
*********************************************************

Description
===========

The file :file:`chfpga_kc705_corr8_config.vhd` defines the package `chfpga_config` used to configure `chFPGA` for the 8-channel correlator configuration on the KC705. This configuration includes:

- Data acquisition from one FMC ADC mezzanine (8 channels)
- 8 channelizers with FFT (HIRAX 3-DSP style)
- 8-input :math:`N^2` correlator (UCORR44)
- Corner-turn: ``CT_LEVEL=1``, ``CONFIG_CT_CLK_SOURCE=ADC_CLK``
- ``CONFIG_GPU_LINK_TYPE = NONE``

Package definition
==================

.. parse:: hdl/chfpga_kc705_corr8_config.vhd
