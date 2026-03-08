----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: JF Cliche
--
-- Create Date:
-- Design Name:
-- Module Name:    UDP_MAG_GMII_TO_SGMII
-- Project Name: CHIME
-- Target Devices:
-- Tool versions: ISE, Vivado
-- Description: GMII to SGMII core wrapper
--
-- Dependencies:
--
-- Revision:  See GIT repository

-- Additional Comments:
--
----------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
--use work.ip_package.all; -- Import definition of components used in this module

--------------------------------------------------------------------------------
-- The entity declaration for the example design
--------------------------------------------------------------------------------

entity udp_mac_gmii_to_sgmii is
	generic (
		SIM: BOOLEAN := FALSE
		);
	port (

		-- Tranceiver Interface
		
		gtrefclk_nobuf       : in std_logic;                     --  unbuffered GTX reference clock for tranceiver: 125MHz, very high quality
		gtrefclk_buf         : in std_logic;                     --  BUFG-buffered GTX reference clock for tranceiver: 125MHz, very high quality
		txp                  : out std_logic;                    -- Differential +ve of serial transmission from PMA to PMD.
		txn                  : out std_logic;                    -- Differential -ve of serial transmission from PMA to PMD.
		rxp                  : in std_logic;                     -- Differential +ve for serial reception from PMD to PMA.
		rxn                  : in std_logic;                     -- Differential -ve for serial reception from PMD to PMA.

		-- GMII Interface (client MAC <=> PCS)

		gmii_clk             : out std_logic;                    -- Clock to be used for bith GMII RX and TX bus transfers.

		gmii_txd             : in std_logic_vector(7 downto 0);  -- Transmit data from client MAC.
		gmii_tx_en           : in std_logic;                     -- Transmit control signal from client MAC.
		gmii_tx_er           : in std_logic;                     -- Transmit control signal from client MAC.

		gmii_rxd             : out std_logic_vector(7 downto 0); -- Received Data to client MAC.
		gmii_rx_dv           : out std_logic;                    -- Received control signal to client MAC.
		gmii_rx_er           : out std_logic;                    -- Received control signal to client MAC.

		-- General IO's
		
		status_vector : out std_logic_vector(15 downto 0); -- Core status.
		config_vector : in std_logic_vector(31 downto 0); -- Core config.
		signal_detect : in std_logic;                      -- Input from PMD to indicate presence of optical input.
		mmcm_locked   : out std_logic;
		reset_done    : out std_logic;

		clk125        : in std_logic; -- Buffered (BUFG) 125 MHz clock, An independent clock source used for the main GT transceiver reset logic
		reset         : in std_logic  -- Asynchronous reset for entire core.
		);

end udp_mac_gmii_to_sgmii;



architecture top_level of udp_mac_gmii_to_sgmii is

	-- Attribute definitions
	attribute DONT_TOUCH: string;
	attribute ASYNC_REG: string;

	-- Signals

	------------------------------------------------------------------------------
	-- internal signals used in this top level example design.
	------------------------------------------------------------------------------
	-- clock generation signals for tranceiver
	signal txoutclk_nobuf: std_logic;   -- txoutclk from GT transceiver
	signal txoutclk_bufg: std_logic;    -- txoutclk from GT transceiver routed onto global routing.

	signal rxoutclk_nobuf: std_logic;   -- rxoutclk from GT transceiver
	signal rxoutclk_bufh: std_logic;    -- buffered rxoutclk from GT transceiver

	signal resetdone: std_logic;        -- To indicate that the GT transceiver has completed its reset cycle
	--signal tx_reset_done_int: std_logic;        --
	--signal rx_reset_done_int: std_logic;        --
	signal mmcm_locked_int: std_logic;  -- MMCM locked signal.
	signal mmcm_reset: std_logic;       -- MMCM reset signal.
	signal clkfbout: std_logic;         -- MMCM feedback clock
	signal userclk2_nobuf: std_logic;   -- MMCM clock0 output (62.5 MHz).
	signal userclk_nobuf: std_logic;    -- MMCM clock1 output (125 MHz).
	signal userclk: std_logic;          -- 62.5 MHz clock for GT transceiver Tx/Rx user clocks
	signal userclk2: std_logic;         -- 125 MHz clock for core reference clock.

	signal basex_or_sgmii: std_logic;
	signal user_reset: std_logic;
	signal an_restart: std_logic;
	signal loss_of_signal: std_logic;
	signal config_vector_int: std_logic_vector(4 downto 0);
	signal an_config_vector: std_logic_vector(15 downto 0);

	attribute DONT_TOUCH of userclk2_nobuf: signal is "yes";
	attribute DONT_TOUCH of userclk_nobuf: signal is "yes";

	-- PMA reset generation signals for tranceiver
	signal pma_reset_pipe: std_logic_vector(3 downto 0); -- flip-flop pipeline for reset duration stretch
	signal pma_reset: std_logic;                         -- Synchronous transcevier PMA reset
	signal init_reset: std_logic := '1';
	signal init_reset_ctr: unsigned(21 downto 0) := (others=>'0');

	-- Signals used for an IDELAYCTRL
	signal idelayctrl_reset_sync: std_logic;               -- Used to create a reset pulse in the IDELAYCTRL clock domain.
	signal idelay_reset_cnt: std_logic_vector(3 downto 0); -- Counter to create a long IDELAYCTRL reset pulse.
	signal idelayctrl_reset: std_logic;                    -- The reset pulse for the IDELAYCTRL.

	-- GMII signals
	signal gmii_txd_delay: std_logic_vector(7 downto 0); -- Internal gmii_txd signal after IDELAY.
	signal gmii_tx_en_delay: std_logic;                  -- Internal gmii_tx_en signal after IDELAY.
	signal gmii_tx_er_delay: std_logic;                  -- Internal gmii_tx_er signal after IDELAY.
	signal gmii_txd_iff: std_logic_vector(7 downto 0);   -- gmii_txd signal for input IOB flip-flop.
	signal gmii_tx_en_iff: std_logic;                    -- gmii_tx_en signal for input IOB flip-flop.
	signal gmii_tx_er_iff: std_logic;                    -- gmii_tx_er signal for input IOB flip-flop.
	signal gmii_txd_reg: std_logic_vector(7 downto 0);   -- Internal gmii_txd signal.
	signal gmii_tx_en_reg: std_logic;                    -- Internal gmii_tx_en signal.
	signal gmii_tx_er_reg: std_logic;                    -- Internal gmii_tx_er signal.
	signal gmii_txd_int: std_logic_vector(7 downto 0);   -- gmii_txd signal after Tx Elastic Buffer.
	signal gmii_tx_en_int: std_logic;                    -- gmii_tx_en signal after Tx Elastic Buffer.
	signal gmii_tx_er_int: std_logic;                    -- gmii_tx_er signal after Tx Elastic Buffer.
	signal gmii_rxd_int: std_logic_vector(7 downto 0);   -- Internal gmii_rxd signal.
	signal gmii_rx_dv_int: std_logic;                    -- Internal gmii_rx_dv signal.
	signal gmii_rx_er_int: std_logic;                    -- Internal gmii_rx_er signal.
	signal gmii_rxd_obuf: std_logic_vector(7 downto 0);  -- gmii_rxd registered in IOBs prior to an OBUF.
	signal gmii_rx_dv_obuf: std_logic;                   -- gmii_rx_dv registered in IOBs prior to an OBUF.
	signal gmii_rx_er_obuf: std_logic;                   -- gmii_rx_er registered in IOBs prior to an OBUF.

	-- Extra registers to ease IOB placement
	signal status_vector_int : std_logic_vector(15 downto 0);

	-- These attributes will stop timing errors being reported in back annotated
	-- SDF simulation.
	attribute ASYNC_REG of pma_reset_pipe: signal is "true";

FUNCTION sel(b: BOOLEAN; if_true: integer; if_false: integer) return integer is
	begin
		if b then
			return if_true;
		else
			return if_false;
		end if;
	end sel;


begin

	 -----------------------------------------------------------------------------
	 -- Transceiver Clock Management
	 -----------------------------------------------------------------------------
	 -- Clock circuitry for the GT Transceiver uses a differential input clock.

-- Route txoutclk (62.5 MHz) input through a BUFG to send it to the MMCM
bufg_txoutclk : BUFG
port map (
	I         => txoutclk_nobuf,
	O         => txoutclk_bufg
);


	-- The GT transceiver provides a 62.5MHz clock to the FPGA fabrix.  This is
	-- routed to an MMCM module where it is used to create phase and frequency
	-- related 62.5MHz and 125MHz clock sources
	mmcm_adv_inst : MMCME2_ADV
		generic map(
			BANDWIDTH            => "OPTIMIZED",
			CLKOUT4_CASCADE      => FALSE,
			COMPENSATION         => "ZHOLD",
			STARTUP_WAIT         => FALSE,
			DIVCLK_DIVIDE        => 1,
			CLKFBOUT_MULT_F      => 16.000,
			CLKFBOUT_PHASE       => 0.000,
			CLKFBOUT_USE_FINE_PS => FALSE,
			CLKOUT0_DIVIDE_F     => 8.000,
			CLKOUT0_PHASE        => 0.000,
			CLKOUT0_DUTY_CYCLE   => 0.5,
			CLKOUT0_USE_FINE_PS  => FALSE,
			CLKOUT1_DIVIDE       => 16,
			CLKOUT1_PHASE        => 0.000,
			CLKOUT1_DUTY_CYCLE   => 0.5,
			CLKOUT1_USE_FINE_PS  => FALSE,
			CLKOUT2_DIVIDE       => 5,
			CLKOUT2_PHASE        => 0.000,
			CLKOUT2_DUTY_CYCLE   => 0.5,
			CLKOUT2_USE_FINE_PS  => FALSE,
			CLKOUT3_DIVIDE       => 40,
			CLKOUT3_PHASE        => 0.000,
			CLKOUT3_DUTY_CYCLE   => 0.5,
			CLKOUT3_USE_FINE_PS  => FALSE,
			CLKIN1_PERIOD        => 16.0,
			REF_JITTER1          => 0.010
			)
		port map(
			-- Output clocks
			CLKFBOUT     => clkfbout,
			CLKFBOUTB    => open,
			CLKOUT0      => userclk2_nobuf, -- 125 MHz usrclk2
			CLKOUT0B     => open,
			CLKOUT1      => userclk_nobuf, -- 62.5 MHz usrclk
			CLKOUT1B     => open,
			CLKOUT2      => open, -- 200 MHz
			CLKOUT2B     => open,
			CLKOUT3      => open, -- 25 MHz
			CLKOUT3B     => open,
			CLKOUT4      => open,
			CLKOUT5      => open,
			CLKOUT6      => open,
			-- Input clock control
			CLKFBIN      => clkfbout,
			CLKIN1       => txoutclk_bufg,
			CLKIN2       => '0',
			-- Tied to always select the primary input clock
			CLKINSEL     => '1',
			-- Ports for dynamic reconfiguration
			DADDR        => (others => '0'),
			DCLK         => '0',
			DEN          => '0',
			DI           => (others => '0'),
			DO           => open,
			DRDY         => open,
			DWE          => '0',
			-- Ports for dynamic phase shift
			PSCLK        => '0',
			PSEN         => '0',
			PSINCDEC     => '0',
			PSDONE       => open,
			-- Other control and status signals
			LOCKED       => mmcm_locked_int,
			CLKINSTOPPED => open,
			CLKFBSTOPPED => open,
			PWRDWN       => '0',
			RST          => mmcm_reset
			);

--	mmcm_reset <= reset or (not resetdone);
	-- mmcm_reset <= reset; -- From v14 of the core example design: resetdone nolonger involved
	mmcm_locked <= mmcm_locked_int;
	reset_done <= resetdone;

	-- This 62.5MHz clock is placed onto global clock routing and is then used
	-- for tranceiver TXUSRCLK/RXUSRCLK.
	bufg_userclk: BUFG
		port map (
			I     => userclk_nobuf,
			O     => userclk
		);


	-- This 125MHz clock is placed onto global clock routing and is then used
	-- to clock all Ethernet core logic.
	bufg_userclk2: BUFG
		port map (
			I     => userclk2_nobuf,
			O     => userclk2
		);

	 bufh_rxclkout: BUFH
		port map (
			I     => rxoutclk_nobuf,
			O     => rxoutclk_bufh
		);


	 ---- Place the Rx recovered clock on a Global Clock Buffer (it may be possible
	 ---- to switch this for a BUFHCE/BUR and BUFMR combination)
	 --rxrecclkbufg : BUFG port map (
	 --  I   => rxoutclk,
	 --  O   => rxoutclk_buf
	 --);

	 --  rxuserclk2 <= rxoutclk_buf;
	 --  rxuserclk  <= rxoutclk_buf;


--    -----------------------------------------------------------------------------
--    -- Transceiver PMA reset circuitry
--    -----------------------------------------------------------------------------
-- -- Hold the rest line for some delay after FPGA configuration and reset to make sure the link comes up.
-- -- Otherwise we have 2-3% link up failure rate (known to happen on cores v14.3 rev1 and v15, maybe this is a SFP thing).
process(all) begin
	if reset then
		init_reset <= '1';
		init_reset_ctr <= (others=>'0');
	elsif rising_edge(clk125) then
		init_reset_ctr <= init_reset_ctr + 1;
		if signed(init_reset_ctr)=-1 then
			init_reset<= '0';
		end if;
	end if;
end process;


	 -- Create a reset pulse of a decent length
	 process(all) begin
	 if reset or user_reset then
			 pma_reset_pipe <= "1111";
		 elsif rising_edge(clk125) then
			 pma_reset_pipe <= pma_reset_pipe(2 downto 0) & reset;
		 end if;
	 end process;

	 --pma_reset <= pma_reset_pipe(3) or init_reset;
		pma_reset <= pma_reset_pipe(3); -- bypass initial delay. Will cause 3% uplink failure rate

	 --tx_reset_done <= tx_reset_done_int;
	 --rx_reset_done <= rx_reset_done_int;
	------------------------------------------------------------------------------
	-- Instantiate the Core Block (core wrapper).
	------------------------------------------------------------------------------
	core_wrapper : entity work.gmii_to_sgmii_bridge
		port map (
			-- GTX interface
			gtrefclk               => gtrefclk_nobuf, -- reference clock. Can be direct output from IBUFGDS_GTE2, but coming from a BUFG also works
			gtrefclk_bufg          => gtrefclk_buf, -- new in v15
			gt0_qplloutclk_in      => '0', -- The core does not use the QPLL
			gt0_qplloutrefclk_in   => '0', -- The core does not use the QPLL
			txp                    => txp,
			txn                    => txn,
			rxp                    => rxp,
			rxn                    => rxn,

			txoutclk               => txoutclk_nobuf,-- 62.5 MHz clock from GT transceiver to be used by the MMCM to generate user clocks
			rxoutclk               => rxoutclk_nobuf,-- 62.5 MHz clock from GT transceiver. re-introduced . Was not used for a while, as it was internally buffered by BUFH in the core.

			resetdone              => resetdone,
			cplllock               => open,
			mmcm_reset             => mmcm_reset, -- MMCM reset output. New in v15.
			mmcm_locked            => mmcm_locked_int,

			-- Transceiver user clock inputs
			userclk                => userclk, -- 62.5 MHz transceiver TX user clock used for **both** txuserclk and txuserclk2 since external data width (20 bits) = internal data width
			userclk2               => userclk2, -- 125 MHz user clock used for the PCS/PMA core

			rxuserclk             =>  rxoutclk_bufh,  --re-introduced. Was Not used in the core. Was 62.5 MHz transcever RX user clock used for rxuserclk
			rxuserclk2            =>  rxoutclk_bufh, --re-introduced. Was not used in the core. Was 62.5 MHz transceiver RX user clock user for rxuserclk2. Xilinx's naming convention is very confusing.

			independent_clock_bufg => clk125,
			pma_reset              => pma_reset,

			-- GMII interface, clocked on userclk2
			gmii_txd               => gmii_txd_int,
			gmii_tx_en             => gmii_tx_en_int,
			gmii_tx_er             => gmii_tx_er_int,
			gmii_rxd               => gmii_rxd_int,
			gmii_rx_dv             => gmii_rx_dv_int,
			gmii_rx_er             => gmii_rx_er_int,
			gmii_isolate           => open,

			-- Configuration vector
			--  bit 0: Unidirectional enable: 1:enabled
			--  bit 1: Loopbck control: 1:enabled
			--  bit 2: Power down: 1:enabled
			--  bit 3: Isolate: 1:enabled
			--  bit 4: Auto-negotiation Enable: 1:enabled
			configuration_vector   => config_vector_int, --"10000"


			status_vector        => status_vector_int,


			-- Ports present if auto-negotiation is enabled
			-- Auto-negociation config vector
			--  bit 0 :    1000BASE-X: Reserved; SGMII: always 1
			--  bit 4:1:   Reserved
			--  bit 5:     100BASE-X: 1: Advertise full duplex mode; SGMII: Reserved
			--  bit 6:     Reserved
			--  bit 8-7:   1000BASE-X pause: 00=None, 01: Sym pause, 10, Asym pause, 11: both sym & asym pause
			--  bit 9:     Reserved
			--  bit 11:10: 1000BASE-X: reserved, SGMII: speed
			--  bit 13:12: 100BASEX: Remote fault: 00: no error, 01 offline, 10 Link failure, 11: AN error; SGMII: see docs
			--  bit 14:    1000BASE-X: Reserved; SGMII: Acknowledge
			--  bit 15:    1000BASE-X: Reserved, SGMII: Link Status: 1=Up, 0-down
			--an_adv_config_vector => "0000000000100000", -- for 1000BASE-X core
			an_adv_config_vector => an_config_vector, -- for 1000BASE-X core
			an_restart_config    => an_restart,



			-- Ports present if SGMII is enabled
			speed_is_10_100      => '0',
			speed_is_100         => '0',

			-- Ports present if dynamic SGMII/1000BASE-X switching is enabled

			--basex_or_sgmii       => basex_or_sgmii,

			-- Resets

			reset                  => pma_reset,
			signal_detect          => not loss_of_signal

			---- DRP Interface (not used, except to provide a clock to work around core bugs)
			--gt0_drpaddr_in             => (others => '0') ,
			--gt0_drpclk_in              => gtrefclk_buf, -- updated in v15
			---- gt0_drpclk_in              => '0', -- Is not needed now that the 14.3 Rev1 core is fixed
			--gt0_drpdi_in               => (others => '0') ,
			--gt0_drpdo_out              => open ,
			--gt0_drpen_in               => '0',
			--gt0_drprdy_out             => open,
			--gt0_drpwe_in               => '0',

			---- Debug interface. Not used. Just there because it comes when we enable the DRP interface.
			--gt0_rxchariscomma_out => open,
			--gt0_rxcharisk_out => open,
			--gt0_rxbyteisaligned_out => open,
			--gt0_rxbyterealign_out => open,
			--gt0_rxcommadet_out => open,
			--gt0_txpolarity_in  =>'0',
			--gt0_txdiffctrl_in => (others =>'0'),
			--gt0_txpostcursor_in => (others =>'0'),
			--gt0_txprecursor_in => (others =>'0'),
			--gt0_rxpolarity_in =>'0',
			--gt0_txinhibit_in => '0',
			--gt0_txprbssel_in => (others =>'0'),
			--gt0_txprbsforceerr_in =>'0',
			--gt0_rxprbscntreset_in =>'0',
			--gt0_rxprbserr_out => open,
			--gt0_rxprbssel_in => (others =>'0'),

			--gt0_loopback_in => (others=>'0'),
			--gt0_txresetdone_out => tx_reset_done_int,
			--gt0_rxresetdone_out => rx_reset_done_int,
			--gt0_rxdisperr_out => open,
			--gt0_txbufstatus_out => open,
			--gt0_rxnotintable_out => open,
			--gt0_dmonitorout_out       => open,

			--gt0_eyescanreset_in =>'0',
			--gt0_eyescandataerror_out=>open,
			--gt0_eyescantrigger_in =>'0',

			--gt0_rxcdrhold_in  =>'0',
			--gt0_rxpmareset_in =>'0',
			--gt0_txpmareset_in => '0',
			--gt0_rxpcsreset_in =>'0',
			--gt0_txpcsreset_in =>'0',
			--gt0_rxbufreset_in =>'0',
			--gt0_rxbufstatus_out => open,
			--gt0_rxdfelpmreset_in =>'0',
			--gt0_rxdfeagcovrden_in  =>'0',
			--gt0_rxlpmen_in  =>'0',
			--gt0_rxmonitorout_out => open,
			--gt0_rxmonitorsel_in => (others=>'0')

			);
	 -----------------------------------------------------------------------------
	 -- GMII clock
	 -----------------------------------------------------------------------------

	gmii_clk <= userclk2;

	 -----------------------------------------------------------------------------
	 -- GMII transmitter clock logic
	 -----------------------------------------------------------------------------

	 -- Pipeline the TX interface to facilitate routing
	 process(all) begin
		if rising_edge(userclk2) then
				 gmii_txd_iff    <= gmii_txd;
				 gmii_tx_en_iff  <= gmii_tx_en;
				 gmii_tx_er_iff  <= gmii_tx_er;

				 gmii_txd_int    <= gmii_txd_iff;
				 gmii_tx_en_int  <= gmii_tx_en_iff;
				 gmii_tx_er_int  <= gmii_tx_er_iff;

				 gmii_rx_dv   <= gmii_rx_dv_int;
				 gmii_rx_er <= gmii_rx_er_int;
				 gmii_rxd <= gmii_rxd_int;
			end if;
	 end process;

	 -- status_vector(0) <= resetdone;
	 --status_vector(0) <= resetdone;
	 --status_vector(3 downto 1) <= status_vector_int(3 downto 1);
	 --status_vector(4) <= pma_reset;
	 --status_vector(5) <= mmcm_locked_int;
	 --status_vector(6) <= signal_detect;
	 --status_vector(7) <= tx_reset_done_int;
	 --status_vector(8) <= rx_reset_done_int;
	 --status_vector(9) <= reset;
	 --status_vector(10) <= mmcm_reset;

	 status_vector <= status_vector_int; -- pass the native core stus vector.

	 basex_or_sgmii <= config_vector(31);
	 an_restart <= config_vector(30);
	 user_reset <= config_vector(29);
	 loss_of_signal <= config_vector(28);
	 config_vector_int <= config_vector(20 downto 16);
	 an_config_vector <= config_vector(15 downto 0);


end top_level;
