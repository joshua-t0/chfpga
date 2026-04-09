#!/usr/bin/env -S vivado -mode batch -notrace -source
#*****************************************************************************************
# create_project.tcl: Tcl script for re-creating the project in the folder of this script
#*****************************************************************************************

cd [file normalize [file dirname [info script]]]

source ../../tcl/project_sources.tcl

set platform_dir $zcu111_platform_dir

set target_part $zcu111_target_part
set bd_name $zcu111_bd_name
set ooc_ip_files $zcu111_ooc_ip_files
set ip_files $zcu111_ct_ip_files
set hdl_files [concat $zcu111_ct_hdl_files "platforms/zcu111/chfpga_zcu111_ct_config.vhd"]
set const_files [list \
  "zcu111_physical_constraints.xdc" \
]

source ../../tcl/create_generic_project.tcl
