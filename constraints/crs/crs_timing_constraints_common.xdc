############################################################################
##
##   CRS Rev1 and Rev2 Timing constraints (common)
##
############################################################################
## Common timing constraints shared by all CRS configs.
## Physical constraints (I/O pins, clocks on ports) are in
## crs_physical_constraints_common.xdc; clock periods and delay/multicycle
## constraints are defined here.
############################################################################


set_switching_activity -default_toggle_rate 50.000


# CLK10 SMA: 10 MHz clock signal (copy fed to the HMC7044 input)
create_clock -period 100.000 -name SMA_CLK10 [get_ports sma_clk10_p]

# GTY reference clock MGTREFCLK0, 156.25 MHz from fixed PLL, Bank 131 (corner-turn engine)
create_clock -period 6.400 -name CLK_BP_SHUFFLE_REFCLK [get_ports {bp_shuffle_refclk_p[0]}]

# Output from the HMC7044 PLL1 (50 MHz VCXO, phase-aligned with SMA or BP 10 MHz when present)
create_clock -period 20.000 -name OSCOUT [get_ports pll_oscout_p]

# PLL Sync control line, synchronous to OSCOUT
set_output_delay -clock OSCOUT -max 1.000 [get_ports pll_sync]
set_output_delay -clock OSCOUT -min -1.000 [get_ports pll_sync]
set_multicycle_path -setup -to [get_ports pll_sync] 1

# PL_CLK (Bank 69), fabric signal processing word clock (ADC sampling freq / 8, e.g. 400 MHz)
create_clock -period 2.500 -name PL_CLK [get_ports plclk_p]
set_clock_latency -min -source -0.015 [get_ports plclk_p]
set_clock_latency -max -source 0.015 [get_ports plclk_p]

# SYSREF (Bank 69), 2.5 MHz; not a clock, data synchronized to PL_CLK
set_input_delay -clock [get_clocks PL_CLK] -max 0.015 [get_ports pl_sysref_p]
set_input_delay -clock [get_clocks PL_CLK] -min -0.015 [get_ports pl_sysref_p]
# Align SYSREF setup on same edge (generated outside FPGA)
set_multicycle_path -setup -from [get_ports pl_sysref_p] 0

# DDR4_CLK (Bank 67), 10 MHz system clock
create_clock -period 100.000 -name SYS_CLK [get_ports sysclk_p]
set_clock_latency -min -source -0.015 [get_ports sysclk_p]
set_clock_latency -max -source 0.015 [get_ports sysclk_p]

set_multicycle_path -setup -from [get_clocks SYS_CLK] -to [get_clocks PL_CLK] 0

# 100 MHz PS-to-PL clock (BSB) is asynchronous to other clocks
set_clock_groups -name BSB_CLK_GROUP -asynchronous -group [get_clocks -of_objects [get_nets aclk]]

# Backplane IRIG-B (SYS_CLK domain)
set_input_delay -clock [get_clocks SYS_CLK] -max 0.015 [get_ports bp_irig_p]
set_input_delay -clock [get_clocks SYS_CLK] -min -0.015 [get_ports bp_irig_p]

# Backplane 10 MHz reference clock (copy fed to HMC7044)
create_clock -period 100.000 -name PL_BP_CLK10 [get_ports bp_clk10_p]
set_clock_groups -name exclusive_clk0_clk1 -physically_exclusive -group SMA_CLK10 -group PL_BP_CLK10

# Rear SMA IRIG-B
set_input_delay -clock [get_clocks SYS_CLK] -max 0.015 [get_ports sma_irig_p]
set_input_delay -clock [get_clocks SYS_CLK] -min -0.015 [get_ports sma_irig_p]

# AUX SMA driver output
set_output_delay -clock [get_clocks SYS_CLK] -max 0.015 [get_ports sma_aux_drv]
set_output_delay -clock [get_clocks SYS_CLK] -min -0.015 [get_ports sma_aux_drv]

# Multicycle paths between IRIG-B/AUX and internal clocks that generate or capture them
set_multicycle_path -hold -from [get_clocks SYS_CLK] -to [get_clocks clk200_nobuf] 1
set_multicycle_path -hold -end -from [get_clocks PL_CLK] -to [get_clocks SYS_CLK] 1
set_multicycle_path -setup -from [get_clocks PL_CLK] -to [get_clocks SYS_CLK] 2
set_multicycle_path -setup -from [get_clocks clk200_nobuf] -to [get_clocks SYS_CLK] 2
set_multicycle_path -hold -end -from [get_clocks clk200_nobuf] -to [get_clocks SYS_CLK] 1

# Buck SYNC outputs: not timed to any clock
set_false_path -to [get_ports buck_sync_*]

###############################
# Frequency counter
################################
# Constrain the frequency counter clock. The clock frequency on this net is 1/2 if the measured clock source
# no constraint: Causes  critical warning: no clock reaching counter registers clock inputs
# Reaassigning a clock causes methodology critical warnings
create_clock -period 3.200 -name FREQ_CTR [get_pins */*.system0/*.freq_ctr0/*.srcclk0/I]
set_clock_groups -name FREQ_CTR_GROUP -asynchronous -group [get_clocks FREQ_CTR]



