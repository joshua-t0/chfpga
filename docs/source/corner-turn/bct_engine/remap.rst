.. title:: REMAP

********************************************************************
:entity:`remap` (*remap.vhd*): Lane Remapping Module
********************************************************************

.. parse:: hdl/ct/remap.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: remap

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

