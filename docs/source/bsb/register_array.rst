.. title:: register_array

**********************************************************************
:entity:`register_array` (*register_array.vhd*): Register Array Module
**********************************************************************

.. parse:: hdl/CMD/register_array.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: register_array

Principle of Operations
=======================

The `register_array` module implements an array of 32-bit registers that are accessible via two interfaces:

1. **32-bit req/ack bus**: Standard memory-mapped interface with address, write data, read data, write request, write acknowledge, read request, and read acknowledge signals
2. **8-bit byte-wide bus**: Alternative interface using 8-bit data and byte addresses

The module uses an address mask to determine which address range it responds to, allowing multiple register arrays to coexist in the same address space.

Key Features
------------

- **Configurable register count**: Supports any number of registers (up to 256 with 8-bit local addressing)
- **Address masking**: Uses an address mask to define the address range
- **Default values**: Registers can be initialized with default values
- **Dual interface**: Supports both 32-bit and 8-bit access modes
- **Simulation mode**: Includes a simulation mode to accelerate simulations

Usage
-----

The `register_array` module is used in the IceBoard platform to implement core firmware registers that are expected to be present in every application. It provides a flexible way to create memory-mapped register banks with configurable addressing.

