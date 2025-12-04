.. title:: ctrl_master

************************************************************
:entity:`CTRL_MASTER` (*CMD_MASTER.vhd*): Command Bus Master
************************************************************

.. parse:: hdl/CMD/CMD_MASTER.vhd

.. default-role:: vhdl:entity

The `CTRL_MASTER` module serves as the command bus master for the BSB (Byte-Serial Bus) in the chFPGA system. Its main role is to interface between an upstream command/reply stream (commonly from UDP/Ethernet) and the network of BSB slave modules for memory-mapped register access and module control.

- Receives command packets via a streaming interface and forward them directly to the BSB command channel.
- Send BSB reply packets or raw data packets  back to the streaming interface. 
- BSB reply channel and data channels are are scanned continuously to determine which wull have its packet sent, keeping the others on hold. 
- The first byte of reply packets is replaced with a packet counter to help downstream command/reply synchronization.
- Counts incoming and outgoing command packets for statistics and debugging.
- Performs data throttling to avoid overwhelming the downstream modules.

`CTRL_MASTER` BSB bus typically connects a `CTRL_ROUTER` for address-based command distribution.


Entity documentation
--------------------

.. autoentity:: CTRL_MASTER

