.. title:: axis_merge2

******************************************************************************************
:entity:`axis_merge2` (*axis_merge2.vhd*): N-port packet-level round-robin AXIS merge
******************************************************************************************

.. parse:: hdl/common/axis_merge2.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: axis_merge2

Overview
========

:entity:`axis_merge2` merges N AXI4-Stream sources into a single output with **one pipeline stage**
(:entity:`axis_sync_fifo`). Arbitration is **round-robin at packet boundaries** (:vhdl:port:`tlast`).
Port index range is 0 to :vhdl:gen:`N_PORTS` − 1 (cyclic: port 0 follows port N_PORTS−1).

- **Generics**: :vhdl:gen:`N_PORTS`, :vhdl:gen:`DATA_WIDTH` (default 8). Same entity works for any port count and bus width.
- **No combinatorial path** from :vhdl:port:`m_axis_tready` to any :vhdl:port:`s_axis_tready`; backpressure is broken by the FIFO so timing is easier.
- **No idle scan cycles**: round-robin is implemented with a **barrel-shift + priority encode**: :vhdl:signal:`rotated_valid` rotates :vhdl:port:`s_axis_tvalid` so the first candidate after :vhdl:signal:`last_served` is at index 0; :vhdl:func:`first_set_bit_index` (in :entity:`chfpga_package`) returns the first set bit; :vhdl:signal:`next_port_from_rotate` is then (last_served+1+offset) mod N. This avoids a mod-in-loop and keeps LUT usage low for large :vhdl:gen:`N_PORTS`.
- **1-cycle data latency**: :vhdl:signal:`next_port` is latched: combinatorially updated when :vhdl:signal:`en` = 1 (scanning), frozen when :vhdl:signal:`en` = 0 (in packet). EN goes to 0 when the first byte is taken, back to 1 when tlast is accepted. Merge always drives from :vhdl:signal:`next_port`; no combinatorial path from :vhdl:port:`m_axis_tready` to sources.

Detailed description
====================

Design concerns addressed
-------------------------

- **Single pipeline stage only**  
  One :entity:`axis_sync_fifo` sits between the merge mux and :vhdl:port:`m_axis_*`. No extra register stages; the FIFO provides the only buffering and breaks the TREADY comb path.

- **Purely synchronous arbitration**  
  Arbitration uses a single clocked process: :vhdl:signal:`en`, :vhdl:signal:`next_port` (latched), and :vhdl:signal:`last_served`. There is **no** combinatorial path from :vhdl:port:`m_axis_tready` to sources. Combinatorial logic: barrel-shift :vhdl:signal:`rotated_valid`, :vhdl:func:`first_set_bit_index`, :vhdl:signal:`next_port_from_rotate`; :vhdl:signal:`next_port` = :vhdl:signal:`next_port_from_rotate` when en else hold; N:1 mux from :vhdl:signal:`next_port`; 1:N demux for :vhdl:port:`s_axis_tready` from the FIFO’s input ready (registered inside :entity:`axis_sync_fifo`).

- **Round-robin without idle cycles**  
  :vhdl:signal:`rotated_valid` is built so that ``rotated_valid(i) = s_axis_tvalid((last_served+1+i) mod N_PORTS)``. :vhdl:func:`first_set_bit_index`(rotated_valid) gives the offset of the first valid port in that rotated view; :vhdl:signal:`next_port_from_rotate` = (last_served+1+offset) mod N_PORTS (or −1 if none). When :vhdl:signal:`en` = 1, :vhdl:signal:`next_port` follows :vhdl:signal:`next_port_from_rotate`; when en = 0 it holds. No multi-cycle scan and no wasted cycles.

- **No latches**  
  The clocked process assigns :vhdl:signal:`en` and :vhdl:signal:`last_served` on every path; reset is handled in a separate ``if rst`` block at the **bottom** of the process so that reset overrides normal logic and no branch fails to assign a register. :vhdl:signal:`next_port` is driven only by the concurrent assignment (when en) and is not assigned in the process.

Data path and backpressure
--------------------------

- **Data path**: Selected port (by :vhdl:signal:`next_port`) → N:1 mux → :vhdl:signal:`merged_tdata` / :vhdl:signal:`merged_tvalid` / :vhdl:signal:`merged_tlast` → :entity:`axis_sync_fifo` → :vhdl:port:`m_axis_*`. :vhdl:port:`tdata` and :vhdl:port:`tlast` are assigned directly from the selected port (no conditional); the consumer only uses them when :vhdl:port:`tvalid` is set.

- **TREADY to sources**: :vhdl:port:`s_axis_tready`(i) is driven from the FIFO’s **input** :vhdl:port:`s_axis_tready` (internal :vhdl:signal:`fifo_s_axis_tready`), and only for the current port: high when :vhdl:signal:`next_port` = i (and ≥ 0), else ``'0'``.

EN and latched next_port
-------------------------

- **en = 1 (scanning)**: :vhdl:signal:`next_port` is updated each cycle from :vhdl:signal:`next_port_from_rotate` (barrel-shift + :vhdl:func:`first_set_bit_index`). Merge and TREADY use this port, so the first byte can be taken in the same cycle (1-cycle latency).

- **en = 0 (in packet)**: :vhdl:signal:`next_port` is frozen (register holds). Merge keeps forwarding that port until the packet ends.

- **EN** goes to 0 when the first byte of a packet is taken (:vhdl:signal:`first_byte_taken`: en and valid port and FIFO ready). EN goes back to 1 when the last beat is accepted (:vhdl:signal:`tlast_done`); then :vhdl:signal:`last_served` is set to :vhdl:signal:`next_port` for round-robin.

Resource utilization
--------------------

A 2-to-1 merge of two 8-bit buses (:vhdl:gen:`N_PORTS` = 2, :vhdl:gen:`DATA_WIDTH` = 8) uses approximately **18 LUTs** and **24 registers** (merge logic plus the internal :entity:`axis_sync_fifo`). Scale with port count and data width for other configurations.

Dependencies
------------

- **chFPGA_Package**: :vhdl:type:`slv_array` for :vhdl:port:`s_axis_tdata` array; :vhdl:func:`first_set_bit_index` for priority encode (barrel-shift round-robin). Both are in :entity:`chfpga_package`.
- **axis_sync_fifo**: Single instantiation; :vhdl:gen:`DATA_WIDTH` is passed through. Project must include both :file:`common/axis_merge2.vhd` and :file:`bsb/axis_sync_fifo.vhd` in the same library (e.g. ``work``).

Design notes (architecture, decoding variants, trade-offs)
----------------------------------------------------------

This section preserves design decisions, decoding/architecture variants, and trade-offs
discussed during development of the axis_merge family.

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

We reuse the existing axis_sync_fifo as the skid buffer/register slice. The merge module only
implements arbitration logic.

Arbitration logic (decoding variants)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

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

**Case 2: Double-length vector**

Avoids MOD in the loop: concatenate tvalid twice, linear search from last_served+1, pick first
valid. Synthesis uses fewer LUTs than Case 1.

.. code-block:: vhdl

   tvalid2 := s_axis_tvalid & s_axis_tvalid;
   for i in 0 to 2*N_PORTS - 1 loop
       if i > last_served and tvalid2(i)='1' then
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
