.. title:: spi

*****************************************
:entity:`spi` (*spi.vhd*): SPI peripheral
*****************************************

.. figure:: ../images/SYSTEM/spi.svg
    :width: 100%

Entity documentation
====================

.. parse:: hdl/system/spi.vhd

.. autoentity:: spi

Parameters
==========

- **NUMBER_OF_SS_LINES:** Number of independent SPI slave-select lines (chip selects). Determines the width of the ``spi_ss_n`` port and the ``SS_SEL`` register field (default 1).
- **CLK_FREQ:** Input clock frequency in Hz. Used to compute the SPI clock divider (default 200 MHz).
- **SPI_CLK_FREQ:** SPI SCK frequency in Hz (default 25 MHz). Sets the divider to produce the correct half-period.
- **CPOL:** SPI clock polarity: ``0`` = SCK idle low, ``1`` = SCK idle high (default 0, CPOL=0).
- **CPHA:** SPI clock phase: ``0`` = data captured on the first clock edge, ``1`` = data captured on the second clock edge (default 0, CPHA=0).
- **MSB_FIRST:** When ``TRUE``, the MSB of the byte is transmitted/received first (default ``TRUE``).

Interface
=========

- ``s/m_axis_bsb_t*``: BSB (Byte-Stream Bus) interface for register-based control.
- ``bsb_clk``/``bsb_rst``: BSB clock and reset.
- ``spi_clk``: SPI SCK output. Divided from ``clk200`` with a configurable ratio.
- ``spi_mosi``: SPI MOSI output. Data is shifted out MSB-first or LSB-first according to ``MSB_FIRST``.
- ``spi_miso``: SPI MISO input. Data is shifted in MSB-first or LSB-first.
- ``spi_ss_n``: Active-low slave-select vector, ``NUMBER_OF_SS_LINES`` wide. The selected line is driven low during a transaction.
- ``clk200``: 200 MHz clock. Clocks the SPI state machine and SCK divider.
- ``rst``: Synchronous reset.


Implementation details
======================

Principle of operations
-----------------------

The SPI controller divides ``clk200`` by a configurable factor (``CLK_DIVIDE_FACTOR``) using a prescaler counter to generate a clock-enable signal ``ce``. Each SCK half-period is further divided into four internal phases. At phase 0 SCK is driven low and the transmit shift register is loaded (first bit) or left-shifted (subsequent bits), presenting the next MOSI bit. At phase 1 the active slave-select line (``spi_cs_n``) is asserted. At phase 2 SCK is driven high and the MISO sample is captured and shifted into the receive register. At phase 3 the bit counter is decremented and, on the last bit, CS is deasserted and the ``ready`` flag is set. A transaction is triggered by detecting a 0-to-1 edge on the ``START_TRIG`` control-byte field.

Architecture
------------

Transactions of 1 to 4 bytes are supported, set by the ``BYTES`` field. The 32-bit transmit register is loaded MSB-first and left-shifted each bit period; the receive register assembles the received data so the MSB of the first byte always occupies bit 31 of the 32-bit ``RX_DATA`` status field regardless of transaction length. An ``alt_timing`` mode defers CS deassertion by one quarter-clock to accommodate peripherals (such as certain ADC PLLs) that require the latch-enable to remain active longer than the standard SPI specification. The register interface is handled by an internal ``bsb_regs`` instance (6 control bytes, 5 status bytes) that runs on ``bsb_clk``.

Clocking
--------

The SPI state machine runs on ``clk200`` (200 MHz). The BSB register interface runs on ``bsb_clk`` (125 MHz) through the internal ``bsb_regs`` instance. Register values are written by software before the transaction is started, so no explicit clock-domain crossing is required between the two domains.


Additional details
==================

The SPI entity is a very simple SPI controller that can perform 1, 2,3 or 4 bytes tansactions (the count includes both read and write bytes).
The module is operated through control and status registers, and there is no buffer or FIFO. Throughput is therefore limited. The SPI controller provided by the platform processor, if available, should be used if a high-performance interface is required.

Operations
----------

A transaction is performed as follows:

- Write N bytes to transmit in the TX_BYTES register
- Set the number of bytes of the transaction, address and port
- Write 0 then 1 in the START_TRIG register to initiate the transfer
- Wait for the READY bit to be set to 1
- Read the readout bits in RX_REGISTER

Memory map
==========

.. include-docs:: spi
    :start-after: Memory map

