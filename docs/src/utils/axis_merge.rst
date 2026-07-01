.. title:: axis_merge

******************************************************************************************
:entity:`axis_merge` (*axis_merge.vhd*): N-port packet-level round-robin AXIS merge
******************************************************************************************

.. parse:: hdl/utils/axis_merge.vhd

.. default-role:: vhdl:entity

Entity documentation
====================

.. autoentity:: axis_merge

Parameters
==========

- **N_PORTS:** Number of AXI4-Stream input ports to merge. Port indices run from 0 to
  ``N_PORTS − 1``. Default: 2.

- **DATA_WIDTH:** Data width in bits for all AXIS buses (input and output). Default: 8.

- **USE_FIFO:** When ``TRUE`` (default), an internal :entity:`axis_sync_fifo` is inserted
  between the arbitration mux and the output to break the combinatorial path from
  ``m_axis_tready`` back to ``s_axis_tready``. When ``FALSE``, the output is driven
  directly (combinatorial back-pressure path; suitable for moderate clock rates only).

Interface
=========

Input streams (slave side)
--------------------------

- ``s_axis_tdata``: Array of ``N_PORTS`` input data buses, each ``DATA_WIDTH`` bits wide.
  Type: ``slv_array(0 to N_PORTS − 1)(DATA_WIDTH − 1 downto 0)``.

- ``s_axis_tvalid``: ``N_PORTS``-bit vector of source-valid handshake signals, one per port.

- ``s_axis_tlast``: ``N_PORTS``-bit vector of end-of-packet markers, one per port. Arbitration
  advances to the next round-robin candidate only when the current port asserts ``tlast`` and
  the transfer is accepted.

- ``s_axis_tready``: ``N_PORTS``-bit vector of back-pressure outputs. Only the currently
  selected port's bit is driven high; all others are held low.

Output stream (master side)
---------------------------

- ``m_axis_tdata``: Merged output data bus (``DATA_WIDTH`` bits).

- ``m_axis_tvalid``: Asserts when the selected input port has valid data (or when the internal
  FIFO has data, when ``USE_FIFO = TRUE``).

- ``m_axis_tlast``: End-of-packet marker forwarded from the selected input port.

- ``m_axis_tready``: Back-pressure input from the downstream consumer.

Clock and reset
---------------

- ``clk``: System clock. All arbitration logic and (if enabled) the internal FIFO are
  synchronous to the rising edge.

- ``rst``: Synchronous active-high reset. Clears the arbitration state. Default: ``'0'``.

Overview
========

:entity:`axis_merge` merges N AXI4-Stream sources into a single output with **one pipeline stage**
(:entity:`axis_sync_fifo` when ``USE_FIFO`` is true). Arbitration is **round-robin at packet boundaries** (``tlast``).
Port index range is 0 to ``N_PORTS`` − 1 (cyclic: port 0 follows port ``N_PORTS`` − 1).

- **Generics**: ``N_PORTS``, ``DATA_WIDTH`` (default 8), ``USE_FIFO`` (default true). Same entity works for any port count and bus width.
- **USE_FIFO=true**: No combinatorial path from ``m_axis_tready`` to any ``s_axis_tready``; backpressure is broken by the FIFO so timing is easier.
- **USE_FIFO=false**: Direct connection; combinatorial ``m_axis_tready``→ ``s_axis_tready``; 1-cycle latency, 2 dead cycles; for moderate clock rates only.
- Round-robin is implemented with a double-length vector: concatenate ``s_axis_tvalid`` twice and linear search from ``current_port`` + 1 to pick the first valid port (Case 2 in design notes).

Detailed description
====================

Design concerns addressed
-------------------------

- **Single pipeline stage only**  
  One :entity:`axis_sync_fifo` sits between the merge mux and ``m_axis_*`` when ``USE_FIFO`` is true. No extra register stages; the FIFO provides the only buffering and breaks the TREADY comb path.

- **Purely synchronous arbitration**  
  Arbitration uses ``current_port`` and ``current_port_active``. Port selection uses a double-length ``s_axis_tvalid`` vector and a linear search. When the last word of a frame is accepted, ``current_port_active`` is cleared; the next cycle selects the first valid port after the current one (round-robin).

Data path and backpressure
--------------------------

- **Data path**: Selected port (by ``current_port``) → N:1 mux → ``fifo_tdata`` / ``fifo_tvalid`` / ``fifo_tlast`` → :entity:`axis_sync_fifo` (or direct to ``m_axis_*`` when ``USE_FIFO=false``) → ``m_axis_*``.

- **TREADY to sources**: ``s_axis_tready``(i) is driven only when i = ``current_port`` and ``current_port_active``; it forwards the FIFO (or m_axis) ready signal.

Resource utilization
--------------------

A 2-to-1 merge of two 8-bit buses (``N_PORTS`` = 2, ``DATA_WIDTH`` = 8) uses approximately **18 LUTs** and **24 registers** (merge logic plus the internal :entity:`axis_sync_fifo` when ``USE_FIFO=true``). Scale with port count and data width for other configurations.

Dependencies
------------

- **chFPGA_Package**: ``slv_array`` for ``s_axis_tdata`` array.
- **axis_sync_fifo**: Single instantiation when ``USE_FIFO`` is true; ``DATA_WIDTH`` is passed through. Project must include both :file:`common/axis_merge.vhd` and :file:`bsb/axis_sync_fifo.vhd` in the same library (e.g. ``work``).

Design notes (architecture, decoding variants, trade-offs)
----------------------------------------------------------

This section preserves design decisions, decoding/architecture variants, and trade-offs
discussed during development.

Architecture
~~~~~~~~~~~~

We want to implement an N-port packet-level round-robin merge. Goals: minimize LUTs and FFs,
meet timing (target buses are relatively slow), break the TREADY combinatorial loop, and keep
latency and dead cycles minimal.

Starting point
^^^^^^^^^^^^^^

We based the design on the bsb_router reply path: an N-port packet-level merge with a skid
buffer (1-deep FIFO) to handle TREADY pipelining. The skid logic was integrated into the state
machine. A SCAN/SEND FSM orchestrated source selection. Port selection was simple first-valid
priority (not round-robin). It gave **2-cycle latency** and **2 dead cycles**. One latent bug:
the SCAN loop had no ``exit``, so if multiple ports had tvalid=1, all got tready=1 for one cycle;
only the last port in the loop was served, so data from others could be lost. Rare in practice
on the low-rate BSB bus. axis_merge3 fixes this by asserting tready only for the selected port.

New design
^^^^^^^^^^

We reuse the existing axis_sync_fifo as the skid buffer/register slice when USE_FIFO=true. The merge module only
implements arbitration logic.

Arbitration logic (decoding variants)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Several options for round-robin port selection:

**Case 1: (next_start+k) mod N**

.. code-block:: vhdl

   for k in 0 to N_PORTS - 1 loop
       i := (next_start + k) mod N_PORTS;
       if s_axis_tvalid(i) = '1' then
           port_sel <= i;
           exit;
       end if;
   end loop;

Uses many LUTs due to modulo in loop (carry chains).

**Case 2: Double-length vector** (used in implementation)

Avoids MOD in the loop: concatenate tvalid twice, linear search from current_port+1, pick first
valid. Synthesis uses fewer LUTs than Case 1.

.. code-block:: vhdl

   tvalid2 := s_axis_tvalid & s_axis_tvalid;
   for i in 0 to 2*N_PORTS - 1 loop
       if i > current_port and tvalid2(i)='1' then
           port_sel <= i mod N_PORTS;
           exit;
       end if;
   end loop;

**Case 3: Thermo logic**

Use thermometer trick (``tvalid and -tvalid``) to find first set bit, then convert to index.
Carry chain (minus) can help, but index conversion adds LUTs; overall not clearly better than Case 2.

**MOD N vs x-N**

Tried ``x mod N`` vs ``x when x < N else x-N``. No significant logic difference.

Dead cycles
^^^^^^^^^^^

Target: one dead cycle between packets. Zero dead cycles would require selecting the next port
when the last word is taken, but that can reselect the current port. Simpler: wait for current
port to finish before choosing the next — gives 1 dead cycle, acceptable for our bandwidth needs.

**TREADY path**: The single dead cycle keeps one MUX LUT in the reply path. Fully breaking the
combinatorial tready path would require a 2-deep FIFO and an extra dead cycle.

Implementation details
======================

Principle of operations
-----------------------

The arbiter maintains a ``current_port`` register and a ``current_port_active`` flag. While a port is active, its data passes through an N:1 combinatorial mux to the output (or to an internal :entity:`axis_sync_fifo` when ``USE_FIFO`` is true). When the last word of a packet is accepted (``tlast`` and ``tready`` both asserted simultaneously), ``current_port_active`` clears and the arbiter searches a double-length copy of ``s_axis_tvalid`` starting from ``current_port + 1`` to select the next valid port in round-robin order, incurring one dead cycle between packets. Only the currently selected port's ``s_axis_tready`` bit is driven high; all others are held low.

Clocking
--------

All arbitration logic and the optional internal :entity:`axis_sync_fifo` operate in a single clock domain driven by ``clk``. There are no multi-clock-domain crossings.
