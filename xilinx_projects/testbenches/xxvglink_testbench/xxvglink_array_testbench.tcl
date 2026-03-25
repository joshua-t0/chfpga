#!/usr/bin/env -S vivado -mode batch -source

cd [file dirname [info script]]
puts "Project will be created in folder [pwd]"

create_project -force -part xczu47dr-ffvg1517-1-i xxvglink_array_testbench xxvglink_array_testbench

set hdl "../../../hdl"
set core "../../../hdl/platforms/crs/ip_cores"
add_files -fileset sources_1		\
	"$hdl/testbenches/xxvglink_array_testbench.vhd"	\
	"$hdl/testbenches/tb_package.vhd"		\
	[ glob $hdl/XXVGLINK/*.vhd ]	\
	"$hdl/bsb/bsb_regs.vhd"		\
	"$hdl/bsb/bsb_router.vhd"		\
	"$hdl/bsb/bsb_sync_fifo.vhd"	\
	"$hdl/bsb/axis_sync_fifo.vhd"	\
	"$hdl/chfpga_package.vhd"	\
	"$core/GTY/gtwizard_ultrascale_0.xci"

set_property file_type {VHDL 2008} [get_files *.vhd]

set_property -dict [ list			\
	top xxvglink_array_testbench		\
	xsim.simulate.log_all_signals true	\
	xsim.simulate.wdb xxvglink_array_testbench.wdb	\
] -objects [get_fileset sim_1]

launch_simulation

run
exit
