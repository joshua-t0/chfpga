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

UltraRAM-backed MAC array companion to ``UCORR44``: stores partial sums efficiently for large correlator instantiations.
