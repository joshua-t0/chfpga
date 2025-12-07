.. title:: align32

***************************************************************************
:entity:`align32` (*align32.vhd*): 32-bit Multi-Lane Frame Alignment Module
***************************************************************************

.. parse:: hdl/ct/align32.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: align32

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

