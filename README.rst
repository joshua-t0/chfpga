.. Use UTF-8 encoding

Quick links
===========

- Source code: https://github.com/winterlandcosmology/chfpga

- Online documentation: https://winterlandcosmology.github.io/chfpga (use ``make docs`` to build the documentation locally in ``docs/build/html``)


Introduction
============

``chFPGA`` is a multiplatform FPGA firmware designed to implement wide bandwidth radiotelescope and radio-interferometers front-ends. It provides the following components:

- F-Engine (channelizer)
- Corner-turn engine (groups data from one or multiple boards by frequency)
- Optional X-engine (:math:`N^2` correlator)
- Optional real-time 80G/100G Ethernet streaming of corner-turned data
- Hardware platform management and peripheral controllers...

Arrays of one or more FPGAs running the ``chFPGA`` firmware are meant to be operated through the Python package ``pychfpga`` (see https://winterlandcosmology.github.io/pychfpga)
