#*****************************************************************************************
# Vivado (TM) v2022.2 (64-bit)
#
# Defines a number of filesets to be used to create projects
#
#
#*****************************************************************************************


set crs_bd_name "zynq_tcpipe_crs"

set crs_target_part "xczu47dr-ffvg1517-1-i"
# List of files used in this project

# Set the repo directory to access files outside of the project dir
# We assume we are two levels down from the repo root, e.g. repo_dir/xilinx_projects/my_project_name/.
set repo_dir [file normalize "../../"]


set bd_dir "${repo_dir}/hdl/TCPIPE"
set ip_dir "${repo_dir}/_Cores/"
set hdl_dir "${repo_dir}/hdl/"
set const_dir "${repo_dir}/constraints/"



# set crs ip_repo_path [list $ip_dir]
set crs_ip_files [list \
 "CRS/pfb_fft_bitgrowth_0/pfb_fft_bitgrowth_0.xci" \
 "CRS/GTY/gtwizard_ultrascale_0.xci" \
 ]

# HDL files, found in $repo_dir/hdl/


set crs_top_wrapper_file  "chfpga_crs.vhd"


set hdl_base_files [list  \
 "chfpga_package.vhd" \
 "chfpga.vhd" \
 "CMD/axis_sync_fifo.vhd" \
 "CMD/CMD_SYNC_FIFO.vhd" \
 "CMD/CMD_ROUTER.vhd" \
 "CMD/CMD_SLAVE2.vhd" \
 "CMD/CMD_ASYNC_FIFO.vhd" \
 "CMD/CMD_MASTER.vhd" \
 "CMD/icecore_package.vhd" \
 "CMD/register_array.vhd" \
 "CMD/irigb_decoder.vhd" \
 "CMD/irigb_comparator.vhd" \
 "CMD/irigb_encoder.vhd" \
 "SYSTEM/system.vhd" \
 "SYSTEM/GPIO.vhd" \
 "SYSTEM/FREQ_CTR.vhd" \
 "SYSTEM/REFCLK.vhd" \
 "SYSTEM/SYSMON_V6.vhd" \
 "SYSTEM/blinker.vhd" \
 "SYSTEM/clocks.vhd" \
 "CHAN/chan_package.vhd" \
 "CHAN/CHAN.vhd" \
 "CHAN/LFSR.vhd" \
 "CHAN/FUNCGEN.vhd" \
 "CHAN/SYNC.vhd" \
 "CHAN/FFT.vhd" \
 "CHAN/scaler_mul.vhd" \
 "CHAN/SCALER.vhd" \
 "CHAN/chan_fifo.vhd" \
 ]


set hdl_files [list  \
 "chfpga_package.vhd" \
 "chfpga_crs_corr32_config.vhd" \
 "chfpga.vhd" \
 "chfpga_crs.vhd" \
 "CMD/axis_sync_fifo.vhd" \
 "CMD/CMD_SYNC_FIFO.vhd" \
 "CMD/CMD_ROUTER.vhd" \
 "CMD/CMD_SLAVE2.vhd" \
 "CMD/CMD_ASYNC_FIFO.vhd" \
 "CMD/CMD_MASTER.vhd" \
 "CMD/icecore_package.vhd" \
 "CMD/arm_spi.vhd" \
 "CMD/register_array.vhd" \
 "CMD/irigb_decoder.vhd" \
 "CMD/irigb_comparator.vhd" \
 "CMD/irigb_encoder.vhd" \
 "SYSTEM/system.vhd" \
 "SYSTEM/GPIO.vhd" \
 "SYSTEM/FREQ_CTR.vhd" \
 "SYSTEM/REFCLK.vhd" \
 "SYSTEM/SYSMON_V6.vhd" \
 "SYSTEM/blinker.vhd" \
 "SYSTEM/clocks.vhd" \
 "CHAN/chan_package.vhd" \
 "CHAN/CHAN.vhd" \
 "CHAN/LFSR.vhd" \
 "CHAN/FUNCGEN.vhd" \
 "CHAN/SYNC.vhd" \
 "CHAN/FFT.vhd" \
 "CHAN/scaler_mul.vhd" \
 "CHAN/SCALER.vhd" \
 "CHAN/chan_fifo.vhd" \
 "CHAN/ucap.vhd" \
 "CROSSBAR/uct_engine.vhd" \
 "CROSSBAR/align64_fifo.vhd" \
 "CROSSBAR/ALIGN64.vhd" \
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
 "CORR/UCMAC44_ARRAY.vhd" \
 "CORR/UCORR44.vhd" \
 "CORR/UCORR44_ARRAY.vhd" \
 ]



set crs_hdl_files [concat $hdl_base_files [list \
 "CHAN/ucap.vhd" \
 "CROSSBAR/uct_engine.vhd" \
 ]]


set crs_corr_hdl_files [concat $crs_hdl_files [list \
 "CROSSBAR/align64_fifo.vhd" \
 "CROSSBAR/ALIGN64.vhd" \
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
 "CORR/UCMAC44_ARRAY.vhd" \
 "CORR/UCORR44.vhd" \
 "CORR/UCORR44_ARRAY.vhd" \
 ]]

set crs_ct_hdl_files [concat $crs_hdl_files [list \
  "CROSSBAR/ucorn.vhd" \
  "100GE_UDP_MAC/cge.vhd"\
  ]]


set ice_hdl_files [concat $hdl_base_files [list \
  "CMD/arm_spi.vhd" \
  "CHAN/PROBER.vhd" \
  ]]



