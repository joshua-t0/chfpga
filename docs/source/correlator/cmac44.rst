
CMAC44: (4+4) bit Complex Multiply-and-Accumulate Core
******************************************************

.. default-role:: math

.. parse:: hdl/CORR/CMAC44.vhd


Entity documentation
--------------------


.. autoentity:: cmac44

Architecture implementation
---------------------------


Design requirements
-------------------

The :entity:`CMAC44` is designed with the following objectives:

- Implement a full (4+4) bit complex multiplier and vector accumulator
- Both (4+4) bit terms are full range signed values, with each element ranging from  -8 to 7 (and not -7 to 7).
- A flag can enable the complex conjugate on each term individually to facilitate implementation of the correlator
- The accumulator is wide enough to allow non-saturated accumulation periods that are long enough to reduce the readout bandwidth of a 16-element correlator below 1 Gbps.
- The vector accumulator must be as deep as possible to maximize the number of products and frequency bins stored by each correlator and minimize the number of CMAC44 required to implement a correlator.
- The CMAC must use its ressources efficiently and perform one or more CMAC operation on each clock (or more).
- The CMAC must operate at a minimum of 250 MHz (250 MCMAC/s) to match the input base clock and avoid unnecessary cross-domain clock crossing (CDC) FIFO and logic. The CMAC must be as fast as possible, as it might be worth using CDC logic if that meant less CMACs are needed to implement a correlatoro if a given size.
- Use as little resources as possible
- Have a non-blocking AXI4-Streaming input interface
- Offer a daisy-chainable output readout
- Handle accumulator saturation adequately


Data rates
----------

A `N` element `N^2` correlator generate `N_p = N(N+1)/2` products for each frequency bin.  Each product is stored in a Nb bit value (`N_b/2 + N_b/2`) bit complex number.

The sampling rate of CHIME is 800MSPS, with data grouped in 2048 sample frames, yielding a frame rate of `F_r = 800MSPS/2048= 390625 Frames/s`.

The output data rate is `B_{out} = N_p F_r N_b/P`, where `P` is the integration period. Increasing `P` reduces `B_{out}`, but increases the probability that the `N_b`-wide accumulated product will saturate during that period.

The worst case (nonrealistic) maximum integration period can be computed by assuming the products is constantly the maximum real or imaginary value possible. The maximum real or imaginary product is 64 (e.g. (-8 + 0j) * (-8 + 0j)). The number of bits required to store thr integration is `N_b = 2 log2(64*P)`, or `P = 2^{N_b/2}/64`. This requires 6 bits. For a `N`=16 correlator generating 1 Gbps, we would require

`Nb P = B_{out}/Np/Fr = N_b 2^{N_b/2)/64


The table shows that in the worst case, we need (19+19) bit products, but (17+17) bit is sufficient with t e constant mid-range ADC signal. There is also the consideration of the FPGA resources. It happens that the 7-Series BRAMs width can be configured to be 36, 18, 9, etc.. bits wide, meaning that a (18+18) bit accumulated product value would fit conveniently both in memory and in bandwidth. The next step, (9+9) bit products, is not feasable even if 10G links were available.

In consequence, accumulators will be (18+18) bits wide. A single BRAM can therefore store 512 such products.

BRAM and DSP utilization
------------------------



Increasing density of the CMAC44: an analysis
=============================================

How could we compute more correlation products with less resources?

Here is some background information:

- We assume that we have the requirement of *continuous* data acquisition (i.e. no dead time), meaning that we want to be able to *slowly* dump the integration products while we integrate for the next period. This implies we need to store data in two physically or logically separate memory banks, which doubles the memory requirement.

- The total amount of computations (in CMAC/s) required to correlate the data is given by C = N_elem*(N_elem+1)/2*N_bins*Frame_rate. The number of CMAC units is solely determined by N_cmac = C/CMAC_frequency. The Number of DSP48s = N_cmac * N_dsp_per_CMAC. The number of CMAC and DSP is dependent on the CMAC speed and architecture, but is is independent of the higher level architecture.

- The total amount of accumulation and readout memory space is S = N_elem*(N_elem+1)/2*N_bins*2*Word_width. This assumes a separate accumulation and capture memory (factor of 2). The number of BRAM18 is given by N_bram18 = S/18k. This is INDEPENDENT OF THE CMAC SPEED or architecture. The data rate required to readout the data is S*Frame_rate/N_integ.

- Every additional bit of data width (on both the real and imaginary part) doubles the allowed integration time. Cutting the BRAM space by halving the data width results in an integration time that is the square root of its original value.

- DSP48s and BRAMs are organized in columns. A DSP48 uses the same column height as a RAMB18. A RAMB36 has the same height as two DSP48 and 5 slices. The minimum vertical spacing betwen CMAC cores is essentially limited the largest space used by either the DSP48s, BRAMs, control logic, and possibly routing resources. A maximally space-efficient CMAC should use the same vertical space for DSPs, BRAMs and logic. In practice, this means a design shall either use 1 DSP and 1 BRAM18, or 2 DSPs and two BRAM18s (assuming we spead the logic horizontally as much as needed to match the vertical space).

- In the 7-Series, the BRAMs can be used in True Dual Port (TDP) or Simple Dual Port (SDP). The TDP implements two independent memories, each with its own read and write ports, and the read and write ports can have different width. The SDP has only one read and write ports, does not allow independent widths, but offers double of the data width of the TDP ports. At its widest, RAMB18 in SDP offers a memory space of 512 words x 36 bits accessed by one read and write port, whereas in TDP it offers a 1024 Words x 18 bits memory space accessed through two independent read/write ports. Both SDP and TDP allow simultaneous read and write at independent addresses. In our application, where data width is important, SDP memory is usually whan we want.

- The width of the memory storage affects the maximum integration period. The narrower the memory, more often we need to dump the results before saturation. This maximum period also depends on the statistics of the signal we integrate. The maximum period must be large enough there is time to dump the data from all CMACs and send them off through whatever link is available to send the data offboard (either typically a 1 G Ethernet control link, or up to 8 10G Ethernet links). In practice, widths will be either (9+9) bits (much too short), (18+18) bits (current design), or (36+36 ) bits (uses too much BRAM real-estate).

- The depth of the memory storage depends on how many distinct products and bins each CMAC has to store. In the CORR44 design, the data is organized such that each CMAC44 must store N/4 products per bin. Multiple CMAC44s work in parallel to cover all required products. A 512-deep memory therefore allows processing a single bin of a N=2048 element vector, or 128 bins in a N=16 element correlator.

- Possible BRAM (or BRAM-based FIFO) configurations:
   - Use two separate BRAM18: one for accumulation, one for readout. This is the current design. We therefore use a vertical
     space of two BRAMs, and there is no space advantage in using less than two DSPs for the
     computations. In SDP mode, this gives us a (18+18) bit width and a depth of 512 products-bins.

   - Use a single BRAM36 for both accumulation and readout? There is no real space advantage (in fact we
     won't be able to use the FIFO hardware counters etc.). In TDP, accumulation and readout can
     be done on separate 36 bit ports, each using their half of the 1024 words x 36 bits memory
     space, which is equivalent to two separate SDP BRAM18 option. In SDP, we can't read two addresses
     (accumulation and readout) at the same time, so we would have to multiplex in time. The only advantage this brings is that 72 bit (36+36 bits) accumulated products is possible by halfing the memory depth to 256 words.

   - Use a single BRAM18. This would be the only way to make a single-BRAM-high CMAC kernel that
     would also also use a single DSP. A TDP BRAM18 could be used, one port for the
     accumulation read/write, another for the readout. The width would be 18 bits, meaning only
     (9+9) bits accumulated products, with a depth of 512 words assigned to each port.
     Alternatively, a SDP could be used at twice the clock speed, with accumulation and readout
     multiplexed in time, which would allow for (18+18) bits data width, but with only a depth of
     256 words.

We could increase the computational density of the CMAC by:
	- Cutting the size of CMAC by half by using one DSP48 and one BRAM. The single DSP48 needs to
	  run twice as fast, and available memory (i.e. width or depth) is cut in half. The additional
	  logic needed to multiplex the DSP inputs might slow down things and use additional resources.

	- Run the whole CMAC twice as fast. Two pairs of complex values could be presented on each clock
	  (would simplify the CORR44 design). We would have the same amount of BRAM as before but would
	  need to store twice as many products, effectively reducing the available memory by half if we
	  need half the number of CMACs.

The density of the CMAC is driven by the memory requirements, since doubling clock speeds could help reduce DSP real-estate but does not help with storage real-estate. If (18+18) bits of dead-time-free integration is required, the CMAC needs to use two BRAM18, in which case there is no need to go into the complication in using only one DSP at twice the speed.

The only way to reduce the design density is to reduce the BRAM requirement by half (there does not seem to be practical in-betweens).

Reducing the BRAM by half without other compromises would force us to use only half the integrated product width (likely to kill the integration time or saturate the readout link) or hald the memory depth (we can process half the bins or half the products per CMAC, which forces us to use twice as many CMACs, which does not help).

The only ways to reasonably reduce BRAM requirements would seem to to make one of the the following compromises:

	- Scale the products before accumulation so the results can be integrated for an amount of time
	  in (9+9) bits that allows the readout data rate to fit in the downlink bandwidth. Such scaling
	  might cause some loss of resolution or sensitivity. Readout downlonks might have to be
	  increased (to 10G Ethernet or multiple 10GE links) to make this possible.

	- If the science allows it, waive the requirement of dead-time-free integration, that is, stop the integration while the
	  accumulated data is sent out. This would cut the BRAM requirement in half, allowing a double-
	  speed CMAC to be used and effectively doubling the CMAC density. Fast
	  readout links (10G Ethernet) might be needed to minimize the dead time.

Any other drastic design changes?
	- Half the number of frequency bins (i.e. half the FFT length). Frame rate doubles, but that just uses one more bit of
	  the integrated product width, and we can live with 256-deep memories (?)




