.. title:: xgmii_udp_mac_tx_header_fifo

XGMII UDP MAC Header Data FIFO
*******************************

.. _xgmii-udp-mac-tx-header-fifo-xil-module:

Overview
========

This is a **Xilinx FIFO Generator IP** core used inside `xge_udp_mac_tx` to store per-frame metadata (packet length) across the clock domain boundary between the user ``s_axis_tx_clk`` and the 10G link transmit ``clk``. It is a narrow, shallow **asynchronous** FWFT FIFO: one entry is written per frame (on the last payload word) and read by the TX state machine when it is ready to emit the IP/UDP length fields into the Ethernet frame header.

The following screenshots show the IP core configuration as set in Vivado.

.. image:: ../../images/xilinx_modules/xgmii_udp_mac_tx_header_fifo.png
    :width: 25%

Basic
=====

.. image:: ../../images/xilinx_modules/xgmii_udp_mac_tx_header_fifo1.png
    :width: 100%

Native Ports
============

.. image:: ../../images/xilinx_modules/xgmii_udp_mac_tx_header_fifo2.png
	:width: 100%

Status Flags
============

.. image:: ../../images/xilinx_modules/xgmii_udp_mac_tx_header_fifo3.png
	:width: 100%

Data Counts
===========

.. image:: ../../images/xilinx_modules/xgmii_udp_mac_tx_header_fifo4.png
	:width: 100%

Summary
=======

.. image:: ../../images/xilinx_modules/xgmii_udp_mac_tx_header_fifo5.png
	:width: 100%

Parameters
==========

These are the key FIFO Generator configuration choices (see the Vivado screenshots below for the full settings):

- **FIFO implementation:** Independent-clock (asynchronous) FIFO (distributed RAM).
- **Data width:** 18 bits (``din(15:0)`` / ``dout(15:0)`` = 16-bit UDP payload byte count; ``din(17:16)`` / ``dout(17:16)`` = 2-bit channel/port-offset selector).
- **Depth:** Shallow (one entry per in-flight frame).
- **Read mode:** First-Word Fall-Through (FWFT).
- **Clock domains:** Write side driven by ``s_axis_tx_clk`` (user TX clock); read side driven by ``clk`` (XGMII transmit clock).
- **Status flags:** ``overflow``, ``valid``.

Interface
=========

Write side (``s_axis_tx_clk`` domain)
--------------------------------------

- ``rst``: Asynchronous active-high reset (shared).
- ``wr_clk``: Write clock, sourced from the user ``s_axis_tx_clk``.
- ``din(15:0)``: UDP payload byte count (frame length) captured at the end of each incoming user frame (``tlast``).
- ``din(17:16)``: 2-bit channel/port-offset selector, latched from the last valid ``tuser`` word of the frame.
- ``wr_en``: Asserted for one cycle on the last word of each incoming frame to commit the frame metadata.

Read side (``clk`` domain)
---------------------------

- ``rd_clk``: Read clock, sourced from the XGMII transmit ``clk``.
- ``rd_en``: Asserted by the TX state machine when it has consumed the header and is ready to start transmitting the next frame's payload.
- ``dout(15:0)``: Frame byte count presented to the TX state machine for IP/UDP length field insertion.
- ``dout(17:16)``: Channel selector used to choose the destination UDP port.
- ``valid``: Asserted when ``dout`` holds valid FWFT data (i.e. at least one complete frame is buffered).
- ``overflow``: Asserted for one clock when a write is attempted while the FIFO is full.

Implementation details
======================

Principle of operations
-----------------------

One entry is written to the header FIFO per frame: the front-end logic accumulates the incoming byte count while the frame is being written into ``XGMII_UDP_MAC_TX_DATA_FIFO``, then commits a single 18-bit word (length + channel) on ``tlast``. The TX state machine on the ``clk`` side polls the ``valid`` flag before starting a new frame; once valid, it reads ``dout`` to obtain the IP/UDP length fields and the destination port, and then reads the payload from the data FIFO word by word. This two-FIFO arrangement guarantees that the TX state machine always knows the complete frame length before it begins emitting the IP/UDP header, avoiding the need for a multi-pass transmit path.

