.. title:: xglink_core

***************************************************************
:entity:`xglink_core` (*xglink_core.vhd*): 10G Serial Link Core
***************************************************************

.. parse:: hdl/XGLINK/xglink_core.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: xglink_core

Memory Map
==========

The `xglink_core` module uses a control router to distribute commands to multiple CTRL_SLAVE instances. Each CTRL_SLAVE provides a memory-mapped interface for configuration and monitoring.

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

