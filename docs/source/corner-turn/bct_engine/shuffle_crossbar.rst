.. title:: SHUFFLE_CROSSBAR

**********************************************************************************
:entity:`shuffle_crossbar` (*shuffle_crossbar.vhd*): 2nd and 3rd stage corner-turn
**********************************************************************************

.. toctree::
   :titlesonly:
   :hidden:

   ip_cores/shuffle_crossbar_align_fifo
   align32
   remap
   shuffle_bin_sel
   ../../navbar_separator


The `SHUFFLE_CROSSBAR` implements the second and third stages of the corner-turn operation. Contrary to the channelizer crossbar, the shuffle crossbar accepts data that is already packetized with headers, flags etc., and there needs to process the data differnetly than the first crossbar.

Generics are used to specialze the bodule for second or stage operations. Software-controlled registers can be used to change the operation of these crossbars to support different packet geometry and allow the implementation of all the corner turn engine modes of operation.

The shuffle_crossbar consists of the following  sub-modules:

  - The align module (:entity:`align32`), which buffers and aligns the incoming packets so they can be processed easily. The aligner receives data from board-to-board GTX links, which are prone to errors, lost packets or simply delays. The aligner must reliably deal with and recover from  all these situations to minimize data loss.
  - The remapping module (:entity:`remap`) Reorganizes the ordering of the lanes so the data will be reorganized in the right order and will be sent to the right destinations.
  - An array of bin selectors (:entity:`shuffle_bin_sel`). Each bin selector pulls data from all incoming streams, and retains and buffers a subset of the frequency bins they contain. The captured bins from all the input lanes are then streamed out, along with their headers, flags etc.

The shuffle_crossbar is designed to facilitate downstream processing of the data by the X engine by regrouping all the data bytes from multiple frames into a single contiguous block, followrd by a block of data flags (Scaling overflow), frame flags (ADC/FFT overflows) and packet flags. This allows the F-engine to move the data from its network interface card to the processing memory a single, efficient move / DMA operation. This feature, however, comes at the cost of additional buffering and complexifies the logic of the bin selector code.

The module contains a set of control and monitoring memory-map registers.

.. toctree::
   :titlesonly:

   shuffle_bin_sel
   remap
   align32

Entity documentation
--------------------

.. parse:: hdl/ct/shuffle_crossbar.vhd

.. autoentity:: shuffle_crossbar


Additional details
------------------

Memory map
----------

.. include-docs:: shuffle_crossbar
    :start-after: shuffle_crossbar Memory Map

Implementation details
----------------------
