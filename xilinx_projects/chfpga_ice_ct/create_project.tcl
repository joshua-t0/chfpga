#!/usr/bin/env -S vivado -mode batch -notrace -source
#*****************************************************************************************
# create_project.tcl: Tcl script for re-creating the project in the folder of this script
#*****************************************************************************************

# Make sure the cwd is the folder containing this script

cd [file normalize [file dirname [info script]]]

# Get variables that will be used to define the project sources
source ../../tcl/project_sources.tcl

set target_part $ice_target_part
set bd_name $ice_bd_name

# Define config files, with path relative to $hdl_dir
# set config_file "chfpga_ice_ct_config.vhd"


# Define list of IP files, with path relative to $ip_dir
set ooc_ip_files $ice_ooc_ip_files
set ip_files $ice_ct_ip_files
set hdl_files [concat $ice_ct_hdl_files "chfpga_ice_ct_config.vhd" ]

set const_files [list \
	"mgk7mb/chfpga_mgk7mb_timing_constraints.xdc" \
	"mgk7mb/chFPGA_mgk7mb_Rev2_physical_constraints.xdc" \
 ]

# Enable LUT combining, otherwise the design does not fit
set no_lc "0"


source ../../tcl/create_generic_project.tcl
