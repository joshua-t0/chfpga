.. title:: UCAP

********************************************************
:entity:`UCAP` (*ucap.vhd*): UltraRAM-based data capture
********************************************************

Overview
--------

UCAP periodically captures raw data frames coming from eight 128-bit AXI Stream buses and streams  out the the captured data  through a single 8-bit AXI stream bus. This module is typically used to capture raw ADC of FFT data from the 'CHAN' module and stream it through UDP packets over a Gigabit Ethernet interface.


Features
--------

- `UCAP` is a centralized capture engine, as opposed to a channelizer-based (distributed) capture engine.
- It makes use of the Ultrascale UltraRAM blocks to store large amounts of data (512 kBytes total).
- Operation of `UCAP` is configured over a memory-mapped register interface through a Byte-serial bus (BSB)
- `UCAP` allows the user to  can capture data from up to 8 channels simulatenously, but the user can dynamically choose a compromise between the number of channels captured and the number of contiguous frames stored for each channel. Options are:

    - 2 contiguous frames from all 8 channels (where one frame = 16384 samples @ 16-bit/sample)
    - 4 contiguous frames from 4 user-selectable channels
    - 8 contiguous frames from 2 user-selectable channels
    - 16 contiguous frames from one user-selectable channel

- Each capture channel can be independently selected from one of 2 data sources.  The muxing is done in near the data source,
- `UCAP` continuously keeps track of the frame number of each souce, independent of which source is selected. The capture triggers are also independently generated for each source. This allow switching back and forth between sources while maintaining the timing of the capture of each source.
- `UCAP` ensures that the current frame is completed and that data capture starts on the first frame of the new source when the source is changed by the user.
- Data is captured at a base period that can be set to any number of frames. `UCAP` must be reset if that base rate is changed.
- In order to allow dynamic capture rate changes (e.g. during instrument calibration periods), a power-of-two sub-capture period can be set at any time to increase the number of captures within the base period. The sub capture period corresponds to ``2^(N+1)`` frames starting at the beginning of each base capture period. The sub rate can be changed at any time without resetting `UCAP` while ensuring there will be always be a capture every ``frame_number = k * base_rate frame``.


Limitations
-----------

- All sources must be synchrounous, i.e. they all operate on a single clock.
- Data from the same source must have the same packet alignments; all packets from source 0 on all channels must start and end on the same clock. Same for the source 1.



Schematic
---------

.. .. figure:: ../images/ucap.svg
..     :width: 50%

.. parse:: hdl/chan/ucap.vhd

.. toctree::
   :titlesonly:


Entity documentation
--------------------

 .. autoentity:: ucap


Parameters
----------

- **NUMBER_OF_CHANNELS:** Number of input channels. Hard-coded to 8 in practice; this generic exists for code clarity only. The current implementation is limited to 8 channels because the mode selection uses a fixed 2-bit encoding (4 modes: 8, 4, 2, or 1 channel), the mux logic is optimised for 8 inputs, and only 16 UltraRAM blocks are available (8 buffers × 2 URAM each). Default is 8.
- **NUMBER_OF_SOURCES:** Number of selectable data sources per channel. Hard-coded to 2; the logic uses a single-bit source-selection signal throughout. Default is 2.
- **CAPTURE_BITS_PER_WORD:** Width of each input data word in bits. Must be a multiple of 8. Typically 128 bits to accommodate 8 samples × 16 bits per sample, but `UCAP` is word-content agnostic. Default is 128.

Interface
---------

Input
~~~~~

- ``s_axis_tdata`` (array): ``NUMBER_OF_CHANNELS`` AXI4-Streaming data inputs, each ``CAPTURE_BITS_PER_WORD`` bits wide. ``s_axis_tvalid`` and ``s_axis_tlast`` are shared across all channels; all channels from the same source must have synchronised packet boundaries.
- ``source_sel_out``: Per-channel output requesting which source should be active at the remote multiplexer.
- ``source_sel_in``: Per-channel feedback indicating which source is currently presented on each channel's data bus.
- ``s_axis_stream_in_*``: Optional 8-bit auxiliary AXI4-Streaming input for capturing additional data (e.g., correlator output).
- ``s_axis_clk``: Main capture clock (typically 400 MHz).

Output
~~~~~~

- ``m_axis_*``: AXI4-Streaming byte-serialised output carrying captured frames or auxiliary stream data (selected by ``output_source_sel``).
- ``m_axis_clk``: Output stream clock.

BSB control
~~~~~~~~~~~

- ``s_axis_bsb_*/m_axis_bsb_*``: Blocking 8-bit AXI4-Streaming Byte-Serial Bus command/reply interface for memory-mapped register access.
- ``ctrl_clk``: Control bus clock.

Implementation details
----------------------

Principle of operations
~~~~~~~~~~~~~~~~~~~~~~~

UCAP captures wide AXI-Streaming data frames into UltraRAM buffers and then serialises them byte-by-byte over an 8-bit output stream. Up to 8 independent input channels can be captured simultaneously; the number of channels and frames per capture is traded off by selecting one of four modes. Capture is triggered at a software-configurable base period (in frames) and optionally at power-of-two sub-periods to support dynamic cadence changes without a reset. Independent frame counters and period counters are maintained for each source so that source switching does not disrupt timing.

Clocking and resets
~~~~~~~~~~~~~~~~~~~

UCAP operates on three clock domains:

- ``s_axis_clk``: The main capture clock (typically 400 MHz), used for all input data interfaces, memory write/read operations, and internal processing

- ``m_axis_clk``: Clock for the output stream.
- ``ctrl_clk``: Clock for the  BSB control interface

The module uses synchronous resets. A user reset (``user_reset``) can be triggered via the BSB control interface and is synchronized to the ``s_axis_clk`` domain. During reset, all counters are cleared and capture is enabled for the first frame after reset.

Capture modes
~~~~~~~~~~~~~

UCAP supports four capture modes, selected by the 2-bit ``mode`` register:

- **Mode 0 (8-channel mode)**: Captures 2 contiguous frames from all 8 channels simultaneously. Each channel uses one memory buffer (2 frames per buffer).
- **Mode 1 (4-channel mode)**: Captures 4 contiguous frames from 4 user-selectable channels. Each selected channel uses 2 memory buffers (4 frames total per channel).
- **Mode 2 (2-channel mode)**: Captures 8 contiguous frames from 2 user-selectable channels. Each selected channel uses 4 memory buffers (8 frames total per channel).
- **Mode 3 (1-channel mode)**: Captures 16 contiguous frames from one user-selectable channel. The selected channel uses all 8 memory buffers (16 frames total).

The mode determines how input channels are mapped to memory buffers. In mode 0, channels 0-7 map directly to buffers 0-7. In other modes, user-selected channels (via ``chan_sel_map``) are routed to groups of buffers to store multiple frames per channel.

Source selection and frame tracking
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Each physical channel can select between two data sources via a remote multiplexer. The source selection is controlled per-channel through the ``source_sel_out`` signals, which are sent to the remote mux, and the active source is reported back via ``source_sel_in``.

UCAP maintains independent frame counters, period counters, and timestamps for each source, regardless of which source is currently selected. This allows switching between sources while maintaining proper timing for each source independently. The capture triggers are generated continuously in parallel for both sources, so frame numbers remain synchronized even when a source is not actively being captured.

When the source selection changes, UCAP ensures that the current frame completes before starting capture on the new source. Capture always begins on the first frame of the newly selected source.

Capture period and sub-period
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Data capture is triggered at a configurable base period, specified in frames via the ``base_period`` register (24 bits, one per source). The base period can be set to any number of frames, but UCAP must be reset if the base period is changed.

To allow dynamic capture rate changes (e.g., during instrument calibration), a power-of-two sub-capture period can be enabled via the ``sub_period`` register (5 bits). The sub-period corresponds to ``2^(N+1)`` frames, where N is the value in ``sub_period``. The sub-period can be changed at any time without resetting UCAP, and ensures there is always a capture every ``frame_number = k * base_period`` frame.

The capture trigger logic checks both conditions: ``period_ctr = base_period`` OR the sub-period condition (using ``all_ones(period_ctr, sub_period, 0)``). When either condition is met, ``capture_en`` is set to '1' and capture begins on the next frame boundary.

Memory organization
~~~~~~~~~~~~~~~~~~~

UCAP uses UltraRAM (URAM) blocks to store captured data. Each memory buffer is 128 bits wide × 4096 words deep, requiring 2 URAM primitives (each URAM is 4K × 72 bits). With 16 URAM blocks available, UCAP can implement 8 memory buffers.

Each buffer can store 2 frames (16384 samples / 8 samples per word = 2048 words per frame, so 2 frames = 4096 words). The total storage capacity is:

- Mode 0: 2 frames × 8 channels = 16 frames total
- Mode 1: 4 frames × 4 channels = 16 frames total
- Mode 2: 8 frames × 2 channels = 16 frames total
- Mode 3: 16 frames × 1 channel = 16 frames total

The memory write address is constructed from the frame number LSB (selecting which of the 2 frames in the buffer) and the word counter (11 bits for 2048 words per frame). The memory read address uses the same structure but is driven by the read sequencer.

Write process
~~~~~~~~~~~~~

The write process (``wr_blk``) handles data capture and storage. It operates independently for each source, maintaining separate counters and state.

For each source, the process:

1. Tracks word and frame counters, incrementing on ``s_axis_tvalid`` and ``s_axis_tlast``
2. Maintains a period counter that increments on each frame boundary
3. Generates capture triggers when the period counter matches ``base_period`` or the sub-period condition
4. Writes data to the appropriate memory buffer based on the current mode, selected channel, and frame number

The input channel multiplexing logic routes selected channels to memory buffers according to the mode:

- **Mode 0**: Uses four 8:1 muxes for even buffers (0,2,4,6) and four 2:1 muxes for odd buffers (1,3,5,7). Even buffers select channels 0,2,4,6; odd buffers select channels 1,3,5,7 directly.
- **Modes 1-3**: Uses four 8:1 muxes that feed both even and odd buffers in each pair with the same data. The mux selection is driven by ``chan_pair_sel``, which is derived from ``chan_sel_map`` based on the mode.

The memory write enable is set for only one buffer per channel at a time, based on the current frame number and the mode-dependent buffer assignment. When a capture completes (all frames stored), a ``src_readout_trig`` pulse is generated to initiate readout.

Read process and packet formatting
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The read process (``rd_blk``) handles data readout and packet formatting. It consists of two main components:

1. **Read sequencer**: A state machine that generates RAM read addresses and opcodes for the data processor. It operates in three states:
   - ``READ_SEQ_WAIT``: Waits for buffers to be ready for readout
   - ``READ_SEQ_SEND_HEADER``: Sends the 10-byte packet header
   - ``READ_SEQ_SEND_DATA``: Sends the packet data (8192 bytes per packet)

2. **Read processor**: Processes data coming out of RAM (after the RAM read latency) based on opcodes from the sequencer. It handles:
   - Header byte transmission
   - Data byte extraction from 128-bit words (MSB first)
   - Packet boundary management (4 packets per frame)

The read sequencer uses a delay pipeline (``read_proc_op`` and ``buf_ix``) to compensate for the RAM read latency (4 clocks). The opcode and buffer index are pipelined so they arrive at the same time as the data.

Each captured frame is split into 4 packets to fit within Ethernet jumbo frame limits. Each packet contains:

- **10-byte header**:

  - Byte 0: PROBE ID (``0xA0`` for source 0, ``0xA1`` for source 1)

  - Bytes 1-2: STREAM ID (16 bits, MSB first)

    - Bits 15:12: Frame number (0 to N-1, where N=2,4,8,16 depending on mode)
    - Bits 11:4: User stream ID (crate/slot identifier)
    - Bits 3: Unused (zero)
    - Bits 2:0: Channel number

  - Byte 3: Flags
  
    - Bits 7:4: Serial flags (all zeros)
    - Bits 3:2: Mode (0=8-channel, 1=4-channel, 2=2-channel, 3=1-channel)
    - Bits 1:0: Packet number within frame (0-3)

  - Bytes 4-9: 48-bit timestamp (frame number, MSB first)

- **8192 bytes of data**: 128-bit words are transmitted byte-by-byte, MSB first, in the natural order they were captured.

The read sequencer throttles based on the ``fifo_full`` signal. Since there is data in the pipeline when ``fifo_full`` is asserted, the FIFO's ``prog_full`` threshold must be set low enough to accommodate pipeline writes after the throttle signal is raised.

Output FIFO
~~~~~~~~~~~

An asynchronous FIFO bridges the ``s_axis_clk`` domain (write side) and ``m_axis_clk`` domain (read side). The FIFO is 9 bits wide (8 data + 1 TLAST) and 512 words deep, using BRAM with First-Word-Fall-Through (FWFT) mode.

The FIFO depth and ``prog_full`` threshold are carefully sized to handle the clock domain crossing latency. The ``prog_full`` threshold is set to 256 to account for:
- Clock domain crossing delay (4-5 slow clocks = 16-20 fast clocks)
- Pipeline writes after the throttle signal is raised

The FIFO can accept data from either the UCAP captured data stream or the auxiliary input stream, selected via ``output_source_sel``.

BSB registers
~~~~~~~~~~~~~

UCAP is configured and monitored through BSB (Byte-Serial Bus) control registers:

- **Control registers**:
  - ``mode``: 2-bit capture mode selection
  - ``chan_sel_map``: Channel selection for modes 1-3 (4 × 3-bit values)
  - ``base_period``: Capture period in frames (24 bits per source)
  - ``sub_period``: Sub-capture period (5 bits)
  - ``source_sel_out``: Source selection request for each channel (8 bits)
  - ``user_stream_id``: User-defined stream identifier (8 bits)
  - ``output_source_sel``: Output stream selection (0=UCAP data, 1=auxiliary)
  - ``user_reset``: User reset trigger

- **Status registers**:
  - ``fifo_overflow_sticky``: FIFO overflow indicator (sticky)
  - ``overrun``: Buffer overrun indicator
  - ``period_ctr``: Current period counter value (8 LSBs of source 0)
  - ``source_sel_in``: Current source selection input (8 bits)

See the Memory Map section below for detailed register descriptions.



Memory Map
----------

.. include-docs:: UCAP
    :start-after: UCAP Memory Map
