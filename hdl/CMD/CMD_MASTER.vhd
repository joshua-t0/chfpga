----------------------------------------------------------------------------------
--! @file
-- Company: McGill University
-- Engineer: JF Cliche
--
-- Create Date:    21:23:49 03/17/2011
-- Design Name: chFPGA
-- Module Name:    CMD_MASTER - Behavioral
-- Project Name: CHIME PoC
-- Target Devices: Virtex6 or 7 series
-- Tool versions: ISE 13.2
-- Description: Process Read/Write commands received throught the UDP/Ethernet interface and reads/write data to/from the modules specified in the address. Also transmit frames captured by data probes.
--
-- Dependencies:
--
-- Revision:
--  2011-09-14 JFC - Added reset of RX_STATE when RST=1 to make sure we get our of locked situations
--  2012-01-31 JFC - modified command format to facilitate migration towards AXI4. Uses a single address space, and number of bytes to be transferred.
--	 2012-10-18 JFC: Added wait state after data transmission

-- History
--  120608 JFC: removed some commended code. Changed CTRL_CLK to clk.
--  120612 JFC: Cleanup. Removed Probe header insertion (now in prober itself). Added timeout on the command and probe streams
--  121021 JFC: Added throttling since transmitting a large number of large correlator frames overflows the Host buffers
--  130128 JFC: Changed they way HOST_BUFFER_READOUT_TIMER_MAX is computed to suit Vivado 2012.4 (did not like a non-constant in the slice)
--  130801 JFC: Modified to handle AXI-Streaming UDP RX and TX buses.

-- Improvements
--  110916 JFC: Add read count to read multiple bytes in one command
--  110916 JFC: Improve probe port scanning to reduce Probe data transmission latency

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chFPGA_Package.all; -- Get all component definitions

library UNISIM;
use UNISIM.VComponents.all;

use work.ip_package.all; -- Import definition of components used in this module

--! Ethernet port access arbitrator. Passes the incoming commands to the modules, and merges the incoming command replies and data streams with some arbitrating algorithm.
--! Command frame format
--!		  Byte 0 | Byte 1 | Byte 2
--!    [pppNNAAA AAAAAAAA AAAAAAAA]
--!
--!
--!  Byte 0 - 2: (Byte 0 is received first and is MSB)
--!    Bit 23-21 (ppp) Operation opcode
--!    Bit 20-19 (NN): Log2 of number of bytes to read (Read command only). 0: 1 byte, 1: 2 bytes, 2: 4 bytes, 3: 8 bytes
--!    Bit 18-0: 19-bit address

--!--!
--! The address space is subdivided according to the needs of the design.
--! The subdivision is done by the ROUTERs, which splits the command and reply streams in N ways based on the number of adrress bits used for the splitting.
--! A typical splitting scheme is:
--!    Bits 19-17: Subsystem (SYSTEM, CHAN/ADC, CORR, REORDER, GPU_LINK etc)
--!    Bits 16-13: Instance number (0-15, one for each)
--!    Bits 12-10: Module number (0-7)
--!    Bits 9-0 (AAAAAAAAAA): 10-bit address within module

--! The module address space is split to distinguish between COMMAND, STATUS and RAM/DRP accesses:

--!  Byte 3+: Data bytes (write command only)
--!
--! Note: Does not handle the UDP transmitter TREADY signal: we will send data even if the TX buffers are full.
--!    Also always passes the received UDP data to the command bus independent of its TREADY state.
--!
entity CTRL_MASTER is
	GENERIC (
		NUMBER_OF_PROBES: INTEGER
	);
	PORT (
		-- UDP Transmitter/Receiver interface

		-- UDP Rx interface
		s_axis_udp_rx_tdata  : in std_logic_vector (7 downto 0);
		s_axis_udp_rx_tvalid : in std_logic;
		s_axis_udp_rx_tlast  : in std_logic;
		s_axis_udp_rx_tready : out std_logic;

		-- UDP Tx interface
		m_axis_udp_tx_tvalid : out std_logic;
		m_axis_udp_tx_tdata : out  std_logic_vector (7 downto 0); -- will be axis_tx_tdata
		m_axis_udp_tx_tlast : out std_logic;
		m_axis_udp_tx_tready: in std_logic;
		udp_tx_port : out std_logic_vector(1 downto 0); --! Port offset. The destination port number will be offseted by this value relatove to the base port number.


		-- Command and reply stream buses
		m_axis_cmd_tdata  : out std_logic_vector(7 downto 0);
		m_axis_cmd_tvalid : out std_logic;
		m_axis_cmd_tlast  : out std_logic;
		m_axis_cmd_tready : in std_logic;

		s_axis_rply_tdata  : in std_logic_vector(7 downto 0);
		s_axis_rply_tvalid : in std_logic;
		s_axis_rply_tlast  : in std_logic;
		s_axis_rply_tready : out std_logic;
		rply_port_offset: in slv2;
		cmd_packet_counter: out std_logic_vector(7 downto 0);
		rply_packet_counter: out std_logic_vector(7 downto 0);


		-- Raw Data (probe) inputs
		prb_dat: in axis8_dat_struct_array(NUMBER_OF_PROBES-1 downto 0);
		prb_rdy: out axis8_rdy_struct_array(NUMBER_OF_PROBES-1 downto 0);
		prb_port_offset: in slv2_array(NUMBER_OF_PROBES-1 downto 0);

		-- System
		host_frame_read_rate: in std_logic_vector(4 downto 0);
		clk:  in std_logic;
		rst : in std_logic
		);

end CTRL_MASTER;

architecture Behavioral of CTRL_MASTER is

-- RX process
signal s_axis_udp_rx_tready_int: std_logic;

-- TX Process

TYPE TX_STATE_TYPE IS (TX_STATE_SCAN, TX_STATE_SEND_CMD,TX_STATE_SEND_ANT, TX_STATE_WAIT); -- States of the TX state machine
signal tx_state: TX_STATE_TYPE := TX_STATE_SCAN; -- Initialization needed
signal probe_number : integer range 0 to (NUMBER_OF_PROBES-1):=0;
signal timeout_ctr: unsigned(7 downto 0); --
signal host_buffer_readout_timer: unsigned(23 downto 0);
signal host_buffer_readout_timer_max: unsigned(host_buffer_readout_timer'Range);

signal host_buffer_count: unsigned(15 downto 0); --! Counts the estimated bytes in the host buffer. Frames are not sent if the buffer is more than half full. Must be at least twice the size of the maximum frame length (6667 bytes for a correlator frame).
signal m_axis_udp_tx_tvalid_int: std_logic;

signal cmd_packet_counter_int: unsigned(7 downto 0) := (others=>'0');
signal rply_packet_counter_int: unsigned(7 downto 0) := (others=>'0');
signal is_reply_header: std_logic;
signal s_axis_udp_rx_tfirst: std_logic := '1';

signal rply_flush: std_logic;
signal prb_flush: std_logic_vector(0 to NUMBER_OF_PROBES-1);

begin

--! Receive process: process incoming commands
--! The uncoming UDP stream is just passed on to the command bus.

cmd_packet_counter <= std_logic_vector(cmd_packet_counter_int);
rply_packet_counter <= std_logic_vector(rply_packet_counter_int);


s_axis_udp_rx_tready <= m_axis_cmd_tready; -- Only accept data when we can pass it immediately to the destination
m_axis_cmd_tdata     <= s_axis_udp_rx_tdata;
m_axis_cmd_tvalid    <= s_axis_udp_rx_tvalid;
m_axis_cmd_tlast     <= s_axis_udp_rx_tlast;


-- UDP Received packet counter and tfirst flag generator
rx_proc: process(clk)
begin
	if rising_edge(clk) then
		if s_axis_udp_rx_tvalid='1' then
			s_axis_udp_rx_tfirst <= s_axis_udp_rx_tlast;
			if s_axis_udp_rx_tfirst='1' then
				cmd_packet_counter_int <= cmd_packet_counter_int + 1;
			end if;
		end if;

		if rst='1' then -- Synchronous reset
			s_axis_udp_rx_tfirst <= '1';
			cmd_packet_counter_int <= (others=>'0');
		end if; --rst
	end if; -- clk
end process;

m_axis_udp_tx_tvalid <= m_axis_udp_tx_tvalid_int;

------------------------
-- UDP Transmit process
------------------------
-- Selects data from the reply or raw data buses, and forward them to the UDP transmitter.
tx_proc: process(clk)
	begin
		if rising_edge(clk) then

			timeout_ctr <= timeout_ctr + 1; -- Always increment timout counter, unless resetted below


			-------------------------------
			-- Data throttling
			-------------------------------
			-- Throttle the data output rate.
			-- The HOST_BUFFER_COUNTER is incremented every time a byte is sent. Transmission of non-command frames will be held when the buffer more than half-full.
			-- The counter is cleared every 2^HOST_READ_RATE *2  clock cycles.

			-- First compute the maximum timer count based on HOST_FRAME_READ_RATE.
			-- Set all bits <=HOST_FRAME_READ_RATE to 1
            -- The code was refactored below to make it work with Vivado, but beware of how it is implemented

            for i in HOST_BUFFER_READOUT_TIMER_MAX'Range loop
                if i <= to_integer(unsigned(host_frame_read_rate)) then
                    host_buffer_readout_timer_max(i) <= '1';
				else
                    host_buffer_readout_timer_max(i) <= '0';
                end if;
            end loop;

			if host_buffer_readout_timer = HOST_BUFFER_READOUT_TIMER_MAX then
				host_buffer_count <= (others=>'0');
				host_buffer_readout_timer <= (others=>'0');
			else
				if host_buffer_count = 0 then
					host_buffer_readout_timer <= (others=>'0');
				else
					host_buffer_readout_timer <= host_buffer_readout_timer+1;
				end if;

				if m_axis_udp_tx_tvalid_int ='1' then
					host_buffer_count <= host_buffer_count +1;
				end if;
			end if;

			-------------------------------
			-- Data selector/transmitter
			-------------------------------
			---- Alternate between CMD and ANT states
			CASE tx_state IS
				WHEN TX_STATE_SCAN => -- If current antenna finished processing, set next state to SEND_CMD and increment antenna number in preparation for the next round

					-- end the write that was in progress when the last state completed
					m_axis_udp_tx_tvalid_int <= '0';
					--m_axis_udp_tx_tlast<='0';

					s_axis_rply_tready <= rply_flush;
					if s_axis_rply_tvalid='1' and s_axis_rply_tlast ='1' then
						rply_flush <= '0';
					end if;

					for i in 0 to NUMBER_OF_PROBES-1 loop
						prb_rdy(i).tready <= prb_flush(i);
						if prb_dat(i).tvalid='1' and prb_dat(i).tlast='1' then
							prb_flush(i) <= '0';
						end if;
					end loop;


					--if m_axis_udp_tx_tready = '1' then -- Send data only if the header and data FIFOs of the transmitter are not full. This does not guarantee that the data buffer won't overflow, but it is better than nothing.
						if probe_number = 0 and s_axis_rply_tvalid = '1' and rply_flush='0' then --! Send control data in priority
								s_axis_rply_tready <= '1';
								timeout_ctr <= (others=>'0');
								is_reply_header <= '1';
								tx_state <= TX_STATE_SEND_CMD;
						elsif host_buffer_count(host_buffer_count'HIGH) = '0' then--! If the count is less than half the max buffer size, then continue scanning the probe inputs and send the frames
							if prb_dat(probe_number).tvalid='1' and prb_flush(probe_number)='0'  then -- antenna data is ready
									-- start reading antenna data
									prb_rdy(probe_number).tready <= '1';
									timeout_ctr <= (others=>'0');
									tx_state <= TX_STATE_SEND_ANT;
							else
								-- if no data is awaiting, increment antenna number to proceed with scanning
								if (probe_number = NUMBER_OF_PROBES-1) then
									probe_number <= 0;
								else
									probe_number <= probe_number+1;
								end if;
							end if;
						end if;
					--end if; -- if tready=1
				WHEN TX_STATE_SEND_CMD => --
					if s_axis_rply_tvalid = '1' then timeout_ctr<=(others=>'0'); end if; -- reset timout counter as long as we receive bytes
					if signed(timeout_ctr)=-1 then -- if we had no TVALID until the counter reaches its maximum, abandon reception
						tx_state <= tx_state_scan; -- the SCAN state will reset the UDP write signals
					else
						m_axis_udp_tx_tvalid_int <= s_axis_rply_tvalid;
						if is_reply_header = '1' then
							m_axis_udp_tx_tdata <= std_logic_vector(cmd_packet_counter_int);
						else
							m_axis_udp_tx_tdata <= s_axis_rply_tdata;
						end if;
						m_axis_udp_tx_tlast <= s_axis_rply_tlast;
						udp_tx_port <= rply_port_offset;

						if s_axis_rply_tvalid='1' then
								is_reply_header <= '0';
						end if;

						if s_axis_rply_tvalid='1' and s_axis_rply_tlast='1' then
								rply_packet_counter_int <= rply_packet_counter_int + 1;
								s_axis_rply_tready <= '0'; -- we go back in scan mode, so we won't be accepting reply bytes anymore
								tx_state <= TX_STATE_SCAN;
						end if; -- TVALID=1;
					end if; -- if timeout

--
				WHEN TX_STATE_SEND_ANT =>
					if PRB_DAT(PROBE_NUMBER).TVALID='1' then TIMEOUT_CTR<=(others=>'0'); end if; -- reset timout counter as long as we receive bytes
					if signed(TIMEOUT_CTR)=-1 then -- if we had no TVALID until the counter reaches its maximum, abandon reception
							tx_state<=TX_STATE_SCAN; -- the SCAN state will reset the UDP write signals
					else
						m_axis_udp_tx_tvalid_int<=PRB_DAT(PROBE_NUMBER).TVALID;
						m_axis_udp_tx_tdata <= PRB_DAT(PROBE_NUMBER).TDATA;
						UDP_TX_PORT<=PRB_PORT_OFFSET(PROBE_NUMBER);
						m_axis_udp_tx_tlast<='0'; -- is overriden below

						if PRB_DAT(PROBE_NUMBER).TVALID='1' and PRB_DAT(PROBE_NUMBER).TLAST='1' then
								m_axis_udp_tx_tlast<='1'; --  signal the end of frame
								PRB_RDY(PROBE_NUMBER).TREADY<='0'; -- we don't accept reply bytes anymore
								TIMEOUT_CTR<=(others=>'0'); -- prepare counter for the wait state
								tx_state<=TX_STATE_WAIT; -- wait some time before returning to scan to make sure we don't fill the Ethernet interface FIFO
							--end if; -- TLAST=1
						end if; -- TVALID=1;
					end if; -- if timeout

				WHEN TX_STATE_WAIT => -- Wait for some time after transmission to make sure there is enough time for the Ethernet interface to transmit the header bytes, otherwise the FIFO will eventually overflow
					m_axis_udp_tx_tvalid_int<='0';
					--m_axis_udp_tx_tlast<='0';
					if signed(TIMEOUT_CTR)=-1 then
						tx_state<=TX_STATE_SCAN;
					-- enabled block below while debugging CORR output in 2017
					-- make sure we continue with the next probe. We don't want to send the same probe again if it happens it has an other frame already waiting.
						if (PROBE_NUMBER=NUMBER_OF_PROBES-1) then
							PROBE_NUMBER<=0;
						else
							PROBE_NUMBER<=PROBE_NUMBER+1;
						end if;
					end if;
			end case;-- tx_state

			-------------------------------
			-- Synchronous reset
			-------------------------------
			if rst = '1' then
				tx_state <= TX_STATE_SCAN;

				m_axis_udp_tx_tvalid_int <= '0';
				m_axis_udp_tx_tdata <= (others=>'0');
				--m_axis_udp_tx_tlast<='1';
				udp_tx_port <= (others=>'0');


				prb_flush <= (others => '1');
				rply_flush <= '1';
				-- reset reply bus
				s_axis_rply_tready <= '0';

				for i in 0 to NUMBER_OF_PROBES-1 loop
					prb_rdy(i).tready <= '0';
				end loop;

				host_buffer_readout_timer <= (others=>'0');
				host_buffer_count <= (others=>'0');

				rply_packet_counter_int <= (others=>'0');
			end if;

		end if; -- clk
	end process;


end Behavioral;

