.. title:: ucmac44_array

************************************************************************
:entity:`UCMAC44_ARRAY` (*UCMAC44_ARRAY.vhd*): UltraRAM-based CMAC Array
************************************************************************

.. parse:: hdl/corr/UCMAC44_ARRAY.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: UCMAC44_ARRAY

Parameters
==========

UltraRAM and DSP sizing per MAC bank — see entity.

Interface
=========

- Vector product inputs from ``UCORR44``.

- Wide accumulator outputs / read ports.

Principle of operations
=======================

UltraRAM-backed MAC array companion to ``UCORR44``: stores partial sums efficiently for large correlator instantiations. On each valid input clock cycle the module computes ``NCMAC`` independent (4+4)-bit complex products Z = X·Y* and adds each result to its running (18+18)-bit accumulator stored in RAM. After ``integ_period`` frames the accumulator bank is swapped and the completed sums are streamed out byte-by-byte; the output is daisy-chained so that multiple instances can be cascaded with only local routing.

Implementation details
======================

Architecture
------------

Each of the ``NCMAC`` complex multiply-accumulate paths uses two cascaded ``DSP48E1`` primitives. The first DSP computes the partial products (ac, ad+bc, bd) of the sign-corrected inputs in a single multiplier cycle, encoding them into disjoint bit fields of the 48-bit P output. The second DSP adds these partial products to the previously accumulated sum fetched from RAM. Overflow is detected using guard bits between the real and imaginary fields, and the result is saturated combinatorially in fabric before being written back. Every pair of CMACs shares one ``xpm_memory_sdpram`` block (72-bit data: 36 bits per CMAC) configured as UltraRAM (``MEMORY_PRIMITIVE=ultra``) for up to ``URAM_MAX`` pairs and as Block RAM for the remainder, giving a 2-clock read latency that matches the DSP pipeline depth. Two memory banks are maintained: one actively accumulating and one being read out; banks are exchanged at the end of each integration period. Readout is controlled by a byte-shift register that serialises the 5-byte-per-product word stream; a ``send`` handshake propagates through the daisy chain to allow downstream modules to gate the flow.

Clocking
--------

All DSPs, RAM blocks, control logic, and readout logic share the single ``clk`` clock. There is no separate control clock; the ``rst`` synchronous reset is pipelined through a one-stage register (``rst_reg``) before qualifying the main state machine to ease timing closure.
