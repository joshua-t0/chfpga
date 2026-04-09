.. title:: generic_fifo

**************************************************************************
:entity:`generic_fifo` (*generic_fifo.vhd*): Universal FIFO wrapper
**************************************************************************

.. parse:: hdl/utils/generic_fifo.vhd

.. default-role:: vhdl:entity

Entity documentation
====================

.. autoentity:: generic_fifo

Parameters
==========

- **FPGA_SERIES:** FPGA family, defined as an enumerated type in :doc:`/chfpga_package`. Selects
  the correct embedded FIFO primitive generation (FIFO18E1/FIFO36E1 for Kintex-7;
  FIFO18E2/FIFO36E2 for Ultrascale+). Ignored for ``"bram"`` and ``"distributed"``
  memory types.

- **MEMORY_TYPE:** Implementation to use. ``"embedded"`` uses platform-specific hard FIFO
  primitives; ``"bram"`` uses the Xilinx XPM FIFO macro with block RAM; ``"distributed"``
  uses the XPM FIFO macro with distributed RAM.

- **IS_ASYNC:** When ``TRUE``, the FIFO is asynchronous (dual-clock): connect ``wr_clk`` and
  ``rd_clk``. When ``FALSE``, the FIFO is synchronous (single-clock): connect ``clk`` only.

- **IS_FWFT:** When ``TRUE``, first-word fall-through mode: the first word written appears on
  ``dout`` without a read cycle. When ``FALSE``, standard (registered-output) mode.

- **DATA_WIDTH:** Data width in bits. For the ``"embedded"`` type, parallel FIFO primitives are
  used automatically when the width exceeds one primitive's capacity.

- **DEPTH:** FIFO depth in words. Defaults to the largest power-of-two depth that fits in a
  single FIFO18 at the given ``DATA_WIDTH``. For ``"embedded"`` type, must equal a supported
  primitive depth (512, 1024, 2048, 4096, 8192).

- **PROG_FULL_THRESH_OFFSET:** Offset below ``DEPTH`` at which ``prog_full`` asserts (default
  **10**). Overridden by ``PROG_FULL_THRESH``.

- **PROG_FULL_THRESH:** Absolute word count at or above which ``prog_full`` asserts. Defaults
  to ``DEPTH − PROG_FULL_THRESH_OFFSET``.

- **PROG_EMPTY_THRESH_OFFSET:** Word count at or below which ``prog_empty`` asserts (default
  **10**). Overridden by ``PROG_EMPTY_THRESH``.

- **PROG_EMPTY_THRESH:** Absolute word count at or below which ``prog_empty`` asserts. Defaults
  to ``PROG_EMPTY_THRESH_OFFSET``.

Interface
=========

Write side
----------

- ``clk``: Single clock for synchronous FIFOs (``IS_ASYNC = FALSE``). Leave unconnected for
  asynchronous FIFOs (defaults to ``'0'``).

- ``wr_clk``: Write clock for asynchronous FIFOs (``IS_ASYNC = TRUE``). Leave unconnected for
  synchronous FIFOs.

- ``wr_en``: Write enable. Gated internally during reset; a write attempted while the FIFO
  is full is silently ignored (the ``overflow`` flag is set instead).

- ``din``: Write data input (``DATA_WIDTH`` bits wide).

- ``full``: Asserts when the FIFO cannot accept another write.

- ``prog_full``: Programmable almost-full flag, controlled by ``PROG_FULL_THRESH``.

- ``overflow``: Asserts for one cycle when a write is attempted while the FIFO is full.

- ``wr_rst_busy``: Write-domain reset busy. Asserts from the beginning of reset until the
  write domain has completed its reset sequence. Gate ``wr_en`` on this signal if needed.

Read side
---------

- ``rd_clk``: Read clock for asynchronous FIFOs (``IS_ASYNC = TRUE``). Leave unconnected for
  synchronous FIFOs.

- ``rd_en``: Read enable. Gated internally during reset.

- ``dout``: Read data output (``DATA_WIDTH`` bits wide). In FWFT mode, valid data appears
  without a read cycle; in standard mode, a read cycle is required first.

- ``empty``: Asserts when no data is available to read.

- ``prog_empty``: Programmable almost-empty flag, controlled by ``PROG_EMPTY_THRESH``.

- ``valid``: Data-valid qualifier. In FWFT mode, equivalent to ``not empty``. Undefined in
  standard mode for embedded FIFOs.

- ``rd_rst_busy``: Read-domain reset busy. Asserts until the read domain has completed its
  reset sequence.

Reset
-----

- ``rst``: Asynchronous reset (active high). Internally synchronized to each clock domain
  using ``xpm_cdc_async_rst``. Both ``wr_en`` and ``rd_en`` are gated off during reset.
  Monitor ``wr_rst_busy`` / ``rd_rst_busy`` before accessing the FIFO after reset.

Overview
========

`generic_fifo` is a universal FIFO that selects the implementation from the
``MEMORY_TYPE`` generic:

- **embedded** — Platform-specific FIFO18/FIFO36 primitives (Kintex-7: FIFO18E1/FIFO36E1, Ultrascale+: FIFO18E2/FIFO36E2)
- **bram** — XPM FIFO macro (``xpm_fifo_sync`` or ``xpm_fifo_async``)
- **distributed** — XPM FIFO macro with distributed RAM

For embedded FIFOs, the wrapper automatically chooses FIFO18 vs FIFO36 and
instantiates multiple primitives in parallel when ``DATA_WIDTH`` or
``DEPTH`` exceed a single primitive's capacity (following the pattern
used in ``prober``).

Default depth
-------------

When not overridden, ``DEPTH`` defaults to the largest power-of-2 word
depth that fits in a single FIFO18 (18 Kbit). The computation is:

1. **Total bits:** :math:`18 \times 1024 = 18\,432` bits (full FIFO18 capacity).
2. **Max words:** :math:`18\,432 / \texttt{DATA\_WIDTH}` (integer division in VHDL).
3. **Log2 (floor):** ``integer_log2`` from ``chfpga_package``
   returns :math:`\lfloor \log_2(\ldots) \rfloor`.
4. **Power of 2:** :math:`2^{\lfloor \log_2(18 \times 1024 / \texttt{DATA\_WIDTH}) \rfloor}`.

So the default is :math:`2^{\texttt{integer\_log2}(18 \times 1024 / \texttt{DATA\_WIDTH})}`.
This uses the full 18 Kb and yields one of the supported primitive depths
(512, 1024, 2048, 4096, 8192, 16384) depending on ``DATA_WIDTH``. For
common embedded widths the result is: 4→4096, 8–9→2048, 10–18→1024, 19–36→512.

Programmable full/empty thresholds
----------------------------------

``PROG_FULL_THRESH_OFFSET`` (default **10**) is the offset below
``DEPTH`` at which ``prog_full`` asserts: the effective
threshold is ``DEPTH`` − ``PROG_FULL_THRESH_OFFSET`` unless
``PROG_FULL_THRESH`` is set explicitly. ``PROG_EMPTY_THRESH_OFFSET``
(default **10**) is the word count at or below which ``prog_empty``
asserts; it is used as the default for ``PROG_EMPTY_THRESH`` unless
that generic is overridden.

Clocks
------

- **Synchronous (IS_ASYNC = FALSE):** Connect the single ``clk`` port;
  it drives both write and read clock domains internally. Leave ``wr_clk``
  and ``rd_clk`` unconnected (defaults apply).
- **Asynchronous (IS_ASYNC = TRUE):** Connect ``wr_clk`` and
  ``rd_clk``. Leave ``clk`` unconnected.

Reset contract
--------------

The ``rst`` input is treated as **asynchronous**. The wrapper:

- Synchronizes it with ``xpm_cdc_async_rst`` into each clock domain
- Gates ``wr_en`` and ``rd_en`` internally during reset
- Exposes ``wr_rst_busy`` and ``rd_rst_busy`` so the user can
  wait until each domain has completed its reset sequence before using the FIFO

Detailed description
====================

Embedded FIFO
-------------

Primitive selection (depth-first, FIFO18-first)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

For ``MEMORY_TYPE`` = ``"embedded"``, the wrapper uses a **depth-first,
FIFO18-first** algorithm to minimize BRAM usage:

1. **Try FIFO18 first.** The logic scans primitive modes from narrowest (4-bit)
   to widest (36-bit). It picks the **narrowest** FIFO18 mode for which
   total width ≥ ``DATA_WIDTH`` and FIFO18 depth ≥ ``DEPTH``.
   If such a mode exists, a single FIFO18 is used (one BRAM18).

2. **Fall back to FIFO36.** If no FIFO18 mode fits, the logic picks the
   **widest** FIFO36 mode with depth ≥ ``DEPTH``, then computes
   :math:`n = \lceil \texttt{DATA\_WIDTH} / \texttt{prim\_width} \rceil`
   and instantiates :math:`n` parallel FIFO36 primitives.

Supported primitive depths are 512, 1024, 2048, 4096, 8192 words. ``DEPTH``
must equal one of these.

Kintex-7 and FWFT
^^^^^^^^^^^^^^^^^

On Kintex-7, the embedded synchronous FIFO primitive does not support
first-word-fall-through (FWFT) with zero latency. When ``IS_FWFT`` is
TRUE, the wrapper **forces** async mode (EN_SYN = FALSE) internally even when
``IS_ASYNC`` is FALSE, so that the same clock can be used on both
ports while the primitive runs in independent clock mode and delivers
zero-latency FWFT. A NOTE assertion reports this situation at elaboration.

Resets
^^^^^^
Embedded FIFO resets differ significantly between Kintex-7 and Ultrascale+.
- Kintex-7: The reset is asynchronous and is internally synchronized::

    A reset synchronizer circuit has been introduced to 7 series FPGAs. RST
    must be asserted for five cycles to reset all read and write address
    counters and initialize flags after power-up. RST does not clear the
    memory, nor does it clear the output register. When RST is asserted High,
    EMPTY and ALMOSTEMPTY are set to 1, FULL and ALMOSTFULL are reset to 0.
    The RST signal must be High for at least five read clock and write clock
    cycles to ensure all internal states are reset to correct values. During
    Reset, both RDEN and WREN must be deasserted (held Low).


- Ultrascale+: The reset line must be synchronous to the wr_clk::

   The reset spec and implementation has been changed completely compared to 7 series FIFOs. RST is synchronous to WRCLK. To assert RST, it must be asserted for one setup time prior to the rising edge of WRCLK. RST has an optional inversion at the input.

   If RST is asserted, the WRRSTBUSY output asserts immediately after the rising edge of WRCLK, and remains asserted until the reset operation is complete. Following the assertion of WRRSTBUSY, the internal reset is synchronized to the RDCLK domain. Upon arrival in the RDCLK domain, the RDRSTBUSY is asserted, and is held asserted until the resetting of all RDCLK domain signals is complete, then RDRSTBUSY is deasserted. In common-clock Mode, this logic is simplified because the clock domain crossing is not required.

The embedded path uses a **unified reset pipeline** for both Kintex-7 and
Ultrascale+:

1. Asynchronous ``rst`` is synchronized to the write clock with
   ``xpm_cdc_async_rst`` → short pulse ``wr_rst_cdc``.
2. A 6-bit counter extends that pulse to **64 write-clock cycles** → ``wr_rst_hold``
   (conservative for both families).
3. For async FIFOs, ``wr_rst_hold`` is synchronized to the read clock with
   another ``xpm_cdc_async_rst`` → ``rd_rst_hold``. For sync FIFOs,
   ``rd_rst_hold`` is tied to ``wr_rst_hold``.
4. On K7, primitives have no WRRSTBUSY/RDRSTBUSY outputs; the wrapper drives
   synthetic busy signals from ``wr_rst_hold`` / ``rd_rst_hold``. On Ultrascale+,
   primitive WRRSTBUSY/RDRSTBUSY are used. The same gating and busy formulas
   apply on both platforms (when/else selects synthetic vs real busy).
5. All primitives receive RST = ``wr_rst_hold``. Write and read enables are
   gated with ``wr_rst_cdc or or(prim_wr_rst_busy)`` and ``or(prim_rd_rst_busy)``
   respectively; ``wr_rst_busy`` and ``rd_rst_busy`` are derived from the same
   expressions.


On 7-series devices, the RST pin of the FIFO18E1/FIFO36E1 primitives directly drive the reset synchronizer circuit and is subject to the
primitive's recovery/removal timing checks. Those checks can be noticeably
tighter than ordinary synchronous timing paths. In blocks with difficult placement constraints, especially I/O-driven ones such
as ``ADCDAQ``, this can become the dominant timing problem even when the
launching reset logic is placed physically close to the FIFO. The issue is not
usually LUT depth; it is the combination of a hard primitive reset arc and a
route constrained by surrounding clocking and I/O resources.


However, since the 7-series have a synchronizer,  wecan safely treat the primitive reset as a
functionally asynchronous control path, provided the reset pulse is long enough and there are no reads or writes
during reset. We can therefore apply a false-path constraint on the internal built-in FIFO reset network to the RST pin. This is also what the legacy Xilinx FIFO Generator IP does for "built-in" async FIFOs. 

In order to facilitate constraining the RST ping on Kintex-7 embeded FIFOs instantiated by  ``generic_fifo``, its primitive instances are marked with a custom ``RST_FALSE_PATH=TRUE`` attribute.
Vivado preserves that attribute as a cell property after synthesis, so the XDC
can directly select the marked FIFO primitive cells and apply the exception to
their ``RST`` pins. Note that this attribute is not set for Ultrascale+ embeded FIFOs.

A false path constraint can therefore be added for the whole design with simply::
   
.. code-block:: tcl

    set_false_path -to [get_pins -of_objects [get_cells -hier -filter {RST_FALSE_PATH == "TRUE"}] -filter {REF_PIN_NAME == RST}]





Width / depth vs resources (embedded)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The following table summarizes representative ``DATA_WIDTH`` /
``DEPTH`` combinations and the resulting primitive configuration and
BRAM usage for the **embedded** implementation.

+------------------+-----------+---------------------------+------------------+
| DATA_WIDTH       | DEPTH     | Configuration             | Resources        |
+==================+===========+===========================+==================+
| 4                | 4096      | 1× FIFO18 (4-bit mode)    | 1 BRAM18         |
+------------------+-----------+---------------------------+------------------+
| 4                | 8192      | 1× FIFO36 (4-bit mode)    | 1 BRAM36         |
+------------------+-----------+---------------------------+------------------+
| 9                | 512       | 1× FIFO18 (9-bit mode)    | 1 BRAM18         |
+------------------+-----------+---------------------------+------------------+
| 33               | 512       | 1× FIFO18 (36-bit mode)   | 1 BRAM18         |
+------------------+-----------+---------------------------+------------------+
| 35               | 512       | 1× FIFO18 (36-bit mode)   | 1 BRAM18         |
+------------------+-----------+---------------------------+------------------+
| 36               | 512       | 1× FIFO18 (36-bit mode)   | 1 BRAM18         |
+------------------+-----------+---------------------------+------------------+
| 37               | 512       | 1× FIFO36 (72-bit mode)    | 1 BRAM36        |
+------------------+-----------+---------------------------+------------------+
| 72               | 512       | 1× FIFO36 (72-bit mode)   | 1 BRAM36         |
+------------------+-----------+---------------------------+------------------+
| 33               | 2048      | 2× FIFO36 (18-bit mode)   | 2 BRAM36         |
+------------------+-----------+---------------------------+------------------+
| 36               | 2048      | 2× FIFO36 (18-bit mode)   | 2 BRAM36         |
+------------------+-----------+---------------------------+------------------+
| 72               | 2048      | 4× FIFO36 (18-bit mode)   | 4 BRAM36         |
+------------------+-----------+---------------------------+------------------+

For widths ≤ 36 bits and depth ≤ 512, a single FIFO18 is used when possible to
save resources. For depth > 512 or width > 36, FIFO36 primitives are used,
with parallel instances when the data width exceeds one primitive's width.

BRAM FIFO
---------

Implementation
^^^^^^^^^^^^^^

For ``MEMORY_TYPE`` = ``"bram"``, the wrapper instantiates ``xpm_fifo_sync``
when ``IS_ASYNC`` is ``FALSE`` and ``xpm_fifo_async`` when ``IS_ASYNC`` is
``TRUE``. The XPM FIFO is configured with block RAM storage and uses the same
generic FIFO interface as the other implementations.

Reset behavior
^^^^^^^^^^^^^^

The asynchronous ``rst`` input is first synchronized to the write clock, then
fed into the XPM FIFO. The wrapper uses the XPM ``wr_rst_busy`` /
``rd_rst_busy`` outputs to gate access during reset and release.

Unlike the ``embedded`` implementation, the ``bram`` path does not expose the
same hard embedded FIFO primitive reset arc directly. In practice, this avoids
the specific recovery/removal timing issue seen with ``FIFO18E1`` / ``FIFO36E1``
in placement-constrained blocks such as ``ADCDAQ``. This is why ``bram`` is the
preferred choice there, even if the embedded implementation can be more
resource-efficient in simpler parts of the design.

Distributed FIFO
----------------

Implementation
^^^^^^^^^^^^^^

For ``MEMORY_TYPE`` = ``"distributed"``, the wrapper uses the same XPM FIFO
path as ``"bram"``, but requests distributed RAM storage instead of block RAM.
This is generally most appropriate for relatively small FIFOs where saving BRAM
matters more than maximizing depth.

Reset behavior
^^^^^^^^^^^^^^

The reset handling is the same XPM-based scheme used by the ``bram``
implementation: reset is synchronized to the write clock, and the XPM busy
outputs are used to gate accesses safely during reset.

Because this path does not expose the hard embedded FIFO primitive reset arc in
the same way as ``MEMORY_TYPE = "embedded"``, it does not have the same reset
timing sensitivity described above. The main reason to avoid ``distributed`` is
usually capacity or resource trade-offs, not the embedded FIFO reset-timing
problem.

XPM path summary (bram / distributed)
-------------------------------------

For ``MEMORY_TYPE`` = ``"bram"`` or ``"distributed"``, the wrapper
instantiates ``xpm_fifo_sync`` (when ``IS_ASYNC`` is ``FALSE``)
or ``xpm_fifo_async`` (when ``IS_ASYNC`` is ``TRUE``). Reset is synchronized to the
write clock and the XPM busy outputs are used for gating and for
``wr_rst_busy`` / ``rd_rst_busy``.

Implementation details
======================

Principle of operations
-----------------------

``generic_fifo`` selects between three storage implementations at elaboration time via the ``MEMORY_TYPE`` generic. For ``"embedded"``, a depth-first, FIFO18-first algorithm determines the narrowest fitting Kintex-7 or Ultrascale+ primitive (FIFO18E1/E2 or FIFO36E1/E2) and instantiates parallel primitives when the data width exceeds one primitive's capacity; a unified reset pipeline using ``xpm_cdc_async_rst`` handles the differing reset requirements between device families. For ``"bram"`` and ``"distributed"``, the Xilinx XPM ``xpm_fifo_sync`` / ``xpm_fifo_async`` macros are instantiated directly, with reset synchronized to the write clock and accesses gated by the XPM busy outputs.

Clocking
--------

Synchronous mode (``IS_ASYNC = FALSE``) uses the single ``clk`` port for both write and read. Asynchronous mode (``IS_ASYNC = TRUE``) uses separate ``wr_clk`` and ``rd_clk`` ports. The ``rst`` input is treated as asynchronous and is synchronized into each clock domain internally by ``xpm_cdc_async_rst``; both ``wr_en`` and ``rd_en`` are gated off during reset in all modes.
