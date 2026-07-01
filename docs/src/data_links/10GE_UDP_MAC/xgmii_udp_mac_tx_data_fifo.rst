.. title:: xgmii_udp_mac_tx_data_fifo

XGMII UDP MAC Tx Data FIFO
**************************

.. _xgmii-udp-mac-tx-data-fifo-xil-module:

Overview
========

This is a **Xilinx FIFO Generator IP** core used inside `xge_udp_mac_tx` to buffer payload data across the clock domain boundary between the user ``s_axis_tx_clk`` and the 10G link transmit ``clk``. It is an **asynchronous** (independent-clock) FWFT FIFO with a **32-bit** data path and sufficient depth to absorb burst traffic while the transmitter is busy emitting Ethernet/IP/UDP headers.

The following screenshots show the IP core configuration as set in Vivado.

.. image:: ../../images/xilinx_modules/xgmii_udp_mac_tx_data_fifo.png
    :width: 25%

Basic
=====

.. image:: ../../images/xilinx_modules/xgmii_udp_mac_tx_data_fifo1.png
    :width: 100%

Native Ports
============

.. image:: ../../images/xilinx_modules/xgmii_udp_mac_tx_data_fifo2.png
	:width: 100%

Status Flags
============

.. image:: ../../images/xilinx_modules/xgmii_udp_mac_tx_data_fifo3.png
	:width: 100%

Data Counts
===========

.. image:: ../../images/xilinx_modules/xgmii_udp_mac_tx_data_fifo4.png
	:width: 100%

.. Summary
.. =======

.. .. image:: ../../images/xilinx_modules/xgmii_udp_mac_tx_data_fifo5.png
.. 	:width: 100%

Parameters
==========

These are the key FIFO Generator configuration choices (see the Vivado screenshots below for the full settings):

- **FIFO implementation:** Independent-clock (asynchronous) BRAM FIFO.
- **Data width:** 33 bits (``din(32)`` / ``dout(32)`` = ``tlast`` / end-of-frame flag; ``din(31:0)`` / ``dout(31:0)`` = 32-bit payload word).
- **Read mode:** First-Word Fall-Through (FWFT).
- **Clock domains:** Write side driven by ``s_axis_tx_clk`` (user TX clock); read side driven by ``clk`` (XGMII transmit clock, ~156.25 MHz).
- **Status flags:** ``overflow``, ``valid``.

Interface
=========

Write side (``s_axis_tx_clk`` domain)
--------------------------------------

- ``rst``: Asynchronous active-high reset (shared).
- ``wr_clk``: Write clock, sourced from the user ``s_axis_tx_clk``.
- ``din(32)``: End-of-frame flag (``tlast``) packed into the MSB.
- ``din(31:0)``: 32-bit user payload word.
- ``wr_en``: Write enable; driven by the front-end logic when ``s_axis_tx_tvalid`` is asserted.

Read side (``clk`` domain)
---------------------------

- ``rd_clk``: Read clock, sourced from the XGMII transmit ``clk``.
- ``rd_en``: Read enable; qualified with the XGMII ``tx_ready`` signal so words are consumed only when the link accepts them.
- ``dout(32)``: End-of-frame flag at the head of the FIFO.
- ``dout(31:0)``: Payload word at the head of the FIFO.
- ``valid``: Asserted when ``dout`` holds valid FWFT data.
- ``overflow``: Asserted for one clock when a write is attempted while the FIFO is full.

Implementation details
======================

Principle of operations
-----------------------

The data FIFO bridges the user transmit clock (``s_axis_tx_clk``) to the XGMII link clock (``clk``). User payload data and the associated end-of-frame flag are written into the FIFO on every clock cycle where ``s_axis_tx_tvalid`` is high. The TX state machine on the ``clk`` side reads words from the FIFO only when ``tx_ready`` is asserted (the XGMII gearbox back-pressure), pacing reads to match the link bandwidth. A separate ``XGMII_UDP_MAC_TX_HEADER_FIFO`` provides the IP/UDP header length information needed before the TX state machine can start emitting the Ethernet frame.
