.. title:: BCT_Engine

********************************************************************
:entity:`BCT_Engine` (*bct_engine.vhd*): Kintex-7 Corner-turn engine
********************************************************************


.. toctree::
   :titlesonly:
   :hidden:

   chan_crossbar
   ../../data_links/xglink/xglink_array
   shuffle_crossbar
   ../../navbar_separator

.. parse:: hdl/CROSSBAR/bct_engine.vhd
.. default-role:: vhdl:entity



The BCT Engine is is the corner-turn engine typically used for 7-Series FPGA platforms. It uses 7-Series BRAM and FIFO primitives when XPM macros can't be used, has a 32-bit data bus per lane, and uses GTX (10 Gbps) transceivers for sharing data between boards.  The mapping of the bins to the output lanes is almost fully user-configurable. The BCT Engine expects the F-Engine to issue data for two bins per clock in (4+4) or (8+8)-bit format (the later to be used in bypass modes only), and allows ADC, FFT and SCALER overflow flags to be grouped and send as a block at the top of the payload.


The BCT Engine system consists of:

- :doc:`bct_engine`: Main BCT engine module
- :doc:`chan_crossbar`: First stage corner-turn crossbar (channelizer crossbar)
- :doc:`shuffle_crossbar`: Second and third stage corner-turn crossbars
- :doc:`chan_bin_sel`: Bin selector used in the channelizer crossbar
- :doc:`shuffle_bin_sel`: Bin selector used in shuffle crossbars
- Supporting FIFOs and memory modules for data buffering and flag handling


The corner turn engine can be configured in software to reorder F-Engine data from single board, a single crate, or a pair of crates. It also allow various bypass modes to stream raw channelizer in real time when the output is connected to a high-speed link.

The supported modes of operation:
   - ``shuffle512``:  Corner-turns the F-Engine data from 2 crates (512 analog channels). Each board produces 8x 10G Ethernet streams, each containing (4+4)-bit channelizer data for 4 bins x 512 channels.
   - ``shuffle256``:  Corner-turns the data from 1 crate (256 analog channels). Each board produces 8x 10G Ethernet streams, each containing  (4+4)-bit F-Engine data the F-Engine data for 8 bins x 256 channels.
   - ``shuffle16``:  Corner-turns the F-Engine data from a single board (16 analog channels). Each board produces 8x 10G Ethernet streams, each containing (4+4)-bit F-Engine data for 128 bins x 16 channels.
   - ``chan8``: Streams the (8+8) data from half (8) of the board's F-Engine to 8 of the 10G Ethernet ports (6.4 Gbps per lane)
   - ``chan4``: Stream the (4+4) data from all the 16 channelizers to 8 of the 10G Ethernet ports (6.4 Gbps  data per lane)
   - ``corr16``: Corner-turns the data from a single board (16 analog channels) and feeds the data to an internal N^2 firmware correlator.

The corner-turn operations are performed in five stages:

1) The first crossbar, (channelizer crossbar `chan_crossbar`) takes the output of 16 on-board channelizers, realigned the data frames, exchanges and reorganizes the data between those, packetizes frames into packets with headers, data flags, frame flags, and produce 16 streams of data.
2) The backplane PCB links transmit 15 of the streams to other boards in the same crate, and receives data from those crates as well. The stream from lane 0 is passed directly to the next stage in the same FPGA.
3) The second crossbar (shuffle_crossbar) takes the data from the local lane and the 15 remote lanes, realigns the packets, and reorganizes the data in 8 streams.
4) The backplane QSFP links transmit 4 of those streams to the corresponding board in another crate, and receives 4 streams from those boards. Lanes 0-3 are passed directly to the next stage.
5) The 3rd crossbar (another shuffle crossbar) takes the data from the 4 local lanes and 4 remote lanes, realigns the packets, and reorder their contents into 8 streams.

The 8 resulting streams are then fed to 8 10G Ethernet packetizers/transmitters that send their data through two QSFP+ connectors.

The modules that implement each of these stages are configured differnetly by software depending on the desired mode of operation.


Entity documentation
--------------------


.. autoentity:: bct_engine




..    - Corner turn engine (Used in CHIME)
..       - :entity:`chan_crossbar` : 1st corner-turn engine (takes data from the channelizers)
..       - :entity:`shuffle_crossbar` : 2nd and 3rd corner-turn engine (takes data from a previous crossbars)
..       - :entity:`backplane-shuffle`: Sends and receive packets to other boards over the backplane and QSFP+ cables

   chan_crossbar: 1st corner-turn engine (takes data from the channelizers) <chan_crossbar>
   backplane-shuffle: Sends and receive packets to other boards over the backplane and QSFP+ cables <backplane_shuffle>
   shuffle_crossbar: 2nd and 3rd corner-turn engine (takes data from a previous crossbars) <shuffle_crossbar>

   .. chdist_data_embed_fifo
   .. chdist_frame_fifo
   .. chdist_scaler_flag_fifo
   .. crossbar
   .. mask_ram
   .. shuffle_crossbar_align_fifo


Overall operation
=================

Clocking
--------

The corner turn engine operates on a single clock. All input and output data buses operate on this clock. A multi-clock design was used in the past, but although that allowed the aligner to also act as a clock-domain-crossing FIFO between the channelizer and the corner-turn internal logic, that caused the clock domains to be physically fragmented and caused the design to run out of clocking resources (buffers and clock lines).

The first step of the corner-turn engine is to packetize the data into packets containing headers and flags in addition of the 200 Mwords/s of incoming data.  Since the design maintains a 32-bit wide data bus, we need a slightly faster word clock to handle the header and flag overhead. Beyond that, the clock frequency is arbitrary, as and interfaces to the GTX transmitters and receivers are buffered with asunchronous FIFOs. We could use a 250 MHz clock generated by the FPGA's PLL, but we opted to use the 244 MHz word clock that is generated internally by the backplane PCB and QSFP GTXes.

The backplane links (both the PCBa nd QSFP) operate at the same signalling rate of 50x the 50x the 156.25 reference clock = 7.812 Gbit/s, resulting in a word clock of  50*156.25/32=244.140625 MHz.
This considerably relaxes the FPGA timing constraints and improves the GTX signal integrity compared the the next up multiplier of 66x (322.265625 MHz, 10.3125 Gbits/s).


Channelizer crossbar
--------------------

The crossbar consist of an array of 16 bin selectors (`CHAN_BIN_SEL`).

The channelizer frame aliger is pretty simple since  the data it receives is reliable, i.e. there is no possibility of
packet loss or malformed packets since it is coming directly from the
channelizers. However, each channelizer operates on a separate clock phase,
and even each channelizer resynchronizes the data to the corner turn clock,
the frames are not garanteed to arrive at the same time because each
channelizer operate independently and is not aware of the data statis of the
other ones. This simplifies routing considerably. The aligner stored the
incoming data in a FIFO and outputs words from all the FIFOs simultaneously
only when they all have valid data (basically it is all done by an
``and_reduce(fifo_tvalid)`` operation).

The channelizer bin selectors each selects a fraction of the bins from all
channelizers, and geterates a structured packet consisting of a header, att
the selected data words from all bins, all data flags for all bins, a frame
flag word, and a packet flag word.

To save resources, the channelizer crossbar does not have a lane remapper.
Assignment of the proper bins to the correct output lanes is instead done by
configuring the bin selection map appropriately.

Shuffle crossbars
-----------------

Shuffle crossbars receive packetized data (with headers and flags), as opposed
to the channelizer crossbar who receives raw channelizer data. Processing of
the data is different. It is simpler because the data is already grouped  is
data, flags etc. and we can use a single FIFO per input lane to store the
data, data flags and frame flags, and we don't have to worry about packaging.
However, we have to deal with frame alignment, because the process of
transmitting data over the PCB and QSFP links with the GTX might introduced
malformed or missing packets which need to be dealt with to allow the pipeline
to recover automatically in the case of such occurences.

The 2nd corsbar acceps data from 16 PCB lanes (1 direct, 15 GTX). Data is
aligned, remapped, and is selected by **two** bin selectors, each of which
have 4 outputs. This means that all four outputs ona single bin selector share
the same bin selection map. This configuration simplifies the logic and
resource usage (especially BRAM), and is flexible enough to support both
shuffle256 and shuffle512 modes, but in both  cases further bin selection is
needed from the 3rd crossbar.

The 3rd corsbar accepts data from 16 backplane QSFP lanes (4 direct, 4 GTX).
Data is aligned, remapped, and is selected by 8 bin selectors, each of which
have a single output. Each output feed on eof the 8 lanes of the 10G Ethernet
transmitter connecter to the two **motherboard** QSFPs for offloading the data
to the node.

The shuffle bin selectors can combine data words. It does that on the FIFO
readout process. This does not involve adding an extra FIFO read cycle (as it
was the case for the channelizer bin selector) because the data flags to be
combined are already present simulaneously at the output of all the FIFOs, and
can then be combined by reading them two at a time on each clock.


``shuffle16`` mode
==================

In shuffle16 mode, each of the 8 links provided by the two motherboard QSFPs
output data for 128 bins, each bin containing the data from 16 channels. The
data for each channel is a byte, representing the FFT output as a (4+4) bit
compler number.

In this mode, we use only the first 8 `chan_bin_sel` crossbars (out of 16) to
pick up 1024/8=128 bins each out of the 16 channelizer outputs. The output of
these bin selectors is sent directly to the 8 QSFP 10GE transmitters by
bypassing the PCB shuffle (16 lane wide), 2nd crossbar (8 lane wide), QSFP
shuffle (8 lane wide) and 3rd crossbar (8 lane wide). The output of the last 8
channelizer bin selectors is discarded.

Channelizer bin selector
------------------------

Each of the 16 `chan_bin_sel` selects data from lane groups 0-3
(i.e. lanes 0-15). They each select 1 out of every 8 bins from all of these 16 input channels. In total, each bin selector has accumulated 1/8 of the bins, i.e. 1024/8 = 128 from all 16 channelizers.
Bin selector inputs are  interleaved, i.e. bin_sel[0] selects bins 0,8,16..., bin_sel[1] selects bins 1,9,17... etc. The first 8 bin selectors [0-7] therefore capture all the data. The data from the last 8 bin selectors is redundant and will not be used. The logic does not offer the capability to disable unused lanes to save power.


There are a total of 128 selected bins. Each bin contains 16 1-byte sample from each channel. There are therefore 4 words per bins.

There are 16 data flags per bin. However, the minimum unit of transmission is a 32-bit word, so the data flags would fill only half the word. However, because we have selected 128 bins, we don't have the bandwidth to  send half-filled data flag words. Indeed, this would require sending one word of data flag for each 4 words of data, i.e. a 25% overhead (excluding the additional overhead of the header, frame flags and packet flags, which are much smaller overheads). The corner-turn engine is clocked at 244 MHz, but the data is coming at 200 MHz, so can process only a 1-244/200 = 22% overhead.


In order to handle the case of 128 bins/frame, the channelizer bin selector has the capability to
combine the data flags from two consecutive bins in a single word.  This brings down the overhead to 12.5%, which is within the capability of the corner-turn engine. The first crossbar flags combining is not used in modes where downstream crossbars need to further separate bins, which would be harder if the flags of two bins are combined


rate to fit within the corner turn's engine internal data bus bandwidth (see
discussion in `CHAN_BIN_SEL`). The combined words cannot be split apart
by the bin selection of downstream bin_selectors, but there is no need to
since those will be bypassed.





The packet size at the output of the 1st crossbar is::

   Payload size =  [(4 header words/frame) (1 frame/packet) *{(128 bins/frame) * [ (4 data words/bin) + (0.5 data flag word/bin)] + (1 frame flags word/frame)} * (1 frame/packet) + (1 packet flags/packet)]
      For 1 frames/packet, with flags: = 2328 bytes # Confirmed with wireshark & tcpump
      For 2 frames/packet, with flags, (4+2*(128*(4+.5)+1)+1): 1159 words, 4636 bytes
      For 2 frames/packet, no flags, (4+2*(128*(4+0)+0)+1): 1029 words, 4116 bytes


Output packet format
--------------------

In ``shuffle16`` mode, the backplane PCB link data shuffle, 2nd crossbar,
backplane QSFP link shuffle, and 3rd crossbars are bypassed and pass the 1st
crossbar 8 outputs directly to the 8 10G Ethernet tranmitter connected to the
motherboard QSFPs.

The packet format is as follows (assuming one frame per packet):

    - Header: 4 words (16 bytes) for the header
    - Data block: 128 bins x 16 channels = 2056 bytes
    - Data flags block: We combine the data flags, so scaler flags
      from two consecutive bins are combined into a single 32 bit
      word ( one bit per channel for each of the 2 bins). This represents 128*16/32=64 words = 256 bytes
    - Frame flags: 16 bit FFT overflow + 16 bit ADC overflow flags per frame. This is 1 word = 4 bytes.
    - Packet flags: 32 bit word (4 bytes)
    - Total: 2328 bytes


The output data rate on the 10G links are:

   - For 1 frame/packet, with flags::

      UDP Packet size: 2328 bytes
      Ethernet frame size = int(UDP Payload) + 42 + 7) /8) * 8 = 2376 bytes # confirmwd with wireshark
      Ethernet bandwidth = (2376 *8 bits/frame) / (2.56e-6 s/frame) = 7.425 Gbit/s

   - For 2 frames per packet, with flags::

      UDP payload: 4636 bytes # confirmed by tcpdump & wireshark
      Ethernet frame size:  4680 bytes # confirmed by wireshark & logs
      Ethernet Bandwidth: = 7.3125 Gbit/s # configmed with bmon

   - For 2 frames per packet, no flags::

      UDP payload: 4116 bytes # confirmed by tcpdump & wireshark
      Ethernet frame size:  4160 bytes # confirmed by wireshark
      Ethernet Bandwidth: 6.500 Gbit/s # configmed with bmon



``shuffle256`` mode
===================

In ``shuffle256`` mode, all 16 bin selectors of the channelizer crossbars are used to feed the 16 PCB data shuffle lanes. Each crossbar captures 1/16 of the bins, and therefore contain 1024/16=64 bins in total. Each bin still comprises of the data from all 16 channels and fit in 4 words.

Data/scaler flags of consecutive bins are **not** combined by the shiffle bin selectors. Only half of the data scaler word that represent each bin is populated. This will allow the next crossbar to further downselect bins.

The data rate at the output of the channelizer bin selectors is about half of what it was in ``shuffle16``, so there is no concern for bandwidth here::

   Payload size=  (4 header words/frame) + (N frame/packet) * {(64 bins/frame) * [ (4 data words/bin) + (1 data flag word/bin (half filled))] + (1 frame flags word/frame)} + (1 packet flags word/packet)]

      For 1 frame/packet, no flags: 261 words ((4+1*(64*(4+0)+0)+1))
      For 2 frames/packet, with flags = 647 words, x4 = 2588 bytes, *8*frame_rate/{N frames/packet) = 4.04375 Gbit/s # Confirmed with wireshark & tcpump
      For 2 frames/packet, no flags: 516 words, 2064 bytes


Since the connectivity of the PCB links between two slots varies from slot to slot, and since the channelizer crossbar does not have any lane remapping capability, the bin selection maps of each bin selector must be customized in order to make sure that the right bins end up at least in the right slot (i.e. bins 0,16,... on slot 0, bins 1,17,... on slot 1 etc). The map is therefore created using the knowledge of the backplane connectivity. Even if we do that, we can't control on which lane of the destination slot the data will arrive in; fixing that is the role of the second crossbar remap operation which will reorder the lanes such that post-remap lane 0 gets its data from slot 0,  lane 1 from slot 1 etc...

In ``shuffle256`` mode, the backplane PCB shuffle is operated normally. Lane
0 is the direct, internal one, and is assumed to suffer no packet loss, and is
therefore used by the 2nd crossbar aligner as a reference to align the
packets. The latency of lane 0 is therefore much shorter than that of lanes
1-15 which go through the GTX logic. Data is transmitted at the 156.25*50 =7.812 Gbit/s.

The 2nd crossbar receives packetized data from the one direct and 15 GTX links, realigns the data on the direct link (always lane 0), and remaps (reorders) the lanes to account for the backplane connectivity so the bin selectors can pack data in order from lane 0 to lane 15. Since there are only two 4-output bin selectors, we cannot do the final corner-turn operation of splitting the data in 8 ways with each of the 8 output having a different set of bin because both bin selectors use the same bin selection map. We need the 3rd crossbar to finish the job. This means the the second crossbar role is to combine the 16 input lanes into 8 output lanes, but we need the output lanes to still represent different channels that the 3rd crossbar will finally combine.

For this reason, each of the output lanes of the bin selector 0 is set-up to combine bins from half of their associated lanes: output lanes 0,1,2 and 3 combines input from lane 0-1, 4-5, 8-9, and 12-13   respectively. Bin selector 1outputs  combines data from lanes 1-2, 5-6, 9-10 and 13-14. So each output lanes combines data from 2 input lanes, but we select every bin (i.e. 64 bins), so we end up with twice the data. This makes sense since overall we are merging the 16 input lanes into 8.

Note that the  2nd crossbar is configured to combine the data flag words, which wasn't done by the channelizer bin selectors.

The packet size at the output of the 2nd bin selectors is::

   Payload size =  (4 header words/frame) + (N frame/packet) * {(64 bins/frame) * [ (8 data words/bin) + (1 data flag word/bin (fully filled))] + (2 frame flags word/frame)} + (1 packet flags word/packet)]
      For 1 frame/packet, no flags: 517 words  (4+1*(64*(8+0)+0)+1) (checked on CB3)
      For 2 frames/packet, with flags= 1161 words, 4644 bytes
      For 2 frames/packet, no flags= 1028 words, 4112 bytes

The backplane QSFP data shuffle is bypassed in this mode. The 8 output lanes of the 2nd crossbar are connected directly to the 8 inputs of the 3rd crossbar.

The 3rd crossbar remap reorganizes the lanes so the 8 input lanes of the bin selectors to undo the interleaving of the 2nd crossbar. The bin selectors then combine data from all remapped 8 input lanes, from lane 0 to lane 7, and selects 1/8th of the bins. We end up with 64/8=8 bins per output lanes, with each bins containing data from 32*8=256 channels.

The data packet size at each output of the 3rd crossbar is::

   Payload size:  (4 header words/frame) + (N frame/packet) * {(8 bins/frame) * [ (64 data words/bin) + (8 data flag word/bin (fully filled))] + (16 frame flags word/frame)} + (1 packet flags word/packet)]
      For 1 frame/packet, no flags: 517 words (4+1*(8*(64+0)+0)+1), 2068 bytes (checked on TCPDump)
      For 1 frame/packet, with flags: 597 words, 2388 bytes
      For 2 frames/packet, no flags: 1029 words (4+2*(8*(64+0)+0)+1), 4116 bytes
      For 2 frames/packet, with flags: 1189 words, 4756 bytes

The Ethernet packet size and data rate at the output of the 10G transmitter are:

   - For 1 frame/packet, no flags::

      Ethernet frame size: 2112 bytes
      Ethernet data rate: 2112 * 8/2.56e-6 = 6.600 Gbits/s (hard to measure with bmon)

   - For 1 frame/packet, with flags::

      UDP payload size: 2388 bytes (confirmed with TCPdump)
      Ethernet frame size: 2432 bytes (confirmed with wireshark)
      Ethernet data rate: 2432 *8/2.56e-6 = 7.600 Gbits/s (hard to measure with bmon)

   - For 2 frames/packet, no flags::

      UDP payload size: 4116 bytes (confirmed with TCPdump)
      Ethernet frame size: 4160 bytes
      Ethernet data rate: 4160 * 8/2.56e-6/2 = 6.500 Gbits/s (confirmed with bmon)

   - For 2 frames/packets, with flags::

      UDP payload size: 4756 bytes (confirmed with tcpdump)
      Ethernet frame size: 4800 bytes (4756+42+7)//8*8) (confirmed with wireshark)
      Ethernet data rate: 4800 *8/2/2.56e-6 = 7.500 Gbits/s (confirmed with bmon)


``shuffle512``
--------------

in ``shuffle512`` mode, the 1st crossbar and PCB shuffle is identical to the ``shuffle256`` mode, with identical packet sizes.

However, the 2nd crossbar is configured differently. The 3rd crossbar now needs to split data in a way that half the channels will go to the other crate. Do do this, each output of the bin selectors are set to gather data from all 16 input channels, but they select only half of the bins. The 4 outputs of bin selector 0,1,2 and 3  therefore contains 32 bins from lanes 0-3, 4-7, 8-11 and 12-15. Bin selector 1 contains the other bins from the other channels.

The backplane QSFP shuffle passes the 4 first lanes 0-3 directly to the 3rd crossbar lanes 0-3.  The odd-selected bins are sent to the other crate through the GTX links connected to the QSFP cables between the crates. The even crate bin selection map is configured to send its odd bins to the other crate and keep the even bine. The odd-numbered crate kepps the odd bine and send over the even bins.

In the end the 3rd crossbar receives all the even- or odd-selected bins in its 8 lanes. Even crates do not need to remap. Odd crates needs to remap so as to read the remote data (lower channel numbers) before the local data (higher channel numbers) to preserve the channel ordering within bins.  Each 8 bin selector selects 1/8th of the bins from the 8 input lanes, and feed the corresponding 10G Ethernet offload link.

The packet size at the output of the 2nd bin selectors is::

   Payload size =  (4 header words/frame) + (N frame/packet) * {(32 bins/frame) * [ (16 data words/bin) + (2 data flag word/bin (fully filled))] + (4 frame flags word/frame)} + (1 packet flags word/packet)]
      For 1 frame/packet, with flags:
      For 2 frames/packet, with flags, (4+2*(32*(16+2)+4)+1): 1165 words, 4660 bytes (as reported by CB3 monitor)
      For 2 frames/packet, no flags= 1028 words, 4112 bytes (CB3 reports 1013 words from CB2)


The output of the 3rd crossbar:
   Payload size =  (4 header words/frame) + (N frame/packet) * {(4 bins/frame) * [ (64 data words/bin) + (16 data flag word/bin (fully filled))] + (32 frame flags word/frame)} + (1 packet flags word/packet)]

      For 2 frames/packet, no flags, (4+2*(4*(128+0)+0)+1): 1029 words, 4116 bytes
      For 2 frames/packet, with flags, (4+2*(4*(128+16)+32)+1): 1165 words, 4884 bytes


10G Ethernet output:

   For 2 frames/packet, no flags:
      USP payload: 4116 bytes (confirmed with tcpdump)
      Ethernet packet size: 4160 bytes (confirmed with wireshark)
      Ethernet data rate: 6.500 Gbits/s (confirmed with bmon)
   For 2 frames/packet, with flags:
      USP payload: 4884 bytes (confirmed with tcpdump)
      Ethernet packet size: 4928 bytes (confirmed with wireshark)
      Ethernet data rate: 7.700 Gbits/s (confirmed with bmon)




