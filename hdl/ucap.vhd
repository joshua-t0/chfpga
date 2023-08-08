----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/24/2023 01:33:49 PM
-- Design Name: 
-- Module Name: ucap - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


--! Standard libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--use IEEE.std_logic_misc.ALL; -- for and_reduce

library UNISIM;
use UNISIM.vcomponents.all;

library xpm;
use xpm.vcomponents.all;

--! Project libraries
use work.chFPGA_Package.all; --! Get all component definitions

-- ucap: UltraRAM-based raw data capture engine
--
-- `ucap` allows the capture of raw ADC data frames, where a frame is 16384 x 16-bit samples provided 8 sample at a time.
-- `ucap` can store 2 frames for all 8 channels, 4 frames for 4 selected channels, 8 frames for 2 selected channels, or 16 frames for 1 selected channel.
--  Frames are captured Every N frames.

entity ucap is
	generic (
	    NUMBER_OF_CHANNELS: integer := 8; -- Warning: current design works only with NUMBER_OF_CHANNELS = 8
	    NUMBER_OF_SOURCES : integer := 2; -- Warning; current design works only with NUMBER_OF_SOURCES = 2

	    ADC_BITS_PER_SAMPLE: integer;
        ADC_SAMPLES_PER_WORD: integer;
        ADC_SAMPLES_PER_FRAME: integer;
        SIM: boolean := FALSE
	);
    port ( 
        -- Input data buses

        s_axis_tdata: in slv112_array(0 to NUMBER_OF_CHANNELS-1);
        s_axis_tvalid: in std_logic_vector(0 to NUMBER_OF_SOURCES - 1); -- common to all channels
        s_axis_tlast: in std_logic_vector(0 to NUMBER_OF_SOURCES - 1); -- common to all channels
--        s_axis_tuser: in std_logic_vector(0 to 0); -- bit 0: current source

        -- Remote mux control

        source_sel_out: out std_logic_vector(0 to NUMBER_OF_SOURCES - 1); -- data source request
        source_sel_in: in std_logic_vector(0 to NUMBER_OF_SOURCES - 1); -- curent data source on tdata

        -- Output data bus

        m_axis_bsb_tdata: out std_logic_vector(7 downto 0); -- 8-bit output bus
		m_axis_bsb_tvalid: out std_logic;
		m_axis_bsb_tlast: out std_logic;
		m_axis_bsb_tready: in std_logic := '1';
        bsb_clk: in std_logic;
        
        clk: in std_logic;
        rst: in std_logic; -- synchronous to clk

		-- BSB Control interface
		cmd_dat: in axis8_dat_struct := (TDATA=>(others=>'0'), TVALID=>'0', TLAST=>'0');
		cmd_rdy: out axis8_rdy_struct;
		rply_dat: out axis8_dat_struct;
		rply_rdy: in axis8_rdy_struct := (TREADY=>'0');
		ctrl_clk : IN std_logic := '0'; -- control clock
		ctrl_rst : in std_logic := '0'
        
    
    );
end ucap;

architecture Behavioral of ucap is

    subtype int8 is integer range 0 to NUMBER_OF_CHANNELS-1;
    type int8_array is array (NATURAL RANGE <>) of int8;



	signal control_bytes: slv8_array(0 to 8);
	signal status_bytes: slv8_array(0 to 0);


    signal mode: std_logic_vector(1 downto 0) := "11"; -- "00": 8-channel, "01": 4-channel, "10": 2-channel, "11": 1-channel
    signal chan_sel_map : u3_array(0 to 3) := ("000", "001", "010", "011");
    -- data rate ratio: 3000 Gsps * 2 bytes/sample * 2 frames/capture * 8 channel / 100 Mbyte readout = 960.
	signal base_period: u24_array(0 to NUMBER_OF_SOURCES-1); -- 2 frames * 16 bytes, 3000e6/16384 = 183105.46875 =1s, max period = 91.6s
    signal sub_period: unsigned(4 downto 0);
	signal user_reset, user_reset_reg: std_logic;

    signal chan_sel: u3_array(0 to NUMBER_OF_CHANNELS/2-1);        
    signal data_out: slv112_array(0 to NUMBER_OF_CHANNELS-1);
	signal ram_wr_addr, ram_rd_addr: slv12_array(0 to NUMBER_OF_CHANNELS-1);
	signal ram_din: slv112_array(0 to NUMBER_OF_CHANNELS-1);
	signal ram_dout: slv128_array(0 to NUMBER_OF_CHANNELS-1); -- one for each column;
	signal ram_wr_en: std_logic_vector(0 to NUMBER_OF_CHANNELS-1);  -- one for each row
--	signal ram_wr_byte_en: std_logic_vector(31 downto 0);  -- enable for each of the 32 bytes across the row
	signal ram_rd_en: std_logic_vector(0 to NUMBER_OF_CHANNELS-1);  -- one for each column
	signal wr_bank: std_logic; -- 2 banks
	signal overrun: std_logic;

	signal frame_max: unsigned(3 downto 0); -- currently limited to 16. Depends on memory depth (frames/uram block) x number of channels.
	signal readout_trig: std_logic_vector(0 to NUMBER_OF_CHANNELS-1); -- pulse indicating when a channel is ready to be readout
	signal capture_timestamp: u48_array(0 to NUMBER_OF_SOURCES-1);

	signal fifo_in_tdata: std_logic_vector(7 downto 0); 
	signal fifo_in_tvalid: std_logic;
	signal fifo_in_tlast: std_logic;
	signal fifo_full: std_logic;
	signal fifo_overflow: std_logic;
	signal fifo_overflow_sticky: std_logic;

begin

	bsb_regs0: entity work.CTRL_SLAVE
		GENERIC MAP (
			DEFAULT_CONTROL_BYTES=> X"C8_1A" & to_slv(sel(SIM, 1024, 183105), 24),
			NUMBER_OF_CONTROL_BYTES => control_bytes'Length(1), -- Number of bits in the control word
			NUMBER_OF_STATUS_BYTES => status_bytes'Length(1) -- Number of bits in the status word.
		)
		PORT MAP(

			control_bytes => control_bytes,
			status_bytes => status_bytes,

			ctrl_cmd_in_dat=>   cmd_dat,
			ctrl_cmd_in_rdy=>   cmd_rdy,
			ctrl_rply_out_dat=> rply_dat,
			ctrl_rply_out_rdy=> rply_rdy,
			ctrl_clk => ctrl_clk,
			ctrl_rst => ctrl_rst
		);

	-- CONTROL byte 0 -1 : mode and channel selection

	mode            <= control_bytes(0)(7 downto 6); -- "00": 8-channel mode, "01": 4-channel, "10": 2-channel, "11": 1-channel
	chan_sel_map(1) <= unsigned(control_bytes(0)(5 downto 3));
	chan_sel_map(0) <= unsigned(control_bytes(0)(2 downto 0));

	user_reset      <= control_bytes(1)(7);
	chan_sel_map(3) <= unsigned(control_bytes(1)(5 downto 3));
	chan_sel_map(2) <= unsigned(control_bytes(1)(2 downto 0));

	-- CONTROL bytes 2-7: base capture period
	base_period(0) <= to_unsigned(control_bytes(2 to 4));
	base_period(1) <= to_unsigned(control_bytes(5 to 7));

	-- CONTROL bytes 8: capture subperiod
	sub_period <= unsigned(control_bytes(8)(4 downto 0));

	-- STATUS byte 0
	status_bytes(0)(0) <= fifo_overflow_sticky;
	status_bytes(0)(1) <= overrun;



    -- Generate 8 URAM buffers, each 16-byte wide (128 bit wide) x 4096 words
    -- Each buffers can store 2 frames. The buffers ca be used to store:
    --   2 frames from 8 channels (mode "00")
    --   4 frames from 4 channels (mode "01")
    --   8 frames from 2 channels (mode "10")
    --   16 frames from 1 channel (mode "11")
    --
	uram_gen: for i in 0 to NUMBER_OF_CHANNELS-1 generate
--			signal ram_dout_word: std_logic_vector(63 downto 0);
			signal ram_din_word: std_logic_vector(127 downto 0);
--			signal ram_wr_byte_en_word: std_logic_vector(7 downto 0);
		begin
--			ram_dout(col)(64*row + 63 downto 64*row) <= ram_dout_word;
            din_gen: for j in 0 to 7 generate
                   ram_din_word(16*j+15 downto 16*j) <= ram_din(i)(14*j+13 downto 14*j) & "00";
            end generate;	           
--			ram_din_word <= ram_din(64*col + 63 downto 64*col);
--			ram_wr_byte_en_word <= ram_wr_byte_en(8*col+7 downto 8*col);
		   	-- xpm_memory_sdpram: Simple Dual Port RAM
		   	-- Xilinx Parameterized Macro, version 2022.1
		   	-- UltraRAM primitive is organized as 4K x 72 bits
		   	-- Addr width: we use all the memory space. The uram is 2kx
		   	uram_cell_inst : xpm_memory_sdpram
			   	generic map (
			      MEMORY_PRIMITIVE => "ultra",      -- force the use of UltraRAM
                    -- write bus A
			      ADDR_WIDTH_A => 12,               -- 4k (12 bits) per URAM
			      WRITE_DATA_WIDTH_A => 128,        -- 8 byte (64 bits) wide write bus
			      BYTE_WRITE_WIDTH_A => 128,          -- We use 8-bit-wide-byte-enabled write, i.e. we have 8 byte enable bits
                    -- Read bus B
			      ADDR_WIDTH_B => 12,               -- same
			      READ_DATA_WIDTH_B => 128,         -- 8 byte (64 bits) wide read bus
			      --CASCADE_HEIGHT => 4,             -- We castade 4 URAM
			      --MEMORY_OPTIMIZATION => "true",   -- String
			      MEMORY_SIZE => 128 * 4096,         -- 128-bit word * 4096 words/URAM
			      --MESSAGE_CONTROL => 0,            -- DECIMAL
			      READ_LATENCY_B => 4,             -- Needs to be >= of cascade height to allow registering. Synthesis ask for more than 4 to have full pipelining (4 is partial).
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
					addra => ram_wr_addr(i),
					ena => ram_wr_en(i),
					wea => "1",

					-- read port
					doutb => ram_dout(i),
					addrb => ram_rd_addr(i),
					enb => ram_rd_en(i),

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

	end generate uram_gen;

    -- Write block: writes data to memory
    --
    -- External interfaces:
    --  - capture_timestamp: timestamp of the first frame of the capture
    --  - readout_trig: single pulse indicating that the memory can be readout
	wr_blk: block
		signal timestamp: u48_array(0 to NUMBER_OF_SOURCES-1);
		signal period_ctr: u24_array(0 to NUMBER_OF_SOURCES-1);

  		signal frame: u4_array(0 to NUMBER_OF_SOURCES-1); -- we count up to 16 frames in 1 channel mode (2 frames/memory block * 8 memory blocks)
		signal word_ctr: u11_array(0 to NUMBER_OF_SOURCES-1); -- Counts group of 8 samples. 14-3=11 bits (16k samples / 8 = 2k clocks/frame). 
  	    signal capture_en: std_logic_vector(0 to NUMBER_OF_SOURCES-1);
        signal mux_mode: std_logic;
	begin

	    wr_proc: process(clk)
	        variable sel_i: int8;        
		    variable tvalid: std_logic_vector(0 to NUMBER_OF_SOURCES-1); -- word currently on the bus shall be stored
		    variable src: integer range 0 to NUMBER_OF_SOURCES-1;
            variable capture_trig: std_logic_vector(0 to NUMBER_OF_SOURCES-1);
            variable N: integer; -- number of captured channels in current mode
            variable K: integer; -- number of memory blocks per channel in current mode
            variable K_WIDTH: integer; -- number of bits needed to represent the memory block for each channel
            constant FRAMES_PER_BLOCK: integer := 2; -- number of frames that can be stored by each memory block. *Do not change: This parameter is implicitely hardcoded in some logic such as the memory enable and memory address.
	    begin
	        if rising_edge(clk) then

	        	-- Register user reset
	            user_reset_reg <= user_reset;

	            -- Generate capture trigger (capture_trig(i))  for each sources
	            --
	            -- These triggers are generated continuously in parallel, independent of which source is selected, 
	            -- so we can keep track of the frame number
	            --
	            -- capture_trig(i) is active high when the first word of the first frame of a captue burst is currently present on the bus. 
--	        	for i in 0 to NUMBER_OF_SOURCES-1 loop
--	        		if s_axis_tuser(i) = '1' then -- true on the last word of every frame
--	        			timestamp(i) <= timestamp(i) + 1;
--	        			period_ctr(i) <= period_ctr(i) + 1;
--	        			if period_ctr(i) = base_period(i) then
--	        				period_ctr(i) <= (others => '0');
--	        			end if;
--	        			capture_trig(i) := '0';
--	        			if all_zeros(period_ctr(i)(to_integer(sub_period) downto 0)) then
--	        				capture_trig(i) := '1';
--	        			end if;
--	        		end if;
--	        	end loop; -- source

	            -- for i in 0 to 7 loop
	            --    m_axis_tdata(i) <= ram_dout(i)(111 downto 0);
	            --end loop;
	        	for src in 0 to NUMBER_OF_SOURCES-1 loop
		            tvalid(src) := '0';
--		            readout_trig(src) <= '0'; -- single clock pulse signal, overriden below
					if s_axis_tvalid(src)='1' then
						tvalid(src) := capture_en(src);
						word_ctr(src) <= word_ctr(src) + 1;
						if s_axis_tlast(src) = '1' then
							word_ctr(src) <= (others => '0');
							frame(src) <= frame(src) + 1;
							period_ctr(src) <= period_ctr(src) + 1;
							timestamp(src) <= timestamp(src) + 1;
							if frame(src) = frame_max then
	                            frame(src) <= (others => '0');
								capture_en(src) <= '0';
								-- Pulse the readout_trig bit for each channel who has this source selected
                                for i in 0 to NUMBER_OF_CHANNELS-1 loop
                                    if to_integer(to_unsigned(source_sel_in(i))) = src then
           								readout_trig(i) <= capture_en(src);
           						    end if;
           						end loop;
							end if;
							if period_ctr(src) = base_period(src) or all_ones(period_ctr(src)(to_integer(sub_period) downto 0)) then
								capture_en(src) <= '1'; 
	                            frame(src) <= (others => '0');
								period_ctr(src) <= (others => '0');
								capture_timestamp(src) <= timestamp(src) + 1; -- reuse earlier timestamp+1 logic
							end if;
						end if;                
					end if;

					if rst = '1' or user_reset_reg = '1' then
                        -- block-local signals
						word_ctr(src) <= (others => '0');
						capture_en(src) <= '1'; -- capture the first frame coming out of reset
						frame(src) <= (others => '0');
						period_ctr(src) <= (others => '0');
	                    timestamp(src) <= (others => '0'); -- needed for the first frame header
                        -- external signals under the control of this block
	                    readout_trig(src) <= '0';
	                    capture_timestamp(src) <= (others => '0'); -- needed if we reset with capture_en=1
					end if; --rst
				end loop; -- source

	            -- The muxing of the input data to the data buffers is done
	            -- with a 4-channel mux modified with an additional 2:1 mux to allow
	            -- the odd buffer to use the corresponding data input
	            -- directly.  This mux allows us to implement all other modes.
	            -- 
	            -- This mux logic selects the following:
	            --    - Even buffers (i = 0,2,4,6) can select any of the 8 input, as described in chan_sel(i/2)
	            --    - Odd buffers (i = 1,3,5,7) can select either the corresponding input (i) (mux_mode=0) or the same data as the even buffer (mux_mode=1)
	            --  8 channels mode: mux_mode=0. chan_sel(i) = i/2. We ignore the selection map. Buffers 0-7 : input 0-7
	            --  4 channels mode: mux_mode=1. Buffers 0-1: chan_sel(0), 2-3: chan_sel(1), 4-5: chan_sel(2), 6-7: chan_sel(3).  
	            --  2 channelw mode: mux_mode=1. Buffers 0-3: chan_sel(0), 4-7: chan_sel(1). 
	            --  1 channel mode: mux_mode=1. Buffers 0-7: chan_sel(0) 
				--
				-- The synthesizer is not smart
				-- enough to know that the 8-channel mode can be implemented with properly
				-- selected chan_sel() values, and it we tell it that it should use the inputs directly, it will infer additional 2:1 muxes to bypass the 8:1 mux.
				--
				-- For the 2- or 1- channel mode, the logic provide more
				-- flexibility than needed, but trying to exploit that in
				-- hardware also results in more muxes.
				--
				-- Consequently, we explicitely describe a simple
				-- modified 4-channel-mode core and pre-process the control signals on the 4-channel mode muxes to get the desired functional mode. 
				-- 
				-- This uses half the resources compared to a blunt muxing of
				-- all 8 buffer inputs, which is overkill (we don't want to
				-- chose the order of the channels or select channels
				-- multiple times). The modified 4-channel mux is still
				-- over-flexible , which suggests we might still be using
				-- more logic than necessary, but so far we have not found a
				-- way to make it smaller. This is good enough.

	            -- Prepare the input muxing signals to simplify the control lines that will go into the large input muxing network  
--	           	ram_wr_addr <= frame(0) & std_logic_vector(word_ctr); -- 14-3 bits + 1 bit = 12 bits, 4k words/URAM
	          	ram_wr_en <= (others => '0'); -- overriden below to select which buffer is write-enabled depending on the mode and frame number
	            if mode = "00" then -- 8 channel mode
                    N := 8; -- capturing 8 channels
                    K := NUMBER_OF_CHANNELS / N; -- 2 memory blocks per channel
                    -- Setup the input channel muxes
                    mux_mode <= '0'; -- force selection of same channel for odd buffers
                    for i in 0 to NUMBER_OF_CHANNELS/2-1 loop -- set the input source for each channel pair
                        chan_sel(i) <= to_unsigned(2*i/K, 3); -- force selection of same channel for even buffers. Ignore user selection map.
                    end loop;
                    -- Set the maximum frame number per channel
                    frame_max <= to_unsigned(FRAMES_PER_BLOCK*K-1, 4); -- mode 0: 2 frames

                    -- Set the RAM address and enable lines
                    for i in 0 to NUMBER_OF_CHANNELS-1 loop -- For each channel 
                        sel_i := i;
                        src := to_integer(to_unsigned(source_sel_in(sel_i))); -- data source associated ith the channel
                        ram_wr_en(i) <= tvalid(src); -- 
                        ram_wr_addr(i) <= frame(src)(0) & std_logic_vector(word_ctr(src)) ; -- 1  bit + (14-3) bits = 12 bits, 4k words/URAM
                        -- Generate the ram readout triggers signals based on the channel triggers, mode and mux settings
                        if readout_trig(sel_i) = '1' then
                            ram_readout_trig(i) <= not ram_readout_trig(i);
                        end if;
                    end loop;

                else -- 2-, 4-, or 8-channel modes

                    -- Derive the basic readoit parameters
                    if mode = "01" then
                        N := 4; -- capturing 4 channels
                    elsif mode = "10" then
                        N := 2; -- capturing 2 channels
                    else
                        N := 1; -- capturing 1 channel
                    end if;
                    K := NUMBER_OF_CHANNELS / N; -- memory blocks per channel (2 in mode 1, 4 in mode 2, 8 in mode 3)
                    K_WIDTH := integer_log2(K); -- Number of bits to represent the block number (1 in mode 1, 2 in mode 2, 3 in mode 3)
                    
                    
                    -- Set the source for each channel-pair mux
                    --   mode 1: (map(0), map(1), map(2), map(3)), 
                    --   mode 2: (map(0), map(0), map(1), map(1)), 
                    --   mode 3: (map(0), map(0), map(0), map(0))
                    mux_mode <= '1'; -- Odd buffer use the same channel as even buffer 
                    for i in 0 to NUMBER_OF_CHANNELS/2-1 loop -- one mux per channel pair
                        chan_sel(i) <= chan_sel_map(2*i/K); 
                    end loop;

                    -- Set the maximum frame number stored for each channel
                    frame_max <= to_unsigned(FRAMES_PER_BLOCK*K-1, 4); -- mode 1: 4 frames, mode 2: 8 frames, mode 3: 16 frames   

                    -- Set the memory enable and address
                    for i in 0 to N-1 loop -- 4 groups of 2 channels
                        sel_i := to_integer(chan_sel_map(i)); -- integer representation of user-selected selected channel number
                        src := to_integer(to_unsigned(source_sel_in(sel_i))); -- integer representation of the source for that channel
                        -- Enable the one memory block to that will receive the data for each channel
                        -- based on the current frame number
                        ram_wr_en(K*i + to_integer(frame(src)(K_WIDTH downto 1))) <= tvalid(src); 
                        -- Set the write address for the memory blocks for each channel. 
                        -- All blocks have the same address, but only one was enabled above.
                        -- The address depends on the word counter and the last bit of the frame counter (since there are 2 frames per memory) 
                        ram_wr_addr(K*i to K*(i+1)-1) <= (others => frame(src)(0) & std_logic_vector(word_ctr(src))); -- 14-3 bits + 1 bit = 12 bits, 4k words/URAM
                        if readout_trig(sel_i) = '1' then
                            ram_readout_trig(K*i to K*(i+1)-1) <= not ram_readout_trig(K*i to K*(i+1)-1);
                        end if;
                    end loop;
    
                end if;
		  
	            -- Mux the 8 input channels to the 8 buffers.
	            --
	            -- The code is optimized to minimize resources. Muxing logic handles pair of buffers. We need:
	            --    even buffers: 112*4 x  8:1 muxes (8:1 muxes = 2x LUT8 + F7= 4 mux/CLB, 448 x 8:1 muxes = 112 CLBs)
	            --    odd buffers: 112*4 x  2:1 muxes (2:1 mux = 1x LUT3 = 16 mux/CLB,  448x 2:1 muxes = 28 CLBs )
	            --  We confirm this design uses 896 LUT6 + 448 LUT3, 448 F7)
	            --
   	            -- Resource utlisation notes
	            -- 	mode 8 only (baseline), full muxing: 28 CLB x 8 = 224 CLB, 8*28*8 = 1792 LUTs with 112*8 F7s
	            -- 	M8 + M4: 230 CLBs, 1833 LUTs
	            -- 	M8+M4+M2+M1: want to use 2525 LUTs

	            for i in 0 to 3 loop
		           sel_i := to_integer(unsigned(chan_sel(i)));

	               if mux_mode = '0' then -- Assign input channel x to buffer x
	                   ram_din(2*i)(111 downto 0) <= s_axis_tdata(sel_i); -- When mux_mode=0, chan_sel(i) is forced to 2*i. We don't assign the input directly becasue the synthesizer would infer an additional mux, which is redundant.
	                   ram_din(2*i+1)(111 downto 0) <= s_axis_tdata(2*i+1);
	               else -- Select the same even and odd input channel for each buffer pair  
	                   ram_din(2*i)(111 downto 0) <= s_axis_tdata(sel_i);
	                   ram_din(2*i+1)(111 downto 0) <= s_axis_tdata(sel_i);
	               end if;
	            end loop;

	            end if; --clk
	    end process;
	end block wr_blk;


	-- Read and stream out
	----------------------
	rd_blk: block
        -- byte counter
        --   18:15: frame number( 4 bits, 16 frames/capture,  counts both frame and channels. We always have a total of 16 frames from 1, 2,4, or 8 channels.)
        --   14:4: word number (11 bits, 16384/8=2048 words)
		--   3:0: byte number (4 bits, 16 bytes/word)
		signal byte_ctr: unsigned(18 downto 0);  -- counts byte, word, frame and channel for the read sequencer
		signal pkt_ctr: unsigned(5 downto 0);  -- counts packets (frame part, frame and channel) for the read processor
        signal byte: unsigned(3 downto 0); -- counts byted in the read processor 

		type SEND_STATE_TYPE IS (
		    SEND_WAIT,
		    SEND_HEADER,
		    SEND_DATA);
		signal send_state: SEND_STATE_TYPE;

		-- Header bytes & counter
		signal header_byte_ctr: integer range 0 to FRAME_HEADER_BYTE_LENGTH; -- counts header bytes in the read sequencer
        
        -- signals to send to the RAM data processor when it comes out of RAM after the read latency
        constant RAM_LATENCY: integer := 4;
        signal header_tvalid: std_logic_vector(RAM_LATENCY downto 0);
        signal data_tvalid: std_logic_vector(RAM_LATENCY downto 0);
        signal data_tlast: std_logic_vector(RAM_LATENCY downto 0);

	begin

            
	    wr_proc: process(clk)
		    variable frame_header: FRAME_HEADER_STRUCT;
            variable chan_int: integer range 0 to 7;
            variable chan_sel_int: integer range 0 to 3;
            variable byte_int: integer range 0 to 15;
		    variable frame_header_bytes: slv8_array(0 to FRAME_HEADER_BYTE_LENGTH-1); 
		    variable timestamp_incr: unsigned(3 downto 0);

	    begin


	        if rising_edge(clk) then


		    	ram_rd_addr <= std_logic_vector(byte_ctr(15 downto 4));
		    	ram_rd_en <= (others => '0'); -- the active read line will be overriden below

                header_tvalid <= shift_right(header_tvalid, 1); -- '0' inserted on the left, overriden below
                data_tvalid <= shift_right(data_tvalid, 1);
                data_tlast<= shift_right(data_tlast, 1);

                -- detect overrun, i.e. we are asked to start a new readout before the previous one is finished
                if send_state /= SEND_WAIT and readout_trig='1' then
                	overrun <= '1';
                end if;

                -- RAM Read sequencer
                --
                -- The following state machine drives the readout process by generating the RAM read addresses and sending out signals to the next stage on what to do when the data arrives a few clocks later. 
                -- We use fifo_full signal to throttle the machine. Since we have tvalids in the delay pipeline, we stop writing too late. 
                -- The full threshold MUST be set so the fifo can accomodate a few extra writes after fifo_full is raised
	            case send_state is
	            	when SEND_WAIT =>
	            		-- data_tvalid =0, header_tvalid = 0, data_tlast = x.
                        header_byte_ctr <= 0;
	            		if readout_trig='1' then
                        	--data_tlast(data_tlast'LEFT) <= '1'; -- clear pkt_ctr
                            send_state <= SEND_HEADER;
	            		end if;
                    when SEND_HEADER =>
	                    if fifo_full='0' then  
	                        header_tvalid(header_tvalid'LEFT) <= '1';
	                        header_byte_ctr <= header_byte_ctr + 1;
	                        if header_byte_ctr = FRAME_HEADER_BYTE_LENGTH-1 then -- if this is the last header byte.
                          		 data_tlast(data_tlast'LEFT) <= '1'; -- signal last byte of header (not end of packet)
                                 header_byte_ctr <= 0; -- get ready for the next time we get here
	                             send_state <= SEND_DATA; -- start sending the data
	                        end if;
	                    end if; -- if header fifo & send_delay & dest_ready
	                when SEND_DATA =>
	                    if fifo_full='0' then
	                        byte_ctr <= byte_ctr + 1;
	                        data_tvalid(data_tvalid'LEFT) <= '1';
                            -- Pulse the RAM rd_en only on byte 0 to save power
                            if byte_ctr(3 downto 0) = 0 then
                                chan_int := to_integer(byte_ctr(18 downto 16));
                		    	ram_rd_en(chan_int) <= '1'; -- read only when ready to save power 
                            end if;
                            if signed(byte_ctr(12 downto 0))= -1 then -- every 512 words x 16 bytes = 8K
                                send_state <= SEND_HEADER;
                        		data_tlast(data_tlast'LEFT) <= '1';
                            end if;

                            if signed(byte_ctr) = -1 then -- if End of transmission
                        		data_tlast(data_tlast'LEFT) <= '1'; -- redundant, but for clarity
    	                        header_tvalid(header_tvalid'LEFT) <= '1'; -- signal end of transmission (increment timestamp)
                                byte_ctr <= (others => '0');
                                send_state <= SEND_WAIT;
                            end if;
    	                end if; -- HEADER or DATA ready to be sent
	            end case;

	            -- Prepare the frame information. 
	            -- The header info is used in the data processor machine below. 
	            -- The signals used to build the header (high bits of byte_ctr, timestamp) changes with the RAM read address, 
	            -- i.e. a few clocks before the frame header data it is actually used.
	            -- Since we  have plenty of data to send before the next header is processed, 
	            -- but we have finished reading the header well before its value changes again.
	            frame_header.PROBE_ID := X"A0";
	            frame_header.PROBE_ID(0) := '0'; -- current_source(0);
	            --frame_header.STREAM_ID := "0000000000" & std_logic_vector(pkt_ctr); --stream_id;
	            frame_header.SERIAL_FLAGS := "0000"; -- serial_flags(2 downto 0) & in_dat(source).TUSER(TUSER_SERIAL_FLAGS_BIT);
	            frame_header.FLAGS := mode & std_logic_vector(pkt_ctr(1 downto 0)); --mode and subframe number;
	            -- Override the capture flag withthe overflow flags so we know  from the packet header if somewhing is amiss with the stream
	            --frame_header.FLAGS(TUSER_CAPTURE_BIT) := data_fifo_overflow_sticky or header_fifo_overflow_sticky;
	            frame_header.TIMESTAMP := std_logic_vector(capture_timestamp);
	            -- Set the STREAM ID. Format is: 4-bit frame , 4-bit crate, 4-bit slot, 4-bit channel
				frame_header.STREAM_ID := (others => '0');
	            case mode is
	                when  "00" => -- 8 channel mode (pkt ctr = 3 bit chan, 1 bit seq, 2 bit subframe)
			            frame_header.STREAM_ID(12) := pkt_ctr(2);
			            frame_header.STREAM_ID(2 downto 0) := std_logic_vector(pkt_ctr(5 downto 3));
	                when "01" => -- 4-channel mode   (pkt ctr = 2 bit chan, 2 bit seq, 2 bit subframe)
			            frame_header.STREAM_ID(13 downto 12) := std_logic_vector(pkt_ctr(3 downto 2));
			            frame_header.STREAM_ID(2 downto 0) := chan_sel(to_integer(pkt_ctr(5 downto 4)));
	                when "10" => -- 2-channel mode (pkt ctr = 1 bit chan, 3 bit seq, 2 bit subframe)
			            frame_header.STREAM_ID(14 downto 12) := std_logic_vector(pkt_ctr(4 downto 2));
			            frame_header.STREAM_ID(2 downto 0) := chan_sel(to_integer(pkt_ctr(5 downto 5)));
	                when "11" => -- 1-channel mode (pkt ctr =  4 bit seq, 2 bit subframe)
			            frame_header.STREAM_ID(15 downto 12) := std_logic_vector(pkt_ctr(5 downto 2));
			            frame_header.STREAM_ID(2 downto 0) := chan_sel(0);
                    when others =>
                        assert False report "Unhandled mode";
	            end case;		        
                -- Convert to an array of bytes
	            frame_header_bytes := struct_to_bytes(frame_header);

                -- RAM data processor
                --
                -- This logic processes words coming out of RAM after the read latency period.
                -- The processing is based on control signals sent by the read sequencer and delayed to arrive at the same time as the data. 
                -- The control signals are:
                --    - header_tvalid(0) HV: Send a header byte. A 0 to 1 transition indicates a new header. 
                --    - data_tvalid(0) DV: Send RAM data
                --    - data_tlast(0): L This is the last byte of a group
                -- Processing operations
                --      DV HV L
                --      0 0 X : NOP
                --      0 1 0: Send header byte, byte +=1 
                --      0 1 1: Send last header byte, byte =0 
                --      1 X 0: Send data byte, byte += 1 
                --      1 0 1: Send last data byte, byte=0, pkt+=1
                --      1 1 1: Send last data byte of last packet, byte=0, pkt=0
                -- 
                fifo_in_tvalid <= '0';
                fifo_in_tlast <= '0';
                
                -- Send the data as per the instructions from the control signals
                if  data_tvalid(0) = '0' and header_tvalid(0) = '1' then
                    byte_int := to_integer(byte); -- Read in natural array order
                    fifo_in_tdata <= frame_header_bytes(byte_int);
                    fifo_in_tvalid <= '1';
                    byte <= byte + 1;
                    if data_tlast(0) = '1' then
                        byte <= (others => '0');
                    end if;
                elsif data_tvalid(0) = '1' then
                    -- get the right byte from the right data buffer
                    -- The logic implies a combinatorial 16x 8:1 mux followed by  8x 16:1 mux. Might be speed limiting.  
                    chan_int := to_integer(pkt_ctr(5 downto 3));
                    byte_int := to_integer(not byte); -- invert bits to read from MSB to LSB
                    fifo_in_tdata <= ram_dout(chan_int)(8*byte_int+7 downto 8*byte_int);
                    fifo_in_tvalid <= '1';
                    byte <= byte + 1;
                    if data_tlast(0) = '1' then
                        fifo_in_tlast <= '1';
                        byte <= (others => '0');
                        pkt_ctr <= pkt_ctr + 1;
                        if header_tvalid(0) = '1' then
                            pkt_ctr <= (others => '0');
                            -- increment timestamp by the number of frames sent
                            --timestamp_incr := shift_left("0010", to_integer(unsigned(mode)));
              		        --timestamp <= timestamp + timestamp_incr;
                        end if;
                    end if;
                end if; 

                -- keep track of fifo overflows
                if fifo_overflow = '1' then
                    fifo_overflow_sticky <= '1';
                end if;

                -- synchronous reset
	            if rst = '1' or user_reset_reg = '1'  then
                    fifo_overflow_sticky <= '0';
                    data_tvalid <= (others => '0');
                    header_tvalid <= (others => '0');
	                fifo_in_tvalid <= '0'; -- needed
	                byte_ctr <= (others => '0');
	                send_state <= SEND_WAIT; -- needed to make sure we start with header transmission
                    byte <= (others=> '0'); -- needed for the first frame header transmission 
                    pkt_ctr <= (others=> '0'); -- needed for the first frame header transmission 
                    overrun <= '0';
	            end if; -- reset
		           
	        end if; --clk
	    end process;
    end block rd_blk;
    
    fifo_blk: block
        signal fifo_din: std_logic_vector(8 downto 0); 
        signal fifo_dout: std_logic_vector(8 downto 0); 
        signal fifo_data_valid: std_logic;
        signal fifo_wr_en: std_logic;
        signal fifo_rd_en: std_logic;
        signal fifo_rd_rst_busy: std_logic;
        signal fifo_wr_rst_busy: std_logic;
        signal fifo_rst: std_logic;
        
--        type line is access string;
        use std.textio.all;
        use ieee.std_logic_textio;

        function xpm_async_fifo_features(overflow, data_valid, prog_full:boolean := FALSE) return  string is
            variable l: line;
            variable v: std_logic_vector(15 downto 0):= (others => '0');
        begin
            v := (
                0  => to_std_logic(overflow),
                1  => to_std_logic(prog_full),
                12 => to_std_logic(data_valid),
                others => '0');
            std_logic_textio.hwrite(l, v);
            return l.all;
        end function;
        
    begin    

    	fifo_rst <= rst  or user_reset_reg;
        fifo_din <= fifo_in_tlast & fifo_in_tdata;
        fifo_wr_en <= fifo_in_tvalid and not (rst or fifo_wr_rst_busy);

        m_axis_bsb_tdata <= fifo_dout(7 downto 0);
        m_axis_bsb_tlast <= fifo_dout(8);
        m_axis_bsb_tvalid <= fifo_data_valid;
        fifo_rd_en <= m_axis_bsb_tready and not fifo_rd_rst_busy and fifo_data_valid; -- valid in included to prevent reads during resets

            
       -- BSB FIFO
       -- There is a considerable delay between the time the read  side sees there is data on the write side (4-5 slow clocks, which is equivalent to 16-20 fast clocks).
       -- If the FIFO is not deep enough, the readout stops needlessly. Data is good, but bandwidth is reduced needlessly.
       -- We have to set the full threshold to 16-6 = 12 to make sure that flusing the writes in the pipeline won't overflow the FIFO.
        -- This means the depth of the FIFO should be ~6 + 20 = 26. Te FIFO does not work properly in simulation with values not multiples of 16.
       -- xpm_fifo_async: Asynchronous FIFO
       -- Xilinx Parameterized Macro, version 2022.2
       fifo0 : xpm_fifo_async
           generic map (
              FIFO_MEMORY_TYPE => "auto", -- String
              FIFO_WRITE_DEPTH => 32,   -- DECIMAL. 16 is the minimum
              FULL_RESET_VALUE => 1,      -- DECIMAL
              PROG_FULL_THRESH => 12,     -- DECIMAL 11 has overflows
              READ_DATA_WIDTH => 9,      -- DECIMAL
              READ_MODE => "fwft",         -- String
        --      RELATED_CLOCKS => 0,        -- DECIMAL
              SIM_ASSERT_CHK => 1,        -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
              USE_ADV_FEATURES => "1407", --"1003", -- xpm_async_fifo_features(overflow => true, prog_full => true, data_valid => TRUE),-- to_hex_string((0 | 1 | 12 => '1', others => '0')), -- 0:overflow, 1:prog_full, 12:data_valid
              WRITE_DATA_WIDTH => 9,     -- DECIMAL
              WR_DATA_COUNT_WIDTH => 5,  
              RD_DATA_COUNT_WIDTH => 5  
           )
           port map (
              din =>        fifo_din,
              wr_en =>      fifo_wr_en,  --  Must be low when rst=1 or wr_rst_busy=1 
              prog_full =>  fifo_full,
              overflow =>   fifo_overflow,
              wr_clk =>     clk,
              rst =>        fifo_rst,         -- synchronous to wr_clk. 
        
              dout =>       fifo_dout,
              data_valid => fifo_data_valid,       
              rd_en =>      fifo_rd_en, -- Must be low when rst=1 or rd_rst_busy=1
              rd_clk =>     bsb_clk,
        
              rd_rst_busy => fifo_rd_rst_busy,
              wr_rst_busy => fifo_wr_rst_busy,
              
              sleep => '0',
              injectsbiterr => '0',
              injectdbiterr => '0'
        
           );
    end block;
				
end Behavioral;
