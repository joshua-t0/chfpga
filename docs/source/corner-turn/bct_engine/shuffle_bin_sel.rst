.. title:: SHUFFLE_BIN_SEL

*********************************************************************************************
:entity:`SHUFFLE_BIN_SEL` (*SHUFFLE_BIN_SEL.vhd*): 2nd and 3rd stage corner-turn bin selector
*********************************************************************************************

.. .. figure:: ../../images/channelizer.svg
..     :width: 75%

:entity:`SHUFFLE_BIN_SEL` Selects specified frequency bins from multiple incoming data streams (the input lanes) and merges them into a single output stream.  The incoming streams are presumed to contain header, data, scaler flags, frame flags and footer. The outgoing stream maintains the same structure.

Generics are used to specialize the module for second or third stage corner-turn operations. Software-controlled registers can be used to change the operation of these bin selectors to support different packet geometry and allow the implementation of all the corner turn engine modes of operation.

The :entity:`SHUFFLE_BIN_SEL` can process incoming packets that has been packed to contain data and flags from  multiple frames.  A multi-frame packet has data bytes from multiple frames are grouped into a single contiguous block, followed by a block of data flags (Scaling overflow), frame flags (ADC/FFT overflows) and packet flags. A multi-frame packet facilitate downstream processing of the data by the X-Engine by allowing single operation block memory transfers. This feature, however, comes at the cost of additional buffering and complexifies the logic of the bin selector code.

The module contains a set of control and monitoring memory-map registers.

.. toctree::
   :titlesonly:

   ip_cores/shuffle_bin_sel_mask_ram
   ip_cores/shuffle_bin_sel_data_fifo_bram
   ip_cores/shuffle_bin_sel_data_fifo_embed
   ip_cores/shuffle_bin_sel_flags_fifo

Entity documentation
--------------------

.. parse:: hdl/CT/SHUFFLE_BIN_SEL.vhd

.. autoentity:: shuffle_bin_sel



Additional details
------------------

Memory map
----------

.. include-docs:: shuffle_bin_sel
    :start-after: SHUFFLE_BIN_SEL Memory Map

Implementation details
----------------------

Data blocks
~~~~~~~~~~~

The data FIFO stores 3 types of data, called data blocks. Each block correspond to groups of consecutive data in the incoming packets, and each require slightly different FIFO write and read sequences:

  (0) DATA_BLOCK: The channelizer data  (FFT output)
  (1) DATA_FLAGS_BLOCK: The data (scaler) flags: 1 bit for each of the (N_frames x N_bins x N_channels) element
  (2) FRAME_FLAGS_BLOCK: The frame flags: 2 bits for each of the (N_frames x N_channels) element

  (3) PACKET_FLAGS/FLUSH_BLOCK: The packet flag word. Any subsequent data shall be ignored (flushed)

The packet header is not included as it is not stored in the FIFO. The readout logic recreates a new header from scratch.

There are two FIFOs:

Data FIFO
~~~~~~~~~

The data FIFO stored the data/flag word(s) from each input lane when the bin selection map indicates the corresponding words fort that bin shall be kept. The same FIFO stores the selected channelizer data words, the data flag words from the same selected bins, all the frame flag words (ADC and FFT overflow flags which are not bin-dependent), and the packet flag word. It is possible to use a single FIFO for all this information because the data is already grouped in blocks, and the number of frames per packet is not changed.

The DATA FIFO can be implemented as BRAM/Embedded FIFO or shift-register FIFO, depending on the value of the FIFO_TYPE_MAP for the corresponding input lane.

    - When FIFO_TYPE_MAP(lane)=0, even lanes are implemented as a BRAM FIFO (with the FIFO logic implemented in the fabric), and odd lanes use embedded FIFOs (with the FIFO logic included in the silicon). This is to minimize fabric resources, as a RAMB36 block can support one FIFO18 and one RAMB18, but not two FIFO18s. We cannot use a FIFO36  connected to two input lanes because we need to read out the data from the two lanes independently (N words from one lane, and *then* N words from the other lane)

    - When FIFO_TYPE_MAP(lane)=1, shift-register-based FIFO is used, which is implemented in fabric using distributed ram. This is used for the 2nd crossbar, where ther eis a large number of lanes (16) and there is fabric logic to spare.

The data FIFO used to stores flags to guide the readout process, such as the NEXT_INPUT flag that indicated that a word was the last of its block. This was a bad idea in terms of routing, as all these flags had to be routed from each FIFO to a central state machine that coordinated the data FIFO readout. The Flags FIFO is used for this purpose instead.

Readout Flags FIFO
~~~~~~~~~~~~~~~~~~

The flags FIFO describe provide instructions to the readout logic on how to read each block of data from the data FIFO.

It indicate:
  - size of each block of data in words
  - whether words from pair of lanes should be combined (used for data flags only)
  - whether this is the last block of he the packet. Used to set the TLAST flag if the output stream.

The FIFO physically centralises all the information that is needed to sequence the FIFO readout.

An entry is written in the FLAGS FIFO when the last word of a block is being written to the DATA FIFO.

THE FLAGS FIFO is implemented as a Distributed RAM FIFO in order to preserve BRAM resources. These FIFOs do not require a lot of memory.

To further preserve space, the FLAGS FIFO can be implemented as a deep 4-bit wide FIFO (2-bit word counter + 2 bits of flags) or a wide shallow FIFO (4-bit word counter + 2 bits of flags). The selection is based on the ``WORD_CTR_WIDTH`` generics.




FIFO writing process
~~~~~~~~~~~~~~~~~~~~

`recv_flags` indicate whether we are expecting the header words.  The header word counter `recv_header_word_ctr` is incremented when valid data comes in. When the 4th word is received we clear recv_flags so data processing can start. No data from the header is saved. The data processing counters are reset during the header phase.

In the data phase, we count, from the fastest to slowest counters: words, bins, frames and blocks.
The limit of these counters are changed from block to block:

- During the header phase, we set the counter limits to  `number_of_input_words_per_bin` words,
  `number_of_input_bins_per_frame` bins, and 'last_frame_number` frames and set the block counter to
  DATA_BLOCK.

- In the DATA_BLOCK, we count `number_of_input_words_per_bin` words,
  `number_of_input_bins_per_frame` bins, and 'last_frame_number` frames.

- On the last word of the last bin of the last frame of the DATA_BLOCK,  we write to the readout
  flag FIFO to read `last_word_number=number_of_input_words_per_bin` if the bin was selected. We
  increment the block counter to DATA_FLAGS_BLOCK, and set the word counter limit to 1 word.

- In the DATA_FLAG_BLOCK, we now count 1 word, `number_of_input_bins_per_frame` bins, and
  'last_frame_number` frames. In other words (pun intended), we store one data flag word for each
  bin and each frame.

- On the last word of the last bin of the last frame of the DATA_FLAGS_BLOCK,  we write to the
  readout flag FIFO to read `last_word_number=1` words if the bin was selected. We increment the
  block counter to FRAME_FLAGS_BLOCK, and we set the word counter limit to
  `last_frame_flags_word_number` and the bin  counter limit to 1 bin.

- In the FRAME_FLAGS_BLOCK, we now count `last_frame_flags_word_number word`, 1 bin, and
  'last_frame_number` frames. In other words, we store `last_frame_flags_word_number word` frame
  flags words each frame.

- On the last word of the last bin of the last frame of the FRAME_FLAGS_BLOCK,  we increment the
  block counter to FLUSH_BLOCK, and we set the word counter limit back to 1.

- In the FLUSH_BLOCK, nothing is done. The counters stay at zero.


- When the last word of the packet arrive, the word is ignored, but the packet word is written in
  the FIFO. Readout flags are written on the last word of each block.


data_fifo_wr_en_packet_flags_dly=1: The data written in the FIFO is: lower bits: the TLAST flag of each input lane, which indicate if every lane finished at the same time. Other bits are zero.



FIFO readout process
~~~~~~~~~~~~~~~~~~~~

The FIFO readout logic is relatively simple.

- When a word is present in the FLAGS FIFO, we read N words from the DATA FIFO of each input lane, where N is indicted in the FLAGS FIFO word. The RD_EN of the FAGS FIFO is activated onthe last word of the last lane to prepare for the readout of the next block.


Since the FLAGS FIFO word is written only when the data has been written, we assume that a TVALID=1 flags on the FLAGS FIFO means a TVALID=1 flag on the DATA FIFO. To avoid high-fanout logic that would need to span multiple FIFOs, we do not check the DATA FIFO TVALID lines. Is this assumption dangerous?

The DRAM common clock FIFO has an output register, which facilitates timing.
The DATA FIFO currently has no output register, which makes timing closure more difficult. But We need a zero latency as the FIFO's ``rd_en`` signal is derived from the output of the FIFO.

On the K7, an output register on a common-clock embedded FIFO adds a read latency, which is not compatible with the logic. A independent-clock embedded FIFO with registers does *not* add a read latency, but might add a propagation delay. Will the delay be long enouugh so the data is not yet ready when the FLAG word comes out of the FIFO? Even if we use the same clock on each side of the FIFO?
We have to consider we don't write the flag until the last word of the block  is written. For multiple-word blocks, the first word has more time to propagate. But that does not apply for single-word blocks.
Can we add a pipeline delay on the FLAGS FIFO to compensate without creating a delay in the feedback signals?


 registered output?with