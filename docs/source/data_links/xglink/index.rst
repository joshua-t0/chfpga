.. title:: XGLINK

XGLINK (10Gbps Links): 10G Serial Link Modules
***********************************************

.. default-role:: vhdl:entity

The XGLINK modules implement 10 Gbps serial link transmitters and receivers using GTX transceivers on Kintex-7 FPGAs. These modules provide high-speed data transmission for corner-turn operations and other data-intensive applications.

The XGLINK system consists of:

- :entity:`xglink_core`: Main module that instantiates and coordinates GTX transceivers, providing a memory-mapped interface for configuration and monitoring
- :entity:`xglink_array`: Array wrapper that manages multiple xglink_core instances
- :entity:`xglink_tx`: Transmitter module that handles packet transmission
- :entity:`xglink_rx`: Receiver module that handles packet reception
- :entity:`xglink_bypass`: Bypass mode for testing and debugging
- Supporting modules:
  - :doc:`xglink_scrambler`: 64B/66B scrambler for data encoding
  - :doc:`xglink_descrambler`: 64B/66B descrambler for data decoding
  - :doc:`xglink_block_sync`: Block synchronization state machine
  - :doc:`xglink_gtx`: GTX transceiver wrapper
  - :doc:`xglink_rx_startup_fsm`: RX startup state machine
  - :doc:`xglink_tx_startup_fsm`: TX startup state machine
  - :doc:`xglink_sync_block`: Clock domain crossing synchronizer
  - :doc:`xglink_crc32_32`: CRC-32 computation module

.. toctree::
   :maxdepth: 2
   :hidden:

   xglink_core
   xglink_array
   xglink_tx
   xglink_rx
   xglink_bypass
   xglink_scrambler
   xglink_descrambler
   xglink_block_sync
   xglink_gtx
   xglink_rx_startup_fsm
   xglink_tx_startup_fsm
   xglink_sync_block
   xglink_crc32_32

