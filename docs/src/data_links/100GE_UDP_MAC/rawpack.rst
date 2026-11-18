.. title:: RAWPACK

**************************************************************
:entity:`RAWPACK` (*rawpack.vhd*): Raw ADC sample streamer
**************************************************************

.. default-role:: vhdl:entity

Overview
========

`rawpack` streams raw ADC samples of one or two channels over the 100G Ethernet link as UDP
packets. It sends 12 bits for each sample: the 12 most significant bits of the 14-bit ADC sample.
It sits between `upack` and `cge`:

- When disabled (reset state), the `upack` stream passes through with one clock of latency.
- When enabled, the link carries the raw stream instead. The two streams are mutually
  exclusive: stop the `upack` transmitter before enabling `rawpack`. When `rawpack` is disabled
  again, the packet in progress is completed before the link is handed back.

The samples are taken from the capture bus that feeds `ucap` (8 samples per clock per channel),
so no extra logic is added to the channelizers. The data source of each channel (FUNCGEN output,
i.e. ADC samples or a test pattern, or SCALER output) is the one selected in `ucap`; `rawpack`
reports it in the packet header.

Data rates at 3.2 GS/s:

=============  ================  =============================  ======================
Mode           Sample data rate  Packets (64 blocks per packet) Sample times per packet
=============  ================  =============================  ======================
Two channels   76.8 Gb/s         1.5625 million per second      2048
One channel    38.4 Gb/s         0.78125 million per second     4096
=============  ================  =============================  ======================

A 3:4 gearbox packs the 192 bits received per clock into 256-bit words; the idle slot left
every 4 clocks is used to insert the two header words of each packet. A small elastic buffer
absorbs the header insertion.

Entity documentation
====================

.. parse:: hdl/data_links/100GE_UDP_MAC/rawpack.vhd

.. autoentity:: rawpack

Packet format
=============

All multi-byte header fields are big-endian. With the default 64 blocks per packet the Ethernet
frame is 6208 bytes long (without FCS), so the network path needs a jumbo MTU (9000).

===========  ==========================================================================
Bytes        Content
===========  ==========================================================================
0-13         Ethernet header: destination MAC, source MAC, ethertype 0x0800
14-33        IPv4 header: no options, DF set, TTL 64, protocol UDP, valid header checksum
34-41        UDP header. The checksum is 0 (not used).
42-43        Magic number 0x5241 ("RA")
44           Format version (2)
45           Flags: bit 0 = data source of channel A, bit 1 = data source of channel B,
             bit 2 = single-channel mode, bit 6 = framing error (sticky),
             bit 7 = internal FIFO overflow (sticky)
46           Bits 2:0 = channel A, bits 6:4 = channel B
47           Blocks per packet
48-53        Packet counter (48 bits), zero at reset
54-59        Frame number (48 bits) of the first sample; same counter as the `ucap` timestamp
60-61        Word number (0-2047) of the first sample in its frame. The first sample of the
             packet is sample 8 x word of that frame.
62           Stream number: incremented every time the stream starts, including a restart
             after a reset (which also zeroes the packet counter)
63           Reserved (0)
64...        Samples: 96 bytes per block
===========  ==========================================================================

The sample area is a little-endian bit stream: stream bit *n* is bit (*n* mod 8) of byte
(*n* / 8). Sample *i* of the packet occupies stream bits 12 *i* to 12 *i* + 11, least
significant bit first, so every 2 samples fill exactly 3 bytes. A sample value is the 14-bit ADC
sample divided by 4 (signed, -2048 to 2047). With two channels the samples
are interleaved in time order (A(t), B(t), A(t+1), B(t+1), ...); with one channel they are
A(t), A(t+1), ... A block is 64 samples: 32 sample times of two channels or 64 sample times
of one channel. The first packet after the stream is enabled starts on the first sample of a
frame; with 64 blocks per packet a frame is exactly 8 packets (4 in single-channel mode).

A receiver detects lost packets with the packet counter and places the samples in time with the
frame and word numbers.

Parameters
==========

- **DEFAULT_ENABLE / DEFAULT_SINGLE / DEFAULT_CHAN_A / DEFAULT_CHAN_B / DEFAULT_BLOCKS_PER_PACKET:**
  reset values of the corresponding registers.

- **DEFAULT_MAC_SRC_ADDR / DEFAULT_MAC_DEST_ADDR / DEFAULT_IP_SRC_ADDR / DEFAULT_IP_DEST_ADDR /
  DEFAULT_IP_SRC_PORT / DEFAULT_IP_DEST_PORT:** reset values of the addresses used in the packet
  headers. All can be changed at run time.

Registers
=========

`rawpack` is at port 6 of the top-level BSB router. The memory map is in the entity source
(control bytes 0-27, status bytes 0-8). Notes:

- ``blocks_per_packet`` (4 to 90) and ``single`` are taken into account only while the stream is completely stopped (status bit ``raw_active`` = 0). Host software should disable the stream and wait for ``raw_active`` to clear before changing them.
- ``src_port_mask`` adds the low bits of the packet counter to the UDP source port, so that the
  receiving network card spreads the packets over several receive queues. The receiver then has
  to put the packets back in order using the packet counter.

Simulation
==========

See :doc:`the testbench list </testbenches/index>`: ``rawpack_testbench`` (self-checking unit
test) and ``rawpack_cge_testbench`` (full-rate chain with `cge` and a behavioural model of the
100G MAC). Both are run with the scripts in ``xilinx_projects/testbenches/rawpack_testbench/``.
