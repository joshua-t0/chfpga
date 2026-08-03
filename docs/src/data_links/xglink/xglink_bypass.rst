.. title:: xglink_bypass

**************************************************************************
:entity:`xglink_bypass` (*xglink_bypass.vhd*): 10G Serial Link Bypass Mode
**************************************************************************

.. parse:: hdl/data_links/XGLINK/xglink_bypass.vhd

.. default-role:: vhdl:entity

Overview
========

`xglink_bypass` replaces the GTX transceiver and `xglink_core` with a **direct internal loopback** for simulation or loopback testing. It routes the TX AXI-Stream input back to the RX AXI-Stream output through a pair of synchronous FIFOs, inserting a read-throttle that mimics the 2-cycle overhead of the 64/66B gearbox.

Entity documentation
--------------------

.. autoentity:: xglink_bypass

Parameters
==========

No generic parameters.

Interface
=========

TX input (non-blocking)
-----------------------

- ``s_axis_tx_tdata``: 32-bit TX data. First transmitted byte is the MSB.

- ``s_axis_tx_tvalid``: TX data valid. No handshake; data is written unconditionally to the TX FIFO.

- ``s_axis_tx_tlast``: End-of-frame indicator on the TX path.

RX output (non-blocking)
-------------------------

- ``m_axis_rx_tdata``: 32-bit RX loopback data.

- ``m_axis_rx_tvalid``: RX data valid.

- ``m_axis_rx_tlast``: End-of-frame indicator on the RX path.

- ``m_axis_rx_terror``: Frame error flag; always ``'0'`` for a direct internal link.

Statistics and diagnostics
---------------------------

- ``reset_stats``: Resets the frame-size and overflow statistics counters (synchronous).

- ``tx_fifo_overflow``: TX FIFO overflow flag. Non-sticky; reflects the instantaneous overflow condition.

- ``rx_fifo_overflow``: RX FIFO overflow flag. Asserted when the RX FIFO is full or the slave-ready is deasserted.

- ``rx_frame_detect``: Pulsed for one clock cycle each time a complete frame is received.

- ``rx_err_ctr``: 16-bit error counter; always zero for a direct internal link.

- ``rx_max_frame``: Maximum received frame size in 32-bit words (13 bits, max 8191). Cleared by ``reset_stats``.

- ``rx_min_frame``: Minimum received frame size in 32-bit words. Cleared by ``reset_stats``.

Clock and reset
---------------

- ``clk``: Single clock domain used for both TX and RX paths.

- ``rst``: Asynchronous reset.

Implementation details
======================

Architecture
------------

The module contains two FIFOs:

- A TX data FIFO (:doc:`xglink_tx_data_fifo`, synchronous BRAM-based, 512 × 33 bits) accepts data from the user TX interface.
- An RX data FIFO (:doc:`xglink_rx_data_fifo`, AXI4-Stream, synchronous) provides data to the user RX interface with ``tready='1'`` (non-blocking output).

Principle of operations
-----------------------

A 7-bit counter cycles from 0 to 65 (i.e. 66 clock periods) to replicate the 64B/66B gearbox timing: the TX FIFO read-enable is deasserted for 2 cycles out of every 66, throttling throughput to the same average rate as the GTX serializer. This allows the rest of the data-link logic to be validated without a real transceiver.

Frame-size statistics are maintained in the RX path: ``rx_word_ctr`` counts 32-bit words per frame, and ``rx_max_frame`` / ``rx_min_frame`` are updated on each ``tlast``. Both are reset by ``reset_stats`` or ``rst``.
