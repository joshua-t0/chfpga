.. title:: FUNCGEN

:entity:`FUNCGEN`: Data source selector and Function Generator
**************************************************************


Overview
========

AXI4-Streaming function generator that either forwards the input from the ADC or replaces it with user-programmable arbitrary waveforms, noise, or packet test patterns.

Schematic
=========

.. figure:: ../images/funcgen.svg
    :width: 50%

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

