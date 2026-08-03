// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
// Date        : Tue Dec  2 15:31:25 2025
// Host        : twiddlebug running 64-bit Ubuntu 22.04.5 LTS
// Command     : write_verilog -force -mode funcsim
//               /home/vbidula/chfpgalite/_Cores/KC705/gmii_to_sgmii_bridge/gmii_to_sgmii_bridge_sim_netlist.v
// Design      : gmii_to_sgmii_bridge
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7k420tffg901-2
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* EXAMPLE_SIMULATION = "0" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "gig_ethernet_pcs_pma_v16_2_9,Vivado 2022.2" *) 
(* NotValidForBitStream *)
module gmii_to_sgmii_bridge
   (gtrefclk,
    gtrefclk_bufg,
    txp,
    txn,
    rxp,
    rxn,
    resetdone,
    cplllock,
    mmcm_reset,
    txoutclk,
    rxoutclk,
    userclk,
    userclk2,
    rxuserclk,
    rxuserclk2,
    pma_reset,
    mmcm_locked,
    independent_clock_bufg,
    sgmii_clk_r,
    sgmii_clk_f,
    sgmii_clk_en,
    gmii_txd,
    gmii_tx_en,
    gmii_tx_er,
    gmii_rxd,
    gmii_rx_dv,
    gmii_rx_er,
    gmii_isolate,
    configuration_vector,
    an_interrupt,
    an_adv_config_vector,
    an_restart_config,
    speed_is_10_100,
    speed_is_100,
    status_vector,
    reset,
    signal_detect,
    gt0_qplloutclk_in,
    gt0_qplloutrefclk_in);
  input gtrefclk;
  input gtrefclk_bufg;
  output txp;
  output txn;
  input rxp;
  input rxn;
  output resetdone;
  output cplllock;
  output mmcm_reset;
  output txoutclk;
  output rxoutclk;
  input userclk;
  input userclk2;
  input rxuserclk;
  input rxuserclk2;
  input pma_reset;
  input mmcm_locked;
  input independent_clock_bufg;
  output sgmii_clk_r;
  output sgmii_clk_f;
  output sgmii_clk_en;
  input [7:0]gmii_txd;
  input gmii_tx_en;
  input gmii_tx_er;
  output [7:0]gmii_rxd;
  output gmii_rx_dv;
  output gmii_rx_er;
  output gmii_isolate;
  input [4:0]configuration_vector;
  output an_interrupt;
  input [15:0]an_adv_config_vector;
  input an_restart_config;
  input speed_is_10_100;
  input speed_is_100;
  output [15:0]status_vector;
  input reset;
  input signal_detect;
  input gt0_qplloutclk_in;
  input gt0_qplloutrefclk_in;

  wire \<const0> ;
  wire [15:0]an_adv_config_vector;
  wire an_interrupt;
  wire an_restart_config;
  wire [4:0]configuration_vector;
  wire cplllock;
  wire gmii_isolate;
  wire gmii_rx_dv;
  wire gmii_rx_er;
  wire [7:0]gmii_rxd;
  wire gmii_tx_en;
  wire gmii_tx_er;
  wire [7:0]gmii_txd;
  wire gt0_qplloutclk_in;
  wire gt0_qplloutrefclk_in;
  wire gtrefclk;
  wire gtrefclk_bufg;
  wire independent_clock_bufg;
  wire mmcm_locked;
  wire mmcm_reset;
  wire pma_reset;
  wire reset;
  wire resetdone;
  wire rxn;
  wire rxoutclk;
  wire rxp;
  wire rxuserclk;
  wire rxuserclk2;
  wire sgmii_clk_en;
  wire sgmii_clk_f;
  wire sgmii_clk_r;
  wire signal_detect;
  wire speed_is_100;
  wire speed_is_10_100;
  wire [13:0]\^status_vector ;
  wire txn;
  wire txoutclk;
  wire txp;
  wire userclk;
  wire userclk2;
  wire [15:8]NLW_U0_status_vector_UNCONNECTED;

  assign status_vector[15] = \<const0> ;
  assign status_vector[14] = \<const0> ;
  assign status_vector[13:9] = \^status_vector [13:9];
  assign status_vector[8] = \<const0> ;
  assign status_vector[7:0] = \^status_vector [7:0];
  GND GND
       (.G(\<const0> ));
  (* EXAMPLE_SIMULATION = "0" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  gmii_to_sgmii_bridge_block U0
       (.an_adv_config_vector({1'b0,1'b0,1'b0,1'b0,an_adv_config_vector[11],1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .an_interrupt(an_interrupt),
        .an_restart_config(an_restart_config),
        .configuration_vector(configuration_vector),
        .cplllock(cplllock),
        .gmii_isolate(gmii_isolate),
        .gmii_rx_dv(gmii_rx_dv),
        .gmii_rx_er(gmii_rx_er),
        .gmii_rxd(gmii_rxd),
        .gmii_tx_en(gmii_tx_en),
        .gmii_tx_er(gmii_tx_er),
        .gmii_txd(gmii_txd),
        .gt0_qplloutclk_in(gt0_qplloutclk_in),
        .gt0_qplloutrefclk_in(gt0_qplloutrefclk_in),
        .gtrefclk(gtrefclk),
        .gtrefclk_bufg(gtrefclk_bufg),
        .independent_clock_bufg(independent_clock_bufg),
        .mmcm_locked(mmcm_locked),
        .mmcm_reset(mmcm_reset),
        .pma_reset(pma_reset),
        .reset(reset),
        .resetdone(resetdone),
        .rxn(rxn),
        .rxoutclk(rxoutclk),
        .rxp(rxp),
        .rxuserclk(rxuserclk),
        .rxuserclk2(rxuserclk2),
        .sgmii_clk_en(sgmii_clk_en),
        .sgmii_clk_f(sgmii_clk_f),
        .sgmii_clk_r(sgmii_clk_r),
        .signal_detect(signal_detect),
        .speed_is_100(speed_is_100),
        .speed_is_10_100(speed_is_10_100),
        .status_vector({NLW_U0_status_vector_UNCONNECTED[15:14],\^status_vector }),
        .txn(txn),
        .txoutclk(txoutclk),
        .txp(txp),
        .userclk(userclk),
        .userclk2(userclk2));
endmodule

module gmii_to_sgmii_bridge_GTWIZARD
   (cplllock,
    txn,
    txp,
    rxoutclk,
    txoutclk,
    TXBUFSTATUS,
    D,
    mmcm_reset,
    data_in,
    rx_fsm_reset_done_int_reg,
    independent_clock_bufg,
    gtrefclk_bufg,
    gtrefclk,
    rxn,
    rxp,
    gt0_qplloutclk_in,
    gt0_qplloutrefclk_in,
    reset_out,
    reset,
    rxuserclk,
    TXPD,
    userclk,
    RXPD,
    Q,
    gtxe2_i,
    gtxe2_i_0,
    gtxe2_i_1,
    pma_reset,
    gtxe2_i_2,
    gtxe2_i_3,
    mmcm_locked,
    data_out);
  output cplllock;
  output txn;
  output txp;
  output rxoutclk;
  output txoutclk;
  output [0:0]TXBUFSTATUS;
  output [23:0]D;
  output mmcm_reset;
  output data_in;
  output rx_fsm_reset_done_int_reg;
  input independent_clock_bufg;
  input gtrefclk_bufg;
  input gtrefclk;
  input rxn;
  input rxp;
  input gt0_qplloutclk_in;
  input gt0_qplloutrefclk_in;
  input reset_out;
  input reset;
  input rxuserclk;
  input [0:0]TXPD;
  input userclk;
  input [0:0]RXPD;
  input [15:0]Q;
  input [1:0]gtxe2_i;
  input [1:0]gtxe2_i_0;
  input [1:0]gtxe2_i_1;
  input pma_reset;
  input gtxe2_i_2;
  input gtxe2_i_3;
  input mmcm_locked;
  input data_out;

  wire [23:0]D;
  wire [15:0]Q;
  wire [0:0]RXPD;
  wire [0:0]TXBUFSTATUS;
  wire [0:0]TXPD;
  wire cplllock;
  wire data_in;
  wire data_out;
  wire gt0_qplloutclk_in;
  wire gt0_qplloutrefclk_in;
  wire gtrefclk;
  wire gtrefclk_bufg;
  wire [1:0]gtxe2_i;
  wire [1:0]gtxe2_i_0;
  wire [1:0]gtxe2_i_1;
  wire gtxe2_i_2;
  wire gtxe2_i_3;
  wire independent_clock_bufg;
  wire mmcm_locked;
  wire mmcm_reset;
  wire pma_reset;
  wire reset;
  wire reset_out;
  wire rx_fsm_reset_done_int_reg;
  wire rxn;
  wire rxoutclk;
  wire rxp;
  wire rxuserclk;
  wire txn;
  wire txoutclk;
  wire txp;
  wire userclk;

  gmii_to_sgmii_bridge_GTWIZARD_init U0
       (.D(D),
        .Q(Q),
        .RXPD(RXPD),
        .TXBUFSTATUS(TXBUFSTATUS),
        .TXPD(TXPD),
        .cplllock(cplllock),
        .data_in(data_in),
        .data_out(data_out),
        .gt0_qplloutclk_in(gt0_qplloutclk_in),
        .gt0_qplloutrefclk_in(gt0_qplloutrefclk_in),
        .gtrefclk(gtrefclk),
        .gtrefclk_bufg(gtrefclk_bufg),
        .gtxe2_i(gtxe2_i),
        .gtxe2_i_0(gtxe2_i_0),
        .gtxe2_i_1(gtxe2_i_1),
        .gtxe2_i_2(gtxe2_i_2),
        .gtxe2_i_3(gtxe2_i_3),
        .independent_clock_bufg(independent_clock_bufg),
        .mmcm_locked(mmcm_locked),
        .mmcm_reset(mmcm_reset),
        .pma_reset(pma_reset),
        .reset(reset),
        .reset_out(reset_out),
        .rx_fsm_reset_done_int_reg(rx_fsm_reset_done_int_reg),
        .rxn(rxn),
        .rxoutclk(rxoutclk),
        .rxp(rxp),
        .rxuserclk(rxuserclk),
        .txn(txn),
        .txoutclk(txoutclk),
        .txp(txp),
        .userclk(userclk));
endmodule

module gmii_to_sgmii_bridge_GTWIZARD_GT
   (cplllock,
    gt0_cpllrefclklost_i,
    txn,
    txp,
    rxoutclk,
    gtxe2_i_0,
    txoutclk,
    gtxe2_i_1,
    TXBUFSTATUS,
    D,
    independent_clock_bufg,
    cpll_pd0_i,
    cpllreset_in,
    gtrefclk_bufg,
    gtrefclk,
    SR,
    gt0_gttxreset_in0_out,
    rxn,
    rxp,
    gt0_qplloutclk_in,
    gt0_qplloutrefclk_in,
    reset_out,
    reset,
    gt0_rxuserrdy_t,
    rxuserclk,
    TXPD,
    gt0_txuserrdy_t,
    userclk,
    RXPD,
    Q,
    gtxe2_i_2,
    gtxe2_i_3,
    gtxe2_i_4);
  output cplllock;
  output gt0_cpllrefclklost_i;
  output txn;
  output txp;
  output rxoutclk;
  output gtxe2_i_0;
  output txoutclk;
  output gtxe2_i_1;
  output [0:0]TXBUFSTATUS;
  output [23:0]D;
  input independent_clock_bufg;
  input cpll_pd0_i;
  input cpllreset_in;
  input gtrefclk_bufg;
  input gtrefclk;
  input [0:0]SR;
  input gt0_gttxreset_in0_out;
  input rxn;
  input rxp;
  input gt0_qplloutclk_in;
  input gt0_qplloutrefclk_in;
  input reset_out;
  input reset;
  input gt0_rxuserrdy_t;
  input rxuserclk;
  input [0:0]TXPD;
  input gt0_txuserrdy_t;
  input userclk;
  input [0:0]RXPD;
  input [15:0]Q;
  input [1:0]gtxe2_i_2;
  input [1:0]gtxe2_i_3;
  input [1:0]gtxe2_i_4;

  wire [23:0]D;
  wire [15:0]Q;
  wire [0:0]RXPD;
  wire [0:0]SR;
  wire [0:0]TXBUFSTATUS;
  wire [0:0]TXPD;
  wire cpll_pd0_i;
  wire cplllock;
  wire cpllreset_in;
  wire gt0_cpllrefclklost_i;
  wire gt0_gttxreset_in0_out;
  wire gt0_qplloutclk_in;
  wire gt0_qplloutrefclk_in;
  wire gt0_rxuserrdy_t;
  wire gt0_txuserrdy_t;
  wire gtrefclk;
  wire gtrefclk_bufg;
  wire gtxe2_i_0;
  wire gtxe2_i_1;
  wire [1:0]gtxe2_i_2;
  wire [1:0]gtxe2_i_3;
  wire [1:0]gtxe2_i_4;
  wire gtxe2_i_n_0;
  wire gtxe2_i_n_10;
  wire gtxe2_i_n_16;
  wire gtxe2_i_n_170;
  wire gtxe2_i_n_171;
  wire gtxe2_i_n_172;
  wire gtxe2_i_n_173;
  wire gtxe2_i_n_174;
  wire gtxe2_i_n_175;
  wire gtxe2_i_n_176;
  wire gtxe2_i_n_177;
  wire gtxe2_i_n_178;
  wire gtxe2_i_n_179;
  wire gtxe2_i_n_180;
  wire gtxe2_i_n_181;
  wire gtxe2_i_n_182;
  wire gtxe2_i_n_183;
  wire gtxe2_i_n_184;
  wire gtxe2_i_n_27;
  wire gtxe2_i_n_3;
  wire gtxe2_i_n_38;
  wire gtxe2_i_n_39;
  wire gtxe2_i_n_4;
  wire gtxe2_i_n_46;
  wire gtxe2_i_n_47;
  wire gtxe2_i_n_48;
  wire gtxe2_i_n_49;
  wire gtxe2_i_n_50;
  wire gtxe2_i_n_51;
  wire gtxe2_i_n_52;
  wire gtxe2_i_n_53;
  wire gtxe2_i_n_54;
  wire gtxe2_i_n_55;
  wire gtxe2_i_n_56;
  wire gtxe2_i_n_57;
  wire gtxe2_i_n_58;
  wire gtxe2_i_n_59;
  wire gtxe2_i_n_60;
  wire gtxe2_i_n_61;
  wire gtxe2_i_n_81;
  wire gtxe2_i_n_82;
  wire gtxe2_i_n_83;
  wire gtxe2_i_n_84;
  wire gtxe2_i_n_9;
  wire independent_clock_bufg;
  wire reset;
  wire reset_out;
  wire rxn;
  wire rxoutclk;
  wire rxp;
  wire rxuserclk;
  wire txn;
  wire txoutclk;
  wire txp;
  wire userclk;
  wire NLW_gtxe2_i_GTREFCLKMONITOR_UNCONNECTED;
  wire NLW_gtxe2_i_PHYSTATUS_UNCONNECTED;
  wire NLW_gtxe2_i_RXCDRLOCK_UNCONNECTED;
  wire NLW_gtxe2_i_RXCHANBONDSEQ_UNCONNECTED;
  wire NLW_gtxe2_i_RXCHANISALIGNED_UNCONNECTED;
  wire NLW_gtxe2_i_RXCHANREALIGN_UNCONNECTED;
  wire NLW_gtxe2_i_RXCOMINITDET_UNCONNECTED;
  wire NLW_gtxe2_i_RXCOMSASDET_UNCONNECTED;
  wire NLW_gtxe2_i_RXCOMWAKEDET_UNCONNECTED;
  wire NLW_gtxe2_i_RXDATAVALID_UNCONNECTED;
  wire NLW_gtxe2_i_RXDLYSRESETDONE_UNCONNECTED;
  wire NLW_gtxe2_i_RXELECIDLE_UNCONNECTED;
  wire NLW_gtxe2_i_RXHEADERVALID_UNCONNECTED;
  wire NLW_gtxe2_i_RXOUTCLKFABRIC_UNCONNECTED;
  wire NLW_gtxe2_i_RXOUTCLKPCS_UNCONNECTED;
  wire NLW_gtxe2_i_RXPHALIGNDONE_UNCONNECTED;
  wire NLW_gtxe2_i_RXQPISENN_UNCONNECTED;
  wire NLW_gtxe2_i_RXQPISENP_UNCONNECTED;
  wire NLW_gtxe2_i_RXRATEDONE_UNCONNECTED;
  wire NLW_gtxe2_i_RXSTARTOFSEQ_UNCONNECTED;
  wire NLW_gtxe2_i_RXVALID_UNCONNECTED;
  wire NLW_gtxe2_i_TXCOMFINISH_UNCONNECTED;
  wire NLW_gtxe2_i_TXDLYSRESETDONE_UNCONNECTED;
  wire NLW_gtxe2_i_TXGEARBOXREADY_UNCONNECTED;
  wire NLW_gtxe2_i_TXPHALIGNDONE_UNCONNECTED;
  wire NLW_gtxe2_i_TXPHINITDONE_UNCONNECTED;
  wire NLW_gtxe2_i_TXQPISENN_UNCONNECTED;
  wire NLW_gtxe2_i_TXQPISENP_UNCONNECTED;
  wire NLW_gtxe2_i_TXRATEDONE_UNCONNECTED;
  wire [15:0]NLW_gtxe2_i_PCSRSVDOUT_UNCONNECTED;
  wire [7:2]NLW_gtxe2_i_RXCHARISCOMMA_UNCONNECTED;
  wire [7:2]NLW_gtxe2_i_RXCHARISK_UNCONNECTED;
  wire [4:0]NLW_gtxe2_i_RXCHBONDO_UNCONNECTED;
  wire [1:0]NLW_gtxe2_i_RXCLKCORCNT_UNCONNECTED;
  wire [63:16]NLW_gtxe2_i_RXDATA_UNCONNECTED;
  wire [7:2]NLW_gtxe2_i_RXDISPERR_UNCONNECTED;
  wire [2:0]NLW_gtxe2_i_RXHEADER_UNCONNECTED;
  wire [7:2]NLW_gtxe2_i_RXNOTINTABLE_UNCONNECTED;
  wire [4:0]NLW_gtxe2_i_RXPHMONITOR_UNCONNECTED;
  wire [4:0]NLW_gtxe2_i_RXPHSLIPMONITOR_UNCONNECTED;
  wire [2:0]NLW_gtxe2_i_RXSTATUS_UNCONNECTED;
  wire [9:0]NLW_gtxe2_i_TSTOUT_UNCONNECTED;

  (* box_type = "PRIMITIVE" *) 
  GTXE2_CHANNEL #(
    .ALIGN_COMMA_DOUBLE("FALSE"),
    .ALIGN_COMMA_ENABLE(10'b0001111111),
    .ALIGN_COMMA_WORD(2),
    .ALIGN_MCOMMA_DET("TRUE"),
    .ALIGN_MCOMMA_VALUE(10'b1010000011),
    .ALIGN_PCOMMA_DET("TRUE"),
    .ALIGN_PCOMMA_VALUE(10'b0101111100),
    .CBCC_DATA_SOURCE_SEL("DECODED"),
    .CHAN_BOND_KEEP_ALIGN("FALSE"),
    .CHAN_BOND_MAX_SKEW(1),
    .CHAN_BOND_SEQ_1_1(10'b0000000000),
    .CHAN_BOND_SEQ_1_2(10'b0000000000),
    .CHAN_BOND_SEQ_1_3(10'b0000000000),
    .CHAN_BOND_SEQ_1_4(10'b0000000000),
    .CHAN_BOND_SEQ_1_ENABLE(4'b1111),
    .CHAN_BOND_SEQ_2_1(10'b0000000000),
    .CHAN_BOND_SEQ_2_2(10'b0000000000),
    .CHAN_BOND_SEQ_2_3(10'b0000000000),
    .CHAN_BOND_SEQ_2_4(10'b0000000000),
    .CHAN_BOND_SEQ_2_ENABLE(4'b1111),
    .CHAN_BOND_SEQ_2_USE("FALSE"),
    .CHAN_BOND_SEQ_LEN(1),
    .CLK_CORRECT_USE("FALSE"),
    .CLK_COR_KEEP_IDLE("FALSE"),
    .CLK_COR_MAX_LAT(36),
    .CLK_COR_MIN_LAT(32),
    .CLK_COR_PRECEDENCE("TRUE"),
    .CLK_COR_REPEAT_WAIT(0),
    .CLK_COR_SEQ_1_1(10'b0100000000),
    .CLK_COR_SEQ_1_2(10'b0000000000),
    .CLK_COR_SEQ_1_3(10'b0000000000),
    .CLK_COR_SEQ_1_4(10'b0000000000),
    .CLK_COR_SEQ_1_ENABLE(4'b1111),
    .CLK_COR_SEQ_2_1(10'b0100000000),
    .CLK_COR_SEQ_2_2(10'b0000000000),
    .CLK_COR_SEQ_2_3(10'b0000000000),
    .CLK_COR_SEQ_2_4(10'b0000000000),
    .CLK_COR_SEQ_2_ENABLE(4'b1111),
    .CLK_COR_SEQ_2_USE("FALSE"),
    .CLK_COR_SEQ_LEN(1),
    .CPLL_CFG(24'hBC07DC),
    .CPLL_FBDIV(4),
    .CPLL_FBDIV_45(5),
    .CPLL_INIT_CFG(24'h00001E),
    .CPLL_LOCK_CFG(16'h01E8),
    .CPLL_REFCLK_DIV(1),
    .DEC_MCOMMA_DETECT("TRUE"),
    .DEC_PCOMMA_DETECT("TRUE"),
    .DEC_VALID_COMMA_ONLY("FALSE"),
    .DMONITOR_CFG(24'h000A00),
    .ES_CONTROL(6'b000000),
    .ES_ERRDET_EN("FALSE"),
    .ES_EYE_SCAN_EN("TRUE"),
    .ES_HORZ_OFFSET(12'h000),
    .ES_PMA_CFG(10'b0000000000),
    .ES_PRESCALE(5'b00000),
    .ES_QUALIFIER(80'h00000000000000000000),
    .ES_QUAL_MASK(80'h00000000000000000000),
    .ES_SDATA_MASK(80'h00000000000000000000),
    .ES_VERT_OFFSET(9'b000000000),
    .FTS_DESKEW_SEQ_ENABLE(4'b1111),
    .FTS_LANE_DESKEW_CFG(4'b1111),
    .FTS_LANE_DESKEW_EN("FALSE"),
    .GEARBOX_MODE(3'b000),
    .IS_CPLLLOCKDETCLK_INVERTED(1'b0),
    .IS_DRPCLK_INVERTED(1'b0),
    .IS_GTGREFCLK_INVERTED(1'b0),
    .IS_RXUSRCLK2_INVERTED(1'b0),
    .IS_RXUSRCLK_INVERTED(1'b0),
    .IS_TXPHDLYTSTCLK_INVERTED(1'b0),
    .IS_TXUSRCLK2_INVERTED(1'b0),
    .IS_TXUSRCLK_INVERTED(1'b0),
    .OUTREFCLK_SEL_INV(2'b11),
    .PCS_PCIE_EN("FALSE"),
    .PCS_RSVD_ATTR(48'h000000000000),
    .PD_TRANS_TIME_FROM_P2(12'h03C),
    .PD_TRANS_TIME_NONE_P2(8'h19),
    .PD_TRANS_TIME_TO_P2(8'h64),
    .PMA_RSV(32'h00018480),
    .PMA_RSV2(16'h2050),
    .PMA_RSV3(2'b00),
    .PMA_RSV4(32'h00000000),
    .RXBUFRESET_TIME(5'b00001),
    .RXBUF_ADDR_MODE("FAST"),
    .RXBUF_EIDLE_HI_CNT(4'b1000),
    .RXBUF_EIDLE_LO_CNT(4'b0000),
    .RXBUF_EN("TRUE"),
    .RXBUF_RESET_ON_CB_CHANGE("TRUE"),
    .RXBUF_RESET_ON_COMMAALIGN("FALSE"),
    .RXBUF_RESET_ON_EIDLE("FALSE"),
    .RXBUF_RESET_ON_RATE_CHANGE("TRUE"),
    .RXBUF_THRESH_OVFLW(61),
    .RXBUF_THRESH_OVRD("FALSE"),
    .RXBUF_THRESH_UNDFLW(8),
    .RXCDRFREQRESET_TIME(5'b00001),
    .RXCDRPHRESET_TIME(5'b00001),
    .RXCDR_CFG(72'h03000023FF10100020),
    .RXCDR_FR_RESET_ON_EIDLE(1'b0),
    .RXCDR_HOLD_DURING_EIDLE(1'b0),
    .RXCDR_LOCK_CFG(6'b010101),
    .RXCDR_PH_RESET_ON_EIDLE(1'b0),
    .RXDFELPMRESET_TIME(7'b0001111),
    .RXDLY_CFG(16'h001F),
    .RXDLY_LCFG(9'h030),
    .RXDLY_TAP_CFG(16'h0000),
    .RXGEARBOX_EN("FALSE"),
    .RXISCANRESET_TIME(5'b00001),
    .RXLPM_HF_CFG(14'b00000011110000),
    .RXLPM_LF_CFG(14'b00000011110000),
    .RXOOB_CFG(7'b0000110),
    .RXOUT_DIV(4),
    .RXPCSRESET_TIME(5'b00001),
    .RXPHDLY_CFG(24'h084020),
    .RXPH_CFG(24'h000000),
    .RXPH_MONITOR_SEL(5'b00000),
    .RXPMARESET_TIME(5'b00011),
    .RXPRBS_ERR_LOOPBACK(1'b0),
    .RXSLIDE_AUTO_WAIT(7),
    .RXSLIDE_MODE("OFF"),
    .RX_BIAS_CFG(12'b000000000100),
    .RX_BUFFER_CFG(6'b000000),
    .RX_CLK25_DIV(5),
    .RX_CLKMUX_PD(1'b1),
    .RX_CM_SEL(2'b11),
    .RX_CM_TRIM(3'b010),
    .RX_DATA_WIDTH(20),
    .RX_DDI_SEL(6'b000000),
    .RX_DEBUG_CFG(12'b000000000000),
    .RX_DEFER_RESET_BUF_EN("TRUE"),
    .RX_DFE_GAIN_CFG(23'h020FEA),
    .RX_DFE_H2_CFG(12'b000000000000),
    .RX_DFE_H3_CFG(12'b000001000000),
    .RX_DFE_H4_CFG(11'b00011110000),
    .RX_DFE_H5_CFG(11'b00011100000),
    .RX_DFE_KL_CFG(13'b0000011111110),
    .RX_DFE_KL_CFG2(32'h301148AC),
    .RX_DFE_LPM_CFG(16'h0904),
    .RX_DFE_LPM_HOLD_DURING_EIDLE(1'b0),
    .RX_DFE_UT_CFG(17'b10001111000000000),
    .RX_DFE_VP_CFG(17'b00011111100000011),
    .RX_DFE_XYD_CFG(13'b0000000000000),
    .RX_DISPERR_SEQ_MATCH("TRUE"),
    .RX_INT_DATAWIDTH(0),
    .RX_OS_CFG(13'b0000010000000),
    .RX_SIG_VALID_DLY(10),
    .RX_XCLK_SEL("RXREC"),
    .SAS_MAX_COM(64),
    .SAS_MIN_COM(36),
    .SATA_BURST_SEQ_LEN(4'b0101),
    .SATA_BURST_VAL(3'b100),
    .SATA_CPLL_CFG("VCO_3000MHZ"),
    .SATA_EIDLE_VAL(3'b100),
    .SATA_MAX_BURST(8),
    .SATA_MAX_INIT(21),
    .SATA_MAX_WAKE(7),
    .SATA_MIN_BURST(4),
    .SATA_MIN_INIT(12),
    .SATA_MIN_WAKE(4),
    .SHOW_REALIGN_COMMA("TRUE"),
    .SIM_CPLLREFCLK_SEL(3'b001),
    .SIM_RECEIVER_DETECT_PASS("TRUE"),
    .SIM_RESET_SPEEDUP("TRUE"),
    .SIM_TX_EIDLE_DRIVE_LEVEL("X"),
    .SIM_VERSION("4.0"),
    .TERM_RCAL_CFG(5'b10000),
    .TERM_RCAL_OVRD(1'b0),
    .TRANS_TIME_RATE(8'h0E),
    .TST_RSV(32'h00000000),
    .TXBUF_EN("TRUE"),
    .TXBUF_RESET_ON_RATE_CHANGE("TRUE"),
    .TXDLY_CFG(16'h001F),
    .TXDLY_LCFG(9'h030),
    .TXDLY_TAP_CFG(16'h0000),
    .TXGEARBOX_EN("FALSE"),
    .TXOUT_DIV(4),
    .TXPCSRESET_TIME(5'b00001),
    .TXPHDLY_CFG(24'h084020),
    .TXPH_CFG(16'h0780),
    .TXPH_MONITOR_SEL(5'b00000),
    .TXPMARESET_TIME(5'b00001),
    .TX_CLK25_DIV(5),
    .TX_CLKMUX_PD(1'b1),
    .TX_DATA_WIDTH(20),
    .TX_DEEMPH0(5'b00000),
    .TX_DEEMPH1(5'b00000),
    .TX_DRIVE_MODE("DIRECT"),
    .TX_EIDLE_ASSERT_DELAY(3'b110),
    .TX_EIDLE_DEASSERT_DELAY(3'b100),
    .TX_INT_DATAWIDTH(0),
    .TX_LOOPBACK_DRIVE_HIZ("FALSE"),
    .TX_MAINCURSOR_SEL(1'b0),
    .TX_MARGIN_FULL_0(7'b1001110),
    .TX_MARGIN_FULL_1(7'b1001001),
    .TX_MARGIN_FULL_2(7'b1000101),
    .TX_MARGIN_FULL_3(7'b1000010),
    .TX_MARGIN_FULL_4(7'b1000000),
    .TX_MARGIN_LOW_0(7'b1000110),
    .TX_MARGIN_LOW_1(7'b1000100),
    .TX_MARGIN_LOW_2(7'b1000010),
    .TX_MARGIN_LOW_3(7'b1000000),
    .TX_MARGIN_LOW_4(7'b1000000),
    .TX_PREDRIVER_MODE(1'b0),
    .TX_QPI_STATUS_EN(1'b0),
    .TX_RXDETECT_CFG(14'h1832),
    .TX_RXDETECT_REF(3'b100),
    .TX_XCLK_SEL("TXOUT"),
    .UCODEER_CLR(1'b0)) 
    gtxe2_i
       (.CFGRESET(1'b0),
        .CLKRSVD({1'b0,1'b0,1'b0,1'b0}),
        .CPLLFBCLKLOST(gtxe2_i_n_0),
        .CPLLLOCK(cplllock),
        .CPLLLOCKDETCLK(independent_clock_bufg),
        .CPLLLOCKEN(1'b1),
        .CPLLPD(cpll_pd0_i),
        .CPLLREFCLKLOST(gt0_cpllrefclklost_i),
        .CPLLREFCLKSEL({1'b0,1'b0,1'b1}),
        .CPLLRESET(cpllreset_in),
        .DMONITOROUT({gtxe2_i_n_177,gtxe2_i_n_178,gtxe2_i_n_179,gtxe2_i_n_180,gtxe2_i_n_181,gtxe2_i_n_182,gtxe2_i_n_183,gtxe2_i_n_184}),
        .DRPADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .DRPCLK(gtrefclk_bufg),
        .DRPDI({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .DRPDO({gtxe2_i_n_46,gtxe2_i_n_47,gtxe2_i_n_48,gtxe2_i_n_49,gtxe2_i_n_50,gtxe2_i_n_51,gtxe2_i_n_52,gtxe2_i_n_53,gtxe2_i_n_54,gtxe2_i_n_55,gtxe2_i_n_56,gtxe2_i_n_57,gtxe2_i_n_58,gtxe2_i_n_59,gtxe2_i_n_60,gtxe2_i_n_61}),
        .DRPEN(1'b0),
        .DRPRDY(gtxe2_i_n_3),
        .DRPWE(1'b0),
        .EYESCANDATAERROR(gtxe2_i_n_4),
        .EYESCANMODE(1'b0),
        .EYESCANRESET(1'b0),
        .EYESCANTRIGGER(1'b0),
        .GTGREFCLK(1'b0),
        .GTNORTHREFCLK0(1'b0),
        .GTNORTHREFCLK1(1'b0),
        .GTREFCLK0(gtrefclk),
        .GTREFCLK1(1'b0),
        .GTREFCLKMONITOR(NLW_gtxe2_i_GTREFCLKMONITOR_UNCONNECTED),
        .GTRESETSEL(1'b0),
        .GTRSVD({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .GTRXRESET(SR),
        .GTSOUTHREFCLK0(1'b0),
        .GTSOUTHREFCLK1(1'b0),
        .GTTXRESET(gt0_gttxreset_in0_out),
        .GTXRXN(rxn),
        .GTXRXP(rxp),
        .GTXTXN(txn),
        .GTXTXP(txp),
        .LOOPBACK({1'b0,1'b0,1'b0}),
        .PCSRSVDIN({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .PCSRSVDIN2({1'b0,1'b0,1'b0,1'b0,1'b0}),
        .PCSRSVDOUT(NLW_gtxe2_i_PCSRSVDOUT_UNCONNECTED[15:0]),
        .PHYSTATUS(NLW_gtxe2_i_PHYSTATUS_UNCONNECTED),
        .PMARSVDIN({1'b0,1'b0,1'b0,1'b0,1'b0}),
        .PMARSVDIN2({1'b0,1'b0,1'b0,1'b0,1'b0}),
        .QPLLCLK(gt0_qplloutclk_in),
        .QPLLREFCLK(gt0_qplloutrefclk_in),
        .RESETOVRD(1'b0),
        .RX8B10BEN(1'b1),
        .RXBUFRESET(1'b0),
        .RXBUFSTATUS({gtxe2_i_n_82,gtxe2_i_n_83,gtxe2_i_n_84}),
        .RXBYTEISALIGNED(gtxe2_i_n_9),
        .RXBYTEREALIGN(gtxe2_i_n_10),
        .RXCDRFREQRESET(1'b0),
        .RXCDRHOLD(1'b0),
        .RXCDRLOCK(NLW_gtxe2_i_RXCDRLOCK_UNCONNECTED),
        .RXCDROVRDEN(1'b0),
        .RXCDRRESET(1'b0),
        .RXCDRRESETRSV(1'b0),
        .RXCHANBONDSEQ(NLW_gtxe2_i_RXCHANBONDSEQ_UNCONNECTED),
        .RXCHANISALIGNED(NLW_gtxe2_i_RXCHANISALIGNED_UNCONNECTED),
        .RXCHANREALIGN(NLW_gtxe2_i_RXCHANREALIGN_UNCONNECTED),
        .RXCHARISCOMMA({NLW_gtxe2_i_RXCHARISCOMMA_UNCONNECTED[7:2],D[11],D[23]}),
        .RXCHARISK({NLW_gtxe2_i_RXCHARISK_UNCONNECTED[7:2],D[10],D[22]}),
        .RXCHBONDEN(1'b0),
        .RXCHBONDI({1'b0,1'b0,1'b0,1'b0,1'b0}),
        .RXCHBONDLEVEL({1'b0,1'b0,1'b0}),
        .RXCHBONDMASTER(1'b0),
        .RXCHBONDO(NLW_gtxe2_i_RXCHBONDO_UNCONNECTED[4:0]),
        .RXCHBONDSLAVE(1'b0),
        .RXCLKCORCNT(NLW_gtxe2_i_RXCLKCORCNT_UNCONNECTED[1:0]),
        .RXCOMINITDET(NLW_gtxe2_i_RXCOMINITDET_UNCONNECTED),
        .RXCOMMADET(gtxe2_i_n_16),
        .RXCOMMADETEN(1'b1),
        .RXCOMSASDET(NLW_gtxe2_i_RXCOMSASDET_UNCONNECTED),
        .RXCOMWAKEDET(NLW_gtxe2_i_RXCOMWAKEDET_UNCONNECTED),
        .RXDATA({NLW_gtxe2_i_RXDATA_UNCONNECTED[63:16],D[7:0],D[19:12]}),
        .RXDATAVALID(NLW_gtxe2_i_RXDATAVALID_UNCONNECTED),
        .RXDDIEN(1'b0),
        .RXDFEAGCHOLD(1'b0),
        .RXDFEAGCOVRDEN(1'b0),
        .RXDFECM1EN(1'b0),
        .RXDFELFHOLD(1'b0),
        .RXDFELFOVRDEN(1'b0),
        .RXDFELPMRESET(1'b0),
        .RXDFETAP2HOLD(1'b0),
        .RXDFETAP2OVRDEN(1'b0),
        .RXDFETAP3HOLD(1'b0),
        .RXDFETAP3OVRDEN(1'b0),
        .RXDFETAP4HOLD(1'b0),
        .RXDFETAP4OVRDEN(1'b0),
        .RXDFETAP5HOLD(1'b0),
        .RXDFETAP5OVRDEN(1'b0),
        .RXDFEUTHOLD(1'b0),
        .RXDFEUTOVRDEN(1'b0),
        .RXDFEVPHOLD(1'b0),
        .RXDFEVPOVRDEN(1'b0),
        .RXDFEVSEN(1'b0),
        .RXDFEXYDEN(1'b1),
        .RXDFEXYDHOLD(1'b0),
        .RXDFEXYDOVRDEN(1'b0),
        .RXDISPERR({NLW_gtxe2_i_RXDISPERR_UNCONNECTED[7:2],D[9],D[21]}),
        .RXDLYBYPASS(1'b1),
        .RXDLYEN(1'b0),
        .RXDLYOVRDEN(1'b0),
        .RXDLYSRESET(1'b0),
        .RXDLYSRESETDONE(NLW_gtxe2_i_RXDLYSRESETDONE_UNCONNECTED),
        .RXELECIDLE(NLW_gtxe2_i_RXELECIDLE_UNCONNECTED),
        .RXELECIDLEMODE({1'b1,1'b1}),
        .RXGEARBOXSLIP(1'b0),
        .RXHEADER(NLW_gtxe2_i_RXHEADER_UNCONNECTED[2:0]),
        .RXHEADERVALID(NLW_gtxe2_i_RXHEADERVALID_UNCONNECTED),
        .RXLPMEN(1'b1),
        .RXLPMHFHOLD(1'b0),
        .RXLPMHFOVRDEN(1'b0),
        .RXLPMLFHOLD(1'b0),
        .RXLPMLFKLOVRDEN(1'b0),
        .RXMCOMMAALIGNEN(reset_out),
        .RXMONITOROUT({gtxe2_i_n_170,gtxe2_i_n_171,gtxe2_i_n_172,gtxe2_i_n_173,gtxe2_i_n_174,gtxe2_i_n_175,gtxe2_i_n_176}),
        .RXMONITORSEL({1'b0,1'b0}),
        .RXNOTINTABLE({NLW_gtxe2_i_RXNOTINTABLE_UNCONNECTED[7:2],D[8],D[20]}),
        .RXOOBRESET(1'b0),
        .RXOSHOLD(1'b0),
        .RXOSOVRDEN(1'b0),
        .RXOUTCLK(rxoutclk),
        .RXOUTCLKFABRIC(NLW_gtxe2_i_RXOUTCLKFABRIC_UNCONNECTED),
        .RXOUTCLKPCS(NLW_gtxe2_i_RXOUTCLKPCS_UNCONNECTED),
        .RXOUTCLKSEL({1'b0,1'b1,1'b0}),
        .RXPCOMMAALIGNEN(reset_out),
        .RXPCSRESET(reset),
        .RXPD({RXPD,RXPD}),
        .RXPHALIGN(1'b0),
        .RXPHALIGNDONE(NLW_gtxe2_i_RXPHALIGNDONE_UNCONNECTED),
        .RXPHALIGNEN(1'b0),
        .RXPHDLYPD(1'b0),
        .RXPHDLYRESET(1'b0),
        .RXPHMONITOR(NLW_gtxe2_i_RXPHMONITOR_UNCONNECTED[4:0]),
        .RXPHOVRDEN(1'b0),
        .RXPHSLIPMONITOR(NLW_gtxe2_i_RXPHSLIPMONITOR_UNCONNECTED[4:0]),
        .RXPMARESET(1'b0),
        .RXPOLARITY(1'b0),
        .RXPRBSCNTRESET(1'b0),
        .RXPRBSERR(gtxe2_i_n_27),
        .RXPRBSSEL({1'b0,1'b0,1'b0}),
        .RXQPIEN(1'b0),
        .RXQPISENN(NLW_gtxe2_i_RXQPISENN_UNCONNECTED),
        .RXQPISENP(NLW_gtxe2_i_RXQPISENP_UNCONNECTED),
        .RXRATE({1'b0,1'b0,1'b0}),
        .RXRATEDONE(NLW_gtxe2_i_RXRATEDONE_UNCONNECTED),
        .RXRESETDONE(gtxe2_i_0),
        .RXSLIDE(1'b0),
        .RXSTARTOFSEQ(NLW_gtxe2_i_RXSTARTOFSEQ_UNCONNECTED),
        .RXSTATUS(NLW_gtxe2_i_RXSTATUS_UNCONNECTED[2:0]),
        .RXSYSCLKSEL({1'b0,1'b0}),
        .RXUSERRDY(gt0_rxuserrdy_t),
        .RXUSRCLK(rxuserclk),
        .RXUSRCLK2(rxuserclk),
        .RXVALID(NLW_gtxe2_i_RXVALID_UNCONNECTED),
        .SETERRSTATUS(1'b0),
        .TSTIN({1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1}),
        .TSTOUT(NLW_gtxe2_i_TSTOUT_UNCONNECTED[9:0]),
        .TX8B10BBYPASS({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .TX8B10BEN(1'b1),
        .TXBUFDIFFCTRL({1'b1,1'b0,1'b0}),
        .TXBUFSTATUS({TXBUFSTATUS,gtxe2_i_n_81}),
        .TXCHARDISPMODE({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,gtxe2_i_2}),
        .TXCHARDISPVAL({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,gtxe2_i_3}),
        .TXCHARISK({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,gtxe2_i_4}),
        .TXCOMFINISH(NLW_gtxe2_i_TXCOMFINISH_UNCONNECTED),
        .TXCOMINIT(1'b0),
        .TXCOMSAS(1'b0),
        .TXCOMWAKE(1'b0),
        .TXDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,Q}),
        .TXDEEMPH(1'b0),
        .TXDETECTRX(1'b0),
        .TXDIFFCTRL({1'b1,1'b0,1'b0,1'b0}),
        .TXDIFFPD(1'b0),
        .TXDLYBYPASS(1'b1),
        .TXDLYEN(1'b0),
        .TXDLYHOLD(1'b0),
        .TXDLYOVRDEN(1'b0),
        .TXDLYSRESET(1'b0),
        .TXDLYSRESETDONE(NLW_gtxe2_i_TXDLYSRESETDONE_UNCONNECTED),
        .TXDLYUPDOWN(1'b0),
        .TXELECIDLE(TXPD),
        .TXGEARBOXREADY(NLW_gtxe2_i_TXGEARBOXREADY_UNCONNECTED),
        .TXHEADER({1'b0,1'b0,1'b0}),
        .TXINHIBIT(1'b0),
        .TXMAINCURSOR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .TXMARGIN({1'b0,1'b0,1'b0}),
        .TXOUTCLK(txoutclk),
        .TXOUTCLKFABRIC(gtxe2_i_n_38),
        .TXOUTCLKPCS(gtxe2_i_n_39),
        .TXOUTCLKSEL({1'b1,1'b0,1'b0}),
        .TXPCSRESET(1'b0),
        .TXPD({TXPD,TXPD}),
        .TXPDELECIDLEMODE(1'b0),
        .TXPHALIGN(1'b0),
        .TXPHALIGNDONE(NLW_gtxe2_i_TXPHALIGNDONE_UNCONNECTED),
        .TXPHALIGNEN(1'b0),
        .TXPHDLYPD(1'b0),
        .TXPHDLYRESET(1'b0),
        .TXPHDLYTSTCLK(1'b0),
        .TXPHINIT(1'b0),
        .TXPHINITDONE(NLW_gtxe2_i_TXPHINITDONE_UNCONNECTED),
        .TXPHOVRDEN(1'b0),
        .TXPISOPD(1'b0),
        .TXPMARESET(1'b0),
        .TXPOLARITY(1'b0),
        .TXPOSTCURSOR({1'b0,1'b0,1'b0,1'b0,1'b0}),
        .TXPOSTCURSORINV(1'b0),
        .TXPRBSFORCEERR(1'b0),
        .TXPRBSSEL({1'b0,1'b0,1'b0}),
        .TXPRECURSOR({1'b0,1'b0,1'b0,1'b0,1'b0}),
        .TXPRECURSORINV(1'b0),
        .TXQPIBIASEN(1'b0),
        .TXQPISENN(NLW_gtxe2_i_TXQPISENN_UNCONNECTED),
        .TXQPISENP(NLW_gtxe2_i_TXQPISENP_UNCONNECTED),
        .TXQPISTRONGPDOWN(1'b0),
        .TXQPIWEAKPUP(1'b0),
        .TXRATE({1'b0,1'b0,1'b0}),
        .TXRATEDONE(NLW_gtxe2_i_TXRATEDONE_UNCONNECTED),
        .TXRESETDONE(gtxe2_i_1),
        .TXSEQUENCE({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .TXSTARTSEQ(1'b0),
        .TXSWING(1'b0),
        .TXSYSCLKSEL({1'b0,1'b0}),
        .TXUSERRDY(gt0_txuserrdy_t),
        .TXUSRCLK(userclk),
        .TXUSRCLK2(userclk));
endmodule

module gmii_to_sgmii_bridge_GTWIZARD_init
   (cplllock,
    txn,
    txp,
    rxoutclk,
    txoutclk,
    TXBUFSTATUS,
    D,
    mmcm_reset,
    data_in,
    rx_fsm_reset_done_int_reg,
    independent_clock_bufg,
    gtrefclk_bufg,
    gtrefclk,
    rxn,
    rxp,
    gt0_qplloutclk_in,
    gt0_qplloutrefclk_in,
    reset_out,
    reset,
    rxuserclk,
    TXPD,
    userclk,
    RXPD,
    Q,
    gtxe2_i,
    gtxe2_i_0,
    gtxe2_i_1,
    pma_reset,
    gtxe2_i_2,
    gtxe2_i_3,
    mmcm_locked,
    data_out);
  output cplllock;
  output txn;
  output txp;
  output rxoutclk;
  output txoutclk;
  output [0:0]TXBUFSTATUS;
  output [23:0]D;
  output mmcm_reset;
  output data_in;
  output rx_fsm_reset_done_int_reg;
  input independent_clock_bufg;
  input gtrefclk_bufg;
  input gtrefclk;
  input rxn;
  input rxp;
  input gt0_qplloutclk_in;
  input gt0_qplloutrefclk_in;
  input reset_out;
  input reset;
  input rxuserclk;
  input [0:0]TXPD;
  input userclk;
  input [0:0]RXPD;
  input [15:0]Q;
  input [1:0]gtxe2_i;
  input [1:0]gtxe2_i_0;
  input [1:0]gtxe2_i_1;
  input pma_reset;
  input gtxe2_i_2;
  input gtxe2_i_3;
  input mmcm_locked;
  input data_out;

  wire [23:0]D;
  wire [15:0]Q;
  wire [0:0]RXPD;
  wire [0:0]TXBUFSTATUS;
  wire [0:0]TXPD;
  wire cplllock;
  wire [13:1]data0;
  wire data_in;
  wire data_out;
  wire gt0_cpllrefclklost_i;
  wire gt0_cpllreset_t;
  wire gt0_gtrxreset_in1_out;
  wire gt0_gttxreset_in0_out;
  wire gt0_qplloutclk_in;
  wire gt0_qplloutrefclk_in;
  wire [13:0]gt0_rx_cdrlock_counter;
  wire gt0_rx_cdrlock_counter0_carry__0_n_0;
  wire gt0_rx_cdrlock_counter0_carry__0_n_1;
  wire gt0_rx_cdrlock_counter0_carry__0_n_2;
  wire gt0_rx_cdrlock_counter0_carry__0_n_3;
  wire gt0_rx_cdrlock_counter0_carry__1_n_0;
  wire gt0_rx_cdrlock_counter0_carry__1_n_1;
  wire gt0_rx_cdrlock_counter0_carry__1_n_2;
  wire gt0_rx_cdrlock_counter0_carry__1_n_3;
  wire gt0_rx_cdrlock_counter0_carry_n_0;
  wire gt0_rx_cdrlock_counter0_carry_n_1;
  wire gt0_rx_cdrlock_counter0_carry_n_2;
  wire gt0_rx_cdrlock_counter0_carry_n_3;
  wire \gt0_rx_cdrlock_counter[0]_i_2_n_0 ;
  wire \gt0_rx_cdrlock_counter[13]_i_2_n_0 ;
  wire \gt0_rx_cdrlock_counter[13]_i_3_n_0 ;
  wire \gt0_rx_cdrlock_counter[13]_i_4_n_0 ;
  wire [13:0]gt0_rx_cdrlock_counter_0;
  wire gt0_rx_cdrlocked_i_1_n_0;
  wire gt0_rx_cdrlocked_reg_n_0;
  wire gt0_rxuserrdy_t;
  wire gt0_txuserrdy_t;
  wire gtrefclk;
  wire gtrefclk_bufg;
  wire gtwizard_i_n_5;
  wire gtwizard_i_n_7;
  wire [1:0]gtxe2_i;
  wire [1:0]gtxe2_i_0;
  wire [1:0]gtxe2_i_1;
  wire gtxe2_i_2;
  wire gtxe2_i_3;
  wire independent_clock_bufg;
  wire mmcm_locked;
  wire mmcm_reset;
  wire pma_reset;
  wire reset;
  wire reset_out;
  wire rx_fsm_reset_done_int_reg;
  wire rxn;
  wire rxoutclk;
  wire rxp;
  wire rxuserclk;
  wire txn;
  wire txoutclk;
  wire txp;
  wire userclk;
  wire [3:0]NLW_gt0_rx_cdrlock_counter0_carry__2_CO_UNCONNECTED;
  wire [3:1]NLW_gt0_rx_cdrlock_counter0_carry__2_O_UNCONNECTED;

  (* ADDER_THRESHOLD = "35" *) 
  CARRY4 gt0_rx_cdrlock_counter0_carry
       (.CI(1'b0),
        .CO({gt0_rx_cdrlock_counter0_carry_n_0,gt0_rx_cdrlock_counter0_carry_n_1,gt0_rx_cdrlock_counter0_carry_n_2,gt0_rx_cdrlock_counter0_carry_n_3}),
        .CYINIT(gt0_rx_cdrlock_counter[0]),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O(data0[4:1]),
        .S(gt0_rx_cdrlock_counter[4:1]));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY4 gt0_rx_cdrlock_counter0_carry__0
       (.CI(gt0_rx_cdrlock_counter0_carry_n_0),
        .CO({gt0_rx_cdrlock_counter0_carry__0_n_0,gt0_rx_cdrlock_counter0_carry__0_n_1,gt0_rx_cdrlock_counter0_carry__0_n_2,gt0_rx_cdrlock_counter0_carry__0_n_3}),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O(data0[8:5]),
        .S(gt0_rx_cdrlock_counter[8:5]));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY4 gt0_rx_cdrlock_counter0_carry__1
       (.CI(gt0_rx_cdrlock_counter0_carry__0_n_0),
        .CO({gt0_rx_cdrlock_counter0_carry__1_n_0,gt0_rx_cdrlock_counter0_carry__1_n_1,gt0_rx_cdrlock_counter0_carry__1_n_2,gt0_rx_cdrlock_counter0_carry__1_n_3}),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O(data0[12:9]),
        .S(gt0_rx_cdrlock_counter[12:9]));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY4 gt0_rx_cdrlock_counter0_carry__2
       (.CI(gt0_rx_cdrlock_counter0_carry__1_n_0),
        .CO(NLW_gt0_rx_cdrlock_counter0_carry__2_CO_UNCONNECTED[3:0]),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({NLW_gt0_rx_cdrlock_counter0_carry__2_O_UNCONNECTED[3:1],data0[13]}),
        .S({1'b0,1'b0,1'b0,gt0_rx_cdrlock_counter[13]}));
  LUT2 #(
    .INIT(4'h2)) 
    \gt0_rx_cdrlock_counter[0]_i_1 
       (.I0(\gt0_rx_cdrlock_counter[0]_i_2_n_0 ),
        .I1(gt0_rx_cdrlock_counter[0]),
        .O(gt0_rx_cdrlock_counter_0[0]));
  LUT6 #(
    .INIT(64'hFFFFFFFFFFFFFFFB)) 
    \gt0_rx_cdrlock_counter[0]_i_2 
       (.I0(\gt0_rx_cdrlock_counter[13]_i_4_n_0 ),
        .I1(gt0_rx_cdrlock_counter[4]),
        .I2(gt0_rx_cdrlock_counter[5]),
        .I3(gt0_rx_cdrlock_counter[7]),
        .I4(gt0_rx_cdrlock_counter[6]),
        .I5(\gt0_rx_cdrlock_counter[13]_i_2_n_0 ),
        .O(\gt0_rx_cdrlock_counter[0]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hFFFF0001)) 
    \gt0_rx_cdrlock_counter[10]_i_1 
       (.I0(\gt0_rx_cdrlock_counter[13]_i_2_n_0 ),
        .I1(\gt0_rx_cdrlock_counter[13]_i_3_n_0 ),
        .I2(\gt0_rx_cdrlock_counter[13]_i_4_n_0 ),
        .I3(gt0_rx_cdrlock_counter[0]),
        .I4(data0[10]),
        .O(gt0_rx_cdrlock_counter_0[10]));
  LUT5 #(
    .INIT(32'hFFFE0000)) 
    \gt0_rx_cdrlock_counter[11]_i_1 
       (.I0(\gt0_rx_cdrlock_counter[13]_i_2_n_0 ),
        .I1(\gt0_rx_cdrlock_counter[13]_i_3_n_0 ),
        .I2(\gt0_rx_cdrlock_counter[13]_i_4_n_0 ),
        .I3(gt0_rx_cdrlock_counter[0]),
        .I4(data0[11]),
        .O(gt0_rx_cdrlock_counter_0[11]));
  LUT5 #(
    .INIT(32'hFFFE0000)) 
    \gt0_rx_cdrlock_counter[12]_i_1 
       (.I0(\gt0_rx_cdrlock_counter[13]_i_2_n_0 ),
        .I1(\gt0_rx_cdrlock_counter[13]_i_3_n_0 ),
        .I2(\gt0_rx_cdrlock_counter[13]_i_4_n_0 ),
        .I3(gt0_rx_cdrlock_counter[0]),
        .I4(data0[12]),
        .O(gt0_rx_cdrlock_counter_0[12]));
  LUT5 #(
    .INIT(32'hFFFF0001)) 
    \gt0_rx_cdrlock_counter[13]_i_1 
       (.I0(\gt0_rx_cdrlock_counter[13]_i_2_n_0 ),
        .I1(\gt0_rx_cdrlock_counter[13]_i_3_n_0 ),
        .I2(\gt0_rx_cdrlock_counter[13]_i_4_n_0 ),
        .I3(gt0_rx_cdrlock_counter[0]),
        .I4(data0[13]),
        .O(gt0_rx_cdrlock_counter_0[13]));
  LUT5 #(
    .INIT(32'hFFFFFFEF)) 
    \gt0_rx_cdrlock_counter[13]_i_2 
       (.I0(gt0_rx_cdrlock_counter[1]),
        .I1(gt0_rx_cdrlock_counter[12]),
        .I2(gt0_rx_cdrlock_counter[13]),
        .I3(gt0_rx_cdrlock_counter[3]),
        .I4(gt0_rx_cdrlock_counter[2]),
        .O(\gt0_rx_cdrlock_counter[13]_i_2_n_0 ));
  LUT4 #(
    .INIT(16'hFFFD)) 
    \gt0_rx_cdrlock_counter[13]_i_3 
       (.I0(gt0_rx_cdrlock_counter[4]),
        .I1(gt0_rx_cdrlock_counter[5]),
        .I2(gt0_rx_cdrlock_counter[7]),
        .I3(gt0_rx_cdrlock_counter[6]),
        .O(\gt0_rx_cdrlock_counter[13]_i_3_n_0 ));
  LUT4 #(
    .INIT(16'hFF7F)) 
    \gt0_rx_cdrlock_counter[13]_i_4 
       (.I0(gt0_rx_cdrlock_counter[9]),
        .I1(gt0_rx_cdrlock_counter[8]),
        .I2(gt0_rx_cdrlock_counter[10]),
        .I3(gt0_rx_cdrlock_counter[11]),
        .O(\gt0_rx_cdrlock_counter[13]_i_4_n_0 ));
  LUT5 #(
    .INIT(32'hFFFE0000)) 
    \gt0_rx_cdrlock_counter[1]_i_1 
       (.I0(\gt0_rx_cdrlock_counter[13]_i_2_n_0 ),
        .I1(\gt0_rx_cdrlock_counter[13]_i_3_n_0 ),
        .I2(\gt0_rx_cdrlock_counter[13]_i_4_n_0 ),
        .I3(gt0_rx_cdrlock_counter[0]),
        .I4(data0[1]),
        .O(gt0_rx_cdrlock_counter_0[1]));
  LUT5 #(
    .INIT(32'hFFFE0000)) 
    \gt0_rx_cdrlock_counter[2]_i_1 
       (.I0(\gt0_rx_cdrlock_counter[13]_i_2_n_0 ),
        .I1(\gt0_rx_cdrlock_counter[13]_i_3_n_0 ),
        .I2(\gt0_rx_cdrlock_counter[13]_i_4_n_0 ),
        .I3(gt0_rx_cdrlock_counter[0]),
        .I4(data0[2]),
        .O(gt0_rx_cdrlock_counter_0[2]));
  LUT5 #(
    .INIT(32'hFFFE0000)) 
    \gt0_rx_cdrlock_counter[3]_i_1 
       (.I0(\gt0_rx_cdrlock_counter[13]_i_2_n_0 ),
        .I1(\gt0_rx_cdrlock_counter[13]_i_3_n_0 ),
        .I2(\gt0_rx_cdrlock_counter[13]_i_4_n_0 ),
        .I3(gt0_rx_cdrlock_counter[0]),
        .I4(data0[3]),
        .O(gt0_rx_cdrlock_counter_0[3]));
  LUT5 #(
    .INIT(32'hFFFF0001)) 
    \gt0_rx_cdrlock_counter[4]_i_1 
       (.I0(\gt0_rx_cdrlock_counter[13]_i_2_n_0 ),
        .I1(\gt0_rx_cdrlock_counter[13]_i_3_n_0 ),
        .I2(\gt0_rx_cdrlock_counter[13]_i_4_n_0 ),
        .I3(gt0_rx_cdrlock_counter[0]),
        .I4(data0[4]),
        .O(gt0_rx_cdrlock_counter_0[4]));
  LUT5 #(
    .INIT(32'hFFFE0000)) 
    \gt0_rx_cdrlock_counter[5]_i_1 
       (.I0(\gt0_rx_cdrlock_counter[13]_i_2_n_0 ),
        .I1(\gt0_rx_cdrlock_counter[13]_i_3_n_0 ),
        .I2(\gt0_rx_cdrlock_counter[13]_i_4_n_0 ),
        .I3(gt0_rx_cdrlock_counter[0]),
        .I4(data0[5]),
        .O(gt0_rx_cdrlock_counter_0[5]));
  LUT5 #(
    .INIT(32'hFFFE0000)) 
    \gt0_rx_cdrlock_counter[6]_i_1 
       (.I0(\gt0_rx_cdrlock_counter[13]_i_2_n_0 ),
        .I1(\gt0_rx_cdrlock_counter[13]_i_3_n_0 ),
        .I2(\gt0_rx_cdrlock_counter[13]_i_4_n_0 ),
        .I3(gt0_rx_cdrlock_counter[0]),
        .I4(data0[6]),
        .O(gt0_rx_cdrlock_counter_0[6]));
  LUT5 #(
    .INIT(32'hFFFE0000)) 
    \gt0_rx_cdrlock_counter[7]_i_1 
       (.I0(\gt0_rx_cdrlock_counter[13]_i_2_n_0 ),
        .I1(\gt0_rx_cdrlock_counter[13]_i_3_n_0 ),
        .I2(\gt0_rx_cdrlock_counter[13]_i_4_n_0 ),
        .I3(gt0_rx_cdrlock_counter[0]),
        .I4(data0[7]),
        .O(gt0_rx_cdrlock_counter_0[7]));
  LUT5 #(
    .INIT(32'hFFFF0001)) 
    \gt0_rx_cdrlock_counter[8]_i_1 
       (.I0(\gt0_rx_cdrlock_counter[13]_i_2_n_0 ),
        .I1(\gt0_rx_cdrlock_counter[13]_i_3_n_0 ),
        .I2(\gt0_rx_cdrlock_counter[13]_i_4_n_0 ),
        .I3(gt0_rx_cdrlock_counter[0]),
        .I4(data0[8]),
        .O(gt0_rx_cdrlock_counter_0[8]));
  LUT5 #(
    .INIT(32'hFFFF0001)) 
    \gt0_rx_cdrlock_counter[9]_i_1 
       (.I0(\gt0_rx_cdrlock_counter[13]_i_2_n_0 ),
        .I1(\gt0_rx_cdrlock_counter[13]_i_3_n_0 ),
        .I2(\gt0_rx_cdrlock_counter[13]_i_4_n_0 ),
        .I3(gt0_rx_cdrlock_counter[0]),
        .I4(data0[9]),
        .O(gt0_rx_cdrlock_counter_0[9]));
  FDRE #(
    .INIT(1'b0)) 
    \gt0_rx_cdrlock_counter_reg[0] 
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(gt0_rx_cdrlock_counter_0[0]),
        .Q(gt0_rx_cdrlock_counter[0]),
        .R(gt0_gtrxreset_in1_out));
  FDRE #(
    .INIT(1'b0)) 
    \gt0_rx_cdrlock_counter_reg[10] 
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(gt0_rx_cdrlock_counter_0[10]),
        .Q(gt0_rx_cdrlock_counter[10]),
        .R(gt0_gtrxreset_in1_out));
  FDRE #(
    .INIT(1'b0)) 
    \gt0_rx_cdrlock_counter_reg[11] 
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(gt0_rx_cdrlock_counter_0[11]),
        .Q(gt0_rx_cdrlock_counter[11]),
        .R(gt0_gtrxreset_in1_out));
  FDRE #(
    .INIT(1'b0)) 
    \gt0_rx_cdrlock_counter_reg[12] 
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(gt0_rx_cdrlock_counter_0[12]),
        .Q(gt0_rx_cdrlock_counter[12]),
        .R(gt0_gtrxreset_in1_out));
  FDRE #(
    .INIT(1'b0)) 
    \gt0_rx_cdrlock_counter_reg[13] 
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(gt0_rx_cdrlock_counter_0[13]),
        .Q(gt0_rx_cdrlock_counter[13]),
        .R(gt0_gtrxreset_in1_out));
  FDRE #(
    .INIT(1'b0)) 
    \gt0_rx_cdrlock_counter_reg[1] 
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(gt0_rx_cdrlock_counter_0[1]),
        .Q(gt0_rx_cdrlock_counter[1]),
        .R(gt0_gtrxreset_in1_out));
  FDRE #(
    .INIT(1'b0)) 
    \gt0_rx_cdrlock_counter_reg[2] 
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(gt0_rx_cdrlock_counter_0[2]),
        .Q(gt0_rx_cdrlock_counter[2]),
        .R(gt0_gtrxreset_in1_out));
  FDRE #(
    .INIT(1'b0)) 
    \gt0_rx_cdrlock_counter_reg[3] 
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(gt0_rx_cdrlock_counter_0[3]),
        .Q(gt0_rx_cdrlock_counter[3]),
        .R(gt0_gtrxreset_in1_out));
  FDRE #(
    .INIT(1'b0)) 
    \gt0_rx_cdrlock_counter_reg[4] 
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(gt0_rx_cdrlock_counter_0[4]),
        .Q(gt0_rx_cdrlock_counter[4]),
        .R(gt0_gtrxreset_in1_out));
  FDRE #(
    .INIT(1'b0)) 
    \gt0_rx_cdrlock_counter_reg[5] 
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(gt0_rx_cdrlock_counter_0[5]),
        .Q(gt0_rx_cdrlock_counter[5]),
        .R(gt0_gtrxreset_in1_out));
  FDRE #(
    .INIT(1'b0)) 
    \gt0_rx_cdrlock_counter_reg[6] 
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(gt0_rx_cdrlock_counter_0[6]),
        .Q(gt0_rx_cdrlock_counter[6]),
        .R(gt0_gtrxreset_in1_out));
  FDRE #(
    .INIT(1'b0)) 
    \gt0_rx_cdrlock_counter_reg[7] 
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(gt0_rx_cdrlock_counter_0[7]),
        .Q(gt0_rx_cdrlock_counter[7]),
        .R(gt0_gtrxreset_in1_out));
  FDRE #(
    .INIT(1'b0)) 
    \gt0_rx_cdrlock_counter_reg[8] 
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(gt0_rx_cdrlock_counter_0[8]),
        .Q(gt0_rx_cdrlock_counter[8]),
        .R(gt0_gtrxreset_in1_out));
  FDRE #(
    .INIT(1'b0)) 
    \gt0_rx_cdrlock_counter_reg[9] 
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(gt0_rx_cdrlock_counter_0[9]),
        .Q(gt0_rx_cdrlock_counter[9]),
        .R(gt0_gtrxreset_in1_out));
  LUT5 #(
    .INIT(32'hFFFF0001)) 
    gt0_rx_cdrlocked_i_1
       (.I0(\gt0_rx_cdrlock_counter[13]_i_2_n_0 ),
        .I1(\gt0_rx_cdrlock_counter[13]_i_3_n_0 ),
        .I2(\gt0_rx_cdrlock_counter[13]_i_4_n_0 ),
        .I3(gt0_rx_cdrlock_counter[0]),
        .I4(gt0_rx_cdrlocked_reg_n_0),
        .O(gt0_rx_cdrlocked_i_1_n_0));
  FDRE gt0_rx_cdrlocked_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(gt0_rx_cdrlocked_i_1_n_0),
        .Q(gt0_rx_cdrlocked_reg_n_0),
        .R(gt0_gtrxreset_in1_out));
  gmii_to_sgmii_bridge_RX_STARTUP_FSM gt0_rxresetfsm_i
       (.\FSM_sequential_rx_state_reg[0]_0 (gt0_rx_cdrlocked_reg_n_0),
        .SR(gt0_gtrxreset_in1_out),
        .cplllock(cplllock),
        .data_in(rx_fsm_reset_done_int_reg),
        .data_out(data_out),
        .data_sync_reg1(gtwizard_i_n_5),
        .gt0_rxuserrdy_t(gt0_rxuserrdy_t),
        .gtxe2_i(gtxe2_i_2),
        .independent_clock_bufg(independent_clock_bufg),
        .mmcm_locked(mmcm_locked),
        .pma_reset(pma_reset),
        .rxuserclk(rxuserclk));
  gmii_to_sgmii_bridge_TX_STARTUP_FSM gt0_txresetfsm_i
       (.cplllock(cplllock),
        .data_in(data_in),
        .data_sync_reg1(gtwizard_i_n_7),
        .gt0_cpllrefclklost_i(gt0_cpllrefclklost_i),
        .gt0_cpllreset_t(gt0_cpllreset_t),
        .gt0_gttxreset_in0_out(gt0_gttxreset_in0_out),
        .gt0_txuserrdy_t(gt0_txuserrdy_t),
        .gtxe2_i(gtxe2_i_3),
        .independent_clock_bufg(independent_clock_bufg),
        .mmcm_locked(mmcm_locked),
        .mmcm_reset(mmcm_reset),
        .pma_reset(pma_reset),
        .userclk(userclk));
  gmii_to_sgmii_bridge_GTWIZARD_multi_gt gtwizard_i
       (.D(D),
        .Q(Q),
        .RXPD(RXPD),
        .SR(gt0_gtrxreset_in1_out),
        .TXBUFSTATUS(TXBUFSTATUS),
        .TXPD(TXPD),
        .cplllock(cplllock),
        .gt0_cpllrefclklost_i(gt0_cpllrefclklost_i),
        .gt0_cpllreset_t(gt0_cpllreset_t),
        .gt0_gttxreset_in0_out(gt0_gttxreset_in0_out),
        .gt0_qplloutclk_in(gt0_qplloutclk_in),
        .gt0_qplloutrefclk_in(gt0_qplloutrefclk_in),
        .gt0_rxuserrdy_t(gt0_rxuserrdy_t),
        .gt0_txuserrdy_t(gt0_txuserrdy_t),
        .gtrefclk(gtrefclk),
        .gtrefclk_bufg(gtrefclk_bufg),
        .gtxe2_i(gtwizard_i_n_5),
        .gtxe2_i_0(gtwizard_i_n_7),
        .gtxe2_i_1(gtxe2_i),
        .gtxe2_i_2(gtxe2_i_0),
        .gtxe2_i_3(gtxe2_i_1),
        .independent_clock_bufg(independent_clock_bufg),
        .reset(reset),
        .reset_out(reset_out),
        .rxn(rxn),
        .rxoutclk(rxoutclk),
        .rxp(rxp),
        .rxuserclk(rxuserclk),
        .txn(txn),
        .txoutclk(txoutclk),
        .txp(txp),
        .userclk(userclk));
endmodule

module gmii_to_sgmii_bridge_GTWIZARD_multi_gt
   (cplllock,
    gt0_cpllrefclklost_i,
    txn,
    txp,
    rxoutclk,
    gtxe2_i,
    txoutclk,
    gtxe2_i_0,
    TXBUFSTATUS,
    D,
    independent_clock_bufg,
    gtrefclk_bufg,
    gtrefclk,
    SR,
    gt0_gttxreset_in0_out,
    rxn,
    rxp,
    gt0_qplloutclk_in,
    gt0_qplloutrefclk_in,
    reset_out,
    reset,
    gt0_rxuserrdy_t,
    rxuserclk,
    TXPD,
    gt0_txuserrdy_t,
    userclk,
    RXPD,
    Q,
    gtxe2_i_1,
    gtxe2_i_2,
    gtxe2_i_3,
    gt0_cpllreset_t);
  output cplllock;
  output gt0_cpllrefclklost_i;
  output txn;
  output txp;
  output rxoutclk;
  output gtxe2_i;
  output txoutclk;
  output gtxe2_i_0;
  output [0:0]TXBUFSTATUS;
  output [23:0]D;
  input independent_clock_bufg;
  input gtrefclk_bufg;
  input gtrefclk;
  input [0:0]SR;
  input gt0_gttxreset_in0_out;
  input rxn;
  input rxp;
  input gt0_qplloutclk_in;
  input gt0_qplloutrefclk_in;
  input reset_out;
  input reset;
  input gt0_rxuserrdy_t;
  input rxuserclk;
  input [0:0]TXPD;
  input gt0_txuserrdy_t;
  input userclk;
  input [0:0]RXPD;
  input [15:0]Q;
  input [1:0]gtxe2_i_1;
  input [1:0]gtxe2_i_2;
  input [1:0]gtxe2_i_3;
  input gt0_cpllreset_t;

  wire [23:0]D;
  wire [15:0]Q;
  wire [0:0]RXPD;
  wire [0:0]SR;
  wire [0:0]TXBUFSTATUS;
  wire [0:0]TXPD;
  wire cpll_pd0_i;
  wire cplllock;
  wire cpllreset_in;
  wire gt0_cpllrefclklost_i;
  wire gt0_cpllreset_t;
  wire gt0_gttxreset_in0_out;
  wire gt0_qplloutclk_in;
  wire gt0_qplloutrefclk_in;
  wire gt0_rxuserrdy_t;
  wire gt0_txuserrdy_t;
  wire gtrefclk;
  wire gtrefclk_bufg;
  wire gtxe2_i;
  wire gtxe2_i_0;
  wire [1:0]gtxe2_i_1;
  wire [1:0]gtxe2_i_2;
  wire [1:0]gtxe2_i_3;
  wire independent_clock_bufg;
  wire reset;
  wire reset_out;
  wire rxn;
  wire rxoutclk;
  wire rxp;
  wire rxuserclk;
  wire txn;
  wire txoutclk;
  wire txp;
  wire userclk;

  gmii_to_sgmii_bridge_cpll_railing cpll_railing0_i
       (.cpll_pd0_i(cpll_pd0_i),
        .cpllreset_in(cpllreset_in),
        .gt0_cpllreset_t(gt0_cpllreset_t),
        .gtrefclk_bufg(gtrefclk_bufg));
  gmii_to_sgmii_bridge_GTWIZARD_GT gt0_GTWIZARD_i
       (.D(D),
        .Q(Q),
        .RXPD(RXPD),
        .SR(SR),
        .TXBUFSTATUS(TXBUFSTATUS),
        .TXPD(TXPD),
        .cpll_pd0_i(cpll_pd0_i),
        .cplllock(cplllock),
        .cpllreset_in(cpllreset_in),
        .gt0_cpllrefclklost_i(gt0_cpllrefclklost_i),
        .gt0_gttxreset_in0_out(gt0_gttxreset_in0_out),
        .gt0_qplloutclk_in(gt0_qplloutclk_in),
        .gt0_qplloutrefclk_in(gt0_qplloutrefclk_in),
        .gt0_rxuserrdy_t(gt0_rxuserrdy_t),
        .gt0_txuserrdy_t(gt0_txuserrdy_t),
        .gtrefclk(gtrefclk),
        .gtrefclk_bufg(gtrefclk_bufg),
        .gtxe2_i_0(gtxe2_i),
        .gtxe2_i_1(gtxe2_i_0),
        .gtxe2_i_2(gtxe2_i_1),
        .gtxe2_i_3(gtxe2_i_2),
        .gtxe2_i_4(gtxe2_i_3),
        .independent_clock_bufg(independent_clock_bufg),
        .reset(reset),
        .reset_out(reset_out),
        .rxn(rxn),
        .rxoutclk(rxoutclk),
        .rxp(rxp),
        .rxuserclk(rxuserclk),
        .txn(txn),
        .txoutclk(txoutclk),
        .txp(txp),
        .userclk(userclk));
endmodule

module gmii_to_sgmii_bridge_RX_STARTUP_FSM
   (data_in,
    gt0_rxuserrdy_t,
    SR,
    independent_clock_bufg,
    rxuserclk,
    pma_reset,
    gtxe2_i,
    \FSM_sequential_rx_state_reg[0]_0 ,
    data_sync_reg1,
    mmcm_locked,
    data_out,
    cplllock);
  output data_in;
  output gt0_rxuserrdy_t;
  output [0:0]SR;
  input independent_clock_bufg;
  input rxuserclk;
  input pma_reset;
  input gtxe2_i;
  input \FSM_sequential_rx_state_reg[0]_0 ;
  input data_sync_reg1;
  input mmcm_locked;
  input data_out;
  input cplllock;

  wire \FSM_sequential_rx_state[0]_i_2_n_0 ;
  wire \FSM_sequential_rx_state[1]_i_3_n_0 ;
  wire \FSM_sequential_rx_state[2]_i_2_n_0 ;
  wire \FSM_sequential_rx_state[3]_i_10_n_0 ;
  wire \FSM_sequential_rx_state[3]_i_3_n_0 ;
  wire \FSM_sequential_rx_state[3]_i_7_n_0 ;
  wire \FSM_sequential_rx_state[3]_i_9_n_0 ;
  wire \FSM_sequential_rx_state_reg[0]_0 ;
  wire GTRXRESET;
  wire RXUSERRDY_i_1_n_0;
  wire [0:0]SR;
  wire check_tlock_max_i_1_n_0;
  wire check_tlock_max_reg_n_0;
  wire cplllock;
  wire data_in;
  wire data_out;
  wire data_out_0;
  wire data_sync_reg1;
  wire gt0_rxuserrdy_t;
  wire gtrxreset_i_i_1_n_0;
  wire gtxe2_i;
  wire independent_clock_bufg;
  wire \init_wait_count[0]_i_1__0_n_0 ;
  wire \init_wait_count[6]_i_1__0_n_0 ;
  wire \init_wait_count[6]_i_3__0_n_0 ;
  wire [6:0]init_wait_count_reg;
  wire init_wait_done_i_1__0_n_0;
  wire init_wait_done_reg_n_0;
  wire \mmcm_lock_count[2]_i_1__0_n_0 ;
  wire \mmcm_lock_count[3]_i_1__0_n_0 ;
  wire \mmcm_lock_count[4]_i_1__0_n_0 ;
  wire \mmcm_lock_count[5]_i_1__0_n_0 ;
  wire \mmcm_lock_count[6]_i_1__0_n_0 ;
  wire \mmcm_lock_count[7]_i_2__0_n_0 ;
  wire \mmcm_lock_count[7]_i_3__0_n_0 ;
  wire [7:0]mmcm_lock_count_reg;
  wire mmcm_lock_i;
  wire mmcm_lock_reclocked;
  wire mmcm_lock_reclocked_i_1_n_0;
  wire mmcm_lock_reclocked_i_2__0_n_0;
  wire mmcm_locked;
  wire [6:1]p_0_in__1;
  wire [1:0]p_0_in__2;
  wire pma_reset;
  wire reset_time_out_i_3_n_0;
  wire reset_time_out_i_4_n_0;
  wire reset_time_out_reg_n_0;
  wire run_phase_alignment_int_i_1__0_n_0;
  wire run_phase_alignment_int_reg_n_0;
  wire run_phase_alignment_int_s3_reg_n_0;
  wire rx_fsm_reset_done_int_i_5_n_0;
  wire rx_fsm_reset_done_int_i_6_n_0;
  wire rx_fsm_reset_done_int_s2;
  wire rx_fsm_reset_done_int_s3;
  wire [3:0]rx_state;
  wire [3:0]rx_state__0;
  wire rxresetdone_s2;
  wire rxresetdone_s3;
  wire rxuserclk;
  wire sync_cplllock_n_0;
  wire sync_data_valid_n_0;
  wire sync_data_valid_n_1;
  wire sync_data_valid_n_5;
  wire sync_mmcm_lock_reclocked_n_0;
  wire time_out_100us_i_1_n_0;
  wire time_out_100us_i_2_n_0;
  wire time_out_100us_i_3_n_0;
  wire time_out_100us_reg_n_0;
  wire time_out_1us_i_1_n_0;
  wire time_out_1us_i_2_n_0;
  wire time_out_1us_i_3_n_0;
  wire time_out_1us_reg_n_0;
  wire time_out_2ms_i_1_n_0;
  wire time_out_2ms_i_2_n_0;
  wire time_out_2ms_i_3__0_n_0;
  wire time_out_2ms_i_4_n_0;
  wire time_out_2ms_reg_n_0;
  wire time_out_counter;
  wire \time_out_counter[0]_i_3_n_0 ;
  wire [18:0]time_out_counter_reg;
  wire \time_out_counter_reg[0]_i_2__0_n_0 ;
  wire \time_out_counter_reg[0]_i_2__0_n_1 ;
  wire \time_out_counter_reg[0]_i_2__0_n_2 ;
  wire \time_out_counter_reg[0]_i_2__0_n_3 ;
  wire \time_out_counter_reg[0]_i_2__0_n_4 ;
  wire \time_out_counter_reg[0]_i_2__0_n_5 ;
  wire \time_out_counter_reg[0]_i_2__0_n_6 ;
  wire \time_out_counter_reg[0]_i_2__0_n_7 ;
  wire \time_out_counter_reg[12]_i_1__0_n_0 ;
  wire \time_out_counter_reg[12]_i_1__0_n_1 ;
  wire \time_out_counter_reg[12]_i_1__0_n_2 ;
  wire \time_out_counter_reg[12]_i_1__0_n_3 ;
  wire \time_out_counter_reg[12]_i_1__0_n_4 ;
  wire \time_out_counter_reg[12]_i_1__0_n_5 ;
  wire \time_out_counter_reg[12]_i_1__0_n_6 ;
  wire \time_out_counter_reg[12]_i_1__0_n_7 ;
  wire \time_out_counter_reg[16]_i_1__0_n_2 ;
  wire \time_out_counter_reg[16]_i_1__0_n_3 ;
  wire \time_out_counter_reg[16]_i_1__0_n_5 ;
  wire \time_out_counter_reg[16]_i_1__0_n_6 ;
  wire \time_out_counter_reg[16]_i_1__0_n_7 ;
  wire \time_out_counter_reg[4]_i_1__0_n_0 ;
  wire \time_out_counter_reg[4]_i_1__0_n_1 ;
  wire \time_out_counter_reg[4]_i_1__0_n_2 ;
  wire \time_out_counter_reg[4]_i_1__0_n_3 ;
  wire \time_out_counter_reg[4]_i_1__0_n_4 ;
  wire \time_out_counter_reg[4]_i_1__0_n_5 ;
  wire \time_out_counter_reg[4]_i_1__0_n_6 ;
  wire \time_out_counter_reg[4]_i_1__0_n_7 ;
  wire \time_out_counter_reg[8]_i_1__0_n_0 ;
  wire \time_out_counter_reg[8]_i_1__0_n_1 ;
  wire \time_out_counter_reg[8]_i_1__0_n_2 ;
  wire \time_out_counter_reg[8]_i_1__0_n_3 ;
  wire \time_out_counter_reg[8]_i_1__0_n_4 ;
  wire \time_out_counter_reg[8]_i_1__0_n_5 ;
  wire \time_out_counter_reg[8]_i_1__0_n_6 ;
  wire \time_out_counter_reg[8]_i_1__0_n_7 ;
  wire time_out_wait_bypass_i_1_n_0;
  wire time_out_wait_bypass_i_2__0_n_0;
  wire time_out_wait_bypass_i_3__0_n_0;
  wire time_out_wait_bypass_i_4__0_n_0;
  wire time_out_wait_bypass_reg_n_0;
  wire time_out_wait_bypass_s2;
  wire time_out_wait_bypass_s3;
  wire time_tlock_max;
  wire time_tlock_max1;
  wire time_tlock_max1_carry__0_i_1_n_0;
  wire time_tlock_max1_carry__0_i_2_n_0;
  wire time_tlock_max1_carry__0_i_3_n_0;
  wire time_tlock_max1_carry__0_i_4_n_0;
  wire time_tlock_max1_carry__0_i_5_n_0;
  wire time_tlock_max1_carry__0_i_6_n_0;
  wire time_tlock_max1_carry__0_n_0;
  wire time_tlock_max1_carry__0_n_1;
  wire time_tlock_max1_carry__0_n_2;
  wire time_tlock_max1_carry__0_n_3;
  wire time_tlock_max1_carry__1_i_1_n_0;
  wire time_tlock_max1_carry__1_i_2_n_0;
  wire time_tlock_max1_carry__1_i_3_n_0;
  wire time_tlock_max1_carry__1_n_3;
  wire time_tlock_max1_carry_i_1_n_0;
  wire time_tlock_max1_carry_i_2_n_0;
  wire time_tlock_max1_carry_i_3_n_0;
  wire time_tlock_max1_carry_i_4_n_0;
  wire time_tlock_max1_carry_i_5_n_0;
  wire time_tlock_max1_carry_i_6_n_0;
  wire time_tlock_max1_carry_i_7_n_0;
  wire time_tlock_max1_carry_i_8_n_0;
  wire time_tlock_max1_carry_n_0;
  wire time_tlock_max1_carry_n_1;
  wire time_tlock_max1_carry_n_2;
  wire time_tlock_max1_carry_n_3;
  wire time_tlock_max_i_1_n_0;
  wire \wait_bypass_count[0]_i_1__0_n_0 ;
  wire \wait_bypass_count[0]_i_2__0_n_0 ;
  wire \wait_bypass_count[0]_i_4__0_n_0 ;
  wire [12:0]wait_bypass_count_reg;
  wire \wait_bypass_count_reg[0]_i_3__0_n_0 ;
  wire \wait_bypass_count_reg[0]_i_3__0_n_1 ;
  wire \wait_bypass_count_reg[0]_i_3__0_n_2 ;
  wire \wait_bypass_count_reg[0]_i_3__0_n_3 ;
  wire \wait_bypass_count_reg[0]_i_3__0_n_4 ;
  wire \wait_bypass_count_reg[0]_i_3__0_n_5 ;
  wire \wait_bypass_count_reg[0]_i_3__0_n_6 ;
  wire \wait_bypass_count_reg[0]_i_3__0_n_7 ;
  wire \wait_bypass_count_reg[12]_i_1__0_n_7 ;
  wire \wait_bypass_count_reg[4]_i_1__0_n_0 ;
  wire \wait_bypass_count_reg[4]_i_1__0_n_1 ;
  wire \wait_bypass_count_reg[4]_i_1__0_n_2 ;
  wire \wait_bypass_count_reg[4]_i_1__0_n_3 ;
  wire \wait_bypass_count_reg[4]_i_1__0_n_4 ;
  wire \wait_bypass_count_reg[4]_i_1__0_n_5 ;
  wire \wait_bypass_count_reg[4]_i_1__0_n_6 ;
  wire \wait_bypass_count_reg[4]_i_1__0_n_7 ;
  wire \wait_bypass_count_reg[8]_i_1__0_n_0 ;
  wire \wait_bypass_count_reg[8]_i_1__0_n_1 ;
  wire \wait_bypass_count_reg[8]_i_1__0_n_2 ;
  wire \wait_bypass_count_reg[8]_i_1__0_n_3 ;
  wire \wait_bypass_count_reg[8]_i_1__0_n_4 ;
  wire \wait_bypass_count_reg[8]_i_1__0_n_5 ;
  wire \wait_bypass_count_reg[8]_i_1__0_n_6 ;
  wire \wait_bypass_count_reg[8]_i_1__0_n_7 ;
  wire [0:0]wait_time_cnt0__0;
  wire \wait_time_cnt[1]_i_1__0_n_0 ;
  wire \wait_time_cnt[2]_i_1__0_n_0 ;
  wire \wait_time_cnt[3]_i_1__0_n_0 ;
  wire \wait_time_cnt[4]_i_1__0_n_0 ;
  wire \wait_time_cnt[5]_i_1__0_n_0 ;
  wire \wait_time_cnt[6]_i_1_n_0 ;
  wire \wait_time_cnt[6]_i_2__0_n_0 ;
  wire \wait_time_cnt[6]_i_3__0_n_0 ;
  wire \wait_time_cnt[6]_i_4__0_n_0 ;
  wire [6:0]wait_time_cnt_reg;
  wire [3:2]\NLW_time_out_counter_reg[16]_i_1__0_CO_UNCONNECTED ;
  wire [3:3]\NLW_time_out_counter_reg[16]_i_1__0_O_UNCONNECTED ;
  wire [3:0]NLW_time_tlock_max1_carry_O_UNCONNECTED;
  wire [3:0]NLW_time_tlock_max1_carry__0_O_UNCONNECTED;
  wire [3:2]NLW_time_tlock_max1_carry__1_CO_UNCONNECTED;
  wire [3:0]NLW_time_tlock_max1_carry__1_O_UNCONNECTED;
  wire [3:0]\NLW_wait_bypass_count_reg[12]_i_1__0_CO_UNCONNECTED ;
  wire [3:1]\NLW_wait_bypass_count_reg[12]_i_1__0_O_UNCONNECTED ;

  LUT6 #(
    .INIT(64'h2222AAAA00000C00)) 
    \FSM_sequential_rx_state[0]_i_2 
       (.I0(time_out_2ms_reg_n_0),
        .I1(rx_state[2]),
        .I2(rx_state[3]),
        .I3(time_tlock_max),
        .I4(reset_time_out_reg_n_0),
        .I5(rx_state[1]),
        .O(\FSM_sequential_rx_state[0]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'h0000AABF000F0000)) 
    \FSM_sequential_rx_state[1]_i_3 
       (.I0(reset_time_out_reg_n_0),
        .I1(time_tlock_max),
        .I2(rx_state[2]),
        .I3(rx_state[3]),
        .I4(rx_state[1]),
        .I5(rx_state[0]),
        .O(\FSM_sequential_rx_state[1]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'h0000000050FF2200)) 
    \FSM_sequential_rx_state[2]_i_1 
       (.I0(rx_state[1]),
        .I1(time_out_2ms_reg_n_0),
        .I2(\FSM_sequential_rx_state[2]_i_2_n_0 ),
        .I3(rx_state[0]),
        .I4(rx_state[2]),
        .I5(rx_state[3]),
        .O(rx_state__0[2]));
  (* SOFT_HLUTNM = "soft_lutpair88" *) 
  LUT2 #(
    .INIT(4'hB)) 
    \FSM_sequential_rx_state[2]_i_2 
       (.I0(reset_time_out_reg_n_0),
        .I1(time_tlock_max),
        .O(\FSM_sequential_rx_state[2]_i_2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair85" *) 
  LUT2 #(
    .INIT(4'hB)) 
    \FSM_sequential_rx_state[3]_i_10 
       (.I0(reset_time_out_reg_n_0),
        .I1(time_out_2ms_reg_n_0),
        .O(\FSM_sequential_rx_state[3]_i_10_n_0 ));
  LUT6 #(
    .INIT(64'h0000000050005300)) 
    \FSM_sequential_rx_state[3]_i_3 
       (.I0(\FSM_sequential_rx_state[3]_i_10_n_0 ),
        .I1(\wait_time_cnt[6]_i_4__0_n_0 ),
        .I2(rx_state[0]),
        .I3(rx_state[1]),
        .I4(wait_time_cnt_reg[6]),
        .I5(rx_state[3]),
        .O(\FSM_sequential_rx_state[3]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'h0000000023002F00)) 
    \FSM_sequential_rx_state[3]_i_7 
       (.I0(time_out_2ms_reg_n_0),
        .I1(rx_state[2]),
        .I2(rx_state[1]),
        .I3(rx_state[0]),
        .I4(\FSM_sequential_rx_state[2]_i_2_n_0 ),
        .I5(rx_state[3]),
        .O(\FSM_sequential_rx_state[3]_i_7_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair79" *) 
  LUT5 #(
    .INIT(32'h80800080)) 
    \FSM_sequential_rx_state[3]_i_9 
       (.I0(rx_state[0]),
        .I1(rx_state[1]),
        .I2(rx_state[2]),
        .I3(time_out_2ms_reg_n_0),
        .I4(reset_time_out_reg_n_0),
        .O(\FSM_sequential_rx_state[3]_i_9_n_0 ));
  (* FSM_ENCODED_STATES = "release_pll_reset:0011,verify_recclk_stable:0100,wait_for_pll_lock:0010,fsm_done:1010,assert_all_resets:0001,init:0000,wait_reset_done:0111,monitor_data_valid:1001,wait_for_rxusrclk:0110,do_phase_alignment:1000,release_mmcm_reset:0101" *) 
  FDRE #(
    .INIT(1'b0)) 
    \FSM_sequential_rx_state_reg[0] 
       (.C(independent_clock_bufg),
        .CE(sync_data_valid_n_5),
        .D(rx_state__0[0]),
        .Q(rx_state[0]),
        .R(pma_reset));
  (* FSM_ENCODED_STATES = "release_pll_reset:0011,verify_recclk_stable:0100,wait_for_pll_lock:0010,fsm_done:1010,assert_all_resets:0001,init:0000,wait_reset_done:0111,monitor_data_valid:1001,wait_for_rxusrclk:0110,do_phase_alignment:1000,release_mmcm_reset:0101" *) 
  FDRE #(
    .INIT(1'b0)) 
    \FSM_sequential_rx_state_reg[1] 
       (.C(independent_clock_bufg),
        .CE(sync_data_valid_n_5),
        .D(rx_state__0[1]),
        .Q(rx_state[1]),
        .R(pma_reset));
  (* FSM_ENCODED_STATES = "release_pll_reset:0011,verify_recclk_stable:0100,wait_for_pll_lock:0010,fsm_done:1010,assert_all_resets:0001,init:0000,wait_reset_done:0111,monitor_data_valid:1001,wait_for_rxusrclk:0110,do_phase_alignment:1000,release_mmcm_reset:0101" *) 
  FDRE #(
    .INIT(1'b0)) 
    \FSM_sequential_rx_state_reg[2] 
       (.C(independent_clock_bufg),
        .CE(sync_data_valid_n_5),
        .D(rx_state__0[2]),
        .Q(rx_state[2]),
        .R(pma_reset));
  (* FSM_ENCODED_STATES = "release_pll_reset:0011,verify_recclk_stable:0100,wait_for_pll_lock:0010,fsm_done:1010,assert_all_resets:0001,init:0000,wait_reset_done:0111,monitor_data_valid:1001,wait_for_rxusrclk:0110,do_phase_alignment:1000,release_mmcm_reset:0101" *) 
  FDRE #(
    .INIT(1'b0)) 
    \FSM_sequential_rx_state_reg[3] 
       (.C(independent_clock_bufg),
        .CE(sync_data_valid_n_5),
        .D(rx_state__0[3]),
        .Q(rx_state[3]),
        .R(pma_reset));
  LUT5 #(
    .INIT(32'hFFFB4000)) 
    RXUSERRDY_i_1
       (.I0(rx_state[3]),
        .I1(rx_state[0]),
        .I2(rx_state[2]),
        .I3(rx_state[1]),
        .I4(gt0_rxuserrdy_t),
        .O(RXUSERRDY_i_1_n_0));
  FDRE #(
    .INIT(1'b0)) 
    RXUSERRDY_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(RXUSERRDY_i_1_n_0),
        .Q(gt0_rxuserrdy_t),
        .R(pma_reset));
  (* SOFT_HLUTNM = "soft_lutpair80" *) 
  LUT5 #(
    .INIT(32'hFFFB0008)) 
    check_tlock_max_i_1
       (.I0(rx_state[2]),
        .I1(rx_state[0]),
        .I2(rx_state[1]),
        .I3(rx_state[3]),
        .I4(check_tlock_max_reg_n_0),
        .O(check_tlock_max_i_1_n_0));
  FDRE #(
    .INIT(1'b0)) 
    check_tlock_max_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(check_tlock_max_i_1_n_0),
        .Q(check_tlock_max_reg_n_0),
        .R(pma_reset));
  LUT5 #(
    .INIT(32'hFFEF0100)) 
    gtrxreset_i_i_1
       (.I0(rx_state[3]),
        .I1(rx_state[1]),
        .I2(rx_state[2]),
        .I3(rx_state[0]),
        .I4(GTRXRESET),
        .O(gtrxreset_i_i_1_n_0));
  FDRE #(
    .INIT(1'b0)) 
    gtrxreset_i_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(gtrxreset_i_i_1_n_0),
        .Q(GTRXRESET),
        .R(pma_reset));
  LUT3 #(
    .INIT(8'hEA)) 
    gtxe2_i_i_2
       (.I0(GTRXRESET),
        .I1(data_in),
        .I2(gtxe2_i),
        .O(SR));
  LUT1 #(
    .INIT(2'h1)) 
    \init_wait_count[0]_i_1__0 
       (.I0(init_wait_count_reg[0]),
        .O(\init_wait_count[0]_i_1__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair86" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \init_wait_count[1]_i_1__0 
       (.I0(init_wait_count_reg[0]),
        .I1(init_wait_count_reg[1]),
        .O(p_0_in__1[1]));
  (* SOFT_HLUTNM = "soft_lutpair84" *) 
  LUT3 #(
    .INIT(8'h78)) 
    \init_wait_count[2]_i_1__0 
       (.I0(init_wait_count_reg[0]),
        .I1(init_wait_count_reg[1]),
        .I2(init_wait_count_reg[2]),
        .O(p_0_in__1[2]));
  (* SOFT_HLUTNM = "soft_lutpair83" *) 
  LUT4 #(
    .INIT(16'h7F80)) 
    \init_wait_count[3]_i_1__0 
       (.I0(init_wait_count_reg[1]),
        .I1(init_wait_count_reg[2]),
        .I2(init_wait_count_reg[0]),
        .I3(init_wait_count_reg[3]),
        .O(p_0_in__1[3]));
  (* SOFT_HLUTNM = "soft_lutpair83" *) 
  LUT5 #(
    .INIT(32'h7FFF8000)) 
    \init_wait_count[4]_i_1__0 
       (.I0(init_wait_count_reg[2]),
        .I1(init_wait_count_reg[1]),
        .I2(init_wait_count_reg[3]),
        .I3(init_wait_count_reg[0]),
        .I4(init_wait_count_reg[4]),
        .O(p_0_in__1[4]));
  LUT6 #(
    .INIT(64'h7FFFFFFF80000000)) 
    \init_wait_count[5]_i_1__0 
       (.I0(init_wait_count_reg[2]),
        .I1(init_wait_count_reg[1]),
        .I2(init_wait_count_reg[3]),
        .I3(init_wait_count_reg[0]),
        .I4(init_wait_count_reg[4]),
        .I5(init_wait_count_reg[5]),
        .O(p_0_in__1[5]));
  LUT4 #(
    .INIT(16'hFEFF)) 
    \init_wait_count[6]_i_1__0 
       (.I0(\init_wait_count[6]_i_3__0_n_0 ),
        .I1(init_wait_count_reg[0]),
        .I2(init_wait_count_reg[4]),
        .I3(init_wait_count_reg[6]),
        .O(\init_wait_count[6]_i_1__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair86" *) 
  LUT4 #(
    .INIT(16'hBF40)) 
    \init_wait_count[6]_i_2__0 
       (.I0(\init_wait_count[6]_i_3__0_n_0 ),
        .I1(init_wait_count_reg[0]),
        .I2(init_wait_count_reg[4]),
        .I3(init_wait_count_reg[6]),
        .O(p_0_in__1[6]));
  (* SOFT_HLUTNM = "soft_lutpair84" *) 
  LUT4 #(
    .INIT(16'h7FFF)) 
    \init_wait_count[6]_i_3__0 
       (.I0(init_wait_count_reg[3]),
        .I1(init_wait_count_reg[1]),
        .I2(init_wait_count_reg[2]),
        .I3(init_wait_count_reg[5]),
        .O(\init_wait_count[6]_i_3__0_n_0 ));
  FDCE #(
    .INIT(1'b0)) 
    \init_wait_count_reg[0] 
       (.C(independent_clock_bufg),
        .CE(\init_wait_count[6]_i_1__0_n_0 ),
        .CLR(pma_reset),
        .D(\init_wait_count[0]_i_1__0_n_0 ),
        .Q(init_wait_count_reg[0]));
  FDCE #(
    .INIT(1'b0)) 
    \init_wait_count_reg[1] 
       (.C(independent_clock_bufg),
        .CE(\init_wait_count[6]_i_1__0_n_0 ),
        .CLR(pma_reset),
        .D(p_0_in__1[1]),
        .Q(init_wait_count_reg[1]));
  FDCE #(
    .INIT(1'b0)) 
    \init_wait_count_reg[2] 
       (.C(independent_clock_bufg),
        .CE(\init_wait_count[6]_i_1__0_n_0 ),
        .CLR(pma_reset),
        .D(p_0_in__1[2]),
        .Q(init_wait_count_reg[2]));
  FDCE #(
    .INIT(1'b0)) 
    \init_wait_count_reg[3] 
       (.C(independent_clock_bufg),
        .CE(\init_wait_count[6]_i_1__0_n_0 ),
        .CLR(pma_reset),
        .D(p_0_in__1[3]),
        .Q(init_wait_count_reg[3]));
  FDCE #(
    .INIT(1'b0)) 
    \init_wait_count_reg[4] 
       (.C(independent_clock_bufg),
        .CE(\init_wait_count[6]_i_1__0_n_0 ),
        .CLR(pma_reset),
        .D(p_0_in__1[4]),
        .Q(init_wait_count_reg[4]));
  FDCE #(
    .INIT(1'b0)) 
    \init_wait_count_reg[5] 
       (.C(independent_clock_bufg),
        .CE(\init_wait_count[6]_i_1__0_n_0 ),
        .CLR(pma_reset),
        .D(p_0_in__1[5]),
        .Q(init_wait_count_reg[5]));
  FDCE #(
    .INIT(1'b0)) 
    \init_wait_count_reg[6] 
       (.C(independent_clock_bufg),
        .CE(\init_wait_count[6]_i_1__0_n_0 ),
        .CLR(pma_reset),
        .D(p_0_in__1[6]),
        .Q(init_wait_count_reg[6]));
  LUT5 #(
    .INIT(32'hFFFF0010)) 
    init_wait_done_i_1__0
       (.I0(\init_wait_count[6]_i_3__0_n_0 ),
        .I1(init_wait_count_reg[4]),
        .I2(init_wait_count_reg[6]),
        .I3(init_wait_count_reg[0]),
        .I4(init_wait_done_reg_n_0),
        .O(init_wait_done_i_1__0_n_0));
  FDCE #(
    .INIT(1'b0)) 
    init_wait_done_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .CLR(pma_reset),
        .D(init_wait_done_i_1__0_n_0),
        .Q(init_wait_done_reg_n_0));
  LUT1 #(
    .INIT(2'h1)) 
    \mmcm_lock_count[0]_i_1__0 
       (.I0(mmcm_lock_count_reg[0]),
        .O(p_0_in__2[0]));
  (* SOFT_HLUTNM = "soft_lutpair90" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \mmcm_lock_count[1]_i_1__0 
       (.I0(mmcm_lock_count_reg[0]),
        .I1(mmcm_lock_count_reg[1]),
        .O(p_0_in__2[1]));
  (* SOFT_HLUTNM = "soft_lutpair90" *) 
  LUT3 #(
    .INIT(8'h78)) 
    \mmcm_lock_count[2]_i_1__0 
       (.I0(mmcm_lock_count_reg[1]),
        .I1(mmcm_lock_count_reg[0]),
        .I2(mmcm_lock_count_reg[2]),
        .O(\mmcm_lock_count[2]_i_1__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair82" *) 
  LUT4 #(
    .INIT(16'h7F80)) 
    \mmcm_lock_count[3]_i_1__0 
       (.I0(mmcm_lock_count_reg[2]),
        .I1(mmcm_lock_count_reg[0]),
        .I2(mmcm_lock_count_reg[1]),
        .I3(mmcm_lock_count_reg[3]),
        .O(\mmcm_lock_count[3]_i_1__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair82" *) 
  LUT5 #(
    .INIT(32'h7FFF8000)) 
    \mmcm_lock_count[4]_i_1__0 
       (.I0(mmcm_lock_count_reg[3]),
        .I1(mmcm_lock_count_reg[1]),
        .I2(mmcm_lock_count_reg[0]),
        .I3(mmcm_lock_count_reg[2]),
        .I4(mmcm_lock_count_reg[4]),
        .O(\mmcm_lock_count[4]_i_1__0_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFF80000000)) 
    \mmcm_lock_count[5]_i_1__0 
       (.I0(mmcm_lock_count_reg[4]),
        .I1(mmcm_lock_count_reg[2]),
        .I2(mmcm_lock_count_reg[0]),
        .I3(mmcm_lock_count_reg[1]),
        .I4(mmcm_lock_count_reg[3]),
        .I5(mmcm_lock_count_reg[5]),
        .O(\mmcm_lock_count[5]_i_1__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair89" *) 
  LUT2 #(
    .INIT(4'h9)) 
    \mmcm_lock_count[6]_i_1__0 
       (.I0(mmcm_lock_reclocked_i_2__0_n_0),
        .I1(mmcm_lock_count_reg[6]),
        .O(\mmcm_lock_count[6]_i_1__0_n_0 ));
  LUT3 #(
    .INIT(8'hBF)) 
    \mmcm_lock_count[7]_i_2__0 
       (.I0(mmcm_lock_reclocked_i_2__0_n_0),
        .I1(mmcm_lock_count_reg[6]),
        .I2(mmcm_lock_count_reg[7]),
        .O(\mmcm_lock_count[7]_i_2__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair89" *) 
  LUT3 #(
    .INIT(8'hD2)) 
    \mmcm_lock_count[7]_i_3__0 
       (.I0(mmcm_lock_count_reg[6]),
        .I1(mmcm_lock_reclocked_i_2__0_n_0),
        .I2(mmcm_lock_count_reg[7]),
        .O(\mmcm_lock_count[7]_i_3__0_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \mmcm_lock_count_reg[0] 
       (.C(independent_clock_bufg),
        .CE(\mmcm_lock_count[7]_i_2__0_n_0 ),
        .D(p_0_in__2[0]),
        .Q(mmcm_lock_count_reg[0]),
        .R(sync_mmcm_lock_reclocked_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \mmcm_lock_count_reg[1] 
       (.C(independent_clock_bufg),
        .CE(\mmcm_lock_count[7]_i_2__0_n_0 ),
        .D(p_0_in__2[1]),
        .Q(mmcm_lock_count_reg[1]),
        .R(sync_mmcm_lock_reclocked_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \mmcm_lock_count_reg[2] 
       (.C(independent_clock_bufg),
        .CE(\mmcm_lock_count[7]_i_2__0_n_0 ),
        .D(\mmcm_lock_count[2]_i_1__0_n_0 ),
        .Q(mmcm_lock_count_reg[2]),
        .R(sync_mmcm_lock_reclocked_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \mmcm_lock_count_reg[3] 
       (.C(independent_clock_bufg),
        .CE(\mmcm_lock_count[7]_i_2__0_n_0 ),
        .D(\mmcm_lock_count[3]_i_1__0_n_0 ),
        .Q(mmcm_lock_count_reg[3]),
        .R(sync_mmcm_lock_reclocked_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \mmcm_lock_count_reg[4] 
       (.C(independent_clock_bufg),
        .CE(\mmcm_lock_count[7]_i_2__0_n_0 ),
        .D(\mmcm_lock_count[4]_i_1__0_n_0 ),
        .Q(mmcm_lock_count_reg[4]),
        .R(sync_mmcm_lock_reclocked_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \mmcm_lock_count_reg[5] 
       (.C(independent_clock_bufg),
        .CE(\mmcm_lock_count[7]_i_2__0_n_0 ),
        .D(\mmcm_lock_count[5]_i_1__0_n_0 ),
        .Q(mmcm_lock_count_reg[5]),
        .R(sync_mmcm_lock_reclocked_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \mmcm_lock_count_reg[6] 
       (.C(independent_clock_bufg),
        .CE(\mmcm_lock_count[7]_i_2__0_n_0 ),
        .D(\mmcm_lock_count[6]_i_1__0_n_0 ),
        .Q(mmcm_lock_count_reg[6]),
        .R(sync_mmcm_lock_reclocked_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \mmcm_lock_count_reg[7] 
       (.C(independent_clock_bufg),
        .CE(\mmcm_lock_count[7]_i_2__0_n_0 ),
        .D(\mmcm_lock_count[7]_i_3__0_n_0 ),
        .Q(mmcm_lock_count_reg[7]),
        .R(sync_mmcm_lock_reclocked_n_0));
  LUT5 #(
    .INIT(32'hAAEA0000)) 
    mmcm_lock_reclocked_i_1
       (.I0(mmcm_lock_reclocked),
        .I1(mmcm_lock_count_reg[7]),
        .I2(mmcm_lock_count_reg[6]),
        .I3(mmcm_lock_reclocked_i_2__0_n_0),
        .I4(mmcm_lock_i),
        .O(mmcm_lock_reclocked_i_1_n_0));
  LUT6 #(
    .INIT(64'h7FFFFFFFFFFFFFFF)) 
    mmcm_lock_reclocked_i_2__0
       (.I0(mmcm_lock_count_reg[4]),
        .I1(mmcm_lock_count_reg[2]),
        .I2(mmcm_lock_count_reg[0]),
        .I3(mmcm_lock_count_reg[1]),
        .I4(mmcm_lock_count_reg[3]),
        .I5(mmcm_lock_count_reg[5]),
        .O(mmcm_lock_reclocked_i_2__0_n_0));
  FDRE #(
    .INIT(1'b0)) 
    mmcm_lock_reclocked_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(mmcm_lock_reclocked_i_1_n_0),
        .Q(mmcm_lock_reclocked),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair80" *) 
  LUT2 #(
    .INIT(4'hE)) 
    reset_time_out_i_3
       (.I0(rx_state[2]),
        .I1(rx_state[3]),
        .O(reset_time_out_i_3_n_0));
  (* SOFT_HLUTNM = "soft_lutpair78" *) 
  LUT5 #(
    .INIT(32'h34347674)) 
    reset_time_out_i_4
       (.I0(rx_state[2]),
        .I1(rx_state[3]),
        .I2(rx_state[0]),
        .I3(\FSM_sequential_rx_state_reg[0]_0 ),
        .I4(rx_state[1]),
        .O(reset_time_out_i_4_n_0));
  FDSE #(
    .INIT(1'b0)) 
    reset_time_out_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(sync_data_valid_n_0),
        .Q(reset_time_out_reg_n_0),
        .S(pma_reset));
  LUT5 #(
    .INIT(32'hFEFF0010)) 
    run_phase_alignment_int_i_1__0
       (.I0(rx_state[2]),
        .I1(rx_state[1]),
        .I2(rx_state[3]),
        .I3(rx_state[0]),
        .I4(run_phase_alignment_int_reg_n_0),
        .O(run_phase_alignment_int_i_1__0_n_0));
  FDRE #(
    .INIT(1'b0)) 
    run_phase_alignment_int_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(run_phase_alignment_int_i_1__0_n_0),
        .Q(run_phase_alignment_int_reg_n_0),
        .R(pma_reset));
  FDRE #(
    .INIT(1'b0)) 
    run_phase_alignment_int_s3_reg
       (.C(rxuserclk),
        .CE(1'b1),
        .D(data_out_0),
        .Q(run_phase_alignment_int_s3_reg_n_0),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair79" *) 
  LUT2 #(
    .INIT(4'hB)) 
    rx_fsm_reset_done_int_i_5
       (.I0(rx_state[1]),
        .I1(rx_state[0]),
        .O(rx_fsm_reset_done_int_i_5_n_0));
  (* SOFT_HLUTNM = "soft_lutpair78" *) 
  LUT2 #(
    .INIT(4'h2)) 
    rx_fsm_reset_done_int_i_6
       (.I0(rx_state[3]),
        .I1(rx_state[2]),
        .O(rx_fsm_reset_done_int_i_6_n_0));
  FDRE #(
    .INIT(1'b0)) 
    rx_fsm_reset_done_int_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(sync_data_valid_n_1),
        .Q(data_in),
        .R(pma_reset));
  FDRE #(
    .INIT(1'b0)) 
    rx_fsm_reset_done_int_s3_reg
       (.C(rxuserclk),
        .CE(1'b1),
        .D(rx_fsm_reset_done_int_s2),
        .Q(rx_fsm_reset_done_int_s3),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    rxresetdone_s3_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(rxresetdone_s2),
        .Q(rxresetdone_s3),
        .R(1'b0));
  gmii_to_sgmii_bridge_sync_block__parameterized1_23 sync_RXRESETDONE
       (.data_out(rxresetdone_s2),
        .data_sync_reg1_0(data_sync_reg1),
        .independent_clock_bufg(independent_clock_bufg));
  gmii_to_sgmii_bridge_sync_block__parameterized1_24 sync_cplllock
       (.\FSM_sequential_rx_state_reg[1] (sync_cplllock_n_0),
        .Q(rx_state[3:1]),
        .cplllock(cplllock),
        .independent_clock_bufg(independent_clock_bufg),
        .rxresetdone_s3(rxresetdone_s3));
  gmii_to_sgmii_bridge_sync_block__parameterized1_25 sync_data_valid
       (.D({rx_state__0[3],rx_state__0[1:0]}),
        .E(sync_data_valid_n_5),
        .\FSM_sequential_rx_state_reg[0] (\FSM_sequential_rx_state[3]_i_3_n_0 ),
        .\FSM_sequential_rx_state_reg[0]_0 (\FSM_sequential_rx_state[3]_i_7_n_0 ),
        .\FSM_sequential_rx_state_reg[0]_1 (\FSM_sequential_rx_state_reg[0]_0 ),
        .\FSM_sequential_rx_state_reg[0]_2 (\FSM_sequential_rx_state[0]_i_2_n_0 ),
        .\FSM_sequential_rx_state_reg[0]_3 (init_wait_done_reg_n_0),
        .\FSM_sequential_rx_state_reg[1] (sync_data_valid_n_0),
        .\FSM_sequential_rx_state_reg[1]_0 (\FSM_sequential_rx_state[1]_i_3_n_0 ),
        .\FSM_sequential_rx_state_reg[3] (\FSM_sequential_rx_state[3]_i_9_n_0 ),
        .Q(rx_state),
        .data_in(data_in),
        .data_out(data_out),
        .independent_clock_bufg(independent_clock_bufg),
        .mmcm_lock_reclocked(mmcm_lock_reclocked),
        .reset_time_out_reg(sync_cplllock_n_0),
        .reset_time_out_reg_0(reset_time_out_i_3_n_0),
        .reset_time_out_reg_1(reset_time_out_i_4_n_0),
        .reset_time_out_reg_2(reset_time_out_reg_n_0),
        .rx_fsm_reset_done_int_reg(sync_data_valid_n_1),
        .rx_fsm_reset_done_int_reg_0(rx_fsm_reset_done_int_i_5_n_0),
        .rx_fsm_reset_done_int_reg_1(time_out_100us_reg_n_0),
        .rx_fsm_reset_done_int_reg_2(time_out_1us_reg_n_0),
        .rx_fsm_reset_done_int_reg_3(rx_fsm_reset_done_int_i_6_n_0),
        .time_out_wait_bypass_s3(time_out_wait_bypass_s3));
  gmii_to_sgmii_bridge_sync_block__parameterized1_26 sync_mmcm_lock_reclocked
       (.SR(sync_mmcm_lock_reclocked_n_0),
        .data_out(mmcm_lock_i),
        .independent_clock_bufg(independent_clock_bufg),
        .mmcm_locked(mmcm_locked));
  gmii_to_sgmii_bridge_sync_block__parameterized1_27 sync_run_phase_alignment_int
       (.data_in(run_phase_alignment_int_reg_n_0),
        .data_out(data_out_0),
        .rxuserclk(rxuserclk));
  gmii_to_sgmii_bridge_sync_block__parameterized1_28 sync_time_out_wait_bypass
       (.data_in(time_out_wait_bypass_reg_n_0),
        .data_out(time_out_wait_bypass_s2),
        .independent_clock_bufg(independent_clock_bufg));
  gmii_to_sgmii_bridge_sync_block__parameterized1_29 sync_tx_fsm_reset_done_int
       (.data_in(data_in),
        .data_out(rx_fsm_reset_done_int_s2),
        .rxuserclk(rxuserclk));
  LUT6 #(
    .INIT(64'hFFFFFFFF00000100)) 
    time_out_100us_i_1
       (.I0(time_out_2ms_i_4_n_0),
        .I1(time_out_counter_reg[17]),
        .I2(time_out_counter_reg[16]),
        .I3(time_out_100us_i_2_n_0),
        .I4(time_out_100us_i_3_n_0),
        .I5(time_out_100us_reg_n_0),
        .O(time_out_100us_i_1_n_0));
  LUT6 #(
    .INIT(64'h0000002000000000)) 
    time_out_100us_i_2
       (.I0(time_out_counter_reg[10]),
        .I1(time_out_counter_reg[12]),
        .I2(time_out_counter_reg[5]),
        .I3(time_out_counter_reg[7]),
        .I4(time_out_counter_reg[18]),
        .I5(time_out_counter_reg[14]),
        .O(time_out_100us_i_2_n_0));
  LUT5 #(
    .INIT(32'hFFFFFFFE)) 
    time_out_100us_i_3
       (.I0(time_out_counter_reg[4]),
        .I1(time_out_counter_reg[0]),
        .I2(time_out_counter_reg[1]),
        .I3(time_out_counter_reg[15]),
        .I4(time_out_counter_reg[13]),
        .O(time_out_100us_i_3_n_0));
  FDRE #(
    .INIT(1'b0)) 
    time_out_100us_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(time_out_100us_i_1_n_0),
        .Q(time_out_100us_reg_n_0),
        .R(reset_time_out_reg_n_0));
  LUT6 #(
    .INIT(64'hFFFFFFFF00100000)) 
    time_out_1us_i_1
       (.I0(time_out_2ms_i_2_n_0),
        .I1(time_out_1us_i_2_n_0),
        .I2(time_out_counter_reg[3]),
        .I3(time_out_counter_reg[2]),
        .I4(time_out_1us_i_3_n_0),
        .I5(time_out_1us_reg_n_0),
        .O(time_out_1us_i_1_n_0));
  (* SOFT_HLUTNM = "soft_lutpair87" *) 
  LUT2 #(
    .INIT(4'hE)) 
    time_out_1us_i_2
       (.I0(time_out_counter_reg[16]),
        .I1(time_out_counter_reg[17]),
        .O(time_out_1us_i_2_n_0));
  LUT6 #(
    .INIT(64'h0000000000000010)) 
    time_out_1us_i_3
       (.I0(time_out_counter_reg[9]),
        .I1(time_out_counter_reg[11]),
        .I2(time_out_counter_reg[6]),
        .I3(time_out_counter_reg[8]),
        .I4(time_out_counter_reg[18]),
        .I5(time_out_counter_reg[12]),
        .O(time_out_1us_i_3_n_0));
  FDRE #(
    .INIT(1'b0)) 
    time_out_1us_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(time_out_1us_i_1_n_0),
        .Q(time_out_1us_reg_n_0),
        .R(reset_time_out_reg_n_0));
  (* SOFT_HLUTNM = "soft_lutpair85" *) 
  LUT4 #(
    .INIT(16'hFF01)) 
    time_out_2ms_i_1
       (.I0(time_out_2ms_i_2_n_0),
        .I1(time_out_2ms_i_3__0_n_0),
        .I2(time_out_2ms_i_4_n_0),
        .I3(time_out_2ms_reg_n_0),
        .O(time_out_2ms_i_1_n_0));
  LUT5 #(
    .INIT(32'hFFFFFEFF)) 
    time_out_2ms_i_2
       (.I0(time_out_counter_reg[10]),
        .I1(time_out_counter_reg[14]),
        .I2(time_out_counter_reg[5]),
        .I3(time_out_counter_reg[7]),
        .I4(time_out_100us_i_3_n_0),
        .O(time_out_2ms_i_2_n_0));
  (* SOFT_HLUTNM = "soft_lutpair87" *) 
  LUT4 #(
    .INIT(16'hDFFF)) 
    time_out_2ms_i_3__0
       (.I0(time_out_counter_reg[12]),
        .I1(time_out_counter_reg[16]),
        .I2(time_out_counter_reg[18]),
        .I3(time_out_counter_reg[17]),
        .O(time_out_2ms_i_3__0_n_0));
  LUT6 #(
    .INIT(64'hFFFFFFFFFEFFFFFF)) 
    time_out_2ms_i_4
       (.I0(time_out_counter_reg[2]),
        .I1(time_out_counter_reg[3]),
        .I2(time_out_counter_reg[8]),
        .I3(time_out_counter_reg[9]),
        .I4(time_out_counter_reg[11]),
        .I5(time_out_counter_reg[6]),
        .O(time_out_2ms_i_4_n_0));
  FDRE #(
    .INIT(1'b0)) 
    time_out_2ms_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(time_out_2ms_i_1_n_0),
        .Q(time_out_2ms_reg_n_0),
        .R(reset_time_out_reg_n_0));
  LUT6 #(
    .INIT(64'hFFFFFFFFFFFFF7FF)) 
    \time_out_counter[0]_i_1 
       (.I0(time_out_counter_reg[17]),
        .I1(time_out_counter_reg[18]),
        .I2(time_out_counter_reg[16]),
        .I3(time_out_counter_reg[12]),
        .I4(time_out_2ms_i_2_n_0),
        .I5(time_out_2ms_i_4_n_0),
        .O(time_out_counter));
  LUT1 #(
    .INIT(2'h1)) 
    \time_out_counter[0]_i_3 
       (.I0(time_out_counter_reg[0]),
        .O(\time_out_counter[0]_i_3_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[0] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[0]_i_2__0_n_7 ),
        .Q(time_out_counter_reg[0]),
        .R(reset_time_out_reg_n_0));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \time_out_counter_reg[0]_i_2__0 
       (.CI(1'b0),
        .CO({\time_out_counter_reg[0]_i_2__0_n_0 ,\time_out_counter_reg[0]_i_2__0_n_1 ,\time_out_counter_reg[0]_i_2__0_n_2 ,\time_out_counter_reg[0]_i_2__0_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b1}),
        .O({\time_out_counter_reg[0]_i_2__0_n_4 ,\time_out_counter_reg[0]_i_2__0_n_5 ,\time_out_counter_reg[0]_i_2__0_n_6 ,\time_out_counter_reg[0]_i_2__0_n_7 }),
        .S({time_out_counter_reg[3:1],\time_out_counter[0]_i_3_n_0 }));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[10] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[8]_i_1__0_n_5 ),
        .Q(time_out_counter_reg[10]),
        .R(reset_time_out_reg_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[11] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[8]_i_1__0_n_4 ),
        .Q(time_out_counter_reg[11]),
        .R(reset_time_out_reg_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[12] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[12]_i_1__0_n_7 ),
        .Q(time_out_counter_reg[12]),
        .R(reset_time_out_reg_n_0));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \time_out_counter_reg[12]_i_1__0 
       (.CI(\time_out_counter_reg[8]_i_1__0_n_0 ),
        .CO({\time_out_counter_reg[12]_i_1__0_n_0 ,\time_out_counter_reg[12]_i_1__0_n_1 ,\time_out_counter_reg[12]_i_1__0_n_2 ,\time_out_counter_reg[12]_i_1__0_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\time_out_counter_reg[12]_i_1__0_n_4 ,\time_out_counter_reg[12]_i_1__0_n_5 ,\time_out_counter_reg[12]_i_1__0_n_6 ,\time_out_counter_reg[12]_i_1__0_n_7 }),
        .S(time_out_counter_reg[15:12]));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[13] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[12]_i_1__0_n_6 ),
        .Q(time_out_counter_reg[13]),
        .R(reset_time_out_reg_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[14] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[12]_i_1__0_n_5 ),
        .Q(time_out_counter_reg[14]),
        .R(reset_time_out_reg_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[15] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[12]_i_1__0_n_4 ),
        .Q(time_out_counter_reg[15]),
        .R(reset_time_out_reg_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[16] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[16]_i_1__0_n_7 ),
        .Q(time_out_counter_reg[16]),
        .R(reset_time_out_reg_n_0));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \time_out_counter_reg[16]_i_1__0 
       (.CI(\time_out_counter_reg[12]_i_1__0_n_0 ),
        .CO({\NLW_time_out_counter_reg[16]_i_1__0_CO_UNCONNECTED [3:2],\time_out_counter_reg[16]_i_1__0_n_2 ,\time_out_counter_reg[16]_i_1__0_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\NLW_time_out_counter_reg[16]_i_1__0_O_UNCONNECTED [3],\time_out_counter_reg[16]_i_1__0_n_5 ,\time_out_counter_reg[16]_i_1__0_n_6 ,\time_out_counter_reg[16]_i_1__0_n_7 }),
        .S({1'b0,time_out_counter_reg[18:16]}));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[17] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[16]_i_1__0_n_6 ),
        .Q(time_out_counter_reg[17]),
        .R(reset_time_out_reg_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[18] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[16]_i_1__0_n_5 ),
        .Q(time_out_counter_reg[18]),
        .R(reset_time_out_reg_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[1] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[0]_i_2__0_n_6 ),
        .Q(time_out_counter_reg[1]),
        .R(reset_time_out_reg_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[2] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[0]_i_2__0_n_5 ),
        .Q(time_out_counter_reg[2]),
        .R(reset_time_out_reg_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[3] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[0]_i_2__0_n_4 ),
        .Q(time_out_counter_reg[3]),
        .R(reset_time_out_reg_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[4] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[4]_i_1__0_n_7 ),
        .Q(time_out_counter_reg[4]),
        .R(reset_time_out_reg_n_0));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \time_out_counter_reg[4]_i_1__0 
       (.CI(\time_out_counter_reg[0]_i_2__0_n_0 ),
        .CO({\time_out_counter_reg[4]_i_1__0_n_0 ,\time_out_counter_reg[4]_i_1__0_n_1 ,\time_out_counter_reg[4]_i_1__0_n_2 ,\time_out_counter_reg[4]_i_1__0_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\time_out_counter_reg[4]_i_1__0_n_4 ,\time_out_counter_reg[4]_i_1__0_n_5 ,\time_out_counter_reg[4]_i_1__0_n_6 ,\time_out_counter_reg[4]_i_1__0_n_7 }),
        .S(time_out_counter_reg[7:4]));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[5] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[4]_i_1__0_n_6 ),
        .Q(time_out_counter_reg[5]),
        .R(reset_time_out_reg_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[6] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[4]_i_1__0_n_5 ),
        .Q(time_out_counter_reg[6]),
        .R(reset_time_out_reg_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[7] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[4]_i_1__0_n_4 ),
        .Q(time_out_counter_reg[7]),
        .R(reset_time_out_reg_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[8] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[8]_i_1__0_n_7 ),
        .Q(time_out_counter_reg[8]),
        .R(reset_time_out_reg_n_0));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \time_out_counter_reg[8]_i_1__0 
       (.CI(\time_out_counter_reg[4]_i_1__0_n_0 ),
        .CO({\time_out_counter_reg[8]_i_1__0_n_0 ,\time_out_counter_reg[8]_i_1__0_n_1 ,\time_out_counter_reg[8]_i_1__0_n_2 ,\time_out_counter_reg[8]_i_1__0_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\time_out_counter_reg[8]_i_1__0_n_4 ,\time_out_counter_reg[8]_i_1__0_n_5 ,\time_out_counter_reg[8]_i_1__0_n_6 ,\time_out_counter_reg[8]_i_1__0_n_7 }),
        .S(time_out_counter_reg[11:8]));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[9] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[8]_i_1__0_n_6 ),
        .Q(time_out_counter_reg[9]),
        .R(reset_time_out_reg_n_0));
  LUT4 #(
    .INIT(16'hAB00)) 
    time_out_wait_bypass_i_1
       (.I0(time_out_wait_bypass_reg_n_0),
        .I1(rx_fsm_reset_done_int_s3),
        .I2(time_out_wait_bypass_i_2__0_n_0),
        .I3(run_phase_alignment_int_s3_reg_n_0),
        .O(time_out_wait_bypass_i_1_n_0));
  LUT5 #(
    .INIT(32'hFBFFFFFF)) 
    time_out_wait_bypass_i_2__0
       (.I0(time_out_wait_bypass_i_3__0_n_0),
        .I1(wait_bypass_count_reg[1]),
        .I2(wait_bypass_count_reg[11]),
        .I3(wait_bypass_count_reg[0]),
        .I4(time_out_wait_bypass_i_4__0_n_0),
        .O(time_out_wait_bypass_i_2__0_n_0));
  LUT4 #(
    .INIT(16'hDFFF)) 
    time_out_wait_bypass_i_3__0
       (.I0(wait_bypass_count_reg[9]),
        .I1(wait_bypass_count_reg[4]),
        .I2(wait_bypass_count_reg[12]),
        .I3(wait_bypass_count_reg[2]),
        .O(time_out_wait_bypass_i_3__0_n_0));
  LUT6 #(
    .INIT(64'h0000000400000000)) 
    time_out_wait_bypass_i_4__0
       (.I0(wait_bypass_count_reg[5]),
        .I1(wait_bypass_count_reg[7]),
        .I2(wait_bypass_count_reg[3]),
        .I3(wait_bypass_count_reg[6]),
        .I4(wait_bypass_count_reg[10]),
        .I5(wait_bypass_count_reg[8]),
        .O(time_out_wait_bypass_i_4__0_n_0));
  FDRE #(
    .INIT(1'b0)) 
    time_out_wait_bypass_reg
       (.C(rxuserclk),
        .CE(1'b1),
        .D(time_out_wait_bypass_i_1_n_0),
        .Q(time_out_wait_bypass_reg_n_0),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    time_out_wait_bypass_s3_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(time_out_wait_bypass_s2),
        .Q(time_out_wait_bypass_s3),
        .R(1'b0));
  (* COMPARATOR_THRESHOLD = "11" *) 
  CARRY4 time_tlock_max1_carry
       (.CI(1'b0),
        .CO({time_tlock_max1_carry_n_0,time_tlock_max1_carry_n_1,time_tlock_max1_carry_n_2,time_tlock_max1_carry_n_3}),
        .CYINIT(1'b0),
        .DI({time_tlock_max1_carry_i_1_n_0,time_tlock_max1_carry_i_2_n_0,time_tlock_max1_carry_i_3_n_0,time_tlock_max1_carry_i_4_n_0}),
        .O(NLW_time_tlock_max1_carry_O_UNCONNECTED[3:0]),
        .S({time_tlock_max1_carry_i_5_n_0,time_tlock_max1_carry_i_6_n_0,time_tlock_max1_carry_i_7_n_0,time_tlock_max1_carry_i_8_n_0}));
  (* COMPARATOR_THRESHOLD = "11" *) 
  CARRY4 time_tlock_max1_carry__0
       (.CI(time_tlock_max1_carry_n_0),
        .CO({time_tlock_max1_carry__0_n_0,time_tlock_max1_carry__0_n_1,time_tlock_max1_carry__0_n_2,time_tlock_max1_carry__0_n_3}),
        .CYINIT(1'b0),
        .DI({time_out_counter_reg[15],time_tlock_max1_carry__0_i_1_n_0,1'b0,time_tlock_max1_carry__0_i_2_n_0}),
        .O(NLW_time_tlock_max1_carry__0_O_UNCONNECTED[3:0]),
        .S({time_tlock_max1_carry__0_i_3_n_0,time_tlock_max1_carry__0_i_4_n_0,time_tlock_max1_carry__0_i_5_n_0,time_tlock_max1_carry__0_i_6_n_0}));
  LUT2 #(
    .INIT(4'hE)) 
    time_tlock_max1_carry__0_i_1
       (.I0(time_out_counter_reg[12]),
        .I1(time_out_counter_reg[13]),
        .O(time_tlock_max1_carry__0_i_1_n_0));
  LUT2 #(
    .INIT(4'h8)) 
    time_tlock_max1_carry__0_i_2
       (.I0(time_out_counter_reg[8]),
        .I1(time_out_counter_reg[9]),
        .O(time_tlock_max1_carry__0_i_2_n_0));
  LUT2 #(
    .INIT(4'h2)) 
    time_tlock_max1_carry__0_i_3
       (.I0(time_out_counter_reg[14]),
        .I1(time_out_counter_reg[15]),
        .O(time_tlock_max1_carry__0_i_3_n_0));
  LUT2 #(
    .INIT(4'h1)) 
    time_tlock_max1_carry__0_i_4
       (.I0(time_out_counter_reg[13]),
        .I1(time_out_counter_reg[12]),
        .O(time_tlock_max1_carry__0_i_4_n_0));
  LUT2 #(
    .INIT(4'h8)) 
    time_tlock_max1_carry__0_i_5
       (.I0(time_out_counter_reg[10]),
        .I1(time_out_counter_reg[11]),
        .O(time_tlock_max1_carry__0_i_5_n_0));
  LUT2 #(
    .INIT(4'h2)) 
    time_tlock_max1_carry__0_i_6
       (.I0(time_out_counter_reg[9]),
        .I1(time_out_counter_reg[8]),
        .O(time_tlock_max1_carry__0_i_6_n_0));
  (* COMPARATOR_THRESHOLD = "11" *) 
  CARRY4 time_tlock_max1_carry__1
       (.CI(time_tlock_max1_carry__0_n_0),
        .CO({NLW_time_tlock_max1_carry__1_CO_UNCONNECTED[3:2],time_tlock_max1,time_tlock_max1_carry__1_n_3}),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,time_out_counter_reg[18],time_tlock_max1_carry__1_i_1_n_0}),
        .O(NLW_time_tlock_max1_carry__1_O_UNCONNECTED[3:0]),
        .S({1'b0,1'b0,time_tlock_max1_carry__1_i_2_n_0,time_tlock_max1_carry__1_i_3_n_0}));
  LUT2 #(
    .INIT(4'hE)) 
    time_tlock_max1_carry__1_i_1
       (.I0(time_out_counter_reg[16]),
        .I1(time_out_counter_reg[17]),
        .O(time_tlock_max1_carry__1_i_1_n_0));
  LUT1 #(
    .INIT(2'h1)) 
    time_tlock_max1_carry__1_i_2
       (.I0(time_out_counter_reg[18]),
        .O(time_tlock_max1_carry__1_i_2_n_0));
  LUT2 #(
    .INIT(4'h1)) 
    time_tlock_max1_carry__1_i_3
       (.I0(time_out_counter_reg[17]),
        .I1(time_out_counter_reg[16]),
        .O(time_tlock_max1_carry__1_i_3_n_0));
  LUT2 #(
    .INIT(4'hE)) 
    time_tlock_max1_carry_i_1
       (.I0(time_out_counter_reg[6]),
        .I1(time_out_counter_reg[7]),
        .O(time_tlock_max1_carry_i_1_n_0));
  LUT2 #(
    .INIT(4'h8)) 
    time_tlock_max1_carry_i_2
       (.I0(time_out_counter_reg[4]),
        .I1(time_out_counter_reg[5]),
        .O(time_tlock_max1_carry_i_2_n_0));
  LUT2 #(
    .INIT(4'hE)) 
    time_tlock_max1_carry_i_3
       (.I0(time_out_counter_reg[2]),
        .I1(time_out_counter_reg[3]),
        .O(time_tlock_max1_carry_i_3_n_0));
  LUT2 #(
    .INIT(4'hE)) 
    time_tlock_max1_carry_i_4
       (.I0(time_out_counter_reg[0]),
        .I1(time_out_counter_reg[1]),
        .O(time_tlock_max1_carry_i_4_n_0));
  LUT2 #(
    .INIT(4'h1)) 
    time_tlock_max1_carry_i_5
       (.I0(time_out_counter_reg[7]),
        .I1(time_out_counter_reg[6]),
        .O(time_tlock_max1_carry_i_5_n_0));
  LUT2 #(
    .INIT(4'h2)) 
    time_tlock_max1_carry_i_6
       (.I0(time_out_counter_reg[5]),
        .I1(time_out_counter_reg[4]),
        .O(time_tlock_max1_carry_i_6_n_0));
  LUT2 #(
    .INIT(4'h1)) 
    time_tlock_max1_carry_i_7
       (.I0(time_out_counter_reg[3]),
        .I1(time_out_counter_reg[2]),
        .O(time_tlock_max1_carry_i_7_n_0));
  LUT2 #(
    .INIT(4'h1)) 
    time_tlock_max1_carry_i_8
       (.I0(time_out_counter_reg[1]),
        .I1(time_out_counter_reg[0]),
        .O(time_tlock_max1_carry_i_8_n_0));
  (* SOFT_HLUTNM = "soft_lutpair88" *) 
  LUT3 #(
    .INIT(8'hF8)) 
    time_tlock_max_i_1
       (.I0(check_tlock_max_reg_n_0),
        .I1(time_tlock_max1),
        .I2(time_tlock_max),
        .O(time_tlock_max_i_1_n_0));
  FDRE #(
    .INIT(1'b0)) 
    time_tlock_max_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(time_tlock_max_i_1_n_0),
        .Q(time_tlock_max),
        .R(reset_time_out_reg_n_0));
  LUT1 #(
    .INIT(2'h1)) 
    \wait_bypass_count[0]_i_1__0 
       (.I0(run_phase_alignment_int_s3_reg_n_0),
        .O(\wait_bypass_count[0]_i_1__0_n_0 ));
  LUT2 #(
    .INIT(4'h2)) 
    \wait_bypass_count[0]_i_2__0 
       (.I0(time_out_wait_bypass_i_2__0_n_0),
        .I1(rx_fsm_reset_done_int_s3),
        .O(\wait_bypass_count[0]_i_2__0_n_0 ));
  LUT1 #(
    .INIT(2'h1)) 
    \wait_bypass_count[0]_i_4__0 
       (.I0(wait_bypass_count_reg[0]),
        .O(\wait_bypass_count[0]_i_4__0_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[0] 
       (.C(rxuserclk),
        .CE(\wait_bypass_count[0]_i_2__0_n_0 ),
        .D(\wait_bypass_count_reg[0]_i_3__0_n_7 ),
        .Q(wait_bypass_count_reg[0]),
        .R(\wait_bypass_count[0]_i_1__0_n_0 ));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \wait_bypass_count_reg[0]_i_3__0 
       (.CI(1'b0),
        .CO({\wait_bypass_count_reg[0]_i_3__0_n_0 ,\wait_bypass_count_reg[0]_i_3__0_n_1 ,\wait_bypass_count_reg[0]_i_3__0_n_2 ,\wait_bypass_count_reg[0]_i_3__0_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b1}),
        .O({\wait_bypass_count_reg[0]_i_3__0_n_4 ,\wait_bypass_count_reg[0]_i_3__0_n_5 ,\wait_bypass_count_reg[0]_i_3__0_n_6 ,\wait_bypass_count_reg[0]_i_3__0_n_7 }),
        .S({wait_bypass_count_reg[3:1],\wait_bypass_count[0]_i_4__0_n_0 }));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[10] 
       (.C(rxuserclk),
        .CE(\wait_bypass_count[0]_i_2__0_n_0 ),
        .D(\wait_bypass_count_reg[8]_i_1__0_n_5 ),
        .Q(wait_bypass_count_reg[10]),
        .R(\wait_bypass_count[0]_i_1__0_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[11] 
       (.C(rxuserclk),
        .CE(\wait_bypass_count[0]_i_2__0_n_0 ),
        .D(\wait_bypass_count_reg[8]_i_1__0_n_4 ),
        .Q(wait_bypass_count_reg[11]),
        .R(\wait_bypass_count[0]_i_1__0_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[12] 
       (.C(rxuserclk),
        .CE(\wait_bypass_count[0]_i_2__0_n_0 ),
        .D(\wait_bypass_count_reg[12]_i_1__0_n_7 ),
        .Q(wait_bypass_count_reg[12]),
        .R(\wait_bypass_count[0]_i_1__0_n_0 ));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \wait_bypass_count_reg[12]_i_1__0 
       (.CI(\wait_bypass_count_reg[8]_i_1__0_n_0 ),
        .CO(\NLW_wait_bypass_count_reg[12]_i_1__0_CO_UNCONNECTED [3:0]),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\NLW_wait_bypass_count_reg[12]_i_1__0_O_UNCONNECTED [3:1],\wait_bypass_count_reg[12]_i_1__0_n_7 }),
        .S({1'b0,1'b0,1'b0,wait_bypass_count_reg[12]}));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[1] 
       (.C(rxuserclk),
        .CE(\wait_bypass_count[0]_i_2__0_n_0 ),
        .D(\wait_bypass_count_reg[0]_i_3__0_n_6 ),
        .Q(wait_bypass_count_reg[1]),
        .R(\wait_bypass_count[0]_i_1__0_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[2] 
       (.C(rxuserclk),
        .CE(\wait_bypass_count[0]_i_2__0_n_0 ),
        .D(\wait_bypass_count_reg[0]_i_3__0_n_5 ),
        .Q(wait_bypass_count_reg[2]),
        .R(\wait_bypass_count[0]_i_1__0_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[3] 
       (.C(rxuserclk),
        .CE(\wait_bypass_count[0]_i_2__0_n_0 ),
        .D(\wait_bypass_count_reg[0]_i_3__0_n_4 ),
        .Q(wait_bypass_count_reg[3]),
        .R(\wait_bypass_count[0]_i_1__0_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[4] 
       (.C(rxuserclk),
        .CE(\wait_bypass_count[0]_i_2__0_n_0 ),
        .D(\wait_bypass_count_reg[4]_i_1__0_n_7 ),
        .Q(wait_bypass_count_reg[4]),
        .R(\wait_bypass_count[0]_i_1__0_n_0 ));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \wait_bypass_count_reg[4]_i_1__0 
       (.CI(\wait_bypass_count_reg[0]_i_3__0_n_0 ),
        .CO({\wait_bypass_count_reg[4]_i_1__0_n_0 ,\wait_bypass_count_reg[4]_i_1__0_n_1 ,\wait_bypass_count_reg[4]_i_1__0_n_2 ,\wait_bypass_count_reg[4]_i_1__0_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\wait_bypass_count_reg[4]_i_1__0_n_4 ,\wait_bypass_count_reg[4]_i_1__0_n_5 ,\wait_bypass_count_reg[4]_i_1__0_n_6 ,\wait_bypass_count_reg[4]_i_1__0_n_7 }),
        .S(wait_bypass_count_reg[7:4]));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[5] 
       (.C(rxuserclk),
        .CE(\wait_bypass_count[0]_i_2__0_n_0 ),
        .D(\wait_bypass_count_reg[4]_i_1__0_n_6 ),
        .Q(wait_bypass_count_reg[5]),
        .R(\wait_bypass_count[0]_i_1__0_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[6] 
       (.C(rxuserclk),
        .CE(\wait_bypass_count[0]_i_2__0_n_0 ),
        .D(\wait_bypass_count_reg[4]_i_1__0_n_5 ),
        .Q(wait_bypass_count_reg[6]),
        .R(\wait_bypass_count[0]_i_1__0_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[7] 
       (.C(rxuserclk),
        .CE(\wait_bypass_count[0]_i_2__0_n_0 ),
        .D(\wait_bypass_count_reg[4]_i_1__0_n_4 ),
        .Q(wait_bypass_count_reg[7]),
        .R(\wait_bypass_count[0]_i_1__0_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[8] 
       (.C(rxuserclk),
        .CE(\wait_bypass_count[0]_i_2__0_n_0 ),
        .D(\wait_bypass_count_reg[8]_i_1__0_n_7 ),
        .Q(wait_bypass_count_reg[8]),
        .R(\wait_bypass_count[0]_i_1__0_n_0 ));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \wait_bypass_count_reg[8]_i_1__0 
       (.CI(\wait_bypass_count_reg[4]_i_1__0_n_0 ),
        .CO({\wait_bypass_count_reg[8]_i_1__0_n_0 ,\wait_bypass_count_reg[8]_i_1__0_n_1 ,\wait_bypass_count_reg[8]_i_1__0_n_2 ,\wait_bypass_count_reg[8]_i_1__0_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\wait_bypass_count_reg[8]_i_1__0_n_4 ,\wait_bypass_count_reg[8]_i_1__0_n_5 ,\wait_bypass_count_reg[8]_i_1__0_n_6 ,\wait_bypass_count_reg[8]_i_1__0_n_7 }),
        .S(wait_bypass_count_reg[11:8]));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[9] 
       (.C(rxuserclk),
        .CE(\wait_bypass_count[0]_i_2__0_n_0 ),
        .D(\wait_bypass_count_reg[8]_i_1__0_n_6 ),
        .Q(wait_bypass_count_reg[9]),
        .R(\wait_bypass_count[0]_i_1__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair91" *) 
  LUT1 #(
    .INIT(2'h1)) 
    \wait_time_cnt[0]_i_1__0 
       (.I0(wait_time_cnt_reg[0]),
        .O(wait_time_cnt0__0));
  (* SOFT_HLUTNM = "soft_lutpair91" *) 
  LUT2 #(
    .INIT(4'h9)) 
    \wait_time_cnt[1]_i_1__0 
       (.I0(wait_time_cnt_reg[0]),
        .I1(wait_time_cnt_reg[1]),
        .O(\wait_time_cnt[1]_i_1__0_n_0 ));
  LUT3 #(
    .INIT(8'hE1)) 
    \wait_time_cnt[2]_i_1__0 
       (.I0(wait_time_cnt_reg[1]),
        .I1(wait_time_cnt_reg[0]),
        .I2(wait_time_cnt_reg[2]),
        .O(\wait_time_cnt[2]_i_1__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair81" *) 
  LUT4 #(
    .INIT(16'hFE01)) 
    \wait_time_cnt[3]_i_1__0 
       (.I0(wait_time_cnt_reg[2]),
        .I1(wait_time_cnt_reg[0]),
        .I2(wait_time_cnt_reg[1]),
        .I3(wait_time_cnt_reg[3]),
        .O(\wait_time_cnt[3]_i_1__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair81" *) 
  LUT5 #(
    .INIT(32'hFFFE0001)) 
    \wait_time_cnt[4]_i_1__0 
       (.I0(wait_time_cnt_reg[3]),
        .I1(wait_time_cnt_reg[1]),
        .I2(wait_time_cnt_reg[0]),
        .I3(wait_time_cnt_reg[2]),
        .I4(wait_time_cnt_reg[4]),
        .O(\wait_time_cnt[4]_i_1__0_n_0 ));
  LUT6 #(
    .INIT(64'hFFFFFFFE00000001)) 
    \wait_time_cnt[5]_i_1__0 
       (.I0(wait_time_cnt_reg[4]),
        .I1(wait_time_cnt_reg[2]),
        .I2(wait_time_cnt_reg[0]),
        .I3(wait_time_cnt_reg[1]),
        .I4(wait_time_cnt_reg[3]),
        .I5(wait_time_cnt_reg[5]),
        .O(\wait_time_cnt[5]_i_1__0_n_0 ));
  LUT3 #(
    .INIT(8'h02)) 
    \wait_time_cnt[6]_i_1 
       (.I0(rx_state[0]),
        .I1(rx_state[1]),
        .I2(rx_state[3]),
        .O(\wait_time_cnt[6]_i_1_n_0 ));
  LUT2 #(
    .INIT(4'hE)) 
    \wait_time_cnt[6]_i_2__0 
       (.I0(\wait_time_cnt[6]_i_4__0_n_0 ),
        .I1(wait_time_cnt_reg[6]),
        .O(\wait_time_cnt[6]_i_2__0_n_0 ));
  LUT2 #(
    .INIT(4'h9)) 
    \wait_time_cnt[6]_i_3__0 
       (.I0(\wait_time_cnt[6]_i_4__0_n_0 ),
        .I1(wait_time_cnt_reg[6]),
        .O(\wait_time_cnt[6]_i_3__0_n_0 ));
  LUT6 #(
    .INIT(64'hFFFFFFFFFFFFFFFE)) 
    \wait_time_cnt[6]_i_4__0 
       (.I0(wait_time_cnt_reg[4]),
        .I1(wait_time_cnt_reg[2]),
        .I2(wait_time_cnt_reg[0]),
        .I3(wait_time_cnt_reg[1]),
        .I4(wait_time_cnt_reg[3]),
        .I5(wait_time_cnt_reg[5]),
        .O(\wait_time_cnt[6]_i_4__0_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \wait_time_cnt_reg[0] 
       (.C(independent_clock_bufg),
        .CE(\wait_time_cnt[6]_i_2__0_n_0 ),
        .D(wait_time_cnt0__0),
        .Q(wait_time_cnt_reg[0]),
        .R(\wait_time_cnt[6]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \wait_time_cnt_reg[1] 
       (.C(independent_clock_bufg),
        .CE(\wait_time_cnt[6]_i_2__0_n_0 ),
        .D(\wait_time_cnt[1]_i_1__0_n_0 ),
        .Q(wait_time_cnt_reg[1]),
        .R(\wait_time_cnt[6]_i_1_n_0 ));
  FDSE #(
    .INIT(1'b0)) 
    \wait_time_cnt_reg[2] 
       (.C(independent_clock_bufg),
        .CE(\wait_time_cnt[6]_i_2__0_n_0 ),
        .D(\wait_time_cnt[2]_i_1__0_n_0 ),
        .Q(wait_time_cnt_reg[2]),
        .S(\wait_time_cnt[6]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \wait_time_cnt_reg[3] 
       (.C(independent_clock_bufg),
        .CE(\wait_time_cnt[6]_i_2__0_n_0 ),
        .D(\wait_time_cnt[3]_i_1__0_n_0 ),
        .Q(wait_time_cnt_reg[3]),
        .R(\wait_time_cnt[6]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \wait_time_cnt_reg[4] 
       (.C(independent_clock_bufg),
        .CE(\wait_time_cnt[6]_i_2__0_n_0 ),
        .D(\wait_time_cnt[4]_i_1__0_n_0 ),
        .Q(wait_time_cnt_reg[4]),
        .R(\wait_time_cnt[6]_i_1_n_0 ));
  FDSE #(
    .INIT(1'b0)) 
    \wait_time_cnt_reg[5] 
       (.C(independent_clock_bufg),
        .CE(\wait_time_cnt[6]_i_2__0_n_0 ),
        .D(\wait_time_cnt[5]_i_1__0_n_0 ),
        .Q(wait_time_cnt_reg[5]),
        .S(\wait_time_cnt[6]_i_1_n_0 ));
  FDSE #(
    .INIT(1'b0)) 
    \wait_time_cnt_reg[6] 
       (.C(independent_clock_bufg),
        .CE(\wait_time_cnt[6]_i_2__0_n_0 ),
        .D(\wait_time_cnt[6]_i_3__0_n_0 ),
        .Q(wait_time_cnt_reg[6]),
        .S(\wait_time_cnt[6]_i_1_n_0 ));
endmodule

module gmii_to_sgmii_bridge_TX_STARTUP_FSM
   (mmcm_reset,
    gt0_cpllreset_t,
    data_in,
    gt0_txuserrdy_t,
    gt0_gttxreset_in0_out,
    independent_clock_bufg,
    userclk,
    pma_reset,
    gtxe2_i,
    gt0_cpllrefclklost_i,
    data_sync_reg1,
    mmcm_locked,
    cplllock);
  output mmcm_reset;
  output gt0_cpllreset_t;
  output data_in;
  output gt0_txuserrdy_t;
  output gt0_gttxreset_in0_out;
  input independent_clock_bufg;
  input userclk;
  input pma_reset;
  input gtxe2_i;
  input gt0_cpllrefclklost_i;
  input data_sync_reg1;
  input mmcm_locked;
  input cplllock;

  wire CPLL_RESET_i_1_n_0;
  wire CPLL_RESET_i_2_n_0;
  wire \FSM_sequential_tx_state[0]_i_2_n_0 ;
  wire \FSM_sequential_tx_state[0]_i_3_n_0 ;
  wire \FSM_sequential_tx_state[2]_i_2_n_0 ;
  wire \FSM_sequential_tx_state[3]_i_3_n_0 ;
  wire \FSM_sequential_tx_state[3]_i_4_n_0 ;
  wire \FSM_sequential_tx_state[3]_i_6_n_0 ;
  wire \FSM_sequential_tx_state[3]_i_7_n_0 ;
  wire \FSM_sequential_tx_state[3]_i_8_n_0 ;
  wire GTTXRESET;
  wire MMCM_RESET_i_1_n_0;
  wire TXUSERRDY_i_1_n_0;
  wire clear;
  wire cplllock;
  wire data_in;
  wire data_out;
  wire data_sync_reg1;
  wire gt0_cpllrefclklost_i;
  wire gt0_cpllreset_t;
  wire gt0_gttxreset_in0_out;
  wire gt0_txuserrdy_t;
  wire gttxreset_i_i_1_n_0;
  wire gtxe2_i;
  wire independent_clock_bufg;
  wire \init_wait_count[0]_i_1_n_0 ;
  wire \init_wait_count[6]_i_1_n_0 ;
  wire \init_wait_count[6]_i_3_n_0 ;
  wire [6:0]init_wait_count_reg;
  wire init_wait_done_i_1_n_0;
  wire init_wait_done_reg_n_0;
  wire \mmcm_lock_count[2]_i_1_n_0 ;
  wire \mmcm_lock_count[3]_i_1_n_0 ;
  wire \mmcm_lock_count[4]_i_1_n_0 ;
  wire \mmcm_lock_count[5]_i_1_n_0 ;
  wire \mmcm_lock_count[6]_i_1_n_0 ;
  wire \mmcm_lock_count[7]_i_2_n_0 ;
  wire \mmcm_lock_count[7]_i_3_n_0 ;
  wire [7:0]mmcm_lock_count_reg;
  wire mmcm_lock_i;
  wire mmcm_lock_reclocked;
  wire mmcm_lock_reclocked_i_1_n_0;
  wire mmcm_lock_reclocked_i_2_n_0;
  wire mmcm_locked;
  wire mmcm_reset;
  wire [6:1]p_0_in;
  wire [1:0]p_0_in__0;
  wire pll_reset_asserted_i_1_n_0;
  wire pll_reset_asserted_i_2_n_0;
  wire pll_reset_asserted_reg_n_0;
  wire pma_reset;
  wire refclk_stable_count;
  wire \refclk_stable_count[0]_i_3_n_0 ;
  wire \refclk_stable_count[0]_i_4_n_0 ;
  wire \refclk_stable_count[0]_i_5_n_0 ;
  wire \refclk_stable_count[0]_i_6_n_0 ;
  wire \refclk_stable_count[0]_i_7_n_0 ;
  wire \refclk_stable_count[0]_i_8_n_0 ;
  wire \refclk_stable_count[0]_i_9_n_0 ;
  wire [31:0]refclk_stable_count_reg;
  wire \refclk_stable_count_reg[0]_i_2_n_0 ;
  wire \refclk_stable_count_reg[0]_i_2_n_1 ;
  wire \refclk_stable_count_reg[0]_i_2_n_2 ;
  wire \refclk_stable_count_reg[0]_i_2_n_3 ;
  wire \refclk_stable_count_reg[0]_i_2_n_4 ;
  wire \refclk_stable_count_reg[0]_i_2_n_5 ;
  wire \refclk_stable_count_reg[0]_i_2_n_6 ;
  wire \refclk_stable_count_reg[0]_i_2_n_7 ;
  wire \refclk_stable_count_reg[12]_i_1_n_0 ;
  wire \refclk_stable_count_reg[12]_i_1_n_1 ;
  wire \refclk_stable_count_reg[12]_i_1_n_2 ;
  wire \refclk_stable_count_reg[12]_i_1_n_3 ;
  wire \refclk_stable_count_reg[12]_i_1_n_4 ;
  wire \refclk_stable_count_reg[12]_i_1_n_5 ;
  wire \refclk_stable_count_reg[12]_i_1_n_6 ;
  wire \refclk_stable_count_reg[12]_i_1_n_7 ;
  wire \refclk_stable_count_reg[16]_i_1_n_0 ;
  wire \refclk_stable_count_reg[16]_i_1_n_1 ;
  wire \refclk_stable_count_reg[16]_i_1_n_2 ;
  wire \refclk_stable_count_reg[16]_i_1_n_3 ;
  wire \refclk_stable_count_reg[16]_i_1_n_4 ;
  wire \refclk_stable_count_reg[16]_i_1_n_5 ;
  wire \refclk_stable_count_reg[16]_i_1_n_6 ;
  wire \refclk_stable_count_reg[16]_i_1_n_7 ;
  wire \refclk_stable_count_reg[20]_i_1_n_0 ;
  wire \refclk_stable_count_reg[20]_i_1_n_1 ;
  wire \refclk_stable_count_reg[20]_i_1_n_2 ;
  wire \refclk_stable_count_reg[20]_i_1_n_3 ;
  wire \refclk_stable_count_reg[20]_i_1_n_4 ;
  wire \refclk_stable_count_reg[20]_i_1_n_5 ;
  wire \refclk_stable_count_reg[20]_i_1_n_6 ;
  wire \refclk_stable_count_reg[20]_i_1_n_7 ;
  wire \refclk_stable_count_reg[24]_i_1_n_0 ;
  wire \refclk_stable_count_reg[24]_i_1_n_1 ;
  wire \refclk_stable_count_reg[24]_i_1_n_2 ;
  wire \refclk_stable_count_reg[24]_i_1_n_3 ;
  wire \refclk_stable_count_reg[24]_i_1_n_4 ;
  wire \refclk_stable_count_reg[24]_i_1_n_5 ;
  wire \refclk_stable_count_reg[24]_i_1_n_6 ;
  wire \refclk_stable_count_reg[24]_i_1_n_7 ;
  wire \refclk_stable_count_reg[28]_i_1_n_1 ;
  wire \refclk_stable_count_reg[28]_i_1_n_2 ;
  wire \refclk_stable_count_reg[28]_i_1_n_3 ;
  wire \refclk_stable_count_reg[28]_i_1_n_4 ;
  wire \refclk_stable_count_reg[28]_i_1_n_5 ;
  wire \refclk_stable_count_reg[28]_i_1_n_6 ;
  wire \refclk_stable_count_reg[28]_i_1_n_7 ;
  wire \refclk_stable_count_reg[4]_i_1_n_0 ;
  wire \refclk_stable_count_reg[4]_i_1_n_1 ;
  wire \refclk_stable_count_reg[4]_i_1_n_2 ;
  wire \refclk_stable_count_reg[4]_i_1_n_3 ;
  wire \refclk_stable_count_reg[4]_i_1_n_4 ;
  wire \refclk_stable_count_reg[4]_i_1_n_5 ;
  wire \refclk_stable_count_reg[4]_i_1_n_6 ;
  wire \refclk_stable_count_reg[4]_i_1_n_7 ;
  wire \refclk_stable_count_reg[8]_i_1_n_0 ;
  wire \refclk_stable_count_reg[8]_i_1_n_1 ;
  wire \refclk_stable_count_reg[8]_i_1_n_2 ;
  wire \refclk_stable_count_reg[8]_i_1_n_3 ;
  wire \refclk_stable_count_reg[8]_i_1_n_4 ;
  wire \refclk_stable_count_reg[8]_i_1_n_5 ;
  wire \refclk_stable_count_reg[8]_i_1_n_6 ;
  wire \refclk_stable_count_reg[8]_i_1_n_7 ;
  wire refclk_stable_i_1_n_0;
  wire refclk_stable_i_2_n_0;
  wire refclk_stable_i_3_n_0;
  wire refclk_stable_i_4_n_0;
  wire refclk_stable_i_5_n_0;
  wire refclk_stable_i_6_n_0;
  wire refclk_stable_reg_n_0;
  wire reset_time_out;
  wire reset_time_out_i_2__0_n_0;
  wire run_phase_alignment_int_i_1_n_0;
  wire run_phase_alignment_int_reg_n_0;
  wire run_phase_alignment_int_s3;
  wire sel;
  wire sync_cplllock_n_0;
  wire sync_cplllock_n_1;
  wire sync_mmcm_lock_reclocked_n_0;
  wire time_out_2ms_i_1_n_0;
  wire time_out_2ms_i_2__0_n_0;
  wire time_out_2ms_i_3_n_0;
  wire time_out_2ms_i_4__0_n_0;
  wire time_out_2ms_i_5_n_0;
  wire time_out_2ms_reg_n_0;
  wire time_out_500us_i_1_n_0;
  wire time_out_500us_i_2_n_0;
  wire time_out_500us_reg_n_0;
  wire time_out_counter;
  wire \time_out_counter[0]_i_3__0_n_0 ;
  wire \time_out_counter[0]_i_4_n_0 ;
  wire [18:0]time_out_counter_reg;
  wire \time_out_counter_reg[0]_i_2_n_0 ;
  wire \time_out_counter_reg[0]_i_2_n_1 ;
  wire \time_out_counter_reg[0]_i_2_n_2 ;
  wire \time_out_counter_reg[0]_i_2_n_3 ;
  wire \time_out_counter_reg[0]_i_2_n_4 ;
  wire \time_out_counter_reg[0]_i_2_n_5 ;
  wire \time_out_counter_reg[0]_i_2_n_6 ;
  wire \time_out_counter_reg[0]_i_2_n_7 ;
  wire \time_out_counter_reg[12]_i_1_n_0 ;
  wire \time_out_counter_reg[12]_i_1_n_1 ;
  wire \time_out_counter_reg[12]_i_1_n_2 ;
  wire \time_out_counter_reg[12]_i_1_n_3 ;
  wire \time_out_counter_reg[12]_i_1_n_4 ;
  wire \time_out_counter_reg[12]_i_1_n_5 ;
  wire \time_out_counter_reg[12]_i_1_n_6 ;
  wire \time_out_counter_reg[12]_i_1_n_7 ;
  wire \time_out_counter_reg[16]_i_1_n_2 ;
  wire \time_out_counter_reg[16]_i_1_n_3 ;
  wire \time_out_counter_reg[16]_i_1_n_5 ;
  wire \time_out_counter_reg[16]_i_1_n_6 ;
  wire \time_out_counter_reg[16]_i_1_n_7 ;
  wire \time_out_counter_reg[4]_i_1_n_0 ;
  wire \time_out_counter_reg[4]_i_1_n_1 ;
  wire \time_out_counter_reg[4]_i_1_n_2 ;
  wire \time_out_counter_reg[4]_i_1_n_3 ;
  wire \time_out_counter_reg[4]_i_1_n_4 ;
  wire \time_out_counter_reg[4]_i_1_n_5 ;
  wire \time_out_counter_reg[4]_i_1_n_6 ;
  wire \time_out_counter_reg[4]_i_1_n_7 ;
  wire \time_out_counter_reg[8]_i_1_n_0 ;
  wire \time_out_counter_reg[8]_i_1_n_1 ;
  wire \time_out_counter_reg[8]_i_1_n_2 ;
  wire \time_out_counter_reg[8]_i_1_n_3 ;
  wire \time_out_counter_reg[8]_i_1_n_4 ;
  wire \time_out_counter_reg[8]_i_1_n_5 ;
  wire \time_out_counter_reg[8]_i_1_n_6 ;
  wire \time_out_counter_reg[8]_i_1_n_7 ;
  wire time_out_wait_bypass_i_1_n_0;
  wire time_out_wait_bypass_i_2_n_0;
  wire time_out_wait_bypass_i_3_n_0;
  wire time_out_wait_bypass_i_4_n_0;
  wire time_out_wait_bypass_i_5_n_0;
  wire time_out_wait_bypass_i_6_n_0;
  wire time_out_wait_bypass_reg_n_0;
  wire time_out_wait_bypass_s2;
  wire time_out_wait_bypass_s3;
  wire time_tlock_max_i_1_n_0;
  wire time_tlock_max_i_2_n_0;
  wire time_tlock_max_i_3_n_0;
  wire time_tlock_max_i_4_n_0;
  wire time_tlock_max_reg_n_0;
  wire tx_fsm_reset_done_int_i_1_n_0;
  wire tx_fsm_reset_done_int_s2;
  wire tx_fsm_reset_done_int_s3;
  wire [3:0]tx_state;
  wire [3:0]tx_state__0;
  wire txresetdone_s2;
  wire txresetdone_s3;
  wire userclk;
  wire \wait_bypass_count[0]_i_2_n_0 ;
  wire \wait_bypass_count[0]_i_4_n_0 ;
  wire [16:0]wait_bypass_count_reg;
  wire \wait_bypass_count_reg[0]_i_3_n_0 ;
  wire \wait_bypass_count_reg[0]_i_3_n_1 ;
  wire \wait_bypass_count_reg[0]_i_3_n_2 ;
  wire \wait_bypass_count_reg[0]_i_3_n_3 ;
  wire \wait_bypass_count_reg[0]_i_3_n_4 ;
  wire \wait_bypass_count_reg[0]_i_3_n_5 ;
  wire \wait_bypass_count_reg[0]_i_3_n_6 ;
  wire \wait_bypass_count_reg[0]_i_3_n_7 ;
  wire \wait_bypass_count_reg[12]_i_1_n_0 ;
  wire \wait_bypass_count_reg[12]_i_1_n_1 ;
  wire \wait_bypass_count_reg[12]_i_1_n_2 ;
  wire \wait_bypass_count_reg[12]_i_1_n_3 ;
  wire \wait_bypass_count_reg[12]_i_1_n_4 ;
  wire \wait_bypass_count_reg[12]_i_1_n_5 ;
  wire \wait_bypass_count_reg[12]_i_1_n_6 ;
  wire \wait_bypass_count_reg[12]_i_1_n_7 ;
  wire \wait_bypass_count_reg[16]_i_1_n_7 ;
  wire \wait_bypass_count_reg[4]_i_1_n_0 ;
  wire \wait_bypass_count_reg[4]_i_1_n_1 ;
  wire \wait_bypass_count_reg[4]_i_1_n_2 ;
  wire \wait_bypass_count_reg[4]_i_1_n_3 ;
  wire \wait_bypass_count_reg[4]_i_1_n_4 ;
  wire \wait_bypass_count_reg[4]_i_1_n_5 ;
  wire \wait_bypass_count_reg[4]_i_1_n_6 ;
  wire \wait_bypass_count_reg[4]_i_1_n_7 ;
  wire \wait_bypass_count_reg[8]_i_1_n_0 ;
  wire \wait_bypass_count_reg[8]_i_1_n_1 ;
  wire \wait_bypass_count_reg[8]_i_1_n_2 ;
  wire \wait_bypass_count_reg[8]_i_1_n_3 ;
  wire \wait_bypass_count_reg[8]_i_1_n_4 ;
  wire \wait_bypass_count_reg[8]_i_1_n_5 ;
  wire \wait_bypass_count_reg[8]_i_1_n_6 ;
  wire \wait_bypass_count_reg[8]_i_1_n_7 ;
  wire [0:0]wait_time_cnt0;
  wire wait_time_cnt0_0;
  wire \wait_time_cnt[1]_i_1_n_0 ;
  wire \wait_time_cnt[2]_i_1_n_0 ;
  wire \wait_time_cnt[3]_i_1_n_0 ;
  wire \wait_time_cnt[4]_i_1_n_0 ;
  wire \wait_time_cnt[5]_i_1_n_0 ;
  wire \wait_time_cnt[6]_i_3_n_0 ;
  wire \wait_time_cnt[6]_i_4_n_0 ;
  wire [6:0]wait_time_cnt_reg;
  wire [3:3]\NLW_refclk_stable_count_reg[28]_i_1_CO_UNCONNECTED ;
  wire [3:2]\NLW_time_out_counter_reg[16]_i_1_CO_UNCONNECTED ;
  wire [3:3]\NLW_time_out_counter_reg[16]_i_1_O_UNCONNECTED ;
  wire [3:0]\NLW_wait_bypass_count_reg[16]_i_1_CO_UNCONNECTED ;
  wire [3:1]\NLW_wait_bypass_count_reg[16]_i_1_O_UNCONNECTED ;

  LUT6 #(
    .INIT(64'hFFFFFF1F0000001F)) 
    CPLL_RESET_i_1
       (.I0(pll_reset_asserted_reg_n_0),
        .I1(gt0_cpllrefclklost_i),
        .I2(refclk_stable_reg_n_0),
        .I3(CPLL_RESET_i_2_n_0),
        .I4(\FSM_sequential_tx_state[0]_i_3_n_0 ),
        .I5(gt0_cpllreset_t),
        .O(CPLL_RESET_i_1_n_0));
  (* SOFT_HLUTNM = "soft_lutpair98" *) 
  LUT2 #(
    .INIT(4'hE)) 
    CPLL_RESET_i_2
       (.I0(tx_state[1]),
        .I1(tx_state[2]),
        .O(CPLL_RESET_i_2_n_0));
  FDRE #(
    .INIT(1'b0)) 
    CPLL_RESET_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(CPLL_RESET_i_1_n_0),
        .Q(gt0_cpllreset_t),
        .R(pma_reset));
  LUT6 #(
    .INIT(64'hF3FFF3F0F5F0F5F0)) 
    \FSM_sequential_tx_state[0]_i_1 
       (.I0(\FSM_sequential_tx_state[2]_i_2_n_0 ),
        .I1(\FSM_sequential_tx_state[0]_i_2_n_0 ),
        .I2(\FSM_sequential_tx_state[0]_i_3_n_0 ),
        .I3(tx_state[2]),
        .I4(time_out_2ms_reg_n_0),
        .I5(tx_state[1]),
        .O(tx_state__0[0]));
  (* SOFT_HLUTNM = "soft_lutpair93" *) 
  LUT2 #(
    .INIT(4'hB)) 
    \FSM_sequential_tx_state[0]_i_2 
       (.I0(reset_time_out),
        .I1(time_out_500us_reg_n_0),
        .O(\FSM_sequential_tx_state[0]_i_2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair97" *) 
  LUT2 #(
    .INIT(4'hB)) 
    \FSM_sequential_tx_state[0]_i_3 
       (.I0(tx_state[3]),
        .I1(tx_state[0]),
        .O(\FSM_sequential_tx_state[0]_i_3_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair94" *) 
  LUT5 #(
    .INIT(32'h005A001A)) 
    \FSM_sequential_tx_state[1]_i_1 
       (.I0(tx_state[1]),
        .I1(tx_state[2]),
        .I2(tx_state[0]),
        .I3(tx_state[3]),
        .I4(\FSM_sequential_tx_state[2]_i_2_n_0 ),
        .O(tx_state__0[1]));
  LUT6 #(
    .INIT(64'h04000C0C06020C0C)) 
    \FSM_sequential_tx_state[2]_i_1 
       (.I0(tx_state[1]),
        .I1(tx_state[2]),
        .I2(tx_state[3]),
        .I3(\FSM_sequential_tx_state[2]_i_2_n_0 ),
        .I4(tx_state[0]),
        .I5(time_out_2ms_reg_n_0),
        .O(tx_state__0[2]));
  LUT3 #(
    .INIT(8'hFD)) 
    \FSM_sequential_tx_state[2]_i_2 
       (.I0(time_tlock_max_reg_n_0),
        .I1(reset_time_out),
        .I2(mmcm_lock_reclocked),
        .O(\FSM_sequential_tx_state[2]_i_2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair93" *) 
  LUT5 #(
    .INIT(32'hF4FF4444)) 
    \FSM_sequential_tx_state[3]_i_2 
       (.I0(time_out_wait_bypass_s3),
        .I1(tx_state[3]),
        .I2(reset_time_out),
        .I3(time_out_500us_reg_n_0),
        .I4(\FSM_sequential_tx_state[3]_i_8_n_0 ),
        .O(tx_state__0[3]));
  LUT6 #(
    .INIT(64'h00BA000000000000)) 
    \FSM_sequential_tx_state[3]_i_3 
       (.I0(txresetdone_s3),
        .I1(reset_time_out),
        .I2(time_out_500us_reg_n_0),
        .I3(\FSM_sequential_tx_state[0]_i_3_n_0 ),
        .I4(tx_state[2]),
        .I5(tx_state[1]),
        .O(\FSM_sequential_tx_state[3]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'h0000000300FF00AA)) 
    \FSM_sequential_tx_state[3]_i_4 
       (.I0(init_wait_done_reg_n_0),
        .I1(\wait_time_cnt[6]_i_4_n_0 ),
        .I2(wait_time_cnt_reg[6]),
        .I3(tx_state[0]),
        .I4(tx_state[3]),
        .I5(CPLL_RESET_i_2_n_0),
        .O(\FSM_sequential_tx_state[3]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'h0404040400040000)) 
    \FSM_sequential_tx_state[3]_i_6 
       (.I0(tx_state[1]),
        .I1(tx_state[2]),
        .I2(\FSM_sequential_tx_state[0]_i_3_n_0 ),
        .I3(reset_time_out),
        .I4(time_tlock_max_reg_n_0),
        .I5(mmcm_lock_reclocked),
        .O(\FSM_sequential_tx_state[3]_i_6_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair94" *) 
  LUT4 #(
    .INIT(16'h1000)) 
    \FSM_sequential_tx_state[3]_i_7 
       (.I0(tx_state[2]),
        .I1(tx_state[3]),
        .I2(tx_state[0]),
        .I3(tx_state[1]),
        .O(\FSM_sequential_tx_state[3]_i_7_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair95" *) 
  LUT4 #(
    .INIT(16'h4000)) 
    \FSM_sequential_tx_state[3]_i_8 
       (.I0(tx_state[3]),
        .I1(tx_state[0]),
        .I2(tx_state[2]),
        .I3(tx_state[1]),
        .O(\FSM_sequential_tx_state[3]_i_8_n_0 ));
  (* FSM_ENCODED_STATES = "wait_for_txoutclk:0100,release_pll_reset:0011,wait_for_pll_lock:0010,assert_all_resets:0001,init:0000,wait_reset_done:0111,reset_fsm_done:1001,wait_for_txusrclk:0110,do_phase_alignment:1000,release_mmcm_reset:0101" *) 
  FDRE #(
    .INIT(1'b0)) 
    \FSM_sequential_tx_state_reg[0] 
       (.C(independent_clock_bufg),
        .CE(sync_cplllock_n_1),
        .D(tx_state__0[0]),
        .Q(tx_state[0]),
        .R(pma_reset));
  (* FSM_ENCODED_STATES = "wait_for_txoutclk:0100,release_pll_reset:0011,wait_for_pll_lock:0010,assert_all_resets:0001,init:0000,wait_reset_done:0111,reset_fsm_done:1001,wait_for_txusrclk:0110,do_phase_alignment:1000,release_mmcm_reset:0101" *) 
  FDRE #(
    .INIT(1'b0)) 
    \FSM_sequential_tx_state_reg[1] 
       (.C(independent_clock_bufg),
        .CE(sync_cplllock_n_1),
        .D(tx_state__0[1]),
        .Q(tx_state[1]),
        .R(pma_reset));
  (* FSM_ENCODED_STATES = "wait_for_txoutclk:0100,release_pll_reset:0011,wait_for_pll_lock:0010,assert_all_resets:0001,init:0000,wait_reset_done:0111,reset_fsm_done:1001,wait_for_txusrclk:0110,do_phase_alignment:1000,release_mmcm_reset:0101" *) 
  FDRE #(
    .INIT(1'b0)) 
    \FSM_sequential_tx_state_reg[2] 
       (.C(independent_clock_bufg),
        .CE(sync_cplllock_n_1),
        .D(tx_state__0[2]),
        .Q(tx_state[2]),
        .R(pma_reset));
  (* FSM_ENCODED_STATES = "wait_for_txoutclk:0100,release_pll_reset:0011,wait_for_pll_lock:0010,assert_all_resets:0001,init:0000,wait_reset_done:0111,reset_fsm_done:1001,wait_for_txusrclk:0110,do_phase_alignment:1000,release_mmcm_reset:0101" *) 
  FDRE #(
    .INIT(1'b0)) 
    \FSM_sequential_tx_state_reg[3] 
       (.C(independent_clock_bufg),
        .CE(sync_cplllock_n_1),
        .D(tx_state__0[3]),
        .Q(tx_state[3]),
        .R(pma_reset));
  (* SOFT_HLUTNM = "soft_lutpair96" *) 
  LUT5 #(
    .INIT(32'hFFF70004)) 
    MMCM_RESET_i_1
       (.I0(tx_state[2]),
        .I1(tx_state[0]),
        .I2(tx_state[3]),
        .I3(tx_state[1]),
        .I4(mmcm_reset),
        .O(MMCM_RESET_i_1_n_0));
  FDRE #(
    .INIT(1'b1)) 
    MMCM_RESET_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(MMCM_RESET_i_1_n_0),
        .Q(mmcm_reset),
        .R(pma_reset));
  (* SOFT_HLUTNM = "soft_lutpair97" *) 
  LUT5 #(
    .INIT(32'hFFFD2000)) 
    TXUSERRDY_i_1
       (.I0(tx_state[0]),
        .I1(tx_state[3]),
        .I2(tx_state[2]),
        .I3(tx_state[1]),
        .I4(gt0_txuserrdy_t),
        .O(TXUSERRDY_i_1_n_0));
  FDRE #(
    .INIT(1'b0)) 
    TXUSERRDY_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(TXUSERRDY_i_1_n_0),
        .Q(gt0_txuserrdy_t),
        .R(pma_reset));
  (* SOFT_HLUTNM = "soft_lutpair95" *) 
  LUT5 #(
    .INIT(32'hFFEF0100)) 
    gttxreset_i_i_1
       (.I0(tx_state[3]),
        .I1(tx_state[1]),
        .I2(tx_state[2]),
        .I3(tx_state[0]),
        .I4(GTTXRESET),
        .O(gttxreset_i_i_1_n_0));
  FDRE #(
    .INIT(1'b0)) 
    gttxreset_i_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(gttxreset_i_i_1_n_0),
        .Q(GTTXRESET),
        .R(pma_reset));
  LUT3 #(
    .INIT(8'hEA)) 
    gtxe2_i_i_3
       (.I0(GTTXRESET),
        .I1(data_in),
        .I2(gtxe2_i),
        .O(gt0_gttxreset_in0_out));
  LUT1 #(
    .INIT(2'h1)) 
    \init_wait_count[0]_i_1 
       (.I0(init_wait_count_reg[0]),
        .O(\init_wait_count[0]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair103" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \init_wait_count[1]_i_1 
       (.I0(init_wait_count_reg[0]),
        .I1(init_wait_count_reg[1]),
        .O(p_0_in[1]));
  (* SOFT_HLUTNM = "soft_lutpair102" *) 
  LUT3 #(
    .INIT(8'h78)) 
    \init_wait_count[2]_i_1 
       (.I0(init_wait_count_reg[0]),
        .I1(init_wait_count_reg[1]),
        .I2(init_wait_count_reg[2]),
        .O(p_0_in[2]));
  (* SOFT_HLUTNM = "soft_lutpair101" *) 
  LUT4 #(
    .INIT(16'h7F80)) 
    \init_wait_count[3]_i_1 
       (.I0(init_wait_count_reg[1]),
        .I1(init_wait_count_reg[2]),
        .I2(init_wait_count_reg[0]),
        .I3(init_wait_count_reg[3]),
        .O(p_0_in[3]));
  (* SOFT_HLUTNM = "soft_lutpair101" *) 
  LUT5 #(
    .INIT(32'h7FFF8000)) 
    \init_wait_count[4]_i_1 
       (.I0(init_wait_count_reg[2]),
        .I1(init_wait_count_reg[1]),
        .I2(init_wait_count_reg[3]),
        .I3(init_wait_count_reg[0]),
        .I4(init_wait_count_reg[4]),
        .O(p_0_in[4]));
  LUT6 #(
    .INIT(64'h7FFFFFFF80000000)) 
    \init_wait_count[5]_i_1 
       (.I0(init_wait_count_reg[2]),
        .I1(init_wait_count_reg[1]),
        .I2(init_wait_count_reg[3]),
        .I3(init_wait_count_reg[0]),
        .I4(init_wait_count_reg[4]),
        .I5(init_wait_count_reg[5]),
        .O(p_0_in[5]));
  LUT4 #(
    .INIT(16'hFEFF)) 
    \init_wait_count[6]_i_1 
       (.I0(\init_wait_count[6]_i_3_n_0 ),
        .I1(init_wait_count_reg[0]),
        .I2(init_wait_count_reg[4]),
        .I3(init_wait_count_reg[6]),
        .O(\init_wait_count[6]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair103" *) 
  LUT4 #(
    .INIT(16'hBF40)) 
    \init_wait_count[6]_i_2 
       (.I0(\init_wait_count[6]_i_3_n_0 ),
        .I1(init_wait_count_reg[0]),
        .I2(init_wait_count_reg[4]),
        .I3(init_wait_count_reg[6]),
        .O(p_0_in[6]));
  (* SOFT_HLUTNM = "soft_lutpair102" *) 
  LUT4 #(
    .INIT(16'h7FFF)) 
    \init_wait_count[6]_i_3 
       (.I0(init_wait_count_reg[3]),
        .I1(init_wait_count_reg[1]),
        .I2(init_wait_count_reg[2]),
        .I3(init_wait_count_reg[5]),
        .O(\init_wait_count[6]_i_3_n_0 ));
  FDCE #(
    .INIT(1'b0)) 
    \init_wait_count_reg[0] 
       (.C(independent_clock_bufg),
        .CE(\init_wait_count[6]_i_1_n_0 ),
        .CLR(pma_reset),
        .D(\init_wait_count[0]_i_1_n_0 ),
        .Q(init_wait_count_reg[0]));
  FDCE #(
    .INIT(1'b0)) 
    \init_wait_count_reg[1] 
       (.C(independent_clock_bufg),
        .CE(\init_wait_count[6]_i_1_n_0 ),
        .CLR(pma_reset),
        .D(p_0_in[1]),
        .Q(init_wait_count_reg[1]));
  FDCE #(
    .INIT(1'b0)) 
    \init_wait_count_reg[2] 
       (.C(independent_clock_bufg),
        .CE(\init_wait_count[6]_i_1_n_0 ),
        .CLR(pma_reset),
        .D(p_0_in[2]),
        .Q(init_wait_count_reg[2]));
  FDCE #(
    .INIT(1'b0)) 
    \init_wait_count_reg[3] 
       (.C(independent_clock_bufg),
        .CE(\init_wait_count[6]_i_1_n_0 ),
        .CLR(pma_reset),
        .D(p_0_in[3]),
        .Q(init_wait_count_reg[3]));
  FDCE #(
    .INIT(1'b0)) 
    \init_wait_count_reg[4] 
       (.C(independent_clock_bufg),
        .CE(\init_wait_count[6]_i_1_n_0 ),
        .CLR(pma_reset),
        .D(p_0_in[4]),
        .Q(init_wait_count_reg[4]));
  FDCE #(
    .INIT(1'b0)) 
    \init_wait_count_reg[5] 
       (.C(independent_clock_bufg),
        .CE(\init_wait_count[6]_i_1_n_0 ),
        .CLR(pma_reset),
        .D(p_0_in[5]),
        .Q(init_wait_count_reg[5]));
  FDCE #(
    .INIT(1'b0)) 
    \init_wait_count_reg[6] 
       (.C(independent_clock_bufg),
        .CE(\init_wait_count[6]_i_1_n_0 ),
        .CLR(pma_reset),
        .D(p_0_in[6]),
        .Q(init_wait_count_reg[6]));
  LUT5 #(
    .INIT(32'hFFFF0010)) 
    init_wait_done_i_1
       (.I0(\init_wait_count[6]_i_3_n_0 ),
        .I1(init_wait_count_reg[4]),
        .I2(init_wait_count_reg[6]),
        .I3(init_wait_count_reg[0]),
        .I4(init_wait_done_reg_n_0),
        .O(init_wait_done_i_1_n_0));
  FDCE #(
    .INIT(1'b0)) 
    init_wait_done_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .CLR(pma_reset),
        .D(init_wait_done_i_1_n_0),
        .Q(init_wait_done_reg_n_0));
  LUT1 #(
    .INIT(2'h1)) 
    \mmcm_lock_count[0]_i_1 
       (.I0(mmcm_lock_count_reg[0]),
        .O(p_0_in__0[0]));
  (* SOFT_HLUTNM = "soft_lutpair105" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \mmcm_lock_count[1]_i_1 
       (.I0(mmcm_lock_count_reg[0]),
        .I1(mmcm_lock_count_reg[1]),
        .O(p_0_in__0[1]));
  (* SOFT_HLUTNM = "soft_lutpair105" *) 
  LUT3 #(
    .INIT(8'h78)) 
    \mmcm_lock_count[2]_i_1 
       (.I0(mmcm_lock_count_reg[1]),
        .I1(mmcm_lock_count_reg[0]),
        .I2(mmcm_lock_count_reg[2]),
        .O(\mmcm_lock_count[2]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair100" *) 
  LUT4 #(
    .INIT(16'h7F80)) 
    \mmcm_lock_count[3]_i_1 
       (.I0(mmcm_lock_count_reg[2]),
        .I1(mmcm_lock_count_reg[0]),
        .I2(mmcm_lock_count_reg[1]),
        .I3(mmcm_lock_count_reg[3]),
        .O(\mmcm_lock_count[3]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair100" *) 
  LUT5 #(
    .INIT(32'h7FFF8000)) 
    \mmcm_lock_count[4]_i_1 
       (.I0(mmcm_lock_count_reg[3]),
        .I1(mmcm_lock_count_reg[1]),
        .I2(mmcm_lock_count_reg[0]),
        .I3(mmcm_lock_count_reg[2]),
        .I4(mmcm_lock_count_reg[4]),
        .O(\mmcm_lock_count[4]_i_1_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFF80000000)) 
    \mmcm_lock_count[5]_i_1 
       (.I0(mmcm_lock_count_reg[4]),
        .I1(mmcm_lock_count_reg[2]),
        .I2(mmcm_lock_count_reg[0]),
        .I3(mmcm_lock_count_reg[1]),
        .I4(mmcm_lock_count_reg[3]),
        .I5(mmcm_lock_count_reg[5]),
        .O(\mmcm_lock_count[5]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair104" *) 
  LUT2 #(
    .INIT(4'h9)) 
    \mmcm_lock_count[6]_i_1 
       (.I0(mmcm_lock_reclocked_i_2_n_0),
        .I1(mmcm_lock_count_reg[6]),
        .O(\mmcm_lock_count[6]_i_1_n_0 ));
  LUT3 #(
    .INIT(8'hBF)) 
    \mmcm_lock_count[7]_i_2 
       (.I0(mmcm_lock_reclocked_i_2_n_0),
        .I1(mmcm_lock_count_reg[6]),
        .I2(mmcm_lock_count_reg[7]),
        .O(\mmcm_lock_count[7]_i_2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair104" *) 
  LUT3 #(
    .INIT(8'hD2)) 
    \mmcm_lock_count[7]_i_3 
       (.I0(mmcm_lock_count_reg[6]),
        .I1(mmcm_lock_reclocked_i_2_n_0),
        .I2(mmcm_lock_count_reg[7]),
        .O(\mmcm_lock_count[7]_i_3_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \mmcm_lock_count_reg[0] 
       (.C(independent_clock_bufg),
        .CE(\mmcm_lock_count[7]_i_2_n_0 ),
        .D(p_0_in__0[0]),
        .Q(mmcm_lock_count_reg[0]),
        .R(sync_mmcm_lock_reclocked_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \mmcm_lock_count_reg[1] 
       (.C(independent_clock_bufg),
        .CE(\mmcm_lock_count[7]_i_2_n_0 ),
        .D(p_0_in__0[1]),
        .Q(mmcm_lock_count_reg[1]),
        .R(sync_mmcm_lock_reclocked_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \mmcm_lock_count_reg[2] 
       (.C(independent_clock_bufg),
        .CE(\mmcm_lock_count[7]_i_2_n_0 ),
        .D(\mmcm_lock_count[2]_i_1_n_0 ),
        .Q(mmcm_lock_count_reg[2]),
        .R(sync_mmcm_lock_reclocked_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \mmcm_lock_count_reg[3] 
       (.C(independent_clock_bufg),
        .CE(\mmcm_lock_count[7]_i_2_n_0 ),
        .D(\mmcm_lock_count[3]_i_1_n_0 ),
        .Q(mmcm_lock_count_reg[3]),
        .R(sync_mmcm_lock_reclocked_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \mmcm_lock_count_reg[4] 
       (.C(independent_clock_bufg),
        .CE(\mmcm_lock_count[7]_i_2_n_0 ),
        .D(\mmcm_lock_count[4]_i_1_n_0 ),
        .Q(mmcm_lock_count_reg[4]),
        .R(sync_mmcm_lock_reclocked_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \mmcm_lock_count_reg[5] 
       (.C(independent_clock_bufg),
        .CE(\mmcm_lock_count[7]_i_2_n_0 ),
        .D(\mmcm_lock_count[5]_i_1_n_0 ),
        .Q(mmcm_lock_count_reg[5]),
        .R(sync_mmcm_lock_reclocked_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \mmcm_lock_count_reg[6] 
       (.C(independent_clock_bufg),
        .CE(\mmcm_lock_count[7]_i_2_n_0 ),
        .D(\mmcm_lock_count[6]_i_1_n_0 ),
        .Q(mmcm_lock_count_reg[6]),
        .R(sync_mmcm_lock_reclocked_n_0));
  FDRE #(
    .INIT(1'b0)) 
    \mmcm_lock_count_reg[7] 
       (.C(independent_clock_bufg),
        .CE(\mmcm_lock_count[7]_i_2_n_0 ),
        .D(\mmcm_lock_count[7]_i_3_n_0 ),
        .Q(mmcm_lock_count_reg[7]),
        .R(sync_mmcm_lock_reclocked_n_0));
  LUT5 #(
    .INIT(32'hAAEA0000)) 
    mmcm_lock_reclocked_i_1
       (.I0(mmcm_lock_reclocked),
        .I1(mmcm_lock_count_reg[7]),
        .I2(mmcm_lock_count_reg[6]),
        .I3(mmcm_lock_reclocked_i_2_n_0),
        .I4(mmcm_lock_i),
        .O(mmcm_lock_reclocked_i_1_n_0));
  LUT6 #(
    .INIT(64'h7FFFFFFFFFFFFFFF)) 
    mmcm_lock_reclocked_i_2
       (.I0(mmcm_lock_count_reg[4]),
        .I1(mmcm_lock_count_reg[2]),
        .I2(mmcm_lock_count_reg[0]),
        .I3(mmcm_lock_count_reg[1]),
        .I4(mmcm_lock_count_reg[3]),
        .I5(mmcm_lock_count_reg[5]),
        .O(mmcm_lock_reclocked_i_2_n_0));
  FDRE #(
    .INIT(1'b0)) 
    mmcm_lock_reclocked_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(mmcm_lock_reclocked_i_1_n_0),
        .Q(mmcm_lock_reclocked),
        .R(1'b0));
  LUT6 #(
    .INIT(64'h0000CD55CCCCCCCC)) 
    pll_reset_asserted_i_1
       (.I0(tx_state[3]),
        .I1(pll_reset_asserted_reg_n_0),
        .I2(gt0_cpllrefclklost_i),
        .I3(refclk_stable_reg_n_0),
        .I4(tx_state[1]),
        .I5(pll_reset_asserted_i_2_n_0),
        .O(pll_reset_asserted_i_1_n_0));
  (* SOFT_HLUTNM = "soft_lutpair96" *) 
  LUT3 #(
    .INIT(8'h02)) 
    pll_reset_asserted_i_2
       (.I0(tx_state[0]),
        .I1(tx_state[3]),
        .I2(tx_state[2]),
        .O(pll_reset_asserted_i_2_n_0));
  FDRE #(
    .INIT(1'b0)) 
    pll_reset_asserted_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(pll_reset_asserted_i_1_n_0),
        .Q(pll_reset_asserted_reg_n_0),
        .R(pma_reset));
  LUT6 #(
    .INIT(64'hFFFFFFFFFFFEFFFF)) 
    \refclk_stable_count[0]_i_1 
       (.I0(\refclk_stable_count[0]_i_3_n_0 ),
        .I1(\refclk_stable_count[0]_i_4_n_0 ),
        .I2(\refclk_stable_count[0]_i_5_n_0 ),
        .I3(\refclk_stable_count[0]_i_6_n_0 ),
        .I4(\refclk_stable_count[0]_i_7_n_0 ),
        .I5(\refclk_stable_count[0]_i_8_n_0 ),
        .O(refclk_stable_count));
  LUT6 #(
    .INIT(64'hFFDFFFFFFFFFFFFF)) 
    \refclk_stable_count[0]_i_3 
       (.I0(refclk_stable_count_reg[13]),
        .I1(refclk_stable_count_reg[12]),
        .I2(refclk_stable_count_reg[10]),
        .I3(refclk_stable_count_reg[11]),
        .I4(refclk_stable_count_reg[9]),
        .I5(refclk_stable_count_reg[8]),
        .O(\refclk_stable_count[0]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hFFFFFFFFFFFFFFDF)) 
    \refclk_stable_count[0]_i_4 
       (.I0(refclk_stable_count_reg[19]),
        .I1(refclk_stable_count_reg[18]),
        .I2(refclk_stable_count_reg[16]),
        .I3(refclk_stable_count_reg[17]),
        .I4(refclk_stable_count_reg[15]),
        .I5(refclk_stable_count_reg[14]),
        .O(\refclk_stable_count[0]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hFFFFFFFFFFFFFFFE)) 
    \refclk_stable_count[0]_i_5 
       (.I0(refclk_stable_count_reg[30]),
        .I1(refclk_stable_count_reg[31]),
        .I2(refclk_stable_count_reg[28]),
        .I3(refclk_stable_count_reg[29]),
        .I4(refclk_stable_count_reg[27]),
        .I5(refclk_stable_count_reg[26]),
        .O(\refclk_stable_count[0]_i_5_n_0 ));
  LUT6 #(
    .INIT(64'hFFFFFFFFFFFFFFFE)) 
    \refclk_stable_count[0]_i_6 
       (.I0(refclk_stable_count_reg[24]),
        .I1(refclk_stable_count_reg[25]),
        .I2(refclk_stable_count_reg[22]),
        .I3(refclk_stable_count_reg[23]),
        .I4(refclk_stable_count_reg[21]),
        .I5(refclk_stable_count_reg[20]),
        .O(\refclk_stable_count[0]_i_6_n_0 ));
  LUT2 #(
    .INIT(4'h1)) 
    \refclk_stable_count[0]_i_7 
       (.I0(refclk_stable_count_reg[0]),
        .I1(refclk_stable_count_reg[1]),
        .O(\refclk_stable_count[0]_i_7_n_0 ));
  LUT6 #(
    .INIT(64'hFFFFFFFFFFFFFFF7)) 
    \refclk_stable_count[0]_i_8 
       (.I0(refclk_stable_count_reg[6]),
        .I1(refclk_stable_count_reg[7]),
        .I2(refclk_stable_count_reg[4]),
        .I3(refclk_stable_count_reg[5]),
        .I4(refclk_stable_count_reg[3]),
        .I5(refclk_stable_count_reg[2]),
        .O(\refclk_stable_count[0]_i_8_n_0 ));
  LUT1 #(
    .INIT(2'h1)) 
    \refclk_stable_count[0]_i_9 
       (.I0(refclk_stable_count_reg[0]),
        .O(\refclk_stable_count[0]_i_9_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[0] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[0]_i_2_n_7 ),
        .Q(refclk_stable_count_reg[0]),
        .R(1'b0));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \refclk_stable_count_reg[0]_i_2 
       (.CI(1'b0),
        .CO({\refclk_stable_count_reg[0]_i_2_n_0 ,\refclk_stable_count_reg[0]_i_2_n_1 ,\refclk_stable_count_reg[0]_i_2_n_2 ,\refclk_stable_count_reg[0]_i_2_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b1}),
        .O({\refclk_stable_count_reg[0]_i_2_n_4 ,\refclk_stable_count_reg[0]_i_2_n_5 ,\refclk_stable_count_reg[0]_i_2_n_6 ,\refclk_stable_count_reg[0]_i_2_n_7 }),
        .S({refclk_stable_count_reg[3:1],\refclk_stable_count[0]_i_9_n_0 }));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[10] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[8]_i_1_n_5 ),
        .Q(refclk_stable_count_reg[10]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[11] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[8]_i_1_n_4 ),
        .Q(refclk_stable_count_reg[11]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[12] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[12]_i_1_n_7 ),
        .Q(refclk_stable_count_reg[12]),
        .R(1'b0));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \refclk_stable_count_reg[12]_i_1 
       (.CI(\refclk_stable_count_reg[8]_i_1_n_0 ),
        .CO({\refclk_stable_count_reg[12]_i_1_n_0 ,\refclk_stable_count_reg[12]_i_1_n_1 ,\refclk_stable_count_reg[12]_i_1_n_2 ,\refclk_stable_count_reg[12]_i_1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\refclk_stable_count_reg[12]_i_1_n_4 ,\refclk_stable_count_reg[12]_i_1_n_5 ,\refclk_stable_count_reg[12]_i_1_n_6 ,\refclk_stable_count_reg[12]_i_1_n_7 }),
        .S(refclk_stable_count_reg[15:12]));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[13] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[12]_i_1_n_6 ),
        .Q(refclk_stable_count_reg[13]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[14] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[12]_i_1_n_5 ),
        .Q(refclk_stable_count_reg[14]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[15] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[12]_i_1_n_4 ),
        .Q(refclk_stable_count_reg[15]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[16] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[16]_i_1_n_7 ),
        .Q(refclk_stable_count_reg[16]),
        .R(1'b0));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \refclk_stable_count_reg[16]_i_1 
       (.CI(\refclk_stable_count_reg[12]_i_1_n_0 ),
        .CO({\refclk_stable_count_reg[16]_i_1_n_0 ,\refclk_stable_count_reg[16]_i_1_n_1 ,\refclk_stable_count_reg[16]_i_1_n_2 ,\refclk_stable_count_reg[16]_i_1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\refclk_stable_count_reg[16]_i_1_n_4 ,\refclk_stable_count_reg[16]_i_1_n_5 ,\refclk_stable_count_reg[16]_i_1_n_6 ,\refclk_stable_count_reg[16]_i_1_n_7 }),
        .S(refclk_stable_count_reg[19:16]));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[17] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[16]_i_1_n_6 ),
        .Q(refclk_stable_count_reg[17]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[18] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[16]_i_1_n_5 ),
        .Q(refclk_stable_count_reg[18]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[19] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[16]_i_1_n_4 ),
        .Q(refclk_stable_count_reg[19]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[1] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[0]_i_2_n_6 ),
        .Q(refclk_stable_count_reg[1]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[20] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[20]_i_1_n_7 ),
        .Q(refclk_stable_count_reg[20]),
        .R(1'b0));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \refclk_stable_count_reg[20]_i_1 
       (.CI(\refclk_stable_count_reg[16]_i_1_n_0 ),
        .CO({\refclk_stable_count_reg[20]_i_1_n_0 ,\refclk_stable_count_reg[20]_i_1_n_1 ,\refclk_stable_count_reg[20]_i_1_n_2 ,\refclk_stable_count_reg[20]_i_1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\refclk_stable_count_reg[20]_i_1_n_4 ,\refclk_stable_count_reg[20]_i_1_n_5 ,\refclk_stable_count_reg[20]_i_1_n_6 ,\refclk_stable_count_reg[20]_i_1_n_7 }),
        .S(refclk_stable_count_reg[23:20]));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[21] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[20]_i_1_n_6 ),
        .Q(refclk_stable_count_reg[21]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[22] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[20]_i_1_n_5 ),
        .Q(refclk_stable_count_reg[22]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[23] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[20]_i_1_n_4 ),
        .Q(refclk_stable_count_reg[23]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[24] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[24]_i_1_n_7 ),
        .Q(refclk_stable_count_reg[24]),
        .R(1'b0));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \refclk_stable_count_reg[24]_i_1 
       (.CI(\refclk_stable_count_reg[20]_i_1_n_0 ),
        .CO({\refclk_stable_count_reg[24]_i_1_n_0 ,\refclk_stable_count_reg[24]_i_1_n_1 ,\refclk_stable_count_reg[24]_i_1_n_2 ,\refclk_stable_count_reg[24]_i_1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\refclk_stable_count_reg[24]_i_1_n_4 ,\refclk_stable_count_reg[24]_i_1_n_5 ,\refclk_stable_count_reg[24]_i_1_n_6 ,\refclk_stable_count_reg[24]_i_1_n_7 }),
        .S(refclk_stable_count_reg[27:24]));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[25] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[24]_i_1_n_6 ),
        .Q(refclk_stable_count_reg[25]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[26] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[24]_i_1_n_5 ),
        .Q(refclk_stable_count_reg[26]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[27] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[24]_i_1_n_4 ),
        .Q(refclk_stable_count_reg[27]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[28] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[28]_i_1_n_7 ),
        .Q(refclk_stable_count_reg[28]),
        .R(1'b0));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \refclk_stable_count_reg[28]_i_1 
       (.CI(\refclk_stable_count_reg[24]_i_1_n_0 ),
        .CO({\NLW_refclk_stable_count_reg[28]_i_1_CO_UNCONNECTED [3],\refclk_stable_count_reg[28]_i_1_n_1 ,\refclk_stable_count_reg[28]_i_1_n_2 ,\refclk_stable_count_reg[28]_i_1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\refclk_stable_count_reg[28]_i_1_n_4 ,\refclk_stable_count_reg[28]_i_1_n_5 ,\refclk_stable_count_reg[28]_i_1_n_6 ,\refclk_stable_count_reg[28]_i_1_n_7 }),
        .S(refclk_stable_count_reg[31:28]));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[29] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[28]_i_1_n_6 ),
        .Q(refclk_stable_count_reg[29]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[2] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[0]_i_2_n_5 ),
        .Q(refclk_stable_count_reg[2]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[30] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[28]_i_1_n_5 ),
        .Q(refclk_stable_count_reg[30]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[31] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[28]_i_1_n_4 ),
        .Q(refclk_stable_count_reg[31]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[3] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[0]_i_2_n_4 ),
        .Q(refclk_stable_count_reg[3]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[4] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[4]_i_1_n_7 ),
        .Q(refclk_stable_count_reg[4]),
        .R(1'b0));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \refclk_stable_count_reg[4]_i_1 
       (.CI(\refclk_stable_count_reg[0]_i_2_n_0 ),
        .CO({\refclk_stable_count_reg[4]_i_1_n_0 ,\refclk_stable_count_reg[4]_i_1_n_1 ,\refclk_stable_count_reg[4]_i_1_n_2 ,\refclk_stable_count_reg[4]_i_1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\refclk_stable_count_reg[4]_i_1_n_4 ,\refclk_stable_count_reg[4]_i_1_n_5 ,\refclk_stable_count_reg[4]_i_1_n_6 ,\refclk_stable_count_reg[4]_i_1_n_7 }),
        .S(refclk_stable_count_reg[7:4]));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[5] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[4]_i_1_n_6 ),
        .Q(refclk_stable_count_reg[5]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[6] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[4]_i_1_n_5 ),
        .Q(refclk_stable_count_reg[6]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[7] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[4]_i_1_n_4 ),
        .Q(refclk_stable_count_reg[7]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[8] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[8]_i_1_n_7 ),
        .Q(refclk_stable_count_reg[8]),
        .R(1'b0));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \refclk_stable_count_reg[8]_i_1 
       (.CI(\refclk_stable_count_reg[4]_i_1_n_0 ),
        .CO({\refclk_stable_count_reg[8]_i_1_n_0 ,\refclk_stable_count_reg[8]_i_1_n_1 ,\refclk_stable_count_reg[8]_i_1_n_2 ,\refclk_stable_count_reg[8]_i_1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\refclk_stable_count_reg[8]_i_1_n_4 ,\refclk_stable_count_reg[8]_i_1_n_5 ,\refclk_stable_count_reg[8]_i_1_n_6 ,\refclk_stable_count_reg[8]_i_1_n_7 }),
        .S(refclk_stable_count_reg[11:8]));
  FDRE #(
    .INIT(1'b0)) 
    \refclk_stable_count_reg[9] 
       (.C(independent_clock_bufg),
        .CE(refclk_stable_count),
        .D(\refclk_stable_count_reg[8]_i_1_n_6 ),
        .Q(refclk_stable_count_reg[9]),
        .R(1'b0));
  LUT6 #(
    .INIT(64'h8000000000000000)) 
    refclk_stable_i_1
       (.I0(\refclk_stable_count[0]_i_7_n_0 ),
        .I1(refclk_stable_i_2_n_0),
        .I2(refclk_stable_i_3_n_0),
        .I3(refclk_stable_i_4_n_0),
        .I4(refclk_stable_i_5_n_0),
        .I5(refclk_stable_i_6_n_0),
        .O(refclk_stable_i_1_n_0));
  LUT6 #(
    .INIT(64'h0001000000000000)) 
    refclk_stable_i_2
       (.I0(refclk_stable_count_reg[4]),
        .I1(refclk_stable_count_reg[5]),
        .I2(refclk_stable_count_reg[2]),
        .I3(refclk_stable_count_reg[3]),
        .I4(refclk_stable_count_reg[7]),
        .I5(refclk_stable_count_reg[6]),
        .O(refclk_stable_i_2_n_0));
  LUT6 #(
    .INIT(64'h0000200000000000)) 
    refclk_stable_i_3
       (.I0(refclk_stable_count_reg[10]),
        .I1(refclk_stable_count_reg[11]),
        .I2(refclk_stable_count_reg[8]),
        .I3(refclk_stable_count_reg[9]),
        .I4(refclk_stable_count_reg[12]),
        .I5(refclk_stable_count_reg[13]),
        .O(refclk_stable_i_3_n_0));
  LUT6 #(
    .INIT(64'h0000000200000000)) 
    refclk_stable_i_4
       (.I0(refclk_stable_count_reg[16]),
        .I1(refclk_stable_count_reg[17]),
        .I2(refclk_stable_count_reg[14]),
        .I3(refclk_stable_count_reg[15]),
        .I4(refclk_stable_count_reg[18]),
        .I5(refclk_stable_count_reg[19]),
        .O(refclk_stable_i_4_n_0));
  LUT6 #(
    .INIT(64'h0000000000000001)) 
    refclk_stable_i_5
       (.I0(refclk_stable_count_reg[22]),
        .I1(refclk_stable_count_reg[23]),
        .I2(refclk_stable_count_reg[20]),
        .I3(refclk_stable_count_reg[21]),
        .I4(refclk_stable_count_reg[25]),
        .I5(refclk_stable_count_reg[24]),
        .O(refclk_stable_i_5_n_0));
  LUT6 #(
    .INIT(64'h0000000000000001)) 
    refclk_stable_i_6
       (.I0(refclk_stable_count_reg[28]),
        .I1(refclk_stable_count_reg[29]),
        .I2(refclk_stable_count_reg[26]),
        .I3(refclk_stable_count_reg[27]),
        .I4(refclk_stable_count_reg[31]),
        .I5(refclk_stable_count_reg[30]),
        .O(refclk_stable_i_6_n_0));
  FDRE #(
    .INIT(1'b0)) 
    refclk_stable_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(refclk_stable_i_1_n_0),
        .Q(refclk_stable_reg_n_0),
        .R(1'b0));
  LUT6 #(
    .INIT(64'h440000FF50505050)) 
    reset_time_out_i_2__0
       (.I0(tx_state[3]),
        .I1(txresetdone_s3),
        .I2(init_wait_done_reg_n_0),
        .I3(tx_state[1]),
        .I4(tx_state[2]),
        .I5(tx_state[0]),
        .O(reset_time_out_i_2__0_n_0));
  FDRE #(
    .INIT(1'b0)) 
    reset_time_out_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(sync_cplllock_n_0),
        .Q(reset_time_out),
        .R(pma_reset));
  (* SOFT_HLUTNM = "soft_lutpair98" *) 
  LUT5 #(
    .INIT(32'hFFFB0002)) 
    run_phase_alignment_int_i_1
       (.I0(tx_state[3]),
        .I1(tx_state[0]),
        .I2(tx_state[2]),
        .I3(tx_state[1]),
        .I4(run_phase_alignment_int_reg_n_0),
        .O(run_phase_alignment_int_i_1_n_0));
  FDRE #(
    .INIT(1'b0)) 
    run_phase_alignment_int_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(run_phase_alignment_int_i_1_n_0),
        .Q(run_phase_alignment_int_reg_n_0),
        .R(pma_reset));
  FDRE #(
    .INIT(1'b0)) 
    run_phase_alignment_int_s3_reg
       (.C(userclk),
        .CE(1'b1),
        .D(data_out),
        .Q(run_phase_alignment_int_s3),
        .R(1'b0));
  gmii_to_sgmii_bridge_sync_block__parameterized1_17 sync_TXRESETDONE
       (.data_out(txresetdone_s2),
        .data_sync_reg1_0(data_sync_reg1),
        .independent_clock_bufg(independent_clock_bufg));
  gmii_to_sgmii_bridge_sync_block__parameterized1_18 sync_cplllock
       (.E(sync_cplllock_n_1),
        .\FSM_sequential_tx_state_reg[0] (\FSM_sequential_tx_state[3]_i_3_n_0 ),
        .\FSM_sequential_tx_state_reg[0]_0 (\FSM_sequential_tx_state[3]_i_4_n_0 ),
        .\FSM_sequential_tx_state_reg[0]_1 (\FSM_sequential_tx_state[3]_i_6_n_0 ),
        .\FSM_sequential_tx_state_reg[0]_2 (time_out_2ms_reg_n_0),
        .\FSM_sequential_tx_state_reg[0]_3 (\FSM_sequential_tx_state[3]_i_7_n_0 ),
        .\FSM_sequential_tx_state_reg[0]_4 (pll_reset_asserted_reg_n_0),
        .\FSM_sequential_tx_state_reg[0]_5 (refclk_stable_reg_n_0),
        .\FSM_sequential_tx_state_reg[0]_6 (\FSM_sequential_tx_state[0]_i_3_n_0 ),
        .Q(tx_state),
        .cplllock(cplllock),
        .independent_clock_bufg(independent_clock_bufg),
        .mmcm_lock_reclocked(mmcm_lock_reclocked),
        .reset_time_out(reset_time_out),
        .reset_time_out_reg(sync_cplllock_n_0),
        .reset_time_out_reg_0(reset_time_out_i_2__0_n_0),
        .reset_time_out_reg_1(init_wait_done_reg_n_0));
  gmii_to_sgmii_bridge_sync_block__parameterized1_19 sync_mmcm_lock_reclocked
       (.SR(sync_mmcm_lock_reclocked_n_0),
        .data_out(mmcm_lock_i),
        .independent_clock_bufg(independent_clock_bufg),
        .mmcm_locked(mmcm_locked));
  gmii_to_sgmii_bridge_sync_block__parameterized1_20 sync_run_phase_alignment_int
       (.data_in(run_phase_alignment_int_reg_n_0),
        .data_out(data_out),
        .userclk(userclk));
  gmii_to_sgmii_bridge_sync_block__parameterized1_21 sync_time_out_wait_bypass
       (.data_in(time_out_wait_bypass_reg_n_0),
        .data_out(time_out_wait_bypass_s2),
        .independent_clock_bufg(independent_clock_bufg));
  gmii_to_sgmii_bridge_sync_block__parameterized1_22 sync_tx_fsm_reset_done_int
       (.data_in(data_in),
        .data_out(tx_fsm_reset_done_int_s2),
        .userclk(userclk));
  LUT4 #(
    .INIT(16'h00AE)) 
    time_out_2ms_i_1
       (.I0(time_out_2ms_reg_n_0),
        .I1(time_out_2ms_i_2__0_n_0),
        .I2(time_out_2ms_i_3_n_0),
        .I3(reset_time_out),
        .O(time_out_2ms_i_1_n_0));
  LUT6 #(
    .INIT(64'h0000000000000800)) 
    time_out_2ms_i_2__0
       (.I0(time_out_counter_reg[17]),
        .I1(time_out_counter_reg[18]),
        .I2(time_out_counter_reg[10]),
        .I3(time_out_counter_reg[12]),
        .I4(time_out_counter_reg[5]),
        .I5(time_tlock_max_i_3_n_0),
        .O(time_out_2ms_i_2__0_n_0));
  LUT4 #(
    .INIT(16'hFFFD)) 
    time_out_2ms_i_3
       (.I0(time_out_counter_reg[7]),
        .I1(time_out_counter_reg[14]),
        .I2(time_out_2ms_i_4__0_n_0),
        .I3(time_out_2ms_i_5_n_0),
        .O(time_out_2ms_i_3_n_0));
  (* SOFT_HLUTNM = "soft_lutpair92" *) 
  LUT4 #(
    .INIT(16'hFFFE)) 
    time_out_2ms_i_4__0
       (.I0(time_out_counter_reg[4]),
        .I1(time_out_counter_reg[3]),
        .I2(time_out_counter_reg[8]),
        .I3(time_out_counter_reg[6]),
        .O(time_out_2ms_i_4__0_n_0));
  LUT5 #(
    .INIT(32'hFFFFFFEF)) 
    time_out_2ms_i_5
       (.I0(time_out_counter_reg[0]),
        .I1(time_out_counter_reg[13]),
        .I2(time_out_counter_reg[9]),
        .I3(time_out_counter_reg[2]),
        .I4(time_out_counter_reg[1]),
        .O(time_out_2ms_i_5_n_0));
  FDRE #(
    .INIT(1'b0)) 
    time_out_2ms_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(time_out_2ms_i_1_n_0),
        .Q(time_out_2ms_reg_n_0),
        .R(1'b0));
  LUT6 #(
    .INIT(64'h00000000AAAAEAAA)) 
    time_out_500us_i_1
       (.I0(time_out_500us_reg_n_0),
        .I1(time_out_500us_i_2_n_0),
        .I2(time_out_counter_reg[5]),
        .I3(time_out_counter_reg[10]),
        .I4(time_out_2ms_i_3_n_0),
        .I5(reset_time_out),
        .O(time_out_500us_i_1_n_0));
  LUT6 #(
    .INIT(64'h0000000000000008)) 
    time_out_500us_i_2
       (.I0(time_out_counter_reg[15]),
        .I1(time_out_counter_reg[16]),
        .I2(time_out_counter_reg[11]),
        .I3(time_out_counter_reg[12]),
        .I4(time_out_counter_reg[18]),
        .I5(time_out_counter_reg[17]),
        .O(time_out_500us_i_2_n_0));
  FDRE #(
    .INIT(1'b0)) 
    time_out_500us_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(time_out_500us_i_1_n_0),
        .Q(time_out_500us_reg_n_0),
        .R(1'b0));
  LUT6 #(
    .INIT(64'hFFFFFFFFFFFBFFFF)) 
    \time_out_counter[0]_i_1__0 
       (.I0(time_tlock_max_i_3_n_0),
        .I1(\time_out_counter[0]_i_3__0_n_0 ),
        .I2(time_out_2ms_i_3_n_0),
        .I3(time_out_counter_reg[10]),
        .I4(time_out_counter_reg[12]),
        .I5(time_out_counter_reg[5]),
        .O(time_out_counter));
  LUT2 #(
    .INIT(4'h8)) 
    \time_out_counter[0]_i_3__0 
       (.I0(time_out_counter_reg[17]),
        .I1(time_out_counter_reg[18]),
        .O(\time_out_counter[0]_i_3__0_n_0 ));
  LUT1 #(
    .INIT(2'h1)) 
    \time_out_counter[0]_i_4 
       (.I0(time_out_counter_reg[0]),
        .O(\time_out_counter[0]_i_4_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[0] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[0]_i_2_n_7 ),
        .Q(time_out_counter_reg[0]),
        .R(reset_time_out));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \time_out_counter_reg[0]_i_2 
       (.CI(1'b0),
        .CO({\time_out_counter_reg[0]_i_2_n_0 ,\time_out_counter_reg[0]_i_2_n_1 ,\time_out_counter_reg[0]_i_2_n_2 ,\time_out_counter_reg[0]_i_2_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b1}),
        .O({\time_out_counter_reg[0]_i_2_n_4 ,\time_out_counter_reg[0]_i_2_n_5 ,\time_out_counter_reg[0]_i_2_n_6 ,\time_out_counter_reg[0]_i_2_n_7 }),
        .S({time_out_counter_reg[3:1],\time_out_counter[0]_i_4_n_0 }));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[10] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[8]_i_1_n_5 ),
        .Q(time_out_counter_reg[10]),
        .R(reset_time_out));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[11] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[8]_i_1_n_4 ),
        .Q(time_out_counter_reg[11]),
        .R(reset_time_out));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[12] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[12]_i_1_n_7 ),
        .Q(time_out_counter_reg[12]),
        .R(reset_time_out));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \time_out_counter_reg[12]_i_1 
       (.CI(\time_out_counter_reg[8]_i_1_n_0 ),
        .CO({\time_out_counter_reg[12]_i_1_n_0 ,\time_out_counter_reg[12]_i_1_n_1 ,\time_out_counter_reg[12]_i_1_n_2 ,\time_out_counter_reg[12]_i_1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\time_out_counter_reg[12]_i_1_n_4 ,\time_out_counter_reg[12]_i_1_n_5 ,\time_out_counter_reg[12]_i_1_n_6 ,\time_out_counter_reg[12]_i_1_n_7 }),
        .S(time_out_counter_reg[15:12]));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[13] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[12]_i_1_n_6 ),
        .Q(time_out_counter_reg[13]),
        .R(reset_time_out));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[14] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[12]_i_1_n_5 ),
        .Q(time_out_counter_reg[14]),
        .R(reset_time_out));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[15] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[12]_i_1_n_4 ),
        .Q(time_out_counter_reg[15]),
        .R(reset_time_out));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[16] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[16]_i_1_n_7 ),
        .Q(time_out_counter_reg[16]),
        .R(reset_time_out));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \time_out_counter_reg[16]_i_1 
       (.CI(\time_out_counter_reg[12]_i_1_n_0 ),
        .CO({\NLW_time_out_counter_reg[16]_i_1_CO_UNCONNECTED [3:2],\time_out_counter_reg[16]_i_1_n_2 ,\time_out_counter_reg[16]_i_1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\NLW_time_out_counter_reg[16]_i_1_O_UNCONNECTED [3],\time_out_counter_reg[16]_i_1_n_5 ,\time_out_counter_reg[16]_i_1_n_6 ,\time_out_counter_reg[16]_i_1_n_7 }),
        .S({1'b0,time_out_counter_reg[18:16]}));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[17] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[16]_i_1_n_6 ),
        .Q(time_out_counter_reg[17]),
        .R(reset_time_out));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[18] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[16]_i_1_n_5 ),
        .Q(time_out_counter_reg[18]),
        .R(reset_time_out));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[1] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[0]_i_2_n_6 ),
        .Q(time_out_counter_reg[1]),
        .R(reset_time_out));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[2] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[0]_i_2_n_5 ),
        .Q(time_out_counter_reg[2]),
        .R(reset_time_out));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[3] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[0]_i_2_n_4 ),
        .Q(time_out_counter_reg[3]),
        .R(reset_time_out));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[4] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[4]_i_1_n_7 ),
        .Q(time_out_counter_reg[4]),
        .R(reset_time_out));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \time_out_counter_reg[4]_i_1 
       (.CI(\time_out_counter_reg[0]_i_2_n_0 ),
        .CO({\time_out_counter_reg[4]_i_1_n_0 ,\time_out_counter_reg[4]_i_1_n_1 ,\time_out_counter_reg[4]_i_1_n_2 ,\time_out_counter_reg[4]_i_1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\time_out_counter_reg[4]_i_1_n_4 ,\time_out_counter_reg[4]_i_1_n_5 ,\time_out_counter_reg[4]_i_1_n_6 ,\time_out_counter_reg[4]_i_1_n_7 }),
        .S(time_out_counter_reg[7:4]));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[5] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[4]_i_1_n_6 ),
        .Q(time_out_counter_reg[5]),
        .R(reset_time_out));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[6] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[4]_i_1_n_5 ),
        .Q(time_out_counter_reg[6]),
        .R(reset_time_out));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[7] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[4]_i_1_n_4 ),
        .Q(time_out_counter_reg[7]),
        .R(reset_time_out));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[8] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[8]_i_1_n_7 ),
        .Q(time_out_counter_reg[8]),
        .R(reset_time_out));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \time_out_counter_reg[8]_i_1 
       (.CI(\time_out_counter_reg[4]_i_1_n_0 ),
        .CO({\time_out_counter_reg[8]_i_1_n_0 ,\time_out_counter_reg[8]_i_1_n_1 ,\time_out_counter_reg[8]_i_1_n_2 ,\time_out_counter_reg[8]_i_1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\time_out_counter_reg[8]_i_1_n_4 ,\time_out_counter_reg[8]_i_1_n_5 ,\time_out_counter_reg[8]_i_1_n_6 ,\time_out_counter_reg[8]_i_1_n_7 }),
        .S(time_out_counter_reg[11:8]));
  FDRE #(
    .INIT(1'b0)) 
    \time_out_counter_reg[9] 
       (.C(independent_clock_bufg),
        .CE(time_out_counter),
        .D(\time_out_counter_reg[8]_i_1_n_6 ),
        .Q(time_out_counter_reg[9]),
        .R(reset_time_out));
  LUT4 #(
    .INIT(16'hAB00)) 
    time_out_wait_bypass_i_1
       (.I0(time_out_wait_bypass_reg_n_0),
        .I1(time_out_wait_bypass_i_2_n_0),
        .I2(tx_fsm_reset_done_int_s3),
        .I3(run_phase_alignment_int_s3),
        .O(time_out_wait_bypass_i_1_n_0));
  LUT4 #(
    .INIT(16'hFFFE)) 
    time_out_wait_bypass_i_2
       (.I0(time_out_wait_bypass_i_3_n_0),
        .I1(time_out_wait_bypass_i_4_n_0),
        .I2(time_out_wait_bypass_i_5_n_0),
        .I3(time_out_wait_bypass_i_6_n_0),
        .O(time_out_wait_bypass_i_2_n_0));
  LUT4 #(
    .INIT(16'h7FFF)) 
    time_out_wait_bypass_i_3
       (.I0(wait_bypass_count_reg[4]),
        .I1(wait_bypass_count_reg[3]),
        .I2(wait_bypass_count_reg[6]),
        .I3(wait_bypass_count_reg[5]),
        .O(time_out_wait_bypass_i_3_n_0));
  LUT5 #(
    .INIT(32'hDFFFFFFF)) 
    time_out_wait_bypass_i_4
       (.I0(wait_bypass_count_reg[0]),
        .I1(wait_bypass_count_reg[15]),
        .I2(wait_bypass_count_reg[16]),
        .I3(wait_bypass_count_reg[2]),
        .I4(wait_bypass_count_reg[1]),
        .O(time_out_wait_bypass_i_4_n_0));
  LUT4 #(
    .INIT(16'hFFDF)) 
    time_out_wait_bypass_i_5
       (.I0(wait_bypass_count_reg[12]),
        .I1(wait_bypass_count_reg[11]),
        .I2(wait_bypass_count_reg[14]),
        .I3(wait_bypass_count_reg[13]),
        .O(time_out_wait_bypass_i_5_n_0));
  LUT4 #(
    .INIT(16'hFFDF)) 
    time_out_wait_bypass_i_6
       (.I0(wait_bypass_count_reg[7]),
        .I1(wait_bypass_count_reg[8]),
        .I2(wait_bypass_count_reg[9]),
        .I3(wait_bypass_count_reg[10]),
        .O(time_out_wait_bypass_i_6_n_0));
  FDRE #(
    .INIT(1'b0)) 
    time_out_wait_bypass_reg
       (.C(userclk),
        .CE(1'b1),
        .D(time_out_wait_bypass_i_1_n_0),
        .Q(time_out_wait_bypass_reg_n_0),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    time_out_wait_bypass_s3_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(time_out_wait_bypass_s2),
        .Q(time_out_wait_bypass_s3),
        .R(1'b0));
  LUT6 #(
    .INIT(64'h00000000AAAAAAEA)) 
    time_tlock_max_i_1
       (.I0(time_tlock_max_reg_n_0),
        .I1(time_tlock_max_i_2_n_0),
        .I2(time_out_counter_reg[5]),
        .I3(time_tlock_max_i_3_n_0),
        .I4(time_tlock_max_i_4_n_0),
        .I5(reset_time_out),
        .O(time_tlock_max_i_1_n_0));
  LUT6 #(
    .INIT(64'h0000000000000020)) 
    time_tlock_max_i_2
       (.I0(time_out_counter_reg[14]),
        .I1(time_out_counter_reg[12]),
        .I2(time_out_counter_reg[10]),
        .I3(time_out_counter_reg[7]),
        .I4(time_out_counter_reg[18]),
        .I5(time_out_counter_reg[17]),
        .O(time_tlock_max_i_2_n_0));
  LUT3 #(
    .INIT(8'hEF)) 
    time_tlock_max_i_3
       (.I0(time_out_counter_reg[16]),
        .I1(time_out_counter_reg[15]),
        .I2(time_out_counter_reg[11]),
        .O(time_tlock_max_i_3_n_0));
  (* SOFT_HLUTNM = "soft_lutpair92" *) 
  LUT5 #(
    .INIT(32'hFFFFFFFE)) 
    time_tlock_max_i_4
       (.I0(time_out_2ms_i_5_n_0),
        .I1(time_out_counter_reg[6]),
        .I2(time_out_counter_reg[8]),
        .I3(time_out_counter_reg[3]),
        .I4(time_out_counter_reg[4]),
        .O(time_tlock_max_i_4_n_0));
  FDRE #(
    .INIT(1'b0)) 
    time_tlock_max_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(time_tlock_max_i_1_n_0),
        .Q(time_tlock_max_reg_n_0),
        .R(1'b0));
  LUT5 #(
    .INIT(32'hFFFF1000)) 
    tx_fsm_reset_done_int_i_1
       (.I0(tx_state[1]),
        .I1(tx_state[2]),
        .I2(tx_state[0]),
        .I3(tx_state[3]),
        .I4(data_in),
        .O(tx_fsm_reset_done_int_i_1_n_0));
  FDRE #(
    .INIT(1'b0)) 
    tx_fsm_reset_done_int_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(tx_fsm_reset_done_int_i_1_n_0),
        .Q(data_in),
        .R(pma_reset));
  FDRE #(
    .INIT(1'b0)) 
    tx_fsm_reset_done_int_s3_reg
       (.C(userclk),
        .CE(1'b1),
        .D(tx_fsm_reset_done_int_s2),
        .Q(tx_fsm_reset_done_int_s3),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    txresetdone_s3_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(txresetdone_s2),
        .Q(txresetdone_s3),
        .R(1'b0));
  LUT1 #(
    .INIT(2'h1)) 
    \wait_bypass_count[0]_i_1 
       (.I0(run_phase_alignment_int_s3),
        .O(clear));
  LUT2 #(
    .INIT(4'h2)) 
    \wait_bypass_count[0]_i_2 
       (.I0(time_out_wait_bypass_i_2_n_0),
        .I1(tx_fsm_reset_done_int_s3),
        .O(\wait_bypass_count[0]_i_2_n_0 ));
  LUT1 #(
    .INIT(2'h1)) 
    \wait_bypass_count[0]_i_4 
       (.I0(wait_bypass_count_reg[0]),
        .O(\wait_bypass_count[0]_i_4_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[0] 
       (.C(userclk),
        .CE(\wait_bypass_count[0]_i_2_n_0 ),
        .D(\wait_bypass_count_reg[0]_i_3_n_7 ),
        .Q(wait_bypass_count_reg[0]),
        .R(clear));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \wait_bypass_count_reg[0]_i_3 
       (.CI(1'b0),
        .CO({\wait_bypass_count_reg[0]_i_3_n_0 ,\wait_bypass_count_reg[0]_i_3_n_1 ,\wait_bypass_count_reg[0]_i_3_n_2 ,\wait_bypass_count_reg[0]_i_3_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b1}),
        .O({\wait_bypass_count_reg[0]_i_3_n_4 ,\wait_bypass_count_reg[0]_i_3_n_5 ,\wait_bypass_count_reg[0]_i_3_n_6 ,\wait_bypass_count_reg[0]_i_3_n_7 }),
        .S({wait_bypass_count_reg[3:1],\wait_bypass_count[0]_i_4_n_0 }));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[10] 
       (.C(userclk),
        .CE(\wait_bypass_count[0]_i_2_n_0 ),
        .D(\wait_bypass_count_reg[8]_i_1_n_5 ),
        .Q(wait_bypass_count_reg[10]),
        .R(clear));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[11] 
       (.C(userclk),
        .CE(\wait_bypass_count[0]_i_2_n_0 ),
        .D(\wait_bypass_count_reg[8]_i_1_n_4 ),
        .Q(wait_bypass_count_reg[11]),
        .R(clear));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[12] 
       (.C(userclk),
        .CE(\wait_bypass_count[0]_i_2_n_0 ),
        .D(\wait_bypass_count_reg[12]_i_1_n_7 ),
        .Q(wait_bypass_count_reg[12]),
        .R(clear));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \wait_bypass_count_reg[12]_i_1 
       (.CI(\wait_bypass_count_reg[8]_i_1_n_0 ),
        .CO({\wait_bypass_count_reg[12]_i_1_n_0 ,\wait_bypass_count_reg[12]_i_1_n_1 ,\wait_bypass_count_reg[12]_i_1_n_2 ,\wait_bypass_count_reg[12]_i_1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\wait_bypass_count_reg[12]_i_1_n_4 ,\wait_bypass_count_reg[12]_i_1_n_5 ,\wait_bypass_count_reg[12]_i_1_n_6 ,\wait_bypass_count_reg[12]_i_1_n_7 }),
        .S(wait_bypass_count_reg[15:12]));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[13] 
       (.C(userclk),
        .CE(\wait_bypass_count[0]_i_2_n_0 ),
        .D(\wait_bypass_count_reg[12]_i_1_n_6 ),
        .Q(wait_bypass_count_reg[13]),
        .R(clear));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[14] 
       (.C(userclk),
        .CE(\wait_bypass_count[0]_i_2_n_0 ),
        .D(\wait_bypass_count_reg[12]_i_1_n_5 ),
        .Q(wait_bypass_count_reg[14]),
        .R(clear));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[15] 
       (.C(userclk),
        .CE(\wait_bypass_count[0]_i_2_n_0 ),
        .D(\wait_bypass_count_reg[12]_i_1_n_4 ),
        .Q(wait_bypass_count_reg[15]),
        .R(clear));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[16] 
       (.C(userclk),
        .CE(\wait_bypass_count[0]_i_2_n_0 ),
        .D(\wait_bypass_count_reg[16]_i_1_n_7 ),
        .Q(wait_bypass_count_reg[16]),
        .R(clear));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \wait_bypass_count_reg[16]_i_1 
       (.CI(\wait_bypass_count_reg[12]_i_1_n_0 ),
        .CO(\NLW_wait_bypass_count_reg[16]_i_1_CO_UNCONNECTED [3:0]),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\NLW_wait_bypass_count_reg[16]_i_1_O_UNCONNECTED [3:1],\wait_bypass_count_reg[16]_i_1_n_7 }),
        .S({1'b0,1'b0,1'b0,wait_bypass_count_reg[16]}));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[1] 
       (.C(userclk),
        .CE(\wait_bypass_count[0]_i_2_n_0 ),
        .D(\wait_bypass_count_reg[0]_i_3_n_6 ),
        .Q(wait_bypass_count_reg[1]),
        .R(clear));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[2] 
       (.C(userclk),
        .CE(\wait_bypass_count[0]_i_2_n_0 ),
        .D(\wait_bypass_count_reg[0]_i_3_n_5 ),
        .Q(wait_bypass_count_reg[2]),
        .R(clear));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[3] 
       (.C(userclk),
        .CE(\wait_bypass_count[0]_i_2_n_0 ),
        .D(\wait_bypass_count_reg[0]_i_3_n_4 ),
        .Q(wait_bypass_count_reg[3]),
        .R(clear));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[4] 
       (.C(userclk),
        .CE(\wait_bypass_count[0]_i_2_n_0 ),
        .D(\wait_bypass_count_reg[4]_i_1_n_7 ),
        .Q(wait_bypass_count_reg[4]),
        .R(clear));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \wait_bypass_count_reg[4]_i_1 
       (.CI(\wait_bypass_count_reg[0]_i_3_n_0 ),
        .CO({\wait_bypass_count_reg[4]_i_1_n_0 ,\wait_bypass_count_reg[4]_i_1_n_1 ,\wait_bypass_count_reg[4]_i_1_n_2 ,\wait_bypass_count_reg[4]_i_1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\wait_bypass_count_reg[4]_i_1_n_4 ,\wait_bypass_count_reg[4]_i_1_n_5 ,\wait_bypass_count_reg[4]_i_1_n_6 ,\wait_bypass_count_reg[4]_i_1_n_7 }),
        .S(wait_bypass_count_reg[7:4]));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[5] 
       (.C(userclk),
        .CE(\wait_bypass_count[0]_i_2_n_0 ),
        .D(\wait_bypass_count_reg[4]_i_1_n_6 ),
        .Q(wait_bypass_count_reg[5]),
        .R(clear));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[6] 
       (.C(userclk),
        .CE(\wait_bypass_count[0]_i_2_n_0 ),
        .D(\wait_bypass_count_reg[4]_i_1_n_5 ),
        .Q(wait_bypass_count_reg[6]),
        .R(clear));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[7] 
       (.C(userclk),
        .CE(\wait_bypass_count[0]_i_2_n_0 ),
        .D(\wait_bypass_count_reg[4]_i_1_n_4 ),
        .Q(wait_bypass_count_reg[7]),
        .R(clear));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[8] 
       (.C(userclk),
        .CE(\wait_bypass_count[0]_i_2_n_0 ),
        .D(\wait_bypass_count_reg[8]_i_1_n_7 ),
        .Q(wait_bypass_count_reg[8]),
        .R(clear));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \wait_bypass_count_reg[8]_i_1 
       (.CI(\wait_bypass_count_reg[4]_i_1_n_0 ),
        .CO({\wait_bypass_count_reg[8]_i_1_n_0 ,\wait_bypass_count_reg[8]_i_1_n_1 ,\wait_bypass_count_reg[8]_i_1_n_2 ,\wait_bypass_count_reg[8]_i_1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\wait_bypass_count_reg[8]_i_1_n_4 ,\wait_bypass_count_reg[8]_i_1_n_5 ,\wait_bypass_count_reg[8]_i_1_n_6 ,\wait_bypass_count_reg[8]_i_1_n_7 }),
        .S(wait_bypass_count_reg[11:8]));
  FDRE #(
    .INIT(1'b0)) 
    \wait_bypass_count_reg[9] 
       (.C(userclk),
        .CE(\wait_bypass_count[0]_i_2_n_0 ),
        .D(\wait_bypass_count_reg[8]_i_1_n_6 ),
        .Q(wait_bypass_count_reg[9]),
        .R(clear));
  (* SOFT_HLUTNM = "soft_lutpair106" *) 
  LUT1 #(
    .INIT(2'h1)) 
    \wait_time_cnt[0]_i_1 
       (.I0(wait_time_cnt_reg[0]),
        .O(wait_time_cnt0));
  (* SOFT_HLUTNM = "soft_lutpair106" *) 
  LUT2 #(
    .INIT(4'h9)) 
    \wait_time_cnt[1]_i_1 
       (.I0(wait_time_cnt_reg[0]),
        .I1(wait_time_cnt_reg[1]),
        .O(\wait_time_cnt[1]_i_1_n_0 ));
  LUT3 #(
    .INIT(8'hE1)) 
    \wait_time_cnt[2]_i_1 
       (.I0(wait_time_cnt_reg[1]),
        .I1(wait_time_cnt_reg[0]),
        .I2(wait_time_cnt_reg[2]),
        .O(\wait_time_cnt[2]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair99" *) 
  LUT4 #(
    .INIT(16'hFE01)) 
    \wait_time_cnt[3]_i_1 
       (.I0(wait_time_cnt_reg[2]),
        .I1(wait_time_cnt_reg[0]),
        .I2(wait_time_cnt_reg[1]),
        .I3(wait_time_cnt_reg[3]),
        .O(\wait_time_cnt[3]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair99" *) 
  LUT5 #(
    .INIT(32'hFFFE0001)) 
    \wait_time_cnt[4]_i_1 
       (.I0(wait_time_cnt_reg[3]),
        .I1(wait_time_cnt_reg[1]),
        .I2(wait_time_cnt_reg[0]),
        .I3(wait_time_cnt_reg[2]),
        .I4(wait_time_cnt_reg[4]),
        .O(\wait_time_cnt[4]_i_1_n_0 ));
  LUT6 #(
    .INIT(64'hFFFFFFFE00000001)) 
    \wait_time_cnt[5]_i_1 
       (.I0(wait_time_cnt_reg[4]),
        .I1(wait_time_cnt_reg[2]),
        .I2(wait_time_cnt_reg[0]),
        .I3(wait_time_cnt_reg[1]),
        .I4(wait_time_cnt_reg[3]),
        .I5(wait_time_cnt_reg[5]),
        .O(\wait_time_cnt[5]_i_1_n_0 ));
  LUT4 #(
    .INIT(16'h0700)) 
    \wait_time_cnt[6]_i_1__0 
       (.I0(tx_state[1]),
        .I1(tx_state[2]),
        .I2(tx_state[3]),
        .I3(tx_state[0]),
        .O(wait_time_cnt0_0));
  LUT2 #(
    .INIT(4'hE)) 
    \wait_time_cnt[6]_i_2 
       (.I0(\wait_time_cnt[6]_i_4_n_0 ),
        .I1(wait_time_cnt_reg[6]),
        .O(sel));
  LUT2 #(
    .INIT(4'h9)) 
    \wait_time_cnt[6]_i_3 
       (.I0(\wait_time_cnt[6]_i_4_n_0 ),
        .I1(wait_time_cnt_reg[6]),
        .O(\wait_time_cnt[6]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hFFFFFFFFFFFFFFFE)) 
    \wait_time_cnt[6]_i_4 
       (.I0(wait_time_cnt_reg[4]),
        .I1(wait_time_cnt_reg[2]),
        .I2(wait_time_cnt_reg[0]),
        .I3(wait_time_cnt_reg[1]),
        .I4(wait_time_cnt_reg[3]),
        .I5(wait_time_cnt_reg[5]),
        .O(\wait_time_cnt[6]_i_4_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \wait_time_cnt_reg[0] 
       (.C(independent_clock_bufg),
        .CE(sel),
        .D(wait_time_cnt0),
        .Q(wait_time_cnt_reg[0]),
        .R(wait_time_cnt0_0));
  FDRE #(
    .INIT(1'b0)) 
    \wait_time_cnt_reg[1] 
       (.C(independent_clock_bufg),
        .CE(sel),
        .D(\wait_time_cnt[1]_i_1_n_0 ),
        .Q(wait_time_cnt_reg[1]),
        .R(wait_time_cnt0_0));
  FDSE #(
    .INIT(1'b0)) 
    \wait_time_cnt_reg[2] 
       (.C(independent_clock_bufg),
        .CE(sel),
        .D(\wait_time_cnt[2]_i_1_n_0 ),
        .Q(wait_time_cnt_reg[2]),
        .S(wait_time_cnt0_0));
  FDRE #(
    .INIT(1'b0)) 
    \wait_time_cnt_reg[3] 
       (.C(independent_clock_bufg),
        .CE(sel),
        .D(\wait_time_cnt[3]_i_1_n_0 ),
        .Q(wait_time_cnt_reg[3]),
        .R(wait_time_cnt0_0));
  FDRE #(
    .INIT(1'b0)) 
    \wait_time_cnt_reg[4] 
       (.C(independent_clock_bufg),
        .CE(sel),
        .D(\wait_time_cnt[4]_i_1_n_0 ),
        .Q(wait_time_cnt_reg[4]),
        .R(wait_time_cnt0_0));
  FDSE #(
    .INIT(1'b0)) 
    \wait_time_cnt_reg[5] 
       (.C(independent_clock_bufg),
        .CE(sel),
        .D(\wait_time_cnt[5]_i_1_n_0 ),
        .Q(wait_time_cnt_reg[5]),
        .S(wait_time_cnt0_0));
  FDSE #(
    .INIT(1'b0)) 
    \wait_time_cnt_reg[6] 
       (.C(independent_clock_bufg),
        .CE(sel),
        .D(\wait_time_cnt[6]_i_3_n_0 ),
        .Q(wait_time_cnt_reg[6]),
        .S(wait_time_cnt0_0));
endmodule

(* EXAMPLE_SIMULATION = "0" *) (* downgradeipidentifiedwarnings = "yes" *) 
module gmii_to_sgmii_bridge_block
   (gtrefclk,
    gtrefclk_bufg,
    txp,
    txn,
    rxp,
    rxn,
    txoutclk,
    rxoutclk,
    resetdone,
    cplllock,
    mmcm_reset,
    mmcm_locked,
    userclk,
    userclk2,
    rxuserclk,
    rxuserclk2,
    independent_clock_bufg,
    pma_reset,
    sgmii_clk_r,
    sgmii_clk_f,
    sgmii_clk_en,
    gmii_txd,
    gmii_tx_en,
    gmii_tx_er,
    gmii_rxd,
    gmii_rx_dv,
    gmii_rx_er,
    gmii_isolate,
    configuration_vector,
    an_interrupt,
    an_adv_config_vector,
    an_restart_config,
    speed_is_10_100,
    speed_is_100,
    status_vector,
    reset,
    signal_detect,
    gt0_qplloutclk_in,
    gt0_qplloutrefclk_in);
  input gtrefclk;
  input gtrefclk_bufg;
  output txp;
  output txn;
  input rxp;
  input rxn;
  output txoutclk;
  output rxoutclk;
  output resetdone;
  output cplllock;
  output mmcm_reset;
  input mmcm_locked;
  input userclk;
  input userclk2;
  input rxuserclk;
  input rxuserclk2;
  input independent_clock_bufg;
  input pma_reset;
  output sgmii_clk_r;
  output sgmii_clk_f;
  output sgmii_clk_en;
  input [7:0]gmii_txd;
  input gmii_tx_en;
  input gmii_tx_er;
  output [7:0]gmii_rxd;
  output gmii_rx_dv;
  output gmii_rx_er;
  output gmii_isolate;
  input [4:0]configuration_vector;
  output an_interrupt;
  input [15:0]an_adv_config_vector;
  input an_restart_config;
  input speed_is_10_100;
  input speed_is_100;
  output [15:0]status_vector;
  input reset;
  input signal_detect;
  input gt0_qplloutclk_in;
  input gt0_qplloutrefclk_in;

  wire \<const0> ;
  wire [15:0]an_adv_config_vector;
  wire an_interrupt;
  wire an_restart_config;
  wire [4:0]configuration_vector;
  wire cplllock;
  wire enablealign;
  wire gmii_isolate;
  wire gmii_rx_dv;
  wire gmii_rx_dv_int;
  wire gmii_rx_er;
  wire gmii_rx_er_int;
  wire [7:0]gmii_rxd;
  wire [7:0]gmii_rxd_int;
  wire gmii_tx_en;
  wire gmii_tx_en_int;
  wire gmii_tx_er;
  wire gmii_tx_er_int;
  wire [7:0]gmii_txd;
  wire [7:0]gmii_txd_int;
  wire gt0_qplloutclk_in;
  wire gt0_qplloutrefclk_in;
  wire gtrefclk;
  wire gtrefclk_bufg;
  wire independent_clock_bufg;
  wire mgt_rx_reset;
  wire mgt_tx_reset;
  wire mmcm_locked;
  wire mmcm_reset;
  wire pma_reset;
  wire powerdown;
  wire reset;
  wire resetdone;
  wire rx_reset_done_i;
  wire rxbuferr;
  wire rxchariscomma;
  wire rxcharisk;
  wire [2:0]rxclkcorcnt;
  wire [7:0]rxdata;
  wire rxdisperr;
  wire rxn;
  wire rxnotintable;
  wire rxoutclk;
  wire rxp;
  wire rxuserclk;
  wire rxuserclk2;
  wire sgmii_clk_en;
  wire sgmii_clk_f;
  wire sgmii_clk_r;
  wire signal_detect;
  wire speed_is_100;
  wire speed_is_10_100;
  wire [13:0]\^status_vector ;
  wire transceiver_inst_n_13;
  wire transceiver_inst_n_14;
  wire txbuferr;
  wire txchardispmode;
  wire txchardispval;
  wire txcharisk;
  wire [7:0]txdata;
  wire txn;
  wire txoutclk;
  wire txp;
  wire userclk;
  wire userclk2;
  wire NLW_gmii_to_sgmii_bridge_core_an_enable_UNCONNECTED;
  wire NLW_gmii_to_sgmii_bridge_core_drp_den_UNCONNECTED;
  wire NLW_gmii_to_sgmii_bridge_core_drp_dwe_UNCONNECTED;
  wire NLW_gmii_to_sgmii_bridge_core_drp_req_UNCONNECTED;
  wire NLW_gmii_to_sgmii_bridge_core_en_cdet_UNCONNECTED;
  wire NLW_gmii_to_sgmii_bridge_core_ewrap_UNCONNECTED;
  wire NLW_gmii_to_sgmii_bridge_core_loc_ref_UNCONNECTED;
  wire NLW_gmii_to_sgmii_bridge_core_mdio_out_UNCONNECTED;
  wire NLW_gmii_to_sgmii_bridge_core_mdio_tri_UNCONNECTED;
  wire NLW_gmii_to_sgmii_bridge_core_s_axi_arready_UNCONNECTED;
  wire NLW_gmii_to_sgmii_bridge_core_s_axi_awready_UNCONNECTED;
  wire NLW_gmii_to_sgmii_bridge_core_s_axi_bvalid_UNCONNECTED;
  wire NLW_gmii_to_sgmii_bridge_core_s_axi_rvalid_UNCONNECTED;
  wire NLW_gmii_to_sgmii_bridge_core_s_axi_wready_UNCONNECTED;
  wire [9:0]NLW_gmii_to_sgmii_bridge_core_drp_daddr_UNCONNECTED;
  wire [15:0]NLW_gmii_to_sgmii_bridge_core_drp_di_UNCONNECTED;
  wire [63:0]NLW_gmii_to_sgmii_bridge_core_rxphy_correction_timer_UNCONNECTED;
  wire [31:0]NLW_gmii_to_sgmii_bridge_core_rxphy_ns_field_UNCONNECTED;
  wire [47:0]NLW_gmii_to_sgmii_bridge_core_rxphy_s_field_UNCONNECTED;
  wire [1:0]NLW_gmii_to_sgmii_bridge_core_s_axi_bresp_UNCONNECTED;
  wire [31:0]NLW_gmii_to_sgmii_bridge_core_s_axi_rdata_UNCONNECTED;
  wire [1:0]NLW_gmii_to_sgmii_bridge_core_s_axi_rresp_UNCONNECTED;
  wire [1:0]NLW_gmii_to_sgmii_bridge_core_speed_selection_UNCONNECTED;
  wire [15:8]NLW_gmii_to_sgmii_bridge_core_status_vector_UNCONNECTED;
  wire [9:0]NLW_gmii_to_sgmii_bridge_core_tx_code_group_UNCONNECTED;

  assign status_vector[15] = \<const0> ;
  assign status_vector[14] = \<const0> ;
  assign status_vector[13:9] = \^status_vector [13:9];
  assign status_vector[8] = \<const0> ;
  assign status_vector[7:0] = \^status_vector [7:0];
  GND GND
       (.G(\<const0> ));
  (* B_SHIFTER_ADDR = "10'b0101001110" *) 
  (* C_1588 = "0" *) 
  (* C_2_5G = "FALSE" *) 
  (* C_COMPONENT_NAME = "gmii_to_sgmii_bridge" *) 
  (* C_DYNAMIC_SWITCHING = "FALSE" *) 
  (* C_ELABORATION_TRANSIENT_DIR = "BlankString" *) 
  (* C_FAMILY = "kintex7" *) 
  (* C_HAS_AN = "TRUE" *) 
  (* C_HAS_AXIL = "FALSE" *) 
  (* C_HAS_MDIO = "FALSE" *) 
  (* C_HAS_TEMAC = "TRUE" *) 
  (* C_IS_SGMII = "TRUE" *) 
  (* C_RX_GMII_CLK = "TXOUTCLK" *) 
  (* C_SGMII_FABRIC_BUFFER = "TRUE" *) 
  (* C_SGMII_PHY_MODE = "FALSE" *) 
  (* C_USE_LVDS = "FALSE" *) 
  (* C_USE_TBI = "FALSE" *) 
  (* C_USE_TRANSCEIVER = "TRUE" *) 
  (* GT_RX_BYTE_WIDTH = "1" *) 
  (* KEEP_HIERARCHY = "soft" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  gmii_to_sgmii_bridge_gig_ethernet_pcs_pma_v16_2_9 gmii_to_sgmii_bridge_core
       (.an_adv_config_val(1'b0),
        .an_adv_config_vector({1'b0,1'b0,1'b0,1'b0,an_adv_config_vector[11],1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .an_enable(NLW_gmii_to_sgmii_bridge_core_an_enable_UNCONNECTED),
        .an_interrupt(an_interrupt),
        .an_restart_config(an_restart_config),
        .basex_or_sgmii(1'b0),
        .configuration_valid(1'b0),
        .configuration_vector(configuration_vector),
        .correction_timer({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .dcm_locked(mmcm_locked),
        .drp_daddr(NLW_gmii_to_sgmii_bridge_core_drp_daddr_UNCONNECTED[9:0]),
        .drp_dclk(1'b0),
        .drp_den(NLW_gmii_to_sgmii_bridge_core_drp_den_UNCONNECTED),
        .drp_di(NLW_gmii_to_sgmii_bridge_core_drp_di_UNCONNECTED[15:0]),
        .drp_do({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .drp_drdy(1'b0),
        .drp_dwe(NLW_gmii_to_sgmii_bridge_core_drp_dwe_UNCONNECTED),
        .drp_gnt(1'b0),
        .drp_req(NLW_gmii_to_sgmii_bridge_core_drp_req_UNCONNECTED),
        .en_cdet(NLW_gmii_to_sgmii_bridge_core_en_cdet_UNCONNECTED),
        .enablealign(enablealign),
        .ewrap(NLW_gmii_to_sgmii_bridge_core_ewrap_UNCONNECTED),
        .gmii_isolate(gmii_isolate),
        .gmii_rx_dv(gmii_rx_dv_int),
        .gmii_rx_er(gmii_rx_er_int),
        .gmii_rxd(gmii_rxd_int),
        .gmii_tx_en(gmii_tx_en_int),
        .gmii_tx_er(gmii_tx_er_int),
        .gmii_txd(gmii_txd_int),
        .gtx_clk(1'b0),
        .link_timer_basex({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .link_timer_sgmii({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .link_timer_value({1'b0,1'b0,1'b0,1'b0,1'b1,1'b1,1'b0,1'b0,1'b1,1'b0}),
        .loc_ref(NLW_gmii_to_sgmii_bridge_core_loc_ref_UNCONNECTED),
        .mdc(1'b0),
        .mdio_in(1'b0),
        .mdio_out(NLW_gmii_to_sgmii_bridge_core_mdio_out_UNCONNECTED),
        .mdio_tri(NLW_gmii_to_sgmii_bridge_core_mdio_tri_UNCONNECTED),
        .mgt_rx_reset(mgt_rx_reset),
        .mgt_tx_reset(mgt_tx_reset),
        .phyad({1'b0,1'b0,1'b0,1'b0,1'b0}),
        .pma_rx_clk0(1'b0),
        .pma_rx_clk1(1'b0),
        .powerdown(powerdown),
        .reset(reset),
        .reset_done(resetdone),
        .rx_code_group0({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .rx_code_group1({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .rx_gt_nominal_latency({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1,1'b1,1'b0,1'b0,1'b0}),
        .rxbufstatus({rxbuferr,1'b0}),
        .rxchariscomma(rxchariscomma),
        .rxcharisk(rxcharisk),
        .rxclkcorcnt({rxclkcorcnt[2],1'b0,rxclkcorcnt[0]}),
        .rxdata(rxdata),
        .rxdisperr(rxdisperr),
        .rxnotintable(rxnotintable),
        .rxphy_correction_timer(NLW_gmii_to_sgmii_bridge_core_rxphy_correction_timer_UNCONNECTED[63:0]),
        .rxphy_ns_field(NLW_gmii_to_sgmii_bridge_core_rxphy_ns_field_UNCONNECTED[31:0]),
        .rxphy_s_field(NLW_gmii_to_sgmii_bridge_core_rxphy_s_field_UNCONNECTED[47:0]),
        .rxrecclk(1'b0),
        .rxrundisp(1'b0),
        .s_axi_aclk(1'b0),
        .s_axi_araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arready(NLW_gmii_to_sgmii_bridge_core_s_axi_arready_UNCONNECTED),
        .s_axi_arvalid(1'b0),
        .s_axi_awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready(NLW_gmii_to_sgmii_bridge_core_s_axi_awready_UNCONNECTED),
        .s_axi_awvalid(1'b0),
        .s_axi_bready(1'b0),
        .s_axi_bresp(NLW_gmii_to_sgmii_bridge_core_s_axi_bresp_UNCONNECTED[1:0]),
        .s_axi_bvalid(NLW_gmii_to_sgmii_bridge_core_s_axi_bvalid_UNCONNECTED),
        .s_axi_rdata(NLW_gmii_to_sgmii_bridge_core_s_axi_rdata_UNCONNECTED[31:0]),
        .s_axi_resetn(1'b0),
        .s_axi_rready(1'b0),
        .s_axi_rresp(NLW_gmii_to_sgmii_bridge_core_s_axi_rresp_UNCONNECTED[1:0]),
        .s_axi_rvalid(NLW_gmii_to_sgmii_bridge_core_s_axi_rvalid_UNCONNECTED),
        .s_axi_wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wready(NLW_gmii_to_sgmii_bridge_core_s_axi_wready_UNCONNECTED),
        .s_axi_wvalid(1'b0),
        .signal_detect(signal_detect),
        .speed_is_100(1'b0),
        .speed_is_10_100(1'b0),
        .speed_selection(NLW_gmii_to_sgmii_bridge_core_speed_selection_UNCONNECTED[1:0]),
        .status_vector({NLW_gmii_to_sgmii_bridge_core_status_vector_UNCONNECTED[15:14],\^status_vector }),
        .systemtimer_ns_field({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .systemtimer_s_field({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .tx_code_group(NLW_gmii_to_sgmii_bridge_core_tx_code_group_UNCONNECTED[9:0]),
        .txbuferr(txbuferr),
        .txchardispmode(txchardispmode),
        .txchardispval(txchardispval),
        .txcharisk(txcharisk),
        .txdata(txdata),
        .userclk(1'b0),
        .userclk2(userclk2));
  gmii_to_sgmii_bridge_sgmii_adapt sgmii_logic
       (.D(gmii_rxd_int),
        .Q(gmii_txd_int),
        .SR(mgt_tx_reset),
        .gmii_rx_dv(gmii_rx_dv_int),
        .gmii_rx_dv_out_reg(gmii_rx_dv),
        .gmii_rx_er(gmii_rx_er_int),
        .gmii_rx_er_out_reg(gmii_rx_er),
        .gmii_rxd(gmii_rxd),
        .gmii_tx_en(gmii_tx_en_int),
        .gmii_tx_en_out_reg(gmii_tx_en),
        .gmii_tx_er(gmii_tx_er_int),
        .gmii_tx_er_out_reg(gmii_tx_er),
        .gmii_txd(gmii_txd),
        .sgmii_clk_en_reg(sgmii_clk_en),
        .sgmii_clk_f(sgmii_clk_f),
        .sgmii_clk_r(sgmii_clk_r),
        .speed_is_100(speed_is_100),
        .speed_is_10_100(speed_is_10_100),
        .userclk2(userclk2));
  gmii_to_sgmii_bridge_sync_block__parameterized1 sync_block_rx_reset_done
       (.data_in(transceiver_inst_n_14),
        .data_out(rx_reset_done_i),
        .userclk2(userclk2));
  gmii_to_sgmii_bridge_sync_block__parameterized1_0 sync_block_tx_reset_done
       (.data_in(transceiver_inst_n_13),
        .resetdone(resetdone),
        .resetdone_0(rx_reset_done_i),
        .userclk2(userclk2));
  gmii_to_sgmii_bridge_transceiver transceiver_inst
       (.D(txchardispmode),
        .Q(rxdata),
        .SR(mgt_tx_reset),
        .cplllock(cplllock),
        .data_in(transceiver_inst_n_13),
        .enablealign(enablealign),
        .gt0_qplloutclk_in(gt0_qplloutclk_in),
        .gt0_qplloutrefclk_in(gt0_qplloutrefclk_in),
        .gtrefclk(gtrefclk),
        .gtrefclk_bufg(gtrefclk_bufg),
        .independent_clock_bufg(independent_clock_bufg),
        .mgt_rx_reset(mgt_rx_reset),
        .mmcm_locked(mmcm_locked),
        .mmcm_reset(mmcm_reset),
        .pma_reset(pma_reset),
        .powerdown(powerdown),
        .rx_fsm_reset_done_int_reg(transceiver_inst_n_14),
        .rxbufstatus(rxbuferr),
        .rxchariscomma(rxchariscomma),
        .rxcharisk(rxcharisk),
        .rxclkcorcnt({rxclkcorcnt[2],rxclkcorcnt[0]}),
        .rxdisperr(rxdisperr),
        .rxn(rxn),
        .rxnotintable(rxnotintable),
        .rxoutclk(rxoutclk),
        .rxp(rxp),
        .rxuserclk(rxuserclk),
        .rxuserclk2(rxuserclk2),
        .status_vector(\^status_vector [1]),
        .txbuferr(txbuferr),
        .txchardispval_reg_reg_0(txchardispval),
        .txcharisk_reg_reg_0(txcharisk),
        .\txdata_reg_reg[7]_0 (txdata),
        .txn(txn),
        .txoutclk(txoutclk),
        .txp(txp),
        .userclk(userclk),
        .userclk2(userclk2));
endmodule

module gmii_to_sgmii_bridge_clk_gen
   (sgmii_clk_r,
    sgmii_clk_en_reg_0,
    sgmii_clk_f,
    userclk2,
    reset_out,
    data_out,
    speed_is_10_100_fall_reg_0);
  output sgmii_clk_r;
  output sgmii_clk_en_reg_0;
  output sgmii_clk_f;
  input userclk2;
  input reset_out;
  input data_out;
  input speed_is_10_100_fall_reg_0;

  wire clk12_5;
  wire clk12_5_reg;
  wire clk1_25;
  wire clk1_25_reg;
  wire clk_div_stage1_n_3;
  wire clk_en;
  wire clk_en0;
  wire clk_en_12_5_fall;
  wire clk_en_12_5_fall0;
  wire clk_en_1_25_fall;
  wire clk_en_1_25_fall0;
  wire data_out;
  wire reset_fall;
  wire reset_out;
  wire sgmii_clk_en_i_1_n_0;
  wire sgmii_clk_en_reg_0;
  wire sgmii_clk_f;
  wire sgmii_clk_r;
  wire sgmii_clk_r0_out;
  wire speed_is_100_fall;
  wire speed_is_10_100_fall;
  wire speed_is_10_100_fall_reg_0;
  wire userclk2;

  FDRE clk12_5_reg_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(clk12_5),
        .Q(clk12_5_reg),
        .R(reset_out));
  FDRE clk1_25_reg_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(clk1_25),
        .Q(clk1_25_reg),
        .R(reset_out));
  gmii_to_sgmii_bridge_johnson_cntr clk_div_stage1
       (.clk12_5(clk12_5),
        .clk12_5_reg(clk12_5_reg),
        .clk1_25(clk1_25),
        .clk_en0(clk_en0),
        .clk_en_12_5_fall0(clk_en_12_5_fall0),
        .reset_fall(reset_fall),
        .reset_out(reset_out),
        .speed_is_100_fall(speed_is_100_fall),
        .speed_is_10_100_fall(speed_is_10_100_fall),
        .speed_is_10_100_fall_reg(clk_div_stage1_n_3),
        .userclk2(userclk2));
  gmii_to_sgmii_bridge_johnson_cntr_33 clk_div_stage2
       (.clk12_5(clk12_5),
        .clk1_25(clk1_25),
        .clk1_25_reg(clk1_25_reg),
        .clk_en(clk_en),
        .clk_en_1_25_fall0(clk_en_1_25_fall0),
        .data_out(data_out),
        .reset_out(reset_out),
        .sgmii_clk_r0_out(sgmii_clk_r0_out),
        .sgmii_clk_r_reg(speed_is_10_100_fall_reg_0),
        .userclk2(userclk2));
  FDRE clk_en_12_5_fall_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(clk_en_12_5_fall0),
        .Q(clk_en_12_5_fall),
        .R(reset_out));
  FDRE clk_en_12_5_rise_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(clk_en0),
        .Q(clk_en),
        .R(reset_out));
  FDRE clk_en_1_25_fall_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(clk_en_1_25_fall0),
        .Q(clk_en_1_25_fall),
        .R(reset_out));
  FDRE #(
    .IS_C_INVERTED(1'b1)) 
    reset_fall_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(reset_out),
        .Q(reset_fall),
        .R(1'b0));
  LUT4 #(
    .INIT(16'hE2FF)) 
    sgmii_clk_en_i_1
       (.I0(clk_en_1_25_fall),
        .I1(data_out),
        .I2(clk_en_12_5_fall),
        .I3(speed_is_10_100_fall_reg_0),
        .O(sgmii_clk_en_i_1_n_0));
  FDRE sgmii_clk_en_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(sgmii_clk_en_i_1_n_0),
        .Q(sgmii_clk_en_reg_0),
        .R(reset_out));
  FDRE #(
    .IS_C_INVERTED(1'b1)) 
    sgmii_clk_f_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(clk_div_stage1_n_3),
        .Q(sgmii_clk_f),
        .R(1'b0));
  FDRE sgmii_clk_r_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(sgmii_clk_r0_out),
        .Q(sgmii_clk_r),
        .R(reset_out));
  FDRE #(
    .IS_C_INVERTED(1'b1)) 
    speed_is_100_fall_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(data_out),
        .Q(speed_is_100_fall),
        .R(1'b0));
  FDRE #(
    .IS_C_INVERTED(1'b1)) 
    speed_is_10_100_fall_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(speed_is_10_100_fall_reg_0),
        .Q(speed_is_10_100_fall),
        .R(1'b0));
endmodule

module gmii_to_sgmii_bridge_cpll_railing
   (cpll_pd0_i,
    cpllreset_in,
    gtrefclk_bufg,
    gt0_cpllreset_t);
  output cpll_pd0_i;
  output cpllreset_in;
  input gtrefclk_bufg;
  input gt0_cpllreset_t;

  wire cpll_pd0_i;
  wire cpll_reset_out;
  wire \cpllpd_wait_reg[31]_srl32_n_1 ;
  wire \cpllpd_wait_reg[63]_srl32_n_1 ;
  wire \cpllpd_wait_reg[94]_srl31_n_0 ;
  wire cpllreset_in;
  wire \cpllreset_wait_reg[126]_srl31_n_0 ;
  wire \cpllreset_wait_reg[31]_srl32_n_1 ;
  wire \cpllreset_wait_reg[63]_srl32_n_1 ;
  wire \cpllreset_wait_reg[95]_srl32_n_1 ;
  wire gt0_cpllreset_t;
  wire gtrefclk_bufg;
  wire \NLW_cpllpd_wait_reg[31]_srl32_Q_UNCONNECTED ;
  wire \NLW_cpllpd_wait_reg[63]_srl32_Q_UNCONNECTED ;
  wire \NLW_cpllpd_wait_reg[94]_srl31_Q31_UNCONNECTED ;
  wire \NLW_cpllreset_wait_reg[126]_srl31_Q31_UNCONNECTED ;
  wire \NLW_cpllreset_wait_reg[31]_srl32_Q_UNCONNECTED ;
  wire \NLW_cpllreset_wait_reg[63]_srl32_Q_UNCONNECTED ;
  wire \NLW_cpllreset_wait_reg[95]_srl32_Q_UNCONNECTED ;

  (* srl_bus_name = "U0/\transceiver_inst/gtwizard_inst/U0/gtwizard_i/cpll_railing0_i/cpllpd_wait_reg " *) 
  (* srl_name = "U0/\transceiver_inst/gtwizard_inst/U0/gtwizard_i/cpll_railing0_i/cpllpd_wait_reg[31]_srl32 " *) 
  SRLC32E #(
    .INIT(32'hFFFFFFFF)) 
    \cpllpd_wait_reg[31]_srl32 
       (.A({1'b1,1'b1,1'b1,1'b1,1'b1}),
        .CE(1'b1),
        .CLK(gtrefclk_bufg),
        .D(1'b0),
        .Q(\NLW_cpllpd_wait_reg[31]_srl32_Q_UNCONNECTED ),
        .Q31(\cpllpd_wait_reg[31]_srl32_n_1 ));
  (* srl_bus_name = "U0/\transceiver_inst/gtwizard_inst/U0/gtwizard_i/cpll_railing0_i/cpllpd_wait_reg " *) 
  (* srl_name = "U0/\transceiver_inst/gtwizard_inst/U0/gtwizard_i/cpll_railing0_i/cpllpd_wait_reg[63]_srl32 " *) 
  SRLC32E #(
    .INIT(32'hFFFFFFFF)) 
    \cpllpd_wait_reg[63]_srl32 
       (.A({1'b1,1'b1,1'b1,1'b1,1'b1}),
        .CE(1'b1),
        .CLK(gtrefclk_bufg),
        .D(\cpllpd_wait_reg[31]_srl32_n_1 ),
        .Q(\NLW_cpllpd_wait_reg[63]_srl32_Q_UNCONNECTED ),
        .Q31(\cpllpd_wait_reg[63]_srl32_n_1 ));
  (* srl_bus_name = "U0/\transceiver_inst/gtwizard_inst/U0/gtwizard_i/cpll_railing0_i/cpllpd_wait_reg " *) 
  (* srl_name = "U0/\transceiver_inst/gtwizard_inst/U0/gtwizard_i/cpll_railing0_i/cpllpd_wait_reg[94]_srl31 " *) 
  SRLC32E #(
    .INIT(32'h7FFFFFFF)) 
    \cpllpd_wait_reg[94]_srl31 
       (.A({1'b1,1'b1,1'b1,1'b1,1'b0}),
        .CE(1'b1),
        .CLK(gtrefclk_bufg),
        .D(\cpllpd_wait_reg[63]_srl32_n_1 ),
        .Q(\cpllpd_wait_reg[94]_srl31_n_0 ),
        .Q31(\NLW_cpllpd_wait_reg[94]_srl31_Q31_UNCONNECTED ));
  (* equivalent_register_removal = "no" *) 
  FDRE #(
    .INIT(1'b1)) 
    \cpllpd_wait_reg[95] 
       (.C(gtrefclk_bufg),
        .CE(1'b1),
        .D(\cpllpd_wait_reg[94]_srl31_n_0 ),
        .Q(cpll_pd0_i),
        .R(1'b0));
  (* srl_bus_name = "U0/\transceiver_inst/gtwizard_inst/U0/gtwizard_i/cpll_railing0_i/cpllreset_wait_reg " *) 
  (* srl_name = "U0/\transceiver_inst/gtwizard_inst/U0/gtwizard_i/cpll_railing0_i/cpllreset_wait_reg[126]_srl31 " *) 
  SRLC32E #(
    .INIT(32'h00000000)) 
    \cpllreset_wait_reg[126]_srl31 
       (.A({1'b1,1'b1,1'b1,1'b1,1'b0}),
        .CE(1'b1),
        .CLK(gtrefclk_bufg),
        .D(\cpllreset_wait_reg[95]_srl32_n_1 ),
        .Q(\cpllreset_wait_reg[126]_srl31_n_0 ),
        .Q31(\NLW_cpllreset_wait_reg[126]_srl31_Q31_UNCONNECTED ));
  (* equivalent_register_removal = "no" *) 
  FDRE #(
    .INIT(1'b0)) 
    \cpllreset_wait_reg[127] 
       (.C(gtrefclk_bufg),
        .CE(1'b1),
        .D(\cpllreset_wait_reg[126]_srl31_n_0 ),
        .Q(cpll_reset_out),
        .R(1'b0));
  (* srl_bus_name = "U0/\transceiver_inst/gtwizard_inst/U0/gtwizard_i/cpll_railing0_i/cpllreset_wait_reg " *) 
  (* srl_name = "U0/\transceiver_inst/gtwizard_inst/U0/gtwizard_i/cpll_railing0_i/cpllreset_wait_reg[31]_srl32 " *) 
  SRLC32E #(
    .INIT(32'h000000FF)) 
    \cpllreset_wait_reg[31]_srl32 
       (.A({1'b1,1'b1,1'b1,1'b1,1'b1}),
        .CE(1'b1),
        .CLK(gtrefclk_bufg),
        .D(1'b0),
        .Q(\NLW_cpllreset_wait_reg[31]_srl32_Q_UNCONNECTED ),
        .Q31(\cpllreset_wait_reg[31]_srl32_n_1 ));
  (* srl_bus_name = "U0/\transceiver_inst/gtwizard_inst/U0/gtwizard_i/cpll_railing0_i/cpllreset_wait_reg " *) 
  (* srl_name = "U0/\transceiver_inst/gtwizard_inst/U0/gtwizard_i/cpll_railing0_i/cpllreset_wait_reg[63]_srl32 " *) 
  SRLC32E #(
    .INIT(32'h00000000)) 
    \cpllreset_wait_reg[63]_srl32 
       (.A({1'b1,1'b1,1'b1,1'b1,1'b1}),
        .CE(1'b1),
        .CLK(gtrefclk_bufg),
        .D(\cpllreset_wait_reg[31]_srl32_n_1 ),
        .Q(\NLW_cpllreset_wait_reg[63]_srl32_Q_UNCONNECTED ),
        .Q31(\cpllreset_wait_reg[63]_srl32_n_1 ));
  (* srl_bus_name = "U0/\transceiver_inst/gtwizard_inst/U0/gtwizard_i/cpll_railing0_i/cpllreset_wait_reg " *) 
  (* srl_name = "U0/\transceiver_inst/gtwizard_inst/U0/gtwizard_i/cpll_railing0_i/cpllreset_wait_reg[95]_srl32 " *) 
  SRLC32E #(
    .INIT(32'h00000000)) 
    \cpllreset_wait_reg[95]_srl32 
       (.A({1'b1,1'b1,1'b1,1'b1,1'b1}),
        .CE(1'b1),
        .CLK(gtrefclk_bufg),
        .D(\cpllreset_wait_reg[63]_srl32_n_1 ),
        .Q(\NLW_cpllreset_wait_reg[95]_srl32_Q_UNCONNECTED ),
        .Q31(\cpllreset_wait_reg[95]_srl32_n_1 ));
  LUT2 #(
    .INIT(4'hE)) 
    gtxe2_i_i_1
       (.I0(cpll_reset_out),
        .I1(gt0_cpllreset_t),
        .O(cpllreset_in));
endmodule

module gmii_to_sgmii_bridge_johnson_cntr
   (clk12_5,
    clk_en_12_5_fall0,
    clk_en0,
    speed_is_10_100_fall_reg,
    userclk2,
    reset_out,
    clk12_5_reg,
    speed_is_10_100_fall,
    speed_is_100_fall,
    clk1_25,
    reset_fall);
  output clk12_5;
  output clk_en_12_5_fall0;
  output clk_en0;
  output speed_is_10_100_fall_reg;
  input userclk2;
  input reset_out;
  input clk12_5_reg;
  input speed_is_10_100_fall;
  input speed_is_100_fall;
  input clk1_25;
  input reset_fall;

  wire clk12_5;
  wire clk12_5_reg;
  wire clk1_25;
  wire clk_en0;
  wire clk_en_12_5_fall0;
  wire reg1;
  wire reg1_i_1_n_0;
  wire reg2;
  wire reg4;
  wire reg5;
  wire reg5_reg_n_0;
  wire reset_fall;
  wire reset_out;
  wire speed_is_100_fall;
  wire speed_is_10_100_fall;
  wire speed_is_10_100_fall_reg;
  wire userclk2;

  (* SOFT_HLUTNM = "soft_lutpair70" *) 
  LUT2 #(
    .INIT(4'h2)) 
    clk_en_12_5_fall_i_1
       (.I0(clk12_5_reg),
        .I1(clk12_5),
        .O(clk_en_12_5_fall0));
  (* SOFT_HLUTNM = "soft_lutpair70" *) 
  LUT2 #(
    .INIT(4'h2)) 
    clk_en_12_5_rise_i_1
       (.I0(clk12_5),
        .I1(clk12_5_reg),
        .O(clk_en0));
  LUT1 #(
    .INIT(2'h1)) 
    reg1_i_1
       (.I0(reg5_reg_n_0),
        .O(reg1_i_1_n_0));
  FDRE reg1_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(reg1_i_1_n_0),
        .Q(reg1),
        .R(reg5));
  FDRE reg2_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(reg1),
        .Q(reg2),
        .R(reg5));
  FDRE reg3_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(reg2),
        .Q(clk12_5),
        .R(reg5));
  FDRE reg4_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(clk12_5),
        .Q(reg4),
        .R(reg5));
  LUT3 #(
    .INIT(8'hF4)) 
    reg5_i_1
       (.I0(reg4),
        .I1(reg5_reg_n_0),
        .I2(reset_out),
        .O(reg5));
  FDRE reg5_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(reg4),
        .Q(reg5_reg_n_0),
        .R(reg5));
  LUT5 #(
    .INIT(32'h0000DFD5)) 
    sgmii_clk_f_i_1
       (.I0(speed_is_10_100_fall),
        .I1(clk12_5),
        .I2(speed_is_100_fall),
        .I3(clk1_25),
        .I4(reset_fall),
        .O(speed_is_10_100_fall_reg));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_johnson_cntr" *) 
module gmii_to_sgmii_bridge_johnson_cntr_33
   (clk1_25,
    sgmii_clk_r0_out,
    clk_en_1_25_fall0,
    clk_en,
    userclk2,
    reset_out,
    sgmii_clk_r_reg,
    data_out,
    clk12_5,
    clk1_25_reg);
  output clk1_25;
  output sgmii_clk_r0_out;
  output clk_en_1_25_fall0;
  input clk_en;
  input userclk2;
  input reset_out;
  input sgmii_clk_r_reg;
  input data_out;
  input clk12_5;
  input clk1_25_reg;

  wire clk12_5;
  wire clk1_25;
  wire clk1_25_reg;
  wire clk_en;
  wire clk_en_1_25_fall0;
  wire data_out;
  wire reg1_i_1__0_n_0;
  wire reg1_reg_n_0;
  wire reg2_reg_n_0;
  wire reg4;
  wire reg5;
  wire reg5_reg_n_0;
  wire reset_out;
  wire sgmii_clk_r0_out;
  wire sgmii_clk_r_reg;
  wire userclk2;

  (* SOFT_HLUTNM = "soft_lutpair71" *) 
  LUT2 #(
    .INIT(4'h2)) 
    clk_en_1_25_fall_i_1
       (.I0(clk1_25_reg),
        .I1(clk1_25),
        .O(clk_en_1_25_fall0));
  LUT1 #(
    .INIT(2'h1)) 
    reg1_i_1__0
       (.I0(reg5_reg_n_0),
        .O(reg1_i_1__0_n_0));
  FDRE reg1_reg
       (.C(userclk2),
        .CE(clk_en),
        .D(reg1_i_1__0_n_0),
        .Q(reg1_reg_n_0),
        .R(reg5));
  FDRE reg2_reg
       (.C(userclk2),
        .CE(clk_en),
        .D(reg1_reg_n_0),
        .Q(reg2_reg_n_0),
        .R(reg5));
  FDRE reg3_reg
       (.C(userclk2),
        .CE(clk_en),
        .D(reg2_reg_n_0),
        .Q(clk1_25),
        .R(reg5));
  FDRE reg4_reg
       (.C(userclk2),
        .CE(clk_en),
        .D(clk1_25),
        .Q(reg4),
        .R(reg5));
  LUT4 #(
    .INIT(16'hFF40)) 
    reg5_i_1__0
       (.I0(reg4),
        .I1(clk_en),
        .I2(reg5_reg_n_0),
        .I3(reset_out),
        .O(reg5));
  FDRE reg5_reg
       (.C(userclk2),
        .CE(clk_en),
        .D(reg4),
        .Q(reg5_reg_n_0),
        .R(reg5));
  (* SOFT_HLUTNM = "soft_lutpair71" *) 
  LUT4 #(
    .INIT(16'hA808)) 
    sgmii_clk_r_i_1
       (.I0(sgmii_clk_r_reg),
        .I1(clk1_25),
        .I2(data_out),
        .I3(clk12_5),
        .O(sgmii_clk_r0_out));
endmodule

module gmii_to_sgmii_bridge_reset_sync
   (reset_out,
    rxuserclk2,
    enablealign);
  output reset_out;
  input rxuserclk2;
  input enablealign;

  wire enablealign;
  wire reset_out;
  wire reset_sync_reg1;
  wire reset_sync_reg2;
  wire reset_sync_reg3;
  wire reset_sync_reg4;
  wire reset_sync_reg5;
  wire rxuserclk2;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync1
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(1'b0),
        .PRE(enablealign),
        .Q(reset_sync_reg1));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync2
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(reset_sync_reg1),
        .PRE(enablealign),
        .Q(reset_sync_reg2));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync3
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(reset_sync_reg2),
        .PRE(enablealign),
        .Q(reset_sync_reg3));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync4
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(reset_sync_reg3),
        .PRE(enablealign),
        .Q(reset_sync_reg4));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync5
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(reset_sync_reg4),
        .PRE(enablealign),
        .Q(reset_sync_reg5));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync6
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(reset_sync_reg5),
        .PRE(1'b0),
        .Q(reset_out));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_reset_sync" *) 
module gmii_to_sgmii_bridge_reset_sync_1
   (SR,
    reset_out,
    reset_sync6_0,
    reset_sync6_1,
    start,
    initialize_ram_complete,
    initialize_ram_complete_pulse,
    rxuserclk2,
    mgt_rx_reset);
  output [0:0]SR;
  output reset_out;
  output [0:0]reset_sync6_0;
  output [0:0]reset_sync6_1;
  input start;
  input initialize_ram_complete;
  input initialize_ram_complete_pulse;
  input rxuserclk2;
  input mgt_rx_reset;

  wire [0:0]SR;
  wire initialize_ram_complete;
  wire initialize_ram_complete_pulse;
  wire mgt_rx_reset;
  wire reset_out;
  wire [0:0]reset_sync6_0;
  wire [0:0]reset_sync6_1;
  wire reset_sync_reg1;
  wire reset_sync_reg2;
  wire reset_sync_reg3;
  wire reset_sync_reg4;
  wire reset_sync_reg5;
  wire rxuserclk2;
  wire start;

  (* SOFT_HLUTNM = "soft_lutpair107" *) 
  LUT2 #(
    .INIT(4'hE)) 
    initialize_ram_complete_i_1
       (.I0(reset_out),
        .I1(start),
        .O(SR));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync1
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(1'b0),
        .PRE(mgt_rx_reset),
        .Q(reset_sync_reg1));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync2
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(reset_sync_reg1),
        .PRE(mgt_rx_reset),
        .Q(reset_sync_reg2));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync3
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(reset_sync_reg2),
        .PRE(mgt_rx_reset),
        .Q(reset_sync_reg3));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync4
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(reset_sync_reg3),
        .PRE(mgt_rx_reset),
        .Q(reset_sync_reg4));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync5
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(reset_sync_reg4),
        .PRE(mgt_rx_reset),
        .Q(reset_sync_reg5));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync6
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(reset_sync_reg5),
        .PRE(1'b0),
        .Q(reset_out));
  LUT2 #(
    .INIT(4'hE)) 
    \wr_addr[4]_i_1 
       (.I0(reset_out),
        .I1(initialize_ram_complete_pulse),
        .O(reset_sync6_1));
  (* SOFT_HLUTNM = "soft_lutpair107" *) 
  LUT2 #(
    .INIT(4'hB)) 
    \wr_data_reg[28]_i_1 
       (.I0(reset_out),
        .I1(initialize_ram_complete),
        .O(reset_sync6_0));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_reset_sync" *) 
module gmii_to_sgmii_bridge_reset_sync_2
   (reset_out,
    independent_clock_bufg,
    mgt_rx_reset);
  output reset_out;
  input independent_clock_bufg;
  input mgt_rx_reset;

  wire independent_clock_bufg;
  wire mgt_rx_reset;
  wire reset_out;
  wire reset_sync_reg1;
  wire reset_sync_reg2;
  wire reset_sync_reg3;
  wire reset_sync_reg4;
  wire reset_sync_reg5;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync1
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(1'b0),
        .PRE(mgt_rx_reset),
        .Q(reset_sync_reg1));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync2
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(reset_sync_reg1),
        .PRE(mgt_rx_reset),
        .Q(reset_sync_reg2));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync3
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(reset_sync_reg2),
        .PRE(mgt_rx_reset),
        .Q(reset_sync_reg3));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync4
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(reset_sync_reg3),
        .PRE(mgt_rx_reset),
        .Q(reset_sync_reg4));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync5
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(reset_sync_reg4),
        .PRE(mgt_rx_reset),
        .Q(reset_sync_reg5));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync6
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(reset_sync_reg5),
        .PRE(1'b0),
        .Q(reset_out));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_reset_sync" *) 
module gmii_to_sgmii_bridge_reset_sync_3
   (reset_out,
    userclk,
    SR);
  output reset_out;
  input userclk;
  input [0:0]SR;

  wire [0:0]SR;
  wire reset_out;
  wire reset_sync_reg1;
  wire reset_sync_reg2;
  wire reset_sync_reg3;
  wire reset_sync_reg4;
  wire reset_sync_reg5;
  wire userclk;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync1
       (.C(userclk),
        .CE(1'b1),
        .D(1'b0),
        .PRE(SR),
        .Q(reset_sync_reg1));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync2
       (.C(userclk),
        .CE(1'b1),
        .D(reset_sync_reg1),
        .PRE(SR),
        .Q(reset_sync_reg2));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync3
       (.C(userclk),
        .CE(1'b1),
        .D(reset_sync_reg2),
        .PRE(SR),
        .Q(reset_sync_reg3));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync4
       (.C(userclk),
        .CE(1'b1),
        .D(reset_sync_reg3),
        .PRE(SR),
        .Q(reset_sync_reg4));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync5
       (.C(userclk),
        .CE(1'b1),
        .D(reset_sync_reg4),
        .PRE(SR),
        .Q(reset_sync_reg5));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync6
       (.C(userclk),
        .CE(1'b1),
        .D(reset_sync_reg5),
        .PRE(1'b0),
        .Q(reset_out));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_reset_sync" *) 
module gmii_to_sgmii_bridge_reset_sync_30
   (reset_out,
    userclk2,
    SR);
  output reset_out;
  input userclk2;
  input [0:0]SR;

  wire [0:0]SR;
  wire reset_out;
  wire reset_sync_reg1;
  wire reset_sync_reg2;
  wire reset_sync_reg3;
  wire reset_sync_reg4;
  wire reset_sync_reg5;
  wire userclk2;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync1
       (.C(userclk2),
        .CE(1'b1),
        .D(1'b0),
        .PRE(SR),
        .Q(reset_sync_reg1));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync2
       (.C(userclk2),
        .CE(1'b1),
        .D(reset_sync_reg1),
        .PRE(SR),
        .Q(reset_sync_reg2));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync3
       (.C(userclk2),
        .CE(1'b1),
        .D(reset_sync_reg2),
        .PRE(SR),
        .Q(reset_sync_reg3));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync4
       (.C(userclk2),
        .CE(1'b1),
        .D(reset_sync_reg3),
        .PRE(SR),
        .Q(reset_sync_reg4));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync5
       (.C(userclk2),
        .CE(1'b1),
        .D(reset_sync_reg4),
        .PRE(SR),
        .Q(reset_sync_reg5));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FDP" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  (* box_type = "PRIMITIVE" *) 
  FDPE #(
    .INIT(1'b1)) 
    reset_sync6
       (.C(userclk2),
        .CE(1'b1),
        .D(reset_sync_reg5),
        .PRE(1'b0),
        .Q(reset_out));
endmodule

module gmii_to_sgmii_bridge_reset_wtd_timer
   (reset,
    independent_clock_bufg,
    data_out);
  output reset;
  input independent_clock_bufg;
  input data_out;

  wire \counter_stg1[5]_i_1_n_0 ;
  wire \counter_stg1[5]_i_3_n_0 ;
  wire [5:5]counter_stg1_reg;
  wire [4:0]counter_stg1_reg__0;
  wire \counter_stg2[0]_i_3_n_0 ;
  wire [11:0]counter_stg2_reg;
  wire \counter_stg2_reg[0]_i_2_n_0 ;
  wire \counter_stg2_reg[0]_i_2_n_1 ;
  wire \counter_stg2_reg[0]_i_2_n_2 ;
  wire \counter_stg2_reg[0]_i_2_n_3 ;
  wire \counter_stg2_reg[0]_i_2_n_4 ;
  wire \counter_stg2_reg[0]_i_2_n_5 ;
  wire \counter_stg2_reg[0]_i_2_n_6 ;
  wire \counter_stg2_reg[0]_i_2_n_7 ;
  wire \counter_stg2_reg[4]_i_1_n_0 ;
  wire \counter_stg2_reg[4]_i_1_n_1 ;
  wire \counter_stg2_reg[4]_i_1_n_2 ;
  wire \counter_stg2_reg[4]_i_1_n_3 ;
  wire \counter_stg2_reg[4]_i_1_n_4 ;
  wire \counter_stg2_reg[4]_i_1_n_5 ;
  wire \counter_stg2_reg[4]_i_1_n_6 ;
  wire \counter_stg2_reg[4]_i_1_n_7 ;
  wire \counter_stg2_reg[8]_i_1_n_1 ;
  wire \counter_stg2_reg[8]_i_1_n_2 ;
  wire \counter_stg2_reg[8]_i_1_n_3 ;
  wire \counter_stg2_reg[8]_i_1_n_4 ;
  wire \counter_stg2_reg[8]_i_1_n_5 ;
  wire \counter_stg2_reg[8]_i_1_n_6 ;
  wire \counter_stg2_reg[8]_i_1_n_7 ;
  wire counter_stg30;
  wire \counter_stg3[0]_i_3_n_0 ;
  wire \counter_stg3[0]_i_4_n_0 ;
  wire \counter_stg3[0]_i_5_n_0 ;
  wire [11:0]counter_stg3_reg;
  wire \counter_stg3_reg[0]_i_2_n_0 ;
  wire \counter_stg3_reg[0]_i_2_n_1 ;
  wire \counter_stg3_reg[0]_i_2_n_2 ;
  wire \counter_stg3_reg[0]_i_2_n_3 ;
  wire \counter_stg3_reg[0]_i_2_n_4 ;
  wire \counter_stg3_reg[0]_i_2_n_5 ;
  wire \counter_stg3_reg[0]_i_2_n_6 ;
  wire \counter_stg3_reg[0]_i_2_n_7 ;
  wire \counter_stg3_reg[4]_i_1_n_0 ;
  wire \counter_stg3_reg[4]_i_1_n_1 ;
  wire \counter_stg3_reg[4]_i_1_n_2 ;
  wire \counter_stg3_reg[4]_i_1_n_3 ;
  wire \counter_stg3_reg[4]_i_1_n_4 ;
  wire \counter_stg3_reg[4]_i_1_n_5 ;
  wire \counter_stg3_reg[4]_i_1_n_6 ;
  wire \counter_stg3_reg[4]_i_1_n_7 ;
  wire \counter_stg3_reg[8]_i_1_n_1 ;
  wire \counter_stg3_reg[8]_i_1_n_2 ;
  wire \counter_stg3_reg[8]_i_1_n_3 ;
  wire \counter_stg3_reg[8]_i_1_n_4 ;
  wire \counter_stg3_reg[8]_i_1_n_5 ;
  wire \counter_stg3_reg[8]_i_1_n_6 ;
  wire \counter_stg3_reg[8]_i_1_n_7 ;
  wire data_out;
  wire eqOp;
  wire independent_clock_bufg;
  wire [5:0]plusOp__0;
  wire reset;
  wire reset0;
  wire reset_i_2_n_0;
  wire reset_i_3_n_0;
  wire reset_i_4_n_0;
  wire reset_i_5_n_0;
  wire reset_i_6_n_0;
  wire [3:3]\NLW_counter_stg2_reg[8]_i_1_CO_UNCONNECTED ;
  wire [3:3]\NLW_counter_stg3_reg[8]_i_1_CO_UNCONNECTED ;

  (* SOFT_HLUTNM = "soft_lutpair110" *) 
  LUT1 #(
    .INIT(2'h1)) 
    \counter_stg1[0]_i_1 
       (.I0(counter_stg1_reg__0[0]),
        .O(plusOp__0[0]));
  (* SOFT_HLUTNM = "soft_lutpair110" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \counter_stg1[1]_i_1 
       (.I0(counter_stg1_reg__0[0]),
        .I1(counter_stg1_reg__0[1]),
        .O(plusOp__0[1]));
  (* SOFT_HLUTNM = "soft_lutpair109" *) 
  LUT3 #(
    .INIT(8'h78)) 
    \counter_stg1[2]_i_1 
       (.I0(counter_stg1_reg__0[1]),
        .I1(counter_stg1_reg__0[0]),
        .I2(counter_stg1_reg__0[2]),
        .O(plusOp__0[2]));
  (* SOFT_HLUTNM = "soft_lutpair109" *) 
  LUT4 #(
    .INIT(16'h7F80)) 
    \counter_stg1[3]_i_1 
       (.I0(counter_stg1_reg__0[2]),
        .I1(counter_stg1_reg__0[0]),
        .I2(counter_stg1_reg__0[1]),
        .I3(counter_stg1_reg__0[3]),
        .O(plusOp__0[3]));
  (* SOFT_HLUTNM = "soft_lutpair108" *) 
  LUT5 #(
    .INIT(32'h7FFF8000)) 
    \counter_stg1[4]_i_1 
       (.I0(counter_stg1_reg__0[3]),
        .I1(counter_stg1_reg__0[1]),
        .I2(counter_stg1_reg__0[0]),
        .I3(counter_stg1_reg__0[2]),
        .I4(counter_stg1_reg__0[4]),
        .O(plusOp__0[4]));
  LUT5 #(
    .INIT(32'hFFFF2000)) 
    \counter_stg1[5]_i_1 
       (.I0(reset_i_2_n_0),
        .I1(counter_stg3_reg[0]),
        .I2(reset_i_3_n_0),
        .I3(\counter_stg1[5]_i_3_n_0 ),
        .I4(data_out),
        .O(\counter_stg1[5]_i_1_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFF80000000)) 
    \counter_stg1[5]_i_2 
       (.I0(counter_stg1_reg__0[4]),
        .I1(counter_stg1_reg__0[2]),
        .I2(counter_stg1_reg__0[0]),
        .I3(counter_stg1_reg__0[1]),
        .I4(counter_stg1_reg__0[3]),
        .I5(counter_stg1_reg),
        .O(plusOp__0[5]));
  (* SOFT_HLUTNM = "soft_lutpair108" *) 
  LUT5 #(
    .INIT(32'h80000000)) 
    \counter_stg1[5]_i_3 
       (.I0(counter_stg1_reg__0[3]),
        .I1(counter_stg1_reg__0[1]),
        .I2(counter_stg1_reg__0[0]),
        .I3(counter_stg1_reg__0[2]),
        .I4(counter_stg1_reg__0[4]),
        .O(\counter_stg1[5]_i_3_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg1_reg[0] 
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(plusOp__0[0]),
        .Q(counter_stg1_reg__0[0]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg1_reg[1] 
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(plusOp__0[1]),
        .Q(counter_stg1_reg__0[1]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg1_reg[2] 
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(plusOp__0[2]),
        .Q(counter_stg1_reg__0[2]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg1_reg[3] 
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(plusOp__0[3]),
        .Q(counter_stg1_reg__0[3]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg1_reg[4] 
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(plusOp__0[4]),
        .Q(counter_stg1_reg__0[4]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg1_reg[5] 
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(plusOp__0[5]),
        .Q(counter_stg1_reg),
        .R(\counter_stg1[5]_i_1_n_0 ));
  LUT6 #(
    .INIT(64'h8000000000000000)) 
    \counter_stg2[0]_i_1 
       (.I0(counter_stg1_reg__0[4]),
        .I1(counter_stg1_reg__0[2]),
        .I2(counter_stg1_reg__0[0]),
        .I3(counter_stg1_reg__0[1]),
        .I4(counter_stg1_reg__0[3]),
        .I5(counter_stg1_reg),
        .O(eqOp));
  LUT1 #(
    .INIT(2'h1)) 
    \counter_stg2[0]_i_3 
       (.I0(counter_stg2_reg[0]),
        .O(\counter_stg2[0]_i_3_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg2_reg[0] 
       (.C(independent_clock_bufg),
        .CE(eqOp),
        .D(\counter_stg2_reg[0]_i_2_n_7 ),
        .Q(counter_stg2_reg[0]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \counter_stg2_reg[0]_i_2 
       (.CI(1'b0),
        .CO({\counter_stg2_reg[0]_i_2_n_0 ,\counter_stg2_reg[0]_i_2_n_1 ,\counter_stg2_reg[0]_i_2_n_2 ,\counter_stg2_reg[0]_i_2_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b1}),
        .O({\counter_stg2_reg[0]_i_2_n_4 ,\counter_stg2_reg[0]_i_2_n_5 ,\counter_stg2_reg[0]_i_2_n_6 ,\counter_stg2_reg[0]_i_2_n_7 }),
        .S({counter_stg2_reg[3:1],\counter_stg2[0]_i_3_n_0 }));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg2_reg[10] 
       (.C(independent_clock_bufg),
        .CE(eqOp),
        .D(\counter_stg2_reg[8]_i_1_n_5 ),
        .Q(counter_stg2_reg[10]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg2_reg[11] 
       (.C(independent_clock_bufg),
        .CE(eqOp),
        .D(\counter_stg2_reg[8]_i_1_n_4 ),
        .Q(counter_stg2_reg[11]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg2_reg[1] 
       (.C(independent_clock_bufg),
        .CE(eqOp),
        .D(\counter_stg2_reg[0]_i_2_n_6 ),
        .Q(counter_stg2_reg[1]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg2_reg[2] 
       (.C(independent_clock_bufg),
        .CE(eqOp),
        .D(\counter_stg2_reg[0]_i_2_n_5 ),
        .Q(counter_stg2_reg[2]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg2_reg[3] 
       (.C(independent_clock_bufg),
        .CE(eqOp),
        .D(\counter_stg2_reg[0]_i_2_n_4 ),
        .Q(counter_stg2_reg[3]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg2_reg[4] 
       (.C(independent_clock_bufg),
        .CE(eqOp),
        .D(\counter_stg2_reg[4]_i_1_n_7 ),
        .Q(counter_stg2_reg[4]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \counter_stg2_reg[4]_i_1 
       (.CI(\counter_stg2_reg[0]_i_2_n_0 ),
        .CO({\counter_stg2_reg[4]_i_1_n_0 ,\counter_stg2_reg[4]_i_1_n_1 ,\counter_stg2_reg[4]_i_1_n_2 ,\counter_stg2_reg[4]_i_1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\counter_stg2_reg[4]_i_1_n_4 ,\counter_stg2_reg[4]_i_1_n_5 ,\counter_stg2_reg[4]_i_1_n_6 ,\counter_stg2_reg[4]_i_1_n_7 }),
        .S(counter_stg2_reg[7:4]));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg2_reg[5] 
       (.C(independent_clock_bufg),
        .CE(eqOp),
        .D(\counter_stg2_reg[4]_i_1_n_6 ),
        .Q(counter_stg2_reg[5]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg2_reg[6] 
       (.C(independent_clock_bufg),
        .CE(eqOp),
        .D(\counter_stg2_reg[4]_i_1_n_5 ),
        .Q(counter_stg2_reg[6]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg2_reg[7] 
       (.C(independent_clock_bufg),
        .CE(eqOp),
        .D(\counter_stg2_reg[4]_i_1_n_4 ),
        .Q(counter_stg2_reg[7]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg2_reg[8] 
       (.C(independent_clock_bufg),
        .CE(eqOp),
        .D(\counter_stg2_reg[8]_i_1_n_7 ),
        .Q(counter_stg2_reg[8]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \counter_stg2_reg[8]_i_1 
       (.CI(\counter_stg2_reg[4]_i_1_n_0 ),
        .CO({\NLW_counter_stg2_reg[8]_i_1_CO_UNCONNECTED [3],\counter_stg2_reg[8]_i_1_n_1 ,\counter_stg2_reg[8]_i_1_n_2 ,\counter_stg2_reg[8]_i_1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\counter_stg2_reg[8]_i_1_n_4 ,\counter_stg2_reg[8]_i_1_n_5 ,\counter_stg2_reg[8]_i_1_n_6 ,\counter_stg2_reg[8]_i_1_n_7 }),
        .S(counter_stg2_reg[11:8]));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg2_reg[9] 
       (.C(independent_clock_bufg),
        .CE(eqOp),
        .D(\counter_stg2_reg[8]_i_1_n_6 ),
        .Q(counter_stg2_reg[9]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  LUT4 #(
    .INIT(16'h8000)) 
    \counter_stg3[0]_i_1 
       (.I0(\counter_stg3[0]_i_3_n_0 ),
        .I1(\counter_stg3[0]_i_4_n_0 ),
        .I2(counter_stg2_reg[0]),
        .I3(\counter_stg1[5]_i_3_n_0 ),
        .O(counter_stg30));
  LUT6 #(
    .INIT(64'h8000000000000000)) 
    \counter_stg3[0]_i_3 
       (.I0(counter_stg2_reg[3]),
        .I1(counter_stg2_reg[4]),
        .I2(counter_stg2_reg[1]),
        .I3(counter_stg2_reg[2]),
        .I4(counter_stg2_reg[6]),
        .I5(counter_stg2_reg[5]),
        .O(\counter_stg3[0]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'h8000000000000000)) 
    \counter_stg3[0]_i_4 
       (.I0(counter_stg2_reg[9]),
        .I1(counter_stg2_reg[10]),
        .I2(counter_stg2_reg[7]),
        .I3(counter_stg2_reg[8]),
        .I4(counter_stg1_reg),
        .I5(counter_stg2_reg[11]),
        .O(\counter_stg3[0]_i_4_n_0 ));
  LUT1 #(
    .INIT(2'h1)) 
    \counter_stg3[0]_i_5 
       (.I0(counter_stg3_reg[0]),
        .O(\counter_stg3[0]_i_5_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg3_reg[0] 
       (.C(independent_clock_bufg),
        .CE(counter_stg30),
        .D(\counter_stg3_reg[0]_i_2_n_7 ),
        .Q(counter_stg3_reg[0]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \counter_stg3_reg[0]_i_2 
       (.CI(1'b0),
        .CO({\counter_stg3_reg[0]_i_2_n_0 ,\counter_stg3_reg[0]_i_2_n_1 ,\counter_stg3_reg[0]_i_2_n_2 ,\counter_stg3_reg[0]_i_2_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b1}),
        .O({\counter_stg3_reg[0]_i_2_n_4 ,\counter_stg3_reg[0]_i_2_n_5 ,\counter_stg3_reg[0]_i_2_n_6 ,\counter_stg3_reg[0]_i_2_n_7 }),
        .S({counter_stg3_reg[3:1],\counter_stg3[0]_i_5_n_0 }));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg3_reg[10] 
       (.C(independent_clock_bufg),
        .CE(counter_stg30),
        .D(\counter_stg3_reg[8]_i_1_n_5 ),
        .Q(counter_stg3_reg[10]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg3_reg[11] 
       (.C(independent_clock_bufg),
        .CE(counter_stg30),
        .D(\counter_stg3_reg[8]_i_1_n_4 ),
        .Q(counter_stg3_reg[11]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg3_reg[1] 
       (.C(independent_clock_bufg),
        .CE(counter_stg30),
        .D(\counter_stg3_reg[0]_i_2_n_6 ),
        .Q(counter_stg3_reg[1]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg3_reg[2] 
       (.C(independent_clock_bufg),
        .CE(counter_stg30),
        .D(\counter_stg3_reg[0]_i_2_n_5 ),
        .Q(counter_stg3_reg[2]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg3_reg[3] 
       (.C(independent_clock_bufg),
        .CE(counter_stg30),
        .D(\counter_stg3_reg[0]_i_2_n_4 ),
        .Q(counter_stg3_reg[3]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg3_reg[4] 
       (.C(independent_clock_bufg),
        .CE(counter_stg30),
        .D(\counter_stg3_reg[4]_i_1_n_7 ),
        .Q(counter_stg3_reg[4]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \counter_stg3_reg[4]_i_1 
       (.CI(\counter_stg3_reg[0]_i_2_n_0 ),
        .CO({\counter_stg3_reg[4]_i_1_n_0 ,\counter_stg3_reg[4]_i_1_n_1 ,\counter_stg3_reg[4]_i_1_n_2 ,\counter_stg3_reg[4]_i_1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\counter_stg3_reg[4]_i_1_n_4 ,\counter_stg3_reg[4]_i_1_n_5 ,\counter_stg3_reg[4]_i_1_n_6 ,\counter_stg3_reg[4]_i_1_n_7 }),
        .S(counter_stg3_reg[7:4]));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg3_reg[5] 
       (.C(independent_clock_bufg),
        .CE(counter_stg30),
        .D(\counter_stg3_reg[4]_i_1_n_6 ),
        .Q(counter_stg3_reg[5]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg3_reg[6] 
       (.C(independent_clock_bufg),
        .CE(counter_stg30),
        .D(\counter_stg3_reg[4]_i_1_n_5 ),
        .Q(counter_stg3_reg[6]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg3_reg[7] 
       (.C(independent_clock_bufg),
        .CE(counter_stg30),
        .D(\counter_stg3_reg[4]_i_1_n_4 ),
        .Q(counter_stg3_reg[7]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg3_reg[8] 
       (.C(independent_clock_bufg),
        .CE(counter_stg30),
        .D(\counter_stg3_reg[8]_i_1_n_7 ),
        .Q(counter_stg3_reg[8]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  (* ADDER_THRESHOLD = "11" *) 
  CARRY4 \counter_stg3_reg[8]_i_1 
       (.CI(\counter_stg3_reg[4]_i_1_n_0 ),
        .CO({\NLW_counter_stg3_reg[8]_i_1_CO_UNCONNECTED [3],\counter_stg3_reg[8]_i_1_n_1 ,\counter_stg3_reg[8]_i_1_n_2 ,\counter_stg3_reg[8]_i_1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\counter_stg3_reg[8]_i_1_n_4 ,\counter_stg3_reg[8]_i_1_n_5 ,\counter_stg3_reg[8]_i_1_n_6 ,\counter_stg3_reg[8]_i_1_n_7 }),
        .S(counter_stg3_reg[11:8]));
  FDRE #(
    .INIT(1'b0)) 
    \counter_stg3_reg[9] 
       (.C(independent_clock_bufg),
        .CE(counter_stg30),
        .D(\counter_stg3_reg[8]_i_1_n_6 ),
        .Q(counter_stg3_reg[9]),
        .R(\counter_stg1[5]_i_1_n_0 ));
  LUT3 #(
    .INIT(8'h20)) 
    reset_i_1
       (.I0(reset_i_2_n_0),
        .I1(counter_stg3_reg[0]),
        .I2(reset_i_3_n_0),
        .O(reset0));
  LUT6 #(
    .INIT(64'h0000001000000000)) 
    reset_i_2
       (.I0(counter_stg3_reg[9]),
        .I1(counter_stg3_reg[10]),
        .I2(counter_stg3_reg[7]),
        .I3(counter_stg3_reg[8]),
        .I4(counter_stg2_reg[0]),
        .I5(counter_stg3_reg[11]),
        .O(reset_i_2_n_0));
  LUT3 #(
    .INIT(8'h80)) 
    reset_i_3
       (.I0(reset_i_4_n_0),
        .I1(reset_i_5_n_0),
        .I2(reset_i_6_n_0),
        .O(reset_i_3_n_0));
  LUT6 #(
    .INIT(64'h0000000000000008)) 
    reset_i_4
       (.I0(counter_stg2_reg[3]),
        .I1(counter_stg2_reg[4]),
        .I2(counter_stg2_reg[1]),
        .I3(counter_stg2_reg[2]),
        .I4(counter_stg2_reg[6]),
        .I5(counter_stg2_reg[5]),
        .O(reset_i_4_n_0));
  LUT6 #(
    .INIT(64'h0020000000000000)) 
    reset_i_5
       (.I0(counter_stg2_reg[10]),
        .I1(counter_stg2_reg[9]),
        .I2(counter_stg2_reg[8]),
        .I3(counter_stg2_reg[7]),
        .I4(counter_stg1_reg),
        .I5(counter_stg2_reg[11]),
        .O(reset_i_5_n_0));
  LUT6 #(
    .INIT(64'h0002000000000000)) 
    reset_i_6
       (.I0(counter_stg3_reg[4]),
        .I1(counter_stg3_reg[3]),
        .I2(counter_stg3_reg[1]),
        .I3(counter_stg3_reg[2]),
        .I4(counter_stg3_reg[6]),
        .I5(counter_stg3_reg[5]),
        .O(reset_i_6_n_0));
  FDRE reset_reg
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(reset0),
        .Q(reset),
        .R(1'b0));
endmodule

module gmii_to_sgmii_bridge_rx_elastic_buffer
   (start,
    initialize_ram_complete,
    initialize_ram_complete_pulse,
    rxchariscomma,
    rxcharisk,
    rxdisperr,
    rxnotintable,
    rxclkcorcnt,
    rxbufstatus,
    Q,
    userclk2,
    rxuserclk2,
    reset_out,
    SR,
    \wr_addr_plus1_reg[0]_0 ,
    \wr_data_reg_reg[0]_0 ,
    D,
    mgt_rx_reset);
  output start;
  output initialize_ram_complete;
  output initialize_ram_complete_pulse;
  output [0:0]rxchariscomma;
  output [0:0]rxcharisk;
  output [0:0]rxdisperr;
  output [0:0]rxnotintable;
  output [1:0]rxclkcorcnt;
  output [0:0]rxbufstatus;
  output [7:0]Q;
  input userclk2;
  input rxuserclk2;
  input reset_out;
  input [0:0]SR;
  input [0:0]\wr_addr_plus1_reg[0]_0 ;
  input [0:0]\wr_data_reg_reg[0]_0 ;
  input [23:0]D;
  input mgt_rx_reset;

  wire [23:0]D;
  wire [7:0]Q;
  wire [0:0]SR;
  wire [4:1]bin_to_gray;
  wire d16p2_wr_reg;
  wire d16p2_wr_reg_i_2_n_0;
  wire d21p5_wr_reg;
  wire d21p5_wr_reg2;
  wire d21p5_wr_reg_i_2_n_0;
  wire d2p2_wr_reg;
  wire d2p2_wr_reg2;
  wire d2p2_wr_reg_i_2_n_0;
  wire data_in;
  wire data_out;
  wire [28:0]dpo;
  wire even;
  wire even_i_1_n_0;
  wire [4:0]gray_to_bin;
  wire initialize_counter0;
  wire [4:0]initialize_counter_reg;
  wire initialize_ram;
  wire initialize_ram_complete;
  wire initialize_ram_complete_i_2_n_0;
  wire initialize_ram_complete_pulse;
  wire initialize_ram_complete_pulse0;
  wire initialize_ram_complete_reg__0;
  wire initialize_ram_complete_sync;
  wire initialize_ram_complete_sync_reg1;
  wire initialize_ram_complete_sync_ris_edg;
  wire initialize_ram_complete_sync_ris_edg0;
  wire initialize_ram_i_1_n_0;
  wire insert_idle;
  wire insert_idle_i_1_n_0;
  wire insert_idle_reg__0;
  wire k28p5_wr_reg;
  wire k28p5_wr_reg2;
  wire k28p5_wr_reg_i_2_n_0;
  wire mgt_rx_reset;
  wire p_10_in;
  wire p_13_in;
  wire p_14_in;
  wire p_17_in;
  wire p_18_in;
  wire p_1_in;
  wire p_1_in15_in;
  wire p_1_in30_in;
  wire p_1_in4_in;
  wire p_25_in;
  wire p_2_in;
  wire p_2_in18_in;
  wire p_2_in33_in;
  wire p_2_in6_in;
  wire p_3_in;
  wire p_3_in21_in;
  wire p_3_in36_in;
  wire p_3_in8_in;
  wire p_4_in;
  wire p_4_in10_in;
  wire p_4_in_0;
  wire [4:0]plusOp;
  wire [5:0]plusOp__1;
  wire [4:0]plusOp__2;
  wire [5:0]rd_addr;
  wire [5:0]rd_addr_gray;
  wire \rd_addr_gray[0]_i_1_n_0 ;
  wire \rd_addr_gray[1]_i_1_n_0 ;
  wire \rd_addr_gray[2]_i_1_n_0 ;
  wire \rd_addr_gray[3]_i_1_n_0 ;
  wire \rd_addr_gray[4]_i_1_n_0 ;
  wire [5:0]rd_addr_plus1;
  wire \rd_addr_plus2_reg_n_0_[0] ;
  wire \rd_addr_plus2_reg_n_0_[5] ;
  wire [27:0]rd_data;
  wire [28:0]rd_data_reg;
  wire \rd_data_reg_n_0_[28] ;
  wire rd_enable;
  wire rd_enable_i_10_n_0;
  wire rd_enable_i_11_n_0;
  wire rd_enable_i_12_n_0;
  wire rd_enable_i_1_n_0;
  wire rd_enable_i_2_n_0;
  wire rd_enable_i_4_n_0;
  wire rd_enable_i_5_n_0;
  wire rd_enable_i_6_n_0;
  wire rd_enable_i_7_n_0;
  wire rd_enable_i_8_n_0;
  wire rd_enable_i_9_n_0;
  wire [5:0]rd_occupancy;
  wire [5:0]rd_occupancy01_out;
  wire rd_occupancy0_carry__0_n_3;
  wire rd_occupancy0_carry_n_0;
  wire rd_occupancy0_carry_n_1;
  wire rd_occupancy0_carry_n_2;
  wire rd_occupancy0_carry_n_3;
  wire \reclock_rd_addrgray[0].sync_rd_addrgray_n_0 ;
  wire \reclock_rd_addrgray[1].sync_rd_addrgray_n_0 ;
  wire \reclock_rd_addrgray[2].sync_rd_addrgray_n_0 ;
  wire \reclock_rd_addrgray[3].sync_rd_addrgray_n_0 ;
  wire \reclock_rd_addrgray[4].sync_rd_addrgray_n_0 ;
  wire \reclock_rd_addrgray[4].sync_rd_addrgray_n_1 ;
  wire \reclock_rd_addrgray[5].sync_rd_addrgray_n_0 ;
  wire \reclock_rd_addrgray[5].sync_rd_addrgray_n_1 ;
  wire \reclock_wr_addrgray[0].sync_wr_addrgray_n_0 ;
  wire \reclock_wr_addrgray[1].sync_wr_addrgray_n_0 ;
  wire \reclock_wr_addrgray[2].sync_wr_addrgray_n_0 ;
  wire \reclock_wr_addrgray[3].sync_wr_addrgray_n_0 ;
  wire \reclock_wr_addrgray[4].sync_wr_addrgray_n_0 ;
  wire \reclock_wr_addrgray[4].sync_wr_addrgray_n_1 ;
  wire \reclock_wr_addrgray[5].sync_wr_addrgray_n_0 ;
  wire \reclock_wr_addrgray[5].sync_wr_addrgray_n_1 ;
  wire remove_idle;
  wire remove_idle_i_1_n_0;
  wire remove_idle_i_2_n_0;
  wire remove_idle_i_3_n_0;
  wire remove_idle_i_4_n_0;
  wire remove_idle_i_5_n_0;
  wire remove_idle_reg1;
  wire remove_idle_reg2;
  wire reset_modified;
  wire reset_modified_i_1_n_0;
  wire reset_out;
  wire rxbuferr0;
  wire rxbuferr_i_1_n_0;
  wire [0:0]rxbufstatus;
  wire [0:0]rxchariscomma;
  wire rxchariscomma_usr_i_1_n_0;
  wire [0:0]rxcharisk;
  wire rxcharisk_usr_i_1_n_0;
  wire [1:0]rxclkcorcnt;
  wire \rxclkcorcnt[0]_i_1_n_0 ;
  wire \rxclkcorcnt[2]_i_1_n_0 ;
  wire \rxdata_usr[0]_i_1_n_0 ;
  wire \rxdata_usr[1]_i_1_n_0 ;
  wire \rxdata_usr[2]_i_1_n_0 ;
  wire \rxdata_usr[3]_i_1_n_0 ;
  wire \rxdata_usr[4]_i_1_n_0 ;
  wire \rxdata_usr[5]_i_1_n_0 ;
  wire \rxdata_usr[6]_i_1_n_0 ;
  wire \rxdata_usr[7]_i_1_n_0 ;
  wire [0:0]rxdisperr;
  wire rxdisperr_usr_i_1_n_0;
  wire [0:0]rxnotintable;
  wire rxnotintable_usr_i_1_n_0;
  wire rxuserclk2;
  wire start;
  wire userclk2;
  wire [5:0]wr_addr;
  wire \wr_addr[5]_i_1_n_0 ;
  wire \wr_addr_gray_reg_n_0_[0] ;
  wire \wr_addr_gray_reg_n_0_[1] ;
  wire \wr_addr_gray_reg_n_0_[2] ;
  wire \wr_addr_gray_reg_n_0_[3] ;
  wire \wr_addr_gray_reg_n_0_[4] ;
  wire [5:0]wr_addr_plus1;
  wire \wr_addr_plus1[5]_i_1_n_0 ;
  wire [0:0]\wr_addr_plus1_reg[0]_0 ;
  wire \wr_addr_plus2[5]_i_1_n_0 ;
  wire \wr_addr_plus2[5]_i_2_n_0 ;
  wire \wr_addr_plus2_reg_n_0_[0] ;
  wire \wr_addr_plus2_reg_n_0_[5] ;
  wire [28:0]wr_data;
  wire [28:0]wr_data_reg;
  wire [0:0]\wr_data_reg_reg[0]_0 ;
  wire wr_enable;
  wire wr_enable_i_1_n_0;
  wire wr_enable_i_2_n_0;
  wire wr_enable_i_3_n_0;
  wire wr_enable_i_4_n_0;
  wire wr_enable_i_5_n_0;
  wire wr_enable_i_6_n_0;
  wire wr_enable_i_7_n_0;
  wire wr_enable_i_8_n_0;
  wire wr_enable_i_9_n_0;
  wire [5:0]wr_occupancy;
  wire [5:0]wr_occupancy00_out;
  wire wr_occupancy0_carry__0_n_3;
  wire wr_occupancy0_carry_n_0;
  wire wr_occupancy0_carry_n_1;
  wire wr_occupancy0_carry_n_2;
  wire wr_occupancy0_carry_n_3;
  wire NLW_ram_reg_0_63_0_2_DOD_UNCONNECTED;
  wire NLW_ram_reg_0_63_12_14_DOC_UNCONNECTED;
  wire NLW_ram_reg_0_63_12_14_DOD_UNCONNECTED;
  wire NLW_ram_reg_0_63_15_17_DOA_UNCONNECTED;
  wire NLW_ram_reg_0_63_15_17_DOD_UNCONNECTED;
  wire NLW_ram_reg_0_63_18_20_DOD_UNCONNECTED;
  wire NLW_ram_reg_0_63_21_23_DOD_UNCONNECTED;
  wire NLW_ram_reg_0_63_24_26_DOA_UNCONNECTED;
  wire NLW_ram_reg_0_63_24_26_DOD_UNCONNECTED;
  wire NLW_ram_reg_0_63_27_29_DOC_UNCONNECTED;
  wire NLW_ram_reg_0_63_27_29_DOD_UNCONNECTED;
  wire NLW_ram_reg_0_63_3_5_DOD_UNCONNECTED;
  wire NLW_ram_reg_0_63_6_8_DOC_UNCONNECTED;
  wire NLW_ram_reg_0_63_6_8_DOD_UNCONNECTED;
  wire NLW_ram_reg_0_63_9_11_DOD_UNCONNECTED;
  wire [3:1]NLW_rd_occupancy0_carry__0_CO_UNCONNECTED;
  wire [3:2]NLW_rd_occupancy0_carry__0_O_UNCONNECTED;
  wire [3:1]NLW_wr_occupancy0_carry__0_CO_UNCONNECTED;
  wire [3:2]NLW_wr_occupancy0_carry__0_O_UNCONNECTED;

  LUT5 #(
    .INIT(32'h96696996)) 
    \/i_ 
       (.I0(p_3_in21_in),
        .I1(p_1_in15_in),
        .I2(p_14_in),
        .I3(\reclock_rd_addrgray[4].sync_rd_addrgray_n_1 ),
        .I4(p_2_in18_in),
        .O(p_25_in));
  (* SOFT_HLUTNM = "soft_lutpair120" *) 
  LUT4 #(
    .INIT(16'h0002)) 
    d16p2_wr_reg_i_1
       (.I0(d16p2_wr_reg_i_2_n_0),
        .I1(wr_data[0]),
        .I2(wr_data[1]),
        .I3(wr_data[2]),
        .O(p_17_in));
  LUT6 #(
    .INIT(64'h0000000000000020)) 
    d16p2_wr_reg_i_2
       (.I0(wr_data[4]),
        .I1(wr_data[3]),
        .I2(wr_data[6]),
        .I3(wr_data[5]),
        .I4(wr_data[11]),
        .I5(wr_data[7]),
        .O(d16p2_wr_reg_i_2_n_0));
  FDRE d16p2_wr_reg_reg
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(p_17_in),
        .Q(d16p2_wr_reg),
        .R(reset_out));
  FDRE d21p5_wr_reg2_reg
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(d21p5_wr_reg),
        .Q(d21p5_wr_reg2),
        .R(reset_out));
  (* SOFT_HLUTNM = "soft_lutpair119" *) 
  LUT4 #(
    .INIT(16'h0080)) 
    d21p5_wr_reg_i_1
       (.I0(d21p5_wr_reg_i_2_n_0),
        .I1(wr_data[0]),
        .I2(wr_data[2]),
        .I3(wr_data[1]),
        .O(p_13_in));
  LUT6 #(
    .INIT(64'h0000002000000000)) 
    d21p5_wr_reg_i_2
       (.I0(wr_data[4]),
        .I1(wr_data[3]),
        .I2(wr_data[5]),
        .I3(wr_data[6]),
        .I4(wr_data[11]),
        .I5(wr_data[7]),
        .O(d21p5_wr_reg_i_2_n_0));
  FDRE d21p5_wr_reg_reg
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(p_13_in),
        .Q(d21p5_wr_reg),
        .R(reset_out));
  FDRE d2p2_wr_reg2_reg
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(d2p2_wr_reg),
        .Q(d2p2_wr_reg2),
        .R(reset_out));
  (* SOFT_HLUTNM = "soft_lutpair120" *) 
  LUT4 #(
    .INIT(16'h0020)) 
    d2p2_wr_reg_i_1
       (.I0(d2p2_wr_reg_i_2_n_0),
        .I1(wr_data[0]),
        .I2(wr_data[1]),
        .I3(wr_data[2]),
        .O(p_10_in));
  LUT6 #(
    .INIT(64'h0000000000000010)) 
    d2p2_wr_reg_i_2
       (.I0(wr_data[3]),
        .I1(wr_data[4]),
        .I2(wr_data[6]),
        .I3(wr_data[5]),
        .I4(wr_data[11]),
        .I5(wr_data[7]),
        .O(d2p2_wr_reg_i_2_n_0));
  FDRE d2p2_wr_reg_reg
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(p_10_in),
        .Q(d2p2_wr_reg),
        .R(reset_out));
  LUT1 #(
    .INIT(2'h1)) 
    even_i_1
       (.I0(even),
        .O(even_i_1_n_0));
  FDSE even_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(even_i_1_n_0),
        .Q(even),
        .S(reset_modified));
  LUT1 #(
    .INIT(2'h1)) 
    \initialize_counter[0]_i_1 
       (.I0(initialize_counter_reg[0]),
        .O(plusOp__2[0]));
  (* SOFT_HLUTNM = "soft_lutpair130" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \initialize_counter[1]_i_1 
       (.I0(initialize_counter_reg[0]),
        .I1(initialize_counter_reg[1]),
        .O(plusOp__2[1]));
  (* SOFT_HLUTNM = "soft_lutpair130" *) 
  LUT3 #(
    .INIT(8'h78)) 
    \initialize_counter[2]_i_1 
       (.I0(initialize_counter_reg[0]),
        .I1(initialize_counter_reg[1]),
        .I2(initialize_counter_reg[2]),
        .O(plusOp__2[2]));
  (* SOFT_HLUTNM = "soft_lutpair113" *) 
  LUT4 #(
    .INIT(16'h7F80)) 
    \initialize_counter[3]_i_1 
       (.I0(initialize_counter_reg[1]),
        .I1(initialize_counter_reg[0]),
        .I2(initialize_counter_reg[2]),
        .I3(initialize_counter_reg[3]),
        .O(plusOp__2[3]));
  LUT6 #(
    .INIT(64'h2AAAAAAAAAAAAAAA)) 
    \initialize_counter[4]_i_1 
       (.I0(initialize_ram),
        .I1(initialize_counter_reg[1]),
        .I2(initialize_counter_reg[0]),
        .I3(initialize_counter_reg[4]),
        .I4(initialize_counter_reg[3]),
        .I5(initialize_counter_reg[2]),
        .O(initialize_counter0));
  (* SOFT_HLUTNM = "soft_lutpair113" *) 
  LUT5 #(
    .INIT(32'h7FFF8000)) 
    \initialize_counter[4]_i_2 
       (.I0(initialize_counter_reg[2]),
        .I1(initialize_counter_reg[0]),
        .I2(initialize_counter_reg[1]),
        .I3(initialize_counter_reg[3]),
        .I4(initialize_counter_reg[4]),
        .O(plusOp__2[4]));
  FDRE \initialize_counter_reg[0] 
       (.C(rxuserclk2),
        .CE(initialize_counter0),
        .D(plusOp__2[0]),
        .Q(initialize_counter_reg[0]),
        .R(SR));
  FDRE \initialize_counter_reg[1] 
       (.C(rxuserclk2),
        .CE(initialize_counter0),
        .D(plusOp__2[1]),
        .Q(initialize_counter_reg[1]),
        .R(SR));
  FDRE \initialize_counter_reg[2] 
       (.C(rxuserclk2),
        .CE(initialize_counter0),
        .D(plusOp__2[2]),
        .Q(initialize_counter_reg[2]),
        .R(SR));
  FDRE \initialize_counter_reg[3] 
       (.C(rxuserclk2),
        .CE(initialize_counter0),
        .D(plusOp__2[3]),
        .Q(initialize_counter_reg[3]),
        .R(SR));
  FDRE \initialize_counter_reg[4] 
       (.C(rxuserclk2),
        .CE(initialize_counter0),
        .D(plusOp__2[4]),
        .Q(initialize_counter_reg[4]),
        .R(SR));
  LUT6 #(
    .INIT(64'hFFFFFFFF80000000)) 
    initialize_ram_complete_i_2
       (.I0(initialize_counter_reg[1]),
        .I1(initialize_counter_reg[0]),
        .I2(initialize_counter_reg[4]),
        .I3(initialize_counter_reg[3]),
        .I4(initialize_counter_reg[2]),
        .I5(initialize_ram_complete),
        .O(initialize_ram_complete_i_2_n_0));
  LUT2 #(
    .INIT(4'h2)) 
    initialize_ram_complete_pulse_i_1
       (.I0(initialize_ram_complete),
        .I1(initialize_ram_complete_reg__0),
        .O(initialize_ram_complete_pulse0));
  FDRE initialize_ram_complete_pulse_reg
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(initialize_ram_complete_pulse0),
        .Q(initialize_ram_complete_pulse),
        .R(SR));
  FDRE initialize_ram_complete_reg
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(initialize_ram_complete_i_2_n_0),
        .Q(initialize_ram_complete),
        .R(SR));
  FDRE initialize_ram_complete_reg_reg
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(initialize_ram_complete),
        .Q(initialize_ram_complete_reg__0),
        .R(SR));
  FDRE initialize_ram_complete_sync_reg1_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(initialize_ram_complete_sync),
        .Q(initialize_ram_complete_sync_reg1),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    initialize_ram_complete_sync_ris_edg_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(initialize_ram_complete_sync_ris_edg0),
        .Q(initialize_ram_complete_sync_ris_edg),
        .R(1'b0));
  LUT2 #(
    .INIT(4'h4)) 
    initialize_ram_i_1
       (.I0(initialize_ram_complete),
        .I1(initialize_ram),
        .O(initialize_ram_i_1_n_0));
  FDSE initialize_ram_reg
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(initialize_ram_i_1_n_0),
        .Q(initialize_ram),
        .S(SR));
  LUT6 #(
    .INIT(64'h4400400040004000)) 
    insert_idle_i_1
       (.I0(reset_modified),
        .I1(even),
        .I2(rd_enable_i_2_n_0),
        .I3(p_4_in),
        .I4(rd_enable_i_4_n_0),
        .I5(rd_enable_i_5_n_0),
        .O(insert_idle_i_1_n_0));
  FDRE insert_idle_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(insert_idle_i_1_n_0),
        .Q(insert_idle),
        .R(1'b0));
  FDRE insert_idle_reg_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(insert_idle),
        .Q(insert_idle_reg__0),
        .R(reset_modified));
  FDRE k28p5_wr_reg2_reg
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(k28p5_wr_reg),
        .Q(k28p5_wr_reg2),
        .R(reset_out));
  (* SOFT_HLUTNM = "soft_lutpair116" *) 
  LUT4 #(
    .INIT(16'h0020)) 
    k28p5_wr_reg_i_1
       (.I0(k28p5_wr_reg_i_2_n_0),
        .I1(wr_data[16]),
        .I2(wr_data[18]),
        .I3(wr_data[17]),
        .O(p_18_in));
  LUT6 #(
    .INIT(64'h0080000000000000)) 
    k28p5_wr_reg_i_2
       (.I0(wr_data[19]),
        .I1(wr_data[20]),
        .I2(wr_data[21]),
        .I3(wr_data[22]),
        .I4(wr_data[27]),
        .I5(wr_data[23]),
        .O(k28p5_wr_reg_i_2_n_0));
  FDRE k28p5_wr_reg_reg
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(p_18_in),
        .Q(k28p5_wr_reg),
        .R(reset_out));
  (* METHODOLOGY_DRC_VIOS = "" *) 
  (* RTL_RAM_BITS = "2304" *) 
  (* RTL_RAM_NAME = "transceiver_inst/rx_elastic_buffer_inst/ram_reg_0_63_0_2" *) 
  (* RTL_RAM_TYPE = "RAM_SDP" *) 
  (* ram_addr_begin = "0" *) 
  (* ram_addr_end = "63" *) 
  (* ram_offset = "0" *) 
  (* ram_slice_begin = "0" *) 
  (* ram_slice_end = "2" *) 
  RAM64M ram_reg_0_63_0_2
       (.ADDRA(rd_addr),
        .ADDRB(rd_addr),
        .ADDRC(rd_addr),
        .ADDRD(wr_addr),
        .DIA(wr_data_reg[0]),
        .DIB(wr_data_reg[1]),
        .DIC(wr_data_reg[2]),
        .DID(1'b0),
        .DOA(dpo[0]),
        .DOB(dpo[1]),
        .DOC(dpo[2]),
        .DOD(NLW_ram_reg_0_63_0_2_DOD_UNCONNECTED),
        .WCLK(rxuserclk2),
        .WE(wr_enable));
  (* METHODOLOGY_DRC_VIOS = "" *) 
  (* RTL_RAM_BITS = "2304" *) 
  (* RTL_RAM_NAME = "transceiver_inst/rx_elastic_buffer_inst/ram_reg_0_63_12_14" *) 
  (* RTL_RAM_TYPE = "RAM_SDP" *) 
  (* ram_addr_begin = "0" *) 
  (* ram_addr_end = "63" *) 
  (* ram_offset = "0" *) 
  (* ram_slice_begin = "12" *) 
  (* ram_slice_end = "14" *) 
  RAM64M ram_reg_0_63_12_14
       (.ADDRA(rd_addr),
        .ADDRB(rd_addr),
        .ADDRC(rd_addr),
        .ADDRD(wr_addr),
        .DIA(wr_data_reg[12]),
        .DIB(wr_data_reg[13]),
        .DIC(1'b0),
        .DID(1'b0),
        .DOA(dpo[12]),
        .DOB(dpo[13]),
        .DOC(NLW_ram_reg_0_63_12_14_DOC_UNCONNECTED),
        .DOD(NLW_ram_reg_0_63_12_14_DOD_UNCONNECTED),
        .WCLK(rxuserclk2),
        .WE(wr_enable));
  (* METHODOLOGY_DRC_VIOS = "" *) 
  (* RTL_RAM_BITS = "2304" *) 
  (* RTL_RAM_NAME = "transceiver_inst/rx_elastic_buffer_inst/ram_reg_0_63_15_17" *) 
  (* RTL_RAM_TYPE = "RAM_SDP" *) 
  (* ram_addr_begin = "0" *) 
  (* ram_addr_end = "63" *) 
  (* ram_offset = "0" *) 
  (* ram_slice_begin = "15" *) 
  (* ram_slice_end = "17" *) 
  RAM64M ram_reg_0_63_15_17
       (.ADDRA(rd_addr),
        .ADDRB(rd_addr),
        .ADDRC(rd_addr),
        .ADDRD(wr_addr),
        .DIA(1'b0),
        .DIB(wr_data_reg[16]),
        .DIC(wr_data_reg[17]),
        .DID(1'b0),
        .DOA(NLW_ram_reg_0_63_15_17_DOA_UNCONNECTED),
        .DOB(dpo[16]),
        .DOC(dpo[17]),
        .DOD(NLW_ram_reg_0_63_15_17_DOD_UNCONNECTED),
        .WCLK(rxuserclk2),
        .WE(wr_enable));
  (* METHODOLOGY_DRC_VIOS = "" *) 
  (* RTL_RAM_BITS = "2304" *) 
  (* RTL_RAM_NAME = "transceiver_inst/rx_elastic_buffer_inst/ram_reg_0_63_18_20" *) 
  (* RTL_RAM_TYPE = "RAM_SDP" *) 
  (* ram_addr_begin = "0" *) 
  (* ram_addr_end = "63" *) 
  (* ram_offset = "0" *) 
  (* ram_slice_begin = "18" *) 
  (* ram_slice_end = "20" *) 
  RAM64M ram_reg_0_63_18_20
       (.ADDRA(rd_addr),
        .ADDRB(rd_addr),
        .ADDRC(rd_addr),
        .ADDRD(wr_addr),
        .DIA(wr_data_reg[18]),
        .DIB(wr_data_reg[19]),
        .DIC(wr_data_reg[20]),
        .DID(1'b0),
        .DOA(dpo[18]),
        .DOB(dpo[19]),
        .DOC(dpo[20]),
        .DOD(NLW_ram_reg_0_63_18_20_DOD_UNCONNECTED),
        .WCLK(rxuserclk2),
        .WE(wr_enable));
  (* METHODOLOGY_DRC_VIOS = "" *) 
  (* RTL_RAM_BITS = "2304" *) 
  (* RTL_RAM_NAME = "transceiver_inst/rx_elastic_buffer_inst/ram_reg_0_63_21_23" *) 
  (* RTL_RAM_TYPE = "RAM_SDP" *) 
  (* ram_addr_begin = "0" *) 
  (* ram_addr_end = "63" *) 
  (* ram_offset = "0" *) 
  (* ram_slice_begin = "21" *) 
  (* ram_slice_end = "23" *) 
  RAM64M ram_reg_0_63_21_23
       (.ADDRA(rd_addr),
        .ADDRB(rd_addr),
        .ADDRC(rd_addr),
        .ADDRD(wr_addr),
        .DIA(wr_data_reg[21]),
        .DIB(wr_data_reg[22]),
        .DIC(wr_data_reg[23]),
        .DID(1'b0),
        .DOA(dpo[21]),
        .DOB(dpo[22]),
        .DOC(dpo[23]),
        .DOD(NLW_ram_reg_0_63_21_23_DOD_UNCONNECTED),
        .WCLK(rxuserclk2),
        .WE(wr_enable));
  (* METHODOLOGY_DRC_VIOS = "" *) 
  (* RTL_RAM_BITS = "2304" *) 
  (* RTL_RAM_NAME = "transceiver_inst/rx_elastic_buffer_inst/ram_reg_0_63_24_26" *) 
  (* RTL_RAM_TYPE = "RAM_SDP" *) 
  (* ram_addr_begin = "0" *) 
  (* ram_addr_end = "63" *) 
  (* ram_offset = "0" *) 
  (* ram_slice_begin = "24" *) 
  (* ram_slice_end = "26" *) 
  RAM64M ram_reg_0_63_24_26
       (.ADDRA(rd_addr),
        .ADDRB(rd_addr),
        .ADDRC(rd_addr),
        .ADDRD(wr_addr),
        .DIA(1'b0),
        .DIB(wr_data_reg[25]),
        .DIC(wr_data_reg[26]),
        .DID(1'b0),
        .DOA(NLW_ram_reg_0_63_24_26_DOA_UNCONNECTED),
        .DOB(dpo[25]),
        .DOC(dpo[26]),
        .DOD(NLW_ram_reg_0_63_24_26_DOD_UNCONNECTED),
        .WCLK(rxuserclk2),
        .WE(wr_enable));
  (* METHODOLOGY_DRC_VIOS = "" *) 
  (* RTL_RAM_BITS = "2304" *) 
  (* RTL_RAM_NAME = "transceiver_inst/rx_elastic_buffer_inst/ram_reg_0_63_27_29" *) 
  (* RTL_RAM_TYPE = "RAM_SDP" *) 
  (* ram_addr_begin = "0" *) 
  (* ram_addr_end = "63" *) 
  (* ram_offset = "0" *) 
  (* ram_slice_begin = "27" *) 
  (* ram_slice_end = "29" *) 
  RAM64M ram_reg_0_63_27_29
       (.ADDRA(rd_addr),
        .ADDRB(rd_addr),
        .ADDRC(rd_addr),
        .ADDRD(wr_addr),
        .DIA(wr_data_reg[27]),
        .DIB(wr_data_reg[28]),
        .DIC(1'b0),
        .DID(1'b0),
        .DOA(dpo[27]),
        .DOB(dpo[28]),
        .DOC(NLW_ram_reg_0_63_27_29_DOC_UNCONNECTED),
        .DOD(NLW_ram_reg_0_63_27_29_DOD_UNCONNECTED),
        .WCLK(rxuserclk2),
        .WE(wr_enable));
  (* METHODOLOGY_DRC_VIOS = "" *) 
  (* RTL_RAM_BITS = "2304" *) 
  (* RTL_RAM_NAME = "transceiver_inst/rx_elastic_buffer_inst/ram_reg_0_63_3_5" *) 
  (* RTL_RAM_TYPE = "RAM_SDP" *) 
  (* ram_addr_begin = "0" *) 
  (* ram_addr_end = "63" *) 
  (* ram_offset = "0" *) 
  (* ram_slice_begin = "3" *) 
  (* ram_slice_end = "5" *) 
  RAM64M ram_reg_0_63_3_5
       (.ADDRA(rd_addr),
        .ADDRB(rd_addr),
        .ADDRC(rd_addr),
        .ADDRD(wr_addr),
        .DIA(wr_data_reg[3]),
        .DIB(wr_data_reg[4]),
        .DIC(wr_data_reg[5]),
        .DID(1'b0),
        .DOA(dpo[3]),
        .DOB(dpo[4]),
        .DOC(dpo[5]),
        .DOD(NLW_ram_reg_0_63_3_5_DOD_UNCONNECTED),
        .WCLK(rxuserclk2),
        .WE(wr_enable));
  (* METHODOLOGY_DRC_VIOS = "" *) 
  (* RTL_RAM_BITS = "2304" *) 
  (* RTL_RAM_NAME = "transceiver_inst/rx_elastic_buffer_inst/ram_reg_0_63_6_8" *) 
  (* RTL_RAM_TYPE = "RAM_SDP" *) 
  (* ram_addr_begin = "0" *) 
  (* ram_addr_end = "63" *) 
  (* ram_offset = "0" *) 
  (* ram_slice_begin = "6" *) 
  (* ram_slice_end = "8" *) 
  RAM64M ram_reg_0_63_6_8
       (.ADDRA(rd_addr),
        .ADDRB(rd_addr),
        .ADDRC(rd_addr),
        .ADDRD(wr_addr),
        .DIA(wr_data_reg[6]),
        .DIB(wr_data_reg[7]),
        .DIC(1'b0),
        .DID(1'b0),
        .DOA(dpo[6]),
        .DOB(dpo[7]),
        .DOC(NLW_ram_reg_0_63_6_8_DOC_UNCONNECTED),
        .DOD(NLW_ram_reg_0_63_6_8_DOD_UNCONNECTED),
        .WCLK(rxuserclk2),
        .WE(wr_enable));
  (* METHODOLOGY_DRC_VIOS = "" *) 
  (* RTL_RAM_BITS = "2304" *) 
  (* RTL_RAM_NAME = "transceiver_inst/rx_elastic_buffer_inst/ram_reg_0_63_9_11" *) 
  (* RTL_RAM_TYPE = "RAM_SDP" *) 
  (* ram_addr_begin = "0" *) 
  (* ram_addr_end = "63" *) 
  (* ram_offset = "0" *) 
  (* ram_slice_begin = "9" *) 
  (* ram_slice_end = "11" *) 
  RAM64M ram_reg_0_63_9_11
       (.ADDRA(rd_addr),
        .ADDRB(rd_addr),
        .ADDRC(rd_addr),
        .ADDRD(wr_addr),
        .DIA(wr_data_reg[9]),
        .DIB(wr_data_reg[10]),
        .DIC(wr_data_reg[11]),
        .DID(1'b0),
        .DOA(dpo[9]),
        .DOB(dpo[10]),
        .DOC(dpo[11]),
        .DOD(NLW_ram_reg_0_63_9_11_DOD_UNCONNECTED),
        .WCLK(rxuserclk2),
        .WE(wr_enable));
  (* SOFT_HLUTNM = "soft_lutpair125" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \rd_addr_gray[0]_i_1 
       (.I0(\rd_addr_plus2_reg_n_0_[0] ),
        .I1(p_1_in),
        .O(\rd_addr_gray[0]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair132" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \rd_addr_gray[1]_i_1 
       (.I0(p_1_in),
        .I1(p_2_in),
        .O(\rd_addr_gray[1]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair132" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \rd_addr_gray[2]_i_1 
       (.I0(p_2_in),
        .I1(p_3_in),
        .O(\rd_addr_gray[2]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair131" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \rd_addr_gray[3]_i_1 
       (.I0(p_3_in),
        .I1(p_4_in_0),
        .O(\rd_addr_gray[3]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair131" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \rd_addr_gray[4]_i_1 
       (.I0(p_4_in_0),
        .I1(\rd_addr_plus2_reg_n_0_[5] ),
        .O(\rd_addr_gray[4]_i_1_n_0 ));
  FDRE \rd_addr_gray_reg[0] 
       (.C(userclk2),
        .CE(1'b1),
        .D(\rd_addr_gray[0]_i_1_n_0 ),
        .Q(rd_addr_gray[0]),
        .R(reset_modified));
  FDRE \rd_addr_gray_reg[1] 
       (.C(userclk2),
        .CE(1'b1),
        .D(\rd_addr_gray[1]_i_1_n_0 ),
        .Q(rd_addr_gray[1]),
        .R(reset_modified));
  FDRE \rd_addr_gray_reg[2] 
       (.C(userclk2),
        .CE(1'b1),
        .D(\rd_addr_gray[2]_i_1_n_0 ),
        .Q(rd_addr_gray[2]),
        .R(reset_modified));
  FDRE \rd_addr_gray_reg[3] 
       (.C(userclk2),
        .CE(1'b1),
        .D(\rd_addr_gray[3]_i_1_n_0 ),
        .Q(rd_addr_gray[3]),
        .R(reset_modified));
  FDRE \rd_addr_gray_reg[4] 
       (.C(userclk2),
        .CE(1'b1),
        .D(\rd_addr_gray[4]_i_1_n_0 ),
        .Q(rd_addr_gray[4]),
        .R(reset_modified));
  FDRE \rd_addr_gray_reg[5] 
       (.C(userclk2),
        .CE(1'b1),
        .D(\rd_addr_plus2_reg_n_0_[5] ),
        .Q(rd_addr_gray[5]),
        .R(reset_modified));
  FDSE \rd_addr_plus1_reg[0] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(\rd_addr_plus2_reg_n_0_[0] ),
        .Q(rd_addr_plus1[0]),
        .S(reset_modified));
  FDRE \rd_addr_plus1_reg[1] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(p_1_in),
        .Q(rd_addr_plus1[1]),
        .R(reset_modified));
  FDRE \rd_addr_plus1_reg[2] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(p_2_in),
        .Q(rd_addr_plus1[2]),
        .R(reset_modified));
  FDRE \rd_addr_plus1_reg[3] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(p_3_in),
        .Q(rd_addr_plus1[3]),
        .R(reset_modified));
  FDRE \rd_addr_plus1_reg[4] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(p_4_in_0),
        .Q(rd_addr_plus1[4]),
        .R(reset_modified));
  FDRE \rd_addr_plus1_reg[5] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(\rd_addr_plus2_reg_n_0_[5] ),
        .Q(rd_addr_plus1[5]),
        .R(reset_modified));
  LUT1 #(
    .INIT(2'h1)) 
    \rd_addr_plus2[0]_i_1 
       (.I0(\rd_addr_plus2_reg_n_0_[0] ),
        .O(plusOp__1[0]));
  (* SOFT_HLUTNM = "soft_lutpair125" *) 
  LUT3 #(
    .INIT(8'h78)) 
    \rd_addr_plus2[2]_i_1 
       (.I0(\rd_addr_plus2_reg_n_0_[0] ),
        .I1(p_1_in),
        .I2(p_2_in),
        .O(plusOp__1[2]));
  (* SOFT_HLUTNM = "soft_lutpair112" *) 
  LUT4 #(
    .INIT(16'h7F80)) 
    \rd_addr_plus2[3]_i_1 
       (.I0(p_1_in),
        .I1(\rd_addr_plus2_reg_n_0_[0] ),
        .I2(p_2_in),
        .I3(p_3_in),
        .O(plusOp__1[3]));
  (* SOFT_HLUTNM = "soft_lutpair112" *) 
  LUT5 #(
    .INIT(32'h7FFF8000)) 
    \rd_addr_plus2[4]_i_1 
       (.I0(p_2_in),
        .I1(\rd_addr_plus2_reg_n_0_[0] ),
        .I2(p_1_in),
        .I3(p_3_in),
        .I4(p_4_in_0),
        .O(plusOp__1[4]));
  LUT6 #(
    .INIT(64'h7FFFFFFF80000000)) 
    \rd_addr_plus2[5]_i_1 
       (.I0(p_4_in_0),
        .I1(p_3_in),
        .I2(p_1_in),
        .I3(\rd_addr_plus2_reg_n_0_[0] ),
        .I4(p_2_in),
        .I5(\rd_addr_plus2_reg_n_0_[5] ),
        .O(plusOp__1[5]));
  FDRE \rd_addr_plus2_reg[0] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(plusOp__1[0]),
        .Q(\rd_addr_plus2_reg_n_0_[0] ),
        .R(reset_modified));
  FDSE \rd_addr_plus2_reg[1] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(\rd_addr_gray[0]_i_1_n_0 ),
        .Q(p_1_in),
        .S(reset_modified));
  FDRE \rd_addr_plus2_reg[2] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(plusOp__1[2]),
        .Q(p_2_in),
        .R(reset_modified));
  FDRE \rd_addr_plus2_reg[3] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(plusOp__1[3]),
        .Q(p_3_in),
        .R(reset_modified));
  FDRE \rd_addr_plus2_reg[4] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(plusOp__1[4]),
        .Q(p_4_in_0),
        .R(reset_modified));
  FDRE \rd_addr_plus2_reg[5] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(plusOp__1[5]),
        .Q(\rd_addr_plus2_reg_n_0_[5] ),
        .R(reset_modified));
  FDRE \rd_addr_reg[0] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_addr_plus1[0]),
        .Q(rd_addr[0]),
        .R(reset_modified));
  FDRE \rd_addr_reg[1] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_addr_plus1[1]),
        .Q(rd_addr[1]),
        .R(reset_modified));
  FDRE \rd_addr_reg[2] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_addr_plus1[2]),
        .Q(rd_addr[2]),
        .R(reset_modified));
  FDRE \rd_addr_reg[3] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_addr_plus1[3]),
        .Q(rd_addr[3]),
        .R(reset_modified));
  FDRE \rd_addr_reg[4] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_addr_plus1[4]),
        .Q(rd_addr[4]),
        .R(reset_modified));
  FDRE \rd_addr_reg[5] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_addr_plus1[5]),
        .Q(rd_addr[5]),
        .R(reset_modified));
  FDRE \rd_data_reg[0] 
       (.C(userclk2),
        .CE(1'b1),
        .D(dpo[0]),
        .Q(rd_data[0]),
        .R(reset_modified));
  FDRE \rd_data_reg[10] 
       (.C(userclk2),
        .CE(1'b1),
        .D(dpo[10]),
        .Q(rd_data[10]),
        .R(reset_modified));
  FDRE \rd_data_reg[11] 
       (.C(userclk2),
        .CE(1'b1),
        .D(dpo[11]),
        .Q(rd_data[11]),
        .R(reset_modified));
  FDRE \rd_data_reg[12] 
       (.C(userclk2),
        .CE(1'b1),
        .D(dpo[12]),
        .Q(rd_data[12]),
        .R(reset_modified));
  FDRE \rd_data_reg[13] 
       (.C(userclk2),
        .CE(1'b1),
        .D(dpo[13]),
        .Q(rd_data[13]),
        .R(reset_modified));
  FDRE \rd_data_reg[16] 
       (.C(userclk2),
        .CE(1'b1),
        .D(dpo[16]),
        .Q(rd_data[16]),
        .R(reset_modified));
  FDRE \rd_data_reg[17] 
       (.C(userclk2),
        .CE(1'b1),
        .D(dpo[17]),
        .Q(rd_data[17]),
        .R(reset_modified));
  FDRE \rd_data_reg[18] 
       (.C(userclk2),
        .CE(1'b1),
        .D(dpo[18]),
        .Q(rd_data[18]),
        .R(reset_modified));
  FDRE \rd_data_reg[19] 
       (.C(userclk2),
        .CE(1'b1),
        .D(dpo[19]),
        .Q(rd_data[19]),
        .R(reset_modified));
  FDRE \rd_data_reg[1] 
       (.C(userclk2),
        .CE(1'b1),
        .D(dpo[1]),
        .Q(rd_data[1]),
        .R(reset_modified));
  FDRE \rd_data_reg[20] 
       (.C(userclk2),
        .CE(1'b1),
        .D(dpo[20]),
        .Q(rd_data[20]),
        .R(reset_modified));
  FDRE \rd_data_reg[21] 
       (.C(userclk2),
        .CE(1'b1),
        .D(dpo[21]),
        .Q(rd_data[21]),
        .R(reset_modified));
  FDRE \rd_data_reg[22] 
       (.C(userclk2),
        .CE(1'b1),
        .D(dpo[22]),
        .Q(rd_data[22]),
        .R(reset_modified));
  FDRE \rd_data_reg[23] 
       (.C(userclk2),
        .CE(1'b1),
        .D(dpo[23]),
        .Q(rd_data[23]),
        .R(reset_modified));
  FDRE \rd_data_reg[25] 
       (.C(userclk2),
        .CE(1'b1),
        .D(dpo[25]),
        .Q(rd_data[25]),
        .R(reset_modified));
  FDRE \rd_data_reg[26] 
       (.C(userclk2),
        .CE(1'b1),
        .D(dpo[26]),
        .Q(rd_data[26]),
        .R(reset_modified));
  FDRE \rd_data_reg[27] 
       (.C(userclk2),
        .CE(1'b1),
        .D(dpo[27]),
        .Q(rd_data[27]),
        .R(reset_modified));
  FDRE \rd_data_reg[28] 
       (.C(userclk2),
        .CE(1'b1),
        .D(dpo[28]),
        .Q(\rd_data_reg_n_0_[28] ),
        .R(reset_modified));
  FDRE \rd_data_reg[2] 
       (.C(userclk2),
        .CE(1'b1),
        .D(dpo[2]),
        .Q(rd_data[2]),
        .R(reset_modified));
  FDRE \rd_data_reg[3] 
       (.C(userclk2),
        .CE(1'b1),
        .D(dpo[3]),
        .Q(rd_data[3]),
        .R(reset_modified));
  FDRE \rd_data_reg[4] 
       (.C(userclk2),
        .CE(1'b1),
        .D(dpo[4]),
        .Q(rd_data[4]),
        .R(reset_modified));
  FDRE \rd_data_reg[5] 
       (.C(userclk2),
        .CE(1'b1),
        .D(dpo[5]),
        .Q(rd_data[5]),
        .R(reset_modified));
  FDRE \rd_data_reg[6] 
       (.C(userclk2),
        .CE(1'b1),
        .D(dpo[6]),
        .Q(rd_data[6]),
        .R(reset_modified));
  FDRE \rd_data_reg[7] 
       (.C(userclk2),
        .CE(1'b1),
        .D(dpo[7]),
        .Q(rd_data[7]),
        .R(reset_modified));
  FDRE \rd_data_reg[9] 
       (.C(userclk2),
        .CE(1'b1),
        .D(dpo[9]),
        .Q(rd_data[9]),
        .R(reset_modified));
  FDRE \rd_data_reg_reg[0] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_data[0]),
        .Q(rd_data_reg[0]),
        .R(reset_modified));
  FDRE \rd_data_reg_reg[10] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_data[10]),
        .Q(rd_data_reg[10]),
        .R(reset_modified));
  FDRE \rd_data_reg_reg[11] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_data[11]),
        .Q(rd_data_reg[11]),
        .R(reset_modified));
  FDRE \rd_data_reg_reg[12] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_data[12]),
        .Q(rd_data_reg[12]),
        .R(reset_modified));
  FDRE \rd_data_reg_reg[13] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_data[13]),
        .Q(rd_data_reg[13]),
        .R(reset_modified));
  FDRE \rd_data_reg_reg[16] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_data[16]),
        .Q(rd_data_reg[16]),
        .R(reset_modified));
  FDRE \rd_data_reg_reg[17] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_data[17]),
        .Q(rd_data_reg[17]),
        .R(reset_modified));
  FDRE \rd_data_reg_reg[18] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_data[18]),
        .Q(rd_data_reg[18]),
        .R(reset_modified));
  FDRE \rd_data_reg_reg[19] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_data[19]),
        .Q(rd_data_reg[19]),
        .R(reset_modified));
  FDRE \rd_data_reg_reg[1] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_data[1]),
        .Q(rd_data_reg[1]),
        .R(reset_modified));
  FDRE \rd_data_reg_reg[20] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_data[20]),
        .Q(rd_data_reg[20]),
        .R(reset_modified));
  FDRE \rd_data_reg_reg[21] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_data[21]),
        .Q(rd_data_reg[21]),
        .R(reset_modified));
  FDRE \rd_data_reg_reg[22] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_data[22]),
        .Q(rd_data_reg[22]),
        .R(reset_modified));
  FDRE \rd_data_reg_reg[23] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_data[23]),
        .Q(rd_data_reg[23]),
        .R(reset_modified));
  FDRE \rd_data_reg_reg[25] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_data[25]),
        .Q(rd_data_reg[25]),
        .R(reset_modified));
  FDRE \rd_data_reg_reg[26] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_data[26]),
        .Q(rd_data_reg[26]),
        .R(reset_modified));
  FDRE \rd_data_reg_reg[27] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_data[27]),
        .Q(rd_data_reg[27]),
        .R(reset_modified));
  FDRE \rd_data_reg_reg[28] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(\rd_data_reg_n_0_[28] ),
        .Q(rd_data_reg[28]),
        .R(reset_modified));
  FDRE \rd_data_reg_reg[2] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_data[2]),
        .Q(rd_data_reg[2]),
        .R(reset_modified));
  FDRE \rd_data_reg_reg[3] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_data[3]),
        .Q(rd_data_reg[3]),
        .R(reset_modified));
  FDRE \rd_data_reg_reg[4] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_data[4]),
        .Q(rd_data_reg[4]),
        .R(reset_modified));
  FDRE \rd_data_reg_reg[5] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_data[5]),
        .Q(rd_data_reg[5]),
        .R(reset_modified));
  FDRE \rd_data_reg_reg[6] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_data[6]),
        .Q(rd_data_reg[6]),
        .R(reset_modified));
  FDRE \rd_data_reg_reg[7] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_data[7]),
        .Q(rd_data_reg[7]),
        .R(reset_modified));
  FDRE \rd_data_reg_reg[9] 
       (.C(userclk2),
        .CE(rd_enable),
        .D(rd_data[9]),
        .Q(rd_data_reg[9]),
        .R(reset_modified));
  LUT6 #(
    .INIT(64'h0044044404440444)) 
    rd_enable_i_1
       (.I0(reset_modified),
        .I1(even),
        .I2(rd_enable_i_2_n_0),
        .I3(p_4_in),
        .I4(rd_enable_i_4_n_0),
        .I5(rd_enable_i_5_n_0),
        .O(rd_enable_i_1_n_0));
  (* SOFT_HLUTNM = "soft_lutpair111" *) 
  LUT2 #(
    .INIT(4'h7)) 
    rd_enable_i_10
       (.I0(rd_occupancy[2]),
        .I1(rd_occupancy[3]),
        .O(rd_enable_i_10_n_0));
  (* SOFT_HLUTNM = "soft_lutpair115" *) 
  LUT4 #(
    .INIT(16'h4000)) 
    rd_enable_i_11
       (.I0(rd_data[6]),
        .I1(rd_data[7]),
        .I2(rd_data[5]),
        .I3(rd_data[4]),
        .O(rd_enable_i_11_n_0));
  (* SOFT_HLUTNM = "soft_lutpair115" *) 
  LUT4 #(
    .INIT(16'h0004)) 
    rd_enable_i_12
       (.I0(rd_data[7]),
        .I1(rd_data[6]),
        .I2(rd_data[5]),
        .I3(rd_data[4]),
        .O(rd_enable_i_12_n_0));
  LUT6 #(
    .INIT(64'h0001000000000000)) 
    rd_enable_i_2
       (.I0(rd_data[1]),
        .I1(rd_data[0]),
        .I2(rd_data[3]),
        .I3(rd_data[2]),
        .I4(rd_enable_i_6_n_0),
        .I5(rd_enable_i_7_n_0),
        .O(rd_enable_i_2_n_0));
  LUT4 #(
    .INIT(16'h0020)) 
    rd_enable_i_3
       (.I0(rd_enable_i_8_n_0),
        .I1(rd_data[16]),
        .I2(rd_data[18]),
        .I3(rd_data[17]),
        .O(p_4_in));
  LUT6 #(
    .INIT(64'h0001000100010000)) 
    rd_enable_i_4
       (.I0(rd_occupancy[4]),
        .I1(rd_occupancy[5]),
        .I2(rd_data[3]),
        .I3(rd_data[11]),
        .I4(rd_enable_i_9_n_0),
        .I5(rd_enable_i_10_n_0),
        .O(rd_enable_i_4_n_0));
  LUT5 #(
    .INIT(32'h08300800)) 
    rd_enable_i_5
       (.I0(rd_enable_i_11_n_0),
        .I1(rd_data[2]),
        .I2(rd_data[1]),
        .I3(rd_data[0]),
        .I4(rd_enable_i_12_n_0),
        .O(rd_enable_i_5_n_0));
  LUT6 #(
    .INIT(64'h0000000000000020)) 
    rd_enable_i_6
       (.I0(rd_data[4]),
        .I1(rd_data[5]),
        .I2(rd_data[6]),
        .I3(rd_data[7]),
        .I4(rd_occupancy[5]),
        .I5(rd_data[11]),
        .O(rd_enable_i_6_n_0));
  (* SOFT_HLUTNM = "soft_lutpair111" *) 
  LUT5 #(
    .INIT(32'h7FFFFFFF)) 
    rd_enable_i_7
       (.I0(rd_occupancy[2]),
        .I1(rd_occupancy[3]),
        .I2(rd_occupancy[0]),
        .I3(rd_occupancy[1]),
        .I4(rd_occupancy[4]),
        .O(rd_enable_i_7_n_0));
  LUT6 #(
    .INIT(64'h0080000000000000)) 
    rd_enable_i_8
       (.I0(rd_data[19]),
        .I1(rd_data[20]),
        .I2(rd_data[21]),
        .I3(rd_data[22]),
        .I4(rd_data[27]),
        .I5(rd_data[23]),
        .O(rd_enable_i_8_n_0));
  LUT2 #(
    .INIT(4'h7)) 
    rd_enable_i_9
       (.I0(rd_occupancy[0]),
        .I1(rd_occupancy[1]),
        .O(rd_enable_i_9_n_0));
  FDRE rd_enable_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(rd_enable_i_1_n_0),
        .Q(rd_enable),
        .R(1'b0));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY4 rd_occupancy0_carry
       (.CI(1'b0),
        .CO({rd_occupancy0_carry_n_0,rd_occupancy0_carry_n_1,rd_occupancy0_carry_n_2,rd_occupancy0_carry_n_3}),
        .CYINIT(1'b1),
        .DI(gray_to_bin[3:0]),
        .O(rd_occupancy01_out[3:0]),
        .S({\reclock_wr_addrgray[4].sync_wr_addrgray_n_0 ,\reclock_wr_addrgray[3].sync_wr_addrgray_n_0 ,\reclock_wr_addrgray[2].sync_wr_addrgray_n_0 ,\reclock_wr_addrgray[1].sync_wr_addrgray_n_0 }));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY4 rd_occupancy0_carry__0
       (.CI(rd_occupancy0_carry_n_0),
        .CO({NLW_rd_occupancy0_carry__0_CO_UNCONNECTED[3:1],rd_occupancy0_carry__0_n_3}),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,gray_to_bin[4]}),
        .O({NLW_rd_occupancy0_carry__0_O_UNCONNECTED[3:2],rd_occupancy01_out[5:4]}),
        .S({1'b0,1'b0,\reclock_wr_addrgray[5].sync_wr_addrgray_n_0 ,\reclock_wr_addrgray[5].sync_wr_addrgray_n_1 }));
  LUT2 #(
    .INIT(4'h6)) 
    rd_occupancy0_carry__0_i_1
       (.I0(\reclock_wr_addrgray[4].sync_wr_addrgray_n_1 ),
        .I1(data_out),
        .O(gray_to_bin[4]));
  LUT3 #(
    .INIT(8'h96)) 
    rd_occupancy0_carry_i_1
       (.I0(p_1_in30_in),
        .I1(data_out),
        .I2(\reclock_wr_addrgray[4].sync_wr_addrgray_n_1 ),
        .O(gray_to_bin[3]));
  LUT4 #(
    .INIT(16'h6996)) 
    rd_occupancy0_carry_i_2
       (.I0(p_2_in33_in),
        .I1(\reclock_wr_addrgray[4].sync_wr_addrgray_n_1 ),
        .I2(data_out),
        .I3(p_1_in30_in),
        .O(gray_to_bin[2]));
  LUT5 #(
    .INIT(32'h96696996)) 
    rd_occupancy0_carry_i_3
       (.I0(p_3_in36_in),
        .I1(p_1_in30_in),
        .I2(data_out),
        .I3(\reclock_wr_addrgray[4].sync_wr_addrgray_n_1 ),
        .I4(p_2_in33_in),
        .O(gray_to_bin[1]));
  LUT6 #(
    .INIT(64'h6996966996696996)) 
    rd_occupancy0_carry_i_4
       (.I0(\reclock_wr_addrgray[0].sync_wr_addrgray_n_0 ),
        .I1(p_2_in33_in),
        .I2(\reclock_wr_addrgray[4].sync_wr_addrgray_n_1 ),
        .I3(data_out),
        .I4(p_1_in30_in),
        .I5(p_3_in36_in),
        .O(gray_to_bin[0]));
  FDRE \rd_occupancy_reg[0] 
       (.C(userclk2),
        .CE(1'b1),
        .D(rd_occupancy01_out[0]),
        .Q(rd_occupancy[0]),
        .R(reset_modified));
  FDRE \rd_occupancy_reg[1] 
       (.C(userclk2),
        .CE(1'b1),
        .D(rd_occupancy01_out[1]),
        .Q(rd_occupancy[1]),
        .R(reset_modified));
  FDRE \rd_occupancy_reg[2] 
       (.C(userclk2),
        .CE(1'b1),
        .D(rd_occupancy01_out[2]),
        .Q(rd_occupancy[2]),
        .R(reset_modified));
  FDRE \rd_occupancy_reg[3] 
       (.C(userclk2),
        .CE(1'b1),
        .D(rd_occupancy01_out[3]),
        .Q(rd_occupancy[3]),
        .R(reset_modified));
  FDRE \rd_occupancy_reg[4] 
       (.C(userclk2),
        .CE(1'b1),
        .D(rd_occupancy01_out[4]),
        .Q(rd_occupancy[4]),
        .R(reset_modified));
  FDSE \rd_occupancy_reg[5] 
       (.C(userclk2),
        .CE(1'b1),
        .D(rd_occupancy01_out[5]),
        .Q(rd_occupancy[5]),
        .S(reset_modified));
  gmii_to_sgmii_bridge_sync_block \reclock_rd_addrgray[0].sync_rd_addrgray 
       (.Q(rd_addr_gray[0]),
        .data_out(\reclock_rd_addrgray[0].sync_rd_addrgray_n_0 ),
        .rxuserclk2(rxuserclk2));
  gmii_to_sgmii_bridge_sync_block_5 \reclock_rd_addrgray[1].sync_rd_addrgray 
       (.Q(wr_addr[0]),
        .S(\reclock_rd_addrgray[1].sync_rd_addrgray_n_0 ),
        .data_out(\reclock_rd_addrgray[0].sync_rd_addrgray_n_0 ),
        .data_sync_reg1_0(rd_addr_gray[1]),
        .data_sync_reg6_0(p_3_in21_in),
        .p_25_in(p_25_in),
        .rxuserclk2(rxuserclk2));
  gmii_to_sgmii_bridge_sync_block_6 \reclock_rd_addrgray[2].sync_rd_addrgray 
       (.Q(wr_addr[1]),
        .S(\reclock_rd_addrgray[2].sync_rd_addrgray_n_0 ),
        .data_out(p_2_in18_in),
        .data_sync_reg1_0(rd_addr_gray[2]),
        .rxuserclk2(rxuserclk2),
        .\wr_occupancy_reg[3] (\reclock_rd_addrgray[4].sync_rd_addrgray_n_1 ),
        .\wr_occupancy_reg[3]_0 (p_14_in),
        .\wr_occupancy_reg[3]_1 (p_1_in15_in),
        .\wr_occupancy_reg[3]_2 (p_3_in21_in));
  gmii_to_sgmii_bridge_sync_block_7 \reclock_rd_addrgray[3].sync_rd_addrgray 
       (.Q(wr_addr[2]),
        .S(\reclock_rd_addrgray[3].sync_rd_addrgray_n_0 ),
        .data_out(p_1_in15_in),
        .data_sync_reg1_0(rd_addr_gray[3]),
        .rxuserclk2(rxuserclk2),
        .\wr_occupancy_reg[3] (p_14_in),
        .\wr_occupancy_reg[3]_0 (\reclock_rd_addrgray[4].sync_rd_addrgray_n_1 ),
        .\wr_occupancy_reg[3]_1 (p_2_in18_in));
  gmii_to_sgmii_bridge_sync_block_8 \reclock_rd_addrgray[4].sync_rd_addrgray 
       (.Q(wr_addr[3]),
        .S(\reclock_rd_addrgray[4].sync_rd_addrgray_n_0 ),
        .data_out(\reclock_rd_addrgray[4].sync_rd_addrgray_n_1 ),
        .data_sync_reg1_0(rd_addr_gray[4]),
        .rxuserclk2(rxuserclk2),
        .\wr_occupancy_reg[3] (p_14_in),
        .\wr_occupancy_reg[3]_0 (p_1_in15_in));
  gmii_to_sgmii_bridge_sync_block_9 \reclock_rd_addrgray[5].sync_rd_addrgray 
       (.ADDRD(wr_addr[5:4]),
        .Q(rd_addr_gray[5]),
        .S({\reclock_rd_addrgray[5].sync_rd_addrgray_n_0 ,\reclock_rd_addrgray[5].sync_rd_addrgray_n_1 }),
        .data_out(p_14_in),
        .rxuserclk2(rxuserclk2),
        .\wr_occupancy_reg[5] (\reclock_rd_addrgray[4].sync_rd_addrgray_n_1 ));
  gmii_to_sgmii_bridge_sync_block_10 \reclock_wr_addrgray[0].sync_wr_addrgray 
       (.Q(\wr_addr_gray_reg_n_0_[0] ),
        .data_out(\reclock_wr_addrgray[0].sync_wr_addrgray_n_0 ),
        .userclk2(userclk2));
  gmii_to_sgmii_bridge_sync_block_11 \reclock_wr_addrgray[1].sync_wr_addrgray 
       (.DI(gray_to_bin[1]),
        .Q(rd_addr[0]),
        .S(\reclock_wr_addrgray[1].sync_wr_addrgray_n_0 ),
        .data_out(\reclock_wr_addrgray[0].sync_wr_addrgray_n_0 ),
        .data_sync_reg1_0(\wr_addr_gray_reg_n_0_[1] ),
        .data_sync_reg6_0(p_3_in36_in),
        .userclk2(userclk2));
  gmii_to_sgmii_bridge_sync_block_12 \reclock_wr_addrgray[2].sync_wr_addrgray 
       (.Q(rd_addr[1]),
        .S(\reclock_wr_addrgray[2].sync_wr_addrgray_n_0 ),
        .data_out(p_2_in33_in),
        .data_sync_reg1_0(\wr_addr_gray_reg_n_0_[2] ),
        .\rd_occupancy_reg[3] (\reclock_wr_addrgray[4].sync_wr_addrgray_n_1 ),
        .\rd_occupancy_reg[3]_0 (data_out),
        .\rd_occupancy_reg[3]_1 (p_1_in30_in),
        .\rd_occupancy_reg[3]_2 (p_3_in36_in),
        .userclk2(userclk2));
  gmii_to_sgmii_bridge_sync_block_13 \reclock_wr_addrgray[3].sync_wr_addrgray 
       (.Q(rd_addr[2]),
        .S(\reclock_wr_addrgray[3].sync_wr_addrgray_n_0 ),
        .data_out(p_1_in30_in),
        .data_sync_reg1_0(\wr_addr_gray_reg_n_0_[3] ),
        .\rd_occupancy_reg[3] (data_out),
        .\rd_occupancy_reg[3]_0 (\reclock_wr_addrgray[4].sync_wr_addrgray_n_1 ),
        .\rd_occupancy_reg[3]_1 (p_2_in33_in),
        .userclk2(userclk2));
  gmii_to_sgmii_bridge_sync_block_14 \reclock_wr_addrgray[4].sync_wr_addrgray 
       (.Q(rd_addr[3]),
        .S(\reclock_wr_addrgray[4].sync_wr_addrgray_n_0 ),
        .data_out(\reclock_wr_addrgray[4].sync_wr_addrgray_n_1 ),
        .data_sync_reg1_0(\wr_addr_gray_reg_n_0_[4] ),
        .\rd_occupancy_reg[3] (data_out),
        .\rd_occupancy_reg[3]_0 (p_1_in30_in),
        .userclk2(userclk2));
  gmii_to_sgmii_bridge_sync_block_15 \reclock_wr_addrgray[5].sync_wr_addrgray 
       (.Q(rd_addr[5:4]),
        .S({\reclock_wr_addrgray[5].sync_wr_addrgray_n_0 ,\reclock_wr_addrgray[5].sync_wr_addrgray_n_1 }),
        .data_out(data_out),
        .data_sync_reg1_0(data_in),
        .\rd_occupancy_reg[5] (\reclock_wr_addrgray[4].sync_wr_addrgray_n_1 ),
        .userclk2(userclk2));
  LUT6 #(
    .INIT(64'hABAAFFFFABAA0000)) 
    remove_idle_i_1
       (.I0(remove_idle_i_2_n_0),
        .I1(wr_enable_i_4_n_0),
        .I2(remove_idle_i_3_n_0),
        .I3(wr_enable_i_2_n_0),
        .I4(initialize_ram_complete),
        .I5(remove_idle),
        .O(remove_idle_i_1_n_0));
  LUT6 #(
    .INIT(64'h8000000000000000)) 
    remove_idle_i_2
       (.I0(d16p2_wr_reg_i_2_n_0),
        .I1(remove_idle_i_4_n_0),
        .I2(wr_enable_i_9_n_0),
        .I3(wr_enable_i_8_n_0),
        .I4(remove_idle_i_5_n_0),
        .I5(k28p5_wr_reg_i_2_n_0),
        .O(remove_idle_i_2_n_0));
  LUT6 #(
    .INIT(64'hFFFFF1FFFFFFFFFF)) 
    remove_idle_i_3
       (.I0(d2p2_wr_reg2),
        .I1(d21p5_wr_reg2),
        .I2(wr_data[17]),
        .I3(wr_data[18]),
        .I4(wr_data[16]),
        .I5(k28p5_wr_reg_i_2_n_0),
        .O(remove_idle_i_3_n_0));
  (* SOFT_HLUTNM = "soft_lutpair119" *) 
  LUT3 #(
    .INIT(8'h01)) 
    remove_idle_i_4
       (.I0(wr_data[2]),
        .I1(wr_data[1]),
        .I2(wr_data[0]),
        .O(remove_idle_i_4_n_0));
  (* SOFT_HLUTNM = "soft_lutpair116" *) 
  LUT3 #(
    .INIT(8'h04)) 
    remove_idle_i_5
       (.I0(wr_data[17]),
        .I1(wr_data[18]),
        .I2(wr_data[16]),
        .O(remove_idle_i_5_n_0));
  FDRE remove_idle_reg
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(remove_idle_i_1_n_0),
        .Q(remove_idle),
        .R(reset_out));
  FDRE remove_idle_reg1_reg
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(remove_idle),
        .Q(remove_idle_reg1),
        .R(reset_out));
  FDRE remove_idle_reg2_reg
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(remove_idle_reg1),
        .Q(remove_idle_reg2),
        .R(reset_out));
  LUT3 #(
    .INIT(8'h3A)) 
    reset_modified_i_1
       (.I0(mgt_rx_reset),
        .I1(initialize_ram_complete_sync_ris_edg),
        .I2(reset_modified),
        .O(reset_modified_i_1_n_0));
  FDRE #(
    .INIT(1'b0)) 
    reset_modified_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(reset_modified_i_1_n_0),
        .Q(reset_modified),
        .R(1'b0));
  LUT2 #(
    .INIT(4'hE)) 
    rxbuferr_i_1
       (.I0(rxbuferr0),
        .I1(rxbufstatus),
        .O(rxbuferr_i_1_n_0));
  LUT6 #(
    .INIT(64'hE000000000000007)) 
    rxbuferr_i_2
       (.I0(rd_occupancy[0]),
        .I1(rd_occupancy[1]),
        .I2(rd_occupancy[5]),
        .I3(rd_occupancy[4]),
        .I4(rd_occupancy[3]),
        .I5(rd_occupancy[2]),
        .O(rxbuferr0));
  FDRE rxbuferr_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(rxbuferr_i_1_n_0),
        .Q(rxbufstatus),
        .R(reset_modified));
  (* SOFT_HLUTNM = "soft_lutpair123" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    rxchariscomma_usr_i_1
       (.I0(rd_data_reg[28]),
        .I1(even),
        .I2(rd_data_reg[12]),
        .O(rxchariscomma_usr_i_1_n_0));
  FDRE rxchariscomma_usr_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(rxchariscomma_usr_i_1_n_0),
        .Q(rxchariscomma),
        .R(reset_modified));
  (* SOFT_HLUTNM = "soft_lutpair123" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    rxcharisk_usr_i_1
       (.I0(rd_data_reg[27]),
        .I1(even),
        .I2(rd_data_reg[11]),
        .O(rxcharisk_usr_i_1_n_0));
  FDRE rxcharisk_usr_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(rxcharisk_usr_i_1_n_0),
        .Q(rxcharisk),
        .R(reset_modified));
  LUT3 #(
    .INIT(8'hAE)) 
    \rxclkcorcnt[0]_i_1 
       (.I0(insert_idle_reg__0),
        .I1(rd_data_reg[13]),
        .I2(rxclkcorcnt[0]),
        .O(\rxclkcorcnt[0]_i_1_n_0 ));
  LUT4 #(
    .INIT(16'h4404)) 
    \rxclkcorcnt[2]_i_1 
       (.I0(reset_modified),
        .I1(insert_idle_reg__0),
        .I2(rd_data_reg[13]),
        .I3(rxclkcorcnt[0]),
        .O(\rxclkcorcnt[2]_i_1_n_0 ));
  FDRE \rxclkcorcnt_reg[0] 
       (.C(userclk2),
        .CE(1'b1),
        .D(\rxclkcorcnt[0]_i_1_n_0 ),
        .Q(rxclkcorcnt[0]),
        .R(reset_modified));
  FDRE \rxclkcorcnt_reg[2] 
       (.C(userclk2),
        .CE(1'b1),
        .D(\rxclkcorcnt[2]_i_1_n_0 ),
        .Q(rxclkcorcnt[1]),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair129" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \rxdata_usr[0]_i_1 
       (.I0(rd_data_reg[16]),
        .I1(even),
        .I2(rd_data_reg[0]),
        .O(\rxdata_usr[0]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair129" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \rxdata_usr[1]_i_1 
       (.I0(rd_data_reg[17]),
        .I1(even),
        .I2(rd_data_reg[1]),
        .O(\rxdata_usr[1]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair128" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \rxdata_usr[2]_i_1 
       (.I0(rd_data_reg[18]),
        .I1(even),
        .I2(rd_data_reg[2]),
        .O(\rxdata_usr[2]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair128" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \rxdata_usr[3]_i_1 
       (.I0(rd_data_reg[19]),
        .I1(even),
        .I2(rd_data_reg[3]),
        .O(\rxdata_usr[3]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair127" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \rxdata_usr[4]_i_1 
       (.I0(rd_data_reg[20]),
        .I1(even),
        .I2(rd_data_reg[4]),
        .O(\rxdata_usr[4]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair127" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \rxdata_usr[5]_i_1 
       (.I0(rd_data_reg[21]),
        .I1(even),
        .I2(rd_data_reg[5]),
        .O(\rxdata_usr[5]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair126" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \rxdata_usr[6]_i_1 
       (.I0(rd_data_reg[22]),
        .I1(even),
        .I2(rd_data_reg[6]),
        .O(\rxdata_usr[6]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair126" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \rxdata_usr[7]_i_1 
       (.I0(rd_data_reg[23]),
        .I1(even),
        .I2(rd_data_reg[7]),
        .O(\rxdata_usr[7]_i_1_n_0 ));
  FDRE \rxdata_usr_reg[0] 
       (.C(userclk2),
        .CE(1'b1),
        .D(\rxdata_usr[0]_i_1_n_0 ),
        .Q(Q[0]),
        .R(reset_modified));
  FDRE \rxdata_usr_reg[1] 
       (.C(userclk2),
        .CE(1'b1),
        .D(\rxdata_usr[1]_i_1_n_0 ),
        .Q(Q[1]),
        .R(reset_modified));
  FDRE \rxdata_usr_reg[2] 
       (.C(userclk2),
        .CE(1'b1),
        .D(\rxdata_usr[2]_i_1_n_0 ),
        .Q(Q[2]),
        .R(reset_modified));
  FDRE \rxdata_usr_reg[3] 
       (.C(userclk2),
        .CE(1'b1),
        .D(\rxdata_usr[3]_i_1_n_0 ),
        .Q(Q[3]),
        .R(reset_modified));
  FDRE \rxdata_usr_reg[4] 
       (.C(userclk2),
        .CE(1'b1),
        .D(\rxdata_usr[4]_i_1_n_0 ),
        .Q(Q[4]),
        .R(reset_modified));
  FDRE \rxdata_usr_reg[5] 
       (.C(userclk2),
        .CE(1'b1),
        .D(\rxdata_usr[5]_i_1_n_0 ),
        .Q(Q[5]),
        .R(reset_modified));
  FDRE \rxdata_usr_reg[6] 
       (.C(userclk2),
        .CE(1'b1),
        .D(\rxdata_usr[6]_i_1_n_0 ),
        .Q(Q[6]),
        .R(reset_modified));
  FDRE \rxdata_usr_reg[7] 
       (.C(userclk2),
        .CE(1'b1),
        .D(\rxdata_usr[7]_i_1_n_0 ),
        .Q(Q[7]),
        .R(reset_modified));
  (* SOFT_HLUTNM = "soft_lutpair124" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    rxdisperr_usr_i_1
       (.I0(rd_data_reg[26]),
        .I1(even),
        .I2(rd_data_reg[10]),
        .O(rxdisperr_usr_i_1_n_0));
  FDRE rxdisperr_usr_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(rxdisperr_usr_i_1_n_0),
        .Q(rxdisperr),
        .R(reset_modified));
  (* SOFT_HLUTNM = "soft_lutpair124" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    rxnotintable_usr_i_1
       (.I0(rd_data_reg[25]),
        .I1(even),
        .I2(rd_data_reg[9]),
        .O(rxnotintable_usr_i_1_n_0));
  FDRE rxnotintable_usr_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(rxnotintable_usr_i_1_n_0),
        .Q(rxnotintable),
        .R(reset_modified));
  FDRE #(
    .INIT(1'b1)) 
    start_reg
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(1'b0),
        .Q(start),
        .R(1'b0));
  gmii_to_sgmii_bridge_sync_block_16 sync_initialize_ram_comp
       (.data_in(initialize_ram_complete),
        .data_out(initialize_ram_complete_sync),
        .initialize_ram_complete_sync_reg1(initialize_ram_complete_sync_reg1),
        .initialize_ram_complete_sync_ris_edg0(initialize_ram_complete_sync_ris_edg0),
        .userclk2(userclk2));
  (* SOFT_HLUTNM = "soft_lutpair121" *) 
  LUT4 #(
    .INIT(16'hFBF8)) 
    \wr_addr[5]_i_1 
       (.I0(wr_addr_plus1[5]),
        .I1(wr_enable),
        .I2(initialize_ram_complete_pulse),
        .I3(wr_addr[5]),
        .O(\wr_addr[5]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair133" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \wr_addr_gray[1]_i_1 
       (.I0(p_1_in4_in),
        .I1(p_2_in6_in),
        .O(bin_to_gray[1]));
  (* SOFT_HLUTNM = "soft_lutpair134" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \wr_addr_gray[2]_i_1 
       (.I0(p_2_in6_in),
        .I1(p_3_in8_in),
        .O(bin_to_gray[2]));
  (* SOFT_HLUTNM = "soft_lutpair134" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \wr_addr_gray[3]_i_1 
       (.I0(p_3_in8_in),
        .I1(p_4_in10_in),
        .O(bin_to_gray[3]));
  LUT2 #(
    .INIT(4'h6)) 
    \wr_addr_gray[4]_i_1 
       (.I0(p_4_in10_in),
        .I1(\wr_addr_plus2_reg_n_0_[5] ),
        .O(bin_to_gray[4]));
  FDSE \wr_addr_gray_reg[0] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(plusOp[1]),
        .Q(\wr_addr_gray_reg_n_0_[0] ),
        .S(reset_out));
  FDRE \wr_addr_gray_reg[1] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(bin_to_gray[1]),
        .Q(\wr_addr_gray_reg_n_0_[1] ),
        .R(reset_out));
  FDRE \wr_addr_gray_reg[2] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(bin_to_gray[2]),
        .Q(\wr_addr_gray_reg_n_0_[2] ),
        .R(reset_out));
  FDRE \wr_addr_gray_reg[3] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(bin_to_gray[3]),
        .Q(\wr_addr_gray_reg_n_0_[3] ),
        .R(reset_out));
  FDSE \wr_addr_gray_reg[4] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(bin_to_gray[4]),
        .Q(\wr_addr_gray_reg_n_0_[4] ),
        .S(reset_out));
  FDSE \wr_addr_gray_reg[5] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(\wr_addr_plus2_reg_n_0_[5] ),
        .Q(data_in),
        .S(reset_out));
  (* SOFT_HLUTNM = "soft_lutpair121" *) 
  LUT4 #(
    .INIT(16'hFBF8)) 
    \wr_addr_plus1[5]_i_1 
       (.I0(\wr_addr_plus2_reg_n_0_[5] ),
        .I1(wr_enable),
        .I2(initialize_ram_complete_pulse),
        .I3(wr_addr_plus1[5]),
        .O(\wr_addr_plus1[5]_i_1_n_0 ));
  FDSE \wr_addr_plus1_reg[0] 
       (.C(rxuserclk2),
        .CE(wr_enable),
        .D(\wr_addr_plus2_reg_n_0_[0] ),
        .Q(wr_addr_plus1[0]),
        .S(\wr_addr_plus1_reg[0]_0 ));
  FDRE \wr_addr_plus1_reg[1] 
       (.C(rxuserclk2),
        .CE(wr_enable),
        .D(p_1_in4_in),
        .Q(wr_addr_plus1[1]),
        .R(\wr_addr_plus1_reg[0]_0 ));
  FDRE \wr_addr_plus1_reg[2] 
       (.C(rxuserclk2),
        .CE(wr_enable),
        .D(p_2_in6_in),
        .Q(wr_addr_plus1[2]),
        .R(\wr_addr_plus1_reg[0]_0 ));
  FDRE \wr_addr_plus1_reg[3] 
       (.C(rxuserclk2),
        .CE(wr_enable),
        .D(p_3_in8_in),
        .Q(wr_addr_plus1[3]),
        .R(\wr_addr_plus1_reg[0]_0 ));
  FDRE \wr_addr_plus1_reg[4] 
       (.C(rxuserclk2),
        .CE(wr_enable),
        .D(p_4_in10_in),
        .Q(wr_addr_plus1[4]),
        .R(\wr_addr_plus1_reg[0]_0 ));
  FDRE \wr_addr_plus1_reg[5] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(\wr_addr_plus1[5]_i_1_n_0 ),
        .Q(wr_addr_plus1[5]),
        .R(reset_out));
  LUT1 #(
    .INIT(2'h1)) 
    \wr_addr_plus2[0]_i_1 
       (.I0(\wr_addr_plus2_reg_n_0_[0] ),
        .O(plusOp[0]));
  (* SOFT_HLUTNM = "soft_lutpair133" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \wr_addr_plus2[1]_i_1 
       (.I0(\wr_addr_plus2_reg_n_0_[0] ),
        .I1(p_1_in4_in),
        .O(plusOp[1]));
  (* SOFT_HLUTNM = "soft_lutpair122" *) 
  LUT3 #(
    .INIT(8'h78)) 
    \wr_addr_plus2[2]_i_1 
       (.I0(\wr_addr_plus2_reg_n_0_[0] ),
        .I1(p_1_in4_in),
        .I2(p_2_in6_in),
        .O(plusOp[2]));
  (* SOFT_HLUTNM = "soft_lutpair122" *) 
  LUT4 #(
    .INIT(16'h7F80)) 
    \wr_addr_plus2[3]_i_1 
       (.I0(p_1_in4_in),
        .I1(\wr_addr_plus2_reg_n_0_[0] ),
        .I2(p_2_in6_in),
        .I3(p_3_in8_in),
        .O(plusOp[3]));
  (* SOFT_HLUTNM = "soft_lutpair114" *) 
  LUT5 #(
    .INIT(32'h7FFF8000)) 
    \wr_addr_plus2[4]_i_1 
       (.I0(p_2_in6_in),
        .I1(\wr_addr_plus2_reg_n_0_[0] ),
        .I2(p_1_in4_in),
        .I3(p_3_in8_in),
        .I4(p_4_in10_in),
        .O(plusOp[4]));
  LUT5 #(
    .INIT(32'hFF7FFF80)) 
    \wr_addr_plus2[5]_i_1 
       (.I0(p_4_in10_in),
        .I1(\wr_addr_plus2[5]_i_2_n_0 ),
        .I2(wr_enable),
        .I3(initialize_ram_complete_pulse),
        .I4(\wr_addr_plus2_reg_n_0_[5] ),
        .O(\wr_addr_plus2[5]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair114" *) 
  LUT4 #(
    .INIT(16'h8000)) 
    \wr_addr_plus2[5]_i_2 
       (.I0(p_3_in8_in),
        .I1(p_1_in4_in),
        .I2(\wr_addr_plus2_reg_n_0_[0] ),
        .I3(p_2_in6_in),
        .O(\wr_addr_plus2[5]_i_2_n_0 ));
  FDRE \wr_addr_plus2_reg[0] 
       (.C(rxuserclk2),
        .CE(wr_enable),
        .D(plusOp[0]),
        .Q(\wr_addr_plus2_reg_n_0_[0] ),
        .R(\wr_addr_plus1_reg[0]_0 ));
  FDSE \wr_addr_plus2_reg[1] 
       (.C(rxuserclk2),
        .CE(wr_enable),
        .D(plusOp[1]),
        .Q(p_1_in4_in),
        .S(\wr_addr_plus1_reg[0]_0 ));
  FDRE \wr_addr_plus2_reg[2] 
       (.C(rxuserclk2),
        .CE(wr_enable),
        .D(plusOp[2]),
        .Q(p_2_in6_in),
        .R(\wr_addr_plus1_reg[0]_0 ));
  FDRE \wr_addr_plus2_reg[3] 
       (.C(rxuserclk2),
        .CE(wr_enable),
        .D(plusOp[3]),
        .Q(p_3_in8_in),
        .R(\wr_addr_plus1_reg[0]_0 ));
  FDRE \wr_addr_plus2_reg[4] 
       (.C(rxuserclk2),
        .CE(wr_enable),
        .D(plusOp[4]),
        .Q(p_4_in10_in),
        .R(\wr_addr_plus1_reg[0]_0 ));
  FDRE \wr_addr_plus2_reg[5] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(\wr_addr_plus2[5]_i_1_n_0 ),
        .Q(\wr_addr_plus2_reg_n_0_[5] ),
        .R(reset_out));
  FDRE \wr_addr_reg[0] 
       (.C(rxuserclk2),
        .CE(wr_enable),
        .D(wr_addr_plus1[0]),
        .Q(wr_addr[0]),
        .R(\wr_addr_plus1_reg[0]_0 ));
  FDRE \wr_addr_reg[1] 
       (.C(rxuserclk2),
        .CE(wr_enable),
        .D(wr_addr_plus1[1]),
        .Q(wr_addr[1]),
        .R(\wr_addr_plus1_reg[0]_0 ));
  FDRE \wr_addr_reg[2] 
       (.C(rxuserclk2),
        .CE(wr_enable),
        .D(wr_addr_plus1[2]),
        .Q(wr_addr[2]),
        .R(\wr_addr_plus1_reg[0]_0 ));
  FDRE \wr_addr_reg[3] 
       (.C(rxuserclk2),
        .CE(wr_enable),
        .D(wr_addr_plus1[3]),
        .Q(wr_addr[3]),
        .R(\wr_addr_plus1_reg[0]_0 ));
  FDRE \wr_addr_reg[4] 
       (.C(rxuserclk2),
        .CE(wr_enable),
        .D(wr_addr_plus1[4]),
        .Q(wr_addr[4]),
        .R(\wr_addr_plus1_reg[0]_0 ));
  FDRE \wr_addr_reg[5] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(\wr_addr[5]_i_1_n_0 ),
        .Q(wr_addr[5]),
        .R(reset_out));
  FDRE \wr_data_reg[0] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(D[0]),
        .Q(wr_data[0]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg[10] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(D[9]),
        .Q(wr_data[10]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg[11] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(D[10]),
        .Q(wr_data[11]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg[12] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(D[11]),
        .Q(wr_data[12]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg[16] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(D[12]),
        .Q(wr_data[16]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg[17] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(D[13]),
        .Q(wr_data[17]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg[18] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(D[14]),
        .Q(wr_data[18]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg[19] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(D[15]),
        .Q(wr_data[19]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg[1] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(D[1]),
        .Q(wr_data[1]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg[20] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(D[16]),
        .Q(wr_data[20]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg[21] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(D[17]),
        .Q(wr_data[21]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg[22] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(D[18]),
        .Q(wr_data[22]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg[23] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(D[19]),
        .Q(wr_data[23]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg[25] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(D[20]),
        .Q(wr_data[25]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg[26] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(D[21]),
        .Q(wr_data[26]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg[27] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(D[22]),
        .Q(wr_data[27]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg[28] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(D[23]),
        .Q(wr_data[28]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg[2] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(D[2]),
        .Q(wr_data[2]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg[3] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(D[3]),
        .Q(wr_data[3]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg[4] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(D[4]),
        .Q(wr_data[4]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg[5] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(D[5]),
        .Q(wr_data[5]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg[6] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(D[6]),
        .Q(wr_data[6]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg[7] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(D[7]),
        .Q(wr_data[7]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg[9] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(D[8]),
        .Q(wr_data[9]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg_reg[0] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_data[0]),
        .Q(wr_data_reg[0]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg_reg[10] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_data[10]),
        .Q(wr_data_reg[10]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg_reg[11] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_data[11]),
        .Q(wr_data_reg[11]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg_reg[12] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_data[12]),
        .Q(wr_data_reg[12]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg_reg[13] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(remove_idle),
        .Q(wr_data_reg[13]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg_reg[16] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_data[16]),
        .Q(wr_data_reg[16]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg_reg[17] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_data[17]),
        .Q(wr_data_reg[17]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg_reg[18] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_data[18]),
        .Q(wr_data_reg[18]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg_reg[19] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_data[19]),
        .Q(wr_data_reg[19]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg_reg[1] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_data[1]),
        .Q(wr_data_reg[1]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg_reg[20] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_data[20]),
        .Q(wr_data_reg[20]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg_reg[21] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_data[21]),
        .Q(wr_data_reg[21]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg_reg[22] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_data[22]),
        .Q(wr_data_reg[22]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg_reg[23] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_data[23]),
        .Q(wr_data_reg[23]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg_reg[25] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_data[25]),
        .Q(wr_data_reg[25]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg_reg[26] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_data[26]),
        .Q(wr_data_reg[26]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg_reg[27] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_data[27]),
        .Q(wr_data_reg[27]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg_reg[28] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_data[28]),
        .Q(wr_data_reg[28]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg_reg[2] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_data[2]),
        .Q(wr_data_reg[2]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg_reg[3] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_data[3]),
        .Q(wr_data_reg[3]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg_reg[4] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_data[4]),
        .Q(wr_data_reg[4]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg_reg[5] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_data[5]),
        .Q(wr_data_reg[5]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg_reg[6] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_data[6]),
        .Q(wr_data_reg[6]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg_reg[7] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_data[7]),
        .Q(wr_data_reg[7]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_data_reg_reg[9] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_data[9]),
        .Q(wr_data_reg[9]),
        .R(\wr_data_reg_reg[0]_0 ));
  LUT6 #(
    .INIT(64'h0F0FFFDFFFFFFFFF)) 
    wr_enable_i_1
       (.I0(wr_enable_i_2_n_0),
        .I1(wr_enable_i_3_n_0),
        .I2(p_18_in),
        .I3(wr_enable_i_4_n_0),
        .I4(wr_enable_i_5_n_0),
        .I5(initialize_ram_complete),
        .O(wr_enable_i_1_n_0));
  LUT5 #(
    .INIT(32'h00200000)) 
    wr_enable_i_2
       (.I0(wr_occupancy[4]),
        .I1(remove_idle_reg2),
        .I2(wr_occupancy[5]),
        .I3(remove_idle_reg1),
        .I4(wr_enable_i_6_n_0),
        .O(wr_enable_i_2_n_0));
  LUT2 #(
    .INIT(4'h1)) 
    wr_enable_i_3
       (.I0(d21p5_wr_reg2),
        .I1(d2p2_wr_reg2),
        .O(wr_enable_i_3_n_0));
  LUT6 #(
    .INIT(64'hFFFABFFFFFFFBFFF)) 
    wr_enable_i_4
       (.I0(wr_enable_i_7_n_0),
        .I1(d21p5_wr_reg_i_2_n_0),
        .I2(wr_data[0]),
        .I3(wr_data[2]),
        .I4(wr_data[1]),
        .I5(d2p2_wr_reg_i_2_n_0),
        .O(wr_enable_i_4_n_0));
  LUT6 #(
    .INIT(64'h0000000800000000)) 
    wr_enable_i_5
       (.I0(wr_enable_i_8_n_0),
        .I1(wr_enable_i_9_n_0),
        .I2(wr_data[2]),
        .I3(wr_data[1]),
        .I4(wr_data[0]),
        .I5(d16p2_wr_reg_i_2_n_0),
        .O(wr_enable_i_5_n_0));
  (* SOFT_HLUTNM = "soft_lutpair117" *) 
  LUT4 #(
    .INIT(16'hFFFE)) 
    wr_enable_i_6
       (.I0(wr_occupancy[0]),
        .I1(wr_occupancy[3]),
        .I2(wr_occupancy[2]),
        .I3(wr_occupancy[1]),
        .O(wr_enable_i_6_n_0));
  (* SOFT_HLUTNM = "soft_lutpair118" *) 
  LUT2 #(
    .INIT(4'hB)) 
    wr_enable_i_7
       (.I0(remove_idle),
        .I1(k28p5_wr_reg2),
        .O(wr_enable_i_7_n_0));
  (* SOFT_HLUTNM = "soft_lutpair117" *) 
  LUT4 #(
    .INIT(16'hFFFE)) 
    wr_enable_i_8
       (.I0(wr_occupancy[2]),
        .I1(wr_occupancy[1]),
        .I2(wr_occupancy[4]),
        .I3(wr_occupancy[3]),
        .O(wr_enable_i_8_n_0));
  (* SOFT_HLUTNM = "soft_lutpair118" *) 
  LUT4 #(
    .INIT(16'h0800)) 
    wr_enable_i_9
       (.I0(d16p2_wr_reg),
        .I1(wr_occupancy[5]),
        .I2(remove_idle),
        .I3(k28p5_wr_reg),
        .O(wr_enable_i_9_n_0));
  FDRE wr_enable_reg
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_enable_i_1_n_0),
        .Q(wr_enable),
        .R(reset_out));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY4 wr_occupancy0_carry
       (.CI(1'b0),
        .CO({wr_occupancy0_carry_n_0,wr_occupancy0_carry_n_1,wr_occupancy0_carry_n_2,wr_occupancy0_carry_n_3}),
        .CYINIT(1'b1),
        .DI(wr_addr[3:0]),
        .O(wr_occupancy00_out[3:0]),
        .S({\reclock_rd_addrgray[4].sync_rd_addrgray_n_0 ,\reclock_rd_addrgray[3].sync_rd_addrgray_n_0 ,\reclock_rd_addrgray[2].sync_rd_addrgray_n_0 ,\reclock_rd_addrgray[1].sync_rd_addrgray_n_0 }));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY4 wr_occupancy0_carry__0
       (.CI(wr_occupancy0_carry_n_0),
        .CO({NLW_wr_occupancy0_carry__0_CO_UNCONNECTED[3:1],wr_occupancy0_carry__0_n_3}),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,wr_addr[4]}),
        .O({NLW_wr_occupancy0_carry__0_O_UNCONNECTED[3:2],wr_occupancy00_out[5:4]}),
        .S({1'b0,1'b0,\reclock_rd_addrgray[5].sync_rd_addrgray_n_0 ,\reclock_rd_addrgray[5].sync_rd_addrgray_n_1 }));
  FDRE \wr_occupancy_reg[0] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_occupancy00_out[0]),
        .Q(wr_occupancy[0]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_occupancy_reg[1] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_occupancy00_out[1]),
        .Q(wr_occupancy[1]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_occupancy_reg[2] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_occupancy00_out[2]),
        .Q(wr_occupancy[2]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_occupancy_reg[3] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_occupancy00_out[3]),
        .Q(wr_occupancy[3]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDRE \wr_occupancy_reg[4] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_occupancy00_out[4]),
        .Q(wr_occupancy[4]),
        .R(\wr_data_reg_reg[0]_0 ));
  FDSE \wr_occupancy_reg[5] 
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(wr_occupancy00_out[5]),
        .Q(wr_occupancy[5]),
        .S(\wr_data_reg_reg[0]_0 ));
endmodule

module gmii_to_sgmii_bridge_rx_rate_adapt
   (gmii_rx_dv_out_reg_0,
    gmii_rx_er_out_reg_0,
    gmii_rxd,
    reset_out,
    rx_er_aligned_reg_0,
    gmii_rx_dv,
    userclk2,
    gmii_rx_er,
    D);
  output gmii_rx_dv_out_reg_0;
  output gmii_rx_er_out_reg_0;
  output [7:0]gmii_rxd;
  input reset_out;
  input rx_er_aligned_reg_0;
  input gmii_rx_dv;
  input userclk2;
  input gmii_rx_er;
  input [7:0]D;

  wire [7:0]D;
  wire gmii_rx_dv;
  wire gmii_rx_dv_out_reg_0;
  wire gmii_rx_er;
  wire gmii_rx_er_out_reg_0;
  wire [7:0]gmii_rxd;
  wire muxsel;
  wire muxsel_i_1_n_0;
  wire [3:0]p_0_in;
  wire reset_out;
  wire rx_dv_aligned;
  wire rx_dv_aligned_i_1_n_0;
  wire rx_dv_reg1;
  wire rx_dv_reg2;
  wire rx_er_aligned;
  wire rx_er_aligned_0;
  wire rx_er_aligned_reg_0;
  wire rx_er_reg1;
  wire rx_er_reg2;
  wire [7:0]rxd_aligned;
  wire \rxd_aligned[0]_i_1_n_0 ;
  wire \rxd_aligned[1]_i_1_n_0 ;
  wire \rxd_aligned[2]_i_1_n_0 ;
  wire \rxd_aligned[3]_i_1_n_0 ;
  wire \rxd_aligned[4]_i_1_n_0 ;
  wire \rxd_aligned[5]_i_1_n_0 ;
  wire \rxd_aligned[6]_i_1_n_0 ;
  wire \rxd_aligned[7]_i_1_n_0 ;
  wire \rxd_reg1_reg_n_0_[0] ;
  wire \rxd_reg1_reg_n_0_[1] ;
  wire \rxd_reg1_reg_n_0_[2] ;
  wire \rxd_reg1_reg_n_0_[3] ;
  wire [7:0]rxd_reg2;
  wire sfd_enable;
  wire sfd_enable0;
  wire sfd_enable_i_1_n_0;
  wire sfd_enable_i_2_n_0;
  wire sfd_enable_i_4_n_0;
  wire sfd_enable_i_5_n_0;
  wire userclk2;

  FDRE #(
    .INIT(1'b0)) 
    gmii_rx_dv_out_reg
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(rx_dv_aligned),
        .Q(gmii_rx_dv_out_reg_0),
        .R(reset_out));
  FDRE #(
    .INIT(1'b0)) 
    gmii_rx_er_out_reg
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(rx_er_aligned),
        .Q(gmii_rx_er_out_reg_0),
        .R(reset_out));
  FDRE #(
    .INIT(1'b0)) 
    \gmii_rxd_out_reg[0] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(rxd_aligned[0]),
        .Q(gmii_rxd[0]),
        .R(reset_out));
  FDRE #(
    .INIT(1'b0)) 
    \gmii_rxd_out_reg[1] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(rxd_aligned[1]),
        .Q(gmii_rxd[1]),
        .R(reset_out));
  FDRE #(
    .INIT(1'b0)) 
    \gmii_rxd_out_reg[2] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(rxd_aligned[2]),
        .Q(gmii_rxd[2]),
        .R(reset_out));
  FDRE #(
    .INIT(1'b0)) 
    \gmii_rxd_out_reg[3] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(rxd_aligned[3]),
        .Q(gmii_rxd[3]),
        .R(reset_out));
  FDRE #(
    .INIT(1'b0)) 
    \gmii_rxd_out_reg[4] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(rxd_aligned[4]),
        .Q(gmii_rxd[4]),
        .R(reset_out));
  FDRE #(
    .INIT(1'b0)) 
    \gmii_rxd_out_reg[5] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(rxd_aligned[5]),
        .Q(gmii_rxd[5]),
        .R(reset_out));
  FDRE #(
    .INIT(1'b0)) 
    \gmii_rxd_out_reg[6] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(rxd_aligned[6]),
        .Q(gmii_rxd[6]),
        .R(reset_out));
  FDRE #(
    .INIT(1'b0)) 
    \gmii_rxd_out_reg[7] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(rxd_aligned[7]),
        .Q(gmii_rxd[7]),
        .R(reset_out));
  LUT6 #(
    .INIT(64'h00000000CCCCA8CC)) 
    muxsel_i_1
       (.I0(sfd_enable_i_5_n_0),
        .I1(muxsel),
        .I2(sfd_enable_i_2_n_0),
        .I3(sfd_enable),
        .I4(sfd_enable_i_4_n_0),
        .I5(reset_out),
        .O(muxsel_i_1_n_0));
  FDRE muxsel_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(muxsel_i_1_n_0),
        .Q(muxsel),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair72" *) 
  LUT3 #(
    .INIT(8'hB0)) 
    rx_dv_aligned_i_1
       (.I0(rx_dv_reg1),
        .I1(muxsel),
        .I2(rx_dv_reg2),
        .O(rx_dv_aligned_i_1_n_0));
  FDRE rx_dv_aligned_reg
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(rx_dv_aligned_i_1_n_0),
        .Q(rx_dv_aligned),
        .R(reset_out));
  FDRE rx_dv_reg1_reg
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(gmii_rx_dv),
        .Q(rx_dv_reg1),
        .R(reset_out));
  FDRE rx_dv_reg2_reg
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(rx_dv_reg1),
        .Q(rx_dv_reg2),
        .R(reset_out));
  (* SOFT_HLUTNM = "soft_lutpair73" *) 
  LUT3 #(
    .INIT(8'hF8)) 
    rx_er_aligned_i_1
       (.I0(muxsel),
        .I1(rx_er_reg1),
        .I2(rx_er_reg2),
        .O(rx_er_aligned_0));
  FDRE rx_er_aligned_reg
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(rx_er_aligned_0),
        .Q(rx_er_aligned),
        .R(reset_out));
  FDRE rx_er_reg1_reg
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(gmii_rx_er),
        .Q(rx_er_reg1),
        .R(reset_out));
  FDRE rx_er_reg2_reg
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(rx_er_reg1),
        .Q(rx_er_reg2),
        .R(reset_out));
  (* SOFT_HLUTNM = "soft_lutpair76" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \rxd_aligned[0]_i_1 
       (.I0(rxd_reg2[4]),
        .I1(muxsel),
        .I2(rxd_reg2[0]),
        .O(\rxd_aligned[0]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair75" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \rxd_aligned[1]_i_1 
       (.I0(rxd_reg2[5]),
        .I1(muxsel),
        .I2(rxd_reg2[1]),
        .O(\rxd_aligned[1]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair74" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \rxd_aligned[2]_i_1 
       (.I0(rxd_reg2[6]),
        .I1(muxsel),
        .I2(rxd_reg2[2]),
        .O(\rxd_aligned[2]_i_1_n_0 ));
  LUT3 #(
    .INIT(8'hB8)) 
    \rxd_aligned[3]_i_1 
       (.I0(rxd_reg2[7]),
        .I1(muxsel),
        .I2(rxd_reg2[3]),
        .O(\rxd_aligned[3]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair76" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \rxd_aligned[4]_i_1 
       (.I0(\rxd_reg1_reg_n_0_[0] ),
        .I1(muxsel),
        .I2(rxd_reg2[4]),
        .O(\rxd_aligned[4]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair75" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \rxd_aligned[5]_i_1 
       (.I0(\rxd_reg1_reg_n_0_[1] ),
        .I1(muxsel),
        .I2(rxd_reg2[5]),
        .O(\rxd_aligned[5]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair74" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \rxd_aligned[6]_i_1 
       (.I0(\rxd_reg1_reg_n_0_[2] ),
        .I1(muxsel),
        .I2(rxd_reg2[6]),
        .O(\rxd_aligned[6]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair73" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \rxd_aligned[7]_i_1 
       (.I0(\rxd_reg1_reg_n_0_[3] ),
        .I1(muxsel),
        .I2(rxd_reg2[7]),
        .O(\rxd_aligned[7]_i_1_n_0 ));
  FDRE \rxd_aligned_reg[0] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(\rxd_aligned[0]_i_1_n_0 ),
        .Q(rxd_aligned[0]),
        .R(reset_out));
  FDRE \rxd_aligned_reg[1] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(\rxd_aligned[1]_i_1_n_0 ),
        .Q(rxd_aligned[1]),
        .R(reset_out));
  FDRE \rxd_aligned_reg[2] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(\rxd_aligned[2]_i_1_n_0 ),
        .Q(rxd_aligned[2]),
        .R(reset_out));
  FDRE \rxd_aligned_reg[3] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(\rxd_aligned[3]_i_1_n_0 ),
        .Q(rxd_aligned[3]),
        .R(reset_out));
  FDRE \rxd_aligned_reg[4] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(\rxd_aligned[4]_i_1_n_0 ),
        .Q(rxd_aligned[4]),
        .R(reset_out));
  FDRE \rxd_aligned_reg[5] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(\rxd_aligned[5]_i_1_n_0 ),
        .Q(rxd_aligned[5]),
        .R(reset_out));
  FDRE \rxd_aligned_reg[6] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(\rxd_aligned[6]_i_1_n_0 ),
        .Q(rxd_aligned[6]),
        .R(reset_out));
  FDRE \rxd_aligned_reg[7] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(\rxd_aligned[7]_i_1_n_0 ),
        .Q(rxd_aligned[7]),
        .R(reset_out));
  FDRE \rxd_reg1_reg[0] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(D[0]),
        .Q(\rxd_reg1_reg_n_0_[0] ),
        .R(reset_out));
  FDRE \rxd_reg1_reg[1] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(D[1]),
        .Q(\rxd_reg1_reg_n_0_[1] ),
        .R(reset_out));
  FDRE \rxd_reg1_reg[2] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(D[2]),
        .Q(\rxd_reg1_reg_n_0_[2] ),
        .R(reset_out));
  FDRE \rxd_reg1_reg[3] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(D[3]),
        .Q(\rxd_reg1_reg_n_0_[3] ),
        .R(reset_out));
  FDRE \rxd_reg1_reg[4] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(D[4]),
        .Q(p_0_in[0]),
        .R(reset_out));
  FDRE \rxd_reg1_reg[5] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(D[5]),
        .Q(p_0_in[1]),
        .R(reset_out));
  FDRE \rxd_reg1_reg[6] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(D[6]),
        .Q(p_0_in[2]),
        .R(reset_out));
  FDRE \rxd_reg1_reg[7] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(D[7]),
        .Q(p_0_in[3]),
        .R(reset_out));
  FDRE \rxd_reg2_reg[0] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(\rxd_reg1_reg_n_0_[0] ),
        .Q(rxd_reg2[0]),
        .R(reset_out));
  FDRE \rxd_reg2_reg[1] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(\rxd_reg1_reg_n_0_[1] ),
        .Q(rxd_reg2[1]),
        .R(reset_out));
  FDRE \rxd_reg2_reg[2] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(\rxd_reg1_reg_n_0_[2] ),
        .Q(rxd_reg2[2]),
        .R(reset_out));
  FDRE \rxd_reg2_reg[3] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(\rxd_reg1_reg_n_0_[3] ),
        .Q(rxd_reg2[3]),
        .R(reset_out));
  FDRE \rxd_reg2_reg[4] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(p_0_in[0]),
        .Q(rxd_reg2[4]),
        .R(reset_out));
  FDRE \rxd_reg2_reg[5] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(p_0_in[1]),
        .Q(rxd_reg2[5]),
        .R(reset_out));
  FDRE \rxd_reg2_reg[6] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(p_0_in[2]),
        .Q(rxd_reg2[6]),
        .R(reset_out));
  FDRE \rxd_reg2_reg[7] 
       (.C(userclk2),
        .CE(rx_er_aligned_reg_0),
        .D(p_0_in[3]),
        .Q(rxd_reg2[7]),
        .R(reset_out));
  LUT6 #(
    .INIT(64'hFFDDFFCCC0C8C0CC)) 
    sfd_enable_i_1
       (.I0(sfd_enable_i_2_n_0),
        .I1(sfd_enable0),
        .I2(rx_er_aligned_reg_0),
        .I3(sfd_enable_i_4_n_0),
        .I4(sfd_enable_i_5_n_0),
        .I5(sfd_enable),
        .O(sfd_enable_i_1_n_0));
  LUT5 #(
    .INIT(32'h04000000)) 
    sfd_enable_i_2
       (.I0(p_0_in[3]),
        .I1(D[0]),
        .I2(D[1]),
        .I3(D[3]),
        .I4(D[2]),
        .O(sfd_enable_i_2_n_0));
  (* SOFT_HLUTNM = "soft_lutpair72" *) 
  LUT2 #(
    .INIT(4'h2)) 
    sfd_enable_i_3
       (.I0(gmii_rx_dv),
        .I1(rx_dv_reg1),
        .O(sfd_enable0));
  LUT4 #(
    .INIT(16'hDFFF)) 
    sfd_enable_i_4
       (.I0(p_0_in[0]),
        .I1(p_0_in[1]),
        .I2(rx_er_aligned_reg_0),
        .I3(p_0_in[2]),
        .O(sfd_enable_i_4_n_0));
  LUT5 #(
    .INIT(32'hFFFFDFFF)) 
    sfd_enable_i_5
       (.I0(\rxd_reg1_reg_n_0_[0] ),
        .I1(\rxd_reg1_reg_n_0_[3] ),
        .I2(p_0_in[3]),
        .I3(\rxd_reg1_reg_n_0_[2] ),
        .I4(\rxd_reg1_reg_n_0_[1] ),
        .O(sfd_enable_i_5_n_0));
  FDRE sfd_enable_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(sfd_enable_i_1_n_0),
        .Q(sfd_enable),
        .R(reset_out));
endmodule

module gmii_to_sgmii_bridge_sgmii_adapt
   (sgmii_clk_r,
    sgmii_clk_en_reg,
    gmii_rx_dv_out_reg,
    gmii_rx_er_out_reg,
    gmii_tx_en,
    gmii_tx_er,
    sgmii_clk_f,
    gmii_rxd,
    Q,
    userclk2,
    gmii_rx_dv,
    gmii_rx_er,
    gmii_tx_en_out_reg,
    gmii_tx_er_out_reg,
    SR,
    speed_is_10_100,
    speed_is_100,
    D,
    gmii_txd);
  output sgmii_clk_r;
  output sgmii_clk_en_reg;
  output gmii_rx_dv_out_reg;
  output gmii_rx_er_out_reg;
  output gmii_tx_en;
  output gmii_tx_er;
  output sgmii_clk_f;
  output [7:0]gmii_rxd;
  output [7:0]Q;
  input userclk2;
  input gmii_rx_dv;
  input gmii_rx_er;
  input gmii_tx_en_out_reg;
  input gmii_tx_er_out_reg;
  input [0:0]SR;
  input speed_is_10_100;
  input speed_is_100;
  input [7:0]D;
  input [7:0]gmii_txd;

  wire [7:0]D;
  wire [7:0]Q;
  wire [0:0]SR;
  wire gmii_rx_dv;
  wire gmii_rx_dv_out_reg;
  wire gmii_rx_er;
  wire gmii_rx_er_out_reg;
  wire [7:0]gmii_rxd;
  wire gmii_tx_en;
  wire gmii_tx_en_out_reg;
  wire gmii_tx_er;
  wire gmii_tx_er_out_reg;
  wire [7:0]gmii_txd;
  wire sgmii_clk_en_reg;
  wire sgmii_clk_f;
  wire sgmii_clk_r;
  wire speed_is_100;
  wire speed_is_100_resync;
  wire speed_is_10_100;
  wire speed_is_10_100_resync;
  wire sync_reset;
  wire userclk2;

  gmii_to_sgmii_bridge_clk_gen clock_generation
       (.data_out(speed_is_100_resync),
        .reset_out(sync_reset),
        .sgmii_clk_en_reg_0(sgmii_clk_en_reg),
        .sgmii_clk_f(sgmii_clk_f),
        .sgmii_clk_r(sgmii_clk_r),
        .speed_is_10_100_fall_reg_0(speed_is_10_100_resync),
        .userclk2(userclk2));
  gmii_to_sgmii_bridge_reset_sync_30 gen_sync_reset
       (.SR(SR),
        .reset_out(sync_reset),
        .userclk2(userclk2));
  gmii_to_sgmii_bridge_rx_rate_adapt receiver
       (.D(D),
        .gmii_rx_dv(gmii_rx_dv),
        .gmii_rx_dv_out_reg_0(gmii_rx_dv_out_reg),
        .gmii_rx_er(gmii_rx_er),
        .gmii_rx_er_out_reg_0(gmii_rx_er_out_reg),
        .gmii_rxd(gmii_rxd),
        .reset_out(sync_reset),
        .rx_er_aligned_reg_0(sgmii_clk_en_reg),
        .userclk2(userclk2));
  gmii_to_sgmii_bridge_sync_block_31 resync_speed_100
       (.data_out(speed_is_100_resync),
        .speed_is_100(speed_is_100),
        .userclk2(userclk2));
  gmii_to_sgmii_bridge_sync_block_32 resync_speed_10_100
       (.data_out(speed_is_10_100_resync),
        .speed_is_10_100(speed_is_10_100),
        .userclk2(userclk2));
  gmii_to_sgmii_bridge_tx_rate_adapt transmitter
       (.E(sgmii_clk_en_reg),
        .Q(Q),
        .gmii_tx_en(gmii_tx_en),
        .gmii_tx_en_out_reg_0(gmii_tx_en_out_reg),
        .gmii_tx_er(gmii_tx_er),
        .gmii_tx_er_out_reg_0(gmii_tx_er_out_reg),
        .gmii_txd(gmii_txd),
        .reset_out(sync_reset),
        .userclk2(userclk2));
endmodule

module gmii_to_sgmii_bridge_sync_block
   (data_out,
    Q,
    rxuserclk2);
  output data_out;
  input [0:0]Q;
  input rxuserclk2;

  wire [0:0]Q;
  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire rxuserclk2;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(Q),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block_10
   (data_out,
    Q,
    userclk2);
  output data_out;
  input [0:0]Q;
  input userclk2;

  wire [0:0]Q;
  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire userclk2;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(userclk2),
        .CE(1'b1),
        .D(Q),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block_11
   (S,
    data_sync_reg6_0,
    DI,
    data_out,
    Q,
    data_sync_reg1_0,
    userclk2);
  output [0:0]S;
  output data_sync_reg6_0;
  input [0:0]DI;
  input data_out;
  input [0:0]Q;
  input [0:0]data_sync_reg1_0;
  input userclk2;

  wire [0:0]DI;
  wire [0:0]Q;
  wire [0:0]S;
  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire [0:0]data_sync_reg1_0;
  wire data_sync_reg6_0;
  wire userclk2;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync_reg1_0),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_sync_reg6_0),
        .R(1'b0));
  LUT3 #(
    .INIT(8'h69)) 
    rd_occupancy0_carry_i_8
       (.I0(DI),
        .I1(data_out),
        .I2(Q),
        .O(S));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block_12
   (S,
    data_out,
    \rd_occupancy_reg[3] ,
    \rd_occupancy_reg[3]_0 ,
    \rd_occupancy_reg[3]_1 ,
    \rd_occupancy_reg[3]_2 ,
    Q,
    data_sync_reg1_0,
    userclk2);
  output [0:0]S;
  output data_out;
  input \rd_occupancy_reg[3] ;
  input \rd_occupancy_reg[3]_0 ;
  input \rd_occupancy_reg[3]_1 ;
  input \rd_occupancy_reg[3]_2 ;
  input [0:0]Q;
  input [0:0]data_sync_reg1_0;
  input userclk2;

  wire [0:0]Q;
  wire [0:0]S;
  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire [0:0]data_sync_reg1_0;
  wire \rd_occupancy_reg[3] ;
  wire \rd_occupancy_reg[3]_0 ;
  wire \rd_occupancy_reg[3]_1 ;
  wire \rd_occupancy_reg[3]_2 ;
  wire userclk2;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync_reg1_0),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
  LUT6 #(
    .INIT(64'h9669699669969669)) 
    rd_occupancy0_carry_i_7
       (.I0(data_out),
        .I1(\rd_occupancy_reg[3] ),
        .I2(\rd_occupancy_reg[3]_0 ),
        .I3(\rd_occupancy_reg[3]_1 ),
        .I4(\rd_occupancy_reg[3]_2 ),
        .I5(Q),
        .O(S));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block_13
   (S,
    data_out,
    \rd_occupancy_reg[3] ,
    \rd_occupancy_reg[3]_0 ,
    \rd_occupancy_reg[3]_1 ,
    Q,
    data_sync_reg1_0,
    userclk2);
  output [0:0]S;
  output data_out;
  input \rd_occupancy_reg[3] ;
  input \rd_occupancy_reg[3]_0 ;
  input \rd_occupancy_reg[3]_1 ;
  input [0:0]Q;
  input [0:0]data_sync_reg1_0;
  input userclk2;

  wire [0:0]Q;
  wire [0:0]S;
  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire [0:0]data_sync_reg1_0;
  wire \rd_occupancy_reg[3] ;
  wire \rd_occupancy_reg[3]_0 ;
  wire \rd_occupancy_reg[3]_1 ;
  wire userclk2;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync_reg1_0),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
  LUT5 #(
    .INIT(32'h69969669)) 
    rd_occupancy0_carry_i_6
       (.I0(data_out),
        .I1(\rd_occupancy_reg[3] ),
        .I2(\rd_occupancy_reg[3]_0 ),
        .I3(\rd_occupancy_reg[3]_1 ),
        .I4(Q),
        .O(S));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block_14
   (S,
    data_out,
    \rd_occupancy_reg[3] ,
    \rd_occupancy_reg[3]_0 ,
    Q,
    data_sync_reg1_0,
    userclk2);
  output [0:0]S;
  output data_out;
  input \rd_occupancy_reg[3] ;
  input \rd_occupancy_reg[3]_0 ;
  input [0:0]Q;
  input [0:0]data_sync_reg1_0;
  input userclk2;

  wire [0:0]Q;
  wire [0:0]S;
  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire [0:0]data_sync_reg1_0;
  wire \rd_occupancy_reg[3] ;
  wire \rd_occupancy_reg[3]_0 ;
  wire userclk2;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync_reg1_0),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
  LUT4 #(
    .INIT(16'h9669)) 
    rd_occupancy0_carry_i_5
       (.I0(data_out),
        .I1(\rd_occupancy_reg[3] ),
        .I2(\rd_occupancy_reg[3]_0 ),
        .I3(Q),
        .O(S));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block_15
   (S,
    data_out,
    \rd_occupancy_reg[5] ,
    Q,
    data_sync_reg1_0,
    userclk2);
  output [1:0]S;
  output data_out;
  input \rd_occupancy_reg[5] ;
  input [1:0]Q;
  input [0:0]data_sync_reg1_0;
  input userclk2;

  wire [1:0]Q;
  wire [1:0]S;
  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire [0:0]data_sync_reg1_0;
  wire \rd_occupancy_reg[5] ;
  wire userclk2;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync_reg1_0),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
  LUT2 #(
    .INIT(4'h9)) 
    rd_occupancy0_carry__0_i_2
       (.I0(data_out),
        .I1(Q[1]),
        .O(S[1]));
  LUT3 #(
    .INIT(8'h69)) 
    rd_occupancy0_carry__0_i_3
       (.I0(data_out),
        .I1(\rd_occupancy_reg[5] ),
        .I2(Q[0]),
        .O(S[0]));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block_16
   (initialize_ram_complete_sync_ris_edg0,
    data_out,
    initialize_ram_complete_sync_reg1,
    data_in,
    userclk2);
  output initialize_ram_complete_sync_ris_edg0;
  output data_out;
  input initialize_ram_complete_sync_reg1;
  input data_in;
  input userclk2;

  wire data_in;
  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire initialize_ram_complete_sync_reg1;
  wire initialize_ram_complete_sync_ris_edg0;
  wire userclk2;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(userclk2),
        .CE(1'b1),
        .D(data_in),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
  LUT2 #(
    .INIT(4'h2)) 
    initialize_ram_complete_sync_ris_edg_i_1
       (.I0(data_out),
        .I1(initialize_ram_complete_sync_reg1),
        .O(initialize_ram_complete_sync_ris_edg0));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block_31
   (data_out,
    speed_is_100,
    userclk2);
  output data_out;
  input speed_is_100;
  input userclk2;

  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire speed_is_100;
  wire userclk2;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(userclk2),
        .CE(1'b1),
        .D(speed_is_100),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block_32
   (data_out,
    speed_is_10_100,
    userclk2);
  output data_out;
  input speed_is_10_100;
  input userclk2;

  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire speed_is_10_100;
  wire userclk2;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(userclk2),
        .CE(1'b1),
        .D(speed_is_10_100),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block_5
   (S,
    data_sync_reg6_0,
    Q,
    p_25_in,
    data_out,
    data_sync_reg1_0,
    rxuserclk2);
  output [0:0]S;
  output data_sync_reg6_0;
  input [0:0]Q;
  input p_25_in;
  input data_out;
  input [0:0]data_sync_reg1_0;
  input rxuserclk2;

  wire [0:0]Q;
  wire [0:0]S;
  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire [0:0]data_sync_reg1_0;
  wire data_sync_reg6_0;
  wire p_25_in;
  wire rxuserclk2;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync_reg1_0),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_sync_reg6_0),
        .R(1'b0));
  LUT3 #(
    .INIT(8'h69)) 
    wr_occupancy0_carry_i_4
       (.I0(Q),
        .I1(p_25_in),
        .I2(data_out),
        .O(S));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block_6
   (S,
    data_out,
    Q,
    \wr_occupancy_reg[3] ,
    \wr_occupancy_reg[3]_0 ,
    \wr_occupancy_reg[3]_1 ,
    \wr_occupancy_reg[3]_2 ,
    data_sync_reg1_0,
    rxuserclk2);
  output [0:0]S;
  output data_out;
  input [0:0]Q;
  input \wr_occupancy_reg[3] ;
  input \wr_occupancy_reg[3]_0 ;
  input \wr_occupancy_reg[3]_1 ;
  input \wr_occupancy_reg[3]_2 ;
  input [0:0]data_sync_reg1_0;
  input rxuserclk2;

  wire [0:0]Q;
  wire [0:0]S;
  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire [0:0]data_sync_reg1_0;
  wire rxuserclk2;
  wire \wr_occupancy_reg[3] ;
  wire \wr_occupancy_reg[3]_0 ;
  wire \wr_occupancy_reg[3]_1 ;
  wire \wr_occupancy_reg[3]_2 ;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync_reg1_0),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
  LUT6 #(
    .INIT(64'h9669699669969669)) 
    wr_occupancy0_carry_i_3
       (.I0(Q),
        .I1(data_out),
        .I2(\wr_occupancy_reg[3] ),
        .I3(\wr_occupancy_reg[3]_0 ),
        .I4(\wr_occupancy_reg[3]_1 ),
        .I5(\wr_occupancy_reg[3]_2 ),
        .O(S));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block_7
   (S,
    data_out,
    Q,
    \wr_occupancy_reg[3] ,
    \wr_occupancy_reg[3]_0 ,
    \wr_occupancy_reg[3]_1 ,
    data_sync_reg1_0,
    rxuserclk2);
  output [0:0]S;
  output data_out;
  input [0:0]Q;
  input \wr_occupancy_reg[3] ;
  input \wr_occupancy_reg[3]_0 ;
  input \wr_occupancy_reg[3]_1 ;
  input [0:0]data_sync_reg1_0;
  input rxuserclk2;

  wire [0:0]Q;
  wire [0:0]S;
  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire [0:0]data_sync_reg1_0;
  wire rxuserclk2;
  wire \wr_occupancy_reg[3] ;
  wire \wr_occupancy_reg[3]_0 ;
  wire \wr_occupancy_reg[3]_1 ;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync_reg1_0),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
  LUT5 #(
    .INIT(32'h69969669)) 
    wr_occupancy0_carry_i_2
       (.I0(Q),
        .I1(data_out),
        .I2(\wr_occupancy_reg[3] ),
        .I3(\wr_occupancy_reg[3]_0 ),
        .I4(\wr_occupancy_reg[3]_1 ),
        .O(S));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block_8
   (S,
    data_out,
    Q,
    \wr_occupancy_reg[3] ,
    \wr_occupancy_reg[3]_0 ,
    data_sync_reg1_0,
    rxuserclk2);
  output [0:0]S;
  output data_out;
  input [0:0]Q;
  input \wr_occupancy_reg[3] ;
  input \wr_occupancy_reg[3]_0 ;
  input [0:0]data_sync_reg1_0;
  input rxuserclk2;

  wire [0:0]Q;
  wire [0:0]S;
  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire [0:0]data_sync_reg1_0;
  wire rxuserclk2;
  wire \wr_occupancy_reg[3] ;
  wire \wr_occupancy_reg[3]_0 ;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync_reg1_0),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
  LUT4 #(
    .INIT(16'h9669)) 
    wr_occupancy0_carry_i_1
       (.I0(Q),
        .I1(data_out),
        .I2(\wr_occupancy_reg[3] ),
        .I3(\wr_occupancy_reg[3]_0 ),
        .O(S));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block_9
   (S,
    data_out,
    ADDRD,
    \wr_occupancy_reg[5] ,
    Q,
    rxuserclk2);
  output [1:0]S;
  output data_out;
  input [1:0]ADDRD;
  input \wr_occupancy_reg[5] ;
  input [0:0]Q;
  input rxuserclk2;

  wire [1:0]ADDRD;
  wire [0:0]Q;
  wire [1:0]S;
  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire rxuserclk2;
  wire \wr_occupancy_reg[5] ;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(Q),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(rxuserclk2),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
  LUT2 #(
    .INIT(4'h9)) 
    wr_occupancy0_carry__0_i_1
       (.I0(ADDRD[1]),
        .I1(data_out),
        .O(S[1]));
  LUT3 #(
    .INIT(8'h69)) 
    wr_occupancy0_carry__0_i_2
       (.I0(ADDRD[0]),
        .I1(data_out),
        .I2(\wr_occupancy_reg[5] ),
        .O(S[0]));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block__parameterized1
   (data_out,
    data_in,
    userclk2);
  output data_out;
  input data_in;
  input userclk2;

  wire data_in;
  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire userclk2;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(userclk2),
        .CE(1'b1),
        .D(data_in),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block__parameterized1_0
   (resetdone,
    resetdone_0,
    data_in,
    userclk2);
  output resetdone;
  input resetdone_0;
  input data_in;
  input userclk2;

  wire data_in;
  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire resetdone;
  wire resetdone_0;
  wire userclk2;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(userclk2),
        .CE(1'b1),
        .D(data_in),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(userclk2),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
  LUT2 #(
    .INIT(4'h8)) 
    resetdone_INST_0
       (.I0(data_out),
        .I1(resetdone_0),
        .O(resetdone));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block__parameterized1_17
   (data_out,
    data_sync_reg1_0,
    independent_clock_bufg);
  output data_out;
  input data_sync_reg1_0;
  input independent_clock_bufg;

  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire data_sync_reg1_0;
  wire independent_clock_bufg;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync_reg1_0),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block__parameterized1_18
   (reset_time_out_reg,
    E,
    reset_time_out_reg_0,
    reset_time_out,
    \FSM_sequential_tx_state_reg[0] ,
    \FSM_sequential_tx_state_reg[0]_0 ,
    \FSM_sequential_tx_state_reg[0]_1 ,
    \FSM_sequential_tx_state_reg[0]_2 ,
    \FSM_sequential_tx_state_reg[0]_3 ,
    Q,
    reset_time_out_reg_1,
    mmcm_lock_reclocked,
    \FSM_sequential_tx_state_reg[0]_4 ,
    \FSM_sequential_tx_state_reg[0]_5 ,
    \FSM_sequential_tx_state_reg[0]_6 ,
    cplllock,
    independent_clock_bufg);
  output reset_time_out_reg;
  output [0:0]E;
  input reset_time_out_reg_0;
  input reset_time_out;
  input \FSM_sequential_tx_state_reg[0] ;
  input \FSM_sequential_tx_state_reg[0]_0 ;
  input \FSM_sequential_tx_state_reg[0]_1 ;
  input \FSM_sequential_tx_state_reg[0]_2 ;
  input \FSM_sequential_tx_state_reg[0]_3 ;
  input [3:0]Q;
  input reset_time_out_reg_1;
  input mmcm_lock_reclocked;
  input \FSM_sequential_tx_state_reg[0]_4 ;
  input \FSM_sequential_tx_state_reg[0]_5 ;
  input \FSM_sequential_tx_state_reg[0]_6 ;
  input cplllock;
  input independent_clock_bufg;

  wire [0:0]E;
  wire \FSM_sequential_tx_state[3]_i_5_n_0 ;
  wire \FSM_sequential_tx_state_reg[0] ;
  wire \FSM_sequential_tx_state_reg[0]_0 ;
  wire \FSM_sequential_tx_state_reg[0]_1 ;
  wire \FSM_sequential_tx_state_reg[0]_2 ;
  wire \FSM_sequential_tx_state_reg[0]_3 ;
  wire \FSM_sequential_tx_state_reg[0]_4 ;
  wire \FSM_sequential_tx_state_reg[0]_5 ;
  wire \FSM_sequential_tx_state_reg[0]_6 ;
  wire [3:0]Q;
  wire cplllock;
  wire cplllock_sync;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire independent_clock_bufg;
  wire mmcm_lock_reclocked;
  wire reset_time_out;
  wire reset_time_out_i_3__0_n_0;
  wire reset_time_out_i_4__0_n_0;
  wire reset_time_out_reg;
  wire reset_time_out_reg_0;
  wire reset_time_out_reg_1;

  LUT6 #(
    .INIT(64'hFFFFFFFEFFFEFFFE)) 
    \FSM_sequential_tx_state[3]_i_1 
       (.I0(\FSM_sequential_tx_state_reg[0] ),
        .I1(\FSM_sequential_tx_state_reg[0]_0 ),
        .I2(\FSM_sequential_tx_state[3]_i_5_n_0 ),
        .I3(\FSM_sequential_tx_state_reg[0]_1 ),
        .I4(\FSM_sequential_tx_state_reg[0]_2 ),
        .I5(\FSM_sequential_tx_state_reg[0]_3 ),
        .O(E));
  LUT6 #(
    .INIT(64'h0000000000F00008)) 
    \FSM_sequential_tx_state[3]_i_5 
       (.I0(\FSM_sequential_tx_state_reg[0]_4 ),
        .I1(\FSM_sequential_tx_state_reg[0]_5 ),
        .I2(cplllock_sync),
        .I3(Q[2]),
        .I4(Q[1]),
        .I5(\FSM_sequential_tx_state_reg[0]_6 ),
        .O(\FSM_sequential_tx_state[3]_i_5_n_0 ));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(cplllock),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync5),
        .Q(cplllock_sync),
        .R(1'b0));
  LUT4 #(
    .INIT(16'hEFE0)) 
    reset_time_out_i_1
       (.I0(reset_time_out_reg_0),
        .I1(reset_time_out_i_3__0_n_0),
        .I2(reset_time_out_i_4__0_n_0),
        .I3(reset_time_out),
        .O(reset_time_out_reg));
  LUT6 #(
    .INIT(64'h020002000F000200)) 
    reset_time_out_i_3__0
       (.I0(cplllock_sync),
        .I1(Q[2]),
        .I2(Q[3]),
        .I3(Q[0]),
        .I4(mmcm_lock_reclocked),
        .I5(Q[1]),
        .O(reset_time_out_i_3__0_n_0));
  LUT6 #(
    .INIT(64'h0505FF040505F504)) 
    reset_time_out_i_4__0
       (.I0(Q[1]),
        .I1(reset_time_out_reg_1),
        .I2(Q[2]),
        .I3(Q[0]),
        .I4(Q[3]),
        .I5(cplllock_sync),
        .O(reset_time_out_i_4__0_n_0));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block__parameterized1_19
   (SR,
    data_out,
    mmcm_locked,
    independent_clock_bufg);
  output [0:0]SR;
  output data_out;
  input mmcm_locked;
  input independent_clock_bufg;

  wire [0:0]SR;
  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire independent_clock_bufg;
  wire mmcm_locked;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(mmcm_locked),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
  LUT1 #(
    .INIT(2'h1)) 
    \mmcm_lock_count[7]_i_1 
       (.I0(data_out),
        .O(SR));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block__parameterized1_20
   (data_out,
    data_in,
    userclk);
  output data_out;
  input data_in;
  input userclk;

  wire data_in;
  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire userclk;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(userclk),
        .CE(1'b1),
        .D(data_in),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(userclk),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(userclk),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(userclk),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(userclk),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(userclk),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block__parameterized1_21
   (data_out,
    data_in,
    independent_clock_bufg);
  output data_out;
  input data_in;
  input independent_clock_bufg;

  wire data_in;
  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire independent_clock_bufg;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_in),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block__parameterized1_22
   (data_out,
    data_in,
    userclk);
  output data_out;
  input data_in;
  input userclk;

  wire data_in;
  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire userclk;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(userclk),
        .CE(1'b1),
        .D(data_in),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(userclk),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(userclk),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(userclk),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(userclk),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(userclk),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block__parameterized1_23
   (data_out,
    data_sync_reg1_0,
    independent_clock_bufg);
  output data_out;
  input data_sync_reg1_0;
  input independent_clock_bufg;

  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire data_sync_reg1_0;
  wire independent_clock_bufg;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync_reg1_0),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block__parameterized1_24
   (\FSM_sequential_rx_state_reg[1] ,
    Q,
    rxresetdone_s3,
    cplllock,
    independent_clock_bufg);
  output \FSM_sequential_rx_state_reg[1] ;
  input [2:0]Q;
  input rxresetdone_s3;
  input cplllock;
  input independent_clock_bufg;

  wire \FSM_sequential_rx_state_reg[1] ;
  wire [2:0]Q;
  wire cplllock;
  wire cplllock_sync;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire independent_clock_bufg;
  wire rxresetdone_s3;

  LUT5 #(
    .INIT(32'h008F0080)) 
    \FSM_sequential_rx_state[3]_i_5 
       (.I0(Q[0]),
        .I1(rxresetdone_s3),
        .I2(Q[1]),
        .I3(Q[2]),
        .I4(cplllock_sync),
        .O(\FSM_sequential_rx_state_reg[1] ));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(cplllock),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync5),
        .Q(cplllock_sync),
        .R(1'b0));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block__parameterized1_25
   (\FSM_sequential_rx_state_reg[1] ,
    rx_fsm_reset_done_int_reg,
    D,
    E,
    reset_time_out_reg,
    reset_time_out_reg_0,
    Q,
    reset_time_out_reg_1,
    reset_time_out_reg_2,
    data_in,
    \FSM_sequential_rx_state_reg[1]_0 ,
    rx_fsm_reset_done_int_reg_0,
    rx_fsm_reset_done_int_reg_1,
    \FSM_sequential_rx_state_reg[0] ,
    \FSM_sequential_rx_state_reg[0]_0 ,
    \FSM_sequential_rx_state_reg[0]_1 ,
    mmcm_lock_reclocked,
    \FSM_sequential_rx_state_reg[0]_2 ,
    time_out_wait_bypass_s3,
    \FSM_sequential_rx_state_reg[3] ,
    \FSM_sequential_rx_state_reg[0]_3 ,
    rx_fsm_reset_done_int_reg_2,
    rx_fsm_reset_done_int_reg_3,
    data_out,
    independent_clock_bufg);
  output \FSM_sequential_rx_state_reg[1] ;
  output rx_fsm_reset_done_int_reg;
  output [2:0]D;
  output [0:0]E;
  input reset_time_out_reg;
  input reset_time_out_reg_0;
  input [3:0]Q;
  input reset_time_out_reg_1;
  input reset_time_out_reg_2;
  input data_in;
  input \FSM_sequential_rx_state_reg[1]_0 ;
  input rx_fsm_reset_done_int_reg_0;
  input rx_fsm_reset_done_int_reg_1;
  input \FSM_sequential_rx_state_reg[0] ;
  input \FSM_sequential_rx_state_reg[0]_0 ;
  input \FSM_sequential_rx_state_reg[0]_1 ;
  input mmcm_lock_reclocked;
  input \FSM_sequential_rx_state_reg[0]_2 ;
  input time_out_wait_bypass_s3;
  input \FSM_sequential_rx_state_reg[3] ;
  input \FSM_sequential_rx_state_reg[0]_3 ;
  input rx_fsm_reset_done_int_reg_2;
  input rx_fsm_reset_done_int_reg_3;
  input data_out;
  input independent_clock_bufg;

  wire [2:0]D;
  wire [0:0]E;
  wire \FSM_sequential_rx_state[0]_i_3_n_0 ;
  wire \FSM_sequential_rx_state[1]_i_2_n_0 ;
  wire \FSM_sequential_rx_state[3]_i_4_n_0 ;
  wire \FSM_sequential_rx_state[3]_i_6_n_0 ;
  wire \FSM_sequential_rx_state[3]_i_8_n_0 ;
  wire \FSM_sequential_rx_state_reg[0] ;
  wire \FSM_sequential_rx_state_reg[0]_0 ;
  wire \FSM_sequential_rx_state_reg[0]_1 ;
  wire \FSM_sequential_rx_state_reg[0]_2 ;
  wire \FSM_sequential_rx_state_reg[0]_3 ;
  wire \FSM_sequential_rx_state_reg[1] ;
  wire \FSM_sequential_rx_state_reg[1]_0 ;
  wire \FSM_sequential_rx_state_reg[3] ;
  wire [3:0]Q;
  wire data_in;
  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire data_valid_sync;
  wire independent_clock_bufg;
  wire mmcm_lock_reclocked;
  wire reset_time_out_i_2_n_0;
  wire reset_time_out_reg;
  wire reset_time_out_reg_0;
  wire reset_time_out_reg_1;
  wire reset_time_out_reg_2;
  wire rx_fsm_reset_done_int;
  wire rx_fsm_reset_done_int_i_3_n_0;
  wire rx_fsm_reset_done_int_i_4_n_0;
  wire rx_fsm_reset_done_int_reg;
  wire rx_fsm_reset_done_int_reg_0;
  wire rx_fsm_reset_done_int_reg_1;
  wire rx_fsm_reset_done_int_reg_2;
  wire rx_fsm_reset_done_int_reg_3;
  wire time_out_wait_bypass_s3;

  LUT5 #(
    .INIT(32'hFFEFEFEF)) 
    \FSM_sequential_rx_state[0]_i_1 
       (.I0(\FSM_sequential_rx_state_reg[0]_2 ),
        .I1(\FSM_sequential_rx_state[0]_i_3_n_0 ),
        .I2(Q[0]),
        .I3(Q[1]),
        .I4(Q[3]),
        .O(D[0]));
  (* SOFT_HLUTNM = "soft_lutpair77" *) 
  LUT4 #(
    .INIT(16'h0200)) 
    \FSM_sequential_rx_state[0]_i_3 
       (.I0(Q[3]),
        .I1(reset_time_out_reg_2),
        .I2(data_valid_sync),
        .I3(rx_fsm_reset_done_int_reg_1),
        .O(\FSM_sequential_rx_state[0]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hFFFFFFFF24200400)) 
    \FSM_sequential_rx_state[1]_i_1 
       (.I0(Q[0]),
        .I1(Q[1]),
        .I2(Q[3]),
        .I3(Q[2]),
        .I4(\FSM_sequential_rx_state[1]_i_2_n_0 ),
        .I5(\FSM_sequential_rx_state_reg[1]_0 ),
        .O(D[1]));
  LUT2 #(
    .INIT(4'hB)) 
    \FSM_sequential_rx_state[1]_i_2 
       (.I0(data_valid_sync),
        .I1(rx_fsm_reset_done_int_reg_1),
        .O(\FSM_sequential_rx_state[1]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hFFFFFFFFFFFFFEEE)) 
    \FSM_sequential_rx_state[3]_i_1 
       (.I0(\FSM_sequential_rx_state_reg[0] ),
        .I1(\FSM_sequential_rx_state[3]_i_4_n_0 ),
        .I2(Q[0]),
        .I3(reset_time_out_reg),
        .I4(\FSM_sequential_rx_state[3]_i_6_n_0 ),
        .I5(\FSM_sequential_rx_state_reg[0]_0 ),
        .O(E));
  LUT6 #(
    .INIT(64'hFFFFFFFFCCC0C4C4)) 
    \FSM_sequential_rx_state[3]_i_2 
       (.I0(time_out_wait_bypass_s3),
        .I1(Q[3]),
        .I2(Q[1]),
        .I3(\FSM_sequential_rx_state[3]_i_8_n_0 ),
        .I4(Q[0]),
        .I5(\FSM_sequential_rx_state_reg[3] ),
        .O(D[2]));
  LUT6 #(
    .INIT(64'hAAAAAAAAAAAAEFEA)) 
    \FSM_sequential_rx_state[3]_i_4 
       (.I0(\FSM_sequential_rx_state[0]_i_3_n_0 ),
        .I1(\FSM_sequential_rx_state_reg[0]_1 ),
        .I2(Q[2]),
        .I3(\FSM_sequential_rx_state_reg[0]_3 ),
        .I4(Q[0]),
        .I5(Q[1]),
        .O(\FSM_sequential_rx_state[3]_i_4_n_0 ));
  LUT5 #(
    .INIT(32'h0CE20CCC)) 
    \FSM_sequential_rx_state[3]_i_6 
       (.I0(mmcm_lock_reclocked),
        .I1(Q[3]),
        .I2(data_valid_sync),
        .I3(Q[1]),
        .I4(Q[0]),
        .O(\FSM_sequential_rx_state[3]_i_6_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair77" *) 
  LUT3 #(
    .INIT(8'hFD)) 
    \FSM_sequential_rx_state[3]_i_8 
       (.I0(rx_fsm_reset_done_int_reg_1),
        .I1(data_valid_sync),
        .I2(reset_time_out_reg_2),
        .O(\FSM_sequential_rx_state[3]_i_8_n_0 ));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_out),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_valid_sync),
        .R(1'b0));
  LUT6 #(
    .INIT(64'hEEEFFFFFEEEF0000)) 
    reset_time_out_i_1__0
       (.I0(reset_time_out_i_2_n_0),
        .I1(reset_time_out_reg),
        .I2(reset_time_out_reg_0),
        .I3(Q[1]),
        .I4(reset_time_out_reg_1),
        .I5(reset_time_out_reg_2),
        .O(\FSM_sequential_rx_state_reg[1] ));
  LUT6 #(
    .INIT(64'h0FF30E0E0FF30202)) 
    reset_time_out_i_2
       (.I0(\FSM_sequential_rx_state_reg[0]_1 ),
        .I1(Q[0]),
        .I2(Q[1]),
        .I3(data_valid_sync),
        .I4(Q[3]),
        .I5(mmcm_lock_reclocked),
        .O(reset_time_out_i_2_n_0));
  LUT4 #(
    .INIT(16'hABA8)) 
    rx_fsm_reset_done_int_i_1
       (.I0(rx_fsm_reset_done_int),
        .I1(rx_fsm_reset_done_int_i_3_n_0),
        .I2(rx_fsm_reset_done_int_i_4_n_0),
        .I3(data_in),
        .O(rx_fsm_reset_done_int_reg));
  LUT5 #(
    .INIT(32'h00040000)) 
    rx_fsm_reset_done_int_i_2
       (.I0(Q[0]),
        .I1(data_valid_sync),
        .I2(Q[2]),
        .I3(reset_time_out_reg_2),
        .I4(rx_fsm_reset_done_int_reg_2),
        .O(rx_fsm_reset_done_int));
  LUT6 #(
    .INIT(64'h0400040004040400)) 
    rx_fsm_reset_done_int_i_3
       (.I0(rx_fsm_reset_done_int_reg_0),
        .I1(Q[3]),
        .I2(Q[2]),
        .I3(data_valid_sync),
        .I4(rx_fsm_reset_done_int_reg_1),
        .I5(reset_time_out_reg_2),
        .O(rx_fsm_reset_done_int_i_3_n_0));
  LUT6 #(
    .INIT(64'h0008000808080008)) 
    rx_fsm_reset_done_int_i_4
       (.I0(rx_fsm_reset_done_int_reg_3),
        .I1(Q[1]),
        .I2(Q[0]),
        .I3(data_valid_sync),
        .I4(rx_fsm_reset_done_int_reg_2),
        .I5(reset_time_out_reg_2),
        .O(rx_fsm_reset_done_int_i_4_n_0));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block__parameterized1_26
   (SR,
    data_out,
    mmcm_locked,
    independent_clock_bufg);
  output [0:0]SR;
  output data_out;
  input mmcm_locked;
  input independent_clock_bufg;

  wire [0:0]SR;
  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire independent_clock_bufg;
  wire mmcm_locked;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(mmcm_locked),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
  LUT1 #(
    .INIT(2'h1)) 
    \mmcm_lock_count[7]_i_1__0 
       (.I0(data_out),
        .O(SR));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block__parameterized1_27
   (data_out,
    data_in,
    rxuserclk);
  output data_out;
  input data_in;
  input rxuserclk;

  wire data_in;
  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire rxuserclk;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(rxuserclk),
        .CE(1'b1),
        .D(data_in),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(rxuserclk),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(rxuserclk),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(rxuserclk),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(rxuserclk),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(rxuserclk),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block__parameterized1_28
   (data_out,
    data_in,
    independent_clock_bufg);
  output data_out;
  input data_in;
  input independent_clock_bufg;

  wire data_in;
  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire independent_clock_bufg;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_in),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block__parameterized1_29
   (data_out,
    data_in,
    rxuserclk);
  output data_out;
  input data_in;
  input rxuserclk;

  wire data_in;
  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire rxuserclk;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(rxuserclk),
        .CE(1'b1),
        .D(data_in),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(rxuserclk),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(rxuserclk),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(rxuserclk),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(rxuserclk),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(rxuserclk),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
endmodule

(* ORIG_REF_NAME = "gmii_to_sgmii_bridge_sync_block" *) 
module gmii_to_sgmii_bridge_sync_block__parameterized1_4
   (data_out,
    status_vector,
    independent_clock_bufg);
  output data_out;
  input [0:0]status_vector;
  input independent_clock_bufg;

  wire data_out;
  wire data_sync1;
  wire data_sync2;
  wire data_sync3;
  wire data_sync4;
  wire data_sync5;
  wire independent_clock_bufg;
  wire [0:0]status_vector;

  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg1
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(status_vector),
        .Q(data_sync1),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg2
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync1),
        .Q(data_sync2),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg3
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync2),
        .Q(data_sync3),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg4
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync3),
        .Q(data_sync4),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg5
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync4),
        .Q(data_sync5),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* SHREG_EXTRACT = "no" *) 
  (* XILINX_LEGACY_PRIM = "FD" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE GND:R" *) 
  (* box_type = "PRIMITIVE" *) 
  FDRE #(
    .INIT(1'b0)) 
    data_sync_reg6
       (.C(independent_clock_bufg),
        .CE(1'b1),
        .D(data_sync5),
        .Q(data_out),
        .R(1'b0));
endmodule

module gmii_to_sgmii_bridge_transceiver
   (cplllock,
    txn,
    txp,
    rxoutclk,
    txoutclk,
    rxchariscomma,
    rxcharisk,
    rxdisperr,
    rxnotintable,
    rxclkcorcnt,
    txbuferr,
    mmcm_reset,
    data_in,
    rx_fsm_reset_done_int_reg,
    rxbufstatus,
    Q,
    independent_clock_bufg,
    gtrefclk_bufg,
    gtrefclk,
    rxn,
    rxp,
    gt0_qplloutclk_in,
    gt0_qplloutrefclk_in,
    rxuserclk,
    userclk,
    userclk2,
    rxuserclk2,
    SR,
    powerdown,
    D,
    txchardispval_reg_reg_0,
    txcharisk_reg_reg_0,
    pma_reset,
    status_vector,
    enablealign,
    mgt_rx_reset,
    mmcm_locked,
    \txdata_reg_reg[7]_0 );
  output cplllock;
  output txn;
  output txp;
  output rxoutclk;
  output txoutclk;
  output [0:0]rxchariscomma;
  output [0:0]rxcharisk;
  output [0:0]rxdisperr;
  output [0:0]rxnotintable;
  output [1:0]rxclkcorcnt;
  output txbuferr;
  output mmcm_reset;
  output data_in;
  output rx_fsm_reset_done_int_reg;
  output [0:0]rxbufstatus;
  output [7:0]Q;
  input independent_clock_bufg;
  input gtrefclk_bufg;
  input gtrefclk;
  input rxn;
  input rxp;
  input gt0_qplloutclk_in;
  input gt0_qplloutrefclk_in;
  input rxuserclk;
  input userclk;
  input userclk2;
  input rxuserclk2;
  input [0:0]SR;
  input powerdown;
  input [0:0]D;
  input [0:0]txchardispval_reg_reg_0;
  input [0:0]txcharisk_reg_reg_0;
  input pma_reset;
  input [0:0]status_vector;
  input enablealign;
  input mgt_rx_reset;
  input mmcm_locked;
  input [7:0]\txdata_reg_reg[7]_0 ;

  wire [0:0]D;
  wire [7:0]Q;
  wire [0:0]SR;
  wire cplllock;
  wire data_in;
  wire data_valid_reg2;
  wire enablealign;
  wire encommaalign_rec;
  wire gt0_qplloutclk_in;
  wire gt0_qplloutrefclk_in;
  wire gtrefclk;
  wire gtrefclk_bufg;
  wire gtwizard_inst_n_5;
  wire independent_clock_bufg;
  wire initialize_ram0;
  wire initialize_ram_complete;
  wire initialize_ram_complete_pulse;
  wire mgt_rx_reset;
  wire mmcm_locked;
  wire mmcm_reset;
  wire pma_reset;
  wire powerdown;
  wire reclock_rxreset_n_3;
  wire reset;
  wire rx_fsm_reset_done_int_reg;
  wire [0:0]rxbufstatus;
  wire [0:0]rxchariscomma;
  wire [1:0]rxchariscomma_rec;
  wire [0:0]rxcharisk;
  wire [1:0]rxcharisk_rec;
  wire [1:0]rxclkcorcnt;
  wire [15:0]rxdata_rec;
  wire [0:0]rxdisperr;
  wire [1:0]rxdisperr_rec;
  wire rxn;
  wire [0:0]rxnotintable;
  wire [1:0]rxnotintable_rec;
  wire rxoutclk;
  wire rxp;
  wire rxreset_int;
  wire rxreset_rec;
  wire rxuserclk;
  wire rxuserclk2;
  wire start;
  wire [0:0]status_vector;
  wire toggle;
  wire toggle_i_1_n_0;
  wire txbuferr;
  wire [1:1]txbufstatus_reg;
  wire [1:0]txchardispmode_double;
  wire [1:0]txchardispmode_int;
  wire txchardispmode_reg;
  wire [1:0]txchardispval_double;
  wire [1:0]txchardispval_int;
  wire txchardispval_reg;
  wire [0:0]txchardispval_reg_reg_0;
  wire [1:0]txcharisk_double;
  wire [1:0]txcharisk_int;
  wire txcharisk_reg;
  wire [0:0]txcharisk_reg_reg_0;
  wire [15:0]txdata_double;
  wire [15:0]txdata_int;
  wire [7:0]txdata_reg;
  wire [7:0]\txdata_reg_reg[7]_0 ;
  wire txn;
  wire txoutclk;
  wire txp;
  wire txpowerdown;
  wire txpowerdown_double;
  wire txpowerdown_reg__0;
  wire txreset_int;
  wire userclk;
  wire userclk2;
  wire wr_data1;

  gmii_to_sgmii_bridge_GTWIZARD gtwizard_inst
       (.D({rxchariscomma_rec[0],rxcharisk_rec[0],rxdisperr_rec[0],rxnotintable_rec[0],rxdata_rec[7:0],rxchariscomma_rec[1],rxcharisk_rec[1],rxdisperr_rec[1],rxnotintable_rec[1],rxdata_rec[15:8]}),
        .Q(txdata_int),
        .RXPD(txpowerdown_reg__0),
        .TXBUFSTATUS(gtwizard_inst_n_5),
        .TXPD(txpowerdown),
        .cplllock(cplllock),
        .data_in(data_in),
        .data_out(data_valid_reg2),
        .gt0_qplloutclk_in(gt0_qplloutclk_in),
        .gt0_qplloutrefclk_in(gt0_qplloutrefclk_in),
        .gtrefclk(gtrefclk),
        .gtrefclk_bufg(gtrefclk_bufg),
        .gtxe2_i(txchardispmode_int),
        .gtxe2_i_0(txchardispval_int),
        .gtxe2_i_1(txcharisk_int),
        .gtxe2_i_2(rxreset_int),
        .gtxe2_i_3(txreset_int),
        .independent_clock_bufg(independent_clock_bufg),
        .mmcm_locked(mmcm_locked),
        .mmcm_reset(mmcm_reset),
        .pma_reset(pma_reset),
        .reset(reset),
        .reset_out(encommaalign_rec),
        .rx_fsm_reset_done_int_reg(rx_fsm_reset_done_int_reg),
        .rxn(rxn),
        .rxoutclk(rxoutclk),
        .rxp(rxp),
        .rxuserclk(rxuserclk),
        .txn(txn),
        .txoutclk(txoutclk),
        .txp(txp),
        .userclk(userclk));
  gmii_to_sgmii_bridge_reset_sync reclock_encommaalign
       (.enablealign(enablealign),
        .reset_out(encommaalign_rec),
        .rxuserclk2(rxuserclk2));
  gmii_to_sgmii_bridge_reset_sync_1 reclock_rxreset
       (.SR(initialize_ram0),
        .initialize_ram_complete(initialize_ram_complete),
        .initialize_ram_complete_pulse(initialize_ram_complete_pulse),
        .mgt_rx_reset(mgt_rx_reset),
        .reset_out(rxreset_rec),
        .reset_sync6_0(wr_data1),
        .reset_sync6_1(reclock_rxreset_n_3),
        .rxuserclk2(rxuserclk2),
        .start(start));
  gmii_to_sgmii_bridge_reset_sync_2 reclock_rxreset_ind_clk
       (.independent_clock_bufg(independent_clock_bufg),
        .mgt_rx_reset(mgt_rx_reset),
        .reset_out(rxreset_int));
  gmii_to_sgmii_bridge_reset_sync_3 reclock_txreset
       (.SR(SR),
        .reset_out(txreset_int),
        .userclk(userclk));
  gmii_to_sgmii_bridge_reset_wtd_timer reset_wtd_timer
       (.data_out(data_valid_reg2),
        .independent_clock_bufg(independent_clock_bufg),
        .reset(reset));
  gmii_to_sgmii_bridge_rx_elastic_buffer rx_elastic_buffer_inst
       (.D({rxchariscomma_rec[0],rxcharisk_rec[0],rxdisperr_rec[0],rxnotintable_rec[0],rxdata_rec[7:0],rxchariscomma_rec[1],rxcharisk_rec[1],rxdisperr_rec[1],rxnotintable_rec[1],rxdata_rec[15:8]}),
        .Q(Q),
        .SR(initialize_ram0),
        .initialize_ram_complete(initialize_ram_complete),
        .initialize_ram_complete_pulse(initialize_ram_complete_pulse),
        .mgt_rx_reset(mgt_rx_reset),
        .reset_out(rxreset_rec),
        .rxbufstatus(rxbufstatus),
        .rxchariscomma(rxchariscomma),
        .rxcharisk(rxcharisk),
        .rxclkcorcnt(rxclkcorcnt),
        .rxdisperr(rxdisperr),
        .rxnotintable(rxnotintable),
        .rxuserclk2(rxuserclk2),
        .start(start),
        .userclk2(userclk2),
        .\wr_addr_plus1_reg[0]_0 (reclock_rxreset_n_3),
        .\wr_data_reg_reg[0]_0 (wr_data1));
  gmii_to_sgmii_bridge_sync_block__parameterized1_4 sync_block_data_valid
       (.data_out(data_valid_reg2),
        .independent_clock_bufg(independent_clock_bufg),
        .status_vector(status_vector));
  LUT1 #(
    .INIT(2'h1)) 
    toggle_i_1
       (.I0(toggle),
        .O(toggle_i_1_n_0));
  FDRE toggle_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(toggle_i_1_n_0),
        .Q(toggle),
        .R(SR));
  FDRE txbuferr_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(txbufstatus_reg),
        .Q(txbuferr),
        .R(1'b0));
  FDRE \txbufstatus_reg_reg[1] 
       (.C(userclk),
        .CE(1'b1),
        .D(gtwizard_inst_n_5),
        .Q(txbufstatus_reg),
        .R(1'b0));
  FDRE \txchardispmode_double_reg[0] 
       (.C(userclk2),
        .CE(toggle_i_1_n_0),
        .D(txchardispmode_reg),
        .Q(txchardispmode_double[0]),
        .R(SR));
  FDRE \txchardispmode_double_reg[1] 
       (.C(userclk2),
        .CE(toggle_i_1_n_0),
        .D(D),
        .Q(txchardispmode_double[1]),
        .R(SR));
  FDRE \txchardispmode_int_reg[0] 
       (.C(userclk),
        .CE(1'b1),
        .D(txchardispmode_double[0]),
        .Q(txchardispmode_int[0]),
        .R(1'b0));
  FDRE \txchardispmode_int_reg[1] 
       (.C(userclk),
        .CE(1'b1),
        .D(txchardispmode_double[1]),
        .Q(txchardispmode_int[1]),
        .R(1'b0));
  FDRE txchardispmode_reg_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(D),
        .Q(txchardispmode_reg),
        .R(SR));
  FDRE \txchardispval_double_reg[0] 
       (.C(userclk2),
        .CE(toggle_i_1_n_0),
        .D(txchardispval_reg),
        .Q(txchardispval_double[0]),
        .R(SR));
  FDRE \txchardispval_double_reg[1] 
       (.C(userclk2),
        .CE(toggle_i_1_n_0),
        .D(txchardispval_reg_reg_0),
        .Q(txchardispval_double[1]),
        .R(SR));
  FDRE \txchardispval_int_reg[0] 
       (.C(userclk),
        .CE(1'b1),
        .D(txchardispval_double[0]),
        .Q(txchardispval_int[0]),
        .R(1'b0));
  FDRE \txchardispval_int_reg[1] 
       (.C(userclk),
        .CE(1'b1),
        .D(txchardispval_double[1]),
        .Q(txchardispval_int[1]),
        .R(1'b0));
  FDRE txchardispval_reg_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(txchardispval_reg_reg_0),
        .Q(txchardispval_reg),
        .R(SR));
  FDRE \txcharisk_double_reg[0] 
       (.C(userclk2),
        .CE(toggle_i_1_n_0),
        .D(txcharisk_reg),
        .Q(txcharisk_double[0]),
        .R(SR));
  FDRE \txcharisk_double_reg[1] 
       (.C(userclk2),
        .CE(toggle_i_1_n_0),
        .D(txcharisk_reg_reg_0),
        .Q(txcharisk_double[1]),
        .R(SR));
  FDRE \txcharisk_int_reg[0] 
       (.C(userclk),
        .CE(1'b1),
        .D(txcharisk_double[0]),
        .Q(txcharisk_int[0]),
        .R(1'b0));
  FDRE \txcharisk_int_reg[1] 
       (.C(userclk),
        .CE(1'b1),
        .D(txcharisk_double[1]),
        .Q(txcharisk_int[1]),
        .R(1'b0));
  FDRE txcharisk_reg_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(txcharisk_reg_reg_0),
        .Q(txcharisk_reg),
        .R(SR));
  FDRE \txdata_double_reg[0] 
       (.C(userclk2),
        .CE(toggle_i_1_n_0),
        .D(txdata_reg[0]),
        .Q(txdata_double[0]),
        .R(SR));
  FDRE \txdata_double_reg[10] 
       (.C(userclk2),
        .CE(toggle_i_1_n_0),
        .D(\txdata_reg_reg[7]_0 [2]),
        .Q(txdata_double[10]),
        .R(SR));
  FDRE \txdata_double_reg[11] 
       (.C(userclk2),
        .CE(toggle_i_1_n_0),
        .D(\txdata_reg_reg[7]_0 [3]),
        .Q(txdata_double[11]),
        .R(SR));
  FDRE \txdata_double_reg[12] 
       (.C(userclk2),
        .CE(toggle_i_1_n_0),
        .D(\txdata_reg_reg[7]_0 [4]),
        .Q(txdata_double[12]),
        .R(SR));
  FDRE \txdata_double_reg[13] 
       (.C(userclk2),
        .CE(toggle_i_1_n_0),
        .D(\txdata_reg_reg[7]_0 [5]),
        .Q(txdata_double[13]),
        .R(SR));
  FDRE \txdata_double_reg[14] 
       (.C(userclk2),
        .CE(toggle_i_1_n_0),
        .D(\txdata_reg_reg[7]_0 [6]),
        .Q(txdata_double[14]),
        .R(SR));
  FDRE \txdata_double_reg[15] 
       (.C(userclk2),
        .CE(toggle_i_1_n_0),
        .D(\txdata_reg_reg[7]_0 [7]),
        .Q(txdata_double[15]),
        .R(SR));
  FDRE \txdata_double_reg[1] 
       (.C(userclk2),
        .CE(toggle_i_1_n_0),
        .D(txdata_reg[1]),
        .Q(txdata_double[1]),
        .R(SR));
  FDRE \txdata_double_reg[2] 
       (.C(userclk2),
        .CE(toggle_i_1_n_0),
        .D(txdata_reg[2]),
        .Q(txdata_double[2]),
        .R(SR));
  FDRE \txdata_double_reg[3] 
       (.C(userclk2),
        .CE(toggle_i_1_n_0),
        .D(txdata_reg[3]),
        .Q(txdata_double[3]),
        .R(SR));
  FDRE \txdata_double_reg[4] 
       (.C(userclk2),
        .CE(toggle_i_1_n_0),
        .D(txdata_reg[4]),
        .Q(txdata_double[4]),
        .R(SR));
  FDRE \txdata_double_reg[5] 
       (.C(userclk2),
        .CE(toggle_i_1_n_0),
        .D(txdata_reg[5]),
        .Q(txdata_double[5]),
        .R(SR));
  FDRE \txdata_double_reg[6] 
       (.C(userclk2),
        .CE(toggle_i_1_n_0),
        .D(txdata_reg[6]),
        .Q(txdata_double[6]),
        .R(SR));
  FDRE \txdata_double_reg[7] 
       (.C(userclk2),
        .CE(toggle_i_1_n_0),
        .D(txdata_reg[7]),
        .Q(txdata_double[7]),
        .R(SR));
  FDRE \txdata_double_reg[8] 
       (.C(userclk2),
        .CE(toggle_i_1_n_0),
        .D(\txdata_reg_reg[7]_0 [0]),
        .Q(txdata_double[8]),
        .R(SR));
  FDRE \txdata_double_reg[9] 
       (.C(userclk2),
        .CE(toggle_i_1_n_0),
        .D(\txdata_reg_reg[7]_0 [1]),
        .Q(txdata_double[9]),
        .R(SR));
  FDRE \txdata_int_reg[0] 
       (.C(userclk),
        .CE(1'b1),
        .D(txdata_double[0]),
        .Q(txdata_int[0]),
        .R(1'b0));
  FDRE \txdata_int_reg[10] 
       (.C(userclk),
        .CE(1'b1),
        .D(txdata_double[10]),
        .Q(txdata_int[10]),
        .R(1'b0));
  FDRE \txdata_int_reg[11] 
       (.C(userclk),
        .CE(1'b1),
        .D(txdata_double[11]),
        .Q(txdata_int[11]),
        .R(1'b0));
  FDRE \txdata_int_reg[12] 
       (.C(userclk),
        .CE(1'b1),
        .D(txdata_double[12]),
        .Q(txdata_int[12]),
        .R(1'b0));
  FDRE \txdata_int_reg[13] 
       (.C(userclk),
        .CE(1'b1),
        .D(txdata_double[13]),
        .Q(txdata_int[13]),
        .R(1'b0));
  FDRE \txdata_int_reg[14] 
       (.C(userclk),
        .CE(1'b1),
        .D(txdata_double[14]),
        .Q(txdata_int[14]),
        .R(1'b0));
  FDRE \txdata_int_reg[15] 
       (.C(userclk),
        .CE(1'b1),
        .D(txdata_double[15]),
        .Q(txdata_int[15]),
        .R(1'b0));
  FDRE \txdata_int_reg[1] 
       (.C(userclk),
        .CE(1'b1),
        .D(txdata_double[1]),
        .Q(txdata_int[1]),
        .R(1'b0));
  FDRE \txdata_int_reg[2] 
       (.C(userclk),
        .CE(1'b1),
        .D(txdata_double[2]),
        .Q(txdata_int[2]),
        .R(1'b0));
  FDRE \txdata_int_reg[3] 
       (.C(userclk),
        .CE(1'b1),
        .D(txdata_double[3]),
        .Q(txdata_int[3]),
        .R(1'b0));
  FDRE \txdata_int_reg[4] 
       (.C(userclk),
        .CE(1'b1),
        .D(txdata_double[4]),
        .Q(txdata_int[4]),
        .R(1'b0));
  FDRE \txdata_int_reg[5] 
       (.C(userclk),
        .CE(1'b1),
        .D(txdata_double[5]),
        .Q(txdata_int[5]),
        .R(1'b0));
  FDRE \txdata_int_reg[6] 
       (.C(userclk),
        .CE(1'b1),
        .D(txdata_double[6]),
        .Q(txdata_int[6]),
        .R(1'b0));
  FDRE \txdata_int_reg[7] 
       (.C(userclk),
        .CE(1'b1),
        .D(txdata_double[7]),
        .Q(txdata_int[7]),
        .R(1'b0));
  FDRE \txdata_int_reg[8] 
       (.C(userclk),
        .CE(1'b1),
        .D(txdata_double[8]),
        .Q(txdata_int[8]),
        .R(1'b0));
  FDRE \txdata_int_reg[9] 
       (.C(userclk),
        .CE(1'b1),
        .D(txdata_double[9]),
        .Q(txdata_int[9]),
        .R(1'b0));
  FDRE \txdata_reg_reg[0] 
       (.C(userclk2),
        .CE(1'b1),
        .D(\txdata_reg_reg[7]_0 [0]),
        .Q(txdata_reg[0]),
        .R(SR));
  FDRE \txdata_reg_reg[1] 
       (.C(userclk2),
        .CE(1'b1),
        .D(\txdata_reg_reg[7]_0 [1]),
        .Q(txdata_reg[1]),
        .R(SR));
  FDRE \txdata_reg_reg[2] 
       (.C(userclk2),
        .CE(1'b1),
        .D(\txdata_reg_reg[7]_0 [2]),
        .Q(txdata_reg[2]),
        .R(SR));
  FDRE \txdata_reg_reg[3] 
       (.C(userclk2),
        .CE(1'b1),
        .D(\txdata_reg_reg[7]_0 [3]),
        .Q(txdata_reg[3]),
        .R(SR));
  FDRE \txdata_reg_reg[4] 
       (.C(userclk2),
        .CE(1'b1),
        .D(\txdata_reg_reg[7]_0 [4]),
        .Q(txdata_reg[4]),
        .R(SR));
  FDRE \txdata_reg_reg[5] 
       (.C(userclk2),
        .CE(1'b1),
        .D(\txdata_reg_reg[7]_0 [5]),
        .Q(txdata_reg[5]),
        .R(SR));
  FDRE \txdata_reg_reg[6] 
       (.C(userclk2),
        .CE(1'b1),
        .D(\txdata_reg_reg[7]_0 [6]),
        .Q(txdata_reg[6]),
        .R(SR));
  FDRE \txdata_reg_reg[7] 
       (.C(userclk2),
        .CE(1'b1),
        .D(\txdata_reg_reg[7]_0 [7]),
        .Q(txdata_reg[7]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    txpowerdown_double_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(txpowerdown_reg__0),
        .Q(txpowerdown_double),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    txpowerdown_reg
       (.C(userclk),
        .CE(1'b1),
        .D(txpowerdown_double),
        .Q(txpowerdown),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    txpowerdown_reg_reg
       (.C(userclk2),
        .CE(1'b1),
        .D(powerdown),
        .Q(txpowerdown_reg__0),
        .R(SR));
endmodule

module gmii_to_sgmii_bridge_tx_rate_adapt
   (gmii_tx_en,
    gmii_tx_er,
    Q,
    reset_out,
    E,
    gmii_tx_en_out_reg_0,
    userclk2,
    gmii_tx_er_out_reg_0,
    gmii_txd);
  output gmii_tx_en;
  output gmii_tx_er;
  output [7:0]Q;
  input reset_out;
  input [0:0]E;
  input gmii_tx_en_out_reg_0;
  input userclk2;
  input gmii_tx_er_out_reg_0;
  input [7:0]gmii_txd;

  wire [0:0]E;
  wire [7:0]Q;
  wire gmii_tx_en;
  wire gmii_tx_en_out_reg_0;
  wire gmii_tx_er;
  wire gmii_tx_er_out_reg_0;
  wire [7:0]gmii_txd;
  wire reset_out;
  wire userclk2;

  FDRE #(
    .INIT(1'b0)) 
    gmii_tx_en_out_reg
       (.C(userclk2),
        .CE(E),
        .D(gmii_tx_en_out_reg_0),
        .Q(gmii_tx_en),
        .R(reset_out));
  FDRE #(
    .INIT(1'b0)) 
    gmii_tx_er_out_reg
       (.C(userclk2),
        .CE(E),
        .D(gmii_tx_er_out_reg_0),
        .Q(gmii_tx_er),
        .R(reset_out));
  FDRE #(
    .INIT(1'b0)) 
    \gmii_txd_out_reg[0] 
       (.C(userclk2),
        .CE(E),
        .D(gmii_txd[0]),
        .Q(Q[0]),
        .R(reset_out));
  FDRE #(
    .INIT(1'b0)) 
    \gmii_txd_out_reg[1] 
       (.C(userclk2),
        .CE(E),
        .D(gmii_txd[1]),
        .Q(Q[1]),
        .R(reset_out));
  FDRE #(
    .INIT(1'b0)) 
    \gmii_txd_out_reg[2] 
       (.C(userclk2),
        .CE(E),
        .D(gmii_txd[2]),
        .Q(Q[2]),
        .R(reset_out));
  FDRE #(
    .INIT(1'b0)) 
    \gmii_txd_out_reg[3] 
       (.C(userclk2),
        .CE(E),
        .D(gmii_txd[3]),
        .Q(Q[3]),
        .R(reset_out));
  FDRE #(
    .INIT(1'b0)) 
    \gmii_txd_out_reg[4] 
       (.C(userclk2),
        .CE(E),
        .D(gmii_txd[4]),
        .Q(Q[4]),
        .R(reset_out));
  FDRE #(
    .INIT(1'b0)) 
    \gmii_txd_out_reg[5] 
       (.C(userclk2),
        .CE(E),
        .D(gmii_txd[5]),
        .Q(Q[5]),
        .R(reset_out));
  FDRE #(
    .INIT(1'b0)) 
    \gmii_txd_out_reg[6] 
       (.C(userclk2),
        .CE(E),
        .D(gmii_txd[6]),
        .Q(Q[6]),
        .R(reset_out));
  FDRE #(
    .INIT(1'b0)) 
    \gmii_txd_out_reg[7] 
       (.C(userclk2),
        .CE(E),
        .D(gmii_txd[7]),
        .Q(Q[7]),
        .R(reset_out));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2022.2"
`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
kYrcO/E+Jhm4R/4R3+CukKYR9M2FIvcsEHYDIEQ941LV/qe3nw66ouV0tjU2K77WxMp0KzE3bUaN
EkHZUhS54Zbapq0AAlHGThTWWu9TToic0Fogfo0uxbTRj/YKvsYbGHXn+38UtVT4gl+Z+q34s2Mx
S+RksJLLbqa/UjuB2IA=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
k7VYfhbczr+tglBVnP2dNpzQUg4faERuh35S6DlbOXKmaLBzNWJuLZKd3/iHJso+4/ki/NZUVDCo
PIbVzwxMtfGyW1fMXDvveUi46OnejPwVxk5t1kIbtSbcZCd++dNgqg5UzMEgptRWzheZuzX0GigU
yFrxhwF/EKgqip1pp6C9cstz8ElT8YbfLOW5ZqJRuK3p8wRTUD9tZ+3ZT4AUQNnb5LwhJYd18bKy
gCZ5WG9Mj+aMW9valUSRFjEY4oFOYnca2u9dC1uGlv48Br0t9pUhfrmTbufRCalBxAR594dFK/W+
13kLKPWgZzIiZRLopKxSb3kx8JrEbJXF16BnhQ==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
TxEtvLMShWARGvALMwAihIuShrdtPpwirMDR7BzuLz8WzVhoqvJSM5/nLMHFGqovxD5hXGIA2TAw
UB0YVlq6K3gG1/oM4RpzHTN3yz8Lt5YW3A+UfuxJr1V9UVkS6LmvF75rPoruMKpllkRnQaQkrdOH
79erJYgSSdvNFj79HX4=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Jd4QdSkhWhpPJfQcqGINGTBbyQi4fwpgiNWDB3Wd2IjKeric0AmdHU7UViuSzCLh03DSaNG2q/XP
qatCMMw9/14uzhpUJU/1zUWxXlbRxdCkB/LSsYsRRmVRjaX8PHa9/COyOOXOwziBKCZ4EH/zCO32
LML+m8CiAQ/Hl3o7OkbgzReeGFKo2yT0AlTR1mlGeI1ujqvvwRe1Fai0g+TwEJcmsDU1/5bkvxQ8
aV49pZh6N2SUhTCJ+wLBZlcMIljfD3Bu8Sp/4tL/+j+yW2zEEf4Sl33jw0Cb08EifW3RF8BmuSm6
hUeX9HuDvEf347dVCR8t8qRzeC+0nGD4/fB1NQ==

`pragma protect key_keyowner="Real Intent", key_keyname="RI-RSA-KEY-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
nE6k/lSQEQ4OmPB4XqBcP/LpC07K/JJ0IvLqk0FbQzQZjzqT5yDvPsiRjELAcBvPJRahwOqlfyes
JDXxH4G+XSbtKQtE02yLheyEjNesZ0dv/v3vL+wA09O8khSrVyP5ijRndW00Cf5Bf2IpNiaJRcds
F1ushZZu9jXeBItrh4znBf9fOoXggbdnBLyNjuw7bRfvTeY2Xhe1Z7RpJLgPWMz3yKmlUVxO5Zyf
mjNu1+82dGuZ9x/eImCHDzcLcpca/TdMV0iJAkZHrvuhhu0GfQ7zgBbvuyb+I/r0q0vuL52PeEET
HDmGQS2oxiFTbcwiGY3t/ioXPJYkEEqNFUIzSA==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2021_07", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
EYYoCPbR+OMFlmBfBNcQ1RKQKD88wkYgxA5pkdacb5EuwAeven6zC8gsLrmbmaf1Y+GE+exjL/E8
csfwUz3cQq4551Y/pgVQB6wc+K/5qus2SV7wqxTpqsWY/Yu+bULiGuBSdS51qWlfxDNujKEBhRPN
GKWkQK8KP7xMHh1W8rO4WL7cLP0qnZ7xSovnz379iAYpAJOGf/f5GjM87wrRCh+60BUmNbENwN6h
Un/7huetrD2tvDcD67Ox5Dkto+nybbrNNH3ry0zh96Cq8sxNBI7cJ/iRp5kCBgqxCxELTa7hlTHW
RWkLjA2W/Y2HjatDbYo5U0A7bO8ORiG66IX0Kg==

`pragma protect key_keyowner="Metrics Technologies Inc.", key_keyname="DSim", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
q9bGXHBOyTLb3eTSnDNZfQbfjyoc3yN7NB+1C2N+mReGSJxWRtlWWn5HWbhvjoAJehclGC7OtjK2
ZSTJ0A3pHY3St3rul3liQXKD5kCQ9+vFLUhyKlQc08mhaOXPkXVrLBkSbJoneeg+zcwJuKQzPvv8
Se016G+DYsP9PPIjvWbgYSkDDPBmrvDI1+5mRe5HwZFGFGhAQNqFMnPAskAW1MwhObzaIpkQKTZT
7A6i2BjYT3UzWyOCYK2zgjiB9ZFwChUw4Bwh+H8Xf2j3ysF46VVr3Y/hfiRxPSHR8Jb8iMEkCJjf
nRAfkr8Y2ZxDL10aUR1VFpL5aHsLiRKnNRdZXw==

`pragma protect key_keyowner="Atrenta", key_keyname="ATR-SG-RSA-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=384)
`pragma protect key_block
nsakC0nZIZNi1X6ujQodgmUw2UIdYzuFQ4iAZwA9YfvRrxXUL7ynKQCgPpNVzwJk5S+CJlgNjRvH
avhNsBU4C+cBB3dvqouQ4tOLrtjvGCn/tgPDevuIaG5LBxGdZZ/MOgVEltPHWIYycz6nfuA5/Axp
6IIz71mUhQT3OW6kWYR5cK3zVKmHXkQGZxfNAWG/Pw5DHuc9xxTQpswaIv4ECw8olrxqfoRkzz/n
gmc1riU255Qanc8CpzTXkB0TXLYD8b3W4k0EIAYhAlKk5HVAVS9D3DfcWg27dKxRMm5dVH7ddpvn
9W7az/Gv4/jAcQ/A2wvn+5RGmVdmY2XJTvnb42j3M+6+R6PXkHvxDCRRgj7df9TYddZWyOeT0KQd
DnIaIlkFA345xytHveeTmDy6qVwsD6GrlsYJS9tCsR6FloMwjoQcZKSxBqfWh+rvQ8/8NxsGVy4v
3tFI5PwOhr5e4Nw4hm2q3u3mpmtv9+BzXIuf1HXxWr2eSaeu22WHlCsg

`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="CDS_RSA_KEY_VER_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
WuUgcS5b6yfqTuzjufwmIVC5kWm6y/3mx22Aii+Dgdcnv/uLoI9/njjHdhb7hUlsD3Xs1keDNIwN
3pNTWeUxyZTJzKR7udvlJMLBMym3o/ECBMv+uN4BToB/hl2qqhLvFAO/r5AFOlliZqDwiGcbQvyz
YxE2I3qA+lBeP2iX2/4t2ns07deHzxcGsGDpvkWpwNcM3RmD3m5puzv13u/mWj0iTjzSuDu+lCO3
EIjElwRdbJl/F7N/czlKYgmKd6feg7/nbSKTQgrJk+bEOJwzrhlLGQvovZgtfM2nxWwlvulcT7sS
n2ZxTDzZIZJeakYPGSP3PRWLzaOntLk4/JYNoQ==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
HAfLWwf5IE4nVH0RKu6Ckfcag4YISAB7GxmA74RLd0WtgVtvSg/hiI6xjdDBajL3WlsS8r0EeRuE
7k3XV6Iw18PLWYY7xEqYXN+4UCUMJuuhFnCKbupuHsoPe92DFCS1iQmSCu4KA4if6La2soKs0Eai
lizBuddfJbplTj7Z459Jc2VAD/slvgcakh9coxr57R1xf3xL+SqtbztnNWXTWebaVsMi9o1R8+q2
Bw6o2bthJTK5AjuaNFC1mXchmICuCVK92/JyceC3nXwexvYK1qRmiOyoTPwPOS9/j/gup9+/1Be6
vYxlYOcskfzyxWLNti298ohd6UCc2uC5C4Rl3w==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-PREC-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
DzCZLHkutR8dxKMJJC1uS/LdG9PoCtj5GsOR4GKxJSZTHbAW3Lwb4zUisDiKbo8nzvAc+Pc3aKIh
FZY+iEihN/UyNBp/ZVBx4xfw4KiNs0WcNidwHxnj/AmT0YahVcv3MBdpFE4TvDgOFqEqCr2KvrS5
K14RY6HsADqifYcgChtDVh4X+2Nen/oSD8dZS1qLOsyQr7ETEhogVmc4Gi3TE4/HYjm8lV5GRuJM
x1+0GPRONu+RFuc2B6sidWODYyJus0b7HVqnBAA8gMcV6twjAADrnyIqZwnPoiUCKAMzsDKVKhW3
GrlmNwP5uDSVq/4QrLJ59GIzFy3EXCfFTYr7nA==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 246464)
`pragma protect data_block
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
`pragma protect end_protected
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
    parameter GRES_WIDTH = 10000;
    parameter GRES_START = 10000;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    wire GRESTORE;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;
    reg GRESTORE_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;
    assign (strong1, weak0) GRESTORE = GRESTORE_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

    initial begin 
	GRESTORE_int = 1'b0;
	#(GRES_START);
	GRESTORE_int = 1'b1;
	#(GRES_WIDTH);
	GRESTORE_int = 1'b0;
    end

endmodule
`endif
