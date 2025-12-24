.. title:: FFT

*************************************************
:entity:`fft` (*fft.vhd*): Fast Fourier Transform
*************************************************

.. default-role:: vhdl:entity


.. parse:: hdl/chan/fft.vhd

Schematic
=========

.. figure:: ../images/CHAN/fft.svg
    :width: 50%

Entity documentation
====================    

.. autoentity:: fft



Principle of operations
=======================

Generic parameters
------------------

Many, if not most, of the parameters that define the FFT geometry are already defined in the ``FFT_INFO`` structure that is defined in the ``chfpga_package.vhd`` (file: :doc:`../../hdl/chfpga_package.vhd`). The ``FFT_TYPE`` parameter is passed from the configuration file all the way to this FFT entity and is used to select the proper ``FFT_INFO`` entry. From the selected ``FFT_INFO`` entry, the module extracts parameters such as:

- Number of bits per sample (``BITS_PER_SAMPLE``)
- Samples per word (``SAMPLES_PER_WORD``)
- Bits per bin (``BITS_PER_BIN``)
- Bins per word (``BINS_PER_WORD``)
- FFT latency (``LATENCY``)

This approach allows the same FFT entity to support different FFT configurations (CHIME, D3A/CHORD, HIRAX) without code duplication.



FFT selection
-------------

The type of FFT is selected by the ``FFT_TYPE`` constant defined in the configuration package. ``FFT_TYPE`` is used  to select the FFT configuration parameters from the ``FFT_INFO`` structure, and a case-generate statement selects which FFT entity to instantiate and maps the input bus to whatever interface that particular FFT has, as different CASPER-generated FFTs may have slightly different port names and structures. All FFT entities have been generated using the CASPER framework, which explains why they may have different interfaces despite serving the same purpose.

Interface signals
-----------------

Data is provided to the FFT over an AXI4-Streaming, non-blocking input interface. The data word structure contains:
 - ``ADC_SAMPLES_PER_WORD`` samples per clock (4 for CHIME, 8 for D3A/CHORD). 
 - Each sample is signed (2's complement format)
 - First sample is in the MSB of the word
 - TUSER contains the ADC frame-wide overflow flag, valid on TLAST
- TVALID must be always '1' because the FFT processes data on every clock (see section below).  

The output is also an AXI4-Streaming, non-blocking interface. Each output word contains:
 - ``FFT_BINS_PER_WORD`` complex frequency bins per clock (2 for CHIME, 4 for D3A/CHORD). 
 - Each bin is signed (2's complement format)
 - First bin is in the MSB of the word
 - Real part is in the MSB of the bin, Imaginary part is in the LSB
 - TUSER contains the FFT frame-wide overflow flag, valid on TLAST, in addition to the ADC frame-wide overflow flag

A BSB interface is also available to read and write the memory map registers used to configure and monitor the FFT. 

Clocking and resets
-------------------

The FFT operates on a single clock domain (``clk``) for all interfaces. During reset, ``fft_sync_in`` is held high to generate a single output SYNC pulse. ``delay_clk_en`` is disabled during reset to prevent forced SYNC from entering delay line. ``fft_clk_en`` is always '1' (FFT always clocked), but ``delay_clk_en`` follows input valid.

Continuous data requirement
---------------------------

The CASPER FFT accepts data on every clock; it has no TVALID signal. However, it does have clock enable signal that could be used for the same purpose, but er decided not to use it in order to reduce resources utilization. The upstream pipeline is designed to make sure the data is continuous. We could also have used a gated clock to enable the FFT only on TVALID, but that did not seems worth the clocking resource utilization (each clocking region would have its own clock buffer) 

BSB registers (control and status)
----------------------------------

A number of status bytes indicate the type of the FFT, the counter width, whether the FFT is implemented or not, if bins are rotated, etc. These flags are used by the software to auto-discover what FFT is present and to configure the software accordingly.

- FFT latency:
    - ``fft_pipeline_delay``: Allows setting the latency value used by the delay line
    - ``fft_measured_pipeline_delay``: Indicates the latency that was measured from the last reset
- Shift schedule:
    - ``fft_shift_schedule``: Allows setting the shift schedule used by the FFT
    - ``fft_measured_shift_schedule``: Indicates the shift schedule that was measured from the last reset
- Overflow control:
    - ``fft_overflow_counter``: Allows setting the overflow counter used by the FFT
    - ``fft_overflow_counter_reset``: Allows resetting the overflow counter
    - ``fft_overflow_counter_force``: Allows forcing an overflow for testing purposes
- Bypass mode:
    - ``fft_bypass``: Allows bypassing the FFT
    - ``fft_bypass_reset``: Allows resetting the bypass mode
    - ``fft_bypass_force``: Allows forcing bypass mode for testing purposes

See the Memory Map section below for more details.


Pipelining
----------

The FFT data bus are internally pipelined to help meet timing requirements and improve performance. The ``SHREG_EXTRACT = "no"`` attribute is used on pipelined signals to prevent the synthesizer from combining the different pipelining stages into shift registers. 

Pipeline delay measurement and synchronization
----------------------------------------------

The ``fft_delay`` block performs two functions:
- Measures CASPER FFT latency by counting clocks between input and output SYNC pulses. This measurement capability is mainly used to measure the latency of new FFTs. The value can be measured by software and then can then be hard-coded in the VHDL code to be used as the default.
- Propagates flags (including ``TLAST``, ``TUSER``, ``SYNC``, and ``TVALID``) with the spftware-programmable latency (which should be set to match the FFT's measured latency). This is to ensure these signals  remain aligned with the corresponding FFT output data.


Delay measurement operates by sending a SYNC pulse into the FFT and measure how many clocks it takes for the SYNC signal to come out of the FFT (all CASPER FFTs porpagate the SYNC signal with the same layency as the data). 



Delay measurement requires: reset → wait for input SYNC → count until output SYNC. The delay line uses a circular buffer (RAM) with precomputed ``delay_ctr_max = delay - 3`` to account for:

- RAM read latency (1 clock)
- Pipeline output register (1 clock)
- Counter logic timing (1 clock)

Flags (TLAST, TUSER, SYNC) are combined into single vector, delayed, then split back out. The ``valid`` output indicates when delayed flags are aligned with FFT output.

A reset is needed after the delay is changed to ensure the flags will be properly synchronized.

.. note:: We do not automatically compute and set the delay line on startup. That would require the user to perform two global resets of the pipeline: one reset to compute the delay, and then another reset to reset everything with the proper delay. To avoid this, we ask the developer to measure the FFT and store the default delays in tables (in ``chfpga_package.vhd``, accessed via ``FFT_INFO(FFT_TYPE).LATENCY``) and use this value by default, since these values never change anyway once the design has been implemented.


SYNC pulse generation
---------------------

Periodic SYNC pulse generation is not used during normal operation. Generating periodic SYNC pulses would reset the FFT completely, erasing all memory and starting with a new set of data from zero, causing a discontinuity in the data stream. This is unacceptable for continuous data processing.

SYNC is only used at the beginning when resetting the FFT module, which happens when syncing the signal processing pipeline. This provides the initial synchronization needed for the FFT to start processing correctly.

For reference, though not actively used, SYNC pulses would be generated every ``sync_period`` frames (not clocks) if enabled. The frame counter increments on TLAST, checks if ``sync_frame_ctr = sync_period - 1``. The SYNC pulse is one clock wide (set on valid word, cleared on next clock). If ``sync_period = 0``, no SYNC pulses are generated. During reset, SYNC held high to generate initial output SYNC (CASPER behavior: holding SYNC high generates single output SYNC when released).


.. todo:: Remove periodic SYNC logic and control bytes.

Bin rotation
------------

The bin rotation module ensures that low frequency bins are spread out across different lanes (output words). When de-scrambling is enabled, FFTs with integrated de-scrambling already spread bins across lanes (e.g., bins 1, 2, 3, 4 on different lanes), so rotation is not needed. When de-scrambling is disabled, due to the FFT architecture, low frequency bins end up concentrated on one lane, with the next higher set of frequency bins on another lane, etc. This distribution is not desirable for downstream processing.

The correlator sacrifices one bin per lane. By rotating bins, low frequency bins are spread across lanes so each correlator lane has its own low frequency bin to sacrifice, rather than all low bins being lost from a single lane.

When corner turning, some bins must be removed from the stream to fit the pipeline and transmission channel bandwidth. By rotating bins, the low frequency bins can be removed from every lane, rather than removing all low bins from a single lane.

Bin rotation is an optional feature controlled by ``ROTATE_BINS`` generic. It uses independent word counters per output lane (``word_ctr`` array). Each counter increments per word, resets on TLAST. The rotation formula is: ``src_lane = (i + word_ctr(i)) MOD FFT_BINS_PER_WORD``. Large MUX logic (2:1 or 4:1 per bin) is kept separate from bypass logic to avoid extra MUX depth. The ``DONT_TOUCH`` attribute on ``word_ctr`` prevents optimization.

Bin rotation is particularly tricky for large buses (such as on CRS systems) because the rotation involves a large number of data lines. This can make timing closure difficult. The rotation logic is pipelined as much as possible to meet timing requirements, and currently appears to be working correctly.

Overflow detection and handling
-------------------------------

The `FFT` module keeps track of FFT overflows during the frame and passes a frame-global overflow flag in the TUSER field on the output bus on TLAST. The overflow flags from the CASPER FFT are not necessarily synchronized to the frame boundaries. An overflow could have happened before the end of the frame or after the end of the frame, so we don't know exactly which frame generated the overflow. However, this still provides general information about the health of the FFT and the signals coming in.

An 8-bit overflow counter counts the overflow events during the frame, and it saturates at 255. This counter gives a crude idea of whether FFT overflows have been very frequent or not, but it is very limited in its precision. The counter can be reset using the ``overflow_counter_reset`` control bit.

For D3A/CHORD, multiple overflow bits are OR'd together (``fft_overflow <= or fft_overflow_d3a``). 
An ``overflow_force`` control bit is available for testing.

In practice, we now use FFTs that employ bit growth, so we should never have any overflow anyway. For this reason, there is no point in having a more complex statistics module for measuring FFT overflows more precisely.

Bypass mode
-----------

In bypass mode, a two-stage pipeline (``bypass1``, ``bypass2``) matches is used to propagate the input data into the output directly (the FFT loguc uses a large area, and the input is far for the output). FFT overflow flags are set to zero.

Input samples are left-aligned into each Re or Im component of the output word.  

Output TUSER construction
-------------------------

The TUSER vector construction follows a specific assignment order that matters. The TUSER vector is first zeroed: ``m_axis_out_dat_tuser <= (others => '0')``. Then FUNCGEN flags are assigned: ``m_axis_out_dat_tuser(FUNCGEN_TUSER_BITS_PER_WORD-1 downto 0) <= out_dat_pre_tuser``. Finally, the overflow flag is assigned (only on TLAST): ``m_axis_out_dat_tuser(FUNCGEN_TUSER_BITS_PER_WORD) <= out_dat_pre_overflow_sticky``. The assignment order matters - the overflow flag assignment must come last to override zero.

Implementation details
======================

The FFT engine is based on a CASPER PFB/FFT combination.

The FFT computes the Fast Fourier Transform with 2\ :sup:`N` \ channels for time samples presented 2\ :sup:`P` \ at a time in parallel. Uses a biplex FFT architecture under the hood which has been extended to handled time samples in parallel. For P = 0, this block accepts two independent, parallel streams (labelled as pols) and computes the FFT of each independently (the biplex architecture provides this for free). Data is output in normal frequency order, meaning that channel 0 (corresponding to DC) is output first, followed by channel 1, on up to channel 2N − 1 (which can be interpreted as channel -1). When multiple time samples are presented in parallel on the input, multiple frequency samples are output in parallel.

In our implementation the CASPER PFB/FFT is generated using Xilinx System Generator, Time-based data is presented 4 samples at a time,  in0 being the earliest sample (see Ports section below). Each time sample is 8 bit wide. Output is the complex frequency samples (18 bits real + 18 bits imaginary). Out0 and out 1 provide the even and odd frequencies respectively. The FFT block also includes a delay block which measures the CASPER block pipelining delay and propagates a vector containing the data flags with the same delay.

.. todo:: Update for the newer FFTs (CHORD, HIRAX)

    
Memory Map
==========

.. include-docs:: fft
    :start-after: Memory Map




