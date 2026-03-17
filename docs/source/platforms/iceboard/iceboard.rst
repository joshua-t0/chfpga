IceBoard (MGK7MB)
*****************

.. toctree::
   :maxdepth: 1
   :hidden:

   chfpga_ice
   chfpga_ice_corr16
   chfpga_ice_ct
   ../../navbar_separator


Hardware description
====================

.. figure:: ../../images/PLATFORMS/IceBoard/IceBoard_with_2_Mezz_back.JPG
    :width: 50%

The IceBoard is a Kintex-7-based FPGA motherboard designed by McGill Cosmology Instrumentation Laboratory. The board is optimized to be used in arrays requiring the processing of large number of analog signals.  The board provides the following capabilities:

- Xilinx/AMD XC7K420T FPGA
- 2x HPC FMC connector fully connected to the FPGA
- On-board Texas Instruments AM3874 ARM processor with 1GB DDR3 memory for networking, board monitoring & FPGA configuration
- 1x SFP+ (up to 10 Gbps) and 2x QSFP+ (Up to 80 Gbps in total) for data offload
- 9U Form Factor
- Can be packed into a 16-slot crate that distributes power, clock, timing, and provides a full-mesh 10 Gbps network for multi-board corner-turning
- On board PLL to provide various frequencies to the FPGA and ARM
- All on-boards devices clocked from single reference clock source to mitigate RFI
- Powered by a single 14-20V power source

Detailed description of the IceBoard hardware can be found at https://winterlandcosmology.bitbucket.io/iceboard-docs/


Clocking hardware
=================

The IceBoard uses two on-board PLLs to distribute clocks to the FPGA, ARM, Ethernet PHY and backplane fabric. All devices are ultimately derived from a common reference clock to minimize relative phase noise between analogue signal paths.

The following table summarizes the main clock sources and how they appear in the FPGA design (see ``constraints/ice/ice_physical_constraints_common.xdc`` and ``hdl/chfpga_ice.vhd``):

.. list-table::
   :header-rows: 1

   * - Source
     - PLL/output
     - Frequency
     - Board / destination
     - FPGA / HDL signal
     - Usage in ``chFPGA``
   * - PLL1
     - OUT0
     - 20 MHz
     - ARM processor
     - (no direct PL port)
     - ARM-side clocks only
   * - PLL1
     - OUT1
     - 100 MHz
     - MGTCLKREF1_114 (ARM / PCIe)
     - (no direct PL port)
     - Non–CHFPGA infrastructure
   * - PLL1
     - OUT2
     - 25 MHz
     - Ethernet PHY reference
     - (no direct PL port)
     - 1G Ethernet/management
   * - PLL1
     - OUT3
     - 125 MHz
     - SFP refclk (MGTCLKREF1_116)
     - ``sfp_clk_p/n``
     - 1G/10G SFP link and as a possible system clock source
   * - PLL1
     - OUT4
     - 200 MHz
     - MGT reference
     - ``mgt_clk200_p/n``
     - Internal 200 MHz system/monitoring clocks
   * - PLL2
     - OUT0–2
     - 156.25 MHz
     - GTX refclks for backplane/QSFP+
     - ``xge_refclk_p/n`` and related MGT refclks
     - 10G backplane / shuffle links
   * - PLL2
     - OUT3
     - 125 MHz
     - Alternate 1G/10G reference
     - (no dedicated top-level port)
     - Alternative Ethernet clocking
   * - PLL2
     - OUT4
     - 10 MHz
     - MGTCLKREF1_115 (PLL bypass)
     - ``mgt_clk10_p/n``
     - 10 MHz reference used for timing and for resampling backplane time/trigger
   * - Raw clock
     - (bypass)
     - 10 MHz
     - Single-ended 10 MHz reference
     - ``raw_clk10``
     - Used by `chFPGA` for clock monitoring and coarse timing


Platform wrapper
================

`chFPGA` is implemented on the Iceboard platform using the :ref:`chfpga_ice<chfpga_ice>` platform wrapper, which instantiates the `chFPGA` module. See :ref:`platform_wrappers` for more details.

Configurations
==============

Multiple `chFPGA` firmware configurations are supported on this platform:

- :ref:`ct <chfpga_ice_ct_config>` — ``chfpga_ice_ct_config``: 16-, 256- or 512-channel F-Engine, corner-turn engine and real-time data offload to an external X-Engine
- :ref:`corr16 <chfpga_ice_corr16_config>` — ``chfpga_ice_corr16_config``: 16-channel single-board F-Engine and :math:`N^2` correlator

.. include:: ./floorplanning.rst


Top-level port signals and timing
=================================

The IceBoard platform wrapper :entity:`chfpga_ice` connects `chFPGA` to the following key timing-related ports:

* ``mgt_clk10_p/n`` — 10 MHz reference clock (PLL bypass) brought into the PL through a GT reference-clock input and buffered as ``mgt_clk10`` in the design.
* ``raw_clk10`` — single-ended 10 MHz reference used for frequency monitoring and coarse timing.
* ``bp_time_p/n`` — differential backplane **time** signal.
* ``bp_trig_p/n`` — differential backplane **trigger** signal.

In :entity:`chfpga_ice`, the backplane time and trigger inputs are first converted to single-ended signals (``time_in`` and ``trig_in``) using ``IBUFGDS`` instances. They are then resampled in the ``mgt_clk10`` clock domain:

* On the **falling edge** of ``mgt_clk10``, the raw inputs are captured into intermediate registers.
* On the **rising edge** of ``mgt_clk10``, a second set of registers captures the intermediate values to produce stable, time-aligned versions of the time and trigger signals.

These resampled signals are combined into the ``time_trig(0 to 1)`` vector that is passed to :entity:`chfpga`:

* ``time_trig(0)`` — backplane time signal.
* ``time_trig(1)`` — backplane trigger signal.

Inside :entity:`chfpga` and :entity:`system`, this vector is further pipelined on the falling and then rising edge of the 200 MHz ``clk200`` clock before being used by the IRIG-B decoder, refclk synchronizer and time-tagging logic. As on the CRS platform, this double registration (first in the 10 MHz domain, then in the 200 MHz domain) provides deterministic and well-characterised timing for all time and trigger events.
Inside :entity:`chfpga` and :entity:`system`, this vector is further pipelined on the rising edge of the 200 MHz ``clk200`` clock before being used by the IRIG-B decoder, refclk synchronizer and time-tagging logic. As on the CRS platform, this double registration (first in the 10 MHz domain, then in the 200 MHz domain) provides deterministic and well-characterised timing for all time and trigger events. To guarantee this, ``clk200`` must be generated from a clock source that is synchronous to the external time/trigger domain used to drive ``time_trig``.