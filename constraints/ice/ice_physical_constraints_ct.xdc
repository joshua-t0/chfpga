# Common constraints are in ice_physical_constraints_common.xdc


##############################
# LOCATION CONSTRAINTS
##############################

### MMCMs ###
# We need to put the ADCDAQ PLL in the same bank as the BUFR that drives it (Bank 13)
#set_property LOC MMCME2_ADV_X0Y3 [get_cells {chfpga0/chan_array0/adc_gen.ev8aq160_case.adcgen[0].adcdaq0/IMPL.USEPLL.PLL0/U0/mmcm_adv_inst}]
# The Channelizer MMCM has 2 inputs:  adcdaq0 and System MMCM (CLK200). If Tey are there were driven directly (no BUFG) by both the ADCDAQ BUFR and Sysntem MMCM output, . The MMCM must be adjacent, but on a half that has enough BUFGs
#set_property LOC MMCME2_ADV_X0Y3 [get_cells chfpga0/clk0/gen_chanpll_k7.chan_mmcm0]
#set_property LOC MMCME2_ADV_X0Y3 [get_cells chfpga0/clk0/gen_chanpll_k7.mmcm_case.chan_mmcm0]
# The system MMCM also drives the Channelizer MMCM, and also needs to be adjacent.

set_property LOC BUFGCTRL_X0Y18 [get_cells chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/xglink0/txoutclk_bufg0]
set_property LOC BUFGCTRL_X0Y19 [get_cells chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/xglink0/refclk_bufg0]


#################################
# Motherboard QSFP+ Pins
#################################

# ### QSFP A

set_property PACKAGE_PIN G4 [get_ports {xge_rx_p[0]}]
set_property PACKAGE_PIN D2 [get_ports {xge_tx_p[0]}]
set_property PACKAGE_PIN E4 [get_ports {xge_rx_p[1]}]
set_property PACKAGE_PIN B2 [get_ports {xge_tx_p[1]}]
set_property PACKAGE_PIN D6 [get_ports {xge_rx_p[2]}]
set_property PACKAGE_PIN A4 [get_ports {xge_tx_p[2]}]
set_property PACKAGE_PIN C4 [get_ports {xge_rx_p[3]}]
set_property PACKAGE_PIN B6 [get_ports {xge_tx_p[3]}]

# ### QSFP B

set_property PACKAGE_PIN F10 [get_ports {xge_rx_p[4]}]
set_property PACKAGE_PIN C8 [get_ports {xge_tx_p[4]}]
set_property PACKAGE_PIN D10 [get_ports {xge_rx_p[5]}]
set_property PACKAGE_PIN A8 [get_ports {xge_tx_p[5]}]
set_property PACKAGE_PIN E12 [get_ports {xge_rx_p[6]}]
set_property PACKAGE_PIN B10 [get_ports {xge_tx_p[6]}]
set_property PACKAGE_PIN C12 [get_ports {xge_rx_p[7]}]
set_property PACKAGE_PIN A12 [get_ports {xge_tx_p[7]}]



#################################
# Backplane shuffle
#################################
# Backplane PCB shuffle
#  Index Lane #   GTX #      GTX #  FPGA Pin #   Ref clock       bp_shuffle_refclk[x]
#   0     1      GTX114_3   X0Y15_TX  N4         MGTREFCLK114_0    1
#   1     2      GTX114_2   X0Y14_TX  P2         MGTREFCLK114_0    1
#   2     3      GTX114_1   X0Y13_TX  T2         MGTREFCLK114_0    1
#   3     4      GTX114_0   X0Y12_TX  V2         MGTREFCLK114_0    1
#   4     5      GTX111_3   X0Y3_TX   AG8        MGTREFCLK112_0    0
#   5     6      GTX111_2   X0Y2_TX   AJ8        MGTREFCLK112_0    0
#   6     7      GTX111_1   X0Y1_TX   AK10       MGTREFCLK112_0    0
#   7     8      GTX111_0   X0Y0_TX   AJ12       MGTREFCLK112_0    0
#   8     9      GTX112_3   X0Y7_TX   AH2        MGTREFCLK112_0    0
#   9     10     GTX112_2   X0Y6_TX   AK2        MGTREFCLK112_0    0
#   10    11     GTX112_1   X0Y5_TX   AJ4        MGTREFCLK112_0    0
#   11    12     GTX112_0   X0Y4_TX   AK6        MGTREFCLK112_0    0
#   12    13     GTX115_0   X0Y16_TX  M2         MGTREFCLK114_0    1
#   13    14     GTX115_1   X0Y17_TX  K2         MGTREFCLK114_0    1
#   14    15     GTX115_2   X0Y18_TX  H2         MGTREFCLK114_0    1
# Backplane QSFP+ shuffle
#   15    0      GTX113_3   X0Y11_TX  AF1        MGTREFCLK114_0    1
#   16    1      GTX113_2   X0Y10_TX  AD1        MGTREFCLK114_0    1
#   17    2      GTX113_1   X0Y9_TX   AB1        MGTREFCLK114_0    1
#   18    3      GTX113_0   X0Y8_TX   Y1         MGTREFCLK114_0    1

set_property PACKAGE_PIN N4 [get_ports {bp_shuffle_tx_p[0]}]
set_property PACKAGE_PIN P2 [get_ports {bp_shuffle_tx_p[1]}]
set_property PACKAGE_PIN T2 [get_ports {bp_shuffle_tx_p[2]}]
set_property PACKAGE_PIN V2 [get_ports {bp_shuffle_tx_p[3]}]
set_property PACKAGE_PIN AG8 [get_ports {bp_shuffle_tx_p[4]}]
set_property PACKAGE_PIN AJ8 [get_ports {bp_shuffle_tx_p[5]}]
set_property PACKAGE_PIN AK10 [get_ports {bp_shuffle_tx_p[6]}]
set_property PACKAGE_PIN AJ12 [get_ports {bp_shuffle_tx_p[7]}]
set_property PACKAGE_PIN AH2 [get_ports {bp_shuffle_tx_p[8]}]
set_property PACKAGE_PIN AK2 [get_ports {bp_shuffle_tx_p[9]}]
set_property PACKAGE_PIN AJ4 [get_ports {bp_shuffle_tx_p[10]}]
set_property PACKAGE_PIN AK6 [get_ports {bp_shuffle_tx_p[11]}]
set_property PACKAGE_PIN M2 [get_ports {bp_shuffle_tx_p[12]}]
set_property PACKAGE_PIN K2 [get_ports {bp_shuffle_tx_p[13]}]
set_property PACKAGE_PIN H2 [get_ports {bp_shuffle_tx_p[14]}]
# set_property PACKAGE_PIN D2 [get_ports {bp_shuffle_tx_p[15]}]
set_property PACKAGE_PIN AF2 [get_ports {bp_shuffle_tx_p[15]}]
set_property PACKAGE_PIN AD2 [get_ports {bp_shuffle_tx_p[16]}]
set_property PACKAGE_PIN AB2 [get_ports {bp_shuffle_tx_p[17]}]
set_property PACKAGE_PIN Y2 [get_ports {bp_shuffle_tx_p[18]}]





# ###################################
# # AREA Contraints
# ###################################



# create_pblock GPU0
# add_cells_to_pblock [get_pblocks GPU0] [get_cells -quiet [list {chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/udp_gen[0].udp0} {chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/udp_gen[1].udp0}]]
# resize_pblock [get_pblocks GPU0] -add {SLICE_X166Y250:SLICE_X189Y269}
# resize_pblock [get_pblocks GPU0] -add {DSP48_X11Y100:DSP48_X11Y107}
# resize_pblock [get_pblocks GPU0] -add {RAMB18_X11Y100:RAMB18_X11Y107}
# resize_pblock [get_pblocks GPU0] -add {RAMB36_X11Y50:RAMB36_X11Y53}
# set_property IS_SOFT TRUE [get_pblocks GPU0]


# create_pblock GPU1
# add_cells_to_pblock [get_pblocks GPU1] [get_cells -quiet [list {chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/udp_gen[2].udp0} {chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/udp_gen[3].udp0}]]
# resize_pblock [get_pblocks GPU1] -add {SLICE_X166Y270:SLICE_X189Y289}
# resize_pblock [get_pblocks GPU1] -add {DSP48_X11Y108:DSP48_X11Y115}
# resize_pblock [get_pblocks GPU1] -add {RAMB18_X11Y108:RAMB18_X11Y115}
# resize_pblock [get_pblocks GPU1] -add {RAMB36_X11Y54:RAMB36_X11Y57}
# set_property IS_SOFT TRUE [get_pblocks GPU1]


# create_pblock GPU2
# add_cells_to_pblock [get_pblocks GPU2] [get_cells -quiet [list {chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/udp_gen[4].udp0} {chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/udp_gen[5].udp0}]]
# resize_pblock [get_pblocks GPU2] -add {SLICE_X166Y310:SLICE_X189Y329}
# resize_pblock [get_pblocks GPU2] -add {DSP48_X11Y124:DSP48_X11Y131}
# resize_pblock [get_pblocks GPU2] -add {RAMB18_X11Y124:RAMB18_X11Y131}
# resize_pblock [get_pblocks GPU2] -add {RAMB36_X11Y62:RAMB36_X11Y65}
# set_property IS_SOFT TRUE [get_pblocks GPU2]


# create_pblock GPU3
# add_cells_to_pblock [get_pblocks GPU3] [get_cells -quiet [list {chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/udp_gen[6].udp0} {chfpga0/GPU_GEN.gpu_sel_gen.gpulink0/udp_gen[7].udp0}]]
# resize_pblock [get_pblocks GPU3] -add {SLICE_X166Y330:SLICE_X189Y349}
# resize_pblock [get_pblocks GPU3] -add {DSP48_X11Y132:DSP48_X11Y139}
# resize_pblock [get_pblocks GPU3] -add {RAMB18_X11Y132:RAMB18_X11Y139}
# resize_pblock [get_pblocks GPU3] -add {RAMB36_X11Y66:RAMB36_X11Y69}
# set_property IS_SOFT TRUE [get_pblocks GPU3]


# create_pblock CB00
# resize_pblock [get_pblocks CB00] -add {SLICE_X148Y150:SLICE_X189Y199}
# resize_pblock [get_pblocks CB00] -add {DSP48_X10Y60:DSP48_X11Y79}
# resize_pblock [get_pblocks CB00] -add {RAMB18_X9Y60:RAMB18_X11Y79}
# resize_pblock [get_pblocks CB00] -add {RAMB36_X9Y30:RAMB36_X11Y39}
# set_property IS_SOFT FALSE [get_pblocks CB00]
# add_cells_to_pblock [get_pblocks CB00] [get_cells -quiet {{chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[0].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[1].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[2].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[3].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/quad_gen[0].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/quad_gen[1].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/quad_gen[2].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/quad_gen[3].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/rx_gen[0].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/rx_gen[1].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/rx_gen[2].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/rx_gen[3].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/tx_gen[0].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/tx_gen[1].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/tx_gen[2].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/tx_gen[3].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[0]*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[1]*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[2]*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[3]*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[4]*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[0].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[1].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[2].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[3].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[4].*}}]

# ---------------------------------------------------------------------------
# CB00 BRAM/FIFO LOC (replaces pblock RAMB18 range)
# FIFO18E1 (sngfifo18e1) -> lower half of RAMB36 only: RAMB18_X9Y60,62,64,66,68
# RAMB18E1 (rest) -> upper half / any: RAMB18_X9Y61,63,65,67,69,70-79, X10Y60-64
# ---------------------------------------------------------------------------
# FIFO18E1 (sngfifo18e1) - lower half of RAMB36 tile only
set_property LOC RAMB18_X9Y60 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[0].binsel_i/data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X9Y62 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[1].binsel_i/data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X9Y64 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[2].binsel_i/data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X9Y66 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[3].binsel_i/data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X9Y68 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[4].binsel_i/data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]

# RAMB18E1 (upper half / any) - bp_shuffle lane rx/tx fifos (WIDE_PRIM18)
set_property LOC RAMB18_X9Y61 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[0].direct_gen.direct0/rx_fifo0/U0/inst_fifo_gen/gaxis_fifo.gaxisf.axisf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y63 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[0].direct_gen.direct0/tx_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y65 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[1].rx_gen.rx0/rx_fifo0/U0/inst_fifo_gen/gaxis_fifo.gaxisf.axisf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y67 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[1].tx_gen.tx0/tx_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y69 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[2].rx_gen.rx0/rx_fifo0/U0/inst_fifo_gen/gaxis_fifo.gaxisf.axisf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y70 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[2].tx_gen.tx0/tx_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y71 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[3].rx_gen.rx0/rx_fifo0/U0/inst_fifo_gen/gaxis_fifo.gaxisf.axisf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y72 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[3].tx_gen.tx0/tx_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y73 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[4].rx_gen.rx0/rx_fifo0/U0/inst_fifo_gen/gaxis_fifo.gaxisf.axisf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y74 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[4].tx_gen.tx0/tx_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]

# RAMB18E1 - chan_crossbar data_flags_fifo0, mask_ram0
set_property LOC RAMB18_X9Y75 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[0].binsel_i/data_flags_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y76 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[0].binsel_i/mask_ram0/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM18.ram}]
set_property LOC RAMB18_X9Y77 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[1].binsel_i/data_flags_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y78 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[1].binsel_i/mask_ram0/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM18.ram}]
set_property LOC RAMB18_X9Y79 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[2].binsel_i/data_flags_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X10Y60 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[2].binsel_i/mask_ram0/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM18.ram}]
set_property LOC RAMB18_X10Y61 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[3].binsel_i/data_flags_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X10Y62 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[3].binsel_i/mask_ram0/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM18.ram}]
set_property LOC RAMB18_X10Y63 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[4].binsel_i/data_flags_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X10Y64 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[4].binsel_i/mask_ram0/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM18.ram}]



# create_pblock CB01
# resize_pblock [get_pblocks CB01] -add {SLICE_X144Y0:SLICE_X189Y49}
# resize_pblock [get_pblocks CB01] -add {DSP48_X10Y0:DSP48_X11Y19}
# resize_pblock [get_pblocks CB01] -add {RAMB18_X9Y0:RAMB18_X11Y19}
# resize_pblock [get_pblocks CB01] -add {RAMB36_X9Y0:RAMB36_X11Y9}
# set_property IS_SOFT FALSE [get_pblocks CB01]
# add_cells_to_pblock [get_pblocks CB01] [get_cells -quiet {{chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[4].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[5].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[6].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[7].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/quad_gen[4].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/quad_gen[5].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/quad_gen[6].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/quad_gen[7].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/rx_gen[4].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/rx_gen[5].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/rx_gen[6].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/rx_gen[7].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/tx_gen[4].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/tx_gen[5].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/tx_gen[6].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/tx_gen[7].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[5]*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[6]*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[7]*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[8]*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[5].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[6].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[7].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[8].*}}]
# ---------------------------------------------------------------------------
# CB01 BRAM/FIFO LOC (replaces pblock RAMB18 range)
# FIFO18E1 (sngfifo18e1) -> lower half of RAMB36 only: RAMB18_X9Y0,2,4,6
# RAMB18E1 (rest) -> upper half / any: RAMB18_X9Y1,3,5,7,8-19
# ---------------------------------------------------------------------------
# FIFO18E1 (sngfifo18e1) - lower half of RAMB36 tile only
set_property LOC RAMB18_X9Y0 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[5].binsel_i/data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X9Y2 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[6].binsel_i/data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X9Y4 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[7].binsel_i/data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X9Y6 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[8].binsel_i/data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]

# RAMB18E1 (upper half / any) - bp_shuffle lane_gen[5,6,7,8] rx/tx fifos (WIDE_PRIM18)
set_property LOC RAMB18_X9Y1 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[5].rx_gen.rx0/rx_fifo0/U0/inst_fifo_gen/gaxis_fifo.gaxisf.axisf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y3 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[5].tx_gen.tx0/tx_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y5 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[6].rx_gen.rx0/rx_fifo0/U0/inst_fifo_gen/gaxis_fifo.gaxisf.axisf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y7 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[6].tx_gen.tx0/tx_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y8 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[7].rx_gen.rx0/rx_fifo0/U0/inst_fifo_gen/gaxis_fifo.gaxisf.axisf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y9 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[7].tx_gen.tx0/tx_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y10 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[8].rx_gen.rx0/rx_fifo0/U0/inst_fifo_gen/gaxis_fifo.gaxisf.axisf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y11 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[8].tx_gen.tx0/tx_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]

# RAMB18E1 - chan_crossbar data_flags_fifo0, mask_ram0 (bin_sel_gen[5..8])
set_property LOC RAMB18_X9Y12 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[5].binsel_i/data_flags_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y13 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[5].binsel_i/mask_ram0/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM18.ram}]
set_property LOC RAMB18_X9Y14 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[6].binsel_i/data_flags_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y15 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[6].binsel_i/mask_ram0/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM18.ram}]
set_property LOC RAMB18_X9Y16 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[7].binsel_i/data_flags_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y17 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[7].binsel_i/mask_ram0/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM18.ram}]
set_property LOC RAMB18_X9Y18 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[8].binsel_i/data_flags_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y19 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[8].binsel_i/mask_ram0/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM18.ram}]





# create_pblock CB02
# resize_pblock [get_pblocks CB02] -add {SLICE_X144Y50:SLICE_X189Y84}
# resize_pblock [get_pblocks CB02] -add {DSP48_X10Y20:DSP48_X11Y33}
# resize_pblock [get_pblocks CB02] -add {RAMB18_X9Y20:RAMB18_X11Y33}
# resize_pblock [get_pblocks CB02] -add {RAMB36_X9Y10:RAMB36_X11Y16}
# set_property IS_SOFT FALSE [get_pblocks CB02]
# add_cells_to_pblock [get_pblocks CB02] [get_cells -quiet {{chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[8].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[9].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[10].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[11].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/quad_gen[8].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/quad_gen[9].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/quad_gen[10].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/quad_gen[11].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/rx_gen[8].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/rx_gen[9].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/rx_gen[10].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/rx_gen[11].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/tx_gen[8].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/tx_gen[9].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/tx_gen[10].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/tx_gen[11].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[9]*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[10]*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[11]*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[12]*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[9].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[10].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[11].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[12].*}}]
# ---------------------------------------------------------------------------
# CB02 BRAM/FIFO LOC (replaces pblock RAMB18 range)
# FIFO18E1 (sngfifo18e1) -> lower half of RAMB36 only (left cols). RAMB18E1 -> left cols; lane_gen -> rightmost col X11
# ---------------------------------------------------------------------------
# FIFO18E1 (sngfifo18e1) - lower half of RAMB36, left columns (X9)
set_property LOC RAMB18_X9Y20 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[10].binsel_i/data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X9Y22 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[11].binsel_i/data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X9Y24 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[12].binsel_i/data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X9Y26 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[9].binsel_i/data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]

# RAMB18E1 - chan_crossbar (left columns X9)
set_property LOC RAMB18_X9Y21 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[10].binsel_i/data_flags_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y23 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[10].binsel_i/mask_ram0/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM18.ram}]
set_property LOC RAMB18_X9Y25 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[11].binsel_i/data_flags_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y27 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[11].binsel_i/mask_ram0/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM18.ram}]
set_property LOC RAMB18_X9Y28 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[12].binsel_i/data_flags_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y29 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[12].binsel_i/mask_ram0/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM18.ram}]
set_property LOC RAMB18_X9Y30 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[9].binsel_i/data_flags_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y31 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[9].binsel_i/mask_ram0/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM18.ram}]

# RAMB18E1 - bp_shuffle lane_gen (rightmost column X11)
set_property LOC RAMB18_X11Y20 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[10].rx_gen.rx0/rx_fifo0/U0/inst_fifo_gen/gaxis_fifo.gaxisf.axisf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X11Y21 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[10].tx_gen.tx0/tx_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X11Y22 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[11].rx_gen.rx0/rx_fifo0/U0/inst_fifo_gen/gaxis_fifo.gaxisf.axisf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X11Y23 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[11].tx_gen.tx0/tx_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X11Y24 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[12].rx_gen.rx0/rx_fifo0/U0/inst_fifo_gen/gaxis_fifo.gaxisf.axisf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X11Y25 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[12].tx_gen.tx0/tx_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X11Y26 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[9].rx_gen.rx0/rx_fifo0/U0/inst_fifo_gen/gaxis_fifo.gaxisf.axisf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X11Y27 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[9].tx_gen.tx0/tx_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]





# create_pblock CB03
# resize_pblock [get_pblocks CB03] -add {SLICE_X148Y200:SLICE_X189Y234}
# resize_pblock [get_pblocks CB03] -add {DSP48_X10Y80:DSP48_X11Y93}
# resize_pblock [get_pblocks CB03] -add {RAMB18_X9Y80:RAMB18_X11Y93}
# resize_pblock [get_pblocks CB03] -add {RAMB36_X9Y40:RAMB36_X11Y46}
# set_property IS_SOFT FALSE [get_pblocks CB03]
# add_cells_to_pblock [get_pblocks CB03] [get_cells -quiet {{chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[12].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[13].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[14].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/quad_gen[12].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/quad_gen[13].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/quad_gen[14].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/rx_gen[12].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/rx_gen[13].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/rx_gen[14].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/tx_gen[12].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/tx_gen[13].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/tx_gen[14].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[13]*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[14]*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[15]*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[13].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[14].*} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[15].*}}]
# ---------------------------------------------------------------------------
# CB03 BRAM/FIFO LOC (replaces pblock RAMB18 range)
# FIFO18E1 (sngfifo18e1) -> lower half of RAMB36 only (left cols). RAMB18E1 -> left cols; lane_gen -> rightmost col X11
# ---------------------------------------------------------------------------
# FIFO18E1 (sngfifo18e1) - lower half of RAMB36, left column (X9)
set_property LOC RAMB18_X9Y80 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[13].binsel_i/data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X9Y82 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[14].binsel_i/data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X9Y84 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[15].binsel_i/data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]

# RAMB18E1 - chan_crossbar (left column X9)
set_property LOC RAMB18_X9Y81 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[13].binsel_i/data_flags_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y83 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[13].binsel_i/mask_ram0/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM18.ram}]
set_property LOC RAMB18_X9Y85 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[14].binsel_i/data_flags_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y86 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[14].binsel_i/mask_ram0/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM18.ram}]
set_property LOC RAMB18_X9Y87 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[15].binsel_i/data_flags_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y88 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.chan_crossbar0/bin_sel_gen[15].binsel_i/mask_ram0/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM18.ram}]

# RAMB18E1 - bp_shuffle lane_gen (rightmost column X11)
set_property LOC RAMB18_X10Y80 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[13].rx_gen.rx0/rx_fifo0/U0/inst_fifo_gen/gaxis_fifo.gaxisf.axisf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X10Y81 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[13].tx_gen.tx0/tx_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X10Y82 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[14].rx_gen.rx0/rx_fifo0/U0/inst_fifo_gen/gaxis_fifo.gaxisf.axisf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X10Y83 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[14].tx_gen.tx0/tx_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X10Y84 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[15].rx_gen.rx0/rx_fifo0/U0/inst_fifo_gen/gaxis_fifo.gaxisf.axisf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X10Y85 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[15].tx_gen.tx0/tx_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]


# create_pblock CB30
# resize_pblock [get_pblocks CB30] -add {SLICE_X148Y250:SLICE_X165Y274}
# resize_pblock [get_pblocks CB30] -add {DSP48_X10Y100:DSP48_X10Y109}
# resize_pblock [get_pblocks CB30] -add {RAMB18_X9Y100:RAMB18_X10Y109}
# resize_pblock [get_pblocks CB30] -add {RAMB36_X9Y50:RAMB36_X10Y54}
# set_property IS_SOFT FALSE [get_pblocks CB30]
#add_cells_to_pblock [get_pblocks CB30] [get_cells -quiet [list {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[0].binsel_i} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[1].binsel_i}]]
# ---------------------------------------------------------------------------
# CB30 BRAM/FIFO LOC (replaces pblock RAMB18 range)
# crossbar3 bin_sel_gen[0,1]. FIFO18E1 (sngfifo18e1) -> lower half (even Y); RAMB18E1 -> odd Y / rest
# Range: RAMB18_X9Y100:RAMB18_X10Y109
# ---------------------------------------------------------------------------
# FIFO18E1 (sngfifo18e1) - lower half of RAMB36 only (even Y)
set_property LOC RAMB18_X9Y100 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[0].binsel_i/data_fifo_gen[1].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X9Y102 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[0].binsel_i/data_fifo_gen[3].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X9Y104 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[0].binsel_i/data_fifo_gen[5].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X9Y106 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[0].binsel_i/data_fifo_gen[7].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X9Y108 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[1].binsel_i/data_fifo_gen[1].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X10Y100 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[1].binsel_i/data_fifo_gen[3].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X10Y102 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[1].binsel_i/data_fifo_gen[5].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X10Y104 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[1].binsel_i/data_fifo_gen[7].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]

# RAMB18E1 - bram_fifo (WIDE_PRIM18) and mask_ram (SIMPLE_PRIM18)
set_property LOC RAMB18_X9Y101 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[0].binsel_i/data_fifo_gen[0].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y103 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[0].binsel_i/data_fifo_gen[2].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y105 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[0].binsel_i/data_fifo_gen[4].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y107 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[0].binsel_i/data_fifo_gen[6].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y109 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[0].binsel_i/mask_ram0/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM18.ram}]
set_property LOC RAMB18_X10Y101 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[1].binsel_i/data_fifo_gen[0].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X10Y103 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[1].binsel_i/data_fifo_gen[2].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X10Y105 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[1].binsel_i/data_fifo_gen[4].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X10Y107 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[1].binsel_i/data_fifo_gen[6].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X10Y109 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[1].binsel_i/mask_ram0/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM18.ram}]




# create_pblock CB31
# resize_pblock [get_pblocks CB31] -add {SLICE_X166Y290:SLICE_X189Y309}
# resize_pblock [get_pblocks CB31] -add {DSP48_X11Y116:DSP48_X11Y123}
# resize_pblock [get_pblocks CB31] -add {RAMB18_X11Y116:RAMB18_X11Y123 RAMB18_X10Y110:RAMB18_X10Y121}
# resize_pblock [get_pblocks CB31] -add {RAMB36_X11Y58:RAMB36_X11Y61 RAMB36_X10Y55:RAMB36_X10Y60}
# set_property IS_SOFT FALSE [get_pblocks CB31]
#add_cells_to_pblock [get_pblocks CB31] [get_cells -quiet [list {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[2].binsel_i} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[3].binsel_i}]]
# ---------------------------------------------------------------------------
# CB31 BRAM/FIFO LOC (replaces pblock RAMB18 range)
# crossbar3 bin_sel_gen[2,3]. FIFO18E1 (sngfifo18e1) -> lower half (even Y); RAMB18E1 -> odd Y / rest
# Range: RAMB18_X11Y116:X11Y123, RAMB18_X10Y110:X10Y121
# ---------------------------------------------------------------------------
# FIFO18E1 (sngfifo18e1) - lower half of RAMB36 only (even Y)
set_property LOC RAMB18_X11Y116 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[2].binsel_i/data_fifo_gen[1].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X11Y118 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[2].binsel_i/data_fifo_gen[3].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X11Y120 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[2].binsel_i/data_fifo_gen[5].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X11Y122 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[2].binsel_i/data_fifo_gen[7].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X10Y110 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[3].binsel_i/data_fifo_gen[1].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X10Y112 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[3].binsel_i/data_fifo_gen[3].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X10Y114 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[3].binsel_i/data_fifo_gen[5].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X10Y116 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[3].binsel_i/data_fifo_gen[7].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]

# RAMB18E1 - bram_fifo (WIDE_PRIM18) and mask_ram (SIMPLE_PRIM18)
set_property LOC RAMB18_X11Y117 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[2].binsel_i/data_fifo_gen[0].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X11Y119 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[2].binsel_i/data_fifo_gen[2].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X11Y121 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[2].binsel_i/data_fifo_gen[4].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X11Y123 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[2].binsel_i/data_fifo_gen[6].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X10Y111 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[2].binsel_i/mask_ram0/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM18.ram}]
set_property LOC RAMB18_X10Y113 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[3].binsel_i/data_fifo_gen[0].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X10Y115 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[3].binsel_i/data_fifo_gen[2].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X10Y117 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[3].binsel_i/data_fifo_gen[4].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X10Y119 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[3].binsel_i/data_fifo_gen[6].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X10Y121 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[3].binsel_i/mask_ram0/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM18.ram}]




# create_pblock CB32
# resize_pblock [get_pblocks CB32] -add {SLICE_X148Y305:SLICE_X165Y334}
# resize_pblock [get_pblocks CB32] -add {DSP48_X10Y122:DSP48_X10Y133}
# resize_pblock [get_pblocks CB32] -add {RAMB18_X9Y122:RAMB18_X10Y133}
# resize_pblock [get_pblocks CB32] -add {RAMB36_X9Y61:RAMB36_X10Y66}
# set_property IS_SOFT FALSE [get_pblocks CB32]
#add_cells_to_pblock [get_pblocks CB32] [get_cells -quiet [list {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[4].binsel_i} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[5].binsel_i}]]
# ---------------------------------------------------------------------------
# CB32 BRAM/FIFO LOC (replaces pblock RAMB18 range)
# crossbar3 bin_sel_gen[4,5]. FIFO18E1 (sngfifo18e1) -> lower half (even Y); RAMB18E1 -> odd Y / rest
# Range: RAMB18_X9Y122:RAMB18_X10Y133
# ---------------------------------------------------------------------------
# FIFO18E1 (sngfifo18e1) - lower half of RAMB36 only (even Y)
set_property LOC RAMB18_X9Y122 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[4].binsel_i/data_fifo_gen[1].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X9Y124 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[4].binsel_i/data_fifo_gen[3].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X9Y126 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[4].binsel_i/data_fifo_gen[5].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X9Y128 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[4].binsel_i/data_fifo_gen[7].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X10Y122 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[5].binsel_i/data_fifo_gen[1].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X10Y124 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[5].binsel_i/data_fifo_gen[3].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X10Y126 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[5].binsel_i/data_fifo_gen[5].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X10Y128 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[5].binsel_i/data_fifo_gen[7].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]

# RAMB18E1 - bram_fifo (WIDE_PRIM18) and mask_ram (SIMPLE_PRIM18)
set_property LOC RAMB18_X9Y123 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[4].binsel_i/data_fifo_gen[0].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y125 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[4].binsel_i/data_fifo_gen[2].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y127 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[4].binsel_i/data_fifo_gen[4].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y129 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[4].binsel_i/data_fifo_gen[6].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y131 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[4].binsel_i/mask_ram0/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM18.ram}]
set_property LOC RAMB18_X10Y123 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[5].binsel_i/data_fifo_gen[0].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X10Y125 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[5].binsel_i/data_fifo_gen[2].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X10Y127 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[5].binsel_i/data_fifo_gen[4].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X10Y129 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[5].binsel_i/data_fifo_gen[6].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X10Y131 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[5].binsel_i/mask_ram0/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM18.ram}]



# create_pblock CB33
# resize_pblock [get_pblocks CB33] -add {SLICE_X148Y335:SLICE_X165Y359}
# resize_pblock [get_pblocks CB33] -add {DSP48_X10Y134:DSP48_X10Y143}
# resize_pblock [get_pblocks CB33] -add {RAMB18_X9Y134:RAMB18_X10Y143}
# resize_pblock [get_pblocks CB33] -add {RAMB36_X9Y67:RAMB36_X10Y71}
# set_property IS_SOFT FALSE [get_pblocks CB33]
#add_cells_to_pblock [get_pblocks CB33] [get_cells -quiet [list {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[6].binsel_i} {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[7].binsel_i}]]
# ---------------------------------------------------------------------------
# CB33 BRAM/FIFO LOC (replaces pblock RAMB18 range)
# crossbar3 bin_sel_gen[6,7]. FIFO18E1 (sngfifo18e1) -> lower half (even Y); RAMB18E1 -> odd Y / rest
# Range: RAMB18_X9Y134:RAMB18_X10Y143
# ---------------------------------------------------------------------------
# FIFO18E1 (sngfifo18e1) - lower half of RAMB36 only (even Y)
set_property LOC RAMB18_X9Y134 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[6].binsel_i/data_fifo_gen[1].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X9Y136 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[6].binsel_i/data_fifo_gen[3].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X9Y138 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[6].binsel_i/data_fifo_gen[5].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X9Y140 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[6].binsel_i/data_fifo_gen[7].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X10Y134 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[7].binsel_i/data_fifo_gen[1].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X10Y136 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[7].binsel_i/data_fifo_gen[3].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X10Y138 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[7].binsel_i/data_fifo_gen[5].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]
set_property LOC RAMB18_X10Y140 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[7].binsel_i/data_fifo_gen[7].embed_fifo_gen.data_fifo_k7.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/gbi.bi/v7_bi_fifo.fblk/gextw[1].gnll_fifo.inst_extd/gonep.inst_prim/gf18e1_inst.sngfifo18e1}]

# RAMB18E1 - bram_fifo (WIDE_PRIM18) and mask_ram (SIMPLE_PRIM18)
set_property LOC RAMB18_X9Y135 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[6].binsel_i/data_fifo_gen[0].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y137 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[6].binsel_i/data_fifo_gen[2].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y139 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[6].binsel_i/data_fifo_gen[4].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y141 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[6].binsel_i/data_fifo_gen[6].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y143 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[6].binsel_i/mask_ram0/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM18.ram}]
set_property LOC RAMB18_X10Y135 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[7].binsel_i/data_fifo_gen[0].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X10Y137 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[7].binsel_i/data_fifo_gen[2].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X10Y139 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[7].binsel_i/data_fifo_gen[4].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X10Y141 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[7].binsel_i/data_fifo_gen[6].bram_fifo_gen.data_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X10Y143 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bin_sel_gen[7].binsel_i/mask_ram0/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM18.ram}]



# create_pblock ALIGN3
# add_cells_to_pblock [get_pblocks ALIGN3] [get_cells -quiet [list chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/align0 chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/bsb_regs0 chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/crossbar_router0 chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar3/remap0]]
# resize_pblock [get_pblocks ALIGN3] -add {SLICE_X148Y275:SLICE_X165Y304}
# resize_pblock [get_pblocks ALIGN3] -add {DSP48_X10Y110:DSP48_X10Y121}
# resize_pblock [get_pblocks ALIGN3] -add {RAMB18_X9Y110:RAMB18_X9Y121}
# resize_pblock [get_pblocks ALIGN3] -add {RAMB36_X9Y55:RAMB36_X9Y60}
#set_property IS_SOFT FALSE [get_pblocks ALIGN3]

# create_pblock CB10
# resize_pblock [get_pblocks CB10] -add {SLICE_X144Y85:SLICE_X189Y149}
# resize_pblock [get_pblocks CB10] -add {DSP48_X10Y34:DSP48_X11Y59}
# resize_pblock [get_pblocks CB10] -add {RAMB18_X9Y34:RAMB18_X11Y59}
# resize_pblock [get_pblocks CB10] -add {RAMB36_X9Y17:RAMB36_X11Y29}
#add_cells_to_pblock [get_pblocks CB10] [get_cells -quiet [list #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[15].gt_regs0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[15].gt_rxresetfsm_i} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[15].gtx_i} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[16].gt_regs0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[16].gt_rxresetfsm_i} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[16].gtx_i} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[17].gt_regs0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[17].gt_rxresetfsm_i} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[17].gtx_i} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[18].gt_regs0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[18].gt_rxresetfsm_i} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/gtx_gen[18].gtx_i} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/rx_gen[15].block_sync0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/rx_gen[15].descrambler0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/rx_gen[16].block_sync0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/rx_gen[16].descrambler0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/rx_gen[17].block_sync0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/rx_gen[17].descrambler0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/rx_gen[18].block_sync0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/rx_gen[18].descrambler0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/tx_gen[15].gt_txresetfsm} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/tx_gen[15].scrambler0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/tx_gen[16].gt_txresetfsm} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/tx_gen[16].scrambler0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/tx_gen[17].gt_txresetfsm} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/tx_gen[17].scrambler0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/tx_gen[18].gt_txresetfsm} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/core0/tx_gen[18].scrambler0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[16].direct_gen.direct0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[17].direct_gen.direct0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[18].direct_gen.direct0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[19].direct_gen.direct0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[20].rx_gen.rx0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[20].tx_gen.tx0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[21].rx_gen.rx0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[21].tx_gen.tx0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[22].rx_gen.rx0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[22].tx_gen.tx0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[23].rx_gen.rx0} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[23].tx_gen.tx0} #          chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar2/align0 #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar2/bin_sel_gen[0].binsel_i} #          {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar2/bin_sel_gen[1].binsel_i}]]
#set_property IS_SOFT FALSE [get_pblocks CB10]
# ---------------------------------------------------------------------------
# CB10 BRAM/FIFO LOC (replaces pblock RAMB18 range)
# All RAMB18E1 (no FIFO18). lane_gen[16-23] -> rightmost col X11; crossbar2/align0/fifogen -> left cols X9/X10
# Range: RAMB18_X9Y34:RAMB18_X11Y59
# ---------------------------------------------------------------------------
# RAMB18E1 - bp_shuffle lane_gen[16-23] (rightmost column X11)
set_property LOC RAMB18_X11Y34 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[16].direct_gen.direct0/rx_fifo0/U0/inst_fifo_gen/gaxis_fifo.gaxisf.axisf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X11Y35 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[16].direct_gen.direct0/tx_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X11Y36 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[17].direct_gen.direct0/rx_fifo0/U0/inst_fifo_gen/gaxis_fifo.gaxisf.axisf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X11Y37 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[17].direct_gen.direct0/tx_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X11Y38 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[18].direct_gen.direct0/rx_fifo0/U0/inst_fifo_gen/gaxis_fifo.gaxisf.axisf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X11Y39 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[18].direct_gen.direct0/tx_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X11Y40 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[19].direct_gen.direct0/rx_fifo0/U0/inst_fifo_gen/gaxis_fifo.gaxisf.axisf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X11Y41 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[19].direct_gen.direct0/tx_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X11Y42 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[20].rx_gen.rx0/rx_fifo0/U0/inst_fifo_gen/gaxis_fifo.gaxisf.axisf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X11Y43 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[20].tx_gen.tx0/tx_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X11Y44 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[21].rx_gen.rx0/rx_fifo0/U0/inst_fifo_gen/gaxis_fifo.gaxisf.axisf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X11Y45 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[21].tx_gen.tx0/tx_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X11Y46 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[22].rx_gen.rx0/rx_fifo0/U0/inst_fifo_gen/gaxis_fifo.gaxisf.axisf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X11Y47 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[22].tx_gen.tx0/tx_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X11Y48 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[23].rx_gen.rx0/rx_fifo0/U0/inst_fifo_gen/gaxis_fifo.gaxisf.axisf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X11Y49 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.bp_shuffle0/lane_gen[23].tx_gen.tx0/tx_fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]

# RAMB18E1 - crossbar2/align0/fifogen (left columns X9, X10)
set_property LOC RAMB18_X9Y34 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar2/align0/fifogen[0].fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y35 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar2/align0/fifogen[10].fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y36 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar2/align0/fifogen[11].fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y37 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar2/align0/fifogen[12].fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y38 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar2/align0/fifogen[13].fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y39 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar2/align0/fifogen[14].fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y40 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar2/align0/fifogen[15].fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y41 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar2/align0/fifogen[1].fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]
set_property LOC RAMB18_X9Y42 [get_cells {chfpga0/ct_gen.ct_case.bct_case.ct0/crossbar0_gen.crossbar2/align0/fifogen[2].fifo0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.WIDE_PRIM18.ram}]


