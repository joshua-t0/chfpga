.. title:: GPIO

:entity:`GPIO`: General Purpose Input/Output
********************************************


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

    register_array
    arm_spi
    irigb_decoder
    irigb_encoder
    bp_buck_sync



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
