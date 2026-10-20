----------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: J.-F. Cliche
--
-- Create Date: 2016
-- Design Name: chFPGA
-- Module Name: CMAC44 - Behavioral
-- Project Name: Suitcase Interferometer
-- Target Devices: 7 Series
-- Tool versions: Vivado 2016.4
-- Description: Implements a compact (4+4) bit complex multiplier/accumulator
--
-- Dependencies:
--
-- Revision:
--
-- Additional Comments:
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_complex.ALL;

library work;
use work.chFPGA_Package.all;

library UNISIM;
use UNISIM.VComponents.all;

--library UNIMACRO;
--use unimacro.Vcomponents.all;

library xpm;
use xpm.vcomponents.all;




-- UCMAC44: (4+4) bit complex vector multiplier-and-accumulate core
--
-- Casadable, compact (4+4) bit 512-element complex vector
-- multiplier/accumulator that uses two DSP48E1 and two RAMB16 blocks.
--
-- The input stream consist of a pair of (4+4) bit complex value presented on
-- each clock on its 16-bit input data bus. Each pair in a frame is multiplied
-- and accumulated in a separate memory location. Up to 512 separate products
-- can be stored.
--
-- The data is accumulated in a FIFO as a saturated (18+18) bit value. ! When
-- the ``last_frame`` flag is set, the final accumulated values are transferred
-- in a BRAM readout ! buffer and are read slowly through a 36-bit bus while
-- another integration in is progress. A readout input port allows the CMACs
-- to be connected in a readout chain.
--
--
-- See the Entity architecture for more implementation details.
entity UCORR44 is
	GENERIC (
		PLATFORM_TYPE: platform_type_enum := CRS;
		NCHAN: integer := 64; -- Number of inputs to correlate
		NCHAN_PER_CLK: integer := 32; -- Number of channels provided on each clock
		NBINS: integer; -- Number of bins to be processed by this correlator (before decimation)
		NDECIM: integer := 1; -- Only 1 out of every NDECIM bin is processed in order to provide extra comoputing cycles and use less resources
		CORR_NUMBER: integer := 0; -- correlator number to be used in packet headers
        NCORR: integer := 1;
		URAM_MAX: integer := 64;
		READOUT_BIN: integer := 0; -- bin number sacrificed for the readout cycle
		BINS_PER_FRAME_LOG2: integer := 3 -- Aggregate 2**N readout bins per AXIS frame / UDP packet (TLAST every 2**N bins, or on the last bin). Must be >= 1. 3 => 8 bins/frame.
		);
	PORT(

		-- Data be correlated & integrated. NCHAN channels (NCHAN bytes). AXI4-Streaming, non-blocking.
		s_axis_tdata: in slv_array(0 to NCHAN_PER_CLK - 1)(7 downto 0); -- Contains both (4+4) bit, Re in MSB
		s_axis_tlast: in std_logic;
		s_axis_tvalid: in std_logic;

		bin_set: in std_logic_vector(3 downto 0); -- Bin to select, from 0 to NDECIM-1.
		auto_bin_set: in std_logic;
		offset_encoding: in std_logic := '0'; -- '1' if incoming data uses offset binary encoding, so it can be undone before the correlator.
        integ_period: in std_logic_vector(15 downto 0);
        autocorr_only: in std_logic := '1';
	    no_accum: in std_logic := '1'; -- when '1', there is no accumulation: only th elast product of the accumulation period is kept.
	    corr_id: in std_logic_vector(3 downto 0); -- Software-defined identifier placed in the MSB of the STREAM ID. Used to uniquely identify correlator packets from multiple boards.

        overrun: out std_logic;
        overrun_reset: in std_logic;

		-- Byte-serialized cascadable data input/outputs, AXI-Streaming, 8-bit, sloppy blocking via `send`
		z_out_tdata: out std_logic_vector(7 downto 0);
		z_out_tlast: out std_logic;
		z_out_tvalid: out std_logic;
		z_out_send: in std_logic := '0'; -- for sims

		z_in_tdata: in std_logic_vector(7 downto 0) := (others => '0');
		z_in_tlast: in std_logic := '0';
		z_in_tvalid: in std_logic := '0'; -- for sims
		z_in_send: out std_logic := '0'; -- for sims

		clk : in std_logic; -- clock
		rst : in std_logic -- rst

		);

end UCORR44;


-- Compact (4+4) bit NCHAN-element correlator.
--
-- The complex multiplier/accumulator (CMAC) takes advantage of the small bit width if the incoming
-- complex number (4-bit real, 4-bit imaginary) to implement a full complex multiplier and
-- accumulator using only two DSP48, a half of a UltraRAM (or equivalent BRAMs), and a very small
-- amount of logic and routing resources.
--
-- Many tricks have been used to use the various features and operation modes of the DSP
-- block to minimize the use of fabric logic (such as fabric-based adders) and maximize speed.
--
-- The RAM is divided in two pages: the acculator page and the readout page. Since the UltraRAM does
-- not allow two fully independent read ports, we steal the write cycle of the first word of each
-- frame to read a word from the readout page.  We therefore lose the first 4 bins of the spectrum.
--
-- A UltraRAM has 4096 words x 72 bits. If each product is (18+18) bits, we can store 2 product per
-- word, and therefore 4096 products in each of the Accumulator and Readout pages.
--
-- It is assumed that the integration period is long enough so that the data can be sent out before
-- a new integration period starts. The capture buffer has the same geometry as the accumulator. It
-- is implemented as a BRAM, not a FIFO, since the FIFO embedded logic is used by the accumulator
-- FIFO. The read logic is simplified compared to a ful-fledged FIFO in order to reduce the logic
-- count.
--
--
-- Readout logic
-- -------------
--
-- The CMAC output is meant to be daisy-chained with other CMACs in order to stream the captured
-- accumulated products of all the units in the chain. Once the first unit of the chain has sent its data, the data
-- from the second CMAC is passed through the first one, and so on. This ensures that the routing needed to readout all the CMACs stays local.
--
-- Each CMAC has a `send` signal both on the upstream and downstram side to allow some degree of flow
-- control. On the downstream side, the `send` signal indicates a CMAC can send its data, or , when it is finished, it's neighbor's data.
-- The upstram `send` signal is enabled when the CMAC has finished sending its data to tells the neighbor that it can send its own data.
--
-- The `send` signal **does not** behave exactly as a AXI-S tREADY signal, which
-- *instantaneously* starts or stop data transfer. Implementing this behaviour in a daisy-chained (and
-- pipelined) data path involves more complex logic and data buffering to deal with data that
-- was sent based on delayed tready signal but can no longer be immediately accepted it when it
-- arrives at the sink.
--
-- Instead, the `send_in` signal is an instruction to start and stop sending data "as soon as
-- possible", meaning that  the data flow can start and stop some time after the signal is asserted.
-- This allows time for the `send_in` signal to propagate up to the targeted data source and for the
-- data to propagate back down through its pipeline stages. In other word, the `send` signal will
-- take effect only after the control and data pipeline latency.
--
-- Using such a *lazy* flow control scheme greatly simplifies the logic and storage requirements
-- (i.e flops) in each and every of the CMAC modules. However, an elastic buffer with sufficient
-- capacity is required at the end of the readout module to accomodate the time lag between the flow
-- control instruction and the actual effect of the flow. Since  we need to have a FIFO anyways to
-- cope with data width conversion and clock domain crossing, and that FIFO is needed only once
-- for every group of daisy-chained CMAC blocks, the resource usage is totally acceptable.
--
--
architecture impl of UCORR44 is

	-- Constants
	constant P: integer := (NCHAN * (NCHAN + 1) / 2); -- number of products
	constant NCLK_PER_BIN: integer := NCHAN / NCHAN_PER_CLK; -- number of clocks it takes to send all the channels of one bin
	constant NCLK: integer := NDECIM * NCLK_PER_BIN; -- Number of clocks the correlator should take to compute the products
	constant NCMAC : integer := P / NCLK;
	constant NCOL_PER_CLK: integer := NCHAN / 2 / NCLK; -- Number of columns if the squarified prodict matrix (NCHAN+1 rows bu NCHAN/2 cols) to processed per clock

	signal xy_tdata: slv_array(0 to NCMAC - 1)(15 downto 0);
	signal xy_swap: std_logic_vector(0 to NCMAC - 1);
	signal xy_tvalid: std_logic;
	signal xy_tlast: std_logic;

	signal xy_bin_set: std_logic_vector(3 downto 0);

	signal word_ctr: unsigned(3 downto 0); -- 0 to NCLK_PER_BIN - 1
	signal bin_ctr: unsigned(3 downto 0); -- 0 to NDECIM - 1


begin

	bin_sel: process(all) begin
		if rising_edge(clk) then
		end if;
	end process bin_sel;


    corr_blk: block is
		signal staging_tdata: slv_array(0 to NCHAN - 1)(7 downto 0); -- data staging (assembly) vector
		signal staging_tvalid: std_logic;
		signal staging_tlast: std_logic;
		signal staging_bin_set: std_logic_vector(3 downto 0);
    	signal xy_tlast_reg: std_logic;

		signal x: slv_array(0 to NCHAN - 1)(7 downto 0) := (others => (others => '0')); -- fixed correlation vector. Init value for nice sims only.
		signal y: slv_array(0 to NCHAN - 1)(7 downto 0):= (others => (others => '0')); -- rotating correlation vector. Init value for nice sims only.
		signal xsel: std_logic_vector(NCHAN / 2 to NCHAN - 1); -- mux selection vector, only applies to muxes fron NCHAN / 2+1 to NCHAN. Elements frm 0 to NCHAN / 2 are not touches and shoudl be synthesized out.

		signal clk_ctr: unsigned(4 downto 0); -- counts from 0 to NCLK (inclusively)
		signal bin_set_int: unsigned(3 downto 0);
		signal frame_ctr: unsigned(15 downto 0);
	begin

        xyj_gen: for j in 0 to NCOL_PER_CLK-1 generate
            xyi_gen: for i in 0 to NCHAN generate
                xy_swap(i * NCOL_PER_CLK + j) <= '1' when i>= NCHAN / 2 + 1 and (i + j >= NCHAN or xsel(i + j) = '1') else '0';
                xy_tdata(i * NCOL_PER_CLK + j)(15 downto 8) <= x(i - 1) when i>= NCHAN / 2 + 1 and (i + j >= NCHAN or xsel(i + j) = '1') else x(i);
                xy_tdata(i * NCOL_PER_CLK + j)(7 downto 0) <= y((i + j) mod NCHAN);
            end generate; --i
        end generate; --j

		seq_proc: process(all) begin
			if rising_edge(clk) then

				-- Count bins and words within bins
				if s_axis_tvalid then
					word_ctr <= word_ctr + 1;
					if word_ctr = NCLK_PER_BIN - 1 then
						word_ctr <= (others => '0');
						bin_ctr <= (others => '0') when bin_ctr = NDECIM - 1 else bin_ctr + 1;
					end if;
				end if; -- tvalid
				-- Extra counter resets when reset or end of frame is reached
				word_ctr <= (others => '0') when rst or (s_axis_tvalid and s_axis_tlast);
				bin_ctr <= (others => '0') when rst or (s_axis_tvalid and s_axis_tlast);

				-- Phase 1: Assemble the data into the staging vector, and undo offset binary encoding if present

				staging_tvalid <= '0'; -- Overriden below - Make sure tvalid is a single clock pulse
				if s_axis_tvalid then
					if bin_ctr = to_integer(bin_set_int) then -- if bin is in the selected bin set
                        for i in 0 to NCHAN_PER_CLK - 1 loop
                            staging_tdata(to_integer(word_ctr)*NCHAN_PER_CLK+i) <= s_axis_tdata(i) xor x"88" when offset_encoding else s_axis_tdata(i);
                        end loop;
                    end if;
					if (bin_ctr = NDECIM - 1 and word_ctr=NCLK_PER_BIN - 1) or s_axis_tlast='1' then -- set tvalid and tlast on the last word of the decimation block
						staging_tvalid <= '1'; -- pulse tvalid to start a new Nclock correlation cycle
   						staging_tlast <= s_axis_tlast;
		   				staging_bin_set <= std_logic_vector(bin_set_int);
   					end if;
   				end if;
				staging_tvalid <= '0' when rst;

				-- Generate auto bin set
				if staging_tvalid and staging_tlast then
					frame_ctr <= frame_ctr + 1;
					if frame_ctr = unsigned(integ_period) then
						frame_ctr <= (others => '0');
						bin_set_int <= unsigned(bin_set) when not auto_bin_set else
						               (others => '0') when bin_set_int = NDECIM - 1 else
						               bin_set_int + 1;
			        end if;
				end if;
	            frame_ctr <= (others => '0') when rst;
	            bin_set_int <= (others => '0') when rst;

   				-- Phase 2: Load and rotate X & Y registers NCLK times

				clk_ctr <= clk_ctr + 1;  -- Counts NCLKs - overriden below of new loads, otherwise free-running
				xy_tlast <= xy_tlast_reg when ??xy_tvalid and NCLK > 1 and clk_ctr = NCLK-2; -- set tlast on the last clock
 				xy_tvalid <= '0' when clk_ctr = NCLK-1 or ??autocorr_only; -- Processing complete
				-- Rotate y and grow xsel vectors by NCHAN. Overriden below when new data is ready.
                y <= y(NCOL_PER_CLK to NCHAN - 1) & y(0 to NCOL_PER_CLK-1);
                xsel(NCHAN / 2+1 to NCHAN - 1-NCOL_PER_CLK) <= xsel(NCHAN / 2+1+NCOL_PER_CLK to NCHAN - 1);
                xsel(NCHAN-NCOL_PER_CLK to NCHAN - 1) <= (others => '1');
                -- Load up XY and start new NCLK cycle upon valid staging word pulse
				if staging_tvalid then
					x <= staging_tdata;
					y <= staging_tdata;
					xsel(NCHAN / 2+1 to NCHAN - 1) <= (others =>'0');
                    clk_ctr <= (others => '0');
					xy_tvalid <= '1'; -- x & y contains valid data
					xy_tlast <= staging_tlast when NCLK = 1 or ??autocorr_only else '0'; -- Store tlast immediately if NCLK=1, otherwise it will be set at the end of the cycle
					xy_tlast_reg <= staging_tlast; -- store tlast to apply at then end on NCLK cycle if NCLK > 1
	   				xy_bin_set <= staging_bin_set when staging_tlast;
                end if;

				if rst then
    				xsel <= (others =>'0');
    				xy_tvalid <= '0';
    			end if; --rst
			end if; --clk
        end process;
	end block corr_blk;


	corr0: entity work.UCMAC44_ARRAY
		generic map (
			NCMAC => NCMAC,
			NPROD => NBINS / NDECIM * NCLK,
			AUTOCORR_STRIDE => NCOL_PER_CLK,
			CORR_NUMBER => CORR_NUMBER,
			NCORR => NCORR,
			URAM_MAX => URAM_MAX,
			READOUT_BIN => READOUT_BIN,
			BINS_PER_FRAME_LOG2 => BINS_PER_FRAME_LOG2
		)
		port map (
			s_axis_xy_tdata => xy_tdata,
			s_axis_xy_tvalid => xy_tvalid,
			s_axis_xy_tlast => xy_tlast,
			s_axis_xy_swap => xy_swap,


	        integ_period => integ_period,
            bin_set => xy_bin_set,
		    no_accum => no_accum,
	        overrun => overrun,
	        overrun_reset => overrun_reset,
	        autocorr_only => autocorr_only,
	        corr_id => corr_id,

			m_axis_z_tdata => z_out_tdata,
			m_axis_z_tlast => z_out_tlast,
			m_axis_z_tvalid => z_out_tvalid,
			m_axis_z_send => z_out_send,

			s_axis_z_tdata => z_in_tdata,
			s_axis_z_tlast => z_in_tlast,
			s_axis_z_tvalid => z_in_tvalid,
			s_axis_z_send => z_in_send,

			clk => clk,
			rst => rst
	);

end architecture impl;

