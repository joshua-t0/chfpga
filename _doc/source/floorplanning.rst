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



Pblocks
-------


CHAN0-15: Channelizers. 1/2 clock region high. We leave space to the left for the ADCDAQ. Extends to the right until there is enough resources. We grab a few more BRAM to the left to meet the needs.

ADCDAQ0-15: Located there they can have access to the required logic. They use only CLBs, but grab one extra BRAM for the output FIFO.


ARM_SPI: close to the SPI pins.
SPI
SYSTEM
UDP_MAC: Next to the corresponding GTX.
BP_BUCK_SYNC
CLK0

ALIGN2: Crossbar0 CTRL_SLAVE and CHAN_ALIGN block.

ALIGN3:
	- Located between the GPU blocks
	- Common stuff for all GPU links

	    - XGLINK QUAD_GEN, CTRL_SLVE, etc.
	- Crossbar 3 common logic

	    + CTRL_ROUTER & CTRL_SLAVE
	    + ALIGN
	    + REMAP
	    + Bus pipelining registers
	- Uses 8 RAMB18 for ALIGN. 12 are unused.
	- Limited by logic.
	-

BP0
BP1
BP2
BP3

BP4: (logic that feeds the backplane QSFP link (4 GTX))
	CB2 ALIGN, REMAP, BIN_SEL[0..1]
	BP_TX[15..18]

	Usage:
		CB2 ALIGN: 16 RMB16
		BIN_SEL: 16 RAMB18 for each BIN_SEL
		TOTAL: 2 * 16 + 16 = 48


GPU0 : Instance [0] and [1] of CB3 BIN_SEL, UDP_GEN, xglink0.gtx_gen, xglink0.tx_gen
GPU1 : CB3 BIN_SEL 2 & 3, with all GTX TX logic, next to their corresponding GTXes.
GPU2 : CB3 BIN_SEL 4 & 5, with all GTX TX logic, next to their corresponding GTXes.
GPU3 : CB3 BIN_SEL 6 & 7, with all GTX TX logic, next to their corresponding GTXes.


.. .. figure:: ../images/banner.jpg
..    :align:  center

.. .. contents:: Table of Contents
..    :local:



.. vim: sts=3 ts=3 sw=3 tw=78 smarttab expandtab
