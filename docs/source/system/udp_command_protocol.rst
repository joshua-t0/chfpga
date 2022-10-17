Command and Control Interfaces
******************************

chFPGA implements two interfaces that allows control and monitoring of the FPGA firmware operation:


- UDP Control Link : This is a lightweight command protocol carried using
  UDP packets over the FPGA's SFP 1Gbps Ethernet port. The protocol allows
  memory-mapped read and write operations to internal registers, memory blocks
  and Xilinx Core's Dynamic Reconfigurable Ports (DRP). Most of the chFPGA
  custom  firmware use this link as it is very fast and is optimized to use
  very little FPGA logic and routing resources.

- ARM-SPI Control Link : Uses the ~60Mbps SPI between the ARM and the FPGA to carry memory-mapped access of 32-bit registers in the
  FPGA. This link is slower and is used to  provide access to core functionalities of the FPGA. This link is used to  operate the IRIG-B subsystem and set-up the networking parameters needed to establish the UDP Control link (MAC & IP addresses, port numbers).

Both links access different address spaces, e.g. one  link cannot access registers associated with the other link.


UDP Control System
==================

Design Philosophy
-----------------

The UDP control system is designed to distribute memory-mapped registers throughout the FPGA within each sub-modules in a hierarchical way while maintaining low resources utilization. We want each FFT, scaler, GTX transceiver etc. to have its own set of registers that are placed locally with their logic to facilitate floorplanning, routing, and  timing closure. This allows the design to be scaled up or down easily. We also wanted to be able to create Python classes that represent each firmware subsystem and transparently expose its memory-mapped registers, and instantiate as many of those classes as needed.

It is typical to use AXI4 or AXI4-Lite to implement buses and memory-mapped resources. However, these protocols use 32-bit wide buses both the the address and data, on both the read and write channels. We beleived that routing such buses to every corner of the FPGA would use precious routing resources we might need for the routing-intensive shuffling subsystem. Also, since our 1G Ethernet link allows transfer at a maximum of 125 MBytes/s, the AXI4 protocol is massively overkill in terms of bandwidth (although we would not care and prefer to use a pre-existing protocol if the resource utilization was not in question).

For this reason, we chose to internally interconnect the elements of the control system in the following way:

- Commands and addresses are routed to each memory-mapped registers on a single 8-bit wide AXI4-Streaming bus. There is no separate address and data bus. The address is found in the header of each packet.
- Routers inspect the header of each packet and forward them to the appropriate output poer based on a specified addres mask.
- Each end nodes decode the header and implement the register bank and the logic to read and write to those registers. This leads to the duplication of the header processing and read/write state machines, but the protocol is simple enough that the overhead is acceptable given that is makes floorplanning much simpler.
- Each command generate a reply and optional data. Tese are sent back up the hiearchy of routers through another ASI4-Streaming bus.
- All AXI4-Streaming buses are blocking, i.e. transfers are only made if the destination has asserted the TREADY line. This minimizes the need to buffer packets throughout the system, but makes the pipeling slightly more difficult (we need a 1-byte FIFO each time we want to pipeline the bus)

Although we could in theory process commands in multiple end nodes concurrently and get replies asynchronously, it was decided that only one command will be issued at a time, i.e. a new command is not issued until the reply from the previous one has been sent out.  To do this,  it would be necessary to tag each command with a unique ID so we can sort out the replies. This is not hard to do (just add an extra byte to the command),  but the speed benefit was not  significant in the context of typical operations.

Infrastructure
--------------


MASTER:
    - Receives command packets from the UDP subsystem, counts them, and foward them to the 1st router.
    - Arbitrates access to the UDP packet transmitter between reply packets from the 1st router and data packats from the PROBER inputs.
    - Implemnt timeout
    - Implement data throttling
    - Count reply packets and add command packet count to every reply to allow the hist system to detect command/reply desynchronization (this is used to implement a more reliable UDP protocol)

ROUTER:
    - Inspects the address at the top of the packet and forward the packet to one of its output ports based on the value of specified addesss bits.
    - Merge the incoming reply streams and send them back to  up the hierarchy.


SLAVE (end node):
    - Capture the opcode, byte count and address at the top of the packet
    - Trigger the appropriate state machine based on the opcode
    - In write operations, any bytes after the command bytes are written to the selected destination. In read operation, those bytes are ignored.
    - Targets:

        + Control registers: Can always be read-back. Connect to fabric signals. Loaded with default values on reset.
        + Status registers: read back only. Connect to fabri signals.
        + RAM: block ram (single or dual port. Input port of BRAM is 8 or 16 bits. Output port can by any width supported by the BRAM.
        + DRP: Xilinx core. 16-bit wide.
    - RAM/DRP:  support slow devices; wait for ready signal or fixed latency.
    - Supported operations:
        - Read/write of control registers. Masked write is also supported for bitfield operations. Any number of contiguous registers can be written in a single command packet (limited only by the maximum packet sized). Reads are limited to 1,2,4 or 8 bytes.
        - Read of status registers. Reads are limited to 1,2,4 or 8 contiguous bytes.
        - Byte-wise Read and write of block RAM contents. Any number of contiguous bytes can be written in one command packet. Reads are limited to 1,2,4 or 8 contiguous bytes.
        - Word-wise (16-bit word) of DRP registers or RAM. Any number of contiguous words can be written in one command packet. Reads are limited to 1,2,4 or 8 contiguous words.

Interconnects:
    - AXI4-Streaming, 8-bit data bus, blocking, no TUSER buts for both the command and reply channels.
    - Common 125 MHz control system clock throughout the FPGA (ctrl_clk)
    - Pipelined synchrounous control system reset line (ctrl_rst)


Command and Reply Packet Format
-------------------------------

.. figure:: ../images/udp_command_packet_format.svg
    :width: 75 %

AXI4-Streaming Protocol
-----------------------

The AXI4-Stream protocol is used for applications that typically focus on a data-centric and data-flow paradigm where the concept of an address is not present or not required. Each AXI4-Stream acts as a single unidirectional channel for a handshake data flow. At this lower level of operation (compared to the memory mapped AXI protocol types), the mechanism to move data between IP is defined and efficient, but there is no unifying address context between IP. The AXI4-Stream IP can be better optimized for performance in data flow applications, but also tends to be more specialized around a given application space.

AXI-Stream Ports and Waveform

.. table::

    +------------------+--------------+-----------+----------------------------------------------------+
    | Port Name        | Width (bits) | Direction | Description                                        |
    +==================+==============+===========+====================================================+
    | TREADY           | 1            | In        | Indicates destination is to accept data            |
    +------------------+--------------+-----------+----------------------------------------------------+
    | TVALID           | 1            | Out       | Indicates TDATA is valid                           |
    +------------------+--------------+-----------+----------------------------------------------------+
    | TLAST            | 1            | Out       | Indicates last word of a transfer                  |
    +------------------+--------------+-----------+----------------------------------------------------+
    | TDATA            | 8            | Out       | Data                                               |
    +------------------+--------------+-----------+----------------------------------------------------+


.. figure:: ../images/axi_stream_waveform.png
    :scale: 22
    :alt: AXI-Stream Interface Waveform


UDP Command Protocol Memory Map
-------------------------------

.. figure:: ../images/udp_command_address_map.svg


**chFPGA**

.. .. include-docs:: ../hdl/chfpga.vhd
    :end-before:  entity chFPGA


router
------

.. .. include-docs:: ../hdl/chfpga.vhd
    :end-before:  sys_router0:


.. .. include-docs:: ../hdl/chfpga.vhd
    :start-before:  SYSTEM Memory Map

.. Example of literal comment include from chfpga.vhd

.. Literal include

.. .. literalinclude:: ../../hdl/chfpga.vhd
..     :language: vhdl
..     :start-after: --startLiteralInclude
..     :end-before: --stopLiteralInclude

.. .. Example of literal source code snippet include from chfpga.vhd

.. .. literalinclude:: ../../hdl/chfpga.vhd
..     :language: vhdl
..     :start-after: --startSysMonInclude
..     :end-before: --stopSysMonInclude




Protocol
--------

In some controlled environment, UDP can be very reliable.
No CRC. The problem is the stack. Any packet can be dropped for any reason.

Windows: if ARP has to be sent, all but the last UDP packet is dropped until the address is resolved.
try: ``netsh interface ip delete arpcache`` before sending many UDP packets back-to-back.


ACK vs NAK

http://stackoverflow.com/questions/4624333/reliable-udp-and-ack-method-question

- Comand Packet was not received by the FPGA (was dropped by the host computer, the routers/switches, or was dropped by the FPGA due to a bad CRC)
- The Packet reached the FPGA but the reply packet did not reach the host computer

Reply has a 1st byte: sequence counter, counts the number of received command packets so far.
If command packet lost: not incremented, no reply.
If reply lost: incremented, no reply.

If no reply is received, we can send another read request to read the packet counter to determine if the command was received or not. (assuming *that* request is not lost)

In practice, if we don't get our reply in a timely fashion, we just resend the command.

Trigger-less behavior:
- Reading an address multiple times will not change the state of the system (i.e. always return the same data)
- Writing: have to be careful with edge-sensitive soft triggers (write zero, then write one, separate packets).
Readback:
- A control register can always be read back. There are no blind writes (writing writes to a register, reading returns something different). This allows toggling only some bits by read-mask-write operation, although masked writes is a native operation.


SPI Protocol
============

32-bit based.

Meant to be AXI-lite. No AXI bridge
SLow. Through JSON over HTTP.

Performance
===========



General approach
----------------




Sources
=======
`Xilinx AXI Reference Guide <https://www.xilinx.com/support/documentation/ip_documentation/ug761_axi_reference_guide.pdf>`_



.. vim: sts=3 ts=3 sw=3 tw=78 smarttab expandtab
