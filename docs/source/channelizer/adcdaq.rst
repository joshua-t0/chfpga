.. title:: ADCDAQ

*****************************************************************************
:entity:`adcdaq` (*adcdaq.vhd*): Analog to Digital Converter Data Acquisition
*****************************************************************************

.. default-role:: vhdl:entity


Schematic
=========

.. figure:: ../images/CHAN/ADCDAQ/adcdaq_block_diagram.svg
    :width: 50%


.. toctree::
    :titlesonly:

    adcdaq_fifo

Entity documentation
====================

.. parse:: hdl/chan/adcdaq.vhd

.. autoentity:: adcdaq

Parameters
==========

- **FPGA_SERIES:** Target FPGA device series (``KINTEX7`` or ``ULTRASCALE_PLUS``). Selects SERDES, FIFO, and IDELAY primitives appropriate for the target family.
- **SAMPLES_PER_FRAME:** Number of ADC samples per output frame. Determines when ``TLAST`` is asserted on the readout bus. Default is 2048.
- **IMPLEMENT_ADCDAQ:** When ``FALSE``, a dummy module is generated with preserved I/O ports but no capture logic. Useful for partial builds.
- **INSTANTIATE_IDELAYCTRL:** When ``TRUE``, instantiates an IDELAYCTRL primitive in this module. Only one ADCDAQ per clock region needs to instantiate this; the tools auto-place others.
- **INSTANTIATE_PLL:** When ``TRUE``, instantiates a PLL/MMCM to generate globally-buffered IOCLK and DIVCLK signals for export to other ADCDAQ instances in non-adjacent clock regions.
- **CLOCKING_REGION_MAP:** Integer array mapping each data line (indices 0–7) and the ADC clock (index 8) to a BUFR/BUFIO clock region integer. If all entries are negative, no BUFMR is instantiated.
- **IS_DIFFERENTIAL:** Per-line flag array. When ``TRUE``, differential reception is used (IBUFDS). When ``FALSE``, only the P input is used as a single-ended input. Applies to data lines (0–7) and clock (8).
- **PROVIDE_BUFFERED_DIVCLK:** When ``TRUE``, exports a BUFG-buffered word clock on ``divclk_out_bufg`` for downstream logic such as a channelizer.
- **USE_EXT_DATA_CLK:** When ``TRUE``, uses externally provided bit and word clocks (``ioclk_in`` / ``divclk_in``) rather than locally derived clocks. Required when data lines span non-adjacent clock regions.
- **CLK_VALID_OFFSET:** Word-clock cycles to wait after ADC startup before data is declared valid. Compensates for PLL lock time and analog pipeline delays. Default is −3.
- **SIM:** When ``TRUE``, simulation-friendly behavior is enabled (e.g., shorter startup timeouts).

Interface
=========

ADC physical input
------------------

8-bit double-data-rate (DDR) ADC data on the ``adc_data_h_p/n`` lines (named AHD/BHD/CHD/DHD on the EV8AQ160 ADC) is captured on both edges of the data clock ``adc_clk_h_p/n``. ADC data is offset-binary-encoded and converted to two's complement internally; 0x00 is the most negative value, 0xFF the most positive, and 0x80 the midpoint.

- ``adc_data_h_p/n``: 8-bit differential DDR data bus from the EV8AQ160 ADC (AHD/BHD/CHD/DHD lines).
- ``adc_clk_h_p/n``: Differential DDR data clock from the ADC (nominally 400 MHz for 800 MSPS operation).

Readout interface
-----------------

``m_axis_adc_*`` is the 32-bit output AXI4-Streaming interface on a non-blocking bus. There are 4 samples per 32-bit word, with the first (earliest) sample in the MSBs. Data is signed two's complement. ``ADCDAQ`` does not begin transmitting until the FIFO is sufficiently full and ``send_data`` is asserted, allowing multiple instances to start streaming in sync.

- ``m_axis_adc_tdata``: 32-bit word containing four 8-bit two's-complement samples. The earliest sample is in the most significant byte.
- ``m_axis_adc_tvalid``: Valid strobe for the output word.
- ``m_axis_adc_tlast``: Asserted on the last word of each frame (every ``SAMPLES_PER_FRAME / 4`` clocks).
- ``m_axis_adc_tuser``: 4-bit overrange flags, one per sample (MSB = first sample). Overrange is detected when a sample code reaches 0x00 or 0xFF.
- ``data_ready``: Asserted when the output FIFO has accumulated enough words to guarantee uninterrupted streaming. Used to synchronize multiple ADCDAQ instances before asserting ``send_data``.
- ``send_data``: When asserted, the ADCDAQ begins streaming data (``TVALID`` goes high). Typically driven simultaneously for all channels once all report ``data_ready``.
- ``adc_clk``: Readout clock. Must match the ADC word clock frequency with a fixed phase relationship.

Output clocks
-------------

- ``ioclk_out_pll``: PLL-generated SERDES bit clock buffered by BUFG (available when ``INSTANTIATE_PLL = TRUE``).
- ``divclk_out_pll``: PLL-generated word clock buffered by BUFG (available when ``INSTANTIATE_PLL = TRUE``).
- ``divclk_out_bufr``: Word clock derived directly from the ADC clock using a BUFR. Stops when ``adcdaq_reset`` is asserted.
- ``divclk_out_bufg``: BUFG-buffered version of ``divclk_out_bufr`` (available when ``PROVIDE_BUFFERED_DIVCLK = TRUE``).
- ``adc_clk_out_div2``: Logic signal toggling at half the word clock rate, used by a frequency counter for health monitoring.

External clock inputs
---------------------

- ``ioclk_in``: External SERDES bit clock input (used when ``USE_EXT_DATA_CLK = TRUE``).
- ``divclk_in``: External word clock input (used when ``USE_EXT_DATA_CLK = TRUE``).

Reset and control
-----------------

- ``adcdaq_reset``: Asynchronous reset. Clears deserializers, word counters, and the output FIFO even in the absence of an ADC clock. Should be asserted during ADC SYNC sequencing.

BSB interface
-------------

- ``s_axis_bsb_*/m_axis_bsb_*``: Blocking 8-bit AXI4-Streaming BSB command/reply interface for control and status register access (delay tuning, soft resets, pattern capture, health status).
- ``bsb_clk/bsb_rst``: BSB interface clock and synchronous reset.
- ``ref_clk``: Reference clock used by the ADC clock sampling logic for delay calibration.
- ``clk200``: 200 MHz clock for the IDELAYCTRL primitive.


Implementation details
======================

Principle of operations
-----------------------

`ADCDAQ` implements the data acquisition of one EV8AQ160 ADC channel in 4-channel/1:1-DMUX mode, using a 4:1 SERDES to capture 8-bit DDR data on both edges of the 400 MHz ADC clock and combine them into 32-bit words at one quarter of the sampling frequency (200 MHz for 800 MSPS). Clock and data lines can be individually configured as single-ended or differential via the ``IS_DIFFERENTIAL`` generic. Words are stored in an asynchronous output FIFO that bridges the ADC capture clock to the user readout clock; once the FIFO is sufficiently full, ``data_ready`` is asserted, and all connected ADCDAQ instances begin streaming together when ``send_data`` is asserted, enabling deterministic cross-channel synchronization.

The module supports deterministic ADC SYNC sequencing: asserting ``adcdaq_reset`` while the ADC SYNC line halts the ADC clocks clears all deserializers, word counters, and the output FIFO. After SYNC is released and the ADC restarts, a configurable number of initial samples is discarded (``CLK_VALID_OFFSET``) to allow the PLL to stabilize and to compensate for inter-channel cable delays. Operation is controlled via BSB memory-mapped registers for delay tuning, soft resets, debug pattern capture, and health monitoring.

Clocking
--------

The module supports two clocking modes. In internal clocking mode (``USE_EXT_DATA_CLK = FALSE``), the ADC clock is buffered locally via ``BUFIO`` (SERDES bit clock) and ``BUFR`` (word clock); this works when all relevant data lines are in the same or an adjacent clock region. In external clocking mode (``USE_EXT_DATA_CLK = TRUE``), SERDES clocks generated by another ADCDAQ instance's PLL (``ioclk_out_pll``, ``divclk_out_pll``) are used instead, enabling capture across non-adjacent I/O banks. A local divide-by-two ``BUFR`` is always instantiated to run the word counter and generate the ``adc_clk_valid`` reference, ensuring deterministic startup timing independent of PLL lock.

Architecture
============

Output FIFO
-----------

``ADCDAQ`` uses an asynchronous output FIFO that provides the following functions:

- Cross the data from the ADC capture word clock domain to the user readout clock domain.
- Allow easy synchronization of multiple ADCDAQ output streams.
- Allow buffering to compensate for large analog delays due to cable lengths

We use a ``generic_fifo`` wrapper to instantiate the FIFO. The FIFO is 32 bits wide and 1024 words deep and is used to absorb clock phase differences while allowing deterministic synchronized release of data across multiple channels. We use an ``embedded`` FIFO implementation to save resources. On a Kintex-7, this FIFO requires a false_path timing constraint so the asynchronous FIFO reset is properly timed (see :ref:`generic_fifo:Embedded FIFO`).

Athough the downstream pipeline should run on on a word clock speed that is the same than the ADC capture word clock, the phase of the ADC data arrival is unknown and the data needs to be realigned the downstream pipeline clock. The asynchronous FIFO allows this.
The FIFO can also thoretically allows the downstream pipeline to run on a faster clock speed than the ADC capture word clock (if there is a need for that, but we generally don't have much overhead here)  AND if all the downstream logic can handle non-contiguous data arrival (the FFT does not). 

In order to support aligning data output for multiple ADCDAQs, incoming words are are stored in the FIFO until it is sufficiently full, and then sends out the ``data_ready`` signal is  asserted. The user can combine the ``data_ready`` signals from all ADCDAQs and generate a ``send_data`` signal that will instruct all ADCDAQ instances to begin output streaming simultaneously. 

The ``data_ready`` signal is asserted when the FIFO is full enough to guarantee that a valid word will always be ready to send out when ``send_data`` is asserted (assuming we read the data no faster than the FIFO fills).

The FIFO overhead between ALMOST_FULL and FULL can absorb a reasonable amount of pipelining delay between the outgoing ``data_ready`` and the returning ``data_ready``, which is useful since the ADCDAQs are spread across the FPGA. 

The FIFO buffering is also used to implement arbitrary delays on the ADC data. A programmable word delay can be set to hold off writing incoming data into the FIFO for a number of clocks at startup, effectively delaying the data by that number of clocks. The output stream synchronization will let the FIFOs of all ADCDAQs fill up until the channel with the largest delay is ready. The headroom between ALMOST_FULL and FULL can also be used to absorb that delay.
The FIFO has a depth of 1024 words, with a threshold of 16 words, which allows for a maximum delay of 1024 - 16 = 1008 clocks, i.e. about 500 ns at 200 MHz or about 100 m of maximum differential cable length between channels. 

Clocking
========

``ADCDAQ`` supports two clocking approaches.

Internal clocking
-----------------

Internal clocking is the preferred and simpler mode. It is used when ``USE_EXT_DATA_CLK = FALSE``.

In this mode:

- The input ADC clock is buffered locally.
- ``BUFIO`` generates the high-speed SERDES bit clock.
- ``BUFR`` generates the divided word clock.

This works only when the relevant data lines are in the same bank as the clock, or in an adjacent bank that can still be reached by the local clocking resources.

External clocking
-----------------

External clocking is used when some data lines cannot be reached reliably from their local ADC clock routing. One ADCDAQ instance can instantiate a PLL/MMCM and export globally buffered IOCLK and DIVCLK signals for use by other ADCDAQ blocks.

Other ADCDAQ blocks associated with the same ADC chip can then set ``USE_EXT_DATA_CLK = TRUE`` and use those externally generated clocks for data acquisition.

This allows capture even when data lines are spread beyond the reach of the local BUFIO/BUFR resources.



Clock delay alignment in external clocking mode
-----------------------------------------------

When using external clocks, the locally generated ``adc_clk_valid`` event and the externally supplied word clock can be shifted relative to one another by PCB and FPGA delays. If the phase relationship is wrong, ADCDAQ may start capturing one byte early, one byte late, or near a metastable alignment boundary.

To make this reliable:

1. The timing constraints must define the external-clocked ADC clocks relative to the ADC clock source that generates them.
2. Software must be able to adjust the relevant clock delays so the locally observed ADC timing and the externally supplied clocks line up correctly.

The ADC clock sampling system is used to measure those relative arrival times.

PLL-based exported clocks
--------------------------

When ``INSTANTIATE_PLL = TRUE``, ADCDAQ instantiates a PLL/MMCM that generates:

- a bit clock for SERDES input sampling,
- a data-acquisition word clock,
- a channelizer word clock.

All three are distributed on global clock resources.

The PLL is driven from the locally generated 200 MHz divided clock rather than directly from the ADC bit clock. This avoids phase ambiguity problems that were observed when trying to derive a lower-frequency output from a higher-frequency input clock inside the PLL.

The design notes in the source also record two practical observations:

- high PLL bandwidth was sometimes needed with jittery input clocks to avoid rare byte errors,
- older Xilinx Clocking Wizard versions behaved differently across device families and tool versions.

Local word counter and ``adc_clk_valid``
========================================

Regardless of whether internal or external clocking is used for the SERDES, a local divide-by-two BUFR is always instantiated from the local ADC clock.

This local clock is used to:

- run the local word counter,
- determine when valid ADC words should begin to appear,
- generate the local ``adc_clk_valid`` timing reference.

This is important because the local divider does not require PLL lock time and therefore starts in a deterministic way after ADC SYNC. The design uses that deterministic local timing to decide when the rest of the capture logic may safely begin storing data, including in the externally clocked case.


Performance
============


The maximum tested input data rate is 850 MSPS, corresponding to a 425 MHz DDR input clock.


Resource utilization
====================





Data framing
============

``ADCDAQ`` groups samples into compile-time fixed-length frames and asserts ``TLAST`` every N output words. For example, a 2048-sample frame produces 512 output words.

After reset, some initial samples are intentionally discarded to allow the PLL and related clocking to stabilize. Because this discard interval is counted from the ADC clock itself, the timing of the first accepted sample remains repeatable.

Overrange detection
===================

The EV8AQ160 hardware overrange outputs were not routed to the FPGA, so overrange is reconstructed in logic. A sample is treated as overrange when its code reaches either extreme of data's offset-binary-encoded 8-bit range:

- 0x00 (``-128`` in two's complement) 
- 0xFF (``+127`` in two's complement)

This works because the ADC saturates nicely to these codes when it overranges. The trade-off is that treating these extreme codes as overrange effectively removes 2 codes out of 256 from the usable numeric range if software decides to reject them.

Redout sequence
===============



The stream is delivered through an asynchronous FIFO read on the user-provided readout clock. This allows downstream processing to use a word clock with a different phase than the local ADC capture clock, but the readout clock must still have the same frequency and a fixed phase relationship with the ADC word clock to avoid FIFO overflow or underflow.

``ADCDAQ`` does not start transmitting immediately when samples begin to arrive. Instead:

1. It fills the FIFO until a readiness threshold is reached.
2. It raises ``data_ready``.
3. The user asserts ``send_data``.
4. The module starts sending words with ``TVALID`` asserted.

This mechanism lets several ADCDAQ blocks begin streaming in sync by waiting until all of them report ``data_ready`` and then asserting ``send_data`` simultaneously.




ADC delay calibration
=====================

The clock and data lines use programmable delay elements. Data delays must normally be tuned to place the sampling point near the center of the eye because PCB skew and FPGA routing delays are large enough to prevent reliable capture without calibration.


SYNC delay calibration
======================


Control interface
=================

``ADCDAQ`` exposes a BSB register space for bring-up, calibration, and debug. Software normally interacts with this block in three phases:

1. configure delays and optional clocking/debug features,
2. perform reset / SYNC sequencing and verify status,
3. use pattern capture and counters to confirm alignment and monitor health.


Memory Map
==========

.. include-docs:: adcdaq
    :start-after: ADCDAQ Memory Map

Register overview
=================



Delay tuning registers
----------------------

The first control and status bytes are the ones software uses most often during board bring-up. Control bytes ``0`` to ``8`` program the data and clock IDELAY tap values, while status bytes ``0`` to ``8`` report the corresponding ``cntvalueout`` readback.

In software, these registers are typically used as a calibration loop rather than as static configuration:

1. program candidate delays for the eight data lines and the clock line,
2. trigger or observe the associated reset/reload behavior,
3. read back the applied values,
4. evaluate ramp-pattern quality or captured samples,
5. iterate until stable byte alignment is reached.

The key point is that these registers are not just "settings"; they are part of the data-capture tuning workflow. The readback values are useful to confirm that the requested delays were actually loaded, especially while bring-up scripts are experimenting with multiple tap combinations.

Reset and clock-control registers
---------------------------------

Control byte ``9`` groups the soft resets and low-level clocking controls:

- ``pll_soft_reset``
- ``clk_iodelay_soft_reset``
- ``idelayctrl_rst``
- ``bufr_soft_reset``
- ``serdes_soft_reset``
- ``data_iodelay_soft_reset``
- ``enable_ramp``

Software normally uses these bits in two ways.

First, they provide a fine-grained recovery path during bring-up. If the capture path is unhealthy, software can reset only the affected part of the chain, such as the SERDES or the PLL, without having to reset the whole design.

Second, they support structured tuning. For example, changing delay values is often followed by a targeted reset of the data or clock delay path so the new values take effect in a controlled way. Likewise, ``enable_ramp`` is used to switch the module into a debug-friendly mode while alignment is being verified.

These controls are most useful in scripted procedures. For routine field operation, they are typically touched only during initialization or fault recovery.

Sample-alignment and output-release registers
---------------------------------------------

Control bytes ``10`` and ``11`` contain the software-visible controls that most directly affect when valid output is released:

- ``sample_delay``
- ``force_data_ready``
- ``clear_fifo_flags``
- ``ramp_err_clear``

``sample_delay`` is the main timing-alignment knob used when external clocking shifts the relationship between the local validity logic and the clock that actually reads the capture path. In practice, software adjusts this after the hardware clock routing has been fixed, using measured ramp correctness or captured patterns as feedback.

``force_data_ready`` is mainly a debug escape hatch. It is useful when software wants to inspect downstream behavior without waiting for the normal FIFO threshold conditions, but it should not be part of the normal synchronized startup sequence.

``clear_fifo_flags`` and ``ramp_err_clear`` support repeated calibration trials. Bring-up software often sweeps delays, checks errors, clears flags, and tries again. These bits make that process repeatable without reloading the whole design.

Pattern-capture and masking registers
-------------------------------------

Control bytes ``12`` to ``14`` contain the short-term debug aids:

- ``capture2_period``
- ``capture2_word_number``
- ``data_mask``

These are mainly for investigation rather than routine streaming. ``capture2_period`` and ``capture2_word_number`` let software sample a specific point in the internal data flow so it can compare runs, verify alignment, or debug intermittent problems. ``data_mask`` is useful when isolating bit-lane problems or intentionally suppressing selected bits during tests.

In software terms, this group is most valuable when the capture path "mostly works" but one still needs to answer where the misalignment or corruption is coming from.

Health and readiness status registers
-------------------------------------

Status bytes ``9`` to ``15`` provide the first-line health indicators:

- PLL lock and IDELAYCTRL status,
- FIFO reset / empty / overflow / underflow flags,
- sticky FIFO fault flags,
- internal readiness and FIFO enable state,
- output word counter low bits.

These are the registers software should poll during initialization. A typical startup sequence checks that the clocking path is healthy, verifies that FIFO faults are clear, and only then proceeds to wait for ``data_ready`` and release ``send_data``.

The sticky FIFO flags are especially useful because they preserve evidence of short-lived failures that might otherwise be missed by a slow polling loop. In practice, these are the status bits that make post-mortem debugging possible once the system is already streaming.

Clock-sampling and pattern-debug status
---------------------------------------

The later status bytes expose deeper debug information:

- ``ramp_err_ctr``
- ``adc_clk_sample``
- ``capture2_pattern``
- ``ramp_bit_err_ctr``

Software uses these when the basic health flags are not enough to explain a problem. ``ramp_err_ctr`` gives a high-level view of whether capture is correct at all, while ``ramp_bit_err_ctr`` helps narrow faults to specific data bits. ``capture2_pattern`` and ``adc_clk_sample`` support timing investigations, especially when trying to understand clock phase relationships across channels.

This group is what makes automated calibration practical: scripts can score candidate settings, not just decide pass/fail.



Configuration
==============

For a typical user integrating ADCDAQ into a new wrapper or board design, the expected flow is:

1. Set ``IS_DIFFERENTIAL`` and ``CLOCKING_REGION_MAP`` to match the board pinout and FPGA bank placement.
2. Decide whether the channel uses local clocking or exported clocks from another ADCDAQ instance.
3. If one instance must source clocks for other channels, enable ``INSTANTIATE_PLL`` there and route its exported clocks to the consumers.

Calibration 
============

There are two types of calibration required to operate the ADC reliably and deterministically.

1. SYNC delay calibration: ensures that the SYNC signal is asserted and released with a good margin relative to the ADC internal 1600 MHz clock.
2. Data delay calibration: Ensures that the data is captured with a good margin relative to the 400 MHzADC data clock edges.

SYNC delay calibration
======================


Data delay calibration
======================


Needs to be done once. Delays can be saved.

4. Tune the data and clock delay settings using the BSB-controlled delay registers and debug pattern support.
5. Perform the ADC SYNC / ``adcdaq_reset`` sequencing so all channels restart deterministically.
6. Wait for ``data_ready`` on all channels, then assert ``send_data`` together if aligned output start is required.

In practice, the most error-prone parts are clock-region mapping, delay calibration, and the reset/SYNC ordering.


SYNC and reset sequencing
=========================

``ADCDAQ`` is designed so data acquisition restarts deterministically after an ADC SYNC event.

An ADC SYNC event resets the ADC's internal timing and stops its output clocks. That means any PLL driven from those clocks will lose lock. ``ADCDAQ`` therefore uses ``adcdaq_reset`` and a carefully ordered restart sequence so that all internal counters, SERDES blocks, and FIFOs restart in a repeatable phase relationship.

The intended sequence is:

1. Assert ADC SYNC. ADC clocks stop and any dependent PLL loses lock.
2. Assert ``adcdaq_reset``. This asynchronously resets the PLL, BUFR divider, word counters, SERDES reset machinery, FIFO write logic, and valid/ready flags.
3. After a few divider clocks, FIFO reset is asserted.
4. Release ``adcdaq_reset``. No functional change happens yet because clocks are still absent.
5. Release ADC SYNC. ADC clocks restart.
6. The local divider resumes immediately, while the PLL begins relocking.
7. After enough clocks, FIFO reset is released.
8. The local word counter reaches the configured threshold and asserts ``adc_clk_valid``.
9. SERDES reset is released on the next valid divided-clock edge.
10. Once the SERDES output timing is valid, data is written into the FIFO.
11. When the FIFO fill level reaches the ready threshold, ``data_ready`` is asserted.
12. The user asserts ``send_data`` to begin output streaming.

The key design rule is that the decision of when data becomes valid is based on the deterministic local ADC timing, not on PLL lock timing alone. That is what makes repeated SYNC events produce repeatable byte and frame alignment across channels and boards.



Typical configurations
======================

Local-clocked channel
---------------------

This is the simplest and preferred setup:

- ``USE_EXT_DATA_CLK = FALSE``
- ``INSTANTIATE_PLL = FALSE``
- ``CLOCKING_REGION_MAP`` matches the local BUFR/BUFIO reach of the ADC clock

Software effort is mostly limited to IDELAY tuning and the normal ``adcdaq_reset`` / ADC SYNC sequencing.

Clock-exporting source channel
------------------------------

One ADCDAQ instance may be designated as the clock source for other channels:

- ``INSTANTIATE_PLL = TRUE``
- ``USE_EXT_DATA_CLK = FALSE`` for the source instance itself
- exported ``ioclk_out_pll`` / ``divclk_out_pll`` routed to consumer instances

In software, this instance is the one whose PLL health matters most. If it is not locked, all dependent consumers are suspect even if their local status otherwise looks reasonable.

Externally clocked consumer channel
-----------------------------------

Consumer channels use clocks generated by another ADCDAQ:

- ``USE_EXT_DATA_CLK = TRUE``
- ``INSTANTIATE_PLL = FALSE``
- ``ioclk_in`` / ``divclk_in`` driven from the source instance

These channels typically need the most care in ``sample_delay`` tuning because the capture-valid timing is derived locally while the actual SERDES clocks are remote.

Related modules
===============

- See :doc:`chan_array` for how multiple ``ADCDAQ`` instances are instantiated and connected to the channelizer pipeline.
- See :doc:`adcdaq_fifo` for the FIFO used to bridge the capture path to the readout clock.
- Platform wrappers such as :doc:`../platforms/kc705/chfpga_kc705` define board-specific values for ``CLOCKING_REGION_MAP`` and the overall ADC clocking topology.

Schematic
=========

.. figure:: ../images/CHAN/ADCDAQ/adcdaq_pll_unambiguous_phase_config.svg
    :width: 50%

