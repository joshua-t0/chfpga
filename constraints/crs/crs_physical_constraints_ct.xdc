############################################################################
##
##   CRS Rev1.0 Physical constraints - "-ct" config-specific
##
############################################################################


# -- QSFP Connector for 100G Ethernet (CGE)
# -- GTY QSFP28 ports - Bank 128
# Note: The pin assignments here overrides the pins assigned in the CMAC IP
#set_property PACKAGE_PIN Y35 [get_ports {qsfp_txp[0]}]
#set_property PACKAGE_PIN V35 [get_ports {qsfp_txp[1]}]
#set_property PACKAGE_PIN T35 [get_ports {qsfp_txp[2]}]
#set_property PACKAGE_PIN R33 [get_ports {qsfp_txp[3]}]
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
add_cells_to_pblock [get_pblocks UCORN] [get_cells -quiet [list chfpga0/crossbar0_gen.cb1_gen.uram_case.uram0]]
resize_pblock [get_pblocks UCORN] -add {SLICE_X15Y180:SLICE_X19Y419 SLICE_X13Y220:SLICE_X14Y239}
resize_pblock [get_pblocks UCORN] -add {RAMB18_X1Y88:RAMB18_X1Y95}
resize_pblock [get_pblocks UCORN] -add {RAMB36_X1Y44:RAMB36_X1Y47}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks UCORN]
set_property IS_SOFT FALSE [get_pblocks UCORN]




set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets smp_OBUF[3]]
