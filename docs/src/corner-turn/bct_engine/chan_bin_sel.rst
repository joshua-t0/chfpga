.. title:: CHAN_BIN_SEL

*******************************************************************************
:entity:`chan_bin_sel` (*chan_bin_sel.vhd*): 1st stage corner-turn bin selector
*******************************************************************************

.. .. figure:: ../../images/channelizer.svg
..     :width: 75%

:entity:`chan_bin_sel` receives the raw data frames and flags from all the local channelizers and selects a subset of their frequency bins. The data, scaler flags and frame flags (ADC/FFT overflows) are stored in separate FIFOs and are streamed out along with a header and a final packer flag word. The buffering is done to allow the data is sent as one contiguous block, followed by the scaler flag block and a frame flag block. This packet format is intended to facilitate further corner-turn operations and also ultimately allowing the receifing node to efficiently transfer the data part of the packet using single DMA requests. This feature, however, comes at the cost of additional buffering and complexifies the logic of the bin selector code.


The module contains a set of control and monitoring memory-map registers.

.. toctree::
   :titlesonly:
   :hidden:

   ip_cores/mask_ram
   ip_cores/chdist_data_embed_fifo
   ip_cores/chdist_scaler_flag_fifo
   ip_cores/chdist_frame_fifo
   ../../navbar_separator

.. todo:: Missing ip_cores/chdist_data_embed_fifo_up



Entity documentation
====================

.. parse:: hdl/ct/chan_bin_sel.vhd

.. autoentity:: chan_bin_sel

Parameters
==========

- **PLATFORM_TYPE:** FPGA platform type enumerated in the chFPGA package. Selects the embedded FIFO primitive to use (FIFO36E2 for Kintex-7, URAM or BRAM for Ultrascale+) for the internal data and flag FIFOs.
- **LANE_NUMBER:** Logical index of this bin-selector instance within the channelizer crossbar. Used to identify the correct BSB register page.
- **NUMBER_OF_INPUTS:** Number of channelizer input lanes (i.e., the number of ``chan_bin_sel`` instances connected in parallel in ``chan_crossbar``).

Interface
=========

Channelizer data input
-----------------------

- ``s_axis_tdata``: Per-lane 32-bit input data words, each containing two frequency bins from the channelizer. One array entry per input lane.
- ``s_axis_tuser``: Per-lane 4-bit sideband word carrying ADC overflow, FFT overflow, and scaler flags.
- ``s_axis_tvalid``: Per-lane valid flags. The input is non-blocking.
- ``s_axis_tlast``: Per-lane end-of-frame flag.
- ``s_axis_global_tvalid``: Global valid flag, asserted for the duration of the longest input frame across all lanes. Used to align the write windows of all lane FIFOs.
- ``s_axis_global_tlast``: Active high on the last word of the global frame window.

Bin counter control
--------------------

- ``bin_ctr_en``: Enables the internal bin counter to track which frequency bin is currently being processed.
- ``bin_ctr_clr``: Clears the internal bin counter.

Packetized output
-----------------

- ``m_axis_tdata``: 32-bit output data carrying the packetized corner-turn stream. The packet starts with a header word, followed by a data block, a scaler-flag block, and a frame-flag block.
- ``m_axis_tvalid``: Output valid flag.
- ``m_axis_tlast``: Output end-of-packet flag.

BSB control interface
---------------------

- ``s_axis_bsb_*/m_axis_bsb_*``: BSB command and reply byte streams for software-controlled register access.
- ``bsb_clk/bsb_rst``: Dedicated clock and synchronous reset for the BSB interface.

Clocking
--------

- ``clk``: AXI-Streaming clock for all data-path logic.
- ``rst``: Synchronous active-high reset.


Memory map
==========

.. include-docs:: CHAN_BIN_SEL
    :start-after: chan_bin_sel Memory Map

Implementation details
======================

Data FIFO
---------

.. .. include-docs:: chan_bin_sel
    :start-after: Data FIFOs


Data Flag FIFO
--------------


.. .. include-docs:: chan_bin_sel
    :start-after: Data flags FIFOs


Data flags combining
--------------------

Data flags from consecutive bins can be combined by the front end, i.e. before the write process by setting the ``combine_data_flags`` bit. Indeed, since there is only 16 channels that feed the bin selectors, there are only 16 data (scaler) flags for each bin. This means that there is a full half-filled data flag word for each group of 4 data words (16 bytes, one (4+4) bit complex value for each channel).

Half-packing the data flag word is inefficient, but it is necessary to have the flag word to represent only one bin if we need to easily perform further channel selection in the following crossbar. That 2nd bin selector can do the data flag combining. The resulting set of flags from all combined channels will result in a block of data flags what will be a integer number of fully utilized data flag words that can be handled easily fby the following 3rd crossbar if need be.

One exception to this is the `shuffle16` mode, in which we pack 128 bins into a frame in order to fit all the data from the 16 channelizers into only 8 bin selector outputs (to feed the 8 links to the receiving node). With half used data words, the word rate is, on average::

    {(4 header words/frame) + (128 bins/frame)* [ (4 data words/bin) + (1 data flag word/bin)] + (1 frame flags word/frame) + (1 packet flags/frame) } / (2.56 us/frame) = 252.34375 Mwords/s (8.075 Gbit/s)

This exceeds the speed of the corner turn engine's internal clock of 244.140625 MHz. (This is the 32-bit-word clock of the backplane GTX transmitter, which operates at a signalling rate of 50x the 156.25 reference clock = 7.812 Gbit/s. This considerably relaxes the FPGA timing constraints and improves the GTX signal integrity compared the the next up multiplier of 66x (322.265625 MHz, 10.3125 Gbits/s)). If we combine the data words, we have an effective 0.5 data flag word/bin::

    {(4 header words/frame) + (128 bins/frame)* [ (4 data words/bin) + (0.5 data flag word/bin)] + (1 frame flags word/frame) + (1 packet flags/packet) } / (2.56 us/frame) = 227.34375 Mwords/s (7.275 Gbit/s)

Now this fits or 50x clock. The combined flags  cannot be used by a downstream bin selector, but those are bypassed anyways in `shuffle16` mode.

In term of implementation, we used to have the FIFO readout process do the data flags combining, but that caused a number of subtle problems. The extra cycles that were needed to read two sets of flags from the FIFOs to combine them into a single 32-bit-wide flag word caused the data from the next frame wo start piling up in the data fifo, reducing the effective FIFO capacity, and causing the data to be sent in large bursts. This problem was exacerbated by downstream logic that waited for a full frame to be completed before forwarding it. That didn't help aligners do their job. A front end combiner eliminated these complex data dynamics problems.



Readout Flags FIFO
------------------


The flags FIFO describe provide instructions to the readout logic on how to read each block of data from the data FIFO.
It indicates:

  - size of each block of data in words
  - whether words from pair of lanes should be combined (used for data flags only)
  - whether this is the last block of he the packet. Used to set the TLAST flag if the output stream.

The FIFO physically centralises all the information that is needed to sequence the FIFO readout.


FIFO writing process
--------------------

`recv_flags` indicate whether we are expecting the header words.  The header word counter `recv_header_word_ctr` is incremented when valid data comes in. When the 4th word is received we clear recv_flags so data processing can start. No data from the header is saved. The data processing counters are reset during the header phase.

In the data phase, we count, from the fastest to slowest counters: words, bins, frames and blocks.
The limit of these counters are changed from block to block:

  - During the header phase, we set the counter limits to  `number_of_input_words_per_bin` words, `number_of_input_bins_per_frame` bins, and 'last_frame_number` frames and set the block counter to DATA_BLOCK.

  - In the DATA_BLOCK, we count `number_of_input_words_per_bin` words, `number_of_input_bins_per_frame` bins, and 'last_frame_number` frames.

  - On the last word of the last bin of the last frame of the DATA_BLOCK,  we write to the readout flag FIFO to read `last_word_number=number_of_input_words_per_bin` if the bin was selected. We increment the block counter to DATA_FLAGS_BLOCK, and set the word counter limit to 1 word.

  - In the DATA_FLAG_BLOCK, we now count 1 word, `number_of_input_bins_per_frame` bins, and 'last_frame_number` frames. In other words (pun intended), we store one data flag word for each bin and each frame.

  - On the last word of the last bin of the last frame of the DATA_FLAGS_BLOCK,  we write to the readout flag FIFO to read `last_word_number=1` words if the bin was selected. We increment the block counter to FRAME_FLAGS_BLOCK, and we set the word counter limit to `last_frame_flags_word_number` and the bin  counter limit to 1 bin.

  - In the FRAME_FLAGS_BLOCK, we now count `last_frame_flags_word_number word`, 1 bin, and 'last_frame_number` frames. In other words, we store `last_frame_flags_word_number word` frame flags words each frame.

  - On the last word of the last bin of the last frame of the FRAME_FLAGS_BLOCK,  we increment the block counter to FLUSH_BLOCK, and we set the word counter limit back to 1.

  - In the FLUSH_BLOCK, nothing is done. The counters stay at zero.


  - When the last word of the packet arrive, the word is ignored, but the packet word is written in the FIFO.
    Readout flags are written on the last word of each block.


data_fifo_wr_en_packet_flags_dly=1: The data written in the FIFO is: lower bits: the TLAST flag of each input lane, which indicate if every lane finished at the same time. Other bits are zero.



FIFO readout process
--------------------

The FIFO readout logic implements a one-hot encoded state machine with five states that control the order in which data is transmitted:

- **send_header**: Sends the 4-word packet header. Transmission is triggered by the arrival of the first frame of a packet to minimize the delay between header and data, which is important for downstream packet aligners.

- **send_data**: Reads and transmits data from the data FIFO. Data is sent as it becomes available, so the FIFO doesn't need to store large amounts of data. When the last data word of the packet is detected (indicated by a flag bit in the FIFO output), the state machine transitions to either `send_data_flags` (if flags are enabled) or directly to `send_packet_flags` (if flags are disabled or in bypass mode).

- **send_data_flags**: Reads and transmits scaler (data) flags from the data flags FIFO. When the last flag word is detected, transitions to `send_frame_flags`.

- **send_frame_flags**: Reads and transmits frame flags (ADC and FFT overflow flags) from the frame flags FIFO. When the last flag word is detected, transitions to `send_packet_flags`.

- **send_packet_flags**: Sends a single packet flag word (currently all zeros) with the TLAST flag set, marking the end of the packet. Then transitions back to `send_header` to prepare for the next packet.

The state machine is manually encoded (not inferred by the synthesizer) as a one-hot state machine to reduce logic depth. This allows the state variables to be used combinatorially to generate FIFO read enables (`data_fifo_rd_en`, `data_flags_fifo_rd_en`, `frame_flags_fifo_rd_en`) without additional decoding logic.

The readout process assumes the destination can always accept data (non-blocking output). This simplifies the logic and helps meet timing constraints. The data flags and frame flags FIFOs must buffer a full packet's worth of flags plus any flags arriving while the FIFOs are being emptied, since flags are only sent after all data for the packet has been transmitted.

