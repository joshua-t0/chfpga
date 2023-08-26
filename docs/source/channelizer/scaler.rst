:entity:`SCALER`: Scaler
************************

Overview
--------
Scales the FFT output (typically in 18+18 bits format) into (8+8) bits or (4+4) bits complex values by applying a real or complex gain in each freqency bin and truncate or round the value to the desired format.

.. parse:: hdl/CHAN/SCALER.vhd


.. toctree::
	:titlesonly:

	scaler_mul


Entity documentation
--------------------


.. autoentity:: SCALER


Memory Map
----------

.. include-docs:: SCALER
    :start-after: SCALER Module Memory Map

