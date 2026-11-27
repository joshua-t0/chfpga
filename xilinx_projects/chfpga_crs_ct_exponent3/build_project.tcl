#!/usr/bin/env -S vivado -mode batch -notrace -source
#*****************************************************************************************
# Vivado (TM) v2022.2 (64-bit)
#
# build_project.tcl: Tcl script for building the project in the current folder and generate its bitstream
#
#  # Run this script
#
#      ./build_project.tcl
#
#*****************************************************************************************
# Make sure the cwd is the folder containing this script
cd [file normalize [file dirname [info script]]]

source ../../tcl/build_project.tcl
