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
-- use IEEE.std_logic_misc.ALL; -- for reduce functions

library UNISIM;
use UNISIM.VComponents.ALL;

library xpm;
use xpm.vcomponents.ALL;


library work;
use work.chFPGA_Package.ALL;
-- use work.ip_package.all; -- Import definition of components used in this module

--
-- Implements a 4x4 UltraRAM matrix that is filled with channelizer data on one axis and is read out on the other axis.
--
-- Each frame contains 8k bins (16k samples / 2), spread into 4 columns. Each column has to store 8k/4 = 2k bins/frame/bank.
-- We have to store 16 frames (to fill a 128-byte GPU cache line with same-bin data, i.e. 8 samples * 16 frames= 128 bytes) & 2 banks (one is read while the other is written).
-- We therefore need to store 2k bins/col * 16 frames * 2 banks = 64k bins per column. Each bin is one address x 8 byte wide, we have 64K addresses, 4K per URAM, 16 URAM total/col.
-- The frames are spread in 4 rows (so we can read 4x8 =32 bytes in parallel), so we need 2k bins * 16 frames *2 banks/4 cells/col = 2k*8=16k bins/cell (14 bit address/cell)
-- An URAM can store 4k bins, so each cell of the 4x4 matrix is made of 2k*8/4k = 4 URAMs.
-- Each cell has 64 bit data (8 bytes) and 14 bits of address, in both the read and write ports.
-- The total write address space is 16 bits wide. This address selects the row; we write all 4 columns at the same time.
--
--    15:14: cell row number (4 rows)
--    13:12: uram select in cell (4 URAM/cell)
--    11:0: address in URAM (4kword/uram)
--
-- On the write side, we write data 4 bins at a time, accessing all 4 URAM in a row. The data from
-- one bin is contain in a 8-byte word. The word for each bin is written in a different URAM column.
-- Consecutive frames are written successive rows, looping back to the next line of row 0 every 4
-- frames. Each URAM cell can store 4 frames, for a total of 16 frames. Address bits are assigned as
--
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
		s_axis_in_tdata: in std_logic_vector(255 downto 0) := (others => '0'); -- First byte to transmit is in in most significant byte
		s_axis_in_tvalid: in std_logic                     := '0';
		s_axis_in_tlast: in std_logic                      := '0';

		m_axis_out_tdata: out std_logic_vector(255 downto 0);
		m_axis_out_tvalid: out std_logic := '0';
		m_axis_out_tlast: out std_logic  := '0';

		clk: in std_logic;
		rst: in std_logic; -- synchrounous reset


		debug_out: out slv32;

		-- init_clk: in std_logic; -- continuous clock

		-- Control and reply streams
		cmd_dat: in axis8_dat_struct  := (TDATA=> (others => '0'), TVALID=> '0', TLAST=> '0');
		cmd_rdy: out axis8_rdy_struct;
		rply_dat: out axis8_dat_struct;
		rply_rdy: in axis8_rdy_struct := (TREADY=> '0');
		ctrl_clk: in std_logic        := '0'; -- control clock
		ctrl_rst: in std_logic        := '0'

	-- areset: in std_logic --! asynchronous reset
	);
end entity uram_ct;

architecture impl of uram_ct is

	signal control_bytes: slv8_array(0 to 7);
	signal status_bytes: slv8_array(0 to 2);

	signal cmd_dat_int: axis8_dat_struct;
	signal cmd_rdy_int: axis8_rdy_struct;
	signal rply_dat_int: axis8_dat_struct;
	signal rply_rdy_int: axis8_rdy_struct;
	signal ctrl_rst_int: std_logic;

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

	signal rx_write_enable: std_logic;
	signal rx_mask_low_bins: std_logic;
	signal tx_trig_sel: std_logic;
	signal tx_period: unsigned(31 downto 0);
	signal tx_length: unsigned(7 downto 0);
	signal tx_enable: std_logic;
	signal tx_reset: std_logic;
	signal play_ram_wr_en: std_logic;
	signal play_ram_wr_byte_en: std_logic_vector(0 downto 0);
	signal play_ram_rd_addr: unsigned(12 downto 0);
	signal play_ram_rd_en: std_logic;
	signal play_ram_dout: std_logic_vector(15 downto 0);
	signal bsb_ram_sel: std_logic;

	signal in_frame_ctr: unsigned(7 downto 0);
	signal out_frame_ctr: unsigned(7 downto 0);
	signal cmd_rdy_out: axis8_rdy_struct;
	signal rply_dat_out: axis8_dat_struct;
	signal tx_override_data: std_logic;
	signal tx_toggle_bank: std_logic;
	signal tx_insert_timestamp: std_logic;
	signal timestamp_incr: unsigned(4 downto 0);

begin

	cmd_rdy  <= cmd_rdy_out;
	rply_dat <= rply_dat_out;


	-- Implement an an asynchronous FIFO to bridge the BSB bus from the ctrl_clk
	-- to the clk domains (RAM accesses must be made in the clk domain)
	bsb_fifo0: entity work.CMD_ASYNC_FIFO
		port map (
			cmd_a_dat  => cmd_dat,
			cmd_a_rdy  => cmd_rdy_out,
			rply_a_dat => rply_dat_out,
			rply_a_rdy => rply_rdy,
			a_clk      => ctrl_clk,

			cmd_b_dat  => cmd_dat_int,
			cmd_b_rdy  => cmd_rdy_int,
			rply_b_dat => rply_dat_int,
			rply_b_rdy => rply_rdy_int,
			b_clk      => clk,

			rst       => ctrl_rst, -- reset is asynchronous and will be extended until a few clocks have happened on both clocks
			b_rst_out => ctrl_rst_int  -- ctrl_reset, resynchronized to the B_CLK
		);

	bsb_regs0: entity work.CTRL_SLAVE
		generic map (
			DEFAULT_CONTROL_BYTES   => X"00_66_00010000_FF_10",
			USE_RAM_DOUT_RDY        => FALSE, -- need to wait for the RDY signal on RAM read accesses
			RAM_DATA_WIDTH          => 8,
			RAM_ADDR_WIDTH          => 16, -- 16 bits : 64k page, 8k bins x 8 channels
			NUMBER_OF_CONTROL_BYTES => control_bytes'Length(1), -- Number of bits in the control word
			NUMBER_OF_STATUS_BYTES  => status_bytes'Length(1) -- Number of bits in the status word.
		)
		port map (
			ctrl_cmd_in_dat   => cmd_dat_int,
			ctrl_cmd_in_rdy   => cmd_rdy_int,
			ctrl_rply_out_dat => rply_dat_int,
			ctrl_rply_out_rdy => rply_rdy_int,
			ctrl_clk          => clk,
			ctrl_rst          => ctrl_rst_int,

			control_bytes => control_bytes,
			status_bytes  => status_bytes,

			-- RAM interface
			ram_din  => bsb_ram_din,
			ram_dout => (others => '0'),
			-- RAM_DOUT_RDY => bsb_ram_rdy,
			ram_wr_en => bsb_ram_we,
			ram_en    => bsb_ram_en,
			ram_addr  => bsb_ram_addr

		-- -- System
		-- RST => areset
		);


	-- CONTROL byte 0

	bsb_ram_sel   <= control_bytes(0)(5); -- write data target:  0: data buffer, 1: playlist buffer
	bsb_ram_bank  <= control_bytes(0)(4);
	bsb_ram_frame <= control_bytes(0)(3 downto 0);

	-- CONTROL byte 1
	rx_write_enable      <= control_bytes(1)(7); -- When '1', incoming data is written to the data buffer.
	tx_trig_sel          <= control_bytes(1)(6); -- 0: Data transmission starts when an incoming frame set is completed; 1: data transmission starts every `TX_PERIOD` clocks.
	tx_enable            <= control_bytes(1)(5); -- '1' to enable data transmission. '0' data transmission is muted.
	tx_reset             <= control_bytes(1)(4); -- '1' resets the data transmitter
	tx_toggle_bank       <= control_bytes(1)(3);
	tx_insert_timestamp  <= control_bytes(1)(2);
	rx_mask_low_bins     <= control_bytes(1)(1);
	tx_override_data     <= control_bytes(1)(0);
	-- CONTROL byte 2-5
	tx_period <= to_unsigned(control_bytes(2 to 5));

	-- CONTROL byte 6
	tx_length <= unsigned(control_bytes(6));


	timestamp_incr <= unsigned(control_bytes(7)(4 downto 0));

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
			ram_dout(col)(64 * row + 63 downto 64 * row) <= ram_dout_word;
			ram_din_word                                 <= ram_din(64 * col + 63 downto 64 * col);
			ram_wr_byte_en_word                          <= ram_wr_byte_en(8 * col + 7 downto 8 * col);
			-- xpm_memory_sdpram: Simple Dual Port RAM
			-- Xilinx Parameterized Macro, version 2022.1
			-- UltraRAM primitive is organized as 4K x 72 bits
			-- Addr width: we use all the memory space. The uram is 2kx
			uram_cell_inst: xpm_memory_sdpram
				generic map (
					MEMORY_PRIMITIVE => "ultra",      -- force the use of UltraRAM
					-- write bus A
					ADDR_WIDTH_A       => 14,               -- 4k (12 bits) per URAM, +2 because we cascade 4 of them.
					WRITE_DATA_WIDTH_A => 64,        -- 8 byte (64 bits) wide write bus
					BYTE_WRITE_WIDTH_A => 8,          -- We use 8-bit-wide-byte-enabled write, i.e. we have 8 byte enable bits
					-- Read bus B
					ADDR_WIDTH_B      => 14,               -- same
					READ_DATA_WIDTH_B => 64,         -- 8 byte (64 bits) wide read bus
					-- CASCADE_HEIGHT => 4,             -- We castade 4 URAM
					-- MEMORY_OPTIMIZATION => "true",   -- String
					MEMORY_SIZE => 64 * 4096 * 4,         -- 64-bit word * 4096 words/URAM * 4 URAMs
					-- MESSAGE_CONTROL => 0,            -- DECIMAL
					READ_LATENCY_B => 5,             -- Needs to be >= of cascade height to allow registering. Synthesis ask for more than 4 to have full pipelining (4 is partial).
					-- READ_RESET_VALUE_B => "0",       -- String
					-- RST_MODE_A => "SYNC",            -- String
					-- RST_MODE_B => "SYNC",            -- String
					SIM_ASSERT_CHK => 1,             -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
					-- USE_EMBEDDED_CONSTRAINT => 0,    -- DECIMAL
					-- USE_MEM_INIT => 1,               -- DECIMAL
					-- USE_MEM_INIT_MMI => 0,           -- DECIMAL
					-- WAKEUP_TIME => "disable_sleep",  -- String
					WRITE_MODE_B  => "write_first",     -- URAM is either read_first or write_first
					WRITE_PROTECT => 1               -- DECIMAL
				)
				port map (
					-- Write port
					dina  => ram_din_word,
					addra => ram_wr_addr,
					ena   => ram_wr_row_en(row),
					wea   => ram_wr_byte_en_word,

					-- read port
					doutb => ram_dout_word,
					addrb => ram_rd_addr,
					enb   => ram_rd_col_en(col),

					-- clock and reset
					clka => clk,
					rstb => rst,

					-- unused signals
					sleep          => '0',
					injectsbiterra => '0',
					injectdbiterra => '0',
					regceb         => '1',
					clkb           => '0'
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
	--    signal bin_frame_ctr: unsigned(14 downto 0); -- 8k bins/4 * 16 frames
	begin

		ram_wr_proc: process(clk)

			variable row, byte: integer;
			variable bank: std_logic;                     -- 2 banks
			variable frame: std_logic_vector(3 downto 0); -- 16 frames
			variable bin: std_logic_vector(10 downto 0);  -- 8k/4 = 2k bins
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
				if s_axis_in_tvalid = '1' then
					in_frame_ctr <= in_frame_ctr + 1;

					bin_ctr <= bin_ctr + 1; -- we receive bins 4 at a time
					-- Write data unless we rx_mask_low_bins=1 and we are receiving bins 0-127
					if not(rx_mask_low_bins = '1' and bin_ctr(10 downto 5) = 0) then  -- 128 bins / (4 bins/count) = 32 counts = last 5 bits
						wr_en := rx_write_enable;
					end if;
					if s_axis_in_tlast = '1' then
						bin_ctr <= (others => '0');
						frame_ctr <= frame_ctr + 1;
						if frame_ctr = 15 then
							wr_bank <= not wr_bank;
						end if;
					end if;
				end if;

				--  Write from BSB overrides incoming stream write
				if bsb_ram_en = '1' and bsb_ram_we = '1' and bsb_ram_sel = '0' then
					byte := to_integer(unsigned(not bsb_ram_addr(4 downto 0))); -- 8 channels * 4 cols = 32 bytes, addr 0 = byte 31
					bin := bsb_ram_addr(15 downto 5);
					frame := bsb_ram_frame;
					bank := bsb_ram_bank;

					wr_en := '1';
					ram_wr_byte_en <= (others => '0');
					ram_wr_byte_en(byte) <= '1';

					for i in 0 to 31 loop
						ram_din(8 * i + 7 downto 8 * i) <= bsb_ram_din;
					end loop;

				end if;

				-- generate address and row enable
				ram_wr_addr <= bank & frame(3 downto 2) & bin; -- 1 + 2 + 11 = 14 bits, 16 kwords = 128 kB/cell = 4x32 kB
				row := to_integer(unsigned(not frame(1 downto 0)));
				ram_wr_row_en <= (others => '0'); -- overriden below
				ram_wr_row_en(row) <= wr_en;

				if rst = '1' then
					-- bin_frame_ctr <= (others => '0');
					frame_ctr <= (others => '0');
					bin_ctr <= (others => '0');
					wr_bank <= '0';
					in_frame_ctr <= (others => '0');
				end if; -- rst
			end if; -- clk
		end process ram_wr_proc;

	end block ram_wr_block;

	play_ram0: xpm_memory_sdpram
		generic map (
			MEMORY_PRIMITIVE => "auto",      -- force the use of UltraRAM
			-- write bus A
			ADDR_WIDTH_A       => 14,               -- 4k (12 bits) per URAM, +2 because we cascade 4 of them.
			WRITE_DATA_WIDTH_A => 8,        -- 8 byte (64 bits) wide write bus
			BYTE_WRITE_WIDTH_A => 8,          -- We use 8-bit-wide-byte-enabled write, i.e. we have 8 byte enable bits
			-- Read bus B
			ADDR_WIDTH_B      => 13,               -- same
			READ_DATA_WIDTH_B => 16,         -- 8 byte (64 bits) wide read bus
			-- CASCADE_HEIGHT => 0,             -- Auto detect
			-- MEMORY_OPTIMIZATION => "true",   -- String
			MEMORY_SIZE => 16 * 8192,         -- 64-bit word * 4096 words/URAM * 4 URAMs
			-- MESSAGE_CONTROL => 0,            -- DECIMAL
			READ_LATENCY_B => 1,             -- Needs to be >= of cascade height to allow registering.
			-- READ_RESET_VALUE_B => "0",       -- String
			-- RST_MODE_A => "SYNC",            -- String
			-- RST_MODE_B => "SYNC",            -- String
			SIM_ASSERT_CHK => 1,             -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
			-- USE_EMBEDDED_CONSTRAINT => 0,    -- DECIMAL
			-- USE_MEM_INIT => 1,               -- DECIMAL
			-- USE_MEM_INIT_MMI => 0,           -- DECIMAL
			-- WAKEUP_TIME => "disable_sleep",  -- String
			WRITE_MODE_B  => "read_first",     -- has to be read_first for assymetrical data ports, otherwise raises error on synthesis
			WRITE_PROTECT => 1               -- DECIMAL
		)
		port map (
			-- Write port
			dina  => bsb_ram_din,
			addra => bsb_ram_addr(13 downto 0),
			ena   => play_ram_wr_en,
			wea   => play_ram_wr_byte_en,

			-- read port
			doutb(7 downto 0)  => play_ram_dout(15 downto 8), -- Byte written at low address on din appears in LSB in dout
			doutb(15 downto 8) => play_ram_dout(7 downto 0),
			addrb              => std_logic_vector(play_ram_rd_addr),
			enb                => play_ram_rd_en,

			-- clock and reset
			clka => clk,
			rstb => rst,

			-- unused signals
			sleep          => '0',
			injectsbiterra => '0',
			injectdbiterra => '0',
			regceb         => '1',
			clkb           => '0'
		);

	play_ram_wr_en      <= bsb_ram_en and bsb_ram_sel;
	play_ram_wr_byte_en <= (0 => bsb_ram_we);

	-- Reads data from 4x4 UltraRAM cell array in the specified order.
	--
	-- Bins from one frame are written in all cells in one row.
	-- Consecutive frames are written in consecutive rows.
	-- Consecutive sets of 16 frames are stored in alternate banks.
	-- One row stores two banks of 4 frames.
	ram_rd_block: block
		-- signal bin_ctr: unsigned(12 downto 0); -- 8k bins
		signal framegroup_ctr: unsigned(1 downto 0); -- 16/4 = 4 frames (we read frames 4 at a time)
		signal wr_bank_reg, rd_bank: std_logic; -- 2 banks
		signal busy: std_logic;
		-- signal tvalid_pre, tlast_pre: std_logic;
		-- signal col_pre: std_logic_vector(1 downto 0);
		signal tvalid, tlast: std_logic_vector(5 downto 0);
		signal col: slv2_array(5 downto 0);
		signal insert_ts: std_logic_vector(5 downto 0);
		signal eot: std_logic_vector(5 downto 0);
		signal tdata_reg: std_logic_vector(255 downto 0);
		signal tvalid_reg, tlast_reg: std_logic;
		signal play_ram_rd_rdy: std_logic;
		signal word_ctr: unsigned(31 downto 0);
		signal timestamp: unsigned(63 downto 0);
		signal first_bin: std_logic;
	begin
		rd_bank        <= (not wr_bank) and tx_toggle_bank;
		play_ram_rd_en <= busy;


		debug_out(0)          <= busy;
		debug_out(1)          <= play_ram_rd_rdy;
		debug_out(3 downto 2) <= std_logic_vector(framegroup_ctr);
		debug_out(4)          <= rd_bank;
		debug_out(5)          <= play_ram_rd_en;
		-- debug_out(7 downto 6) <= col_pre;
		-- debug_out(5) <= rply_rdy.TREADY;
		-- debug_out(6) <=  cmd_dat_int.TVALID;
		-- debug_out(7) <=  cmd_dat_int.TLAST;
		-- debug_out(8) <= cmd_rdy_int.TREADY;
		-- debug_out(9) <= rply_dat_int.TVALID;
		-- debug_out(10) <= rply_dat_int.TLAST;
		-- debug_out(11) <= rply_rdy_int.TREADY;

		-- debug_out(12) <=  ctrl_rst;
		-- debug_out(13) <= rst;
		-- debug_out(14) <= '0'; --bsb_rst;
		-- debug_out(15) <= '0';
		debug_out(15 downto 8)  <= std_logic_vector(play_ram_rd_addr(7 downto 0));
		debug_out(31 downto 16) <= play_ram_dout;


		ram_rd_proc: process(clk)

			-- variable frame: std_logic_vector(1 downto 0);
			variable bin: std_logic_vector(12 downto 0);
			variable col_var: std_logic_vector(1 downto 0);
			variable col_int: integer;

			variable last_framegroup: unsigned(1 downto 0);
			variable end_of_packet: std_logic;
			variable end_of_transmission: std_logic;

		begin -- process
			if rising_edge(clk) then
				-- Generate read address and enable signals
				bin := play_ram_dout(12 downto 0);
				-- Number of framegroups to read. 0=2 framegroups (64 bytes), 1=4 framegroups (128 bytes)
				last_framegroup := "11" when play_ram_dout(13) else "01";
				end_of_packet := play_ram_dout(14);
				end_of_transmission := play_ram_dout(15);

				ram_rd_addr <= rd_bank & std_logic_vector(framegroup_ctr) & bin(12 downto 2);
				col_var := not bin(1 downto 0);  -- first column in col 3
				col_int := to_integer(unsigned(col_var));
				ram_rd_col_en <= (others => '0'); -- one bit overriden below
				ram_rd_col_en(col_int) <= '1'; -- set read_en only when we are actually using the data to make simulations more clear
				-- ram_rd_addr(13) <= rd_bank;
				-- ram_rd_addr(12 downto 11) <= std_logic_vector(framegroup_ctr(3 downto 2));
				-- ram_rd_addr(10 downto 0) <= std_logic_vector(bin_ctr(12 downto 2));
				-- std_logic_vector((0=>rd_bank)) & std_logic_vector(framegroup_ctr(3 downto 2)) & std_logic_vector(bin_ctr); -- 1 + 2 + 11 = 14 bits

				-- Delay various signals to compensate for the URAM 5-clock latency

				tvalid <= shift_right(tvalid, 1); -- shift in a '0', overriden below
				tlast <= shift_right(tlast, 1); -- shift in a '0', overriden below
				insert_ts <= shift_right(insert_ts, 1); -- shift in a '0', overriden below
				eot <= shift_right(eot, 1); -- shift in a '0', overriden below
				col <= shift_right(col); -- shift in overriden below
				col(col'LEFT) <= col_var;

				word_ctr <= word_ctr + 1;
				play_ram_rd_rdy <= play_ram_rd_en; -- 1 clk latency on playlist RAM
				if play_ram_rd_rdy then
					framegroup_ctr <= framegroup_ctr + 1;
					tvalid(tvalid'LEFT) <= '1';
					-- Send a signal to insert the timestamp on the second frame downstream in the pipeline
					if tx_insert_timestamp = '1' and first_bin = '1' and framegroup_ctr = 1 then
						insert_ts(insert_ts'LEFT) <= '1';
					end if;
					-- Setup the next read one frame before the last because of the RAM latency
					-- We have to do this because the output of the RAM is feeds back into the RAM address (via last_framegroup)
					if framegroup_ctr = last_framegroup - 1 then
						play_ram_rd_addr <= play_ram_rd_addr + 1;
						if end_of_transmission = '1' then
							busy <= '0'; -- we're done
						end if;
					end if;
					-- if the last frame of a bin
					if framegroup_ctr = last_framegroup then
						framegroup_ctr <= (others => '0');
						first_bin <= '0';
						if end_of_packet then -- 8k bins / 128 NUMA =64 bins/packets, 16 frames*8 bytes/bin/frame * 64 bins/packets = 8kB packet
							tlast(tlast'LEFT) <= '1';
							first_bin <= '1';
						end if;
						if end_of_transmission then
							eot(eot'LEFT) <= '1'; -- signal end of transmission down the pipeline
						end if;
					end if; -- if last frame

				-- Force end of transmission based on tx_len. This is a protection to protect against never-ending packets or transmissions.
				-- Should never be reached if playlist is programmed properly.
				-- if word_ctr = tx_length  then
				--  busy <= '0'; -- we're done
				--  tlast(tlast'LEFT) <= '1'; -- force tlast on that word
				--  first_bin <= '1';
				-- end if;
				end if;


				-- capture URAM output when it comes out
				tdata_reg <= ram_dout(to_integer(unsigned(col(col'RIGHT))));
				-- insert the timestamp when it's time (2nd frame of 1st bin of a packet)
				if insert_ts(insert_ts'RIGHT) = '1' then
					tdata_reg(8 * 6 + 63 downto 8 * 6) <= reverse_bytes(std_logic_vector(timestamp));
				end if;
				-- override output in test mode
				if tx_override_data = '1' then
					tdata_reg <= X"000102030405060708090A0B0C0D0E0F_101112131415161718191A1B1C1D1E1F";
				end if;

				tvalid_reg <= tvalid(tvalid'RIGHT) and tx_enable;
				tlast_reg <= tlast(tvalid'RIGHT);

				-- keep track of output frames for debugging
				if tvalid_reg = '1' and tlast_reg = '1' then
					out_frame_ctr <= out_frame_ctr + 1;
				end if;

				-- increment timestamp
				if eot(eot'RIGHT) = '1' then
					timestamp <= timestamp + timestamp_incr;
				end if;

				---- pipeline final output
				m_axis_out_tdata <= tdata_reg;
				m_axis_out_tvalid <= tvalid_reg;
				m_axis_out_tlast <= tlast_reg;

				-- start a new readout and set the busy flag when the bank changes (tx_trig_sel=0) or when the specified period has elapsed (tx_trig_sel=1)
				wr_bank_reg <= wr_bank;
				if (tx_trig_sel = '0' and wr_bank /= wr_bank_reg) or (tx_trig_sel = '1' and word_ctr = tx_period) then
					if busy = '1' then
						overrun <= '1';
					end if;
					busy <= '1';
					framegroup_ctr <= (others => '0');
					-- bin_ctr <= (others => '0');
					word_ctr <= (others => '0');
					play_ram_rd_addr <= (others => '0');
				end if;

				if rst = '1' or tx_reset = '1' then
					framegroup_ctr <= (others => '0');
					-- bin_ctr <= (others => '0');
					busy <= '0';
					overrun <= '0';
					-- tvalid_pre <= '0';
					tvalid <= (others => '0');
					tvalid_reg <= '0';
					m_axis_out_tvalid <= '0';
					play_ram_rd_rdy <= '0';
					play_ram_rd_addr <= (others => '0');
					wr_bank_reg <= '0';
					out_frame_ctr <= (others => '0');
					word_ctr <= (others => '0');
					first_bin <= '1';
					timestamp <= (others => '0');
				end if; -- rst
			end if; -- clk
		end process ram_rd_proc;

	end block ram_rd_block;


end architecture impl;





