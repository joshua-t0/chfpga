.. title:: chan_fifo

***************************************************************************	
:entity:`chan_fifo` (*chan_fifo.vhd*): Channelizer Asynchronous Output FIFO
***************************************************************************

.. parse:: hdl/chan/chan_fifo.vhd

.. default-role:: vhdl:entity

Entity documentation
====================

.. autoentity:: chan_fifo

Parameters
==========

- **FPGA_SERIES:** Target FPGA series (``KINTEX7`` or ``ULTRASCALE_PLUS``). Selects the appropriate embedded FIFO primitive: FIFO36E1 for 7-Series, FIFO36E2 for Ultrascale+.
- **DATA_WIDTH:** Width of the ``tdata`` payload in bits. Default is 64.
- **USER_WIDTH:** Width of the ``tuser`` sideband in bits. Default is 4.
- **ALMOST_FULL_THRESH_OFFSET:** Number of words below full at which ``almost_full`` is asserted. Default is 16.
- **ALMOST_EMPTY_THRESH_OFFSET:** Number of words above empty at which ``almost_empty`` is asserted. Default is 16.

Interface
=========

Write side
----------

- ``s_axis_tdata/tuser/tlast/tvalid``: Non-blocking AXI4-Streaming write interface (channelizer clock domain).
- ``s_axis_clk``: Write clock (channelizer clock).

Read side
---------

- ``m_axis_tdata/tuser/tlast/tvalid``: Non-blocking AXI4-Streaming read interface (corner-turn/output clock domain).
- ``m_axis_tready``: Read enable. Defaults to ``'1'``.
- ``m_axis_clk``: Read clock (corner-turn clock).

Status flags
------------

- ``empty``: Asserted when the FIFO has no data.
- ``full``: Asserted when the FIFO is full.
- ``almost_full``: Asserted when the FIFO is within ``ALMOST_FULL_THRESH_OFFSET`` words of full.
- ``almost_empty``: Asserted when the FIFO has fewer than ``ALMOST_EMPTY_THRESH_OFFSET`` words remaining.
- ``overflow``: Asserted when a write is attempted to a full FIFO.
- ``wr_count``: 10-bit write-side occupancy counter (Ultrascale+ only; driven to zero for Kintex-7).
- ``rst``: Asynchronous reset. For Kintex-7, must be held for at least 31 cycles of the slowest clock; no read or write operations may occur during this period.

Implementation details
======================

Principle of operations
-----------------------

The `chan_fifo` module implements an asynchronous First-Word-Fall-Through (FWFT) FIFO used at the output of the channelizer to buffer data during clock domain crossing operations. The FIFO allows data to be written at one clock rate (channelizer clock) and read at a different clock rate (corner-turn or output clock). The module uses Xilinx embedded FIFO primitives (FIFO36E1 for 7-Series, FIFO36E2 for Ultrascale+) to provide efficient resource usage, and the primitive is selected at synthesis time via the ``FPGA_SERIES`` generic.

Clocking
--------

The write side is clocked by ``s_axis_clk`` (channelizer clock domain) and the read side by ``m_axis_clk`` (corner-turn or output clock domain). Both clocks are fully independent. Reset handling differs by platform: on Kintex-7, an internal counter holds the embedded FIFO reset for at least 31 write-clock cycles; on Ultrascale+, ``wr_rst_busy`` and ``rd_rst_busy`` gate write and read enables during reset to avoid data corruption.

Platform-specific implementation
---------------------------------

The module automatically selects the appropriate FIFO primitive based on the ``FPGA_SERIES`` generic:

**7-Series (Kintex-7)**
~~~~~~~~~~~~~~~~~~~~~~~

- Uses ``FIFO36E1`` primitive
- Configuration: 512 words × 72 bits, asynchronous, FWFT, zero latency
- Reset: Asynchronous reset must be held for at least 31 cycles of the slowest clock
- Reset sequencer: Implements a counter-based reset sequencer to ensure proper FIFO initialization
- Write/read enables are gated during reset to prevent data corruption

**Ultrascale+**
~~~~~~~~~~~~~~~

- Uses ``FIFO36E2`` primitive
- Configuration: 512 words × 72 bits, independent clock domains, FWFT, registered output
- Reset: Synchronous reset to write clock (read domain reset is handled automatically)
- Reset busy signals: Uses ``wr_rst_busy`` and ``rd_rst_busy`` to gate write/read operations during reset
- Write count: Provides ``wr_count`` output for FIFO occupancy monitoring

Data mapping
------------

The FIFO stores AXI-Streaming signals in a 72-bit wide format:

- **Bits [DATA_WIDTH-1:0]**: ``tdata`` (data payload)
- **Bit [DATA_WIDTH]**: ``tlast`` (end-of-frame indicator)
- **Bits [DATA_WIDTH+USER_WIDTH:DATA_WIDTH+1]**: ``tuser`` (user-defined metadata, typically flags)

For 7-Series, the data is split into:
- ``di[63:0]`` and ``dip[7:0]`` (data and parity inputs)
- ``do[63:0]`` and ``dop[7:0]`` (data and parity outputs)

For Ultrascale+, the data is split into:
- ``DIN[63:0]`` and ``DINP[7:0]`` (data and parity inputs)
- ``DOUT[63:0]`` and ``DOUTP[7:0]`` (data and parity outputs)

Usage in channelizer
--------------------

The `chan_fifo` is instantiated at the output of the :entity:`chan` (channelizer) module to:

1. **Clock domain crossing**: Buffer data when transitioning from the channelizer clock domain to the corner-turn or output clock domain
2. **Rate matching**: Absorb rate differences between the channelizer output rate and the downstream processing rate
3. **Data buffering**: Provide buffering to handle bursty data patterns and prevent data loss

The FIFO ensures that channelized data can be reliably transferred between different clock domains while maintaining AXI-Streaming protocol compliance.
