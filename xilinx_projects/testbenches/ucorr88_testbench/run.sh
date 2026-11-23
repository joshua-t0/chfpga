#!/bin/bash
# Compiles and runs the testbench of the correlator with (8+8)-bit inputs (UCORR44_ARRAY, N_BITS_PER_BIN = 16) with the Vivado simulator.
# Needs the Vivado environment (source setenv.sh from the repository root).
#
# Usage: ./run.sh [GENERIC=value ...]     e.g. ./run.sh     ./run.sh SAMPLE_BITS=8 INTEG=1300 (the same test on the (4+4)-bit correlator)
# Prints "UCORR88 TEST PASSED" on success. A run takes a few minutes.
# Environment: WORK=<directory> for the work files (default ./work, not versioned), so that runs can be made in parallel.
set -e
here=$(cd "$(dirname "$0")" && pwd)
hdl=$here/../../../hdl
work=${WORK:-$here/work}
mkdir -p "$work" && cd "$work"
generics=()
for g in "$@"; do generics+=(-generic_top "$g"); done
rm -rf xsim.dir/ucorr88_tb  # never run an old snapshot when the compilation fails
xvlog -nolog "$XILINX_VIVADO/data/verilog/src/glbl.v" > /dev/null
xvhdl -2008 -nolog "$hdl/chfpga_package.vhd" "$hdl/bsb/bsb_regs.vhd" "$hdl/utils/generic_fifo.vhd" "$hdl/corr/UCMAC44_ARRAY.vhd" "$hdl/corr/UCMAC88_ARRAY.vhd" "$hdl/corr/UCORR44.vhd" "$hdl/corr/UCORR44_ARRAY.vhd" "$hdl/testbenches/ucorr88_testbench.vhd" > compile.log 2>&1 \
	|| { grep ERROR compile.log; echo "Failure: compilation error"; exit 1; }
xelab -nolog -L xpm -L unisim work.ucorr88_testbench work.glbl -s ucorr88_tb "${generics[@]}" > elaborate.log 2>&1 \
	|| { grep ERROR elaborate.log; echo "Failure: elaboration error"; exit 1; }
xsim ucorr88_tb -nolog -R | tee sim.log | grep -E 'PASSED|Failure|Error|ERROR' | grep -vE 'SLEEP_CHECK|EMPTY_CHECK|N=8' | head -5
