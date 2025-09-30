#!/usr/bin/env -S vivado -mode batch -source

source create_project.tcl

# Upgrade IP so runs aren't frozen and build can proceed
upgrade_ip [get_ips  {gtwizard_ultrascale_0 zynq_tcpipe_crs_zynq_ultra_ps_e_0_0}] -log ip_upgrade.log
generate_target all [get_files zynq_tcpipe_crs.bd]

# Launch runs
launch_runs impl_1 -to_step write_bitstream -jobs 8

# These wait_on_run commands surface stdout/stderr - we really only need the
# impl_1 but would rather see what's happening on the way there.
wait_on_run pfb_fft_bitgrowth_0_synth_1			\
	zynq_tcpipe_crs_smartconnect_0_0_synth_1	\
	zynq_tcpipe_crs_system_ila_0_0_synth_1		\
	zynq_tcpipe_crs_zynq_ultra_ps_e_0_0_synth_1

wait_on_run synth_1
wait_on_run impl_1
