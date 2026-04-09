.. title:: xxvglink_data_fifo

***************************************************************************
:entity:`xxvglink_data_fifo` (*xxvglink_data_fifo.vhd*): XXVGLINK Data FIFO
***************************************************************************

.. parse:: hdl/data_links/XXVGLINK/xxvglink_data_fifo.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: xxvglink_data_fifo

Parameters
==========

- **DATA_WIDTH:** Width of the data bus in bits (default: 64).

- **EMPTY_THRESHOLD:** ``PROG_EMPTY`` threshold, i.e. the ``almost_empty`` flag is asserted when the number of entries in the FIFO falls below this value (must be ≥ 1, default: 1). Used by `xxvglink_bypass` to set a minimum RX delay.

- **FULL_THRESHOLD:** ``PROG_FULL`` threshold, i.e. the ``almost_full`` flag is asserted when the number of entries reaches this value (default: 500).

Interface
=========

Write side (``s_clk``)
-----------------------

- ``s_axis_tdata``: Input data word.

- ``s_axis_tlast``: End-of-packet qualifier, stored alongside the data in the parity bits of the FIFO.

- ``s_axis_tvalid``: Write enable. Data is written when ``tvalid`` is asserted; if the FIFO is full, the word is dropped and ``overflow`` is asserted.

- ``s_axis_terror``: Error flag to be stored with the word (stored in the parity bits alongside ``tlast``).

- ``s_clk``: Write clock. May differ from ``m_clk`` for asynchronous operation.

- ``full``: Asserted when the FIFO is full.

- ``almost_full``: Asserted when the write occupancy reaches ``FULL_THRESHOLD``.

- ``overflow``: Asserted for one cycle when a write is attempted while the FIFO is full (data is lost).

Read side (``m_clk``)
----------------------

- ``m_axis_tdata``: Output data word.

- ``m_axis_tlast``: End-of-packet qualifier recovered from the parity bits.

- ``m_axis_tvalid``: Asserted when the FIFO is not empty (FWFT: data is valid as soon as it is written).

- ``m_axis_tready``: Read enable. A word is consumed when both ``tvalid`` and ``tready`` are high.

- ``m_axis_terror``: Error flag recovered from the parity bits.

- ``m_clk``: Read clock.

- ``empty``: Asserted when the FIFO is empty.

- ``almost_empty``: Asserted when the read occupancy falls below ``EMPTY_THRESHOLD``.

Clock and reset
---------------

- ``arst``: Asynchronous active-high reset. Internally re-synchronized to the write clock via ``xpm_cdc_async_rst``.

Implementation details
======================

Principle of operations
-----------------------

`xxvglink_data_fifo` is an asynchronous **First-Word-Fall-Through (FWFT)** FIFO built directly on the UltraScale+ **FIFO36E2** primitive (rather than the XPM macro) to take advantage of the primitive's native asynchronous mode and parity bits. It bridges the user and GTY transceiver clock domains for both TX and RX datapaths.

The FIFO data width is fixed at 72 bits internally: 64 data bits (``DIN``/``DOUT``) plus 8 parity bits (``DINP``/``DOUTP``). The ``tlast`` and ``terror`` sideband signals are packed into parity bits 0 and 1, respectively, which travel alongside the data without consuming any of the 64-bit data bus. The ``REGISTER_MODE => "REGISTERED"`` setting adds an output register stage inside the FIFO block for timing closure without adding latency in FWFT mode. The asynchronous reset ``arst`` is re-synchronized to the write clock via ``xpm_cdc_async_rst`` before being applied to the FIFO's synchronous ``RST`` port. ``m_axis_tvalid`` is derived directly from the FIFO ``EMPTY`` flag (active-low).

Key Features
^^^^^^^^^^^^

- **Direct FIFO36E2**: Uses the Xilinx UltraScale+ embedded FIFO primitive directly for efficient resource usage and native async support
- **Parity-bit sideband**: ``tlast`` and ``terror`` travel in FIFO parity bits, preserving the full 64-bit data width
- **FWFT with output register**: Zero-latency read interface with an internal output register for timing closure
- **Configurable thresholds**: ``EMPTY_THRESHOLD`` and ``FULL_THRESHOLD`` tune the ``almost_empty`` / ``almost_full`` programmable flags independently

Usage in XXVGLINK
^^^^^^^^^^^^^^^^^

The `xxvglink_data_fifo` is used in both :entity:`xxvglink_tx` and :entity:`xxvglink_rx` modules to buffer data during clock domain crossing operations between the user logic and GTY transceiver interfaces.

