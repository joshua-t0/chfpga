.. title:: udp_mac_tx

********************************************************************
:entity:`UDP_MAC_TX` (*udp_mac_tx.vhd*): UDP/IP/Ethernet Transmitter
********************************************************************

.. parse:: hdl/1G_UDP_MAC/udp_mac_tx.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: UDP_MAC_TX

Sub-modules
-----------

The `UDP_MAC_TX` module uses the following FIFOs:

- :doc:`udp_mac_tx_data_fifo`: Asynchronous FIFO for clock domain crossing between user data clock and GMII transmit clock
- :doc:`udp_mac_tx_frame_fifo`: Asynchronous FIFO for storing packet length and transmit channel information

