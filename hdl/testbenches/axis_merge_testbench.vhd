----------------------------------------------------------------------------------
-- Company: McGill Univ.
-- Testbench for axis_merge: N-port round-robin AXIS merge with one pipeline stage.
-- Variable N_PORTS; each source sends packets with port-specific marker.
-- Checker reports port, packet length, and content validity.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
use std.env.finish;

library work;
use work.chFPGA_Package.all;
use work.tb_package.all;

entity axis_merge_testbench is
    generic (
        N_PORTS     : positive := 1;
        DATA_WIDTH  : positive := 8;
        USE_FIFO    : boolean  := FALSE;
        PKT_LEN     : positive := 37;
        PERIOD_BASE : positive := 1;
        PERIOD_INC  : positive := 3;
        NUM_PACKETS : positive := 600
    );
end entity axis_merge_testbench;

architecture sim of axis_merge_testbench is

    constant CLK_PERIOD   : time := 4 ns;
    constant PORT_MARKER  : natural := 16#10#;
    constant MAX_PKT_LEN  : positive := PKT_LEN+1;

    signal clk   : std_logic := '0';
    signal rst   : std_logic := '1';

    signal s_axis_tdata  : slv_array(0 to N_PORTS - 1)(DATA_WIDTH - 1 downto 0) := (others => (others => '0'));
    signal s_axis_tvalid : std_logic_vector(0 to N_PORTS - 1)                  := (others => '0');
    signal s_axis_tlast  : std_logic_vector(0 to N_PORTS - 1)                  := (others => '0');
    signal s_axis_tready : std_logic_vector(0 to N_PORTS - 1);

    signal m_axis_tdata  : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal m_axis_tvalid : std_logic;
    signal m_axis_tlast  : std_logic;
    signal m_axis_tready : std_logic := '1';
    signal hdr: std_logic_vector(7 downto 0);
begin

    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.axis_merge
        generic map (
            N_PORTS    => N_PORTS,
            DATA_WIDTH => DATA_WIDTH,
            USE_FIFO   => USE_FIFO
        )
        port map (
            s_axis_tdata  => s_axis_tdata,
            s_axis_tvalid => s_axis_tvalid,
            s_axis_tlast  => s_axis_tlast,
            s_axis_tready => s_axis_tready,
            m_axis_tdata  => m_axis_tdata,
            m_axis_tvalid => m_axis_tvalid,
            m_axis_tlast  => m_axis_tlast,
            m_axis_tready => m_axis_tready,
            clk           => clk,
            rst           => rst
        );

    rst_proc : process
    begin
        rst <= '1';
        sleep(clk, 8);
        rst <= '0';
        sleep(clk, 4);
        wait;
    end process;

    -- One stimulus process per port: repeat packets with port-specific period
    g_stim : for p in 0 to N_PORTS - 1 generate
        stim_p : process
            variable pkt    : slv_array(0 to PKT_LEN - 1)(7 downto 0);
            variable period : natural;
        begin
            wait until rst = '0';
            sleep(clk, 4 + p * 4);
            period := PERIOD_BASE + p * PERIOD_INC;
            for n in 0 to NUM_PACKETS - 1 loop
                pkt(0) := std_logic_vector(to_unsigned(PORT_MARKER + p, 8));
                for b in 1 to PKT_LEN - 1 loop
                    pkt(b) := std_logic_vector(to_unsigned(b, 8));
                end loop;
                send_axis_packet(clk, s_axis_tdata(p), s_axis_tvalid(p), s_axis_tlast(p), s_axis_tready(p), pkt, period);
            end loop;
            if p = N_PORTS-1 then
                sleep(clk,10);
                finish;
            end if;
            wait;
        end process stim_p;
    end generate g_stim;

    -- Checker: report port, packet length, content_ok for each completed packet
    check_proc : process (all)
        variable packet_buf : slv_array(0 to MAX_PKT_LEN - 1)(7 downto 0);
        variable packet_idx : natural range 0 to MAX_PKT_LEN := 0;
        variable port_id    : integer;
        variable content_ok : boolean;
        variable j          : natural;
        variable buf        : line;
    begin
        if rising_edge(clk) then
            if not rst then
                if m_axis_tvalid and m_axis_tready then
                    packet_buf(packet_idx) := m_axis_tdata;
                    hdr <= packet_buf(0);
                    if m_axis_tlast then
                        port_id := to_integer(unsigned(packet_buf(0))) - PORT_MARKER;
                        content_ok := (port_id >= 0 and port_id < N_PORTS);
                        if packet_idx >= 1 and content_ok then
                            for j in 1 to packet_idx loop
                                if to_integer(unsigned(packet_buf(j))) /= j then
                                    content_ok := false;
                                end if;
                            end loop;
                        end if;
                        write(buf, string'("port=") & integer'image(port_id) &
                             string'(" len=") & integer'image(packet_idx + 1) &
                             string'(" content_ok=") & boolean'image(content_ok) & " 0x" & to_hstring(packet_buf(0)));
                        writeline(output, buf);
                        packet_idx := 0;
                    else
                        packet_idx := packet_idx + 1;
                    end if;
                end if;
            else
                packet_idx := 0;
            end if;
        end if;
    end process check_proc;

end architecture sim;
