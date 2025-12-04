.. title:: ALIGN64

***************************************************************************
:entity:`ALIGN64` (*ALIGN64.vhd*): 64-bit Multi-Lane Frame Alignment Module
***************************************************************************

.. toctree::
   :titlesonly:
   :hidden:

   align64_fifo
   ../../navbar_separator

.. parse:: hdl/CROSSBAR/ALIGN64.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: align64

Principle of Operations
=======================

The `ALIGN64` module robustly aligns multiple 64-bit AXI-Streaming data streams to a common ``tvalid`` / ``tlast`` framing. It is designed for Ultrascale+ FPGAs and operates at high clock frequencies (up to 400 MHz). Lane 0 is used as a reference for alignment, and the output ``tvalid``/``tlast`` are delayed versions of lane 0, ensuring they are always present even if other lanes are missing or misaligned.

Key Features
------------

- **Multi-lane alignment**: Aligns up to 4 lanes (configurable via ``NUMBER_OF_LANES`` generic)
- **64-bit data width**: Processes 64-bit words per lane (optimized for Ultrascale+)
- **High-speed operation**: Designed to operate at 400 MHz on Ultrascale+ FPGAs
- **Non-blocking operation**: Always accepts data on input lanes
- **Configurable buffering**: Programmable ``BUFFERING_DEPTH`` to account for lane delays and dead times
- **Lane error reporting**: Provides ``lane_error`` signals to indicate unreliable lanes
- **Monitoring support**: Optional monitoring logic for debugging alignment issues

Alignment Process
-----------------

The alignment process uses a state machine per lane with the following states:

1. **READ State**: All lanes are expected to be aligned. Data is read simultaneously from all lanes when lane 0 is read. Lane 0 is always read when its FIFO has at least ``BUFFERING_DEPTH`` words, acting as a delay line to ensure other lanes have time to catch up.

2. **FLUSH_UNTIL_EMPTY State**: If a lane does not start when lane 0 starts (SOF misalignment detected), the lane enters this state to flush its FIFO down to almost-empty. This prevents FIFO occupancy from gradually increasing during bad alignments.

3. **FLUSH_UNTIL_EOF State**: After the FIFO is almost empty, the lane continues flushing but stops after a TLAST (end-of-frame) is read out.

4. **HOLD State**: After flushing to EOF, the lane holds the following SOF (if present) until the next lane 0 SOF, at which point alignment is tested again.

FIFO Architecture
-----------------

Each lane has an independent 512-word deep FIFO implemented using Xilinx XPM macros (Ultrascale+ embedded synchronous FIFOs). The FIFOs are First-Word-Fall-Through (FWFT) with embedded output registers to minimize latency while meeting timing constraints.

Key design features:

- **Lane 0 as reference**: Lane 0 is always read when ``not almost_empty(0)``, ensuring other lanes have buffered data available
- **Independent lanes**: All lanes operate independently except for sharing the lane 0 read enable signal
- **Almost-full protection**: FIFO writes are stopped when almost-full, except for TLAST words to ensure frame boundaries are preserved
- **Buffering depth**: The ``BUFFERING_DEPTH`` parameter (default 128 words) must be large enough to account for:
  - Delay between lanes (typically 35-45 words for bypass vs. GTY lanes)
  - Maximum dead times (periods where ``tvalid=0``)

Error Detection
---------------

The module detects and reports alignment errors:

- **Lane errors**: ``lane_error(i)`` is asserted when a lane's SOF or EOF does not match lane 0's SOF/EOF during read operations
- **Missing frames**: Detected when a lane doesn't start when lane 0 starts
- **Bad frame length**: Detected when frames end at different times
- **FIFO overflow/underflow**: Monitored and reported when monitoring logic is enabled

Monitoring
----------

When ``ENABLE_MONITORING_LOGIC`` is set to ``TRUE``, the module provides comprehensive monitoring:

- FIFO occupancy counts per lane
- Lane delay measurements (time between lane 0 SOF and other lane SOFs)
- Error counters (overflow, missing frames, bad frame length, invalid lanes)
- Sticky error flags for persistent issues
- Clock counter since lane 0 SOF

Usage in UCT_Engine
-------------------

The `ALIGN64` module is used in the :entity:`uct_engine` to align incoming data streams from multiple sources (direct connections and GTY transceiver links). It ensures that 64-bit data words from all lanes are properly aligned before being processed by downstream corner-turn stages.

The module is critical for reliable operation in multi-board corner-turn configurations where data arrives from different physical sources with variable delays.

