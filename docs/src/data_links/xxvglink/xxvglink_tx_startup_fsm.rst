.. title:: xxvglink_tx_startup_fsm

*****************************************************************************************
:entity:`xxvglink_tx_startup_fsm` (*xxvglink_tx_startup_fsm.vhd*): GTY TX Startup FSM
*****************************************************************************************

.. default-role:: vhdl:entity

Overview
========

**TX reset and initialization FSM** adapted from the **7-series Transceivers Wizard** flow, reused for **UltraScale+ GTY** bring-up: stable-clock-based counters, soft reset, PLL lock handshakes, optional **manual phase alignment**, and **`TX_FSM_RESET_DONE` / `TXUSERRDY`** qualification. Generics configure **clock period, retry counter width**, and whether **QPLL/CPLL** resets are coordinated with RX FSMs.

Entity documentation
====================

.. parse:: hdl/data_links/XXVGLINK/xxvglink_tx_startup_fsm.vhd

.. autoentity:: xxvglink_tx_startup_fsm

Parameters
==========

**Wizard** generics: **stable clock period, retry counter width, QPLL/CPLL** coordination flags, **simulation speedup, phase alignment** enables—see parsed entity (values set at **IP generation** time).

Interface
=========

**GTY TX reset** handshake ports: **stable** and **user** clocks, **reset** strobes, **TXUSERRDY, TXRESETDONE, PLL lock**—as exported for **UltraScale+** (wired from `xxvglink_core` / GTY wrapper).

Principle of operations
=======================

Sequences GTY TX reset and waits for PLL lock and TXRESETDONE, optionally performs manual phase alignment, then asserts TXUSERRDY so PCS logic may drive the serial output safely.

Implementation details
======================

Treat as **generated** transceiver infrastructure: adjust generics only when the Wizard / core IP is regenerated for a new device or clocking plan.
