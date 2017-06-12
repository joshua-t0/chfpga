:entity:`CHAN`:Channelizer engine
*********************************

.. title:: CHAN

.. figure:: ../images/channelizer.svg
    :width: 75%

The Channelizer (CHAN) implements the main data acquisition pipeline for the chFPGA project. It recieves a data stream from the ADCs and passes it to the Function Generator sub-module (FUNCGEN). The Function Generator can pass the ADC data down the pipeline or it can insert used-defined packets. The Channelizer then performs a 2048-sample PFB-FFT on the data and forwards the result to a Scaler (SCALER) sub-module which applies complex gains on the resulting spectrum and scales it down to (4+4) bit complex representsation. The output stream is then resynchronized to an external output clock (typically a correlator or corner-turn subsystem clocks) through a FIFO (CHAN_FIFO).

The Channelizer consists of the following sub-modules:

.. toctree::
   :titlesonly:

   adcdaq
   funcgen
   fft
   scaler
   prober
   chan_fifo



- :entity:`adcdaq`: ADC Data Acquisition (ACQ)
    - :entity:`adcdaq_fifo`:
- :entity:`funcgen`: Generate user-defined packstes, test pattern packets, or just pass on the ADC data.
    - :entity:`funcgen_ram`:
- :entity:`fft`: my FFT
- :entity:`scaler`: my scaler
- :entity:`chan_fifo`: FIFO to cross data between the channelizer and the corner-turn or correlator engines
- :entity:`prober`: Captures and buffer a subset of the raw ADC or SCALER output data and send it back over the control channel
    - :entity:`prober_data_fifo`: FIFO to store the captured data and cross between the channelizer and control system clock domains
    - :entity:`prober_frame_fifo`: FIFO to store the frame header to be sent before the captured data
- :entity:`router`: The router recieves commands through the UDP Command Protocol backbone from
  chFPGA and relays them to all the necessary sub-modules relevent to the channelizer. The addresses
  for each sub-module are shown below.




Entity documentation
--------------------

.. parse:: hdl/CHAN/CHAN.vhd

.. autoentity:: CHAN


.. .. highlight:: vhdl

..  .. role:: vhdl(code)
..   :language: vhdl


Additional details
------------------

Memory map
----------

.. include-docs:: CHAN
    :start-after: CHANNELIZER Memory Map

