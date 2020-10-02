----------------------------------------------------------------------------------
--! @file
-- Company: McGill University
-- Engineer: JF Cliche
--
-- Create Date:   2013-05-22
-- Design Name:  None
-- Module Name:    IP definition Package
-- Project Name: None
-- Target Devices: Kintex 7
-- Tool versions: Vivado 2013.2
-- Description: Provide definition of the IP cores as components so they can be instantiated as black boxes. This is needed to use the pre-synthesized IP feature of Vivado 2013.2
--
-- Dependencies:
--
-- Revision:
--  2013-06-30 JFC: Created
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;

-------- chFPGA Package ------------
--! @brief Defines the system-level constants and data types, declares the components used in the system, and provide support functions and procedures
package ip_package is


ATTRIBUTE SYN_BLACK_BOX : BOOLEAN;
ATTRIBUTE BLACK_BOX_PAD_PIN : STRING;



COMPONENT ACC_ACCUM_FIFO
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(71 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(71 DOWNTO 0);
    full : OUT STD_LOGIC;
    overflow : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC;
    underflow : OUT STD_LOGIC
  );
END COMPONENT;

--ATTRIBUTE SYN_BLACK_BOX OF ACC_ACCUM_FIFO : COMPONENT IS TRUE;
ATTRIBUTE BLACK_BOX_PAD_PIN OF ACC_ACCUM_FIFO : COMPONENT IS "rst,wr_clk,rd_clk,din[71:0],wr_en,rd_en,dout[71:0],full,overflow,empty,valid,underflow";

COMPONENT ACC_CAPTURE_FIFO
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(71 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(71 DOWNTO 0);
    full : OUT STD_LOGIC;
    overflow : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC;
    underflow : OUT STD_LOGIC
  );
END COMPONENT;

--ATTRIBUTE SYN_BLACK_BOX OF ACC_CAPTURE_FIFO : COMPONENT IS TRUE;
ATTRIBUTE BLACK_BOX_PAD_PIN OF ACC_CAPTURE_FIFO : COMPONENT IS "rst,wr_clk,rd_clk,din[71:0],wr_en,rd_en,dout[71:0],full,overflow,empty,valid,underflow";

COMPONENT ADCDAQ_FIFO
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    full : OUT STD_LOGIC;
    overflow : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC;
    underflow : OUT STD_LOGIC;
    prog_full : OUT STD_LOGIC
  );
END COMPONENT;

-- ATTRIBUTE SYN_BLACK_BOX OF ADCDAQ_FIFO : COMPONENT IS TRUE;
ATTRIBUTE BLACK_BOX_PAD_PIN OF ADCDAQ_FIFO : COMPONENT IS "rst,wr_clk,rd_clk,din[31:0],wr_en,rd_en,dout[31:0],full,overflow,empty,valid,underflow,rd_data_count[4:0],wr_data_count[4:0]";

-- component IO_PLL
-- port
--  (-- Clock in ports
--   CLK_IN1           : in     std_logic;
--   CLKFB_IN          : in     std_logic;
--   -- Clock out ports
--   CLK_OUT1          : out    std_logic;
--   CLK_OUT2          : out    std_logic;
--   CLK_OUT3          : out    std_logic;
--   CLKFB_OUT         : out    std_logic;
--   -- Dynamic reconfiguration ports
--   DADDR             : in     std_logic_vector( 6 downto 0);
--   DCLK              : in     std_logic;
--   DEN               : in     std_logic;
--   DIN                : in     std_logic_vector(15 downto 0);
--   DOUT                : out    std_logic_vector(15 downto 0);
--   DWE               : in     std_logic;
--   DRDY              : out    std_logic;
--   -- Status and control signals
--   RESET             : in     std_logic;
--   LOCKED            : out    std_logic
--  );
-- end component;

-- -- ATTRIBUTE SYN_BLACK_BOX OF IO_PLL : COMPONENT IS TRUE;
-- ATTRIBUTE BLACK_BOX_PAD_PIN OF IO_PLL : COMPONENT IS "CLK_IN1,CLKFB_INCLK_OUT1,CLK_OUT2,CLK_OUT3,CLKFB_OUT,DADDR[6:0],DCLK,DCLK,DEN,DIN[15:0],DOUT[15:0],DRDY,DWE,RESET,LOCKED";


COMPONENT AXI4S_REG_SLICE
  PORT (
    ACLK : IN STD_LOGIC;
    ARESETN : IN STD_LOGIC;
    S00_AXIS_ACLK : IN STD_LOGIC;
    S00_AXIS_ARESETN : IN STD_LOGIC;
    S00_AXIS_TVALID : IN STD_LOGIC;
    S00_AXIS_TREADY : OUT STD_LOGIC;
    S00_AXIS_TDATA : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    S00_AXIS_TLAST : IN STD_LOGIC;
    M00_AXIS_ACLK : IN STD_LOGIC;
    M00_AXIS_ARESETN : IN STD_LOGIC;
    M00_AXIS_TVALID : OUT STD_LOGIC;
    M00_AXIS_TREADY : IN STD_LOGIC;
    M00_AXIS_TDATA : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    M00_AXIS_TLAST : OUT STD_LOGIC
  );
END COMPONENT;

-- ATTRIBUTE SYN_BLACK_BOX OF AXI4S_REG_SLICE : COMPONENT IS TRUE;
ATTRIBUTE BLACK_BOX_PAD_PIN OF AXI4S_REG_SLICE : COMPONENT IS "ACLK,ARESETN,S00_AXIS_ACLK,S00_AXIS_ARESETN,S00_AXIS_TVALID,S00_AXIS_TREADY,S00_AXIS_TDATA[7:0],S00_AXIS_TLAST,M00_AXIS_ACLK,M00_AXIS_ARESETN,M00_AXIS_TVALID,M00_AXIS_TREADY,M00_AXIS_TDATA[7:0],M00_AXIS_TLAST,M00_SPARSE_TKEEP_REMOVED";


-------------------------------------------------------------------------------
-- PACKETIZER
-------------------------------------------------------------------------------

COMPONENT PACKETIZER_DATA_FIFO
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(33 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(33 DOWNTO 0);
    full : OUT STD_LOGIC;
    almost_full : OUT STD_LOGIC;
    overflow : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC
  );
END COMPONENT;

COMPONENT PACKETIZER_DATA_FLAGS_FIFO
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(32 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(32 DOWNTO 0);
    full : OUT STD_LOGIC;
    almost_full : OUT STD_LOGIC;
    overflow : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC
  );
END COMPONENT;

COMPONENT PACKETIZER_FRAME_FLAGS_FIFO
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    full : OUT STD_LOGIC;
    almost_full : OUT STD_LOGIC;
    overflow : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC
  );
END COMPONENT;


-------------------------------------------------------------------------------
-- CHAN_FIFO
-------------------------------------------------------------------------------

COMPONENT CHDIST_ALIGN_FIFO
  PORT (
    m_aclk : IN STD_LOGIC;
    s_aclk : IN STD_LOGIC;
    s_aresetn : IN STD_LOGIC;
    s_axis_tvalid : IN STD_LOGIC;
    s_axis_tready : OUT STD_LOGIC;
    s_axis_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axis_tlast : IN STD_LOGIC;
    s_axis_tuser : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axis_tvalid : OUT STD_LOGIC;
    m_axis_tready : IN STD_LOGIC;
    m_axis_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_tlast : OUT STD_LOGIC;
    m_axis_tuser : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axis_overflow : OUT STD_LOGIC
  );
END COMPONENT;
--ATTRIBUTE SYN_BLACK_BOX OF CHDIST_ALIGN_FIFO : COMPONENT IS TRUE;
-- ATTRIBUTE BLACK_BOX_PAD_PIN OF CHDIST_ALIGN_FIFO : COMPONENT IS "m_aclk,s_aclk,s_aresetn,s_axis_tvalid,s_axis_tready,s_axis_tdata[31:0],s_axis_tlast,s_axis_tuser[3:0],m_axis_tvalid,m_axis_tready,m_axis_tdata[31:0],m_axis_tlast,m_axis_tuser[3:0]";

COMPONENT XGLINK_RX_DATA_FIFO
  PORT (
    m_aclk : IN STD_LOGIC;
    s_aclk : IN STD_LOGIC;
    s_aresetn : IN STD_LOGIC;
    s_axis_tvalid : IN STD_LOGIC;
    s_axis_tready : OUT STD_LOGIC;
    s_axis_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axis_tlast : IN STD_LOGIC;
    s_axis_tuser : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    m_axis_tvalid : OUT STD_LOGIC;
    m_axis_tready : IN STD_LOGIC;
    m_axis_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_tlast : OUT STD_LOGIC;
    m_axis_tuser : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    axis_overflow : OUT STD_LOGIC
  );
END COMPONENT;

-------------------------------------------------------------------------------
-- CHAN_BIN_SEL
-------------------------------------------------------------------------------

COMPONENT MASK_RAM
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    clkb : IN STD_LOGIC;
    web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addrb : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    dinb : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
  );
END COMPONENT;



COMPONENT CHDIST_DATA_FIFO
  PORT (
    clk : IN STD_LOGIC;
    srst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(35 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    full : OUT STD_LOGIC;
    overflow : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC
  );
END COMPONENT;

--ATTRIBUTE SYN_BLACK_BOX OF CHDIST_DATA_FIFO : COMPONENT IS TRUE;
ATTRIBUTE BLACK_BOX_PAD_PIN OF CHDIST_DATA_FIFO : COMPONENT IS "srst,wr_clk,rd_clk,din[32:0],wr_en,rd_en,dout[32:0],full,overflow,empty,valid";




-------------------------------------------------------------------------------
-- SHUFFLE CROSSBAR
-------------------------------------------------------------------------------

COMPONENT SHUFFLE_CROSSBAR_ALIGN_FIFO
  PORT (
    clk : IN STD_LOGIC;
    srst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(35 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    full : OUT STD_LOGIC;
    overflow : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    almost_empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC;
    data_count : OUT STD_LOGIC_VECTOR(9 DOWNTO 0)

  );
END COMPONENT;

-------------------------------------------------------------------------------
-- SHUFFLE_BIN_SEL
-------------------------------------------------------------------------------


COMPONENT SHUFFLE_BIN_SEL_MASK_RAM
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    clkb : IN STD_LOGIC;
    web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    dinb : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
  );
END COMPONENT;


COMPONENT SHUFFLE_BIN_SEL_DATA_FIFO_BRAM
  PORT (
    clk : IN STD_LOGIC;
    srst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(34 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(34 DOWNTO 0);
    full : OUT STD_LOGIC;
    overflow : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC
  );
END COMPONENT;

COMPONENT SHUFFLE_BIN_SEL_DATA_FIFO_DRAM
  PORT (
    clk : IN STD_LOGIC;
    srst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(34 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(34 DOWNTO 0);
    full : OUT STD_LOGIC;
    overflow : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
END COMPONENT;

COMPONENT SHUFFLE_BIN_SEL_FLAGS_FIFO6
  PORT (
    clk : IN STD_LOGIC;
    srst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    full : OUT STD_LOGIC;
    overflow : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC;
    data_count : OUT STD_LOGIC_VECTOR(5 DOWNTO 0)
  );
END COMPONENT;

COMPONENT SHUFFLE_BIN_SEL_FLAGS_FIFO4
  PORT (
    clk : IN STD_LOGIC;
    srst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    full : OUT STD_LOGIC;
    overflow : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC;
    data_count : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;



COMPONENT CHDIST_FRAME_FIFO
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(32 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(32 DOWNTO 0);
    full : OUT STD_LOGIC;
    overflow : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC
  );
END COMPONENT;

--ATTRIBUTE SYN_BLACK_BOX OF CHDIST_FRAME_FIFO : COMPONENT IS TRUE;
--ATTRIBUTE BLACK_BOX_PAD_PIN OF CHDIST_FRAME_FIFO : COMPONENT IS "rst,wr_clk,rd_clk,din[31:0],wr_en,rd_en,dout[31:0],full,overflow,empty,valid";

COMPONENT CHDIST_SCALER_FLAGS_FIFO
  PORT (
    clk : IN STD_LOGIC;
    srst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(32 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(32 DOWNTO 0);
    full : OUT STD_LOGIC;
    overflow : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC
  );
END COMPONENT;


-------------------------------------------------------------------------------
-- COMMAND SYSTEM COMPONENTS
-------------------------------------------------------------------------------


COMPONENT CMD_FIFO
  PORT (
    m_aclk : IN STD_LOGIC;
    s_aclk : IN STD_LOGIC;
    s_aresetn : IN STD_LOGIC;
    s_axis_tvalid : IN STD_LOGIC;
    s_axis_tready : OUT STD_LOGIC;
    s_axis_tdata : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    s_axis_tlast : IN STD_LOGIC;
    m_axis_tvalid : OUT STD_LOGIC;
    m_axis_tready : IN STD_LOGIC;
    m_axis_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    m_axis_tlast : OUT STD_LOGIC
  );
END COMPONENT;

-- ATTRIBUTE SYN_BLACK_BOX OF CMD_FIFO : COMPONENT IS TRUE;
ATTRIBUTE BLACK_BOX_PAD_PIN OF CMD_FIFO : COMPONENT IS "m_aclk,s_aclk,s_aresetn,s_axis_tvalid,s_axis_tready,s_axis_tdata[7:0],s_axis_tlast,m_axis_tvalid,m_axis_tready,m_axis_tdata[7:0],m_axis_tlast";


-------------------------------------------------------------------------------
-- SCALER Components
-------------------------------------------------------------------------------


COMPONENT SCALER_CMUL
  PORT (
    aclk : IN STD_LOGIC;
    s_axis_a_tvalid : IN STD_LOGIC;
    s_axis_a_tuser : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    s_axis_a_tlast : IN STD_LOGIC;
    s_axis_a_tdata : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
    s_axis_b_tvalid : IN STD_LOGIC;
    s_axis_b_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_dout_tvalid : OUT STD_LOGIC;
    m_axis_dout_tuser : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axis_dout_tlast : OUT STD_LOGIC;
    m_axis_dout_tdata : OUT STD_LOGIC_VECTOR(79 DOWNTO 0)
  );
END COMPONENT;


COMPONENT SCALER_COEFF_RAM
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    clkb : IN STD_LOGIC;
    web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    dinb : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
  );
END COMPONENT;


COMPONENT CMUL
  PORT (
    aclk : IN STD_LOGIC;
    aresetn : IN STD_LOGIC;
    s_axis_a_tvalid : IN STD_LOGIC;
    s_axis_a_tlast : IN STD_LOGIC;
    s_axis_a_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    s_axis_b_tvalid : IN STD_LOGIC;
    s_axis_b_tlast : IN STD_LOGIC;
    s_axis_b_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_dout_tvalid : OUT STD_LOGIC;
    m_axis_dout_tlast : OUT STD_LOGIC;
    m_axis_dout_tdata : OUT STD_LOGIC_VECTOR(47 DOWNTO 0)
  );
END COMPONENT;

--ATTRIBUTE SYN_BLACK_BOX OF CMUL : COMPONENT IS TRUE;
ATTRIBUTE BLACK_BOX_PAD_PIN OF CMUL : COMPONENT IS "aclk,aresetn,s_axis_a_tvalid,s_axis_a_tlast,s_axis_a_tdata[15:0],s_axis_b_tvalid,s_axis_b_tlast,s_axis_b_tdata[31:0],m_axis_dout_tvalid,m_axis_dout_tlast,m_axis_dout_tdata[47:0]";


COMPONENT CORR_ADD
  PORT (
    A : IN STD_LOGIC_VECTOR(33 DOWNTO 0);
    B : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    CLK : IN STD_LOGIC;
    BYPASS : IN STD_LOGIC;
    S : OUT STD_LOGIC_VECTOR(33 DOWNTO 0)
  );
END COMPONENT;

--ATTRIBUTE SYN_BLACK_BOX OF CORR_ADD : COMPONENT IS TRUE;
ATTRIBUTE BLACK_BOX_PAD_PIN OF CORR_ADD : COMPONENT IS "A[33:0],B[16:0],CLK,BYPASS,S[33:0]";


-- COMPONENT gmii_to_sgmii_bridge
--   PORT (
--     gtrefclk : IN STD_LOGIC;
--     txn : OUT STD_LOGIC;
--     txp : OUT STD_LOGIC;
--     rxn : IN STD_LOGIC;
--     rxp : IN STD_LOGIC;
--     txoutclk : OUT STD_LOGIC;
--     resetdone : OUT STD_LOGIC;
--     mmcm_locked : IN STD_LOGIC;
--     userclk : IN STD_LOGIC;
--     userclk2 : IN STD_LOGIC;
--     independent_clock_bufg : IN STD_LOGIC;
--     drpaddr_in : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
--     drpclk_in : IN STD_LOGIC;
--     drpdi_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
--     drpdo_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
--     drpen_in : IN STD_LOGIC;
--     drprdy_out : OUT STD_LOGIC;
--     drpwe_in : IN STD_LOGIC;
--     pma_reset : IN STD_LOGIC;
--     gmii_txd : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
--     gmii_tx_en : IN STD_LOGIC;
--     gmii_tx_er : IN STD_LOGIC;
--     gmii_rxd : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
--     gmii_rx_dv : OUT STD_LOGIC;
--     gmii_rx_er : OUT STD_LOGIC;
--     gmii_isolate : OUT STD_LOGIC;
--     configuration_vector : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
--     status_vector : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
--     reset : IN STD_LOGIC;
--     signal_detect : IN STD_LOGIC
--   );
-- END COMPONENT;

--# Core v15
COMPONENT gmii_to_sgmii_bridge
  PORT (
    gtrefclk_bufg : IN STD_LOGIC;
    gtrefclk : IN STD_LOGIC;
    txn : OUT STD_LOGIC;
    txp : OUT STD_LOGIC;
    rxn : IN STD_LOGIC;
    rxp : IN STD_LOGIC;
    independent_clock_bufg : IN STD_LOGIC;
    txoutclk : OUT STD_LOGIC;
    rxoutclk : OUT STD_LOGIC;
    resetdone : OUT STD_LOGIC;
    cplllock : OUT STD_LOGIC;
    mmcm_reset : OUT STD_LOGIC;
    userclk : IN STD_LOGIC;
    userclk2 : IN STD_LOGIC;
    pma_reset : IN STD_LOGIC;
    mmcm_locked : IN STD_LOGIC;
    rxuserclk : IN STD_LOGIC;
    rxuserclk2 : IN STD_LOGIC;
    gmii_txd : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    gmii_tx_en : IN STD_LOGIC;
    gmii_tx_er : IN STD_LOGIC;
    gmii_rxd : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    gmii_rx_dv : OUT STD_LOGIC;
    gmii_rx_er : OUT STD_LOGIC;
    gmii_isolate : OUT STD_LOGIC;
    configuration_vector : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    status_vector : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    reset : IN STD_LOGIC;
    signal_detect : IN STD_LOGIC;
    gt0_qplloutclk_in : IN STD_LOGIC;
    gt0_qplloutrefclk_in : IN STD_LOGIC;
    gt0_rxchariscomma_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    gt0_rxcharisk_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    gt0_rxbyteisaligned_out : OUT STD_LOGIC;
    gt0_rxbyterealign_out : OUT STD_LOGIC;
    gt0_rxcommadet_out : OUT STD_LOGIC;
    gt0_txpolarity_in : IN STD_LOGIC;
    gt0_txdiffctrl_in : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    gt0_txpostcursor_in : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    gt0_txprecursor_in : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    gt0_rxpolarity_in : IN STD_LOGIC;
    gt0_txinhibit_in : IN STD_LOGIC;
    gt0_txprbssel_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    gt0_txprbsforceerr_in : IN STD_LOGIC;
    gt0_rxprbscntreset_in : IN STD_LOGIC;
    gt0_rxprbserr_out : OUT STD_LOGIC;
    gt0_rxprbssel_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    gt0_loopback_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    gt0_txresetdone_out : OUT STD_LOGIC;
    gt0_rxresetdone_out : OUT STD_LOGIC;
    gt0_rxdisperr_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    gt0_txbufstatus_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    gt0_rxnotintable_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    gt0_eyescanreset_in : IN STD_LOGIC;
    gt0_eyescandataerror_out : OUT STD_LOGIC;
    gt0_eyescantrigger_in : IN STD_LOGIC;
    gt0_rxcdrhold_in : IN STD_LOGIC;
    gt0_rxpmareset_in : IN STD_LOGIC;
    gt0_txpmareset_in : IN STD_LOGIC;
    gt0_rxpcsreset_in : IN STD_LOGIC;
    gt0_txpcsreset_in : IN STD_LOGIC;
    gt0_rxbufreset_in : IN STD_LOGIC;
    gt0_rxbufstatus_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    gt0_rxdfelpmreset_in : IN STD_LOGIC;
    gt0_rxdfeagcovrden_in : IN STD_LOGIC;
    gt0_rxlpmen_in : IN STD_LOGIC;
    gt0_rxmonitorout_out : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
    gt0_rxmonitorsel_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    gt0_drpaddr_in : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    gt0_drpclk_in : IN STD_LOGIC;
    gt0_drpdi_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    gt0_drpdo_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    gt0_drpen_in : IN STD_LOGIC;
    gt0_drprdy_out : OUT STD_LOGIC;
    gt0_drpwe_in : IN STD_LOGIC;
    gt0_dmonitorout_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;

-- ATTRIBUTE SYN_BLACK_BOX OF gmii_to_sgmii_bridge : COMPONENT IS TRUE;
-- ATTRIBUTE BLACK_BOX_PAD_PIN OF gmii_to_sgmii_bridge : COMPONENT IS "gtrefclk_p,gtrefclk_n,gtrefclk_out,txn,txp,rxn,rxp,independent_clock_bufg,userclk_out,userclk2_out,rxuserclk_out,rxuserclk2_out,resetdone,pma_reset_out,mmcm_locked_out,gmii_txd[7:0],gmii_tx_en,gmii_tx_er,gmii_rxd[7:0],gmii_rx_dv,gmii_rx_er,gmii_isolate,configuration_vector[4:0],status_vector[15:0],reset,signal_detect,gt0_qplloutclk_out,gt0_qplloutrefclk_out";

--ATTRIBUTE SYN_BLACK_BOX OF MASK_RAM : COMPONENT IS TRUE;
-- ATTRIBUTE BLACK_BOX_PAD_PIN OF MASK_RAM : COMPONENT IS "clka,wea[0:0],addra[6:0],dina[7:0],douta[7:0],clkb,web[0:0],addrb[9:0],dinb[0:0],doutb[0:0]";



COMPONENT PROBER_DATA_FIFO
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(35 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    full : OUT STD_LOGIC;
    almost_full : OUT STD_LOGIC;
    overflow : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC
  );
END COMPONENT;

-- ATTRIBUTE SYN_BLACK_BOX OF PROBER_DATA_FIFO : COMPONENT IS TRUE;
--ATTRIBUTE BLACK_BOX_PAD_PIN OF PROBER_DATA_FIFO : COMPONENT IS "rst,wr_clk,rd_clk,din[35:0],wr_en,rd_en,dout[8:0],full,overflow,empty,valid";


COMPONENT PROBER_FRAME_FIFO
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    full : OUT STD_LOGIC;
    almost_full : OUT STD_LOGIC;
    overflow : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC
  );
END COMPONENT;

-- ATTRIBUTE SYN_BLACK_BOX OF PROBER_FRAME_FIFO : COMPONENT IS TRUE;
--ATTRIBUTE BLACK_BOX_PAD_PIN OF PROBER_FRAME_FIFO : COMPONENT IS "rst,wr_clk,rd_clk,din[8:0],wr_en,rd_en,dout[8:0],full,overflow,empty,valid";


-- COMPONENT FrameDist_Ctrl_FIFO
--   PORT (
--     rst : IN STD_LOGIC;
--     wr_clk : IN STD_LOGIC;
--     rd_clk : IN STD_LOGIC;
--     din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
--     wr_en : IN STD_LOGIC;
--     rd_en : IN STD_LOGIC;
--     dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
--     full : OUT STD_LOGIC;
--     overflow : OUT STD_LOGIC;
--     empty : OUT STD_LOGIC;
--     valid : OUT STD_LOGIC;
--     rd_data_count : OUT STD_LOGIC_VECTOR(9 DOWNTO 0)
--   );
-- END COMPONENT;
-- ATTRIBUTE SYN_BLACK_BOX OF FrameDist_Ctrl_FIFO : COMPONENT IS TRUE;
-- ATTRIBUTE BLACK_BOX_PAD_PIN OF FrameDist_Ctrl_FIFO : COMPONENT IS "rst,wr_clk,rd_clk,din[7:0],wr_en,rd_en,dout[31:0],full,overflow,empty,valid,rd_data_count[9:0]";

COMPONENT FUNCGEN_RAM
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    clkb : IN STD_LOGIC;
    web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    dinb : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;



-- COMPONENT UDP_MAC_FRAME_FIFO
--   PORT (
--     rst : IN STD_LOGIC;
--     wr_clk : IN STD_LOGIC;
--     rd_clk : IN STD_LOGIC;
--     din : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
--     wr_en : IN STD_LOGIC;
--     rd_en : IN STD_LOGIC;
--     dout : OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
--     full : OUT STD_LOGIC;
--     overflow : OUT STD_LOGIC;
--     empty : OUT STD_LOGIC
--   );
-- END COMPONENT;


COMPONENT udp_mac_rx_data_fifo
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    full : OUT STD_LOGIC;
    almost_full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC
  );
END COMPONENT;

-- ATTRIBUTE SYN_BLACK_BOX OF udp_mac_rx_data_fifo : COMPONENT IS TRUE;
ATTRIBUTE BLACK_BOX_PAD_PIN OF udp_mac_rx_data_fifo : COMPONENT IS "rst,wr_clk,rd_clk,din[8:0],wr_en,rd_en,dout[8:0],full,almost_full,empty,valid";

COMPONENT udp_mac_rx_frame_fifo
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    full : OUT STD_LOGIC;
    overflow : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC
  );
END COMPONENT;

-- ATTRIBUTE SYN_BLACK_BOX OF udp_mac_rx_frame_fifo : COMPONENT IS TRUE;
ATTRIBUTE BLACK_BOX_PAD_PIN OF udp_mac_rx_frame_fifo : COMPONENT IS "rst,wr_clk,rd_clk,din[0:0],wr_en,rd_en,dout[0:0],full,overflow,empty,valid";

COMPONENT udp_mac_tx_data_fifo
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    full : OUT STD_LOGIC;
    almost_full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    wr_rst_busy : OUT STD_LOGIC;
    rd_rst_busy : OUT STD_LOGIC
  );
END COMPONENT;
-- ATTRIBUTE SYN_BLACK_BOX OF udp_mac_tx_data_fifo : COMPONENT IS TRUE;
ATTRIBUTE BLACK_BOX_PAD_PIN OF udp_mac_tx_data_fifo : COMPONENT IS "rst,wr_clk,rd_clk,din[7:0],wr_en,rd_en,dout[7:0],full,empty";


COMPONENT udp_mac_tx_frame_fifo
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
    full : OUT STD_LOGIC;
    almost_full : OUT STD_LOGIC;
    overflow : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
END COMPONENT;

-- ATTRIBUTE SYN_BLACK_BOX OF udp_mac_tx_frame_fifo : COMPONENT IS TRUE;
ATTRIBUTE BLACK_BOX_PAD_PIN OF udp_mac_tx_frame_fifo : COMPONENT IS "rst,wr_clk,rd_clk,din[17:0],wr_en,rd_en,dout[17:0],full,overflow,empty";


COMPONENT XGMII_UDP_MAC_TX_DATA_FIFO
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(65 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(65 DOWNTO 0);
    full : OUT STD_LOGIC;
    overflow : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC
  );
END COMPONENT;

-- ATTRIBUTE SYN_BLACK_BOX OF XGMII_UDP_MAC_TX_DATA_FIFO : COMPONENT IS TRUE;
ATTRIBUTE BLACK_BOX_PAD_PIN OF XGMII_UDP_MAC_TX_DATA_FIFO : COMPONENT IS "rst,wr_clk,rd_clk,din[33:0],wr_en,rd_en,dout[67:0],full,empty,valid";


COMPONENT XGMII_UDP_MAC_TX_HEADER_FIFO
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
    full : OUT STD_LOGIC;
    overflow : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC
  );
END COMPONENT;

-- ATTRIBUTE SYN_BLACK_BOX OF XGMII_UDP_MAC_TX_HEADER_FIFO : COMPONENT IS TRUE;
ATTRIBUTE BLACK_BOX_PAD_PIN OF XGMII_UDP_MAC_TX_HEADER_FIFO : COMPONENT IS "rst,wr_clk,rd_clk,din[17:0],wr_en,rd_en,dout[17:0],full,empty,valid";



COMPONENT xge_pcs_pma
  PORT (
    clk156 : IN STD_LOGIC;
    dclk : IN STD_LOGIC;
    txusrclk : IN STD_LOGIC;
    txusrclk2 : IN STD_LOGIC;
    areset : IN STD_LOGIC;
    txclk322 : OUT STD_LOGIC;
    areset_clk156 : IN STD_LOGIC;
    gttxreset : IN STD_LOGIC;
    gtrxreset : IN STD_LOGIC;
    txuserrdy : IN STD_LOGIC;
    qplllock : IN STD_LOGIC;
    qplloutclk : IN STD_LOGIC;
    qplloutrefclk : IN STD_LOGIC;
    reset_counter_done : IN STD_LOGIC;
    txp : OUT STD_LOGIC;
    txn : OUT STD_LOGIC;
    rxp : IN STD_LOGIC;
    rxn : IN STD_LOGIC;
    xgmii_txd : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    xgmii_txc : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    xgmii_rxd : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    xgmii_rxc : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    configuration_vector : IN STD_LOGIC_VECTOR(535 DOWNTO 0);
    status_vector : OUT STD_LOGIC_VECTOR(447 DOWNTO 0);
    core_status : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    tx_resetdone : OUT STD_LOGIC;
    rx_resetdone : OUT STD_LOGIC;
    signal_detect : IN STD_LOGIC;
    tx_fault : IN STD_LOGIC;
    drp_req : OUT STD_LOGIC;
    drp_gnt : IN STD_LOGIC;
    drp_den_o : OUT STD_LOGIC;
    drp_dwe_o : OUT STD_LOGIC;
    drp_daddr_o : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    drp_di_o : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    drp_drdy_o : OUT STD_LOGIC;
    drp_drpdo_o : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    drp_den_i : IN STD_LOGIC;
    drp_dwe_i : IN STD_LOGIC;
    drp_daddr_i : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    drp_di_i : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    drp_drdy_i : IN STD_LOGIC;
    drp_drpdo_i : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    tx_disable : OUT STD_LOGIC;
    pma_pmd_type : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    gt0_eyescanreset : IN STD_LOGIC;
    gt0_eyescandataerror : OUT STD_LOGIC;
    gt0_txbufstatus : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    gt0_rxbufstatus : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    gt0_eyescantrigger : IN STD_LOGIC;
    gt0_rxcdrhold : IN STD_LOGIC;
    gt0_txprbsforceerr : IN STD_LOGIC;
    gt0_txpolarity : IN STD_LOGIC;
    gt0_rxpolarity : IN STD_LOGIC;
    gt0_rxprbserr : OUT STD_LOGIC;
    gt0_txpmareset : IN STD_LOGIC;
    gt0_rxpmareset : IN STD_LOGIC;
    gt0_txresetdone : OUT STD_LOGIC;
    gt0_rxresetdone : OUT STD_LOGIC;
    gt0_rxdfelpmreset : IN STD_LOGIC;
    gt0_rxlpmen : IN STD_LOGIC;
    gt0_dmonitorout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    gt0_rxrate : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    gt0_txprecursor : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    gt0_txpostcursor : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    gt0_txdiffctrl : IN STD_LOGIC_VECTOR(3 DOWNTO 0)
  );
END COMPONENT;


end ip_package;

package body ip_package is
end ip_package;
