.. _chfpga_crs:

:entity:`chfpga_crs` platform wrapper (*hdl/platforms/crs/chfpga_crs.vhd*)
********************************************************


Description
===========

This platform wrapper is the top-level entity that is used to implement `chFPGA` on the CRS platform. It is used with multiple firmware configurations.

The entity defines the I/Os that connect the FPGA with the board-specific hardware. it also instantiates the TCPIPE block diagram, which "instantiate" the ZYNQ processor, the ADCs, and adds DMA engines to communicate with `chFPGA`'s BSB (command bus) streams and raw capture bus streams.

Key hardware-specific parameters
================================

The wrapper hard-codes the following parameters that are specific to the IceBoard platform:


.. todo:: Update hardware config parameters

- PLATFORM_TYPE = CRS
- Clocking


- ADCs:

- BSB interface

  	- BSB bus is connected to the ARM processor

Entity definition
=================

.. parse:: hdl/platforms/crs/chfpga_crs.vhd

.. autoentity:: chfpga_crs
