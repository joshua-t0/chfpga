.. title:: udp_mac_tx_data_fifo

.. _udp-mac-tx-data-fifo-xil-module:

UDP Mac Tx Data FIFO
********************

.. note::

   This page documents the legacy **Xilinx FIFO Generator IP** configuration that was used
   before the unified :doc:`../../utils/generic_fifo` wrapper was introduced. The current
   implementation of :doc:`udp_mac_tx` instantiates ``generic_fifo`` directly (9-bit wide,
   16384 words deep, asynchronous first-word fall-through, embedded FIFO primitive). The
   screenshots below describe the corresponding FIFO Generator wizard settings for reference.

.. image:: ../../images/xilinx_modules/udp_mac_tx_data_fifo.png
    :width: 25%

Basic
=====

.. image:: ../../images/xilinx_modules/udp_mac_tx_data_fifo1.png
    :width: 100%

Native Ports
============

.. image:: ../../images/xilinx_modules/udp_mac_tx_data_fifo2.png
	:width: 100%

Status Flags
============

.. image:: ../../images/xilinx_modules/udp_mac_tx_data_fifo3.png
	:width: 100%

Data Counts
===========

.. image:: ../../images/xilinx_modules/udp_mac_tx_data_fifo4.png
	:width: 100%

Summary
=======

.. image:: ../../images/xilinx_modules/udp_mac_tx_data_fifo5.png
	:width: 100%

Parameters
==========

These are the key FIFO Generator configuration choices reflected in the screenshots (for the current ``generic_fifo`` replacement, see :doc:`../../utils/generic_fifo`):

- **FIFO implementation:** Independent-clock (asynchronous) embedded FIFO primitive (FIFO18/FIFO36).
- **Data width:** 9 bits (8-bit payload byte + 1-bit ``tlast`` / end-of-frame flag).
- **Depth:** 16 384 words (sufficient to hold multiple maximum-sized UDP frames at byte granularity).
- **Read mode:** First-Word Fall-Through (FWFT).
- **Clock domains:** Write side driven by the user ``s_axis_udp_tx_clk``; read side driven by the GMII transmit clock (~125 MHz).
- **Status flags:** ``full``, ``empty``, ``overflow``, ``valid``.

Interface
=========

Write side (user clock domain)
-------------------------------

- ``wr_clk``: User TX clock.
- ``rst``: Asynchronous active-high reset.
- ``din(8)``: End-of-frame flag (``tlast``) packed into the MSB.
- ``din(7:0)``: 8-bit user payload byte.
- ``wr_en``: Write enable; driven by the TX front-end when ``s_axis_udp_tx_tvalid`` is asserted.
- ``full``: Asserted when the FIFO cannot accept more data.

Read side (GMII clock domain)
------------------------------

- ``rd_clk``: GMII transmit clock (~125 MHz).
- ``rd_en``: Read enable, driven by the TX state machine.
- ``dout(8)``: End-of-frame flag at the head of the FIFO.
- ``dout(7:0)``: Payload byte at the head of the FIFO.
- ``valid``: Asserted when ``dout`` holds valid FWFT data.
- ``empty``: Asserted when the FIFO is empty.

Implementation details
======================

Principle of operations
-----------------------

The TX data FIFO bridges the user byte-stream clock to the GMII transmit clock. The user writes one byte per clock (plus the ``tlast`` flag on the last byte of each UDP payload). The TX state machine on the GMII side reads bytes individually while constructing the Ethernet/IP/UDP header, then drains the FIFO byte by byte for the payload. The large depth (16 384 bytes) ensures that back-pressure from the GMII side (e.g. inter-frame gaps or header insertion delays) does not stall the upstream user logic during normal operation. The companion frame FIFO (``udp_mac_tx_frame_fifo``) provides the frame length before the TX state machine begins reading the payload.
