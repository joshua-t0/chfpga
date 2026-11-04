.. title:: CORR44

**********************************************************
:entity:`CORR44` (*CORR44.vhd*): (4+4) bit Correlator Core
**********************************************************

.. parse:: hdl/corr/CORR44.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: CORR44

Parameters
----------

- **PLATFORM_TYPE:** FPGA platform type (``platform_type_enum``), used to select DSP and FIFO primitive variants and determine RPM coordinate spacings for the CMAC44 cells.
- **RPM_LAYOUT:** String naming the physical layout pattern of the CMAC44 column (e.g. ``"BDDB"`` or ``"DBBD"``), used to derive the relative placement coordinates of all :entity:`CMAC44` instances.
- **CORR_NUMBER:** Integer index of this correlator within the parent array, embedded in the output packet header and used to compute RPM origins (default 0).
- **NUMBER_OF_WORDS_PER_BIN:** Number of 32-bit input words per frequency bin (default 4). Each word carries four (4+4)-bit complex samples, giving ``4 × NUMBER_OF_WORDS_PER_BIN`` samples per bin.
- **NUMBER_OF_HEADER_WORDS:** Number of 32-bit header words at the beginning of each input frame (default 4, must be ≤ 4).
- **DEFAULT_INTEGRATION_PERIOD:** Default number of input frames per integration period (default 390625, corresponding to 1 second at the CHIME frame rate). Configurable at run time via the BSB control interface.
- **DEFAULT_BINS_PER_FRAME:** Default number of frequency bins per input frame (default 128). Configurable at run time.
- **DEFAULT_CONTROL_BYTE0:** Default value of control register byte 0 at reset (default ``0x80``).

Interface
---------

Data input
~~~~~~~~~~

- ``s_axis_tdata``: 32-bit non-blocking AXI4-Stream input carrying four (4+4)-bit signed complex samples per word. Each frame begins with ``NUMBER_OF_HEADER_WORDS`` header words followed by frequency-bin data.
- ``s_axis_tvalid``, ``s_axis_tlast``: AXI4-Stream valid and last flags.
- ``in_clk``: Clock for the input data path and correlator logic.
- ``in_rst``: Synchronous reset for the input-clock domain.

Data output
~~~~~~~~~~~

- ``m_axis_data_out_tdata``: 8-bit blocking AXI4-Stream carrying byte-serialized integrated-product frames (a 3-word / 12-byte packet header followed by 5 bytes per (18+18)-bit product word).
- ``m_axis_data_out_tvalid``, ``m_axis_data_out_tlast``, ``m_axis_data_out_tready``: AXI4-Stream handshake signals.
- ``out_clk``: Clock for the output stream (may differ from ``in_clk``).
- ``out_rst``: Synchronous reset for the output-clock domain.

Control (BSB)
~~~~~~~~~~~~~

- ``s_axis_bsb_tdata/tvalid/tlast/tready``: Incoming BSB (byte-stream bus) control commands targeting the on-board register bank.
- ``m_axis_bsb_tdata/tvalid/tlast/tready``: BSB reply stream.
- ``bsb_clk``: Control-bus clock.
- ``bsb_rst``: Control-bus reset.

Implementation details
----------------------

Architecture
~~~~~~~~~~~~

A single CORR44 core consists of:

- An array of ``(N+1)×2`` :entity:`CMAC44` units, where ``N = 4 × NUMBER_OF_WORDS_PER_BIN``, arranged so that every unique antenna-pair correlation product is covered in N/2 input clocks.
- Input buffering and rotation logic that presents the correct (X, Y) sample pair to each CMAC44 on every clock, covering the lower-triangular product matrix plus the auto-correlations.
- A 38-bit × 512-word asynchronous FIFO that serializes the 36-bit CMAC readout stream to 8-bit words across clock domains.
- A BSB register bank (:entity:`bsb_regs`) exposing software-configurable integration period, bin count, and operating mode flags.

Clocking
~~~~~~~~

Input data is processed on ``in_clk``. Integrated products are read out on ``out_clk``. An asynchronous FIFO bridges the two clock domains. The BSB control interface runs on ``bsb_clk``.

Principle of operations
~~~~~~~~~~~~~~~~~~~~~~~~

Each incoming frame is parsed: the ``NUMBER_OF_HEADER_WORDS`` header words are consumed to synchronize framing, and the subsequent data words (``NUMBER_OF_WORDS_PER_BIN`` per bin) are buffered and then presented in rotation order to the CMAC44 array. The rotation ensures that every unique product of the N×N cross-correlation matrix (lower triangle plus diagonal) is computed exactly once per bin. All CMAC44s accumulate their assigned product into a 512-deep vector accumulator. After ``integration_period`` frames the accumulated data is captured and streamed out, prepended with a packet header carrying the correlator ID, integration number, and bin count.

Memory Map
----------

.. include-docs:: CORR44
    :start-after: CONTROL and STATUS Bytes

