#!/usr/bin/env -S vivado -mode batch -notrace -source
#*****************************************************************************************
# Vivado (TM) v2022.2 (64-bit)
#
# build.tcl: Tcl script for building the project in the current folder and generate its bitstream
#
# The script re-creates the project by calling create_project.tcl before building it.
#
# Usage:
#
#  # Make sure the vivado environment is enabled
#
#      source <path_to_vivado_install>/settings64.sh
#
#  # Run this script
#
#      ./build_project.tcl
#
#*****************************************************************************************


set t_start [clock seconds]

# Disable echo of script command
# set ::tcl_trace 0
# set ::tclapp::xilinx::common::quiet_mode 1

# cd to the script folder
# cd [file dirname [info script]]

source ./create_project.tcl

puts ""
puts "------------------------------------------------------------------------------------------------------------"
puts "Building project ${proj_name} in folder ${proj_dir}"
puts "------------------------------------------------------------------------------------------------------------"
puts ""

# # Upgrade IP so runs aren't frozen and build can proceed
# upgrade_ip [get_ips  {gtwizard_ultrascale_0 zynq_tcpipe_crs_zynq_ultra_ps_e_0_0}] -log ip_upgrade.log
# generate_target all [get_files zynq_tcpipe_crs.bd]

# # Launch runs
# launch_runs impl_1 -to_step write_bitstream -jobs 8

# # These wait_on_run commands surface stdout/stderr - we really only need the
# # impl_1 but would rather see what's happening on the way there.
# wait_on_run pfb_fft_bitgrowth_0_synth_1			\
# 	zynq_tcpipe_crs_smartconnect_0_0_synth_1	\
# 	zynq_tcpipe_crs_system_ila_0_0_synth_1		\
# 	zynq_tcpipe_crs_zynq_ultra_ps_e_0_0_synth_1

# wait_on_run synth_1
# wait_on_run impl_1


  # Upgrade IP so runs aren't frozen and build can proceed
  upgrade_ip [get_ips] -log ip_upgrade.log
  generate_target all [get_files $bd_files]

  # Launch runs

puts ""
puts "------------------------------------------------------------------------------------------------------------"
puts "Synthesizing OOC modules"
puts "------------------------------------------------------------------------------------------------------------"
puts ""

  set synth_runs [get_runs *_synth_1]
  
  if {[llength $synth_runs] == 0} {
    puts "INFO: no synth runs to execute, skipping"
  } else {
      reset_run   $synth_runs
      launch_runs $synth_runs -jobs 8 -verbose
      wait_on_run $synth_runs
  }


puts ""
puts "------------------------------------------------------------------------------------------------------------"
puts "Synthesizing global project"
puts "------------------------------------------------------------------------------------------------------------"
puts ""
  launch_runs synth_1 -jobs 8 -verbose
  wait_on_run synth_1

puts ""
puts "------------------------------------------------------------------------------------------------------------"
puts "Implementing"
puts "------------------------------------------------------------------------------------------------------------"
puts ""
  launch_runs impl_1 -to_step write_bitstream -jobs 8 -verbose
  wait_on_run impl_1

#   foreach r [get_runs -filter {IS_SYNTHESIS}] {
#     launch_runs $r -jobs 8 -verbose
#     wait_on_run $r
# }

  # These wait_on_run commands surface stdout/stderr - we really only need the
  # impl_1 but would rather see what's happening on the way there.
  # wait_on_run pfb_fft_bitgrowth_0_synth_1     \
  #   zynq_tcpipe_crs_smartconnect_0_0_synth_1  \
  #   zynq_tcpipe_crs_system_ila_0_0_synth_1    \
  #   zynq_tcpipe_crs_zynq_ultra_ps_e_0_0_synth_1

  # wait_on_run synth_1
  # wait_on_run [get_runs -filter {NAME ~= "*synth_1"}]

  # wait_on_run impl_1


# set active_runs [get_runs -filter {STATUS=="running"}]
# set active_runs {}
# foreach r [get_runs] {
#     set status [get_property STATUS $r]
#     if {$status eq "running" || $status eq "queued"} {
#         lappend active_runs $r
#     }
# }

# puts "Active runs:"
# foreach r $active_runs { puts "  $r" }

  # wait_on_run $active_runs

# Display timing summary
# Make sure the run exists and is completed
set run [get_runs impl_1]

# Fetch timing results stored in the run metadata
set wns [get_property STATS.WNS $run]
set tns [get_property STATS.TNS $run]
set whs [get_property STATS.WHS $run]
set ths [get_property STATS.THS $run]

puts "=== STORED TIMING SUMMARY ==="
puts [format "WNS (Setup): %7.3f ns" $wns]
puts [format "TNS (Setup): %7.3f ns" $tns]
puts [format "WHS (Hold) : %7.3f ns" $whs]
puts [format "THS (Hold) : %7.3f ns" $ths]

# Display the runtime
set t_end [clock seconds]
set runtime [expr {$t_end - $t_start}]

set hrs [expr {$runtime / 3600}]
set mins [expr {($runtime % 3600) / 60}]
set secs [expr {$runtime % 60}]
puts [format "Script runtime: %02d:%02d:%02d (h:m:s)" $hrs $mins $secs]
