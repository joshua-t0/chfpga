#!/bin/bash
# Compiles and runs the testbench of the correlator accumulators with the Vivado simulator.
# Needs the Vivado environment (source setenv.sh from the repository root).
#
# Usage: ./run.sh [GENERIC=value ...]     e.g. ./run.sh WIDE=0     or     ./run.sh INTEG=32768 CONSTANT_ONLY=1 INTEGRATIONS=1
# Prints "UCORR ACC TEST PASSED" on success. A run takes 15 minutes or more.
# Environment: WORK=<directory> for the work files (default ./work, not versioned), so that runs can be made in parallel.
#              CORR_SRC=<directory> to take UCMAC44_ARRAY.vhd, UCORR44.vhd and UCORR44_ARRAY.vhd from another
#              directory (e.g. the files before a change, to compare the DUMP_FILE of the two designs).
set -e
here=$(cd "$(dirname "$0")" && pwd)
hdl=$here/../../../hdl
work=${WORK:-$here/work}
corr=${CORR_SRC:-$hdl/corr}
mkdir -p "$work" && cd "$work"
generics=()
for g in "$@"; do generics+=(-generic_top "$g"); done
rm -rf xsim.dir/ucorr_acc_tb  # never run an old snapshot when the compilation fails
tb=$hdl/testbenches/ucorr_acc_testbench.vhd
if [ -n "$CORR_SRC" ]; then  # a design before the change does not have the generic for the wide autocorrelations
	grep -v "WIDE_AUTOCORR  => WIDE = 1," "$tb" > ucorr_acc_testbench_old.vhd
	tb=ucorr_acc_testbench_old.vhd
fi
xvlog -nolog "$XILINX_VIVADO/data/verilog/src/glbl.v" > /dev/null
xvhdl -2008 -nolog "$hdl/chfpga_package.vhd" "$hdl/bsb/bsb_regs.vhd" "$hdl/utils/generic_fifo.vhd" \
	"$corr/UCMAC44_ARRAY.vhd" "$corr/UCORR44.vhd" "$corr/UCORR44_ARRAY.vhd" "$tb" > compile.log 2>&1 \
	|| { grep ERROR compile.log; echo "Failure: compilation error"; exit 1; }
xelab -nolog -L xpm -L unisim work.ucorr_acc_testbench work.glbl -s ucorr_acc_tb "${generics[@]}" > elaborate.log 2>&1 \
	|| { grep ERROR elaborate.log; echo "Failure: elaboration error"; exit 1; }
xsim ucorr_acc_tb -nolog -R | tee sim.log | grep -E 'PASSED|Failure|Error|ERROR' | grep -vE 'SLEEP_CHECK|EMPTY_CHECK|N=8' | head -5
