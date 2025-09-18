#!/usr/bin/env -S vivado -mode batch -source

source create_project.tcl

# Launch runs
launch_runs impl_1 -to_step write_bitstream -jobs 8

# These wait_on_run commands surface stdout/stderr - we really only need the
# impl_1 but would rather see what's happening on the way there.
wait_on_run pfb_fft_bitgrowth_0_synth_1
wait_on_run synth_1
wait_on_run impl_1
