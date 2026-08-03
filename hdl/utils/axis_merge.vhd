----------------------------------------------------------------------------------
-- Company: McGill Univ.
-- Engineer: JF Cliche
--
-- Create Date:    2026-02-17
-- Module Name:    axis_merge
-- Target Devices: Kintex 7, Ultrascale+
-- Tool versions: Vivado 2022.2
-- Description: N-port packet-level round-robin AXIS merge with one pipeline stage.
--
--   Merges N AXI4-Stream sources into one output. Arbitration is round-robin at
--   packet boundaries (tlast), using next_valid_port_after() so there are no
--   idle scan cycles. A single axis_sync_fifo breaks the TREADY path if USE_FIFO=true;
--
-- Data latency is 1 cycle. next_port is
--   latched: combinatorially updated when EN=1 (scanning), frozen when EN=0 (in packet).
--
--   Generics: N_PORTS, DATA_WIDTH, USE_FIFO. Port index range 0 to N_PORTS-1 (cyclic).
--   USE_FIFO=true (default): axis_sync_fifo breaks TREADY path; 2-cycle latency, 1 dead cycle.
--   USE_FIFO=false: direct connection; combinatorial m_axis_tready->s_axis_tready; 1-cycle latency,
--   2 dead cycles; for moderate clock rates only.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.chFPGA_Package.all;

entity axis_merge is
    generic (
        N_PORTS    : positive := 2;
        DATA_WIDTH : positive := 8;
        USE_FIFO   : boolean  := TRUE
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
end entity axis_merge;


architecture impl of axis_merge is

    signal current_port   : integer range 0 to N_PORTS - 1 := 0;
    signal current_port_active : std_logic := '0';
    signal fifo_tdata   : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal fifo_tvalid  : std_logic;
    signal fifo_tlast   : std_logic;
    signal fifo_tready : std_logic;

begin

 
    sel_gen: if N_PORTS = 1 generate -- only one port, bypass the port selection logic
        fifo_tvalid <= s_axis_tvalid(0);
        fifo_tdata  <= s_axis_tdata(0);
        fifo_tlast  <= s_axis_tlast(0);
        s_axis_tready(0) <= fifo_tready;

    elsif N_PORTS > 1 generate
        fifo_tvalid <= s_axis_tvalid(current_port) when current_port_active else '0';
        fifo_tdata  <= s_axis_tdata(current_port);
        fifo_tlast  <= s_axis_tlast(current_port);

        process(all) 
            variable tvalid : std_logic_vector(0 to 2*N_PORTS - 1);
            variable last_word: std_logic; 
        begin

            -- Combinatorially forward the output's  TREADY signal to the currently selected port, others are 0
            s_axis_tready <= (others => '0');
            s_axis_tready(current_port) <= fifo_tready when current_port_active else '0';

            -- Detect when the last word of a frame is being read out
            last_word := s_axis_tlast(current_port) and s_axis_tvalid(current_port) and s_axis_tready(current_port);

            if rising_edge(clk) then
                -- Deselect source port when the last word of a frame is being read out or when the reset is asserted
                current_port_active <= '0' when last_word or rst;

                -- Select the next source port to read from if no port is selected
                if not current_port_active then
                    -- Create a vector of all the valid signals, duplicated to simplify round-robin detection
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
    else generate
        assert FALSE report "N_PORTS must be 1 or greater" severity failure;
    end generate sel_gen;

    fifo_gen : if USE_FIFO and N_PORTS >= 1 generate
        u_fifo : entity work.axis_sync_fifo
            generic map (DATA_WIDTH => DATA_WIDTH)
            port map (
                clk           => clk,
                rst           => rst,
                s_axis_tdata  => fifo_tdata,
                s_axis_tvalid => fifo_tvalid,
                s_axis_tlast  => fifo_tlast,
                s_axis_tready => fifo_tready,
                m_axis_tdata  => m_axis_tdata,
                m_axis_tvalid => m_axis_tvalid,
                m_axis_tlast  => m_axis_tlast,
                m_axis_tready => m_axis_tready
            );
    else generate -- connect directly to m_axis
        fifo_tready      <= m_axis_tready;
        m_axis_tdata     <= fifo_tdata;
        m_axis_tvalid    <= fifo_tvalid;
        m_axis_tlast     <= fifo_tlast;
    end generate fifo_gen;

end architecture impl;
