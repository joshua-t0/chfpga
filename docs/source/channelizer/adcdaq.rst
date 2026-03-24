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


.. .. highlight:: vhdl

..  .. role:: vhdl(code)
..   :language: vhdl


Detailed description
====================

Overview
========

`ADCDAQ` implements the data acquisition of one of the EV8AQ160 ADC channel in 4-channel mode and in  1:1 DMUX mode (i.e. only the high bus signals  (AH/BH/CH/DH) are used, and data is DDR (double data rate)). Clock and data lines can be individually configured to be individually configured to be single-ended or differential using the ``IS_DIFFERENTIAL`` generic.  The module uses a 4:1 SERDES to combine the bits of 4 consecutive bytes into a 32-bit word, with the word clock frequency being 1/4 of the ADC sampling frequency (200 MHz for an 800 MSPS ADC). The use of the SERDES and associated IOB clocking allows handling of high sample rates up to 850 MSPS on a Kintex-7 FPGA.

This ADC is typically used on the McGill's MGADC08 FMC mezzanine card with Kintex-7 platforms (IceBoards, KC705). The connectivity between the FMC and the FPGA is such that the ADC clocks and data lines may end up in different banks. `ADCDAQ` is parametrizable to allow multi-clock-region clocking via the ``CLOCKING_REGION_MAP`` generic. A PLL-based clocking approach is also supported (``INSTANTIATE_PLL``, ``USE_EXT_DATA_CLK``) for those pinout configurations where the clock cannot be routed to the data lines using the IOB local clocking resources.

The module is designed to perform deterministic ADC SYNC sequencing. The module can be reset while the ADC SYNC line is being activated, i.e. while the ADC clocks are stopped. The reset clears all deserializers and data framing counters. Once the ADCDAQ reset is deasserted, data will start being captured and framed as soon as the ADC starts clocking again after the ADC SYNC line is released. A configurable number of samples will be dropped to ensure the PLL (if present)  had time to stabilize, and optionally to compensate for differential delays between analog inputs (caused, e.g., by cable lenghts). 

Data is packed into ``SAMPLES_PER_FRAME``-sample frames (``SAMPLES_PER_FRAME/4`` words) and the words are stored in an asynchronous FIFO. Once the FIFO is sufficiently full, the ``data_ready`` signal is  asserted. The user can then assert ``send_data`` to begin output streaming. This allows multiple ADCDAQ instances to be synchronized and start streaming in sync even if each ADC operate on clocks with differents delays and phases.

`ADCDAQ` operation is controlled by registers accessed through the BSB control and monitoring bus. 

Key generics
============


- ``SAMPLES_PER_FRAME``: Integer that defines the number of samples per frame.
- ``INSTANTIATE_PLL``: When TRUE, enables generation of bit and word clocks (IOCLK/DIVCLK) using a PLL. The clocks are made available on ``ioclk_out_pll`` and ``divclk_out_pll``.
- ``CLOCKING_REGION_MAP``: maps on which clock region the corresponding data and clock lines are associated. This will instantiate the BUFR/BUFIO in each specified region, and data bit processing will use the relevant clock. The clock region is identified by an arbitrary integer number 0, 1, 2, ... (the number does not correspond to a physical bank or FPGA clock region). If any number is negative, no BUFMR is instantiated to feed the BUFIO/BUFR. Integers at indices 0-7 of the vector are the clock region of the data lines, and integer at index  8 is the clock region of the clock line (the bank that will have the BUFMR).     
- ``IS_DIFFERENTIAL``: If TRUE, selects differential reception per input line. If FALSE, single-ended reception is used. If single-ended, only the P side will be used.
- ``PROVIDE_BUFFERED_DIVCLK``: When TRUE, exports a BUFG-buffered word clock on ``divclk_out_bufg`` for downstream logic such as a channelizer.
- ``USE_EXT_DATA_CLK``: when TRUE, uses external bit and word clocks provided by ``ioclk_in`` and ``divclk_in`` instead of locally generated clocks. These are generally connected to the ``ioclk_out_pll`` and ``divclk_out_pll`` clocks of another ADCDAQ instance. This allows capture even when data lines are spread beyond the reach of the local BUFIO/BUFR resources.
- ``CLK_VALID_OFFSET``: adjusts the point at which captured words are considered valid after startup. This is used to compensate for the pipelining delay in the ADC.

Interfaces
==========

ADC input interface
-------------------

8-bit double-data-rate (DDR) ADC data on the ``adc_data_h_p/n`` data lines (named "AHD/BHD/CHD/DHD" on the ADC) is captured on  both the rising and falling edges of the data clock ``adc_clk_h_p/n`` (named "ADC/BDR/CDR/DDR" on the ADC). The Nth sample is captured on the rising edge, and the N+1th sample is captured on the falling edge.

The "low" lines of the ADC ("ALD/BLD/CLD/DLD") and the out-of-range ("\*OR") are not used in order to preserve FPGA pins and maximize the number of ADCs that can fit onto a FMC mezzanine and a single FPGA. Since the ADC nicely saturates an over-range signal to 0x00 and 0xFF, the over-range is recreated internally by looking for those values.

The FPGA was demonstrated to be fast enough to handle the required 800 MSPS data rate using by capturing data on both edges of the 400 MHz data clock from the ADC.  

ADC data is offset-binary-encoded. 0x00 is the most negative differential value, and 0xFF is the most positive differential value. 0x80 is the midpoint of the differential range. Note that the data is converted to two's complement by the `ADCDAQ`.

Readout interface
-----------------

- ``m_axis_adc_*`` is the 32-bit output AXI4-Streaming interface on a non-blocking AXI-Stream bus. There are 4 samples per 32-bit word, with the first sample in the MSBs. Data is signed two's complement. TUSER is a 4-bit vector carrying one overrange flag per sample, with the first sample corresponding to the MSB.
- ``adc_clk`` is the readout clock.
- ``data_ready``: Set HIGH by ADCDAQ to indicate that enough words are buffered to begin output safely, i.e. it is guaranteed that a valid word will come out when ``send_data`` is asserted..
- ``send_data``:  When '1', ADCDAQ starts sending data form the FIFO (TVALID=1). This signal is somewhat similar to a TREADY signal, except it does not immediately start or stop the data flow. This line is usually asserted whn ALL ADCs have their data_ready signal HIGH, and stays there until the pipeline is reset.

Incoming ADC data is packed four samples at a time into a 32-bit AXI4-Streaming word operating at one quarter of the sampling rate (typically 200 MHz for an 800 MSPS ADC).

The output stream uses:

- ``TDATA``: 32-bit word containing four 8-bit samples in two's-complement format. The first sample is in the most significant byte.
- ``TUSER``: 4-bit vector carrying one overrange flag per sample. The first sample corresponds to the most significant bit.
- ``TVALID``: asserted when a valid output word is present.
- ``TLAST``: asserted on the last word of the frame.

Clocks
------

- ``ioclk_out_pll`` and ``divclk_out_pll`` are BUFG-buffered clocks generated by the PLL when ``INSTANTIATE_PLL = TRUE``.
- ``divclk_out_bufr`` is the BUFR-buffered word clock derived directly from the ADC clock.
- ``divclk_out_bufg`` is the BUFG-buffered version of the local word clock.
- ``ioclk_in`` and ``divclk_in`` are the external bit and word clocks used when ``USE_EXT_DATA_CLK = TRUE``.

- ``ref_clk`` is used by the clock sampling logic.
- ``clk200`` is used by the IDELAY controller when that controller is instantiated.


Reset and control interface
---------------------------

- ``adcdaq_reset`` is the external asynchronous reset used during ADC SYNC sequencing. This will reset the internal state of the module and the FIFO, even if there is no clock from the ADC, therefore ensuring that the data capture will start in a known state whenever the ADC data starts clocking out data again.

BSB interface
-------------

- ``s_axis_bsb_*`` / ``m_axis_bsb_*``: Byte-serial-Bus (BSB) interface to access the control and status registers. This is a pair of blocking 8-bit AXI-Streaming buses.
- ``bsb_clk`` and ``bsb_rst`` clock and reset for the BSB interface.



Architecture
============

Output FIFO
-----------

``ADCDAQ`` uses an asynchronous output FIFO to cross from the ADC capture word clock to the user readout clock. The FIFO is 32 bits wide and 1024 words deep and is used to absorb clock phase differences while allowing deterministic synchronized release of data across multiple channels.

For ``ADCDAQ``, the FIFO implementation matters for timing closure.

The ``embedded`` FIFO implementation maps directly to Xilinx hard FIFO primitives such as ``FIFO36E1`` on 7-series devices. In that mode, the FIFO reset drives the primitive's internal embedded FIFO control logic. That reset path is subject to relatively strict recovery/removal timing checks.

In ``ADCDAQ``, those reset timing requirements interact poorly with the module's I/O-driven placement constraints. The data capture path is strongly shaped by ``BUFIO``/``BUFR`` reach, SERDES placement, IDELAY resources, and clock-region topology. As a result, the reset path to the embedded FIFO primitive can become difficult to route with enough margin, and timing failures were observed regularly on Kintex-7 designs even when the associated logic was placed close to the FIFO.

Using the ``bram`` FIFO implementation avoids this problem. In that mode, the FIFO is implemented using a BRAM-based XPM FIFO rather than exposing the hard embedded FIFO reset arc directly. The problematic primitive reset recovery/removal path is therefore not present in the same way, and timing closure for ``ADCDAQ`` is much more reliable.

For this reason, ``ADCDAQ`` should prefer the ``bram`` FIFO implementation rather than the ``embedded`` FIFO implementation, even if the embedded FIFO may save some resources in less timing-constrained parts of the design.

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

