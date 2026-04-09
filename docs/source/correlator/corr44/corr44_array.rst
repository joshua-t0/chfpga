.. title:: corr44_array

***********************************************************************
:entity:`CORR44_ARRAY` (*CORR44_ARRAY.vhd*): (4+4) bit Correlator Array
***********************************************************************

.. parse:: hdl/corr/CORR44_ARRAY.vhd

Entity documentation
--------------------

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: CORR44_ARRAY

Parameters
----------

- **PLATFORM_TYPE:** FPGA platform type, defined as a ``platform_type_enum`` in :doc:`../../chfpga_package`. Passed down to each :entity:`CORR44` instance to select the correct hard-macro primitives and RPM layouts.
- **NUMBER_OF_CORRELATORS:** Number of independent :entity:`CORR44` correlator cores instantiated in the array. Each core receives its own input data stream and produces its own integrated-product output stream.
- **NUMBER_OF_WORDS_PER_BIN:** Number of 32-bit input words per frequency bin, which also equals the number of input clocks per bin. There are 4 complex samples per 32-bit word, so the total samples per bin is ``4 × NUMBER_OF_WORDS_PER_BIN``.

Interface
---------

Data input
~~~~~~~~~~

- ``s_axis_tdata``: Array of ``NUMBER_OF_CORRELATORS`` 32-bit input data streams, each carrying four (4+4)-bit signed complex samples per word. Frames start with header words followed by per-bin data.
- ``s_axis_tvalid``, ``s_axis_tlast``: Per-correlator AXI4-Stream valid and last flags.
- ``in_clk``: Clock for the input data streams and the correlator array logic.
- ``in_rst``: Synchronous reset for the input-clock domain.

Data output
~~~~~~~~~~~

- ``m_axis_data_out_tdata``: Array of ``NUMBER_OF_CORRELATORS`` 8-bit AXI4-Stream outputs, each carrying byte-serialized integrated-product frames (header + 5 bytes per (18+18)-bit product).
- ``m_axis_data_out_tvalid``, ``m_axis_data_out_tlast``, ``m_axis_data_out_tready``: Per-correlator AXI4-Stream handshake signals.
- ``out_clk``: Clock for the integrated-product output streams (may differ from ``in_clk``).
- ``out_rst``: Synchronous reset for the output-clock domain.

Control (BSB)
~~~~~~~~~~~~~

- ``s_axis_bsb_tdata/tvalid/tlast/tready``: Byte-stream bus (BSB) control command input, routed by an internal :entity:`bsb_router` to the appropriate correlator core.
- ``m_axis_bsb_tdata/tvalid/tlast/tready``: BSB reply stream from the addressed correlator.
- ``bsb_clk``: Clock for the BSB control interface.
- ``bsb_rst``: Reset for the BSB control interface.

Implementation details
----------------------

Architecture
~~~~~~~~~~~~

The array instantiates ``NUMBER_OF_CORRELATORS`` copies of :entity:`CORR44` and one :entity:`bsb_router`. Input data and reset signals are registered before being fanned out to the correlators to ease timing closure. The BSB router decodes the correlator address from each incoming command and forwards it to the correct :entity:`CORR44` instance; replies are multiplexed back.

Clocking
~~~~~~~~

The array operates with two clocks: ``in_clk`` for data ingestion and correlation, and ``out_clk`` for integrated-product readout. Clock-domain crossing is handled inside each :entity:`CORR44` instance by an asynchronous FIFO.

Principle of operations
~~~~~~~~~~~~~~~~~~~~~~~~

Each :entity:`CORR44` core independently receives its own slice of the antenna-channelizer output, computes all N²/2 cross-correlation products (where N = ``4 × NUMBER_OF_WORDS_PER_BIN``), integrates them over a programmable number of frames, and periodically streams the accumulated products on its dedicated output port. The BSB control bus is broadcast to all cores and replies are routed back through the BSB router.

.. toctree::
   :hidden:

   corr44
   cmac44
