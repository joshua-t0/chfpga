#!/bin/bash
# Compiles and runs the testbench of the exponent mode of the packetizer (upack) with the Vivado simulator.
# Needs the Vivado environment (source setenv.sh from the repository root).
#
# Usage: ./run.sh [GENERIC=value ...]
#   ./run.sh                                    frames of 32 words, 4 packets of 8 bins (about 15 seconds)
#   ./run.sh EB=3                               exponents of 3 bits: exponents of 2 and of 4 bits in the packets (about 30 seconds)
#   ./run.sh NBINS=6                            packets with another number of data bins
#   ./run.sh WORDS=2048 NPKT=128 NBINS=48 BLOCKS=2 SWEEP=4   the frames and the packets of the firmware
#   ./run.sh VECTORS=$PWD/vectors               writes the files for the host decoder (one setting only)
# Prints "UPACK EXPONENT TEST PASSED" on success. Work files go in ./work (not versioned).
set -e
here=$(cd "$(dirname "$0")" && pwd)
hdl=$here/../../../hdl
work=${TB_WORK_DIR:-$here/work}  # TB_WORK_DIR=<directory>: to run two simulations at the same time
mkdir -p "$work" && cd "$work"
generics=()
for g in "$@"; do generics+=(-generic_top "$g"); done
rm -rf xsim.dir/upack_exponent_tb  # never run an old snapshot when the compilation fails
xvlog -nolog "$XILINX_VIVADO/data/verilog/src/glbl.v" > /dev/null
xvhdl -2008 -nolog "$hdl/chfpga_package.vhd" "$hdl/bsb/bsb_regs.vhd" "$hdl/bsb/bsb_async_fifo.vhd" \
	"$hdl/ct/upack.vhd" \
	"$hdl/testbenches/tb_package.vhd" "$hdl/testbenches/upack_exponent_testbench.vhd" > compile.log 2>&1 \
	|| { grep ERROR compile.log; echo "Failure: compilation error"; exit 1; }
xelab -nolog -L xpm -L unisim work.upack_exponent_testbench work.glbl -s upack_exponent_tb "${generics[@]}" > elaborate.log 2>&1 \
	|| { grep ERROR elaborate.log; echo "Failure: elaboration error"; exit 1; }
xsim upack_exponent_tb -nolog -R | grep -E 'PASSED|Failure|Error|ERROR|Phase|Exponents of|Shift by|Packets with|VECTORS' | grep -vE 'SLEEP_CHECK|EMPTY_CHECK' | head -60
