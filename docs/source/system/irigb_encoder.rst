.. title:: irigb_encoder

***********************************************************************
:entity:`irigb_encoder` (*irigb_encoder.vhd*): IRIG-B Time Code Encoder
***********************************************************************

.. parse:: hdl/system/irigb_encoder.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: irigb_encoder

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

