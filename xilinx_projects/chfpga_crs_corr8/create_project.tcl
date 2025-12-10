#!/usr/bin/env -S vivado -mode batch -notrace -source
#*****************************************************************************************
# create_project.tcl: Tcl script for re-creating the project in the folder of this script
#*****************************************************************************************

# Make sure the cwd is the folder containing this script
cd [file normalize [file dirname [info script]]]

# Get variables defining project sources
source ../../tcl/project_sources.tcl

# Set project target part and source files
set target_part $crs_target_part
set bd_name $crs_bd_name
set ooc_ip_files $crs_ooc_ip_files
set ip_files $crs_corr_ip_files
set hdl_files [concat $crs_corr_hdl_files "chfpga_crs_corr8_config.vhd" ]
set const_files [list \
	 "crs/crs_physical_constraints_corr.xdc"\
	 "crs/crs_physical_constraints_common.xdc"\
]
# Create project
source ../../tcl/create_generic_project.tcl
