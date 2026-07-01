.. title:: irigb_encoder

***********************************************************************
:entity:`irigb_encoder` (*irigb_encoder.vhd*): IRIG-B Time Code Encoder
***********************************************************************

.. parse:: hdl/system/irigb_encoder.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: irigb_encoder

Parameters
==========

This module has no generic parameters.

Interface
=========

- ``clk_200mhz``: 200 MHz clock. All logic is synchronous to this clock.
- ``ts_out``: IRIG-B modulated output signal. Pulse widths encode bit values: 2 ms high = ``0`` bit, 5 ms high = ``1`` bit, 8 ms high = position marker P.

Implementation details
======================

Principle of operations
-----------------------

The encoder maintains an autonomous free-running time base starting from a fixed epoch (day 1, 00:00:00, year 0). Time resolution is 1 ms, derived from a 200 000-cycle counter on ``clk_200mhz`` that generates a 1 ms tick strobe. A ``ms`` counter (0–9) tracks the millisecond position within each 10 ms bit slot, and an ``index`` counter (0–99) selects the current slot within the one-second frame. The encoder does not accept external time input; it free-runs from power-on.

Architecture
------------

Time is maintained in BCD digit registers: ``sec1`` / ``sec10``, ``min1`` / ``min10``, ``hour1`` / ``hour10``, ``day1`` / ``day10`` / ``day100``, ``year1`` / ``year10``, and a 17-bit binary sub-second counter ``sbs`` (0–86 399). A ``case`` statement on ``index`` maps each slot to its source bit (BCD digit or ``sbs`` bit) or to a position marker. Three constants control the output high-time: ``L0`` = 2 ms (bit '0'), ``L1`` = 5 ms (bit '1'), ``LP`` = 8 ms (position marker P). The output is registered by one additional pipeline stage, so ``ts_out`` lags the internal logic by one clock cycle.

Clocking
--------

All logic is synchronous to a single clock: ``clk_200mhz`` (200 MHz). There are no clock-domain crossings.

Principle of Operations
=======================

The ``irigb_encoder`` module generates IRIG-B time code signals. IRIG-B is a standard time code format used for time synchronization in industrial and scientific applications. The module generates a serial output signal (``ts_out``) that encodes time information according to the IRIG-B standard.

The encoder operates at 200 MHz and generates time codes with proper pulse widths and encoding for seconds, minutes, hours, day of year, and year information.

Key Features
------------

- **IRIG-B compliant**: Generates standard IRIG-B time code format
- **200 MHz operation**: Operates at 200 MHz clock frequency
- **Time encoding**: Encodes seconds, minutes, hours, day of year, and year
- **Pulse width encoding**: Uses different pulse widths (L0, L1) to encode binary data

Usage
-----

The ``irigb_encoder`` is used in systems that need to generate IRIG-B time code signals for time synchronization purposes. It is typically used in conjunction with the :entity:`irigb_comparator` module for time-based event triggering.

