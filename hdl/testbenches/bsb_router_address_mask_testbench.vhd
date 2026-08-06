--------------------------------------------------------------------------------
-- Verify the BSB address-mask placement used by XGLINK.
--
-- A backplane corner-turn address has CT bits at 18:16 and BCT-router bits at
-- 15:14.  An XGLINK module number then occupies bits 13:9.  In particular,
-- a request for module 0 below BCT port 3 must select port 0, not port 24.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use std.env.finish;

library work;
use work.chFPGA_Package.all;

entity bsb_router_address_mask_testbench is
end entity bsb_router_address_mask_testbench;

architecture sim of bsb_router_address_mask_testbench is
    constant CLOCK_PERIOD : time := 10 ns;
    constant NUMBER_OF_PORTS : integer := 32;

    signal clk : std_logic := '0';
    signal rst : std_logic := '1';

    -- This is a BCT address for module 0: CT port 0, BCT port 3, module 0.
    signal cmd_tdata  : std_logic_vector(7 downto 0) := (others => '0');
    signal cmd_tvalid : std_logic := '0';
    signal cmd_tlast  : std_logic := '0';

    signal direct_cmd_tready : std_logic;
    signal bct_cmd_tready    : std_logic;

    signal direct_routed_tdata  : slv8_array(0 to NUMBER_OF_PORTS - 1);
    signal direct_routed_tvalid : std_logic_vector(0 to NUMBER_OF_PORTS - 1);
    signal direct_routed_tlast  : std_logic_vector(0 to NUMBER_OF_PORTS - 1);
    signal bct_routed_tdata     : slv8_array(0 to NUMBER_OF_PORTS - 1);
    signal bct_routed_tvalid    : std_logic_vector(0 to NUMBER_OF_PORTS - 1);
    signal bct_routed_tlast     : std_logic_vector(0 to NUMBER_OF_PORTS - 1);

    signal no_reply_data  : slv8_array(0 to NUMBER_OF_PORTS - 1) := (others => (others => '0'));
    signal no_reply_valid : std_logic_vector(0 to NUMBER_OF_PORTS - 1) := (others => '0');
    signal no_reply_last  : std_logic_vector(0 to NUMBER_OF_PORTS - 1) := (others => '0');
begin
    clk <= not clk after CLOCK_PERIOD / 2;

    direct_router : entity work.bsb_router
        generic map (
            NUMBER_OF_PORTS => NUMBER_OF_PORTS,
            ADDRESS_MASK    => "---11111-----------"
        )
        port map (
            s_axis_bsb_tdata  => cmd_tdata,
            s_axis_bsb_tvalid => cmd_tvalid,
            s_axis_bsb_tlast  => cmd_tlast,
            s_axis_bsb_tready => direct_cmd_tready,
            m_axis_bsb_tdata  => open,
            m_axis_bsb_tvalid => open,
            m_axis_bsb_tlast  => open,
            m_axis_bsb_tready => '1',
            m_axis_routed_bsb_tdata  => direct_routed_tdata,
            m_axis_routed_bsb_tvalid => direct_routed_tvalid,
            m_axis_routed_bsb_tlast  => direct_routed_tlast,
            m_axis_routed_bsb_tready => (others => '0'),
            s_axis_routed_bsb_tdata  => no_reply_data,
            s_axis_routed_bsb_tvalid => no_reply_valid,
            s_axis_routed_bsb_tlast  => no_reply_last,
            s_axis_routed_bsb_tready => open,
            cmd_overflow => open,
            clk => clk,
            rst => rst
        );

    bct_router : entity work.bsb_router
        generic map (
            NUMBER_OF_PORTS => NUMBER_OF_PORTS,
            ADDRESS_MASK    => "-----11111---------"
        )
        port map (
            s_axis_bsb_tdata  => cmd_tdata,
            s_axis_bsb_tvalid => cmd_tvalid,
            s_axis_bsb_tlast  => cmd_tlast,
            s_axis_bsb_tready => bct_cmd_tready,
            m_axis_bsb_tdata  => open,
            m_axis_bsb_tvalid => open,
            m_axis_bsb_tlast  => open,
            m_axis_bsb_tready => '1',
            m_axis_routed_bsb_tdata  => bct_routed_tdata,
            m_axis_routed_bsb_tvalid => bct_routed_tvalid,
            m_axis_routed_bsb_tlast  => bct_routed_tlast,
            m_axis_routed_bsb_tready => (others => '0'),
            s_axis_routed_bsb_tdata  => no_reply_data,
            s_axis_routed_bsb_tvalid => no_reply_valid,
            s_axis_routed_bsb_tlast  => no_reply_last,
            s_axis_routed_bsb_tready => open,
            cmd_overflow => open,
            clk => clk,
            rst => rst
        );

    stimulus : process
        procedure send_command_byte(
            constant data : std_logic_vector(7 downto 0);
            constant last : std_logic
        ) is
        begin
            cmd_tdata  <= data;
            cmd_tlast  <= last;
            cmd_tvalid <= '1';
            loop
                wait until rising_edge(clk);
                exit when direct_cmd_tready = '1' and bct_cmd_tready = '1';
            end loop;
            cmd_tvalid <= '0';
            cmd_tlast  <= '0';
            wait until rising_edge(clk);
        end procedure;
    begin
        wait for 3 * CLOCK_PERIOD;
        rst <= '0';

        -- BSB read-control command, address 0b000_11_00000_000000000.
        send_command_byte(x"00", '0');
        send_command_byte(x"C0", '0');
        send_command_byte(x"00", '1');

        for i in 0 to 15 loop
            wait until rising_edge(clk);
        end loop;

        assert bct_routed_tvalid(0) = '1'
            report "BCT XGLINK mask did not route module 0 to port 0"
            severity failure;
        assert direct_routed_tvalid(24) = '1'
            report "Direct XGLINK mask no longer reproduces the legacy port-24 decode"
            severity failure;
        assert direct_routed_tvalid(0) = '0'
            report "Direct XGLINK mask unexpectedly selected module 0 for BCT port 3"
            severity failure;

        report "bsb_router_address_mask_testbench passed" severity note;
        finish;
    end process;
end architecture sim;
