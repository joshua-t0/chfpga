.. title:: irigb_decoder

********************************************************************
:entity:`irigb_decoder` (*irigb_decoder.vhd*): IRIG-B signal decoder
********************************************************************

Schematic
=========

.. figure:: ../images/irigb_decoder.svg
    :width: 100%


Entity documentation
====================

.. parse:: hdl/system/irigb_decoder.vhd

.. autoentity:: irigb_decoder

Parameters
==========

This module has no generic parameters.

Interface
=========

- ``clk_200mhz``: 200 MHz clock. Drives all decoding logic and the sub-second counter.
- ``irig``: 8-element vector of IRIG-B input signals from different hardware sources.
- ``source``: 3-bit index selecting which element of ``irig`` is decoded.
- ``pol``: IRIG-B signal polarity: ``0`` = normal, ``1`` = inverted.
- ``pps``: Pulse-per-second output. Goes high at the start of each decoded IRIG-B frame and falls 0.5 s later (50% duty cycle).
- ``ts``: Output ``irigb`` record populated with the decoded timestamp at the end of each complete frame. Contains year (2-digit BCD), day-of-year, hour, minute, second, sub-second, control bits, and source/validity fields.

Implementation details
======================

Principle of operations
-----------------------

The decoder measures the low-duration of each IRIG-B bit in milliseconds and classifies it as a ``0`` bit (low 7-8 ms), ``1`` bit (low 4-5 ms), or position marker P (low 1-2 ms). Two consecutive P markers identify the frame reference point (``Pr``), which synchronises the state machine to ``S1`` and begins decoding a new frame.

BCD time fields (seconds, minutes, hours, day-of-year, year, SBS) are accumulated bit-by-bit as the frame progresses through its 100-state machine. When the final P marker is detected in state ``P0``, the accumulated values are registered into ``ts`` and the sub-second counter is reset.

Sub-second time
---------------

A 29-bit counter running at 200 MHz provides 10 ns resolution within the current second (``ss`` field). The ``recent`` flag in the output record is cleared when the counter saturates (no valid frame received for >2.7 s) or when the selected source or polarity changes, allowing downstream logic to detect a loss of valid time.


UDP Control Memory Map
======================

There are no memory-mapped registers in this module
.. .. include-docs
..     :start-after: Function Generator Memory Map

