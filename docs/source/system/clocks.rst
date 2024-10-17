

:entity:`clocks` (`clocks.vhd`)
*******************************


The SYSTEM/CLOCKS module takes the 125 MHz reference clock coming from the MGT (and also used for the SFP+ interface) and generates the following clocks:

- 125 MHz Command clock
- 62.5 MHz SYSMON clock
- 200 MHz for auxiliary systems (IRIG-B decoder etc.) and to be used as a clock if there is no ADC Mezzanine
- 250 MHz clock (not used)

A MMCM takes the 200 MHz word clock from one ADC (ADC0, bus A on Mezzanine A) and generates an 8-phase 200 MHz clock to feed all 16 channelizers.


.. figure:: ../images/clocks.svg
    :width: 50%

Entity documentation
====================

.. parse:: hdl/SYSTEM/clocks.vhd

.. autoentity:: clocks




Additional details
==================




.. vim: sts=3 ts=3 sw=3 tw=78 smarttab expandtab
