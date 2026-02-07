.. title:: arm_spi

***********************************************************
:entity:`arm_spi` (*arm_spi.vhd*): ARM SPI Interface Module
***********************************************************

.. parse:: hdl/system/arm_spi.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: arm_spi

Principle of Operations
=======================

The `arm_spi` module implements an SPI (Serial Peripheral Interface) slave that interfaces with an ARM processor. It converts SPI transactions into memory-mapped read/write requests that can be used to access registers and memory within the FPGA.

The module operates as an SPI slave, receiving commands and data from the ARM processor via the SPI bus (MOSI, MISO, SCK, CS_N signals) and translating them into address/data/request signals for the internal bus.

Key Features
------------

- **SPI Slave Interface**: Implements a standard SPI slave protocol
- **Memory-mapped Access**: Converts SPI transactions to read/write requests
- **32-bit Data Width**: Handles 32-bit addresses and data
- **Synchronous Operation**: All operations are synchronized to the system clock

Usage
-----

The `arm_spi` module is used in IceBoard platforms to provide a control interface between the ARM processor (typically on a Zynq device) and the FPGA fabric. It allows the ARM processor to read and write registers and memory within the FPGA using standard SPI communication.
