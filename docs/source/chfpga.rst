.. title:: chfpga

**********************************************************
:entity:`chfpga` (*chfpga.vhd*): Top-level firmware module
**********************************************************

.. default-role:: vhdl:entity

Overview
========

chFPGA is the common module that is used to implement the core firmware for all configurations of all platforms. This entity uses parameters passed as generics or defined in the configuration file to select which sub-modules are instantiated and in which quantities, how they are configured and how they are connected.

chfpga is normally instantiated by a platform-specific top module that creates the platform-specific logic (board-specific ports, clock and data buffers etc.) that connects chfpga to the outside world.

`chfpga` instantiates the following sub-modules:

- System modules

    - Clocking system (`clocks`)
    - System Bus master (`bsb_master` and routers `bsb_router` with optional `UDP_MAC` 1G Ethernet interface)
    - GPIO and general configuration registers (`gpio`)
    - I2C and SPI controllers (`i2c` and `spi`)
    - System monitor (`sysmon`)
    - Reference clock/ synchroniztion sequencer (`refclk`)
    - Frequency counter (`freq_ctr`)
    - Heartbeat LED blinker (`blinker`)


- ADC Data acquisition logic and Channelizer array (`chan_array`)

- F-Engine/Channelizers (individual channelizer modules within `chan_array`)

- Corner-turn Engine

- X-Engine/Correlator

- 10/100 G Ethernet Data real-time streaming interfaces

- Data capture engine

Schematic
=========

.. .. figure:: ../images/chfpga.svg
..     :width: 100%



Entity documentation
====================

.. parse:: hdl/chfpga.vhd

.. autoentity:: chfpga


Description
===========

-The firmware can acquire the data and channelize N signals coming from the ADC board through the FMC connector. The number of supported ADCs is set by a variable in the firmware. The channelization is performed by a CASPER Polyphase filter bank (PFB)/FFT. A scaler module brings the frequency samples into a (8+8) bit complex number format. The FFT and the scaler modules can be bypassed for debugging purposed.

-The channelizer can be set to use data from three sources: the ADC chip, from a firmware-based function generator that can generate various patterns or from a injection buffer that allows the user to send data patters to be processed.

-The data at the output of the channelizer can be captured and streamed over the Ethernet interface. If the FFT is bypassed, the timestream is captured instead. The number of frames to capture and the frequency of the captures can be set by software.

-The firmware can implement M streaming correlators that correlate the (8+8) bits complex frequency samples from the N ADCs. Each correlator is programmed to process a fraction of the frequency bins grabbed from each antenna data streams. Multiple correlators are used to cover all designed frequency bins. The correlators operate on a separate clock from the data acquistion. The number of frequency channels that can be processed (and there the total number of correlators needed) depends on the correlator speed and the maximum accumulator depth.  The integration time and the data capture time can be set independently by software.

-All data processing modules and the control interfaces are interconnected through a standard AXI4 Streaming bus. This makes system interconnections and scaling easy.

-The design contains no processor or associated firmware. A simple UDP packet receiver/transmitter implemented as a state machine receives simple command frames and returns data. Every module in the system is mapped to a specific memory space in which control and status registers can be read or written.




Generic parameters
==================

Two general-purpose parameters appear outside the functional groups:

**PLATFORM_ID** *(integer)*

Integer identifying the target platform. Used internally to select low-level primitives (FIFO types, DSP/BRAM RPM coordinates, etc.). Predefined constants in ``chFPGA_Package``: ``PLATFORM_ID_KC705``, ``PLATFORM_ID_MGK7MB`` (ICEBoard), ``PLATFORM_ID_CRS``, etc.

**PROTOCOL_VERSION** *(integer)*

Version number embedded in BSB command/reply frames. Used by the host software to verify firmware compatibility.


Clocking
---------

**SYSTEM_CLOCK_SOURCE** *(clk_source_enum — SYSCLK | SYSCLK_BUFG | SFP_REFCLK)*

Source of the main system reference clock fed to the system MMCM:

- ``SYSCLK``: 200 MHz unbuffered differential clock from the ``sysclk_p/n`` pins (must be on MRCC/SRCC-capable pins).
- ``SYSCLK_BUFG``: Pre-buffered 200 MHz clock delivered on the ``sysclk_bufg`` input port.
- ``SFP_REFCLK``: 125 MHz clock from the SFP GTX/GTY reference. Used when no on-board oscillator is present.

**SYSTEM_CLOCK_FREQ** *(real)*

Frequency of the system reference clock in MHz. Used by the system PLL to select the correct divider/multiplier factors.

**CHAN_CLK_SOURCE** *(chan_clk_source_enum — ADC | MMCM)*

Source of the channelizer processing clock:

- ``ADC``: The single-phase ADC word clock is used directly as the channelizer clock.
- ``MMCM``: An 8-phase clock is generated by an MMCM driven by the ADC or system clock, allowing the channelizer to remain clocked during ADC resets.

**CHAN_CLK_FREQ** *(real)*

Target channelizer clock frequency in MHz. Only used when ``CHAN_CLK_SOURCE = MMCM``.

**CT_CLK_SOURCE** *(ct_clk_source_enum)*

Clock source for the corner-turn and correlator data path. See `Corner-turn engine`_ below.

**BUCK_SYNC_ENABLE** *(boolean)*

Default state of the DC-DC converter (buck regulator) synchronization at startup. When ``TRUE``, the buck switching frequency is synchronized to a divided-down version of the system clock.

**BUCK_CLK_DIVIDE_FACTOR** *(integer)*

Sets the buck sync frequency as ``200 MHz / BUCK_CLK_DIVIDE_FACTOR / 16``. For example, 12 → ~1.04 MHz; 24 → ~0.52 MHz.


BSB and data capture interface
-------------------------------

**BSB_INTERFACE** *(bsb_interface_enum — UDP_GMII | UDP_SGMII | AXIS)*

Selects the monitor and control (BSB) Ethernet interface:

- ``UDP_GMII``: A 1G Ethernet UDP interface is instantiated with a GMII physical layer (e.g. on the KC705 evaluation board).
- ``UDP_SGMII``: A 1G Ethernet UDP interface is instantiated with an SGMII physical layer over a GTX/GTY serial transceiver (e.g. on the ICEBoard and CHORD boards).
- ``AXIS``: No Ethernet MAC is instantiated. The BSB control interface is connected directly to the top-level ``*_axis_bsb_*`` AXI4-Streaming ports, for use with an external soft or hard MAC (e.g. the ARM PS on the CRS/ZCU111 platforms).

**CAP_INTERFACE** *(cap_interface_enum — BSB | AXIS)*  *(default: BSB)*

Selects the destination of the raw data capture buses produced by the probers and correlator readout engines:

- ``BSB``: Capture streams are forwarded to ``bsb_master``, which arbitrates them with command/reply traffic and transmits them over the 1G Ethernet link. Capture logic runs on ``bsb_clk``. Requires ``BSB_INTERFACE = UDP_GMII`` or ``UDP_SGMII``.
- ``AXIS``: Capture streams are merged by ``axis_merge`` and sent to the external ``m_axis_cap_*`` AXI4-Streaming port. Capture logic runs on ``axis_cap_clk``. Used on platforms where Ethernet is handled externally (e.g. CRS, ZCU111).

The two generics are independent: ``BSB_INTERFACE`` controls the command/control Ethernet path, while ``CAP_INTERFACE`` controls where probe data is sent.


ADCs and Mezzanines
--------------------

**ADC_TYPE** *(adc_type_enum — EV8AQ160 | AXIS)*

Selects the ADC data acquisition logic:

- ``EV8AQ160``: Instantiates the ADCDAQ deserializer and alignment logic for the EV8AQ160 analog front-end chip. The board-specific parameters below apply only for this type.
- ``AXIS``: ADC data is provided externally over the ``adc_axis_*`` AXI4-Streaming bus with no deserializer logic.

**NUMBER_OF_ADCS** *(integer)*

Number of ADC data acquisition (ADCDAQ) blocks to implement. Typically equal to ``NUMBER_OF_CHANNELIZERS``.

**NUMBER_OF_ADC_BOARDS** *(integer)*

Number of ADC mezzanine boards (e.g. FMC connectors). Determines the number of SPI chip-select lines and ADC synchronization (SYNC/SYSREF) signals.

The following parameters apply only when ``ADC_TYPE = EV8AQ160``:

**ADC_IS_DIFFERENTIAL** *(bufmr_map_array)*

Per-ADC, per-line indicator of whether each data and clock input is differential (non-zero) or single-ended (zero). Defaults to all differential.

**ADC_PROVIDE_BUFFERED_DIVCLK** *(bool_array)*

Per-ADC flag enabling the generation of a BUFG-buffered ADC word clock used as the global channelizer processing clock. Only one ADC (typically one on an MRCC pin pair) should set this to ``TRUE`` to avoid exhausting global clock buffers.

**ADC_INSTANTIATE_PLL** *(bool_array)*

Per-ADC flag to instantiate an MMCM/PLL providing IOCLK and DIVCLK to ISERDES blocks in non-adjacent IO banks. Only required when data lines cross 7-Series clock regions.

**ADC_USE_EXT_DATA_CLK** *(bool_array)*

Per-ADC flag selecting the PLL-generated IOCLK/DIVCLK instead of the local IOCLK/BUFR clocks. Required when data lines span non-adjacent IO banks.

**ADC_INSTANTIATE_BUFMR** *(bufmr_map_array)*

For 7-Series only. Per-ADC, per-line BUFMR index, enabling multi-region clock buffer routing when data or clock lines span adjacent clock regions. Negative values disable BUFMR for that line.

**CHAN_CLK_SOURCE_LANE** *(integer)*

Index of the ADC whose BUFG-buffered word clock is used as the global channelizer processing clock. Must be an ADC with ``ADC_PROVIDE_BUFFERED_DIVCLK = TRUE``.

**ADC_TO_ADC_BOARD_MAP** *(integer_array)*

Maps each ADC index to its physical mezzanine board number (e.g. FMC A or FMC B). Used to route SPI and SYNC signals to the correct connector.


Channelizers
-------------

**FFT_TYPE** *(fft_type_enum — NONE | CHIME | D3A | CHORD | HIRAX | HIRAX_3DSP)*

Selects the polyphase filter bank (PFB)/FFT core to implement. Each choice fixes the number of samples per frame, FFT size, input bit width and bins per output word, as defined in the ``FFT_INFO`` constant in ``chFPGA_Package``.

**NUMBER_OF_CHANNELIZERS** *(integer)*

Total number of channelizer instances to implement. Must not exceed ``NUMBER_OF_ADCS`` when ``ADC_TYPE = EV8AQ160``.

**NUMBER_OF_CHANNELIZERS_WITH_FFT** *(integer)*

Number of channelizers that instantiate the full PFB/FFT core. Remaining channelizers pass raw time-domain data downstream (bypass mode).

**CAPTURE_TYPE** *(chan_capture_type_enum — PROBER | UCAP)*

Selects the raw data capture engine:

- ``PROBER``: BRAM-based capture engine instantiated within each channelizer. Simple and portable across all platforms.
- ``UCAP``: Centralized URAM-based capture engine shared across all channelizers. Provides deeper capture buffers at lower per-channelizer cost; requires an Ultrascale+ device.

**CAPTURE_BITS_PER_WORD** *(integer)*

Number of bits per word fed into the capture engine. Defaults to ``CHAN_CAPTURE_INFO(CAPTURE_TYPE).INPUT_WIDTH``.


Corner-turn engine
-------------------

The corner-turn engine transposes channelized frequency data so that each output stream covers all antennas for a subset of frequency bins, as required by the correlator or data offload backends.

**CT_TYPE** *(ct_type_enum — NONE | BCT | UCT)*

Selects the corner-turn engine variant:

- ``NONE``: No corner-turn engine is instantiated.
- ``BCT``: Backplane corner-turn engine (``bct_engine``), used with IceBoard-based systems and Kintex-7 FPGAs. Performs an internal 16×16 corner-turn and optionally a 16×16 intra-crate and inter-crate corner-turn. Each input lane packs 2×(8+8)-bit bin values per 32-bit word (8+8 in bypass mode; 4+4 in normal operation).
- ``UCT``: Ultrascale+ corner-turn engine (``uct_engine``), used with CRS boards. Performs single-board (8-input) and multi-board (up to 32-input) corner-turns. Each input lane packs 4×(4+4)-bit bin values per 32-bit word.

**CT_LEVEL** *(integer — 1 | 2 | 3)*

Number of corner-turn stages:

- ``1``: Single-board (local) corner-turn only. No backplane GTY links are used.
- ``2``: Level 1 plus a 4×4 sub-backplane corner-turn connecting 4 boards via GTY transceivers.
- ``3``: Level 2 plus an additional 4×4 corner-turn between 2 or 4 sub-backplanes (8 or 16 boards total).

When ``CT_LEVEL = 1`` no GTY output buffers are instantiated and one correlator is implemented per frequency bin per channelizer output word. For ``CT_LEVEL ≥ 2`` backplane GTY links and associated quads are enabled.

**CT_CLK_SOURCE** *(ct_clk_source_enum — BP_SHUFFLE_TXCLK | ADC_CLK | CGE_CLK322 | CORR_CLK)*

Clock source for the corner-turn and correlator data path:

- ``BP_SHUFFLE_TXCLK``: Backplane GTY transmit word clock (~244 MHz at 7.5 Gb/s; ~322 MHz at 10 Gb/s). Locks the data path to the backplane serial link clock. Suitable for multi-board configurations.
- ``ADC_CLK``: ADC word clock (~200–400 MHz depending on platform). Suitable for single-board configurations.
- ``CGE_CLK322``: 322 MHz clock derived from the 100G Ethernet (UPACK_CGE) reference.
- ``CORR_CLK``: Correlator clock from the system MMCM. Used when the correlator and corner-turn must share a clock domain.

**BP_LINK_SPEED** *(integer — 0 | 1)*

Backplane GTY link speed. ``0`` → 7.5 Gb/s (word clock ≈ 244 MHz); ``1`` → 10 Gb/s (word clock ≈ 322 MHz). Only relevant when ``CT_LEVEL ≥ 2``.

**CT_LANE_TO_LINK_MAP** *(integer_array)*

Maps each logical corner-turn lane index to a GTY link number. ``-1`` designates a *bypass lane* — one that stays internal to the board with no GTY transceiver. Links listed in ``CT_LINK_TO_QUAD_MAP`` but absent from this map receive minimal GTY logic (sufficient for BER testing only).

*Example (CRS, CT_LEVEL=1 — no GTY needed):*

.. code-block:: vhdl

   CT_LANE_TO_LINK_MAP => (0 => -1)

*Example (ICEBoard, CT_LEVEL=3):*

.. code-block:: vhdl

   CT_LANE_TO_LINK_MAP => (
       0 => -1,                                -- bypass lane
       1 => 0, 2 => 1, ..., 15 => 14,         -- backplane PCB lanes → GTY links 0–14
       16 to 19 => -1,                         -- bypass lanes
       20 => 15, 21 => 16, 22 => 17, 23 => 18 -- QSFP lanes → GTY links 15–18
   )

**CT_LINK_TO_QUAD_MAP** *(integer_array)*

Maps each GTY link to the transceiver quad it belongs to. The array length sets ``NUMBER_OF_CT_LINKS``, and ``max(list)+1`` QPLLs are implemented.

.. code-block:: vhdl

   CT_LINK_TO_QUAD_MAP => (0 to 3 => 0, 4 to 7 => 1, 8 to 11 => 2)
   -- 12 links across 3 quads

**CT_QUAD_TO_REFCLK_MAP** *(integer_array)*

Maps each transceiver quad to a reference clock index. ``max(list)+1`` sets ``NUMBER_OF_CT_REFCLKS`` and the width of the ``bp_shuffle_refclk_p/n`` ports. Multiple quads may share a reference clock.

.. code-block:: vhdl

   CT_QUAD_TO_REFCLK_MAP => (0 => 1, 1 => 0, 2 => 0)
   -- Quad 0 → refclk(1);  Quads 1 and 2 → refclk(0)

**CT_LANE_TO_GROUP_MAP** *(integer_array)*

Maps each logical lane to a lane group. Groups differentiate lanes used at different corner-turn levels:

- Group ``0``: Level-2 lanes (sub-backplane / intra-crate shuffle).
- Group ``1``: Level-3 lanes (inter-crate shuffle).

The count of group-0 lanes (when ``CT_LEVEL ≥ 2``) sets ``NUMBER_OF_CT_CB1_OUTPUTS``, used by the software to configure the first-level crossbar bin-selection registers.

.. code-block:: vhdl

   CT_LANE_TO_GROUP_MAP => (0 to 15 => 0, 16 to 23 => 1)
   -- Lanes 0–15: CT2 (sub-backplane);  Lanes 16–23: CT3 (inter-crate)


Correlator
-----------

**CORR_TYPE** *(corr_type_enum — NONE | CORR44 | UCORR44)*

Selects the X-Engine correlator architecture:

- ``NONE``: No correlator is instantiated.
- ``CORR44``: Standard 4+4 bit fixed-point correlator using hardened DSP48 tiles. Available on Kintex-7 and Ultrascale+.
- ``UCORR44``: Ultrascale+ variant with URAM-based accumulation buffers for deeper integration depths.

**CORR_READOUT_BINS** *(integer_array)*

Array of length equal to the number of correlators, specifying which frequency-bin group each correlator reads out. Used to configure the bin-selection logic within each correlator block.


Real-time data offload
-----------------------

**DATA_LINK_TYPE** *(data_link_type_enum — NONE | XGE | UPACK_CGE)*

Selects the high-speed Ethernet interface for real-time streaming to a GPU or computing node:

- ``NONE``: No offload link is instantiated.
- ``XGE``: 10 Gigabit Ethernet over SFP+ transceivers.
- ``UPACK_CGE``: 100 Gigabit Ethernet over QSFP28 transceivers, using the UPACK packetizer engine.

**DATA_LINK_LINK_TO_QUAD_MAP** *(integer_array)*

Maps each offload channel to the GTY transceiver quad it uses. The array length determines ``NUMBER_OF_GPU_LINKS``. Ignored when ``DATA_LINK_TYPE = NONE``.

**DATA_LINK_QUAD_TO_REFCLK_MAP** *(integer_array)*

Maps each GTY quad used for offload links to its reference clock index. ``max(list)+1`` sets ``NUMBER_OF_GPU_REFCLKS``.


Peripherals
------------

**BLINKER_PRESENT** *(boolean)*

When ``TRUE``, instantiates the LED heartbeat blinker module.

**NUMBER_OF_I2C_PORTS** *(integer)*

Number of I2C master controller instances.

**NUMBER_OF_SPI_PORTS** *(integer)*

Number of SPI master controller instances (typically one per FMC mezzanine).

**IMPLEMENT_LCD** *(boolean)*

When ``TRUE``, instantiates the LCD/OLED display controller and clock-select logic.

**IMPLEMENT_SWITCHER_SYNC** *(boolean)*

When ``TRUE``, instantiates the DC-DC converter synchronization logic driving the ``buck_sync`` output.

**IMPLEMENT_FAN** *(boolean)*

When ``TRUE``, instantiates the fan speed controller for board thermal management.

**IMPLEMENT_ARM_SPI** *(boolean)*

When ``TRUE``, instantiates the ARM-facing SPI bridge (PS-PL SPI on Zynq-based platforms).

**SIM** *(boolean)*

When ``TRUE``, enables simulation-mode shortcuts that accelerate functional simulations (e.g. reduced counter widths, shortened initialization sequences).


Derived parameters
-------------------

The following generics have default values computed from other generics. They expose port vector widths to the platform-specific top-level wrapper and should not be overridden unless the computed default is incorrect.

**NUMBER_OF_CT_LINKS** = ``CT_LINK_TO_QUAD_MAP'LENGTH``

Number of GTY links for the corner-turn backplane shuffle. Sets the width of ``bp_shuffle_tx_p/n`` and ``bp_shuffle_rx_p/n``.

**NUMBER_OF_CT_REFCLKS** = ``max(CT_QUAD_TO_REFCLK_MAP) + 1``

Number of GTY reference clock pairs for the corner-turn engine. Sets the width of ``bp_shuffle_refclk_p/n``.

**NUMBER_OF_GPU_LINKS** = ``DATA_LINK_LINK_TO_QUAD_MAP'LENGTH`` *(0 if* ``DATA_LINK_TYPE = NONE`` *)*

Number of high-speed offload links instantiated.

**NUMBER_OF_GPU_REFCLKS** = ``max(DATA_LINK_QUAD_TO_REFCLK_MAP) + 1``

Number of GTY reference clock pairs for the offload links.


Memory Map
==========

Top level memory map
--------------------

.. include-docs:: chfpga
    :start-after: Top-level Memory map




Submodules
==========

The following modules are instantiated directly by `chFPGA`:


.. toctree::
    :maxdepth: 1
    :hidden:

    System<system/system>
    F-Engine<channelizer/chan>
    CT Engine <corner-turn/index>
    X Engine <correlator/index>
