.. title:: SYSTEM

**********************************************
:entity:`SYSTEM` (*system.vhd*): System module
**********************************************

.. toctree::
   :maxdepth: 1
   :hidden:

   gpio
   i2c
   spi
   blinker
   refclk
   sysmon_xadc
   freq_ctr
   ../navbar_separator

.. parse:: hdl/SYSTEM/system.vhd

.. default-role:: vhdl:entity

.. figure:: ../images/SYSTEM/system.svg
    :width: 50%

    SYSTEM module block diagram showing the command router and sub-modules.



Entity documentation
====================

.. autoentity:: system


Memory map
==========

.. include-docs:: system
    :start-after: SYSTEM Memory Map

