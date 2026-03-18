--------------------------------------------------------------------------------
-- Company: McGill University
-- Engineer: JF Cliche
--
-- Create Date:   2025-01-23
-- Design Name:
-- Module Name:   xxvglink_array_testbench.vhd
-- Project Name:  chFPGA
-- Target Device: Ultrascale+
-- Tool versions: Vivado 2022.2+
-- Description: Used to test 25Gbps packet transmitter array 
--
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

library work;
USE work.chFPGA_Package.all;
use work.tb_package.all;

ENTITY uct_testbench IS
	generic (
	   CT_LEVEL: integer := 3;
		NCHAN: integer := 8;
		LANE_TO_LINK_MAP: integer_array := (-1,0,1,2,-1,-1,3,4);
		LINK_TO_QUAD_MAP: integer_array:= (0,1,1,2,2, 2,2,2,2,2,2,2);
		QUAD_TO_REFCLK_MAP: integer_array := (0,0,0);

		NUMBER_OF_LANES: integer := LANE_TO_LINK_MAP'LENGTH;
		NUMBER_OF_LINKS: integer := LINK_TO_QUAD_MAP'LENGTH
		);
END uct_testbench;


ARCHITECTURE impl OF uct_testbench IS

   -- Clock period definitions
constant REFCLK_PERIOD : time := 6.4 ns;
constant CLK125_period : time := 8 ns;
constant CHAN_CLK_PERIOD : time := 2.5 ns;


--Inputs
signal CPU_RESET : std_logic := '0';
signal send_data : std_logic := '0';

 -- UDP/Ethernet interfaces


signal ctr: unsigned(6 downto 0):=(others=>'0'); -- init for sim

signal clk: std_logic := '0'; -- 402 MHx Tx_clk clock
signal chan_clk: std_logic := '0'; -- 400 MHx Tx_clk clock
signal clk125: std_logic := '0'; --
signal rst : STD_LOGIC; -- asynchronous reset

signal tx_ctr: unsigned(7 downto 0):= (others=>'0'); -- init needed for sim
signal word_ctr: unsigned(10 downto 0) := (others => '0'); -- counts 2048 words
signal word_ctr2: u11_array(0 to NUMBER_OF_LANES-1) := (others => (others => '0')); -- counts 2048 words
signal frame_ctr: unsigned(11 downto 0) := (others => '0');

signal cb1_out_tdata: slv_array(0 to NUMBER_OF_LANES-1)(63 downto 0);
signal cb1_out_tvalid: std_logic_vector(0 to NUMBER_OF_LANES-1);
signal cb1_out_tlast: std_logic_vector(0 to NUMBER_OF_LANES-1);

signal fifo_out_tdata: slv_array(0 to NUMBER_OF_LANES-1)(63 downto 0);
signal fifo_out_tvalid: std_logic_vector(0 to NUMBER_OF_LANES-1);
signal fifo_out_tlast: std_logic_vector(0 to NUMBER_OF_LANES-1);

--signal word_ctr: unsigned(5 downto 0) := (others => '0'); -- counts 64 words

constant data1: slv36_array(0 to 17) := (
	X"1_90E2BA2F", X"1_F88090E2",
	X"1_BA2FF880", X"1_08004500",
	X"1_0034013F", X"1_00000111",
	X"1_D37B0202", X"1_0201E000",
	X"1_00FCC313", X"1_14EB0020",
	X"1_70AC73D4", X"1_00000001",
	X"1_00000000", X"1_00000669",
	X"1_73617461", X"1_70000001",
	X"1_0001B85E", X"3_5E00FD07"
		);
constant data2: slv36_array := (
	0=> X"1_FAFEF1F0",
	1=> X"3_01234567"
	);

constant data3: slv36_array := ( -- works ok
	0=> X"1_FAFEF1F0",
	1=> X"0_00000000",
	2=> X"3_01234567"
	);

constant data4: slv36_array := ( --
	0=> X"1_FAFEF1F0",
	1=> X"0_00000000",
	2=> X"0_00000000",
	3=> X"0_00000000",
	4=> X"0_00000000",
	5=> X"0_00000000",
	6=> X"0_00000000",
	7=> X"3_01234567"
	);

constant data5: slv68_array(0 to 8) := (
	X"1_01234567_89ABCDEF",
	X"1_FFFFFFFF_FFFFFFFF",
	X"1_0FF00FF0_06060606",
	X"1_07070707_08080808",
	X"1_09090909_0A0A0A0A",
	X"1_0B0B0B0B_0C0C0C0C",
	X"1_0D0D0D0D_0E0E0E0E",
	X"3_0F0F0F0F_10101010",
	X"3_11111111_12121212"
		);

constant data6: slv36_array(0 to 127) := (
	X"1_00000000", X"1_01010101",
	X"1_02020202", X"1_03030303",
	X"1_04040404", X"1_05050505",
	X"1_06060606", X"1_07070707",
	X"1_08080808", X"1_09090909",
	X"1_0A0A0A0A", X"1_0B0B0B0B",
	X"1_0C0C0C0C", X"1_0D0D0D0D",
	X"1_0E0E0E0E", X"1_0F0F0F0F",
	X"1_10101010", X"1_11111111",
	X"1_12121212", X"1_13131313",
	X"1_14141414", X"1_15151515",
	X"1_16161616", X"1_17171717",
	X"1_18181818", X"1_19191919",
	X"1_1A1A1A1A", X"1_1B1B1B1B",
	X"1_1C1C1C1C", X"1_1D1D1D1D",
	X"1_1E1E1E1E", X"1_1F1F1F1F",
	X"1_20202020", X"1_21212121",
	X"1_22222222", X"1_23232323",
	X"1_24242424", X"1_25252525",
	X"1_26262626", X"1_27272727",
	X"1_28282828", X"1_29292929",
	X"1_2A2A2A2A", X"1_2B2B2B2B",
	X"1_2C2C2C2C", X"1_2D2D2D2D",
	X"1_2E2E2E2E", X"1_2F2F2F2F",
	X"1_30303030", X"1_31313131",
	X"1_32323232", X"1_33333333",
	X"1_34343434", X"1_35353535",
	X"1_36363636", X"1_37373737",
	X"1_38383838", X"1_39393939",
	X"1_3A3A3A3A", X"1_3B3B3B3B",
	X"1_3C3C3C3C", X"1_3D3D3D3D",
	X"1_3E3E3E3E", X"1_3F3F3F3F",
	X"1_40404040", X"1_41414141",
	X"1_42424242", X"1_43434343",
	X"1_44444444", X"1_45454545",
	X"1_46464646", X"1_47474747",
	X"1_48484848", X"1_49494949",
	X"1_4A4A4A4A", X"1_4B4B4B4B",
	X"1_4C4C4C4C", X"1_4D4D4D4D",
	X"1_4E4E4E4E", X"1_4F4F4F4F",
	X"1_50505050", X"1_51515151",
	X"1_52525252", X"1_53535353",
	X"1_54545454", X"1_55555555",
	X"1_56565656", X"1_57575757",
	X"1_58585858", X"1_59595959",
	X"1_5A5A5A5A", X"1_5B5B5B5B",
	X"1_5C5C5C5C", X"1_5D5D5D5D",
	X"1_5E5E5E5E", X"1_5F5F5F5F",
	X"1_60606060", X"1_61616161",
	X"1_62626262", X"1_63636363",
	X"1_64646464", X"1_65656565",
	X"1_66666666", X"1_67676767",
	X"1_68686868", X"1_69696969",
	X"1_6A6A6A6A", X"1_6B6B6B6B",
	X"1_6C6C6C6C", X"1_6D6D6D6D",
	X"1_6E6E6E6E", X"1_6F6F6F6F",
	X"1_70707070", X"1_71717171",
	X"1_72727272", X"1_73737373",
	X"1_74747474", X"1_75757575",
	X"1_76767676", X"1_77777777",
	X"1_78787878", X"1_79797979",
	X"1_7A7A7A7A", X"1_7B7B7B7B",
	X"1_7C7C7C7C", X"1_7D7D7D7D",
	X"1_7E7E7E7E", X"3_7F7F7F7F"
		);


signal rx_p: std_logic_vector(0 to NUMBER_OF_LINKS-1);
signal rx_n: std_logic_vector(0 to NUMBER_OF_LINKS-1);
signal tx_p: std_logic_vector(0 to NUMBER_OF_LINKS-1);
signal tx_n: std_logic_vector(0 to NUMBER_OF_LINKS-1);
signal refclk_p: std_logic := '0';
signal refclk_n: std_logic;

--subtype slv32_array is slv_array(0 to NCHAN-1)(31 downto 0);
signal s_axis_tx_tdata: slv_array(0 to NCHAN-1)(31 downto 0);
signal s_axis_tx_tvalid: std_logic;
signal s_axis_tx_tlast: std_logic;

--signal m_axis_rx_tdata: slv64_array(0 to NUMBER_OF_LANES-1);
--signal m_axis_rx_tvalid: std_logic_vector(0 to NUMBER_OF_LANES-1);
--signal m_axis_rx_tlast: std_logic_vector(0 to NUMBER_OF_LANES-1);
signal m_axis_rx_tdata: std_logic_vector(255 downto 0);
signal m_axis_rx_tvalid: std_logic;
signal m_axis_rx_tlast: std_logic;

alias data is data5; -- select test patern source

signal tdata: slv64_array(0 to data'length-1);
signal tvalid: std_logic_vector(0 to data'length-1);
signal tlast: std_logic_vector(0 to data'length-1);

--signal tx_resetdone: std_logic_vector(0 to NUMBER_OF_LANES-1); --
--signal rx_resetdone: std_logic_vector(0 to NUMBER_OF_LANES-1); --
signal resetdone: std_logic;
signal cmd_tdata: slv8;
signal cmd_tvalid: std_logic;
signal cmd_tlast: std_logic;
signal cmd_tready: std_logic;

BEGIN

gen_link: for i in 0 to NUMBER_OF_LINKS-1 generate
    rx_p(i) <= transport tx_p(i) after 7ns*i;
    rx_n(i) <= transport tx_n(i) after 7ns*i;
end generate;

gen1: for i in  0 to data'length-1 generate
	tdata(i) <= data(i)(63 downto 0);
	tvalid(i)<= data(i)(64);
	tlast(i) <= data(i)(65);
end generate;


dut0: entity work.uct_engine
	generic map (
	    PLATFORM_TYPE => CRS,
        NUMBER_OF_INPUT_LANES => NCHAN,
		LANE_TO_LINK_MAP       => LANE_TO_LINK_MAP,
		LINK_TO_QUAD_MAP       => LINK_TO_QUAD_MAP,
		QUAD_TO_REFCLK_MAP     => QUAD_TO_REFCLK_MAP,
		CT_LEVEL => CT_LEVEL
		)
	port map (
        -- Inputs form channelizers
		s_axis_tdata  => s_axis_tx_tdata,
		s_axis_tvalid => s_axis_tx_tvalid,
		s_axis_tlast  => s_axis_tx_tlast,

        -- Output to correlator
		m_axis_tdata  => m_axis_rx_tdata,
		m_axis_tvalid => m_axis_rx_tvalid,
		m_axis_tlast  => m_axis_rx_tlast,

        axis_clk => chan_clk,
        resetdone => resetdone,
        -- Backplane links
		tx_p => tx_p,
		tx_n => tx_n,
		rx_p => rx_p,
		rx_n => rx_n,
		refclk_p(0) => refclk_p,
		refclk_n(0) => refclk_n,

		txclk_out    => clk,
		rst => CPU_RESET,
		arst => CPU_RESET,

		bsb_CMD_DAT.TDATA => cmd_tdata,
		bsb_CMD_DAT.TVALID => cmd_tvalid, 
		bsb_CMD_DAT.TLAST => cmd_tlast,
		bsb_CMD_RDY.TREADY =>cmd_tready,
		bsb_RPLY_DAT => open,
		bsb_RPLY_RDY => (TREADY => '1'),
		bsb_CLK => clk125,
		bsb_RST => CPU_RESET

	);




-- tx_ready <= not to_std_logic(tx_ctr(7 downto 1)=32);



refclk_p <= not refclk_p  after REFCLK_PERIOD/2;
refclk_n <= not refclk_p;

clk125 <= not clk125 after clk125_period/2;

chan_clk <= not chan_clk after chan_clk_period/2;

reset_process: process
	begin
	CPU_RESET <= '1';
	sleep(chan_clk, 100); -- not really needed
--	sleep(clk, 10); -- wait for the QPLL to lock and starts generating the main clock
	CPU_RESET <= '0'; -- release RESET. FIFOs start their reset sequence
	wait until resetdone='1';
	sleep(chan_clk, 32); -- wait for the FIFO to finish their resent before writing into them
	send_data <= '1';
	wait;
end process;

--fifo_gen: for i in 0 to NUMBER_OF_LANES-1 generate
--    fifo0: entity work.xxvglink_data_fifo
--        port map (
--            s_axis_tvalid   => s_axis_tx_tvalid(i),
--            s_axis_tdata    => s_axis_tx_tdata(i),
--            s_axis_tlast    => s_axis_tx_tlast(i),
--            s_clk          => chan_clk,
    
--            m_axis_tvalid   => fifo_out_tvalid(i),
--            m_axis_tdata    => fifo_out_tdata(i),
--            m_axis_tlast    => fifo_out_tlast(i),
--            m_clk          => clk,
    
--            overflow => open,
--            arst      => rst
--        );
--end generate;
-- Stimulus: send data packets
chan_proc: process(all) begin
    if rising_edge(chan_clk) then
		s_axis_tx_tdata  <= (others=> (others => '0'));
		s_axis_tx_tvalid <= '0';
		s_axis_tx_tlast  <= '0';
       	if send_data then

            word_ctr <= word_ctr + 1;
            if all_ones(word_ctr) then
                frame_ctr <= frame_ctr + 1;
            end if;
            if cpu_reset or not send_data then
                word_ctr <=  (others => '0');
                frame_ctr <=  (others => '0');
            end if; 

            for lane in 0 to NCHAN-1 loop
                for bin in 0 to 3 loop
                    s_axis_tx_tdata(lane)(8*(bin+1)-1 downto 8*bin)  <= to_slv(to_integer(word_ctr(5 downto 0)) *4 + (3-bin), 8);
                end loop; --bin
--                    s_axis_tx_tdata(lane)(word_ctr'RANGE)  <= std_logic_vector(word_ctr);
--                    s_axis_tx_tdata(lane)(27 downto 16)  <= std_logic_vector(frame_ctr);
--                    s_axis_tx_tdata(lane)(31 downto 28)  <= to_slv(i,4);
            end loop; --lane
            s_axis_tx_tvalid <= '1';
            s_axis_tx_tlast  <= to_std_logic(all_ones(word_ctr));

		end if; --if send_data
     end if; --clk
  end process;


-- Stimulus: send data packets
--stim_proc: process(clk)
--begin
--    if rising_edge(clk) then

--       	if send_data='1' then
--            for i in 0 to NUMBER_OF_LANES-1 loop
--                if fifo_out_tvalid(i)='1' then
--                    word_ctr2(i) <= word_ctr2(i) + 1;
--                    if fifo_out_tlast(i)='1' then
--                        word_ctr2(i) <= (others => '0');
--                    end if;
--                end if;
--                if cpu_reset='1' then
--                        word_ctr2(i) <= (others => '0');
--                end if;
--                cb1_out_tdata(i) <= fifo_out_tdata(i);
--                cb1_out_tvalid(i) <= fifo_out_tvalid(i);
--                if cpu_reset='1' or (word_ctr2(i)(10 downto 8) = 0 and word_ctr2(i)(1 downto 0)= i and fifo_out_tlast(i)='0') then
--                    cb1_out_tvalid(i) <= '0';
--                end if;
--                cb1_out_tlast(i) <= fifo_out_tlast(i);
--            end loop; --i

--		end if; --if send_data
--     end if; --clk
--  end process;


---- Enable send_data an number of clk  after reset was deasserted to allow the
---- FIFOs to finish their reset procedure
--clock_ready_process: process
--	begin
--	wait until CPU_RESET='0';
--	sleep(clk, 15);
--	send_data <= '1';
--	wait;
--end process;

end architecture;
