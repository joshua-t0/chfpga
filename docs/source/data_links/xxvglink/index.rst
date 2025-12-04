.. title:: XXVGLINK

XXVGLINK (25Gbps Links): 25G Serial Link Modules
************************************************


.. default-role:: vhdl:entity

The XXVGLINK modules implement 25 Gbps serial link transmitters and receivers using GTY transceivers on Ultrascale+ FPGAs. These modules provide high-speed data transmission for corner-turn operations and other data-intensive applications.

The XXVGLINK system consists of:

- :entity:`xxvglink_core`: Main module that instantiates and coordinates GTY transceivers, providing a memory-mapped interface for configuration and monitoring
- :entity:`xxvglink_array`: Array wrapper that manages multiple xxvglink_core instances
- :entity:`xxvglink_tx`: Transmitter module that handles packet transmission
- :entity:`xxvglink_rx`: Receiver module that handles packet reception
- :entity:`xxvglink_bypass`: Bypass mode for testing and debugging
- Supporting modules:
  - :doc:`xxvglink_scrambler`: 64B/66B scrambler for data encoding
  - :doc:`xxvglink_descrambler`: 64B/66B descrambler for data decoding
  - :doc:`xxvglink_block_sync`: Block synchronization state machine
  - :doc:`xxvglink_data_fifo`: Asynchronous data FIFO for clock domain crossing
  - :doc:`crc32_64`: 64-bit CRC-32 computation module

.. toctree::
   :maxdepth: 2
   :hidden:

   xxvglink_core
   xxvglink_array
   xxvglink_tx
   xxvglink_rx
   xxvglink_bypass
   xxvglink_scrambler
   xxvglink_descrambler
   xxvglink_block_sync
   xxvglink_data_fifo
   crc32_64

