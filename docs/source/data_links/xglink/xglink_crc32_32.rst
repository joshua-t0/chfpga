.. title:: xglink_crc32_32

****************************************************************************
:entity:`xglink_crc32_32` (*xglink_crc32_32.vhd*): CRC-32 Computation Module
****************************************************************************

.. parse:: hdl/data_links/XGLINK/xglink_crc32_32.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: xglink_crc32_32

Principle of Operations
=======================

The `xglink_crc32_32` module computes a 32-bit CRC (Cyclic Redundancy Check) checksum for data streams. It processes 32-bit words and generates a CRC-32 value that can be used for error detection in packet transmission.

The module implements a pipelined CRC computation that processes one 32-bit word per clock cycle. The CRC polynomial and initialization values are configured for compatibility with standard CRC-32 algorithms used in networking protocols.

Key Features
------------

- **Pipelined operation**: Processes one 32-bit word per clock cycle
- **32-bit data width**: Operates on 32-bit input words
- **32-bit CRC output**: Generates a 32-bit CRC checksum
- **Synchronous reset**: Includes reset functionality for initialization

Usage in XGLINK
---------------

The `xglink_crc32_32` module is instantiated in both the :entity:`xglink_tx` (transmitter) and :entity:`xglink_rx` (receiver) modules:

- **In xglink_tx**: Computes the CRC for outgoing packets to be appended to the packet data
- **In xglink_rx**: Computes the CRC for incoming packets to verify data integrity

The CRC computation is used to detect transmission errors in the high-speed serial link data streams.

