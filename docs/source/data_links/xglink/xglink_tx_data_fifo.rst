.. _xglink-tx-data-fifo-xil-module:

Xglink Tx Data FIFO
*******************

Overview
========

This is a **Xilinx FIFO Generator** IP core used inside ``xglink_bypass`` as the transmit-side data buffer. It is a synchronous, First-Word Fall-Through (FWFT) FIFO with a **33-bit** data path (32-bit payload plus 1 ``tlast`` bit packed into the MSB). It is implemented in BRAM with an embedded output register so that the effective read latency seen by the consumer is zero, which is required by the 64/66B gearbox timing.

The following screenshots show the IP core configuration as set in Vivado.

.. image:: ../../images/xilinx_modules/xglink_tx_data_fifo.png
    :width: 25%

Parameters
==========

These are the key FIFO Generator configuration choices (see the Vivado screenshots below for the full settings):

- **FIFO implementation:** Common-clock BRAM FIFO with embedded output register (read latency = 0).
- **Data width:** 33 bits (``din(32)`` / ``dout(32)`` = ``tlast``, ``din(31:0)`` / ``dout(31:0)`` = 32-bit payload).
- **Depth:** 512 words.
- **Read mode:** First-Word Fall-Through (FWFT).
- **Status flags:** ``full``, ``empty``, ``overflow``, ``valid``.

Interface
=========

Write side
----------

- ``clk``: Single shared clock for both write and read.
- ``rst``: Synchronous active-high reset.
- ``wr_en``: Write enable; driven by ``s_axis_tx_tvalid``.
- ``din(32)``: ``tlast`` packed into the MSB.
- ``din(31:0)``: 32-bit transmit payload word.
- ``full``: Asserted when the FIFO cannot accept more data.
- ``overflow``: Asserted for one clock when a write is attempted while ``full`` (sticky in the parent module).

Read side
---------

- ``rd_en``: Read enable; qualified with the 64/66B gearbox ``read_en`` signal.
- ``dout(32)``: ``tlast`` bit of the word at the head of the FIFO.
- ``dout(31:0)``: Payload word at the head of the FIFO.
- ``valid``: Asserted when ``dout`` holds valid FWFT data.
- ``empty``: Asserted when the FIFO is empty.

Implementation details
======================

Principle of operations
-----------------------

The TX data FIFO decouples the user-side write clock from the 64/66B gearbox read cadence. Data (payload + ``tlast``) is written whenever the user asserts ``s_axis_tx_tvalid``. The gearbox inhibits reading every 66th block by deasserting ``read_en`` for two consecutive clocks; the FIFO absorbs these two idle slots without stalling the transmit pipeline. The BRAM embedded-output-register mode gives read latency = 0, which is necessary because the ``xglink_bypass`` state machine uses FWFT semantics and cannot tolerate an extra pipeline bubble between the FIFO and the link output.

Basic
=====

.. image:: ../../images/xilinx_modules/xglink_tx_data_fifo1.png
    :width: 100%

AXI4 Stream Ports
=================

.. image:: ../../images/xilinx_modules/xglink_tx_data_fifo2.png
	:width: 100%

Config
======

.. image:: ../../images/xilinx_modules/xglink_tx_data_fifo3.png
	:width: 100%

Status Flags
============

.. image:: ../../images/xilinx_modules/xglink_tx_data_fifo4.png
	:width: 100%

Summary
=======

.. image:: ../../images/xilinx_modules/xglink_tx_data_fifo5.png
	:width: 100%