#!/bin/bash
# Compiles and runs the testbench of the split-sample stage with the Vivado simulator.
# Needs the Vivado environment (source setenv.sh from the repository root).
# Prints "SAMPLE SPLIT TEST PASSED" on success. Work files go in ./work (not versioned).
set -e
here=$(cd "$(dirname "$0")" && pwd)
hdl=$here/../../../hdl
mkdir -p "$here/work" && cd "$here/work"
generics=()
for g in "$@"; do generics+=(-generic_top "$g"); done
rm -rf xsim.dir/sample_split_tb  # never run an old snapshot when the compilation fails
xvhdl -2008 -nolog "$hdl/chfpga_package.vhd" "$hdl/chan/sample_split.vhd" "$hdl/testbenches/sample_split_testbench.vhd" > compile.log 2>&1 \
	|| { grep ERROR compile.log; echo "Failure: compilation error"; exit 1; }
xelab -nolog work.sample_split_testbench -s sample_split_tb "${generics[@]}" > elaborate.log 2>&1 \
	|| { grep ERROR elaborate.log; echo "Failure: elaboration error"; exit 1; }
xsim sample_split_tb -nolog -R | grep -E 'PASSED|Failure|Error|ERROR' | head -5
