library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity FFT2 is port (
    clk_1     : in  std_logic;
    ce_1      : in  std_logic;
    sync_in   : in  std_logic;
    in0       : in  std_logic_vector;
    in1       : in  std_logic_vector;
    in2       : in  std_logic_vector;
    in3       : in  std_logic_vector;
    shift     : in  std_logic_vector;
    sync_out  : out std_logic;
    out1      : out std_logic_vector;
    out2      : out std_logic_vector;
    overflow  : out std_logic
  );
end entity FFT2;
architecture stub of FFT2 is
begin
end stub;

library ieee;
use ieee.std_logic_1164.all;
entity pfb_fft_d3a_0 is
  port (
    clk      : in  std_logic;
    sync_in  : in  std_logic_vector;
    in0      : in  std_logic_vector;
    in1      : in  std_logic_vector;
    in2      : in  std_logic_vector;
    in3      : in  std_logic_vector;
    in4      : in  std_logic_vector;
    in5      : in  std_logic_vector;
    in6      : in  std_logic_vector;
    in7      : in  std_logic_vector;
    shift    : in  std_logic_vector;
    sync_out : out std_logic_vector;
    out0     : out std_logic_vector;
    out1     : out std_logic_vector;
    out2     : out std_logic_vector;
    out3     : out std_logic_vector;
    of_x0    : out std_logic_vector
  );
end entity pfb_fft_d3a_0;
architecture stub of pfb_fft_d3a_0 is
begin
end stub;

library ieee;
use ieee.std_logic_1164.all;
entity hirax_bit_growth_0 is
  port (
    clk      : in  std_logic;
    sync_in  : in  std_logic_vector;
    pol_in1  : in  std_logic_vector;
    pol_in2  : in  std_logic_vector;
    pol_in3  : in  std_logic_vector;
    pol_in4  : in  std_logic_vector;
    shift    : in  std_logic_vector;
    sync_out : out std_logic_vector;
    out00    : out std_logic_vector;
    out01    : out std_logic_vector;
    overflow : out std_logic_vector
  );
end entity hirax_bit_growth_0;
architecture stub of hirax_bit_growth_0 is
begin
end stub;

library ieee;
use ieee.std_logic_1164.all;
use work.chfpga_package.all;
entity udp_mac is
  generic (
    PHY_TYPE         : phy_type_enum := GMII;
    BROADCAST_IP_PORT: integer := 41000;
    SIM              : boolean
  );
  port (
    local_mac_addr : in  std_logic_vector;
    local_ip_addr  : in  std_logic_vector;
    local_ip_port  : in  std_logic_vector;
    local_subarray : in  std_logic_vector;
    remote_mac_addr0 : in  std_logic_vector;
    remote_ip_addr0  : in  std_logic_vector;
    remote_ip_port0  : in  std_logic_vector;
    remote_mac_addr1 : in  std_logic_vector;
    remote_ip_addr1  : in  std_logic_vector;
    remote_ip_port1  : in  std_logic_vector;
    phy_rxclk       : in  std_logic;
    phy_txer        : out std_logic;
    phy_reset_l     : out std_logic;
    phy_rxctrl_rxdv : in  std_logic;
    phy_rxd         : in  std_logic_vector;
    phy_txc_gtxclk  : out std_logic;
    phy_txctl_txen  : out std_logic;
    phy_txd         : out std_logic_vector;
    phy_txclk       : in  std_logic;
    sfp_tx_p : out std_logic;
    sfp_tx_n : out std_logic;
    sfp_rx_p : in  std_logic;
    sfp_rx_n : in  std_logic;
    sfp_refclk_nobuf : in  std_logic;
    sfp_refclk_buf   : in  std_logic;
    status_vector : out std_logic_vector;
    config_vector : in  std_logic_vector;
    mmcm_locked   : in  std_logic;
    reset_done    : in  std_logic;
    signal_detect : in  std_logic;
    s_axis_udp_tx_tvalid : in  std_logic;
    s_axis_udp_tx_tdata  : in  std_logic_vector;
    s_axis_udp_tx_tlast  : in  std_logic;
    s_axis_udp_tx_tready : out std_logic;
    tx_port              : in  std_logic_vector;
    m_axis_udp_rx_tdata  : out std_logic_vector;
    m_axis_udp_rx_tvalid : out std_logic;
    m_axis_udp_rx_tlast  : out std_logic;
    m_axis_udp_rx_tready : in  std_logic;
    tx_overflow : out std_logic;
    rx_overflow : out std_logic;
    clk125 : in  std_logic;
    rst    : in  std_logic
  );
end entity udp_mac;
architecture stub of udp_mac is
begin
end stub;

library ieee;
use ieee.std_logic_1164.all;
use work.chfpga_package.all;
entity sysmon is
	generic (
		PLATFORM_ID: integer
	);
	port (
		ctrl_cmd_in_dat: in AXIS8_DAT_STRUCT;
		ctrl_cmd_in_rdy: out AXIS8_RDY_STRUCT;
		ctrl_rply_out_dat: out AXIS8_DAT_STRUCT;
		ctrl_rply_out_rdy: in AXIS8_RDY_STRUCT;
		ctrl_clk: in  std_logic;
		ctrl_rst: in std_logic;
		vaux_curr_n: in  std_logic;
		vaux_curr_p: in  std_logic;
		vaux_volt_n: in  std_logic;
		vaux_volt_p: in  std_logic;
		vp: in  std_logic;
		vn: in  std_logic;
		fan_pwm: out std_logic;
		fan_tach: in std_logic := '0';
		sysmon_clk: in  std_logic;
		sysmon_rst: in std_logic
	);
end entity sysmon;
architecture stub of sysmon is
begin
end stub;

library ieee;
use ieee.std_logic_1164.all;
use work.chfpga_package.all;
entity bct_engine is
	generic (
		PLATFORM_ID: integer;
		NUMBER_OF_INPUT_LANES: integer := 16;
		BINS_PER_INPUT_WORD: integer   := 2;
		BITS_PER_INPUT_BIN: integer    := 8 + 8;
		INPUT_LANE_WIDTH: integer := BINS_PER_INPUT_WORD * BITS_PER_INPUT_BIN;
		CT_LEVEL: integer := 3;
		LANE_TO_LINK_MAP: integer_array := (
			  0 => -1,
			  1 => 0, 2=> 1, 3 => 2, 4 => 3,  5 => 4,  6 => 5,  7 => 6, 8=> 7, 9=> 8, 10=> 9, 11=> 10, 12=> 11, 13=> 12, 14=> 13, 15=> 14,
			  16 to 19 => -1,
			  20 => 15, 21 => 16, 22 => 17, 23=> 18);
		LINK_TO_QUAD_MAP: integer_array   := (0 to 3 => 0, 4 to 7 => 1, 8 to 11=> 2, 12 to 14 => 3, 15 to 18=> 4);
		QUAD_TO_REFCLK_MAP: integer_array := (0 => 1, 1 => 0, 2 => 0, 3=> 1, 4 => 1);
		LANE_TO_GROUP_MAP: integer_array  := (0 to 15 => 0, 16 to 23 => 1);
		INPUT_WORD_WIDTH: integer    := NUMBER_OF_INPUT_LANES * INPUT_LANE_WIDTH;
		BITS_PER_OUTPUT_BIN: integer := BITS_PER_INPUT_BIN / 2;
		OUTPUT_WORD_WIDTH: integer           := INPUT_WORD_WIDTH * BITS_PER_OUTPUT_BIN / BITS_PER_INPUT_BIN;
		NUMBER_OF_LINKS: integer             := max(LANE_TO_LINK_MAP) + 1;
		NUMBER_OF_REFCLK: integer            := max(QUAD_TO_REFCLK_MAP) + 1;
		NUMBER_OF_CROSSBAR1_OUTPUTS: integer := 16;
		BP_LINK_SPEED: integer               := 0
	);
	port (
		s_axis_tdata: in slv_array(0 to NUMBER_OF_INPUT_LANES - 1)(INPUT_LANE_WIDTH - 1 downto 0);
		s_axis_tuser: in slv_array(0 to NUMBER_OF_INPUT_LANES - 1)(3 downto 0);
		s_axis_tvalid: in std_logic;
		s_axis_tlast: in std_logic;
		m_axis_tvalid: out std_logic;
		m_axis_tdata: out slv(OUTPUT_WORD_WIDTH - 1 downto 0);
		m_axis_tlast: out std_logic;
		tx_p: out std_logic_vector(0 to NUMBER_OF_LINKS - 1);
		tx_n: out std_logic_vector(0 to NUMBER_OF_LINKS - 1);
		rx_p: in std_logic_vector(0 to NUMBER_OF_LINKS - 1);
		rx_n: in std_logic_vector(0 to NUMBER_OF_LINKS - 1);
		refclk_p: in std_logic_vector(0 to NUMBER_OF_REFCLK - 1);
		refclk_n: in std_logic_vector(0 to NUMBER_OF_REFCLK - 1);
		refclk_div2: out std_logic_vector(0 to NUMBER_OF_REFCLK - 1);
		txclk_div2: out std_logic;
		txclk_out: out std_logic;
		clk: in  std_logic;
		rst: in std_logic;
		align_pulse: out std_logic;
		bsb_cmd_dat: in AXIS8_DAT_STRUCT;
		bsb_cmd_rdy: out AXIS8_RDY_STRUCT;
		bsb_rply_dat: out AXIS8_DAT_STRUCT;
		bsb_rply_rdy: in AXIS8_RDY_STRUCT;
		bsb_clk: in  std_logic;
		bsb_rst: in  std_logic
	);
end entity bct_engine;
architecture stub of bct_engine is
begin
end stub;

library ieee;
use ieee.std_logic_1164.all;
use work.chfpga_package.all;
entity ADCDAQ is
	GENERIC (
		SAMPLES_PER_FRAME       : integer := 2048;
		IMPLEMENT_ADCDAQ 		: BOOLEAN:= TRUE;
		INSTANTIATE_IDELAYCTRL 	: BOOLEAN:= TRUE;
		INSTANTIATE_PLL 		: BOOLEAN:= FALSE;
		BUFMR_MAP 				: BUFMRIndexArray := (others=>0);
		IS_DIFFERENTIAL 		: BUFMRIndexArray := (others=>1);
		PROVIDE_BUFFERED_DIVCLK : BOOLEAN:= FALSE;
		USE_EXT_DATA_CLK 		: BOOLEAN:= TRUE;
		CLK_VALID_OFFSET 		: INTEGER:= -3;
		SIM 					: BOOLEAN:= FALSE
		);
	PORT
		(
		adc_data_h_p: in  std_logic_vector(7 downto 0);
		adc_data_h_n: in  std_logic_vector(7 downto 0);
		adc_clk_h_p : in  std_logic;
		adc_clk_h_n : in  std_logic;
		m_axis_adc_tdata 	: out std_logic_vector(31 downto 0);
		m_axis_adc_tvalid 	: out std_logic;
		m_axis_adc_tlast  	: out std_logic;
		m_axis_adc_tuser 	: out std_logic_vector(3 downto 0);
		data_ready 	: out std_logic;
		send_data 	: in std_logic:= '1';
		adc_clk 	: in std_logic;
		ioclk_out_pll 	: out  std_logic;
		divclk_out_pll 	: out  std_logic;
		divclk_out_bufr : out  std_logic;
		divclk_out_bufg : out  std_logic;
		adc_clk_out_div2: out  std_logic:='0';
		ioclk_in : in  std_logic;
		divclk_in : in  std_logic;
		adcdaq_reset : in  std_logic;
		ctrl_cmd_in_dat: in AXIS8_DAT_STRUCT;
		ctrl_cmd_in_rdy: out AXIS8_RDY_STRUCT;
		ctrl_rply_out_dat: out AXIS8_DAT_STRUCT;
		ctrl_rply_out_rdy: in AXIS8_RDY_STRUCT;
		ctrl_clk: in  std_logic;
		ctrl_rst: in  std_logic;
		ref_clk: in std_logic;
		clk200: in  std_logic
		);
end ADCDAQ;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.chFPGA_Package.ALL;
entity xge_array is
	generic (
		LANE_TO_QUAD_MAP: integer_array   := (0 to 3=> 0, 4 to 7=> 1);
		QUAD_TO_REFCLK_MAP: integer_array := (0 to 1=>0);
		NUMBER_OF_TX_LANES: integer      := LANE_TO_QUAD_MAP'LENGTH;
		NUMBER_OF_REFCLK: integer        := max(QUAD_TO_REFCLK_MAP)+1;
		DEFAULT_MAC_SRC_ADDR: slv48_array  := (0 to NUMBER_OF_TX_LANES - 1 => X"123456789ABC");
		DEFAULT_MAC_DEST_ADDR: slv48_array := (0 to NUMBER_OF_TX_LANES - 1 => X"FFFFFFFFFFFF");
		DEFAULT_IP_SRC_ADDR: slv32_array   := (0 to NUMBER_OF_TX_LANES - 1 => X"0A0A0A0B");
		DEFAULT_IP_DEST_ADDR: slv32_array  := (0 to NUMBER_OF_TX_LANES - 1 => X"0A0A0A0A");
		DEFAULT_IP_DEST_PORT: slv16_array  := (0 to NUMBER_OF_TX_LANES - 1 => X"A028");
		USE_LITTLE_ENDIAN: boolean := TRUE;
		SIM: boolean := false
	);
	port (
		tx_p: out std_logic_vector(0 to NUMBER_OF_TX_LANES - 1);
		tx_n: out std_logic_vector(0 to NUMBER_OF_TX_LANES - 1);
		rx_p: in std_logic_vector(0 to NUMBER_OF_TX_LANES - 1);
		rx_n: in std_logic_vector(0 to NUMBER_OF_TX_LANES - 1);
		refclk_p: in std_logic_vector(0 to NUMBER_OF_REFCLK - 1);
		refclk_n: in std_logic_vector(0 to NUMBER_OF_REFCLK - 1);
		refclk_div2: out std_logic_vector(0 to NUMBER_OF_REFCLK - 1);
		txclk_div2: out std_logic;
		clk322_out: out std_logic;
		s_axis_tx_tdata: in slv32_array(0 to NUMBER_OF_TX_LANES - 1);
		s_axis_tx_tvalid: in std_logic_vector(0 to NUMBER_OF_TX_LANES - 1);
		s_axis_tx_tlast: in std_logic_vector(0 to NUMBER_OF_TX_LANES - 1);
		s_axis_tx_tready: out std_logic_vector(0 to NUMBER_OF_TX_LANES - 1);
		s_axis_tx_clk: in std_logic_vector(0 to NUMBER_OF_TX_LANES - 1);
		cmd_dat: in AXIS8_DAT_STRUCT;
		cmd_rdy: out AXIS8_RDY_STRUCT;
		rply_dat: out AXIS8_DAT_STRUCT;
		rply_rdy: in AXIS8_RDY_STRUCT;
		ctrl_clk: in std_logic;
		ctrl_rst: in std_logic;
		areset: in std_logic
	);
end entity xge_array;
architecture stub of xge_array is
begin
end stub;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chFPGA_Package.all;
entity CORR44_ARRAY is
	GENERIC (
		PLATFORM_ID: integer;
		NUMBER_OF_CORRELATORS: integer;
		NUMBER_OF_WORDS_PER_BIN: integer
	);
	PORT (
		s_axis_tdata : in  slv32_array(0 to NUMBER_OF_CORRELATORS-1);
		s_axis_tvalid : in  slv(0 to NUMBER_OF_CORRELATORS-1);
		s_axis_tlast : in  slv(0 to NUMBER_OF_CORRELATORS-1);
		in_clk : in std_logic;
		in_rst: in std_logic;
		m_axis_data_out_tdata: out slv8_array(0 to NUMBER_OF_CORRELATORS-1);
		m_axis_data_out_tvalid: out slv(0 to NUMBER_OF_CORRELATORS-1);
		m_axis_data_out_tlast: out slv(0 to NUMBER_OF_CORRELATORS-1);
		m_axis_data_out_tready: in slv(0 to NUMBER_OF_CORRELATORS-1);
		out_clk : in std_logic;
		out_rst: in std_logic;
		cmd_dat:  in AXIS8_DAT_STRUCT;
		cmd_rdy:  out AXIS8_RDY_STRUCT;
		rply_dat: out AXIS8_DAT_STRUCT;
		rply_rdy: in AXIS8_RDY_STRUCT;
		ctrl_clk: in std_logic;
		ctrl_rst: in STD_LOGIC
		);
end CORR44_ARRAY;
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
ENTITY SCALER_CMUL IS
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
END SCALER_CMUL;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chFPGA_Package.ALL;
entity I2C is
	generic (
		NUMBER_OF_PORTS: integer;
		T_HIGH: real   := 4.0e-6;
		T_LOW: real    := 4.7e-6;
		CLK_FREQ: real := 200.0e6
	);
	port (
		ctrl_cmd_in_dat: in AXIS8_DAT_STRUCT;
		ctrl_cmd_in_rdy: out AXIS8_RDY_STRUCT;
		ctrl_rply_out_dat: out AXIS8_DAT_STRUCT;
		ctrl_rply_out_rdy: in AXIS8_RDY_STRUCT;
		ctrl_clk: in  std_logic;
		ctrl_rst: in std_logic;
		i2c_sck: inout std_logic_vector(NUMBER_OF_PORTS - 1 downto 0);
		i2c_sda: inout std_logic_vector(NUMBER_OF_PORTS - 1 downto 0);
		clk200: in std_logic;
		rst: in std_logic
	);
end entity I2C;
architecture stub of I2C is
begin
end stub;

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chFPGA_Package.ALL;
entity SPI is
	generic (
		NUMBER_OF_PORTS: integer;
		CLK_DIVIDE_FACTOR: integer := 200 / 4
	);
	port (
		ctrl_cmd_in_dat: in    AXIS8_DAT_STRUCT;
		ctrl_cmd_in_rdy: out   AXIS8_RDY_STRUCT;
		ctrl_rply_out_dat: out AXIS8_DAT_STRUCT;
		ctrl_rply_out_rdy: in  AXIS8_RDY_STRUCT;
		ctrl_clk: in  std_logic;
		ctrl_rst: in std_logic;
		spi_sck: out std_logic;
		spi_miso: in std_logic_vector(0 to NUMBER_OF_PORTS - 1);
		spi_mosi: out std_logic;
		spi_cs_n: out std_logic_vector(0 to NUMBER_OF_PORTS - 1);
		spi_addr: out std_logic_vector(2 downto 0);
		spi_rst_n: out std_logic;
		clk200: in std_logic;
		rst: in std_logic
	);
end entity SPI;
architecture stub of SPI is
begin
end stub;

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;
library work;
use work.chFPGA_Package.all;
entity cge is
	generic (
		DEFAULT_MAC_SRC_ADDR: slv48  := X"005d03000000";
		DEFAULT_MAC_DEST_ADDR: slv48 := X"FFFFFFFFFFFF";
		DEFAULT_IP_SRC_ADDR: slv32   := X"0AC00002";
		DEFAULT_IP_DEST_ADDR: slv32  := X"FFFFFFFF";
		DEFAULT_IP_DEST_PORT: slv16  := X"A028";
		IMPLEMENT_PACKET_GENERATOR: boolean := TRUE;
		SIM: boolean := FALSE
		);
	port (
		tx_p: out std_logic_vector(0 to 3);
		tx_n: out std_logic_vector(0 to 3);
		refclk_p: in std_logic;
		refclk_n: in std_logic;
		refclk_out: out std_logic;
		s_axis_tx_tdata: in std_logic_vector(255 downto 0) := (others => '0');
		s_axis_tx_tvalid: in std_logic := '0';
		s_axis_tx_tlast: in std_logic := '0';
		clk: in std_logic;
		clk322_out: out std_logic;
		rst: in std_logic;
		cmd_dat: in axis8_dat_struct := (TDATA => (others => '0'), TVALID => '0', TLAST => '0');
		cmd_rdy: out axis8_rdy_struct;
		rply_dat: out axis8_dat_struct;
		rply_rdy: in axis8_rdy_struct := (TREADY => '0');
		ctrl_clk: IN std_logic := '0';
		ctrl_rst: in std_logic := '0'
	 );
end entity cge;
architecture stub of cge is
begin
end stub;

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;
library work;
use work.chFPGA_Package.ALL;
entity uram_ct is
	generic (
		SIM: boolean := false
	);
	port (
		s_axis_in_tdata: in std_logic_vector(255 downto 0) := (others => '0');
		s_axis_in_tvalid: in std_logic                     := '0';
		s_axis_in_tlast: in std_logic                      := '0';
		m_axis_out_tdata: out std_logic_vector(255 downto 0);
		m_axis_out_tvalid: out std_logic := '0';
		m_axis_out_tlast: out std_logic  := '0';
		clk: in std_logic;
		rst: in std_logic;
		debug_out: out slv32;
		cmd_dat: in axis8_dat_struct  := (TDATA=> (others => '0'), TVALID=> '0', TLAST=> '0');
		cmd_rdy: out axis8_rdy_struct;
		rply_dat: out axis8_dat_struct;
		rply_rdy: in axis8_rdy_struct := (TREADY=> '0');
		ctrl_clk: in std_logic        := '0';
		ctrl_rst: in std_logic        := '0'
	);
end entity uram_ct;
architecture stub of uram_ct is
begin
end stub;

