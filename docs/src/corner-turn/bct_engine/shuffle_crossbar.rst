.. title:: SHUFFLE_CROSSBAR

**********************************************************************************
:entity:`shuffle_crossbar` (*shuffle_crossbar.vhd*): 2nd and 3rd stage corner-turn
**********************************************************************************

.. toctree::
   :titlesonly:
   :hidden:

   ip_cores/shuffle_crossbar_align_fifo
   align32
   remap
   shuffle_bin_sel
   ../../navbar_separator


The `SHUFFLE_CROSSBAR` implements the second and third stages of the corner-turn operation. Contrary to the channelizer crossbar, the shuffle crossbar accepts data that is already packetized with headers, flags etc., and there needs to process the data differnetly than the first crossbar.

Generics are used to specialze the bodule for second or stage operations. Software-controlled registers can be used to change the operation of these crossbars to support different packet geometry and allow the implementation of all the corner turn engine modes of operation.

The shuffle_crossbar consists of the following  sub-modules:

  - The align module (:entity:`align32`), which buffers and aligns the incoming packets so they can be processed easily. The aligner receives data from board-to-board GTX links, which are prone to errors, lost packets or simply delays. The aligner must reliably deal with and recover from  all these situations to minimize data loss.
  - The remapping module (:entity:`remap`) Reorganizes the ordering of the lanes so the data will be reorganized in the right order and will be sent to the right destinations.
  - An array of bin selectors (:entity:`shuffle_bin_sel`). Each bin selector pulls data from all incoming streams, and retains and buffers a subset of the frequency bins they contain. The captured bins from all the input lanes are then streamed out, along with their headers, flags etc.

The shuffle_crossbar is designed to facilitate downstream processing of the data by the X engine by regrouping all the data bytes from multiple frames into a single contiguous block, followrd by a block of data flags (Scaling overflow), frame flags (ADC/FFT overflows) and packet flags. This allows the F-engine to move the data from its network interface card to the processing memory a single, efficient move / DMA operation. This feature, however, comes at the cost of additional buffering and complexifies the logic of the bin selector code.

The module contains a set of control and monitoring memory-map registers.

.. toctree::
   :titlesonly:

   shuffle_bin_sel
   remap
   align32

Entity documentation
--------------------

.. parse:: hdl/ct/shuffle_crossbar.vhd

.. autoentity:: shuffle_crossbar

Parameters
==========

- **PLATFORM_TYPE:** FPGA platform type enumerated in the chFPGA package. Propagated to :entity:`shuffle_bin_sel` to select the appropriate embedded FIFO primitives.
- **NUMBER_OF_INPUT_LANES:** Number of input packet lanes (one per backplane or QSFP GTX receiver). Defaults to 16.
- **NUMBER_OF_OUTPUT_LANES:** Total number of output lanes across all bin-selector instances. Defaults to 8.
- **NUMBER_OF_OUTPUT_LANES_PER_BIN_SEL:** Number of output lanes produced by each individual :entity:`shuffle_bin_sel` instance. Determines how many bin-selector instances are created. Defaults to 1.
- **EIGHT_BIT_SUPPORT:** When ``TRUE``, enables processing of 8-bit (rather than the standard 4-bit real, 4-bit imaginary) bin data. Defaults to ``FALSE``.
- **COMBINE_DATA_FLAGS:** When ``TRUE``, data and flag blocks are merged into a single combined block before storage in the output FIFO. Propagated to each :entity:`shuffle_bin_sel`. Defaults to ``TRUE``.
- **WORDS_PER_BIN_MAX:** Maximum number of 32-bit words per frequency bin. Used to size internal data FIFOs. Defaults to 4.
- **BINS_PER_FRAME_MAX:** Maximum number of frequency bins per input frame. Used to size mask RAMs and counters. Defaults to 64.
- **BIN_SEL_FIFO_TYPE_MAP:** 2-D integer array specifying the FIFO primitive type for each FIFO within each bin-selector instance. Allows per-instance, per-FIFO resource control.
- **SHUFFLE_FLAGS_MASK:** Default 32-bit mask applied at elaboration time to select which flag bits are included in the output packet footer. Can be overridden via BSB register.

Interface
=========

Packet input
------------

- ``s_axis_tvalid``: Per-input-lane valid flags. Non-blocking.
- ``s_axis_tdata``: Per-input-lane 32-bit packet data (header, bin data, scaler flags, frame flags, footer).
- ``s_axis_tlast``: Per-input-lane end-of-packet flag.

Packet output
-------------

- ``m_axis_tvalid``: Per-output-lane valid flags.
- ``m_axis_tdata``: Per-output-lane 32-bit re-packed packet data.
- ``m_axis_tlast``: Per-output-lane end-of-packet flag.

Control and monitoring
----------------------

- ``align_pulse``: Alignment pulse output from the internal :entity:`align32` sub-module, indicating the start of a new aligned frame. Propagated up to :entity:`bct_engine` for debug.

BSB control interface
---------------------

- ``s_axis_bsb_*/m_axis_bsb_*``: BSB command and reply byte streams for software-controlled register access.
- ``bsb_clk/bsb_rst``: Dedicated clock and synchronous reset for the BSB interface.

Clocking
--------

- ``clk``: AXI-Streaming data clock.
- ``rst``: Synchronous active-high reset.

Additional details
------------------

Memory map
----------

.. include-docs:: shuffle_crossbar
    :start-after: shuffle_crossbar Memory Map

Implementation details
----------------------
