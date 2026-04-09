#!/usr/bin/env -S vivado -mode batch -source
# Create Vivado project for blinker testbench (simulation + out-of-context synthesis).
# Usage: vivado -mode batch -source create_project.tcl
# Or from Vivado: source create_project.tcl
#
# Synthesis: top = blinker, option -mode out_of_context so you can run Implement.
# Simulation: top = blinker_testbench.

cd [file dirname [info script]]
set project_dir [file join [pwd] blinker_tb]
set hdl [file normalize [file join [file dirname [info script]] ../../../hdl]]

if { [string first "batch" [info nameofexecutable]] >= 0 } {
    create_project -force -part xc7k420tffg901-2 blinker_tb $project_dir
} else {
    create_project -force -part xc7k420tffg901-2 blinker_tb $project_dir
}

set_property default_lib work [current_project]
set_property target_language VHDL [current_project]

add_files -fileset sources_1 \
    [file join $hdl system blinker.vhd] \
    [file join $hdl testbenches blinker_testbench.vhd]

set_property file_type {VHDL 2008} [get_files *.vhd]

set_property used_in_synthesis false [get_files [file join $hdl testbenches blinker_testbench.vhd]]

set_property top blinker_testbench [get_filesets sim_1]
set_property top_lib work [get_filesets sim_1]

set_property top blinker [get_filesets sources_1]
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]
set_property INCREMENTAL_SYNTHESIS false [get_runs synth_1]

puts "Project created: $project_dir"
puts "Simulation top: blinker_testbench"
puts "Synthesis top: blinker (-mode out_of_context)"
puts "To run simulation: Launch Simulation (or launch_simulation)"
puts "To implement: Run Synthesis then Run Implementation"
