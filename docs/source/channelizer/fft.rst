.. title:: FFT


:entity:`FFT`: Fast Fourier Transform (*FFT.vhd*)
*************************************************

.. default-role:: vhdl:entity


.. parse:: hdl/CHAN/FFT.vhd


Entity documentation
====================

.. autoentity:: FFT



Implementation details
======================

The FFT engine is based on a CASPER PFB/FFT combination.

The FFT computes the Fast Fourier Transform with 2\ :sup:`N` \ channels for time samples presented 2\ :sup:`P` \ at a time in parallel. Uses a biplex FFT architecture under the hood which has been extended to handled time samples in parallel. For P = 0, this block accepts two independent, parallel streams (labelled as pols) and computes the FFT of each independently (the biplex architecture provides this for free). Data is output in normal frequency order, meaning that channel 0 (corresponding to DC) is output first, followed by channel 1, on up to channel 2N − 1 (which can be interpreted as channel -1). When multiple time samples are presented in parallel on the input, multiple frequency samples are output in parallel.

In our implementation the CASPER PFB/FFT is generated using Xilinx System Generator, Time-based data is presented 4 samples at a time,  in0 being the earliest sample (see Ports section below). Each time sample is 8 bit wide. Output is the complex frequency samples (18 bits real + 18 bits imaginary). Out0 and out 1 provide the even and odd frequencies respectively. The FFT block also includes a delay block which measures the CASPER block pipelining delay and propagates a vector containing the data flags with the same delay.

Memory Map
==========

.. include-docs:: FFT
    :start-after: Memory Map




