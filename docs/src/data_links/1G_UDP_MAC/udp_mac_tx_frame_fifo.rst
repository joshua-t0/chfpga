.. title:: udp_mac_tx_frame_fifo

.. _udp-mac-tx-frame-fifo-xil-module:

UDP Mac Tx Frame FIFO
*********************

.. note::

   This page documents the legacy **Xilinx FIFO Generator IP** configuration that was used
   before the unified :doc:`../../utils/generic_fifo` wrapper was introduced. The current
   implementation of :doc:`udp_mac_tx` instantiates ``generic_fifo`` directly (18-bit wide,
   128 words deep, asynchronous standard mode, distributed RAM) for frame-length and
   channel-selector storage. The screenshots below describe the corresponding FIFO Generator
   wizard settings for reference.

.. image:: ../../images/xilinx_modules/udp_mac_tx_frame_fifo.png
    :width: 25%

Basic
=====

.. image:: ../../images/xilinx_modules/udp_mac_tx_frame_fifo1.png
    :width: 100%

Native Ports
============

.. image:: ../../images/xilinx_modules/udp_mac_tx_frame_fifo2.png
	:width: 100%

Status Flags
============

.. image:: ../../images/xilinx_modules/udp_mac_tx_frame_fifo3.png
	:width: 100%

Data Counts
===========

.. image:: ../../images/xilinx_modules/udp_mac_tx_frame_fifo4.png
	:width: 100%

Summary
=======

.. image:: ../../images/xilinx_modules/udp_mac_tx_frame_fifo5.png
	:width: 100%

Parameters
==========

These are the key FIFO Generator configuration choices reflected in the screenshots (for the current ``generic_fifo`` replacement, see :doc:`../../utils/generic_fifo`):

- **FIFO implementation:** Independent-clock (asynchronous) distributed RAM FIFO.
- **Data width:** 18 bits (``din(15:0)`` / ``dout(15:0)`` = 16-bit UDP payload byte count; ``din(17:16)`` / ``dout(17:16)`` = 2-bit channel/port-offset selector).
- **Depth:** 128 words (one entry per in-flight frame).
- **Read mode:** Standard (not FWFT); the TX state machine issues a read and waits one clock for ``dout`` to be valid.
- **Clock domains:** Write side driven by the user ``s_axis_udp_tx_clk``; read side driven by the GMII transmit clock (~125 MHz).
- **Status flags:** ``full``, ``almost_full``, ``empty``, ``overflow``.

Interface
=========

Write side (user clock domain)
-------------------------------

- ``wr_clk``: User TX clock.
- ``rst``: Asynchronous active-high reset.
- ``din(15:0)``: UDP payload byte count (frame length) captured at ``tlast``.
- ``din(17:16)``: 2-bit channel/port-offset selector from ``tuser``.
- ``wr_en``: Asserted for one cycle on the last byte of each incoming frame.
- ``full``: Asserted when the frame FIFO is full (used together with ``data_fifo`` ``full`` to deassert ``s_axis_udp_tx_tready``).
- ``almost_full``: Programmable fill threshold; also used for back-pressure.

Read side (GMII clock domain)
------------------------------

- ``rd_clk``: GMII transmit clock (~125 MHz).
- ``rd_en``: Asserted by the TX state machine to pop a frame-length entry.
- ``dout(15:0)``: Frame byte count read by the TX state machine for IP/UDP length fields.
- ``dout(17:16)``: Channel selector for UDP port selection.
- ``empty``: Asserted when no complete frame is pending; the TX state machine waits in standby while ``empty`` is high.

Implementation details
======================

Principle of operations
-----------------------

One entry is committed to the frame FIFO per outgoing UDP frame: the front-end logic counts incoming bytes on the user clock and writes a single 18-bit word (byte count + channel selector) on ``tlast``. The TX state machine on the GMII side polls ``empty``; when a frame is available it reads the frame metadata, uses the byte count to populate the IP and UDP length fields in the Ethernet header, and then drains the payload from the data FIFO byte by byte. The shallow depth (128 entries) is sufficient because each entry corresponds to an entire UDP frame, and the 16 384-byte data FIFO depth limits the number of concurrently buffered frames to well below 128 for any practical payload size.
