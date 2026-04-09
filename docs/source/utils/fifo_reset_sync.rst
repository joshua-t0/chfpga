.. title:: fifo_reset_sync

****************************************************************************
:entity:`fifo_reset_sync` (*fifo_reset_sync.vhd*): FIFO reset synchronizer (reference)
****************************************************************************

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

- SYNC_STAGES: ``xpm_cdc_async_rst`` depth (2…10).

- MIN_ASSERT_CYCLES: Minimum ``rst_out`` pulse length in ``clk`` cycles.

- POWER_ON_CYCLES: Optional extra reset extension after startup (mimics IP power-on).

Interface
=========

- ``clk``: Target clock domain.

- ``arst``: Asynchronous reset request (active high).

- ``rst_out`` / ``rst_busy``: Synchronized, stretched reset and busy for FIFO IP-style handshake.

Principle of operations
=======================

**Not instantiated in-tree today** (**reference only**): **chains ``xpm_cdc_async_rst`` with a cycle counter so vendor FIFOs see clean reset assertion and release**. **Production path uses `generic_fifo` instead**.
