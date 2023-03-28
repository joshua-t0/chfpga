################################################################################

# This XDC is used only for OOC mode of synthesis, implementation
# This constraints file contains default clock frequencies to be used during
# out-of-context flows such as OOC Synthesis and Hierarchical Designs.
# This constraints file is not used in normal top-down synthesis (default flow
# of Vivado)
################################################################################
create_clock -name adc0_clk_clk_p -period 5 [get_ports adc0_clk_clk_p]
create_clock -name adc1_clk_clk_p -period 5 [get_ports adc1_clk_clk_p]
create_clock -name adc2_clk_clk_p -period 5 [get_ports adc2_clk_clk_p]
create_clock -name adc3_clk_clk_p -period 5 [get_ports adc3_clk_clk_p]
create_clock -name FPGA_REFCLK_OUT_C_clk_p -period 2.667 [get_ports FPGA_REFCLK_OUT_C_clk_p]
create_clock -name SYSREF_FPGA_clk_p -period 3.333 [get_ports SYSREF_FPGA_clk_p]

################################################################################