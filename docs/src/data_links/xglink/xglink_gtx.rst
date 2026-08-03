.. title:: xglink_gtx

****************************************************************
:entity:`xglink_gtx` (*xglink_gtx.vhd*): GTX Transceiver Wrapper
****************************************************************

.. parse:: hdl/data_links/XGLINK/xglink_gtx.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: xglink_gtx

Parameters
==========

- **GT_SIM_GTRESET_SPEEDUP:** String attribute forwarded to the ``GTXE2_CHANNEL`` primitive. Set to ``"TRUE"`` to shorten reset time-out counters in simulation.

- **RX_DFE_KL_CFG2_IN:** Bit-vector configuring the GTX DFE KL equalizer register. Value is specific to the target PCB and loss budget.

- **PMA_RSV_IN:** PMA reserved attribute bit-vector. Used to enable GTX silicon workarounds as directed by Xilinx answer records.

- **PCS_RSVD_ATTR_IN:** PCS reserved attribute bit-vector (48 bits). Controls internal GTX PCS options per Xilinx guidelines.

Interface
=========

Serial I/O
----------

- ``gtxtxp_out`` / ``gtxtxn_out``: Differential TX serial output to the connector / SFP cage.

- ``gtxrxp_in`` / ``gtxrxn_in``: Differential RX serial input from the connector / SFP cage.

Clocking
--------

- ``qpllclk_in`` / ``qpllrefclk_in``: QPLL output clock and QPLL reference clock inputs from the quad QPLL.

- ``rxusrclk_in`` / ``rxusrclk2_in``: RX user clocks (typically both driven by the buffered RX recovered clock).

- ``txusrclk_in`` / ``txusrclk2_in``: TX user clocks (both driven by the TX word clock).

- ``rxoutclk_out``: Unbuffered recovered RX clock output; must be routed through a BUFH or BUFG before use.

- ``txoutclk_out`` / ``txoutclkfabric_out`` / ``txoutclkpcs_out``: TX clock outputs for the fabric, fabric global, and PCS paths respectively.

- ``rxratedone_out``: Asserted when a rate change requested via ``rxrate_in`` has completed.

TX datapath
-----------

- ``txdata_in``: 32-bit TX data word from the 64B/66B framing logic.

- ``txheader_in``: 2-bit 64B/66B sync header accompanying ``txdata_in``.

- ``txsequence_in``: 7-bit gearbox sequence counter.

- ``txbufstatus_out``: 2-bit TX buffer status (overflow / underflow flags from the TX elastic buffer).

- ``txpolarity_in``: TX lane polarity inversion (use when PCB differential pairs are swapped).

- ``txinhibit_in``: Disables the TX driver when ``'1'``.

RX datapath
-----------

- ``rxdata_out``: 32-bit RX deserialized data word.

- ``rxheader_out``: 2-bit 64B/66B sync header received with ``rxdata_out``.

- ``rxheadervalid_out``: ``'1'`` when ``rxheader_out`` is valid (gearbox aligned).

- ``rxdatavalid_out``: ``'1'`` when ``rxdata_out`` contains valid payload data.

- ``rxstartofseq_out``: Gearbox start-of-sequence indicator.

- ``rxgearboxslip_in``: Gearbox-slip command from the block-sync state machine (`xglink_block_sync`).

- ``rxbufstatus_out``: 3-bit RX buffer status.

- ``rxcharisk_out``: 2-bit K-character indicator (used in 8B/10B mode; not applicable for 64B/66B).

- ``rxpolarity_in``: RX lane polarity inversion.

RX equalization
---------------

- ``rxlpmen_in``: Selects Linear Phase Equalizer (LPM) mode when ``'1'``; DFE mode when ``'0'``.

- ``rxdfelpmreset_in``: Resets DFE/LPM adaptation.

- ``rxlpmhold_in`` / ``rxlpmovrd_in``: LPM adaptation hold and override vectors.

- ``rxdfehold_in`` / ``rxdfeovrd_in``: DFE adaptation hold and override vectors.

- ``rxmonitorout_out`` / ``rxmonitorsel_in``: RX monitor bus and selector for eye diagnostics.

- ``dmonitorout_out``: 8-bit DFE digital monitor output.

- ``rxcdrhold_in``: Holds the CDR when ``'1'``.

Reset and initialization
------------------------

- ``gttxreset_in`` / ``gtrxreset_in``: GTX TX / RX hard reset inputs.

- ``txpcsreset_in`` / ``txpmareset_in``: Individual TX PCS / PMA reset inputs.

- ``rxpcsreset_in`` / ``rxpmareset_in``: Individual RX PCS / PMA reset inputs.

- ``txuserrdy_in`` / ``rxuserrdy_in``: User-ready enables; held low until the startup FSMs confirm clocks are stable.

- ``txresetdone_out`` / ``rxresetdone_out``: Reset-complete indicators from the GTX primitive.

- ``eyescanreset_in`` / ``eyescantrigger_in`` / ``eyescandataerror_out``: Eye-scan control and status.

DRP
---

- ``drpaddr_in`` / ``drpclk_in`` / ``drpdi_in`` / ``drpdo_out`` / ``drpen_in`` / ``drprdy_out`` / ``drpwe_in``: Dynamic Reconfiguration Port for runtime attribute access.

PRBS / loopback
---------------

- ``txprbssel_in`` / ``txprbsforceerr_in``: TX PRBS pattern generator select and force-error.

- ``rxprbssel_in`` / ``rxprbserr_out`` / ``rxprbscntreset_in``: RX PRBS checker select, error flag, and counter reset.

- ``loopback_in``: 3-bit loopback mode select (near-end PCS, near-end PMA, far-end, etc.).

- ``rxrate_in``: 3-bit RX rate divider select.

TX driver
---------

- ``txdiffctrl_in``: 4-bit TX differential swing control.

- ``txpostcursor_in`` / ``txprecursor_in``: 5-bit post- and pre-cursor emphasis.

- ``txmaincursor_in``: 7-bit main cursor amplitude.

Implementation details
======================

Principle of operations
-----------------------

`xglink_gtx` is a thin VHDL wrapper generated by the Xilinx 7-Series FPGAs Transceivers Wizard around the ``GTXE2_CHANNEL`` primitive. It exposes exactly the port subset needed by `xglink_core`, mapping signal names to the primitive's port map without additional logic.

The GTX uses the QPLL for 10 Gb/s operation (``LINK_SPEED=1``) to achieve the required 10.3125 Gb/s line rate with a 156.25 MHz reference clock. All RX/TX startup sequencing is handled externally by `xglink_rx_startup_fsm` and `xglink_tx_startup_fsm`.
