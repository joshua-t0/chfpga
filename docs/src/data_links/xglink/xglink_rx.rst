.. title:: xglink_rx

***************************************************************
:entity:`xglink_rx` (*xglink_rx.vhd*): 10G Serial Link Receiver
***************************************************************


.. toctree::
   :hidden:

   xglink_rx_data_fifo
   xglink_crc32_32
   ../../navbar_separator

.. parse:: hdl/data_links/XGLINK/xglink_rx.vhd

.. default-role:: vhdl:entity

Overview
========

`xglink_rx` **depacketizes** 64B/66B data blocks arriving from `xglink_core` into a **non-blocking 32-bit AXI-Stream**. It detects start-of-frame and end-of-frame control codes, strips the framing, verifies the trailing CRC-32 (`xglink_crc32_32`), and bridges the GTX recovered clock domain to the user AXI-Stream clock through an asynchronous FIFO (:doc:`xglink_rx_data_fifo`). An error flag is asserted on the last word of any frame with a bad CRC or unexpected framing.

Entity documentation
--------------------

.. autoentity:: xglink_rx

Parameters
==========

No generic parameters.

Interface
=========

GTX-side interface (``rx_clk``)
--------------------------------

- ``rx_data``: 32-bit data word from the GTX gearbox / `xglink_core` descrambler output.

- ``rx_data_valid``: Valid strobe accompanying ``rx_data``.

- ``rx_header``: 2-bit 64B/66B sync header. ``"01"`` indicates a data block; ``"10"`` indicates a control block.

- ``rx_header_valid``: Valid strobe for ``rx_header`` (asserted on the first half of each 66-bit block).

- ``rx_clk``: Recovered RX word clock from the GTX (driven by ``rxoutclk`` routed through a buffer).

User AXI-Stream interface (``m_axis_rx_clk``)
----------------------------------------------

- ``m_axis_rx_tdata``: 32-bit received data. First byte on the wire appears in the MSB.

- ``m_axis_rx_tvalid``: Data-valid output. Non-blocking; the downstream user must always be ready to consume data.

- ``m_axis_rx_tlast``: End-of-frame indicator. Asserted on the last payload word of each received frame.

- ``m_axis_rx_tready``: Back-pressure input (default ``'1'``). Connects to the RX FIFO read-enable.

- ``m_axis_rx_terror``: Frame-error flag. Asserted simultaneously with ``tlast`` when the CRC check fails or a framing error is detected.

- ``m_axis_rx_clk``: User-side clock for the AXI-Stream output. Typically driven by ``clk_out`` from `xglink_core`.

Statistics (``rx_clk``)
------------------------

- ``reset_stats``: Resets the frame-size counters and ``rx_err_ctr`` (synchronous to ``rx_clk``).

- ``rx_fifo_overflow``: Non-sticky FIFO overflow flag. Asserted when the asynchronous FIFO is full and incoming data is lost.

- ``rx_frame_detect``: Pulsed for one clock cycle (on ``rx_clk``) each time a complete frame boundary is detected.

- ``rx_err_ctr``: 16-bit saturating counter incremented each time a frame ends with ``m_axis_rx_terror='1'``.

- ``rx_max_frame``: 13-bit maximum observed frame size in 32-bit words (max 8191). Updated on each ``tlast``; reset by ``reset_stats``.

- ``rx_min_frame``: 13-bit minimum observed frame size in 32-bit words. Updated on each ``tlast``; reset by ``reset_stats``.

System
------

- ``rst``: Asynchronous reset.

Implementation details
======================

Architecture
------------

The receiver contains:

- A CRC-32 engine (`xglink_crc32_32`) clocked by ``rx_clk`` that computes the running CRC over all received payload words.
- A two-stage pipeline that delays data by one word so the CRC word can be stripped before presentation to the user.
- An asynchronous RX FIFO (:doc:`xglink_rx_data_fifo`) bridging the ``rx_clk`` domain to the user ``m_axis_rx_clk`` domain.

Principle of operations
-----------------------

The RX state machine cycles through ``SOF0 → SOF1 → DATA0 → DATA_IDLE1 → CRC_EOF1`` states. It searches for a start-of-frame (SOF) control code in the 64B/66B header, then passes payload words downstream while accumulating the CRC. When an end-of-frame (EOF) code is detected, the state machine compares the last received word against the expected CRC residue. A mismatch asserts ``m_axis_rx_terror`` on the final output word.

The receiver assumes no IDLE words are inserted between the last payload word and the CRC or between the CRC and the EOF code.

Byte order matches the transmitter: the MSB of each 32-bit word is the first byte on the wire (big-endian).
