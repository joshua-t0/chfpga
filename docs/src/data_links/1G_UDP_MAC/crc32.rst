.. title:: crc32

*************************************************************************
:entity:`udp_mac_crc32` (*udp_mac_crc32.vhd*): Ethernet CRC32 Computation
*************************************************************************

.. parse:: hdl/data_links/1G_UDP_MAC/udp_mac_crc32.vhd

.. default-role:: vhdl:entity

Overview
========

`udp_mac_crc32` is a pipelined **Ethernet CRC-32** engine that operates one byte at a time.
It is used by both `udp_mac_tx` and `udp_mac_rx` to compute and verify the 32-bit frame check
sequence (FCS) mandated by the IEEE 802.3 standard. The polynomial is the standard Ethernet
CRC-32 (0x04C11DB7). The implementation is a VHDL translation of the Verilog example design
provided with the Xilinx SP605 evaluation board.

Entity documentation
====================

.. autoentity:: udp_mac_crc32

Parameters
==========

This entity has no configurable generic parameters.

Interface
=========

- ``clk``: Clock. All registers are updated on the rising edge.

- ``reset``: Synchronous reset. Clears the CRC shift register to the initial value 0xFFFFFFFF.

- ``init``: Initialize (clear) the CRC register to 0xFFFFFFFF on the next rising edge. Assert
  before starting a new frame.

- ``d``: 8-bit input data byte to include in the CRC.

- ``calc``: CRC computation enable. When asserted together with ``d_valid``, the combinatorial
  next-CRC result is loaded into the shift register. When deasserted with ``d_valid`` active,
  the register is shifted left by one byte to clock out the CRC bytes sequentially.

- ``d_valid``: Input data valid. Qualifies both the ``calc`` and byte-shift modes.

- ``crc``: 8-bit CRC output byte. Outputs the four Ethernet FCS bytes sequentially (MSB-first,
  bit-reversed as required by IEEE 802.3) when ``d_valid`` is asserted after ``calc`` is
  deasserted.

- ``crc_reg``: Full 32-bit internal CRC accumulator, exposed for diagnostics.

Implementation details
======================

Architecture
------------

The CRC is computed every clock cycle using a fully-expanded combinatorial XOR network
(``next_crc``) derived from the Ethernet CRC-32 polynomial. The result is registered on each
rising edge when both ``calc`` and ``d_valid`` are asserted. After the last payload byte,
deasserting ``calc`` while keeping ``d_valid`` high shifts the 32-bit register left one byte
per cycle, presenting each FCS byte in order on ``crc``.

Clocking
--------

Single clock ``clk``. All internal state is registered on the rising edge. There are no
asynchronous paths.

Principle of operations
-----------------------

Assert ``init`` (and optionally ``reset``) for one cycle to clear the accumulator. Then assert
``calc`` and ``d_valid`` for each byte of the Ethernet frame (destination MAC through last
payload byte, excluding preamble/SFD and the four FCS bytes). After the final data byte,
deassert ``calc`` and keep ``d_valid`` high for four cycles to clock out the four FCS bytes
on ``crc`` in the bit-reversed, byte-reversed order required by the standard. Both
`udp_mac_rx` and `udp_mac_tx` use this engine in this way, albeit with a 4-cycle delay line
to separate data bytes from the appended FCS bytes on reception.
