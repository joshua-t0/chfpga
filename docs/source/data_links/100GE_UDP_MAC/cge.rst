.. title:: CGE

*********************************************
:entity:`CGE` (*cge.vhd*): 100G Ethernet Core
*********************************************

.. default-role:: vhdl:entity

Overview
========

`cge` (**100G Ethernet**) wraps the **CMAC** + **MAC+PHY** solution for UltraScale+: **four** CAUI-4 lanes on ``tx_p/n``, **156.25 MHz** differential reference, and a wide **AXI-Stream** TX path (**256-bit** user ``s_axis_tx_*`` on ``clk``, with internal widening toward the core). Includes **BSB** registers for configuration, optional **embedded packet generator** (``IMPLEMENT_PACKET_GENERATOR``), and exports ``clk322_out`` for high-speed sideband logic. ``rst`` is documented in the entity as **synchronous** to the user clock domain.

Entity documentation
====================

.. parse:: hdl/data_links/100GE_UDP_MAC/cge.vhd

.. autoentity:: cge

Parameters
==========

- **DEFAULT_MAC_SRC_ADDR / DEFAULT_MAC_DEST_ADDR:** Default Ethernet source and destination for transmitted frames.

- **DEFAULT_IP_SRC_ADDR / DEFAULT_IP_DEST_ADDR / DEFAULT_IP_DEST_PORT:** Default IPv4 addresses and UDP destination port.

- **IMPLEMENT_PACKET_GENERATOR:** When ``TRUE``, includes the embedded packet generator path in the design.

- **SIM:** Simulation-oriented elaboration when ``TRUE``.

Interface
=========

100G serial and clocks
----------------------

- ``tx_p`` / ``tx_n``: CAUI-4 (four differential lanes) to the CMAC / PHY.

- ``refclk_p`` / ``refclk_n``: **156.25 MHz** differential reference.

- ``refclk_out``: Buffered reference out for the board or downstream logic.

- ``clk322_out``: ~322 MHz clock derived from the 100G core; clocks user-side parallel interfaces tied to the MAC.

User data (``clk``)
-------------------

- ``s_axis_tx_tdata`` (**256-bit**), ``tvalid``, ``tlast``: AXI-Stream TX toward the CMAC datapath (widened internally as needed). First byte in the LSB-oriented packing per entity comments.

- ``clk``: User AXIS clock domain.

- ``rst``: Synchronous reset in the user clock domain (per entity).

BSB
---

- ``s_axis_bsb_t*`` / ``m_axis_bsb_t*`` on ``bsb_clk`` / ``bsb_rst``: Register access and status readback.

Implementation details
======================

Principle of operations
-----------------------

`cge` wraps the Xilinx **100G Ethernet** solution (CMAC + supporting MAC/PHY logic) for UltraScale+. It presents a **wide AXI-Stream** transmit interface on ``clk``, bridges to four serialized lanes on ``tx_p/n``, and exposes BSB registers for configuration, optional built-in traffic generation when ``IMPLEMENT_PACKET_GENERATOR`` is enabled, and diagnostics. ``clk322_out`` provides a high-speed sideband clock for logic that must align with the serdes timeline. UDP framing and software-visible defaults for MAC/IP/port follow the same conceptual model as `xge_array`, adapted to the 100G IP boundary.

Architecture
------------

The TX datapath crosses two clock domains through a pair of async FIFOs: a **data FIFO** (256-bit write on ``clk``, 512-bit read on ``clk322_out``, 8×RAMB36) and a **1-bit flag FIFO** that tracks packet boundaries to guarantee full packets are available before the CMAC starts reading, preventing underflow. The write side packs user 256-bit words two-at-a-time; the read side presents 512-bit words with per-half ``tvalid``/``tlast`` byte-enables to the Xilinx **CMAC_USP** IP. A four-state startup FSM (``INIT_CMAC`` → ``CMAC_LOCKED`` → ``CMAC_ALIGNED`` → ``FIFO_READY``) controls when TX is permitted. The packet generator (when enabled) produces Ethernet/IPv4/UDP frames entirely in RTL on the ``clk`` side. BSB registers expose CMAC resets, packet-generator parameters, and DRP access to the CMAC.

Memory map
==========

.. include-docs:: cge
    :start-after: Memory Map
