.. title:: LFSR

***********************************************************
:entity:`lfsr` (*lfsr.vhd*): Linear Feedback Shift Register
***********************************************************

.. default-role:: entity

Overview
========

The `LFSR` module implements a Linear Feedback Shift Register (LFSR) pseudo-random number generator. It is used in the :entity:`funcgen` module as a noise generator to produce pseudo-random test patterns. The LFSR generates a configurable number of output bits per clock cycle, making it suitable for high-throughput applications.

Entity documentation
====================

.. parse:: hdl/chan/lfsr.vhd

.. autoentity:: lfsr

Principle of Operations
=======================

The `LFSR` implements a maximum-length linear feedback shift register that generates pseudo-random sequences. The operation is based on a polynomial defined by the tap positions specified in the ``TAPS`` generic parameter.

Shift Register Structure
------------------------

The shift register has a width determined by ``SHIFT_REG_WIDTH``, which is automatically calculated as the maximum value in the ``TAPS`` array. The default configuration uses taps at positions 32, 30, 26, and 25 (1-based indexing), resulting in a 32-bit shift register. The register uses a left-to-right indexing scheme (0 to SHIFT_REG_WIDTH - 1), where position 0 is the leftmost (newest) bit and position SHIFT_REG_WIDTH - 1 is the rightmost (oldest) bit.

Per-Cycle Operation
-------------------

On each rising edge of the clock, the LFSR generates ``DATA_WIDTH`` bits of output in a single cycle:

1. **Feedback Calculation**: For each output bit to be generated, the module computes the feedback value by XORing all the bits at the tap positions in the current register state. The tap positions are specified as 1-based indices, so they are converted to 0-based by subtracting 1.

2. **Shift Operation**: The register is shifted left by one position:
   - The feedback bit (result of the XOR operation) is inserted at position 0 (leftmost)
   - All existing bits shift right by one position
   - The bit at position SHIFT_REG_WIDTH - 1 (rightmost) becomes the output bit

3. **Output Generation**: This process repeats ``DATA_WIDTH`` times within a single clock cycle, with each iteration producing one output bit. The output bits are assigned in descending order (MSB to LSB).

4. **Register Update**: After all output bits have been generated, the final register state is saved back to the internal register signal.

Reset Behavior
--------------

When the ``rst`` signal is asserted, the module:
- Clears all output bits to zero
- Loads the shift register with the ``seed`` value provided on the input port

The reset is synchronous to the clock and takes effect on the rising edge when ``rst`` is high.

Polynomial Selection
--------------------

The LFSR polynomial is defined by the tap positions in the ``TAPS`` generic. The default taps (32, 30, 26, 25) correspond to a maximum-length polynomial for a 32-bit LFSR, which will cycle through 2^32 - 1 states before repeating (excluding the all-zeros state). The tap positions use 1-based indexing as referenced from standard LFSR polynomial tables.

Usage in FUNCGEN
----------------

In the :entity:`funcgen` module, the LFSR is instantiated with:
- ``DATA_WIDTH`` set to ``ADC_SAMPLES_PER_WORD * ADC_BITS_PER_SAMPLE`` to generate a full word of pseudo-random data per clock cycle
- A seed constructed from control register bytes A and B: ``(byte_a & byte_b & not byte_a & not byte_b)``

This seed construction guarantees a non-zero seed value, ensuring the LFSR will produce a valid pseudo-random sequence. The same seed values will always produce the same sequence, making the output deterministic and repeatable for testing purposes.

