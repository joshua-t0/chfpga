----------------------------------------------------------------------------------
-- Company: McGill Univ.
-- Engineer: JF Cliche
--
-- Create Date:    2026-02-16
-- Module Name:    axis_merge
-- Target Devices: Kintex 7, Ultrascale+
-- Tool versions: Vivado 2022.2
-- Description: Packet-level round-robin arbiter for two AXI4-Stream inputs.
--
--   Merges two AXI4-Stream sources into a single output by alternating between
--   them at packet boundaries (tlast). Uses round-robin fairness: after
--   completing a packet from one source, the arbiter checks the other source
--   first. If only one source has data, it is served immediately.
--
--   All ports operate on a single clock. CDC must be handled upstream (e.g.
--   via generic_fifo with IS_ASYNC=TRUE).
--
--   Backpressure uses a direct combinatorial path from m_axis_tready to the
--   selected source's s*_axis_tready (like bsb_master.vhd). No internal
--   pipelining or overflow FIFOs. This is suitable for moderate clock rates
--   (e.g. 125 MHz capture bus).
--
--   DATA_WIDTH is parameterized to support future bus width changes.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity axis_merge is
    generic (
        DATA_WIDTH : integer := 8
    );
    port (
        -- Input stream 0
        s0_axis_tdata  : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        s0_axis_tvalid : in  std_logic;
        s0_axis_tlast  : in  std_logic;
        s0_axis_tready : out std_logic;
        -- Input stream 1
        s1_axis_tdata  : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        s1_axis_tvalid : in  std_logic;
        s1_axis_tlast  : in  std_logic;
        s1_axis_tready : out std_logic;
        -- Merged output stream
        m_axis_tdata   : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        m_axis_tvalid  : out std_logic;
        m_axis_tlast   : out std_logic;
        m_axis_tready  : in  std_logic;
        -- Clock and reset
        clk : in std_logic;
        rst : in std_logic := '0'
    );
end axis_merge;


architecture impl of axis_merge is

    type state_type is (ST_SCAN, ST_SEND0, ST_SEND1);
    signal state       : state_type := ST_SCAN;
    signal last_served : std_logic  := '1'; -- '0' = source 0 last served, '1' = source 1 last served

begin

    -- Combinatorial output mux and tready forwarding
    process(all) begin
        -- Defaults: nothing selected
        s0_axis_tready <= '0';
        s1_axis_tready <= '0';
        m_axis_tdata   <= (others => '0');
        m_axis_tvalid  <= '0';
        m_axis_tlast   <= '0';

        case state is
            when ST_SCAN =>
                -- Check for available data; round-robin priority
                if last_served = '1' then
                    -- Source 1 was last served, prefer source 0
                    if s0_axis_tvalid = '1' then
                        s0_axis_tready <= m_axis_tready;
                        m_axis_tdata   <= s0_axis_tdata;
                        m_axis_tvalid  <= s0_axis_tvalid;
                        m_axis_tlast   <= s0_axis_tlast;
                    elsif s1_axis_tvalid = '1' then
                        s1_axis_tready <= m_axis_tready;
                        m_axis_tdata   <= s1_axis_tdata;
                        m_axis_tvalid  <= s1_axis_tvalid;
                        m_axis_tlast   <= s1_axis_tlast;
                    end if;
                else
                    -- Source 0 was last served, prefer source 1
                    if s1_axis_tvalid = '1' then
                        s1_axis_tready <= m_axis_tready;
                        m_axis_tdata   <= s1_axis_tdata;
                        m_axis_tvalid  <= s1_axis_tvalid;
                        m_axis_tlast   <= s1_axis_tlast;
                    elsif s0_axis_tvalid = '1' then
                        s0_axis_tready <= m_axis_tready;
                        m_axis_tdata   <= s0_axis_tdata;
                        m_axis_tvalid  <= s0_axis_tvalid;
                        m_axis_tlast   <= s0_axis_tlast;
                    end if;
                end if;

            when ST_SEND0 =>
                s0_axis_tready <= m_axis_tready;
                m_axis_tdata   <= s0_axis_tdata;
                m_axis_tvalid  <= s0_axis_tvalid;
                m_axis_tlast   <= s0_axis_tlast;

            when ST_SEND1 =>
                s1_axis_tready <= m_axis_tready;
                m_axis_tdata   <= s1_axis_tdata;
                m_axis_tvalid  <= s1_axis_tvalid;
                m_axis_tlast   <= s1_axis_tlast;
        end case;
    end process;


    -- Registered state transitions
    process(all) begin
        if rising_edge(clk) then
            if rst = '1' then
                state       <= ST_SCAN;
                last_served <= '1';
            else
                case state is
                    when ST_SCAN =>
                        if last_served = '1' then
                            if s0_axis_tvalid = '1' then
                                -- Single-beat packet: stay in SCAN, update last_served
                                if s0_axis_tlast = '1' and m_axis_tready = '1' then
                                    last_served <= '0';
                                else
                                    state <= ST_SEND0;
                                end if;
                            elsif s1_axis_tvalid = '1' then
                                if s1_axis_tlast = '1' and m_axis_tready = '1' then
                                    last_served <= '1';
                                else
                                    state <= ST_SEND1;
                                end if;
                            end if;
                        else
                            if s1_axis_tvalid = '1' then
                                if s1_axis_tlast = '1' and m_axis_tready = '1' then
                                    last_served <= '1';
                                else
                                    state <= ST_SEND1;
                                end if;
                            elsif s0_axis_tvalid = '1' then
                                if s0_axis_tlast = '1' and m_axis_tready = '1' then
                                    last_served <= '0';
                                else
                                    state <= ST_SEND0;
                                end if;
                            end if;
                        end if;

                    when ST_SEND0 =>
                        if s0_axis_tvalid = '1' and m_axis_tready = '1' and s0_axis_tlast = '1' then
                            last_served <= '0';
                            state       <= ST_SCAN;
                        end if;

                    when ST_SEND1 =>
                        if s1_axis_tvalid = '1' and m_axis_tready = '1' and s1_axis_tlast = '1' then
                            last_served <= '1';
                            state       <= ST_SCAN;
                        end if;
                end case;
            end if;
        end if;
    end process;

end impl;
