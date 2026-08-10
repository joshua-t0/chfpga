#!/usr/bin/env -S vivado -mode batch -source
# Create Vivado project for ct_prober testbench (simulation only).
# Usage: vivado -mode batch -source create_project.tcl
# Or from Vivado: source create_project.tcl
#
# Simulation: top = ct_prober_testbench.
#
# Note: no out-of-context synthesis run is configured (unlike the bsb_master testbench
# template) because ct_prober's mandatory FPGA_SERIES enum generic cannot be supplied through
# the project 'generic' property (Vivado does not accept VHDL enum literals there).
# Synthesizability is covered by the chfpga_ice_ct project, which binds the generic in VHDL.

cd [file dirname [info script]]
set project_dir [file join [pwd] ct_prober_tb]
set hdl [file normalize [file join [file dirname [info script]] ../../../hdl]]

create_project -force -part xc7k420tffg901-2 ct_prober_tb $project_dir

set_property default_lib work [current_project]
set_property target_language VHDL [current_project]

# Sources: package, DUT + its dependencies, tb_package, testbench
add_files -fileset sources_1 \
    [file join $hdl chfpga_package.vhd] \
    [file join $hdl utils generic_fifo.vhd] \
    [file join $hdl bsb bsb_regs.vhd] \
    [file join $hdl ct ct_prober.vhd] \
    [file join $hdl testbenches tb_package.vhd] \
    [file join $hdl testbenches ct_prober_testbench.vhd]

set_property file_type {VHDL 2008} [get_files *.vhd]

# Testbench sources: simulation only, not synthesis
set_property used_in_synthesis false [get_files [file join $hdl testbenches tb_package.vhd]]
set_property used_in_synthesis false [get_files [file join $hdl testbenches ct_prober_testbench.vhd]]

# Simulation top
set_property top ct_prober_testbench [get_filesets sim_1]
set_property top_lib work [get_filesets sim_1]

puts "Project created: $project_dir"
puts "Simulation top: ct_prober_testbench"
puts "To run simulation: Launch Simulation (or launch_simulation)"
