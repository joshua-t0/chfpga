----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: JF Cliche
--
-- Create Date:    2012-06-12
-- Design Name: 	  chFPGA
-- Module Name:    UCORR44_ARRAY - Behavioral
-- Project Name: 	CHIME
-- Target Devices: Ultrascale+
-- Tool versions: Vivado 2022.2
-- Description: Implement an array of UCORR44
-- Dependencies:
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chFPGA_Package.all; -- Get all component definitions

library UNISIM;
use UNISIM.VComponents.all;

library xpm;
use xpm.vcomponents.all;


-- 4+4-bit correlator array
--
-- Input data is provided as a INPUT_WIDTH-wide vector to be divided into NCORR streams, one to each correlator core.
-- Correlator 0 stream is stored in the MSBs.
--
-- Each of the stream contains the input data from NCHAN Channels. Channel 0 is stored towards the MSBs.
-- Each complex data point from a channelizer is made of 4-bit Real part aligned toward sthe MSB, followed by the 4-bit Imaginary part.
-- Both real and imaginary parts are two's complement signed values.
--
entity UCORR44_ARRAY is
	GENERIC (
		PLATFORM_ID: integer;
		NCORR: integer := 1; -- number of correlators
		NCHAN: integer :=8; -- number of channels to correlate per correlator
		NBINS_PER_CORR: integer :=2048; -- Number of bins to be processed by each correlator
		BIN_DECIMATION_FACTOR: integer := 1; -- Only 1 out of every BIN_DECIMATION_FACTOR bin is processed in order to provide extra comoputing cycles and use less resources
		N_BITS_PER_BIN: integer := 4+4; -- The correlator only supports 4+4 bit format.
		SOFT_NINTEG: integer := 8192; -- default integration period (number of frames)
		SOFT_AUTOCORR_ONLY: boolean := FALSE;
		READOUT_BINS: integer_array(0 to NCORR-1) := (others => 0); -- array of integers indicating which bin is sacrificed to the readout cycle for each correlator
        INPUT_WIDTH: integer := 256; -- Number of bits of the input bus. Is divided in NCORR sections (CORR 0 in MSB),
        USE_OUTPUT_FIFO: boolean := FALSE
	);

	PORT (

		-- Input data AXI-S bus , non-blocking
		-- Data ordering from MSB to LSB => (Corr0,Chan0), (Corr0,Chan1), ... (Corr0,ChanN-1), ... (CorrM-1, ChanN-1)
		-- Re in MSB of byte
		s_axis_data_tdata : in  slv(INPUT_WIDTH-1 downto 0); -- input data stream containing the channelized data from every channelizer. Each frame must contain up to 512 words each containing four (4+4) bit signed complex values.
		s_axis_data_tvalid : in  std_logic; --
		s_axis_data_tlast : in  std_logic; --

		clk : in std_logic; -- Input clock channelized data.
		rst: in std_logic; -- Reset synchronous to the input clock


		-- Integrated product output
		-- AXI4-Streaming, blocking, 8-bit wide

		m_axis_data_tdata: out std_logic_vector(7 downto 0);
		m_axis_data_tvalid: out std_logic;
		m_axis_data_tlast: out std_logic;
		m_axis_data_tready: in std_logic;
		out_clk: in std_logic := '0'; -- ouput clock if USE_OUTPUT_FIFO=TRUE

		-- Control and reply streams
		s_axis_bsb_dat:  in AXIS8_DAT_STRUCT := (TDATA => X"00", TVALID => '0', TLAST =>'0');
		s_axis_bsb_rdy:  out AXIS8_RDY_STRUCT := (TREADY => '1');
		m_axis_bsb_dat: out AXIS8_DAT_STRUCT := (TDATA => X"00", TVALID => '0', TLAST =>'0');
		m_axis_bsb_rdy: in AXIS8_RDY_STRUCT := (TREADY => '1');
		ctrl_clk: in std_logic; -- control clock
		ctrl_rst: in std_logic
		);

end UCORR44_ARRAY;

architecture Behavioral of UCORR44_ARRAY is

    -- Attributes used in this design
    attribute equivalent_register_removal: string;
    attribute shreg_extract: string;
    attribute DONT_TOUCH: string;
    --attribute RLOC_ORIGIN : string;

    constant N: integer := NCHAN;
    constant NCHAN_PER_CLK: integer  := INPUT_WIDTH/NCORR/N_BITS_PER_BIN; -- Number of channels
    constant NCLK_PER_BIN: integer := NCHAN / NCHAN_PER_CLK; -- Number of clock needed to send all channels for one bin
    constant URAM_MAX: integer := sel(PLATFORM_INFO(PLATFORM_ID).FPGA_SERIES=FPGA_ULTRASCALEPLUS, 64 / NCORR, 0);
    signal rst_reg: slv(0 to NCORR-1);
    attribute DONT_TOUCH of rst_reg: signal is "true";
    -- Control signals
    signal control_bytes: slv8_array(0 to 3);
    signal status_bytes: slv8_array(0 to 5);
    signal user_reset: std_logic;
    signal user_reset_resync: std_logic;
    signal overrun_reset, overrun_reset_resync: std_logic;
    signal autocorr_only: std_logic;
    signal auto_bin_set: std_logic;
    signal offset_encoding: std_logic;
    signal manual_bin_set: unsigned(3 downto 0);
    signal no_accum: std_logic; -- when '1', there is no accumulation: only th elast product of the accumulation period is kept.
    signal integ_period: std_logic_vector(15 downto 0);
    signal corr_id: std_logic_vector(3 downto 0);

    signal bin_set: std_logic_vector(3 downto 0);
--    signal frame_ctr: unsigned(15 downto 0);

    type slv_2darray is array (natural range <>) of slv_array(0 to NCHAN_PER_CLK-1)(N_BITS_PER_BIN-1 downto 0);
    signal corr_in_tdata: slv_2darray(0 to NCORR-1);
    signal corr_in_tlast: std_logic_vector(0 to NCORR-1);
    signal corr_in_tvalid: std_logic_vector(0 to NCORR-1);
	attribute shreg_extract of corr_in_tdata, corr_in_tlast, corr_in_tvalid: signal is "no";

    signal z_tdata: slv_array(0 to NCORR)(7 downto 0);
    signal z_tlast: std_logic_vector(0 to NCORR);
    signal z_tvalid: std_logic_vector(0 to NCORR);
    signal z_send: std_logic_vector(0 to NCORR);

    signal overrun:std_logic_vector(0 to NCORR-1);
    signal in_frame_ctr: unsigned(7 downto 0);
    signal out_frame_ctr: unsigned(7 downto 0);
begin

    assert FALSE report "N="  & to_string(N) & " NCHAN_PER_CLK=" & to_string(NCHAN_PER_CLK);

    --------------------------------------------
    -- Memory mapped registers
    --------------------------------------------
    -- Memory Map
    -- ------------------------------------------------------------------------------
    -- |  Page   | Addr|Bit(s)|     Name             | Description                   |
    -- |---------|-----|------|----------------------|-------------------------------|
    -- | CONTROL |  0  |  7   | user_reset            | Reset the correlator |
    -- |         |     |  6   | overrun_reset          | Reset overrun counters |
    -- |         |     | 5:2  | corr_id                | Correlator ID |
    -- |         |     |  1   | no_accum               | No accumulation mode |
    -- |         |     |  0   | autocorr_only          | Autocorrelation only mode |
    -- |         | 1-2 | 15:0 | integ_period           | Integration period (number of frames) |
    -- |         |  3  |  7   | offset_encoding        | Offset binary encoding |
    -- |         |     |  6   | auto_bin_set            | Auto bin set |
    -- |         |     | 3:0  | bin_set                 | Manual bin set |
    -- | STATUS  |  0  |  0   | or(overrun)            | OR of all overrun flags |
    -- |         |     |  1   | rst                     | Reset status |
    -- |         |     |  2   | s_axis_data_tvalid      | Input data valid |
    -- |         |     |  3   | s_axis_data_tlast       | Input data last |
    -- |         |  1  | 7:0  | NCHAN                   | Number of channels |
    -- |         |  2  | 7:4  | NCORR                    | Number of correlators |
    -- |         |     | 3:0  | BIN_DECIMATION_FACTOR   | Bin decimation factor |
    -- |         |  3  | 7:0  | in_frame_ctr            | Input frame counter |
    -- |         |  4  | 7:0  | out_frame_ctr           | Output frame counter |
    -- |         |  5  | 3:0  | NCLK_PER_BIN            | Number of clocks per bin |
    -- |         |     | 7:4  | (unused)                | |
    -- ------------------------------------------------------------------------------

	bsb_regs0: entity work.CTRL_SLAVE
		GENERIC MAP (
			DEFAULT_CONTROL_BYTES=> "0000000" & to_std_logic(SOFT_AUTOCORR_ONLY) &
			                        to_slv(SOFT_NINTEG-1,16) &
			                        X"40", -- COntrol byte 3: no autobin, offset_encoding=0, manual_bin_set=0
			NUMBER_OF_CONTROL_BYTES => control_bytes'LENGTH(1), -- Number of bits in the control word
			NUMBER_OF_STATUS_BYTES => status_bytes'LENGTH(1) -- Number of bits in the status word.
		)
		PORT MAP(

			control_bytes => control_bytes,
			status_bytes => status_bytes,

			ctrl_cmd_in_dat=>   s_axis_bsb_dat,
			ctrl_cmd_in_rdy=>   s_axis_bsb_rdy,
			ctrl_rply_out_dat=> m_axis_bsb_dat,
			ctrl_rply_out_rdy=> m_axis_bsb_rdy,
			ctrl_clk => ctrl_clk,
			ctrl_rst => ctrl_rst
		);

	-- CONTROL byte 0
	user_reset            <= control_bytes(0)(7); --
	overrun_reset         <= control_bytes(0)(6); --
	corr_id               <= control_bytes(0)(5 downto 2);
    no_accum              <= control_bytes(0)(1);
    autocorr_only         <= control_bytes(0)(0);

    -- control byte 1-2
    integ_period <= to_slv(control_bytes(1 to 2));

    offset_encoding <= control_bytes(3)(7);
    auto_bin_set <= control_bytes(3)(6);
    bin_set      <= control_bytes(3)(3 downto 0);


    -- Status Byte 0
    status_bytes(0)(0) <= or(overrun);
    status_bytes(0)(1) <= rst;
    status_bytes(0)(2) <= s_axis_data_tvalid;
    status_bytes(0)(3) <= s_axis_data_tlast;

    -- Status Byte 1
    status_bytes(1) <= to_slv(NCHAN, 8);

    -- Status Byte 2
    status_bytes(2)(7 downto 4) <= to_slv(NCORR, 4);
    status_bytes(2)(3 downto 0) <= to_slv(BIN_DECIMATION_FACTOR, 4);

    -- Status Byte 3
    status_bytes(3) <= std_logic_vector(in_frame_ctr);

    -- Status Byte 4
    status_bytes(4) <= std_logic_vector(out_frame_ctr);

    -- Status Byte 5
    status_bytes(5)(3 downto 0) <= to_slv(NCLK_PER_BIN, 4);


	-- Synchronize the software-controlled user reset to the correlator clock to ensure proper release from reset
	rst_cdc0: xpm_cdc_single
		generic map (SRC_INPUT_REG => 0)
		port map (src_clk => '0', src_in => user_reset, dest_clk => clk, dest_out => user_reset_resync);

	-- Synchronize the software-controlled user reset to the correlator clock to ensure proper release from reset
	orrst_cdc0: xpm_cdc_single
		generic map (SRC_INPUT_REG => 0)
		port map (src_clk => '0', src_in => overrun_reset, dest_clk => clk, dest_out => overrun_reset_resync);

	---------------------------------------------------------------------
	-- Correlator input pipelining process
	---------------------------------------------------------------------
	-- Pipeline the reset and data buses inputs to facilitate routing and timing closure.
	process(all)
	   variable rcorr, rchan: integer; --inverted corr and chan numbers
	   variable lsb: integer;
	begin
		if rising_edge(clk) then
			rst_reg <= (others=> (rst or user_reset_resync));

			-- split the input word into NCORR correlator inputs and N channels
			for corr in 0 to NCORR-1 loop
                rcorr := NCORR-1-corr;
				for chan in 0 to NCHAN_PER_CLK-1 loop
				    rchan := NCHAN_PER_CLK-1-chan;
				    lsb := N_BITS_PER_BIN*(rcorr*NCHAN_PER_CLK + rchan);
					corr_in_tdata(corr)(chan) <= s_axis_data_tdata(lsb + N_BITS_PER_BIN -1 downto lsb);
				end loop;
				corr_in_tvalid(corr) <= '0' when rst_reg(corr) else s_axis_data_tvalid;
				corr_in_tlast(corr) <= s_axis_data_tlast;
			end loop;


--			-- Generate auto bin set
--			if corr_in_tvalid(0) and corr_in_tlast(0) then
--				frame_ctr <= frame_ctr + 1;
--				if frame_ctr = unsigned(integ_period) then
--					frame_ctr <= (others => '0');
--					bin_set <= manual_bin_set when not auto_bin_set else
--					               (others => '0') when bin_set = BIN_DECIMATION_FACTOR -1 else
--					               bin_set + 1;
--		        end if;
--			end if;
--            frame_ctr <= (others => '0') when rst_reg(0);
--            bin_set <= (others => '0') when rst_reg(0);

--            bin_set_dly <= bin_set;

			-- Count the input and output frames for debugging
			in_frame_ctr <= in_frame_ctr + 1 when s_axis_data_tvalid and s_axis_data_tlast;
			out_frame_ctr <= out_frame_ctr + 1 when m_axis_data_tvalid and m_axis_data_tlast;

		end if; -- clk
	end process;

	FIFO_GEN: if USE_OUTPUT_FIFO generate
		signal rx_data_fifo_dout64: std_logic_vector(63 downto 0);
		signal rx_data_fifo_dout8: std_logic_vector(7 downto 0);
		signal rx_data_fifo_empty: std_logic;
		signal almost_full: std_logic;
	begin
		m_axis_data_tdata <= rx_data_fifo_dout64(7 downto 0);
		m_axis_data_tvalid <= not rx_data_fifo_empty;
	    m_axis_data_tlast <= rx_data_fifo_dout8(0);
	    z_send(0) <= not almost_full;

		data_fifo0 : FIFO36E1  -- 7-series
			generic map (
				ALMOST_FULL_OFFSET => 13D"32",    -- Sets almost full flag 32 bytes before full to accomodate for the z_send response time
				DATA_WIDTH => 9,                  -- Data width is 9 bits, meaning that depth = 36K/9 = 4K bytes
				DO_REG => 1,                      -- Enable output register (1-0) Must be 1 if EN_SYN = FALSE
				EN_SYN => FALSE,                  -- Asynchronous FIFO
				FIFO_MODE => "FIFO36",            -- "FIFO36" or "FIFO36_72"
				FIRST_WORD_FALL_THROUGH => TRUE   -- We want FWFT
			)
			port map (

				-- Write interfce

				wrclk => clk,              -- 1-bit input: Rising edge write clock.
				wren  => z_tvalid(0),     -- 1-bit input: Write enable

				di(63 downto 8) => (others => '0'), -- data bus is 64 bit, only 8 LSBs are used
				di(7 downto 0)  => z_tdata(0),
				dip(7 downto 1) => (others => '0'), -- Parity bus is 8 bits, only LSB is used
				dip(0)          => z_tlast(0),
				almostfull => almost_full, -- 1-bit output: Almost full flag

				-- Read interface

				rdclk => out_clk, -- Read clock
				rden  => m_axis_data_tready, -- Read enable
				regce => '1', -- 1-bit input: Clock enable

				do  => rx_data_fifo_dout64, -- 64-bit data output. Valid data is in 8 LSBs
				dop => rx_data_fifo_dout8, -- 8 bit parity output. Valid data is on LSB
				empty => rx_data_fifo_empty,            -- 1-bit output: Empty flag


				-- ECC Signals (unused)
				injectdbiterr => '0',
				injectsbiterr => '0',

				-- Resets

				rst    => rst, -- Async -- write domain reset reset, must be high at least 5 cycles of the slowest clock
				rstreg => '0'  -- Output register reset
		   );

	else generate

		-- Connect CORR[0] output stream to the ouput port
		z_send(0) <= m_axis_data_tready; -- first corr sends data only if destination is ready
		m_axis_data_tdata <= z_tdata(0);
		m_axis_data_tvalid <= z_tvalid(0);
		m_axis_data_tlast <= z_tlast(0);

	end generate FIFO_GEN;

	-- Connect null stream to the cascade input of CORR[NCORR]
	z_tvalid(NCORR) <= '0'; -- no data coming into the last corr
	z_tdata(NCORR) <= (others => '0'); -- don't leave floating to prevent warnings
	z_tlast(NCORR) <= '0'; -- don't leave floating to prevent warnings

	corr_gen: for i in 0 to NCORR-1 generate
		-- set the position of the core44 core
		-- attribute RLOC_ORIGIN of corr0: label is rpm_to_string(corr44_rpm(i).loc);
		corr0: entity work.ucorr44
			generic map (
				PLATFORM_ID           => PLATFORM_ID,
				CORR_NUMBER           => i, -- will be used in the packet header and to determine the RPM location of the CORR44 cores
				NCORR                 => NCORR, -- used only to format STREAM ID
				NBINS                 => NBINS_PER_CORR, -- number of bins per correlator
				NCHAN                 => NCHAN,
				NCHAN_PER_CLK         => NCHAN_PER_CLK,
				NDECIM => BIN_DECIMATION_FACTOR,
				URAM_MAX              => URAM_MAX,
				READOUT_BIN           => READOUT_BINS(i)
				)
			port map(
				s_axis_tvalid => corr_in_tvalid(i),
				s_axis_tlast  => corr_in_tlast(i),
				s_axis_tdata  => corr_in_tdata(i),

				integ_period    => integ_period,
				auto_bin_set => auto_bin_set,
				bin_set         => bin_set,
				offset_encoding => offset_encoding,
				autocorr_only   => autocorr_only,
				no_accum        => no_accum,
				overrun         => overrun(i),
				overrun_reset   => overrun_reset,
				corr_id         => corr_id,

				z_out_tdata  => z_tdata(i),
				z_out_tvalid => z_tvalid(i),
				z_out_tlast  => z_tlast(i),
				z_out_send   => z_send(i),

				z_in_tdata  => z_tdata(i + 1),
				z_in_tvalid => z_tvalid(i + 1),
				z_in_tlast  => z_tlast(i + 1),
				z_in_send   => z_send(i + 1),

				clk => clk,
				rst => rst_reg(i)
				);

	end generate; -- NCORR

end Behavioral;

