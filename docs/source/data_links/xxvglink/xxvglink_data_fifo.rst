.. title:: xxvglink_data_fifo

***************************************************************************
:entity:`xxvglink_data_fifo` (*xxvglink_data_fifo.vhd*): XXVGLINK Data FIFO
***************************************************************************

.. parse:: hdl/data_links/XXVGLINK/xxvglink_data_fifo.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: xxvglink_data_fifo

Principle of Operations
=======================

The `xxvglink_data_fifo` module implements an asynchronous First-Word-Fall-Through (FWFT) FIFO using Xilinx Ultrascale+ embedded FIFO primitives (FIFO36E2). It is used in the XXVGLINK system to buffer data for clock domain crossing between the user clock domain and the GTY transceiver clock domain.

The FIFO uses a single RAMB36 site and provides:
- Asynchronous operation (separate read and write clocks)
- FWFT mode with zero latency
- Output register for timing closure
- Configurable full and empty thresholds
- AXI-Streaming compatible interface with error signal support

Key Features
------------

- **64-bit data width**: Processes 64-bit words (configurable)
- **Asynchronous**: Supports different read and write clocks
- **FWFT mode**: First-word-fall-through for minimal latency
- **Embedded FIFO**: Uses Ultrascale+ FIFO36E2 primitive for efficient resource usage
- **Error support**: Includes ``terror`` signal for error indication

Usage in XXVGLINK
-----------------

The `xxvglink_data_fifo` is used in both :entity:`xxvglink_tx` and :entity:`xxvglink_rx` modules to buffer data during clock domain crossing operations between the user logic and GTY transceiver interfaces.

