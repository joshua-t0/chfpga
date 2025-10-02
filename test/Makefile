ifeq ($(XILINX_VIVADO),)
 $(error Please source a Vivado settings.sh script before running this!)
endif

# See if we're inside docker. If not, wrap ourselves in docker and try again.
ifeq ($(wildcard /.dockerenv),)
include Makefile.docker-boilerplate
else
# For the remainder of this Makefile, we're running within Docker and can focus
# on building documentation instead of the build environment.

default: pyxsi.so

.PHONY: rtl rtl_generate rtl_compile test clean

VPATH=src

# Vivado 2025.1+ changed the name of the shared library - it's either
# librdi_simulator_kernel.so or libxv_simulator_kernel.so
SIMENGINE_SO := $(wildcard $(XILINX_VIVADO)/lib/lnx64.o/lib*_simulator_kernel.so)

CXX=g++
CXXFLAGS=-Wall -Werror -g -fPIC -std=c++20		\
	 $(shell python3 -m pybind11 --includes)	\
	-I$(XILINX_VIVADO)/data/xsim/include -Isrc	\
	-DSIMENGINE_SO=\"$(SIMENGINE_SO)\"

%.o: %.cpp xsi_loader.h
	$(CXX) $(CXXFLAGS) -c -o $@ $<

pyxsi.so: pybind.o xsi_loader.o
	$(CXX) $(CXXFLAGS) -shared -o $@ $^ -ldl

# RTL flow - this is very fussy about what directory you execute the simulation
# in (don't get clever!).
rtl: export_sim rtl_compile

# Export simulation capsule (project files, compilation script, memory
# contents) to the export_sim/xsim directory. This does not contain RTL - just
# the "other stuff" you need for compilation and simulation, plus .prj files
# that point to the RTL.
export_sim:
	source $(XILINX_VIVADO)/settings64.sh && \
		./generate_ip.tcl

rtl_compile:
	# Amend simulation script: append "-dll" to xelab command, and don't run simulation
	sed -i '/xelab / s/\( -dll\)*$$/ -dll/' export_sim/xsim/chfpga_crssim.sh
	sed -i '/^  simulate$$/d' export_sim/xsim/chfpga_crssim.sh
	touch export_sim/xsim/design.txt  # avoid segfault - SYSMON_V6 needs this
	cd export_sim/xsim && \
		source $(XILINX_VIVADO)/settings64.sh && \
		./chfpga_crssim.sh

test: pyxsi.so
	ulimit -n 1024 && \
		cd export_sim/xsim && \
		LD_LIBRARY_PATH=$(XILINX_VIVADO)/lib/lnx64.o \
		../../test_something.py

clean:
	-rm *.o *.so
	-rm -rf xsim.dir py/__pycache__ *.jou *.log xelab.pb *.wdb

endif
