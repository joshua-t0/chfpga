.. title:: blinker

********************************************************
:entity:`blinker` (*blinker.vhd*): Heartbeat LED blinker
********************************************************

.. .. figure:: ../images/blinker.svg
..     :width: 100%

Entity documentation
====================

.. parse:: hdl/system/blinker.vhd

.. autoentity:: blinker

Parameters
==========

- **PING_PONG:** If ``TRUE``, the leading lit LED bounces back and forth between the two ends of the LED array. If ``FALSE``, it continuously rotates in one direction.
- **DUMMY:** If ``TRUE``, disables the blinker entirely — all LED outputs are driven to ``'0'``.
- **STYLE:** Selects the LED animation style. ``0``: single one-hot LED; ``1``: ramp-up PWM trail; ``2``: ramp-down PWM trail; ``3``: classic ramp-up then ramp-down trailing glow (default).

Interface
=========

- ``rst``: Synchronous reset. Resets the counters and returns the lead bit to position 0.
- ``clk``: System clock.
- ``kick``: Pulse input that advances the blink pattern one step immediately when asserted, accelerating the apparent blink rate.
- ``leds``: 8-bit LED output vector driven with the selected animation pattern.

Implementation details
======================

A free-running 32-bit counter drives three PWM duty cycles (1/32, 1/4, and 100%). A ``lead`` shift register holds the one-hot position of the bright LED and advances every ~2²³ clock cycles (or sooner when ``kick`` is pulsed). A ``trail`` array records the recent passage of the lead bit per LED position, enabling the trailing glow effect by ANDing trail history with PWM levels.


Additional details
==================


Memory map
==========

The :entity:`blinker` module does ot have memory mapped register.

