.. title:: UCORR44

UCORR44: UltraRAM-based (4+4) bit Correlator Modules
****************************************************

.. default-role:: vhdl:entity

The UCORR44 modules implement UltraRAM-based (4+4) bit correlator cores for Ultrascale+ FPGAs. These modules use UltraRAM for high-density product storage, allowing for larger correlators with more frequency bins.

The UCORR44 system consists of:

- :entity:`UCORR44_ARRAY`: Array wrapper that manages multiple correlator cores
- :entity:`UCORR44`: Correlator core that implements a single correlator using UCMAC44_ARRAY
- :entity:`UCMAC44_ARRAY`: Array of UltraRAM-based complex multiply-and-accumulate modules

.. toctree::
   :maxdepth: 2
   :hidden:

   ucorr44_array
   ucorr44
   ucmac44_array
   ../../navbar_separator


.. default-role:: math

Introduction to UCORR44
=======================

:entity:`chFPGA` can be configured to include an embedded `N^2` correlator. The correlator requires the incoming data stream to be grouped by input channel, then by frequency bin, which means that a corner-turn engine should precede the X-Engine. If data comes in as multiple streams, each one carrying data from a different set of frequencies, then multiple correlator cores can be implemented in parallel.

The correlator computes each of the  products and integrate them over time. Once the integration period is finished, the integrated products are trickled out slowly while the next set of frames are being integrated. Integrated products are typically streamed over a 1G ethernet link. If an on-chip processor is available on the FPGA (e.g. Zynq FPGAs), the data can be passed to the processor for further integration before sending out to the host computer.

The correlator is resource intensive, and is generally memory-limited, both in the 7-Series and Ultrascale+ series FPGAs. The amout of resources grows as the square of the number of inputs to be correlated. Implementing single-board small (up to 16-channel) correlators along the correspondinf F-Engine is possible on our typical platforms (IceBoard, CRS). Wider correlators can be implemented if multiple boards are used in a crate; using K boards allows the input channel count to be multilied by K, resource utilization increase by `K^2`, but those resources are spread across said K boards then each board requires `K` times more resources than a single board. This is typically not feasible unless we make compromises on the number of inputs of the number of bins that can be processed simultaneously.

Radio-interferometers such as CHIME or CHORD do not use the on-board firmware X-Engine. The Corner-turned channelized output is rather sent to an external X-Engine consisting of a farm of GPU-Based computing nodes that perform the `N^2` correlation. Although such a setup is more power hungry, it provides scaleability, great flexibility, and is programmable using more widely programing languages and tools.


Example of single-board correlators are:

- IceBoard 16-channel correlator board, 800 MSPS @ 8 bit / channel, 1024 frequency bins.
- CRS 8-channel correlator board, 3200 MSPS @ 14 bits/channel, 8192 frequency bins.

This document describes the archtitecture of our home-made correlator.


Definitions
===========

.. Define some macros to make it easier to write equations. Unfortunalely this creates an extra blank line.
.. math::
	\def\N{{N}}
	\def\Nclk{{N_{clk}}}
	\def\Nbins{{N_{bins}}}
	\def\NbinsPerClk{{N_{bins\_per\_clk}}}
	\def\Nfpga{{N_{FPGA}}}
	\def\Ncorr{{N_{corr}}}
	\def\Nprod{{N_{prod\_per\_bin}}}
	\def\NprodTot{{N_{prod\_tot}}}
	\def\NprodPerFpga{{N_{prod\_per\_FPGA}}}
	\def\NprodPerCmac{{N_{prod\_per\_CMAC}}}
	\def\NprodPerCorr{{N_{prod\_per\_corr}}}
	\def\NcmacPerCorr{{N_{CMAC\_per\_corr}}}
	\def\NcmacPerFpga{{N_{CMAC\_per\_FPGA}}}
	\def\NbinsPerCorr{{N_{bins\_per\_corr}}}
	\def\NbinsPerFpga{{N_{bins\_per\_FPGA}}}
	\def\NuramPerFpga{{N_{URAM\_per\_FPGA}}}
	\def\NbramPerFpga{{N_{BRAM\_per\_FPGA}}}
	\def\NprodPerUramMax{{N_{prod\_per\_URAM\_max}}}
	\def\NprodPerBramMax{{N_{prod\_per\_BRAM\_max}}}
	\def\NdspPerCorr{{N_{dsp\_per\_corr}}}
	\def\NdspPerCmac{{N_{dsp\_per\_CMAC}}}
	\def\NdspPerFpga{{N_{dsp\_per\_FPGA}}}
	\def\NramPerCmac{{N_{RAM\_per\_CMAC}}}
	\def\NramPerFpga{{N_{RAM\_per\_FPGA}}}
	\def\NprodPerRam{{N_{prod\_per\_RAM}}}
	\def\NcmacPerRam{{N_{CMAC\_per\_RAM}}}

- **BRAM**: Block RAM, which are dedicated hardware memory blocks that are present in the multiple columns of the FPGA. In this document, the term BRAM specifically refer to a Block Ram Tile, which corresponds to a RAMB36 (36 kbit storage) or two RAMB18 (18 kbit storage). A RAM36 can be configured with an aspect ratio of 72-bits x 512, 36-bit x 1024, 18-bit x 2048, and so on. The correnator engine uses the 36-bit x 1024 to match the data width to the CMAC output width (18+18i bits).
- **URAM**: UltraRAM, which is a high density dedicated hardware memory block present in the Ultrascale and later FPGAs. Each block provides 288 kbits of memory in a 72 bits x 4 K configuration only. There is only one column of 80 URAM in the Ultrascale+ FPGAs we use on the CRS platform.
- **Correlator core**: Array of CMAC that compute all the products for a set of frequency bin. Contains `N*(N+1)/N_{clk}` CMACs
- **Bin stream**: Data bus providing the data for all inputs but a subset of the bins.
- **CMAC**: Complex multiply-and-accumulate. Consists on one complex multiplier (implemented as two DSP48 blocks) and a memory block to store the products. One CMAC typically compute products and accumulate multiple pairs of inputs and multiple bins.
- **Product**: Integrated product of two *specific* inputs for one *specific* bin

System parameters used in defining the correlator:

- `\N`: Number of (4+4i) inputs to correlate
- `\Nfpga`: Number of FPGA boards across which the correlations computations are distributed
- `\Ncorr`: Number of correlator cores in each FPGA. This equals the number of bin streams are coming out of the corner-turn engine in any one FPGA.
- `\Nbins`: Number of bins coming out of the output of the F-Engine
- `K` : bin downsampling factor
- `\Nclk`: Number of clock cycles a correlator core takes to compute all the `\Nprod` products for each bin.
- `\NbinsPerClk`: Number of bins provided for each clock cycle at the output of the F-Engine. 2 for the IceBoard F-Engine, 4 for the CRS F-Engine.
- `\NprodPerRam`: Number of products that can be stored in a RAM unit (BRAM or URAM). 2048 for URAM, 512 for BRAM.
- `\NcmacPerRam`: Number of CMACs connected to each RAM unit (BRAM or URAM). 2 for URAM, 1 for BRAM.

Derived variables:

- `\NbinsPerCorr`: Number of bins processed by each correlator core.
- `\Nprod = \frac{\N \cdot (\N + 1)}{2}`: Total number of (18+18i)-bit products that are computed **for each bin**
- `\NprodPerCmac`: Number of products processed by each CMAC
- `\NcmacPerCorr`: Number of CMACs in each correlator core.
- `\NcmacPerFpga`: Number of CMACs used in one FPGA
- `\NramPerCmac`: Number of RAM units (BRAM or URAM) in each CMAC.
- `\NramPerFpga`: Number of RAM units (BRAM or URAM) used by the correlators in each FPGA.
- `\NdspPerCorr`: Number of DSP blok used per correlator core
- `\NcmacPerCorr`: Number of CMACs used per correlator core

.. - `\NdspPerCmac = 2`: Number of DSP blok used per CMAC. Our multiplier design uses 2 DSPs per CMAC.

Resource usage variables:

- `\NuramPerFpga`: Number of URAM blocks used by all correlators in the FPGA if the correlator is implemented only with URAMs.
- `\NbramPerFpga`: Number of BRAM blocks used by correlators in the FPGA if the correlator is implemented only with BRAMs.
- `\NdspPerFpga`: Number of DSP blocks used by all correlators in a FPGA.

.. - `\NprodPerUramMax`: Maximum number of products per URAM. We assume that we implement two banks (one for accumulation, one for slow readout), so only half of the memory depth is available. A URAM is 72 bits x 4096 words (36 kBytes or 288 kbits). Contrary to RAMB, we cannot change the aspect ratio of URAM. The URAM is wide enough to store two (18+18i)-bit products coming from two multipliers, and the depth of one bank is fixed at 2048 products per multiplier, or 4096 product for the two multipliers. (rule of thumb: a URAM has 8x the capacity of a BRAM)

.. - `\NprodPerBramMax`: Maximum number of products per BRAM. Each RAMB36 is 36 kbits, with selectable aspect ratio (i.e. 1,2,4,9,18,36,72 bit wide). If we configure it as 36 bit wide x 1024 bins deep, we can store 512 products.

.. - `\NbinsPerFpga = \Nbins / \Nfpga`: Number of bins processed by each FPGA.
.. - `\NprodTot = \Nprod \cdot \Nbins`: Total number of (18+18i)-bit products that are computed **for each bin**
.. - `\NprodPerFpga = \NbinsPerFpga \cdot \Nprod`: Total number of products processed and stored by one FPGA.
.. - `\NprodPerCorr = \NprodPerFpga / \Ncorr`: Total number of products processed and stored by one correlator core.
.. - `\NprodPerCmac`: Number of (18+18i)-bit products that are handled by one specific CMAC.

Assumptions:

- We fully use the DSPs, i.e. every DSP does a useful computation on every clock cycle
- We fully use the RAM, i.e. we use all the storage available in the RAM resources allocated to the correlator

Resource utilization constraints
================================

In a correlator array of `\Nfpga`, there will be a total of `\NprodTot` products that need to be computed and stored in total across the whole array. Each FPGA will therefore process and store  `\NprodPerFpga` products, assuming the computations are spread equally between boards.


The key element in computing the number of required CMACs is how many clock cycles we have available to us to do perform the product computations. This is established by:

`\Nclk = \frac{K \Nfpga \Ncorr}{\NbinsPerClk}`

where `\Ncorr` is the number of correlator cores in each FPGA, and `K` is the bin downsampling factor. `\Ncorr` is chosen so that `\Nclk` is a positive integer. It is the responsability of the corner-turn engine to divide the channelizer data in a way that each FPGA receives `\Ncorr` streams, i.e. one for each correlator cores in that FPGA. The corner-turn operaton is typically simplest and uses less resources  when `\Ncorr` is such that `\Nclk=1`. `K` means that we spread computations of the products to `K` times the minimum number of clocks. This necessarily implies that we will process `K` times less bins.

The number of bins processed by each correlator is:

`\NbinsPerCorr = \frac{\Nbins}{K \Nfpga \Ncorr}`

The number of CMACs required to perform the computations in each correlator core is:

`\NcmacPerCorr = \frac{\Nprod}{\Nclk} = \frac{\Nprod \NbinsPerClk}{K \Nfpga \Ncorr}`

`\NcmacPerFpga = \NcmacPerCorr \Ncorr = \frac{\Nprod \NbinsPerClk}{K \Nfpga}`


This equation mean that we need `\Nprod = N (N+1) / 2` CMACs if we need to compute all possible products in one single clock. We need `\Nclk` times less CMACs if we spread the computation throughout `Nclk` clock cycles, which implies that each CMAC is reused multiple times, or in other words, each CMAC computes `Nclk` products.

The number of products that are processed and stored by each CMAC and for the whole FPGA is:

`\NprodPerCmac = \NbinsPerCorr \Nclk = \frac{\NbinsPerCorr \Nfpga \Ncorr}{\NbinsPerClk} = \frac{\Nbins}{\NbinsPerClk}`

It is intersting to note that `\NprodPerCmac` does not depend on the number of FPGAs, Correlators or even the downsampling factor. `\NprodPerCmac` is equivalent to the number of clock cycles per frame, and if we assume the system is designed so CMACs are busy generating a product for every clock cycle, it means each CMAC generates  `\NprodPerCmac` products per frame.

.. `\NprodPerFpga = \NprodPerCmac \Ncorr  = \frac{\NbinsPerCorr \Ncorr}{\NbinsPerClk} = \frac{\Nbins}{\NbinsPerClk}`

Now, those products need to be accumulated in RAM. The depth of the RAM determines how many product each RAM can store, so the number of RAM units needed for each CMAC is:

`\NramPerCmac = ceil(\frac{\NprodPerCmac}{\NprodPerRam}) / \NcmacPerRam = ceil(\frac{\Nbins}{\NbinsPerClk \NprodPerRam}) / \NcmacPerRam`

`\NramPerFpga = \NramPerCmac \NcmacPerCorr \Ncorr = ceil(\frac{\Nbins}{\NbinsPerClk \NprodPerRam}) \frac{\Nprod \NbinsPerClk}{K \Nfpga \NcmacPerRam }`


where `\NcmacPerRam` is the number of CMACs that can feed a RAM unit, in case the RAM bus width is wider than the CMAC word width of (18+18i) bits. `\NprodPerRam` is the maximum depth of the RAM unit we use to store the products, assuming we use half the RAM to store the accumulated products, and half are used for readout. We round up fractional numbers to the nearest integer in case we don't fully use the RAM because the CMAC still monomolize a full RAM unit even if it is not fully used. This should not happen in efficiently designed correlators. For a given F-Engine that issues  `\NbinsPerClk`  bins per clock cycle, that engine needs to produce a minimum number of bins in order to fully use ther type of RAM in use for its CMACs (i.e `\Nbins = \frac{\NbinsPerClk \NprodPerRam}{m}` where `m` is a positive integer. If we assume the full RAM utilizatoin condition is met, we have:

`\NramPerFpga = \frac{\Nbins \Nprod}{K \Nfpga  \NprodPerRam \NcmacPerRam}`

URAM has a fixed aspect ratio of 72 bits wide and 4096 words deep, so `\NprodPerRam = 2048` and `\NcmacPerRam = 2`. For a BRAM (RAMB36) configured as 36-bit wide by 1024-word deep, we have `\NprodPerRam = 2048` and `\NcmacPerRam = 2` If the correlator was built using exclusively either BRAM, or URAM, the amount of those blocks we we would therefore need for each FPGA would be:

`\NbramPerFpga = \frac{\Nbins \Nprod}{K \Nfpga \cdot 512}`

`\NuramPerFpga = \frac{\Nbins \Nprod}{K \Nfpga \cdot 2048 \cdot 2}`


Our CMAC uses two DSP blocks to perform all multiply and accumulate operations. The number of required DSPs per FPGA is therefore:

`\NdspPerFpga = 2 \NcmacPerFpga = \frac{2 \Nprod \NbinsPerClk}{K \Nfpga}`


We now have the information required to determine if there are enough BRAM, URAM or DSP resources to implement a `\Nfpga`-board, \N`-input correlator that processes `\Nbins` frequency bins, assuming that the channelizer outputs `\NbinsPerClk` bins at a time. If not, we can determing the bin downsampling factor `K` that would make it fit.

..
	Hardware multipliers are also an essential resource to efficiently perform the complex multiplication. We have designed an efficient 4+4 bit CMAC that uses only two DSP48 tiles to perform all multiply and accumulate operations (see :entity:`CMAC44` and :entity:`UCORR44`).


	The number of CMACs is then given by :

	`\NcmacPerCorr = \Nprod/\Nclk`

	`\NdspPerCorr = \NcmacPerCorr \cdot \NdspPerCmac`

	The number of multiplication operations needed to compute all products assigned to a FPGA is:

	.. math::
		\NdspPerFpga &= \NdspPerCorr \cdot \Ncorr \\
		             &= \frac{\N \cdot (\N + 1) \cdot \NbinsPerClk}{\Nfpga}


Resource utilization examples
=============================


Available RAM and DSP resources
-------------------------------

The resources typically available for each platform for correlation in the chFPFA firmware are:

- Iceboard 16 inputs: 276 BRAMs + 0 URAMs (141k products) and 552 DSPs
- CRS 8 inputs:  96 BRAMs + 64 URAMs ( 311k products) and 288 DSPs
- CRS 4 inputs: 96+480=576 BRAMs + 64 URAM s(557k products) , 288+2208 DSPs


These numbers are approximate, as it is possible to capture unused resources from adjacent blocks, but some of the BRAM might also be needed for corner-turning.


16-input single-board Iceboard correlator
-----------------------------------------

For a single-board IceBoard N=16 input correlator with `\Nbins`=1024, `\NbinsPerClk=2` and no bin downsampling (`K=1`), we need

- `\NprodPerFpga` = 123k products / board (141k available storage capacity, fits in BRAM)
- `\NbramPerFpga` = 272 BRAMs (276 available)
- `\NuramPerFpga` = 34 URAMs (0 available)
- `\NdspPerFpga` = 16*17*2/1 = 544 DSPs

8-input single-board CRS correlator
-----------------------------------

For a single-board CRS N=8 input correlator with `\Nbins = 8192`, `\NbinsPerClk=4 and no bin downsampling (`K=1`), we need

- `\NprodPerFpga` = 295k products / board (311k available storage capacity, fits if using all URAM and some BRAM)
- `\NbramPerFpga` =  576 BRAMs (96 available)
- `\NuramPerFpga` =  72 URAMs (64 available)
- `\NdspPerFpga` = 8*9*4 = 288 DSPs (288 DSPs available)

64-input 8-board CRS correlator
-------------------------------

For an 8-board 64-input correlators with `\Nbins = 8192`, `\NbinsPerClk=4` and no bin downsampling (`K=1`):

- `\NprodPerFpga` = 2,130k products / board (311k available storage, does not fit)
- `\NbramPerFpga` =  4160 BRAMs (96 available)
- `\NuramPerFpga` =  520 URAMs (64 available)
- `\NdspPerFpga` = 64*65*4/8 = 2080 DSPs (288 DSPs available)

The first two are feasible in terms of memory, but the latter won't fit in any way. The only way to make this fit is to reduce the number of bins that are sent by the F-Engine by a factor of 8 (`\Nbins` reduced by a factor of 8), but sending the bins 8 times slower (`NbinsPerClk` also reduced by a factor of 8):

For an 8-board 64-input correlators with `\Nbins=8192`, `\NbinsPerClk=4` and (`K=8`):

- `\NprodPerFpga` = 266k products / board (311k available storage, fits using all URAM and some BRAM)
- `\NbramPerFpga` =  520 BRAMs (96 avalable, we use 8 BRAM to compensate for the missing URAM)
- `\NuramPerFpga` =  65 URAMs (64 available, we  use all 64)
- `\NdspPerFpga` = 64*65*0.5/8  = 260 (`\NbinsPerClk=4/8=0.5`, 288 DSPs available)


Correlator core architecture
============================




Single-clock product computations
---------------------------------

If `\Nclk = 1`,  all N inputs to be correlated for one bin arrive within one processing clock,  and all `\Nprod` products for that in need to be computed in a simgle clock cycle.  We therefore need to implement `\Nprod` multipliers.

.. image:: ../../images/CORR/ucorr44_N8_block_diagram.svg

This is the case of the single-board 8-input CRS correlator. On each clock cycle, the F-Engine issues 4 bins for all of the 8 channels. We therefore implement 4 parallen correlator, each correlator processing the products for each bins in one clock. The IceBoard correlator could have used a similar structure with its 16 inputs providing 2 bins at a time (i.e using 2 correlators), but additional corner turning spread the data into 8 streams, therefore requiring 8 correlators but, each correlator computing its products in 4 clocks.

.. If not only do we receive ann inputs in one clocks but we also receive multiple bins, we need to implement one correlator core for each bin.

.. This is the case of the single-board 8-input CRS correlator:

.. - The output of each of the 8 channelizers presents 4 frequency bins on each clock.  We corner-turn simply by wiring by grouping the 1st bin of each output and send it to correlator 1,  the 2nd bins to correlator 2 etc. So ,
.. - We therefore need `\Ncorr` correlators. Each correlator sees `1/\Ncorr` of the frequency bins.
.. - Each accumulator needs to store `\Nbins / \Ncorr` products. In our case, `\Nbins=8192`, so we need to store 2048 bins per frame, which incidentally is the available depth of an UltraRAM block assuming we store two sets (banks) of results.
.. - We need `\Ncmac=N{prod}=N(N+1)/2 = 36` CMACs.
.. - One UltraRAM is 72-bits wide, which is wide enough to accomodate data from exactly two CMACs (each CMAC outputs is a (18+18i)-bit complex value). We therefore need `\Nuram = \Ncmac/2 = 18` URAMs per correlator core.
.. - Since we have `\Ncorr=4` cores, we need `\Ncorr \cdot \Nuram = 72` URAMs in total. In that design, 64 URAMs are available, so we implement the missing 8 URAMs with BRAMs (each URAM can be implemented using 8 BRAMs)

Multi-clock product computations
--------------------------------

It is not always possible or desirable to present all N inputs on a single clock, and opt to present the N inputs in `\Nclk` consecutive clocks (`N/\Nclk` inputs per clock). This means that we are transmitting a smaller number of bins per stream, but we need `\Nclk` more streams overall in the system.

In this case, the same CMACs are reused multiple times, so we need less of them. We need only `\Ncmac = \Nprod/\Nclk` CMACs per correlator core. If a stream receives `\Nbins`, each CMAC needs to store `\NbinsPerCorr \cdot \Nclk` products.

.. If we use BRAM, we can use one RAMB36 per CMAC with a maximum depth of 512 products. We can cascade multiple BRAM to acheive more depth.

.. If we use URAM, we can store 2048 products. URAM is less flexible, and the width and depth is fixed at 72 bits x 4096 words, of which 2048 words are usable per bank

.. Since memory is usually the limiting resource, we want to fully use the depth of the memory.

.. 2048/1024 = 2. SO need 64*65/2/2 /2 = 520 URAM. No.
.. Only option: increase Nclk to 16 reduce Nuram. Increase Nclk by  8. Now need 65 CMAC. ok Nclk=16.

.. chime:


CRS 8-input correlator
----------------------

.. image:: ../../images/PLATFORMS/CRS/chfpga_crs_corr8.svg

