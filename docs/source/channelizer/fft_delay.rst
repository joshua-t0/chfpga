.. title:: FFT_DELAY

********************************************************************
:entity:`FFT_DELAY` (*SYNC.vhd*): FFT Delay Line Module
********************************************************************

.. parse:: hdl/CHAN/SYNC.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: FFT_DELAY

Principle of Operations
=======================

The `FFT_DELAY` module implements a configurable delay line that delays data signals by a programmable number of clock cycles. It is used in the channelizer to synchronize flag signals with the FFT output data.

The module provides:
- A delay line for data signals (configurable width via ``DATA_WIDTH`` generic)
- Delay measurement capability using sync pulses
- Programmable delay value (up to 2^CTR_WIDTH clock cycles)

Key Features
------------

- **Configurable delay**: Delay can be set from 0 to 2^CTR_WIDTH - 1 clock cycles
- **Data width**: Configurable data width (default 4 bits for flags)
- **Delay measurement**: Can measure the delay between sync pulses
- **Valid output**: Provides a valid signal indicating when delayed data is available

Usage in Channelizer
--------------------

The `FFT_DELAY` module is used in the :entity:`CHAN` (channelizer) to delay flag signals (ADC overflow, FFT overflow, etc.) to align them with the corresponding FFT output data. This ensures that flags are properly associated with the data they describe.

