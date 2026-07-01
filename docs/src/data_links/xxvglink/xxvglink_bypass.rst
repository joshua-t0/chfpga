.. title:: xxvglink_bypass

******************************************************************************
:entity:`xxvglink_bypass` (*xxvglink_bypass.vhd*): 25G Serial Link Bypass Mode
******************************************************************************

.. parse:: hdl/data_links/XXVGLINK/xxvglink_bypass.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: xxvglink_bypass

Parameters
==========

- **DELAY:** Minimum occupancy depth of the RX FIFO before data is released to the output, in words (must be ≥ 1, default: 1). Increasing this value adds latency and can be used to model link propagation delay in simulation.

Interface
=========

TX input (non-blocking, ``clk``)
---------------------------------

- ``s_axis_tx_tdata``: 64-bit transmit data word. First byte transmitted is in the MSB (big-endian).

- ``s_axis_tx_tvalid``: Transmit data valid.

- ``s_axis_tx_tlast``: End-of-packet indicator.

- ``tx_fifo_overflow``: Asserted for one cycle when the TX FIFO has overflowed (data was lost).

RX output (non-blocking, ``clk``)
----------------------------------

- ``m_axis_rx_tdata``: 64-bit receive data word.

- ``m_axis_rx_tvalid``: Receive data valid.

- ``m_axis_rx_tlast``: End-of-packet indicator.

- ``m_axis_rx_terror``: Always ``'0'`` for this bypass module (no error injection).

- ``rx_fifo_overflow``: Asserted for one cycle when the RX FIFO has overflowed.

Monitoring
----------

- ``fifo_overflow``: OR of ``tx_fifo_overflow`` and ``rx_fifo_overflow``, for use by the monitoring logic in `xxvglink_array`.

- ``fifo_in_tvalid``: Mirrors the internal word valid signal going into the RX FIFO (on ``clk``), used by `xxvglink_array` for RX monitoring.

- ``fifo_in_tlast``: Mirrors the internal last-word signal going into the RX FIFO (on ``clk``).

- ``fifo_in_terror``: Always ``'0'``.

Clock and reset
---------------

- ``clk``: Single clock for both the TX and RX paths.

- ``arst``: Asynchronous active-high reset.

Implementation details
======================

Principle of operations
-----------------------

`xxvglink_bypass` chains two `xxvglink_data_fifo` instances (TX FIFO → RX FIFO) and throttles the read from the TX FIFO by skipping 2 reads out of every 66 clock cycles. This throttling replicates the 64/66 encoding overhead of the real GTY gearbox (64 data words out of 66 total clocks), so that the data throughput through the bypass path matches that of a physical 25G link. This allows ``axis_clk`` to be used identically for bypass lanes as for real GTY lanes.

