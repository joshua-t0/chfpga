#!/usr/bin/env -S vivado -mode batch  -source
#*****************************************************************************************
# create_project.tcl: Tcl script for re-creating the project in the folder of this script
#*****************************************************************************************

# Make sure the cwd is the folder containing this script
cd [file normalize [file dirname [info script]]]

# Get variables defining project sources
source ../../tcl/project_sources.tcl

# Set project target part and source files
set target_part $kc705_target_part
set ooc_ip_files $kc705_corr8_ooc_ip_files
set ip_files $kc705_corr8_ip_files
set hdl_files [concat $kc705_corr8_hdl_files "chfpga_kc705_corr8_config.vhd" ]
set const_files [list \
	"kc705/chFPGA_KC705_timing_constraints.xdc" \
	"kc705/chFPGA_KC705_physical_constraints.xdc" \
]

# Enable LUT combining, otherwise the design may not fit
set no_lc "0"

# Create project
source ../../tcl/create_generic_project.tcl
