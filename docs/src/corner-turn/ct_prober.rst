.. title:: CT_PROBER

**************************************************************************
:entity:`ct_prober` (*ct_prober.vhd*): Corner-turn output capture probe
**************************************************************************

.. parse:: hdl/ct/ct_prober.vhd

.. default-role:: vhdl:entity

Overview
========

`ct_prober` periodically captures bursts of 1 to 4 complete corner-turn output packets from
one software-selectable lane of the corner-turn engine output bus and streams them over an
8-bit blocking AXI4-STREAM interface into the slow data capture path (``bsb_master`` → 1 GbE).
Each captured packet is prepended with the standard 10-byte capture frame header carrying the
cookie ``0xA2``, distinguishing this stream from the channelizer prober (``0xA0``/``0xA1``)
and correlator (``0xCF``) capture streams.

The module exists to verify that the corner turn emits correct data — it captures the exact
bytes the X-engine data links would carry. It is *not* meant for debugging upstream pipeline
stages: the in-channelizer probers already capture pre-corner-turn data together with the
ADC/FFT/SCALER flags.

The capture is **packet-size-agnostic**: packets are delimited purely by ``TLAST``, so the
module works unchanged in any shuffle mode (``shuffle16``/``shuffle256``/``shuffle512``), any
frames-per-packet grouping and any flags setting. The inner CT packet header (with its own
timestamp and stream information) is carried intact in the captured payload. The architecture
closely mirrors the channelizer :entity:`prober`, and the control register addresses match it
wherever the fields coincide, so the python driver can subclass the prober driver.

Entity documentation
====================

.. autoentity:: ct_prober

Parameters
==========

- **FPGA_SERIES:** Selects the FIFO primitives instantiated by ``generic_fifo``.
- **NUMBER_OF_LANES:** Number of 32-bit lanes in the input bus. Default is 8.
- **LANE_WIDTH:** Bits per lane. Default is 32.
- **SIM:** When ``TRUE``, shortens the default capture period for simulation. Default is ``FALSE``.

Interface
=========

Input
-----

- ``in_tdata``: Concatenated corner-turn output lanes, **lane 0 at the MSBs** (the
  ``bct_engine`` output flattening reverses lane order; this module undoes the reversal in
  its lane selector).
- ``in_tvalid``/``in_tlast``: Shared by all lanes; ``in_tlast`` delimits CT packets.
- ``in_clk``: The corner-turn clock (a GTX transmit word clock, 244 MHz on ICE). This clock
  **stops** while the corner-turn engine is in reset.
- ``in_reset``: Capture-domain reset; must be asserted during corner-turn resets.

Output
------

- ``out_tdata/tvalid/tlast/tready``: Blocking 8-bit AXI4-STREAM output (``out_clk`` domain).
  Each output packet is a 10-byte header followed by one captured CT packet (32-bit words
  sent MSB first).
- ``out_clk``: Read-side clock (``cap_clk`` = ``bsb_clk`` = 125 MHz on ICE; always running).

BSB control
-----------

- ``s_axis_bsb_*/m_axis_bsb_*``: BSB command/reply streams for memory-mapped register
  access. The module is mapped at top-level BSB port 6 (base address ``0x60000``).
- ``bsb_clk/bsb_rst``: Clock and synchronous reset for the BSB interface.

Header format
=============

For each captured CT packet the output carries the standard ``FRAME_HEADER_STRUCT``:

- Byte 0: cookie ``0xA2``
- Bytes 1-2: 16-bit STREAM_ID: bits 15:12 = packet index within the burst (hardware), bits
  11:4 = software-programmed stream ID, bits 3:0 = captured lane number (hardware, following
  the STREAM_ID lane convention).
- Byte 3: zeros (the corner-turn output has no TUSER sideband; the CT packet's own flag
  blocks, if enabled, are part of the payload).
- Bytes 4-9: 48-bit TIMESTAMP = the CT packet counter value at burst start. This is a local
  count since reset; use the inner CT packet header in the payload for system timing.

Capture capacity
================

The data FIFO stores 2048 x 33-bit words (2x FIFO36E1 on Kintex-7). The whole burst must fit
because readout starts only after the burst capture completes:

===============================  ===========  =====================
CT configuration                 packet size  max packets per burst
===============================  ===========  =====================
flags off, 1 frame/packet          517 words            3
flags off, 2 frames/packet        1029 words            1
flags on,  1 frame/packet          597 words            3
flags on,  2 frames/packet        1221 words      does not fit
===============================  ===========  =====================

An oversized burst raises the sticky FIFO overflow status bit and truncates the capture; it
is not otherwise harmful.

Clocking, resets and CDC contract
=================================

- ``in_clk`` stops during corner-turn resets. Software must configure/reset this module only
  after the corner-turn links are up. The FIFO power-on reset is generated on ``out_clk``
  (always running) so the module resets cleanly even if the corner-turn clock is not yet
  active.
- Control bytes cross from ``bsb_clk`` to ``in_clk`` without synchronization (channelizer
  prober regime): after changing ``primary_period``, ``capture_offset`` or ``sub_period``, a
  ``soft_reset`` is required. ``capture_en`` (single bit) and ``lane_sel`` (latched into the
  capture mux only between bursts) are safe to change during operation.
- Burst metadata crossing the write→read domain is protected by the request/acknowledge
  handshake: it is written at burst start and consumed only after burst end plus CDC latency
  (at least one full packet duration later).

Memory Map
==========

.. include-docs:: ct_prober
    :start-after: CT_PROBER Module Memory Map

Testbench
=========

A self-checking testbench is provided in ``hdl/testbenches/ct_prober_testbench.vhd`` with a
Vivado project script in ``xilinx_projects/testbenches/ct_prober_testbench/``. It emulates
the 8-lane corner-turn bus with lane/packet/word-encoded data and checks the packet format,
lane selection and reversal, burst behaviour, timestamps, live lane switching, overrun
detection and parked operation.
