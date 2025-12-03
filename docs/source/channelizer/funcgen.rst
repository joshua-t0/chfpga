.. title:: FUNCGEN

******************************************************************************
:entity:`FUNCGEN` (*FUNCGEN.vhd*): Data source selector and Function Generator
******************************************************************************


Overview
========

AXI4-Streaming function generator that either forwards the input from the ADC or replaces it with user-programmable arbitrary waveforms, noise, or packet test patterns.

Features:

- Received ADC inputs

Schematic
=========

.. figure:: ../images/CHAN/funcgen.svg
    :width: 100%

.. figure:: ../images/CHAN/funcgen_modes.svg
    :width: 100%

Sub-modules
===========

.. toctree::
    :titlesonly:

    funcgen_ram



Entity documentation
====================

.. parse:: hdl/CHAN/FUNCGEN.vhd

.. autoentity:: FUNCGEN


UDP Control Memory Map
======================

.. include-docs:: FUNCGEN
    :start-after: Function Generator Memory Map

Design notes
============

Interface
---------


Clocking
........

The module data pipeline operates on a single clock ``clk``. Both input and output AXI-Streaming buses are synchronous to this clock.

The BSB control bus operates on its own separate clock (``ctrl_clk``).


CDC
...


There is no CDC logic for quasi-static signals coming from the BSB registers, such as stats frame count, Bytes A and B, seeds etc. These signals are meant to be set and then left unchanged after the module is reset and data starts flowing. The exceptin to these are:

- ``enable``: Can be changed at any time, but is registered only on frame boundaries. Uses a CDC to prevent corruption of the frame counter.
- ``stats_enable``: Can be set at any time to stop ADC overflow statistics updates. Uses  a CDC to protect the integrity of the registering of the counts.
- ``fn-sel``: Switching function during operation can be done safely only if we are not switching between ADC and non-ADC modes. All non-ADC modes generate words using the same framing signals. Switching between non-ADC modes might cause part of the frame to have one type of data, and another part have another type of data, but the packet length and timing will not be affected. The ADC data has an independent framing, and switching between ADC and non-ADC modes will cause over/undersized packets that might corrups the pipeline downstream.

.. todo:: Investigate the effect of ``fn_sel`` CDC glitching on ``out_dat_tvalid/out_dat_tlast`` even when switching between non-ADC modes; a glitch could make ADC bus briefly appear on the ``out_dat`` bus. How to CDC this 3-bit signal? Have a decoder that provides a separate bit for the ADC/non-ADC mode?


ADC interface
.............


The ADC data is provided through a non-blocking AXI-Streaming interface.

ADC samples are packed into a single word in TDATA, with the first sample being placed in the MSBs of the word. This is in line with the CASPER library convention, and makes signal inspection more intuitive in simulations. Samples are signed values.
TVALID and TDATA indicate the validity and framing of the data. `FUNCGEN` will adequately handle data if TVALID that is not always '1', although  some other components downstream of the `FUNCGEN` might not (e.g. the FFT).

The TUSER bus is used to convey the ADC overflow information for each sample in the word. There is one bit per sample, with the overflow flag of first sample placed in the MSB.

Output interface
................

Output is a non-blocking AXI-Streaming bus. TDATA format is the same as the ADC interface. TUSER, however, contains a single bit indicating per presence of one or more overflows during the frame. This bit is set only on the last word of the frame.


TUSER overflow
..............

TUSER This is a very crude overflow indicator; one might expect to have a ADC few overflows in each frame as a compromise to having too much quantization noise. One overflow in a 16384 sample frame is just 0.01% saturation occurence. For this reason, we added a high-resolution overflow statistics module.

