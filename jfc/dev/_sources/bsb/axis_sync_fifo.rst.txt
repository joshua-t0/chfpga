.. title:: axis_sync_fifo

*******************************************************************************
:entity:`axis_sync_fifo` (*axis_sync_fifo.vhd*): AXI-Streaming Synchronous FIFO
*******************************************************************************

.. parse:: hdl/bsb/axis_sync_fifo.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: axis_sync_fifo

Parameters
----------

- **DATA_WIDTH:** Width of the AXIS data bus in bits. Default is 8.

Interface
---------

- ``s_axis_tdata``, ``s_axis_tvalid``, ``s_axis_tlast``, ``s_axis_tready``: Slave AXI-Stream input port.

- ``m_axis_tdata``, ``m_axis_tvalid``, ``m_axis_tlast``, ``m_axis_tready``: Master AXI-Stream output port.

- ``clk``: System clock.

- ``rst``: Synchronous reset. Clears the internal buffer and de-asserts output valid signals.

Implementation details
----------------------

Architecture
~~~~~~~~~~~~

``axis_sync_fifo`` is a 2-deep pipeline register FIFO: one output register and one internal buffer slot. When the downstream module is not ready (``m_axis_tready='0'``) and new data arrives at the input, the extra word is held in the internal buffer. This means the FIFO can absorb one word while the output register still holds data that has not yet been consumed.

Clocking
~~~~~~~~

All logic is clocked on the rising edge of ``clk``. The ``s_axis_tready`` output is registered, so the source is notified one cycle after the FIFO has room. This pipeline latency is why the internal buffer is needed.

Principle of operation
~~~~~~~~~~~~~~~~~~~~~~

The module computes an internal ``dest_ready`` flag that is true when the output register can accept a new word (either because the downstream is consuming it or the register is empty). ``s_axis_tready`` tracks this flag. When ``dest_ready`` is true and the internal buffer holds a word, that word is moved to the output. If the buffer is empty, incoming data bypasses it and goes directly to the output. When a word must be accepted from the input while the output is stalled, it is stored in the internal buffer.
