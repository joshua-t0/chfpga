-- Company: McGill Univ.
-- Engineer: JF Cliche
--
-- Create Date:    2025-01
-- Design Name:
-- Module Name:    xxvglink_tx
-- Project Name:
-- Target Devices: Ultrascale+
-- Tool versions: Vivado 2022.2

-- Description: Packetizes an incoming AXI stream with a header and CRC and
-- feed the packets to a 64/66B XVXGLINK core transmitter, inserting control
-- words and IDLEs as needed.

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--library UNISIM;
--use UNISIM.VComponents.all;

library xpm;
use xpm.vcomponents.all;

library work;
use work.chFPGA_Package.all;


-- Packetizes an incoming AXI stream with a start of frame, payload, CRC32 and end of frame to be fed to the 10G link. The framing is to that of 10G Ethernet (IEEE 802.3ae).
-- This transmitter is meant to be very lightweight in terms or resource utilization.
--
-- On the user side, the start of a frame is initiated when TVALID is active after the last byte of the previous frame is accepted (TVALID=1, TLAST=1 & TREADY=1)
-- If the input data is continuously available, continuous transmission will occur without mid-frame IDLEs (this is needed for Ethernet). If there is no input data, IDLE frames will be inserted.
-- A 32-bit CRC is added at the end of the frame, followed by the End of Frame control block.
--
-- On the GTX side, data will be captured only when tx_ready='1' (due to the GTX gearbox, this line is low every 2 consecutive clock out of every 66 clocks).
-- The next word word accepted after tready has been low is always the first word of a block. The ready line is therefore used to synchronize the first/last half of the data block.
--
-- On the link, the byte in the MSB of the user data word is transmitted first (big-endian). In other words, bit 24 is transmitted first.
-- This is consistent with the ordering used by the xglink core, and is easier to visualize in simulations.
-- The endianness is not configurable.
entity xxvglink_tx is
	port (
			-- User-side streaming interface
			
		s_axis_tx_tdata: in slv64; -- Fisrt *byte* transmitted is in the MSB (i.e. first bit transmitted is bit 24)
		s_axis_tx_tvalid: in std_logic;
		s_axis_tx_tlast: in std_logic;
		s_axis_tx_clk: in std_logic;

		--reset_stats: in std_logic;
		fifo_overflow: out std_logic; -- transient flag indicating that the TX FIFO has a overflow condition. Synchronous to s_axis_tx_clk

		-- XGLINK core interface
		
		tx_data: out slv64 := X"1E000000_00000000"; -- init important for sims
		tx_header: out slv2; -- '10' for control, '01' for data
		tx_ready: in std_logic; -- The data is accepted only on clocks where tx_ready is High
		tx_clk: in std_logic; -- TX clock from the XGLINK core

		arst : in STD_LOGIC -- asynchronous reset
		);


end xxvglink_tx;

architecture impl of xxvglink_tx is

    -- Signals

    signal tx_rst: std_logic; -- synchronous reset

    -- TX state machine
    type TX_STATE_TYPE is (

        TX_STATE_STANDBY_IDLE,
        TX_STATE_SOF,
        TX_STATE_DATA,
        TX_STATE_CRC_EOF
        );

    signal TX_STATE: TX_STATE_TYPE := TX_STATE_STANDBY_IDLE; -- Initialization needed

    signal fifo_tdata: slv64;
    signal fifo_tvalid: std_logic;
    signal fifo_tlast: std_logic;
    signal fifo_rd_en: std_logic;

    --signal tx_reset_done: std_logic;
    signal tx_reset_ctr: unsigned(3 downto 0);

    --signal send_data: std_logic; -- '1' when we are consuming the FIFO data

    --signal crc_calc: std_logic:='0'; --
    signal crc_init: std_logic:='0'; --
    signal crc_out: slv32; -- Ethernet CRC word
    signal crc_out_int: slv32; -- Ethernet CRC word


begin

    rst_cdc0: xpm_cdc_async_rst
        generic map (RST_ACTIVE_HIGH => 1)
        port map (
            src_arst  => arst,
            dest_clk  => tx_clk,
            dest_arst => tx_rst
            );

    tx_fifo0 : entity work.xxvglink_data_fifo
      PORT MAP (

        s_axis_tvalid  => s_axis_tx_tvalid,
        s_axis_tlast   => s_axis_tx_tlast,
        s_axis_tdata   => s_axis_tx_tdata,
        s_clk          => s_axis_tx_clk,
        overflow       => fifo_overflow, -- on s_axis_tx_clk

        m_axis_tready  => fifo_rd_en,
        m_axis_tvalid  => fifo_tvalid,
        m_axis_tlast   => fifo_tlast,
        m_axis_tdata   => fifo_tdata,
        m_clk          => tx_clk,


        arst            => arst
      );



    -- Instantiate the CRC engine, 32-bit wide input.
    crc32_0: entity work.crc32_64
        port map(
            din => reverse_bits_same_dir(reverse_bytes(fifo_tdata)), -- First bit to transmit is in the MSB of data_in
            crc_out => crc_out_int,
            rst => crc_init,
            en => fifo_rd_en and fifo_tvalid,
            clk => tx_clk
    );
    crc_out <= not reverse_bytes(reverse_bits_same_dir(crc_out_int)); -- First *byte* to transmit in the MSB, all bits inverted as per Ethernet standard

    -- fetch new data word when we are sending a data word to the tx_data
    fifo_rd_en <= to_std_logic(tx_ready = '1' and tx_state = TX_STATE_DATA);

    process(all) begin
        if rising_edge(tx_clk) then

    --		-- Mare sure no data is written to FIFO a few clocks after reset
    --		if all_ones(tx_reset_ctr) then
    --			tx_reset_done <= '1';
    --		else
    --			tx_reset_ctr <= tx_reset_ctr + 1;
    --		end if;

            crc_init <= '0'; -- Compute CRC by default unless INIT=1

                    -- Output data state machine
            if tx_ready then -- if GTY's gearbox can receive data

                tx_data <= X"1E000000_00000000";
                tx_header <= "10";

                case tx_state is
                    when TX_STATE_STANDBY_IDLE => -- STANDBY State
                        crc_init <= '1';
                        if fifo_tvalid='1' then -- if there is any data coming our way, start a new frame
                            tx_state <= TX_STATE_SOF;
                        end if;

                    when TX_STATE_SOF => --Start of frame block
                        tx_data <= X"78555555_555555D5";
                        tx_header <= "10";
                        tx_state <= TX_STATE_DATA;

                    when TX_STATE_DATA => --Data block
                        if fifo_tvalid = '1' then
                            tx_data <= fifo_tdata;
                            tx_header <= "01";
                            if fifo_tlast='1' then -- if this is the last word of the frame
                                tx_state <= TX_STATE_CRC_EOF; -- ...send the CRC on the second half of the block, then EOF in a new block
                            end if;
                        end if;
                        -- othewise we don't have enough data to fill a block so send an IDLE block instead. The data is in the pipeline and will be sent later.

                    when TX_STATE_CRC_EOF => -- Send CRC on the second half of the block
                        tx_data <= X"CC" & crc_out & X"000000"; -- Ordered set {D0 D1 D2 D3 T4 C5 C6 C7} = 0xcc D0 D1 D2 D3 "000" C5 C6 C7 (C5-7 are 7 bits and are IDEL (0))
                        tx_header <= "10";
                        tx_state <= TX_STATE_STANDBY_IDLE;
                end case;

            end if; -- if tx_ready=1

            if tx_rst = '1' then
                tx_state <= TX_STATE_STANDBY_IDLE;
                tx_data <= X"1E000000_00000000";
                tx_header <= "10";
                tx_reset_ctr <= (others => '0');
    --			tx_reset_done <= '0';
            end if;

        end if; -- if CLK
    end process;

end impl;

