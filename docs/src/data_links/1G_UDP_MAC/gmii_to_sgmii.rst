.. title:: gmii_to_sgmii

**************************************************************************************
:entity:`udp_mac_gmii_to_sgmii` (*udp_mac_gmii_to_sgmii.vhd*): GMII to SGMII Converter
**************************************************************************************

.. parse:: hdl/data_links/1G_UDP_MAC/udp_mac_gmii_to_sgmii.vhd

.. default-role:: vhdl:entity

Overview
========

`udp_mac_gmii_to_sgmii` wraps the Xilinx **GMII-to-SGMII** IP core and its associated
clocking infrastructure (MMCM, BUFGs, BUFH) to present a standard 8-bit GMII interface
over a GTX serial transceiver (e.g., an SFP or SFP+ module). It is instantiated by `udp_mac`
when ``PHY_TYPE = SGMII``. In simulation mode (``SIM = TRUE``) the GTX and MMCM are bypassed.

Entity documentation
====================

.. autoentity:: udp_mac_gmii_to_sgmii

Parameters
==========

- **SIM:** Simulation-mode flag. When ``TRUE``, the GTX transceiver and MMCM are not
  instantiated, allowing behavioural simulation without transceiver models.

Interface
=========

Transceiver interface
---------------------

- ``gtrefclk_nobuf``: Unbuffered 125 MHz GTX reference clock, typically connected directly
  from an ``IBUFGDS_GTE2`` output.

- ``gtrefclk_buf``: BUFG-buffered 125 MHz reference clock. Fed to the bridge core as
  ``gtrefclk_bufg`` (required by the v15 core).

- ``txp`` / ``txn``: Differential serial transmit pair from the FPGA to the SFP transceiver.

- ``rxp`` / ``rxn``: Differential serial receive pair from the SFP transceiver to the FPGA.

GMII interface
--------------

- ``gmii_clk``: 125 MHz clock output derived from the GTX TX output clock (``userclk2``).
  Used to clock all GMII signals on both TX and RX paths.

- ``gmii_txd``: 8-bit transmit data from the client MAC to the PCS.

- ``gmii_tx_en``: Transmit enable from the client MAC to the PCS.

- ``gmii_tx_er``: Transmit error from the client MAC to the PCS.

- ``gmii_rxd``: 8-bit received data from the PCS to the client MAC, registered on ``gmii_clk``.

- ``gmii_rx_dv``: Receive data valid from the PCS to the client MAC.

- ``gmii_rx_er``: Receive error from the PCS to the client MAC.

Control and status
------------------

- ``status_vector``: 16-bit status output from the bridge core (link status, auto-negotiation
  state, speed, etc.).

- ``config_vector``: 32-bit configuration input. Bits [20:16] control the bridge core
  (unidirectional enable, loopback, power-down, isolate, auto-negotiation enable). Bits [15:0]
  set the auto-negotiation advertisement vector. Bit 30 triggers auto-negotiation restart.
  Bit 29 asserts a user reset. Bit 28 indicates loss of signal. Bit 31 selects 1000BASE-X
  vs SGMII mode.

- ``signal_detect``: Signal-detect input from the SFP optical transceiver (active high
  = optical signal present). Internally inverted to produce the ``loss_of_signal`` flag
  fed to the bridge core reset input.

- ``mmcm_locked``: Asserts when the MMCM has locked onto the GTX TX output clock.

- ``reset_done``: Asserts when the GTX transceiver has completed its reset and the bridge
  core is ready.

Clocks and reset
----------------

- ``clk125``: Independent stable 125 MHz clock used as the GT reset logic reference
  (``independent_clock_bufg`` in the bridge core). Must be continuously valid.

- ``reset``: Asynchronous module reset. Drives the PMA reset pipeline and resets the bridge
  core.

Implementation details
======================

Architecture
------------

The module instantiates the ``gmii_to_sgmii_bridge`` Xilinx IP core, an ``MMCME2_ADV`` that
derives 62.5 MHz (``userclk``) and 125 MHz (``userclk2``) user clocks from the 62.5 MHz GTX
TX output clock, and BUFGs/BUFH for clock distribution. A 4-stage synchronizer pipeline on
``clk125`` generates the ``pma_reset`` pulse from the module ``reset`` input.

Clocking
--------

The GTX TX output clock (``txoutclk``, 62.5 MHz, unbuffered) is routed through a BUFG into
the MMCM, which produces ``userclk`` (62.5 MHz) and ``userclk2`` (125 MHz). These drive the
TX user clock inputs of the bridge core. The RX output clock (``rxoutclk``, 62.5 MHz) is
buffered through a BUFH and drives both ``rxuserclk`` and ``rxuserclk2`` of the bridge core.
The GMII interface clock output (``gmii_clk``) is ``userclk2``. ``clk125`` serves only as a
stable independent reference for the GT reset sequencer.

Principle of operations
-----------------------

On reset release the PMA reset pipeline asserts ``pma_reset`` for several ``clk125`` cycles,
initialising the GTX PMA. The MMCM acquires lock on ``txoutclk`` and asserts ``mmcm_locked``.
The bridge core completes its internal reset sequence and asserts ``reset_done``. GMII TX data
is double-registered (two pipeline stages on ``userclk2``) before being presented to the bridge
core to ease timing closure across the GTX placement region. GMII RX data is registered on
``userclk2`` (``gmii_clk``) before being driven onto the output ports.
