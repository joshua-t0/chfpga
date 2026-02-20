----------------------------------------------------------------------------------
-- Company: McGill Univ.
-- Engineer: JF Cliche
--
-- Create Date:    2026-02-17
-- Module Name:    axis_merge2
-- Target Devices: Kintex 7, Ultrascale+
-- Tool versions: Vivado 2022.2
-- Description: N-port packet-level round-robin AXIS merge with one pipeline stage.
--
--   Merges N AXI4-Stream sources into one output. Arbitration is round-robin at
--   packet boundaries (tlast), using next_valid_port_after() so there are no
--   idle scan cycles. A single axis_sync_fifo breaks the TREADY path; all
--   arbitration is done in a synchronous state machine (no combinatorial
--   m_axis_tready -> s_axis_tready path). Data latency is 1 cycle. next_port is
--   latched: combinatorially updated when EN=1 (scanning), frozen when EN=0 (in packet).
--
--   Generics: N_PORTS, DATA_WIDTH, USE_FIFO. Port index range 0 to N_PORTS-1 (cyclic).
--   USE_FIFO=true (default): axis_sync_fifo breaks TREADY path; 2-cycle latency, 1 dead cycle.
--   USE_FIFO=false: direct connection; combinatorial m_axis_tready->s_axis_tready; 1-cycle latency,
--   2 dead cycles; for moderate clock rates only (like axis_merge).
--
--  SCAN: 17 ports:99 LUT, 32 FF, meets timing
--  ENCODE (cyclic priority encoder): 17 ports:690 LUT, 38 FF, meets timing
--  ENCODE2 (first set bit index priority encoder): 17 ports:104 LUT, 27 FF, meets timing 0.119 ns, 5 levels
--  ENCODE3 (double-encoded priority encoder): 17 ports:144 LUT, 28 FF, WNS=-143 ps/2.5 ns,  4 levels
--  ENCODE3 (double-encoded priority encoder with fix, 1 dead beat): 17 ports:144 LUT, 27 FF, WNS=+181 ps/2.5 ns,  3 levels
--  ENCODE3 (double-encoded priority encoder with fix, 1 dead beat, or'ed valid): 17 ports:145 LUT, 27 FF, WNS=+181 ps/2.5 ns,  ----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.chFPGA_Package.all;

entity axis_merge2 is
    generic (
        N_PORTS    : positive := 17;
        DATA_WIDTH : positive := 8;
        USE_FIFO   : boolean  := true
        -- METHOD : string := "ENCODE3" -- "SCAN" or "ENCODE"
    );
    port (
        -- N input streams (AXI4-Stream)
        s_axis_tdata  : in  slv_array(0 to N_PORTS - 1)(DATA_WIDTH - 1 downto 0);
        s_axis_tvalid  : in  std_logic_vector(0 to N_PORTS - 1);
        s_axis_tlast   : in  std_logic_vector(0 to N_PORTS - 1);
        s_axis_tready  : out std_logic_vector(0 to N_PORTS - 1);
        -- Single merged output stream
        m_axis_tdata   : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        m_axis_tvalid  : out std_logic;
        m_axis_tlast   : out std_logic;
        m_axis_tready  : in  std_logic;
        -- Clock and reset
        clk            : in  std_logic;
        rst            : in  std_logic := '0'
    );
end entity axis_merge2;


architecture impl of axis_merge2 is

    signal current_port   : integer range 0 to N_PORTS - 1 := 0;
    signal next_port   : integer range 0 to N_PORTS - 1 := 0;
    signal current_port_active : std_logic := '0';
    signal last_word: std_logic;
    signal merged_tdata   : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal merged_tvalid  : std_logic;
    signal merged_tlast   : std_logic;
    signal consumer_ready : std_logic;

begin

 
    -- next_port <= next_port_from_rotate when en;

    -- Merge to FIFO: always from next_port (latched when EN=0)
    merged_tvalid <= s_axis_tvalid(current_port) when current_port_active else '0';
    merged_tdata  <= s_axis_tdata(current_port);
    merged_tlast  <= s_axis_tlast(current_port);

    process(all) begin
        s_axis_tready <= (others => '0');
        s_axis_tready(current_port) <= consumer_ready;
    end process;
    last_word <= s_axis_tlast(current_port) and s_axis_tvalid(current_port) and s_axis_tready(current_port);

    -- gen:if METHOD = "SCAN" generate

    --     reg_proc : process (all)
    --             variable next_port_var   : integer range 0 to N_PORTS - 1 := 0;
    --         begin
    --         if rising_edge(clk) then
    --             next_port_var := 0 when next_port = N_PORTS - 1 else next_port + 1;
    --             current_port_active <= '0' when last_word;

    --             if s_axis_tvalid(next_port) then
    --                 if (not current_port_active or last_word) then
    --                     current_port <= next_port;
    --                     current_port_active <= '1';
    --                     next_port <= next_port_var;
    --                 end if;
    --             else
    --                 next_port <= next_port_var;
    --             end if;

    --             if rst then
    --                 current_port <= 0;
    --                 current_port_active <= '0';
    --                 next_port <= 0;
    --             end if;
    --         end if;
    --     end process reg_proc;
    -- elsif METHOD = "ENCODE" generate
    --     process(all) begin
    --         if rising_edge(clk) then
    --             if last_word then
    --                 current_port <= next_valid_port_after(s_axis_tvalid, current_port);
    --                 current_port_active <= or(s_axis_tvalid);
    --             end if;
    --             if rst then
    --                 current_port <= 0;
    --                 current_port_active <= '0';
    --             end if;
    --         end if;
    --     end process;
    -- elsif METHOD = "ENCODE2" generate
    --     process(all) begin
    --         if rising_edge(clk) then
    --             if last_word then
    --                 current_port <= first_set_bit_index(s_axis_tvalid);
    --                 current_port_active <= or(s_axis_tvalid);
    --             end if;
    --             if rst then
    --                 current_port <= 0;
    --                 current_port_active <= '0';
    --             end if;
    --         end if;
    --     end process;
    -- elsif METHOD = "ENCODE3" generate
        process(all) 
        variable tvalid : std_logic_vector(0 to 2*N_PORTS - 1);
        begin
            if rising_edge(clk) then
                current_port_active <= '0' when last_word or rst;
                if not current_port_active then
                    tvalid := s_axis_tvalid & s_axis_tvalid;
                    for i in 0 to 2*N_PORTS - 1 loop
                        if i > current_port and tvalid(i)='1' then
                            current_port <= i mod N_PORTS;
                            current_port_active <= '1';
                            exit;
                        end if;
                    end loop;
                end if;
            end if;
        end process;
    -- end generate;

    g_fifo : if USE_FIFO generate
        signal fifo_s_axis_tready : std_logic;
    begin
        consumer_ready <= fifo_s_axis_tready;
        u_fifo : entity work.axis_sync_fifo
            generic map (DATA_WIDTH => DATA_WIDTH)
            port map (
                clk           => clk,
                rst           => rst,
                s_axis_tdata  => merged_tdata,
                s_axis_tvalid => merged_tvalid,
                s_axis_tlast  => merged_tlast,
                s_axis_tready => fifo_s_axis_tready,
                m_axis_tdata  => m_axis_tdata,
                m_axis_tvalid => m_axis_tvalid,
                m_axis_tlast  => m_axis_tlast,
                m_axis_tready => m_axis_tready
            );
    end generate g_fifo;

    g_bypass : if not USE_FIFO generate
    begin
        consumer_ready   <= m_axis_tready;
        m_axis_tdata     <= merged_tdata;
        m_axis_tvalid    <= merged_tvalid;
        m_axis_tlast     <= merged_tlast;
    end generate g_bypass;

end architecture impl;
