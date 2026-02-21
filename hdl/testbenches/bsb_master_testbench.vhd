----------------------------------------------------------------------------------
-- Company: McGill Univ.
-- Testbench for bsb_master: UDP command/reply and probe data arbitration.
-- Exercises UDP Rx -> cmd path, reply -> UDP Tx, and probe data -> UDP Tx.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
use std.env.finish;

library work;
use work.chFPGA_Package.all;
use work.tb_package.all;

entity bsb_master_testbench is
    generic (
        NUMBER_OF_PROBES : positive := 2;
        CLK_PERIOD       : time     := 8 ns
    );
end entity bsb_master_testbench;

architecture sim of bsb_master_testbench is

    signal clk   : std_logic := '0';
    signal rst   : std_logic := '1';

    -- UDP Rx (commands in)
    signal s_axis_udp_rx_tdata  : std_logic_vector(7 downto 0) := (others => '0');
    signal s_axis_udp_rx_tvalid : std_logic                    := '0';
    signal s_axis_udp_rx_tlast  : std_logic                    := '0';
    signal s_axis_udp_rx_tready : std_logic;

    -- UDP Tx (replies/data out)
    signal m_axis_udp_tx_tdata    : std_logic_vector(7 downto 0);
    signal m_axis_udp_tx_tvalid   : std_logic;
    signal m_axis_udp_tx_tlast    : std_logic;
    signal m_axis_udp_tx_tready   : std_logic := '1';
    signal m_axis_udp_tx_channel  : std_logic_vector(1 downto 0);

    -- Command bus (out)
    signal m_axis_cmd_tdata  : std_logic_vector(7 downto 0);
    signal m_axis_cmd_tvalid : std_logic;
    signal m_axis_cmd_tlast  : std_logic;
    signal m_axis_cmd_tready : std_logic := '1';

    -- Reply bus (in)
    signal s_axis_rply_tdata  : std_logic_vector(7 downto 0) := (others => '0');
    signal s_axis_rply_tvalid : std_logic                    := '0';
    signal s_axis_rply_tlast  : std_logic                    := '0';
    signal s_axis_rply_tready : std_logic;

    -- Probe data (in)
    signal s_axis_data_tdata  : slv_array(0 to NUMBER_OF_PROBES - 1)(7 downto 0) := (others => (others => '0'));
    signal s_axis_data_tvalid : std_logic_vector(0 to NUMBER_OF_PROBES - 1)      := (others => '0');
    signal s_axis_data_tlast  : std_logic_vector(0 to NUMBER_OF_PROBES - 1)      := (others => '0');
    signal s_axis_data_tready : std_logic_vector(0 to NUMBER_OF_PROBES - 1);

    signal cmd_packet_counter   : std_logic_vector(7 downto 0);
    signal rply_packet_counter  : std_logic_vector(7 downto 0);
    signal host_frame_read_rate : std_logic_vector(4 downto 0) := "11111";

begin

    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.bsb_master
        generic map (
            NUMBER_OF_PROBES => NUMBER_OF_PROBES
        )
        port map (
            s_axis_udp_rx_tdata  => s_axis_udp_rx_tdata,
            s_axis_udp_rx_tvalid => s_axis_udp_rx_tvalid,
            s_axis_udp_rx_tlast  => s_axis_udp_rx_tlast,
            s_axis_udp_rx_tready => s_axis_udp_rx_tready,
            m_axis_udp_tx_tdata  => m_axis_udp_tx_tdata,
            m_axis_udp_tx_tvalid => m_axis_udp_tx_tvalid,
            m_axis_udp_tx_tlast  => m_axis_udp_tx_tlast,
            m_axis_udp_tx_tready => m_axis_udp_tx_tready,
            m_axis_udp_tx_channel => m_axis_udp_tx_channel,
            m_axis_cmd_tdata     => m_axis_cmd_tdata,
            m_axis_cmd_tvalid    => m_axis_cmd_tvalid,
            m_axis_cmd_tlast     => m_axis_cmd_tlast,
            m_axis_cmd_tready    => m_axis_cmd_tready,
            s_axis_rply_tdata    => s_axis_rply_tdata,
            s_axis_rply_tvalid   => s_axis_rply_tvalid,
            s_axis_rply_tlast    => s_axis_rply_tlast,
            s_axis_rply_tready   => s_axis_rply_tready,
            s_axis_data_tdata    => s_axis_data_tdata,
            s_axis_data_tvalid   => s_axis_data_tvalid,
            s_axis_data_tlast    => s_axis_data_tlast,
            s_axis_data_tready   => s_axis_data_tready,
            cmd_packet_counter   => cmd_packet_counter,
            rply_packet_counter  => rply_packet_counter,
            host_frame_read_rate => host_frame_read_rate,
            clk                  => clk,
            rst                  => rst
        );

    rst_proc : process
    begin
        rst <= '1';
        sleep(clk, 8);
        rst <= '0';
        sleep(clk, 4);
        wait;
    end process;

    -- Stimulus: send command packets on UDP Rx
    stim_cmd : process
        variable cmd_buf : slv8_array(0 to 2);
    begin
        wait until rst = '0';
        sleep(clk, 16);
        -- Command 1: read control
        cmd_buf := to_command_bytes(opcode => READ_CONTROL, addr => 0);
        send_buffer(clk, s_axis_udp_rx_tdata, s_axis_udp_rx_tvalid, s_axis_udp_rx_tlast, s_axis_udp_rx_tready, cmd_buf);
        sleep(clk, 32);
        -- Command 2: write control
        cmd_buf := to_command_bytes(opcode => WRITE_CONTROL, addr => 4);
        send_buffer(clk, s_axis_udp_rx_tdata, s_axis_udp_rx_tvalid, s_axis_udp_rx_tlast, s_axis_udp_rx_tready, cmd_buf);
        sleep(clk, 200);
        finish;
    end process stim_cmd;

    -- Stimulus: send mock reply packets (replies have priority on TX)
    stim_rply : process
        variable rply_pkt : slv_array(0 to 7)(7 downto 0) := (
            0 => x"AA", 1 => x"BB", 2 => x"CC", 3 => x"DD", 4 => x"EE", 5 => x"FF", 6 => x"11", 7 => x"22"
        );
    begin
        wait until rst = '0';
        sleep(clk, 64);
        send_axis_packet(clk, s_axis_rply_tdata, s_axis_rply_tvalid, s_axis_rply_tlast, s_axis_rply_tready, rply_pkt, 2);
        sleep(clk, 32);
        send_axis_packet(clk, s_axis_rply_tdata, s_axis_rply_tvalid, s_axis_rply_tlast, s_axis_rply_tready, rply_pkt, 2);
        wait;
    end process stim_rply;

    -- Stimulus: send probe data (probes arbitrated after replies, round-robin)
    g_probe : if NUMBER_OF_PROBES > 0 generate
        stim_probe : process
            variable pkt : slv_array(0 to 5)(7 downto 0);
        begin
            wait until rst = '0';
            sleep(clk, 128);
            pkt := (0 => x"F0", 1 => x"F1", 2 => x"F2", 3 => x"F3", 4 => x"F4", 5 => x"F5");
            send_axis_packet(clk, s_axis_data_tdata(0), s_axis_data_tvalid(0), s_axis_data_tlast(0), s_axis_data_tready(0), pkt, 1);
            wait;
        end process stim_probe;
    end generate g_probe;

    -- Checker: capture and report TX packets (channel 00=reply, 01=probe)
    check_proc : process (clk)
        variable pkt_buf   : slv_array(0 to 255)(7 downto 0);
        variable pkt_idx   : natural range 0 to 255 := 0;
        variable ch        : std_logic_vector(1 downto 0);
        variable buf       : line;
    begin
        if rising_edge(clk) then
            if rst = '0' then
                if m_axis_udp_tx_tvalid = '1' and m_axis_udp_tx_tready = '1' then
                    ch := m_axis_udp_tx_channel;
                    pkt_buf(pkt_idx) := m_axis_udp_tx_tdata;
                    if m_axis_udp_tx_tlast = '1' then
                        write(buf, string'("TX ch=") & to_hstring(ch) &
                              string'(" len=") & integer'image(pkt_idx + 1) &
                              string'(" hdr=0x") & to_hstring(pkt_buf(0)));
                        writeline(output, buf);
                        pkt_idx := 0;
                    else
                        pkt_idx := pkt_idx + 1;
                    end if;
                end if;
            else
                pkt_idx := 0;
            end if;
        end if;
    end process check_proc;

end architecture sim;
