.. title:: bsb_sync_fifo

***************************************************************************
:entity:`bsb_sync_fifo` (*bsb_sync_fifo.vhd*): Command Bus Synchronous FIFO
***************************************************************************

.. parse:: hdl/bsb/bsb_sync_fifo.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: bsb_sync_fifo

Parameters
----------

None — this entity has no generic parameters.

Interface
---------

Side A (upstream):

- ``cmd_a_tdata``, ``cmd_a_tvalid``, ``cmd_a_tlast``, ``cmd_a_tready``: Command stream input from the upstream BSB master.

- ``rply_a_tdata``, ``rply_a_tvalid``, ``rply_a_tlast``, ``rply_a_tready``: Reply stream output to the upstream BSB master.

Side B (downstream):

- ``cmd_b_tdata``, ``cmd_b_tvalid``, ``cmd_b_tlast``, ``cmd_b_tready``: Command stream output to the downstream BSB slave.

- ``rply_b_tdata``, ``rply_b_tvalid``, ``rply_b_tlast``, ``rply_b_tready``: Reply stream input from the downstream BSB slave.

System:

- ``CLK``: System clock.

- ``RST``: Synchronous reset. Propagated to both internal `axis_sync_fifo` instances.

Implementation details
----------------------

Architecture
~~~~~~~~~~~~

``bsb_sync_fifo`` wraps two instances of `axis_sync_fifo` — one for the command direction (A→B) and one for the reply direction (B→A) — providing a single entity for inserting a pipeline register into both channels of the bidirectional BSB bus simultaneously.

Principle of operation
~~~~~~~~~~~~~~~~~~~~~~

Each `axis_sync_fifo` implements a 2-deep pipeline register that absorbs one extra byte while the TREADY signal propagates back to the source. This breaks the combinatorial TREADY path that would otherwise couple the upstream and downstream handshake logic, making it much easier to meet timing constraints. The FIFO adds exactly one clock cycle of latency on each direction of the bus.
