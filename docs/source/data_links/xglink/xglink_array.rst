.. title:: xglink_array

******************************************************************
:entity:`xglink_array` (*xglink_array.vhd*): 10G Serial Link Array
******************************************************************

.. parse:: hdl/data_links/XGLINK/xglink_array.vhd

.. default-role:: vhdl:entity

Overview
========

`xglink_array` is a **multi-lane 10 Gb/s serial link array** built on top of `xglink_core`. It instantiates one `xglink_core` per lane group, handles QPLL and reference clock routing, and exposes a **32-bit blocking AXI-Stream TX** and a **non-blocking AXI-Stream RX** interface for each lane. A BSB control tree provides software access to every core. Transmission inserts start-of-frame, CRC-32, and end-of-frame control codes; IDLEs fill the line when no valid data is present. Each RX lane crosses from its own GTX recovered clock to the shared ``clk_out`` domain via an asynchronous FIFO.

Entity documentation
====================

.. autoentity:: xglink_array

Parameters
==========

- **LANE_TO_LINK_MAP:** Integer array mapping each lane index to its link (differential serial port) number. Its length implicitly defines ``NUMBER_OF_LANES``.

- **LANE_GROUP_MAP:** Integer array mapping each lane to a lane group. All lanes in the same group share one `xglink_core` instance.

- **LANE_TO_QUAD_MAP:** Integer array mapping each lane to a GTX quad index (0-based). Used to route clocking resources correctly.

- **QUAD_TO_REFCLK_MAP:** Integer array mapping each quad to one of the reference clock inputs (0 to ``NUMBER_OF_REFCLK``-1). A single refclk can drive at most three adjacent quads on 7-Series devices.

- **IMPLEMENT_RX:** When ``TRUE``, the RX datapath is instantiated for every lane. When ``FALSE``, only the TX path is built to save resources.

- **LINK_SPEED:** Line-rate selector. ``0`` → ~7.8125 Gb/s (244 MHz word clock); ``1`` → ~10.3125 Gb/s (322 MHz word clock).

- **NUMBER_OF_LANES:** Total number of lanes. Derived from ``LANE_TO_LINK_MAP'LENGTH``.

- **NUMBER_OF_LINKS:** Total number of independent serial links. Derived from ``max(LANE_TO_LINK_MAP)+1``.

- **NUMBER_OF_REFCLK:** Number of reference clock differential pairs. Derived from ``max(QUAD_TO_REFCLK_MAP)+1``.

- **SIM:** Top-level simulation switch. When ``TRUE``, GTX-dependent logic is bypassed for behavioural simulation.

Interface
=========

SerDes and reference clocks
----------------------------

- ``tx_p`` / ``tx_n``, ``rx_p`` / ``rx_n``: Differential serial lanes (one pair per link).

- ``refclk_p`` / ``refclk_n``: Differential 156.25 MHz reference clock inputs (one pair per ``NUMBER_OF_REFCLK``).

TX user interface (``clk_out``)
--------------------------------

- ``s_axis_tx_tdata``: 32-bit TX data array (one entry per lane). The first transmitted byte is the MSB of each word (big-endian on the wire).

- ``s_axis_tx_tvalid``: TX data-valid vector (one bit per lane). The interface is blocking: data must be held stable while ``tvalid='1'`` until ``tready`` is asserted by the downstream state machine.

- ``s_axis_tx_tlast``: End-of-packet indicator vector (one bit per lane). Asserted on the last word of each frame.

RX user interface (``clk_out``)
--------------------------------

- ``m_axis_rx_tdata``: 32-bit RX data array (one entry per lane).

- ``m_axis_rx_tvalid``: RX data-valid vector (per lane). Non-blocking; user logic must always be ready to consume data.

- ``m_axis_rx_tlast``: End-of-packet indicator vector (per lane).

- ``m_axis_rx_terror``: Frame error flag vector (per lane). Asserted simultaneously with ``tlast`` when the received frame contains a CRC mismatch or other framing error.

Clocks, resets and monitoring
------------------------------

- ``clk_out``: Word clock output derived from the GTX reference. 244 MHz for ``LINK_SPEED=0``; 322 MHz for ``LINK_SPEED=1``. All TX and RX user data interfaces run on this clock.

- ``areset``: Asynchronous reset for the whole array.

- ``refclk_div2``: Per-refclk logic signal toggling at half the 156.25 MHz reference frequency; useful for clock-presence monitoring.

- ``txclk_div2``: Logic signal toggling at half the TX word clock frequency.

- ``tx_resetdone`` / ``rx_resetdone``: Per-lane GTX reset-done indicators; ``'1'`` when the transceiver is ready.

- ``lane_monitor``: Debug monitoring signal (toggles with link activity).

BSB control
-----------

- ``s_axis_bsb_tdata`` / ``tvalid`` / ``tlast`` / ``tready``: Incoming BSB command byte stream.

- ``m_axis_bsb_tdata`` / ``tvalid`` / ``tlast`` / ``tready``: Outgoing BSB reply byte stream.

- ``bsb_clk``: BSB bus clock.

- ``bsb_rst``: BSB bus reset.

Implementation details
======================

Architecture
------------

`xglink_array` instantiates one `xglink_core` per lane group (determined by ``LANE_GROUP_MAP``). Each core contains its own TX/RX startup FSMs, 64B/66B framing logic, scrambler/descrambler, block-sync state machine, and BSB register interface. A BSB address router distributes software commands from the single incoming stream to the appropriate core and aggregates replies.

Clocking
--------

A single ``clk_out`` word clock is generated from the first lane's GTX TX clock and distributed to all TX and RX user interfaces. Each RX lane's GTX recovered clock independently clocks the receive front end; the per-lane RX data FIFO (:doc:`xglink_rx_data_fifo`) crosses from that recovered clock to ``clk_out``.

Principle of operations
-----------------------

On the TX path, each lane's `xglink_tx` state machine reads 32-bit words from the user AXI-Stream interface, frames them into 64B/66B blocks (start-of-frame, payload, CRC-32, end-of-frame), and passes them to the GTX gearbox via `xglink_core`. IDLEs are inserted when no valid data is presented.

On the RX path, each lane's `xglink_rx` state machine monitors the 64B/66B header, strips framing codes, computes the CRC, and asserts ``m_axis_rx_terror`` alongside ``tlast`` on any mismatch. Received frames are buffered through an asynchronous FIFO before being presented on ``clk_out``.
