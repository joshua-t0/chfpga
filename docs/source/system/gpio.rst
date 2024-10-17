.. title:: GPIO

:entity:`GPIO`: General Purpose Input/Output
********************************************

The :entity:`gpio` provides a bank of configuration registers as well as:

- Motherboard Buck Synchronization
- Backplane Buck Synchronization
- IRIG-B decoder (:entity:`irigb_decoder`) and generator
- IRIG-B tagging of Referenece clock counter and Frame counters
- External ARM processor SPI memory-map interface
- Externally configurable core configuration registers


Overview
========


Schematic
=========

.. figure:: ../images/gpio.svg
    :width: 100%

Sub-modules
===========

.. toctree::
    :titlesonly:

    irigb_decoder
..    bp_buck_sync
..    irigb_encoder
..    register_array
..    arm_spi



Entity documentation
====================

.. parse:: hdl/SYSTEM/GPIO.vhd

.. autoentity:: GPIO


UDP Memory Map
==============

.. include-docs:: GPIO
    :start-after: GPIO Module

ARM-SPI Memory Map
==================

.. .. include-docs:: GPIO
..     :start-after: GPIO Module
