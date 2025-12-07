.. title:: chan_fifo

***************************************************************************	
:entity:`chan_fifo` (*chan_fifo.vhd*): Channelizer Asynchronous Output FIFO
***************************************************************************

.. parse:: hdl/chan/chan_fifo.vhd

.. default-role:: vhdl:entity

Entity documentation
====================

.. autoentity:: chan_fifo

Key Features
============

- **Asynchronous operation**: Supports independent read and write clocks for clock domain crossing
- **FWFT mode**: First-word-fall-through with zero latency for improved throughput
- **AXI-Streaming compatible**: Full support for AXI-Streaming protocol with ``tdata``, ``tuser``, ``tlast``, ``tvalid``, and ``tready`` signals
- **Configurable data width**: Supports configurable data width (default 64 bits) and user width (default 4 bits)
- **Status flags**: Provides ``empty``, ``full``, ``almost_full``, ``almost_empty``, and ``overflow`` status signals
- **Write count**: Provides write count for monitoring FIFO occupancy (Ultrascale+ only)

Principle of Operations
=======================

The `chan_fifo` module implements an asynchronous First-Word-Fall-Through (FWFT) FIFO used at the output of the channelizer to buffer data during clock domain crossing operations. The FIFO allows data to be written at one clock rate (channelizer clock) and read at a different clock rate (corner-turn or output clock).

The module uses Xilinx embedded FIFO primitives (FIFO36E1 for 7-Series, FIFO36E2 for Ultrascale+) to provide efficient resource usage and high performance.



Platform-Specific Implementation
---------------------------------

The module automatically selects the appropriate FIFO primitive based on the ``FPGA_SERIES`` generic:

**7-Series (Kintex-7) Implementation**
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Uses ``FIFO36E1`` primitive
- Configuration: 512 words × 72 bits, asynchronous, FWFT, zero latency
- Reset: Asynchronous reset must be held for at least 31 cycles of the slowest clock
- Reset sequencer: Implements a counter-based reset sequencer to ensure proper FIFO initialization
- Write/read enables are gated during reset to prevent data corruption

**Ultrascale+ Implementation**
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Uses ``FIFO36E2`` primitive
- Configuration: 512 words × 72 bits, independent clock domains, FWFT, registered output
- Reset: Synchronous reset to write clock (read domain reset is handled automatically)
- Reset busy signals: Uses ``wr_rst_busy`` and ``rd_rst_busy`` to gate write/read operations during reset
- Write count: Provides ``wr_count`` output for FIFO occupancy monitoring

Data Mapping
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

Usage in Channelizer
====================

The `chan_fifo` is instantiated at the output of the :entity:`CHAN` (channelizer) module to:

1. **Clock domain crossing**: Buffer data when transitioning from the channelizer clock domain to the corner-turn or output clock domain
2. **Rate matching**: Absorb rate differences between the channelizer output rate and the downstream processing rate
3. **Data buffering**: Provide buffering to handle bursty data patterns and prevent data loss

The FIFO ensures that channelized data can be reliably transferred between different clock domains while maintaining AXI-Streaming protocol compliance.
