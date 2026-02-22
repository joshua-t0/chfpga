.. title:: SCALER

***************************************
:entity:`scaler` (*scaler.vhd*): Scaler
***************************************

.. toctree::
	:titlesonly:
	:hidden:

	scaler_mul
	../navbar_separator

.. default-role:: vhdl:entity
.. parse:: hdl/chan/scaler.vhd

=========
Schematic
=========

.. figure:: ../images/CHAN/scaler.svg
    :width: 50%

========
Overview
========

Scales the complex bin values at the output of the FFT module into (4+4) bits complex values by applying a real or complex gain for each frequency bin and truncate or round the value to the desired bit width. `SCALER`  main output can stream the scaled inputs, the direct inputs (bypass), or special overflow flags. The capture output can independently stream the inputs in various higher-resolution formats. `SCALER` also offers an internal scaler overflow statistics module.

====================
Entity documentation
====================


.. autoentity:: scaler


====================
Detailed description
====================

Principle of operations
=======================

The scaler processes FFT output data through a pipelined sequence:


**Word counter**: A word counter counts the incoming words, ressetting to zero at the start of each frame.

**Gain table readout**: The word counter is used as an address to extract the gain coefficients for the bins in the current word from the gain tables.

**Gain application**: Each complex bin in the input word is multiplied by its corresponding real or complex gain coefficient from the gain table using a pipelined multiplier.

**Post-gain shift**: After multiplication, a configurable left shift (``post_scaler_left_shift``, 0-31 bits) is applied to all results for global scaling. For floating-point gains, an additional per-bin shift is added. Overflow is detected during this shift operation.

**Rounding**: The shifted values are rounded before truncation to the output bit width. Three rounding modes are supported: truncation (no rounding), normal rounding (ties round up), and convergent rounding (ties round to even to avoid bias). Overflows caused by rounding are detected.

**Saturation**: When overflow is detected, values are saturated to the maximum representable value.  

**Output**: The final output is packed into the main output word and is sent on the output port.

Generic parameters
==================

- ``FFT_BITS_PER_BIN``: Bits per frequency bin (sum of real + imaginary bits). E.g. 36 (18+18) bits for CHIME FFT, 64 (32+32) bits for the CHORD FFT 
- ``FFT_BINS_PER_WORD``: Number of frequency bins per word. E.g. 2 for CHIME FFT, 4 for CHORD FFT. 
- ``FFT_BINS_PER_FRAME``: Total number of frequency bins per frame. E.g. 1024 bins for CHIME FFT, 8192 bins for CHORD FFT.
- ``USE_COMPLEX_GAINS``: When TRUE, uses complex gains, otherwise uses real gains 
- ``COEFF_BITS_PER_BIN``: Bits per gain coefficient, typically 16 for real gains or 32 (16+16) for complex gains. Must be multiple of 8 bits.
- ``OUT_BITS_PER_BIN``: Output bits per bin for the main output. Needs to be at least 8 for holding the (4+4 bits) outputs, or 16 (8+8) bits if 8-bit mode is to be supported (``EIGHT_BIT_SUPPORT`` is TRUE). In bypass modes, The input data will be truncated to this width
- ``CAP_BITS_PER_WORD``: Total width of the capture output port. The capture output word holds various number of values depending on the software-selected capture output format. 
  Typically 32 bits for Iceboard (to feed `PROBER`), or 128 bits for CRS (to feed `UCAP`)
- ``EIGHT_BIT_SUPPORT``: TRUE when scaler supports 8+8 bit output in addition to 4+4 bit output

Other generics are derived from the above parameters and are not generally user-configurable.

Interfaces
==========

- **Input AXI4-Streaming interface** (``s_axis_in_*``): Non-blocking AXI4-Streaming interface synchronous to ``clk``. Receives FFT output data.

  - TDATA: ``FFT_BITS_PER_WORD`` bits total. Typically contains ``FFT_BINS_PER_WORD`` complex frequency bins per word. Format from MSB to LSB: Re(N), Im(N), Re(N+1), Im(N+1), ... Each component is signed (2's complement format).

  - TUSER: ``FFT_TUSER_BITS_PER_WORD`` bits (typically 2).  Frame-wide ADC and FFT flags, valid on TLAST only.

	- Bit 0: ADC overflow flag
	- Bit 1: FFT overflow flag.

  - TVALID/TLAST: Standard AXI4-Streaming protocol.

- **Main output AXI4-Streaming interface** (``m_axis_out_*``): Non-blocking AXI4-Streaming interface synchronous to ``clk``. Sends scaled data to correlator or corner-turn engine.

  - TDATA: ``OUT_BITS_PER_WORD`` bits total. See Output Formats section for details on the format. 

  - TUSER: ``SCALER_TUSER_BITS_PER_WORD`` bits. 
  
	- Bit 0: ADC overflow flag. Valid on TLAST only.
	- Bit 1: FFT overflow flag. Valid on TLAST only.
	- Bits 2 to (2+``FFT_BINS_PER_WORD``-1): Scaler overflow flags (one per bin). Valid throughout frame.
	- Last bit: current gain bank. Valid on TLAST only.

- **Capture output AXI4-Streaming interface** (``m_axis_cap_*``): Non-blocking AXI4-Streaming interface synchronous to ``clk``. Sends user-selected data.

  - TDATA: ``CAP_BITS_PER_WORD`` bits total. See Output Formats section for details on the format.

  - Contents of TUSER: Same as main output TUSER.

  - tvalid/tlast: Standard AXI4-Streaming protocol.

- **BSB control bus** (``CTRL_CMD_IN_*``, ``CTRL_RPLY_OUT_*``): Allows access to the module's control and status registers, and gain table RAM space. Synchronous to ``ctrl_clk``.

- **Channel FIFO monitoring interface** (``fifo_overflow``, ``mon_clk``, ``mon_tvalid``, ``mon_tlast``, ``mon_word``, ``mon_ctrl``): Optional control and monitoring interface, typically used for debugging. Used to monitor and control the channel FIFO.



.. Along with the FFT data, the scaler recieves as input two flags which are only meaningful on the last word of the frame and apply to the whole frame: an ADC overflow flag and an FFT overflow flag.
.. It passes these along to the output, and adds to them a scaler overflow flag for each bin (and therefore valid and changing throughout the entire frame, not just the last word of it) as well as a flag representing which gain bank was used which is only meaningful on the last word of the frame.


Clocking
========

- ``clk``: Main clock for all data interfaces (input, main output, capture output). All AXI interfaces are synchronous to this clock.

- ``ctrl_clk``: Control clock for BSB control bus interface.

- ``mon_clk``: Monitoring clock for channel FIFO monitoring interface (optional, defaults to '0').

There is no CDC between ``clk`` and ``ctrl_clk`` domains and timing between these clocks is ignored as most of the control registers are quasi-static and changes are self-recovered or are expected to be followed by a pipeline reset. Exceptions are between the registers and the statistics module, where explicit CDC registers is used to ensure proper statistics readout. 

Resets
======

- ``reset``: Reset synchronous to ``clk``. Resets all internal state, counters, and pipeline stages.

- ``CTRL_RST``: Synchronous reset (synchronous to ``ctrl_clk``). Resets the interface and the control registers to their default values.

Gain table
==========

`SCALER` uses a gain table to store the  gains to be applied to each bin. Two independnt gain tables, named bank 0 and 1, are stored to allow seamless gain switching (see Gain switching section below). The table is implemented as a block RAM instantiated using an XPM macro for inter-platform compatibility. 

Each output word of the gain memory contains ``FFT_BINS_PER_WORD`` gain coefficients, each of which is ``COEFF_BITS_PER_BIN`` bits wide. The gain can be either a real or a complex value. If it is a real gain, it can be a scalar or a floating point value.

The gain table is accessed using the byte-wise BSB interface. Since the address-space of the BSB bus is not sufficient to address the whole gain table, a software-controller page address register ``gain_table_page`` is used to select which page is read and written.


Gain coefficients are stored in little-endian byte order. A typical 16 bits value is stored as two bytes, the least significant byte (LSB) is stored at the lower byte address, followed by the most significant byte (MSB) at the next higher byte address. Words are written in bin order (first word for bin 0, second word for bin 1, etc.). Note that writing the data this way makes the integers appear in the reverse word order (gain for bin 0 in the lower bits of the gain word, not the upper bits as one would expect), so the logic inverts the coefficient positions.

A few points:

- Real and Complex gains are exclusive and are selected at compile time
- Real gains are unsigned. Complex gains are signed.
- Integer vs  floating point gains are software selectable
- Floating point gains are supported only for real gains





Complex gain format
-------------------

If the ``USE_COMPLEX_GAINS`` generic is TRUE, the gain is a complex value, represented as two signed integers. The ``use_float_gains`` register is ignored. 

For complex gains, the first 16-bit integer contain the Imaginary part of bin 0 and  the second word (bytes at address 2 and 3) contains the Real part of the same bin. Then we proceed for bin 1, etc.

The complex gain is fed to the complex multiplier along withthe compled value from the FFT. The product is then left-shifted by the global left shift stored in ``post_scaler_left_shift`` register before being further processed by the rounding and saturation logic.

Real integer gain format
------------------------

If the ``USE_COMPLEX_GAINS`` generics is FALSE and ``use_float_gains`` register is FALSE, the `SCALER` will interpret the gains as a *unsigned* integer to maximize the dynamic range of the gain. 

For real gains, the first integer stored in memory contains the coefficient for bin 0, the second integer contains the coefficient for bin 1, etc. 

Each real and imaginary part of the corresponding input value will be multiplied by this value, and the global left shift stored in ``post_scaler_left_shift`` register will be applied to the result.



Real Floating point gain format
-------------------------------

If the ``USE_COMPLEX_GAINS`` generics is FALSE and ``use_float_gains`` register is TRUE, the `SCALER` will interpret the gains as a floating point gain. 


Floating point gains encode both a log and linear gain for each bin, allowing for far greater dynamic range at the cost of some precision. Their value is encoded as follows:

- Bits 15:11: 5 bit log gain (unsigned exponent). 
- Bits 10:0: 11 bit linear unsigned gain (mantissa)

A real-multiplier multiplied both Re an dIm component of each bin withthe linear gain, and the sum of the per-bin log gain and the global left shift  ``post_scaler_left_shift`` are used to left-shift the product

Note that both the linear and log  parts are unsigned to maximize the resolution/range of the gain.

The format ressembles the half-precision floating point format defined by IEEE 754, but is simplified for ease of implementation. The differences are:

- There is no sign bit.
- We cannot express negative exponent or mantissa. There is therefore no offset encoding.
- We don't assume that the mantissa is prefixed by '1'.  The IEEE standard does this to gain one additional bit of dynamic range, at the expense of having to treat zero as a special case. That is a nice trick though.


Gain switching
==============

The scaler supports two independent gain banks (bank 0 and bank 1) that can be stored simultaneously in memory. The inactive bank can be programmed while the active bank is being used, and then the banks can be swapped, allowing for seamless gain switching. The scaler can switch between these banks using either asynchronous or synchronous switching modes.

**Asynchronous switching**: When the ``synchronize_gain_bank_switch`` register is set to '0', the gain bank switches immediately at the next frame boundary (when TLAST is detected) after the ``next_gain_bank`` register is written. 

**Synchronous switching**: When the ``synchronize_gain_bank_switch`` register is set to '1', the gain bank switches only when the internal frame counter matches the ``gain_bank_switch_frame_number`` register value. This ensures that all scalers across multiple channelizers (and potentially across multiple boards) switch gain banks on the exact same frame number. The user must keep track of the gain tables and the frame number at which the table was applied in order to revert the gains downstream in the processing pipeline.

The current gain bank in use is indicated in the TUSER field of the output data of the SCALER(valid on TLAST only), allowing downstream processing to track which gain bank was applied to each frame.  



Output formats
==============

The scaler has two outputs: the main output and the capture output. The main output typically feeds the corner-turn engine (and its downstream correlator) and the capture output typically feeds the capture engine (``PROBER`` or ``UCAP`` modules) for slow data monitoring.

Each of these outputs are configurable seperately, which allows for the monitoring of the data to be changed synamically without affecting the data sent to the CT engine. 

Main output data type
---------------------

The main output data type is selected by contanenating the bypass register (1 bit)  and bypass_data_type register (2 bits). The following table summarizes the resulting outputs:

 	- "0XX": the main output produces its normal value, e.g. the 4+4 bit or 8+8-bit scaled FFT data. The output word is divided in ``FFT_BINS_PER_WORD`` complex values, and the bin values are placed in the output word in the same order as the input word, with the dame Re/Im component ordering. In their destination: 

		- Re and Im components are left aligned to the MSB of their fields(0 padded on the LSBs if needed)
		- Values are in 2's complement or offset binary encoding, depending on register setting.

	- "100": The input FFT data is forwarded directly to the output. The input and output words are divided in ``2*FFT_BINS_PER_WORD`` integer values, and each integer from the input is placed in the corresponding position in the output. MSB of the input is aligned with MSB on the output. Excess LSBs from the input are truncated. Scaler settings such as offset encoding, symmetric saturation or 4-bit encoding are ignored. This mode is typically used for injecting test patterns in the CT engine by using the FUNCGEN while bypassing the FFT.

	- "101": Divides the output word in ``FFT_BINS_PER_WORD`` complex values, and sends the 4+4-bit value 1+0j if an over- or underflow occurs in either the real or imaginary component of each bin, otherwise, 0+0j is output. The 4-bit values are left-aligned to the MSB of each field. If this data is send to a 4+4-bit correlator, the correlator will count how many overflows happened in each bin.

	- "110": Divides the output word in ``FFT_BINS_PER_WORD`` complex values, and sends the 4+4-bit value 1+0j if a positive overflow occurs in the *real* component of the bin, 0+1j if a negative underflow occurs in that component, otherwise, 0+0j is output. The 4-bit values are left-aligned to the MSB of each field. If the data is sent to a 4+4-bit correlator, the correlator will add 1 to a bin on a positive overflow and subtract 1 on a negative overflow. This can be used to confirm that overflows are symmetrical.

	- "111": Is similar to "110", but for the *imaginary* component of the bin. 

The latter three modes essentially turn the correlator into a real-time statistics engine that can be used to validate the gain settings and the signal dynamics.

Capture data type
-----------------

The ``cap_data_type`` register (3 bits) determines what is output on the scaler's capture output.

	- "000": Main data mode. Forward the main output directly to the capture output. Both main and capture outputs are seen as ``2*FFT_BINS_PER_WORD`` signed integer values, and each main output integer is  copied directly to the corresponding capture output integer. Values are MSB aligned and zero-padded on the remaining LSBs.  This mode can be used to monitor *what the correlator sees* and validate that the scaler and output selection logic operates correctly in testbenches.


	- "001": Raw FFT mode. The MSBs of ``2*FFT_BINS_PER_WORD`` integers from the input are passed to the corresponding integers in the output, in the same order. Inputs integers are truncated to fit the output integers. No other transformation is made. This mode allows the capture of all the bins in a single frame, but with limited dynamic range. Small input signals might not be visible due to the truncation. For example:

		- CHIME: input is 2x (18+18 bits), capture word is 32 bits, so captured output is 2 x (8+8) bits. Lower 10 bits of the input are discarded.
		- CHORD: input is 4x (32+32 bits), capture word is 128 bits, so captured output is 4 x (16+16) bits. Lower 16 bits of the input are discarded.

	- "010": Post-gain FFT mode. The MSBs of ``2*FFT_BINS_PER_WORD`` Re and Im integers obtained *after* applying the gains (but before being rounded or truncated to 4 or 8 bits) are passed to the corresponding integers of the capture output, in the same order. The post-gain integers are truncated to fit the output integers. Non-symmetric Saturation is applied if the gains cause the integer to exceed the product integer range.No other transformation is made. This mode allows the capture of smaller FFT signals and can be used to validate the gain stage. This mode offers the same dynamic range as the Raw FFT mode.


	- "011": 4+4-bit mode. Sends the 4+4 bit (or 8+8 bit) fully processed and transformed scaler value to the MSBs of the capture word integers, with zero padding on the LSBs. This mode is identical to the main data mode if the main output is set to send 4+4-bit data. This mode can be used to capture scaled data if the main output is used to send overflow-counting patterns. 


	- "100": "FFT 2x" mode, a.k.a. Double resolution mode. Output word contains only half the bins but with twice the dynamic range. Even frames contain the even bins, odd frames contain the odd bins. In this mode  the MSBs of the ``FFT_BINS_PER_WORD`` Re and Im integers  of the even or odd bins are copied to the ``FFT_BINS_PER_WORD`` integers in the output word. Nte that the odd and even bins are taken from different input frames,  This mode is typically used for capturing full resolution pre-gain FFT data in order to compute the required gains. This mode allows:

		- CHIME: input is 2x (18+18 bits), capture word is 32 bits,  captured output is 1 x (16+16) bits. Lower 2 bits of the input are discarded.
		- CHORD: input is 4x (32+32 bits), capture word is 128 bits, captured output is 4 x (32+32) bits. No data is discarded.


	- "101": Full resolution mode. The Re and Im component each fully fill an entire capture word.  Re and Im words are sent as two consecutive words. Multiple frames are required to send all the bins. The number of frames required is ``2*FFT_BINS_PER_WORD``. This mode allows full dynamic range capture of the FFT data for platforms with narrow capture words. For example:

		- HIRAX: input is 2x (29+29 bits), capture word is 32 bits,  captured output from two consecutive words is (32+32) bits, with all bins sent using 4 frames. This mode allows full bitgrowth FFT data capture even with a 32-bit capture word.
		- CHORD: input is 4x (32+32 bits), capture word is 128 bits, captured output from two words is (128+128) bits, is 4 x (32+32) bits, with all bins sent using 8 frames. This mode is overkill for this configuration.



	- "110": saturation flags. Output is divided into ``FFT_BINS_PER_WORD`` complex numbers which represent the saturation flags for both the Re and Im component of each bin.  A real value of +1 or -1 represents a positive or negative saturation on the real part, while an imaginary 1j or -1j represents a positive or negative  saturations on the imaginary part. In all cases, a value of 0 represents no saturation in the respective component.  This mode is typically used to monitor the saturation of the scaler output and roughly analyze its distribution over time, although fully real-time capture of those flags is not possible with the downstream capture engine. the gain stage.

	- "111": Not used. 

In all these modes, the complex values are placed in the capture output word in the same order as the input word, with the same Re/Im component ordering.


Rounding modes
==============

The scaler rounds the scaled FFT data before it truncates it to the 4+4 bits that it outputs. The rounding mode determines how this is performed
	- truncation: no rounding is performed. The LSBs are simply truncated off the end.
	- normal rounding: the 4 MSBs are rounded either up or down depending on the value of the remaining bits. On a tie, they are rounded up.
	- convergent rounding: As above, except that on a tie, the data is rounded towards the even number to avoid introducing bias.

Symmetric saturation
====================

Due to the way the two's complement representation of signed integers works, the maximum and minimum values representable by N bits are 2^(N-1) - 1 and -2^(N-1), respectively.
This means that on a 4-bit positive overflow, the scaler output 7, but on a negative underflow, it outputs -8, which can introduce a statistical bias.
To correct for this, when symmetric saturation is enabled, negative overflows saturate to -7 instead in 4-bit mode or -15 instead in 8-bit mode.

Symmetric saturation is enabled by setting the ``symmetric_saturation`` register to '1'.

Zero on saturation
==================

When zero on saturation is enabled, if either the real or imaginary components of a frequency bin over- or underflow, then both components are zero'd so that they do not impact correlation.

Offset encoding
===============

When offset encoding is enabled, the output data is represented via an offset encoding instead of the two's complement. Practically speaking, this amounts to inverting the sign bit.



Overflow statistics module
==========================

The scaler is equipped with counters that can be used to count the number of overflows that occur over a user-specified number of frames.
The scaler counts the number of adc overflows that occur in that period, in number of frames, as well as the number of scaler overflows that occur, in number of bins (i.e. the real and imaginary components are counted together).


==========
Memory Map
==========

.. include-docs:: SCALER
    :start-after: SCALER Module Memory Map

