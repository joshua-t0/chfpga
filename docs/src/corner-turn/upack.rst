.. title:: UPACK

*******************************************************************************
:entity:`UPACK` (*upack.vhd*): UltraRAM-based Packetizer and Corner-Turn Engine
*******************************************************************************

.. parse:: hdl/ct/upack.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: upack

Parameters
==========

- **SIM:** When ``TRUE``, replaces UltraRAM tiles with simulation-friendly RAM models to avoid long elaboration times in behavioural simulation. Must be ``FALSE`` for synthesis. Defaults to ``FALSE``.

Interface
=========

Data input
----------

- ``s_axis_in_tdata``: 256-bit input word from the F-Engine channelizer. Carries 8 channels × 8 bins × 4 bytes, organized as 4 bins per word across 8 lanes.
- ``s_axis_in_tvalid``: Input valid flag. Non-blocking — the module always absorbs data when valid.
- ``s_axis_in_tlast``: End-of-frame flag. Marks the last word of an input data frame.

Data output
-----------

- ``m_axis_out_tdata``: 256-bit output word read from the UltraRAM array. Carries the corner-turned (transposed) data.
- ``m_axis_out_tvalid``: Output valid flag.
- ``m_axis_out_tlast``: End-of-frame flag on the output stream.

Debug
-----

- ``debug_out``: 32-bit debug register output. Contents are implementation-defined; used during bring-up.

BSB control interface
---------------------

- ``s_axis_bsb_*/m_axis_bsb_*``: BSB command and reply byte streams for software-controlled register access (memory-map registers, timing, monitoring).
- ``bsb_clk/bsb_rst``: Dedicated clock and synchronous reset for the BSB interface.

Clocking
--------

- ``clk``: AXI-Streaming clock for all data-path logic.
- ``rst``: Synchronous active-high reset.

Principle of operation
----------------------


Memory organization
-------------------

Data is stored in 16 URAM blocks organized as an array of 4 x 4 blocks. Each block is implemented a 4 UltraRAM tiles, which together form a memory with  64 bits x 16384 words. 

The incoming data is written column-wise, wich each column receiving the 64 bits (8 channels * 8 bit/channel) from each bin in the input word. Data from consecutive frames are written in different rows.  

A data frame consists of 2048 words (8192 bins total, 4 bins per word). Each memory block can store 8 frames, or 4 frames per bank. The 4 blocks in a column can store up to 16 frames per bank.

Data is read column-wise, all 4 blocks in a column in parallel, providing a 256 bit data bus.


Memory Map
----------

.. include-docs:: upack
    :start-after: Memory Map

Implementation details
======================

Principle of operations
-----------------------

The module implements a corner-turn as a memory transposition: channelizer data is written into a 4×4 UltraRAM matrix column-wise (one column per bin group, across all frames), and read out row-wise (one row per bin, across all frames simultaneously), effectively exchanging the frequency-bin and frame axes. Up to 16 consecutive frames are accumulated in one bank before the bank is swapped; the alternating-bank scheme allows readout and accumulation to proceed concurrently. A software-programmed playlist RAM drives the readout sequencer, giving full control over which bins are sent, in what order, and with what packet boundaries.

Architecture
------------

The memory matrix consists of a 4×4 array of ``xpm_memory_sdpram`` instances each backed by 4 cascaded UltraRAM tiles (14-bit address, 64-bit data, ``MEMORY_PRIMITIVE=ultra``), for 16 cells total and 64 URAMs. A separate mask RAM (BRAM) holds a per-bin write-enable mask that can suppress selected input bins. The playlist RAM (auto-selected memory primitive) stores 16-bit words describing each readout step: bin address, framegroup count, end-of-packet flag, and end-of-transmission flag. The readout sequencer uses a 6-stage delay pipeline to compensate for the 5-clock UltraRAM read latency. BSB register access is bridged from ``bsb_clk`` to ``clk`` by a ``bsb_async_fifo`` at the module input, so all RAM write operations execute in the data-clock domain.

Clocking
--------

All data-path logic, URAM read/write, and the playlist/mask RAM sequencer operate on the single ``clk`` domain. The BSB control interface uses a dedicated ``bsb_clk`` and is decoupled from ``clk`` through the ``bsb_async_fifo`` at the module boundary.
