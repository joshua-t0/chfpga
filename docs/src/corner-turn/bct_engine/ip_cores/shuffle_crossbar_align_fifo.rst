.. _shuffle-crossbar-align-fifo-xil-module:

Shuffle Crossbar Align FIFO
****************************

Xilinx **FIFO Generator** IP core instance used between the shuffle crossbar and the alignment stage of `bct_engine`. Provides elasticity to absorb phase differences between the crossbar output and the downstream alignment logic. Width equals the full data word; depth sized for the worst-case pipeline skew.
