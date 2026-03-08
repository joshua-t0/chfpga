----------------------------------------------------------------------------------
-- Company: McGill Univ.
-- Engineer: JF Cliche
--
-- Create Date:    2026-02-16
-- Module Name:    generic_fifo
-- Target Devices: Kintex 7, Ultrascale+
-- Tool versions: Vivado 2022.2
-- Description: Universal FIFO wrapper.
--
--   Selects the appropriate implementation based on MEMORY_TYPE:
--     "embedded"    -> platform-specific FIFO18/FIFO36 primitives (K7: E1, USP: E2)
--     "bram"        -> XPM FIFO macro (xpm_fifo_sync or xpm_fifo_async)
--     "distributed" -> XPM FIFO macro with distributed RAM
--
--   For embedded FIFOs, automatically selects FIFO18 vs FIFO36 and instantiates
--   multiple primitives in parallel when DATA_WIDTH exceeds the capacity of a
--   single primitive at the requested DEPTH (following the prober.vhd pattern).
--
--   Reset contract: rst is treated as ASYNCHRONOUS. The wrapper synchronizes it
--   internally using xpm_cdc_async_rst. Both wr_en and rd_en are gated internally
--   during reset. wr_rst_busy / rd_rst_busy outputs indicate when each domain
--   has completed its reset sequence.
--
--   Embedded FIFO limitations:
--     - DEPTH must be a supported primitive depth (512, 1024, 2048, 4096, 8192).
--     - K7 embedded: when IS_FWFT=TRUE, async mode (EN_SYN=FALSE) is forced
--       internally even for synchronous FIFOs, to guarantee zero-latency FWFT.
--     - Maximum DATA_WIDTH is unlimited (parallel FIFOs are used).
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.ALL;

library xpm;
use xpm.vcomponents.ALL;

library work;
use work.chFPGA_Package.ALL;

entity generic_fifo is
	generic (
		FPGA_SERIES      : integer; -- Is ignored by "bram" and "distributed" MEMORY_TYPES
		MEMORY_TYPE      : string; -- "embedded", "bram", "distributed"
		IS_ASYNC         : boolean;
		IS_FWFT          : boolean;
		DATA_WIDTH       : integer;
		DEPTH            : integer := 2**integer_log2(18.0*1024 / DATA_WIDTH); -- defaults to what fits in a RAMB18/FIFO18 given the specified width.
		PROG_FULL_THRESH_OFFSET: integer := 10; -- offset from DEPTH at which prog_full asserts
		PROG_FULL_THRESH : integer := DEPTH - PROG_FULL_THRESH_OFFSET;  -- absolute word count at which prog_full asserts. Overrides PROG_FULL_THRESH_OFFSET.
		PROG_EMPTY_THRESH_OFFSET: integer := 10;   -- absolute word count at or below which prog_empty 		
		PROG_EMPTY_THRESH: integer := PROG_EMPTY_THRESH_OFFSET   -- absolute word count at or below which prog_empty asserts. Overrides PROG_EMPTY_THRESH_OFFSET
	);
	port (
		clk         : in  std_logic := '0'; -- single clock for synchronous FIFOs (IS_ASYNC=FALSE)
		wr_clk      : in  std_logic := '0'; -- write clock for async FIFOs (IS_ASYNC=TRUE)
		wr_en       : in  std_logic;
		din         : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
		full        : out std_logic;
		prog_full   : out std_logic;
		overflow    : out std_logic;
		wr_rst_busy : out std_logic;

		rd_clk      : in  std_logic := '0'; -- read clock for async FIFOs (IS_ASYNC=TRUE)
		rd_en       : in  std_logic;
		dout        : out std_logic_vector(DATA_WIDTH - 1 downto 0);
		empty       : out std_logic;
		prog_empty  : out std_logic;
		valid       : out std_logic;  -- In FWFT mode: equivalent to not empty. Undefined in standard mode for embedded FIFOs.
		rd_rst_busy : out std_logic;

		rst         : in  std_logic   -- asynchronous reset (synchronized internally)
	);
end entity generic_fifo;


architecture impl of generic_fifo is

	-- Internal clocks: clk when synchronous, wr_clk/rd_clk when asynchronous
	signal wr_clk_i : std_logic;
	signal rd_clk_i : std_logic;

begin

	-- Select the appropriate clock for the FIFO
	wr_clk_i <= clk when not IS_ASYNC else wr_clk;
	rd_clk_i <= clk when not IS_ASYNC else rd_clk;

	---------------------------------------------------------------------------
	-- Static assertions
	---------------------------------------------------------------------------



	---------------------------------------------------------------------------
	-- ===================== XPM FIFO PATH =====================
	---------------------------------------------------------------------------
	top_gen: if MEMORY_TYPE = "bram" or MEMORY_TYPE = "distributed" generate

		signal s_rst          : std_logic; -- rst synchronized to wr_clk
		signal xpm_wr_rst_busy: std_logic;
		signal xpm_rd_rst_busy: std_logic;
		signal gated_wr_en    : std_logic;
		signal gated_rd_en    : std_logic;

	begin

		-- Synchronize async rst to wr_clk
		rst_cdc0: xpm_cdc_async_rst
			generic map (RST_ACTIVE_HIGH => 1, DEST_SYNC_FF => 3)
			port map (src_arst => rst, dest_clk => wr_clk_i, dest_arst => s_rst);

		-- Gate enables
		gated_wr_en <= wr_en and not (s_rst or xpm_wr_rst_busy);
		gated_rd_en <= rd_en and not xpm_rd_rst_busy;

		wr_rst_busy <= s_rst or xpm_wr_rst_busy;
		rd_rst_busy <= xpm_rd_rst_busy;


		-- XPM asynchronous FIFO
		fifo_gen: if IS_ASYNC generate
			fifo0: xpm_fifo_async
				generic map (
					FIFO_MEMORY_TYPE  => MEMORY_TYPE, -- "auto", "block","distributed","ultra"
					FIFO_WRITE_DEPTH  => DEPTH,
					WRITE_DATA_WIDTH  => DATA_WIDTH,
					READ_DATA_WIDTH   => DATA_WIDTH,
					READ_MODE         => sel(IS_FWFT, "fwft", "std"),
					FIFO_READ_LATENCY => sel(IS_FWFT, 0, 1), -- 0 latency in FWFT mode, 1 in standard mode
					PROG_FULL_THRESH  => PROG_FULL_THRESH,
					PROG_EMPTY_THRESH => PROG_EMPTY_THRESH,
					USE_ADV_FEATURES  => xpm_fifo_features(overflow=> TRUE, data_valid=> TRUE, prog_full=> TRUE, prog_empty => TRUE), 
					CDC_SYNC_STAGES   => 3,
					FULL_RESET_VALUE  => 1
				)
				port map (
					wr_clk      => wr_clk_i,
					wr_en       => gated_wr_en,
					din         => din,
					full        => full,
					prog_full   => prog_full,
					overflow    => overflow,
					wr_rst_busy => xpm_wr_rst_busy,
					rst         => s_rst,

					rd_clk      => rd_clk_i,
					rd_en       => gated_rd_en,
					dout        => dout,
					empty       => empty,
					prog_empty  => prog_empty,
					data_valid  => valid,
					rd_rst_busy => xpm_rd_rst_busy,

					sleep       => '0',
					injectsbiterr => '0',
					injectdbiterr => '0'
				);
		
		else generate -- XPM synchronous FIFO
			fifo0: xpm_fifo_sync
				generic map (
					FIFO_MEMORY_TYPE  => MEMORY_TYPE,
					FIFO_WRITE_DEPTH  => DEPTH,
					WRITE_DATA_WIDTH  => DATA_WIDTH,
					READ_DATA_WIDTH   => DATA_WIDTH,
					READ_MODE         => sel(IS_FWFT, "fwft", "std"),
					FIFO_READ_LATENCY => sel(IS_FWFT, 0, 1), -- 0 latency in FWFT mode, 1 in standard mode	
					PROG_FULL_THRESH  => PROG_FULL_THRESH,
					PROG_EMPTY_THRESH => PROG_EMPTY_THRESH,
					USE_ADV_FEATURES  => xpm_fifo_features(overflow=> TRUE, data_valid=> TRUE, prog_full=> TRUE, prog_empty => TRUE),
					FULL_RESET_VALUE  => 1
				)
				port map (
					wr_clk         => wr_clk_i,
					rst         => s_rst,
					wr_en       => gated_wr_en,
					din         => din,
					full        => full,
					prog_full   => prog_full,
					overflow    => overflow,
					wr_rst_busy => xpm_wr_rst_busy,

					rd_en       => gated_rd_en,
					dout        => dout,
					empty       => empty,
					prog_empty  => prog_empty,
					data_valid  => valid,
					rd_rst_busy => xpm_rd_rst_busy,

					sleep       => '0',
					injectsbiterr => '0',
					injectdbiterr => '0'
				);
		end generate fifo_gen;

	---------------------------------------------------------------------------
	-- =================== EMBEDDED FIFO PATH ===================
	---------------------------------------------------------------------------
	elsif MEMORY_TYPE = "embedded" generate

		---------------------------------------------------------------------------
		-- Embedded FIFO parameter record
		---------------------------------------------------------------------------
		type fifo_params_t is record
			use_fifo18       : boolean;
			prim_data_width  : integer; -- data port width per primitive
			prim_parity_width: integer; -- parity port width per primitive
			num_fifos        : integer; -- number of parallel primitives
			data_width       : integer; -- user DATA_WIDTH
		end record;
	
		function compute_fifo_params(data_w: integer; depth: integer) return fifo_params_t is
			variable p: fifo_params_t;
			-- Lookup tables indexed by mode (narrowest to widest)
			constant PRIM_DATA_W   : integer_array := (4,    8,    16,   32,   64);
			constant PRIM_PARITY_W : integer_array := (0,    1,     2,    4,    8);
			constant FIFO36_DEPTHS : integer_array := (8192, 4096, 2048, 1024, 512);
			constant FIFO18_DEPTHS : integer_array := (4096, 2048, 1024,  512,   0); -- no 72-bit mode
			variable pw, dw, parw  : integer;
			variable use_fifo18    : boolean := false;
		begin
			-- Step 1: Try to fit in a single FIFO18 (most resource-efficient).
			-- Find the narrowest FIFO18 mode with width >= data_w AND depth >= requested.
			for i in PRIM_DATA_W'range loop
				pw := PRIM_DATA_W(i) + PRIM_PARITY_W(i);
				if pw >= data_w and FIFO18_DEPTHS(i) >= depth then
					dw := PRIM_DATA_W(i);  parw := PRIM_PARITY_W(i);
					use_fifo18 := true;
					exit;
				end if;
			end loop;
	
			-- Step 2: If FIFO18 can't do it, use FIFO36(s).
			-- Find the widest FIFO36 mode with depth >= requested depth.
			if not use_fifo18 then
				dw := PRIM_DATA_W(0);  parw := PRIM_PARITY_W(0);
				for i in PRIM_DATA_W'range loop
					if FIFO36_DEPTHS(i) >= depth then
						dw := PRIM_DATA_W(i);  parw := PRIM_PARITY_W(i);
					end if;
				end loop;
			end if;
	
			pw := dw + parw;
			p := (
				use_fifo18        => use_fifo18,
				prim_data_width   => dw,
				prim_parity_width => parw,
				num_fifos         => sel(use_fifo18, 1, (data_w + pw - 1) / pw),
				data_width        => data_w
			);
			return p;
		end function;

		constant FI : fifo_params_t := compute_fifo_params(DATA_WIDTH, DEPTH);
		
		constant N          : integer := FI.num_fifos;
		constant PRIM_WIDTH : integer := FI.prim_data_width + FI.prim_parity_width;
		constant PADDED_DATA_WIDTH : integer := PRIM_WIDTH * N;

		-- Padded data buses: zero-pad input, trim output
		signal din_padded  : std_logic_vector(PADDED_DATA_WIDTH - 1 downto 0);
		signal dout_padded : std_logic_vector(PADDED_DATA_WIDTH - 1 downto 0);


		-- Per-FIFO aggregate signals
		signal full_vec      : std_logic_vector(N - 1 downto 0);
		signal empty_vec     : std_logic_vector(N - 1 downto 0);
		signal prog_full_vec : std_logic_vector(N - 1 downto 0);
		signal prog_empty_vec: std_logic_vector(N - 1 downto 0);
		signal overflow_vec  : std_logic_vector(N - 1 downto 0);
		-- Unified reset pipeline (both K7 and USP)
		signal wr_rst_cdc  : std_logic; -- rst synchronized to wr_clk
		signal wr_rst_hold : std_logic; -- extended reset on wr_clk (64 cycles, conservative)
		signal wr_rst_ctr  : unsigned(5 downto 0); -- 6-bit counter -> 64 wr_clk cycles
		signal rd_rst_hold : std_logic; -- reset on rd_clk (CDC of wr_rst_hold, or direct if sync)

		-- Gating and busy
		signal gated_wr_en      : std_logic;
		signal gated_rd_en      : std_logic;
		signal prim_wr_rst_busy : std_logic_vector(N - 1 downto 0);
		signal prim_rd_rst_busy : std_logic_vector(N - 1 downto 0);
		-- Raw primitive busy (USP only; K7 primitives have no RSTBUSY ports)
		signal prim_wrrstbusy_raw : std_logic_vector(N - 1 downto 0) := (others => '0');
		signal prim_rdrstbusy_raw : std_logic_vector(N - 1 downto 0) := (others => '0');

	begin
		assert not (FPGA_SERIES = FPGA_KINTEX7 and not IS_ASYNC and IS_FWFT)
		report "generic_fifo: K7 embedded sync FIFO with FWFT: forcing EN_SYN=FALSE for zero-latency FWFT"
		severity NOTE;
		-- Put the data that is wide enough to accomodate the primitive width. It's possible not all bits will be used.
		din_padded <= resize(din, PADDED_DATA_WIDTH);
		dout <= dout_padded(DATA_WIDTH - 1 downto 0);

		-- Aggregate flags: conservatively OR across all parallel FIFOs
		full      <= or(full_vec);
		empty     <= or(empty_vec);
		prog_full <= or(prog_full_vec);
		prog_empty<= or(prog_empty_vec);
		overflow  <= or(overflow_vec);
		valid     <= not (or(empty_vec));

		-----------------------------------------------------------------------
		-- Unified reset pipeline (both K7 and USP, no platform generate)
		-----------------------------------------------------------------------

		-- Synchronize async rst to wr_clk
		wr_rst_cdc0: xpm_cdc_async_rst
			generic map (RST_ACTIVE_HIGH => 1, DEST_SYNC_FF => 4)
			port map (src_arst => rst, dest_clk => wr_clk_i, dest_arst => wr_rst_cdc);

		-- Extend wr_rst_cdc to 64 wr_clk cycles (conservative for both K7 and USP)
		process(all) begin
			if rising_edge(wr_clk_i) then
				if wr_rst_cdc then
					wr_rst_hold <= '1';
					wr_rst_ctr  <= (others => '0');
				elsif all_ones(wr_rst_ctr) then
					wr_rst_hold <= '0';
				else
					wr_rst_ctr <= wr_rst_ctr + 1;
				end if;
			end if;
		end process;

		-- Rd-side reset: CDC to rd_clk if async, direct if sync
		gen_async_rd_rst: if IS_ASYNC generate
			rd_rst_cdc0: xpm_cdc_async_rst
				generic map (RST_ACTIVE_HIGH => 1, DEST_SYNC_FF => 4)
				port map (src_arst => wr_rst_hold, dest_clk => rd_clk_i, dest_arst => rd_rst_hold);
		else generate
			rd_rst_hold <= wr_rst_hold;
		end generate;

		-- Busy mux: synthetic on K7 (from extended reset), real on USP (from primitive)
		prim_wr_rst_busy <= (others => wr_rst_hold) when (FPGA_SERIES = FPGA_KINTEX7) else prim_wrrstbusy_raw;
		prim_rd_rst_busy <= (others => rd_rst_hold) when (FPGA_SERIES = FPGA_KINTEX7) else prim_rdrstbusy_raw;

		-- Gated enables and busy outputs (same formulas for both platforms)
		gated_wr_en <= wr_en and not (wr_rst_cdc or or(prim_wr_rst_busy));
		gated_rd_en <= rd_en and not (or(prim_rd_rst_busy));
		wr_rst_busy <= wr_rst_cdc or or(prim_wr_rst_busy);
		rd_rst_busy <= or(prim_rd_rst_busy);


		loop_gen: for i in 0 to N - 1 generate

						constant PRIM_DATA_BUS_WIDTH : integer := sel(FI.use_fifo18, 32, 64);
			constant PRIM_PARITY_BUS_WIDTH : integer := sel(FI.use_fifo18, 4, 8);
			-- Per-FIFO data buses: only the lower bits of the data and parity ports are used.
			signal di  : std_logic_vector(PRIM_DATA_BUS_WIDTH - 1 downto 0);
			signal dip : std_logic_vector(PRIM_PARITY_BUS_WIDTH - 1 downto 0);
			signal do  : std_logic_vector(PRIM_DATA_BUS_WIDTH - 1 downto 0);
			signal dop : std_logic_vector(PRIM_PARITY_BUS_WIDTH - 1 downto 0);

		begin
			-- Data port: zero-extend user bits to full primitive bus width
			di <= resize(din_padded((i * PRIM_WIDTH) + FI.prim_data_width - 1 downto i * PRIM_WIDTH), PRIM_DATA_BUS_WIDTH);

			-- Parity port: zero-extend user parity bits, or tie to '0' if no parity in this mode
			gen_has_parity: if FI.prim_parity_width > 0 generate
				dip <= resize(din_padded((i + 1) * PRIM_WIDTH - 1 downto (i * PRIM_WIDTH) + FI.prim_data_width), PRIM_PARITY_BUS_WIDTH);
				dout_padded((i + 1) * PRIM_WIDTH - 1 downto (i * PRIM_WIDTH) + FI.prim_data_width) <= dop(FI.prim_parity_width - 1 downto 0);
			end generate;
			gen_no_parity: if FI.prim_parity_width = 0 generate
				dip <= (others => '0');
			end generate;

			-- Output data port
			dout_padded((i * PRIM_WIDTH) + FI.prim_data_width - 1 downto i * PRIM_WIDTH) <= do(FI.prim_data_width - 1 downto 0);



			-- K7 FIFO18E1 path (single primitive)
			fifo_gen: if FPGA_SERIES = FPGA_KINTEX7 and FI.use_fifo18 generate
				fifo0: FIFO18E1
					generic map (
						ALMOST_FULL_OFFSET      => to_bit_vector(DEPTH - PROG_FULL_THRESH, 13),
						ALMOST_EMPTY_OFFSET     => to_bit_vector(PROG_EMPTY_THRESH, 13),
						DATA_WIDTH              => PRIM_WIDTH,
						DO_REG                  => 1,
						EN_SYN                  => not (IS_ASYNC or IS_FWFT), -- force async for FWFT (zero-latency)
						FIFO_MODE               => sel(PRIM_WIDTH = 36, "FIFO18_36", "FIFO18"),
						FIRST_WORD_FALL_THROUGH => IS_FWFT,
						SIM_DEVICE              => "7SERIES"
					)
					port map (
						wrclk      => wr_clk_i,
						wren       => gated_wr_en,
						di         => di,
						dip        => dip,
						full       => full_vec(i),
						almostfull => prog_full_vec(i),
						wrerr      => overflow_vec(i),

						rdclk      => rd_clk_i,
						rden       => gated_rd_en,
						regce      => '1',
						do         => do, --32 bits
						dop        => dop, --4 bits
						empty      => empty_vec(i),
						almostempty=> prog_empty_vec(i),

						rst        => wr_rst_hold,
						rstreg     => '0'
					);


			-- K7 FIFO36E1 path (N parallel primitives)
			elsif FPGA_SERIES = FPGA_KINTEX7 and not FI.use_fifo18 generate
					fifo0: FIFO36E1
						generic map (
							ALMOST_FULL_OFFSET      => to_bit_vector(DEPTH - PROG_FULL_THRESH, 13),
							ALMOST_EMPTY_OFFSET     => to_bit_vector(PROG_EMPTY_THRESH, 13),
							DATA_WIDTH              => PRIM_WIDTH,
							DO_REG                  => 1,
							EN_SYN                  => not (IS_ASYNC or IS_FWFT), -- force async for FWFT (zero-latency)
							FIFO_MODE               => sel(PRIM_WIDTH = 72, "FIFO36_72", "FIFO36"),
							FIRST_WORD_FALL_THROUGH => IS_FWFT,
							SIM_DEVICE              => "7SERIES"
						)
						port map (
							wrclk      => wr_clk_i,
							wren       => gated_wr_en,
							di         => di,
							dip        => dip,
							full       => full_vec(i),
							almostfull => prog_full_vec(i),
							wrerr      => overflow_vec(i),

							rdclk      => rd_clk_i,
							rden       => gated_rd_en,
							regce      => '1',
							do         => do,
							dop        => dop,
							empty      => empty_vec(i),
							almostempty=> prog_empty_vec(i),

							injectdbiterr => '0',
							injectsbiterr => '0',

							rst        => wr_rst_hold,
							rstreg     => '0'
						);


			elsif FPGA_SERIES = FPGA_ULTRASCALEPLUS and FI.use_fifo18 generate
				-- USP FIFO18E2 path (single primitive)
				fifo0: FIFO18E2
					generic map (
						CLOCK_DOMAINS           => sel(IS_ASYNC, "INDEPENDENT", "COMMON"),
						PROG_FULL_THRESH        => PROG_FULL_THRESH,
						PROG_EMPTY_THRESH       => PROG_EMPTY_THRESH,
						READ_WIDTH              => PRIM_WIDTH,
						WRITE_WIDTH             => PRIM_WIDTH,
						REGISTER_MODE           => sel(IS_FWFT, "REGISTERED", "DO_PIPELINED"),
						FIRST_WORD_FALL_THROUGH => sel(IS_FWFT, "TRUE", "FALSE")
					)
					port map (
						WRCLK     => wr_clk_i,
						WREN      => gated_wr_en,
						DIN       => di,
						DINP      => dip,
						FULL      => full_vec(i),
						PROGFULL  => prog_full_vec(i),
						WRERR     => overflow_vec(i),
						WRRSTBUSY => prim_wrrstbusy_raw(i),

						RDCLK     => rd_clk_i,
						RDEN      => gated_rd_en,
						REGCE     => '1',
						DOUT      => do,
						DOUTP     => dop,
						EMPTY     => empty_vec(i),
						PROGEMPTY => prog_empty_vec(i),
						RDRSTBUSY => prim_rdrstbusy_raw(i),

						RST       => wr_rst_hold,
						RSTREG    => '0',
						SLEEP     => '0',

						CASDIN        => (others => '0'),
						CASDINP       => (others => '0'),
						CASDOMUX      => '0',
						CASDOMUXEN    => '0',
						CASNXTRDEN    => '0',
						CASOREGIMUX   => '0',
						CASOREGIMUXEN => '0',
						CASPRVEMPTY   => '0'
					);
			elsif FPGA_SERIES = FPGA_ULTRASCALEPLUS and not FI.use_fifo18 generate
				fifo0: FIFO36E2
					generic map (
						CLOCK_DOMAINS           => sel(IS_ASYNC, "INDEPENDENT", "COMMON"),
						PROG_FULL_THRESH        => PROG_FULL_THRESH,
						PROG_EMPTY_THRESH       => PROG_EMPTY_THRESH,
						READ_WIDTH              => PRIM_WIDTH,
						WRITE_WIDTH             => PRIM_WIDTH,
						REGISTER_MODE           => sel(IS_FWFT, "REGISTERED", "DO_PIPELINED"),
						FIRST_WORD_FALL_THROUGH => sel(IS_FWFT, "TRUE", "FALSE"),
						WRCOUNT_TYPE            => "EXTENDED_DATACOUNT",
						RDCOUNT_TYPE            => "EXTENDED_DATACOUNT"
					)
					port map (
						WRCLK     => wr_clk_i,
						WREN      => gated_wr_en,
						DIN       => di,
						DINP      => dip,
						FULL      => full_vec(i),
						PROGFULL  => prog_full_vec(i),
						WRERR     => overflow_vec(i),
						WRRSTBUSY => prim_wrrstbusy_raw(i),
						WRCOUNT   => open,

						RDCLK     => rd_clk_i,
						RDEN      => gated_rd_en,
						REGCE     => '1',
						DOUT      => do,
						DOUTP     => dop,
						EMPTY     => empty_vec(i),
						PROGEMPTY => prog_empty_vec(i),
						RDRSTBUSY => prim_rdrstbusy_raw(i),
						RDCOUNT   => open,
						RDERR     => open,

						RST       => wr_rst_hold,
						RSTREG    => '0',
						SLEEP     => '0',

						CASDIN        => (others => '0'),
						CASDINP       => (others => '0'),
						CASDOMUX      => '0',
						CASDOMUXEN    => '0',
						CASNXTRDEN    => '0',
						CASOREGIMUX   => '0',
						CASOREGIMUXEN => '0',
						CASPRVEMPTY   => '0',
						INJECTSBITERR => '0',
						INJECTDBITERR => '0'
					);
			else generate
				assert FALSE report "generic_fifo: Invalid embedded FIFO configuration. Is the FPGA_SERIES specified?"
					severity FAILURE;
			end generate fifo_gen;

		end generate loop_gen;
	else generate
		assert FALSE report "generic_fifo: MEMORY_TYPE must be ""embedded"", ""bram"", or ""distributed"""
			severity FAILURE;
	end generate top_gen;

end architecture impl;
