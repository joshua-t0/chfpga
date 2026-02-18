.. title:: SCALER

***************************************
:entity:`scaler` (*scaler.vhd*): Scaler
***************************************

Overview
========

Scales the FFT output (in 18+18 bits, 32+32 or other formats) into (4+4) bits complex values by applying a real or complex gain in each freqency bin and truncate or round the value to the desired bit width. `SCALER` offers various main output options and and independent capture channels also with various format options.

.. parse:: hdl/chan/scaler.vhd


.. toctree::
	:titlesonly:

	scaler_mul


Entity documentation
====================


.. autoentity:: scaler


Floating point gains
====================

The scaler can be configured to use floating point gains, allowing for far greater dynamic range at the cost of some precision.

A few points:

- real vs complex gains is determined at compile time
- log+lin gains vs floating point gains is software selectable (for now)
- log_lin gains may be scheduled to be deprecated if floating point gains prove adequate in field tests
- Floating point are supported only for real gains


Format
------

The floating point format encodes a both a log and linear gain for each bin. The value is encoded as follows:

- Bits 15:11: 5 bit log gain (unsigned exponent)
- Bits 10:0: 11 bit linear unsigned gain (mantissa)


Note that the linear gain is unsigned to double the resolution/range compared to the previously used signed gains (that were never used with negative values).

The format ressembles the half-precision floating point format defined by IEEE 754, but is simplified for ease of implementation. The differences are:

- There is no sign bit.
- We cannot express negative exponent or mantissa. There is therefore no offset encoding.
- We don't use the assumed '1' bit prefixing the mantissa, although that is a nice trick that could add resolution but would offset the gain range.

Output modes
============

The scaler has two outputs: one for science, which sends the scaled data at full speed into either the firmware correlator or corner-turn engine, depending on the mode, and another for monitoring purposes, which infrequently sends a frame of data to the prober or UCAP module.
Each of these outputs are configurable seperately, which allows for other data to be sent from the scaler to e.g. a PC without interrupting the flow of science data and taking the telescope offline.
Note that whenever the data being output is wider than the width of the corresponding output, the MSBs are taken.

Bypass data type
----------------

If the bypass register is set to 0, the science output produces its normal value, e.g. the 4+4 bit scaled FFT data. However, if bypass is set to 1, then the output depends on the bypass_data_type register:
	- 0: The input FFT data is forwarded directly to the output.
	- 1: If an over- or underflow occurs in either the real or imaginary component of the bin, 1+0j is output for that bin. Otherwise, 0+0j is output.
	- 2: If a positive overflow occurs in the real component of the bin, 1+0j is output for that bin. If a negative underflow occurs in that component, 0+1j is output. Otherwise, 0+0j is output.
	- 3: If a positive overflow occurs in the imaginary component of the bin, 1+0j is output for that bin. If a negative underflow occurs in that component, 0+1j is output. Otherwise, 0+0j is output.

The latter three modes essentially turn autocorrelation into a counter that determines how many over- and underflows occur in the input data.

Capture data type
-----------------

The cap_data_type register determines what is output on the scaler's capture output.

	- 0: Forward science output directly to capture output.
	- 1: Output MSBs of pre-gain raw FFT input.
	- 2: Output MSBs of post-gain FFT values (stage 1), with saturation substitution.
	- 3: Output 4+4 bit scaled FFT values (independent from science output bypass mode).
	- 4: Dual-resolution raw FFT mode: alternate even/odd bins on successive frames at 2x complex bit width.
	- 5: Full-resolution raw FFT mode: emit Re/Im components in separate output words, interleaved across frames.
	- 6: Output saturation flags for each Re/Im component (0: no saturation, +1: positive saturation, -1: negative saturation).
	- 7: Reserved/unhandled in current RTL implementation.

Throughput tradeoff for higher-resolution modes:

	- Mode 4: halves bins per frame and requires 2 frames for full bin coverage.
	- Mode 5: requires ``2*B`` frames for full complex-bin coverage, where ``B = FFT_BINS_PER_WORD``.
	- In both cases, higher captured resolution is obtained by reducing bin coverage per frame while keeping capture word width fixed (``CAP_BITS_PER_WORD``).

Other features
==============

Rounding mode
-------------

The scaler rounds the scaled FFT data before it truncates it to the 4+4 bits that it outputs. The rounding mode determines how this is performed
	- truncation: no rounding is performed. The LSBs are simply truncated off the end.
	- normal rounding: the 4 MSBs are rounded either up or down depending on the value of the remaining bits. On a tie, they are rounded up.
	- convergent rounding: As above, except that on a tie, the data is rounded towards the even number to avoid introducing bias.

Symmetric saturation
--------------------

Due to the way the two's complement representation of signed integers works, the maximum and minimum values representable by N bits are 2^(N-1) - 1 and -2^(N-1), respectively.
This means that on a positive overflow, the scaler output 7, but on a negative underflow, it outputs -8, which can introduce a statistical bias.
To correct for this, when symmetric saturation is enabled, negative overflows saturate to -7 instead.

Zero on saturation
------------------

When zero on saturation is enabled, if either the real or imaginary components of a frequency bin over- or underflow, then both components are zero'd so that they do not impact correlation.

Offset encoding
---------------

When offset encoding is enabled, the output data is represented via an offset encoding instead of the two's complement. Practically speaking, this amounts to inverting the sign bit.

Gain banks
----------

Up to two independent gain tables can be stored in memory simultaneously.
The scaler can be configured to switch between these two banks at any point and ensures that the scalers in each channelizer switches on the same clock cycle. This allows for different gain banks to be used depending on the conditions (e.g. a different gain bank for daytime and nighttime observation).

Overflow statistics
-------------------

The scaler is equipped with counters that can be used to count the number of overflows that occur over a user-specified number of frames.
The scaler counts the number of adc overflows that occur in that period, in number of frames, as well as the number of scaler overflows that occur, in number of bins (i.e. the real and imaginary components are counted together).

Flags
------

Along with the FFT data, the scaler recieves as input two flags which are only meaningful on the last word of the frame and apply to the whole frame: an ADC overflow flag and an FFT overflow flag.
It passes these along to the output, and adds to them a scaler overflow flag for each bin (and therefore valid and changing throughout the entire frame, not just the last word of it) as well as a flag representing which gain bank was used which is only meaningful on the last word of the frame.

Memory Map
==========

.. include-docs:: SCALER
    :start-after: SCALER Module Memory Map
