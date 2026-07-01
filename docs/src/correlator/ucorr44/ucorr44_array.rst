.. title:: ucorr44_array

*************************************************************************
:entity:`UCORR44_ARRAY` (*UCORR44_ARRAY.vhd*): (4+4) bit Correlator Array
*************************************************************************

.. parse:: hdl/corr/UCORR44_ARRAY.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: UCORR44_ARRAY

Parameters
----------

- **PLATFORM_TYPE:** FPGA platform type (``platform_type_enum``), passed to each :entity:`UCORR44` instance and to the output FIFO to select the appropriate hard-macro primitives.
- **NCORR:** Number of :entity:`UCORR44` correlator cores instantiated in the array (default 1).
- **NCHAN:** Number of antenna channels to correlate per core (default 8). Each core computes ``NCHAN × (NCHAN+1) / 2`` unique complex products.
- **NBINS_PER_CORR:** Number of frequency bins processed by each correlator before decimation (default 2048).
- **BIN_DECIMATION_FACTOR:** Only 1 out of every ``BIN_DECIMATION_FACTOR`` consecutive bins is correlated, reducing resource usage when the full bin rate is not needed (default 1, no decimation).
- **N_BITS_PER_BIN:** Bit width of each complex sample. Must be 8 (4-bit real + 4-bit imaginary; default ``4+4``).
- **SOFT_NINTEG:** Power-on default integration period in input frames (default 8192). Overridable at run time via the BSB control interface.
- **SOFT_AUTOCORR_ONLY:** Power-on default for the autocorrelation-only mode (default ``FALSE``).
- **READOUT_BINS:** Array of ``NCORR`` integers specifying, for each correlator, which frequency bin within each decimation block is sacrificed to the readout cycle (default 0 for all cores).
- **INPUT_WIDTH:** Total width of the input data bus in bits (default 256). The bus is divided into ``NCORR`` equal sections, with correlator 0 in the most-significant bits.

Interface
---------

Data input
~~~~~~~~~~

- ``s_axis_data_tdata``: ``INPUT_WIDTH``-bit non-blocking AXI4-Stream input. Data is arranged MSB-first as ``(Corr0,Chan0), (Corr0,Chan1), …, (CorrN−1, ChanM−1)``. Each channel sample is one byte with the 4-bit real part in the upper nibble and the 4-bit imaginary part in the lower nibble.
- ``s_axis_data_tvalid``, ``s_axis_data_tlast``: AXI4-Stream valid and last flags; ``tlast`` marks the last word of each input frame.
- ``clk``: Clock for input data and correlator logic.
- ``rst``: Synchronous reset.

Data output
~~~~~~~~~~~

- ``m_axis_data_tdata``: 8-bit blocking AXI4-Stream carrying byte-serialized integrated-product frames (header + data) from all ``NCORR`` correlators, daisy-chained into a single stream.
- ``m_axis_data_tvalid``, ``m_axis_data_tlast``, ``m_axis_data_tready``: AXI4-Stream handshake signals.
- ``out_clk``: Clock for the output stream. An asynchronous FIFO bridges ``clk`` and ``out_clk``.

Control (BSB)
~~~~~~~~~~~~~

- ``s_axis_bsb_tdata/tvalid/tlast/tready``: BSB (byte-stream bus) control command input shared by all correlators.
- ``m_axis_bsb_tdata/tvalid/tlast/tready``: BSB reply output.
- ``bsb_clk``: Clock for the BSB control interface.
- ``bsb_rst``: Reset for the BSB control interface.

Implementation details
----------------------

Architecture
~~~~~~~~~~~~

The array instantiates ``NCORR`` :entity:`UCORR44` cores and one :entity:`generic_fifo` output FIFO. The incoming wide data bus is split and pipelined into per-correlator streams. The readout outputs of all cores are daisy-chained: the output of core *i* is fed as the cascade input of core *i* - 1, so data flows through the chain and exits from core 0 into the shared output FIFO. A :entity:`bsb_regs` instance exposes control and status registers for the entire array.

Clocking
~~~~~~~~

Input data and correlator logic run on ``clk``. Integrated-product output runs on ``out_clk``. The asynchronous output FIFO bridges the two clock domains. The BSB interface runs on ``bsb_clk``. Software-controlled reset signals are re-synchronized to ``clk`` using XPM CDC cells.

Principle of operations
~~~~~~~~~~~~~~~~~~~~~~~~

On each input clock the wide input bus is split and de-multiplexed into ``NCORR`` streams of ``NCHAN_PER_CLK`` channels each. Each stream is passed to a :entity:`UCORR44` core, which assembles full-bin snapshots and computes all correlation products across the integration period. At the end of each integration period the captured products are serialized to 8-bit words and streamed through the daisy chain to the output FIFO, where they can be consumed by the downstream control link running on ``out_clk``.

