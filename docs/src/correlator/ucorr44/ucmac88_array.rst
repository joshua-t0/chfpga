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
bin. One RAM gives 72 bits for each clock. The device has 80 UltraRAMs, and the correlator had 64 block RAMs (8 more
RAM words). That is 22 RAM words of 72 bits for each of the 4 correlators: 1584 bits for 36 products. The module packs
the sums with no unused bits:

.. list-table::
   :header-rows: 1

   * - Product
     - Number
     - Bits
     - Total
   * - Cross-product
     - 28
     - 24 + 24
     - 1344
   * - Autocorrelation
     - 8
     - 30
     - 240

The correlator thus uses all the UltraRAMs. UCAP has none: see ``BUFFERS_WITH_MEMORY`` of ``ucap``.

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

So the sum of the imaginary parts is ``IM_HIGH & IM_LOW`` (a signed 24-bit number), and the sum of the real parts is
``RE - IM_HIGH``. The host computes this subtraction.

Saturation:

- ``RE`` stays at its largest or smallest value when the sum passes it. A sum that is exactly at a limit is also taken
  as saturated.
- ``IM_HIGH`` stays at its largest value (31) or its smallest value (-32) when it gets there. The real part is then
  not valid, because the carries are no longer counted.
- An autocorrelation is not negative. Its sum is in bits 18 and above of ``dsp2``, and it stays at `2^{30} - 1`.

Result record
-------------

The 10-byte header, then 6 bytes for each product (a little-endian 48-bit word). There are no flag bits: the host finds
a saturation from the values.

.. list-table::
   :header-rows: 1

   * - Product
     - Bits 47:24
     - Bits 23:0
   * - Cross-product
     - ``RE``, signed
     - ``IM_HIGH & IM_LOW``, signed
   * - Autocorrelation
     - 0 (bits 47:30)
     - Unsigned number in bits 29:0

A record of 36 products has 226 bytes (190 bytes for the 4-bit correlator, 197 with its wide cross-products).

Simulation
----------

See the testbenches ``ucmac88`` and ``ucorr88``.
