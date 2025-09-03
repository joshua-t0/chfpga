
System modules
**************

.. xxx   .. title: system

.. .. figure:: ../images/system.svg
..     :width: 100%

The SYSTEM modules provide general support such as GPIOs, SPI and I2C interfces, etc.


.. toctree::
  :hidden:
  :maxdepth: 1

    clocks
    GPIO <gpio>
    i2c
    spi
    blinker
    refclk
    sysmon
    freq_ctr


The :entity:`gpio` also provides the following functionnalities:

  - Motherboard Buck Synchronization
  - Backplane Buck Synchronization
  - IRIG-B decoder (:entity:`irigb_decoder`) and generator
  - IRIG-B tagging of Referenece clock counter and Frame counters


SYSTEM memory map
----------------

.. todo:: Add system memory map

.. .. include-docs:: chfpga
..     :start-after: SYSTEM Memory Map