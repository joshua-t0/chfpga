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
		N: integer :=8; -- Number of analog channels to correlate
		CORR_NUMBER: integer; -- correlator number to be used in packet headers
--		INTEG_PERIOD_MAX: integer := 65535;
		NBINS_TO_READOUT: integer := 2048; -- maximum number of bins that will be read and sent
--		IMPLEMENT_AUTOCORR_ONLY: boolean := TRUE; -- If true, sends only autocorrelations
		P: integer := (N*(N+1)/2); -- number of products - do not change: computed from N
		URAM_MAX: integer := P/2 - 2
--		RPM_NAME: string := "CORR0"; -- name of the RPM set name that identify which correlator the DSPs and BRAMs belong to.
--		RPM_COORDS: cmac44_rpm_coord_struct -- RPM coordinates of the DSPs and BRAMs
		);
	PORT(

		-- Data be correlated & integrated. N channels (N bytes). AXI4-Streaming, non-blocking.
		s_axis_tdata: in slv_array(0 to N-1)(7 downto 0); -- Contains both (4+4) bit
		s_axis_tlast: in std_logic;
		s_axis_tvalid: in std_logic;


        integ_period: in std_logic_vector(15 downto 0);
        autocorr_only: in std_logic := '1';
	    no_accum: in std_logic := '1'; -- when '1', there is no accumulation: only th elast product of the accumulation period is kept.

        overrun: out std_logic;

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


	-- Attributes definition
	attribute RPM_GRID : string;
	attribute RLOC : string;
	--attribute HU_SET : string;
	attribute U_SET : string;
	attribute RLOC_ORIGIN : string;
	attribute KEEP_HIERARCHY : string;
	--attribute HU_SET : string;


	-- Constants
	--constant P: integer := (N * (N + 1))/2; -- i.e. number of products
	constant BYTES_PER_PRODUCT: integer := 5; -- (18+18) bits + 4 extra bits = 40 bits = 5 bytes
--	constant BYTES_PER_RO_WORD: integer := BYTES_PER_PRODUCT * P;
	--constant DSP_LEFT: boolean := FALSE;
	--constant DSP1_RLOC: string := sel(DSP_LEFT, "X65Y0", "X45Y0");
	--constant FIFO_RLOC: string := sel(DSP_LEFT, "X78Y0", "X34Y0");
	--constant BRAM_RLOC: string := sel(DSP_LEFT, "X78Y1", "X34Y1");

	-- Get the FPGA series for this platform so we can chose which DSP primitive to use
	constant FPGA_SERIES:integer := PLATFORM_INFO(PLATFORM_ID).FPGA_SERIES;

	constant s_axis_xconj: std_logic := '0'; -- when '1', uses the complex conjugate of the x
	constant s_axis_yconj: std_logic := '1'; -- when '1', uses the complex conjugate of the y

	-- Function to compute the (i,j) coordinate of each elemenent in the product vector
	-- Exemple for N=4: (0,0), (0,1), (0,2), (0,3), (1,1), (1,2), (1,3), (2,2), (2,3), (3,3)
	type tuple_array is array (NATURAL range <>) of integer_vector(0 to 1);
	function vect_input_map(N:integer) return tuple_array is
		variable M: integer := (N*(N+1))/2;
		variable xy: tuple_array(0 to M-1);
		variable k: integer := 0;
	begin
		for i in 0 to N-1 loop
			for j in i to N-1 loop
				xy(k)(0) := i;
				xy(k)(1) := j;
				k := k + 1;
			end loop;
		end loop;
		return xy;
	end function vect_input_map;

	constant input_map: tuple_array(0 to P-1) := vect_input_map(N);

	attribute KEEP_HIERARCHY of impl: architecture is "YES";
	--attribute RLOC_ORIGIN of Behavioral: architecture is ORIGIN;
	signal rst_reg: std_logic;


	signal ram_dout: slv_array(0 to P-1)(35 downto 0);
	signal ram_din: slv_array(0 to P-1)(35 downto 0);
	signal ram_wr_addr: std_logic_vector(11 downto 0); -- 12 bits = 4096 words
	signal ram_rd_addr: std_logic_vector(11 downto 0); -- 12 bits = 4096 words
	signal ram_wr_en: std_logic :='0';
	signal ram_rd_en: std_logic :='1';

	signal tvalid1, tvalid2, tvalid3, tvalid4: std_logic:='0';
	signal tlast1, tlast2, tlast3, tlast4: std_logic;
	signal first_word1, first_word2: std_logic:='1'; -- first word of frame
	signal last_frame1, last_frame2, last_frame3, last_frame4: std_logic;
	signal first_frame1, first_frame2: std_logic :='1'; --init needed


	-- Relative Placed Macro constraints



begin

	ctrl_blk : block

--        signal frame_max: unsigned(3 downto 0); -- currently limited to 16. Depends on memory depth (frames/uram block) x number of channels.

  		signal frame: unsigned(15 downto 0); -- 11-bits wide: 2048 integ, 12-bits wide: 4096 frame integration
		signal rd_word_ctr1: unsigned(10 downto 0); -- 2048 words/frame.
		signal ro_word_ctr1: unsigned(10 downto 0); -- readout word counter. 2048 words/frame.
--  	    signal capture_en: std_logic; -- '1' when tdata shall be written to RAM when tvalid=1
--    	signal src_readout_trig: std_logic; -- pulse indicating when a source is ready to be read
  		--signal ram_rd_acc_addr: std_logic_vector(10 downto 0); -- accumulator bank read address
--  		signal ram_rd_acc_addr: std_logic_vector(10 downto 0); -- readout bank read address
  		signal wr_word_ctr5: unsigned(10 downto 0); -- readout bank read address
  		--signal ram_rd_ro_addr: std_logic_vector(10 downto 0); -- readout bank read address
--    	signal acc_rd_bank: std_logic; -- Accumulator bank for reading previous accumulated value
    	signal acc_bank1, acc_bank5: std_logic; -- Accumulator bank

		signal bytes: slv8_array(0 to FRAME_HEADER_BYTE_LENGTH + P * BYTES_PER_PRODUCT-1); -- readout buffer: header + products
--		signal send_byte: std_logic_vector(0 to FRAME_HEADER_BYTE_LENGTH + P * BYTES_PER_PRODUCT-1); -- Indicates whether we send the byte or not
		signal byte_ctr: integer range 0 to bytes'LENGTH;
		signal ro_busy: std_logic := '0'; -- memory readout busy
		signal dc_busy: std_logic := '0'; -- daisy chain readout busy
--		signal send_local_data: std_logic := '0';
		signal timestamp, first_timestamp: unsigned(47 downto 0);
        -- signal overrun: std_logic;
	begin

--		ram_rd_acc_addr <= word_ctr;
		ram_rd_addr <= (not acc_bank1) & std_logic_vector(ro_word_ctr1) when rd_word_ctr1=0 else
		               acc_bank1 & std_logic_vector(rd_word_ctr1);
		ram_wr_addr <= acc_bank5 & std_logic_vector(wr_word_ctr5);

		wr_proc: process(clk)
		    variable frame_header: FRAME_HEADER_STRUCT := (PROBE_ID => X"CF", others => (others =>'0'));
		    variable prod: integer range 0 to N; -- counts autocorr products (not N-1 because last increment?)
		    variable prod_bytes: slv8_array(0 to BYTES_PER_PRODUCT-1);
		begin
			if rising_edge(clk) then
				rst_reg <= rst;

				-------------
				-- CLOCK 1 - sign-corrected data is clocked into the DSP1 A & B registers, and we register sign and zero flags
				-------------


				-- Write state machine: count words and frames, and set the done signal
--	            src_readout_trig <= '0'; -- single clock pulse signal, overriden below
				if s_axis_tvalid then
					rd_word_ctr1 <= rd_word_ctr1 + 1;
					if s_axis_tlast then
						rd_word_ctr1 <= (others => '0');
						frame <= frame + 1;
                        timestamp <= timestamp + 1;
						if frame=unsigned(integ_period) then -- if last frame of the integration period
	                        frame <= (others => '0'); -- restart the readout from word 0
                            if ro_busy then
                                overrun <= '1';
                            end if;
							ro_busy <= '1'; -- start the readout
							z_in_send <= '0'; -- tell the upstream cascaded correlators we stop accepting data
							acc_bank1 <= not acc_bank1;
							first_timestamp <= timestamp+1;
--                            z_in_tready <= '0'; -- we won't be processing cascade inputs
							ro_word_ctr1 <= to_unsigned(1, ro_word_ctr1'LENGTH);
							--capture_en <= '0';
						end if;
					end if;
				end if;

                -- pipeline the control signals
				tvalid1 <= s_axis_tvalid;
				tlast1 <= s_axis_tlast;
				first_word1 <= to_std_logic(rd_word_ctr1=0); -- first word of frame
				last_frame1 <= to_std_logic(frame=unsigned(integ_period)); -- last frame of accumulation
                first_frame1 <= to_std_logic(all_zeros(frame)); -- last frame of accumulation
				-------------
				-- CLOCK 2: The product is clocked in the M=XY register of DSP1, and we clock the correction in the C=Z register.
				-- We also present the FIFO output back into the C input of the DSP2.
				-------------

                -- pipeline the control signals
				tvalid2 <= tvalid1;
				tlast2 <= tlast1;
				first_word2 <= first_word1;
				last_frame2 <= last_frame1;
				first_frame2 <= first_frame1;

--				if tvalid1 and tlast1 then
--					timestamp <= timestamp + 1;
--					if first_frame1 then
--						first_timestamp <= timestamp;
--					end if;
--				end if;

				-------------
				-- CLOCK 3: Register the pre-accumulation product (DSP1 sum XY+Z) in DSP1.P and RAM output in DSP2.C.
				-- If frame 0, capture new readout products when needed.
				-------------

                -- pipeline the control signals
				tvalid3 <= tvalid2;
				tlast3 <= tlast2;
				last_frame3 <= last_frame2;
--				z_in_tready <= '0' when cc_done='1' and ro_done='0'

                -- Clear valid flag if output word is transferred
                z_out_tvalid <= '0';
                z_in_send <= z_out_send;

                -- Clear tvalid. Is overriden below if a new byte is available.

                if ro_busy then -- if readout in in progress
                    z_in_send <= '0';
                    z_out_tdata <= bytes(0);
                    z_out_tlast <= '0';
                    z_out_tvalid <= '0';
                    if byte_ctr /= 0 and z_out_send='1' then -- if we have a byte to send and we are allowed to send it
                        z_out_tvalid <= '1';
                        if byte_ctr = 1 then -- tlast when last byte.
                            z_out_tlast <= '1';
                            ro_word_ctr1 <= ro_word_ctr1 + 1;
                            if ro_word_ctr1 = NBINS_TO_READOUT-1 then
                                ro_busy <='0';
                            end if;
                        end if;
                        bytes(0 to bytes'LENGTH-2) <= bytes(1 to bytes'LENGTH-1);
--                        send_byte(0 to send_byte'LENGTH-2) <= send_byte(1 to send_byte'LENGTH-1);
                        byte_ctr <= byte_ctr - 1;
                     end if;
                else -- sending cascade input data
                    z_out_tvalid <= z_in_tvalid;
                    z_out_tdata <= z_in_tdata;
                    z_out_tlast <= z_in_tlast;
                    if z_in_tvalid='1' then
						dc_busy <= '1';
						if z_in_tlast then
							dc_busy <= '0';
							z_in_send <= '0';
						end if;
					end if;
				end if; -- if local data

				-- Load the readout bytes if the first word (word 0) is present on the RAM output (first_word2='1') and
				-- if we are sending the last byte ((z_out_tready='1' and byte_ctr = 1)) or if all bytes have been sent (byte_ctr=0)
				if first_word2='1' and byte_ctr=0 then

					-- Store the header in the bytes buffer
					frame_header.STREAM_ID(12 downto 2) := std_logic_vector(ro_word_ctr1);
					frame_header.STREAM_ID(1 downto 0) := to_slv(CORR_NUMBER, 2); -- Will be bin number (0-3)
					frame_header.TIMESTAMP := std_logic_vector(first_timestamp);
                    frame_header.FLAGS(0) := overrun;
                    frame_header.FLAGS(1) := autocorr_only;
					bytes(0 to FRAME_HEADER_BYTE_LENGTH-1) <= struct_to_bytes(frame_header);
--					send_byte(0 to FRAME_HEADER_BYTE_LENGTH-1) <= (others => '1');
					-- Store the product bytes in the bytes buffer

                    -- Capture the RAM outputs, slice them in 5-byte products,  and store them in the shift register
                    prod := 0;
                    for i in 0 to P-1 loop
                        prod_bytes := to_slv8_array(reverse_bytes(std_logic_vector(resize(unsigned(ram_dout(i)), 8 * BYTES_PER_PRODUCT))));
                        bytes(FRAME_HEADER_BYTE_LENGTH + BYTES_PER_PRODUCT*i to FRAME_HEADER_BYTE_LENGTH + BYTES_PER_PRODUCT*(i+1)-1) <= prod_bytes;
                        -- Override the lower product bytes with the autocorrelation products if the feature is soft-enabled
                        if input_map(i)(0) = input_map(i)(1) then -- if this is an autocorrelation product
                            if autocorr_only='1' then
                                bytes(FRAME_HEADER_BYTE_LENGTH + BYTES_PER_PRODUCT*prod to FRAME_HEADER_BYTE_LENGTH + BYTES_PER_PRODUCT*(prod+1)-1) <= prod_bytes;
                            end if;
                            prod := prod + 1;
                        end if;
                    end loop;

                    if ro_busy then
                        -- Now that we have captured this readout word, move on to the next one.
                        -- we won't have another tfirst for a while so we are guaranteed that the address will hav epropageted for the next readout.
--                        ro_word_ctr1 <= ro_word_ctr1 + 1; -- this could be outside the if condition to save logic but is confusing in sims
                        -- Start the data transmisison unless readout is completed
--                        if ro_word_ctr1 /= 0 then -- don't send bin 0 since the cycle is used for readout instead of accumulation

                        -- set the byte counter to signify we now have data to send
                        if autocorr_only = '1' then
                            byte_ctr <= FRAME_HEADER_BYTE_LENGTH + N * BYTES_PER_PRODUCT;
                        else
                            byte_ctr <= FRAME_HEADER_BYTE_LENGTH + P * BYTES_PER_PRODUCT;
                        end if;
					end if;
				end if;

				-------------
				-- CLOCK 4: Register the accumulated product in DSP2.P and set the RAM wr_en signal if data is valid.
				-------------

                --= pipeline control signals
				tvalid4 <= tvalid3;
				tlast4 <= tlast3; -- last word
				last_frame4 <= last_frame3; -- last frame
				ram_wr_en <= tvalid3; -- write the data

				-------------
				-- CLOCK 5:  Increment write address once data has been written. Switch write bank if last frame is completed.
				-------------

				-- Increment ram write address post-write
				if tvalid4 then
					wr_word_ctr5 <= wr_word_ctr5 + 1;
					if tlast4 then
						wr_word_ctr5 <= (others => '0');
					end if;
					if tlast4 and last_frame4 then
						acc_bank5 <= not acc_bank5;
					end if;
				end if;



				-- Synchronous resets (overrides signals above)
				if rst_reg = '1' then
					rd_word_ctr1 <= (others => '0');
					frame <= (others => '0');
					ro_busy <= '0';
                    overrun <= '0';

                    timestamp <= (others => '0');
                    first_timestamp <= (others => '0');

					tvalid1 <= '0';
					tvalid2 <= '0';
					tvalid3 <= '0';
					tvalid4 <= '0';


					acc_bank1 <= '0';
					acc_bank5 <= '0';
					wr_word_ctr5 <= (others => '0');

--					first_frame2 <= '1';
--					last_frame4 <= '0';
				end if;

			end if; -- CLK
		end process wr_proc;

	end block ctrl_blk;


    -----------------------------
	-- DSPs
	-----------------------------
    -- Implement a complex multiplier and accumulator (CMAC) for each product. Each CMAC consist of a DSP pair.
    --
	-- The first DSP implements the multiplier with correction factors, which yields the ac, (ad-bc) and bd terms in its output registers.
	-- a and c are assumed to be unsigned. Corrections are applied by the adder to compensate for overlaps between the bd and (ad-bc) terms.
	-- results are presented on the P and PC (calcaded P)  ports.
	--
	-- The second DSP adds `ad` and `-bc` to form the real part the product, and  adds the previously accumulated Re and Im parts from the RAM.
	-- The output of DSP2 is saturated if the sum overflows, of if the value from the RAM was already overflown. The saturated product is then
	-- written back to the accumulator RAM.
	--


	dsp_gen: for i in 0 to P-1 generate
		--attribute U_SET of dsp1, dsp2 : label is "CORR" & integer'IMAGE(CORR_NUMBER);
		attribute RPM_GRID of dsp1: label is "GRID";  -- coordinates in unit of RPM_X and RPM_Y. All element sin the same group will automatically use that grid.
--		attribute U_SET of dsp1, dsp2 : label is RPM_NAME;
		--attribute RLOC of dsp1: label is rpm_to_string(RPM_COORDS.DSP1);
		--attribute RLOC of dsp2: label is rpm_to_string(RPM_COORDS.DSP2);

		signal dsp1_a: std_logic_vector(29 downto 0);
		signal dsp1_b: std_logic_vector(17 downto 0);
		signal dsp1_c: std_logic_vector(47 downto 0);
		-- signal dsp1_c_dly: std_logic_vector(47 downto 0);
		signal dsp1_p: std_logic_vector(47 downto 0);
		signal dsp1_pcout: std_logic_vector(47 downto 0);
		signal dsp1_alumode: std_logic_vector(3 downto 0);
		signal dsp1_cin: std_logic;


		signal dsp2_ab: std_logic_vector(47 downto 0);
		signal dsp2_c: std_logic_vector(47 downto 0);
		signal dsp2_p: std_logic_vector(47 downto 0);
		signal dsp2_cin: std_logic;
		signal dsp2_opmode: std_logic_vector(6 downto 0);
		signal dsp2_c_im_sign3: std_logic;
		signal dsp2_c_im_sign4: std_logic;
		signal dsp2_c_re_sign3: std_logic;
		signal dsp2_c_re_sign4: std_logic;
		signal im_sat3: std_logic;
		signal re_sat3: std_logic;
		signal im_sat4: std_logic;
		signal re_sat4: std_logic;
		signal dsp2_ab_im_sign4: std_logic;

		signal a: signed(3 downto 0); --
		signal b: signed(3 downto 0); --
		signal c: signed(3 downto 0); --
		signal d: signed(3 downto 0); --

		signal a1: unsigned(3 downto 0); -- ranges from 0 to 8
		signal b1: signed(4 downto 0); -- ranges from -8 to 8
		signal c1: unsigned(3 downto 0); -- ranges from 0 to 8
		signal d1: signed(4 downto 0); -- ranges from -8 to 8
		signal a1_zero: std_logic;
		signal b1_zero: std_logic;
		signal c1_zero: std_logic;
		signal d1_zero: std_logic;
		signal b1_neg: std_logic;
		signal d1_neg: std_logic;
		signal neg1: std_logic;

	begin

        -- We want to compute the product of (a+jb)*(c-jd)
		-- Extract a,b,c and d from the AXI4-S input word. These are all 4-bit signed values. This does not require any logic, just wiring.
		a <= signed(s_axis_tdata(input_map(i)(0))(7 downto 4)); -- Re
		b <= signed(s_axis_tdata(input_map(i)(0))(3 downto 0)); -- Im
		c <= signed(s_axis_tdata(input_map(i)(1))(7 downto 4)); -- Re
		d <= signed(s_axis_tdata(input_map(i)(1))(3 downto 0)); -- Im


		-- Make sure that a and c are always positive. If a was negative and is negated, then negate b so
		-- the entire complex value (a+jb) is negated. Likewise, if c is negated, negate d as well. We will
		-- invert the sign of the product if either one of a or b was negated (see the neg1 flag)
		--
		-- Since the second dsp inverts the real part of the result (we get (bd-ad) instead of (ad-bd)), we
		-- will compute instead -(*X)(*Y) = -(a-jb)(c-jd) = -((ac-bd)+j(-ad-bc)) = (bd-ac)+j(ad+bc), which,
		-- after the dsp2 stage, will yield (ac-bd)+j(ad+bc). We therefore take the complex conjugate of X
		-- and Y (i.e invert the sign of b and d), and we will invert the neg1 flag.
		--
		-- The signs of b and d can also be inverted individually to allow the user to use the complex
		-- conjugate of either X and Y.
		--
		-- a1 & c1 are 4 bit unsigned values since they store positive values from 0 to 8.
		-- b1 & d1 are 5 bit signed values since they store signed values from -8 to 8.
		-- The negation operations involves some combinatorial logic, which is not too costly here because we operate on 4-bit values.

		a1 <= unsigned(-a) when a(3)='1' else unsigned(a); -- 4-bit unsigned (0-8)
		b1 <= -resize(b,5) when (a(3) xor s_axis_xconj)='0' else resize(b,5); -- use conjugate if a was NOT inverted or if requested
		c1 <= unsigned(-c) when c(3)='1' else unsigned(c); -- 4-bit unsigned (0-8)
		d1 <= -resize(d,5) when (c(3) xor s_axis_yconj) ='0' else resize(d,5); -- use conjugate if a was NOT inverted or if requested

		-- Pack a1, b1, c1 and d1 into the A and B port of the first DSP
		-- b1 and d1 are sign-entended to 9 bits, a1 and c1 are sign-extended to the left (all zeros since always positive)
		-- we have a combinatorial 4-bit negater between the module input and the DSP.

		dsp1_a <= "0000000000000" & std_logic_vector(a1) & "0000" & std_logic_vector(resize(b1, 9));
		dsp1_b <= "0" & std_logic_vector(c1) & "0000" & std_logic_vector(resize(d1, 9));

		-- The XY products contain:
		-- b1*d1:  products spans 17:0, bits 17:13 nulled by correction, bits 12:8 unused, final product in 7:0 ( 8 bits)
		-- (ad+bc): product spans 23:13, +1 added if negated, final product in 21:13 (9 bits)
		-- a1*c1: product spans 47:26, correction applied to set 47:45 to '1', final product in 44:26 (19 bits)
		--
		-- In summary:
		--     dsp1_p (48 bits) = [111][ac, 19 bits][xxxx][ad+bc, 9 bits][xxxxx][bd, 8 bits]
		--------------------------------------------



		-- Corrections for overlaps and to negate values. This imply some combinatorial logic between registered signals and the dsp1_c input.


		-- No need to correct the lower b1*d1
		dsp1_c(12 downto 0) <= (others=>'0');

		-- Compute correction in C port to compensate for the b*d product overlap with ad+bc (all ones), and to add 1 to ad+bc if we negate
		dsp1_c(18 downto 13) <= "100000" when b1_neg='1' and d1_neg='1' and neg1='1' else --# correct for bd/im overlap and add 1 to negate im. No carry proparates from negating bd because bd!=0
		                        "011111" when b1_neg='1' and d1_neg='1' and neg1='0' else --# correct for bd/im overlap. We don't negate so no need to add 1.
		                        "000001" when b1_zero='0' and d1_zero='0' and neg1='1' else -- # There is no bd overlap, so no correction for this. But add 1 to im to negate if there is no carry from bd while negating.
		                        "000000";-- no correction needed
		dsp1_c(25 downto 19) <= (others=>'0');
		-- Add one to ac if we negate and if we don't have a carry from (ab+bc) that does that for us
		dsp1_c(26) <= '1' when neg1='1' and ((a1_zero='0' and d1_zero='0') or (b1_zero='0' and c1_zero='0')) else --# add 1 to ac if im is not zero
		              '0';
		dsp1_c(44 downto 27) <= (others=>'0');

		-- Set upper msbs to '111' to prepare for the following accumulation
		dsp1_c(47 downto 45) <= "001" when neg1='0' else -- 000-001=111
		                        "111" when (a1_zero='1' or c1_zero='1') else -- neg=1 and ac=0, cancel the carry
		                        "000"; --- neg=1, we already have 111, do nothing

		-- dsp1_c(45) <= neg1;
		-- dsp1_c(47 downto 46) <= (others=>'0');


		-- Set ALUMODE and CIN so we negate (X+Y) if neg=1.
		dsp1_alumode <= "0011" when neg1='1' else  -- p = corr - (p + 0) = corr-p ,  P = Z-(X+Y+CIN)
		                "0001"; --p = ~corr + (p + 1) = p-corr # P = ~Z+(X+Y+CIN)
		dsp1_cin <= not neg1; -- adds one to ~bd so we don't have to include this 'one' to the dsp1_c correction

		-- We bypass the DSP2 multiplier, and we bring the 48-bit AB signal directly to the adder
		-- The AB=X signal of DSP2 is composed of slices of the P (fabric) output of DSP1.
		-- The Y signal of the DSP2 adder is the DSP2 C input (the accumulator output)
		-- The Z input of the adder of DSP2 is the cascaded link between DSP1 (PC) shifted right by 17 bits

		dsp2_ab(47 downto 30) <= std_logic_vector(resize(signed(dsp1_p(13 + 9 - 1 downto 13)), 18)); -- im=ac-bd, dsp1_p(21 downto 13) (9 bits wide), casted into 19 bits wide, p[21] copied 10 times,
		dsp2_ab(29 downto 28) <= "00"; -- guard bit, prevents the sum of re part from overflowing in the im part
		dsp2_ab(27 downto 9) <= std_logic_vector(resize(signed(dsp1_p(7 downto 0)), 19)); -- bd
		dsp2_ab(8 downto 0) <= dsp1_p(25 downto 17);

		-- AB = ((im & 0x7FFFF) << 29) | (( bin_to_int(p, 8) & 0x7FFFF)<<9) |(bit(p, 25) << 8)  # im, 9 bits, sign extended to 19 bits, in AB[47:29]. bd, 8 bits, is sign extended to 19 bits and is in AB[27:9].
		-- dsp2_c(47 downto 29) <= (others=>'0'); -- im
		dsp2_c(47 downto 30) <= ram_dout(i)(17 downto 0); -- im
		dsp2_c(29 downto 28) <= "00"; -- guard bits
		dsp2_c(27) <= ram_dout(i)(35);
		dsp2_c(26 downto 9) <= ram_dout(i)(35 downto 18); -- im
		dsp2_c(8 downto 0) <= (others=>'0');
		dsp2_cin <= '1';
		dsp2_opmode <= "1010011" when first_frame2='1' or no_accum='1' else --X=A:B, Y=0, Z=PCIN>>17
		               "1011111"; --X=A:B, Y=C, Z=PCIN>>17


		-- Instantiate the two DSPs
		dsp1 : DSP48E1
			generic map (
				-- Feature Control Attributes: Data Path Selection
				A_INPUT            => "DIRECT", -- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
				B_INPUT            => "DIRECT", -- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
				USE_DPORT          => FALSE, -- Select D port usage (TRUE or FALSE)
				USE_MULT           => "MULTIPLY", -- Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
				USE_SIMD           => "ONE48", -- SIMD selection ("ONE48", "TWO24", "FOUR12")
				-- Pattern Detector Attributes: Pattern Detection Configuration
				AUTORESET_PATDET   => "NO_RESET", -- "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH"
				MASK               => X"3fffffffffff", -- 48-bit mask value for pattern detect (1=ignore)
				PATTERN            => X"000000000000", -- 48-bit pattern match for pattern detect
				SEL_MASK           => "MASK", -- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2"
				SEL_PATTERN        => "PATTERN", -- Select pattern value ("PATTERN" or "C")
				USE_PATTERN_DETECT => "NO_PATDET", -- Enable pattern detect ("PATDET" or "NO_PATDET")
				-- Register Control Attributes: Pipeline Register Configuration
				ACASCREG           => 1, -- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
				ADREG              => 1, -- Number of pipeline stages for pre-adder (0 or 1)
				ALUMODEREG         => 1, -- Number of pipeline stages for ALUMODE (0 or 1)
				AREG               => 1, -- Number of pipeline stages for A (0, 1 or 2)
				BCASCREG           => 1, -- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
				BREG               => 1, -- Number of pipeline stages for B (0, 1 or 2)
				CARRYINREG         => 1, -- Number of pipeline stages for CARRYIN (0 or 1)
				CARRYINSELREG      => 1, -- Number of pipeline stages for CARRYINSEL (0 or 1)
				CREG               => 1, -- Number of pipeline stages for C (0 or 1)
				DREG               => 1, -- Number of pipeline stages for D (0 or 1)
				INMODEREG          => 1, -- Number of pipeline stages for INMODE (0 or 1)
				MREG               => 1, -- Number of multiplier pipeline stages (0 or 1)
				OPMODEREG          => 1, -- Number of pipeline stages for OPMODE (0 or 1)
				PREG               => 1 -- Number of pipeline stages for P (0 or 1)
			)
			port map (
				-- Cascade: 30-bit (each) output: Cascade Ports
				ACOUT          => open, -- 30-bit output: A port cascade output
				BCOUT          => open, -- 18-bit output: B port cascade output
				CARRYCASCOUT   => open, -- 1-bit output: Cascade carry output
				MULTSIGNOUT    => open, -- 1-bit output: Multiplier sign cascade output
				PCOUT          => dsp1_pcout, -- 48-bit output: Cascade output
				P              => dsp1_p, -- 48-bit output: Primary data output
				-- Control: 1-bit (each) output: Control Inputs/Status Bits
				OVERFLOW       => open, -- 1-bit output: Overflow in add/acc output
				PATTERNBDETECT => open, -- 1-bit output: Pattern bar detect output
				PATTERNDETECT  => open, -- 1-bit output: Pattern detect output
				UNDERFLOW      => open, -- 1-bit output: Underflow in add/acc output
				-- Data: 4-bit (each) output: Data Ports
				CARRYOUT       => open, -- 4-bit output: Carry output
				-- Cascade: 30-bit (each) input: Cascade Ports
				ACIN           => (others=> '0'), -- 30-bit input: A cascade data input
				BCIN           => (others=> '0'), -- 18-bit input: B cascade input
				CARRYCASCIN    => '0', -- 1-bit input: Cascade carry input
				MULTSIGNIN     => '0', -- 1-bit input: Multiplier sign input
				PCIN           => (others=> '0'), -- 48-bit input: P cascade input
				-- Control: 4-bit (each) input: Control Inputs/Status Bits
				ALUMODE        => dsp1_alumode, -- 4-bit input: ALU control input
				CARRYINSEL     => "000", -- 3-bit input: Carry select input
				CLK            => clk, -- 1-bit input: Clock input
				INMODE         => "00000", -- 5-bit input: INMODE control input
				OPMODE         => "0110101", -- 7-bit input: Operation mode input, X/Y=M, P=C
				-- Data: 30-bit (each) input: Data Ports
				A              => dsp1_a, -- 30-bit input: A data input
				B              => dsp1_b, -- 18-bit input: B data input
				C              => dsp1_c, -- 48-bit input: C data input
				CARRYIN        => dsp1_cin, -- 1-bit input: Carry input signal
				D              => (others=> '0'), -- 25-bit input: D data input
				-- Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
				CEA1           => '1', -- 1-bit input: Clock enable input for 1st stage AREG
				CEA2           => '1', -- 1-bit input: Clock enable input for 2nd stage AREG
				CEAD           => '0', -- 1-bit input: Clock enable input for ADREG
				CEALUMODE      => '1', -- 1-bit input: Clock enable input for ALUMODE
				CEB1           => '1', -- 1-bit input: Clock enable input for 1st stage BREG
				CEB2           => '1', -- 1-bit input: Clock enable input for 2nd stage BREG
				CEC            => '1', -- 1-bit input: Clock enable input for CREG
				CECARRYIN      => '1', -- 1-bit input: Clock enable input for CARRYINREG
				CECTRL         => '1', -- 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
				CED            => '0', -- 1-bit input: Clock enable input for DREG
				CEINMODE       => '1', -- 1-bit input: Clock enable input for INMODEREG
				CEM            => '1', -- 1-bit input: Clock enable input for MREG
				CEP            => '1', -- 1-bit input: Clock enable input for PREG
				RSTA           => '0', -- 1-bit input: Reset input for AREG
				RSTALLCARRYIN  => '0', -- 1-bit input: Reset input for CARRYINREG
				RSTALUMODE     => '0', -- 1-bit input: Reset input for ALUMODEREG
				RSTB           => '0', -- 1-bit input: Reset input for BREG
				RSTC           => '0', -- 1-bit input: Reset input for CREG
				RSTCTRL        => '0', -- 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
				RSTD           => '0', -- 1-bit input: Reset input for DREG and ADREG
				RSTINMODE      => '0', -- 1-bit input: Reset input for INMODEREG
				RSTM           => '0', -- 1-bit input: Reset input for MREG
				RSTP           => '0' -- 1-bit input: Reset input for PREG
			);

		-- Second DSP: sums the ad and bd terms, and adds the accumulator output to the (ac+bd) and (ad-bc)
		-- terms, with guard bits to allow for overflow detection.
		dsp2 : DSP48E1
			generic map (
				-- Feature Control Attributes: Data Path Selection
				A_INPUT            => "DIRECT", -- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
				B_INPUT            => "DIRECT", -- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
				USE_DPORT          => FALSE, -- Select D port usage (TRUE or FALSE)
				USE_MULT           => "MULTIPLY", -- Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
				USE_SIMD           => "ONE48", -- SIMD selection ("ONE48", "TWO24", "FOUR12")
				-- Pattern Detector Attributes: Pattern Detection Configuration
				AUTORESET_PATDET   => "NO_RESET", -- "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH"
				MASK               => X"3fffffffffff", -- 48-bit mask value for pattern detect (1=ignore)
				PATTERN            => X"000000000000", -- 48-bit pattern match for pattern detect
				SEL_MASK           => "MASK", -- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2"
				SEL_PATTERN        => "PATTERN", -- Select pattern value ("PATTERN" or "C")
				USE_PATTERN_DETECT => "NO_PATDET", -- Enable pattern detect ("PATDET" or "NO_PATDET")
				-- Register Control Attributes: Pipeline Register Configuration
				ACASCREG           => 0, -- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
				ADREG              => 1, -- Number of pipeline stages for pre-adder (0 or 1)
				ALUMODEREG         => 1, -- Number of pipeline stages for ALUMODE (0 or 1)
				AREG               => 0, -- Number of pipeline stages for A (0, 1 or 2)
				BCASCREG           => 0, -- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
				BREG               => 0, -- Number of pipeline stages for B (0, 1 or 2)
				CARRYINREG         => 1, -- Number of pipeline stages for CARRYIN (0 or 1)
				CARRYINSELREG      => 1, -- Number of pipeline stages for CARRYINSEL (0 or 1)
				CREG               => 1, -- Number of pipeline stages for C (0 or 1)
				DREG               => 1, -- Number of pipeline stages for D (0 or 1)
				INMODEREG          => 1, -- Number of pipeline stages for INMODE (0 or 1)
				MREG               => 1, -- Number of multiplier pipeline stages (0 or 1)
				OPMODEREG          => 1, -- Number of pipeline stages for OPMODE (0 or 1)
				PREG               => 1 -- Number of pipeline stages for P (0 or 1)
			)
			port map (
				-- Cascade: 30-bit (each) output: Cascade Ports
				ACOUT          => open, -- 30-bit output: A port cascade output
				BCOUT          => open, -- 18-bit output: B port cascade output
				CARRYCASCOUT   => open, -- 1-bit output: Cascade carry output
				MULTSIGNOUT    => open, -- 1-bit output: Multiplier sign cascade output
				PCOUT          => open, -- 48-bit output: Cascade output
				P              => dsp2_p, -- 48-bit output: Primary data output
				-- Control: 1-bit (each) output: Control Inputs/Status Bits
				OVERFLOW       => open, -- 1-bit output: Overflow in add/acc output
				PATTERNBDETECT => open, -- 1-bit output: Pattern bar detect output
				PATTERNDETECT  => open, -- 1-bit output: Pattern detect output
				UNDERFLOW      => open, -- 1-bit output: Underflow in add/acc output
				-- Data: 4-bit (each) output: Data Ports
				CARRYOUT       => open, -- 4-bit output: Carry output
				-- Cascade: 30-bit (each) input: Cascade Ports
				ACIN           => (others=> '0'), -- 30-bit input: A cascade data input
				BCIN           => (others=> '0'), -- 18-bit input: B cascade input
				CARRYCASCIN    => '0', -- 1-bit input: Cascade carry input
				MULTSIGNIN     => '0', -- 1-bit input: Multiplier sign input
				PCIN           => dsp1_pcout, -- 48-bit input: P cascade input
				-- Control: 4-bit (each) input: Control Inputs/Status Bits
				ALUMODE        => "0001", -- 4-bit input: ALU control input:
				CARRYINSEL     => "000", -- 3-bit input: Carry select input
				CLK            => clk, -- 1-bit input: Clock input
				INMODE         => "00000", -- 5-bit input: INMODE control input
				OPMODE         => dsp2_opmode, -- 7-bit input: Operation mode input
				-- Data: 30-bit (each) input: Data Ports
				A              => dsp2_ab(47 downto 18), -- 30-bit input: A data input
				B              => dsp2_ab(17 downto 0), -- 18-bit input: B data input
				C              => dsp2_c, -- 48-bit input: C data input
				CARRYIN        => dsp2_cin, -- 1-bit input: Carry input signal
				D              => (others=> '0'), -- 25-bit input: D data input
				-- Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
				CEA1           => '0', -- 1-bit input: Clock enable input for 1st stage AREG
				CEA2           => '0', -- 1-bit input: Clock enable input for 2nd stage AREG
				CEAD           => '0', -- 1-bit input: Clock enable input for ADREG
				CEALUMODE      => '1', -- 1-bit input: Clock enable input for ALUMODE
				CEB1           => '0', -- 1-bit input: Clock enable input for 1st stage BREG
				CEB2           => '0', -- 1-bit input: Clock enable input for 2nd stage BREG
				CEC            => '1', -- 1-bit input: Clock enable input for CREG
				CECARRYIN      => '1', -- 1-bit input: Clock enable input for CARRYINREG
				CECTRL         => '1', -- 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
				CED            => '0', -- 1-bit input: Clock enable input for DREG
				CEINMODE       => '1', -- 1-bit input: Clock enable input for INMODEREG
				CEM            => '1', -- 1-bit input: Clock enable input for MREG
				CEP            => '1', -- 1-bit input: Clock enable input for PREG
				RSTA           => '0', -- 1-bit input: Reset input for AREG
				RSTALLCARRYIN  => '0', -- 1-bit input: Reset input for CARRYINREG
				RSTALUMODE     => '0', -- 1-bit input: Reset input for ALUMODEREG
				RSTB           => '0', -- 1-bit input: Reset input for BREG
				RSTC           => '0', -- 1-bit input: Reset input for CREG
				RSTCTRL        => '0', -- 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
				RSTD           => '0', -- 1-bit input: Reset input for DREG and ADREG
				RSTINMODE      => '0', -- 1-bit input: Reset input for INMODEREG
				RSTM           => '0', -- 1-bit input: Reset input for MREG
				RSTP           => '0' -- 1-bit input: Reset input for PREG
			);

		dsp_proc: process(clk)
		begin
			if rising_edge(CLK) then
				-------------
				-- CLOCK 1 - sign-corrected data is clocked into the DSP1 A & B registers, and we register sign and zero flags
				-------------

				-- We need to compensate for these sign inversions so the result have the correct sign
				-- z = (Sa*a*Sc*c - Sa*b*Sc*d) + j(Sa*a*Sc*d + Sa*b*Sc*c) = SaSc(ac-bd) + jSaSc(ad+bc) = SaSc[(ac-bd) +j(ad+bc)]
				-- if both a and c are positive (Sa=Sc=1), nothing is negated, and the result has the right sign
				-- if both a and c are negative (Sa=Sc=-1), all of a,b,c and c are therefore negated, so the result has the right sign. No need to invert the result.
				-- if either a or c is negative Sa=1 & Sc=-1 or Sa=-1 and Sc=1, then we need to invert the result.
				-- neg indicates whether this sign inversion is needed. The inversion will be done by the DSP ALU unit if needed.
				--
				-- Also, to compensate for the sign inversion of the real part of the result, we actually compute -(*X)(*Y).
				-- We therefore invert to negate signal the result.
				b1_neg <= b1(4);
				d1_neg <= d1(4);
				neg1 <= not (a(3) xor c(3));

				-- x = A | B
				-- y = C | D
				-- P = AC | AD+BC | BD
				a1_zero <= to_std_logic(a=0);
				b1_zero <= to_std_logic(b=0);
				c1_zero <= to_std_logic(c=0);
				d1_zero <= to_std_logic(d=0);


				-------------
				-- CLOCK 3: Register the  saturation flags based on the ram output while that output is registered in DSP2.C
				-- The flags will be used to force saturation of the sum output.
				-------------


				dsp2_c_re_sign3 <= ram_dout(i)(35); -- register the real part sign bit
				re_sat3 <= to_std_logic( first_frame2 ='0' and (
					ram_dout(i)(35 downto 18) = "011111111111111111" or
				    ram_dout(i)(35 downto 18) = "100000000000000000"));

				dsp2_c_im_sign3 <= ram_dout(i)(17); -- register the imaginary part sign bit
				im_sat3 <= to_std_logic(first_frame2 ='0' and (
					ram_dout(i)(17 downto 0) = "011111111111111111" or
					ram_dout(i)(17 downto 0) =	"100000000000000000"));

				-------------
				-- CLOCK 4: Register the post-accumulation result in DSP2.P
				-------------

				-- pipeline the sign bits
				dsp2_c_re_sign4 <= dsp2_c_re_sign3;
				dsp2_c_im_sign4 <= dsp2_c_im_sign3;
				-- pipeline the pre-accumulation saturation flags
				re_sat4 <= re_sat3;
				im_sat4 <= im_sat3;
				dsp2_ab_im_sign4 <= dsp2_ab(47); -- register the AB sign bit


			end if; -- clk
		end process dsp_proc;

				-----------------------------------------------
		-- Saturate accumulated sum before storing it into the RAM
		-- This implies combinatorial logic between the DSP P output and the FIFO/BRAM inputs
		ram_din(i)(35 downto 18) <= -- Real part
			"011111111111111111" when (re_sat4='1' and dsp2_c_re_sign4='0') or (dsp2_p(26)='1' and dsp2_p(27)='0') else
			"100000000000000000" when (re_sat4='1' and dsp2_c_re_sign4='1') or (dsp2_p(26)='0' and dsp2_p(27)='1') else
			dsp2_p(26 downto 9);

		ram_din(i)(17 downto 0) <= -- Imaginary part
			"011111111111111111" when (im_sat4='1' and dsp2_c_im_sign4='0') or (dsp2_c_im_sign4='0' and dsp2_ab_im_sign4='0' and dsp2_p(47)='1') else
			"100000000000000000" when (im_sat4='1' and dsp2_c_im_sign4='1') or (dsp2_c_im_sign4='1' and dsp2_ab_im_sign4='1' and dsp2_p(47)='0') else
			dsp2_p(47 downto 30);


	end generate dsp_gen;

    -----------------------------
	-- RAM blocks
	-----------------------------
	-- We have 1 block for each 2 CMUL since ultraRAM bus width is fixed at 72 bits, so we can
	-- store two (18+18) bit products for each ram.

	ram_gen: for i in 0 to P/2 - 1 generate
			signal ram_din_word: std_logic_vector(71 downto 0);
			signal ram_dout_word: std_logic_vector(71 downto 0);
			constant MEM_TYPE: string := sel(i < URAM_MAX, "utra", "block");
	begin
        -- combine the din from 2 CMAC in to the ram din
		ram_din_word <= ram_din(2*i) & ram_din(2*i+1);
        -- Split ram dout into 2 dout for the CMAC
		ram_dout(2*i) <= ram_dout_word(71 downto 36);
		ram_dout(2*i+1) <= ram_dout_word(35 downto 0);

        -- Implement RAM for a pair of CMACs.
        -- For URAM,
        --   LATENCY=2 and write_mode=write_first gives the error: [Synth 8-6058] Synth Error: [XPM_MEMORY 40-9] READ_LATENCY_B (2) specifies fewer than 3 stages, but simple dual port RAM configurations targeting UltraRAM and using write-first mode for port B must use a read latency of at least 3 for port B.   ["/tools/Xilinx/Vivado/2022.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv":588]
        --   LATENCY=2 and write mode=read_first works.
	   	ram0 : xpm_memory_sdpram
		   	generic map (
		      MEMORY_PRIMITIVE => MEM_TYPE,      -- force the use of UltraRAM ("ultra") or Block RAM ("block")
                -- write bus A
		      ADDR_WIDTH_A => 12,               -- 4k (12 bits) per URAM
		      WRITE_DATA_WIDTH_A => 72,        -- 2 x (18+18) bits wide write bus
		      BYTE_WRITE_WIDTH_A => 72,          -- We use 8-bit-wide-byte-enabled write, i.e. we have 8 byte enable bits
                -- Read bus B
		      ADDR_WIDTH_B => 12,               -- same
		      READ_DATA_WIDTH_B => 72,         -- 2 x (18+18) bits wide read bus
		      MEMORY_SIZE => 72 * 4096,         -- 72-bit word * 4096 words = 1 x URAM288 or 8 x RAMB36 (72 x 512 each)
		      READ_LATENCY_B => 2,     -- Needs to be >= of cascade height to allow registering. Synthesis ask for more than 4 to have full pipelining (4 is partial).
		      SIM_ASSERT_CHK => 1,             -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
		      --USE_EMBEDDED_CONSTRAINT => 0,    -- DECIMAL
		      WRITE_MODE_B => "read_first",     -- URAM is either read_first or write_first. Need read_first to allow a latency of 2.
		      WRITE_PROTECT => 1               -- DECIMAL
			)
			port map (
				-- Write port
				dina => ram_din_word,
				addra => ram_wr_addr,
				ena => ram_wr_en,
				wea => "1",

				-- read port
				doutb => ram_dout_word,
				addrb => ram_rd_addr,
				enb => ram_rd_en,

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

	end generate ram_gen;


--ready <= '1' when (m_axis_z_out_tvalid='0' or m_axis_z_out_tready='1') and last_byte='1' and (z_in_done='1' or CASCADED=FALSE) else '0';



end impl;

