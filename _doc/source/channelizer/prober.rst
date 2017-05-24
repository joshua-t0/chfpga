:entity:`PROBER`: Data capture
******************************

Overview
--------
Prober captures and buffer data frames and makes them available over a 8-bit AXI4 STREAM interface for transmission over Ethernet using the UDP Command Protocol infrastructure. A frame header is added to the data to provide flags, frame number, stream ID etc. The number of frames to capture in a contiguous burst,  the number of frames between bursts, and the total number of bursts to send are configurable by software. If the number of bursts to transmit is 0, the bursts are sent continuously while the frame capture bit is high. Otherwise, the transmisision of N bursts is triggered on a 0-to-1 transition of the capture bit. The transition is disregarded while until all the bursts have been sent. The capture-bit transition can happen on any byte of a frame, but transmission is always aligned on the beginning of the next frame.

Schematic
---------

.. figure:: ../images/prober.svg
    :width: 50%

.. parse:: hdl/chan/PROBER.vhd

.. toctree::
   :titlesonly:

   prober_data_fifo
   prober_frame_fifo


Entity documentation
--------------------


.. autoentity:: PROBER



Read / Write Process
--------------------
Incoming 32-bit AXIS Data is captured and written into the DATA FIFO over a 36-bit AXIS bus and read out over a 8-bit wide AXIS Bus. Each byte in the incoming data is extended with a bit which set to '0' except for the LSB , where is set to the TLAST flag from the 32-bit AXIS Bus. The sign extenstion is show below. The HEADER FIFO is 9-bit wide write process which consitutues of all the header information for the data frame written one bit at a time accompanied with a LAST bit at bit(8). When the destination is ready, PROBER sends the header FIFO  bytes until we encounter bit(8)=1, then sends the DATA FIFO bytes until we encounter bit(8)=1 and go back to send header bytes.

.. figure:: ../images/prober_write_data.svg
    :width: 25%



Memory Map
----------

.. include-docs:: PROBER
    :start-after: CAPTURE (PROBER) Module Memory Map
