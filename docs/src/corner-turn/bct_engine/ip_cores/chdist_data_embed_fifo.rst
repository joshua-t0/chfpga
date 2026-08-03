.. _chdist-data-embed-fifo-xil-module:

CHDIST Data Embed FIFO
**********************

Xilinx **Embedded FIFO** IP core instance used in the channel distribution path of `bct_engine` to buffer data words between the channel distribution logic and the embedding stage. Configured as a synchronous FIFO with embedded-memory primitives (FIFO18/FIFO36). Key configuration: width and depth sized to the channelized data word width and maximum burst latency.
