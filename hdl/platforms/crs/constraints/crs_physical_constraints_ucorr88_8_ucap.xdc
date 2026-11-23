# CRS corr8 with the (8+8)-bit correlator, 22 + 22-bit cross-products: the 4 UCAP buffers that have memory use the
# last 8 UltraRAMs (the correlator has URAM288_X0Y0 to Y71). Read this file after crs_physical_constraints_chan_LOCs.xdc.
set_property LOC URAM288_X0Y72 [get_cells {chfpga0/chan_array0/cap_gen.uram_case.ucap0/uram_gen[0]*/*/*_uram_0}]
set_property LOC URAM288_X0Y73 [get_cells {chfpga0/chan_array0/cap_gen.uram_case.ucap0/uram_gen[0]*/*/*_uram_1}]
set_property LOC URAM288_X0Y74 [get_cells {chfpga0/chan_array0/cap_gen.uram_case.ucap0/uram_gen[1]*/*/*_uram_0}]
set_property LOC URAM288_X0Y75 [get_cells {chfpga0/chan_array0/cap_gen.uram_case.ucap0/uram_gen[1]*/*/*_uram_1}]
set_property LOC URAM288_X0Y76 [get_cells {chfpga0/chan_array0/cap_gen.uram_case.ucap0/uram_gen[2]*/*/*_uram_0}]
set_property LOC URAM288_X0Y77 [get_cells {chfpga0/chan_array0/cap_gen.uram_case.ucap0/uram_gen[2]*/*/*_uram_1}]
set_property LOC URAM288_X0Y78 [get_cells {chfpga0/chan_array0/cap_gen.uram_case.ucap0/uram_gen[3]*/*/*_uram_0}]
set_property LOC URAM288_X0Y79 [get_cells {chfpga0/chan_array0/cap_gen.uram_case.ucap0/uram_gen[3]*/*/*_uram_1}]

# The three block RAMs of the FIFOs of the AXI DMAs have exactly the three block RAM sites of the TCPIPE pblock.
# With the larger correlator the placer often fails to put them there ("BRAM area constraints are over utilized").
# They get the sites that they have in the build with the 4-bit correlator.
set_property LOC RAMB36_X2Y9 [get_cells -hierarchical -filter {NAME =~ zynq/axi_dma_0/*GEN_MM2S_FULL*I_DATA_FIFO*mem_reg* && REF_NAME == RAMB36E2}]
set_property LOC RAMB36_X2Y10 [get_cells -hierarchical -filter {NAME =~ zynq/axi_dma_0/*GEN_S2MM_FULL*I_DATA_FIFO*mem_reg* && REF_NAME == RAMB36E2}]
set_property LOC RAMB36_X2Y11 [get_cells -hierarchical -filter {NAME =~ zynq/axi_dma_1/*GEN_S2MM_FULL*I_DATA_FIFO*mem_reg* && REF_NAME == RAMB36E2}]
