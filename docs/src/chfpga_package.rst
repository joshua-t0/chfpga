.. _chfpga-package:

.. title:: chfpga_package

**********************
chFPGA Package
**********************

.. parse:: hdl/chfpga_package.vhd

.. default-role:: code

The ``chFPGA_Package`` VHDL package (``hdl/chfpga_package.vhd``) is the central
repository for system-level enumerated types, constants, and lookup tables used
across all modules of the firmware.  Every entity that needs to know the platform
variant, FFT configuration, or corner-turn type reads its information from this
package rather than hard-coding values.

Enumerated types
================

Platform and FPGA family
------------------------

- **platform_type_enum** — Identifies the physical hardware platform (e.g.
  ``KC705``, ``ICEBOARD``, ``CRS``).  Passed as a generic to modules that need
  to select platform-specific primitives such as embedded FIFOs or transceiver
  IP.

- **fpga_series_enum** — Identifies the Xilinx device generation (``KINTEX7``,
  ``ULTRASCALE_PLUS``).  Used to choose the correct FIFO primitive generation
  (``FIFO18E1`` vs ``FIFO18E2``) via the ``PLATFORM_INFO`` lookup table.

- **PLATFORM_INFO** — Lookup table indexed by ``platform_type_enum`` that
  returns the ``fpga_series_enum`` for a given platform, plus other
  platform-level constants.

PHY and clock source types
--------------------------

- **phy_type_enum** — ``GMII`` or ``SGMII``; selects the MAC-side PHY
  technology.

- **bsb_interface_enum** — BSB transport: ``UDP_GMII``, ``UDP_SGMII``, or
  ``AXIS``.

- **phy_clk_source_enum**, **chan_clk_source_enum** — Selects the reference
  clock source for the channelizer MMCM.

- **clk_source_enum** — General clock-source selector.

Channelizer configuration types
--------------------------------

- **adc_type_enum** — ``EV8AQ160`` (differential SERDES) or ``AXIS``
  (AXI-Streaming).

- **fft_type_enum** — ``NONE``, ``CHIME``, ``D3A``, ``CHORD``, ``HIRAX``,
  ``HIRAX_3DSP``.  Indexes the ``FFT_INFO`` constant array.

- **FFT_INFO** — Lookup table that returns ADC width, FFT size, number of
  output bins, sample depth, and other derived parameters for each
  ``fft_type_enum`` value.

- **chan_capture_type_enum** — ``PROBER`` (internal BRAM) or ``UCAP``
  (external URAM capture bus).

- **CHAN_CAPTURE_INFO** — Lookup table that returns bus widths for each
  capture type.

Corner-turn and correlator types
---------------------------------

- **ct_type_enum** — ``NONE``, ``BCT`` (broadcast corner-turn), ``UCT``
  (unicast corner-turn).

- **CT_INFO** — Lookup table with number of corner-turn levels and bus widths
  for each ``ct_type_enum`` value.

- **ct_clk_source_enum** — ``BP_SHUFFLE_TXCLK``, ``ADC_CLK``,
  ``CGE_CLK322``, ``CORR_CLK``.

- **corr_type_enum** — ``CORR44``, ``UCORR44``, ``NONE``.

- **data_link_type_enum** — ``NONE``, ``XGE``, ``UPACK_CGE``.

Global constants
================

- **NUMBER_OF_CHANNELIZERS_MAX**, **NUMBER_OF_ADCS_MAX** — Maximum array
  sizes used to size generic arrays in platform top-levels.

- **NUMBER_OF_CORRELATORS_MAX**, **NUMBER_OF_CMACS_MAX** — Correlator array
  size limits.

- **GLOBAL_SIM** — When ``TRUE``, simulation-specific code paths are enabled
  across all modules.

- **GLOBAL_NUMBER_OF_GPU_LINKS** — Number of 10GbE links toward GPUs.

AXI-Stream ``tuser`` bit-field constants
=========================================

- **TUSER_ADC_OVERFLOW_BIT** — Bit index in ``tuser`` set by the ADC front
  end when saturation is detected on any sample of the frame.

- **TUSER_FFT_OVERFLOW_BIT** — Bit index in ``tuser`` set by the scaler when
  overflow is detected in the FFT output scaling path.

BSB command protocol constants
================================

- **CTRL_CMD_BYTE_LENGTH**, **CTRL_CMD_WORD_WIDTH** — Width of BSB command
  words in bytes and bits.

- **CTRL_CMD_OPCODE_WIDTH**, **CTRL_CMD_ADDR_WIDTH** — Field widths within a
  command word.
