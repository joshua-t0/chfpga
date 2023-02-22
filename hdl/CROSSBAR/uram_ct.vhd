--! @file
----------------------------------------------------------------------------------
-- Company:  McGill University
-- Engineer: JF CLiche
--
-- Create Date: 2023-02-20 
-- Design Name: chfpga
-- Module Name: uram_ct
-- Project Name: CHORD
-- Target Devices: Zynq Ultrascale+ RfSoC
-- Tool Versions: Vivado 2022.1 +
-- Description: UltraRAM-based corner-turn engine
--
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;
--use IEEE.std_logic_misc.ALL; -- for reduce functions

library UNISIM;
use UNISIM.VComponents.all;

Library xpm;
use xpm.vcomponents.all;


library work;
use work.chFPGA_Package.all;
--use work.ip_package.all; -- Import definition of components used in this module

--
-- Implements a 4x4 UltraRAM matrix that is filled with channelizer data on one axis and is read out on the other axis.
--
-- Each frame contains 8k bins (16k samples / 2), spread into 4 columns. Each column has to store 8k/4 = 2k bins/frame/bank.
-- We have to store 16 frames (to fill a GPU cache line with same-bin data) & 2 banks (one is read while the other is written).
-- Wr therefore need to store 2k * 16 * 2 bins per column.
-- The frames are spread in 4 rows, so we need 2k * 16 *2/4 = 2k*8 bins/cell
-- An URAM can store 4k bins, so each cell of the 4x4 matrix is made of 2k*8/4k = 4 URAMs.
-- Each cell has 64 bit data and 14 bits of address, in both the read and write ports.
-- The total address space is 16 bits wide.
--
--    15:14: cell row number
--    13:12: uram select in cell
--    11:0: address in URAM

-- On the write side, we write data 4 bins at a time, accessing all 4 URAM in a row. The data from one bin is contain in a 8-byte word. The word for each bin is written in a different URAM column. Consecutive frames are written successive rows, looping back to the next line of row 0 every 4 frames. Each URAM cell can store 4 frames, for a total of 16 frames.
-- Address bits are assigned as
--    15:14: frame_ctr(1:0) ( consecutive frames are stored in separate cells so 4 consecutive frames can be accessed simultaneously on the readout side)
--    13: bank
--    12:11: frame_ctr(3:2)
--    10:0: bin_ctr (2k bins)


-- On the read side, we read bins one column at a time, i.e. 4 frames at a time. We select which column based on the desired bin.   
--
entity uram_ct is
	generic (
		SIM: boolean := false
		);
	port (
		s_axis_in_tdata: in std_logic_vector(255 downto 0) := (others=>'0'); -- First byte to transmit is in in most significant byte
		s_axis_in_tvalid: in std_logic := '0';
		s_axis_in_tlast: in std_logic := '0';

		m_axis_out_tdata: out std_logic_vector(255 downto 0);
		m_axis_out_tvalid: out std_logic := '0';
		m_axis_out_tlast: out std_logic := '0';

		clk: in std_logic; 
		rst: in std_logic; -- synchrounous reset


		--init_clk: in std_logic; -- continuous clock

		-- Control and reply streams
		cmd_dat: in axis8_dat_struct := (TDATA=>(others=>'0'), TVALID=>'0', TLAST=>'0');
		cmd_rdy: out axis8_rdy_struct;
		rply_dat: out axis8_dat_struct;
		rply_rdy: in axis8_rdy_struct := (TREADY=>'0');
		ctrl_clk : IN std_logic := '0'; -- control clock
		ctrl_rst : in std_logic := '0'

		--areset: in std_logic --! asynchronous reset
	 );
end uram_ct;

architecture impl of uram_ct is


	signal control_bytes: slv8_array(0 to 3);
	signal status_bytes: slv8_array(0 to 1);



	signal ram_wr_addr, ram_rd_addr: std_logic_vector(13 downto 0);
	signal ram_din: std_logic_vector(255 downto 0);
	signal ram_dout: slv256_array(0 to 3);
	signal ram_wr_en: std_logic_vector(0 to 3);  -- one for each row
	signal ram_rd_en: std_logic_vector(0 to 3);  -- one for each column
	signal wr_bank: std_logic; -- 2 banks
	signal overrun: std_logic;

	signal bsb_ram_dout: std_logic_vector(7 downto 0);
	signal bsb_ram_addr: std_logic_vector(12 downto 0);
	signal bsb_ram_we, bsb_ram_en: std_logic;
	signal bsb_ram_row, bsb_ram_col: std_logic_vector(1 downto 0);
	signal bsb_ram_page: std_logic_vector(3 downto 0);

begin


	bsb_regs0: entity work.CTRL_SLAVE
		GENERIC MAP (
			DEFAULT_CONTROL_BYTES=> X"50_00_0A_FFFF",
			--USE_RAM_DOUT_RDY=>TRUE, -- need to wait for the RDY signal on RAM read accesses
			RAM_DATA_WIDTH => 8,
			RAM_ADDR_WIDTH => 13, -- 8k page, need 8 additional bits to complete the address space of the uRAM array
			NUMBER_OF_CONTROL_BYTES => control_bytes'Length(1), -- Number of bits in the control word
			NUMBER_OF_STATUS_BYTES => status_bytes'Length(1) -- Number of bits in the status word.
		)
		PORT MAP(
			CTRL_CMD_IN_DAT=>   cmd_dat,
			CTRL_CMD_IN_RDY=>   cmd_rdy,
			CTRL_RPLY_OUT_DAT=> rply_dat,
			CTRL_RPLY_OUT_RDY=> rply_rdy,
			CTRL_CLK => ctrl_clk,
			CTRL_RST => ctrl_rst,

			CONTROL_BYTES => control_bytes,
			STATUS_BYTES => status_bytes

			-- RAM interface
			--RAM_DIN      => bsb_ram_in,
			RAM_DOUT     => bsb_ram_out,
			--RAM_DOUT_RDY => bsb_ram_rdy,
			RAM_WR_EN    => bsb_ram_we,
			RAM_EN       => bsb_ram_en,
			RAM_ADDR     => bsb_ram_addr

			-- -- System
			-- RST => areset
		);

	-- CONTROL byte 0
	bsb_ram_row <= control_bytes(0)(7 downto 6);
	bsb_ram_col <= control_bytes(0)(5 downto 4);
	bsb_ram_page <= control_bytes(0)(3 downto 0);


	-- STATUS byte 0
	status_bytes(0)(0) <= overrun;

	uram_row_gen: for row in 0 to 3 generate
		uram_col_gen: for col in 0 to 3 generate
			signal ram_dout_word: std_logic_vector(63 downto 0);
			signal ram_din_word: std_logic_vector(63 downto 0);
		begin
			ram_dout(col)(64*(3-row)+63 downto 64*(3-row)) <= ram_dout_word;
			ram_din_word <= ram_din(64*(3-col)+63 downto 64*(3-col));

		   	-- xpm_memory_sdpram: Simple Dual Port RAM
		   	-- Xilinx Parameterized Macro, version 2022.1
		   	-- UltraRAM primitive is organized as 4K x 72 bits
		   	-- Addr width: we use all the memory space. The uram is 2kx
		   	uram_cell_inst : xpm_memory_sdpram
			   	generic map (
			      MEMORY_PRIMITIVE => "ultra",      -- force the use of UltraRAM
			      ADDR_WIDTH_A => 14,               -- 4k (12 bits) per URAM, +2 because we cascade 4 of them.
			      ADDR_WIDTH_B => 14,               -- same
			      READ_DATA_WIDTH_B => 64,         -- DECIMAL
			      WRITE_DATA_WIDTH_A => 64,        -- 8 byte wide bus
			      BYTE_WRITE_WIDTH_A => 64,        -- Should be same as WRITE_DATA_WIDTH_A if not using byte enables
			      --CASCADE_HEIGHT => 4,             -- We castade 4 URAM
			      --MEMORY_OPTIMIZATION => "true",   -- String
			      MEMORY_SIZE => 64*4096*4,         -- DECIMAL
			      --MESSAGE_CONTROL => 0,            -- DECIMAL
			      READ_LATENCY_B => 5,             -- Needs to be >= of cascade height to allow registering. Synthesis ask for more than 4 to have full pipelining (4 is partial).
			      --READ_RESET_VALUE_B => "0",       -- String
			      --RST_MODE_A => "SYNC",            -- String
			      --RST_MODE_B => "SYNC",            -- String
			      SIM_ASSERT_CHK => 1,             -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
			      --USE_EMBEDDED_CONSTRAINT => 0,    -- DECIMAL
			      --USE_MEM_INIT => 1,               -- DECIMAL
			      --USE_MEM_INIT_MMI => 0,           -- DECIMAL
			      --WAKEUP_TIME => "disable_sleep",  -- String
			      WRITE_MODE_B => "write_first",     -- URAM is either read_first or write_first
			      WRITE_PROTECT => 1               -- DECIMAL
				)
				port map (
					-- Write port
					dina => ram_din_word,
					addra => ram_wr_addr,
					ena => ram_wr_en(row),
					wea(0) => ram_wr_en(row),

					-- read port
					doutb => ram_dout_word,
					addrb => ram_rd_addr,
					enb => ram_rd_en(col),

					-- clock and reset
					clka => clk,
					rstb => rst,

					-- unused signals
					sleep => '0',
					injectsbiterra => '0',
					injectdbiterra => '0',
					regceb => '1',
					clkb => '0'
			   );

		end generate uram_col_gen;
	end generate uram_row_gen;

	-- Write the incoming data to the 4x4 UltraRAM cell array.
	--
	-- Bins form one frame are written in all cells in one row.
	-- Consecutive frames are written in consecutive rows.
	-- Consecutive sets of 16 frames are stored in alternate banks.
	-- One row stores two banks of 4 frames.
	ram_wr_block: block
		signal bin_ctr: unsigned(12 downto 0); -- 8k bins
		signal frame_ctr: unsigned(3 downto 0); -- 16 frames per bank
	begin

		ram_wr_proc: process(clk)
			variable row: integer;
		begin
			if rising_edge(clk) then

				ram_din <= s_axis_in_tdata;
				ram_wr_addr <= wr_bank & std_logic_vector(frame_ctr(3 downto 2)) & std_logic_vector(bin_ctr(12 downto 2)); -- 1 + 2 + 11 = 14 bits
				row := to_integer(frame_ctr(1 downto 0));
				ram_wr_en <= (others => '0'); -- overriden below

				if s_axis_in_tvalid='1' then
					bin_ctr <= bin_ctr + 4; -- we receive bins 4 at a time
					ram_wr_en(row) <= '1'; -- write only when we have valid data
					if s_axis_in_tlast='1' then
						bin_ctr <= (others => '0');
						frame_ctr <= frame_ctr + 1;
						if frame_ctr = 15 then
							wr_bank <= not wr_bank;
						end if;
					end if;
				end if;

				--  Write from BSB overrides incoming stream write
				if bsb_ram_en = '1' and bsb_ram_we = '1' then
					ram_wr_we <= (others => '0');
					row := to_integer(bsb_ram_row);
					ram_wr_we(to_integer(bsb_ram_addr(4 downto 0))) <= '1';
					ram_wr_en(row) <= '1';
					-- add data and addr
				end if;

				if rst='1' then
					frame_ctr <= (others => '0');
					bin_ctr <= (others => '0');
					wr_bank <= '0';
				end if; --rst
			end if; --clk
		end process ram_wr_proc;
	end block ram_wr_block;

	-- Reads data from 4x4 UltraRAM cell array in the specified order.
	--
	-- Bins from one frame are written in all cells in one row.
	-- Consecutive frames are written in consecutive rows.
	-- Consecutive sets of 16 frames are stored in alternate banks.
	-- One row stores two banks of 4 frames.
	ram_rd_block: block
		signal bin_ctr: unsigned(12 downto 0); -- 8k bins
		signal frame_ctr: unsigned(3 downto 0); -- 16 frames
		signal wr_bank_reg, rd_bank: std_logic; -- 2 banks
		signal busy: std_logic;
		signal tvalid_pre, tlast_pre: std_logic;
		signal col_pre: std_logic_vector(1 downto 0);
		signal tvalid_dly, tlast_dly: std_logic_vector(4 downto 0);
		signal col_dly: slv2_array(4 downto 0);
		signal tdata: std_logic_vector(255 downto 0);
		signal tvalid, tlast: std_logic;
	begin
		rd_bank <= not wr_bank;
		ram_rd_proc: process(clk)
		begin
			if rising_edge(clk) then

				-- Generate read address and enable signals
				ram_rd_addr <= rd_bank & std_logic_vector(frame_ctr(3 downto 2)) & std_logic_vector(bin_ctr(12 downto 2));
				--ram_rd_addr(13) <= rd_bank;
				--ram_rd_addr(12 downto 11) <= std_logic_vector(frame_ctr(3 downto 2));
				--ram_rd_addr(10 downto 0) <= std_logic_vector(bin_ctr(12 downto 2));
				--std_logic_vector((0=>rd_bank)) & std_logic_vector(frame_ctr(3 downto 2)) & std_logic_vector(bin_ctr); -- 1 + 2 + 11 = 14 bits
				ram_rd_en <= (others => '0'); -- overriden below
				tvalid_pre <= '0';
				tlast_pre <= '0';
				col_pre <= std_logic_vector(bin_ctr(1 downto 0));
				if busy='1' then
					ram_rd_en(to_integer(bin_ctr(1 downto 0))) <= '1'; -- set read_en only when we are actually using the data to make simulations more clear
					frame_ctr <= frame_ctr + 4; -- we read frames 4 at a time
					tvalid_pre <='1';
					if frame_ctr = 12 then -- last frame, when counting by 4
						bin_ctr <= bin_ctr + 1;
						if bin_ctr(5 downto 0) = 0 then -- skip 10 bins in each 64 bin packet to simulate dropping first 300 MHz of the band (64*300/1500 = 12.8)
							bin_ctr <= bin_ctr + 10;
						end if;
						if signed(bin_ctr(5 downto 0))= -1 then -- 8k bins / 128 NUMA =64 bins/packets, 16 frames*8 bytes/bin/frame * 64 bins/packets = 8kB packet
							tlast_pre <= '1';
						end if;
						if signed(bin_ctr) = -1 then -- don't send the last 10 bins  to allow the transmitter to catch up
							busy <= '0'; -- we're done
						end if;
					end if;
				end if;


				-- Delay tvalid, tlast and col to compensate for the URAM 5-clock latency
				tvalid_dly <= shift_right(tvalid_dly, 1);
				tlast_dly <= shift_right(tlast_dly, 1);
				col_dly(3 downto 0) <= col_dly(4 downto 1);
				col_dly(4) <= col_pre;
				tvalid_dly(4) <= tvalid_pre;
				tlast_dly(4) <= tlast_pre;

				-- capture URAM output when it comes out
				tdata <= ram_dout(to_integer(unsigned(col_dly(0))));
				tvalid <= tvalid_dly(0);
				tlast <= tlast_dly(0);

				-- pipeline final output
				m_axis_out_tdata <= tdata;
				m_axis_out_tvalid <= tvalid;
				m_axis_out_tlast <= tlast;

				-- start a new readout and set the busy flag when the bank changes
				wr_bank_reg <= wr_bank;
				if wr_bank /= wr_bank_reg then
					if busy='1' then
						overrun <= '1';
					end if;
					busy <= '1';
					frame_ctr <= (others => '0');
					bin_ctr <= (others => '0');
				end if;

				if rst='1' then
					frame_ctr <= (others => '0');
					bin_ctr <= (others => '0');
					busy <= '0';
					overrun <= '0';
					tvalid_pre <= '0';
					tvalid_dly <= (others => '0');
					tvalid <= '0';
					m_axis_out_tvalid <= '0';
				end if; --rst
			end if; --clk
		end process ram_rd_proc;
	end block ram_rd_block;




end impl;





