#!/usr/bin/env -S vivado -mode batch -notrace -source
#*****************************************************************************************
# Vivado (TM) v2022.2 (64-bit)
#
# chfpga_crs_corr32.tcl: Tcl script for re-creating project 'chfpga_crs_corr32'
#
# To create the project and automatically build it:
#
#  vivado -mode batch -source create_project.tcl -tclargs build
#
#*****************************************************************************************





# Set the project directory for source file relative paths (by default the value is script directory path)
set proj_dir [file normalize [file dirname [info script]]]

# cd to the script folder
cd $proj_dir

# Set the project name based on the folder name
set proj_name [file tail [pwd]]

# Set the repo directory to access files outside of the project dir
# We assume we are two levels down from the repo root, e.g. repo_dir/xilinx_projects/my_project_name/.
set repo_dir [file normalize "../../"]

puts ""
puts "------------------------------------------------------------------------------------------------------------"
puts "Creating project ${proj_name} in folder ${proj_dir}"
puts "------------------------------------------------------------------------------------------------------------"
puts ""

set target_part "xczu47dr-ffvg1517-1-i"
# List of files used in this project


# Regenerate block design
set bd_name "zynq_tcpipe_crs"
set bd_dir "${repo_dir}/hdl/TCPIPE"
if { ![file exists "${bd_dir}/${bd_name}/${bd_name}.bd"]} {
  puts ""
  puts "    -----------------------------------------------"
  puts "    Creating block diagram ${bd_name}.bd in folder ${bd_dir}/${bd_name}"
  puts "    -----------------------------------------------"
  puts ""

  # The tcl script that builds the block diagram will put it in the folder specified in the global
  # variable ::origin_dir_loc. Since a project is not currently open, it will create a project
  # 'myproj' in the current directory and will fail if that project already exists, so we have to
  # delete it beforehand.
  set ::origin_dir_loc ${bd_dir}
  file delete -force "$bd_dir/myproj"
  cd $bd_dir
  source "${bd_dir}/${bd_name}.tcl"
  file delete -force "$bd_dir/myproj"
  cd $proj_dir
}

puts ""
puts "    -----------------------------------------------"
puts "    Gathering project files"
puts "    -----------------------------------------------"
puts ""

# # BD files, path relative to the bd_dir
set bd_files [list \
  "${bd_name}/${bd_name}.bd" \
  ]

# IP core files, found in $repo_dir/_Cores/
set ip_dir "${repo_dir}/_Cores/"
set ip_files [list \
 "CRS/pfb_fft_bitgrowth_0/pfb_fft_bitgrowth_0.xci" \
 "CRS/GTY/gtwizard_ultrascale_0.xci" \
 ]



# HDL files, found in $repo_dir/hdl/
set hdl_dir "${repo_dir}/hdl/"

 set hdl_files [list  \
 "chfpga_package.vhd" \
 "chfpga_crs_corr32_config.vhd" \
 "chfpga.vhd" \
 "chfpga_crs.vhd" \
 "CMD/axis_sync_fifo.vhd" \
 "CMD/CMD_SYNC_FIFO.vhd" \
 "CMD/CMD_ROUTER.vhd" \
 "CMD/CMD_SLAVE2.vhd" \
 "CMD/CMD_ASYNC_FIFO.vhd" \
 "CMD/CMD_MASTER.vhd" \
 "CMD/icecore_package.vhd" \
 "CMD/arm_spi.vhd" \
 "CMD/register_array.vhd" \
 "CMD/irigb_decoder.vhd" \
 "CMD/irigb_comparator.vhd" \
 "CMD/irigb_encoder.vhd" \
 "SYSTEM/system.vhd" \
 "SYSTEM/GPIO.vhd" \
 "SYSTEM/FREQ_CTR.vhd" \
 "SYSTEM/REFCLK.vhd" \
 "SYSTEM/SYSMON_V6.vhd" \
 "SYSTEM/blinker.vhd" \
 "SYSTEM/clocks.vhd" \
 "CHAN/chan_package.vhd" \
 "CHAN/CHAN.vhd" \
 "CHAN/LFSR.vhd" \
 "CHAN/FUNCGEN.vhd" \
 "CHAN/SYNC.vhd" \
 "CHAN/FFT.vhd" \
 "CHAN/scaler_mul.vhd" \
 "CHAN/SCALER.vhd" \
 "CHAN/chan_fifo.vhd" \
 "CHAN/PROBER.vhd" \
 "CHAN/ucap.vhd" \
 "CROSSBAR/uct_engine.vhd" \
 "CROSSBAR/align64_fifo.vhd" \
 "CROSSBAR/ALIGN64.vhd" \
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
 "CORR/UCMAC44_ARRAY.vhd" \
 "CORR/UCORR44.vhd" \
 "CORR/UCORR44_ARRAY.vhd" \
 ]

# user IP library folder, in $repo_dir/
set ip_libraries [list \
  "ip_library/" \
  ]

# constraints files, in $repo_dir/constraints
set const_dir "${repo_dir}/constraints/"
set const_files [list \
 "crs/crs_physical_constraints_corr64.xdc"\
 "crs/crs_physical_constraints_common.xdc"\
 ]

# Util files, in the project folder
set util_files [list \
 "rename_bitstream.tcl"\
 ]

# Expand and normaline file and folder names
set full_ip_files  {}
foreach f $ip_files { lappend full_ip_files [file normalize "$ip_dir/$f"]}

set full_bd_files  {}
foreach f $bd_files { lappend full_bd_files [file normalize "$bd_dir/$f"]}

set full_hdl_files  {}
foreach f $hdl_files {lappend full_hdl_files [file normalize "$hdl_dir/$f"]}

set full_ip_libraries  {}
foreach f $ip_libraries {lappend full_ip_libraries [file normalize "$repo_dir/$f"]}

set full_const_files  {}
foreach f $const_files {lappend full_const_files [file normalize "$const_dir/$f"]}

set full_util_files  {}
foreach f $util_files {lappend full_util_files [file normalize "$proj_dir/$f"]}

# Check if all files required for this script exist
# --------------------------------------------------

puts ""
puts "    -----------------------------------------------"
puts "    Checking project files"
puts "    -----------------------------------------------"
puts ""

set missing_file false

# Check files
foreach ifile [concat $full_bd_files $full_ip_files $full_hdl_files $full_const_files $full_util_files]  {
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



puts ""
puts "    -----------------------------------------------"
puts "    Create project"
puts "    -----------------------------------------------"
puts ""


# Create project
create_project -force ${proj_name} . -part $target_part

# Set the directory path for the new project
# set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [current_project]
set_property -name "corecontainer.enable" -value "1" -objects $obj
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property -name "enable_core_container" -value "1" -objects $obj
set_property -name "enable_resource_estimation" -value "0" -objects $obj
set_property -name "enable_vhdl_2008" -value "1" -objects $obj
set_property -name "ip_cache_permissions" -value "read write" -objects $obj
set_property -name "ip_output_repo" -value "$proj_dir/${proj_name}.cache/ip" -objects $obj
set_property -name "mem.enable_memory_map_generation" -value "1" -objects $obj
set_property -name "part" -value $target_part -objects $obj
# set_property -name "platform.board_id" -value "zcu111" -objects $obj
set_property -name "revised_directory_structure" -value "1" -objects $obj
set_property -name "sim.central_dir" -value "$proj_dir/${proj_name}.ip_user_files" -objects $obj
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

add_files -norecurse -fileset $fileset_obj [concat $full_ip_files $full_bd_files $full_hdl_files ]

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

# Set the HDL file types to VHDL2008. Here we explicitely select only the specified source files. We don't want to change the type of vhd files included in IPs.
foreach file_obj  [get_files $full_hdl_files] {
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


puts ""
puts "    -----------------------------------------------"
puts "    Setting-up runs"
puts "    -----------------------------------------------"
puts ""

# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {create_run -name synth_1 -part $target_part -constrset constrs_1}

set synth_obj [get_runs synth_1]
set_property strategy "Flow_PerfOptimized_high" $synth_obj
# set_property flow "Vivado Synthesis 2022" $synth_obj
set_property set_report_strategy_name 1 $synth_obj
set_property report_strategy {Vivado Synthesis Default Reports} $synth_obj
set_property set_report_strategy_name 0 $synth_obj
set_property -name "part" -value $target_part -obj $synth_obj
# set_property -name "auto_incremental_checkpoint" -value "1" -synth_objects $synth_obj
# set_property -name "write_incremental_synth_checkpoint" -value "1" -synth_objects $synth_obj
# set_property -name "strategy" -value "Flow_PerfOptimized_high" -synth_objects $synth_obj

# The properties below shoudl not be necessary: we should use the directive defaults.
set_property -name "steps.synth_design.args.directive" -value "PerformanceOptimized" -obj $synth_obj
set_property -name "steps.synth_design.args.fsm_extraction" -value "one_hot" -obj $synth_obj
set_property -name "steps.synth_design.args.keep_equivalent_registers" -value "1" -obj $synth_obj
set_property -name "steps.synth_design.args.resource_sharing" -value "off" -obj $synth_obj
set_property -name "steps.synth_design.args.no_lc" -value "1" -obj $synth_obj
set_property -name "steps.synth_design.args.shreg_min_size" -value "5" -obj $synth_obj
set_property -name "steps.synth_design.args.assert" -value "1" -obj $synth_obj

# set the current synth run
current_run -synthesis $synth_obj


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

puts ""
puts "    -----------------------------------------------"
puts "    Generate FFT OOC"
puts "    -----------------------------------------------"
puts ""

# Create FFT OOC run and set its synth directive
set file_obj  [get_files -filter {NAME =~ "*pfb_fft_bitgrowth_0.xci"}]
generate_target all $file_obj
catch { config_ip_cache -export [get_ips -all pfb_fft_bitgrowth_0] }
export_ip_user_files -of_objects $file_obj -no_script -sync -force -quiet
create_ip_run $file_obj -force
set ip_run [get_runs *fft_bitgrowth*synth*]
set_property strategy "Flow_PerfOptimized_high" -objects $ip_run

puts ""
puts "    -----------------------------------------------"
puts "    Project creation successful"
puts "    -----------------------------------------------"
puts ""

puts "INFO: Project created:${proj_name}"


