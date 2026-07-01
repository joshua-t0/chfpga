.. title:: axi_lite

**************************************************************************
:entity:`axi_lite` (*axi_lite.vhd*): BSB RAM to AXI4-Lite bridge
**************************************************************************

.. parse:: hdl/utils/axi_lite.vhd

.. default-role:: vhdl:entity

Entity documentation
====================

.. autoentity:: axi_lite

Host access contract
====================

BSB RAM **byte** addresses match the **PG203 AXI4-Lite byte map** for the CMAC US+ core
(for example ``0x000C`` = ``CONFIGURATION_TX_REG1``).

The RAM port is **16 bits** wide: one halfword per access, two halfwords per 32-bit AXI
register. ``RAM_ADDR(1)`` selects the halfword within the 32-bit word:

- byte address with bit1 = ``0`` (e.g. ``base``, ``base+1``) → AXI ``[31:16]``
- byte address with bit1 = ``1`` (e.g. ``base+2``, ``base+3``) → AXI ``[15:0]``

When used behind :entity:`cge` ``bsb_regs``, each 16-bit word is built from two BSB bytes
(MSB byte first on the wire).

Write behaviour
---------------

- First halfword: latch into buffer; ``RAM_DOUT_RDY`` immediately.
- Second halfword: issue AXI write; ``RAM_DOUT_RDY`` when ``BVALID`` is received.

Read behaviour
--------------

- First halfword: AXI read on cache miss; ``RAM_DOUT_RDY`` when data returns.
- Second halfword: from cache; ``RAM_DOUT_RDY`` immediately.

``fabric_cfg_*``
================

One-shot full-word AXI write (used by :entity:`cge` for ``CONFIGURATION_TX_REG1``).

``bsb_regs`` configuration (:entity:`cge`)
============================================

- ``RAM_DATA_WIDTH => 16``
- ``RAM_ADDR_WIDTH`` per :entity:`cge` (byte addresses on the AXI path)
- ``USE_RAM_DOUT_RDY => TRUE``
- ``USE_PIPELINED_RAM_WRITE => FALSE``

`cge` RAM port mux (control byte 6, bits 2:0)
=============================================

+-------+------------------+----------------------------------------------+
| Value | Name             | Target                                       |
+=======+==================+==============================================+
| 0     | AXI              | PG203 map via :entity:`axi_lite`             |
| 1     | Core DRP         | CMAC core ``drp_*`` (addr ``[9:0]``)         |
| 2     | GT common DRP    | ``common0_drp*`` (addr ``[15:0]``)           |
| 3-6   | GT channel 0-3   | ``gt0_drp*`` … ``gt3_drp*`` (addr ``[9:0]``) |
+-------+------------------+----------------------------------------------+

Set the mux before RAM read/write commands. ``RAM_ADDR`` is an offset within the selected port only.
