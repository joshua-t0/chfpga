.. title:: irigb_comparator

***************************************************************************
:entity:`irigb_comparator` (*irigb_comparator.vhd*): IRIG-B Time Comparator
***************************************************************************

.. parse:: hdl/system/irigb_comparator.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: irigb_comparator

Parameters
==========

This module has no generic parameters.

Interface
=========

- ``current_ts``: Current IRIG-B timestamp as an ``irigb`` record (year, day, hour, minute, second, sub-second, and validity flags).
- ``target_ts``: Target IRIG-B timestamp to compare against. Resynchronised internally to ``clk_200mhz``.
- ``compare_en``: When high, enables the comparator. When low, ``before_target`` is forced to ``'0'``.
- ``force_sync``: When high, forces ``before_target`` to ``'1'`` regardless of the timestamp comparison.
- ``before_target``: High when the current time is strictly before the target time. Result is valid 7 clock cycles after the inputs change.
- ``clk_200mhz``: 200 MHz clock. All logic is synchronous to this clock.

Implementation details
======================

Principle of operations
-----------------------

The comparator performs a hierarchical timestamp comparison starting from year, down through day of year, hour, minute, second, and sub-second (SBS). Each field pair produces boolean ``_gt`` (greater-than) and ``_eq`` (equal) signals that are registered in a single pipeline stage. In the following cycle these are combined into a single ``before_target_pre3`` flag using a priority chain; the result then propagates through two more register stages before being gated with ``compare_en`` and overridden by ``force_sync``. The ``current_ts.recent`` validity flag must be high for the comparison to assert.

Architecture
------------

Because ``target_ts``, ``compare_en``, and ``force_sync`` may originate from a different clock domain, each is passed through a 2-flip-flop synchronizer (marked ``ASYNC_REG``) before use. The per-field comparison results (``y_gt``, ``y_eq``, ``d_gt``, …, ``ss_gt``) are computed and registered in one stage to break the critical path through the wide ``irigb`` record. This gives a total pipeline depth of 7 clock cycles from a change in ``current_ts`` or ``target_ts`` to a stable ``before_target`` output. The three trailing pipeline stages (``before_target_pre3`` → ``before_target_pre2`` → ``before_target_pre1`` → ``before_target``) are marked ``shreg_extract = "no"`` to prevent the synthesiser from collapsing them.

Principle of Operations
=======================

The `irigb_comparator` module compares a current timestamp with a target timestamp and determines if the current time is before the target time. This is useful for time-based event triggering and synchronization.

The comparator performs hierarchical comparison starting from the year, down through day of year, hour, minute, second, and sub-second (SBS) fields. It includes synchronization logic to handle clock domain crossing when the target timestamp comes from a different clock domain.

Key Features
------------

- **Timestamp comparison**: Compares current and target IRIG-B timestamps
- **Clock domain crossing**: Includes synchronization for cross-domain signals
- **7-clock latency**: Provides comparison result with 7 clock cycles of latency
- **Force sync**: Includes a force synchronization signal for manual triggering

Usage
-----

The `irigb_comparator` is used in systems that need to trigger events at specific times based on IRIG-B timestamps. It works in conjunction with the :entity:`irigb_encoder` module to provide time-based control functionality.

