.. title:: ADCDAQ

:entity:`ADCDAQ`: Analog to Digital Converter Data Aquisistion
**************************************************************

.. default-role:: vhdl:entity


Schematic
=========

.. figure:: ../images/adcdaq_block_diagram.svg
    :width: 50%


.. toctree::
    :titlesonly:

    adcdaq_fifo

Entity documentation
====================

.. parse:: hdl/CHAN/ADCDAQ.vhd

.. autoentity:: ADCDAQ


.. .. highlight:: vhdl

..  .. role:: vhdl(code)
..   :language: vhdl


Additional details
==================

Implements the data acquisition of one channel of a EV8AQ160 ADC in non-DMUX mode and send the output as a non-blocking, 32-bit wide AXI4 Streaming Bus.

Schematic
=========


.. figure:: ../images/adcdaq_pll_unambiguous_phase_config.svg
    :width: 50%
