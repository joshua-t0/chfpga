.. title:: xge_udp_mac_tx

************************************************************************************
:entity:`xge_udp_mac_tx` (*xge_udp_mac_tx.vhd*): 10G Ethernet UDP/IP/MAC Transmitter
************************************************************************************


.. toctree::
   :maxdepth: 2
   :hidden:

   xgmii_udp_mac_tx_data_fifo
   xgmii_udp_mac_tx_header_fifo
   ../../navbar_separator  


.. parse:: hdl/10GE_UDP_MAC/xge_udp_mac_tx.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: xge_udp_mac_tx

Sub-modules
-----------

The `xge_udp_mac_tx` module uses the following FIFOs:

- :doc:`xgmii_udp_mac_tx_data_fifo`: Asynchronous FIFO for clock domain crossing between user data clock and XGMII transmit clock
- :doc:`xgmii_udp_mac_tx_header_fifo`: Asynchronous FIFO for storing packet header information
