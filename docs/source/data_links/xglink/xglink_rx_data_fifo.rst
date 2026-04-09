.. _xglink-rx-data-fifo-xil-module:

XGLINK Rx Data FIFO
*******************

Overview
========

This is a **Xilinx AXI4-Stream Data FIFO** IP core used inside ``xglink_bypass`` to re-buffer the received data stream before presenting it on the user AXI4-Stream output port. It is a synchronous FWFT FIFO with a **32-bit** payload path plus a 1-bit ``tuser`` sideband carrying the per-word error flag.

The following screenshots show the IP core configuration as set in Vivado.

.. image:: ../../images/xilinx_modules/xglink_rx_data_fifo.png
    :width: 25%

Parameters
==========

These are the key FIFO Generator configuration choices (see the Vivado screenshots below for the full settings):

- **FIFO implementation:** AXI4-Stream Data FIFO (synchronous).
- **Data width:** 32-bit ``TDATA`` + 1-bit ``TUSER`` (error flag).
- **Read mode:** First-Word Fall-Through (FWFT).
- **Clock domain:** Single clock (``s_aclk`` drives both write and read sides in ``xglink_bypass``); the IP exposes two clock ports (``s_aclk`` / ``m_aclk``) which are tied together for synchronous operation.

Interface
=========

Write side (``s_aclk`` domain)
-------------------------------

- ``s_aclk``: Write clock.
- ``s_aresetn``: Active-low synchronous reset.
- ``s_axis_tvalid``: Data valid on the write side.
- ``s_axis_tdata``: 32-bit write data.
- ``s_axis_tlast``: End-of-packet marker on the write side.
- ``s_axis_tuser``: 1-bit sideband; carries the per-word error flag (``m_axis_rx_terror``).
- ``s_axis_tready``: Back-pressure output; driven low when the FIFO is full.

Read side (``m_aclk`` domain)
------------------------------

- ``m_aclk``: Read clock (tied to ``s_aclk`` in ``xglink_bypass``).
- ``m_axis_tvalid``: Non-empty flag / data valid on the read side.
- ``m_axis_tdata``: 32-bit read data.
- ``m_axis_tlast``: End-of-packet marker on the read side.
- ``m_axis_tuser(0)``: Forwarded error flag (``m_axis_rx_terror``).
- ``m_axis_tready``: Read enable; tied to ``'1'`` in ``xglink_bypass`` (non-blocking drain).

Implementation details
======================

Principle of operations
-----------------------

Inside ``xglink_bypass``, the RX data FIFO absorbs the 64/66-bit gearbox throttling on the write side (words are written only when ``tx_ready`` is high, i.e. 64 out of every 66 clocks) and presents a continuous AXI4-Stream on the read side to the ``m_axis_rx_*`` user interface. Because both clock ports are driven by the same clock, no CDC logic is active; the asynchronous FIFO capability of the IP is unused in this instantiation.

Basic
=====

.. image:: ../../images/xilinx_modules/xglink_rx_data_fifo1.png
    :width: 100%

AXI4 Stream Ports
=================

.. image:: ../../images/xilinx_modules/xglink_rx_data_fifo2.png
	:width: 100%

Config
======

.. image:: ../../images/xilinx_modules/xglink_rx_data_fifo3.png
	:width: 100%

Status Flags
============

.. image:: ../../images/xilinx_modules/xglink_rx_data_fifo4.png
	:width: 100%

Summary
=======

.. image:: ../../images/xilinx_modules/xglink_rx_data_fifo5.png
	:width: 100%