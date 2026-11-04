Introduction
************

..  chFPGA: Data acquisition, Channelizer, corner-turn and correlator engine FPGA firmware for the IceBoard FPGAs

``chFPGA`` is a multiplatform FPGA firmware designed to implement wide bandwidth radiotelescope and radio-interferometers front-ends. It provides the following components:

- F-Engine (channelizer)
- Corner-turn engine (groups data from one or multiple boards by frequency) with periodic data capture for monitoring
- Optional X-engine (:math:`N^2` correlator)
- Optional real-time 80G/100G Ethernet streaming of corner-turned data
- Hardware platform management and peripheral controllers...


.. figure:: ./images/chfpga_simple_block_diagram_v2.svg
   :width: 70%


`chFPGA` is meant to be operated through the ``pychfpga`` Python package (https://winterlandcosmology.github.io/pychfpga), which provides a Python high-level interface to every subsystem of the `chFPGA` firmware and provides platform wrappers and servers for on-site automated operations. 

`chFPGA` is used in the following applications by building the appropriate firmware configuration:

- `CHIME <https://www.chime-experiment.ca/>`_ radiotelescope: ``ice_ct`` firmware configuration. Handles 1024 dual-polarization feeds digitized at 800 MHz @ 8 bits using 128 Kintex-7 FPGA boards (IceBoards), 2048-sample FFT, 4+4i bit scaling, 32-boards corner-turns, 8x10 Gbps UDP streaming per board to a 256-node GPU-based correlator farm. 
- `CHIME FRB Outriggers <https://www.dunlap.utoronto.ca/chime_outrigger/>`_:  ``ice_ct`` firmware configuration. Similar to CHIME but with 16-boards total.
- `HIRAX <https://hirax.ukzn.ac.za/>`_ telescope: ``ice_ct`` firmware configuration. Similar to CHIME, but with up to 1024 dishes
- `CHORD <https://www.chord-observatory.ca/>`_ telescope: ``crs_ct`` firmware configuration. 512-dual-polarization feeds sampled at 3200 MSPS @ 14-bits performed by 128 Xilinx Ultrascale+ RfSoC FPGA boards (CRS platform), 16384-sample FFT, on-board corner-turning, packet assembly and 100G Ethernet offload to an Ethernet switch to perform the final corner-turn.
- Single-board 16-input ICEBoard correlator or 8,32,64 or 128-input (1,4, 8 or 16 boards) CRS-based  correlators with embedded firmware X-engine used for early pathfinder deployments or small experiments. Uses ``crs_corr8/32/64``, ``ice_corr16`` firmware configurations.
- KC705- and ZCU111-based systems (``zcu111_*`` and ``kc705_*`` firmware configurations) have been deployed to feed real data to X-Engines and perform small experiments.

Links
=====

- Source code: https://github.com/winterlandcosmology/chfpga

- Documentation: https://winterlandcosmology.github.io/chfpga/latest (or click `here <https://winterlandcosmology.github.io/chfpga>`_ to select a specific version)

Features
========

The main features of ``chFPGA`` are:


- Supported hardware platforms

 
   - **ML605** : *Xilinx ML605 Virtex 6 Evaluation kit*, with one HPC and one LPC FMC connector for ADC mezzanine boards.  The first full firmware implementations of ``chfpga`` were done on that platform around 2010. The code base has not been maintained since we moved to the more scalable IceBoard and because the modern development tools that we use (Vivado) no longer support the Virtex 6.

   - **KC705** : *Xilinx KC705 Kintex 7 Evaluation board*, with two HPC FMCs. Used for prototyping the chfpga before the availability of the IceBoards.

   - **MGK7MB/IceBoard**: `McGill Cosmology Lab <https://mcgill.ca/cosmology-lab>`_ *MGK7MB/IceBoard* is a home-made Kintex 7 FPGA board with two HPC FMCs, which was designed specifically for implementing large and fully synchronized high-density array of FPGA boards. With chFPGA, each board can digitize and process 16 analog inputs at 800 MSPS @ 8 bits.  Those boards are used for large interferometers such as the CHIME telescope (128 boards), but are also used for smaller outrigger telescopes or benchtop experiments. More than 500 such boards have been produced.

   - **ZCU111**: *Xilinx Ultrascale+ RfSoC Evaluation board* was the first RfSoC platform on which chFPGA was ported to make use of the  embedded high-frequency ADCs and 100G Ethernet interfaces. On this platform, chFPGA can acquire and process 8 analog inputs at 3000 MSPS. Uses the Embedded ARM processor to provide a TCP/IP interface to the chFPGA firmware.

   - **CRS**: `t₀ technology <https://t0technology.com/>`_ *Ultrascale+ RfSoC* is a compact RfSoC FPGA board designed to implement next-generation high performance and large-density signal processing arrays. On these boards, chFPGA can process 8 analog channels at 3200 GSPS @ 14 bits, perform on-board N^2 correlationor corner-turn the channelized data and stream it through its 100G interface. Also uses the Embedded ARM processor to provide a TCP/IP interface to the chFPGA firmware.

   The firmware is structured so new platform wrappers and configuration files can be added with minimal effort.


- Firmware components configurable through a configuration file:

   - Number of channels, FFT type, corner-turn geometry, correlator configuration, clock sources and speed, peripherals, etc.

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

- X-Engine (a.k.a. :math:`N^2` correlator)

   - Processes (4+4i)-bits data from the corner-turn engine
   - Scaleable to any number of inputs
   - Is highly optimized for maximum density and speed.
   - Uses both BRAM and URAM for integrated product storage

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
   - Can use a firmware-based UDP packet receiver/transmitter or DMA the command stream to/from an on-chip ARM processor.




Build instructions
==================


Requirements
------------

- A good build computer. Vivado is resource-hungry, especially for large projects. For decent build times (1 h max) , it is recommended to have a computer with:

   - At least 4  **fast** CPU cores. Vivado is not that great at parallelizing the work, so fewer but faster cores is better than more slow cores.
   - At 32G of RAM. Fast DDR memory will probably help

- Ubuntu operating system.  The following versions have been tested:

      - 22.04 LTS: is the version we  tested
      - Scripts are written for bash, so it is recommended to use a bash-compatible shell.

- git LFS (git >1.8.2 includes LFS by default. Make sure ``git-lfs`` is initialized on your account.)

- AMD (Xilinx) Vivado IDE:

   - 2022.2: Tested and works with Ubuntu 2022.2
   - 2025.1: Does not meet timing constraints (routing algorithms changed...)
   - Licenses:
      - Standard synthesis/implementation license for the target FPGA
      - CMAC (100G Ethernet hardware corelicense is required for building on Ultrascale+ platforms with corner-turn configurations

Cloning the repository
----------------------

Get the ``chfpga`` repository::

	$ git clone https://github.com/winterlandcosmology/chfpga.git


Building the firmware
---------------------

First, activate the Vivado environment you want to use to build the project. For example::

   source /tools/Xilinx/Vivado/2022.2/settings64.sh

Method 1: Using ``make``
........................

From the repo root::

   make <config>

Examples::

   make crs_corr8 
   make ice_*  # globs are accepted

This creates the Vivado project for the specified configuration(s),  synthesize and implements them, and generates bitstreams ``chfpga_<config_name>.bit``. This can take up to 45-50 minutes for the largest projects.

Other make options are available::

   make help  # display help
   make project <config>  # Only creates the Vivado project(s) for the given configuration(s)
   make clean <config> # clean the project for the crs_ct configuration
   make status [<config>] # displays the status of the build
   make docs  # builds the html documentation
   make all # builds all projects



Method 2: Invoking the build scripts directly
.............................................

``cd`` to the xilinx_project subfolder that corresponds to the platform and configuration you are building, e.g.::

   cd chfpga/xilinx_projects/chfpga_crs_corr32


To create the project, build the firmware and generate a bitstream, execute::

   ./build_project.tcl 

This can take up to 45-50 minutes for the largest projects. A bitstream named ``chfpga_<platform>_<configuration>.bit`` will be placed in the project folder. Note that command will automatically create the .xpr project by invoking the ``create_project.tcl`` script .


Method 3: Using Vivado IDE
..........................

``cd`` to the xilinx_project subfolder that corresponds to the platform and configuration you are building.

To create the .xpr file for the project, run::

   ./create_project.tcl

You can then open the generated .xpr file in Vivado IDE and take it from there.



Historical notes
================

The “chFPGA” name stands for Channelizer FPGA, although it has elvolved to include a corner-turn and X-Engine. 

Early proof-of-concept prototypes of a channelizer firmware was developed on a Xilinx SP605 Spartan 6 Evaluation kit around 2009-2010. We demonstrated basic networking and the use of an FFT to process data. Some traces of the Spartan era this might still be found in the code base today. As the concept of the CHIME telescope took form and the signal processing requirements were growing, it became clear that this platform was not suitable for our application.


Following this, a two-dish pre-CHIME correlator was set-up in 2011 using a CASPER ROACH2 to perform basic data acquisition, channelization and correlation. The  hardware and firmware provided by the CASPER collaboration (https://casper.berkeley.edu/). These tools were invaluable as they allowed a data acquisition system to be put in place in a very short timeframe and therefore allow the engineering and scientific efforts to proceed until the design of the Pathfinder system was finalized.

Meanwhile, The chFPGA code base started its development on the ML605 Virtex 6 since it provided the capability to connect FMC ADC mezzanines, was fast, and had plentiful fabric resources. The firmware was demonstrated using the ML605 connected on two dishes on the future site of the CHIME telescope around 2012-2013 using the home-made MGADC08 4-channel ADC FMC mezzanine.

However, the CHIME telescope needed a large number of tightly synchronized FPGAs. Since the ML605 or ROACH2 boards were not well suited for that, McGill Cosmology Lab developped a home-made FPGA platform, the IceBoard,  based on the Kintex 7. Development of the `chFPGA` firmware continued on the Kintex-7 KC705 evaluation and was ported on the IceBoard when the ICEBoard came out of production in 2014. It was used implement the CHIME Pathfinder (128 feeds in two small cylinders) in 2016, then the full CHIME (2048 feeds in 4 large cylinders) a couple years later.

In 2023, `chFPGA` was ported to the Ultrascale+ RfSoC ZCU111 evaluation board in order to demonstrate the suitability of these FPGAs for the 1500-MHZ bandwidth CHORD telescope array. In 2024, `chFPGA` was ported to the `t₀ technology <https://t0technology.com/>`_ Ultrascale+ RfSoC CRS boards to be used as a 16-board, 64-feed CHORD Pathfinder demonstrator to be deployed in 2026.

During this evolution, the `chFPGA` code base was improved incrementally to add configurability and support new platforms while maintaining backward compatibility with old ones. Efforts were also made to make it  easier to read and maintain.

.. early in the project that the CASPER hardware would not be used to implement the full CHIME, although we want to reuse its firmware as much as possible by wrapping it around a new firmware/software framework that meet the additional CHIME requirements. These CHIME-specific requirements include support for the newest Virtex-6 or 7-series FPGA platforms, support the data acquisition from the McGill 8-channel ADC FMC board and means to format the data packets an reorder/shuffle the data across a large number of boards using multi-gigabit serial links.

.. The CASPER library provides an excellent Polyphase-Filter-Bank-based channelizer and will be used for that purpose. The philosophy of the project is to redesign only what is necessary to meet the target requirements.

.. This document describes the architecture, implementation and real or potential performance of the firmware that is proposed for the Pathfinder experiment with a view to the Full CHIME implementation. This includes both FPGA and GPU-based correlator and beam forming options.

.. Note that this document does not cover GPU-based processing firmware/software and hardware, but only the means to send data to these units.


.. Use UTF-8 encoding

.. Online documentation can be found at: https://winterlandcosmology.github.io/pychfpga


