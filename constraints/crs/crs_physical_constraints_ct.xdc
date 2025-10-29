############################################################################
##
##   CRS Rev1.0 Physical constraints - "-ct" config-specific
##
############################################################################


# -- QSFP Connector for 100G Ethernet (CGE)
# -- GTY QSFP28 ports - Bank 128
# Note: The pin assignments here overrides the pins assigned in the CMAC IP
set_property PACKAGE_PIN Y35 [get_ports {qsfp_txp[0]}]
set_property PACKAGE_PIN V35 [get_ports {qsfp_txp[1]}]
set_property PACKAGE_PIN T35 [get_ports {qsfp_txp[2]}]
set_property PACKAGE_PIN R33 [get_ports {qsfp_txp[3]}]

# -----
# 100G interface
# -----

# GTY reference clock, 156.25 MHz from fixed PLL, Bank 129
# This is config-specific
set_property PACKAGE_PIN W33 [get_ports clk156_p]
#set_property PACKAGE_PIN W33 [get_ports clk156_p]
# Note: clock period is defined by the CMAC IP and does not need to be defined below.
#create_clock -name CLK156 -period 6.4 [get_ports {clk156_p}]


########################################
########################################
# Floorplanning constraints
########################################
########################################



create_pblock CGE
add_cells_to_pblock [get_pblocks CGE] [get_cells -quiet [list chfpga0/GPU_GEN.gpu_sel_gen.cge_case.cge0]]
resize_pblock [get_pblocks CGE] -add {SLICE_X13Y180:SLICE_X14Y219 SLICE_X10Y180:SLICE_X12Y239}
resize_pblock [get_pblocks CGE] -add {RAMB18_X1Y72:RAMB18_X1Y87}
resize_pblock [get_pblocks CGE] -add {RAMB36_X1Y36:RAMB36_X1Y43}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks CGE]
set_property IS_SOFT FALSE [get_pblocks CGE]


create_pblock UCORN
add_cells_to_pblock [get_pblocks UCORN] [get_cells -quiet [list chfpga0/GPU_GEN.gpu_sel_gen.cge_case.uram0]]
resize_pblock [get_pblocks UCORN] -add {SLICE_X15Y180:SLICE_X19Y419 SLICE_X13Y220:SLICE_X14Y239}
resize_pblock [get_pblocks UCORN] -add {RAMB18_X1Y88:RAMB18_X1Y95}
resize_pblock [get_pblocks UCORN] -add {RAMB36_X1Y44:RAMB36_X1Y47}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks UCORN]
set_property IS_SOFT FALSE [get_pblocks UCORN]



create_pblock CORN
add_cells_to_pblock [get_pblocks CORN] [get_cells -quiet [list chfpga0/ct_gen.uct_case.ct0]]
resize_pblock [get_pblocks CORN] -add {SLICE_X6Y360:SLICE_X11Y419 SLICE_X0Y330:SLICE_X5Y419}
resize_pblock [get_pblocks CORN] -add {BUFG_GT_X0Y144:BUFG_GT_X0Y191}
resize_pblock [get_pblocks CORN] -add {BUFG_GT_SYNC_X0Y90:BUFG_GT_SYNC_X0Y119}
resize_pblock [get_pblocks CORN] -add {DSP48E2_X0Y144:DSP48E2_X0Y167}
resize_pblock [get_pblocks CORN] -add {RAMB18_X0Y144:RAMB18_X0Y167}
resize_pblock [get_pblocks CORN] -add {RAMB36_X0Y72:RAMB36_X0Y83}
set_property IS_SOFT FALSE [get_pblocks CORN]



set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets smp_OBUF[3]]
