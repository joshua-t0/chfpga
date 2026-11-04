.. title:: bsb_regs

***********************************************************
:entity:`bsb_regs` (*bsb_regs.vhd*): BSB Register Interface
***********************************************************

.. parse:: hdl/bsb/bsb_regs.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: bsb_regs

Parameters
----------

- **DEFAULT_CONTROL_BYTES:** Initial value of the control register array loaded at reset. Provided as a flat ``std_logic_vector`` where byte 0 is in the most significant position.

- **NUMBER_OF_CONTROL_BYTES:** Number of 8-bit registers in the control word. Determines the width of the ``control_bytes`` output array.

- **NUMBER_OF_STATUS_BYTES:** Number of 8-bit registers in the status word. Determines the width of the ``status_bytes`` input array.

- **ADDR_WIDTH:** Number of address bits decoded by this module (maximum 19). Address bits above this width are forced to zero so that they do not alias into a larger RAM address space.

- **RAM_DATA_WIDTH:** Data width of the external RAM or DRP port, either 8 or 16 bits. In 16-bit mode, each 16-bit word is accessed as two consecutive byte operations (little-endian: LSB at even address, MSB at odd address).

- **RAM_ADDR_WIDTH:** Number of address bits for the external RAM or DRP interface. Setting this to 0 removes the RAM/DRP access logic entirely.

- **USE_PIPELINED_RAM_WRITE:** When ``TRUE``, RAM writes are not acknowledged and the next byte is accepted immediately (pipelined). When ``FALSE``, the module waits for the RAM ready signal (``RAM_DOUT_RDY`` or a fixed-latency delay) before accepting the next write byte.

- **USE_RAM_DOUT_RDY:** When ``TRUE``, the ``RAM_DOUT_RDY`` signal from the RAM is used to gate read data. When ``FALSE``, readout timing is determined by ``RAM_LATENCY``.

- **RAM_LATENCY:** Number of clock cycles between a ``RAM_RD_EN`` pulse and valid data on ``RAM_DOUT``. Only used when ``USE_RAM_DOUT_RDY=FALSE``. Valid values are 1 or 2.

Interface
---------

BSB command/reply bus:

- ``s_axis_bsb_tdata``, ``s_axis_bsb_tvalid``, ``s_axis_bsb_tlast``, ``s_axis_bsb_tready``: Incoming BSB command byte stream. The module is always ready to accept command bytes except when processing a read reply.

- ``m_axis_bsb_tdata``, ``m_axis_bsb_tvalid``, ``m_axis_bsb_tlast``, ``m_axis_bsb_tready``: Outgoing BSB reply byte stream. A dummy header byte is always sent first, followed by any requested read data.

- ``bsb_clk``: BSB clock. All ports are synchronous to this clock.

- ``bsb_rst``: Synchronous reset. Reloads control registers from ``DEFAULT_CONTROL_BYTES``.

Control and status registers:

- ``control_bytes``: Array of ``NUMBER_OF_CONTROL_BYTES`` output bytes. Updated by BSB write-control or write-control-with-mask commands, and reset to ``DEFAULT_CONTROL_BYTES`` on ``bsb_rst``.

- ``status_bytes``: Array of ``NUMBER_OF_STATUS_BYTES`` input bytes. Read back to the BSB master via read-status commands. Typically driven combinatorially from module status signals.

RAM/DRP interface:

- ``RAM_DIN``: Data to write to the external RAM or DRP register (``RAM_DATA_WIDTH`` bits wide).

- ``RAM_DOUT``: Data read back from the RAM or DRP register.

- ``RAM_DOUT_RDY``: Optional ready strobe from the RAM, indicating valid read data. Sampled only when ``USE_RAM_DOUT_RDY=TRUE``.

- ``RAM_ADDR``: Address bus to the RAM or DRP. Width is ``RAM_ADDR_WIDTH`` bits.

- ``RAM_WR_EN``: Single-cycle write enable pulse.

- ``RAM_RD_EN``: Single-cycle read enable pulse.

- ``RAM_EN``: Combined enable (OR of ``RAM_WR_EN`` and ``RAM_RD_EN``), for devices that use a single enable pin instead of separate read/write enables.

Implementation details
----------------------

Command format
~~~~~~~~~~~~~~

Commands are 3-byte packets formatted as ``[pppNNAAA AAAAAAAA AAAAAAAA]``:

- Bits 23–21 (``ppp``): operation opcode.
- Bits 20–19 (``NN``): log₂ of the number of bytes to transfer (read commands only). 0 = 1 byte, 1 = 2 bytes, 2 = 4 bytes, 3 = 8 bytes.
- Bits 18–0: 19-bit target address.

Supported opcodes:

======= =====================================
Opcode  Operation
======= =====================================
``000`` Read ``2^NN`` control bytes
``010`` Read ``2^NN`` status bytes
``011`` Read ``2^NN`` RAM / DRP bytes or words
``100`` Write control bytes
``101`` Write control bytes with mask (value + mask pairs)
``111`` Write RAM / DRP bytes or words
======= =====================================

Reply protocol
~~~~~~~~~~~~~~

Every command generates at least one reply byte (a dummy header whose value will be overwritten by the `bsb_master` with a sequence number). Read commands append the requested data bytes, with ``TLAST`` set on the final byte. Write commands send only the single header byte (``TLAST='1'``).

16-bit DRP access
~~~~~~~~~~~~~~~~~

When ``RAM_DATA_WIDTH=16``, each DRP word is split into two byte operations. The even byte address carries bits 7–0 (LSB) and the odd byte address carries bits 15–8 (MSB). The even address must always be accessed first; the LSB is held internally until the MSB access occurs so both bytes can be presented to the DRP simultaneously.
