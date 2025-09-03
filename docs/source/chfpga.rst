
*******************************
:entity:`chfpga` (`chfpga.vhd`)
*******************************

.. default-role:: vhdl:entity

Overview
========

chFPGA is the common module that is used to implement the core firmware for all configurations of all platforms. This entity uses parameters passed as generics or defined in the configuration file to select which sub-modules are instantiated and in which quantities, how they are configured and how they are connected.

chfpga is normally instantiated by a platform-specific top module that creates the platform-specific logic (board-specific ports, clock and data buffers etc.) that connects chfpga to the outside world.

`chfpga` instantiates the following sub-modules:

- System modules

    - Clocking system (`clocks`)
    - System Bus master (`master` and routers `router` with optional `UDP_MAC` 1G Ethernet interface)
    - GPIO and general configuration registers (`GPIO`)
    - I2C and SPI controllers (`I2C` and `SPI`)
    - System monitor (`SYSMON`)
    - Reference clock/ synchroniztion sequencer (`REFCLK`)
    - Frequency counter (`FREQCTR`)
    - Heartbeat LED blinker (`blinker`)


- ADC Data acquisition logic

- F-Engine/Channelizers

- Corner-turn Engine

- X-Engine/Correlator

- 10/100 G Ethernet Data real-time streaming interfaces

- Data capture engine

Schematic
=========

.. .. figure:: ../images/chfpga.svg
..     :width: 100%



Entity documentation
====================

.. parse:: hdl/chfpga.vhd

.. autoentity:: chfpga


Description
===========

-The firmware can acquire the data and channelize N antenna signals coming from the ADC board through the FMC connector. The number of supported antennas is set by a variable in the firmware. The channelization is performed by a CASPER Polyphase filter bank (PFB)/FFT. A scaler module brings the frequency samples into a (8+8) bit complex number format. The FFT and the scaler modules can be bypassed for debugging purposed.

-The channelizer can be set to use data from three sources: the ADC chip, from a firmware-based function generator that can generate various patterns or from a injection buffer that allows the user to send data patters to be processed.

-The data at the output of the channelizer can be captured and streamed over the Ethernet interface. If the FFT is bypassed, the timestream is captured instead. The number of frames to capture and the frequency of the captures can be set by software.

-The firmware can implement M streaming correlators that correlate the (8+8) bits complex frequency samples from the N antennas. Each correlator is programmed to process a fraction of the frequency bins grabbed from each antenna data streams. Multiple correlators are used to cover all designed frequency bins. The correlators operate on a separate clock from the data acquistion. The number of frequency channels that can be processed (and there the total number of correlators needed) depends on the correlator speed and the maximum accumulator depth.  The integration time and the data capture time can be set independently by software.

-All data processing modules and the control interfaces are interconnected through a standard AXI4 Streaming bus. This makes system interconnections and scaling easy.

-The design contains no processor or associated firmware. A simple UDP packet receiver/transmitter implemented as a state machine receives simple command frames and returns data. Every module in the system is mapped to a specific memory space in which control and status registers can be read or written.




Memory Map
==========

Top level memory map
--------------------

.. include-docs:: chfpga
    :start-after: Top-level Memoy map



Channelizers memory map
-----------------------

.. include-docs:: chfpga
    :start-after: Channel Memory Map

Submodules
==========

The following modules are instantiated directly by `chFPGA`:


.. toctree::
    :maxdepth: 1
    :hidden:

    System<system/system>
    F-Engine<channelizer/chan>
    CT Engine <corner-turn/corner-turn>
    X Engine <correlator/correlator>
