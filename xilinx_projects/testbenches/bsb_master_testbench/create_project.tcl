#!/usr/bin/env -S vivado -mode batch -source
# Create Vivado project for bsb_master testbench (simulation + out-of-context synthesis).
# Usage: vivado -mode batch -source create_project.tcl
# Or from Vivado: source create_project.tcl
#
# Synthesis: top = bsb_master, option -mode out_of_context so you can run Implement.
# Simulation: top = bsb_master_testbench.

cd [file dirname [info script]]
set project_dir [file join [pwd] bsb_master_tb]
set hdl [file normalize [file join [file dirname [info script]] ../../../hdl]]

if { [string first "batch" [info nameofexecutable]] >= 0 } {
    create_project -force -part xc7k420tffg901-2 bsb_master_tb $project_dir
} else {
    create_project -force -part xc7k420tffg901-2 bsb_master_tb $project_dir
}

set_property default_lib work [current_project]
set_property target_language VHDL [current_project]

# Sources: package, DUT, tb_package, testbench
add_files -fileset sources_1 \
    [file join $hdl chfpga_package.vhd] \
    [file join $hdl bsb bsb_master.vhd] \
    [file join $hdl testbenches tb_package.vhd] \
    [file join $hdl testbenches bsb_master_testbench.vhd]

set_property file_type {VHDL 2008} [get_files *.vhd]

# Testbench sources: simulation only, not synthesis
set_property used_in_synthesis false [get_files [file join $hdl testbenches tb_package.vhd]]
set_property used_in_synthesis false [get_files [file join $hdl testbenches bsb_master_testbench.vhd]]

# Simulation top
set_property top bsb_master_testbench [get_filesets sim_1]
set_property top_lib work [get_filesets sim_1]

# Synthesis: design top = DUT; out-of-context so Implement can run
set_property top bsb_master [get_filesets sources_1]
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]

puts "Project created: $project_dir"
puts "Simulation top: bsb_master_testbench"
puts "Synthesis top: bsb_master (-mode out_of_context)"
puts "To run simulation: Launch Simulation (or launch_simulation)"
puts "To implement: Run Synthesis then Run Implementation"
