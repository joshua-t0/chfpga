.. title:: CHAN_CROSSBAR

********************************************************************
:entity:`chan_crossbar` (*chan_crossbar.vhd*): 1st stage corner-turn
********************************************************************

.. toctree::
   :titlesonly:
   :hidden:

   chan_bin_sel

.. default-role:: vhdl:entity
  
.. .. figure:: ../../images/channelizer.svg
..     :width: 75%

The `chan_crossbar` implements the first stages of the corner-turn operation. It accepts the raw data directly from the F-Engine channelizers, which are sent as a N continuous stream of frames without headers coming on the CT-Engine clock domain. The frames are expected to be aligned and continuous.

`chan_crossbar` input frames have no header, but ADC, FFT and scaler flags are passed through the TUSER bus.

`chan_crossbar` implements an array of bin selectors (:entity:`chan_bin_sel`). Each bin selector pulls data from all incoming streams, and retains and buffers a subset of the frequency bins they contain, including the corresponding flags. A memory map indicates which bits are to be retained. The selected bins from all the input lanes are then streamed out in the following order:

- Packet header
- Scaler data
- Block of scaler flags
- Block of frame flags (ADC & FFT)
- Packet Flags

Generics are used to specialize the module for the first stage corner-turn operation. Software-controlled registers can be used to change the operation of the crossbar to support different packet geometry and allow the implementation of multiple corner turn engine modes of operation.


`chan_crossbar` spends resources buffering and reordering the data in order to facilitate downstream processing of the data by the X engine.  Having the data received in a single contiguous data block allows the F-engine to move the data from its network interface card to the processing memory a single, efficient move / DMA operation. This feature, however, comes at the cost of additional buffering and complexifies the logic of the bin selector code.



Entity documentation
====================

.. parse:: hdl/ct/chan_crossbar.vhd

.. autoentity:: chan_crossbar

Parameters
==========

- **PLATFORM_TYPE:** FPGA platform type enumerated in the chFPGA package. Propagated down to each :entity:`chan_bin_sel` instance to select the correct embedded FIFO primitive.
- **NUMBER_OF_INPUT_LANES:** Number of channelizer output lanes feeding the crossbar. Determines the width of the ``s_axis_*`` port arrays. Defaults to 16.
- **NUMBER_OF_OUTPUT_LANES:** Number of bin-selector outputs (i.e., the number of :entity:`chan_bin_sel` instances). Determines the width of the ``m_axis_*`` port arrays. Defaults to 16.
- **BINSEL_PBLOCK_MAP:** Integer array mapping each bin-selector index to a floorplan pblock region for placement-and-routing constraints. Each entry encodes a pblock identifier used by the implementation scripts.

Interface
=========

Channelizer data input
-----------------------

- ``s_axis_tvalid``: Shared valid flag for all input lanes (non-blocking).
- ``s_axis_tdata``: Per-lane 32-bit input data. Each word contains two frequency bins from the F-Engine channelizer.
- ``s_axis_tlast``: Shared end-of-frame flag for all input lanes.
- ``s_axis_tuser``: Per-lane 4-bit sideband carrying ADC overflow, FFT overflow, and scaler flags.

Per-bin-selector output
------------------------

- ``m_axis_tvalid``: Per-output-lane valid flag from each :entity:`chan_bin_sel` instance.
- ``m_axis_tdata``: Per-output-lane 32-bit packetized output word (header, data, scaler flags, frame flags).
- ``m_axis_tlast``: Per-output-lane end-of-packet flag.

Monitoring
----------

- ``lane_monitor``: Single-bit monitoring output, taken from lane 0 of the :entity:`align32` sub-module for debug frame-timing measurements.
- ``frame_clk_out``: Frame reference clock output for external timing analysis.

BSB control interface
---------------------

- ``s_axis_bsb_*/m_axis_bsb_*``: BSB command and reply byte streams for software-controlled register access.
- ``bsb_clk/bsb_rst``: Dedicated clock and synchronous reset for the BSB interface.

Clocking
--------

- ``clk``: AXI-Streaming clock for all data-path logic.
- ``rst``: Synchronous active-high reset.



Memory map
==========

.. include-docs:: CHAN_CROSSBAR
    :start-after: Memory Map

Implementation details
======================

Clocking
--------

`chan_crossbar` operates fully on the CT-Engine clock domain, which is slightly faster than the channelizer clock in order to leave extra cycles to insert the packet headers and flags into the frames. 

.. todo:: Explain the required clocking ratio. Roughly 1/8 = 12.5% faster for the scaler flags (1 bit per 4+4-bit value). 

Alignment
---------

The module assumes that the packets from the channelizers are already aligned via the F-Engine FIFO. We used to have a separate aligner, but we merged the alignment funcitonality in the F-ENGINE output FIFO to preserve BRAM resources.

Continuity
----------

`chan_crossbar` processes TVALID as expected; data does not need to be present on every clock. In fact, discontinuities are expected 
since the channelizers generate data on a slower clock than the CT-Engine clock.


Remapping (or lack thereof)
---------------------------

`chan_crossbar` does not implement input or output remapping. Input remapping is not necessary as we assume we want the channels sent in the logical order. Channel remapping can be done offline at the end of the pipeline if needed. Output remapping would be useful to select which bins are sent to which boards by the shuffle links, but we can do this selection by setting the bin maps accordingly, so there is no need to waste resources implementing large muxes for this, and push the burden to the software.
