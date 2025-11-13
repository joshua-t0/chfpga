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
set config_file "chfpga_ice_ct_config.vhd"
set top_wrapper_file $ice_top_wrapper_file

# Define list of IP files, with path relative to $ip_dir
set ip_files $ice_ct_ip_files
set hdl_files $ice_ct_hdl_files
set ooc_ip_files [list "KC705/hirax_bit_growth_0/hirax_bit_growth_0.xci"]

set const_files [list \
	"mgk7mb/chfpga_mgk7mb_timing_constraints.xdc" \
	"mgk7mb/chFPGA_mgk7mb_Rev2_physical_constraints.xdc" \
 ]



source ../../tcl/create_generic_project.tcl
