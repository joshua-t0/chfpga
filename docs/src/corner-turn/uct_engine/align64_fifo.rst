.. title:: align64_fifo

******************************************************************
:entity:`align64_fifo` (*align64_fifo.vhd*): 64-bit Alignment FIFO
******************************************************************

.. parse:: hdl/ct/align64_fifo.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: align64_fifo

Parameters
==========

- **DATA_WIDTH:** Width of the data bus in bits. Defaults to 64. Must match the ``tdata`` width of the driving lane in :entity:`align64`.
- **ALMOST_FULL_THRESH:** Threshold at which ``almost_full`` is asserted. Measured in words. Defaults to 511 (one word before full).
- **ALMOST_EMPTY_THRESH:** Threshold at which ``almost_empty`` is asserted. Measured in words. Defaults to 1 (one word present).

Interface
=========

Input
-----

- ``s_axis_tdata``: ``DATA_WIDTH``-bit input data word.
- ``s_axis_tlast``: End-of-frame flag, written into the FIFO alongside the data word.
- ``s_axis_tvalid``: Write enable. Data is pushed into the FIFO when asserted. The FIFO is non-blocking — no back-pressure is applied to the input.

Output
------

- ``m_axis_tdata``: ``DATA_WIDTH``-bit data word at the FIFO output (FWFT mode — valid data appears without a read strobe).
- ``m_axis_tlast``: End-of-frame flag corresponding to ``m_axis_tdata``.
- ``m_axis_tready``: Read enable (pop) signal. Asserted by the downstream consumer to advance the FIFO. Defaults to ``'1'`` when left unconnected.
- ``m_axis_tvalid``: Asserted when there is at least one word available at the output.

Status
------

- ``empty``: Asserted when the FIFO contains no data.
- ``full``: Asserted when the FIFO is completely full.
- ``almost_empty``: Asserted when the occupancy is at or below ``ALMOST_EMPTY_THRESH``.
- ``almost_full``: Asserted when the occupancy is at or above ``ALMOST_FULL_THRESH``.
- ``overflow``: Sticky flag. Asserted if a write is attempted while the FIFO is full.
- ``wr_count``: 10-bit write-side occupancy counter. Indicates how many words are currently stored.

Clocking
--------

- ``clk``: Single synchronous clock for all FIFO logic.
- ``rst``: Synchronous active-high reset.

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

Implementation details
======================

Architecture
------------

The FIFO is implemented directly using the Xilinx ``FIFO36E2`` primitive, which occupies a single RAMB36 site and supports a native 72-bit data bus. The data bus is split as 64-bit data (``din``/``dout``) plus 8 parity bits (``dinp``/``doutp``); the ``tlast`` flag is stored in parity bit 0, so no additional memory resources are needed for sideband. The FIFO is configured in FWFT mode (``FIRST_WORD_FALL_THROUGH=TRUE``) with a registered output stage (``REGISTER_MODE=REGISTERED``), providing a zero-latency FWFT interface while keeping the output data path registered for timing. The ``EXTENDED_DATACOUNT`` write-count mode provides a 14-bit occupancy word from which the lower 10 bits are exposed as ``wr_count``. Reset-busy flags (``rd_rst_busy``, ``wr_rst_busy``) are monitored to suppress spurious read/write enables during reset.

Clocking
--------

Both the read and write clock ports of the ``FIFO36E2`` are driven by the same ``clk`` signal (``CLOCK_DOMAINS=COMMON``), making this a fully synchronous single-clock FIFO. The ``rst`` input is synchronous to ``clk`` as required by the FIFO36E2 primitive in common-clock mode.
