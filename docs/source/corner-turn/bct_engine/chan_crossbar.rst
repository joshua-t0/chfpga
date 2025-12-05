.. title:: CHAN_CROSSBAR

********************************************************************
:entity:`CHAN_CROSSBAR` (*CHAN_CROSSBAR.vhd*): 1st stage corner-turn
********************************************************************

.. toctree::
   :titlesonly:
   :hidden:

   chan_bin_sel

.. default-role:: vhdl:entity
  
.. .. figure:: ../../images/channelizer.svg
..     :width: 75%

The `CHAN_CROSSBAR` implements the first stages of the corner-turn operation. It accepts the raw data directly from the F-Engine channelizers, which are sent as a N continuous stream of frames without headers coming on the CT-Engine clock domain. The frames are expected to be aligned and continuous.

`CHAN_CROSSBAR` input frames have no header, but ADC, FFT and scaler flags are passed through the TUSER bus.

`CHAN_CROSSBAR` implements an array of bin selectors (:entity:`CHAN_BIN_SEL`). Each bin selector pulls data from all incoming streams, and retains and buffers a subset of the frequency bins they contain, including the corresponding flags. A memory map indicates which bits are to be retained. The selected bins from all the input lanes are then streamed out in the following order:

- Packet header
- Scaler data
- Block of scaler flags
- Block of frame flags (ADC & FFT)
- Packet Flags

Generics are used to specialize the module for the first stage corner-turn operation. Software-controlled registers can be used to change the operation of the crossbar to support different packet geometry and allow the implementation of multiple corner turn engine modes of operation.


`CHAN_CROSSBAR` spends resources buffering and reordering the data in order to facilitate downstream processing of the data by the X engine.  Having the data received in a single contiguous data block allows the F-engine to move the data from its network interface card to the processing memory a single, efficient move / DMA operation. This feature, however, comes at the cost of additional buffering and complexifies the logic of the bin selector code.



Entity documentation
--------------------

.. parse:: hdl/CROSSBAR/CHAN_CROSSBAR.vhd

.. autoentity:: CHAN_CROSSBAR


Additional details
------------------

Memory map
----------

.. include-docs:: CHAN_CROSSBAR
    :start-after: Memory Map

Implementation details
----------------------

Clocking
........

`CHAN_CROSSBAR` operates fully on the CT-Engine clock domain, which is slightly faster than the channelizer clock in order to leave extra cycles to insert the packet headers and flags into the frames. 

.. todo:: Explain the required clocking ratio. Roughly 1/8 = 12.5% faster for the scaler flags (1 bit per 4+4-bit value). 

Alignment
.........

The module assumes that the packets from the channelizers are already aligned via the F-Engine FIFO. We used to have a separate aligner, but we merged the alignment funcitonality in the F-ENGINE output FIFO to preserve BRAM resources.

Continuity
..........

`CHAN_CROSSBAR` processes TVALID as expected; data does not need to be present on every clock. In fact, discontinuities are expected 
since the channelizers generate data on a slower clock than the CT-Engine clock.


Remapping (or lack thereof)
...........................

`CHAN_CROSSBAR` does not implement input or output remapping. Input remapping is not necessary as we assume we want the channels sent in the logical order. Channel remapping can be done offline at the end of the pipeline if needed. Output remapping would be useful to select which bins are sent to which boards by the shuffle links, but we can do this selection by setting the bin maps accordingly, so there is no need to waste resources implementing large muxes for this, and push the burden to the software.
