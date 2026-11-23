#!/bin/bash
# Compiles and runs the testbench of the (8+8)-bit correlator cells (UCMAC88_ARRAY) with the Vivado simulator.
# Needs the Vivado environment (source setenv.sh from the repository root).
#
# Usage: ./run.sh [GENERIC=value ...]     e.g. ./run.sh     ./run.sh AUTO_BITS=20     ./run.sh CROSS_BITS=22
# Prints "UCMAC88 TEST PASSED" on success. A run takes a few minutes.
# Environment: WORK=<directory> for the work files (default ./work, not versioned), so that runs can be made in parallel.
set -e
here=$(cd "$(dirname "$0")" && pwd)
hdl=$here/../../../hdl
work=${WORK:-$here/work}
mkdir -p "$work" && cd "$work"
generics=()
for g in "$@"; do generics+=(-generic_top "$g"); done
rm -rf xsim.dir/ucmac88_tb  # never run an old snapshot when the compilation fails
xvlog -nolog "$XILINX_VIVADO/data/verilog/src/glbl.v" > /dev/null
xvhdl -2008 -nolog "$hdl/chfpga_package.vhd" "$hdl/corr/UCMAC88_ARRAY.vhd" "$hdl/testbenches/ucmac88_testbench.vhd" > compile.log 2>&1 \
	|| { grep ERROR compile.log; echo "Failure: compilation error"; exit 1; }
xelab -nolog -L xpm -L unisim work.ucmac88_testbench work.glbl -s ucmac88_tb "${generics[@]}" > elaborate.log 2>&1 \
	|| { grep ERROR elaborate.log; echo "Failure: elaboration error"; exit 1; }
xsim ucmac88_tb -nolog -R | tee sim.log | grep -E 'PASSED|Failure|Error|ERROR' | grep -vE 'SLEEP_CHECK|EMPTY_CHECK' | head -5
