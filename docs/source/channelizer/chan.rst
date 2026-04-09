.. title:: CHAN

****************************************
:entity:`chan` (*chan.vhd*): Channelizer
****************************************

.. default-role:: entity



.. figure:: ../images/CHAN/channelizer.svg
    :width: 75%

The Channelizer (CHAN) implements the main data acquisition pipeline for the chFPGA project. It recieves a data stream from the ADCs and passes it to the Function Generator sub-module (FUNCGEN). The Function Generator can pass the ADC data down the pipeline or it can insert used-defined packets or other test waveforms. The Channelizer then performs a 2048-sample PFB-FFT on the data using a CASPER FFT core, and forwards the result to a Scaler (SCALER) sub-module which applies complex gains on the resulting (18+18) bit complex spectrum and scales it down to (4+4) bit complex representation. The output stream is then resynchronized to an external output clock (typically a correlator or corner-turn subsystem clocks) through a FIFO (CHAN_FIFO). The `CHAN` module also allows data from the function generator our scaler output to be captured in periodic bursts and be sent over the control Ethernet link.

The Channelizer consists of the following sub-modules:

- :entity:`funcgen`
- :entity:`fft`
- :entity:`scaler`
- :entity:`chan_fifo`: FIFO to cross data between the channelizer and the corner-turn or correlator engines
- :entity:`prober`: Captures and buffer a subset of the raw ADC or SCALER output data and send it back over the control channel
- :entity:`bsb_router`: The router recieves commands through the UDP Command Protocol backbone from
  chFPGA and relays them to all the necessary sub-modules relevent to the channelizer. The addresses
  for each sub-module are shown below.



Entity
======

.. parse:: hdl/chan/chan.vhd

.. autoentity:: chan

Parameters
==========

- **PLATFORM_TYPE:** Target FPGA platform. Selects platform-specific primitives (e.g., embedded memories). Defined as an enumerated type in :doc:`../chfpga_package`.
- **IMPLEMENT_FFT:** When ``FALSE``, the FFT sub-module is not instantiated. Useful for partial builds or debugging.
- **FFT_TYPE:** Selects the FFT configuration (e.g., ``CHIME``, ``D3A``, ``HIRAX``). Determines ADC width, sample count, bin width, and other FFT-derived parameters via the ``FFT_INFO`` lookup table in :doc:`../chfpga_package`.
- **SCALER_USE_COMPLEX_GAINS:** When ``TRUE``, the scaler applies complex (16+16i)-bit gains per bin. When ``FALSE``, 16-bit real gains are used.
- **CAPTURE_TYPE:** Selects the data capture engine type (``BRAM`` for internal PROBER, ``URAM`` for external UCAP). Determines capture bus width and number of capture sources.
- **CT_TYPE:** Corner-turn type. Determines the width of the output AXI-Streaming bus that feeds the corner-turn or correlator engine.
- **IMPLEMENT_CHAN:** When ``FALSE``, no sub-modules are instantiated but the BSB router is still present. Useful for lightweight test builds. Default is ``TRUE``.
- **SIM:** When ``TRUE``, simulation-friendly behavior is enabled (e.g., shorter delays). Bound to the global ``GLOBAL_SIM`` constant by default.

Interface
=========

ADC input
---------

- ``in_dat_tdata/tvalid/tlast``: Non-blocking AXI4-Streaming input bus carrying ``ADC_SAMPLES_PER_WORD`` ADC samples per clock, each ``ADC_BITS_PER_SAMPLE`` bits wide. The first (earliest) sample occupies the MSBs.
- ``in_dat_tuser``: Per-sample saturation flags (one bit per sample, MSB = first sample).
- ``in_clk``: Input and signal processing clock. All signal processing from ADC input to the output FIFO write side runs on this clock.
- ``in_reset``: Synchronous (``in_clk``) reset for all sub-modules except ADCDAQ.

Output
------

- ``out_dat_tdata/tvalid/tlast/tuser``: Non-blocking AXI4-Streaming output bus carrying scaled complex frequency bins. Width is ``OUT_BITS_PER_WORD`` (set by ``CT_TYPE``). ``tuser`` carries per-frame flags.
- ``out_dat_almost_empty``: Asserted approximately 15 clocks before the output FIFO empties, used for flow control by downstream logic.
- ``out_dat_send``: Flow-control input. When asserted, the output FIFO begins sending data. Typically driven by ``chan_align_blk`` to synchronize all channelizer outputs.
- ``out_clk``: Output clock for the ``out_dat`` bus. May differ from ``in_clk`` to re-align multi-phase channelizers.
- ``out_reset``: Resets the output FIFO only. Synchronous to ``out_clk``.

Monitoring
----------

- ``lane_monitor``: 4-bit diagnostic bus for lane monitoring.

BSB control interface
---------------------

- ``s_axis_bsb_*/m_axis_bsb_*``: Blocking 8-bit AXI4-Streaming Byte-Serial-Bus (BSB) command/reply interface for accessing the memory-mapped registers of all sub-modules.
- ``bsb_clk``: BSB interface clock.
- ``bsb_rst``: Synchronous reset for the BSB interface.
- ``m_axis_adcdaq_bsb_*/s_axis_adcdaq_bsb_*``: BSB pass-through interface routed to the external ADCDAQ module associated with this channelizer.

Data capture interface
----------------------

- ``cap_source_req``: Requests which capture source (0 = FUNCGEN output, 1 = SCALER output) to stream. Source switch occurs on a frame boundary.
- ``cap_source_ack``: Reflects the capture source currently being streamed, aligned to the ``m_axis_cap`` data.
- ``m_axis_cap_tdata/tvalid/tlast``: Wide capture output bus (``CAPTURE_BITS_PER_WORD`` bits) for the external UCAP module (when ``CAPTURE_TYPE = URAM``).
- ``m_axis_prober_tdata/tvalid/tlast/tready``: 8-bit blocking AXI-Streaming output from the internal PROBER capture module (when ``CAPTURE_TYPE = BRAM``).
- ``axis_prober_clk``: Clock for the PROBER output stream.


Implementation details
======================

Parametrization
---------------

`CHAN` is a fairly large module in terms of resource utilization as it emcompasses the majority of `chFPGA` signal processing burden. Furthermore, this module is repeated multiple times, once for each ADC input.

In order to streamline implementation, `CHAN` is often used as an out-of-context (OOC) module, i.e. it is pre-synthesized once as a standalone module, then the pre-synthesis results are reused each time the module is instantiated. The reuse applies only to synthesis, not placement or routing.

Modules to be used as OOC cannot have GENERICS and should be instantiated using *component instantiation*, with a COMPONENT definition that does not include any GENERICS.  We normally prefer to send down all configuration parameters hiearchically from the top modile down to bottom leaf instances using GENERICS, but that is not compatible with OOC modules.  So instead, since we cannot use GENERICS, We define a gegeric-free component in the ``chan_package.vhd`` package and use component instantiation. The `CHAN` module will use its default GENERICS parameters, which are set to the corresponding parameters defined in the configuration file (the ``chfpga_config`` package). Using the configuration file is the best compromise we found to allow OOC usage of `CHAN` while ensuring easy, centralized configuration.

The configuration file is therefore necessary for `CHAN` to be implemented properly. The key parameters that should be found in the configuration are:

- ADC bit width
- Number of ADC samples per bus word
- Type and data width of capture engine
- FFT bit width
- Type of SCALER gains
- etc.

.. todo::
    check if we could use *entity instantiation* if the entity has no GENERICS, i.e. all parameters are CONSTANTs bound to the configuration file parameters.

Clocking and reset architecture
-------------------------------

`CHAN` operates on 3 clock domains:

- ``in_clk`` is the clock on thich the ADC data is provided. All the signal processing is performed on this clock.
    ``in_reset`` is a ``in_clk``-synchronous reset that resets all the submodules. The reset line is pipelined between modules and loosely follow the data flow, but the latency of the pipeline is not matched to the latency of the modules to same on register and memory resources. Reset signals will likely arrive to a module before the data. It is the responsibility of the external reset controller to stop the data flow long enough before reset is released to make sure that the modules all restart in a known state.

- ``out_clk`` is the clock on which the output of the channelizer is provided. Can be equal of higher then ``in_clk``

- ``ctrl_clk`` is the BSB control bus clock. Is used exclusively for accessing memory-mapped registers. Cross-clock domain with the other clocks are ignored by the tools.  It is the responsibility of the sub-modules to take into account the asynchronous nature of the signals controlled by the command system.

    ``ctrl_reset`` is synchronous to ``ctrl_clk`` and  resets only the BSB bus and resets all the memory-mapped registers of the submodules to their default values.



Channelizer clocks
------------------

`chfpga` can operate the channelizer either on a single-phase clock or a multi-phase clock. In both case, the clock is provided from ADC0. If single clock is selected (``CHAN_CLK_SOURCE=ADC``), the buffered bersion of the clock is sent to all ADCs. If an multi-phase clock is selected (``CHAN_CLK_SOURCE=MMCM``), either the ADC clock or the 200 MHz system clock (generated by the MMCM above) can be used to generate 8 independenr channelizer clocks, each shifted in frequency by 45 degrees.

In both case, the ADCDAQ has an asynchronous output FIFO to bridge data between the each of the internal ADC clock domain (each ADC has the same frequency a different delay) and the selected channelizer clock (single or multi-phase). ADCDAQ stores a few words before releasing its data in order eo ensure a non-interrupted flow of data, i.e. TVALID is always asserted. This is required by the FFT, which is wired to expect valid data on every clock.

The channelizers also have an output FIFO users to transfer bridge the channelizer data into the corner-turn clock domain. The FIFO is also used to align the frames.



Control bus
-----------

`CHAN` connects to the system's Byte-serial Bus (BSB) to allow access to the sub-module's memory-mapped registers and memory buffers. Access is provided through the blocking AXI-Streaming buses ``ctrl_cmd`` and ``ctrl_rply``. All BSB control buses operates on the ``ctr_clk``, which is typically slow (100 or 125 MHz) to facilitate routing. A 125 MHz clock provides a command bandwidth of 1 Gbps, which is plenty since the system configuration is usually set-and-forget. The bus structure can be reste using the synchronous reset ``ctrl_rst``.

`CHAN` uses the local address space from 0x000 to 0xFFF (see `Memory Map`_ below).

A BSB router splits the `CHAN` addres space in 8 address regions, each 0x200 bytes (512 bytes) wide. Each sub-modules is allocated to one of these regions.  Modules that require larger address spaces for programming buffers, such as FUNCGEN's waveform tables or SCALER's gain tables, shall use register-based banking in order to extend the logical memory space through the single 512-byte window.

One of the local bus is exposed directly as a port in order to control an external module that is functionally tightly coupled to this channelizer instance. This control bus is typically used to control the ADC data acquisition logic when needed, such as the  `ADCDAQ` module used with the IceBoard platform. This bus is exposed as the blocking AXI-Streaming buses ``adc_cmd`` and ``adc_rply``.

.. Todo:: Normalize names of ADCDAQ BSB buses

The other buses are connected to the `FUNCGEN`, `FFT`, `SCALER` and optional capture engine (`PROBER`). Non-existing modules or unused addresses shall not be accessed: the bus will never indicate that it is ready to accept a command at those addresses and the command will time out.

Dummy Channelizer
-----------------

A dummy channelizer can be implemented by setting ``IMPLEMENT_CHAN`` to ``TRUE``. No sub-module will be instantiated, but the command router will still be there and will be rigged to accept any command (but will never reply to them).

This feature can be useful for simulation or implementing a lightweight design for testing the implementation.


ADC input
---------

The ADC data is provided as a non-blocking AXI-S bus ``in_dat``. The data word consists of ``ADC_SAMPLES_PER_WORD`` samples, each representing ``ADC_BITS_PER_SAMPLE`` - bit-wide ADC samples. The data acquisition, and subsequent signal processing all the way to the output FIFO, is operating synchronously with the ``in_clk``, which is typically the ADC clock.

``ADC_SAMPLES_PER_WORD`` and ``ADC_BITS_PER_SAMPLE`` are bound to the corresponding  parameters set in the configuration file, namely ``CONFIG_ADC_BITS_PER_SAMPLE`` and ``CONFIG_ADC_BITS_PER_SAMPLE``. Following the CASPER convention, the first sample appears in the MSBs of the word.

The system assumed that the TUSER bus field is  ``ADC_SAMPLES_PER_WORD`` bit wide, and indicates if an overflow condition occured for each sample. Like the data itself, the MSB is the overflow flag for the first sample.

The ADC bus is non blocking, i.e. there is no TREADY. As the rest of the pipeline, is is assumed that data can always be processed. Using backpressure makes pipelining much more difficult. Instead, FIFOs are used along the signal processing path when there is a chance that the data might not be processable immediately. In the case of `CHAN`, this happens only on the final clock-domain-crossing FIFO.


Function Generator
------------------

The `FUNCGEN` module received the ADC data, gathers some statistics and proforms some optional processing on it, and passes either the resulting ADC data, preprogrammed wafeform or dynamically generated signals to the FFT module. The type of signal that is provided  is configured by `FUNCGEN` memory-mapped registers.

The output of the ``FUNCGEN`` has the same width as the ADC bus. However, FUNCGEN issues a new, reprocessed  TUSER signals.

The ADC data is propagated  to `FUNCGEN` through a couple of pipelining stages to help with timing closure.

See `FUNCGEN` module for more details.

FFT
---

The `FFT` implements a CASPER PFB/FFT block that is wrapped around some logic to make it operate as a non-blocking AXI-Steaming processing block.

The input of the FFT module is the AXI-Streaming ADC data bus, with the same width as the ADC input and FUNCGEN output, and  TUSER flags processed by FUNCGEN.
Since we use a Real-signal FFT and that the data processing rate shall be conserved (i.e. data comes out in the same number of clock that it came in), it is assumed  that the FFT outputs ``ADC_SAMPLES_PER_WORD/2`` complex values per clock (i.e per word). The width of the FFT depends on its implementation, and is defined by the local parameter ``FFT_BITS_PER_BIN``, which is bound to the configuration parameter ``CONFIG_FFT_BITS_PER_BIN``. The paramater represents the total width of the bin value, including both the real and imaginary part, which are assumed to be equal width.

The FFT module modifies and passes on the TUSER field coming from the FUNCGEN in order to add more statistics flags.

See `FFT` module for more details.


Scaler
------

The `SCALER` takes the wide complex FFT output values and applies a per-bin digital gain to scale those back to (4+4) bit complex values.

See `SCALER` module for more details.

Output FIFO
-----------

The data from the scaler is sent out of `CHAN` using the non-blocking AXI-Streaming bus ``out_dat``, operating on the clock ``out_clk``.  An asynchronous FIFO takes the data from the SCALER output (channelizer clock domain) and re-streams it on the output clock domain. ``out_clk`` may need to be different from ``in_clk`` because multiple channelizers operating on different ``in_clk`` phases need to be re-aligned, and  because the corner-turn engine needs to operate at a higher frequency to make room for header processing and to adapt to the natural word rate of external links.

For example, the IceBoard implementation of `chFPGA` typically have an ``in_clk`` of 200 MHz (ADC word clock = 800 MSPS/4), with each channelizers operating on a 8-phase clock network, which then feeds a 244 MHz corner-turn engine. The CRS implementations, on the other hand, have both ``in_clk`` and ``out_clk`` fed form the same adc clock of 400 MHz clock (3200 MSPS/8) since there is only one clock phase and the correlator also operates at 400 MHz (header space is gained by dropping some frequency bins).

.. todo:: Implement FIFO using a macro

``out_reset`` resets the output FIFO, but nothing else.


Data capture
------------

`CHAN` implements periodic data capture from either the Function Generator (`FUNCGEN`) output (which can provide the raw ADC waveform in addition to internally-generated waveforms) or the Scaler (`SCALER`) output (which can provide the raw FFT values, partially or fully scaled FFT values). These signals are connected to their sources through the bus called ``axis_cap0_*[0]`` and ``axis_cap0_*[1]``  respectively. The bus provides some pipelining to bring the source signals to the capture point, which can be a long distance in the FPGA.

The type of capture engine is set in the global parameter ``CONFIG_CHAN_CAPTURE_TYPE`` that is set in the config file. This parameter is locally bound to ``CAPTURE_TYPE`` in the `CHAN` module.

In implementations where the data capture in implemented in the channelizer (``CAPTURE_TYPE = "BRAM"``, such as the IceBoard implementations), the ``axis_cap0`` buses are routed to the ``PROBER`` module instantiated directly in `CHAN`. The slow-speed, serialized data captured by `PROBER` is sent out through the blocking 8-bit wide AXI-S bus ``prb_*``.

If an external, centralized capture module is used, such as the URAM-based `UCAP` (``CAPTURE_TYPE = "URAM"``, such as for the CRS implementations), one  of the ``axis_cap0`` bus is selected by the externally provided signal ``cap_source_req``, and is routed to the  output bus port ``m_axis_cap``. The ``cap_source_acq`` signal provides feedback  on which source is actually being sent. That signal is guaranteed to be aligned to the type of data being sent, even if the data bus is pipelined. Note that the ``tdata`` and ``tvalid`` bus signals are *always* sent for *both* sources, not just the selected source. This is to allow the capture module to keep track of the frame boundaries and frame numbers, and therefore allowing the capture periods to stay synchronized even if we switch between sources.

A assertion error will be raised during synthesis if any other capture type string is provided to ``CAPTURE_TYPE``, provided that the synthesizer is configured to fail on assertions (``-assert`` synthesis flag).

The width of the capture bus is set by the global parameter ``CONFIG_CAPTURE_BITS_PER_WORD`` defined in the configuration file. In `CHAN`, it is bound to ``CAPTURE_BITS_PER_WORD``. This parameters also sets the output width of the `SCALER`. Note that this width is used only for capturing purposes;  only (4+4 bits) outputs are outputed by `CHAN` to the corner-turn engine. URAM capture module `UCAP` can accomodate a 128-bit wide bus (although 144-bit would be technically possible), whereas the BRAM-based channelizer capture module `PROBER` typically has a 32-bit bus.

The contents of the word depends on the source.

For the FUNCGEN source, we assume the word contains  ``ADC_SAMPLES_PER_WORD`` samples per word, each sample being ``ADC_BITS_PER_SAMPLE`` - bit wide. In this case, the capture bus is divided in ``ADC_SAMPLES_PER_WORD`` fields, and the ADC samples are placed in those fields, left-aligned on the MSB. If the ADC sample is narrower than the field, the LSBs are zero-padded. If it is longer, the LSBs of the ADC samples are truncated. The samples are placed in the same MSB-to_LSB order as thet appear on the ADC bus.

For the SCALER source, the `SCALER` output is connected directly to the capture bus without interpretation, since both buses are the same width by design.

The user can capture `FUNCGEN` and `SCALER` data at any time and can dynamically switch between the two without affecting the channelizer output and the science data, as long as the  `FUNCGEN` and `SCALER` configurations are not changed.

See `FUNCGEN` and `SCALER` for the various types of data that can be captured.


Misc
----

.. todo:: discuss ``trig`` and ``lane_monitor`` signals.

Layout
------


.. todo:: Describe layout constraints
    - pipelining of ADC data to CHAN
    - meeting the route from the ADCs to the `CHAN` instance, which can be pretty far away. It is important to not include `CHAN` in a PBLOCK so the pipelining registers can be freely placed.

Memory map
==========


.. vhdl:include-docs:: CHAN
    :start-after: Memory Map

