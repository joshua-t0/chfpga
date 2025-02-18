create_pblock PFB0
resize_pblock [get_pblocks PFB0] -add {SLICE_X92Y0:SLICE_X105Y59}
resize_pblock [get_pblocks PFB0] -add {DSP48E2_X18Y0:DSP48E2_X20Y23}
resize_pblock [get_pblocks PFB0] -add {RAMB18_X9Y0:RAMB18_X10Y23}
resize_pblock [get_pblocks PFB0] -add {RAMB36_X9Y0:RAMB36_X10Y11}



set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets smp_OBUF[3]]
