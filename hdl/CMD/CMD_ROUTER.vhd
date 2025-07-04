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


entity CTRL_ROUTER is
	generic(
		NUMBER_OF_PORTS: INTEGER := 8;
		ADDRESS_MASK: std_logic_vector(CTRL_CMD_ADDR_WIDTH-1 downto 0);
		TARGET_PBLOCK: string := "" -- generic passed as searchable node property in implementation
		);
    PORT (

		-- Command streams from single slave input to multiple master outputs
		cmd_in_dat: in AXIS8_DAT_STRUCT;
		cmd_in_rdy: out AXIS8_RDY_STRUCT;
		cmd_out_dat: out AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_PORTS-1 downto 0);
		cmd_out_rdy: in AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_PORTS-1 downto 0);


		-- Reply streams from multiple slave inputs to single master output
		rply_in_dat: in AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_PORTS-1 downto 0);
		rply_in_rdy: out AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_PORTS-1 downto 0);
		rply_out_dat: out AXIS8_DAT_STRUCT;
		rply_out_rdy: in AXIS8_RDY_STRUCT;

		-- Monitoringn signals
		cmd_overflow: out std_logic;

		-- System interface
		clk: in STD_LOGIC;
		rst : in  STD_LOGIC
		);

end CTRL_ROUTER;

architecture Behavioral of CTRL_ROUTER is

	function highest_mask_bit(mask:std_logic_vector) return integer is --! returns the position of the highest nonzero bit
		begin
			for i in mask'high downto mask'low loop
				if mask(i)='1' then
					return i;
				end if;
			end loop;
			return -1; -- invalid
		end highest_mask_bit;

	function lowest_mask_bit(mask:std_logic_vector) return integer is --! returns the position of the lowest nonzero bit
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

	-- Interfal post-FIFO BSB signals
	signal cmd_in_dat_int:  AXIS8_DAT_STRUCT;
	signal cmd_in_rdy_int: AXIS8_RDY_STRUCT;
	signal rply_out_dat_int:  AXIS8_DAT_STRUCT;
	signal rply_out_rdy_int: AXIS8_RDY_STRUCT;

	signal cmd_port: integer range 0 to NUMBER_OF_PORTS-1;

	signal cmd_out_dat_int_tdata: slv8_array(NUMBER_OF_PORTS-1 downto 0);
	signal cmd_out_dat_int_tvalid: slv(NUMBER_OF_PORTS-1 downto 0);
	signal cmd_out_dat_int_tlast: slv(NUMBER_OF_PORTS-1 downto 0);

	constant CMD_FIFO_LENGTH: integer:= CTRL_CMD_BYTE_LENGTH + 2; -- Number of command bytes in FIFO. Must be more than the command header length, +1 to accomodate pipeline latency in TREADY.
	signal cmd_word: std_logic_vector(23 downto 0);

	signal cmd_fifo_tdata: slv8_array(CMD_FIFO_LENGTH-1 downto 0);
	signal cmd_fifo_tvalid: slv(CMD_FIFO_LENGTH-1 downto 0);
	signal cmd_fifo_tlast: slv(CMD_FIFO_LENGTH-1 downto 0);

	signal cmd_fifo_len: integer range 0 to CMD_FIFO_LENGTH; -- number of bytes in FIFO
	--signal cmd_fifo_len: unsigned(1 downto 0); -- number of bytes in FIFO

	--signal CMD_OVERFLOW: AXIS8_DAT_STRUCT;

	type CMD_STATE_TYPE is (CMD_STATE_READ_CMD, CMD_STATE_READ_SEND_DAT);
	signal cmd_state: CMD_STATE_TYPE;

	-- Reply stream processing signals
	type RPLY_STATE_TYPE is (RPLY_STATE_SCAN, RPLY_STATE_SEND);
	signal rply_state: RPLY_STATE_TYPE;
	signal rply_overflow: AXIS8_DAT_STRUCT;
	signal rply_port: integer range 0 to NUMBER_OF_PORTS-1;
	signal rply_in_rdy_int_tready: slv(NUMBER_OF_PORTS-1 downto 0);


begin



-- Assign internal CMD bus to output
gen_cmd_out: for i in 0 to NUMBER_OF_PORTS-1 generate
	cmd_out_dat(i).TDATA <= cmd_out_dat_int_tdata(i);
	cmd_out_dat(i).TVALID <= cmd_out_dat_int_tvalid(i);
	cmd_out_dat(i).TLAST <= cmd_out_dat_int_tlast(i);
	rply_in_rdy(i).TREADY <= rply_in_rdy_int_tready(i);
end generate;


--! Instantiate a FIFO at the input port
FIFO0 : entity work.CMD_SYNC_FIFO
  PORT MAP (
  		-- External command input interface
		CMD_A_DAT => cmd_in_dat,
		CMD_A_RDY => cmd_in_rdy,
		RPLY_A_DAT => rply_out_dat,
		RPLY_A_RDY => rply_out_rdy,
		-- FIFO'ed command input
		CMD_B_DAT => cmd_in_dat_int,
		CMD_B_RDY => cmd_in_rdy_int,
		RPLY_B_DAT => rply_out_dat_int,
		RPLY_B_RDY => rply_out_rdy_int,

		-- System interface
		clk => clk,
		rst => rst
		);


cmd_proc: process(clk,rst)

	variable var_cmd_word: std_logic_vector(CTRL_CMD_WORD_WIDTH-1 downto 0);
	variable var_cmd_port: integer range 0 to NUMBER_OF_PORTS-1;

begin

	if rising_edge(clk) then


		-- By default, clear the VALID flag whenever a port is read (i.e its READY=1). The code below will override this if we write a new value to the port.
		for i in 0 to NUMBER_OF_PORTS-1 loop
			if cmd_out_rdy(i).TREADY='1' then
				cmd_out_dat_int_tvalid(i) <= '0';
			end if;
		end loop;

		---- Tell the source if we are ready for more data We accept bytes as
		--   long as the fifo is not one entry from full because there is a
		--   latency on one clock between the length and the TREADY, so we
		--   may have to accomodate one extra entry.
		cmd_in_rdy_int.TREADY <= to_std_logic(cmd_fifo_len < CMD_FIFO_LENGTH - 1);

		case cmd_state is

			-- Command bytes are coming in, and we are shifting them in and not reading them out until we have enough bytes to
			-- establish the packet destination address.
			when CMD_STATE_READ_CMD =>
				-- we arrive in this state when the last bytes of a frame has been transmitted.
				-- The FIFO might already be full with the next command bytes, in which case we simply proceed with grab the output port number and proceed with the data transisssion
				-- otherwise we wait until the fifo is full.


				-- store the command words in the fifo
				if cmd_in_dat_int.TVALID = '1' and cmd_in_rdy_int.TREADY='1'  then
					cmd_fifo_tdata(cmd_fifo_len) <= cmd_in_dat_int.TDATA;
					cmd_fifo_tlast(cmd_fifo_len) <= cmd_in_dat_int.TLAST;
					cmd_fifo_len <= cmd_fifo_len + 1; -- always increment the FIFO length since we are not reading out bytes yet. cannot overflow because we get out of this state before.
				end if;

				-- If the FIFO contains the full command header, get the port address and go process it in the next state.
				-- This is done whether or not an other byte is incoming so we are not blocking the pipeling for commands that have no data (read commands)
				-- We get the port and jump only when we have all 3 bytes stored, not as we receive the 3rd one.
				-- This adds a delay, and we may heve 4 samples in the FIFO when we enter the read state,
				-- but we do this so can enter the command state with a buffer that has already the required header bytes.
				if cmd_fifo_len >= CTRL_CMD_BYTE_LENGTH then
					-- Get the port number fromm the command in the FIFO
					var_cmd_word := cmd_fifo_tdata(0) & cmd_fifo_tdata(1) & cmd_fifo_tdata(2);
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


				---- If we get data out of the FIFO
				if (cmd_out_rdy(cmd_port).TREADY='1' or cmd_out_dat_int_tvalid(cmd_port) = '0') and cmd_fifo_len /= 0 then -- If we can write to the output
					cmd_out_dat_int_tdata(cmd_port) <= cmd_fifo_tdata(0); -- Send the word at the top of the FIFO
					cmd_out_dat_int_tlast(cmd_port) <= cmd_fifo_tlast(0);
					cmd_out_dat_int_tvalid(cmd_port) <= '1';

					-- Shift right the FIFO
					cmd_fifo_tdata(CMD_FIFO_LENGTH-2 downto 0) <= cmd_fifo_tdata(CMD_FIFO_LENGTH-1 downto 1);
					cmd_fifo_tlast(CMD_FIFO_LENGTH-2 downto 0) <= cmd_fifo_tlast(CMD_FIFO_LENGTH-1 downto 1);

					-- If we shifted the last byte of the backet, go back to header accumulation
					if cmd_fifo_tlast(0) = '1' then
						cmd_state <= CMD_STATE_READ_CMD;
					end if; -- if LAST

					-- now determine if we also need the write a new byte in the FIFO, and adjust FIFO length accordingly
					if cmd_in_dat_int.TVALID='1' and cmd_in_rdy_int.TREADY='1' then -- if we accept a byte from the source

						-- write the incoming byte (shifted by one since the whole FIFO has shifted)
						cmd_fifo_tdata(cmd_fifo_len-1) <= cmd_in_dat_int.TDATA;
						cmd_fifo_tlast(cmd_fifo_len-1) <= cmd_in_dat_int.TLAST;
						-- we keep the FIFO length the same since we lost one FIFO element but gained a new one
					else
						cmd_fifo_len <= cmd_fifo_len-1; -- We write nothing, so the FIFO length is decremented. We already tested for cmd_fifo_len /=0 in this block.
					end if;
				-- If we are not sending a byte to the output, just handle the incoming bytes if any
				elsif cmd_in_dat_int.TVALID = '1' and cmd_in_rdy_int.TREADY = '1' then -- if we accept a byte from the source
						-- write the incoming byte (shifted by one since the whole FIFO has shifted)
						cmd_fifo_tdata(cmd_fifo_len) <= cmd_in_dat_int.TDATA;
						cmd_fifo_tlast(cmd_fifo_len) <= cmd_in_dat_int.TLAST;
						cmd_fifo_len <= cmd_fifo_len + 1;
						-- Check for overflows. This should never happen by design
						-- because cmd_in_rdy_int.TREADY=0 by the time we get there.
						if cmd_fifo_len = CMD_FIFO_LENGTH then
							cmd_overflow <= '1';
							assert FALSE report "CTRL_ROUTER command FIFO has overflown"; -- should never happen by design
						end if;
				end if; -- if sending data out
		end case;

		-- Synchronous reset. Overrides signals above.
		if rst = '1' then
			-- Reset buses
			cmd_in_rdy_int.TREADY <= '1';
			for i in 0 to NUMBER_OF_PORTS-1 loop
				cmd_out_dat_int_tvalid(i) <= '0'; -- necessary
			end loop;
			cmd_overflow <= '0';
			cmd_port <= 0;
			cmd_fifo_len <= 0;

			-- Initialize the state machine so it starts reading command bytes
			cmd_state <= CMD_STATE_READ_CMD;

		end if; -- rst
	end if; -- clk
end process;




-- Control replies routing
-- Monitors N reply buses, and when one is VALID, send the stream to the output until LAST
rply_proc: process(clk, rst)
begin

	if rising_edge(clk) then

		if rst='1' then
			-- reset buses
			rply_out_dat_int.TVALID<='0';
			for i in 0 to NUMBER_OF_PORTS-1 loop
				rply_in_rdy_int_tready(i) <= '1';
			end loop;

			-- initialize state machine
			rply_state<=RPLY_STATE_SCAN;
			rply_port<=0;
			rply_overflow.TVALID<='0';
		else

			if rply_out_rdy_int.TREADY='1' then -- if the bus has read the byte on the bus, clear TVALID. This may be overriden below if a new byte is placed on the bus
				rply_out_dat_int.TVALID<='0';
			end if;

			CASE rply_state IS
				WHEN RPLY_STATE_SCAN => -- If current antenna finished processing, set next state to SEND_CMD and increment antenna number in preparation for the next round

					for i in 0 to NUMBER_OF_PORTS-1 loop
						rply_in_rdy_int_tready(i) <= '0'; -- disable TREADY flag after previous state
					end loop;

					-- find next port ready with a reply
					for i in 0 to NUMBER_OF_PORTS-1 loop
--						if rply_in_dat(i).TVALID='1' and rply_out_rdy_int.TREADY='1' then -- if source and destination are ready
						if rply_in_dat(i).TVALID='1' then -- if source and destination are ready
								rply_in_rdy_int_tready(i) <= '1';
								rply_port<=i;
								rply_state<=RPLY_STATE_SEND;
						end if;
					end loop;

				-- Send data from selected source port to the destination port
				WHEN RPLY_STATE_SEND => --

					rply_in_rdy_int_tready(rply_port) <= rply_out_rdy_int.TREADY; -- may be overriden below

					-- Output the data to the destination
					if rply_out_rdy_int.TREADY='1' or rply_out_dat_int.TVALID='0' then -- if the bus is ready to receive a new byte
						if rply_in_dat(rply_port).TVALID='1' and rply_in_rdy_int_tready(rply_port) = '1' then -- if a new source byte is being read
							if rply_overflow.TVALID='1' then -- if there was an overflow byte, use it
								rply_out_dat_int<=rply_overflow;
								rply_overflow<=rply_in_dat(rply_port);
							else
								rply_out_dat_int<=rply_in_dat(rply_port);
							end if; -- oveflow
						else
							if rply_overflow.TVALID='1' then -- if there was an overflow byte, use it
								rply_out_dat_int<=rply_overflow;
								rply_overflow.TVALID<='0';
							else
								rply_out_dat_int.TVALID<='0';
							end if; -- oveflow
						end if;
					else -- if the bus is not accepting new data, process incoming
							-- if the destination is not ready but we already issued it the TREADY (saying we accepted the transfer), then forward the byte in the overflow.
						 -- This happens because the TREADy from the destination is registered and arrives late.
						 -- This is esentially implements a 1 deep FIFO
						if rply_in_dat(rply_port).TVALID='1' and rply_in_rdy_int_tready(rply_port) = '1' then  -- otherwise if one is available from the source , send it
							rply_overflow<=rply_in_dat(rply_port);
						end if;
					end if;


					-- wait until the last byte of a packet has been read, then disable the TREADY and go back to scanning
					-- we could move this one cycle earlier to remove latency
					if rply_out_dat_int.TVALID='1' and rply_out_dat_int.TLAST='1' and rply_out_rdy_int.TREADY='1' then -- if we read the last byte of the frame
							rply_in_rdy_int_tready(rply_port) <= '0'; -- stop accepting data because the next state will not process the transfer
							rply_state<=RPLY_STATE_SCAN;
					end if;
			end case;
		end if; --rst
	end if; -- clk
end process;

end Behavioral;

