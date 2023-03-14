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
--    15:14: cell row number (4 rows)
--    13:12: uram select in cell (4 URAM/cell)
--    11:0: address in URAM (4kword/uram)

-- On the write side, we write data 4 bins at a time, accessing all 4 URAM in a row. The data from one bin is contain in a 8-byte word. The word for each bin is written in a different URAM column. Consecutive frames are written successive rows, looping back to the next line of row 0 every 4 frames. Each URAM cell can store 4 frames, for a total of 16 frames.
-- Address bits are assigned as
--    15:14: frame_ctr(1:0) ( consecutive frames are stored in separate cells so 4 consecutive frames can be accessed simultaneously on the readout side)
--    13: bank ( 2 banks per cell)
--    12:11: frame_ctr(3:2) ( 4 frames per cell)
--    10:0: bin_ctr (2k bins)
--
-- On the read side, we read bins one column at a time, i.e. 4 frames at a time. We select which column based on the desired bin.   
--
-- The buffer can be written using the BSB interface. This is a 8 bit wide interface. 
-- The logical address space from the BSB point of view is:
-- 
--    20: bank (1 bit = 2 banks) -> from page register
--    19:16: frame (4 bits = 16 frames) => from page register
--    15:3 bin  (13 bits = 2k bins) => from bsb_ram_addr(15:3)
--    2:0: channel (3 bits = 8 channels) => from bsb_ram_addr(2:0)
--
-- 16 bits (bin and channel) are derived from the BSB write address directly. 
-- The remaining address bins (frame and bank) are taken from paging registers. There are 32 pages of 64Kbytes. 
-- Writing one 64K  page might require multiple transactions as to not overflow the command buffers and the Ethernet MTU. 

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


	signal control_bytes: slv8_array(0 to 0);
	signal status_bytes: slv8_array(0 to 2);

    signal cmd_dat_int: axis8_dat_struct;
    signal cmd_rdy_int: axis8_rdy_struct;
    signal rply_dat_int: axis8_dat_struct;
    signal rply_rdy_int: axis8_rdy_struct;

    signal bsb_rst: std_logic := '1';

	signal ram_wr_addr, ram_rd_addr: std_logic_vector(13 downto 0);
	signal ram_din: std_logic_vector(255 downto 0);
	signal ram_dout: slv256_array(3 downto 0); -- one for each column;
	signal ram_wr_row_en: std_logic_vector(3 downto 0);  -- one for each row
	signal ram_wr_byte_en: std_logic_vector(31 downto 0);  -- enable for each of the 32 bytes across the row
	signal ram_rd_col_en: std_logic_vector(3 downto 0);  -- one for each column
	signal wr_bank: std_logic; -- 2 banks
	signal overrun: std_logic;

	signal bsb_ram_din: std_logic_vector(7 downto 0);
	signal bsb_ram_addr: std_logic_vector(15 downto 0);
	signal bsb_ram_we, bsb_ram_en: std_logic;
	signal bsb_ram_bank: std_logic;
	signal bsb_ram_frame: std_logic_vector(3 downto 0);

    signal chan_write_enable: std_logic;
    signal auto_trig: std_logic;
    
    signal play_ram_wr_en: std_logic;
    signal play_ram_wr_byte_en: std_logic_vector(0 downto 0);
    signal play_ram_rd_addr: unsigned(12 downto 0);
    signal play_ram_rd_en: std_logic;
	signal play_ram_dout: std_logic_vector(15 downto 0);
    signal play_ram_sel: std_logic;
    
    signal in_frame_ctr: unsigned(7 downto 0);
    signal out_frame_ctr: unsigned(7 downto 0);
begin


    ----Implement an an asynchronous FIFO to bridge the BSB bus from the ctrl_clk
    ----to the clk domains 
    --bsb_fifo0 : entity work.CMD_ASYNC_FIFO
    --  PORT MAP (
    --        CMD_A_DAT  => cmd_dat,
    --        CMD_A_RDY  => cmd_rdy,
    --        RPLY_A_DAT => rply_dat,
    --        RPLY_A_RDY => rply_rdy,
    --        A_CLK      => ctrl_clk,
    
    --        CMD_B_DAT  => cmd_dat_int,
    --        CMD_B_RDY  => cmd_rdy_int,
    --        RPLY_B_DAT => rply_dat_int,
    --        RPLY_B_RDY => rply_rdy_int,
    --        B_CLK      => clk,
    
    --        RST => bsb_rst -- clock is asynchronous
    --        );

	-- Make sure we capture the ctrl_rst reset of the CTRL_SLAVE
	-- even if the sysmon_clk is not yet active and generate a proper reset when the clock
	-- comes on.
	bsb_reset_inst : xpm_cdc_async_rst
		generic map (
		   RST_ACTIVE_HIGH => 1  -- DECIMAL; 0=active low reset, 1=active high reset
		)
		port map (
		   src_arst => ctrl_rst,   -- Source asynchronous reset signal.
		   dest_arst => bsb_rst, -- 1-bit output: src_arst asynchronous reset signal synchronized to destination
		                           -- clock domain. This output is registered. NOTE: Signal asserts asynchronously
		                           -- but deasserts synchronously to dest_clk. Width of the reset signal is at least
		                           -- (DEST_SYNC_FF*dest_clk) period.

		   dest_clk => clk   -- 1-bit input: Destination clock.
		);

    
	bsb_regs0: entity work.CTRL_SLAVE
		GENERIC MAP (
			DEFAULT_CONTROL_BYTES=> X"00",
			USE_RAM_DOUT_RDY=> FALSE, -- need to wait for the RDY signal on RAM read accesses
			RAM_DATA_WIDTH => 8,
			RAM_ADDR_WIDTH => 16, -- 64k page, 8k bins x 8 channels
			NUMBER_OF_CONTROL_BYTES => control_bytes'Length(1), -- Number of bits in the control word
			NUMBER_OF_STATUS_BYTES => status_bytes'Length(1) -- Number of bits in the status word.
		)
		PORT MAP(
			--CTRL_CMD_IN_DAT=>   cmd_dat_int,
			--CTRL_CMD_IN_RDY=>   cmd_rdy_int,
			--CTRL_RPLY_OUT_DAT=> rply_dat_int,
			--CTRL_RPLY_OUT_RDY=> rply_rdy_int,
			--CTRL_CLK => clk,
			--CTRL_RST => rst,

			CTRL_CMD_IN_DAT=>   cmd_dat,
			CTRL_CMD_IN_RDY=>   cmd_rdy,
			CTRL_RPLY_OUT_DAT=> rply_dat,
			CTRL_RPLY_OUT_RDY=> rply_rdy,
			CTRL_CLK => ctrl_clk,
			CTRL_RST => ctrl_rst,

			CONTROL_BYTES => control_bytes,
			STATUS_BYTES => status_bytes,

			-- RAM interface
			RAM_DIN      => bsb_ram_din,
			RAM_DOUT     => (others => '0'),
			--RAM_DOUT_RDY => bsb_ram_rdy,
			RAM_WR_EN    => bsb_ram_we,
			RAM_EN       => bsb_ram_en,
			RAM_ADDR     => bsb_ram_addr

			-- -- System
			-- RST => areset
		);


	-- CONTROL byte 0
	chan_write_enable <= control_bytes(0)(7);
	auto_trig <= control_bytes(0)(6);

	play_ram_sel <= control_bytes(0)(5);
	bsb_ram_bank <= control_bytes(0)(4);
	bsb_ram_frame <= control_bytes(0)(3 downto 0);


	-- STATUS byte 0
	status_bytes(0)(0) <= overrun;

	-- STATUS byte 1
	status_bytes(1) <= std_logic_vector(in_frame_ctr);
	-- STATUS byte 2
	status_bytes(2) <= std_logic_vector(out_frame_ctr);

	uram_row_gen: for row in 3 downto 0 generate
		uram_col_gen: for col in 3 downto 0 generate
			signal ram_dout_word: std_logic_vector(63 downto 0);
			signal ram_din_word: std_logic_vector(63 downto 0);
			signal ram_wr_byte_en_word: std_logic_vector(7 downto 0);
		begin
			ram_dout(col)(64*row + 63 downto 64*row) <= ram_dout_word;
			ram_din_word <= ram_din(64*col + 63 downto 64*col);
			ram_wr_byte_en_word <= ram_wr_byte_en(8*col+7 downto 8*col);
		   	-- xpm_memory_sdpram: Simple Dual Port RAM
		   	-- Xilinx Parameterized Macro, version 2022.1
		   	-- UltraRAM primitive is organized as 4K x 72 bits
		   	-- Addr width: we use all the memory space. The uram is 2kx
		   	uram_cell_inst : xpm_memory_sdpram
			   	generic map (
			      MEMORY_PRIMITIVE => "ultra",      -- force the use of UltraRAM
                    -- write bus A
			      ADDR_WIDTH_A => 14,               -- 4k (12 bits) per URAM, +2 because we cascade 4 of them.
			      WRITE_DATA_WIDTH_A => 64,        -- 8 byte (64 bits) wide write bus
			      BYTE_WRITE_WIDTH_A => 8,          -- We use 8-bit-wide-byte-enabled write, i.e. we have 8 byte enable bits
                    -- Read bus B
			      ADDR_WIDTH_B => 14,               -- same
			      READ_DATA_WIDTH_B => 64,         -- 8 byte (64 bits) wide read bus
			      --CASCADE_HEIGHT => 4,             -- We castade 4 URAM
			      --MEMORY_OPTIMIZATION => "true",   -- String
			      MEMORY_SIZE => 64*4096*4,         -- 64-bit word * 4096 words/URAM * 4 URAMs
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
					ena => ram_wr_row_en(row),
					wea => ram_wr_byte_en_word,

					-- read port
					doutb => ram_dout_word,
					addrb => ram_rd_addr,
					enb => ram_rd_col_en(col),

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
		signal bin_ctr: unsigned(10 downto 0); -- 8k/4 = 2k bins -- we recive and count 4 bins at a time
		signal frame_ctr: unsigned(3 downto 0); -- 16 frames per bank
--		signal bin_frame_ctr: unsigned(14 downto 0); -- 8k bins/4 * 16 frames
	begin

		ram_wr_proc: process(clk)
			variable row, byte: integer;
			variable bank: std_logic; -- 2 banks
			variable frame: std_logic_vector(3 downto 0);-- 16 frames
			variable bin: std_logic_vector(10 downto 0); --8k/4 = 2k bins
			variable wr_en: std_logic;
		begin
			if rising_edge(clk) then

				wr_en := '0'; -- overriden below
				bin := std_logic_vector(bin_ctr);
				frame := std_logic_vector(frame_ctr);
				bank := wr_bank;				

				-- Always set byte enables and din by default to make sure we don't infer unnecessary enables 
				ram_wr_byte_en <= (others => '1'); -- we write all 32 bytes (4 columns) by default
				ram_din <= s_axis_in_tdata;
				if s_axis_in_tvalid='1' then
					in_frame_ctr <= in_frame_ctr + 1;

					bin_ctr <= bin_ctr + 1; -- we receive bins 4 at a time
					wr_en := chan_write_enable;
					if s_axis_in_tlast='1' then
						bin_ctr <= (others => '0');
						frame_ctr <= frame_ctr + 1;
						if frame_ctr = 15 then
							wr_bank <= not wr_bank;
						end if;
					end if;
				end if;

				--  Write from BSB overrides incoming stream write
				if bsb_ram_en = '1' and bsb_ram_we = '1' and play_ram_sel='0' then
					byte := to_integer(unsigned(not bsb_ram_addr(4 downto 0))); -- 8 channels * 4 cols = 32 bytes, addr 0 = byte 31
					bin := bsb_ram_addr(15 downto 5);
					frame := bsb_ram_frame;
					bank := bsb_ram_bank;

					wr_en := '1';
					ram_wr_byte_en <= (others => '0');
					ram_wr_byte_en(byte) <= '1'; 

					for i in 0 to 31 loop
						ram_din(8*i+7 downto 8*i) <= bsb_ram_din;
					end loop;
				end if;

				-- generate address and row enable
				ram_wr_addr <= bank & frame(3 downto 2) & bin; -- 1 + 2 + 11 = 14 bits, 16 kwords = 128 kB/cell = 4x32 kB 
				row := to_integer(unsigned(not frame(1 downto 0)));
				ram_wr_row_en <= (others => '0'); -- overriden below
				ram_wr_row_en(row) <= wr_en;

				if rst='1' then
					--bin_frame_ctr <= (others => '0');
					frame_ctr <= (others => '0');
					bin_ctr <= (others => '0');
					wr_bank <= '0';
					in_frame_ctr <= (others => '0');
				end if; --rst
			end if; --clk
		end process ram_wr_proc;
	end block ram_wr_block;

    play_ram0 : xpm_memory_sdpram
        generic map (
          MEMORY_PRIMITIVE => "auto",      -- force the use of UltraRAM
            -- write bus A
          ADDR_WIDTH_A => 14,               -- 4k (12 bits) per URAM, +2 because we cascade 4 of them.
          WRITE_DATA_WIDTH_A => 8,        -- 8 byte (64 bits) wide write bus
          BYTE_WRITE_WIDTH_A => 8,          -- We use 8-bit-wide-byte-enabled write, i.e. we have 8 byte enable bits
            -- Read bus B
          ADDR_WIDTH_B => 13,               -- same
          READ_DATA_WIDTH_B => 16,         -- 8 byte (64 bits) wide read bus
          --CASCADE_HEIGHT => 4,             -- We castade 4 URAM
          --MEMORY_OPTIMIZATION => "true",   -- String
          MEMORY_SIZE => 16*8192,         -- 64-bit word * 4096 words/URAM * 4 URAMs
          --MESSAGE_CONTROL => 0,            -- DECIMAL
          READ_LATENCY_B => 1,             -- Needs to be >= of cascade height to allow registering. Synthesis ask for more than 4 to have full pipelining (4 is partial).
          --READ_RESET_VALUE_B => "0",       -- String
          --RST_MODE_A => "SYNC",            -- String
          --RST_MODE_B => "SYNC",            -- String
          SIM_ASSERT_CHK => 1,             -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
          --USE_EMBEDDED_CONSTRAINT => 0,    -- DECIMAL
          --USE_MEM_INIT => 1,               -- DECIMAL
          --USE_MEM_INIT_MMI => 0,           -- DECIMAL
          --WAKEUP_TIME => "disable_sleep",  -- String
          WRITE_MODE_B => "read_first",     -- has to be read_first for assymetrical data ports, otherwise raises error on synthesis
          WRITE_PROTECT => 1               -- DECIMAL
        )
        port map (
            -- Write port
            dina => bsb_ram_din,
            addra => bsb_ram_addr(13 downto 0),
            ena => play_ram_wr_en ,
            wea => play_ram_wr_byte_en,

            -- read port
            doutb(7 downto 0) => play_ram_dout(15 downto 8), -- Byte written at low address on din appears in LSB in dout
            doutb(15 downto 8) => play_ram_dout(7 downto 0),
            addrb => std_logic_vector(play_ram_rd_addr),
            enb => play_ram_rd_en,

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

    play_ram_wr_en <= bsb_ram_en and play_ram_sel;
    play_ram_wr_byte_en <= (0 => bsb_ram_we);
    -- Reads data from 4x4 UltraRAM cell array in the specified order.
	--
	-- Bins from one frame are written in all cells in one row.
	-- Consecutive frames are written in consecutive rows.
	-- Consecutive sets of 16 frames are stored in alternate banks.
	-- One row stores two banks of 4 frames.
	ram_rd_block: block
		signal bin_ctr: unsigned(12 downto 0); -- 8k bins
		signal frame_ctr: unsigned(1 downto 0); -- 16/4 = 4 frames (we read frames 4 at a time)
		signal wr_bank_reg, rd_bank: std_logic; -- 2 banks
		signal busy: std_logic;
		signal tvalid_pre, tlast_pre: std_logic;
		signal col_pre: std_logic_vector(1 downto 0);
		signal tvalid_dly, tlast_dly: std_logic_vector(4 downto 0);
		signal col_dly: slv2_array(4 downto 0);
		signal tdata: std_logic_vector(255 downto 0);
		signal tvalid, tlast: std_logic;
		signal play_ram_rd_rdy: std_logic;


	begin
		rd_bank <= not wr_bank;
		play_ram_rd_en <= busy;
	
		ram_rd_proc: process(clk)
		  variable frame: std_logic_vector(1 downto 0);
		  variable bin: std_logic_vector(12 downto 0);
		  variable col: std_logic_vector(1 downto 0);
		  variable col_int: integer;

        variable last_frame: unsigned(1 downto 0);
        variable end_of_packet: std_logic;
        variable end_of_transmission: std_logic;
              
		begin
			if rising_edge(clk) then

                play_ram_rd_rdy <= busy;
				-- Generate read address and enable signals
				frame := std_logic_vector(frame_ctr);
--				bin := std_logic_vector(bin_ctr(5 downto 0)) & std_logic_vector(bin_ctr(12 downto 6)); -- we swap the bin bits to interleave every 128 bins
				bin := play_ram_dout(12 downto 0);
                if play_ram_dout(13)='1' then
                    last_frame := "11"; -- 4 frames (0 to 3) => 128 bytes
                else
                    last_frame := "01"; -- 2 frames (0 to 1) => 64 bytes - use for headers
                end if;
                end_of_packet := play_ram_dout(14);
                end_of_transmission := play_ram_dout(15);

				ram_rd_addr <= rd_bank & frame & bin(12 downto 2); 
				col := not bin(1 downto 0);  -- first column in col 3
				col_int := to_integer(unsigned(col));
				ram_rd_col_en <= (others => '0'); -- overriden below
				ram_rd_col_en(col_int) <= '1'; -- set read_en only when we are actually using the data to make simulations more clear
				--ram_rd_addr(13) <= rd_bank;
				--ram_rd_addr(12 downto 11) <= std_logic_vector(frame_ctr(3 downto 2));
				--ram_rd_addr(10 downto 0) <= std_logic_vector(bin_ctr(12 downto 2));
				--std_logic_vector((0=>rd_bank)) & std_logic_vector(frame_ctr(3 downto 2)) & std_logic_vector(bin_ctr); -- 1 + 2 + 11 = 14 bits
				tvalid_pre <= '0';
				tlast_pre <= '0';
				col_pre <= col;
				if play_ram_rd_rdy='1' then
					frame_ctr <= frame_ctr + 1; -- we read frames 4 at a time
					tvalid_pre <='1';
--					if signed(frame_ctr) = -1 then -- last frame
					if frame_ctr = last_frame then -- last frame
                        frame_ctr <= (others =>'0');
                        play_ram_rd_addr <= play_ram_rd_addr + 1;
--						bin_ctr <= bin_ctr + 1;
--						if bin_ctr(5 downto 0) = 0 then -- skip 10 bins in each 64 bin packet to simulate dropping first 300 MHz of the band (64*300/1500 = 12.8)
--							bin_ctr <= bin_ctr + 10;
--						end if;
--						if signed(bin_ctr(5 downto 0))= -1 then -- 8k bins / 128 NUMA =64 bins/packets, 16 frames*8 bytes/bin/frame * 64 bins/packets = 8kB packet
						if end_of_packet='1' then -- 8k bins / 128 NUMA =64 bins/packets, 16 frames*8 bytes/bin/frame * 64 bins/packets = 8kB packet
							tlast_pre <= '1';
						end if;
--						if signed(bin_ctr) = -1 then -- don't send the last 10 bins  to allow the transmitter to catch up
						if end_of_transmission = '1' then -- don't send the last 10 bins  to allow the transmitter to catch up
							play_ram_rd_rdy <= '0'; -- we're done
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

				if tvalid = '1' then
					out_frame_ctr <= out_frame_ctr + 1;
				end if;

				-- start a new readout and set the busy flag when the bank changes
				wr_bank_reg <= wr_bank;
				if wr_bank /= wr_bank_reg or (busy='0' and auto_trig='1') then
					if busy='1' then
						overrun <= '1';
					end if;
					busy <= '1';
					frame_ctr <= (others => '0');
					bin_ctr <= (others => '0');
					play_ram_rd_addr <= (others => '0');
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
					play_ram_rd_rdy <= '0';
					play_ram_rd_addr <= (others => '0');
					wr_bank_reg <= '0';
					out_frame_ctr <= (others => '0');
				end if; --rst
			end if; --clk
		end process ram_rd_proc;
	end block ram_rd_block;




end impl;





