.. title:: udp_mac_tx

********************************************************************
:entity:`udp_mac_tx` (*udp_mac_tx.vhd*): UDP/IP/Ethernet Transmitter
********************************************************************

.. parse:: hdl/data_links/1G_UDP_MAC/udp_mac_tx.vhd

.. default-role:: vhdl:entity

Overview
========

`udp_mac_tx` is the **transmit half** of the lightweight 1G UDP/IP stack described in
`udp_mac`. It accepts user data as an **8-bit blocking AXI4-Stream** on ``tx_clk``, buffers
it across the clock-domain boundary into the GMII transmit clock domain, and autonomously
constructs and transmits **Ethernet / IPv4 / UDP** frames with on-the-fly header generation,
IP header checksum insertion, Ethernet CRC-32 appending, and minimum-frame padding. It also
handles **ARP reply** generation when signalled by `udp_mac_rx`.

Entity documentation
====================

.. autoentity:: udp_mac_tx

Parameters
==========

- **FPGA_SERIES:** FPGA family, defined as an enumerated type in :ref:`chfpga-package`.
  Passed to the internal `generic_fifo` instances to select the correct embedded FIFO primitive
  generation. Default: ``KINTEX7``.

Interface
=========

Local address
-------------

- ``local_mac_addr``: 48-bit MAC address of this FPGA, inserted as the Ethernet source MAC
  address in every frame.

- ``local_ip_addr``: 32-bit IPv4 source address, inserted in the IP header and used for
  ARP replies.

Remote addresses
----------------

Two independent destination channels are supported, selected by ``tx_port_offset``:

- ``remote_mac_addr0`` / ``remote_ip_addr0`` / ``remote_ip_port0``: Destination MAC, IPv4
  address, and UDP port for channel 0 (``tx_port_offset = "00"``). A zero MAC address means
  the MAC address of the last received non-broadcast packet is used. Same for the IP address.

- ``remote_mac_addr1`` / ``remote_ip_addr1`` / ``remote_ip_port1``: Destination MAC, IPv4
  address, and UDP port for channel 1 (``tx_port_offset = "01"``).

ARP interface
-------------

- ``arp_request``: Rising-edge-triggered ARP reply request from `udp_mac_rx`. The transmitter
  sends one ARP reply packet when a 0→1 transition is detected.

- ``arp_remote_mac_addr``: 48-bit MAC address of the ARP requester (reply destination).

- ``arp_remote_ip_addr``: 32-bit IPv4 address of the ARP requester.

AXI4-Stream transmit input
---------------------------

- ``s_axis_udp_tx_tdata``: 8-bit UDP payload input byte.

- ``s_axis_udp_tx_tvalid``: Source-valid handshake signal.

- ``s_axis_udp_tx_tlast``: Asserted on the last byte of a UDP payload frame.

- ``s_axis_udp_tx_tready``: Back-pressure output. Deasserts when both internal FIFOs are full.

- ``tx_port_offset``: 2-bit channel selector registered on the last byte of each frame.
  Selects between the two remote address sets (0 = channel 0, 1 = channel 1).

- ``tx_clk``: User-side clock for the AXI4-Stream input interface.

Status
------

- ``tx_overflow``: Sticky overflow flag on the ``tx_clk`` domain. Asserts when a write to the
  data FIFO or the frame FIFO is attempted while the respective FIFO is full. Cleared by ``rst``.

- ``rst``: Synchronous reset (on ``tx_clk``).

GMII transmit interface
-----------------------

- ``gmii_txclk``: GMII transmit clock input. The transmit state machine and GMII outputs run
  on this clock.

- ``gmii_txer``: GMII transmit error output. Always driven low (no transmit errors generated).

- ``gmii_txc_gtxclk``: GTX transmit clock output to the PHY. Directly forwarded from
  ``gmii_txclk``.

- ``gmii_txen``: GMII transmit enable. Asserted during preamble, header, payload, padding,
  and CRC transmission.

- ``gmii_txd``: 8-bit GMII transmit data output.

Implementation details
======================

Architecture
------------

The transmitter uses two internal `generic_fifo` instances for clock-domain crossing from
``tx_clk`` to ``gmii_txclk``:

- **Data FIFO** (``data_fifo0``): Asynchronous, first-word fall-through, 9-bit embedded FIFO
  (depth 16384). Bit 8 carries the TLAST flag. Stores the raw UDP payload bytes.

- **Frame FIFO** (``frame_fifo0``): Asynchronous, standard-mode, 18-bit distributed-RAM FIFO
  (depth 128). Stores the frame byte count (bits [15:0]) and the channel selector (bits [17:16])
  for each complete frame. Written when the last byte of a frame is accepted.

A front-end process on ``tx_clk`` counts incoming bytes and writes the length + channel into
the frame FIFO on ``tlast``. A back-end state machine on ``gmii_txclk`` reads the frame FIFO
and, once a complete frame descriptor is available, sequences through the Ethernet/IP/UDP header
bytes followed by payload bytes from the data FIFO, zero-padding, and the CRC-32.

A `udp_mac_crc32` instance computes the running Ethernet CRC-32 over the transmitted frame
and the result is appended automatically. IP header checksum is pre-computed during preamble
transmission (before the IP header is actually sent) using the source and destination IP
addresses.

Clocking
--------

The AXI4-Stream input interface (frame counting, FIFO write side) runs on ``tx_clk``. The GMII
output, frame-FIFO read side, data-FIFO read side, and CRC/checksum engines run on
``gmii_txclk``. Clock-domain crossing is handled by the two asynchronous ``generic_fifo``
instances.

Principle of operations
-----------------------

When the frame FIFO is not empty, the back-end state machine exits ``STDBY`` and begins
transmitting the 8-byte Ethernet preamble (7× 0x55, then 0xD5). During preamble transmission,
the IP header checksum is pre-computed over the source and destination IP addresses. The state
machine then sequences through the full Ethernet / IPv4 / UDP header (42 bytes), inserting the
pre-computed IP checksum and the computed IP/UDP lengths at the appropriate byte positions. UDP
payload bytes are streamed from the data FIFO; if the payload is shorter than 18 bytes, zero
padding bytes are appended to guarantee the minimum 64-byte Ethernet frame. The CRC-32 engine
computes the FCS over every transmitted byte from the destination MAC through the last payload
or padding byte, and the four FCS bytes are appended. After an inter-frame gap of 16 ``gmii_txclk``
cycles the state machine checks whether another frame is ready and either restarts immediately
or returns to ``STDBY``. ARP replies are handled as a special frame type triggered by a rising
edge on ``arp_request``, inserted whenever the transmitter is idle.

Sub-modules
===========

The `udp_mac_tx` module uses the following FIFOs:

- :doc:`udp_mac_tx_data_fifo`: Asynchronous FIFO for clock domain crossing between user data clock and GMII transmit clock
- :doc:`udp_mac_tx_frame_fifo`: Asynchronous FIFO for storing packet length and transmit channel information
