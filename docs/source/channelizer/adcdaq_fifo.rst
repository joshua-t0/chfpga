.. title:: ADCDAQ FIFO

**************************************************************************
ADCDAQ FIFO (*generic_fifo*): Clock-domain crossing FIFO used by ``ADCDAQ``
**************************************************************************

Overview
========

``ADCDAQ`` uses an asynchronous FIFO to cross from the ADC capture word clock to the user readout clock. The FIFO carries 32-bit words and has a depth of 1024 words.

Its main roles are:

- absorb the fixed phase difference between capture and readout clocks,
- let multiple channels fill before output is released,
- support deterministic synchronized start of streaming across channels.

Parameters
==========

The FIFO is instantiated inside `ADCDAQ` using the :doc:`../utils/generic_fifo` wrapper. The relevant configuration as used by `ADCDAQ` is:

- **DATA_WIDTH:** 32 bits (four 8-bit ADC samples per word).
- **DEPTH:** 1024 words.
- **MEMORY_TYPE:** ``"bram"`` — see `Implementation choice`_ below for the rationale.
- **ALMOST_FULL_THRESHOLD:** Set to provide enough headroom (≥ 16 words) for the ``data_ready`` / ``send_data`` round-trip propagation delay across multiple ADCDAQ instances.

Interface
=========

Write side (ADC capture clock domain)
--------------------------------------

- ``wr_clk``: ADC word clock (typically 200 MHz for 800 MSPS operation). Data is written on every valid word output by the SERDES capture logic.
- ``wr_en``: Write enable, asserted when captured words are valid and the FIFO write path is active.
- ``din``: 32-bit data word containing four 8-bit two's-complement ADC samples.
- ``almost_full``: Asserted when the FIFO fill level reaches the configured threshold. Used to derive ``data_ready``.

Read side (user readout clock domain)
--------------------------------------

- ``rd_clk``: User readout clock. Must have the same frequency as ``wr_clk`` and a fixed phase relationship with the ADC word clock.
- ``rd_en``: Read enable, asserted when ``send_data`` is active and a valid word is available.
- ``dout``: 32-bit word output, forwarded to ``m_axis_adc_tdata``.
- ``empty``: Asserted when no valid data is available for readout.

Implementation details
======================

Principle of operations
-----------------------

The ADCDAQ FIFO bridges the ADC capture word clock and the user readout clock domains. Captured words are written into the FIFO by the ADC-side logic and held until the fill level crosses the ``almost_full`` threshold, at which point ``data_ready`` is asserted. Once the user asserts ``send_data``, the read-side logic begins draining the FIFO and driving the AXI4-Streaming output bus. The FIFO depth of 1024 words provides headroom to absorb clock phase differences, multi-channel start-up skew, and programmable per-channel sample delays (up to ~1008 word-clock cycles, equivalent to roughly 100 m of differential cable length at 200 MHz).

Clocking
--------

This is a fully asynchronous (dual-clock) FIFO: the write side runs on the ADC capture word clock and the read side runs on the user readout clock. The two clocks must have the same nominal frequency and a fixed phase relationship (typically both derived from the same ADC source) to prevent long-term FIFO overflow or underflow.

Implementation choice
=====================

Although ``generic_fifo`` can use either hard embedded FIFO primitives or a BRAM-based XPM FIFO, ``ADCDAQ`` should prefer the ``bram`` implementation.

With the ``embedded`` implementation, the FIFO reset drives the hard FIFO primitive reset pin directly. On 7-series devices this exposes recovery/removal timing checks on the primitive's internal FIFO control logic. In ordinary logic this may be acceptable, but in ``ADCDAQ`` the surrounding placement is heavily constrained by I/O clocking resources such as ``BUFIO``, ``BUFR``, SERDES, IDELAY, and clock-region reach.

That combination makes the reset route to the embedded FIFO primitive difficult to close reliably, and repeated timing failures were observed on Kintex-7 ``ADCDAQ`` builds even when the launching reset logic was physically close to the FIFO.

With the ``bram`` implementation, the FIFO is built from a BRAM-based XPM FIFO instead of exposing the hard embedded FIFO reset arc directly. This avoids the problematic primitive reset recovery/removal path in the same form, and timing closure is significantly more robust for ``ADCDAQ``.

Recommendation
==============

For ``ADCDAQ``, use ``MEMORY_TYPE = "bram"``.

The ``embedded`` implementation may still be useful elsewhere in the design when saving resources matters and the reset path is not constrained by the same I/O-driven placement topology.

Historical note
===============

Older documentation referred to a legacy ``ADCDAQ_FIFO`` Xilinx IP core. ``ADCDAQ`` now uses the common ``generic_fifo`` wrapper, and the timing recommendation above reflects the current implementation and observed timing behavior.
