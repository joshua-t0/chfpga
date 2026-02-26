.. title:: UPACK

*************************************************************
:entity:`UPACK` (*upack.vhd*): UltraRAM-based Packetizer and Corner-Turn Engine
*************************************************************

.. parse:: hdl/ct/upack.vhd

.. default-role:: vhdl:entity

Entity documentation
--------------------

.. autoentity:: upack

Principle of operation
----------------------


Memory organization
-------------------

Data is stored in 16 URAM blocks organized as an array of 4 x 4 blocks. Each block is implemented a 4 UltraRAM tiles, which together form a memory with  64 bits x 16384 words. 

The incoming data is written column-wise, wich each column receiving the 64 bits (8 channels * 8 bit/channel) from each bin in the input word. Data from consecutive frames are written in different rows.  

A data frame consists of 2048 words (8192 bins total, 4 bins per word). Each memory block can store 8 frames, or 4 frames per bank. The 4 blocks in a column can store up to 16 frames per bank.

Data is read column-wise, all 4 blocks in a column in parallel, providing a 256 bit data bus.


Memory Map
----------

.. include-docs:: upack
    :start-after: Memory Map

