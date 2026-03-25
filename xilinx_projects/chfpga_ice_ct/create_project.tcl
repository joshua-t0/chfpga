#!/usr/bin/env -S vivado -mode batch -notrace -source
#*****************************************************************************************
# create_project.tcl: Tcl script for re-creating the project in the folder of this script
#*****************************************************************************************

# Make sure the cwd is the folder containing this script
cd [file normalize [file dirname [info script]]]

# Get variables defining project sources
source ../../tcl/project_sources.tcl

set platform_dir $ice_platform_dir

# Set project target part and source files
set target_part $ice_target_part
set ooc_ip_files $ice_ct_ooc_ip_files
set ip_files $ice_ct_ip_files
set hdl_files [concat $ice_ct_hdl_files "platforms/ice/chfpga_ice_ct_config.vhd"]
set const_files [list \
	"ice_timing_constraints_common.xdc" \
	"ice_timing_constraints_ct.xdc" \
	"ice_physical_constraints_common.xdc" \
	"ice_physical_constraints_ct.xdc" \
	"ice_physical_constraints_hirax_fft.xdc" \
]

# Enable LUT combining, otherwise the design does not fit
set no_lc "0"

# Create project
source ../../tcl/create_generic_project.tcl
