
System modules
**************

.. xxx   .. title: system

.. .. figure:: ../images/system.svg
..     :width: 100%

The SYSTEM modules provide general support such as GPIOs, SPI and I2C interfces, etc.


.. toctree::

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
