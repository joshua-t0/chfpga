.. title:: UCT_Engine

***********************************************************************
:entity:`UCT_Engine` (*uct_engine.vhd*): Ultrascale+ Corner-turn engine
***********************************************************************

.. parse:: hdl/CROSSBAR/uct_engine.vhd
.. default-role:: vhdl:entity


Entity documentation
--------------------

.. autoentity:: uct_engine


Sub-modules
-----------

The UCT Engine reuses many of the same sub-modules as the BCT Engine:

- `chan_crossbar`: First corner-turn stage (takes data from the channelizers)
- `shuffle_crossbar`: Second and subsequent corner-turn stages

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


