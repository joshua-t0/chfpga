.. title:: bsb_async_fifo

******************************************************************************
:entity:`bsb_async_fifo` (*bsb_async_fifo.vhd*): Command Bus Asynchronous FIFO
******************************************************************************

.. parse:: hdl/bsb/bsb_async_fifo.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: bsb_async_fifo

Parameters
----------

- **SIM:** Simulation mode flag. Set to ``TRUE`` to enable simulation-specific behavior (e.g. bypassing primitives that do not simulate well). Default is ``FALSE``.

Interface
---------

Side A (e.g. upstream clock domain):

- ``cmd_a_tdata``, ``cmd_a_tvalid``, ``cmd_a_tlast``, ``cmd_a_tready``: Command stream input, synchronous to ``a_clk``.

- ``rply_a_tdata``, ``rply_a_tvalid``, ``rply_a_tlast``, ``rply_a_tready``: Reply stream output, synchronous to ``a_clk``.

- ``a_clk``: Clock for side A.

- ``a_rst_out``: Extended reset pulse output, synchronous to ``a_clk``. Stays asserted for at least 8 ``a_clk`` cycles after ``rst`` is released.

Side B (e.g. downstream clock domain):

- ``cmd_b_tdata``, ``cmd_b_tvalid``, ``cmd_b_tlast``, ``cmd_b_tready``: Command stream output, synchronous to ``b_clk``.

- ``rply_b_tdata``, ``rply_b_tvalid``, ``rply_b_tlast``, ``rply_b_tready``: Reply stream input, synchronous to ``b_clk``.

- ``b_clk``: Clock for side B.

- ``b_rst_out``: Extended reset pulse output, synchronous to ``b_clk``. Stays asserted for at least 8 ``b_clk`` cycles after ``rst`` is released.

System:

- ``rst``: Asynchronous reset input. Triggers reset on both clock domains.

Implementation details
----------------------

Architecture
~~~~~~~~~~~~

Two Xilinx ``xpm_fifo_async`` instances bridge the two clock domains — one for the command direction (A→B) and one for the reply direction (B→A). Each FIFO is 9 bits wide (8 data bits + 1 TLAST bit encoded in the MSB) and 16 entries deep (the minimum depth supported by ``xpm_fifo_async``), implemented in distributed RAM.

Clocking and reset
~~~~~~~~~~~~~~~~~~

``rst`` is an asynchronous global reset. Two independent reset stretching circuits, one per clock domain, ensure that the ``xpm_fifo_async`` reset input remains asserted for at least 8 cycles on the respective clock, satisfying the minimum reset pulse requirements of the primitive. The stretched resets are also exposed as ``a_rst_out`` and ``b_rst_out`` for use by logic in each domain.

Write enables are gated by the reset-busy signals from the FIFO primitive (``wr_rst_busy`` and ``rd_rst_busy``) to prevent writes while the FIFO is initializing.
