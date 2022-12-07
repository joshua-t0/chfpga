----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: JF Cliche
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--use work.chFPGA_Package.all;

-------- udp_mac package ------------
--! Defines the udp_mac entity as a component so we can  defer binding in conditional if-generate blocks
package udp_mac_package is

COMPONENT udp_mac is
  GENERIC (
    PHY_TYPE: string; -- -- "GMII": Alaska 881111 PHY,  or "SGMII": SFP module
    SGMII_CLOCK_SOURCE: string; --! *** NOT USED *** Selects the 125MHz clock source; "CLK125": uses the 125 MHz clock (clk125) from the main MMCM, "REFCLK": uses the GTX Reference clock (gtrefclk)
    BROADCAST_IP_PORT: integer;-- ! Port on which broadcast requests and replies are made. This is fixed as it is used to discover the boards on the network and configure them.
    SIM: boolean := FALSE --
    );

  PORT (
    -- Local addresses
    local_mac_addr: in std_logic_vector(47 downto 0);
    local_ip_addr: in std_logic_vector(31 downto 0);
    local_ip_port: in std_logic_vector(15 downto 0);
    local_subarray: in std_logic_vector(1 downto 0); --! Defines on which of the 4 broadcast ports this fpga will respond.

    -- Remote addresses
    remote_mac_addr0: in std_logic_vector(47 downto 0) := X"000000000000";
    remote_ip_addr0: in std_logic_vector(31 downto 0) := X"00000000";
    remote_ip_port0: in std_logic_vector(15 downto 0) := X"0000";

    remote_mac_addr1: in std_logic_vector(47 downto 0) := X"000000000000";
    remote_ip_addr1: in std_logic_vector(31 downto 0) := X"00000000";
    remote_ip_port1: in std_logic_vector(15 downto 0) := X"0000";

    ------------------------------------
    -- GMII PHY interface (Gbit Ethernet)
    -- (Marvell Alaska 10-100-1000BASE-T PHY, used if PHY_TYPE="GMII")
    ------------------------------------
    phy_rxclk : in std_logic:='0'; --Clock provided by the PHY to clock the RX bus
    phy_rxctrl_rxdv : in std_logic:='0';
    phy_rxd : in std_logic_vector(7 downto 0):=(others=>'0');
    phy_txclk : in std_logic:='0';-- Clock provided by the phy to clock the TX bus. We use clk125 instead for this purpose.
    phy_txer : out std_logic;
    phy_reset_l : out std_logic;
    phy_txc_gtxclk : out std_logic; -- Clock synchronous to the TX bus provided to the PHY
    phy_txctl_txen : out std_logic;
    phy_txd : out std_logic_vector(7 downto 0);

    ------------------------------------
    -- SGMII interface (Gbit Ethernet)
    -- (SFP transceiver, used if PHY_TYPE="SGMII")
    ------------------------------------

    sfp_tx_p : out std_logic; --! serialized data from the fpga mgt to the sfp
    sfp_tx_n : out std_logic;
    sfp_rx_p : in std_logic := '0'; --! serialized data from the sfp to the fpga mgt
    sfp_rx_n : in std_logic := '1';
    sfp_refclk_nobuf: in std_logic; -- Unbuffered 125 MHz SFP GTX reference clock reference clock for SGMII operation
    sfp_refclk_buf: in std_logic; -- Buffered 125 MHz SFP GTX reference clock reference clock for SGMII operation
    signal_detect: in std_logic := '1';

    -- Debugging/status signals

    status_vector : out std_logic_vector(15 downto 0); -- Core status.
    config_vector : in std_logic_vector(31 downto 0); -- Core status.
    mmcm_locked : out std_logic;
    reset_done: out std_logic;

    ------------------------------------
    -- UDP data interface
    ------------------------------------

    -- TX port

    s_axis_udp_tx_tvalid : in std_logic;
    s_axis_udp_tx_tdata : in  std_logic_vector (7 downto 0); -- will be axis_udp_tx_tdata
    s_axis_udp_tx_tlast : in std_logic;
    s_axis_udp_tx_tready: out std_logic;
    tx_port: in std_logic_vector(1 downto 0):="00";
    tx_overflow: out std_logic;

    -- RX port

    m_axis_udp_rx_tdata  : out std_logic_vector (7 downto 0);
    m_axis_udp_rx_tvalid : out std_logic;
    m_axis_udp_rx_tlast  : out std_logic;
    m_axis_udp_rx_tready : in std_logic;
    rx_overflow: out std_logic;

    ------------------------------------
    -- System
    ------------------------------------

    clk125: in std_logic; -- 125 Mhz clock for the UDP data interface and GMII PHY TX clock (SGMII uses sfp_refclk as a source)
    -- clk200: in std_logic; -- clock used for the SGMII reset logic. Must always be present.
    rst: in std_logic:='0'
    );

end COMPONENT;



end udp_mac_package;

--package body udp_mac_package is
--end udp_mac_package;
