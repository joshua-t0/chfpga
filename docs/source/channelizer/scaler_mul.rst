.. title:: scaler_mul

**********************************************************
:entity:`scaler_mul` (*scaler_mul.vhd*): Scaler Multiplier
**********************************************************

.. parse:: hdl/chan/scaler_mul.vhd

.. default-role:: vhdl:entity

Entity documentation
====================

.. autoentity:: scaler_mul

Parameters
==========

- **A_WIDTH:** Bit width of signed multiplicand ``a``. Must be ≤ 42. When ``A_WIDTH > 25``, two cascaded DSP48E1 primitives are used automatically. Default is 18.
- **B_WIDTH:** Bit width of unsigned multiplier ``b``. Must be ≤ 17. Default is 16.
- **P_WIDTH:** Bit width of the signed product output ``p``. Defaults to ``A_WIDTH + B_WIDTH``.

Interface
=========

- ``a``: Signed multiplicand, up to 42 bits wide.
- ``b``: Unsigned multiplier, up to 17 bits wide.
- ``p``: Signed product of width ``P_WIDTH``, available 3 clock cycles after the inputs are presented.
- ``clk``: Clock. The module has a fixed pipeline latency of 3 clock cycles regardless of the number of DSP stages.

Implementation details
======================

Principle of operations
-----------------------

The `SCALER_MUL` module implements a signed × unsigned multiplier using Xilinx DSP48E1 primitives (the tools transparently remap these to DSP48E2 on Ultrascale+). It computes P = A × B where A is a signed operand up to 42 bits wide and B is an unsigned operand up to 17 bits wide. When ``A_WIDTH`` ≤ 25 a single DSP48E1 suffices; for wider A operands two cascaded DSP48E1s are used, with B routed through the cascade bus (BCOUT→BCIN) to avoid fabric routing. The pipeline has a fixed latency of **3 clock cycles** regardless of whether one or two DSP stages are used.

Latency
~~~~~~~

- **Clock 1**: Inputs registered in DSP1 input registers (AREG, BREG). BCOUT cascades to DSP2 if two-stage.
- **Clock 2**: DSP1 multiplier output registered in MREG; for two-stage, DSP2 computes the upper partial product via BCIN.
- **Clock 3**: Single-stage — full product registered in DSP1 PREG. Two-stage — lower partial product registered in fabric, upper partial product registered in DSP2 PREG; concatenated to form the final output.

Two-stage implementation
~~~~~~~~~~~~~~~~~~~~~~~~

When ``A_WIDTH > 25``, the multiplier splits the operation:

1. **DSP1**: Computes the product of the lower 17 bits of A with B. Lower partial product appears on P output (no PREG register). BCOUT provides B operand to DSP2 via cascade.

2. **DSP2**: Computes the product of the upper bits of A with B, adding the shifted lower partial product via PCIN. Upper partial product is registered in PREG.

The final product is assembled by concatenating the upper bits from DSP2 with the lower bits from DSP1.

Usage in SCALER
~~~~~~~~~~~~~~~

The `SCALER_MUL` module is instantiated by the :entity:`scaler` module to multiply FFT output data with gain coefficients. Multiple instances are used in parallel to process all frequency bins in a word simultaneously.
