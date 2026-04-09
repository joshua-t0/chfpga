.. title:: xglink_tx

******************************************************************
:entity:`xglink_tx` (*xglink_tx.vhd*): 10G Serial Link Transmitter
******************************************************************


.. toctree::
   :hidden:

   xglink_tx_data_fifo
   xglink_crc32_32
   ../../navbar_separator

.. parse:: hdl/data_links/XGLINK/xglink_tx.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: xglink_tx

Parameters
==========

- **SIM:** Simulation switch; disables GTX-dependent logic when ``TRUE``.

Interface
=========

User AXI-Stream (``user_clk``)
-------------------------------

- ``s_axis_tx_tdata`` / ``tvalid`` / ``tlast`` / ``tready``: **32-bit blocking AXI-Stream** from user logic. ``tready`` is deasserted when the TX state machine cannot accept data.

- ``tx_fifo_overflow``: Transient flag if the internal TX FIFO overflows.

XGLINK core side (``clk``)
--------------------------

- ``tx_data`` / ``tx_header`` / ``tx_ready``: **32-bit** data and **2-bit** 64B/66B header to `xglink_core`; accepts a word only when ``tx_ready='1'`` (gearbox gating).

System
------

- ``clk``: TX clock from `xglink_core` (``tx_clk``).

- ``rst``: Asynchronous reset.

Principle of operations
=======================

`xglink_tx` **frames** a **blocking 32-bit AXI-Stream** into **64B/66B control** and **data** blocks: **start-of-frame**, **payload**, **CRC-32** (`xglink_crc32_32`), **end-of-frame**, and **IDLE** inserts when no user data is available—matching a **lightweight 10GbE-like** framing. The FSM **only commits** 32-bit halves when ``tx_ready`` is high, so the **first** beat after a deasserted ``tx_ready`` is always the **start of a 66-bit block**. Continuous **tvalid** after a completed frame yields **back-to-back** packets without mid-frame IDLEs.

Implementation details
======================

- **Byte order:** First byte on the wire is the **MSB** of the 32-bit user word (bit 24 first), consistent with `xglink_core` (not configurable).

- **FIFO:** A Xilinx **TX data FIFO** (:doc:`xglink_tx_data_fifo`) bridges rate / phase between user logic and the TX state machine.
