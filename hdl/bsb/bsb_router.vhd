----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: J.-F. Cliche
--
-- Create Date:    00:41:43 05/13/2011
-- Design Name:
-- Module Name:    CMD_ROUTER - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description: Routes a command frame to one of the NUMBER_OF_PORT output command ports, and merges the  NUMBER_OF_PORT reply streams into one
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- <120224:  Horribly combinatorial. Would not be surprised if that breaks the timing, if not, That will do until we can pipeline the control bus.
-- 120224 JFC: Major rework. Now decodes the command stream to find the port number. Uses AXIS interfaces.
--             There may be some combinatorial logic left, but there is no longer a flowthrough path.
--             This implied that a 1 byte FIFO to handle delay in the destination TREADY to the source.
-- 				The path has a 1 byte latency minimum.
--					The router handles properly the handshake lines in both directions. This means that no collision can occur, the source will wait for the destination to be ready before sending data.
-- 120608 JFC: Removed old commented code
--	2012-10-20 JFC: Added a AXI4S Interconnect with slice registers to help meet timing. Seems to work when the fifo is not constrained.
-- 2012-11-20 JFC: CHanged interface to specify an ADDRESS_MASK instead of bit positions
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;
use work.chFPGA_Package.all;


entity bsb_router is
	generic(
		NUMBER_OF_PORTS: INTEGER := 8;
		ADDRESS_MASK: std_logic_vector(CTRL_CMD_ADDR_WIDTH-1 downto 0);
		TARGET_PBLOCK: string := "" -- generic passed as searchable node property in implementation
		);
    PORT (

		-- Upstream BSB interface (command and reply) (AXI-Streaming, blocking, on bsb_clk)
		
		s_axis_bsb_tdata: in std_logic_vector(7 downto 0);
		s_axis_bsb_tvalid: in std_logic;
		s_axis_bsb_tlast: in std_logic;
		s_axis_bsb_tready: out std_logic;

		m_axis_bsb_tdata: out std_logic_vector(7 downto 0);
		m_axis_bsb_tvalid: out std_logic;
		m_axis_bsb_tlast: out std_logic;
		m_axis_bsb_tready: in std_logic;

		-- BSB interface for each downstream port (command and reply) (AXI-Streaming, blocking, on bsb_clk)
	
		m_axis_routed_bsb_tdata: out slv8_array(0 to NUMBER_OF_PORTS-1);
		m_axis_routed_bsb_tvalid: out std_logic_vector(0 to NUMBER_OF_PORTS-1);
		m_axis_routed_bsb_tlast: out std_logic_vector(0 to NUMBER_OF_PORTS-1);
		m_axis_routed_bsb_tready: in std_logic_vector(0 to NUMBER_OF_PORTS-1);


		s_axis_routed_bsb_tdata: in slv8_array(0 to NUMBER_OF_PORTS-1);
		s_axis_routed_bsb_tvalid: in std_logic_vector(0 to NUMBER_OF_PORTS-1);
		s_axis_routed_bsb_tlast: in std_logic_vector(0 to NUMBER_OF_PORTS-1);
		s_axis_routed_bsb_tready: out std_logic_vector(0 to NUMBER_OF_PORTS-1);

		-- Monitoring signals
		
		cmd_overflow: out std_logic;

		-- System interface
		
		clk: in STD_LOGIC;
		rst : in  STD_LOGIC
		);

end bsb_router;

architecture Behavioral of bsb_router is

	function highest_mask_bit(mask:std_logic_vector) return integer is -- returns the position of the highest nonzero bit
		begin
			for i in mask'high downto mask'low loop
				if mask(i)='1' then
					return i;
				end if;
			end loop;
			return -1; -- invalid
		end highest_mask_bit;

	function lowest_mask_bit(mask:std_logic_vector) return integer is -- returns the position of the lowest nonzero bit
		begin
			for i in mask'low to mask'high loop
				if mask(i)='1' then
					return i;
				end if;
			end loop;
			return -1; -- invalid
		end lowest_mask_bit;

	constant PORT_NUMBER_HIGH_BIT: integer := highest_mask_bit(ADDRESS_MASK);
	constant PORT_NUMBER_LOW_BIT: integer := lowest_mask_bit(ADDRESS_MASK);

	-- Internal post-FIFO BSB signals
	signal cmd_tdata: std_logic_vector(7 downto 0);
	signal cmd_tvalid: std_logic;
	signal cmd_tlast: std_logic;
	signal cmd_tready: std_logic;
	signal rply_tdata: std_logic_vector(7 downto 0);
	signal rply_tvalid: std_logic;
	signal rply_tlast: std_logic;
	signal rply_tready: std_logic;

	signal cmd_port: integer range 0 to NUMBER_OF_PORTS-1;

	constant CMD_BUF_LENGTH: integer:= CTRL_CMD_BYTE_LENGTH + 2; -- Number of command bytes in buffer. Must be more than the command header length, +1 to accomodate pipeline latency in TREADY.

	signal cmd_buf_tdata: slv8_array(CMD_BUF_LENGTH-1 downto 0);
	signal cmd_buf_tvalid: std_logic_vector(CMD_BUF_LENGTH-1 downto 0);
	signal cmd_buf_tlast: std_logic_vector(CMD_BUF_LENGTH-1 downto 0);

	signal cmd_buf_len: integer range 0 to CMD_BUF_LENGTH; -- number of bytes in buffer

	type CMD_STATE_TYPE is (CMD_STATE_READ_CMD, CMD_STATE_READ_SEND_DAT);
	signal cmd_state: CMD_STATE_TYPE;

	-- Reply stream processing signals
	type RPLY_STATE_TYPE is (RPLY_STATE_SCAN, RPLY_STATE_SEND);
	signal rply_state: RPLY_STATE_TYPE;
	signal rply_overflow_tdata: std_logic_vector(7 downto 0);
	signal rply_overflow_tvalid: std_logic;
	signal rply_overflow_tlast: std_logic;
	signal rply_port: integer range 0 to NUMBER_OF_PORTS-1;


begin





-- Instantiate a FIFO at the input port
FIFO0 : entity work.bsb_sync_fifo
  PORT MAP (
  		-- External upstream interface
		cmd_a_tdata => s_axis_bsb_tdata,
		cmd_a_tvalid => s_axis_bsb_tvalid,
		cmd_a_tlast => s_axis_bsb_tlast,
		cmd_a_tready => s_axis_bsb_tready,
		rply_a_tdata => m_axis_bsb_tdata,
		rply_a_tvalid => m_axis_bsb_tvalid,
		rply_a_tlast => m_axis_bsb_tlast,
		rply_a_tready => m_axis_bsb_tready,

		-- FIFO'ed upstream interface
		cmd_b_tdata => cmd_tdata,
		cmd_b_tvalid => cmd_tvalid,
		cmd_b_tlast => cmd_tlast,
		cmd_b_tready => cmd_tready,
		rply_b_tdata => rply_tdata,
		rply_b_tvalid => rply_tvalid,
		rply_b_tlast => rply_tlast,
		rply_b_tready => rply_tready,

		-- System interface
		clk => clk,
		rst => rst
		);


cmd_proc: process(all)
	variable var_cmd_word: std_logic_vector(CTRL_CMD_WORD_WIDTH-1 downto 0);
begin

	if rising_edge(clk) then


		-- By default, clear the VALID flag whenever a port is read (i.e its READY=1). The code below will override this if we write a new value to the port.
		for i in 0 to NUMBER_OF_PORTS-1 loop
			m_axis_routed_bsb_tvalid(i) <= '0' when m_axis_routed_bsb_tready(i);
		end loop;

		---- Tell the source if we are ready for more data We accept bytes as
		--   long as the fifo is not one entry from full because there is a
		--   latency on one clock between the length and the TREADY, so we
		--   may have to accomodate one extra entry.
		cmd_tready <= to_std_logic(cmd_buf_len < CMD_BUF_LENGTH - 1);

		case cmd_state is

			-- Command bytes are coming in, and we are shifting them in and not reading them out until we have enough bytes to
			-- establish the packet destination address.
			when CMD_STATE_READ_CMD =>
				-- we arrive in this state when the last bytes of a frame has been transmitted.
				-- The FIFO might already be full with the next command bytes, in which case we simply proceed with grab the output port number and proceed with the data transmission
				-- otherwise we wait until the fifo is full.


				-- store the command words in the buffer
				if cmd_tvalid and cmd_tready then
					cmd_buf_tdata(cmd_buf_len) <= cmd_tdata;
					cmd_buf_tlast(cmd_buf_len) <= cmd_tlast;
					cmd_buf_len <= cmd_buf_len + 1; -- always increment the buffer length since we are not reading out bytes yet. cannot overflow because we get out of this state before.
				end if;

				-- If the buffer contains the full command header, get the port address and go process it in the next state.
				-- This is done whether or not an other byte is incoming so we are not blocking the pipeling for commands that have no data (read commands)
				-- We get the port and jump only when we have all 3 bytes stored, not as we receive the 3rd one.
				-- This adds a delay, and we may heve 4 samples in the buffer when we enter the read state,
				-- but we do this so can enter the command state with a buffer that has already the required header bytes.
				if cmd_buf_len >= CTRL_CMD_BYTE_LENGTH then
					-- Get the port number fromm the command in the buffer
					var_cmd_word := cmd_buf_tdata(0) & cmd_buf_tdata(1) & cmd_buf_tdata(2);
					cmd_port <= to_integer(unsigned(var_cmd_word(PORT_NUMBER_HIGH_BIT downto PORT_NUMBER_LOW_BIT)));
					cmd_state <= CMD_STATE_READ_SEND_DAT;
				end if;


			-- read state. We have 4 possibilities
			--     (data in, data out): action
			--    - 0 , 0: do nothing
			--    - 1,  0: write data at *length, length +=1
			--    - 0,  1: send data out, shift data, length-=1
			--    - 1,  1: send data out, shift data,  write data *(length-1), length += 0
			when CMD_STATE_READ_SEND_DAT => -- send the source data until the last byte of the frame


				---- If we get data out of the buffer
				if (m_axis_routed_bsb_tready(cmd_port)='1' or m_axis_routed_bsb_tvalid(cmd_port)='0') and cmd_buf_len /= 0 then -- If we can write to the output
					m_axis_routed_bsb_tdata(cmd_port) <= cmd_buf_tdata(0); -- Send the word at the top of the buffer
					m_axis_routed_bsb_tlast(cmd_port) <= cmd_buf_tlast(0);
					m_axis_routed_bsb_tvalid(cmd_port) <= '1';

					-- Shift right the buffer
					cmd_buf_tdata(CMD_BUF_LENGTH-2 downto 0) <= cmd_buf_tdata(CMD_BUF_LENGTH-1 downto 1);
					cmd_buf_tlast(CMD_BUF_LENGTH-2 downto 0) <= cmd_buf_tlast(CMD_BUF_LENGTH-1 downto 1);

					-- If we shifted the last byte of the backet, go back to header accumulation
					cmd_state <= CMD_STATE_READ_CMD when cmd_buf_tlast(0);

					-- now determine if we also need the write a new byte in the buffer, and adjust buffer length accordingly
					if cmd_tvalid and cmd_tready then -- if we accept a byte from the source

						-- write the incoming byte (shifted by one since the whole buffer has shifted)
						cmd_buf_tdata(cmd_buf_len-1) <= cmd_tdata;
						cmd_buf_tlast(cmd_buf_len-1) <= cmd_tlast;
						-- we keep the buffer length the same since we lost one buffer element but gained a new one
					else
						cmd_buf_len <= cmd_buf_len-1; -- We write nothing, so the buffer length is decremented. We already tested for cmd_buf_len /=0 in this block.
					end if;
				-- If we are not sending a byte to the output, just handle the incoming bytes if any
				elsif cmd_tvalid and cmd_tready then -- if we accept a byte from the source
						-- write the incoming byte (shifted by one since the whole buffer has shifted)
						cmd_buf_tdata(cmd_buf_len) <= cmd_tdata;
						cmd_buf_tlast(cmd_buf_len) <= cmd_tlast;
						cmd_buf_len <= cmd_buf_len + 1;
						-- Check for overflows. This should never happen by design
						-- because cmd_tready=0 by the time we get there.
						if cmd_buf_len = CMD_BUF_LENGTH then
							cmd_overflow <= '1';
							assert FALSE report "CTRL_ROUTER command FIFO has overflown"; -- should never happen by design
						end if;
				end if; -- if sending data out
		end case;

		-- Synchronous reset. Overrides signals above.
		if rst then
			-- Reset buses
			cmd_tready <= '1';
			m_axis_routed_bsb_tvalid <= (others => '0'); -- necessary
			cmd_overflow <= '0';
			cmd_port <= 0;
			cmd_buf_len <= 0;

			-- Initialize the state machine so it starts reading command bytes
			cmd_state <= CMD_STATE_READ_CMD;

		end if; -- rst
	end if; -- clk
end process;




-- Control replies routing
-- Monitors N reply buses, and when one is VALID, send the stream to the output until LAST
rply_proc: process(all) begin

	if rising_edge(clk) then

		if rst then
			-- reset buses
			rply_tvalid <= '0';
			s_axis_routed_bsb_tready <= (others => '1');

			-- initialize state machine
			rply_state<=RPLY_STATE_SCAN;
			rply_port<=0;
			rply_overflow_tvalid<='0';
		else

			rply_tvalid <= '0' when rply_tready; -- if the bus has read the byte on the bus, clear TVALID. This may be overriden below if a new byte is placed on the bus

			CASE rply_state IS
				WHEN RPLY_STATE_SCAN => -- If current antenna finished processing, set next state to SEND_CMD and increment antenna number in preparation for the next round

					s_axis_routed_bsb_tready <= (others => '0'); -- disable TREADY flag after previous state

					-- find next port ready with a reply
					for i in 0 to NUMBER_OF_PORTS-1 loop
--						if rply_in_dat(i).TVALID='1' and rply_out_rdy_int.TREADY='1' then -- if source and destination are ready
						if s_axis_routed_bsb_tvalid(i) then -- if source and destination are ready
								s_axis_routed_bsb_tready(i) <= '1';
								rply_port<=i;
								rply_state<=RPLY_STATE_SEND;
						end if;
					end loop;

				-- Send data from selected source port to the destination port
				WHEN RPLY_STATE_SEND => --

					s_axis_routed_bsb_tready(rply_port) <= rply_tready; -- may be overriden below

					-- Output the data to the destination
					if rply_tready or not rply_tvalid then -- if the bus is ready to receive a new byte
						if s_axis_routed_bsb_tvalid(rply_port) and s_axis_routed_bsb_tready(rply_port) then -- if a new source byte is being read
							if rply_overflow_tvalid then -- if there was an overflow byte, use it
								rply_tdata <= rply_overflow_tdata;
								rply_tvalid <= rply_overflow_tvalid;
								rply_tlast <= rply_overflow_tlast;
								rply_overflow_tdata <= s_axis_routed_bsb_tdata(rply_port);
								rply_overflow_tvalid <= s_axis_routed_bsb_tvalid(rply_port);
								rply_overflow_tlast <= s_axis_routed_bsb_tlast(rply_port);
							else
								rply_tdata <= s_axis_routed_bsb_tdata(rply_port);
								rply_tvalid <= s_axis_routed_bsb_tvalid(rply_port);
								rply_tlast <= s_axis_routed_bsb_tlast(rply_port);
							end if; -- oveflow
						else
							if rply_overflow_tvalid then -- if there was an overflow byte, use it
								rply_tdata <= rply_overflow_tdata;
								rply_tvalid <= rply_overflow_tvalid;
								rply_tlast <= rply_overflow_tlast;
								rply_overflow_tvalid <= '0';
							else
								rply_tvalid<='0';
							end if; -- oveflow
						end if;
					else -- if the bus is not accepting new data, process incoming
							-- if the destination is not ready but we already issued it the TREADY (saying we accepted the transfer), then forward the byte in the overflow.
						 -- This happens because the TREADy from the destination is registered and arrives late.
						 -- This is esentially implements a 1 deep FIFO
						if s_axis_routed_bsb_tvalid(rply_port) and s_axis_routed_bsb_tready(rply_port) then  -- otherwise if one is available from the source , send it
							rply_overflow_tdata <= s_axis_routed_bsb_tdata(rply_port);
							rply_overflow_tvalid <= s_axis_routed_bsb_tvalid(rply_port);
							rply_overflow_tlast <= s_axis_routed_bsb_tlast(rply_port);
						end if;
					end if;


					-- wait until the last byte of a packet has been read, then disable the TREADY and go back to scanning
					-- we could move this one cycle earlier to remove latency
					if rply_tvalid and rply_tlast and rply_tready then -- if we read the last byte of the frame
							s_axis_routed_bsb_tready(rply_port) <= '0'; -- stop accepting data because the next state will not process the transfer
							rply_state<=RPLY_STATE_SCAN;
					end if;
			end case;
		end if; --rst
	end if; -- clk
end process;

end Behavioral;

