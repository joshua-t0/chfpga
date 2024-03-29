

.. title:: chFPGA

.. image:: images/chfpga_logo.svg
   :width: 30%
.. .. image:: images/chfpga_text.svg
..    :width: 30%

-------------------------------------------------

************
Introduction
************


..  chFPGA: Data acquisition, Channelizer, corner-turn and correlator engine FPGA firmware for the IceBoard FPGAs

``chFPGA`` is a FPGA firmware framework that is used to implement high-performance radiotelescope front-ends consisting of

- ADC data acquisition (from an external ADC or one that is within the FPGA)
- F-Engine (a.k.a FFT Engine or channelizer (hence the *ch* in *ch*FPGA))
- Corner-turn engine (i.e reordering of channelized data within one board or multiple boards)
- X-Engine (a.k.a N^2 correlator)
- Real-time data offload through one or more 10G or 100G Ethernet links
-  and various support functions (raw data capture, waveform/test pattern injection, test packet generators, SPI/I2C controllers etc.)

``chFPGA`` is a multi-platform firmware designed to operate on Xilinx (now AMD) FPGAs. It has been used on the following platforms:

- Xilinx SP605 Spartan 6 Evaluation kit. OK, not really anymore, but as an historical note, ``chFPGA`` precursors started on that platform when we wanted to know if a FPGA could really do an FFT.

- **Xilinx ML605 Virtex 6 Evaluation kit**, with one HPC and one LPC FMC connector for ADC mezzanine boards.  The first full firmware implementations of ``chfpga`` were done on that platform back in the days. We  have stopped developping on it since we moved from ISE to Vivado (which does not support Virtex 6), but archeological traces of that platform can be found in the code.

- **Xilinx KC705 Kintex 7 Evaluation board**, with two HPC FMCs

- **McGill Cosmology Lab IceBoard (MGK7MB)**, Kintex 7 FPGA board with two HPC FMCs.

- **Xilinx ZCU111, Ultrascale+ RfSoC** with integrated GHz ADCs

- **t0 CRS, Ultrascale+ RfSoC** with integrated GHz ADCs


.. 16 ADC analog channels at 800 Msps, channelizes the data in 1024 frequency bins (F-engine), and can either implement an on-board 16-channel correlator (X-engine) or reorder and redistribute the data with other boards before sending it to an external correlator.


``chFPGA`` was originally designed for the Canadian Hydrogen Intensity Mapping Experiment (CHIME) radiotelescope, which consists of an array of 128 IceBoards that digitizes 1024 dual-polarization, 400 MHz bandwidth feeds, implement a 2048-sample FFT, scales and  corner-turns the data between groups of 64 boards, and feeds the baseband data to a a 256-node GPU-based correlator farm. ``chFPGA`` is now used on an array of 128 Xilinx RfSoC FPGAs to digitize the signals from 512-dual-polarization, 1500 MHz bandwidth feeds and perform a 16384-sample FFT and offload the resulting data over a modern GPU farm over 100G Ethernet links. The firmware is also used around the world on many small (2-16 element) arrays to implement single-board full n-square correlators.


A block diagram of chFPGA used in this configuration is shown in chfpga_block_diagram_.

.. _chfpga_block_diagram:
.. figure:: images/chFPGA_block_diagram2.svg
   :width: 50%




.. ###########
.. Quick Links
.. ###########

.. * Source Code Hierarchy





.. .. include:: history.rst

.. .. include:: requirements.rst

.. .. include:: features.rst

.. #########
.. Contents:
.. #########

.. toctree::
   :maxdepth: 2
   :hidden:

   history
   requirements
   features


.. .. include:: history.rst

.. .. include:: requirements.rst

.. .. include:: features.rst
