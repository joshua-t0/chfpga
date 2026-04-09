.. title:: FFT_DELAY

************************************************************
:entity:`fft_delay` (*fft_delay.vhd*): FFT Delay Line Module
************************************************************

.. parse:: hdl/chan/fft_delay.vhd

.. default-role:: vhdl:entity

Entity documentation
====================

.. autoentity:: fft_delay

Parameters
==========

- **CTR_WIDTH:** Bit width of the delay counter. The maximum programmable delay is 2\ :sup:`CTR_WIDTH` clock cycles.
- **DATA_WIDTH:** Number of flag bits to propagate through the delay line (e.g., TLAST, TUSER, SYNC, TVALID concatenated). Default is 4.

Interface
=========

- ``sync_in``: SYNC pulse as seen at the FFT input. Starts the pipeline latency measurement.
- ``sync_out``: SYNC pulse as seen at the FFT output. Stops the measurement and latches the result.
- ``measured_delay``: Latency measured between ``sync_in`` and ``sync_out``, expressed in clock cycles.
- ``data_in``: Input flag vector to be delayed.
- ``data_out``: Delayed flag vector, aligned with the FFT output data.
- ``delay``: Programmed delay value in clock cycles. Should be set to the known FFT pipeline latency.
- ``valid``: Asserted when the delay line has been filled and ``data_out`` is valid.
- ``clk``: Clock.
- ``ce``: Clock enable. When de-asserted, the delay line and measurement counter are frozen.
- ``rst``: Synchronous reset. Clears the measurement counter and restarts the delay measurement sequence.

Implementation details
======================

Principle of operations
-----------------------

The `FFT_DELAY` module implements a configurable delay line that delays flag signals (such as TLAST, TUSER, SYNC, and TVALID) by a programmable number of clock cycles so that they remain aligned with the corresponding FFT output data. A circular RAM of depth 2\ :sup:`CTR_WIDTH` is used as the delay element, with a free-running address counter. A secondary measurement path counts clocks between a sync pulse seen at the FFT input and the corresponding pulse at the FFT output, providing a way to measure the actual pipeline latency of the attached CASPER FFT block.

Key features
~~~~~~~~~~~~

- **Configurable delay**: Delay can be set from 0 to 2\ :sup:`CTR_WIDTH` − 1 clock cycles
- **Data width**: Configurable flag-vector width (default 4 bits: TLAST, TUSER, SYNC, TVALID)
- **Delay measurement**: Measures the round-trip latency between input and output SYNC pulses
- **Valid output**: Asserts ``valid`` once the delay line has been filled and output is aligned

Usage in channelizer
~~~~~~~~~~~~~~~~~~~~

The `FFT_DELAY` module is used in the :entity:`chan` (channelizer) to delay flag signals (ADC overflow, FFT overflow, etc.) to align them with the corresponding FFT output data. This ensures that flags are properly associated with the data they describe.
