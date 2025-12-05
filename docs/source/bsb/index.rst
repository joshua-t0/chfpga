.. title:: BSB

BSB (Byte-Serial Bus): Control Bus Modules
******************************************

.. toctree::
   :maxdepth: 2
   :hidden:

   cmd_master
   cmd_slave2
   cmd_router
   cmd_sync_fifo
   cmd_async_fifo
   axis_sync_fifo
   arm_spi
   register_array
   irigb_encoder
   irigb_comparator
   ../navbar_separator
   bsb_protocol

.. default-role:: vhdl:entity

The BSB (Byte-Serial Bus) section documents the control bus modules used in the chFPGA project for command and control communication between the host system and FPGA modules.

The BSB system consists of:

- :entity:`CTRL_MASTER`: Master module that interfaces with UDP/Ethernet and manages command/reply streams
- :entity:`CTRL_SLAVE`: Slave module that processes commands and provides memory-mapped register access
- :entity:`CTRL_ROUTER`: Router module that distributes commands to multiple slave modules based on address decoding
- :entity:`cmd_sync_fifo`: Synchronous FIFO for pipelining command and reply streams
- :entity:`CMD_ASYNC_FIFO`: Asynchronous FIFO for clock domain crossing of command and reply streams
- :entity:`axis_sync_fifo`: AXI-Streaming synchronous FIFO used by cmd_sync_fifo
- :doc:`arm_spi`: ARM SPI interface module for IceBoard platforms
- :doc:`register_array`: Register array module for memory-mapped register banks
- :doc:`irigb_encoder`: IRIG-B time code encoder
- :doc:`irigb_comparator`: IRIG-B time comparator for time-based event triggering

See :doc:`bsb_protocol` for more details on the BSB protocol.