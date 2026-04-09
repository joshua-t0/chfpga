.. _mask-ram-xil-module:

MASK RAM
********

Xilinx **Block Memory Generator** (True Dual-Port BRAM) IP core instance. Stores the channel-selection mask used by the `bct_engine` to determine which channels are active in each bin. Port A is written by the BSB register interface; Port B is read by the corner-turn datapath.
