.. title:: irigb_comparator

***************************************************************************
:entity:`irigb_comparator` (*irigb_comparator.vhd*): IRIG-B Time Comparator
***************************************************************************

.. parse:: hdl/SYSTEM/irigb_comparator.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: irigb_comparator

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

