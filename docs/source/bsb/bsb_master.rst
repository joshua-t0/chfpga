.. title:: bsb_master

***********************************************************
:entity:`bsb_master` (*bsb_master.vhd*): Command Bus Master
***********************************************************

.. parse:: hdl/bsb/bsb_master.vhd

.. default-role:: vhdl:entity

The `bsb_master` module serves as the command bus master for the BSB (Byte-Serial Bus) in the chFPGA system. Its main role is to interface between an upstream command/reply stream (commonly from UDP/Ethernet) and the network of BSB slave modules for memory-mapped register access and module control.

- Receives command packets via a streaming interface and forward them directly to the BSB command channel.
- Send BSB reply packets or raw data packets  back to the streaming interface. 
- BSB reply channel and data channels are are scanned continuously to determine which wull have its packet sent, keeping the others on hold. 
- The first byte of reply packets is replaced with a packet counter to help downstream command/reply synchronization.
- Counts incoming and outgoing command packets for statistics and debugging.
- Performs data throttling to avoid overwhelming the downstream modules.

`bsb_master` BSB bus typically connects a `bsb_router` for address-based command distribution.


Entity documentation
--------------------

.. autoentity:: bsb_master

Parameters
----------

- **NUMBER_OF_PROBES:** Number of raw data (probe) AXI-Stream inputs that can be multiplexed onto the UDP transmit interface. Each probe stream is sent as a separate UDP packet on channel 1.

Interface
---------

UDP Rx interface:

- ``s_axis_udp_rx_tdata``, ``s_axis_udp_rx_tvalid``, ``s_axis_udp_rx_tlast``, ``s_axis_udp_rx_tready``: Incoming UDP byte stream from the network receiver. Forwarded directly to the BSB command output.

UDP Tx interface:

- ``m_axis_udp_tx_tdata``, ``m_axis_udp_tx_tvalid``, ``m_axis_udp_tx_tlast``, ``m_axis_udp_tx_tready``: Outgoing UDP byte stream to the network transmitter. Carries either command replies or probe data packets.

- ``m_axis_udp_tx_channel``: 2-bit destination channel selector. Set to ``"00"`` for command reply packets, ``"01"`` for probe data packets. The underlying UDP transmitter uses this to offset the destination port number.

BSB command/reply interface:

- ``m_axis_cmd_tdata``, ``m_axis_cmd_tvalid``, ``m_axis_cmd_tlast``, ``m_axis_cmd_tready``: BSB command output stream, directly mapped from UDP Rx.

- ``s_axis_rply_tdata``, ``s_axis_rply_tvalid``, ``s_axis_rply_tlast``, ``s_axis_rply_tready``: BSB reply input stream, forwarded to UDP Tx.

Raw data (probe) streams:

- ``s_axis_data_tdata``, ``s_axis_data_tvalid``, ``s_axis_data_tlast``, ``s_axis_data_tready``: Array of ``NUMBER_OF_PROBES`` raw data streams. Packets are sent over UDP Tx channel 1, interleaved with command replies in round-robin order.

System:

- ``cmd_packet_counter``: 8-bit wrapping counter incremented on the first byte of each received UDP command packet. Useful for diagnostics.

- ``rply_packet_counter``: 8-bit wrapping counter incremented after each reply packet is fully transmitted.

- ``host_frame_read_rate``: 5-bit throttling parameter. Determines the period (as ``2^host_frame_read_rate`` clock cycles) at which the estimated host buffer occupancy counter is cleared. Higher values slow down probe data transmission.

- ``clk``: System clock. All signals are synchronous to this clock.

- ``rst``: Synchronous reset.

Implementation details
----------------------

Architecture
~~~~~~~~~~~~

The receive path is purely combinatorial: UDP Rx signals are wired directly to the BSB command output without any buffering. A packet counter tracks the number of received frames by detecting the first byte of each packet (when ``TLAST`` of the previous byte was asserted).

The transmit path is a state machine with four states:

- ``TX_STATE_SCAN``: Idle scanning state. Checks for reply data first (priority), then probes in round-robin order if no throttling applies.
- ``TX_STATE_SEND_CMD``: Forwards reply stream bytes to UDP Tx on channel 0. The first byte of each reply is replaced by the command packet counter value for command/reply synchronization downstream.
- ``TX_STATE_SEND_DATA``: Forwards one probe stream's bytes to UDP Tx on channel 1.
- ``TX_STATE_WAIT``: Inserts a ~128-cycle gap after each probe packet to prevent the UDP transmitter FIFO from overflowing with rapid back-to-back probe frames.

Throttling
~~~~~~~~~~

A software-controlled throttling mechanism prevents probe data from overwhelming the host receive buffers. The module maintains an estimated byte count of data in the host buffer. This counter increments with each transmitted byte and is cleared periodically every ``2^host_frame_read_rate`` clock cycles. If the counter exceeds half its maximum value, probe transmission is paused until the next clear period.

Timeout
~~~~~~~

If ``TVALID`` is not asserted for 256 consecutive clock cycles while in ``TX_STATE_SEND_CMD`` or ``TX_STATE_SEND_DATA``, the state machine abandons the current packet by injecting a final byte with ``TLAST='1'`` and returning to scan mode. This prevents deadlocks if a source stream stalls unexpectedly.
