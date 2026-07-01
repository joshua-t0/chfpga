.. title:: xxvglink_tx

**********************************************************************
:entity:`xxvglink_tx` (*xxvglink_tx.vhd*): 25G Serial Link Transmitter
**********************************************************************

.. parse:: hdl/data_links/XXVGLINK/xxvglink_tx.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: xxvglink_tx

Parameters
==========

None — this entity has no generic parameters.

Interface
=========

User-side input (``s_axis_tx_clk``)
------------------------------------

- ``s_axis_tx_tdata``: 64-bit transmit payload word. The first byte transmitted is in the MSB (big-endian); bit 63 is the first bit sent on the link.

- ``s_axis_tx_tvalid``: Transmit data valid. Data is written into an internal FIFO when asserted; the interface is non-blocking.

- ``s_axis_tx_tlast``: End-of-packet indicator. Must be asserted on the last word of each frame.

- ``s_axis_tx_clk``: User clock for the input AXIS interface. May be any frequency, subject to average throughput constraints.

- ``fifo_overflow``: Asserted for one cycle on ``s_axis_tx_clk`` when the TX FIFO has overflowed (data was lost).

GTY-side output (``tx_clk``)
------------------------------

- ``tx_data``: 64-bit word output to the GTY/XGLINK transmitter. Carries SOF/EOF control blocks and payload words interleaved with IDLEs.

- ``tx_header``: 2-bit 64B/66B block header: ``01`` for data, ``10`` for ordered-set/control.

- ``tx_ready``: Input from the GTY gearbox. When high, the current ``tx_data`` / ``tx_header`` will be accepted. Low for 2 out of every 66 clocks.

- ``tx_clk``: TX word clock provided by `xxvglink_core` (~402.8 MHz at 25 Gbps).

Reset
-----

- ``arst``: Asynchronous active-high reset. Re-synchronized internally to ``tx_clk`` via ``xpm_cdc_async_rst``.

Implementation details
======================

Principle of operations
-----------------------

`xxvglink_tx` uses an asynchronous `xxvglink_data_fifo` to cross from the user ``s_axis_tx_clk`` domain to the GTY ``tx_clk`` domain. The TX state machine (``TX_STATE_STANDBY_IDLE`` → ``TX_STATE_SOF`` → ``TX_STATE_DATA`` → ``TX_STATE_CRC_EOF``) reads from the FIFO on ``tx_clk`` only on cycles where ``tx_ready`` is high.

When the FIFO is non-empty, the state machine emits a Start-of-Frame ordered-set control block (header ``10``, SOF code), followed by the payload words (header ``01``), then computes the CRC32 via `crc32_64` and emits it as the final data word, and finally emits an End-of-Frame control block (header ``10``, EOF code). When the FIFO is empty between frames, IDLE control blocks are inserted to keep the link active.

The framing is identical to that of 10G Ethernet (IEEE 802.3ae), making the link protocol compatible with standard 10G test equipment when appropriate PHY encoding is used.

