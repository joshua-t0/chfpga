Corner-Turn Engine
******************

.. default-role:: vhdl:entity

The corner turn engine takes the packets coming out of N F-Engine channelizers and regroup the data by frequency bin into M output streams. Each output stream contains data from all N channels but for 1/M frequency bins. The output of the corner-turn engine is typically fed to the high-speed data transmitter (8x 10Gbps Ethernet or 100G Ethernet links) to be transmitted to a X Engine farm.

`chfpga` can implement two versions of the corner-turn, each targetting different planform and heach having different capabilities. Each corner-turn is implemented as a separate module that is selected and instantiated based on the ``CT_TYPE`` configuration parameter.


- `BCT_engine`: Implements the corner-turn operation for the 7-Series FPGA platforms with up to 16x ADCs operating at 800 MSPS each. Takes the F-Engine outputs within a board (16 analog channels), withing a 16-board crate (256 analog channels) or between two crates (512 analog channels). Offloads data using 8x 10 GBps Ethernet data links if an internal correlator is not used.


- `UCT_engine`: Implements the corner-turn operation for the Ultrascale+ FPGA platform with up to 8x ADCs operating at 3200 MSPS each. Takes the F-Engine outputs within a board (8 analog channels), within a 4-board sub-backlane (32 analog channels), within two sub-backplanes (64 analog channels) or a full crate (4 sub-backplanes or 128 analog channels). Offloads data using a 100G Ethernet data link.

.. toctree::
   :hidden:

   bct_engine
   uct_engine
