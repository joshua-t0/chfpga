.. title:: refclk

**********************************************************
:entity:`refclk` (*refclk.vhd*): Reference clock sequencer
**********************************************************

.. .. figure:: ../images/REFCLK.svg
..     :width: 100%

Entity documentation
====================

.. parse:: hdl/system/refclk.vhd

.. autoentity:: refclk

Parameters
==========

- **PLATFORM_TYPE:** Target platform, defined as ``platform_type_enum`` in :doc:`../chfpga_package`. Used to select the correct IDELAY primitive variant and clock buffer configuration.
- **NUMBER_OF_MEZZANINES:** Number of FMC ADC mezzanine boards. Sets the width of the ``fmc_refclk_p/n``, ``fmc_refclk``, ``fmc_refclk_div2``, and ``adc_sync_p/n`` port arrays.
- **IMPLEMENT_CLOCK_ENCODED_SYNC:** When ``TRUE``, generates a pulse-width-modulated 10 MHz output clock (``clk10_out``) that encodes SYNC events as a shorter-than-50% duty-cycle high pulse. When ``FALSE``, ``clk10_out`` passes the BUFG-buffered FMC reference clock from mezzanine 0.
- **SIM:** When ``TRUE``, uses a shortened PLL stabilisation timeout (16 ``clk10`` cycles instead of 65536) to accelerate simulations.

Interface
=========

BSB control interface
---------------------

- ``s/m_axis_bsb_t*``: BSB (Byte-Stream Bus) interface for register access.
- ``bsb_clk``/``bsb_rst``: BSB clock and reset.

SYNC signals
------------

- ``clk10``: Buffered 10 MHz backplane reference clock. Clocks the SYNC state machine and event detection logic.
- ``sync_in``: 6-element vector of external SYNC request inputs (from backplane, IRIG-B comparator, or SMA inputs).
- ``adcdaq_reset``: Output that pulses high when a SYNC event is processed, triggering ADC data acquisition pipeline reset.
- ``clk10_out``: 10 MHz reference output (see ``IMPLEMENT_CLOCK_ENCODED_SYNC``).
- ``sync_out``: Registered version of the user SYNC control bit, reclocked to the falling edge of ``clk10``.

FMC reference clock
--------------------

- ``fmc_refclk_p/n``: LVDS differential reference clock inputs from FMC mezzanines. The ``IBUFGDS`` pad is instantiated inside this module.
- ``fmc_refclk``: BUFG-buffered and IDELAY-delayed mezzanine reference clocks (one per mezzanine).
- ``fmc_refclk_div2``: Divide-by-2 logic signals derived from ``fmc_refclk``, used as frequency counter inputs.

ADC SYNC
--------

- ``adc_sync_p/n``: LVDS SYNC outputs to the ADC mezzanines. The ``OBUFDS`` pad is instantiated inside this module.

Clocks and reset
----------------

- ``clk200``: 200 MHz system clock. Used for SYNC encoding/decoding logic.
- ``rst``: Synchronous reset, synchronous to ``clk200``.

Implementation details
======================

Each FMC reference clock is received through an ``IBUFGDS``, delayed by a variable ``IODELAYE1`` (used to scan the ADC clock phase for optimal SYNC timing), and buffered using a BUFR (bypass mode) followed by a BUFG on Kintex-7, or directly by a BUFG on UltraScale+.

The SYNC state machine runs on ``clk10``. On a rising edge of the selected ``sync_in`` or ``local_sync``, it waits one 10 MHz cycle (``SYNC_STATE_STABILIZE_PLL``) for the ADC PLL to re-lock after any clock pulse-width modulation, then simultaneously asserts ``adcdaq_reset`` and ``adc_sync_pre`` (``SYNC_STATE_ADCDAQ_RESET_RELEASE``), then releases both (``SYNC_STATE_SYNC_RELEASE``). The ``adc_sync`` signal is registered on the rising edge of the mezzanine reference clock (which is inverted relative to the motherboard 10 MHz) to achieve reproducible timing relative to the ADC 1600 MHz internal clock.


Additional details
==================


Memory map
==========

.. include-docs:: refclk
    :start-after: Memory Map

