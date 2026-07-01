.. title:: xge_array

*****************************************************************
:entity:`xge_array` (*xge_array.vhd*): 10G Ethernet UDP/MAC Array
*****************************************************************

.. default-role:: vhdl:entity

Overview
========

`xge_array` bundles **multiple** 10G-class **UDP transmitters** over **GTX** links. Each lane takes **32-bit AXI-Stream** on an independent ``s_axis_tx_clk`` (per-lane user clock) and drives differential TX/RX plus **156.25 MHz** reference clocks. **BSB** command/reply streams configure MAC/IP defaults per lane.

RX pins are wired for transceiver commonality; the primary use case in-tree is **TX UDP streaming** into the corner-turn / backplane fabric. `xge_udp_mac_tx` instances sit under this array, fed from `xglink_core` for serialization.

Entity documentation
====================

.. parse:: hdl/data_links/10GE_UDP_MAC/xge_array.vhd

.. autoentity:: xge_array

Parameters
==========

- **LANE_TO_QUAD_MAP:** Maps each lane index to a GTX quad id (0 … N−1).

- **QUAD_TO_REFCLK_MAP:** Maps each quad to a reference clock index (0 … ``NUMBER_OF_REFCLK`` − 1).

- **NUMBER_OF_TX_LANES:** Number of TX-only lanes (defaults to the length of ``LANE_TO_QUAD_MAP``).

- **NUMBER_OF_REFCLK:** Number of external **156.25 MHz** differential references (derived from ``QUAD_TO_REFCLK_MAP`` by default).

- **DEFAULT_MAC_SRC_ADDR / DEFAULT_MAC_DEST_ADDR:** Per-lane source and destination Ethernet MAC defaults.

- **DEFAULT_IP_SRC_ADDR / DEFAULT_IP_DEST_ADDR / DEFAULT_IP_DEST_PORT:** Per-lane IPv4 and UDP destination port defaults.

- **USE_LITTLE_ENDIAN:** When ``TRUE``, the first bit transmitted from each 32-bit user word follows LSB-first per-byte ordering; when ``FALSE``, MSB-first (see `xge_udp_mac_tx`).

- **`SIM`:** Enables simulation-oriented elaboration where applicable.

Interface
=========

- **SerDes:** ``tx_p`` / ``tx_n``, ``rx_p`` / ``rx_n`` (one differential pair per lane); ``refclk_p`` / ``refclk_n`` (one pair per reference).

- **Clock outputs:** ``refclk_div2``, ``txclk_div2``, ``clk322_out`` — divided reference and ~322 MHz (link-speed dependent) clocks for fabric and MAC datapath.

- **Per-lane AXI-Stream:** ``s_axis_tx_tdata``, ``tvalid``, ``tlast``, ``tready``, each synchronous to the corresponding ``s_axis_tx_clk`` lane clock (blocking ``tready``).

- **BSB:** ``s_axis_bsb_t*`` / ``m_axis_bsb_t*`` on ``bsb_clk`` / ``bsb_rst`` for register access to all lanes.

- **Reset:** ``areset`` — asynchronous reset to the array and contained cores.

Implementation details
======================

Principle of operations
-----------------------

`xge_array` instantiates one `xglink_core` (shared multi-lane GTX/QPLL fabric) and one `xge_udp_mac_tx` per lane. Each lane accepts **32-bit AXI-Stream** UDP payloads on its own user clock, builds Ethernet/IPv4/UDP frames with that lane's default or BSB-programmed addresses, and feeds **64B/66B**-style words into the corresponding TX lane of `xglink_core`. RX pins are connected for transceiver commonality; the in-tree use case emphasizes high-rate UDP transmit into the backplane or corner-turn fabric. BSB space multiplexes per-lane MAC/IP/port overrides and status. Reference clocks and quad/lane mapping generics must match the board's GTX bank wiring.

Architecture
------------

All `xge_udp_mac_tx` instances share a single TX word clock (``xglink_tx_clk``) produced by `xglink_core`; each lane's user-side AXI-Stream runs on its own independent ``s_axis_tx_clk``. A shared BSB router (inside `xglink_core`) distributes control and status bytes across all lanes plus an array-level register set for test-pattern generation, overflow flags, and destination-address mode. The ``dest_address_mode`` control bit allows per-lane destination IP/MAC addresses to be derived dynamically from lane index for corner-turn configurations, overriding the compile-time defaults. Per-lane sticky overflow registers track both data and frame-level FIFO overflows independently.
