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

Wide autocorrelations
---------------------

With ``WIDE_AUTOCORR`` = TRUE, the CMACs that compute an autocorrelation (the first CMAC of each group of ``AUTOCORR_STRIDE``, except in the last group) accumulate it as a 36-bit unsigned number. The imaginary part of an autocorrelation is always zero, so its 18 bits in the RAM word and in the result record are free: the 18 LSBs of the sum are where the real part is (bits 35:18 of the 40-bit product), and the 18 MSBs are where the imaginary part is (bits 17:0). A sum below 2^17 has the same bytes as without this option. The DSP adds only the 18 LSBs, in the field of the real part, where its arithmetic is correct modulo 2^18. The 18 MSBs are a counter beside the DSP: the power of a frame is not negative and is less than 2^17, so the 18 LSBs pass 2^18 one time at most in a frame, and the counter then goes up by one. These products have no saturation, and their two saturation flags are always zero. The other products do not change: 18 + 18 bits with saturation and flags.

A full-scale input (-7 - 7j) gives 98 for each frame, so an integration of 32768 frames gives 3211264: 22 bits.

The option is correct only if a CMAC always has the same pair of inputs (one clock for each bin, as in corr8); ``UCORR44`` enables it only then. ``UCORR44_ARRAY`` reports it in bit 6 of status byte 5.

Clocking
--------

All DSPs, RAM blocks, control logic, and readout logic share the single ``clk`` clock. There is no separate control clock; the ``rst`` synchronous reset is pipelined through a one-stage register (``rst_reg``) before qualifying the main state machine to ease timing closure.
