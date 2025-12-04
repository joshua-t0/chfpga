.. title:: 1G_UDP_MAC

1G Ethernet UDP/MAC: Gigabit Ethernet UDP/IP/MAC Modules
********************************************************


.. toctree::
   :maxdepth: 2
   :hidden:

   udp_mac
   udp_mac_rx
   udp_mac_tx
   udp_mac_tx_data_fifo
   udp_mac_tx_frame_fifo
   gmii_to_sgmii
   crc32
   ../../navbar_separator


.. default-role:: vhdl:entity

The 1G UDP/MAC modules implement a lightweight Gigabit Ethernet UDP/IP/Ethernet packet transmitter/receiver stack. These modules provide 1 Gbps Ethernet connectivity for control and data communication.

The 1G UDP/MAC system consists of:

- :entity:`udp_mac`: Main module that wraps the UDP/IP/Ethernet stack with optional GMII-to-SGMII conversion
- :entity:`udp_mac_rx`: Receiver module that handles UDP packet reception and ARP processing
- :entity:`UDP_MAC_TX`: Transmitter module that handles UDP packet transmission and ARP replies
- :doc:`udp_mac_tx_data_fifo`: Data FIFO for clock domain crossing in the UDP transmitter
- :doc:`udp_mac_tx_frame_fifo`: Frame FIFO for storing packet metadata in the UDP transmitter
- :entity:`gmii_to_sgmii`: Optional GMII-to-SGMII converter for SFP transceiver interfaces
- :entity:`CRC32`: Ethernet CRC32 computation module used by both RX and TX modules


