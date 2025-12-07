.. title:: spi

*****************************************
:entity:`spi` (*spi.vhd*): SPI peripheral
*****************************************

.. figure:: ../images/SYSTEM/spi.svg
    :width: 100%

Entity documentation
====================

.. parse:: hdl/system/spi.vhd

.. autoentity:: spi




Additional details
==================

The SPI entity is a very simple SPI controller that can perform 1, 2,3 or 4 bytes tansactions (the count includes both read and write bytes).
The module is operated through control and status registers, and there is no buffer or FIFO. Throughput is therefore limited. The SPI controller provided by the platform processor, if available, should be used if a high-performance interface is required.

Operations
----------

A transaction is performed as follows:

- Write N bytes to transmit in the TX_BYTES register
- Set the number of bytes of the transaction, address and port
- Write 0 then 1 in the START_TRIG register to initiate the transfer
- Wait for the READY bit to be set to 1
- Read the readout bits in RX_REGISTER

Memory map
==========

.. include-docs:: spi
    :start-after: Memory map

