#!/usr/bin/env -S vivado -mode batch -source

create_project -force -part xczu47dr-ffvg1517-1-i xxvglink_array_testbench xxvglink_array_testbench

add_files -fileset sources_1		\
	"xxvglink_array_testbench.vhd"	\
	"tb_package.vhd"		\
	[ glob ../XXVGLINK/*.vhd ]	\
	"../CMD/CMD_SLAVE2.vhd"		\
	"../CMD/CMD_ROUTER.vhd"		\
	"../CMD/CMD_SYNC_FIFO.vhd"	\
	"../../hdl/chfpga_package.vhd"	\
	"../../_Cores/CRS/GTY/gtwizard_ultrascale_0.xci"	\
	"../../_Cores/CRS/AXI4S_REG_SLICE/AXI4S_REG_SLICE.xci"

set_property file_type {VHDL 2008} [get_files *.vhd]

set_property -dict [ list			\
	top xxvglink_array_testbench		\
	xsim.simulate.log_all_signals true	\
	xsim.simulate.wdb xxvglink_array_testbench.wdb	\
] -objects [get_fileset sim_1]

launch_simulation

run
exit
