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




-- ----------------------------------
-- UCMAC44: (4+4) bit complex vector multiplier-and-accumulate core
-- ----------------------------------
-- Casadable, compact (4+4) bit 512-element complex vector
-- multiplier/accumulator that uses two DSP48E1 and two RAMB16 blocks.
--
-- The input stream consist of a pair of (4+4) bit complex value presented on
-- each clock on its 16-bit input data bus. Each pair in a frame is multiplied
-- and accumulated in a separate memory location. Up to 512 separate products
-- can be stored.
--
-- The data is accumulated in a FIFO as a saturated (18+18) bit value. ! When
-- the `last_frame` flag is set, the final accumulated values are transferred
-- in a BRAM readout ! buffer and are read slowly through a 36-bit bus while
-- another integration in is progress. A readout input port allows the CMACs
-- to be connected in a readout chain.
--
--
-- See the Entity architecture for more implementation details.
entity UCORR44 is
	GENERIC (
		PLATFORM_ID: integer := PLATFORM_ID_CRS;
		N: integer :=64; -- Number of inputs to correlate
		N_PER_CLK: integer := 32; -- Number of inputs provided on each clock
		BIN_DECIMATION_FACTOR: integer := 1; -- Only 1 out of every BIN_DECIMATION_FACTOR bin is processed in order to provide extra comoputing cycles and use less resources
		Nclk: integer := BIN_DECIMATION_FACTOR*N/N_PER_CLK; -- Number of clocks  the correlator should take to compute the products
		CORR_NUMBER: integer := 0; -- correlator number to be used in packet headers
        NCORR: integer := 1;
		URAM_MAX: integer := 64;
		READOUT_BIN: integer := 0 -- bin number sacrificed for the readout cycle
		);
	PORT(

		-- Data be correlated & integrated. N channels (N bytes). AXI4-Streaming, non-blocking.
		s_axis_tdata: in slv_array(0 to N_PER_CLK-1)(7 downto 0); -- Contains both (4+4) bit, Re in MSB
		s_axis_tlast: in std_logic;
		s_axis_tvalid: in std_logic;


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


-- @brief Implementation of the compact (4+4) bit complex multiplier/accumulator.
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
	constant P: integer := (N*(N+1)/2); -- number of products
	constant NCMAC : integer := P / Nclk;
	constant WORDS_PER_BIN: integer := N/N_PER_CLK; -- number of clocks it takes to send all the channels of one bin
	constant K: integer := BIN_DECIMATION_FACTOR; -- bin decimation factor
	constant H: integer := N/2/Nclk; -- Number of columns processed per clock
	--constant Nprod_per_clk: integer := N/2/Nclk/K


	signal xy_tdata: slv_array(0 to NCMAC-1)(15 downto 0);
	signal xy_swap: std_logic_vector(0 to NCMAC-1);
	signal xy_tvalid: std_logic;
	signal xy_tlast: std_logic;
	signal xy_tlast_pre: std_logic;

	signal word_ctr: unsigned(3 downto 0); -- 0 to WORDS_PER_BIN-1
	signal bin_ctr: unsigned(3 downto 0); -- 0 to K-1


begin

	bin_sel: process(all) begin
		if rising_edge(clk) then
			if s_axis_tvalid then
				word_ctr <= word_ctr + 1;
				if word_ctr = WORDS_PER_BIN-1 then
					word_ctr <= (others => '0');
					bin_ctr <= bin_ctr + 1;
					if bin_ctr = K-1 then
						bin_ctr <= (others => '0');
					end if;
				end if;
			end if; -- tvalid
			-- synchronous resets
			if rst or (s_axis_tvalid and s_axis_tlast) then
				word_ctr <= (others => '0');
				bin_ctr <= (others => '0');
			end if; --rst
		end if;
	end process bin_sel;


    corr_blk: block
		signal t: slv_array(0 to N-N_PER_CLK-1)(7 downto 0); -- assembly vector - don't need to store the last word
		signal x: slv_array(0 to N-1)(7 downto 0) := (others => (others => '0')); -- fixed correlation vector. Init value for nice sims only.
		signal y: slv_array(0 to N-1)(7 downto 0):= (others => (others => '0')); -- rotating correlation vector. Init value for nice sims only.
		signal xsel: std_logic_vector(N/2 to N-1); -- mux selection vector, only applies to muxes fron N/2+1 to N. Elements frm 0 to N/2 are not touches and shoudl be synthesized out.

		signal clk_ctr: unsigned(3 downto 0);
	begin

        xyj_gen: for j in 0 to H-1 generate
            xyi_gen: for i in 0 to N generate
                xy_swap(i*H+j) <= '1' when i>= N/2+1 and (i+j>=N or xsel(i+j)='1') else '0';
                xy_tdata(i*H+j)(15 downto 8) <= x(i-1) when i>= N/2+1 and (i+j>=N or xsel(i+j)='1') else x(i);
                xy_tdata(i*H+j)(7 downto 0) <= y((i+j) mod N);
            end generate; --i
        end generate; --j

		seq_proc: process(all) begin
			if rising_edge(clk) then
				-- Rotate y and grow xsel vectors by N. Overriden below when new data is ready.
                y <= y(H to N-1) & y(0 to H-1);
                if NCLK > 1 then
                    xsel(N/2+1 to N-1-H) <= xsel(N/2+1+H to N-1);
                    xsel(N-H to N-1) <= (others => '1');
                end if;
                -- Keep xy_tvalid high for Nclk clocks and set xy_tlast on last clock
                xy_tlast <= '0';
                if xy_tvalid then
                    clk_ctr <= clk_ctr + 1;
  				    if NCLK > 1 and clk_ctr = NCLK-2 and autocorr_only='0' then
                        xy_tlast <= xy_tlast_pre;
                    end if;
  				    if clk_ctr = NCLK-1 or autocorr_only='1' then
  				        xy_tvalid <= '0'; -- overriden below
  				    end if; -- clk_ctr
  				end if; -- xy_tvalid

                -- Assemble N inputs into x and y
				if s_axis_tvalid='1' and bin_ctr=3 then
					if word_ctr = WORDS_PER_BIN-1 then -- if last word of bin
						y(0 to N-N_PER_CLK-1) <= t;
						y(N-N_PER_CLK to N-1) <= s_axis_tdata;
						x(0 to N-N_PER_CLK-1) <= t;
						x(N-N_PER_CLK to N-1) <= s_axis_tdata;
						xsel(N/2+1 to N-1) <= (others =>'0');
						xy_tvalid <= '1'; -- restart a Nclock correlation cycle
                        if NCLK=1 or autocorr_only='1' then
    						xy_tlast <= s_axis_tlast;
    				    end if;
  						xy_tlast_pre <= s_axis_tlast;
                        clk_ctr <= (others => '0');
                    elsif N /= N_PER_CLK then
                        -- Put incoming bytes in assembly vector and transfer to xy when ready
                        for i in 0 to N_PER_CLK-1 loop
                            t(to_integer(word_ctr)*N_PER_CLK+i) <= s_axis_tdata(i);
                        end loop;
					end if;
				end if; -- tvalid and right bin

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
			AUTOCORR_STRIDE => H,
			CORR_NUMBER => CORR_NUMBER,
			N_CORR => NCORR,
			URAM_MAX => URAM_MAX,
			READOUT_BIN => READOUT_BIN
		)
		port map (
			s_axis_xy_tdata => xy_tdata,
			s_axis_xy_tvalid => xy_tvalid,
			s_axis_xy_tlast => xy_tlast,
			s_axis_xy_swap => xy_swap,

	        integ_period => integ_period,
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

