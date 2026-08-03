.. title:: xxvglink_rx

*******************************************************************
:entity:`xxvglink_rx` (*xxvglink_rx.vhd*): 25G Serial Link Receiver
*******************************************************************

.. parse:: hdl/data_links/XXVGLINK/xxvglink_rx.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: xxvglink_rx

Parameters
==========

None — this entity has no generic parameters.

Interface
=========

GTY-side inputs (``rx_clk``)
-----------------------------

- ``rx_data``: 64-bit word from the GTY receiver. The most-significant byte arrives first (big-endian).

- ``rx_data_valid``: Asserted by the GTY gearbox when ``rx_data`` contains valid data.

- ``rx_header``: 2-bit 64B/66B block header: ``01`` for data block, ``10`` for ordered-set/control block.

- ``rx_header_valid``: Asserted when ``rx_header`` is valid (first half of each block).

- ``rx_clk``: Recovered GTY RX word clock. The depacketizer state machine runs on this clock.

User-side output (``m_axis_rx_clk``)
--------------------------------------

- ``m_axis_rx_tdata``: 64-bit received payload word. Big-endian byte order matches the link.

- ``m_axis_rx_tvalid``: Asserted for each valid payload word (non-blocking; driven by FIFO non-empty).

- ``m_axis_rx_tlast``: Asserted on the last payload word of a packet (CRC word is not forwarded).

- ``m_axis_rx_tready``: Flow-control input. When deasserted, the FIFO output is held.

- ``m_axis_rx_terror``: Asserted coincident with ``tlast`` if a CRC mismatch or framing error was detected.

- ``m_axis_rx_clk``: Clock for the user AXIS bus. May differ from ``rx_clk``; the asynchronous FIFO bridges the two domains.

Monitoring (``rx_clk``)
------------------------

- ``fifo_overflow``: Asserted for one clock on ``m_axis_rx_clk`` when the asynchronous RX FIFO overflows (data loss).

- ``fifo_in_tvalid``: Mirrors the valid signal of words entering the RX FIFO, on ``rx_clk``. Used by `xxvglink_array` for monitoring.

- ``fifo_in_tlast``: Mirrors the last-word signal of words entering the RX FIFO, on ``rx_clk``.

- ``fifo_in_terror``: Mirrors the error signal of words entering the RX FIFO, on ``rx_clk``.

Reset
-----

- ``arst``: Asynchronous active-high reset.

Implementation details
======================

Principle of operations
-----------------------

`xxvglink_rx` implements a lightweight two-state machine (``RX_STATE_SOF`` and ``RX_STATE_DATA``) on the GTY recovered clock. It waits for a Start-of-Frame ordered-set control block (header ``10``, SOF code), then streams payload words (header ``01``) into an asynchronous `xxvglink_data_fifo`. On reception of an End-of-Frame control block, the last payload word is tagged with ``tlast``. The CRC32 word (the word immediately before the EOF block) is consumed internally by a `crc32_64` instance and not forwarded to the user; ``terror`` is asserted if the computed CRC does not match. The asynchronous FIFO bridges the recovered RX word clock and the user ``m_axis_rx_clk``.

