# Common constraints are in ice_physical_constraints_common.xdc

# Constraints for UCORR44. The BRAMs and DSPs are LOCed by AI, so the Pblock is just for the rest of the logic and might not even be needed but old habits die hard.
create_pblock CORR
add_cells_to_pblock [get_pblocks CORR] [get_cells -quiet [list chfpga0/CORRGEN.corr_sel_gen.ucorr44_case.ucorr44_array0]]
resize_pblock [get_pblocks CORR] -add {SLICE_X180Y325:SLICE_X189Y399 SLICE_X180Y0:SLICE_X189Y136 SLICE_X132Y225:SLICE_X179Y399 SLICE_X132Y0:SLICE_X179Y169}
resize_pblock [get_pblocks CORR] -add {DSP48_X8Y90:DSP48_X11Y159 DSP48_X8Y0:DSP48_X11Y67}
resize_pblock [get_pblocks CORR] -add {RAMB18_X8Y90:RAMB18_X11Y159 RAMB18_X8Y0:RAMB18_X11Y67}
resize_pblock [get_pblocks CORR] -add {RAMB36_X8Y45:RAMB36_X11Y79 RAMB36_X8Y0:RAMB36_X11Y33}


# Auto-generated LOC constraints are in ice_physical_constraints_ucorr44.xdc



