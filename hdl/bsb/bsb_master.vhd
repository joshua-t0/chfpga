----------------------------------------------------------------------------------
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
--
-- History
--  120608 JFC: removed some commended code. Changed CTRL_CLK to clk.
--  120612 JFC: Cleanup. Removed Probe header insertion (now in prober itself). Added timeout on the command and probe streams
--  121021 JFC: Added throttling since transmitting a large number of large correlator frames overflows the Host buffers
--  130128 JFC: Changed they way HOST_BUFFER_READOUT_TIMER_MAX is computed to suit Vivado 2012.4 (did not like a non-constant in the slice)
--  130801 JFC: Modified to handle AXI-Streaming UDP RX and TX buses.
--
-- Improvements
--  110916 JFC: Add read count to read multiple bytes in one command
--  110916 JFC: Improve probe port scanning to reduce Probe data transmission latency
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chFPGA_Package.all; -- Get all component definitions

library UNISIM;
use UNISIM.VComponents.all;

-- Ethernet port access arbitrator. Passes the incoming commands to the modules, and merges the incoming command replies and data streams with some arbitrating algorithm.
-- Command frame format
--		  Byte 0 | Byte 1 | Byte 2
--    [pppNNAAA AAAAAAAA AAAAAAAA]
--
--
--  Byte 0 - 2: (Byte 0 is received first and is MSB)
--    Bit 23-21 (ppp) Operation opcode
--    Bit 20-19 (NN): Log2 of number of bytes to read (Read command only). 0: 1 byte, 1: 2 bytes, 2: 4 bytes, 3: 8 bytes
--    Bit 18-0: 19-bit address

----
-- The address space is subdivided according to the needs of the design.
-- The subdivision is done by the ROUTERs, which splits the command and reply streams in N ways based on the number of adrress bits used for the splitting.
-- A typical splitting scheme is:
--    Bits 19-17: Subsystem (SYSTEM, CHAN/ADC, CORR, REORDER, GPU_LINK etc)
--    Bits 16-13: Instance number (0-15, one for each)
--    Bits 12-10: Module number (0-7)
--    Bits 9-0 (AAAAAAAAAA): 10-bit address within module

-- The module address space is split to distinguish between COMMAND, STATUS and RAM/DRP accesses:

--  Byte 3+: Data bytes (write command only)
--
-- Note: Does not handle the UDP transmitter TREADY signal: we will send data even if the TX buffers are full.
--    Also always passes the received UDP data to the command bus independent of its TREADY state.
--
entity bsb_master is
	GENERIC (
		NUMBER_OF_PROBES: INTEGER
	);
	PORT (
		-- UDP Transmitter/Receiver interface

		-- UDP Rx interface (synchronous to clk)
		
		s_axis_udp_rx_tdata  : in std_logic_vector (7 downto 0);
		s_axis_udp_rx_tvalid : in std_logic;
		s_axis_udp_rx_tlast  : in std_logic;
		s_axis_udp_rx_tready : out std_logic;

		-- UDP Tx interface (synchronous to clk)
		
		m_axis_udp_tx_tvalid : out std_logic;
		m_axis_udp_tx_tdata : out  std_logic_vector (7 downto 0); -- will be axis_tx_tdata
		m_axis_udp_tx_tlast : out std_logic;
		m_axis_udp_tx_tready: in std_logic;
		m_axis_udp_tx_channel : out std_logic_vector(1 downto 0); -- Port offset. The destination port number will be offseted by this value relatove to the base port number.


		-- Command and reply stream buses
		
		m_axis_cmd_tdata  : out std_logic_vector(7 downto 0);
		m_axis_cmd_tvalid : out std_logic;
		m_axis_cmd_tlast  : out std_logic;
		m_axis_cmd_tready : in std_logic;

		s_axis_rply_tdata  : in std_logic_vector(7 downto 0);
		s_axis_rply_tvalid : in std_logic;
		s_axis_rply_tlast  : in std_logic;
		s_axis_rply_tready : out std_logic;


		-- Raw Data stream buses

		s_axis_data_tdata: in slv8_array(NUMBER_OF_PROBES-1 downto 0);
		s_axis_data_tvalid: in slv(NUMBER_OF_PROBES-1 downto 0);
		s_axis_data_tlast: in slv(NUMBER_OF_PROBES-1 downto 0);
		s_axis_data_tready: out slv(NUMBER_OF_PROBES-1 downto 0);

		--prb_dat: in axis8_dat_struct_array(NUMBER_OF_PROBES-1 downto 0);
		--prb_rdy: out axis8_rdy_struct_array(NUMBER_OF_PROBES-1 downto 0);

		-- System
		
		cmd_packet_counter: out std_logic_vector(7 downto 0);
		rply_packet_counter: out std_logic_vector(7 downto 0);
		host_frame_read_rate: in std_logic_vector(4 downto 0);
		clk:  in std_logic;
		rst : in std_logic
		);

end bsb_master;

architecture Behavioral of bsb_master is

-- RX process
signal s_axis_udp_rx_tready_int: std_logic;

-- TX Process

TYPE TX_STATE_TYPE IS (TX_STATE_SCAN, TX_STATE_SEND_CMD,TX_STATE_SEND_ANT, TX_STATE_WAIT); -- States of the TX state machine
signal tx_state: TX_STATE_TYPE := TX_STATE_SCAN; -- Initialization needed
signal probe_number : integer range 0 to (NUMBER_OF_PROBES-1):=0;
signal timeout_ctr: unsigned(7 downto 0); --
signal host_buffer_readout_timer: unsigned(23 downto 0);
signal host_buffer_readout_timer_max: unsigned(host_buffer_readout_timer'Range);

signal host_buffer_count: unsigned(15 downto 0); -- Counts the estimated bytes in the host buffer. Frames are not sent if the buffer is more than half full. Must be at least twice the size of the maximum frame length (6667 bytes for a correlator frame).
signal m_axis_udp_tx_tvalid_int: std_logic;

signal cmd_packet_counter_int: unsigned(7 downto 0) := (others=>'0');
signal rply_packet_counter_int: unsigned(7 downto 0) := (others=>'0');
signal is_reply_header: std_logic;
signal s_axis_udp_rx_tfirst: std_logic := '1';

--signal rply_flush: std_logic;
--signal prb_flush: std_logic_vector(0 to NUMBER_OF_PROBES-1);

begin

-- Receive process: process incoming commands
-- The uncoming UDP stream is just passed on to the command bus.

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
tx_proc: process(all)
	begin
		if rising_edge(clk) then

			-- Always increment timout counter, unless resetted below
			-- Prevent roll-over to be safe, but that should be handled by the logic below
			if signed(timeout_ctr) /= -1 then
				timeout_ctr <= timeout_ctr + 1;
			end if;

			-------------------------------
			-- Data throttling
			-------------------------------
			-- Throttle the data output rate.
			--
			-- This attempts to evaluate the amount of data there is in the
			-- host buffer. We do this by counting how many bytes are sent,
			-- and clearing that count every N seconds to simulate the host
			-- reading its buffer periodically every N seconds.

			-- The HOST_BUFFER_COUNTER is incremented every time a byte is
			-- sent. Transmission of non-command frames will be held when the
			-- buffer more than half-full. The counter is cleared every
			-- 2^HOST_READ_RATE *2  clock cycles.

			-- First compute the maximum timer count based on HOST_FRAME_READ_RATE.
			-- Set all bits <=HOST_FRAME_READ_RATE to 1
            -- The code was refactored below to make it work with Vivado, but beware of how it is implemented
            --
            -- The code below just fill host_buffer_readout_timer_max with `host_frame_read_rate` '1's, i.e.
            --    host_frame_read_rate=0: host_buffer_readout_timer_max = '00...0001'
            --    host_frame_read_rate=1: host_buffer_readout_timer_max = '00...0011'
            host_buffer_readout_timer_max <= (others => '0');
            for i in HOST_BUFFER_READOUT_TIMER_MAX'Range loop
                if i <= to_integer(unsigned(host_frame_read_rate)) then
                    host_buffer_readout_timer_max(i) <= '1';
                end if;
            end loop;

            -- Reset the host buffer count when we reached the simulated readout period
			if host_buffer_readout_timer = host_buffer_readout_timer_max then
				host_buffer_count <= (others=>'0');
				host_buffer_readout_timer <= (others=>'0');
			else
				if host_buffer_count = 0 then
					host_buffer_readout_timer <= (others=>'0');
				else
					host_buffer_readout_timer <= host_buffer_readout_timer + 1;
				end if;

				if m_axis_udp_tx_tvalid_int ='1' then
					host_buffer_count <= host_buffer_count + 1;
				end if;
			end if;

			-------------------------------
			-- Data selector/transmitter
			-------------------------------
			-- Scan all probe inputs for data in a round robin fashion, and
			-- send packets for probes that have data waiting.
			--
			-- Always process commands in priority before we process probe
			-- data.
			CASE tx_state IS

				-- Wait to see which data source has data to send
				WHEN TX_STATE_SCAN =>

					-- We send nothing in this state. We merely check which data source has something for us.
					m_axis_udp_tx_tvalid_int <= '0';


					-- The following blocks stop accepting replies. This
					-- should be systematically done in the state that landed
					-- us here. This is mainly useful for flush conditions, in
					-- which case no data will be processed anyway..

					s_axis_rply_tready <= '0';
					s_axis_data_tready <= (others => '0');

					-- Flush (and stop flushing) command replies
					--s_axis_rply_tready <= rply_flush;
					--if s_axis_rply_tvalid='1' and s_axis_rply_tlast ='1' then
					--	rply_flush <= '0';
					--end if;

					---- Flush (and stop flushing) probe data
					--for i in 0 to NUMBER_OF_PROBES-1 loop
					--	prb_rdy(i).tready <= prb_flush(i);
					--	if prb_dat(i).tvalid='1' and prb_dat(i).tlast='1' then
					--		prb_flush(i) <= '0';
					--	end if;
					--end loop;


					-- Send command reply in priority (if available)
					--
					-- We removed waiting for probe_number=0, because this
					-- prevents fast replies if we are waiting for throttling
					-- before getting to probe 0.
					if s_axis_rply_tvalid = '1' then
						s_axis_rply_tready <= '1'; -- start accepting reply bytes
						timeout_ctr <= (others=>'0');
						is_reply_header <= '1'; -- prepare to override first reply byte with reply counter
						tx_state <= TX_STATE_SEND_CMD;
					-- If we have noreply and are not throttling, check the probe input
					elsif host_buffer_count(host_buffer_count'HIGH) = '0' then-- If the count is less than half the max buffer size, then continue scanning the probe inputs and send the frames
						if s_axis_data_tvalid(probe_number)='1' then -- antenna data is ready
								-- start reading antenna data.
								-- the probe number will be incremented in the SEND_ANT state.
								s_axis_data_tready(probe_number) <= '1';
								timeout_ctr <= (others => '0');
								tx_state <= TX_STATE_SEND_ANT;
						-- if no data is awaiting, increment antenna number to proceed with scanning
						elsif (probe_number = NUMBER_OF_PROBES-1) then
							probe_number <= 0;
						else
							probe_number <= probe_number + 1;
						end if;
					end if; -- probe=0 and command reply ready

				-- Send command reply packet
				when TX_STATE_SEND_CMD => --
					m_axis_udp_tx_tvalid_int <= '0'; -- don't send anything if none of the conditions below are met
					if s_axis_rply_tvalid = '1' then

						timeout_ctr <= (others=>'0');  -- reset timout counter as long as we receive bytes

						m_axis_udp_tx_tvalid_int <= '1';
						m_axis_udp_tx_tdata <= s_axis_rply_tdata;
						m_axis_udp_tx_tlast <= s_axis_rply_tlast;
						m_axis_udp_tx_channel <= "00";

						-- replace only first byte of the reply with command counter
						is_reply_header <= '0';
						if is_reply_header = '1' then
							m_axis_udp_tx_tdata <= std_logic_vector(cmd_packet_counter_int);
						end if;

						-- Go back to SCAN state if this was the last byte of the reply packet
						if s_axis_rply_tlast='1' then
							s_axis_rply_tready <= '0'; -- we go back in scan mode, so we won't be accepting reply bytes anymore
							rply_packet_counter_int <= rply_packet_counter_int + 1;
							tx_state <= TX_STATE_SCAN;
						end if; -- if TLAST

					-- If we had no data (TVALID=0) for too long,  bail out so
					-- we are not stuck here forever
					elsif signed(timeout_ctr)=-1 then
						s_axis_rply_tready <= '0'; -- we go back in scan mode, so we won't be accepting reply bytes anymore
						tx_state <= TX_STATE_SCAN; -- the SCAN state will reset the UDP write signals
						-- Force the writing of one last byte with TLAST=1 so we don't leave packet remnants in the transmitter buffer
						m_axis_udp_tx_tvalid_int <= '1';
						m_axis_udp_tx_tdata <= X"DD"; -- send a recognizable byte to help understand when this happens
						m_axis_udp_tx_tlast <= '1';
						m_axis_udp_tx_channel <= "00";
					end if; -- if tvalid

				-- Transmit probe data in the currently selected probe
				when TX_STATE_SEND_ANT =>
					m_axis_udp_tx_tvalid_int <= '0'; -- don't send anything if none of the conditions below are met
					if s_axis_data_tvalid(probe_number)='1' then

						timeout_ctr <= (others => '0'); -- reset timout counter as long as we receive bytes

						m_axis_udp_tx_tvalid_int <= s_axis_data_tvalid(probe_number);
						m_axis_udp_tx_tdata <= s_axis_data_tdata(probe_number);
						m_axis_udp_tx_channel <= "01";
						m_axis_udp_tx_tlast <= s_axis_data_tlast(probe_number);

						if s_axis_data_tlast(probe_number)='1' then
							s_axis_data_tready(probe_number)<='0'; -- we don't accept reply bytes anymore
							timeout_ctr <= (others=>'0'); -- prepare counter for the wait state
							tx_state <= TX_STATE_WAIT; -- wait some time before returning to scan to make sure we don't fill the Ethernet interface FIFO
						end if; -- if TLAST;
					elsif signed(timeout_ctr)=-1 then -- if we had no TVALID until the counter reaches its maximum, abandon reception
						s_axis_data_tready(probe_number) <= '0'; -- we don't accept reply bytes anymore
						tx_state <= TX_STATE_SCAN; -- the SCAN state will reset the UDP write signals
						-- Force the writing of one last byte with TLAST=1 so we don't leave packet remnants in the transmitter buffer
						m_axis_udp_tx_tvalid_int <= '1';
						m_axis_udp_tx_tdata <= X"55";
						m_axis_udp_tx_tlast <= '1';
						m_axis_udp_tx_channel <= "01";
					end if; -- if TVALID

				-- Wait for some time after transmission to make sure there is
				-- enough time for the Ethernet interface to transmit the
				-- header bytes, otherwise the FIFO will eventually overflow
				--
				-- We wait for approx 128 CLK (7-bit timeout_ctr), i.e. 128 / 125e6 = 1.024 us.
				WHEN TX_STATE_WAIT =>
					m_axis_udp_tx_tvalid_int<='0';
					--m_axis_udp_tx_tlast<='0';
					if signed(timeout_ctr)=-1 then
						tx_state <= TX_STATE_SCAN;
						-- make sure we continue with the next probe. We don't want to send the same probe again if it happens it has an other frame already waiting.
						if (probe_number=NUMBER_OF_PROBES-1) then
							probe_number <= 0;
						else
							probe_number <= probe_number + 1;
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
				m_axis_udp_tx_channel <= (others=>'0');


				--prb_flush <= (others => '0');
				--rply_flush <= '0';  -- this used to be 1, but that complicates recovering after a fresh power up, and it does not seem to help much.
				-- reset reply bus
				s_axis_rply_tready <= '0';
				s_axis_data_tready <= (others => '0');

				host_buffer_readout_timer <= (others=>'0');
				host_buffer_count <= (others=>'0');

				rply_packet_counter_int <= (others=>'0');
			end if;

		end if; -- clk
	end process;


end Behavioral;

