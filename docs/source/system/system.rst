.. title:: system

System modules
**************

.. title:: System Modules

.. figure:: ../images/system.svg
    :width: 100%

The SYSTEM modules provide general support such as GPIOs, SPI and I2C interfces, etc.


.. toctree::
   :titlesonly:

   gpio
..   i2c
..   spi
..   refclk
..   sysmon
..   freq_ctr
..   clocks
..   blinker

The :entity:`gpio` also provides the following functionnalities:

  - Motherboard Buck Synchronization
  - Backplane Buck Synchronization
  - IRIG-B decoder (:entity:`irigb_decoder`) and generator
  - IRIG-B tagging of Referenece clock counter and Frame counters




.. Entity documentation
.. --------------------

.. .. parse:: hdl/CHAN/CHAN.vhd

.. .. autoentity:: CHAN




.. Additional details
.. ------------------

.. Memory map
.. ----------

.. .. include-docs:: CHAN
..     :start-after: CHANNELIZER Memory Map

