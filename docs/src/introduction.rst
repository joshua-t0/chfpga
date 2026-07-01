

.. title:: chFPGA

.. .. image:: images/chfpga_logo.svg
..    :width: 30%

.. -------------------------------------------------


Introduction
************


..  chFPGA: Data acquisition, Channelizer, corner-turn and correlator engine FPGA firmware for the IceBoard FPGAs

``chFPGA`` is a multiplatform FPGA firmware designed to implement wide bandwidth radiotelescope and radio-interferometers front-ends. It provides the following components:

- F-Engine (channelizer)
- Corner-turn engine (groups data from one or multiple boards by frequency)
- Optional X-engine (:math:`N^2` correlator)
- Optional real-time 80G/100G Ethernet streaming of corner-turned data
- Hardware platform management and peripheral controllers...

A block diagram of the firmware is provided below.

.. figure:: ./images/chfpga_simple_block_diagram_v2.svg
   :width: 70%


Features
========

The main features of ``chFPGA`` are:

- Platforms

   - Runs on Virtex 6, Kintex 7 and Ultrascale+ Xilinx/AMD FPGA platforms
   - FPGAs with embedded ARM processing system can interface directly with chFPGA using DMA streams

- Firmware components configurable through a configuration file:

   - Number of channels
   - Data/FFT bit width
   - Types and geometry of FFT/PFB, corner-turn, correlator
   - Clock sources and speed
   - etc.

- ADC inputs

   - Acquires data from external FMC ADCs or from internal data converters (RfSoC FPGAs)
   - Operates at sampling rates of up to 3200 MSPS @ 14 bits per sample (Ultrascale+)

- F-Engine (a.k.a. channelizer)

      - Supports waveform/test pattern/noise injection.
      - FFT based on resource-efficient CASPER PFB/FFT.
      - Output scaled down to (4+4i) bits using programmable per-frequency digital gains

- Corner-turn engine

   - Flexible frequency selection map
   - Can be scaled from a single board up to 32 boards
   - Uses backplane or SFP/QSFP links to perform 10/25Gbps data exchange between boards

- X-Engine

   - Processes (4+4i)-bits data from the corner-turn engine
   - Scaleable to any number of inputs
   - Is highly optimized for maximum density and speed.

- Real-time data offload

   - Implements 8x10G or 100G Ethernet links over UDP
   - Includes test packet generators

- Data monitoring

   - Raw ADC/FFT/SCALER data can be captured periodically
   - Data source can be switched dynamically without affecting the science data
   - Data is sent through the shared command link (1G Ethernet)

- Hardware support

   - Supports multiple peripherals: SPI, I2C, System monitor, frequency counter, IRIG-B, Buck converter synchronizer etc.
   - Can operate with various reference clock frequencies.

- Control interface

   - Configuration, operation and monitoring of every sybsystem performed through memory-mapped read/write registers accessed through a lightweight 8-bit bus interface.

Python control software
=======================

`chFPGA` is operated through the ``pychfpga`` Python package, which provides a Python high-level interface to every subsystem of the `chFPGA` firmware and provides platform wrappers and servers for on-site automated operations.


Supported hardware platforms
============================

``chFPGA`` has been used on multiple hardware platforms FPGAs:


- **ML605** : *Xilinx ML605 Virtex 6 Evaluation kit*, with one HPC and one LPC FMC connector for ADC mezzanine boards.  The first full firmware implementations of ``chfpga`` were done on that platform around 2010. The code base has not been maintained since we moved to the more scalable IceBoard and because the modern development tools that we use (Vivado) no longer support the Virtex 6.

- **KC705** : *Xilinx KC705 Kintex 7 Evaluation board*, with two HPC FMCs. Used for prototyping the chfpga before the availability of the IceBoards.

- **MGK7MB/IceBoard**: *McGill Cosmology Lab MGK7MB/IceBoard* is a home-made Kintex 7 FPGA board with two HPC FMCs, which was designed specifically for implementing large and fully synchronized high-density array of FPGA boards. With chFPGA, each board can digitize and process 16 analog inputs at 800 MSPS @ 8 bits.  Those boards are used for large interferometers such as the CHIME telescope (128 boards), but are also used for smaller outrigger telescopes or benchtop experiments. More than 500 such boards have been produced.

- **ZCU111**: *Xilinx Ultrascale+ RfSoC Evaluation board* was the first RfSoC platform on which chFPGA was ported to make use of the  embedded high-frequency ADCs and 100G Ethernet interfaces. On this platform, chFPGA can acquire and process 8 analog inputs at 3000 MSPS.

- **CRS**: *t0 Ultrascale+ RfSoC* is a compact RfSoC FPGA board designed to implement next-generation high performance and large-density signal processing arrays. On these boards, chFPGA can process 8 analog channels at 3200 GSPS @ 14 bits, perform on-board N^2 correlationor corner-turn the channelized data and stream it through its 100G interface.

The firmware is structured so new platform wrappers and configuration files can be added with minimal effort.


.. 16 ADC analog channels at 800 Msps, channelizes the data in 1024 frequency bins (F-engine), and can either implement an on-board 16-channel correlator (X-engine) or reorder and redistribute the data with other boards before sending it to an external correlator.

Real-world applications
=======================

``chFPGA`` was originally designed for the Canadian Hydrogen Intensity Mapping Experiment (CHIME) radiotelescope, which consists of an array of 128 Kintex-7 FPGA boards (IceBoards) that digitizes 1024 dual-polarization feeds at 800 MHz @ 8 bits per sample, implement a 2048-sample FFT, scales and  corner-turns the data between groups of 32 boards, and feeds the real-time baseband data to a 256-node GPU-based correlator farm. The firmware is also used on the same platform by  ``CHIME`` outriggers and the ``HIRAX`` telescope.

``chFPGA`` is also used on an array of 128 Xilinx Ultrascale+ RfSoC FPGA boards (CRS platform) to digitize the signals from 512-dual-polarization feeds, sample the feeds at 3200 MSPS @ 14-bits, perform a 16384-sample FFT and on-board corner-turn, and offloads the resulting data over 100G Ethernet links through a Ethernet switch that performs the final corner-turn. Other configurations allow corner-turning between 4- , 8- or eventually 16 boards in a backplane, and allow the implementation of a single- or multi-board embedded firmware X-engine (correlator).

The firmware is also used around the world on many small (2-16 element) arrays to implement single-board full N-square correlators.


.. A block diagram of chFPGA used in this configuration is shown in chfpga_block_diagram_.

.. .. _chfpga_block_diagram:
.. .. figure:: images/chFPGA_block_diagram2.svg
..    :width: 50%



.. #########
.. Contents:
.. #########


.. Firmware features
.. =================



.. Before we dig into a detailed description of each main modules of the chFPGA firmware, here is a list of the main features it supports:





Historical notes
================


Firmware Name
-------------

The Pathfinder firmware described in this document is identified as “chFPGA” for Channelizer FPGA.

Evolution
---------

Early proof-of-concept prototypes of a channelizer firmware was developed on a Xilinx SP605 Spartan 6 Evaluation kit around 2009-2010. We demonstrated basic networking and the use of an FFT to process data. Some traces of the Spartan era this might still be found in the code base today. As the concept of the CHIME telescope took form and the signal processing requirements were growing, it became clear that this platform was not suitable for our application.


Following this, a two-dish pre-CHIME correlator was set-up in 2011 using a CASPER ROACH2 to perform basic data acquisition, channelization and correlation. The  hardware and firmware provided by the CASPER collaboration (https://casper.berkeley.edu/). These tools were invaluable as they allowed a data acquisition system to be put in place in a very short timeframe and therefore allow the engineering and scientific efforts to proceed until the design of the Pathfinder system was finalized.

Meanwhile, The chFPGA code base started its development on the ML605 Virtex 6 since it provided the capability to connect FMC ADC mezzanines, was fast, and had plentiful fabric resources. The firmware was demonstrated using the ML605 connected on two dishes on the future site of the CHIME telescope around 2012-2013 using the home-made MGADC08 4-channel ADC FMC mezzanine.


However, the CHIME telescope needed a large number of tightly synchronized FPGAs. Since the ML605 or ROACH2 boards were not well suited for that, McGill Cosmology Lab developped a home-made FPGA platform, the IceBoard,  based on the Kintex 7. Development of the `chFPGA` firmware continued on the Kintex-7 KC705 evaluation and was ported on the IceBoard when the board came out of production in 2014. It was used implement the CHIME Pathfinder in 2016, then the full CHIME a couple years later.

In 2023, `chFPGA` was ported to the Ultrascale+ RfSoC ZCU111 evaluation board in order to demonstrate the suitability of these FPGAs for the 1500-MHZ bandwidth CHORD telescope array. In 2024, `chFPGA` was ported to the RfSoC CRS boards to be used as a 16-board, 64-feed CHORD Pathfinder demonstrator to be deployed in 2025.

During this evolution, the `chFPGA` code base was improved incrementally to add configurability and support new platforms while maintaining backward compatibility with old ones. Efforts were also made to make it  easier to read and maintain.

.. early in the project that the CASPER hardware would not be used to implement the full CHIME, although we want to reuse its firmware as much as possible by wrapping it around a new firmware/software framework that meet the additional CHIME requirements. These CHIME-specific requirements include support for the newest Virtex-6 or 7-series FPGA platforms, support the data acquisition from the McGill 8-channel ADC FMC board and means to format the data packets an reorder/shuffle the data across a large number of boards using multi-gigabit serial links.

.. The CASPER library provides an excellent Polyphase-Filter-Bank-based channelizer and will be used for that purpose. The philosophy of the project is to redesign only what is necessary to meet the target requirements.

.. This document describes the architecture, implementation and real or potential performance of the firmware that is proposed for the Pathfinder experiment with a view to the Full CHIME implementation. This includes both FPGA and GPU-based correlator and beam forming options.

.. Note that this document does not cover GPU-based processing firmware/software and hardware, but only the means to send data to these units.


.. Use UTF-8 encoding

.. Online documentation can be found at: https://winterlandcosmology.bitbucket.io/pychfpga



Requirements
============


Repository Access
-----------------

``chfpga`` and many of its dependencies are hosted in a private git repository on ``bitbucket``.

Before you start, you therefore need:

- A bitbucket (free) account (https://bitbucket.org)
- A ssh private/public key pair, with the public key attached to your bitbucket account


Software tools
--------------

- The following programs should be installed
   - Ubuntu operating system.  
       - 22.04 LTS: is the version we  tested
       - Scripts are written for bash, so it is recommended to use a bash-compatible shell.

	- git LFS (git >1.8.2 includes LFS by default. Make sure ``git-lfs`` is initialized on your account.)

   - AMD (Xilinx) Vivado IDE:
      - 2022.2: Tested and works with Ubuntu 2022.2
      - 2025.1: Does not meet timing constraints
      - Licenses:
         - Standard synthesis/implementation license
         - CMAC (100G Ethernet hardware corelicense is required for building on Ultrascale+ platforms with corner-turn configurations

Hardware
--------

Vivado is resource-hungry, especially for large projects. For decent speed, it is recommended to have a computer with:
- At least 4  **fast** CPU cores. * is preferably better. Vivado is not that great at parallelizing the work, so fewer fast cores is better than more slow cores.
- At least 32G of RAM. Fast DDR memory will probably help


Cloning the repository
======================

Get the ``chfpga`` repository::

	$ git clone git@bitbucket.org:winterlandcosmology/chfpgalite.git  # add the ``-b`` option to specify a branch




Building the firmware
=====================

First, activate the Vivado environment you want to use to build the project. For example::

   source /tools/Xilinx/Vivado/2022.2/settings64.sh


``cd`` to the xilinx_project subfolder that corresponds to the platform and configuration you are building.

To create the .xpr file for the project, run::

   ./create_project.tcl

You can then open the generated .xpr file in Vivado IDE and take it from there.

If you want to buidl the firmware and generate a bitstream, you can directly run the following command (the ``create_project.tcl`` script will be called automatically)::

   ./build_project.tcl 

When finished (this can take up to 45-50 minutes for the largest projects on a decent machine), a  bitstream named ``chfpga_<platform>_<configuration>.bit`` will be placed in the project folder. 
