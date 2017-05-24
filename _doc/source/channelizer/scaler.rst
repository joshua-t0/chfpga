:entity:`SCALER`: Scaler
************************

Overview
--------
Scales the FFT output into (8+8) bits or (4+4) bits complex values by applying a constant or table-based complex gain, shifting the results, and truncate or round the value to the desired format.

.. parse:: hdl/chan/SCALER.vhd


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

