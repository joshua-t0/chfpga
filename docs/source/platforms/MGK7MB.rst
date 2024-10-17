MGK7MB (IceBoard)
*****************

Hardware Description
====================

The IceBoard is a Kintex-7-based FPGA motherboard designed by McGill Cosmology Instrumentation Laboratory. The board is optimized to be used in arrays requiring the processing of large number of analog signals.  The board provides the following capabilities:

- Xilinx/AMD XC7K420T FPGA
- 2x HPC FMC connector fully connected to the FPGA
- On-board Texas Instruments AM3874 ARM processor with 1GB DDR3 memory for networking, board monitoring & FPGA configuration
- 1x SFP+ (up to 10 Gbps) and 2x QSFP+ (Up to 80 Gbps in total) for data offload
- 9U Form Factor
- Can be packed into a 16-slot crate that distributes power, clock, timing, and provides a full-mesh 10 Gbps network for multi-board corner-turning
- On board PLL to provide various frequencies to the FPGA and ARM
- All on-boards devices clocked from single reference clock source to mitigate RFI
- Powered by a single 14-20V power source

Detailed description of the IceBoard hardware can be fount at https://winterlandcosmology.bitbucket.io/iceboard-docs/


Platform wrapper
================

The platform wrapper for implementing `chFPGA` on the IceBoard platform is :ref:`chFPGA_MGK7MB_Rev2`.

.. toctree::
   :maxdepth: 5
   :caption: Platform wrapper
   :hidden:

   chFPGA_MGK7MB_Rev2

Configurations
==============

There are currently two firmware configurations for the IceBoard platform:

	- :ref:`Corner turn <chfpga_mgk7mb_ct_config>` (``ct`` suffix), which includes the multi-board corner-turn and real time streaming, and is used by CHIME and HIRAX, both of whuch have an external X-Engine
	- :ref:`Correlator <chfpga_mgk7mb_corr_config>` (``corr`` suffix), which includes 16-channel N^2 correlator, used for standalone operations

.. .. parse:: hdl/sifpga_mgk7mb.vhd
.. .. autoentity:: siFPGA_MGK7MB

.. toctree::
   :maxdepth: 5
   :caption: Configurations
   :hidden:
   :includehidden:

   chFPGA_MGK7MB_ct_config
   chFPGA_MGK7MB_corr_config
