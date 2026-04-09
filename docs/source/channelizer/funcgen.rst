.. title:: FUNCGEN

******************************************************************************
:entity:`funcgen` (*funcgen.vhd*): Data source selector and Function Generator
******************************************************************************


Overview
========

AXI4-Streaming function generator that either forwards the input from the ADC or replaces it with user-programmable arbitrary waveforms, noise, or packet test patterns.

Features:

- Received ADC inputs

Schematic
=========

.. figure:: ../images/CHAN/funcgen.svg
    :width: 100%

.. figure:: ../images/CHAN/funcgen_modes.svg
    :width: 100%

Sub-modules
===========

.. toctree::
    :titlesonly:

    lfsr



Entity documentation
====================

.. parse:: hdl/chan/funcgen.vhd

.. autoentity:: funcgen

Parameters
==========

- **ADC_SAMPLES_PER_WORD / ADC_BITS_PER_SAMPLE / ADC_SAMPLES_PER_FRAME:** Input / output word geometry (must match ADC / FFT expectations).

- **IMPLEMENT_DELAY_CAPTURE:** Optional delay-capture logic when ``TRUE``.

Interface
=========

Data
----

- ``s_axis_adc_tdata/tvalid/tlast/tuser``: Non-blocking AXI4-Streaming input from the ADC. ``ADC_SAMPLES_PER_WORD`` samples per clock (8 for D3A/CHORD, typically 4 for other configurations), each ``ADC_BITS_PER_SAMPLE`` bits wide in signed two's complement. First sample is in the MSBs. ``TUSER`` carries one overflow flag per sample (MSB = first sample). FUNCGEN can handle non-continuous ``TVALID``, though some downstream blocks (e.g., the FFT) require continuous data.

- ``m_axis_adc_tdata/tvalid/tlast/tuser``: Non-blocking AXI4-Streaming output toward the FFT. Same ``TDATA`` word structure as the input. ``TUSER`` is collapsed to a single frame-wide overflow flag, set if any sample in the frame overranged; valid only on ``TLAST``.

BSB
---

- ``s_axis_bsb_t*`` / ``m_axis_bsb_t*``: Blocking 8-bit AXI4-Streaming BSB command/reply interface for memory-mapped register access (mode ``fn_sel``, waveform RAM, noise seeds, etc.).
- ``bsb_clk``, ``bsb_rst``: BSB clock and synchronous reset.

Clock and reset
---------------

- ``clk``: Processing clock. Both input and output AXI-Streaming buses are synchronous to this clock.
- ``rst``: Synchronous reset.

UDP Control Memory Map
======================

.. include-docs:: funcgen
    :start-after: Function Generator Memory Map

Principle of operations
=======================

Clocking
--------

The module data pipeline operates on a single clock ``clk``. Both input and output AXI-Streaming buses are synchronous to this clock.

The BSB control bus operates on its own separate clock (``ctrl_clk``), which allows configuration changes without affecting the data path timing.

Clock domain crossing (CDC)
----------------------------

There is no CDC logic for quasi-static signals coming from the BSB registers, such as stats frame count, Bytes A and B, seeds etc. These signals are meant to be set and then left unchanged after the module is reset and data starts flowing. The exception to these are:

- ``enable``: Can be changed at any time, but is registered only on frame boundaries. Uses a CDC to prevent corruption of the frame counter.
- ``stats_enable``: Can be set at any time to stop ADC overflow statistics updates. Uses a CDC to protect the integrity of the registering of the counts.
- ``fn_sel``: Switching function during operation can be done safely only if we are not switching between ADC and non-ADC modes. All non-ADC modes generate words using the same framing signals. Switching between non-ADC modes might cause part of the frame to have one type of data, and another part have another type of data, but the packet length and timing will not be affected. The ADC data has an independent framing, and switching between ADC and non-ADC modes will cause over/undersized packets that might corrupt the pipeline downstream.

.. todo:: Investigate the effect of ``fn_sel`` CDC glitching on ``out_dat_tvalid/out_dat_tlast`` even when switching between non-ADC modes; a glitch could make ADC bus briefly appear on the ``out_dat`` bus. How to CDC this 3-bit signal? Have a decoder that provides a separate bit for the ADC/non-ADC mode?


Operation modes
---------------

The output of FUNCGEN is selected by the 3-bit ``fn_sel`` memory-mapped field. The supported modes are:

- **0 - FN_ADC**: Passes on the ADC input. The overflow flags are taken from the ADC.

- **1 - FN_RAM**: Outputs the RAM contents (2048 bytes, 512 words). The overflow flags are always zero.

- **2 - FN_NOISE**: Outputs pseudo-random noise. The overflow flags are always zero. The noise generator is seeded by the 8-bit A and B fields to allow each channelizer to have up to 65536 different (presumably uncorrelated) patterns.

- **3 - FN_FRAME_WORD_CTR_RAM_FLAGS**: Counts frames and words, with programmable ADC overflow bit patterns. This mode is mostly used for testing. The output data is grouped in 32-bit words, containing a 21-bit frame count in the MSB followed by an 11-bit word count. This pattern does not generate nice data when split into bytes (and even less when going through the FFT), but it ensures that consecutive frames will contain unique data when looked at word-wise.

- **4 - FN_FRAME8**: Each sample is the last 6 bits (for IceBoard) or 12 bits (for CRS) of the current frame number. The overflow flag is taken from the buffer.

- **5 - FN_FRAME4**: The most significant 4 bits of each sample is the last 4 bits of the current frame number. The lower 4 bits are zero. The overflow flag is taken from the buffer.

- **6 - FN_RAM_NIBBLE4**: Sends bits 3:0 of RAM samples on even frames and bits 7:4 of RAM samples on odd frames. Data is aligned with the 4 MSBs of each sample, and the rest of the bits in the sample are zero. In this mode, the overflow flags are always zero.

Overflow handling
-----------------

The overflow flag is set if the data source indicates an overflow or if the left shift operation caused the value to exceed a valid range. These overflow flags are aggregated throughout the frame and the resulting bit is provided on TUSER on the last word of the frame and can be read through the register ``frame_overflow_flag`` for debugging.


Overflow statistics
-------------------

The overflow counter counts over ``stats_period`` (user-defined) frames the number of sample overflows from the ADC or the number of overflows injected through the buffer (from modes FN_FRAME_WORD_CTR_RAM_FLAGS, FN_FRAME8, or FN_FRAME4). The overflow count for other modes (FN_RAM, FN_NOISE, FN_RAM_NIBBLE4) is 0. The maximum number of frames over which to count the number of overflows is 65535. When counting overflows from the buffer, each sample's LSB indicates if there is an overflow or not, so to simulate an overflow in a sample, set the sample value to 1. Overflow counting is enabled with ``stats_enable`` and the result can be read from ``overflow_ctr``.

The TUSER overflow flag is a crude overflow indicator; one might expect to have a few ADC overflows in each frame as a compromise to having too much quantization noise. One overflow in a 16384 sample frame is just 0.01% saturation occurrence. For this reason, a high-resolution overflow statistics module is included.

Implementation details
======================

Principle of operations
-----------------------

`FUNCGEN` sits between the ADC capture block and the FFT and acts as a programmable data source. In normal operation (``fn_sel = FN_ADC``) it passes ADC samples unchanged, collapsing per-sample overflow flags into a single frame-wide flag on ``TLAST``. In test or calibration modes it substitutes synthetic data (waveform RAM, LFSR noise, or frame/word counters) while keeping the same AXI4-Streaming framing. Mode switches take effect on frame boundaries to prevent partial-frame corruption.

Clocking
--------

The data pipeline runs entirely on the ``clk`` domain. The BSB control registers are clocked by the separate ``bsb_clk`` domain; quasi-static configuration fields cross directly without CDC logic, but the dynamic ``enable``, ``stats_enable``, and ``fn_sel`` fields use explicit CDC synchronizers to protect data integrity during live changes.

