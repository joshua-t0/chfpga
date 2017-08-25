Corner-Turn Engine
******************

The corner turn engine takes the packets coming out of all the F-Engine (channelizers) in a set of boards and shares them with other boards and reorganizes them in such a way to produce packets that contain data from all channelizers, but for a subset of the frequency bins.

The corner turn engine is flexible enough to allow repacketizing of channelizer data from single oard, a single crate, or a pair of crates. It also allow various bypass modes to stream raw channelizer in real time.

The supported modes of operation:
   - `shuffle512`:  Reorders the data from 2 crates/512 analog channels so that each board produces eight 10G Ethernet streams of 4 bins / 512 channels of (4+4) bit FFT data.
   - `shuffle256`:  Reorders the data from 1 crate/256 analog channels so that each board produces eight 10G Ethernet streams of 8 bins / 256 channels of (4+4) bit FFT data.
   - `shuffle16`:  Reorders the data from a single board (16 analog channels) and produces eight 10G Ethernet streams of 128 bins / 16 channels of (4+4) bit FFT data.
   - `chan8`: Stream the (8+8) bits spectrum from half (8) of the channelizers to 8 of the 10G Ethernet ports (6.4 Gbps ofactual data per lane)
   - `chan4`: Stream the (4+4) bits spectrum from all the 16 channelizers to 8 of the 10G Ethernet ports (6.4 Gbps  data per lane)
   - `corr16`: used to feed the embedded 16-channel firmware correlator, which streams the integrated results through the 1 Gbps Ethernet control port.

The corner-turn operations are performed in six stages:

1) The first crossbar, (channelizer crossbar `chan_crossbar`) takes the output of 16 on-board channelizers, realigned the data frames, exchanges and reorganizes the data between those, packetizes frames into packets with headers, data flags, frame flags, and produce 16 streams of data.
2) The backpane PCB links transmit 15 of the streams to other boards in the same crate, and receives data from those crates as well.
3) The second crossbar (shuffle_crossbar) takes the data from the 15 other boards and the local stream, realigns the packets, and reorganizes the data in 8 streams.
4) The backplane QSFP links transmit 4 of those streams to the corresponding board in another crate, and receives 4 streams from those boards.
5) The 3rd crossbar (another shuffle crossbar) takes the data from the 4 links and the 4 local streams, realigns the packets, and reorder their contents into 8 streams.
6) The 8 streams are fed to 8 10G Ethernet packetizers/transmitters that send their data through two QSFP+ connectors.

The modules that implement each of these stages are configured differnetly by software depending on the desired mode of operation.

.. toctree::

   chan_crossbar
   xglink_array
   shuffle_crossbar
   xge_array

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


