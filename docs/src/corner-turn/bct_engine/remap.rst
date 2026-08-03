.. title:: REMAP

****************************************************
:entity:`remap` (*remap.vhd*): Lane Remapping Module
****************************************************

.. parse:: hdl/ct/remap.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: remap

Parameters
==========

- **NUMBER_OF_INPUT_LANES:** Number of input data lanes. Determines the width of the ``s_axis_*`` port arrays. Defaults to 4.
- **NUMBER_OF_OUTPUT_LANES:** Number of output data lanes. Determines the width of the ``m_axis_*`` port arrays and the ``lane_map`` array. Can differ from ``NUMBER_OF_INPUT_LANES`` to allow lane count changes. Defaults to 4.

Interface
=========

Input
-----

- ``s_axis_tvalid``: Per-lane valid flags on the input. Non-blocking — the module always accepts data.
- ``s_axis_tdata``: Per-lane 32-bit input data.
- ``s_axis_tlast``: Per-lane end-of-frame flag.

Output
------

- ``m_axis_tvalid``: Per-lane valid flags on the remapped output. Lane ``n`` presents the valid of input lane ``lane_map(n)``.
- ``m_axis_tdata``: Per-lane 32-bit remapped output data.
- ``m_axis_tlast``: Per-lane remapped end-of-frame flag.

Control
-------

- ``lane_map``: Array of 4-bit values, one per output lane. ``lane_map(n)`` specifies which input lane index feeds output lane ``n``. Can be driven by a register or hard-coded at elaboration time.

Clocking
--------

- ``clk``: Single clock for all logic.
- ``rst``: Synchronous active-high reset.

Principle of Operations
=======================

The `remap` module reorganizes the ordering of data lanes by routing any input lane to any output lane based on a configurable mapping. This module is used in the shuffle crossbars to compensate for slot-dependent lane ordering caused by backplane wiring, or for reordering bin order depending on the corner-turn mode of operation.

The remapping operation is performed by a simple combinatorial routing network that connects each output lane to a source input lane specified by the ``lane_map`` register. The mapping is applied to all AXI-Streaming signals (``tvalid``, ``tdata``, ``tlast``) simultaneously.

Key Features
------------

- **Non-blocking operation**: The module always accepts data on all input lanes and always provides data on all output lanes (when valid)
- **Combinatorial routing**: The remapping is performed combinatorially with a single clock cycle of pipelining
- **Configurable mapping**: Each output lane can be mapped to any input lane via the ``lane_map`` register
- **Synchronous reset**: The module includes a synchronous reset that clears all output valid signals

Usage in SHUFFLE_CROSSBAR
--------------------------

The `remap` module is instantiated in the :entity:`shuffle_crossbar` after the alignment stage and before the bin selector stage. It is used to:

1. **Compensate for backplane connectivity**: The backplane wiring may cause data from slot 0 to arrive on a different physical lane than expected. The remapper reorders the lanes so that post-remap lane 0 gets its data from slot 0, lane 1 from slot 1, etc.

2. **Reorder bins for different modes**: In different corner-turn modes (shuffle256, shuffle512), the remapper may need to reorder lanes to ensure proper bin ordering for downstream processing.

3. **Pipeline delay**: The remapper also provides a pipeline delay stage that gives the bin selector module time to look up its bin selection map from RAM.

The remapping configuration is controlled through memory-mapped registers in the shuffle crossbar's control interface.

Implementation details
======================

Architecture
------------

The remapping is implemented as a single registered pipeline stage: on each rising clock edge the process iterates over all output lanes, converts the 4-bit ``lane_map`` value for that lane into an integer index, and registers the corresponding input ``tvalid``, ``tdata``, and ``tlast`` signals into the output registers. The combinatorial lookup and the output registration are fused in a single ``if rising_edge`` process, giving exactly one clock cycle of pipeline latency with no additional buffering. Synthesis can infer this as a simple register array without any routing fabric.

Clocking
--------

All logic is clocked by the single ``clk`` input. The synchronous ``rst`` forces all ``m_axis_tvalid`` outputs to zero on the next rising edge without clearing the data registers, matching the non-blocking AXI-Streaming convention used elsewhere in the corner-turn engine.
