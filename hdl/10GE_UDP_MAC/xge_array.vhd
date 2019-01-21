--! @file
----------------------------------------------------------------------------------
-- Company:  McGill University
-- Engineer: JF CLiche
--
-- Create Date: 09/16/2013 04:48:29 PM
-- Design Name:
-- Module Name: xge_udp_mac
-- Project Name: CHIME
-- Target Devices: Kintex 7
-- Tool Versions: Vivado 2013.4
-- Description: Implements an array of 10G Ethernet interfaces that transmit the incoming data as UDP packets.
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_misc.ALL; -- for reduce functions

library UNISIM;
use UNISIM.VComponents.all;

library work;
use work.chFPGA_Package.all;
use work.ip_package.all; -- Import definition of components used in this module

entity xge_array is
	generic (
		NUMBER_OF_TX_LANES: integer := GLOBAL_NUMBER_OF_GPU_LINKS;
		NUMBER_OF_REFCLK: integer:= GLOBAL_NUMBER_OF_GPU_REFCLKS;
		LANE_TO_QUAD_MAP: integerArray := GLOBAL_GPU_CHANNEL_QUAD; --! Indicates which quad is associated each channel. The QUAD number is an integer between 0 and N-1, where N is the total number of quads used.
		QUAD_TO_REFCLK_MAP: integerArray := GLOBAL_GPU_QUAD_REFCLK; --! Indicates which refclk is associated with each QUAD (N integers from 0 to NUMBER_OF_REFCLK-1).

		DEFAULT_MAC_SRC_ADDR: slv48_array := (0 to GLOBAL_NUMBER_OF_GPU_LINKS-1=> X"123456789ABC");
		DEFAULT_MAC_DEST_ADDR: slv48_array := (0 to GLOBAL_NUMBER_OF_GPU_LINKS-1=> X"FFFFFFFFFFFF");
		DEFAULT_IP_SRC_ADDR: slv32_array := (0 to GLOBAL_NUMBER_OF_GPU_LINKS-1=> X"0A0A0A0B");
		DEFAULT_IP_DEST_ADDR: slv32_array := (0 to GLOBAL_NUMBER_OF_GPU_LINKS-1=> X"0A0A0A0A");
		DEFAULT_IP_DEST_PORT: slv16_array := (0 to GLOBAL_NUMBER_OF_GPU_LINKS-1=> X"A028");

		USE_LITTLE_ENDIAN: boolean := TRUE; --! TRUE: Byte is LSB is transmitted first (i.e. bit 0 of word transmitted first). FALSE: Byte in MSB is transmitted first (i.e. bit 24 of word is transmitted first)

		SIM: boolean := false
		);
	port (
		tx_p: out std_logic_vector(0 to NUMBER_OF_TX_LANES-1);
		tx_n: out std_logic_vector(0 to NUMBER_OF_TX_LANES-1);
		rx_p: in std_logic_vector(0 to NUMBER_OF_TX_LANES-1);
		rx_n: in std_logic_vector(0 to NUMBER_OF_TX_LANES-1);
		refclk_p : in std_logic_vector(0 to NUMBER_OF_REFCLK-1); --156.250 clock
		refclk_n : in std_logic_vector(0 to NUMBER_OF_REFCLK-1);

		refclk_div2: out std_logic_vector(0 to NUMBER_OF_REFCLK-1); -- 156.25 MHz reference clock
		txclk_div2: out std_logic; -- Tx word clock

		s_axis_tx_tdata: in slv32_array(0 to NUMBER_OF_TX_LANES-1); -- First byte to transmit is in in LSB (i.e first bit transmitted is bit 0)
		s_axis_tx_tvalid: in std_logic_vector(0 to NUMBER_OF_TX_LANES-1);
		s_axis_tx_tlast: in std_logic_vector(0 to NUMBER_OF_TX_LANES-1);
		s_axis_tx_tready: out std_logic_vector(0 to NUMBER_OF_TX_LANES-1);
		s_axis_tx_clk: in std_logic_vector(0 to NUMBER_OF_TX_LANES-1); --! AXI-S data clock. Not related to the 10G Ethernet clocks.


		-- Control and reply streams
		CMD_DAT: in AXIS8_DAT_STRUCT;
		CMD_RDY: out AXIS8_RDY_STRUCT;
		RPLY_DAT: out AXIS8_DAT_STRUCT;
		RPLY_RDY: in AXIS8_RDY_STRUCT;
		CTRL_CLK : IN std_logic; -- control clock
		CTRL_RST : in std_logic;

		areset: in std_logic --! asynchronous reset
	 );
end xge_array;

architecture Behavioral of xge_array is

	-- Attribute definitions

	attribute ASYNC_REG : string;
	--- Constants

-- Signals

	signal reset_reg: std_logic;
	signal s_axis_tx_tdata_int: slv32_array(0 to NUMBER_OF_TX_LANES-1);
	signal s_axis_tx_tvalid_int: std_logic_vector(0 to NUMBER_OF_TX_LANES-1);
	signal s_axis_tx_tlast_int: std_logic_vector(0 to NUMBER_OF_TX_LANES-1);

	signal xglink_tx_data: slv32_array(0 to NUMBER_OF_TX_LANES-1);
	signal xglink_tx_header: slv2_array(0 to NUMBER_OF_TX_LANES-1);
	signal xglink_tx_ready: std_logic_vector(0 to NUMBER_OF_TX_LANES-1);
	signal xglink_tx_clk: std_logic;
	signal xglink_tx_resetdone: std_logic_vector(0 to NUMBER_OF_TX_LANES-1);

	signal ip_dest_addr: slv32_array(0 to GLOBAL_NUMBER_OF_GPU_LINKS-1);

	signal overflow_reset: std_logic;
	signal data_overflow: std_logic_vector(0 to NUMBER_OF_TX_LANES-1);
	signal frame_overflow: std_logic_vector(0 to NUMBER_OF_TX_LANES-1);
	signal data_overflow_sticky: std_logic_vector(0 to NUMBER_OF_TX_LANES-1);
	signal frame_overflow_sticky: std_logic_vector(0 to NUMBER_OF_TX_LANES-1);



	signal link_enable: std_logic;
	signal test_enable: std_logic;
	signal user_reset: std_logic;
	signal test_packet_ctr: unsigned(15 downto 0);
	signal test_tvalid: std_logic;
	signal test_tlast: std_logic;
	signal test_tdata: slv32;
	signal frame_ctr: unsigned(7 downto 0);
	signal test_packet_length: unsigned(15 downto 0);
	signal test_packet_period: unsigned(15 downto 0);
	signal dest_address_mode: std_logic;
	signal control_bytes: slv8_array(0 to 4);
	signal status_bytes: slv8_array(0 to 3);

begin


link_enable <='1';

-- CONTROL Byte 4
user_reset     <= control_bytes(0)(0);
test_enable    <= control_bytes(0)(1);
overflow_reset <= control_bytes(0)(2);
dest_address_mode <= control_bytes(0)(3); -- when zero, default dest IP addr is used. Otherwise, use (control_bytes(1 to 3) & index)

test_packet_length <= to_unsigned(control_bytes(1 to 2));
test_packet_period <= to_unsigned(control_bytes(3 to 4));

-- STATUS Byte 2
status_bytes(0) <= to_slv(lsb(test_packet_ctr));
-- STATUS Byte 3
status_bytes(1) <= to_slv(frame_ctr);
-- STATUS Byte 4
status_bytes(2) <= resize(reverse_bits_and_dir(data_overflow_sticky), 8);
-- STATUS Byte 5
status_bytes(3) <= resize(reverse_bits_and_dir(frame_overflow_sticky), 8);

-- Test pattern generator
test_pat_proc: process(s_axis_tx_clk(0))
begin
	if rising_edge(s_axis_tx_clk(0)) then
		reset_reg <= areset or user_reset;
		-- Count input frames for debugging
		if reset_reg='1' then
			frame_ctr <= (others=>'0');
		elsif s_axis_tx_tvalid(0)='1' and s_axis_tx_tlast(0)='1' then
			frame_ctr <= frame_ctr + 1;
		end if;

		test_tdata <= std_logic_vector(resize(test_packet_ctr, test_tdata'LENGTH));
		test_tlast <= '0';

		-- Generate test pattern
		if link_enable='0' or xglink_tx_resetdone(0)='0' then
			test_packet_ctr <= (others=>'0');
			test_tvalid<='0';
		else

			if test_packet_ctr = test_packet_period then
				test_packet_ctr <= (others=>'0');
				test_tlast <= '1';
			else
				test_packet_ctr <= test_packet_ctr + 1;
				if test_packet_ctr = test_packet_length then
					test_tlast <= '1';
				end if;
			end if;
			if test_packet_ctr =  0 then
				test_tvalid <= '1';
			elsif test_tlast = '1' then
				test_tvalid <= '0';
			end if;

		end if;
	end if; --clk
end process;


-- Generate a 10G Ethernet UDP/MAC TX engine for each lane
udp_gen: for i in 0 to NUMBER_OF_TX_LANES-1 generate

	s_axis_tx_tdata_int(i)  <= test_tdata when test_enable='1' else s_axis_tx_tdata(i);
	s_axis_tx_tvalid_int(i) <= test_tvalid when test_enable='1' else s_axis_tx_tvalid(i);
	s_axis_tx_tlast_int(i)  <= test_tlast when test_enable='1' else s_axis_tx_tlast(i);

	ip_dest_addr(i) <= DEFAULT_IP_DEST_ADDR(i) when dest_address_mode='0' else
		               to_slv(test_packet_length & test_packet_period(15 downto 8) & to_unsigned(i, 8));

	udp0: entity work.xge_udp_mac_tx
	generic map (
		USE_LITTLE_ENDIAN => USE_LITTLE_ENDIAN
		)
	port map (

		MAC_SRC_ADDR  => DEFAULT_MAC_SRC_ADDR(i),
		MAC_DEST_ADDR => DEFAULT_MAC_DEST_ADDR(i), -- broadcast
		IP_SRC_ADDR   => DEFAULT_IP_SRC_ADDR(i),
		IP_DEST_ADDR  => ip_dest_addr(i), -- broadcast
		IP_DEST_PORT  => DEFAULT_IP_DEST_PORT(i),


		s_axis_tx_tdata  => s_axis_tx_tdata_int(i),
		s_axis_tx_tvalid => s_axis_tx_tvalid_int(i),
		s_axis_tx_tlast  => s_axis_tx_tlast_int(i),
		s_axis_tx_tready => s_axis_tx_tready(i),
		s_axis_tx_clk    => s_axis_tx_clk(i),

		data_overflow => data_overflow(i),
		frame_overflow => frame_overflow(i),

	    tx_data => xglink_tx_data(i),
	    tx_header => xglink_tx_header(i),
	    tx_ready => xglink_tx_ready(i),
	    clk => xglink_tx_clk,

	    rst => reset_reg
	  );

	overflow_proc: process(s_axis_tx_clk(i))
	begin
		if rising_edge(s_axis_tx_clk(i)) then
			if reset_reg='1' or overflow_reset = '1' then
				data_overflow_sticky(i) <= '0';
				frame_overflow_sticky(i) <= '0';
			else
				data_overflow_sticky(i) <= data_overflow_sticky(i) or data_overflow(i);
				frame_overflow_sticky(i) <= frame_overflow_sticky(i) or frame_overflow(i);
			end if;
		end if; -- clk
	end process;
end generate;

-- Implement an array of 10G Transmitters/receivers
xglink0: entity work.xglink_core
	generic map (
		LINK_SPEED                  => 1, --! 0: 7.8125 Gbps, 1: 10.3125 Gbps line rate, assuming a 156.25 MHz reference clock.
		NUMBER_OF_TX_LANES          => NUMBER_OF_TX_LANES,
		NUMBER_OF_RX_LANES          => 0, --! We don't implement 10G Ethernet receivers for now.
		NUMBER_OF_REFCLK            => NUMBER_OF_REFCLK,
		LANE_TO_QUAD_MAP            => LANE_TO_QUAD_MAP,
		QUAD_TO_REFCLK_MAP          => QUAD_TO_REFCLK_MAP,
		EXAMPLE_SIMULATION          => 1,
		EXAMPLE_SIM_GTRESET_SPEEDUP => "TRUE",    -- simulation setting for GT SecureIP model
		DONT_RESET_ON_DATA_ERROR_IN => '0',
		NUMBER_OF_CONTROL_BYTES     => control_bytes'Length(1), -- All control bytes default to 0x00
		NUMBER_OF_STATUS_BYTES      => status_bytes'Length(1),
		SIM                         => TRUE
		)
	port map (
		tx_p => tx_p,
		tx_n => tx_n,
		rx_p => rx_p,
		rx_n => rx_n,
		refclk_p => refclk_p,
		refclk_n => refclk_n,

		refclk_div2 => refclk_div2,
		txclk_div2 => txclk_div2,

		tx_data   => xglink_tx_data,
		tx_header => xglink_tx_header,
		tx_ready  => xglink_tx_ready,
		tx_clk    => xglink_tx_clk,
		tx_resetdone => xglink_tx_resetdone,

		control_bytes => control_bytes,
		status_bytes => status_bytes,

		-- Control and reply streams
		CMD_DAT => CMD_DAT,
		CMD_RDY => CMD_RDY,
		RPLY_DAT => RPLY_DAT,
		RPLY_RDY=> RPLY_RDY,
		CTRL_CLK => CTRL_CLK,
		CTRL_RST => CTRL_RST,

		-- clk: in std_logic; --! AXI-S data clock. Not related to the 10G Ethernet clocks.
		areset=> reset_reg --! asynchronous reset
	 );


end Behavioral;
