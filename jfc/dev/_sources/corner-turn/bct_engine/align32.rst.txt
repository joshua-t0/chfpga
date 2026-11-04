.. title:: align32

***************************************************************************
:entity:`align32` (*align32.vhd*): 32-bit Multi-Lane Frame Alignment Module
***************************************************************************

.. parse:: hdl/ct/align32.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: align32

Parameters
==========

- **NUMBER_OF_LANES:** Number of input data lanes to align. Determines the width of all per-lane port arrays.
- **ENABLE_MONITORING_LOGIC:** When ``TRUE``, additional monitoring logic is instantiated, enabling the ``lane_monitor`` output for debugging lane alignment behaviour. Defaults to ``FALSE``.

Interface
=========

Input
-----

- ``s_axis_tvalid``: Per-lane valid flags. The input is non-blocking — the aligner always accepts incoming data.
- ``s_axis_tdata``: Per-lane 32-bit input data.
- ``s_axis_tlast``: Per-lane end-of-frame flag.
- ``s_axis_tuser``: Per-lane 4-bit sideband carrying ADC, FFT, and scaler overflow flags from the channelizer.

Output
------

- ``m_axis_tvalid``: Per-lane valid flags on the aligned output. Only asserted for lanes that presented a valid start-of-frame within the SOF window.
- ``m_axis_tdata``: Per-lane 32-bit aligned output data.
- ``m_axis_tlast``: Per-lane end-of-frame flag on the aligned output.
- ``m_axis_tuser``: Per-lane 4-bit sideband passed through from the input.
- ``m_axis_global_tvalid``: Active high while data from the longest aligned frame is being sent. Check per-lane ``m_axis_tvalid`` to determine which lanes are valid.
- ``m_axis_global_tlast``: Active high on the last word of the longest aligned frame.

Control
-------

- ``sof_window_stop``: 8-bit value configuring the SOF window length. Lane 0 SOF starts the window counter; lanes that do not present a SOF before this count is reached are discarded.
- ``ignore_lane``: Per-lane mask. Any lane set to ``'1'`` is unconditionally discarded and will not block the alignment process.

Monitoring
----------

- ``fifo_overflow``: Per-lane sticky flag indicating the internal alignment FIFO has overflowed.
- ``missing_frame``: Per-lane flag that pulses high when no SOF was found within the SOF window.
- ``bad_frame_length``: Per-lane flag that pulses high when a lane's frame ended at a different time than lane 0.
- ``lane0_tfirst_mon``: First-word flag for the incoming (pre-FIFO) lane 0 data stream.
- ``fifo_tfirst_mon``: Per-lane first-word flag at the FIFO output.
- ``fifo_count_mon``: Per-lane 10-bit FIFO occupancy counter.
- ``lane_monitor_source``: Selects which internal signal group is forwarded to ``lane_monitor`` (only meaningful when ``ENABLE_MONITORING_LOGIC=TRUE``).
- ``lane_monitor``: Per-lane monitoring output selected by ``lane_monitor_source``.

Clocking
--------

- ``clk``: Single clock for all input, output, and internal logic.
- ``rst``: Synchronous reset.

Principle of Operations
=======================

The `align32` module aligns multiple 32-bit AXI-Streaming data streams from different sources (lanes) to a common frame timing. It buffers incoming non-blocking streams and ensures that frames from all lanes start and end at the same time, compensating for delays, errors, and lost packets that can occur when data is transmitted over board-to-board GTX links.

Key Features
------------

- **Multi-lane alignment**: Aligns up to 16 lanes (configurable via ``NUMBER_OF_LANES`` generic)
- **32-bit data width**: Processes 32-bit words per lane
- **Non-blocking operation**: Always accepts data on input lanes and always provides data on output lanes when valid
- **Frame windowing**: Uses a programmable SOF (Start of Frame) window to tolerate delays between lanes
- **Error recovery**: Automatically discards misaligned frames and recovers for the next frame
- **Monitoring support**: Optional monitoring logic for debugging alignment issues

Alignment Process
-----------------

The alignment process works as follows:

1. **Frame Detection**: Lane 0 is used as a timing reference. When a start-of-frame (SOF) is detected on lane 0, a SOF window counter starts.

2. **SOF Window**: All lanes are expected to present their SOF within a programmable window (specified by ``sof_window_stop``). The window represents the worst-case delay expected between lanes.

3. **FIFO Buffering**: Each lane has its own FIFO (512 words deep) to buffer incoming data. The FIFOs are First-Word-Fall-Through (FWFT) to minimize latency.

4. **Valid Lane Selection**: At the end of the SOF window, lanes that have a valid SOF at their FIFO output are marked as "valid" and will be read out. Lanes without a valid SOF are marked as invalid and their data is flushed.

5. **Synchronized Readout**: Once valid lanes are determined, data is read from all valid lanes simultaneously. The module ensures that all valid lanes have data available before reading (``all_valid`` signal).

6. **Frame Truncation**: If a frame ends on one lane before others, the remaining lanes are truncated and their remaining data is discarded to maintain frame alignment.

Error Handling
--------------

The module handles various error conditions:

- **Missing frames**: Lanes that don't present a SOF within the window are marked as missing and their data is flushed
- **Bad frame length**: Frames that end at different times are detected and flagged
- **FIFO overflow**: Overflow conditions are detected and reported
- **Early/late frames**: Frames that start before or extend beyond the reference frame are discarded

Monitoring
----------

When ``ENABLE_MONITORING_LOGIC`` is set to ``TRUE``, the module provides extensive monitoring capabilities:

- FIFO occupancy counts
- Frame alignment status
- Error flags (overflow, missing frames, bad frame length)
- Lane-by-lane status monitoring

Usage in SHUFFLE_CROSSBAR
-------------------------

The `align32` module is instantiated in the :entity:`SHUFFLE_CROSSBAR` to align incoming packetized data from multiple GTX links. It ensures that packets from different physical lanes (including direct connections and remote GTX links) are properly aligned before being processed by the remapping and bin selection stages.

The aligner is critical for reliable operation because GTX links can introduce variable delays, packet loss, or malformed packets. The aligner must robustly handle these situations to minimize data loss and maintain system operation.

Implementation details
======================

Architecture
------------

Each input lane is backed by an independent 512-word-deep FWFT BRAM FIFO (``shuffle_crossbar_align_fifo``). The FIFO word width is 36 bits: 32 data bits, 1 ``tlast`` flag, and 3 ``tuser`` sideband bits. Writes are gated by an ``almost_full`` flag, but the last word of each frame (``tlast``) is always admitted to preserve frame-boundary information and prevent irrecoverable desynchronisation. The control pipeline is fully registered to meet timing at 322 MHz, which introduces a fixed 2-clock dead time between SOF detection and the start of synchronized readout; the upstream data source must provide at least 2 idle cycles per frame boundary to accommodate this.

Clocking
--------

All FIFO write, FIFO read, SOF-window, and output logic operate on the single ``clk`` clock domain. The synchronous ``rst`` is registered internally before it qualifies any state registers, easing timing closure in compact placements.

