.. title:: fifo_reset_sync

**************************************************************************************
:entity:`fifo_reset_sync` (*fifo_reset_sync.vhd*): FIFO reset synchronizer (reference)
**************************************************************************************

.. default-role:: vhdl:entity

Overview
========

Synchronizes and **stretches** an asynchronous reset request into a target clock domain using ``xpm_cdc_async_rst``, then holds ``rst_out`` for at least ``MIN_ASSERT_CYCLES``. Optional ``POWER_ON_CYCLES`` mimics Xilinx FIFO IP power-on reset extension.

The VHDL header states this block is **not instantiated in the current chFPGA tree**; it is kept as a **reference** for hard-FIFO reset sequencing next to embedded FIFO primitives. If you reuse it: drive ``arst`` active-high; ``rst_out`` / ``rst_busy`` follow the XPM async-reset pattern on ``clk``. Tune ``SYNC_STAGES`` (2–10) and ``MIN_ASSERT_CYCLES`` to meet vendor FIFO reset pulse requirements.

Production FIFO wrapping and reset discussion: `generic_fifo`.

Entity documentation
====================

.. parse:: hdl/utils/fifo_reset_sync.vhd

.. autoentity:: fifo_reset_sync

Parameters
==========

- **SYNC_STAGES:** ``xpm_cdc_async_rst`` synchronizer chain depth (2–10). Default: 3.

- **MIN_ASSERT_CYCLES:** Minimum number of ``clk`` cycles that ``rst_out`` remains asserted
  after the synchronizer releases, guaranteeing the vendor FIFO primitive's reset pulse-width
  requirement. Default: 5.

- **POWER_ON_CYCLES:** Optional power-on reset extension in ``clk`` cycles, mimicking the
  behavior of Xilinx FIFO Generator IP at startup. Set to 0 to disable. Default: 0.

Interface
=========

- ``clk``: Target clock domain. All outputs are synchronous to this clock.

- ``arst``: Asynchronous reset request (active high). Asserts ``rst_out`` immediately through
  the CDC chain and holds it asserted for at least ``MIN_ASSERT_CYCLES`` after the synchronizer
  deasserts.

- ``rst_out``: Synchronized, stretched active-high reset output suitable for driving hard
  FIFO primitive reset pins.

- ``rst_busy``: Mirrors ``rst_out``; asserted whenever the reset pipeline is active.

Implementation details
======================

Architecture
------------

Three combinatorial conditions are OR-ed to produce ``rst_out`` and ``rst_busy``:

1. ``power_rst`` — a counter-based power-on pulse of ``POWER_ON_CYCLES`` cycles (optional).
2. ``cdc_rst`` — the ``xpm_cdc_async_rst`` output: asserts asynchronously on ``arst``,
   deasserts synchronously after ``SYNC_STAGES`` clock cycles.
3. ``hold_rst`` — a counter that keeps ``rst_out`` high for ``MIN_ASSERT_CYCLES`` additional
   ``clk`` cycles after ``cdc_rst`` begins to release.

Clocking
--------

Single clock ``clk``. The asynchronous ``arst`` input passes through ``xpm_cdc_async_rst``
(async assert, synchronous deassert) before all further logic is clocked on ``clk``.

Principle of operations
-----------------------

This block is **not instantiated in the current chFPGA tree**; it is kept as a **reference**
for hard-FIFO reset sequencing next to embedded FIFO primitives. The production FIFO reset
path is implemented inside `generic_fifo`.

When ``arst`` asserts, ``rst_out`` asserts immediately (asynchronously through the CDC
primitive). When ``arst`` deasserts, ``cdc_rst`` releases after ``SYNC_STAGES`` ``clk`` cycles;
the hold counter then keeps ``rst_out`` high for a further ``MIN_ASSERT_CYCLES`` cycles,
ensuring the embedded FIFO primitive sees a sufficiently long reset pulse regardless of the
asynchronous release timing.
