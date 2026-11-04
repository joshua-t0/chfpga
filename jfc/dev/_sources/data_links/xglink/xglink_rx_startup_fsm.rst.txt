.. title:: xglink_rx_startup_fsm

***************************************************************************************
:entity:`xglink_rx_startup_fsm` (*xglink_rx_startup_fsm.vhd*): RX Startup State Machine
***************************************************************************************

.. parse:: hdl/data_links/XGLINK/xglink_rx_startup_fsm.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: xglink_rx_startup_fsm

Parameters
==========

- **EXAMPLE_SIMULATION:** Set to ``1`` to shorten internal time-out counters for faster simulation. Default is ``0`` (real hardware timing).

- **GT_TYPE:** GTX variant string (e.g. ``"GTX"``). Used for simulation-model selection inside the Wizard-generated code.

- **EQ_MODE:** RX equaliser mode: ``"DFE"`` enables the Decision Feedback Equalizer; ``"LPM"`` selects the Linear Phase equaliser. Default is ``"DFE"``.

- **STABLE_CLOCK_PERIOD:** Period of ``STABLE_CLOCK`` in nanoseconds (range 4–250). Default is 8 ns (125 MHz). All internal time-out counters are scaled by this value so absolute durations are preserved regardless of clock frequency.

- **RETRY_COUNTER_BITWIDTH:** Width of the retry counter output (range 2–8). Default is 8 bits (up to 255 retries).

- **TX_QPLL_USED:** Set to ``True`` when the TX path also uses the QPLL, so the RX FSM does not issue a redundant QPLL reset.

- **RX_QPLL_USED:** Set to ``True`` when the RX path uses the QPLL (10 Gb/s operation). When ``False``, the CPLL path is assumed.

- **PHASE_ALIGNMENT_MANUAL:** When ``True``, the FSM drives ``RUN_PHALIGNMENT`` and waits for ``PHALIGNMENT_DONE`` before completing startup. For single-lane designs the automatic alignment is sufficient and this can be set to ``False``.

Interface
=========

Clocks
------

- ``STABLE_CLOCK``: Stable free-running clock present from power-on. Drives all time-out counters.

- ``RXUSERCLK``: RX user clock from the GTX (recovered clock after buffering). Used to synchronise reset-done flags.

Status inputs
-------------

- ``SOFT_RESET``: User-driven reset; can be asserted at any time to restart the RX initialization sequence.

- ``QPLLREFCLKLOST`` / ``CPLLREFCLKLOST``: Reference-clock loss indicators from the QPLL / CPLL.

- ``QPLLLOCK`` / ``CPLLLOCK``: PLL lock indicators from the QPLL / CPLL.

- ``RXRESETDONE``: GTX ``RXRESETDONE`` output indicating the RX PMA and PCS are ready.

- ``MMCM_LOCK``: MMCM locked indicator for the recovered-clock MMCM (if used).

- ``RECCLK_STABLE``: Indicates the recovered clock frequency is within the expected range.

- ``RECCLK_MONITOR_RESTART``: Restarts the recovered-clock frequency check (default ``'0'``).

- ``DATA_VALID``: Asserted by the block-sync state machine when 64B/66B synchronisation has been achieved. Used to trigger the data-valid monitor and auto-reset on persistent errors.

- ``TXUSERRDY``: ``TXUSERRDY`` output from the GTX (driven by the TX startup FSM) used to coordinate TX/RX reset ordering.

- ``DONT_RESET_ON_DATA_ERROR``: When ``'1'``, suppresses the automatic FSM restart on a persistent ``DATA_VALID=0`` condition.

- ``PHALIGNMENT_DONE``: Asserted by the phase-alignment logic when manual phase alignment has completed.

Control outputs
---------------

- ``GTRXRESET``: Hard GTX RX reset output; driven high during the reset sequence.

- ``MMCM_RESET``: Resets the recovered-clock MMCM.

- ``QPLL_RESET``: Resets the QPLL (only when ``RX_QPLL_USED=True`` and the QPLL was not already reset by the TX FSM).

- ``CPLL_RESET``: Resets the CPLL (only when ``RX_QPLL_USED=False``).

- ``RX_FSM_RESET_DONE``: Asserted when the complete RX initialization sequence has finished successfully.

- ``RXUSERRDY``: Driven high at the appropriate point in the sequence to enable the GTX RX data path.

- ``RUN_PHALIGNMENT``: Triggers the external phase-alignment logic.

- ``RESET_PHALIGNMENT``: Resets the phase-alignment logic at the start of each retry.

- ``RXDFEAGCHOLD`` / ``RXDFELFHOLD``: DFE AGC and LF adaptation hold signals.

- ``RXLPMLFHOLD`` / ``RXLPMHFHOLD``: LPM LF and HF adaptation hold signals.

- ``RETRY_COUNTER``: Saturating counter that records how many times the FSM retried initialization before succeeding.

Implementation details
======================

Principle of operations
-----------------------

The FSM sequences through the following states: ``INIT → ASSERT_ALL_RESETS → WAIT_FOR_PLL_LOCK → RELEASE_PLL_RESET → VERIFY_RECCLK_STABLE → RELEASE_MMCM_RESET → WAIT_FOR_RXUSRCLK → WAIT_RESET_DONE → DO_PHASE_ALIGNMENT → MONITOR_DATA_VALID → FSM_DONE``.

All time-out durations (500 ns post-config delay, 2 ms PLL lock wait, 100 µs MMCM lock wait, etc.) are derived from ``STABLE_CLOCK_PERIOD`` at elaboration time so absolute timing is correct regardless of the stable-clock frequency.

Once in ``MONITOR_DATA_VALID``, the FSM watches for a sustained ``DATA_VALID=0`` condition. If ``DONT_RESET_ON_DATA_ERROR='0'``, it will automatically restart the sequence after a timeout, incrementing ``RETRY_COUNTER``. ``'1'`` on ``DONT_RESET_ON_DATA_ERROR`` disables this auto-recovery.

The module is generated by the Xilinx 7-Series FPGAs Transceivers Wizard and is instantiated in `xglink_core`.
