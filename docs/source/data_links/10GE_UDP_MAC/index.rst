.. title:: 10GE_UDP_MAC

10G Ethernet UDP/MAC: 10 Gigabit Ethernet UDP/IP/MAC Modules
************************************************************


.. toctree::
   :maxdepth: 2
   :hidden:

   xge_array
   xge_udp_mac_tx
   ../../navbar_separator


.. default-role:: vhdl:entity

The 10G Ethernet UDP/MAC modules implement 10 Gigabit Ethernet UDP/IP/Ethernet packet transmission using GTX transceivers on Kintex-7 FPGAs. These modules provide high-speed data transmission for corner-turn operations and other data-intensive applications.

The 10G UDP/MAC system consists of:

- :entity:`xge_array`: Array wrapper that manages multiple 10G Ethernet transmitters, each encapsulating data as UDP packets
- :entity:`XGE_UDP_MAC_TX`: Transmitter module that handles UDP/IP/Ethernet packet encapsulation and transmission over 10G Ethernet links

The system uses :entity:`xglink_core` for the physical layer transmission over GTX transceivers.


