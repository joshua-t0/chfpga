Corner-Turn Engine
******************

.. toctree::

..    - Corner turn engine (Used in CHIME)
..       - :entity:`chan_crossbar` : 1st corner-turn engine (takes data from the channelizers)
..       - :entity:`shuffle_crossbar` : 2nd and 3rd corner-turn engine (takes data from a previous crossbars)
..       - :entity:`backplane-shuffle`: Sends and receive packets to other boards over the backplane and QSFP+ cables

   chan_crossbar: 1st corner-turn engine (takes data from the channelizers) <chan_crossbar>
   backplane-shuffle: Sends and receive packets to other boards over the backplane and QSFP+ cables <backplane_shuffle>
   shuffle_crossbar: 2nd and 3rd corner-turn engine (takes data from a previous crossbars) <shuffle_crossbar>

   .. chdist_data_embed_fifo
   .. chdist_frame_fifo
   .. chdist_scaler_flag_fifo
   .. crossbar
   .. mask_ram
   .. shuffle-bin-sel-mask-ram
   .. shuffle_bin_sel_data_fifo_bram
   .. shuffle_bin_sel_data_fifo_embed
   .. shuffle_bin_sel_flags_fifo
   .. shuffle_crossbar_align_fifo

