.. title:: xge_udp_mac_tx

************************************************************************************
:entity:`xge_udp_mac_tx` (*xge_udp_mac_tx.vhd*): 10G Ethernet UDP/IP/MAC Transmitter
************************************************************************************


.. toctree::
   :maxdepth: 2
   :hidden:

   xgmii_udp_mac_tx_data_fifo
   xgmii_udp_mac_tx_header_fifo
   ../../navbar_separator  


.. parse:: hdl/data_links/10GE_UDP_MAC/xge_udp_mac_tx.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: xge_udp_mac_tx

Parameters
==========

- **USE_LITTLE_ENDIAN:** When ``TRUE`` (default), the LSB of each 32-bit user word is the first byte transmitted (little-endian per-byte ordering). When ``FALSE``, the MSB is transmitted first (big-endian).

Interface
=========

Network address inputs
----------------------

These ports are registered on reset and used to fill the Ethernet/IPv4/UDP headers. The module must be reset when any of these values change.

- ``MAC_SRC_ADDR``: 48-bit source MAC address of the local FPGA.

- ``MAC_DEST_ADDR``: 48-bit destination MAC address.

- ``IP_SRC_ADDR``: 32-bit source IPv4 address.

- ``IP_DEST_ADDR``: 32-bit destination IPv4 address.

- ``IP_DEST_PORT``: 16-bit UDP destination port (default: 41000).

User-side AXI-Stream input (``s_axis_tx_clk``)
------------------------------------------------

- ``s_axis_tx_tdata``: 32-bit user payload word.

- ``s_axis_tx_tvalid``: Data valid; the word is accepted when both ``tvalid`` and ``tready`` are high.

- ``s_axis_tx_tlast``: End-of-packet indicator. Must be asserted on the last payload word of each UDP datagram.

- ``s_axis_tx_tready``: Back-pressure output. Deasserted when the data FIFO is full.

- ``s_axis_tx_clk``: User clock. Must be below ~322.5 MHz minus Ethernet frame overhead.

- ``data_overflow``: Asserted when the data FIFO overflows (payload data was lost).

- ``frame_overflow``: Asserted when the header/frame FIFO overflows (a whole frame was lost).

GTY/XGLINK-side output (``clk``)
---------------------------------

- ``tx_data``: 32-bit word sent to the 10G link core. MSB is transmitted first.

- ``tx_header``: 2-bit 64B/66B block header: ``01`` for data, ``10`` for control.

- ``tx_ready``: Input from the 10G link core gearbox; the transmitter samples ``tx_data`` only when high.

- ``clk``: TX word clock from the 10G link core.

Reset
-----

- ``RST``: Asynchronous active-high reset. Also triggers re-computation of the IP header checksum.

Implementation details
======================

Principle of operations
-----------------------

`xge_udp_mac_tx` is a fully pipelined 10G Ethernet UDP/IP/MAC transmitter packetizer. On receiving a user AXI-Stream frame, it builds a complete Ethernet frame consisting of a preamble/SFD, an Ethernet header (14 bytes), an IPv4 header (20 bytes with pre-computed checksum), a UDP header (8 bytes), the user payload, and an Ethernet CRC32. The frame is output on a 32-bit XGMII-style bus (``tx_data``) at the ``clk`` rate.

Two asynchronous FIFOs bridge the ``s_axis_tx_clk`` and ``clk`` domains: ``xgmii_udp_mac_tx_data_fifo`` buffers the payload, and ``xgmii_udp_mac_tx_header_fifo`` stores the per-frame length. The TX state machine sequences through states to emit the Ethernet/IP/UDP header words, then streams payload words from the data FIFO, adds padding bytes if necessary to align the CRC to the next 64-bit word boundary, and finally emits the CRC followed by an EOF control block. Minimum Ethernet frame padding (to 64 bytes) is not added; the application must supply a sufficiently large payload.

Sub-modules
-----------

The `xge_udp_mac_tx` module uses the following FIFOs:

- :doc:`xgmii_udp_mac_tx_data_fifo`: Asynchronous FIFO for clock domain crossing between user data clock and XGMII transmit clock
- :doc:`xgmii_udp_mac_tx_header_fifo`: Asynchronous FIFO for storing packet header information
