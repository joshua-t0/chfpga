.. title:: bsb_router

***********************************************************
:entity:`bsb_router` (*bsb_router.vhd*): Command Bus Router
***********************************************************

.. parse:: hdl/bsb/bsb_router.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: bsb_router

Parameters
----------

- **NUMBER_OF_PORTS:** Number of downstream BSB ports. Commands are routed to one of these ports based on the address field, and their replies are merged back to the upstream interface.

- **ADDRESS_MASK:** Bitmask applied to the 19-bit command address to extract the destination port number. The bit positions covered by the mask determine which address bits select the port. For example, a mask of ``"000_0001_1100_0000_0000"`` routes on bits 8–6, giving up to 8 ports. The mask must be a contiguous range of bits.

- **TARGET_PBLOCK:** Optional implementation hint string stored as a node property on the module for floorplanning. Has no effect on logic functionality.

Interface
---------

Upstream BSB interface:

- ``s_axis_bsb_tdata``, ``s_axis_bsb_tvalid``, ``s_axis_bsb_tlast``, ``s_axis_bsb_tready``: Incoming command stream from the upstream BSB master (e.g. `bsb_master`).

- ``m_axis_bsb_tdata``, ``m_axis_bsb_tvalid``, ``m_axis_bsb_tlast``, ``m_axis_bsb_tready``: Merged reply stream returned to the upstream BSB master.

Downstream BSB ports (arrays of ``NUMBER_OF_PORTS`` elements):

- ``m_axis_routed_bsb_tdata``, ``m_axis_routed_bsb_tvalid``, ``m_axis_routed_bsb_tlast``, ``m_axis_routed_bsb_tready``: Routed command output to each downstream slave (e.g. `bsb_regs` or another `bsb_router`).

- ``s_axis_routed_bsb_tdata``, ``s_axis_routed_bsb_tvalid``, ``s_axis_routed_bsb_tlast``, ``s_axis_routed_bsb_tready``: Reply input from each downstream slave.

Monitoring:

- ``cmd_overflow``: Sticky flag asserted if the internal command header buffer overflows. This indicates a design error (should never occur under correct operation).

System:

- ``clk``: System clock.

- ``rst``: Synchronous reset.

Implementation details
----------------------

Architecture
~~~~~~~~~~~~

A `bsb_sync_fifo` is instantiated at the upstream port to register the TREADY paths and break combinatorial timing loops between the upstream master and the routing logic.

Command routing
~~~~~~~~~~~~~~~

Commands are accumulated into an internal shift-register buffer (depth = command header length + 2 bytes). The router waits until the full 3-byte header is buffered before inspecting the address field. The destination port number is obtained by extracting the bits indicated by ``ADDRESS_MASK`` from the concatenated header bytes. Once the port is identified, all buffered bytes — and any subsequent data bytes — are streamed out to the selected downstream port until ``TLAST`` is asserted, at which point the router returns to header accumulation for the next command.

Reply merging
~~~~~~~~~~~~~

A separate state machine scans all ``NUMBER_OF_PORTS`` downstream reply inputs in priority order (lowest index first). When a port asserts ``TVALID``, the reply is forwarded byte-by-byte to the upstream reply output until ``TLAST``. A one-slot overflow buffer handles the one-cycle pipeline latency on the upstream ``TREADY``, ensuring no bytes are lost at the boundary between accepting a byte and the upstream signalling that it cannot receive more.
