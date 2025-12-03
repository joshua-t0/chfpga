.. title:: XXVGLINK

:entity:`XXVGLINK`: 25G Serial Link Modules
**********************************

.. default-role:: vhdl:entity

The XXVGLINK modules implement 25 Gbps serial link transmitters and receivers using GTY transceivers on Ultrascale+ FPGAs. These modules provide high-speed data transmission for corner-turn operations and other data-intensive applications.

The XXVGLINK system consists of:

- :entity:`xxvglink_core`: Main module that instantiates and coordinates GTY transceivers, providing a memory-mapped interface for configuration and monitoring
- :entity:`xxvglink_array`: Array wrapper that manages multiple xxvglink_core instances
- :entity:`xxvglink_tx`: Transmitter module that handles packet transmission
- :entity:`xxvglink_rx`: Receiver module that handles packet reception
- :entity:`xxvglink_bypass`: Bypass mode for testing and debugging
- Supporting modules: scrambler, descrambler, block sync, data FIFO, CRC, and startup FSM

.. toctree::
   :maxdepth: 2
   :hidden:

   xxvglink_core
   xxvglink_array
   xxvglink_tx
   xxvglink_rx
   xxvglink_bypass

