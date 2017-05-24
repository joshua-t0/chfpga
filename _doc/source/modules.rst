chFPGA Modules
**************


.. toctree::
   :titlesonly:

   Data Acquisition Engine
   channelizer/chan
   Corner turn engine (Used in CHIME) <corner-turn/corner-turn>
   Correlator engine (X-Engine) (Not used in CHIME) <correlator/corr44_array>




.. HDL Modules
.. ===========
.. - chFPGA
..  - :entity:`CHAN`:
..      - :entity:`adcdaq`
..      - :entity:`fft`
..      - :entity:`funcgen`
..      - :entity:`prober`
..      - :entity:`scaler`
..      - :entity:`channelizer-fifo`
..  - Corner turn engine (Used in CHIME)
..      - :entity:`chan_crossbar` : 1st corner-turn engine (takes data from the channelizers)
..      - :entity:`shuffle_crossbar` : 2nd and 3rd corner-turn engine (takes data from a previous crossbars)
..      - :entity:`backplane-shuffle`: Sends and receive packets to other boards over the backplane and QSFP+ cables
..  - Correlator engine (X-Engine) (Not used in CHIME)
..      - :entity:`corr44_array`: Implements a number of independent correlator cores
..          - :entity:`corr44`
..              - :entity:`cmac44`


.. Xilinx IP Modules
.. =================

.. :ref:`adcdaq-fifo-xil-module`

.. :ref:`axi4s-reg-slice-xil-module`

.. :ref:`chan-fifo2-xil-module`

.. :ref:`chdist-data-embed-fifo-xil-module`

.. :ref:`chdist-frame-fifo-xil-module`

.. :ref:`chdist-scaler-flag-fifo-xil-module`

.. :ref:`cmd-fifo-xil-module`

.. :ref:`funcgen-ram-xil-module`

.. :ref:`mask-ram-xil-module`

.. :ref:`prober-data-fifo-xil-module`

.. :ref:`prober-frame-fifo-xil-module`

.. :ref:`scaler-coeff-ram-xil-module`

.. :ref:`scaler-mul-xil-module`

.. :ref:`shuffle-bin-sel-data-fifo-bram-xil-module`

.. :ref:`shuffle-bin-sel-data-fifo-embed-xil-module`

.. :ref:`shuffle-bin-sel-flags-fifo-xil-module`

.. :ref:`shuffle-bin-sel-mask-ram-xil-module`

.. :ref:`shuffle_crossbar-align-fifo-xil-module`

.. :ref:`udp-mac-tx-data-fifo-xil-module`

.. :ref:`udp-mac-tx-frame-fifo-xil-module`

.. :ref:`xglink-rx-data-fifo-xil-module`

.. :ref:`xglink-tx-data-fifo-xil-module`

.. :ref:`xgmii-udp-mac-tx-header-fifo-xil-module`

.. :ref:`xgmii-udp-mac-tx-data-fifo-xil-module`

.. CASPER IP Modules
.. =================
