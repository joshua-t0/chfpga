Platform information
********************


Hardware description
====================

.. figure:: ../../images/PLATFORMS/IceBoard/IceBoard_with_2_Mezz_back.JPG
    :width: 50%

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

Detailed description of the IceBoard hardware can be found at https://winterlandcosmology.bitbucket.io/iceboard-docs/


Platform wrapper and configurations
===================================

`chFPGA` is implemented on the Iceboard platform using the :ref:`chfpga_ice<chfpga_ice>` platform wrapper, whhich instantiate the `chFPGA` module. Multiple `chFPGA` firmware configurations are supported on this platform, including:

- :ref:`chfpga_ice_ct<chfpga_ice_ct_config>`: 16-, 256- or 512-channel F-Engine, corner-turn engine and real-time data offload to an external X-Engine
- :ref:`chfpga_ice_corr16<chfpga_ice_corr16_config>`: 16-channel single-board F-Engine and :math:`N^2` correlator

See :ref:`this link<platform_wrappers>` for more details on how the platform wrappers and configurations are used.

.. include:: ./floorplanning.rst