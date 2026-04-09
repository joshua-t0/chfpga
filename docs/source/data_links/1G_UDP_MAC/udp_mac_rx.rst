.. title:: udp_mac_rx

********************************************************************
:entity:`udp_mac_rx` (*udp_mac_rx.vhd*): 1G Ethernet UDP/IP Receiver
********************************************************************

.. toctree::
   :titlesonly:

   crc32

.. default-role:: vhdl:entity

Overview
========

`udp_mac_rx` is the **receive half** of the lightweight 1G UDP/IP stack described in `udp_mac`. It ingests **GMII** (8-bit parallel) Ethernet frames on ``gmii_rxclk``, parses **Ethernet / IPv4 / UDP** (and a minimal **ARP** subset), and presents accepted **UDP payloads** on an **8-bit AXI4-Stream** interface synchronous to ``clk``.

The block performs **address and port filtering**, **Ethernet FCS (CRC-32) checking** (via `udp_mac_crc32`), **clock-domain crossing** into the user clock domain, and exposes **source address information** so the companion transmitter can reply to the correct peer or handle **ARP**.

Entity documentation
====================

.. parse:: hdl/data_links/1G_UDP_MAC/udp_mac_rx.vhd

.. autoentity:: udp_mac_rx

Parameters
==========

- **BROADCAST_IP_PORT:** UDP destination port number used to accept broadcast UDP packets,
  regardless of address filtering. Setting a fixed well-known port allows broadcast reception
  even before per-session addressing is configured. Default: 40999.

- **FPGA_SERIES:** FPGA family, defined as an enumerated type in :doc:`../chfpga_package`.
  Selects the appropriate embedded FIFO primitive generation (FIFO18E1 for Kintex-7,
  FIFO18E2 for Ultrascale+). Default: ``KINTEX7``.

Interface
=========

Address configuration
---------------------

- ``local_mac_addr``: 48-bit MAC address of the local FPGA. Incoming frames whose destination
  MAC does not match this address or the broadcast address ``FF:FF:FF:FF:FF:FF`` are discarded.

- ``local_ip_addr``: 32-bit IPv4 address of the local FPGA. Frames whose destination IP does
  not match this address or the broadcast address ``255.255.255.255`` are discarded.

- ``local_ip_port``: 16-bit UDP destination port to accept for unicast packets. Broadcast
  packets are accepted on ``BROADCAST_IP_PORT`` regardless of this value. A value of zero
  suppresses all frame reception.

Source address outputs
----------------------

- ``latest_remote_mac_addr``: 48-bit MAC address of the last accepted non-broadcast unicast
  packet sender. Updated on the last byte of each accepted unicast frame.

- ``latest_remote_ip_addr``: 32-bit IPv4 address of the last accepted non-broadcast unicast
  packet sender.

- ``latest_remote_ip_port``: 16-bit source port of the last accepted non-broadcast unicast
  packet sender.

ARP interface
-------------

- ``arp_request``: Asserts when a valid ARP request matching ``local_ip_addr`` is received.
  Cleared on reset and re-asserted on each new matching ARP request. Used by `udp_mac_tx` to
  trigger an ARP reply.

- ``arp_remote_mac_addr``: 48-bit MAC address of the ARP requester.

- ``arp_remote_ip_addr``: 32-bit IPv4 address of the ARP requester.

AXI4-Stream receive output
---------------------------

- ``m_axis_udp_rx_tdata``: 8-bit UDP payload output byte.

- ``m_axis_udp_rx_tvalid``: Asserts when a valid, fully received, and CRC-checked UDP payload
  byte is available for consumption.

- ``m_axis_udp_rx_tlast``: Asserts on the last byte of a UDP payload frame.

- ``m_axis_udp_rx_tready``: Back-pressure input from the downstream consumer. Must be asserted
  to accept a byte. The interface is blocking: withholding ``tready`` stalls frame delivery.

- ``clk``: User-side clock for the AXIS output bus and the read side of internal FIFOs.

GMII receive interface
----------------------

- ``gmii_rxclk``: Recovered receive clock from the PHY, synchronous to the incoming GMII
  data. Drives the write side of internal FIFOs and the frame-decoding state machine.

- ``gmii_rxctrl_rxdv``: GMII receive data valid (``RX_DV`` in IEEE 802.3). Deasserts between
  frames and on errors.

- ``gmii_rxd``: 8-bit GMII receive data bus.

Status
------

- ``rx_overflow``: Sticky overflow flag. Asserts when the RX data FIFO is almost full while
  a frame payload is being received, or when the frame FIFO overflows. Cleared only by ``rst``.

- ``rst``: Asynchronous reset for the entire module.

Implementation details
======================

Architecture
------------

The receiver is a single synchronous process on ``gmii_rxclk`` that decodes the GMII byte
stream through a multi-state FSM (``rx_state``). Accepted UDP payloads are written byte-by-byte
into an asynchronous, first-word fall-through 9-bit embedded FIFO (``data_fifo0``, depth 4096
words; bit 8 carries the TLAST flag). A separate 1-bit asynchronous distributed-RAM FIFO
(``frame_fifo0``, depth 64) stores one validity flag per frame. A `udp_mac_crc32` engine
computes CRC-32 on the incoming data via a 4-byte delay line (to exclude the received FCS
bytes from the CRC input) and the result is verified at end-of-frame.

Clocking
--------

Frame reception and the write side of both FIFOs run on ``gmii_rxclk`` (PHY recovered clock).
User data delivery and the read side of both FIFOs run on ``clk`` (independent 125 MHz clock).
Clock-domain crossing is handled by the two asynchronous first-word fall-through FIFOs.

Principle of operations
-----------------------

The FSM progresses through Ethernet / IPv4 / UDP header fields, checking destination MAC, IP,
and port at each stage and jumping to a ``SKIP`` state for mismatches. ARP requests for
``local_ip_addr`` are latched into ``arp_request`` / ``arp_remote_*``. For accepted UDP
frames, payload bytes are written into the data FIFO with the TLAST flag set on the last byte.
After the last payload byte, the remaining frame bytes (padding + FCS) are skipped; the CRC
result is then checked over four output cycles. The frame FIFO is written with '1' (valid CRC,
no overflow) or '0' (bad CRC or overflow). On the ``clk`` domain, ``m_axis_udp_rx_tvalid`` is
asserted only when the frame FIFO contains a valid-frame flag and the data FIFO contains bytes;
frames flagged as invalid are silently flushed by consuming data FIFO bytes without asserting
``tvalid``.
