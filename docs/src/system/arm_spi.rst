.. title:: arm_spi

***********************************************************
:entity:`arm_spi` (*arm_spi.vhd*): ARM SPI Interface Module
***********************************************************

.. parse:: hdl/system/arm_spi.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: arm_spi

Parameters
==========

This module has no generic parameters.

Interface
=========

- ``clk``: System clock. All logic is synchronous to this clock.
- ``reset``: Synchronous reset. Resets the SPI state machine when asserted.
- ``sck``: SPI clock input from the ARM processor. Sampled and edge-detected with a 3-stage shift register.
- ``miso``: SPI MISO serial output to the ARM processor.
- ``mosi``: SPI MOSI serial input from the ARM processor.
- ``cs_n``: SPI chip select, active low. Resets the state machine when deasserted.
- ``addr``: 32-bit memory-mapped address driven for each transaction. Bits 1:0 encode the operation type (read/write/masked write).
- ``din``: 32-bit read data input. Captured and shifted out on MISO during read transactions.
- ``dout``: 32-bit write data output. Assembled from MOSI bits during write transactions.
- ``wreq``/``rreq``: Write/read request strobes, each asserted for one clock cycle when a transaction is dispatched.
- ``wack``/``rack``: Write/read acknowledge inputs from the downstream module.

Implementation details
======================

The module implements three operation types, encoded in the two LSBs of the address word received on MOSI:

- ``00`` — Read: address is driven and ``rreq`` is pulsed; the module waits for ``rack`` then shifts ``din`` out on MISO.
- ``01`` — Write: the next 32-bit SPI word is captured and driven on ``dout`` with ``wreq``.
- ``10`` — Masked write: performs a read, waits for the next SPI data word (write value) and a third word (mask), merges them with the read data, then performs a write.

If ``rack`` is not received within 64 clock cycles during a read, the module returns ``0xDEADDEAD`` to avoid hanging the SPI bus.

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
