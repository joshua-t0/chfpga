.. title:: PROBER

*********************************************
:entity:`prober` (*prober.vhd*): Data capture
*********************************************

Overview
========
Prober periodically captures bursts of up to 4 data frames from one of two user-selectable sources and streams them over an 8-bit AXI4 STREAM interface as packets with a header indicating data flags, frame number, stream ID etc. The number of frames to capture in a contiguous burst and the number of frames between capture bursts are configurable by software through BSB memory-mapped registers. The data source and fast data capture rates can be changed at any time during operation without resetting the data pipeline.

Schematic
=========

.. figure:: ../images/CHAN/prober.svg
    :width: 50%

.. todo:: Update block diagram. No mode header FIFO. Show registers cross-clock domain crossings.

.. parse:: hdl/chan/prober.vhd


Entity documentation
====================


.. autoentity:: prober



Principle of operations
=======================

Interface signals
------------------

Data is provided to `PROBER` over two 32-bit non-blocking AXI4-Streaming interfaces operating in the ``in_clk`` clock domain. 
``in_dat0`` and ``in_dat1`` are inputs for sources 0 (typically `FUNCGEN` output) and 1 (`SCALER` output) respectively.

Data frames from the selected source are buffered and streamed out using an 8-bit wide blocking AXI4-Streaming interface operating on the ``out_clk`` clock domain. The output packets contain a 10-byte header followed by frame contents. 

A BSB interface operating on the ``ctrl_clk`` clock provides access to the memory-mapped control and status registers. 

Clocking and resets
-------------------

The input stream, output stream and BSB stream operate on the ``in_clk``, ``out_clk`` and ``ctrl_clk`` clocks. These are fully independent clocks, although ``out_clk`` is usually identical to ``ctrl_clk``. 

``in_reset`` is asynchronous, as it is combined with the software-controlled reset and power-on reset and passed through a CDC synchronizer to generate the main data FIFO reset signal ``rd_rst``.

``ctrl_reset`` is synchronous to ``ctrl_clk``. 

The reset signals are active high.


.. todo:: Clarify if resets are synchronous or asynchronous, and whether data can be active during reset. 

Period counters
---------------

Two independent counters continuously count frames from both sources simultaneously, each with its own programmable period. These are called primary periods. A burst capture starts when the primary period counter reaches the programmed value. Independent counters are used to ensure that the frames are always captured on a multiple of the primary period, even if we switch to another source and come back to the original source. 

Primary period counters are set to 0 at reset. A reset is required every time a primary period is changed to make sure the logic does not miss the new count. The primary periods are therefore usually set at system setup before the global pipeline reset, and are not changed during system operations. Changing source does not require a reset.  

A sub-period counter can be used to generate additional burst capture events by triggering a capture every 2**(N+1) frames after each primary period capture. This sub-period is common to both channels, and can be changed at any time during operations. Such live changes do not confuse the logic because the sub-periods are always powers of 2 and the trigger logic operates by looking at binary patterns in the period counter. Primary and sub periods should, however, be selected such that the last sub-period capture is not too close to the next primary period capture, otherwise the buffers will overflow.

In typical applications, the primary periods are set to the slowest capture rate the system will use (such as for usual data monitoring), and the sub-period is set when higher data cadence is needed for time tasks such as calibration.


Data capture method
-------------------

A burst capture is triggered on the last word of a frame when the period counter is zero or the sub-period bits of the period counter are all zeros. When this happens, ``burst_capture`` is asserted and the timestamp is captured. Data is stored in the FIFO while burst_capture is asserted. On the TLAST word of a frame during a capture, the TUSER flags are stored in an array, and on the last frame of the burst, a readout request is asserted by toggling the readout request bit.

The readout request is passed to the output clock domain using a CDC synchronizer and data transmission starts when the bit state change is detected. At this point, the frame number and TUSER flags are frozen, so they can be read safely in that clock domain. For each frame of the burst, the readout state builds a header, sends it byte by byte, and then reads the data FIFO one word at a time and sends it byte by byte using a mux. We don't use an asymmetric FIFO because FIFO36E2 does not support it, and we have to use a mux anyway to send the header.

When data transmission is complete, the acknowledge bit is set to match the request bit, which is CDC'ed to the write domain for the write logic to detect if it is requesting to store a new burst before the previous burst was finished transmitting. If that happens, the sticky overrun bit is set, and data capture is not started to prevent interference with the ongoing transmission.


Header format
-------------

The header format is defined in the ``chfpga_package.vhd`` file. The header contains the following information:

- Byte 0: 8-bit cookie, which is ``0xA0`` for source 0 and ``0xA1`` for source 1

- Bytes 1-2: 16-bit STREAM ID.  MSB (byte 1) is sent first.

    * Bits 15:12: Frame number (0 to N-1, where N is the number of frames per burst)
    * Bits 11:4: User-programmable stream-ID, usually consisting of the crate number (bits 11:8) and the slot number (bits 7:4)
    * Bits 3:0: User-programmable. Generally the channel number.

- Byte 3: 

    * Bit 7: ``'0'``
    * Bits 6:4: Lower 3 bits of the TUSER flags on the last word of the frame
    * Bits 3:0: Lower 4 bits of the TUSER flags on the last word of the frame

- Bytes 4-9: 48-bit TIMESTAMP (i.e., frame number. This field corresponds to the frame number of the first frame in a burst. All frames in the same burst have the same timestamp)

.. todo:: Add a figure showing the header format.

.. todo:: Update code to use a UCAP-like header format. Byte3 = 0000mmss where mm=mode and ss=subframe, replace the zeros with TUSER flags. Check if scaler issues TUSER flags, and does it combine all the scaler overflow flags?

Data FIFO
---------

The data FIFO is a 36-bit wide, 2048-word deep FWFT asynchronous FIFO with zero read latency. The FIFO stores the 32-bit data plus the TLAST flag, with the remaining bits being unused. The FIFO is implemented using two 18-bit x 2048 FIFO36E2 primitives in parallel to reduce fabric logic utilization and because the XPM_FIFO macro does not support the embedded FIFO. The input data is presented in the 36-bit wide ``data_fifo_din``. The lower 18 bits are fed to the ``di`` and ``dip`` port of the first FIFO primitive, and the upper 18 bits are fed to the other.


.. todo:: describe FIFO resets



Readout state machine
---------------------

The state machine is in the following states:

- SEND_STDBY: The state machine waits for the readout request bit to change. When detected, the delay counter is cleared and we switch to the SEND_DELAY state.
- SEND_DELAY: We wait until the delay counter reaches the delay value (incrementing on every readout clock), then we clear the byte and burst counter and jump to the SEND_HEADER state.
- SEND_HEADER: The header bytes are sent one by one, then we switch to SEND_DATA state. 

  Note that the header bytes are never stored in registers (that would take 10 bytes, or 80 FFs). 
  We just build the header and convert it to a byte array as a variable, and send the byte indexed by the byte counter. The synthesizer will optimize this into muxes that will select data that is already stored elsewhere and won't change during the header transmission process.  
- SEND_DATA: The FIFO data is sent byte by byte, and a new FIFO read is performed on the last byte of the word. We return to the SEND_HEADER when we reach the TLAST word and there are more frames to send. We go back immediately to SEND_STDBY state if there is no more data in the FIFO. Using the FIFO valid (not empty)  works as an *end-of-transmission* flag because 1) data transmission starts only when all frames of the burst are stored and 2) No more data is stored until transmission is complete (due to the acknowledge bit). This approach avoids the need for a separate FIFO-stored end-of-transmission flag (that could be missed in the case of a FIFO overflow) and avoids the need to synchronize a burst-count value between clock domains.





.. .. figure:: ../images/CHAN/prober_write_data.svg
..     :width: 25%



Memory Map
==========

.. include-docs:: prober
    :start-after: CAPTURE (PROBER) Module Memory Map
