######################################
# TIMING CONSTRAINTS - CT SPECIFIC
######################################
# Corner turn-specific timing constraints
# Common constraints are in ice_timing_constraints_common.xdc


################
# GPU LINKS (10G Ethernet)
################

create_clock -period 6.400 -name GPU_REFCLK [get_ports {xge_refclk_p[*]}]
set_clock_groups -name GPU_REFCLK_GROUP -asynchronous -group [get_clocks -include_generated_clocks GPU_REFCLK]

# Vivado 2022.2 does not automatically create the constraints on the GTX RXOUTCLK
create_clock -period 3.103 -name gpu_rxclks0 [get_pins {chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/xglink0/gtx_gen[0].gtx_i/gtxe2_i/RXOUTCLK}]
create_clock -period 3.103 -name gpu_rxclks1 [get_pins {chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/xglink0/gtx_gen[1].gtx_i/gtxe2_i/RXOUTCLK}]
create_clock -period 3.103 -name gpu_rxclks2 [get_pins {chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/xglink0/gtx_gen[2].gtx_i/gtxe2_i/RXOUTCLK}]
create_clock -period 3.103 -name gpu_rxclks3 [get_pins {chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/xglink0/gtx_gen[3].gtx_i/gtxe2_i/RXOUTCLK}]
create_clock -period 3.103 -name gpu_rxclks4 [get_pins {chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/xglink0/gtx_gen[4].gtx_i/gtxe2_i/RXOUTCLK}]
create_clock -period 3.103 -name gpu_rxclks5 [get_pins {chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/xglink0/gtx_gen[5].gtx_i/gtxe2_i/RXOUTCLK}]
create_clock -period 3.103 -name gpu_rxclks6 [get_pins {chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/xglink0/gtx_gen[6].gtx_i/gtxe2_i/RXOUTCLK}]
create_clock -period 3.103 -name gpu_rxclks7 [get_pins {chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/xglink0/gtx_gen[7].gtx_i/gtxe2_i/RXOUTCLK}]

create_clock -period 3.103 -name gpu_txclk [get_pins {chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/xglink0/gtx_gen[0].gtx_i/gtxe2_i/TXOUTCLK}]
set_clock_groups -name gpu_txclk_group -asynchronous -group [get_clocks -include_generated_clocks gpu_txclk]

#############################
# BP SHUFFLE clocks
################################

# The GTX requires us to specify a constraint for the RX and TX clock. These are not derived from the reference clock.
# For the RX clock, we buldle all of the GTX RX clock in one constraint
create_clock -period 4.096 -name bp_rxclks [get_pins {chfpga0/*.ct0/*.bp_shuffle0/core0/gtx_gen[*].gtx_i/gtxe2_i/RXOUTCLK}]
# For the tx clock, we use only the clock from lane 0.
create_clock -period 4.096 -name bp_txclk [get_pins {chfpga0/*.ct0/*.bp_shuffle0/core0/gtx_gen[0].gtx_i/gtxe2_i/TXOUTCLK}]
# We create a constraint to ignore any interaction with the tx clock and other clocks
set_clock_groups -name bp_txclk_group -asynchronous -group [get_clocks -include_generated_clocks bp_txclk]
