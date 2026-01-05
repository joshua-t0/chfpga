.. title:: scaler_mul

******************************************************************
:entity:`scaler_mul` (*scaler_mul.vhd*): Scaler Multiplier
******************************************************************

.. parse:: hdl/chan/scaler_mul.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: scaler_mul

Principle of operations
=======================

The `SCALER_MUL` module implements a signed multiplier using Xilinx DSP48E1 primitives (there are no special optimizations for the DSP48E2; the tools just remap the DSP48E1 to a DSP48E2). It computes the product P = A × B where:

- **A**: Signed operand up to 42 bits wide
- **B**: Unsigned operand up to 17 bits wide  
- **P**: Signed product with width A_WIDTH + B_WIDTH

The module automatically selects between single-stage and two-stage implementations based on the width of operand A:

- **Single-stage (A_WIDTH ≤ 25)**: Uses one DSP48E1 primitive
- **Two-stage (A_WIDTH > 25)**: Uses two cascaded DSP48E1 primitives to handle wider operands

Latency
-------

The multiplier has a fixed latency of **3 clock cycles** regardless of the number of stages:

- **Clock 1**: Inputs are registered in DSP1 input registers (AREG, BREG). BCOUT cascades to DSP2 if two-stage.
- **Clock 2**: 
  - DSP1 multiplier output is registered in MREG
  - For two-stage: DSP2 receives upper A bits and B via BCIN, computes partial product
- **Clock 3**: 
  - Single-stage: Full product is registered in DSP1 PREG and appears on output
  - Two-stage: Lower partial product from DSP1 is registered in fabric registers, upper partial product from DSP2 is registered in DSP2 PREG

Two-Stage Implementation Details
---------------------------------

When A_WIDTH > 25, the multiplier splits the operation:

1. **DSP1**: Computes the product of the lower 17 bits of A with B
   - Lower partial product appears on P output (no PREG register)
   - BCOUT provides B operand to DSP2 via cascade

2. **DSP2**: Computes the product of the upper bits of A with B, and adds the shifted lower partial product
   - Uses BCIN to receive B from DSP1 BCOUT (avoids fabric routing)
   - Uses PCIN to receive the lower partial product from DSP1 PCOUT, shifted right by 17 bits
   - Upper partial product is registered in PREG

The final product is assembled by concatenating the upper bits from DSP2 with the lower bits from DSP1.

Usage in SCALER
----------------

The `SCALER_MUL` module is instantiated by the :entity:`scaler` module to multiply FFT output data with gain coefficients. Multiple instances are used in parallel to process all frequency bins in a word simultaneously.
