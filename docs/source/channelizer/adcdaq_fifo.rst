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
