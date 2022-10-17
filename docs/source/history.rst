Firmware History
================


Firmware Name
-------------

The Pathfinder firmware described in this document is identified as “chFPGA” for Channelizer FPGA.

Evolution
---------

The FPGA firmware was originally designed to operate on a Spartan 6, and was migrated early in the project towards the Virtex 6 since it provided the capability to process a larger number of channels at a lower cost per channel (even more so when the 7-series FPGAs will be used). It is designed to be easily ported to the 7-series Xilinx FPGA and to scale well with bigger number of processing blocks offered by the bigger FPGAs.


The two-dish CHIME experiment has been operating for more than a year using the data acquisition, channelization and correlator hardware and firmware provided by the CASPER collaboration (https://casper.berkeley.edu/). These tools were invaluable as they allowed a data acquisition system to be put in place in a very short timeframe and therefore allow the engineering and scientific efforts to proceed until the design of the Pathfinder system was finalized.
This being said, the full scale CHIME system will needs a large amount of interconnected data processing FPGAs that will each need data processing power that exceed by far the requirements of the two-dish system. Ideally, this hardware will have to be built using low-cost hardware that fits in the electronics hut and dissipates reasonable amount of power, while also fitting in the budget envelope of the project.

For this reason, it was decided early in the project that the CASPER hardware would not be used to implement the full CHIME, although we want to reuse its firmware as much as possible by wrapping it around a new firmware/software framework that meet the additional CHIME requirements. These CHIME-specific requirements include support for the newest Virtex-6 or 7-series FPGA platforms, support the data acquisition from the McGill 8-channel ADC FMC board and means to format the data packets an reorder/shuffle the data across a large number of boards using multi-gigabit serial links.
The CASPER library provides an excellent Polyphase-Filter-Bank-based channelizer and will be used for that purpose. The philosophy of the project is to redesign only what is necessary to meet the target requirements.
This document describes the architecture, implementation and real or potential performance of the firmware that is proposed for the Pathfinder experiment with a view to the Full CHIME implementation. This includes both FPGA and GPU-based correlator and beam forming options.

Note that this document does not cover GPU-based processing firmware/software and hardware, but only the means to send data to these units.

