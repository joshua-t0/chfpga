.. title:: RAWPACK

**************************************************************
:entity:`RAWPACK` (*rawpack.vhd*): Raw ADC sample streamer
**************************************************************

.. default-role:: vhdl:entity

Overview
========

`rawpack` streams raw ADC samples of one to four channels over the 100G Ethernet links as UDP
packets. It sends each sample with 12 bits (the 14-bit ADC sample rounded to 12 bits) or with 14
bits (the ADC sample with no change). The register ``sample_bits`` selects the number of bits at
run time; it is 12 after a reset. Each packet holds the samples of one channel. Each channel is a packet stream: streams A, B, C and D. A
receiver gets contiguous samples of a channel from each packet, and separates the streams with
the UDP destination port or with the stream number of the header.

A 100G link carries two streams, with 12-bit samples and with 14-bit samples. With ``NUMBER_OF_LINKS`` = 2, streams A and
B go to link 0 and streams C and D go to link 1, which has its own `cge` on the second hard MAC of
the device. ``stream_enable`` selects the streams that are sent.

On link 0, `rawpack` sits between `upack` and `cge`:

- While no stream of link 0 is in use (reset state), the `upack` stream passes through with one
  clock of latency. This is also the case while only streams C and D are sent: `upack` and the
  raw streams of link 1 can run at the same time.
- When stream A or B is enabled, link 0 carries the raw streams instead. The link changes hands
  only between two `upack` frames, so no `upack` frame is cut: `rawpack` sends the frame in
  progress to its end before its first packet (the stream FIFOs hold the data during that time,
  194 clocks at most), and `upack` gets the link back at the start of a frame, after the raw
  packets in progress are complete. The `upack` transmitter can thus stay on; its frames are not
  sent while stream A or B is on.
- If the `upack` transmitter is stopped in the middle of a frame (it does that when its
  ``TX_ENABLE`` is cleared) and stays stopped for 256 clocks while the raw streams wait for the
  link, `rawpack` closes that frame with one last word, so that the first raw packet is a frame
  of its own in `cge`.

The samples are taken from the capture bus that feeds `ucap` (8 samples per clock per channel),
so no extra logic is added to the channelizers. The data source of each channel (FUNCGEN output,
i.e. ADC samples or a test pattern, or SCALER output) is the one selected in `ucap`; `rawpack`
reports it in the packet header.

Data rates at 3.2 GS/s. A block is 64 samples of one channel; ``blocks_per_packet`` is the number
of blocks in a packet:

==============  =================  =================  ===============================  ===================
Streams         Rate of the        Rate of the        Packets (64 blocks per packet)   Samples per packet
                samples, 12 bits   samples, 14 bits
==============  =================  =================  ===============================  ===================
Four (2 links)  2 x 76.8 Gb/s      2 x 89.6 Gb/s      4 x 0.78125 million per second   4096 of one channel
Two (1 link)    76.8 Gb/s          89.6 Gb/s          2 x 0.78125 million per second   4096 of one channel
One             38.4 Gb/s          44.8 Gb/s          0.78125 million per second       4096
==============  =================  =================  ===============================  ===================

With the headers, the preamble and the gap between two frames, two streams of 14-bit samples use
90.7 Gb/s of a 100G link (with 64 blocks per packet), and two streams of 12-bit samples use
77.8 Gb/s.

For each stream, two consecutive input words (16 samples) are joined, and a gearbox packs these
into 256-bit words: 64 samples of 12 bits fill 3 words, and 128 samples of 14 bits fill 7 words.
The 12-bit samples are rounded first. Each stream has a block RAM FIFO (512
words) that holds its packets until they are sent. Each link has a sequencer: a packet is sent
when it is complete in its FIFO, and the streams of the link take turns, a packet of the first
stream, then the packet of the second stream that covers the same time. All the enabled streams
start on the same frame.

Entity documentation
====================

.. parse:: hdl/data_links/100GE_UDP_MAC/rawpack.vhd

.. autoentity:: rawpack

Packet format
=============

All multi-byte header fields are big-endian. With the default 64 blocks per packet the Ethernet
frame is 6208 bytes long with 12-bit samples and 7232 bytes long with 14-bit samples (without
FCS), so the network path needs a jumbo MTU (9000).

===========  ==========================================================================
Bytes        Content
===========  ==========================================================================
0-13         Ethernet header: destination MAC, source MAC, ethertype 0x0800
14-33        IPv4 header: no options, DF set, TTL 64, protocol UDP, valid header checksum
34-41        UDP header. The checksum is 0 (not used). The destination port is the
             ``port_dest`` of the link for its first stream and ``port_dest`` + 1 for its
             second stream.
42-43        Magic number 0x5241 ("RA")
44           Format version (4)
45           Flags: bit 0 = data source of the channel of this packet, bit 1 = the samples
             are rounded (1 with 12-bit samples, 0 with 14-bit samples), bits 5:2 = streams
             that are sent (bit 2 = A ... bit 5 = D), bit 7 = internal FIFO overflow (sticky)
46           Bits 2:0 = channel number of the samples of this packet. Bits 6:4 = stream:
             0 = A, 1 = B (link 0), 2 = C, 3 = D (link 1).
47           Blocks per packet (64 samples each), as the firmware uses it
48-53        Packet counter of this stream (48 bits). Zero on the first packet of each
             start from the stopped state, and after a reset.
54-59        Frame number (48 bits) of the first sample; same counter as the `ucap` timestamp
60-61        Word number (0-2047) of the first sample in its frame. The first sample of the
             packet is sample 8 x word of that frame.
62           Run number: incremented every time the streams start, including a restart
             after a reset. The packet counters restart at zero at the same time.
63           Number of bits of a sample: 12 or 14
64...        Samples: 96 bytes per block (12 bits) or 112 bytes per block (14 bits)
===========  ==========================================================================

The sample area is a little-endian bit stream: stream bit *n* is bit (*n* mod 8) of byte
(*n* / 8). With *B* bits in a sample (byte 63), sample *i* of the packet occupies stream bits
*B* *i* to *B* *i* + *B* - 1, least significant bit first.

- **12 bits:** every 2 samples fill exactly 3 bytes. A sample value is the 14-bit ADC sample
  divided by 4 and rounded to the nearest integer (signed, -2048 to 2047; a half goes up, and the
  largest value does not wrap).
- **14 bits:** every 4 samples fill exactly 7 bytes. A sample value is the 14-bit ADC sample
  (signed, -8192 to 8191). The firmware takes the 14 most significant bits of the 16-bit field of
  the capture bus for any data source. The 2 bits below are dropped and not rounded: an ADC
  sample has no information there.

The samples of a packet are in time order and belong
to one channel. A block is 64 samples. The first packets after the stream is enabled start on the
first sample of a frame; with 64 blocks per packet a frame is exactly 4 packets of each stream.
The packets of all streams with the same packet counter cover the same time: all the counters
restart at zero each time the streams start from the stopped state, so a run with fewer streams
does not put them out of step.

A receiver detects lost packets with the packet counter of each stream and places the samples in
time with the frame and word numbers.

Parameters
==========

- **NUMBER_OF_LINKS:** number of 100G links, i.e. of output buses (1 or 2).
- **PASS_THROUGH:** TRUE (default) if link 0 carries the ``s_axis_in`` bus while no raw stream
  uses it. FALSE if there is no such bus (corr8): the logic that shares the link is then removed.

- **DEFAULT_ENABLE / DEFAULT_STREAM_ENABLE / DEFAULT_CHAN_A ... DEFAULT_CHAN_D /
  DEFAULT_BLOCKS_PER_PACKET:** reset values of the corresponding registers.

- **DEFAULT_MAC_SRC_ADDR / DEFAULT_MAC_DEST_ADDR / DEFAULT_IP_SRC_ADDR / DEFAULT_IP_DEST_ADDR /
  DEFAULT_IP_SRC_PORT / DEFAULT_IP_DEST_PORT:** reset values of the addresses used in the packet
  headers of link 0. The same names with ``_1`` are those of link 1. All can be changed at run time.

Registers
=========

`rawpack` is at port 6 of the top-level BSB router. The memory map is in the entity source
(control bytes 0-54, status bytes 0-31). With two links, the registers of the second `cge` are in
the same port, at the addresses with bit 15 set, and `SYSTEM` reports 8 GPU links (4 lanes for
each 100G link). Notes:

- ``blocks_per_packet`` (4 to 90), ``stream_enable`` and ``sample_bits`` are taken into account only while the streams are completely stopped (status bit ``raw_active`` = 0). Host software should disable the streams and wait for ``raw_active`` to clear before changing them. A value that is written while the streams run has no effect until they are stopped.
- ``sample_bits`` (control byte 54) is the number of bits of a sample: 12 (after a reset) or 14. Another value gives 12. Status byte 28 gives the number that the firmware uses, and status byte 30 bit 1 tells that the firmware can send 14-bit samples.
- With 14-bit samples a packet must have a multiple of 4 blocks, 76 at most: 128 samples fill 7 words of 256 bits, the path to the 100G MAC takes two words at a time, and 76 blocks (8512 bytes of samples) is the largest packet for an MTU of 9000. The firmware uses the multiple of 4 below the value of ``blocks_per_packet`` (4 at least, 76 at most). Status byte 31 and byte 47 of each packet give the number that it uses. The default of 64 blocks is 4096 samples in a packet with 12 bits and with 14 bits.
- With 14-bit samples and two streams on a link, use 16 blocks per packet or more. The sequencer of a link needs 4 clocks more than the words of a packet, so two streams of 14-bit samples need 8 blocks per packet at least; with 8 blocks the link is at 98 % of its rate (the simulation with the model of the 100G MAC has no error with 8 blocks). One stream on a link can have 4 blocks per packet.
- The FIFO of a stream (512 words) holds 387 words at most with the largest packets of 14-bit samples and two streams on the link, also when the link comes from the ``upack`` stream (375 words with the largest packets of 12-bit samples). The streams need no more memory for 14-bit samples.
- With 12-bit samples use an even ``blocks_per_packet``: an odd value gives a packet with an odd number of 256-bit words. The firmware does not change the value in this case.
- Status bytes 27 to 31 describe the firmware: number of streams and links, number of bits of a sample, format version, rounding, and the blocks per packet in use.
- ``src_port_mask`` adds the low bits of the packet counter to the UDP source port, so that the
  receiving network card spreads the packets over several receive queues. The receiver then has
  to put the packets back in order using the packet counter.

Simulation
==========

See :doc:`the testbench list </testbenches/index>`: ``rawpack_testbench`` (self-checking unit
test, one checker for each link) and ``rawpack_cge_testbench`` (full-rate chain with one `cge` and
one behavioural model of the 100G MAC for each link). Both are run with the scripts in ``xilinx_projects/testbenches/rawpack_testbench/``.
