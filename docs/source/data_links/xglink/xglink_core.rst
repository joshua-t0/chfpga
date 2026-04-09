.. title:: xglink_core

***************************************************************
:entity:`xglink_core` (*xglink_core.vhd*): 10G Serial Link Core
***************************************************************

.. default-role:: vhdl:entity

Overview
========

`xglink_core` is a **single-lane** 10 Gb/s link slice built around **7-series GTX** hardware. It stitches together the Wizard-generated **`xglink_gtx`** wrapper, **64B/66B** transmitter and receiver  logic, startup FSMs, and a **BSB** control tree so software can configure and monitor the transceiver and datapath. It is meant to be very compact and use as little ressources as possible. This module generates framing, encoding and FCS that is based on 10GBASE standard and is compabible with 10G Ethernet when carrying an Ethernet packet payload. 

Entity documentation
====================

.. parse:: hdl/data_links/XGLINK/xglink_core.vhd

.. autoentity:: xglink_core

Parameters
==========

- **LINK_SPEED:** ``0`` → ~7.8125 Gb/s line rate; ``1`` → ~10.3125 Gb/s (10G-class), with **156.25 MHz** reference assumptions per RTL comments.

- **NUMBER_OF_TX_LANES / NUMBER_OF_RX_LANES:** Count of TX and RX GTX lanes (vectors size to the maximum).

- **NUMBER_OF_REFCLK:** Number of differential reference inputs.

- **LANE_TO_QUAD_MAP:** Which quad each lane belongs to.

- **QUAD_TO_REFCLK_MAP:** Which refclk index feeds each quad.

- **EXAMPLE_SIMULATION / EXAMPLE_SIM_GTRESET_SPEEDUP:** Transceiver simulation attributes.

- **DONT_RESET_ON_DATA_ERROR_IN:** Policy bit for reset-on-error behavior in the wrapper.

- **NUMBER_OF_CONTROL_BYTES / NUMBER_OF_STATUS_BYTES:** Optional extra control/status byte arrays on the datapath router.

- **SIM:** Top-level simulation switch.

Interface
=========

SerDes and clocks
-----------------

- ``tx_p`` / ``tx_n``, ``rx_p`` / ``rx_n``: Differential lanes (one per GTX channel used).

- ``refclk_p`` / ``refclk_n``: **156.25 MHz** references (vector per ``NUMBER_OF_REFCLK``).

- ``refclk_div2``, ``txclk_div2``: Divided clocks for fabric use.

- ``tx_clk``: TX word clock (~244 MHz or ~322 MHz depending on ``LINK_SPEED``).

- Per-lane ``tx_resetdone``, ``rx_clk``, ``rx_resetdone``: Per-lane readiness and recovered RX clocks.

Datapath (parallel)
-------------------

- ``tx_data`` / ``tx_header`` / ``tx_ready``: **32-bit** user words + **2-bit** 64B/66B sync header; gearbox back-pressure on ``tx_ready``.

- ``rx_data`` / ``rx_data_valid`` / ``rx_header`` / ``rx_header_valid``: RX side words and validity (header valid on first half of each 66-bit block per comments).

- ``control_bytes`` / ``status_bytes``: Optional sideband byte arrays.

BSB and reset
-------------

- ``s_axis_bsb_t*`` / ``m_axis_bsb_t*``, ``bsb_clk``, ``bsb_rst``: BSB command/reply streams.

- ``areset``: Asynchronous reset.

Principle of operations
=======================

`xglink_core` is the **integration shell** for one or more **7-series GTX** channels: it instantiates Wizard-generated `xglink_gtx`, QPLL/CPLL clocking, TX/RX startup FSMs, 64B/66B framing (`xglink_tx` path elements, `xglink_rx`, scrambler/descrambler, block sync), and a BSB address router so software can bring up links, read eye/DRP-style status, and control per-quad / per-lane parameters. TX accepts **32-bit** words with **2-bit** headers when ``tx_ready`` allows; RX presents aligned descrambled data with per-lane recovered clocks. The design targets compact backplane or 10GbE-like payloads over a custom **64B/66B** line code.

Memory Map
==========

The `xglink_core` module uses a control router to distribute commands to multiple bsb_regs instances. Each bsb_regs provides a memory-mapped interface for configuration and monitoring.

Address Format
--------------

Common Module Memory Map
------------------------

.. vhdl:include-docs:: xglink_core
    :start-after: Common Module Memory Map

Quad Module Memory Map
----------------------

Each quad (QPLL) has its own memory map.

.. vhdl:include-docs:: xglink_core
    :start-after: Quad Module Memory Map

GTX Module Memory Map
---------------------

Each GTX channel has its own memory map.

.. vhdl:include-docs:: xglink_core
    :start-after: GTX Module Memory Map
