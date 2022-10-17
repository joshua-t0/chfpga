Internal buses
==============

The buses used to communicate data between the various modules of the FPGA use the AXI4 Streaming (or AXIS) protocol. This bus is used to implement both for the control interface and for the real-time signal processing. AXIS is a simple parallel protocol that is standardized and well documented. Xilinx is switching its IP cores to this standard and provides many IP cores specialized in buffering and routing traffic using this bus. The AXI4 and AXI4-Lite protocols differ from the AXI4-Streaming protocol in that they are designed for multiple devices to access memory-mapped devices using bus arbritation, queuing etc. Since we only need stream packets from point to point, AXI4-Streaming was selected as a bus standard as it is also very easy to implement custom modules using this protocol.

An AXIS bus consist of the following lines:

	•	Data lines (TDATA), which can be of variable width
	•	User data lines (TUSER), are used to pass user data or flags along with the data. The number of bits is variable.
	•	Valid flag (TVALID), which indicates that valid data is on the bus
	•	A ‘LAST’ flag (TLAST), which is set on the last word of a packet
	•	A READY flag (TREADY), which is set by the recipient to indicate it will accept the word on the next clock edge (assuming TVALID = 1). This is used in blocking interfaces only, where the data is transferred only when the destination is ready. A non-blocking interface send data continuously and does not use the TREADY line.

All bus operations are synchronous to a single clock (ACLK).

The principle of operation is as follows:

	1.	When the source has data to send, it places the data and user flags on the bus, sets the TLAST flag as appropriate, and sets TVALID=1. The source DOES NOT wait for the TREADY line to be active.
	2.	When the destination is ready to accept data, it sets TREADY=1
	3.	A data transfer occurs on the clock edge where both TVALID=1 and TREADY=1. If the source has more data to send, TVALID is left to ‘1’, otherwise it is cleared on that clock edge. The destination similarly updates its TREADY flag according to its capability of receiving the next word.


The control interface uses a 8-bit wide blocking AXIS bus operating at 125 MHz (the Ethernet interface speed). AXIS routers are used to inspect the destination address contained in the first bytes of the command and forward the data to their destination (or more routers).
The data AXIS interface have data width that vary from 32 to 72 bits and contain 4 bits of USER data to indicate the overflow status of the previous stages and the data capture status. The buses are non-blocking within the antenna or correlator blocks, but a blocking bus interface between the two blocks. The antenna buses operate at ¼ of the sampling rate (each clock processing 4 time sample or 2 frequency samples), while the correlator operates at 225 MHz (each clock processing 2 frequency samples).
