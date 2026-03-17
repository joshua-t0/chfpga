#*****************************************************************************************
# Vivado (TM) v2022.2 (64-bit)
#
# create_generic_project.tcl: Tcl script for re-creating a project
#
# The script should be launched from the project folder  from a script that defines the following key parameters:
#   target_part
#   bd_name
#   config_file
#   top_wrapper_file
#   ip_files
#   hdl_files
#   const_files
#
# Usage examples:
#   # Normal project creation from a project directory
#   #   vivado -mode batch -notrace -source create_project.tcl
#   #
#   # List-only mode for Makefile dependency generation:
#   #   vivado -mode batch -notrace -source create_project.tcl -tclargs --list_files_only
#   #
#   # In list-only mode, this script:
#   #   - Verifies that all referenced files and IP library folders exist.
#   #   - Prints one repository-relative file path per line (HDL, XDC, BD, IP, util files).
#   #   - Exits before creating a Vivado project or runs.
#
#*****************************************************************************************


# We assume the project directory is the cwd
set proj_dir [pwd]

# Set the project name based on the folder name
set proj_name [file tail $proj_dir]

# Check for list-files-only flag in argv (if present)
set list_files_only 0
if {[info exists argv]} {
  foreach arg $argv {
    if { $arg eq "--list_files_only" || $arg eq "-list_files_only" } {
      set list_files_only 1
    }
  }
}

if {!$list_files_only} {
  puts ""
  puts "------------------------------------------------------------------------------------------------------------"
  puts "Creating project ${proj_name} in folder ${proj_dir}"
  puts "------------------------------------------------------------------------------------------------------------"
  puts ""

  puts ""
  puts "    -----------------------------------------------"
  puts "    Gathering project files"
  puts "    -----------------------------------------------"
  puts ""
}


# # BD files, path relative to the bd_dir
set bd_files {}
if { ${bd_name} ne ""} {lappend bd_files "${bd_name}/${bd_name}.bd"}


# user IP library folder, in $repo_dir/
set ip_libraries [list "ip_library/" ]

# Util files, from the repo root
set util_files [list \
 "tcl/rename_bitstream.tcl"\
 ]

# set util_files {}




# Expand and normaline file and folder names
set full_ip_files  {}
foreach f $ip_files { lappend full_ip_files [file normalize "$ip_dir/$f"]}

set full_ooc_ip_files  {}
foreach f $ooc_ip_files { lappend full_ooc_ip_files [file normalize "$ip_dir/$f"]}

set full_bd_files  {}
foreach f $bd_files { lappend full_bd_files [file normalize "$bd_dir/$f"]}

set full_hdl_files  {}
# lappend full_hdl_files [file normalize "$hdl_dir/$config_file"]
# lappend full_hdl_files [file normalize "$hdl_dir/$top_wrapper_file"]
foreach f $hdl_files {lappend full_hdl_files [file normalize "$hdl_dir/$f"]}

set full_ip_libraries  {}
foreach f $ip_libraries {lappend full_ip_libraries [file normalize "$repo_dir/$f"]}

set full_const_files  {}
foreach f $const_files {lappend full_const_files [file normalize "$const_dir/$f"]}

set full_util_files  {}
foreach f $util_files {lappend full_util_files [file normalize "$repo_dir/$f"]}


# Regenerate block design to make sure the .bd file is there
if { ${bd_name} ne ""} {
  if { ![file exists "${bd_dir}/${bd_name}/${bd_name}.bd"]} {
    if {!$list_files_only} {
      puts ""
      puts "    -----------------------------------------------"
      puts "    Creating block diagram ${bd_name}.bd in folder ${bd_dir}/${bd_name}"
      puts "    -----------------------------------------------"
      puts ""
    }

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
}

# Check if all files required for this script exist
# --------------------------------------------------

if {!$list_files_only} {
  puts ""
  puts "    -----------------------------------------------"
  puts "    Checking project files"
  puts "    -----------------------------------------------"
  puts ""
}

set missing_file false

# Check files
foreach ifile [concat $full_bd_files $full_ip_files $full_ooc_ip_files $full_hdl_files $full_const_files $full_util_files]  {
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
  # In list-files-only mode, ensure the calling process sees a failure.
  if {$list_files_only} {
    exit 1
  }
  return
}

if {$list_files_only} {
  # Emit a de-duplicated list of all relevant project input files,
  # with paths relative to the repository root when possible.
  set all_files [concat $full_bd_files $full_ip_files $full_ooc_ip_files $full_hdl_files $full_const_files $full_util_files]

  # De-duplicate while preserving order
  array unset seen
  set unique_files {}
  foreach f $all_files {
    if {![info exists seen($f)]} {
      set seen($f) 1
      lappend unique_files $f
    }
  }

  foreach f $unique_files {
    set norm [file normalize $f]
    # Strip the repo_dir prefix when present to get repo-relative paths
    set rel $norm
    if {[info exists repo_dir]} {
      set repo_norm [file normalize $repo_dir]
      set prefix "${repo_norm}/"
      if {[string first $prefix $norm] == 0} {
        set rel [string range $norm [string length $prefix] end]
      }
    }
    puts "FILE:$rel"
  }

  return
}


puts ""
puts "    -----------------------------------------------"
puts "    Create project"
puts "    -----------------------------------------------"
puts ""


# Create project
create_project -force ${proj_name} . -part $target_part

set irp [concat [get_property ip_repo_paths [current_project]] [list $ip_dir] "${ip_dir}KC705/hirax_bit_growth_0"]

puts "*** IP repo paths = $irp"
set_property ip_repo_paths $ip_dir [current_project]
update_ip_catalog

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


add_files -norecurse -fileset $fileset_obj [concat $full_bd_files $full_hdl_files]

# Import IP definitions into the project so regenerated products live under the
# current project instead of following metadata from another project's .gen dir.
if {[llength [concat $full_ip_files $full_ooc_ip_files]] > 0} {
  import_files -force -norecurse -fileset $fileset_obj [concat $full_ip_files $full_ooc_ip_files]
}

# Set 'sources_1' fileset file properties for remote files
foreach file_obj  [get_files -of_objects $fileset_obj [list "*.xci"]] {
  set_property -name "generate_files_for_reference" -value "0" -objects $file_obj
  set_property -name "registered_with_manager" -value "1" -objects $file_obj
}

# Set OOC
# TODO: list OOC modules in a list
# foreach file_obj  [get_files -of_objects $fileset_obj "*fft*.xci"] {
# foreach file_obj  [get_ips "*fft*"] {
#   if { ![get_property "is_locked" $file_obj] } {
#     # set ip_state [get_property IP_STATE $file_obj]
#     puts "$file_obj is not locked.  Setting synth_checkpoint_mode"
#     set_property -name "synth_checkpoint_mode" -value "Singular" -objects $file_obj
#   }
# }
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
set_property -name "top_auto_set" -value "1" -objects $fileset_obj


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

set_property -name "top_auto_set" -value "1" -objects $obj
set_property -name "top_lib" -value "xil_defaultlib" -objects $obj


# Create utils fileset
# ----------------------------

set obj [get_filesets utils_1]
add_files -norecurse -fileset $obj $full_util_files
set_property -name "file_type" -value "TCL" -objects [get_files -of_objects $obj "*.tcl"]
# set idrFlowPropertiesConstraints ""
# catch {
#  set idrFlowPropertiesConstraints [get_param runs.disableIDRFlowPropertyConstraints]
#  set_param runs.disableIDRFlowPropertyConstraints 1
# }


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
set_property -name "steps.synth_design.args.no_lc" -value $no_lc -obj $synth_obj
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
set_property -name "steps.write_bitstream.tcl.post" -value "$repo_dir/tcl/rename_bitstream.tcl" -objects $obj
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
puts "    Generate OOC modules"
puts "    -----------------------------------------------"
puts ""

set ip_list {}
set ips [get_ips]
# puts "ips=  $ips"

foreach ip_obj  [get_ips] {
  # Note: Vivado 2023+ uses FILE_NAME
  set ip_name [get_property NAME $ip_obj]
  # puts "Checking if $ip_name is in $ooc_ip_files"
  if {[lsearch $ooc_ip_files "*/$ip_name.*"] >=0} {
      puts "Adding $ip_name, specifically adding $ip_obj to IP list"
    lappend ip_list $ip_obj
  }
}
# Create FFT OOC run and set its synth directive
# set file_obj  [get_files -filter {NAME =~ "*fft*.xci"}]
# set file_obj  [get_ips "*fft*"]
# set file_obj  [get_ips $full_ooc_ip_files]
puts "OOC ip files are $ip_list"

# export_ip_user_files -of_objects  [get_files  /home/jfcliche/chfpga/_Cores/KC705/hirax_bit_growth_0/hirax_bit_growth_0.xci] -sync -lib_map_path [list {modelsim=/home/jfcliche/chfpga/xilinx_projects/chfpga_ice_ct/chfpga_ice_ct.cache/compile_simlib/modelsim} {questa=/home/jfcliche/chfpga/xilinx_projects/chfpga_ice_ct/chfpga_ice_ct.cache/compile_simlib/questa} {xcelium=/home/jfcliche/chfpga/xilinx_projects/chfpga_ice_ct/chfpga_ice_ct.cache/compile_simlib/xcelium} {vcs=/home/jfcliche/chfpga/xilinx_projects/chfpga_ice_ct/chfpga_ice_ct.cache/compile_simlib/vcs} {riviera=/home/jfcliche/chfpga/xilinx_projects/chfpga_ice_ct/chfpga_ice_ct.cache/compile_simlib/riviera}] -force -quiet
# set_property generate_synth_checkpoint true [get_files  /home/jfcliche/chfpga/_Cores/KC705/hirax_bit_growth_0/hirax_bit_growth_0.xci]
# generate_target all [get_files  /home/jfcliche/chfpga/_Cores/KC705/hirax_bit_growth_0/hirax_bit_growth_0.xci]

if {[llength $ip_list] > 0} {
  # Re-target imported OOC IPs to the current part before configuring their runs.
  upgrade_ip $ip_list -quiet
  export_ip_user_files -of_objects $ip_list -no_script -sync -force -quiet
  reset_target all $ip_list
  foreach ip $ip_list {
    set ip_name [get_property NAME $ip]
    set ip_xci [get_files -quiet -of_objects $ip [list "*.xci"]]
    if {$ip_xci ne ""} {
      if {[catch {set_property generate_synth_checkpoint true $ip_xci} err]} {
        puts "Skipping generate_synth_checkpoint for ${ip_name}: $err"
      }
    }
  }
  generate_target all $ip_list
  catch { config_ip_cache -export $ip_list }
  foreach ip $ip_list {
    # removed the -force option to avoid regeneration
    set ip_run_name [create_ip_run -force $ip]
    if {$ip_run_name ne ""} {
      set ip_run [get_runs $ip_run_name]
      puts "Configuring IP run properties for $ip_run_name"
      set_property strategy "Flow_PerfOptimized_high" -objects $ip_run
      set_property -name "steps.synth_design.args.no_lc" -value $no_lc -obj $ip_run
      } else {
        puts "IP $ip is already cached"
      }
  }
}

# }



puts ""
puts "    -----------------------------------------------"
puts "    Project creation successful"
puts "    -----------------------------------------------"
puts ""

puts "INFO: Project created:${proj_name}"


