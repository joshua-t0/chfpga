.. title:: ucorr44

************************************************************
:entity:`UCORR44` (*UCORR44.vhd*): (4+4) bit Correlator Core
************************************************************

.. parse:: hdl/corr/UCORR44.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: UCORR44

Parameters
----------

- **PLATFORM_TYPE:** FPGA platform type (``platform_type_enum``), used to instantiate the appropriate RAM primitives (default ``CRS``).
- **NCHAN:** Total number of antenna channels to correlate (default 64). Each channel is one 8-bit complex sample (4-bit real + 4-bit imaginary). The core computes ``NCHAN × (NCHAN+1) / 2`` unique products.
- **NCHAN_PER_CLK:** Number of channel samples delivered on each input clock cycle (default 32). Together with ``NCHAN``, determines the number of clocks per bin: ``NCHAN / NCHAN_PER_CLK``.
- **NBINS:** Number of frequency bins to be processed by this correlator before any decimation.
- **NDECIM:** Bin decimation factor. Only 1 out of every ``NDECIM`` consecutive bins is correlated; the others are skipped to free up computing cycles and reduce memory (default 1, no decimation).
- **CORR_NUMBER:** Integer index of this correlator, embedded in the output packet stream ID (default 0).
- **NCORR:** Total number of correlators in the parent array; used to format the stream ID field (default 1).
- **URAM_MAX:** Maximum number of UltraRAM blocks this core may use for its accumulator and capture memory (default 64).
- **READOUT_BIN:** Index of the frequency bin within each decimation block that is sacrificed to the readout cycle instead of being correlated (default 0).

Interface
---------

Data input
~~~~~~~~~~

- ``s_axis_tdata``: Array of ``NCHAN_PER_CLK`` 8-bit complex samples, with the 4-bit real part in the upper nibble. Samples must be delivered in channel order (channel 0 first) across ``NCHAN / NCHAN_PER_CLK`` consecutive clocks per bin.
- ``s_axis_tvalid``, ``s_axis_tlast``: Non-blocking AXI4-Stream valid and last flags. ``s_axis_tlast`` marks the last clock of the last bin in the input frame.

Run-time control
~~~~~~~~~~~~~~~~

- ``bin_set``: 4-bit value selecting which bin within each decimation block to process (0 to ``NDECIM``−1).
- ``auto_bin_set``: When ``'1'``, the bin selection cycles automatically through 0…``NDECIM``−1 at each integration period boundary.
- ``offset_encoding``: When ``'1'``, the input samples use offset-binary encoding; the core XORs each byte with ``0x88`` to convert to two's complement before correlation.
- ``integ_period``: 16-bit integration period in input frames. After this many frames, the accumulated products are captured and a new integration period begins.
- ``autocorr_only``: When ``'1'``, only auto-correlations (diagonal products) are computed, roughly halving the number of CMAC operations.
- ``no_accum``: When ``'1'``, the accumulator is bypassed; only the product from the most recent integration frame is retained (useful for debugging).
- ``corr_id``: 4-bit software-defined correlator identifier placed in the stream ID field of the output packet header.
- ``overrun``: Output flag asserted when a new integration period begins before the previous readout has completed.
- ``overrun_reset``: Pulse to clear the ``overrun`` flag.

Daisy-chain output (``z_out_*``)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- ``z_out_tdata``: 8-bit byte-serialized readout stream carrying this core's products followed by the forwarded upstream chain data.
- ``z_out_tlast``: Marks the final byte of the complete readout frame.
- ``z_out_tvalid``: Valid flag for the readout stream.
- ``z_out_send``: Lazy flow-control input from the downstream consumer. ``'1'`` allows the stream to flow.

Daisy-chain input (``z_in_*``)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- ``z_in_tdata``, ``z_in_tlast``, ``z_in_tvalid``: Readout stream from the next core in the daisy chain, forwarded on ``z_out_*`` once this core has finished transmitting its own data.
- ``z_in_send``: Lazy flow-control output toward the next core in the chain.

Clocks and reset
~~~~~~~~~~~~~~~~

- ``clk``: System clock. All logic is synchronous to this clock.
- ``rst``: Synchronous reset; clears all state and AXI-S valids.

Implementation details
----------------------

Architecture
~~~~~~~~~~~~

UCORR44 is the Ultrascale+ successor to :entity:`CORR44`. Instead of BRAM-based :entity:`CMAC44` cells requiring tight RPM placement constraints, it uses a :entity:`UCMAC44_ARRAY` backed by UltraRAM (or BRAM equivalents for smaller configurations) to store the accumulator and capture pages. This removes the dense relative-placement requirement and makes the design more portable across Ultrascale+ devices.

The core is divided into two main blocks:

- **Sequencer / input front-end** — Assembles the incoming ``NCHAN_PER_CLK``-wide input slices into full ``NCHAN``-wide snapshots, applies optional offset-binary-to-two's-complement conversion, selects the active decimation bin, and drives the rotating X/Y multiplexer that presents the correct sample pairs to each CMAC unit.
- **UCMAC44_ARRAY** — An array of ``NCMAC = NCHAN×(NCHAN+1)/2 / NCLK`` CMAC units that compute and accumulate all unique products. Results are serialized to 8-bit words and fed into the daisy-chain output.

Clocking
~~~~~~~~

All logic is synchronous to a single ``clk``. Clock-domain crossing to the output bus is handled in the parent :entity:`UCORR44_ARRAY` by a :entity:`generic_fifo` configured in asynchronous mode.

Principle of operations
~~~~~~~~~~~~~~~~~~~~~~~~

The front-end assembles ``NDECIM`` consecutive bin snapshots before presenting one selected bin snapshot to the correlator. This gives the correlator ``NDECIM × NCLK_PER_BIN`` clock cycles to compute all ``NCMAC × NCLK`` products, effectively reducing the required number of CMAC units by a factor of ``NDECIM``.

The X and Y sample vectors are loaded from the assembled snapshot and then rotated by ``NCOL_PER_CLK`` positions on each clock of the ``NCLK``-cycle computation window, ensuring that every column of the lower-triangular product matrix is covered. The optional ``autocorr_only`` mode stops after the diagonal products and skips the cross-correlation rotation logic.

After ``integ_period`` frames, the accumulated products are captured and the UCMAC44_ARRAY begins streaming them out in 8-bit words on the daisy-chain bus. The lazy ``send`` / ``z_in_send`` flow-control signals propagate between successive cores in the chain, with the latency absorbed by the elastic output FIFO in the parent array.

