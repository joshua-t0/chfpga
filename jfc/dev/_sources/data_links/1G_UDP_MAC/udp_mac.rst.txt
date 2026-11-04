.. title:: udp_mac

*****************************************************************
:entity:`udp_mac` (*udp_mac.vhd*): 1G Ethernet UDP/IP/MAC Wrapper
*****************************************************************

.. default-role:: vhdl:entity

Overview
========

Lightweight **1 Gb Ethernet UDP** stack with simple **ARP** protocol implementation using a **GMII** or **SGMII** (e.g. SFP) PHY interface. It receives UDP broadcast packets or packets destined to a software-programmable MAC/IP/port, and transmits data on two channels. The MAC/IP/port of each Tx channel can be software-defined or taken from the last non-broadcast packet received. User data is provided as a **8-bit blocking AXI-Stream** on ``clk125``.

Entity documentation
====================

.. parse:: hdl/data_links/1G_UDP_MAC/udp_mac.vhd

.. autoentity:: udp_mac

Parameters
==========

- **FPGA_SERIES:** FPGA series to target, defined as an enumerated type in :ref:`chfpga-package`. Is used to instantiate the proper platform-specific embedded FIFOs. 
- **PHY_TYPE:** PHY type to use, defined as an enum value in :ref:`chfpga-package`. Valid values are ``GMII`` or ``SGMII``. ``GMII`` uses a 8-bit GMII interface, while ``SGMII`` uses a 1Gbps  serial interface implemented using a GTX transceiver.
- **BROADCAST_IP_PORT:** IP port to use for receiving broadcast packets. This port number is fixed in order to allow broadcast packets to be received even if the networking is not set-up yet.
- **SIM:** Simulation mode. If ``TRUE``, the module will not use the PHY interface and will instead use a simple loopback testbench.

Interface
=========

- ``local_mac_addr/ip_addr/ip_port``: MAC/IP/Port address of the local FPGA

- ``remote_mac_addr/ip_addr/ip_port<n>``: MAC/IP/Port address of the remote FPGA for channel 0 and 1. A zero MAC address means that the MAC address of the last received non-broadcast packet is used. Same for the IP address. A zero port number means that channel 0 will use the last port number and channel 1 will use the last port number + 1 (so data streams on channel 1 are streamed to a different port from the command port).

- ``phy_*``: Interface to the GMII PHY when ``PHY_TYPE="GMII"``. ``phy_txclk`` is sometimes provided by a PHY as a TX clock for the GMII TX interface, bit it is not used in tthis module; we use clk125 instead as a clock for the tx path, and provide that clock the PHY through ``phy_txc_gtxclk``. ``phy_rxclk`` is the clock recovered by the PHY and is synchronous to the RX path. The UDP receiver front-end operates on this clock.

- ``sfp_*``: Interface to the SGMII PHY when ``PHY_TYPE="SGMII"``. ``sfp_refclk_nobuf`` and ``sfp_refclk_buf`` are the unbuffered and buffered reference clocks for the SGMII transceiver. ``sfp_tx_p/n`` and ``sfp_rx_p/n`` are the serialized data from the FPGA to the SFP transceiver and from the SFP transceiver to the FPGA, respectively.

- ``status_vector``: Status vector from the GMII-to-SGMII bridge. This is a 16-bit vector that is used to indicate the status of the link and the transceiver. It is not used in this module, but is passed through to the user for diagnostics.

- ``config_vector``: Configuration vector from the GMII-to-SGMII bridge. This is a 32-bit vector that configure gmii-to-sgmii bridge core basic configuration, its auto-negotiation settings, autonegotiation trigger, type of interface (BASE-X or SGMII), core reset etc. 

- ``mmcm_locked``: MMCM locked signal from the GMII-to-SGMII bridge. This is a signal that indicates that the MMCM is locked and the transceiver is ready. 

- ``reset_done``: Indicates that the module is ready to accept data. Is always '1' for GMII interface, otherwise if provided by the bridge core. 

- ``signal_detect``: Signal detect signal to the GMII-to-SGMII bridge from the SFP transceiver.  

- ``s_axis_udp_tx / m_axis_udp_rx (_tdata/_tvalid/_tlast/_tready)``: AXIS used data interface to the UDP transmitter/receiver.
  AXIS interface is 8-bit wide, blocking, and synchronous to the ``clk125`` clock.

- ``tx_overflow/rx_overflow``: Overflow flags indicating an overflow condition in the FIFOs for the TX and RX paths. These are a sticky signals, reset only by ``rst``.  

- ``tx_port``: Destination port for the next TX packet. Selects whether the packet is sent to TX channel 0 or 1. This signal is synchronous with th rest of the AXIS TX interface, and is register on the last byte of the frame (TLAST=1).

- ``clk125`` clock for the AXIS buses, GMII TX and SGMII stable reset clock. 

- ``rst``: Reset signal for the module. Asynchronous. Also drives the gmii_reset_l signal to the GMII PHY.


Implementation details
======================

Architecture
------------

The UDP/IP/MAC stack is implemented using the following modules:

- `udp_mac_tx`: UDP/ARP packet transmitter with a GMII interface.
- `udp_mac_rx`: UDP/ARP packet receiver with a GMII interface.
- `udp_mac_gmii_to_sgmii`: GMII to SGMII converter used when the PHY type is ``SGMII``


Clocking
--------

In ``GMII`` mode, 125 MHz ``clk125`` clock provided by the user is used for the TX path of the GMII interface. We don't use the TX clock provided by the PHY. The RX path uses the recovered clock, which is sent to a global buffer so it can clock the Rx front end logic.

In SGMII mode, we provide a reference clock, and the GTX generates its RX and TX clocks from it. It generates a 125 MHz clock that is used for both the TX and RX paths of the GMII interface to the the GMII-to_SGMII bridge. The RX path uses the clock that is recovered by the GTX. We still use the ``clk125`` but only as a stable clock for the reset of the GTX core. Note that both a buffered and non-buffered version of the reference clock are provided to the gmii-to-sgmii bridge core in order to allow access to the buffered clock if needed. The buffering is done in the `clocks` module, as the reference clock can also be used as a system clock to drive the system MMCM.

Both `udp_mac_tx` and `udp_mac_rx` have an asynchronous FIFO between the GMII and the user AXIS interface bus clock domain, which is the ``clk125`` clock for both the TX and RX paths.

It is assumed that the GMII clocks (directly from the PHY or derived by the gmii-to-sgmii bridge) are not faster than the ``clk125`` clock.


Principle of operations
-----------------------

`udp_mac_tx` and `udp_mac_rx` provide a GMII (8-bit parallel bus) interface . The `udp_mac_gmii_to_sgmii` module converts the GMII interface to a SGMII interface when the PHY type is ``SGMII`` (e.g. an SFP module), otherwise it just passes the GMII interface through.


If the Rx module received an ARP request, it will set the ``arp_request`` signal to '1' and provide the MAC and IP addresses of the sender in the ``arp_remote_mac_addr`` and ``arp_remote_ip_addr`` signals. The Tx module will detect this request and then send an ARP reply to the sender with the MAC and IP addresses of the local FPGA. Ths transmission will be started when the Tx state machine is in the IDLE state.

