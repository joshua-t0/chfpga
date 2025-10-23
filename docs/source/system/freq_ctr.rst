..   .. title:: FREQ_CTR

:entity:`FREQ_CTR` (FREQ_CTR.vhd)
*************************************

.. title:: FREQ_CTR

.. .. figure:: ../images/FREQCTR.svg
..     :width: 100%

Entity documentation
====================

.. parse:: hdl/SYSTEM/FREQ_CTR.vhd

.. autoentity:: FREQ_CTR


Additional details
==================

Principle of operations
-----------------------

The Frequency counter operates like a desktop frequency counter: it counts the number of rising edges of the the measured signal that happen within a gate time, which is is user-defined number of rising edges of the reference clock. The ratio between the measured vs referece edges times the frequency of the reference clock is the frequency of the measured signal.

The counter is operated solely with the ``start`` signal (``freq_ctr_start``). When ``start`` is 0, both the gate and signal counters are reset to zero as well as the ``ready`` signal.  When 1, the counters starts counting and when the gate counter reaches its destination, it send a signal that stops the signal counter and sets the ``ready`` signal to 1.

To make a measurment, the user sets ``start`` to 0 and then 1, polls the ``ready`` signal until it is asserted, and then reads the final count.


Measured clock signals
----------------------

`FREQ_CTR` does not measure the clock signals directly for a few reasons.

- Some clocks are very fast, perhaps faster than the logic allows
- Routing the  clocks into a mux is awkward and source of many warnings
- But most importantly, routing all the clock signals to a single point utilizes precious clock routing resources and clock buffers. We often run out of BUFH or equivalent local regional clock buffers on the FREQ_CTR clock region, and might even not have enough inferred BUFG.


For this reason, `FREQ_CTR` is provided by a logic signal that toggles at half the rate of the clock. This signal is simply a divide-by-two signal (an inverter and a flip-flop). If that divider is kept local to where the clock is used, we do not use any additional clock buffers. Routing now used standard fabric, not clock lines. The frequency is now in range. And is is easy to mux the clocks signals since they are now standard fabric signals.

Software can account for the fact that we measure only half the frequency.

Signal mux and clock buffer
---------------------------

The entity supports a variable number of divide-by-two signals to be measured (set by ``NUMBER_OF_CLK_IN_PORTS``). We have a 7-bit source selection signal that control the signal mux.

A mux select the signal.  The mux is purely combinatorial. Timing does not matter on this path. Whatever routing delay there is, it does not affect frequency measurement.

The mux output is sent into a clock buffer (BUFH on Kintex 7, BUFG on Ultrascale+) to it can be used to clock the measured signal counter.


CDCs
----

The frequency counter sometimes had infrequent sporadic false results until proper CDC was implemented.

The ``start`` signal is CDCed to both the signal and gate counter processes.

We asynchnously reset the signal counter when 0 to make sure they are cleared even in the absence of a clock. We might not need to CDC  here since it is used asynchronously, but the tool complain that the reset would be released asynchonously, which could be a problem in general. In our case, the ``gate_en`` signal is not set until a few clocks later (due to the CDC latency of the gate signal), so this is not an issue. But why not spare a few flipflops to avoid the warning?

On the gate counter process, the ``start`` signal synchronously resets the counter and state machine, so CDC is crucial. When the gate counter is started, it generates a `gate_en` that enables the signal counter. That ``gate_en`` signal is CDCed from the gate counter clock to the selected signal clock domain to ensure clean signal counter starts and stops. When the gate counter is finished, it generates a ``ready`` signal that is CDCed back to the register clock domain. By the time we read the signal counter, the counter has stopped and is stable, so we need no CDC to the register clock domain for that counter value.

Obviously, the user shall not read the signal counter until ``ready`` has been asserted.


Gate clock and counter width
----------------------------

We use clk200 as a gate clock. It is universally available in the SYSTEM submodule on all platforms, and is fast enough to provide good resolution.


Both gate and signal counters are 32-bit wide. Gate time can be as long as 2**32/200MHz = 21.47 s.

Notes
-----

- Ready will always assert after the gate time, even if there is no transition on the measured signal. We don't have to fear a lock-up in case of a missing signal. The signal counter will clear correctly at the start and will just stay and read back at zero.
- A readout can be interrupted by setting ``start`` to zero (useful if the gate time was set too long), but the counter value is lost.
- We did not implement overflow protection on the signal counter.  The counter will just roll around, yielding non-sensical values. We asume that the gate time will be short enough to prevent any divide-by-two clock to not overflow its counter. Fastest frequencu is 408 MHz (word clock for the 25Gbps link), which is a 204 MHz signal, so measuring for a little less than 21 s should ensure no overflows in this worst case.



Timing constraints
------------------

We'd like to inform the tools how fast the signal counter needs to go (1/2 the frequency of the fastest measured clock). This is tricky.
The timing of each signal wants to propagate to the counter. We try to override it with a new virtual clock connected at the output of the mux or input of the clock buffer, but the target pin does not seem to exist on synthesis (warning) and the tool does not like overriding existing clocks (more warnings).
This will require more investigations.



Memory map
==========

.. include-docs:: FREQ_CTR
    :start-after: Memory map

