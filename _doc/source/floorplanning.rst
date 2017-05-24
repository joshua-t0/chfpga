.. _floorplanning:

Floorplanning
*************

General approach
----------------

CHannelizers are horizontal bands, 1/2 clock region high. Signal flows from
left to right. Each channelizer has its own Pblock, and is placed close to
where the data pins are located. The width of the block was adjusted to allow
the FFT and other channelizer logic to fit. Some  Pblocks have slightly less
logic due to dedicated hardware blocks. We do not attempt to force a left-to-
right flow; we let vivado place the channelizer modules where it wants and
that works sufficiently well.



The ADCDAQ modules are not part of the Channelizers; they are placed at the
left of the chip. Each ADCDAQ module may have BUFMR/BUFR-driven logic that
operate in multiple clock regions, so placing those individually is tedious.
We simply allocate resources (slices and one RAMB18 per ADCDAQ) in a PBLOCK
that covers every clock region and let Vivado process the clock constraints
and decide where the logic should go.

The crossbars should be allocated two columns of BRAM, otherwise they become too long and signals propagating from one end to the other fail timing.

BP_SHUFFLE
----------

Each GTX Receiver generates its own local clock buffered with a BUFH. This clock runs the PRBS Error counter, Block lock, descrambler, and the RX FIFO. There must be enough slices in the same clock region as the GTX to accomodate that logic. This includes at least one RAMB18 per GTX to implement the RX FIFO. It's easy to forget those. The rest of the logic (packetizer/depacketizer with CRC32, TX FIFO etc) operate on the global TX clock and can be placed anywhere.




.. .. figure:: ../images/banner.jpg
..    :align:  center

.. .. contents:: Table of Contents
..    :local:



.. vim: sts=3 ts=3 sw=3 tw=78 smarttab expandtab
