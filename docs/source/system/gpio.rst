****************************
:entity:`GPIO`: (*GPIO.vhd*)
****************************

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


Design Notes
============

Backplane Self-synchronizion and inter-board communication module
-----------------------------------------------------------------


We created an experimental module ``bp_buck_sync`` to allow the boards in a crate to:

- collaborate to generate a single clock  that could be used to synchronize the backplane buck without requiring a master board in a specific slot.
- communicate with each other


This module was not used in the field, and caused implementation to fail on ZCU111 platform, so we just remove it.


The self-sync was based on the clock-slowing principle of I2C, where any peripheral can hold the clock down to slow down the transactions, causing all the devices to operate at the speed of the slowest device on the bus.

Communication between boards was acheived by modulating the clock.