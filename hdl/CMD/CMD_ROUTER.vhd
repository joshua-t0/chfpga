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
use work.chFPGA_Package.all; -- Get all component definitions
--use work.ip_package.all; -- Import definition of components used in this module


entity CTRL_ROUTER is
	generic(
		NUMBER_OF_PORTS: INTEGER :=8;
		ADDRESS_MASK: std_logic_vector(CTRL_ADDR_WIDTH-1 downto 0);
		TARGET_PBLOCK: string := "" -- generic passed as searchable node property in implementation 
		);
    PORT (

		-- Command streams from single slave input to multiple master outputs
		CMD_IN_DAT: in AXIS8_DAT_STRUCT;
		CMD_IN_RDY: out AXIS8_RDY_STRUCT;
		CMD_OUT_DAT: out AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_PORTS-1 downto 0);
		CMD_OUT_RDY: in AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_PORTS-1 downto 0);


		-- Reply streams from multiple slave inputs to single master output
		RPLY_IN_DAT: in AXIS8_DAT_STRUCT_ARRAY(NUMBER_OF_PORTS-1 downto 0);
		RPLY_IN_RDY: out AXIS8_RDY_STRUCT_ARRAY(NUMBER_OF_PORTS-1 downto 0);
		RPLY_OUT_DAT: out AXIS8_DAT_STRUCT;
		RPLY_OUT_RDY: in AXIS8_RDY_STRUCT;


		-- System interface
		CLK: in STD_LOGIC;
		RST : in  STD_LOGIC
		);

end CTRL_ROUTER;

architecture Behavioral of CTRL_ROUTER is

-- make sure the router logic doesn't get fused with cells that are forced to be placed far away
attribute keep_hierarchy : string;
attribute keep_hierarchy of Behavioral : architecture is "yes";


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


signal CMD_IN_DAT_FIFO:  AXIS8_DAT_STRUCT;
signal CMD_IN_RDY_FIFO:  AXIS8_RDY_STRUCT;
signal RPLY_OUT_DAT_FIFO:  AXIS8_DAT_STRUCT;
signal RPLY_OUT_RDY_FIFO: AXIS8_RDY_STRUCT;

signal CMD_PORT: integer range 0 to NUMBER_OF_PORTS-1;
signal CMD_IN_RDY_FIFO_INT: AXIS8_RDY_STRUCT;

signal cmd_out_dat_int_tdata: slv8_array(NUMBER_OF_PORTS-1 downto 0);
signal cmd_out_dat_int_tvalid: slv(NUMBER_OF_PORTS-1 downto 0);
signal cmd_out_dat_int_tlast: slv(NUMBER_OF_PORTS-1 downto 0);

constant CMD_FIFO_MAX_LENGTH: integer:= CTRL_CMD_BYTE_LENGTH+2;

signal CMD_FIFO_TDATA: slv8_array(CMD_FIFO_MAX_LENGTH-1 downto 0);
signal CMD_FIFO_TVALID: slv(CMD_FIFO_MAX_LENGTH-1 downto 0);
signal CMD_FIFO_TLAST: slv(CMD_FIFO_MAX_LENGTH-1 downto 0);

signal CMD_FIFO_LEN: integer range 0 to CMD_FIFO_MAX_LENGTH; -- number of bytes in FIFO

--signal CMD_FIFO_LEN: unsigned(1 downto 0); -- number of bytes in FIFO

--signal CMD_OVERFLOW: AXIS8_DAT_STRUCT;

type CMD_STATE_TYPE is (CMD_STATE_READ_CMD, CMD_STATE_SEND_CMD, CMD_STATE_READ_SEND_DAT);
signal CMD_STATE: CMD_STATE_TYPE;

-- Reply stream processing signals
type RPLY_STATE_TYPE is (RPLY_STATE_SCAN, RPLY_STATE_SEND);
signal RPLY_STATE: RPLY_STATE_TYPE;
signal RPLY_OVERFLOW: AXIS8_DAT_STRUCT;
signal RPLY_PORT: integer range 0 to NUMBER_OF_PORTS-1;
signal RPLY_IN_RDY_INT_TREADY: slv(NUMBER_OF_PORTS-1 downto 0);
signal RPLY_OUT_DAT_FIFO_INT: AXIS8_DAT_STRUCT;


begin



-- Assign internal CMD bus to output
gen_cmd_out: for i in 0 to NUMBER_OF_PORTS-1 generate
	CMD_OUT_DAT(i).TDATA <= cmd_out_dat_int_tdata(i);
	CMD_OUT_DAT(i).TVALID <= cmd_out_dat_int_tvalid(i);
	CMD_OUT_DAT(i).TLAST <= cmd_out_dat_int_tlast(i);
	RPLY_IN_RDY(i).TREADY <= RPLY_IN_RDY_INT_TREADY(i);
end generate;
RPLY_OUT_DAT_FIFO <= RPLY_OUT_DAT_FIFO_INT;
CMD_IN_RDY_FIFO <= CMD_IN_RDY_FIFO_INT;


--! Instantiate a FIFO at the input port
FIFO0 : entity work.CMD_SYNC_FIFO
  PORT MAP (
  		-- External command input interface
		CMD_A_DAT=>CMD_IN_DAT,
		CMD_A_RDY=>CMD_IN_RDY,
		RPLY_A_DAT=>RPLY_OUT_DAT,
		RPLY_A_RDY=>RPLY_OUT_RDY,
		-- FIFO'ed command input
		CMD_B_DAT=>CMD_IN_DAT_FIFO,
		CMD_B_RDY=>CMD_IN_RDY_FIFO,
		RPLY_B_DAT=>RPLY_OUT_DAT_FIFO,
		RPLY_B_RDY=>RPLY_OUT_RDY_FIFO,

		-- System interface
		CLK => CLK,
		RST => RST
		);


cmd_proc: process(CLK,RST)

	variable VAR_CMD_COMMAND_WORD: std_logic_vector(CTRL_CMD_WORD_WIDTH-1 downto 0);
	variable VAR_CMD_ADDR: std_logic_vector(CTRL_ADDR_WIDTH-1 downto 0);
	variable VAR_CMD_PORT: integer range 0 to NUMBER_OF_PORTS-1;

	begin

		if rising_edge(CLK) then

			if RST='1' then
				-- Reset buses
				CMD_IN_RDY_FIFO_INT.TREADY<='1';
				for i in 0 to NUMBER_OF_PORTS-1 loop
					cmd_out_dat_int_tvalid(i) <= '0'; -- necessary
				end loop;

				CMD_PORT <= 0;
				CMD_FIFO_LEN <= 0;

				-- Initialize the state machine so it starts reading command bytes
				CMD_STATE <= CMD_STATE_READ_CMD;

			else

				-- By default, clear the VALID flag whneever a port is read (i.e its READY=1). The code below will override this if we write a new value to the port.
				for i in 0 to NUMBER_OF_PORTS-1 loop
					if CMD_OUT_RDY(i).TREADY='1' then
						cmd_out_dat_int_tvalid(i) <= '0'; --commented out for debug
					end if;
				end loop;


				-- Precompute the port number is case it is needed. This essentially gathers bits afrom various places and does not create logic.
				--VAR_CMD_PORT:=to_integer(UNSIGNED(VAR_CMD_ADDR(PORT_NUMBER_HIGH_BIT downto PORT_NUMBER_LOW_BIT)));

				case CMD_STATE is

					-- Command bytes are coming in, and we are shifting them in to establish the packet destination address.
					-- The data transmission is stopped until we know where the packet hould go.
					when CMD_STATE_READ_CMD =>
						-- we arrive in this state when the last bytes of a frame has been transmitted.
						-- The FIFO might already be full with the next command bytes, in which case we simply proceed with grab the output port number and proceed with the data transisssion
						-- otherwise we wait until the fifo is full.

						-- all destination port not sending data while we gather the command word. We'll send them later
	--					for i in 0 to NUMBER_OF_PORTS-1 loop
	--						CMD_OUT_DAT_INT(i).TVALID<='0';
	--					end loop;

						-- store the command words in the fifo until we have all of them, then jump to the next state
						if CMD_IN_DAT_FIFO.TVALID='1' and CMD_IN_RDY_FIFO_INT.TREADY='1' then
	--						CMD_FIFO<= CMD_IN_DAT_FIFO & CMD_FIFO(0 to CTRL_CMD_BYTE_LENGTH-2);
							-- write the byte in the FIFO
							CMD_FIFO_TDATA(CMD_FIFO_LEN)<= CMD_IN_DAT_FIFO.TDATA;
							CMD_FIFO_TVALID(CMD_FIFO_LEN)<= CMD_IN_DAT_FIFO.TVALID;
							CMD_FIFO_TLAST(CMD_FIFO_LEN)<= CMD_IN_DAT_FIFO.TLAST;
							CMD_FIFO_LEN <= CMD_FIFO_LEN + 1; -- always increment the FIFO length since we are not reading out bytes yet. cannot overflow because we get out of this state before.
						end if;

						-- If we have enough bytes in the FIFO to get a full command, get the port address and go process it in the next state.
						-- This is done whether or not an other byte is incoming so we are not blocking the pipeling for commands that have no data (read commands)
						if CMD_FIFO_LEN=CTRL_CMD_BYTE_LENGTH then
							-- Get the port number fromm the command in the FIFO
							for i in CTRL_CMD_BYTE_LENGTH-1 downto 0 loop
								VAR_CMD_COMMAND_WORD(8*i+7 downto 8*i):=CMD_FIFO_TDATA(CTRL_CMD_BYTE_LENGTH-1-i);
							end loop;
							VAR_CMD_ADDR:=VAR_CMD_COMMAND_WORD(CTRL_ADDR_WIDTH-1 downto 0);
							CMD_PORT<=to_integer(UNSIGNED(VAR_CMD_ADDR(PORT_NUMBER_HIGH_BIT downto PORT_NUMBER_LOW_BIT)));
							CMD_STATE<=CMD_STATE_READ_SEND_DAT;
							-- Note: CMD_IN_RDY_FIFO.TREADY is still '1'
						end if;

							-- detect if we are finished
							--if CMD_FIFO_LEN=CTRL_CMD_BYTE_LENGTH-1 then -- if we are shifting in the last command byte on this clock, register port number and jump to next state. We count bytes instead of looking for a TVALID at the end of the pipeline because the command sequence may have been interrupted and the TVALID would not ve an indication that a valid command i ready.

						-- if FIFO is full (with 3 command bytes) and the first two bytes are not LAST then grab port number and start sending FIFO output


					when CMD_STATE_READ_SEND_DAT => -- send the source data until the last byte of the frame

						---- Tell the source if we are ready for more data
						CMD_IN_RDY_FIFO_INT.TREADY<=CMD_OUT_RDY(CMD_PORT).TREADY; -- can be overriden below

						---- Get data in and out of the FIFO
						if (CMD_OUT_RDY(CMD_PORT).TREADY='1' or cmd_out_dat_int_tvalid(CMD_PORT) = '0') and CMD_FIFO_LEN /= 0 then -- If we can write to the output
							cmd_out_dat_int_tdata(CMD_PORT) <= CMD_FIFO_TDATA(0); -- Send the word at the top of the FIFO
							cmd_out_dat_int_tvalid(CMD_PORT) <= CMD_FIFO_TVALID(0); -- Send the word at the top of the FIFO
							cmd_out_dat_int_tlast(CMD_PORT) <= CMD_FIFO_TLAST(0); -- Send the word at the top of the FIFO

							-- Shift right the FIFO
							CMD_FIFO_TDATA(CMD_FIFO_MAX_LENGTH-2 downto 0) <= CMD_FIFO_TDATA(CMD_FIFO_MAX_LENGTH-1 downto 1);
							CMD_FIFO_TVALID(CMD_FIFO_MAX_LENGTH-2 downto 0) <= CMD_FIFO_TVALID(CMD_FIFO_MAX_LENGTH-1 downto 1);
							CMD_FIFO_TLAST(CMD_FIFO_MAX_LENGTH-2 downto 0) <= CMD_FIFO_TLAST(CMD_FIFO_MAX_LENGTH-1 downto 1);
							-- now determine if we need the write a new byte in the FIFO, and adjust FIFO length accordingly
							if CMD_IN_DAT_FIFO.TVALID='1' and CMD_IN_RDY_FIFO_INT.TREADY='1' then -- if we accept a byte from the source

								-- write the incoming byte (shifted by one since the whole FIFO has shifted)
								CMD_FIFO_TDATA(CMD_FIFO_LEN-1) <= CMD_IN_DAT_FIFO.TDATA;
								CMD_FIFO_TVALID(CMD_FIFO_LEN-1) <= CMD_IN_DAT_FIFO.TVALID;
								CMD_FIFO_TLAST(CMD_FIFO_LEN-1) <= CMD_IN_DAT_FIFO.TLAST;
								-- keep the FIFO length the same since we lost one FIFO element but gained a new one
							else
								CMD_FIFO_LEN<=CMD_FIFO_LEN-1; -- We write nothing, so the FIFO length is decremented
							end if;
							---- If we are sending the last word of the packet, handle the new command
							-- If the FIFO already contains the command byte, get their address and just continue. Otherwise, go back to the CMD_STATE_READ_CMD state to wait until we have all of them
							if CMD_FIFO_TLAST(0) = '1' then
								if CMD_FIFO_LEN<=CTRL_CMD_BYTE_LENGTH then
									CMD_STATE<=CMD_STATE_READ_CMD;
									CMD_IN_RDY_FIFO_INT.TREADY<='1';
								else
									-- Get the port number fromm the command in the FIFO
									for i in CTRL_CMD_BYTE_LENGTH-1 downto 0 loop
										VAR_CMD_COMMAND_WORD(8*i+7 downto 8*i) := CMD_FIFO_TDATA(CTRL_CMD_BYTE_LENGTH-i); -- note: here we read bytes FIFO(3 downto 1) because FIFO(0) is the byte going out
									end loop;
									VAR_CMD_ADDR:=VAR_CMD_COMMAND_WORD(CTRL_ADDR_WIDTH-1 downto 0);
									CMD_PORT<=to_integer(UNSIGNED(VAR_CMD_ADDR(PORT_NUMBER_HIGH_BIT downto PORT_NUMBER_LOW_BIT)));
								end if;
							end if; -- if LAST
						else -- If we are not writing a byte to the output, just handle the incoming bytes
							if CMD_IN_DAT_FIFO.TVALID='1' and CMD_IN_RDY_FIFO_INT.TREADY='1' then -- if we accept a byte from the source
								-- write the incoming byte (shifted by one since the whole FIFO has shifted)
								CMD_FIFO_TDATA(CMD_FIFO_LEN) <= CMD_IN_DAT_FIFO.TDATA;
								CMD_FIFO_TVALID(CMD_FIFO_LEN) <= CMD_IN_DAT_FIFO.TVALID;
								CMD_FIFO_TLAST(CMD_FIFO_LEN) <= CMD_IN_DAT_FIFO.TLAST;
								-- Increase the FIFO length
								if CMD_FIFO_LEN /= CMD_FIFO_MAX_LENGTH then
									CMD_FIFO_LEN <= CMD_FIFO_LEN-1; -- We write nothing, so the FIFO length is decremented
								else
									assert FALSE report "CTRL_ROUTER command FIFO has overflown"; -- should never happen by design
								end if;
							end if;
						end if;

					when others => -- the simulator complains that we do not handle all cases if we do not put this
						assert FALSE report "bad CMD state";
				end case;
			end if; -- RST
		end if; -- CLK
	end process;




-- Control replies routing
-- Monitors N reply buses, and when one is VALID, send the stream to the output until LAST
rply_proc: process(CLK, RST)
	begin

		if rising_edge(CLK) then

			if RST='1' then
				-- reset buses
				RPLY_OUT_DAT_FIFO_INT.TVALID<='0';
				for i in 0 to NUMBER_OF_PORTS-1 loop
					RPLY_IN_RDY_INT_TREADY(i) <= '1';
				end loop;

				-- initialize state machine
				RPLY_STATE<=RPLY_STATE_SCAN;
				RPLY_PORT<=0;
				RPLY_OVERFLOW.TVALID<='0';
			else

				if RPLY_OUT_RDY_FIFO.TREADY='1' then -- if the bus has read the byte on the bus, clear TVALID. This may be overriden below if a new byte is placed on the bus
					RPLY_OUT_DAT_FIFO_INT.TVALID<='0';
				end if;

				CASE RPLY_STATE IS
					WHEN RPLY_STATE_SCAN => -- If current antenna finished processing, set next state to SEND_CMD and increment antenna number in preparation for the next round

						for i in 0 to NUMBER_OF_PORTS-1 loop
							RPLY_IN_RDY_INT_TREADY(i) <= '0'; -- disable TREADY flag after previous state
						end loop;

						-- find next port ready with a reply
						for i in 0 to NUMBER_OF_PORTS-1 loop
	--						if RPLY_IN_DAT(i).TVALID='1' and RPLY_OUT_RDY_FIFO.TREADY='1' then -- if source and destination are ready
							if RPLY_IN_DAT(i).TVALID='1' then -- if source and destination are ready
									RPLY_IN_RDY_INT_TREADY(i) <= '1';
									RPLY_PORT<=i;
									RPLY_STATE<=RPLY_STATE_SEND;
							end if;
						end loop;

					-- Send data from selected source port to the destination port
					WHEN RPLY_STATE_SEND => --

						RPLY_IN_RDY_INT_TREADY(RPLY_PORT) <= RPLY_OUT_RDY_FIFO.TREADY; -- may be overriden below

						-- Output the data to the destination
						if RPLY_OUT_RDY_FIFO.TREADY='1' or RPLY_OUT_DAT_FIFO_INT.TVALID='0' then -- if the bus is ready to receive a new byte
							if RPLY_IN_DAT(RPLY_PORT).TVALID='1' and RPLY_IN_RDY_INT_TREADY(RPLY_PORT) = '1' then -- if a new source byte is being read
								if RPLY_OVERFLOW.TVALID='1' then -- if there was an overflow byte, use it
									RPLY_OUT_DAT_FIFO_INT<=RPLY_OVERFLOW;
									RPLY_OVERFLOW<=RPLY_IN_DAT(RPLY_PORT);
								else
									RPLY_OUT_DAT_FIFO_INT<=RPLY_IN_DAT(RPLY_PORT);
								end if; -- oveflow
							else
								if RPLY_OVERFLOW.TVALID='1' then -- if there was an overflow byte, use it
									RPLY_OUT_DAT_FIFO_INT<=RPLY_OVERFLOW;
									RPLY_OVERFLOW.TVALID<='0';
								else
									RPLY_OUT_DAT_FIFO_INT.TVALID<='0';
								end if; -- oveflow
							end if;
						else -- if the bus is not accepting new data, process incoming
								-- if the destination is not ready but we already issued it the TREADY (saying we accepted the transfer), then forward the byte in the overflow.
							 -- This happens because the TREADy from the destination is registered and arrives late.
							 -- This is esentially implements a 1 deep FIFO
							if RPLY_IN_DAT(RPLY_PORT).TVALID='1' and RPLY_IN_RDY_INT_TREADY(RPLY_PORT) = '1' then  -- otherwise if one is available from the source , send it
								RPLY_OVERFLOW<=RPLY_IN_DAT(RPLY_PORT);
							end if;
						end if;


						-- wait until the last byte of a packet has been read, then disable the TREADY and go back to scanning
						-- we could move this one cycle earlier to remove latency
						if RPLY_OUT_DAT_FIFO_INT.TVALID='1' and RPLY_OUT_DAT_FIFO_INT.TLAST='1' and RPLY_OUT_RDY_FIFO.TREADY='1' then -- if we read the last byte of the frame
								RPLY_IN_RDY_INT_TREADY(RPLY_PORT) <= '0'; -- stop accepting data because the next state will not process the transfer
								RPLY_STATE<=RPLY_STATE_SCAN;
						end if;
				end case;
			end if; --RST
		end if; -- CLK
	end process;

end Behavioral;

