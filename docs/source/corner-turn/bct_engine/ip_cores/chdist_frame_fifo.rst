.. _chdist-frame-fifo-xil-module:

CHDIST Frame FIFO
*****************

Xilinx **Embedded FIFO** IP core instance used in the channel distribution path of `bct_engine` to buffer framing control words. Configured as a synchronous FIFO with embedded-memory primitives. Depth is sized to accommodate the maximum number of in-flight frames in the corner-turn engine.
