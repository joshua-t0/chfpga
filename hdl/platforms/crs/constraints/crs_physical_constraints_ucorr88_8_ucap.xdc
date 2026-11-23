# CRS corr8 with the (8+8)-bit correlator: UCAP has no place of its own.
# Read this file after crs_physical_constraints_common.xdc, which makes the UCAP pblock around the UltraRAMs
# URAM288_X0Y64 to Y79. In this build the correlator has those UltraRAMs, and the two UCAP buffers that have memory
# are block RAMs (30 RAMB36) that do not fit in that pblock. The placer puts UCAP where block RAMs are free.
remove_cells_from_pblock [get_pblocks UCAP] [get_cells -quiet [list chfpga0/chan_array0/cap_gen.uram_case.ucap0]]
