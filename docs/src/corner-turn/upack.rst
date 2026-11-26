.. title:: UPACK

*******************************************************************************
:entity:`UPACK` (*upack.vhd*): UltraRAM-based Packetizer and Corner-Turn Engine
*******************************************************************************

.. parse:: hdl/ct/upack.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: upack

Parameters
==========

- **SIM:** When ``TRUE``, replaces UltraRAM tiles with simulation-friendly RAM models to avoid long elaboration times in behavioural simulation. Must be ``FALSE`` for synthesis. Defaults to ``FALSE``.
- **EXPONENT_BITS:** 0 (default): the packetizer is as it was. 2 or 3: the input samples have an exponent of this number of bits, and the packetizer has the `Exponent mode`_. With 3 the packetizer can also send fields of 4 bits, and it has 16 more UltraRAMs (8 with 2). The value 1 is not built.

Interface
=========

Data input
----------

- ``s_axis_in_tdata``: 256-bit input word from the F-Engine channelizer. Carries 8 channels × 8 bins × 4 bytes, organized as 4 bins per word across 8 lanes.
- ``s_axis_in_texp``: With ``EXPONENT_BITS`` = *E* (2 or 3), the exponent of each sample of ``s_axis_in_tdata``: sample *n* is in ``tdata(8n + 7 downto 8n)`` and its exponent in ``texp(E n + E - 1 downto E n)``. Not used (1 bit for each sample) if ``EXPONENT_BITS`` = 0.
- ``s_axis_in_tvalid``: Input valid flag. Non-blocking — the module always absorbs data when valid.
- ``s_axis_in_tlast``: End-of-frame flag. Marks the last word of an input data frame.

Data output
-----------

- ``m_axis_out_tdata``: 256-bit output word read from the UltraRAM array. Carries the corner-turned (transposed) data.
- ``m_axis_out_tvalid``: Output valid flag.
- ``m_axis_out_tlast``: End-of-frame flag on the output stream.

Debug
-----

- ``debug_out``: 32-bit debug register output. Contents are implementation-defined; used during bring-up.

BSB control interface
---------------------

- ``s_axis_bsb_*/m_axis_bsb_*``: BSB command and reply byte streams for software-controlled register access (memory-map registers, timing, monitoring).
- ``bsb_clk/bsb_rst``: Dedicated clock and synchronous reset for the BSB interface.

Clocking
--------

- ``clk``: AXI-Streaming clock for all data-path logic.
- ``rst``: Synchronous active-high reset.

Principle of operation
----------------------


Memory organization
-------------------

Data is stored in 16 URAM blocks organized as an array of 4 x 4 blocks. Each block is implemented a 4 UltraRAM tiles, which together form a memory with  64 bits x 16384 words. 

The incoming data is written column-wise, wich each column receiving the 64 bits (8 channels * 8 bit/channel) from each bin in the input word. Data from consecutive frames are written in different rows.  

A data frame consists of 2048 words (8192 bins total, 4 bins per word). Each memory block can store 8 frames, or 4 frames per bank. The 4 blocks in a column can store up to 16 frames per bank.

Data is read column-wise, all 4 blocks in a column in parallel, providing a 256 bit data bus.


Memory Map
----------

.. include-docs:: upack
    :start-after: Memory Map

Exponent mode
-------------

This mode is in the build if ``EXPONENT_BITS`` = 2 or 3 (the ``ct`` configuration of the CRS: ``CONFIG_EXPONENT_BITS``). Status byte 0 tells what the build has:

- bits 5:4: the value of ``EXPONENT_BITS``;
- bit 6: 1 for this version of the mode (the exponents are at the end of the packet, and a group of 2 to 16 frames has one exponent);
- bit 7 (``exp_field4_support``): 1 if the build can send exponents of 4 bits (``EXPONENT_BITS`` = 3);
- bit 3 (``exponent_bins_from_scalers``): 1 if the scalers tell the packetizer which bins have an exponent, as this page describes. An earlier build had a table of bins in the packetizer; this bit was then 0.

Each input sample is a (4+4)-bit value with an exponent of ``EXPONENT_BITS`` bits (0 to 3, or 0 to 7; the exponent mode of the `scaler`): value = sample x 2\ :sup:`exponent`. With the mode on, the packetizer sends one exponent for each group of *B* consecutive frames of a bin and of an input (*B* = 2, 4, 8 or 16).

**The bins that have exponents.** The host writes them in one place only: the table of the bins with no exponent of each scaler (see `scaler`; the same table in the 8 scalers). The packetizer has no table. Each scaler sends, with each bin of each frame, one bit that tells that the bin has an exponent in this scaler. This bit goes with the sample and its exponent to the packetizer.

- A bin of a packet has exponents if this bit is 1 for one input or more in the last frame of the 16 frames of the packet.
- An input for which the bit is 0 has the exponent 0 for that bin.
- A bin that holds a header (bit 13 of its entry in the playlist is 0; the playlist is the list of the bins of each packet, which the host writes) never has exponents.
- If the table of the scalers changes while frames flow, the bits of the last frame are used for all the 16 frames in which the change occurs. The samples of that set of 16 frames can be wrong for the bins that lost their exponents. Change the table while the transmitter is in reset (``tx_reset`` = 1), or do not use the sets of 16 frames of the change.

**Buffer.** The buffer keeps the exponent of each sample beside the data, for the two banks. The exponent bits of a bin of a frame (``EXPONENT_BITS`` bits for each input, input 0 in the MSBs: 16 or 24 bits) are:

- the 8 MSBs in the byte that the data does not use in the 72-bit UltraRAM word of the bin;
- the other bits in more UltraRAMs with no cascade, read with the address of the data: 8 bits in 8 UltraRAMs with ``EXPONENT_BITS`` = 2, and 16 bits in 16 UltraRAMs with ``EXPONENT_BITS`` = 3.

One block RAM has, for each bin and each bank, the bit that tells that the bin has exponents (the OR of the bits of the 8 inputs, written again with each frame).

With ``EXPONENT_BITS`` = 3 the packetizer has all the 80 UltraRAMs of the device, and the buffers of UCAP are in block RAM (see the ``ct`` configuration).

**Controls** (0 after a reset):

- control byte 7, bit 7, ``tx_exponents``: the mode is on.
- control byte 7, bits 6:5, ``exp_block``: log2(*B*) - 1. The values 0, 1, 2 and 3 give one exponent for each group of 2, 4, 8 and 16 frames.
- control byte 0, bit 7, ``exp_field4`` (only with ``EXPONENT_BITS`` = 3): 1 = each exponent has 4 bits in the packet. 0 = 2 bits. This bit is in the byte that selects the target of the RAM writes (``bsb_ram_sel``, ``bsb_ram_bank``, ``bsb_ram_frame``): a write of that byte must keep it.
- control byte 0, bit 6 is not used (in an earlier build it selected a table of bins in the packetizer).

Change ``tx_exponents``, ``exp_block`` and ``exp_field4`` only while the transmitter is in reset (``tx_reset`` = 1). With ``tx_override_data`` = 1 the mode is off.

**Status:**

- status byte 0, bit 1, ``exp_field_over``: an exponent above 3 was sent with 2 bits (see below). ``tx_reset`` clears it.
- status byte 0, bit 2, ``exponent_bins_mismatch``: in one packet or more, the bins that got exponents were not the bins that the header of the packet gives (see "Check of the headers"). ``tx_reset`` clears it.
- status byte 3, ``exponent_bins_mismatch_count``: the number of these packets since ``tx_reset`` (it stops at 255). This byte is only in a build with ``EXPONENT_BITS`` > 0.

**Names in the host driver.** The driver of the host (corriscope, class ``UPACK``) has these fields with other names:

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - Field of this page
     - Driver
   * - ``tx_exponents``
     - ``TX_EXPONENTS``
   * - ``exp_block`` (the number of frames that have one exponent)
     - ``FRAMES_PER_EXPONENT_CODE``; ``set_frames_per_exponent(2, 4, 8 or 16)``
   * - ``exp_field4`` (4 bits for each exponent in the packet)
     - ``FOUR_BIT_EXPONENTS_IN_PACKET``; ``set_exponent_bits_in_packet(2 or 4)``
   * - status byte 0 bit 7 (``exp_field4_support``)
     - ``FOUR_BIT_EXPONENTS_AVAILABLE``
   * - status byte 0 bit 6
     - ``EXPONENT_PACKET_FORMAT_2``
   * - ``exp_field_over``
     - ``EXPONENT_TOO_LARGE_FOR_PACKET``
   * - ``exponent_bins_from_scalers``, ``exponent_bins_mismatch``, ``exponent_bins_mismatch_count``
     - The same names in capital letters

**Groups of frames.** The 16 frames of a bin of a packet are in groups of *B* frames, from frame 0 of the packet. For each input of a bin with exponents:

- *E*, the exponent of the group, is the largest exponent of the samples of the group.
- A sample with a smaller exponent *e* has each of its two 4-bit parts divided by 2\ :sup:`E - e` and rounded to the nearest integer. A tie goes to the even integer.
- The other samples do not change.

The samples must be in two's complement (the default of the scaler). The bins with no exponent are sent as they are in the buffer. The data bins of a packet are at the same offsets as in a packet with no exponents.

**Exponents at the end of the packet.** After the last data bin of a packet, the packetizer sends the exponents of the bins of the packet that have exponents, in the order of the bins:

- A bin gives 16 / *B* numbers, one for each group of frames, the first group first.
- Exponents of 2 bits (``exp_field4`` = 0): the number of a group has 16 bits, most significant byte first. Input *i* has the bits 15 - 2\ *i* and 14 - 2\ *i*. A bin gives 16, 8, 4 or 2 bytes for *B* = 2, 4, 8 or 16.
- Exponents of 4 bits (``exp_field4`` = 1, ``EXPONENT_BITS`` = 3): the number of a group has 32 bits, most significant byte first. Input *i* has the bits 31 - 4\ *i* to 28 - 4\ *i* (a value from 0 to 7). A bin gives 32, 16, 8 or 4 bytes for *B* = 2, 4, 8 or 16.
- These numbers follow each other with no gap. Then zeros follow to a multiple of **64 bytes**.
- A packet with no bin with exponents has no exponent bytes.

**Why a multiple of 64 bytes.** Each packet must have an even number of 32-byte words. The path to the 100G MAC (``cge``) puts two 32-byte words in each 64-byte word of its FIFO. If a packet ends in the first half of a 64-byte word and the next packet starts on the next clock, the first word of that next packet goes in the second half of the same 64-byte word. ``cge`` then gives this word to the MAC alone, with only its upper 32 bytes enabled, and the MAC does not send the packet: the packet after a packet with an odd number of words is lost. The packets with no exponents have an even number of words (2 for the header and 4 for each data bin). The playlist can give a header of 4 words (bit 13 = 1 on a header bin): this also keeps the number even.

**Exponents of 2 bits in a build with exponents of 3 bits.** With ``EXPONENT_BITS`` = 3 and ``exp_field4`` = 0, the host must limit the exponents of the scalers to 3 (``exponent_max`` of each scaler): the values are then from -56 to 56. If a group of frames has an exponent above 3, the packetizer sends 3, the samples of the group have the shift of the true exponent, and the status bit ``exp_field_over`` is set: the values of that group are wrong at the receiver.

**Pause after each packet.** With ``tx_exponents`` = 1 the packetizer waits after each packet. A packet of *W* words (*W* = 2 + 4 x data bins + words of exponents) then takes

    *W* + floor((*W* - 1) / 32) + 1 clocks.

Without the pause the packetizer sends 32 bytes on each clock (102.4 Gbit/s), which is more than the 100G link can send. The FIFO of ``cge`` (32 kB) then fills during the readout of a set of 16 frames, and the last packets are lost with no flag in the packetizer (only ``fifo_overflow_sticky`` of ``cge``). This was seen on a board with packets of 242 words. The link sends 31.25 bytes in the time of one clock, and a packet uses 24 more bytes on the link (preamble, CRC and the gap between packets). With the pause, packets of 97 words or more (the packets of the host have 194 or more) do not come faster than the link sends them. For some smaller packets (10 to 32, 52 to 64 and 94 to 96 words) the FIFO still gets 17 bytes or less for each packet. With ``tx_exponents`` = 0 there is no pause (the packets of 194 words fit in the FIFO).

The readout of a set of 16 frames must be complete when the next set is complete: 32,768 clocks. The 128 packets of the host with 48 data bins take, at most:

.. list-table::
   :header-rows: 1

   * - Packet
     - Words
     - Clocks for a packet
     - Clocks for 128 packets
   * - No bin with exponents
     - 194
     - 201
     - 25,728
   * - All the bins, *B* = 2, exponents of 2 bits
     - 218
     - 225
     - 28,800
   * - All the bins, *B* = 2, exponents of 4 bits
     - 242
     - 250
     - 32,000

**A readout that is not complete.** If a set of 16 frames is complete before the end of the readout of the set before, the flag ``overrun`` is set and the packetizer:

- stops the readout (its words that are on their way are sent; a readout keeps its bank to its end, so these words are words of its own frames);
- ends the packet in progress with one or two words of zeros, so that it has an even number of words (this packet is not correct: its length is not that of its header);
- adds ``timestamp_incr`` to the timestamp, as at the end of a complete readout;
- clears the state of the exponents and starts the readout of the new set 24 clocks after it was complete.

So the packets of the next sets are correct, and their timestamps are those of their frames.

**Reset of the transmitter.** No readout starts when ``tx_reset`` goes to 0. The first readout starts when the set of 16 frames in progress is complete, and its packets have the timestamp 0. (Without the exponent mode, and in earlier builds, a readout started at the end of ``tx_reset`` when the write side was in its second bank; the next set then found it not complete, the flag ``overrun`` was set in about one reset of two, and in the exponent mode the exponents of all the packets after that were those of other bins.)

**Timestamps.** The frames are written as with ``EXPONENT_BITS`` = 0: the frame in progress at the end of a reset of the packetizer is frame 0, also if it is not complete. A packet with a timestamp has the same frames as a packet of a build with no exponent mode.

**Check of the headers.** The packetizer does not write the headers. For each packet with ``tx_exponents`` = 1 it compares bytes 16 to 21 of the payload header (48 bits, little endian: bit *k* = 1 if data bin *k* of the packet has exponents; the host writes them) with the bins that got exponents. If they are not the same, ``exponent_bins_mismatch`` is set and ``exponent_bins_mismatch_count`` goes up by 1. Only the first 48 data bins of a packet are compared.

**Largest packet.** The exponents of a packet go through a FIFO: 31 words of 32 bytes with ``EXPONENT_BITS`` = 2 and 63 with ``EXPONENT_BITS`` = 3 (the word of zeros that makes the number even is not in the FIFO):

.. list-table::
   :header-rows: 1

   * - Bins with exponents in a packet, at most
     - *B* = 2
     - *B* = 4
     - *B* = 8
     - *B* = 16
   * - ``EXPONENT_BITS`` = 2 (exponents of 2 bits)
     - 62
     - 124
     - 248
     - 496
   * - ``EXPONENT_BITS`` = 3, exponents of 2 bits
     - 126
     - 252
     - 504
     - 1008
   * - ``EXPONENT_BITS`` = 3, exponents of 4 bits
     - 63
     - 126
     - 252
     - 504

The packets of the host have 48 data bins.

The end of the packet (``tlast``) is on the last word of the exponents, or on the last data word if there are no exponents.

**What the host must do:**

- write the table of the bins with no exponent to the 8 scalers, and nowhere else. This table has the bins in the order of the scaler, as the gain table of the scaler, and not in the order of the frequency (the driver changes the order of the bins of a gain table with ``natural_to_fft_order``; the playlist uses the same numbers; see `scaler`);
- write the lengths of the IP and UDP headers: the bytes of the exponents of the packet, with the zeros to a multiple of 64 bytes;
- write the header of the payload that identifies the format (byte 1 = 0x20 + log2(*B*) with exponents of 2 bits, 0x28 + log2(*B*) with exponents of 4 bits) and the bins (bytes 16 to 21, see "Check of the headers");
- set ``exponent_enable`` of the scalers and ``tx_exponents`` together;
- read ``exponent_bins_mismatch`` and ``overrun`` after some packets: they must be 0.

With ``tx_exponents`` = 0 the packets are those of a packetizer with ``EXPONENT_BITS`` = 0, 7 clocks later.
