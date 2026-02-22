.. title:: generic_fifo

**************************************************************************
:entity:`generic_fifo` (*generic_fifo.vhd*): Universal FIFO wrapper
**************************************************************************

.. parse:: hdl/common/generic_fifo.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: generic_fifo

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

Embedded FIFO: primitive selection (depth-first, FIFO18-first)
--------------------------------------------------------------

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

K7 and FWFT
-----------

On Kintex-7, the embedded synchronous FIFO primitive does not support
first-word-fall-through (FWFT) with zero latency. When ``IS_FWFT`` is
TRUE, the wrapper **forces** async mode (EN_SYN = FALSE) internally even when
``IS_ASYNC`` is FALSE, so that the same clock can be used on both
ports while the primitive runs in independent clock mode and delivers
zero-latency FWFT. A NOTE assertion reports this situation at elaboration.

Embedded FIFO: reset pipeline
-----------------------------

The embedded path uses a **unified reset pipeline** for both Kintex-7 and
Ultrascale+ (no platform-specific generate in the reset logic):

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

Width / depth vs resources (embedded)
-------------------------------------

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

XPM path (bram / distributed)
------------------------------

For ``MEMORY_TYPE`` = ``"bram"`` or ``"distributed"``, the wrapper
instantiates ``xpm_fifo_sync`` (when ``IS_ASYNC`` is ``FALSE``)
or ``xpm_fifo_async`` (when ``IS_ASYNC`` is ``TRUE``). Reset is synchronized to the
write clock and the XPM busy outputs are used for gating and for
``wr_rst_busy`` / ``rd_rst_busy``.
