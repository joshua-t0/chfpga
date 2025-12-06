.. title:: UCT_Engine

***********************************************************************
:entity:`UCT_Engine` (*uct_engine.vhd*): Ultrascale+ Corner-turn engine
***********************************************************************
.. toctree::
   :hidden:
   :titlesonly:

   align64
   ../../navbar_separator

.. parse:: hdl/CT/uct_engine.vhd
.. default-role:: vhdl:entity


Entity documentation
--------------------

.. autoentity:: uct_engine

Sub-modules
-----------

The UCT Engine uses the following modules:

- :doc:`align64`: 64-bit multi-lane frame alignment module for aligning data streams from multiple sources
- :doc:`align64_fifo`: 64-bit alignment FIFO used by the align64 module

Memory Maps
-----------

The UCT Engine has three separate memory-mapped register sets, one for each corner-turn level:

Level 1 Corner-Turn Memory Map
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. include-docs:: uct_engine
    :start-after: Level 1 Corner-Turn Memory Map

Level 2 Corner-Turn Memory Map
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. include-docs:: uct_engine
    :start-after: Level 2 Corner-Turn Memory Map

Level 3 Corner-Turn Memory Map
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. include-docs:: uct_engine
    :start-after: Level 3 Corner-Turn Memory Map


