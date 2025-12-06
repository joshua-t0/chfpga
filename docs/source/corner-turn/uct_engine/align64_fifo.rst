.. title:: align64_fifo

********************************************************************
:entity:`align64_fifo` (*align64_fifo.vhd*): 64-bit Alignment FIFO
********************************************************************

.. parse:: hdl/CT/align64_fifo.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: align64_fifo

Principle of Operations
=======================

The `align64_fifo` module implements a 64-bit wide, 512-word deep First-Word-Fall-Through (FWFT) synchronous FIFO using Xilinx Ultrascale+ embedded FIFO primitives (FIFO36E2). It is specifically designed for use with the :entity:`align64` module to buffer data during multi-lane alignment operations.

The FIFO uses a single RAMB36 site and provides:
- Synchronous operation (single clock domain)
- FWFT mode with zero latency
- Output register for timing closure
- Configurable almost-full and almost-empty thresholds
- AXI-Streaming compatible interface

Key Features
------------

- **64-bit data width**: Processes 64-bit words (can be configured to less)
- **512-word depth**: Provides 512 words of buffering
- **FWFT mode**: First-word-fall-through for minimal latency
- **Embedded FIFO**: Uses Ultrascale+ FIFO36E2 primitive for efficient resource usage
- **Configurable thresholds**: Almost-full and almost-empty thresholds are configurable

Usage in ALIGN64
----------------

The `align64_fifo` is instantiated by the :entity:`align64` module to buffer incoming data streams from each lane. The FIFOs allow the alignment module to compensate for variable delays between lanes by buffering data until all lanes are ready for synchronized readout.

