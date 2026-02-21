#!/usr/bin/env -S vivado -mode batch -source
# Create Vivado project for axis_merge2 testbench (simulation + out-of-context synthesis).
# Usage: vivado -mode batch -source create_project.tcl
# Or from Vivado: source create_project.tcl
#
# Synthesis: top = axis_merge2, option -mode out_of_context so you can run Implement.
# Simulation: top = axis_merge2_testbench.

cd [file dirname [info script]]
set project_dir [file join [pwd] axis_merge2_tb]
set hdl [file normalize [file join [file dirname [info script]] ../../../hdl]]

if { [string first "batch" [info nameofexecutable]] >= 0 } {
    create_project -force -part xc7k420tffg901-2 axis_merge2_tb $project_dir
} else {
    create_project -force -part xc7k420tffg901-2 axis_merge2_tb $project_dir
}

set_property default_lib work [current_project]
set_property target_language VHDL [current_project]

# Sources: package, axis_sync_fifo (used by axis_merge2 when USE_FIFO=true), DUT, tb_package, testbench
add_files -fileset sources_1 \
    [file join $hdl chfpga_package.vhd] \
    [file join $hdl bsb axis_sync_fifo.vhd] \
    [file join $hdl common axis_merge2.vhd] \
    [file join $hdl testbenches tb_package.vhd] \
    [file join $hdl testbenches axis_merge2_testbench.vhd]

set_property file_type {VHDL 2008} [get_files *.vhd]

# Testbench sources: simulation only, not synthesis
set_property used_in_synthesis false [get_files [file join $hdl testbenches tb_package.vhd]]
set_property used_in_synthesis false [get_files [file join $hdl testbenches axis_merge2_testbench.vhd]]

# Simulation top
set_property top axis_merge2_testbench [get_filesets sim_1]
set_property top_lib work [get_filesets sim_1]

# Synthesis: design top = DUT; out-of-context so Implement can run
set_property top axis_merge2 [get_filesets sources_1]
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]
set_property INCREMENTAL_SYNTHESIS false [get_runs synth_1]

puts "Project created: $project_dir"
puts "Simulation top: axis_merge2_testbench"
puts "Synthesis top: axis_merge2 (-mode out_of_context)"
puts "To run simulation: Launch Simulation (or launch_simulation)"
puts "To implement: Run Synthesis then Run Implementation"
