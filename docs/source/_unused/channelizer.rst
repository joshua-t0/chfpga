.. _channelizer-module:

Channelizer
***********

Overview
--------

.. figure:: images/channelizer.svg
    :width: 75%

The Channelizer (CHAN) implements the main data acquisition pipeline for the chFPGA project. It recieves a data stream from the ADCs and passes it to the Function Generator sub-module (FUNCGEN). The Function Generator can pass the ADC data down the pipeline or it can insert used-defined packets. The Channelizer then performs a 2048-sample PFB-FFT on the data and forwards the result to a Scaler (SCALER) sub-module which applies complex gains on the resulting spectrum and scales it down to (4+4) bit complex representsation. The output stream is then resynchronized to an external output clock (typically a correlator or corner-turn subsystem clocks) through a FIFO (CHAN_FIFO).

The Channelizer consists of the following sub-modules:


- :entity:`router`: The router recieves commands through the UDP Command Protocol backbone
    from chFPGA and relays them to all the necessary sub-modules relevent to the channelizer. The addresses for each sub-module are shown below.
- :entity:`funcgen`: Generate user-defined packstes, test pattern packets, or just pass on the ADC data.
- :entity:`adcdaq` : ADC DAQ
- :entity:`fft`: my FFT
- :entity:`scaler`: my scaler
- :entity:`prober`: my prober
- :entity:`chan_fifo`: Resynchronization FIFO (CHAN_FIFO)


Memory map
----------

.. include-docs:: ../hdl/chan/chan.vhd
    :start-after: CHANNELIZER Memory Map

Ports
-----
.. literalinclude:: ../../hdl/CHAN/CHAN.vhd
     :language: vhdl
     :start-after: entity CHAN is
     :end-before: end CHAN;


