********************
Hardware Description
********************

The IceBoard is a Kintex-7-based FPGA motherboard designed by McGill Cosmology Instrumentation Laboratory. The board is optimized to be used in arrays requiring the processing of large number of analog signals.  The board provides the following capabilities:

- Xilinx/AMD XC7K420T FPGA
- 2x HPC FMC connector fully connected to the FPGA
- On-board Texas Instruments AM3874 ARM processor with 1GB DDR3 memory for networking, board monitoring & FPGA configuration
- 1x SFP+ (up to 10 Gbps) and 2x QSFP+ (Up to 80 Gbps in total) for data offload
- 9U Form Factor
- Can be packed into a 16-slot crate that distributes power, clock, timing, and provides a full-mesh 10 Gbps network for multi-board corner-turning
- On board PLL to provide various frequencies to the FPGA and ARM
- All on-boards devices clocked from single reference clock source to mitigate RFI
- Powered by a single 14-20V power source

Detailed description of the IceBoard hardware can be fount at https://winterlandcosmology.bitbucket.io/iceboard-docs/


Platform wrapper
================

The platform wrapper for implementing `chFPGA` on the IceBoard platform is :ref:`chFPGA_MGK7MB_Rev2`.


Configurations
==============

There are currently two firmware configurations for the IceBoard platform:

	- :ref:`Corner turn <chfpga_mgk7mb_ct_config>` (``ct`` suffix), which includes the multi-board corner-turn and real time streaming, and is used by CHIME and HIRAX, both of whuch have an external X-Engine
	- :ref:`Correlator <chfpga_mgk7mb_corr_config>` (``corr`` suffix), which includes 16-channel N^2 correlator, used for standalone operations

Floorplanning
=============



BP4
---


BP4 holds the logic related to the backplane shuffle. Critical resources are BRAM (~100%) and LUTs as logic (~90%) . It holds the following cells:

- BPSHUFFLE:

   - core0

      - gtx_gen[15-18]
      - rx_gen[15-18]
      - tx_gen[15-18]

- crossbar2

   - ALIGN: = 16 RAMB18
   - BIN_SEL[0..1]: 2 * (8 FIFO18 + 9 RAMB18) = 16 FIFO18 + 18 RAMB18
   - CTRL_SLAVE0: 0 BRAM
   - crossbar_router0 : 0 BRAM
   - remap0: 0 BRAM

- TOTAL: 16 FIFO18 + 34 RAMB18  = 50 RAMB16 sites
- ALLOCATED: 27 FIFO18/RAMB18 + 27 RAMB18

BPSHUFFLE.lane_gen[16-23] are the  cross-clock-domain FIFOS that feed the core0 transmitter/receiver (The first 4 are direct internal links).
They use 16 RAMB18 and dont fit in here, but are strangely not allocated anywhere else, although they should beong here based on the data flow.

Disabling IS_SOFT property causes error. Placer reports it needs 33 RAMB16 (66 FIFO18/RAMB18 sites). This could be explained if the tool does not want to assign the  unused RAMB18 of the FIFO18/RAMB18 to another cell when the FIFI18 is used. In this case we have 16 unusable  RAMB18, which brings to total to 66 RAMB18 sites, or 33 RAMB36 sites.

crossbar2/BIN_SEL uses 8 RAMB18 / FIFO18 pairs to implement its 16 FIFOs, plus  one RAMB16 for the bin selection map RAM. SO it should be able to combine the RABM16/FIFO16 pair in one RAMB36 site.

If we enable it to let th eplacement succeed:


bpshuffle/lane_gen = 2 RAMB18 each
crossbar2/BIN_SEL_GEN[i] = 8 FIFO18 + 9 RAMB18
crossbar2/align: 16 RAMB18

Enabling EXCLUDE_PLACEMENT causes warnings, as the GTXes of BP shuffle force some logic location


Memory resources
================


BRAM availability is a limiting factor in the design, often followed closely by slice (LUT & REG) resources. We have to use BRAM is the most efficient way possible, and use embedded FIFOs whenever possible so the FIFO logic does not use fabric resources to make a FIFO out of a BRAM.

There can be only one FIFO per RAMB36 site, either a FIFO18 or a FIFO36. If the FIFO18 is used, the other part of the RAMB36 site can be used as a RAMB18.


.. image:: 7-series_valid_FIFO_RAMB_combinations.png

RAMB18 & FIFO18 overestimation issue
------------------------------------

In places where we need lots of FIFOs, like in the Corner-Turn engine's bin selectors, we implement odd- and even-indexed FIFOs alternatively using embedded FIFO18 and a RAMB18 soft FIFOs in order to maximize RAM usage density and minimize fabric utilization.

Note that before placement, Vivado 2022.2 tools will for some reason assume that the FIFO18 and RAMB18 cannot share the same site and overestimate the resource requirements, and issues warnings if the assigned PBLOCK does not contain the overestimated number of sites (even if the placer will eventually fit everything as it should). It will fails placement if the IS_SOFT property of the PBLOCK is FALSE.

The solution for very tight PBLOCKS it to use IS_SOFT=TRUE and let the logic spill out of the block.

FIFO implementation
-------------------

We used to use IP Generator blocks, but those are stored in differnet files, per platform, and need to be regeerated each time the Vivado version changes, which is a pain to maintain.

We generally now prefer to instantiate FIFOs using XPM macros, since those are generally portable across platforms.

The exception is embedded FIFOs: those are not supported by the XPM FIFO macro. We choose to instantiate the FIFO18 or FIFO36 directly, but need to have if-generate blocks to select the right version (E1 or E2)  based on the platform. See :entity:`CMAC44` for an example of this dual-platform use. Also look in the 1G Ethernet receiver for FIFO38, and UCAP and UCORR44 for Ultrascale memory generation


FIFO output latencies for RAMB and Embedded FIFO implementations
----------------------------------------------------------------

Adding the embeded output register on RAMB-based soft FIFOs and built-in FIFOs dramatically helps timing closure (on a -2, TRCK_DO = 1.8 ns, TRCK_DO_REG=0.63 ns), but in some configurations it might create a extra latencies, even in FWFT mode.

- Builtin FIFO, FWFT, synchronous, DO_REG=True, Embedded: latency = 1
- Builtin FIFO, FWFT, synchronous, DO_REG=False, Embedded: latency = 0, (large TRCK_DO delay)
- Builtin FIFO, FWFT, asynchronous, DO_REG=True (mandatory in FIFO18 primitive): latency = 0
- BRAM FIFO, FWFT, synchronous, DO_REG=False, Latency = 0 (large TRCK_DO delay)
- BRAM FIFO, FWFT, synchronous, DO_REG=True, Embed, Latency = 0
- BRAM FIFO, FWFT, synchronous, DO_REG=True, Fabric, Latency = 0
- BRAM FIFO, FWFT, synchronous, DO_REG=True, Embed+Fabric, Latency = 0
- BRAM FIFO, FWFT, asynchronous, DO_REG=False, Latency = 0 (large TRCK_DO delay)
- BRAM FIFO, FWFT, asynchronous, DO_REG=True, Embed, Latency = 0
- BRAM FIFO, FWFT, asynchronous, DO_REG=True, Fabric, Latency = 0
- BRAM FIFO, FWFT, asynchronous, DO_REG=True, Embed+Fabric, Latency = 0

All configurations with output register (DO_REG=True) have a latency of 0, except for the synchronous builtin FIFO. An asynchronous builting FIFO could be used as a work around.


- Kintex-7 memory resources (UG473):

   - Table 2-2, Figure 2-1
   - Table 2-5, DO_REG

- Kintex 7 datasheet - AC/DC characteristics (DS182)
- Play with parameters in the FIFO generator (13.2)






