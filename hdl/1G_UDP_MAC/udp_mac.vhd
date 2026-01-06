----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: JF Cliche
--
-- Create Date:    06:51:55 03/12/2011
-- Design Name:
-- Module Name:    UDP_MAC
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description: UDP packet transmitter/receiver interface
--
-- Dependencies:
--
-- Revision:
-- 	2011-03-12 JFC: Created wrapper
--  2011-07-09 JFC: Implemented DUMMY functionnality
--  2013-08-01 : Copied the new dual GMII/SGMII version from DFMUX and embedded RX and TX max to eliminate UDP_MAC. Renamed this one UDP_MAC instead of UDP_PHY.

-- Additional Comments:
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

use work.chfpga_package.all; -- Get all component definitions

-- UDP_MAC: Lightweight UDP/IP/Ethernet 1G Ethernet packet transmitter/receiver stack
--
-- This module implements a Gigabit Ethernet UDP packet transmitter/receiver. It is comprised of a
-- monolithic UDP Ethernet packet encoder and UDP Packet that can connect to a PHY with a parallel
-- GMII interface (such as a Alaska 881111 PHY). The module can optionnally implement  GMII-to-SGMII
-- Xilinx core that allows the use of a serial SGMII PHY interface (such aa a SFP adapter).
--
-- The UDP receiver/transmitter implement a very simple ARP protocol.
--
-- The UDP receivers listen to a single MAC/IP/port, which are set by ``std_logic_vector`` input signals
-- and can therefore be set by the top level application.
--
-- The UDP transmitter can send data to two MAC/IP/port destinations (a.k.a. transmit channels).
-- Those destinations are also set by ``std_logic_vector`` signals. Each packet presented on the
-- data input interface is accompanied by a ``tx_port`` signal that tags this packet for one or the
-- other transmit channels. If the destination MAC/IP/Port is set to zero, the tranmitter will send
-- the packet to the source MAC/IP/Port of the last packet that was received.
--
-- The user data interfce is implemented as a AXI4-Streaming blocking interface with a 8-bit-wide
-- data bus. Both the tx and rx data is clocked on a single ``clk125`` clock.
--
-- If the SGMII interface is used, an connection to an external reference clock that can drive the
-- GTX transceiver has to be provided. A BUFG-buffered version of the same clock shall also be
-- provided to clock the SGMII internal logic.
--
entity udp_mac is
	GENERIC (
		PHY_TYPE: phy_type_enum; -- -- "GMII": Alaska 881111 PHY,  or "SGMII": SFP module
		BROADCAST_IP_PORT: integer;-- ! Port on which broadcast requests and replies are made. This is fixed as it is used to discover the boards on the network and configure them.
		SIM: boolean := FALSE --
		);

	PORT (
		-- Local addresses
		
		local_mac_addr: in std_logic_vector(47 downto 0);
		local_ip_addr: in std_logic_vector(31 downto 0);
		local_ip_port: in std_logic_vector(15 downto 0);
		local_subarray: in std_logic_vector(1 downto 0); -- Defines on which of the 4 broadcast ports this fpga will respond.

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
		phy_txc_gtxclk : out std_logic; -- Clock synchronous to the TX bus provided to the PHY. Is clk125.
		phy_txctl_txen : out std_logic;
		phy_txd : out std_logic_vector(7 downto 0);

		------------------------------------
		-- SGMII interface (Gbit Ethernet)
		-- (SFP transceiver, used if PHY_TYPE="SGMII")
		------------------------------------

		sfp_tx_p : out std_logic; -- serialized data from the fpga mgt to the sfp
		sfp_tx_n : out std_logic;
		sfp_rx_p : in std_logic := '0'; -- serialized data from the sfp to the fpga mgt
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

end udp_mac;

architecture IMPL of udp_mac is

-- GMII signals

signal gmii_rxclk :   std_logic;
signal gmii_rxdv:   std_logic;
signal gmii_rxd:   std_logic_vector(7 downto 0);
signal gmii_txclk:  std_logic;-- // clock is supplied by the phy - we do not use it

signal gmii_reset_l:  std_logic;
signal gmii_txer: std_logic;
signal gmii_txc_gtxclk:  std_logic;
signal gmii_txen:  std_logic;
signal gmii_txd:   std_logic_vector(7 downto 0);

--signal phy_rxclk: std_logic;
--signal phy_txclk: std_logic;

--signal status_vector: std_logic_vector(15 downto 0);
signal gmii_clk: std_logic; -- clock provided by the SGMII core to clock both the TX and RX GMII interface side

signal gtrefclk       : std_logic;                    -- Route gtrefclk through an IBUFG.
signal gtrefclk_i     : std_logic;
signal gtrefclk_buf_i : std_logic;                    -- Route gtrefclk through an IBUFG.
-- signal refclk_sel: std_logic;
-- Set the SAVE attribute to prevent the toold from removing all the logic if not used
-- attribute S: string;
-- attribute S of rx_data: signal is "yes";
-- attribute S of tx_data: signal is "yes";

signal latest_remote_mac_addr: std_logic_vector(47 downto 0);
signal latest_remote_ip_addr: std_logic_vector(31 downto 0);
signal latest_remote_ip_port: std_logic_vector(15 downto 0);

signal remote_mac_addr_sel0: std_logic_vector(47 downto 0);
signal remote_ip_addr_sel0: std_logic_vector(31 downto 0);
signal remote_ip_port_sel0: std_logic_vector(15 downto 0);
signal remote_mac_addr_sel1: std_logic_vector(47 downto 0);
signal remote_ip_addr_sel1: std_logic_vector(31 downto 0);
signal remote_ip_port_sel1: std_logic_vector(15 downto 0);

signal arp_mac_addr: std_logic_vector(47 downto 0);
signal arp_ip_addr: std_logic_vector(31 downto 0);

signal arp_request: std_logic;
signal reset_done_int: std_logic;
signal tx_rst: std_logic;

begin

	gmii_reset_l <= not rst;
	--GMII_TXC_GTXCLK<=CLK125;
	reset_done <= reset_done_int;

	-- Select thedestination address: Either the user provided one, or if zero, use the last source
	remote_mac_addr_sel0 <= remote_mac_addr0 when unsigned(remote_mac_addr0)/=0 else latest_remote_mac_addr;
	remote_ip_addr_sel0 <= remote_ip_addr0 when unsigned(remote_ip_addr0)/=0 else latest_remote_ip_addr;
	remote_ip_port_sel0 <= remote_ip_port0 when unsigned(remote_ip_port0)/=0 else latest_remote_ip_port;

	remote_mac_addr_sel1 <= remote_mac_addr1 when unsigned(remote_mac_addr1)/=0 else latest_remote_mac_addr;
	remote_ip_addr_sel1 <= remote_ip_addr1 when unsigned(remote_ip_addr1)/=0 else latest_remote_ip_addr;
	remote_ip_port_sel1 <= remote_ip_port1 when unsigned(remote_ip_port1)/=0 else std_logic_vector(unsigned(latest_remote_ip_port)+1);

	tx_rst <= rst or (not reset_done_int);

	-- Instantiate UDP MAC transmitter
	tx0: entity work.udp_mac_tx
		port map(

			local_mac_addr       => local_mac_addr,
			local_ip_addr        => local_ip_addr,

			remote_mac_addr0      => remote_mac_addr_sel0,
			remote_ip_addr0       => remote_ip_addr_sel0,
			remote_ip_port0      => remote_ip_port_sel0,

			remote_mac_addr1      => remote_mac_addr_sel1,
			remote_ip_addr1       => remote_ip_addr_sel1,
			remote_ip_port1      => remote_ip_port_sel1,

			arp_request          => arp_request,
			arp_remote_mac_addr  => arp_mac_addr,
			arp_remote_ip_addr   => arp_ip_addr,

			s_axis_udp_tx_tvalid => s_axis_udp_tx_tvalid,
			s_axis_udp_tx_tdata  => s_axis_udp_tx_tdata,
			s_axis_udp_tx_tlast  => s_axis_udp_tx_tlast,
			s_axis_udp_tx_tready => s_axis_udp_tx_tready,
			tx_port_offset       => tx_port,
			tx_clk               => clk125, -- data bus clock
			tx_overflow          => tx_overflow,
			rst                  => tx_rst,
			gmii_txclk           => gmii_txclk,  -- transmit clock
			gmii_txer            => gmii_txer,
			gmii_txen            => gmii_txen,
			gmii_txd             => gmii_txd,
			gmii_txc_gtxclk      => gmii_txc_gtxclk -- 125 MHZ clock provided by the PHY

		);

	rx0: entity work.udp_mac_rx
		generic map(
			BROADCAST_IP_PORT => BROADCAST_IP_PORT
			)
		port map(
			local_mac_addr           => local_mac_addr,
			local_ip_addr            => local_ip_addr,
			local_ip_port            => local_ip_port,
			local_subarray           => local_subarray,
			latest_remote_mac_addr   => latest_remote_mac_addr,
			latest_remote_ip_addr    => latest_remote_ip_addr,
			latest_remote_ip_port    => latest_remote_ip_port,

			arp_request              => arp_request,
			arp_remote_mac_addr      => arp_mac_addr,
			arp_remote_ip_addr       => arp_ip_addr,

			m_axis_udp_rx_tdata      => m_axis_udp_rx_tdata,
			m_axis_udp_rx_tvalid     => m_axis_udp_rx_tvalid,
			m_axis_udp_rx_tlast      => m_axis_udp_rx_tlast,
			m_axis_udp_rx_tready     => m_axis_udp_rx_tready,
			rx_overflow              => rx_overflow,

			clk                      => clk125,
			rst                      => rst,
			gmii_rxclk               => gmii_rxclk,
			gmii_rxctrl_rxdv         => gmii_rxdv,
			gmii_rxd                 => gmii_rxd
		);


	phy_gen: case PHY_TYPE generate
		when GMII =>
			-- bridge between mac GMII output and GMII I/Os (forces some buffer instantiation)

			phy_reset_l       <= gmii_reset_l; -- pass the active low reset signal

			-- TX bus

			gmii_txclk     <= clk125; -- clock  the TX outputs of the MAC with clk125
			phy_txc_gtxclk <= clk125; -- pass  the 125 MHz TX data clock to the PHY
			phy_txctl_txen <= gmii_txen;
			phy_txd        <= gmii_txd;
			phy_txer       <= gmii_txer;
			reset_done_int <= '1';

			-- RX bus signals

			-- Instantiate a clock buffer to launch a copy of the RX clock into the FPGA fabric
			rxclk_bufg_inst : bufg
				port map (
					i => phy_rxclk,
					o => gmii_rxclk
					);

			-- Clock the received data.
			rx_data_clocking: process(all) begin
			if rising_edge(gmii_rxclk) then
						gmii_rxdv <= phy_rxctrl_rxdv;
						gmii_rxd <= phy_rxd;
					end if;
				end process;

			sfp_tx_p <='Z';
			sfp_tx_n <='Z';

		when SGMII =>

			gmii_txclk <= gmii_clk; -- use the clock provided by the SGMII core (userclk2) for the GMII TX bus
			gmii_rxclk <= gmii_clk; -- use the clock provided by the SGMII core (userclk2) for the GMII RX bus

			-- sfp_refclk <= gtrefclk; -- pass the GTX reference clock

			sgmii0: entity work.udp_mac_gmii_to_sgmii
				generic map (
					SIM => SIM
					)
				port map (
					-- Tranceiver Interface
					gtrefclk_nobuf   => sfp_refclk_nobuf,
					gtrefclk_buf     => sfp_refclk_buf,
					txp              => sfp_tx_p,
					txn              => sfp_tx_n,
					rxp              => sfp_rx_p,
					rxn              => sfp_rx_n,

					-- GMII Interface (client MAC <=> PCS)
					gmii_clk   => gmii_clk,   -- clock for both the TX and RX GMII bus provided by the core.

					gmii_txd   => gmii_txd,
					gmii_tx_en => gmii_txen,
					gmii_tx_er => gmii_txer,

					gmii_rxd   => gmii_rxd,
					gmii_rx_dv => gmii_rxdv,
					gmii_rx_er => open,

					-- General IO's
					---------------
					status_vector => status_vector,
					config_vector => config_vector,
					mmcm_locked   => mmcm_locked,
					reset_done    => reset_done_int,
					clk125        => clk125,
					signal_detect => signal_detect,
					reset         => rst
					);

				-- Instantiate dummy signals for the unused phy ports
				phy_txer       <='0';
				phy_reset_l    <='1';
				phy_txc_gtxclk <= clk125;
				phy_txctl_txen <='0';
				phy_txd        <=(others=>'0');
		when others =>
			assert FALSE report "Invalid PHY type" severity FAILURE;
		end generate;

end IMPL;

