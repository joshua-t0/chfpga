--------------------------------------------------------------------------------
-- file
-- Company:
-- Engineer:
--
-- Create Date:   
-- Design Name:
-- Module Name:   
-- Project Name:  
-- Target Device:
-- Tool versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes:

--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

library work;
USE work.chFPGA_Package.all;
use work.tb_package.all;

ENTITY udp_mac_rx_testbench IS
END udp_mac_rx_testbench;


ARCHITECTURE behavior OF udp_mac_rx_testbench IS

   -- Clock period definitions

-- constant IN_CLK_PERIOD : time := 5 ns; -- 200 MHz
constant CLK125_period : time := 8 ns;

--Inputs
signal rst : std_logic := '0';


-- signal in_clk: std_logic; --
signal sysmon_clk: std_logic; --
signal clk125: std_logic; --


signal udp_tdata  : std_logic_vector (7 downto 0);
signal udp_tvalid : std_logic;

signal rx_tdata  : std_logic_vector (7 downto 0);
signal rx_tvalid : std_logic;
signal rx_tlast  : std_logic;
signal rx_tready : std_logic;
signal rx_overflow:  std_logic;


begin

clk125_process :process
   begin
		clk125 <= '0';
		wait for clk125_period/2;
		clk125 <= '1';
		wait for clk125_period/2;
   end process;


	rx0: entity work.udp_mac_rx
		generic map(
			BROADCAST_IP_PORT => 2222
			)
		port map(
			local_mac_addr           => X"12340a0a0313",
			local_ip_addr            => X"0a0a0313",
			local_ip_port            => X"8F9F",

			m_axis_udp_rx_tdata      => rx_tdata,
			m_axis_udp_rx_tvalid     => rx_tvalid,
			m_axis_udp_rx_tlast      => rx_tlast,
			m_axis_udp_rx_tready     => rx_tready,
			rx_overflow              => rx_overflow,

			clk                      => clk125,
			rst                      => rst,
			gmii_rxclk               => clk125,
			gmii_rxctrl_rxdv         => udp_tvalid,
			gmii_rxd                 => udp_tdata
		);


-- proc :process(clk125)
--    begin
--    		if rising_edge(clk125) then
--    			SYSMON_DRDY <= SYSMON_DEN;
--    		end if;
--    end process;

stim_proc : process
    variable data: slv8_array(0 to 55) := to_slv8_array(std_logic_vector'(X"D5_12340a0a0313_74563c645a5d_0800_4500_0029_50e64000_40_11_c896_0a0a0a21_0a0a03138f_9f8f9f00151a61_a00005_feffdcff000000000000"));

	begin
		rst <= '1';
		sleep(clk125, 2);
		rst <= '0';
		sleep(clk125, 10); -- make sure we start command transmission on a CLK125 edge or we will lose some data
        for i in 0 to data'LENGTH(1)-1 loop
            udp_tdata <= data(i);
            udp_tvalid <= '1';
            sleep(clk125);
        end loop;            

            rx_tvalid <= '0';

		wait;
	end process ; -- lane0_proc

END;
