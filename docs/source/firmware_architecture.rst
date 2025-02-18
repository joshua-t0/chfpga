*********************
Firmware Architecture
*********************

.. default-role:: entity

VHDL flavor
===========

The source code for `chfpga` is written in VHDL2008. Although the original code was written for VHDL93, the modules have gradually been using VHDL2008 as it significantly simplifies the code. We have not attempted to preserve VHDL93 compatibility.

All files in the project must be tagged to use the VHDL2008 file type, otherwise the synthesizer will fail to compile many files. The default file type of files added to a project is "VHDL", meaning VHDL93. It must explicitely be changed to VHDL2008.


Top module: platform wrappers
=============================

The platform wrapper is the top-level file of the project. It provides the logic and parameters that are specific to a specific platform:

- Hardware-specific constants to be passed to the `chfpga` module such as reference clock source and frequency, type of ADC etc.
- I/O Ports
- Clock and data buffers
- Instantiate the Processing System (PS) block diagram when applicable
- Repackaging of the external signals and buses to the format expected by the `chfpga` module

The platform wrapper is responsible for instantiating the  `chfpga` module and passing it all the hardware- and application-specific parameters.

The platfom wrapper shall be named using the following format::

   chfpga_<platform name>.vhd



I/O buffers
===========

In general, the clock and data buffers shall be instantiated in the platform wrapper, as these are generally hardware-specific.

Note that some modules define their own clock or data buffers  instead having those be defined in the platform module. Some exceptions are:

- `clock` module: defines the clock input buffer based on the clock source parameter.
-  SPI or I2C peripherals: defines their own data buffers to facilitate tristate operation or improve timing.
-  Modules using GTXes or GTYs typically define their own buffers.

In many cases the  exceptions exist mainly for historical reasons, but since having local buffers reduces the size and complexity of the platform file, we have not moved out the buffers from those modules.

Configuration file
==================

The configuration file is a package that defines a number of constants needed to configure the firmware functionality. We refrain from including hardware-specific parameters in this file, e.g., parameters that can never change for a specific platform; those shall be defined in the platform-wrapper. Of course, some firmware functionalities are platform-specific (such as modules using UltraRAM for example) but could be implemented in other ways in the future, and shall therefore be defined in the configuration file.

Configuration files shall define a package named ``chfpga_config``. The selection of the configuration file for a particular build is done by including the desired configuration file in the project. Configuration files must therefore have unique names in the following format::

    chfpga_<platform name>_<config name>_config.vhd

The labels of all constants in the package shall have the format::

    CONFIG_<subsystem name>_<parameter name>

Platform and configuration names
================================

The following platform and configuration names shall be used.

Platforms:

- IceBoard: ``mgk7mb_rev2``
- CRS: ``crs``
- KC705: ``kc705``
- ZCU111: ``zcu111``

Configurations:

- Channelizer and Corner-turn engine with real-time data offload: ``ct``
- Channelizer with on-board corner-turn and correlator: ``corr``



Parameter flow, generics and OOC modules
========================================

As a rule, we try to pass every parameter that a module (and its sub-module) might need as generics to that module. We try to avoid using the parameters defined in the configuration directly; those shall be passed to chFPGA as generics from the platform wrapper module.

There is one exception to this: out-of-context (OOC) module (i.e. modules that are synthesized once and mused multiple times, such as the channelizer). OOC modules cannot be instantiated with generics. The module itself *can* have generics, but the defaults must be used. In these case, the VHDL file that implements the entity imports the configuration file and use its constants to set the default values of the generics. The code in the module should then use these generics, not the configuration file constant. An example of this is the :entity: module.


`chfpga`: a module to rule them all
===================================

The core firmware for every configuration of the firmware for every platform is implemented using the same :module:`chfpga` module.
Of course, this module takes a large number of generics that are passed by the hardware platform and configuration file to enable the various hardware- and application-specific modules with the desired geometry.


Command system
==============


Principle of operations
-----------------------

The operation of `chFPGA` is controlled by exclusively by reading or writing bytes to submodules registers and memory blocks. Each submodule has its own memory-papped address range.

- Control register page
- Status register page
- DRP (Direct reconfigurable ports) or Memory (BRAM or URAM) page



Address space / pages
---------------------

The address space is 19 bit wide. Commands can access one of the following 19-bit address spaces (pages):

The page to access is determined by the command code only, not the address. Each page therefore can access its own 19-bit address space independently, that is, the address space is not shared between pages.





Byte-Serial-Bus (BSB)
---------------------

In general, operating the FPGA is a set-and-forget operation. There is little need for a high-bandwidth interface for accessing the registers and memory buffers except for the initial setup, but the bus needs to propagate to each sub-sub-submodule. This is different from  real-time data pipeline which continuously needs a high bandwidth but has a linear and limited topology.

In order to preserve resources in the FPGA and make it easier to meet timing, access to the FPGA memory-mapped space is done using a Byte-serial-Bus protocol. BSB protocol is implemented using a 8-bit AXI-Stream command bus and a 8-bit AXI-stream reply bus. Commands are sent as packets, where the operation (read, write), byte-count andaddress are encoded in a 3-byte (24-bit) header, followed by any number of data bytes. Each command is acknowledge by a reply packet that contains the command status and the requested data.

A BSB operating at 125 MHz can accomodate the full bandwidth of a 1G Ethernet interface while making timing closure easy to meet.




Command and reply packet format
-------------------------------



Routing
-------

Control and status registers
----------------------------

Some rules have been set on how the control and register accesses should behave:

- Control registers are always read/write. Reading a control register will always return the last value written to it. All the bits of each register can be read back, even if these bits are not connected to any logic.
- Reading or writing a register shall never have any side-effect other than changing the register value or returning the result. Triggers shall be based changes in the register values, not the fact that a read/write transaction has occure. This means that writing a register multiple times with the same value shall be the same as writing it only once. This is necessary to allow safe retries in case of lost packets.
- Status registers are always read only.


RAM/DRP
-------

An BSB endpoint implements any number of control registers, status registers, and either a RAM or DRP interface.

DRP interface implements a 16-bit data bus, whereas a RAM interface has a 8-bit data bus.



The commands are:

- Write control register
- Write control register with mask
- Read control register
- Read status register
- Write DRP/RAM
- Read DRP/RAM

.. Internal buses
.. ----------------

.. include:: internal_buses.rst



Software interface
==================

Configuration management
------------------------

- Software should determine the capability of the firmware by reading registers in order to instantiate and configure the corresponding Python objects accordingly.
- Capability registers that inform on whether a module is present or not are typically found in the GPIO module. Access to a module shall not be made unless we know the module is there to respond. The GPIO module shall be instantiated first to gather the firmware capability information before instantiating the rest of the objects. Presence of a module should **not** be detected by checking if  access to one of its registers succeeds.
- Module-specific capability registers can be placed in their specific modules.
- We generally try to put as much capability information in capability registers as possible to minimize the need to keep the Python code up to date with firmware changes. However, Python-based look up tables might be necessary to provide detailed configuration based on some FPGA capability register in order to minimize the amount of logic resources allocated to these registers. This is the case of platform-specific constants which are looked up from the PLATFORM_ID parameter found in GPIO.
-

Data buses
==========


We use exclusively AXI4-Streaming to carry both the science data and the control/monitoring system.

Generally non-blocking. There is generally no point in blocking the main pipeline: data rate is so high that we can't block for a significant amout of time and not run out of memory. Slow control interfaces are not in this case.
Blocking brings issues with timing. Tready cannot be registered unless we introduce a 1-deep FIFO at each stage. Bad for timing.
Sometimes implement loose backpressure: to avoid confusion, we use the `send` signal instead of tready since we break protocol. Send can be pipelined, but it is expected that data in the pipe will continue flowing until the send has made its way to the source. This is fixed by having an elastic FIFO at the end that requests stop sending before there is no more space left in the FIFO (i.e. use almost full to drive send). This greatly simplifies the logic by using a free feature of the FIFOs. This is used at the output of the channelizer (to allow their outputs to be aligned), and on the daisy-chained outputs of the correlator.


Vivado quirks
=============

Simulation
----------

Vivado simulation (VS) does not seem to have a good reputation, sepecially for VHDL2008. Howeer, the tool seems to simulate the current code correctly, even as we ass more and more VHDL 2008 idioms in the code.

Older versions of VS had a hard time handling ``struct`` passed as port arguments, or indexing those right on the port assignments. We also discovered a buffer overrun condition where setting value in one field affected another one. But these seem to have been solved as of Vivado 2022.2.

Nevertherless, here are the list of strange behaviors that were observed


- Feb 2025, Vivado 2022.2: Crash caused by a assignment outside the range of a vector. No useful message. Had to bisect-disable code to find this out.
- Jan 2025, Vivado 2022.2: Got the impression that we could not use VHDL 2008 on the testbench, but it was ok for any submodules. But then it worked for another testbench, with or without the `-2008` simualtion option. Maybe an error on my part?
- 2022.2: restarting a simulation after adding signals at the bottom  of the waveform list sometimes just crashes the GUI. Save often.
Generic tricks

- When simulaiton does not work because of missing modules, restart a full simulation instead of using the re-run button.