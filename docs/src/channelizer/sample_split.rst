sample_split
============

**File:** ``hdl/chan/sample_split.vhd``

``sample_split`` is the split-sample stage between the channelizers and the corner-turn engine. It is in the builds that have a correlator on the same board and the same clock as the channelizers (corr8: ``SPLIT_SAMPLE_SUPPORT`` of ``chan_array``).

Purpose
-------

The correlator takes (4+4)-bit values. In the split-sample mode it correlates 4 inputs with nearly 7 bits for each component. Each wide value is sent as two parts, and each part is one input of the correlator, which does not change. The host makes the 10 products of the 4 wide inputs from the 36 products of the 8 correlator inputs.

Default mode
------------

With ``split_mode`` = '0' (control byte 3 bit 4 of ``UCORR44_ARRAY``, the reset value), each lane passes the (4+4)-bit value of its channelizer. The correlator gets the same data as in a build without this stage, two clocks later.

The scalers of channelizers 0 to 3 have (8+8)-bit outputs in these builds, and the others have (4+4)-bit outputs. In the 4-bit mode (``four_bits`` = '1'), a scaler with (8+8)-bit outputs gives the same 4-bit values, in the 4 MSBs of each component (``scaler_width_testbench``).

Split mode
----------

With ``split_mode`` = '1', the scalers of channelizers 0 to 3 must be in the 8-bit mode (``four_bits`` = '0') with two's complement outputs. For each component:

- ``w`` is the component, saturated to -60 ... 59;
- ``t = w + 4``;
- ``high = t(6 downto 3)``, from -7 to 7;
- ``low = (not t(2)) & t(1 downto 0)``, sign-extended, from -4 to 3.

Thus ``w = 8 * high + low``, and no part is -8. Wide input ``i`` (channelizer ``i``) drives correlator input ``2i`` with ``high`` and correlator input ``2i + 1`` with ``low``. The two parts of a sample are in the same word, so they are in the same frame and the same bin in the correlator. Channelizers 4 to 7 are not correlated in this mode.

For two wide inputs, with ``hh``, ``hl``, ``lh`` and ``ll`` the products of their parts, the product of the wide values is ``64 hh + 8 (hl + lh) + ll``.

A change of ``split_mode`` takes effect at the end of a frame, so a frame has one mode only. The 4-bit or 8-bit mode of the scalers and their gains do not change at that time: the host sets them, and discards the integration during which it changes the mode.

Status
------

``UCORR44_ARRAY`` has the status of this stage: bit 5 of status byte 5 is '1' if the build has the stage, and status bytes 12 to 19 have, for each wide input, a 16-bit count of the words in which a component was saturated at -60 or 59. The counts stop at 65535 and are cleared by ``overrun_reset``.

Operating limits
----------------

The products of the parts are accumulated as the other products: the cross-products in 18 + 18 bits with saturation flags, and the autocorrelations (``high`` x ``high`` and ``low`` x ``low`` of one input) in 36 bits.
