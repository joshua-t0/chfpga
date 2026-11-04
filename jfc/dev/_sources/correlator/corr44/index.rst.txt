.. title:: CORR44

CORR44: BRAM-based (4+4) bit Correlator Modules
***********************************************

.. default-role:: vhdl:entity

The CORR44 modules implement BRAM-based (4+4) bit correlator cores for 7-Series FPGAs. These modules use BRAM for product storage and are suitable for FPGAs without UltraRAM.

The CORR44 system consists of:

- :entity:`CORR44_ARRAY`: Array wrapper that manages multiple correlator cores
- :entity:`CORR44`: Correlator core that implements a single correlator using CMAC44 modules
- :entity:`CMAC44`: Complex multiply-and-accumulate module used by CORR44

.. toctree::
   :maxdepth: 2
   :hidden:

   corr44_array
   corr44
   cmac44
