************************
:entity:`SCALER`: Scaler
************************

Overview
========

Scales the FFT output (in 18+18 bits, 32+32i or other formats) into (4+4) bits complex values by applying a real or complex gain in each freqency bin and truncate or round the value to the desired bit width. `SCALER` offers various main output options and and independent capture channels also with various format options.

.. parse:: hdl/CHAN/SCALER.vhd


.. toctree::
	:titlesonly:

	scaler_mul


Entity documentation
====================


.. autoentity:: SCALER


Additional details
==================


A few points:

- real vs complex gains is determined at compile time
- log+lin gains vs floating point gains is software selectable (for now)
- log_lin gains may be scheduled to be deprecated if floating point gains prove adequate in field tests
- Floating point are supported only for real gains


Floating point format
---------------------

The floating point format encodes a both a log and linear gain for each bin. The value is encoded as follows:

- Bits 15:11: 5 bit log gain (unsigned exponent)
- Bits 10:0: 11 bit linear unsigned gain (mantissa)


Note that the linear gain is unsigned to double the resolution/range compared to the previously used signed gains (that were never used with negative values).

The format ressembles the half-precision floating point format defined by IEEE 754, but is simplified for ease of implementation. The differences are:

- There is no sign bit.
- We cannot express negative exponent or mantissa. There is therefore no offset encoding.
- We don't use the assumed '1' bit prefixing the mantissa, although that is a nice trick that could add resolution but would offset the gain range.

Memory Map
==========

.. include-docs:: SCALER
    :start-after: SCALER Module Memory Map

