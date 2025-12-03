.. title:: UCAP

*********************************************************
:entity:`UCAP` (*ucap.vhd*): UltraRAM-based data capture
*********************************************************

Overview
--------

UCAP periodically captures raw data frames coming from eight 128-bit AXI-Stream channels and streams  out the totality of the captured data  through a single 8-bit AXI stream bus. This module is typically used to capture raw ADC of FFT data from the 'CHAN' module and stream it through UDP packets over a Gigabit Ethernet interface.


Features
--------

- `UCAP` is a centralized capture engine , as opposed to a channelizer-based capture engine.
- It makes use of the Ultrascale UltraRAM blocks to allow capture of long frames of high bit-width data samples.
- Operation of `UCAP` is configured over a memory-mapped interface through a Byte-serial bus (BSB)
- `UCAP` nominally can capture data from 8 channels simulatenously. It can however be configured by software to capture a larger number of contiguous frames from a smaller number of user-selectable channels

    - 2 contiguous frames from all 8 channels (where one frame = 16384 samples @ 16-bit/sample)
    - 4 contiguous frames from 4 user-selectable channels
    - 8 contiguous frames from 2 user-selectable channels
    - 16 contiguous frames from one user-selectable channel

- Each channel can represent one of 2 data sources. The data source is selected at the source through a source selection bit provided by `UCAP` to each source. Each channel can have a different source from the others. In order to reduce the routing burden, the source selection bit is provided to a remote multiplexer which performs the source selection.
- `UCAP` continuously keeps track of the frame number of each souce, independent of which source is selected. The capture triggers are also independently generated for each source. This allow switching back and forth between sources while maintaining the timing of the capture of each source.
- `UCAP` ensures that the current frame is completed and that data capture starts on the first frame of the new source when the source is changed by the user.
- Data is captured at a base period that can be set to any number of frames. `UCAP` must be reset if that base rate is changed.
- In order to allow dynamic capture rate changes (e.g. during instrument calibration periods), a power-of-two sub-capture period can be set at any time to increase the number of captures within the base period. The sub capture period corresponds to ``2^(N+1)`` frames starting at the beginning of each base capture period. The sub rate can be changed at any time without resetting `UCAP` while ensuring there will be always be a capture every ``frame_number = k * base_rate frame``.


Limitations
-----------

- All sources must be synchrounous, i.e. they all operate on a single clock.
- Data from the same source must have the same packet alignments; all packets from source 0 on all channels must start and end on the same clock. Same for the source 1.



Schematic
---------

.. .. figure:: ../images/ucap.svg
..     :width: 50%

.. parse:: hdl/CHAN/ucap.vhd

.. toctree::
   :titlesonly:


Entity documentation
--------------------

 .. autoentity:: UCAP


Principle of operation
----------------------

Number of input channels
........................

Although we use the generics NUMBER_OF_CHANNELS to represent the number of input channels, this is done mostly for clarity of the code. In practice, the current structure of the code makes UCAP capable of operating only on 8 data inputs, mainly for simplicity. Some of the sources for this limitation are:

- The mode number is fixed to 2 bits.
- The channel multiplexer that maps the input channels to the memory bank is optimized to operate efficiently on 8 input channels.
- In the CHORD configuration of ``chfpga``, there are only 16 URAM blocks available to `UCAP`, meaning we can only handle up to 8 channels.

Number of input sources
.......................

The number of input sources for each input channel is hard coded to be 2. The logic assumes at various  places in the code that the source is represented by a single bit, such as:

- the source selection register
- source selection signal sent to the remote mux

Streaming input sources
.......................

Each channel provides data using a 128-bit (16-byte-wide) AXI-streaming bus. The meaning of the data within the 128-bit word depends on assignments made by the remote multiplexer. The bus width was chosen to be  wide enough to capture 12-, 14- or 16-bit ADC samples presented 8 samples at a time.

Streaming output width
......................

The streaming output is coded for a 8-bit-wide AXI-Streaming bus only, as the intended target is a 1G Ethernet link that is saturated by a byte-wide bus operating at a very modest 125 MHz output clock . This is currently fixed by the logic that reads the 128-byte outputs byte-by-byte, although the code could be modified to read 2, 4 or even 8 bytes at a time for transmission through a faster link.

Output packet format
....................

The data from each data frame is split in 4 packets in order to keep the packet size within the limit of typical Ethernet 9k  jumbo frames. Each packet contains a 10-byte header followed by 8192 bytes of data (4096 16-bit samples).

Each output packet contains:

- Byte 0: 8-bit PROBE ID, which is ``0xA0`` for source 0 and ``0xA1`` for source 1
- Bytes 1-2: 16-bit STREAM ID. Identifies the source of the data. MSB is sent first.
    * Bit 15:12: Frame number (0 - N-1, where n=2,4,8,16  in 8, 4, 2 or 1 channel mode respectively)
    * Bits 11:3: zeros
    * Bits 2:0: Channel number
- Byte 3: Flags
    * Bits 7:4: Serial flags (all zeros)
    * Bits 3:2: Current mode (0=8 channel mode, 1=4 channel mode, 2=2 channel mode, 3=1 channel mode)
    * Bits 1:0: Packet number for the captured frame (0-3)
- Bytes 4-9: 48-bit Frame number, (a.k.a timestamp), MSB transmitted first

The data follows the header. 128-bit data words are sent in the natural order they are produced by the source. The 128-bits of captured data is sent byte-by-byte, MSB being transmitted first.

The meaning of the data depend on the data sourceand alignment of the data is left to the remote multiplexer .

Memory blocks
.............


there are only 16 URAM blocks available. We need 2 URAM to implement a 128-bit wide memory block, meaning we can only handle up to 8 channels.


Operating frequency
...................

UCAP is meant to operate at 400 MHz, which allows capturing ADC samples captured at 3.2 Gsamples/s and carried in a bus 8 samples at a time.


Read / Write Process
--------------------

Incoming 32-bit AXIS Data is captured and written into the DATA FIFO over a 36-bit AXIS bus and read out over a 8-bit wide AXIS Bus. Each byte in the incoming data is extended with a bit which set to '0' except for the LSB , where is set to the TLAST flag from the 32-bit AXIS Bus. The sign extenstion is show below. The HEADER FIFO is 9-bit wide write process which consitutues of all the header information for the data frame written one bit at a time accompanied with a LAST bit at bit(8). When the destination is ready, PROBER sends the header FIFO  bytes until we encounter bit(8)=1, then sends the DATA FIFO bytes until we encounter bit(8)=1 and go back to send header bytes.

.. .. figure:: ../images/prober_write_data.svg
..     :width: 25%



Memory Map
----------

.. include-docs:: UCAP
    :start-after: UCAP Memory Map
