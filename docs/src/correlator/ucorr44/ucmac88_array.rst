UCMAC88_ARRAY
=============

``UCMAC88_ARRAY`` is the version of ``UCMAC44_ARRAY`` for inputs with 8-bit components (-128 to 127). It is an
experiment for the ``crs_corr8`` build: all eight inputs are correlated with 8 bits, the products are exact (there is no
scaling and no rounding), and the sums are wider. ``UCORR44`` uses it when its generic ``SAMPLE_BITS`` is 16
(``UCORR44_ARRAY``: ``N_BITS_PER_BIN = 16``; ``chfpga``: the constant ``WIDE_CORR``).

The control logic, the two memory banks, the readout of one bin for each frame, the bin that is lost for the readout and
the daisy chain of the result bytes are those of ``UCMAC44_ARRAY``.

What limits the width of the sums
---------------------------------

Each sum is read and written one time for each frame, so each clock a correlator reads and writes all the sums of one
bin. One RAM gives 72 bits for each clock. Thus the number of RAMs sets the width of the sums. The module packs the
sums of its 36 products in RAM words of 72 bits with no unused bits. Each correlator has 2 RAM words in block RAM
(64 block RAMs for the 4 correlators), and the others are UltraRAMs, which UCAP also uses:

.. list-table::
   :header-rows: 1

   * - Cross-products
     - Autocorrelations
     - RAM words for each correlator
     - UltraRAMs of the correlator
     - UCAP buffers with memory
   * - 22 + 22 bits (the ``crs_corr8`` build)
     - 26 bits
     - 20
     - 72
     - 4 (UltraRAM)
   * - 24 + 24 bits
     - 30 bits
     - 22
     - 80
     - 0, or some in block RAM

The version with 24 + 24 bits was also built (``WIDE_CORR_CROSS_BITS``, ``WIDE_CORR_AUTO_BITS`` and
``WIDE_CORR_UCAP_BUFFERS`` in ``chfpga.vhd``, ``URAM_TOTAL``, and the LOC constraints). With UCAP buffers in block RAM
the block RAM of the device is 97 % used or more, and those builds did not complete the placement.

The text below gives the fields for 24 bits. With ``CROSS_BITS = 22``, ``IM_HIGH`` has 4 bits (-8 to 7) and ``RE``
has 22 bits; the result record has them sign-extended to 24 bits.

The cell
--------

Each CMAC has two DSP48E2, for `x = a + jb` and `y = c + jd`:

- ``dsp1``: `(a \cdot 2^{18} + b) \cdot c = ac \cdot 2^{18} + bc` (pre-adder and multiplier).
- ``dsp2``: `(b \cdot 2^{18} - a) \cdot d` + ``dsp1`` + the sum from the RAM.

Without the sum from the RAM, ``dsp2`` has `V = (ac + bd) \cdot 2^{18} + (bc - ad)`: one signed number with the
imaginary part of `x y^*` in its 18 LSBs and the real part above. ``dsp2`` accumulates `V` as one number. With
``s_axis_xy_swap``, the pre-adders compute `a \cdot 2^{18} - b` and `b \cdot 2^{18} + a`, and the imaginary part has the
opposite sign (`x^* y`).

The sum of a cross-product has three fields in the RAM:

.. list-table::
   :header-rows: 1

   * - Field
     - Bits
     - Contents
   * - ``IM_LOW``
     - 18
     - The 18 LSBs of the sum of `V`: the 18 LSBs of the sum of the imaginary parts.
   * - ``IM_HIGH``
     - 6, signed
     - The bits above of the sum of the imaginary parts. A counter: +1 when ``IM_LOW`` passes `2^{18}` upward, -1 when
       it passes 0 downward. The imaginary part of one product is less than `2^{16}`, so the two MSBs of ``IM_LOW``
       before and after the addition tell.
   * - ``RE``
     - 24, signed
     - Bits 41:18 of the sum of `V`: the sum of the real parts plus ``IM_HIGH`` (the carries and borrows of ``IM_LOW``
       go in it).

So the sum of the imaginary parts is ``IM_HIGH & IM_LOW``, and the sum of the real parts is ``RE - IM_HIGH``. The
readout computes this subtraction (one clock after it reads the RAM), so the result records have the two sums as
plain numbers.

Saturation:

- ``RE`` stays at its largest or smallest value when the sum passes it. A sum that is exactly at a limit is also taken
  as saturated.
- ``IM_HIGH`` stays at its largest value (31) or its smallest value (-32) when it gets there. The real part is then
  not valid, because the carries are no longer counted.
- An autocorrelation is not negative. Its sum is in bits 18 and above of ``dsp2``, and it stays at
  `2^{AUTO\_BITS} - 1`.

Result record
-------------

The 10-byte header, then for each product a little-endian word of `2 \cdot CROSS\_BITS + 2` bits in whole bytes: 6
bytes with ``CROSS_BITS = 22``.

.. list-table::
   :header-rows: 1

   * - Bits (``CROSS_BITS = 22``)
     - Cross-product
     - Autocorrelation
   * - 21:0
     - Sum of the imaginary parts, signed
     - Unsigned number of ``AUTO_BITS`` bits, in the LSBs (bits 25:0)
   * - 43:22
     - Sum of the real parts, signed (``RE - IM_HIGH``)
     - (the MSBs of the number, zeros)
   * - 44
     - The imaginary part is saturated
     - 0
   * - 45
     - The real part is saturated, or not valid because the imaginary part is saturated
     - The autocorrelation is saturated

A saturated part has the largest or the smallest value of its field. The two flags are in the same bits of the last
byte of a product as in the records of ``UCMAC44_ARRAY``. A record of 36 products has 226 bytes (190 bytes for the 4-bit
correlator, 197 with its wide cross-products).

Status byte 22 of ``UCORR44_ARRAY`` is 1 for this format. The first build of the (8+8)-bit correlator (23 Nov 2026) has
0 there: its records have ``RE`` in bits 47:24 and ``IM_HIGH & IM_LOW`` in bits 23:0, with no flags.

Parallel readout
----------------

With the daisy chain, correlator 0 sends all its records, then correlator 1, and so on. Each correlator reads one bin
for each frame, so the readout of 4 correlators of 2048 bins takes 8192 frames or more (one record for each frame:
353 Mbit/s with records of 226 bytes), and the integration period cannot be shorter.

With the generic ``PARALLEL_READOUT`` of ``UCORR44_ARRAY`` (``chfpga``: with ``WIDE_CORR``), all the correlators read
at the same time and a block in ``UCORR44_ARRAY`` takes one record from each correlator in turn:

- The block gives a grant pulse to one correlator when the output FIFO has space for a full record. It then passes
  the bytes of this correlator to the FIFO until the last byte of the record, and goes to the next correlator.
- The correlators are far from each other, so the grant and the data have two pipeline registers in each direction.
  A latch near each correlator makes its ``send`` level from the grant and clears it on the last byte of the record.
- Each correlator closes each record with TLAST (``BINS_PER_FRAME_LOG2 = 0``). The block makes the output frames
  of 8 records. A frame (one datagram) then has the records of all the correlators in turn: bin 0 of correlators 0
  to 3, then bin 1 of correlators 0 to 3.
- A record takes its number of bytes and approximately 8 clocks, so 4 records of 226 bytes take approximately 940 of
  the 2048 clocks of a frame. The readout takes 2048 frames if the output accepts 4 records for each frame
  (1.4 Gbit/s). If the output is slower, the output sets the time.
- Status byte 0, bit 4 of ``UCORR44_ARRAY`` is 1 with the parallel readout.

The records, their headers and the sums do not change.

Simulation
----------

See the testbenches ``ucmac88`` and ``ucorr88``.
