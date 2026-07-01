.. title:: i2c

*****************************************
:entity:`i2c` (*i2c.vhd*): I2C peripheral
*****************************************

.. figure:: ../images/SYSTEM/i2c.svg
    :width: 100%

Entity documentation
--------------------

.. parse:: hdl/system/i2c.vhd

.. autoentity:: i2c

Parameters
==========

- **NUMBER_OF_PORTS:** Number of independent I2C bus ports. Determines the width of the ``i2c_sck`` and ``i2c_sda`` bidirectional port vectors.
- **T_HIGH:** Minimum SCK high time in seconds (default 4 µs, per 100 kHz I2C standard).
- **T_LOW:** Minimum SCK low time in seconds (default 4.7 µs).
- **CLK_FREQ:** Input clock frequency in Hz (default 200 MHz). Used to convert all timing parameters to clock cycles.

Interface
=========

- ``s/m_axis_bsb_t*``: BSB (Byte-Stream Bus) interface for register-based control.
- ``bsb_clk``/``bsb_rst``: BSB clock and reset.
- ``i2c_sck``: Bidirectional I2C clock lines, one per port. Implemented using ``IOBUF`` open-drain tristate drivers.
- ``i2c_sda``: Bidirectional I2C data lines, one per port. Implemented using ``IOBUF`` open-drain tristate drivers.
- ``clk200``: 200 MHz clock that drives the I2C state machine and all timing counters.
- ``rst``: Synchronous reset, synchronous to ``clk200``.

Implementation details
======================

The module implements a full I2C master state machine (START, STOP, RESTART, data bits, ACK/NACK). Clock stretching is supported: the state machine waits for SCK to be released by the slave before counting the high time. A configurable timeout (35 ms) terminates a transaction if the slave holds SCK or SDA low too long.

Up to 4 bytes can be transferred in two phases: ``BYTES1`` write bytes (including the I2C address byte), followed by an optional ``BYTES2`` read bytes with a repeated START. SCK and SDA are driven open-drain via ``IOBUF`` primitives: the tristate enable is deasserted when the master needs to drive the line low. Both lines are debounced with a ~50 ns filter (``tSP``) to reject glitches.

The active port is selected by the ``PORT`` register field; all other ports remain tristated.


Additional details
------------------

Memory map
----------

.. include-docs:: i2c
    :start-after: Memory map

