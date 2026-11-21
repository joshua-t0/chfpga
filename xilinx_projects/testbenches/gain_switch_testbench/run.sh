#!/bin/bash
# Compiles and runs the gain switch testbench (scalers and correlator array) with the Vivado simulator.
# Needs the Vivado environment (source setenv.sh from the repository root).
#
# Usage: ./run.sh [GENERIC=value ...]     e.g. ./run.sh DELAY=50
# Prints "GAIN SWITCH TEST PASSED" on success. Work files go in ./work (not versioned).
set -e
here=$(cd "$(dirname "$0")" && pwd)
hdl=$here/../../../hdl
mkdir -p "$here/work" && cd "$here/work"
generics=()
for g in "$@"; do generics+=(-generic_top "$g"); done
# The scaler names the complex multiplier IP, which the real gains do not use: an empty unit takes its place
cat > scaler_cmul_stub.vhd <<'STUB'
library ieee;
use ieee.std_logic_1164.all;
entity SCALER_CMUL is
	port (
		aclk: in std_logic;
		s_axis_a_tvalid, s_axis_a_tlast, s_axis_b_tvalid: in std_logic;
		s_axis_a_tuser, s_axis_a_tdata, s_axis_b_tdata: in std_logic_vector;
		m_axis_dout_tvalid, m_axis_dout_tlast: out std_logic;
		m_axis_dout_tuser, m_axis_dout_tdata: out std_logic_vector
	);
end entity;
architecture stub of SCALER_CMUL is begin end architecture;
STUB
rm -rf xsim.dir/gain_switch_tb  # never run an old snapshot when the compilation fails
xvlog -nolog "$XILINX_VIVADO/data/verilog/src/glbl.v" > /dev/null
xvhdl -2008 -nolog "$hdl/chfpga_package.vhd" "$hdl/bsb/bsb_regs.vhd" "$hdl/utils/generic_fifo.vhd" scaler_cmul_stub.vhd \
	"$hdl/chan/scaler_mul.vhd" "$hdl/chan/scaler.vhd" "$hdl/corr/UCMAC44_ARRAY.vhd" "$hdl/corr/UCORR44.vhd" "$hdl/corr/UCORR44_ARRAY.vhd" \
	"$hdl/testbenches/tb_package.vhd" "$hdl/testbenches/gain_switch_testbench.vhd" > compile.log 2>&1 \
	|| { grep ERROR compile.log; echo "Failure: compilation error"; exit 1; }
xelab -nolog -L xpm -L unisim work.gain_switch_testbench work.glbl -s gain_switch_tb "${generics[@]}" > elaborate.log 2>&1 \
	|| { grep ERROR elaborate.log; echo "Failure: elaboration error"; exit 1; }
xsim gain_switch_tb -nolog -R | grep -E 'PASSED|Failure|Error|ERROR' | grep -vE 'SLEEP_CHECK|EMPTY_CHECK' | head -5
