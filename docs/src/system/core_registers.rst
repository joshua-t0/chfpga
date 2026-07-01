.. title:: core_registers

**********************************************************************
:entity:`core_registers` (*core_registers.vhd*): Core Registers Module
**********************************************************************

.. parse:: hdl/system/core_registers.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: core_registers

Parameters
==========

- **ADDRESS_MASK:** 32-bit address mask defining which address bits identify this module. Bits set to ``-`` are the local register address bits (e.g. ``X"000010--"`` responds when bits 31:16 equal ``0x0010`` and uses 8 local address bits).
- **NUMBER_OF_REGISTERS:** Number of 32-bit registers implemented.
- **DEFAULT_REGISTER_VALUES:** Array of 32-bit default values loaded into the write-value registers at elaboration time.
- **ADDRESS_WIDTH:** Bit width of the 32-bit bus address input ``s_addr`` (default 32).
- **BYTE_ADDRESS_WIDTH:** Bit width of the 8-bit bus byte address ``addr``. Defaults to ``ceil(log2(4 * NUMBER_OF_REGISTERS))``.
- **SIM:** When ``TRUE``, enables simulation-specific behaviour to accelerate simulations.

Interface
=========

32-bit control interface
------------------------

- ``s_addr``: Memory-mapped word address input.
- ``s_wdat``: 32-bit write data input.
- ``s_rdat``: 32-bit read data output. Zero when the address does not match this module.
- ``s_wreq``/``s_rreq``: Write/read request inputs.
- ``s_wack``/``s_rack``: Write/read acknowledge outputs.

Register interface
------------------

- ``reg_wr_value``: Array of written register values, one 32-bit entry per register. Updated on each write.
- ``reg_rd_value``: Array of read-back values driven by the application logic. Presented on ``s_rdat`` during reads.

8-bit control interface
-----------------------

- ``din``/``dout``: 8-bit data input/output for byte-wide access.
- ``addr``: Byte address within the register array (2 LSBs select the byte within a word).
- ``wr_en``/``rd_en``: Byte write/read enable inputs.

Clock
-----

- ``clk``: Clocks both the 32-bit and 8-bit control interfaces and all register logic.

Implementation details
======================

Principle of operations
-----------------------

The module implements a synchronous register file backed by the ``reg_wr_value`` and ``reg_rd_value`` arrays. Address decoding for the 32-bit bus compares the high-order bits of ``s_addr`` against the non-dash bits of ``ADDRESS_MASK``; accesses outside the matching range gate off the internal request signals and force ``s_rdat`` to zero, enabling a wired-OR bus topology where multiple ``core_registers`` instances can share a common data bus. The 8-bit interface uses a direct byte address: the upper bits select the register word and bits [1:0] select the byte lane within the 32-bit word (little-endian byte order).

Architecture
------------

Both access paths share the same ``reg_wr_value`` / ``reg_rd_value`` arrays but operate independently in the same clock domain. The 32-bit read path pipelines the incoming word address by one cycle (to relax timing on wide address comparators) and then presents the corresponding ``reg_rd_value`` entry on ``s_rdat`` with a one-cycle read latency. The 8-bit read path decodes word and byte indices combinatorially and outputs one byte on ``dout`` in the cycle following ``rd_en`` assertion. Both write paths update ``reg_wr_value`` directly in the clock cycle after the request is accepted. Registers are initialized at elaboration time to ``DEFAULT_REGISTER_VALUES``, so no explicit reset process is needed.

Clocking
--------

All logic is synchronous to a single clock, ``clk``. Both the 32-bit and 8-bit access paths share this clock with no clock-domain crossings.

Principle of Operations
=======================

The `core_registers` module implements an array of 32-bit registers that are accessible via two interfaces:

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

The `core_registers` module is used in the IceBoard platform to implement core firmware registers that are expected to be present in every application. It provides a flexible way to create memory-mapped register banks with configurable addressing.

