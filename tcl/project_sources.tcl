#*****************************************************************************************
# Vivado (TM) v2022.2 (64-bit)
#
# Defines a number of filesets to be used to create projects
#
#
#*****************************************************************************************


# directives
set no_lc "1"


# List of files used in this project

# Set the repo directory to access files outside of the project dir
# We assume we are two levels down from the repo root, e.g. repo_dir/xilinx_projects/my_project_name/.
set repo_dir [file normalize "../../"]


set bd_dir "${repo_dir}/hdl/TCPIPE"
set ip_dir "${repo_dir}/_Cores/"
set hdl_dir "${repo_dir}/hdl/"
set const_dir "${repo_dir}/constraints/"
set bd_name ""

set hdl_base_files [list  \
 "chfpga_package.vhd" \
 "chfpga.vhd" \
 "bsb/axis_sync_fifo.vhd" \
 "bsb/bsb_sync_fifo.vhd" \
 "bsb/bsb_router.vhd" \
 "bsb/bsb_regs.vhd" \
 "bsb/bsb_async_fifo.vhd" \
 "bsb/bsb_master.vhd" \
 "system/irigb_package.vhd" \
 "system/core_registers.vhd" \
 "system/irigb_decoder.vhd" \
 "system/irigb_comparator.vhd" \
 "system/irigb_encoder.vhd" \
 "system/system.vhd" \
 "system/gpio.vhd" \
 "system/freq_ctr.vhd" \
 "system/refclk.vhd" \
 "system/sysmon.vhd" \
 "system/blinker.vhd" \
 "system/clocks.vhd" \
 "chan/chan.vhd" \
 "chan/chan_array.vhd" \
 "chan/lfsr.vhd" \
 "chan/funcgen.vhd" \
 "chan/fft_delay.vhd" \
 "chan/fft.vhd" \
 "chan/scaler_mul.vhd" \
 "chan/scaler.vhd" \
 "chan/chan_fifo.vhd" \
 ]



set fft_type_chime "KC705/FFT2/FFT2.xci"
set fft_type_hirax "KC705/hirax_bit_growth_0/hirax_bit_growth_0.xci"
set fft_type_chord "CRS/pfb_fft_bitgrowth_0/pfb_fft_bitgrowth_0.xci"

#*****************************************************************************************
# ICE Platform
#*****************************************************************************************


set ice_target_part "xc7k420tffg901-2"

set ice_ct_ooc_ip_files $fft_type_hirax
set ice_corr16_ooc_ip_files $fft_type_chime

# KC705/SCALER_CMUL/SCALER_CMUL.xci to be added if using complex gains

set ice_base_ip_files [list \
  "KC705/ADCDAQ_FIFO/ADCDAQ_FIFO.xci" \
  "KC705/udp_mac_tx_frame_fifo/udp_mac_tx_frame_fifo.xci" \
  "KC705/UDP_MAC_TX_DATA_FIFO/udp_mac_tx_data_fifo.xci" \
  "KC705/gmii_to_sgmii_bridge/gmii_to_sgmii_bridge.xci"\
]

set ice_ct_ip_files [concat $ice_base_ip_files [list \
  "KC705/SHUFFLE_BIN_SEL_FLAGS_FIFO4/SHUFFLE_BIN_SEL_FLAGS_FIFO4.xci" \
  "KC705/SHUFFLE_BIN_SEL_DATA_FIFO_EMBED/SHUFFLE_BIN_SEL_DATA_FIFO_EMBED.xci" \
  "KC705/SHUFFLE_BIN_SEL_DATA_FIFO_BRAM/SHUFFLE_BIN_SEL_DATA_FIFO_BRAM.xci" \
  "KC705/SHUFFLE_BIN_SEL_FLAGS_FIFO6/SHUFFLE_BIN_SEL_FLAGS_FIFO6.xci" \
  "KC705/SHUFFLE_BIN_SEL_MASK_RAM/SHUFFLE_BIN_SEL_MASK_RAM.xci" \
  "KC705/SHUFFLE_CROSSBAR_ALIGN_FIFO/SHUFFLE_CROSSBAR_ALIGN_FIFO.xci" \
  "KC705/XGLINK_RX_DATA_FIFO/XGLINK_RX_DATA_FIFO.xci" \
  "KC705/XGLINK_TX_DATA_FIFO/XGLINK_TX_DATA_FIFO.xci" \
  "KC705/CHDIST_FRAME_FIFO/CHDIST_FRAME_FIFO.xci" \
  "KC705/CHDIST_SCALER_FLAGS_FIFO/CHDIST_SCALER_FLAGS_FIFO.xci" \
  "KC705/CHDIST_DATA_EMBED_FIFO/CHDIST_DATA_EMBED_FIFO.xci" \
  "KC705/MASK_RAM/MASK_RAM.xci" \
  "KC705/XG_UDP_MAC_TX_HEADER_FIFO/XGMII_UDP_MAC_TX_HEADER_FIFO.xci" \
  "KC705/XG_UDP_MAC_TX_DATA_FIFO/XGMII_UDP_MAC_TX_DATA_FIFO.xci" \
 ]]

set ice_corr16_ip_files $ice_base_ip_files

#  "KC705/CORR44_DATA_FIFO/CORR44_DATA_FIFO.xci" \



set ice_hdl_base_files [concat $hdl_base_files [list \
  "chfpga_ice.vhd" \
  \
  "system/spi.vhd" \
  "system/i2c.vhd" \
  "system/arm_spi.vhd" \
  \
  "chan/prober.vhd" \
  "chan/adcdaq.vhd" \
  \
  "ct/bct_engine.vhd"\
  \
  "1G_UDP_MAC/udp_mac_crc32.vhd" \
  "1G_UDP_MAC/udp_mac_tx.vhd" \
  "1G_UDP_MAC/udp_mac_rx.vhd" \
  "1G_UDP_MAC/udp_mac_gmii_to_sgmii.vhd" \
  "1G_UDP_MAC/udp_mac.vhd" \
  ]]


set ice_ct_hdl_files [concat $ice_hdl_base_files [list \
  "ct/align32.vhd"\
  "ct/chan_bin_sel.vhd"\
  "ct/chan_crossbar.vhd"\
  "ct/remap.vhd"\
  "ct/shuffle_bin_sel.vhd"\
  "ct/shuffle_crossbar.vhd"\
  \
  "XGLINK/xglink_bypass.vhd"\
  "XGLINK/xglink_crc32_32.vhd"\
  "XGLINK/xglink_tx.vhd"\
  "XGLINK/xglink_rx.vhd"\
  "XGLINK/xglink_gtx.vhd"\
  "XGLINK/xglink_rx_startup_fsm.vhd"\
  "XGLINK/xglink_tx_startup_fsm.vhd"\
  "XGLINK/xglink_scrambler.vhd"\
  "XGLINK/xglink_block_sync.vhd"\
  "XGLINK/xglink_descrambler.vhd"\
  "XGLINK/xglink_core.vhd"\
  "XGLINK/xglink_array.vhd"\
  "XGLINK/xglink_sync_block.vhd"\
  \
  "10GE_UDP_MAC/xge_udp_mac_tx.vhd" \
  "10GE_UDP_MAC/xge_array.vhd" \
  ]]


set ice_corr16_hdl_files [concat $ice_hdl_base_files [list \
  "corr/UCMAC44_ARRAY.vhd"\
  "corr/UCORR44.vhd"\
  "corr/UCORR44_ARRAY.vhd"\
  ]]


#corr/CMAC44.vhd
#corr/CORR44.vhd
#corr/CORR44_ARRAY.vhd



#*****************************************************************************************
# CRS Platform
#*****************************************************************************************

set crs_target_part "xczu47dr-ffvg1517-1-i"
set crs_bd_name "zynq_tcpipe_crs"

set crs_ooc_ip_files $fft_type_chord

set crs_corr_ip_files [list \
 "CRS/GTY/gtwizard_ultrascale_0.xci" \
 ]

set crs_ct_ip_files [concat [list \
 "CRS/CMAC_USP/CMAC_USP.xci" \
 ]]



set crs_hdl_base_files [concat $hdl_base_files [list \
 "chfpga_crs.vhd" \
 "chan/ucap.vhd" \
 "ct/uct_engine.vhd" \
 ]]


set crs_corr_hdl_files [concat $crs_hdl_base_files [list \
 "ct/align64_fifo.vhd" \
 "ct/align64.vhd" \
 "XXVGLINK/xxvglink_data_fifo.vhd" \
 "XXVGLINK/xxvglink_bypass.vhd" \
 "XXVGLINK/crc32_64.vhd" \
 "XXVGLINK/xxvglink_tx.vhd" \
 "XXVGLINK/xxvglink_rx.vhd" \
 "XXVGLINK/xxvglink_scrambler.vhd" \
 "XXVGLINK/xxvglink_block_sync.vhd" \
 "XXVGLINK/xxvglink_descrambler.vhd" \
 "XXVGLINK/xxvglink_core.vhd" \
 "XXVGLINK/xxvglink_array.vhd" \
 "corr/UCMAC44_ARRAY.vhd" \
 "corr/UCORR44.vhd" \
 "corr/UCORR44_ARRAY.vhd" \
 ]]

set crs_ct_hdl_files [concat $crs_hdl_base_files [list \
  "ct/ucorn.vhd" \
  "100GE_UDP_MAC/cge.vhd"\
  ]]


