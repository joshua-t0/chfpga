#*****************************************************************************************
# Vivado (TM) v2022.2 (64-bit)
#
# chfpga_crs_corr64.tcl: Tcl script for re-creating project 'chfpga_crs_corr64'
#

#
#*****************************************************************************************

# Set the project name
set _xil_proj_name_ "chfpga_crs_corr64"

# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir "."

set target_part "xczu47dr-ffvg1517-1-i"
# List of files used in this project

# IP core files, found in ../../_Cores/
set ip_files [list \
 "CRS/pfb_fft_bitgrowth_0/pfb_fft_bitgrowth_0.xci" \
 "CRS/AXI4S_REG_SLICE/AXI4S_REG_SLICE.xci" \
 "CRS/GTY/gtwizard_ultrascale_0.xci" \
 "CRS/CMD_FIFO/CMD_FIFO.xci" \
 ]


# HDL files, found in ../../hdl/
 set hdl_files [list  \
 "chfpga_package.vhd" \
 "CROSSBAR/align64_fifo.vhd" \
 "CROSSBAR/ALIGN64.vhd" \
 "chfpga_crs_corr64_config.vhd" \
 "CMD/CMD_SYNC_FIFO.vhd" \
 "CMD/CMD_ROUTER.vhd" \
 "CMD/CMD_SLAVE2.vhd" \
 "CHAN/LFSR.vhd" \
 "CHAN/FUNCGEN.vhd" \
 "CHAN/SYNC.vhd" \
 "CHAN/FFT.vhd" \
 "CHAN/scaler_mul.vhd" \
 "CHAN/SCALER.vhd" \
 "CHAN/chan_fifo.vhd" \
 "CHAN/PROBER.vhd" \
 "CHAN/CHAN.vhd" \
 "CMD/CMD_ASYNC_FIFO.vhd" \
 "CMD/CMD_MASTER.vhd" \
 "SYSTEM/FREQ_CTR.vhd" \
 "CMD/icecore_package.vhd" \
 "CMD/arm_spi.vhd" \
 "CMD/register_array.vhd" \
 "CMD/irigb_decoder.vhd" \
 "CMD/irigb_comparator.vhd" \
 "CMD/irigb_encoder.vhd" \
 "SYSTEM/GPIO.vhd" \
 "SYSTEM/REFCLK.vhd" \
 "SYSTEM/SYSMON_V6.vhd" \
 "CORR/UCMAC44_ARRAY.vhd" \
 "CORR/UCORR44.vhd" \
 "CORR/UCORR44_ARRAY.vhd" \
 "SYSTEM/blinker.vhd" \
 "CHAN/chan_package.vhd" \
 "SYSTEM/clocks.vhd" \
 "XXVGLINK/xxvglink_data_fifo.vhd" \
 "XXVGLINK/xxvglink_bypass.vhd" \
 "XXVGLINK/crc32_64.vhd" \
 "XXVGLINK/xxvglink_tx.vhd" \
 "XXVGLINK/xxvglink_rx.vhd" \
 "XXVGLINK/xxvglink_scrambler.vhd" \
 "XXVGLINK/xxvglink_block_sync.vhd" \
 "XXVGLINK/xxvglink_descrambler.vhd" \
 "XXVGLINK/xxvglink_core.vhd" \
 "XXVGLINK/xxvglink_array.vhd" \
 "CROSSBAR/uct_engine.vhd" \
 "CHAN/ucap.vhd" \
 "chfpga.vhd" \
 "chfpga_crs.vhd" \
 ]

# user IP library folder, in ../../
set ip_libraries [list \
  "ip_library/" \
  ]

# constraints files, in ../../constraints
set const_files [list \
 "crs/crs_physical_constraints_corr64.xdc"\
 "crs/crs_physical_constraints_common.xdc"\
 ]

# Util files, in the project file
set util_files [list \
 "rename_bitstream.tcl"\
 ]

# Expand and normaline file and folder names
set full_ip_files  {}
foreach f $ip_files { lappend full_ip_files [file normalize "$origin_dir/../../_Cores/$f"]}

set full_hdl_files  {}
foreach f $hdl_files {lappend full_hdl_files [file normalize "$origin_dir/../../hdl/$f"]}

set full_ip_libraries  {}
foreach f $ip_libraries {lappend full_ip_libraries [file normalize "$origin_dir/../../$f"]}

set full_const_files  {}
foreach f $const_files {lappend full_const_files [file normalize "$origin_dir/../../constraints/$f"]}

set full_util_files  {}
foreach f $util_files {lappend full_util_files [file normalize "$origin_dir/$f"]}

# Check if all files required for this script exist
# --------------------------------------------------

set missing_file false

# Check files
foreach ifile [concat $full_ip_files $full_hdl_files $full_const_files $full_util_files]  {
  if { ![file isfile $ifile] } {
    puts " Could not find remote file $ifile "
    set missing_file true
  }
}
# check folders
foreach ipath $full_ip_libraries {
  if { ![file isdirectory $ipath] } {
    puts " Could not access $ipath "
    set missing_file true
  }
}

# Bail out if we have a missing file
if { $missing_file } {
  puts "ERROR: Not all files required for project creation are accessible. "
  return
}




# Create project
create_project -force ${_xil_proj_name_} . -part $target_part

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [current_project]
set_property -name "corecontainer.enable" -value "1" -objects $obj
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property -name "enable_core_container" -value "1" -objects $obj
set_property -name "enable_resource_estimation" -value "0" -objects $obj
set_property -name "enable_vhdl_2008" -value "1" -objects $obj
set_property -name "ip_cache_permissions" -value "read write" -objects $obj
set_property -name "ip_output_repo" -value "$proj_dir/${_xil_proj_name_}.cache/ip" -objects $obj
set_property -name "mem.enable_memory_map_generation" -value "1" -objects $obj
set_property -name "part" -value $target_part -objects $obj
# set_property -name "platform.board_id" -value "zcu111" -objects $obj
set_property -name "revised_directory_structure" -value "1" -objects $obj
set_property -name "sim.central_dir" -value "$proj_dir/${_xil_proj_name_}.ip_user_files" -objects $obj
set_property -name "sim.ip.auto_export_scripts" -value "1" -objects $obj
set_property -name "simulator_language" -value "Mixed" -objects $obj
set_property -name "sim_compile_state" -value "1" -objects $obj
set_property -name "target_language" -value "VHDL" -objects $obj
set_property -name "webtalk.activehdl_export_sim" -value "267" -objects $obj
set_property -name "webtalk.ies_export_sim" -value "43" -objects $obj
set_property -name "webtalk.modelsim_export_sim" -value "268" -objects $obj
set_property -name "webtalk.questa_export_sim" -value "268" -objects $obj
set_property -name "webtalk.riviera_export_sim" -value "268" -objects $obj
set_property -name "webtalk.vcs_export_sim" -value "268" -objects $obj
set_property -name "webtalk.xsim_export_sim" -value "268" -objects $obj
set_property -name "webtalk.xsim_launch_sim" -value "5" -objects $obj
set_property -name "xpm_libraries" -value "XPM_CDC XPM_FIFO XPM_MEMORY" -objects $obj

# Create 'sources_1' fileset
# --------------------------------------------
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

set fileset_obj [get_filesets sources_1]

# Set IP repository paths
if { $fileset_obj != {} } {
   set_property "ip_repo_paths" $full_ip_libraries $fileset_obj

   # Rebuild user ip_repo's index before adding any source files
   update_ip_catalog -rebuild
}

add_files -norecurse -fileset $fileset_obj [concat $full_ip_files $full_hdl_files]

# Set 'sources_1' fileset file properties for remote files
foreach file_obj  [get_files -of_objects $fileset_obj [list "*.xci"]] {
  set_property -name "generate_files_for_reference" -value "0" -objects $file_obj
  set_property -name "registered_with_manager" -value "1" -objects $file_obj
}

# Set OOC
# TODO: list OOC modules in a list
foreach file_obj  [get_files -of_objects $fileset_obj "*pfb_fft_bitgrowth_0.xci"] {
  if { ![get_property "is_locked" $file_obj] } {
    set_property -name "synth_checkpoint_mode" -value "Singular" -objects $file_obj
  }
}
# Don't set "generate_synth_checkpoint" -value "0" for non-OOC .xci and see what happens


foreach file_obj  [get_files -of_objects $fileset_obj "*.bd"] {
  set_property -name "registered_with_manager" -value "1" -objects $file_obj
}

foreach file_obj  [get_files -of_objects $fileset_obj "*.vhd"] {
  set_property -name "file_type" -value "VHDL 2008" -objects $file_obj
}


# Set 'sources_1' fileset properties
set_property -name "dataflow_viewer_settings" -value "min_width=16" -objects $fileset_obj
set_property -name "top" -value "chfpga_crs" -objects $fileset_obj
set_property -name "top_auto_set" -value "0" -objects $fileset_obj


# Create constraints fileset
# ----------------------------

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {create_fileset -constrset constrs_1}
set fileset_obj [get_filesets constrs_1]

# Add/Import constrs file and set constrs file properties

add_files -norecurse -fileset $fileset_obj $full_const_files
set_property -name "file_type" -value "XDC" -objects [get_files -of_objects $fileset_obj "*.xdc"]
set_property -name "target_part" -value $target_part -objects $fileset_obj


# Create sim fileset
# ----------------------------

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {create_fileset -simset sim_1}
set obj [get_filesets sim_1]

set_property -name "top" -value "chfpga_crs" -objects $obj
set_property -name "top_auto_set" -value "0" -objects $obj
set_property -name "top_lib" -value "xil_defaultlib" -objects $obj


# Create utils fileset
# ----------------------------

set obj [get_filesets utils_1]
add_files -norecurse -fileset $obj $full_util_files
set_property -name "file_type" -value "TCL" -objects [get_files -of_objects $obj "*.tcl"]
set idrFlowPropertiesConstraints ""
catch {
 set idrFlowPropertiesConstraints [get_param runs.disableIDRFlowPropertyConstraints]
 set_param runs.disableIDRFlowPropertyConstraints 1
}

# Regenerate block design
source "../../hdl/TCPIPE/zynq_tcpipe_crs.tcl"

# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {create_run -name synth_1 -part $target_part -constrset constrs_1}

set obj [get_runs synth_1]
set_property strategy "Flow_PerfOptimized_high" $obj
# set_property flow "Vivado Synthesis 2022" $obj
set_property set_report_strategy_name 1 $obj
set_property report_strategy {Vivado Synthesis Default Reports} $obj
set_property set_report_strategy_name 0 $obj
set_property -name "part" -value $target_part -objects $obj
# set_property -name "auto_incremental_checkpoint" -value "1" -objects $obj
# set_property -name "write_incremental_synth_checkpoint" -value "1" -objects $obj
set_property -name "strategy" -value "Flow_PerfOptimized_high" -objects $obj
set_property -name "steps.synth_design.args.directive" -value "PerformanceOptimized" -objects $obj
set_property -name "steps.synth_design.args.fsm_extraction" -value "one_hot" -objects $obj
set_property -name "steps.synth_design.args.keep_equivalent_registers" -value "1" -objects $obj
set_property -name "steps.synth_design.args.resource_sharing" -value "off" -objects $obj
set_property -name "steps.synth_design.args.no_lc" -value "1" -objects $obj
set_property -name "steps.synth_design.args.shreg_min_size" -value "5" -objects $obj
set_property -name "steps.synth_design.args.assert" -value "1" -objects $obj

# set the current synth run
current_run -synthesis $obj


# Create 'impl_1' run (if not found)
if {[string equal [get_runs -quiet impl_1] ""]} {create_run -name impl_1 -part $target_part -constrset constrs_1 -parent_run synth_1}

set obj [get_runs impl_1]
set_property strategy "Performance_ExplorePostRoutePhysOpt" $obj
# set_property flow "Vivado Implementation 2022" $obj
set_property set_report_strategy_name 1 $obj
set_property report_strategy {Timing Closure Reports} $obj
set_property set_report_strategy_name 0 $obj

set_property -name "part" -value $target_part -objects $obj
# set_property -name "auto_incremental_checkpoint.directory" -value "/home/jfcliche/temp/chfpgalite/xilinx_projects/sifpga_crs/impl_1" -objects $obj
# set_property -name "strategy" -value "Performance_ExplorePostRoutePhysOpt" -objects $obj
set_property -name "steps.opt_design.args.directive" -value "Explore" -objects $obj
set_property -name "steps.place_design.args.directive" -value "Explore" -objects $obj
set_property -name "steps.phys_opt_design.args.directive" -value "Explore" -objects $obj
set_property -name "steps.route_design.args.directive" -value "Explore" -objects $obj
set_property -name "steps.route_design.args.more options" -value "-tns_cleanup" -objects $obj
set_property -name "steps.post_route_phys_opt_design.is_enabled" -value "1" -objects $obj
set_property -name "steps.post_route_phys_opt_design.args.directive" -value "Explore" -objects $obj
set_property -name "steps.write_bitstream.tcl.post" -value "$proj_dir/rename_bitstream.tcl" -objects $obj
set_property -name "steps.write_bitstream.args.readback_file" -value "0" -objects $obj
set_property -name "steps.write_bitstream.args.verbose" -value "0" -objects $obj

# set the current impl run
current_run -implementation $obj
catch {
 if { $idrFlowPropertiesConstraints != {} } {
   set_param runs.disableIDRFlowPropertyConstraints $idrFlowPropertiesConstraints
 }
}

# Create FFT OOC run and set its synth directive
set file_obj  [get_files -filter {NAME =~ "*pfb_fft_bitgrowth_0.xci"}]
generate_target all $file_obj
catch { config_ip_cache -export [get_ips -all pfb_fft_bitgrowth_0] }
export_ip_user_files -of_objects $file_obj -no_script -sync -force -quiet
create_ip_run $file_obj -force
set ip_run [get_runs *fft_bitgrowth*synth*]
set_property strategy "Flow_PerfOptimized_high" -objects $ip_run


puts "INFO: Project created:${_xil_proj_name_}"

