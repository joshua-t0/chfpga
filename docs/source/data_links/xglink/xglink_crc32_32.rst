.. title:: xglink_crc32_32

****************************************************************************
:entity:`xglink_crc32_32` (*xglink_crc32_32.vhd*): CRC-32 Computation Module
****************************************************************************

.. parse:: hdl/data_links/XGLINK/xglink_crc32_32.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: xglink_crc32_32

Parameters
==========

No generic parameters.

Interface
=========

Data
----

- ``data_in``: 32-bit input word. Bit 0 is treated as the first bit to be transmitted (LSB-first convention matching the CRC-32 polynomial evaluation order).

- ``crc_out``: 32-bit registered CRC output. Updated one clock cycle after ``crc_en`` is asserted. Contains the running CRC over all words fed since the last reset.

- ``crc_out_comb``: 32-bit combinatorial CRC output. Available in the same clock cycle as ``data_in`` but with longer combinatorial delay than ``crc_out``.

Control
-------

- ``crc_en``: CRC enable. When ``'1'``, the input word is incorporated into the running CRC on the next rising edge of ``clk``. When ``'0'``, the register holds its current value.

- ``rst``: Synchronous reset. Initialises the LFSR to all-ones (``X"FFFFFFFF"``), which is the standard CRC-32 initial value.

- ``clk``: Clock.

Implementation details
======================

Principle of operations
-----------------------

The CRC is computed using the standard Ethernet CRC-32 polynomial:

.. math::

   G(x) = 1 + x + x^2 + x^4 + x^5 + x^7 + x^8 + x^{10} + x^{11} + x^{12} + x^{16} + x^{22} + x^{23} + x^{26} + x^{32}

The combinatorial LFSR equations ``lfsr_c`` are computed from both the current register state ``lfsr_q`` and ``data_in`` in a single combinatorial stage, processing all 32 bits in parallel. The registered output ``lfsr_q`` is updated on the rising edge of ``clk`` when ``crc_en='1'`` or held otherwise.

The module is used in both `xglink_tx` (CRC appended to outgoing frames) and `xglink_rx` (CRC verified on incoming frames). After feeding the payload words, the transmitter reads ``crc_out`` and appends it. The receiver checks that the final CRC over payload plus received CRC equals the expected residue; any mismatch asserts ``m_axis_rx_terror``.
