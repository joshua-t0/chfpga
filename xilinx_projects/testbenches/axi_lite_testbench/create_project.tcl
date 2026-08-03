#!/usr/bin/env -S vivado -mode batch -source
# Create Vivado project for axi_lite testbench (simulation + out-of-context synthesis).
# Usage: vivado -mode batch -source create_project.tcl
# Or from Vivado: source create_project.tcl
#
# Synthesis: top = axi_lite, option -mode out_of_context so you can run Implement.
# Simulation: top = axi_lite_testbench.

cd [file dirname [info script]]
set proj_name   axi_lite_testbench
set project_dir [pwd]
set hdl [file normalize [file join [file dirname [info script]] ../../../hdl]]

create_project -force -part xc7k420tffg901-2 $proj_name $project_dir

set_property default_lib work [current_project]
set_property target_language VHDL [current_project]

# DUT + testbench
add_files -fileset sources_1 \
    [file join $hdl utils axi_lite.vhd] \
    [file join $hdl testbenches axi_lite_testbench.vhd]

set_property file_type {VHDL 2008} [get_files *.vhd]

# Testbench sources: simulation only, not synthesis
set_property used_in_synthesis false [get_files [file join $hdl testbenches axi_lite_testbench.vhd]]

# Simulation top
set_property top axi_lite_testbench [get_filesets sim_1]
set_property top_lib work [get_filesets sim_1]

# Synthesis: design top = DUT; out-of-context so Implement can run
set_property top axi_lite [get_filesets sources_1]
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]

puts "Project created: [file join $project_dir ${proj_name}.xpr]"
puts "Simulation top: axi_lite_testbench"
puts "Synthesis top: axi_lite (-mode out_of_context)"
puts "To run simulation: Launch Simulation"
puts "To implement: Run Synthesis then Run Implementation"
