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
