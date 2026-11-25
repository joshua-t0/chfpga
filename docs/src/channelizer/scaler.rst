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


======================
Implementation details
======================

Principle of operations
=======================

The scaler processes FFT output data through a pipelined sequence:


**Word counter**: A word counter counts the incoming words, ressetting to zero at the start of each frame.

**Gain table readout**: The word counter is used as an address to extract the gain coefficients for the bins in the current word from the gain tables.

**Gain application**: Each complex bin in the input word is multiplied by its corresponding real or complex gain coefficient from the gain table using a pipelined multiplier.

**Post-gain shift**: After multiplication, a configurable left shift (0-31 bits) is applied to all results for global scaling. There is one shift register per gain bank (``post_scaler_left_shift_bank0`` / ``post_scaler_left_shift_bank1``). The datapath uses the register of the active bank, delayed by the gain-table RAM latency so it arrives at the multiplier with the coefficients from that bank. For floating-point gains, an additional per-bin shift is added. Overflow is detected during this shift operation.

**Rounding**: The shifted values are rounded before truncation to the output bit width. Three rounding modes are supported: truncation (no rounding), normal rounding (ties round up), and convergent rounding (ties round to even to avoid bias). Overflows caused by rounding are detected.

**Saturation**: When overflow is detected, values are saturated to the maximum representable value.  

**Output**: The final output is packed into the main output word and is sent on the output port.

Parameters
==========

- ``FFT_BITS_PER_BIN``: Bits per frequency bin (sum of real + imaginary bits). E.g. 36 (18+18) bits for CHIME FFT, 64 (32+32) bits for the CHORD FFT 
- ``FFT_BINS_PER_WORD``: Number of frequency bins per word. E.g. 2 for CHIME FFT, 4 for CHORD FFT. 
- ``FFT_BINS_PER_FRAME``: Total number of frequency bins per frame. E.g. 1024 bins for CHIME FFT, 8192 bins for CHORD FFT.
- ``USE_COMPLEX_GAINS``: When TRUE, uses complex gains, otherwise uses real gains 
- ``COEFF_BITS_PER_BIN``: Bits per gain coefficient, typically 16 for real gains or 32 (16+16) for complex gains. Must be multiple of 8 bits.
- ``OUT_BITS_PER_BIN``: Output bits per bin for the main output. Needs to be at least 8 for holding the (4+4 bits) outputs, or 16 (8+8) bits if 8-bit mode is to be supported (``EIGHT_BIT_SUPPORT`` is TRUE). In bypass modes, The input data will be truncated to this width
- ``CAP_BITS_PER_WORD``: Total width of the capture output port. The capture output word holds various number of values depending on the software-selected capture output format. 
  Typically 32 bits for Iceboard (to feed `PROBER`), or 128 bits for CRS (to feed `UCAP`)
- ``EIGHT_BIT_SUPPORT``: TRUE when scaler supports 8+8 bit output in addition to 4+4 bit output
- ``EXPONENT_BITS``: 0 (default): the scaler does not have the exponent mode. 1 to 3: bits of the exponent of a bin in the exponent mode (see `Exponent mode`_). Only with (4+4)-bit outputs (``OUT_BITS_PER_BIN`` = 8).

Other generics are derived from the above parameters and are not generally user-configurable.

Interface
=========

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

The complex gain is fed to the complex multiplier along withthe compled value from the FFT. The product is then left-shifted by the active bank's left-shift register (delayed to match CMUL latency) before being further processed by the rounding and saturation logic.

Real integer gain format
------------------------

If the ``USE_COMPLEX_GAINS`` generics is FALSE and ``use_float_gains`` register is FALSE, the `SCALER` will interpret the gains as a *unsigned* integer to maximize the dynamic range of the gain. 

For real gains, the first integer stored in memory contains the coefficient for bin 0, the second integer contains the coefficient for bin 1, etc. 

Each real and imaginary part of the corresponding input value will be multiplied by this value, and the active bank's left-shift register will be applied to the result.



Real Floating point gain format
-------------------------------

If the ``USE_COMPLEX_GAINS`` generics is FALSE and ``use_float_gains`` register is TRUE, the `SCALER` will interpret the gains as a floating point gain. 


Floating point gains encode both a log and linear gain for each bin, allowing for far greater dynamic range at the cost of some precision. Their value is encoded as follows:

- Bits 15:11: 5 bit log gain (unsigned exponent). 
- Bits 10:0: 11 bit linear unsigned gain (mantissa)

A real-multiplier multiplied both Re an dIm component of each bin withthe linear gain, and the sum of the per-bin log gain and the active bank's left-shift register are used to left-shift the product

Note that both the linear and log  parts are unsigned to maximize the resolution/range of the gain.

The format ressembles the half-precision floating point format defined by IEEE 754, but is simplified for ease of implementation. The differences are:

- There is no sign bit.
- We cannot express negative exponent or mantissa. There is therefore no offset encoding.
- We don't assume that the mantissa is prefixed by '1'.  The IEEE standard does this to gain one additional bit of dynamic range, at the expense of having to treat zero as a special case. That is a nice trick though.


Gain switching
==============

The scaler supports two independent gain banks (bank 0 and bank 1) that can be stored simultaneously in memory. The inactive bank can be programmed while the active bank is being used, and then the banks can be swapped, allowing for seamless gain switching. The scaler can switch between these banks using either asynchronous or synchronous switching modes.

Each bank has its own post-scaler left-shift register (``post_scaler_left_shift_bank0`` at control byte 0 bits 4:0, ``post_scaler_left_shift_bank1`` at control byte 13 bits 4:0). Writing the inactive bank's shift does not change the live datapath. When ``current_gain_bank`` switches, the corresponding shift is selected after the same RAM latency as the coefficient readout so the new gains and new shift arrive at the multiplier together.

**Asynchronous switching**: When the ``synchronize_gain_bank_switch`` register is set to '0', the gain bank switches immediately at the next frame boundary (when TLAST is detected) after the ``next_gain_bank`` register is written. 

**Synchronous switching**: When the ``synchronize_gain_bank_switch`` register is set to '1', the gain bank switches at the end of the frame whose number is ``gain_bank_switch_frame_number``: the next frame is the first one with the new bank. If that frame is past when the host selects the bank, the switch comes at the end of the frame in progress, and the status bit ``gain_switch_late`` (status byte 18 bit 1) is set. The host clears it with ``gain_switch_late_reset`` (control byte 13 bit 6). The comparison is modulo 2^32: the target is reached when the frame counter minus the target is zero or positive as a signed 32-bit number, so a target can be up to 2^31 frames ahead and the limit of the counter makes no error. Before this change, a selection that came after the target frame waited for the counter to come back to that number (6 hours).

The status bytes 19 to 22 (``gain_switch_frame``) have the number of the frame at the end of which the bank changed last, in all the modes: the target frame for a switch that was on time.

The host must write the gain table of the bank that is not in use, then the target frame, then select the bank. A target that is not written again is a target in the past: the selection of a bank then switches at once, with ``gain_switch_late`` set. Each scaler makes its comparison alone: if the selection is late for one channelizer and on time for another, they switch at different frames, and ``gain_switch_frame`` of each tells which.

**Switching at the end of a correlator integration**: When the ``switch_at_integration`` register (control byte 13 bit 7) is set to '1', the two modes above are not used. The gain bank switches at the end of the frame during which the ``integ_last_frame`` input is '1'. The correlator (``UCORR44_ARRAY``) sets that input while it has the last frame of an integration. Thus the first frame of the next integration and all the frames after it use the new bank, and no frame of the integration that ends uses it. The host does not need a frame number.

This is correct only if the data takes less than one frame to go from the input of the scaler to the correlator, and ``integ_last_frame`` less than the rest of that frame to come back: the scaler and the correlator are then in the same frame when the scaler makes its decision. ``chfpga.vhd`` connects ``integ_last_frame`` only for a correlator on the same board and the same clock as the scalers (``CT_LEVEL`` = 1 with ``CT_CLK_SOURCE`` = ``ADC_CLK``, as in corr8), where the delay is the channelizer FIFO (512 words at most) and some registers, for frames of 2048 words. In the other builds the input stays at '0' and this mode never switches.

The status bit ``gain_switch_armed`` (status byte 18 bit 0) is '1' while ``switch_at_integration`` is set and the next gain bank is not yet the bank in use.

To switch several channelizers at the end of the same integration, the host clears ``gain_switch_enable`` in the correlator (control byte 3 bit 5 of ``UCORR44_ARRAY``), sets the next gain bank of each scaler, then sets ``gain_switch_enable``. Without this, the end of an integration can come between the writes to two scalers. The correlator reports the timestamp of the first frame of the integration in progress (status bytes 6 to 11), which is the timestamp of the result packets of that integration.

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



Exponent mode
=============

This mode is in the scaler only if the generic ``EXPONENT_BITS`` is 1, 2 or 3 (the status field ``exponent_bits``, status byte 18 bits 4:2, has the value of the generic). The host starts it with the register ``exponent_enable`` (control byte 13 bit 5, '0' after a reset).

In this mode the scaler gives each bin an exponent ``e``, and the value of the bin is::

    value = (4-bit real part + j x 4-bit imaginary part) x 2^e

- ``e`` is the smallest number from 0 to 2^EXPONENT_BITS - 1 for which the real part and the imaginary part of the bin, divided by 2^e and rounded, are from -7 to 7. The real part and the imaginary part of a bin have the same exponent.
- The rounding is that of ``rounding_mode``. Thus 7.5 x 2^e gets the exponent ``e + 1``.
- A value that the 4 bits can hold has the exponent 0 and the same output bits as without the mode. There is one exception: without the symmetric saturation, the value -8 is not used in this mode (-8 is sent as -4 with the exponent 1).
- If the largest exponent is not sufficient, the bin has the largest exponent, and each part that is not from -7 to 7 has the saturation value of the 4-bit mode (``symmetric_saturation``, ``zero_on_saturation``). The scaler overflow flag of the bin is set, and the overflow statistics count it. In this mode the flag is not set for a bin that an exponent holds.
- The output ``m_axis_out_texp`` has ``EXPONENT_BITS`` + 1 bits for each bin of the word, in the order of the bins of ``m_axis_out_tdata``: the bin in the 8 LSBs of the data has its bits in the LSBs. They are valid with the data. With the mode off they are 0.

  - The ``EXPONENT_BITS`` LSBs of a bin are its exponent.
  - The MSB of a bin is a bit that tells that the bin has an exponent in this scaler: it is 1 if ``exponent_enable`` is '1', ``exponent_max`` is not 0, and the bin is not in the table of the bins with no exponent (see below). It does not tell that the exponent is not 0. This bit goes with the sample to the packetizer (`upack`), which gives exponents in the packets to the bins that have it. So the host writes the bins that have an exponent in the scalers only.
- With EXPONENT_BITS = 3 the largest value is 7 x 128 = 896 steps of the 4-bit output: 42 dB above the range of the 4 bits.

Run-time controls of the exponent mode
--------------------------------------

The driver of the host (corriscope, class ``SCALER``) has the fields of this mode as ``EXPONENT_ENABLE``, ``EXPONENT_MAX``, ``EXPONENT_BITS``, ``EXPONENT_SETTINGS_AVAILABLE`` (``exponent_controls``) and ``WRITE_BINS_WITH_NO_EXPONENT`` (``exp_table_select``). ``set_bins_with_exponent`` takes the bins in the order of the frequency and writes the table.

A build with the exponent mode has one more control byte (byte 14; the status bit ``exponent_controls``, status byte 18 bit 5, is '1'):

- ``exponent_max`` (control byte 14 bits 2:0; after a reset: 2^EXPONENT_BITS - 1). The exponent of a bin is not larger than this number. A bin that needs more is limited as if the largest exponent of the build was not sufficient: it has the exponent ``exponent_max``, the saturation value of the 4-bit mode in each part that is not from -7 to 7, and its overflow flag. With 3 a value is not more than 7 x 8 = 56 steps and has 8 bits. With 0 the output is that of the 4-bit mode.
- ``exp_table_select`` (control byte 14 bit 7; '0' after a reset). With '1', the RAM interface of the scaler reads and writes the *table of the bins with no exponent*, not the gain tables.

The table has one bit for each bin of a frame. A '1' means that the bin has no exponent: its exponent is 0 and it is limited as in the 4-bit mode, with its overflow flag, also when ``exponent_enable`` is '1'. After the configuration of the FPGA the table has zeros: all the bins have an exponent. A reset does not change the table. The two gain banks use the same table.

The bins of the table are in the order of the bins in the scaler, which is that of the gain tables and not that of the frequency: word *w* of a frame has the bins 4 *w* to 4 *w* + 3 of the table, one for each of the 4 outputs of the FFT. With the FFT of the CRS, frequency bin *f* is bin 4 x (*f* mod 2048) + ((*f* / 2048 + *f*) mod 4) of the table. The host driver gives this order to a gain table with ``natural_to_fft_order``; do the same for this table. The playlist of the packetizer (the list of the bins of each packet) uses the same numbers.

To write the table:

1. Write ``exp_table_select`` = '1' (keep ``exponent_max`` in the same byte).
2. Write the bytes with RAM write commands, as the gain tables: 512 bytes for each value of ``gain_table_page`` (1024 bytes, pages 0 and 1, for 8192 bins). Bin ``b`` is bit ``b mod 8`` of byte ``b / 8`` (bit 0 is the least significant bit).
3. Write ``exp_table_select`` = '0'.

A change of ``exponent_max`` or of the table while frames flow acts in some clocks: some frames can have bins of the two settings.

Implementation of the controls: the table is one block RAM (a RAMB18), read with the number of the word at the output of the multipliers. The latency of the scaler does not change (14 clocks).

Implementation: stage 1 (the shift) makes a second word with 2^EXPONENT_BITS - 1 more bits above the 4-bit field. Three more pipeline stages between stage 1 and stage 2 find, for each part and each exponent, if the part is from -7 to 7; then the exponent of each bin; then they move the word down by the exponent, and stage 2 and stage 3 do the rounding and the saturation of the 4-bit mode on it. Only the top bits of the second word (2^EXPONENT_BITS + 4 bits) and one bit that is the OR of all the bits below them go through these stages: the rounding uses no other bit. One more register stage is between the multipliers and the shifter of stage 1, because the path from the DSP blocks through the shifter had the least margin. The latency of a scaler with ``EXPONENT_BITS`` > 0 is thus 4 clocks more than that of a scaler without it (14 clocks in place of 10), with the mode on or off. A scaler with ``EXPONENT_BITS`` = 0 has no change. The capture outputs that take their data from stage 1 (``cap_data_type`` "010" and others) have 1 clock of this delay.

Do not use ``EXPONENT_BITS`` > 0 in a build in which the correlator sets ``integ_last_frame`` (``switch_at_integration``): that function was tested with the latency of 10 clocks only.

Overflow statistics module
==========================

The scaler is equipped with counters that can be used to count the number of overflows that occur over a user-specified number of frames.
The scaler counts the number of adc overflows that occur in that period, in number of frames, as well as the number of scaler overflows that occur, in number of bins (i.e. the real and imaginary components are counted together).


==========
Memory Map
==========

.. include-docs:: SCALER
    :start-after: SCALER Module Memory Map
